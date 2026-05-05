extends Node2D
# THIS IS FOR CRATES THAT CONTAIN HEALTH

# health
@export var hp: int = 1
@export var hp_player: int = 1

# visuals
@onready var animsprite: AnimatedSprite2D = $AnimatedSprite2D

# sound
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
var music_smash: AudioStream = preload("res://Assets/sound/Crate Smash.wav")

# tracks whether we already registered a hit this dash to prevent spam
var _hit_this_interaction: bool = false
var _is_dying: bool = false


func destroyed():
	if _is_dying:
		return
	_is_dying = true
	play_sound(music_smash)
	GameManager.add_point(100)
	# disable ALL collision objects so nothing physically blocks during animation
	for child in get_children():
		if child is CollisionObject2D:
			child.set_deferred("collision_layer", 0)
			child.set_deferred("collision_mask", 0)
	await _play_destroy_anim()
	queue_free()


func _play_destroy_anim() -> void:
	var origin := animsprite.position

	# Phase 1: rapid erratic shake
	var shake := create_tween()
	for i in range(7):
		shake.tween_property(animsprite, "position", origin + Vector2(randf_range(-7, 7), randf_range(-5, 5)), 0.03)
	shake.tween_property(animsprite, "position", origin, 0.02)
	await shake.finished

	# Phase 2: bright white flash, then scale-explode with spin and orange fade
	animsprite.modulate = Color(3.0, 3.0, 3.0, 1.0)
	var burst := create_tween().set_parallel(true)
	burst.tween_property(animsprite, "scale", Vector2(2.8, 2.8), 0.22).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	burst.tween_property(animsprite, "modulate", Color(2.0, 1.4, 0.3, 0.0), 0.22)
	burst.tween_property(animsprite, "rotation_degrees", randf_range(-65, 65), 0.22).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
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
				if body.is_in_group("Player") and body.has_method("restore_health"):
					body.restore_health(hp_player)
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
		if body.is_in_group("Player") and body.has_method("restore_health"):
			body.restore_health(hp_player)
		take_damage(body.damage)


func play_sound(sound: AudioStream):
	audio.stream = sound
	audio.play()


func take_damage(damage_dealt: int):
	hp -= damage_dealt
	if hp <= 0:
		destroyed()
