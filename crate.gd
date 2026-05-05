extends Node2D

# sound
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
var music_smash: AudioStream = preload("res://Assets/sound/Crate Smash.wav")

# visuals — resolved at runtime to support both AnimatedSprite2D (crates) and Sprite2D (obstacle houses)
var _visual: Node2D = null

# health
@export var hp: int = 1
@export var recoil: int = 20

# Counting Scores
@export var score_value: int = 100

# signals
signal onCrateCrashed

# tracks whether we already registered a hit this dash/crash to prevent spam
var _hit_this_interaction: bool = false
var _is_dying: bool = false


func _ready():
	# support both AnimatedSprite2D (crates) and Sprite2D (obstacle houses)
	if has_node("AnimatedSprite2D"):
		_visual = $AnimatedSprite2D
	elif has_node("Sprite2D"):
		_visual = $Sprite2D


func destroyed():
	if _is_dying:
		return
	_is_dying = true
	GameManager.add_point(score_value)
	# disable ALL collision objects so nothing physically blocks during animation
	for child in get_children():
		if child is CollisionObject2D:
			child.set_deferred("collision_layer", 0)
			child.set_deferred("collision_mask", 0)
	await _play_destroy_anim()
	queue_free()


func _play_destroy_anim() -> void:
	if _visual == null:
		return
	var origin := _visual.position

	# Phase 1: rapid erratic shake
	var shake := create_tween()
	for i in range(7):
		shake.tween_property(_visual, "position", origin + Vector2(randf_range(-7, 7), randf_range(-5, 5)), 0.03)
	shake.tween_property(_visual, "position", origin, 0.02)
	await shake.finished

	# Phase 2: bright white flash, then scale-explode outward with spin and fade
	_visual.modulate = Color(3.0, 3.0, 3.0, 1.0)
	var burst := create_tween().set_parallel(true)
	burst.tween_property(_visual, "scale", Vector2(2.8, 2.8), 0.22).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	burst.tween_property(_visual, "modulate", Color(2.0, 1.4, 0.3, 0.0), 0.22)
	burst.tween_property(_visual, "rotation_degrees", randf_range(-65, 65), 0.22).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	await burst.finished


# Polls overlapping bodies every physics frame.
# Handles the case where the player is already inside the area when dashing starts,
# which body_entered misses since it only fires on entry transitions.
func _physics_process(_delta):
	if _is_dying:
		return
	var any_active := false
	for body in $Area2D.get_overlapping_bodies():
		if body.is_in_group("DASH") and body.is_dashing:
			any_active = true
			if not _hit_this_interaction:
				_hit_this_interaction = true
				take_damage(body.damage)
		elif body.is_in_group("CRASH") and body.is_crashing:
			any_active = true
			if not _hit_this_interaction:
				_hit_this_interaction = true
				if body.has_method("crash_despawn"):
					body.crash_despawn(recoil)
				GameManager.add_point(score_value / 2)
				take_damage(body.damage)
	# reset once no active threat is overlapping, allowing a new hit next dash
	if not any_active:
		_hit_this_interaction = false


# Still used for bodies entering from outside the area (normal-range dashes)
func _on_area_2d_body_entered(body):
	if _is_dying:
		return
	if body.is_in_group("DASH") and body.is_dashing and not _hit_this_interaction:
		_hit_this_interaction = true
		take_damage(body.damage)
	elif body.is_in_group("CRASH") and not _hit_this_interaction:
		if body.has_method("crash_despawn") and body.is_crashing:
			_hit_this_interaction = true
			body.crash_despawn(recoil)
			GameManager.add_point(score_value / 2)
			take_damage(body.damage)


# to play sound
func play_sound(sound: AudioStream):
	audio.stream = sound
	audio.play()


# to take damage
func take_damage(damage_dealt: int):
	if _is_dying:
		return
	hp -= damage_dealt
	play_sound(music_smash)
	onCrateCrashed.emit()
	if hp <= 0:
		destroyed()
