extends Node2D

# health
@export var hp: int = 1
@export var recoil: int = 30
@export var damage: int = 2

# destruction
@onready var destruct_zone: Area2D = $Destruct_Zone
var is_exploding: bool = false

# animated sprite
@onready var animsprite: AnimatedSprite2D = $AnimatedSprite2D

# Counting Scores
@onready var game_manager: Node = %GameManager
@export var score_value: int = 100

# signals
signal onCrateCrashed

# tracks whether we already registered a hit this dash/crash to prevent spam
var _hit_this_interaction: bool = false
var _is_dying: bool = false

func _ready():
	destruct_zone.monitorable = false
	destruct_zone.monitoring = false

func destroyed():
	if _is_dying:
		return
	_is_dying = true
	game_manager.add_point(score_value)
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
	if is_exploding or _is_dying:
		return
	var any_active := false
	for body in $Area2D.get_overlapping_bodies():
		if body.is_in_group("DASH") and body.is_dashing:
			any_active = true
			if not _hit_this_interaction:
				_hit_this_interaction = true
				take_damage(body.damage)
		elif body.is_in_group("Explodable") and body.is_exploding:
			any_active = true
			if not _hit_this_interaction:
				_hit_this_interaction = true
				take_damage(body.damage * 10)
		elif body.is_in_group("CRASH") and body.is_crashing:
			any_active = true
			if not _hit_this_interaction:
				_hit_this_interaction = true
				if body.has_method("crash_despawn"):
					body.crash_despawn(recoil)
				game_manager.add_point(score_value / 2)
				take_damage(body.damage)
	if not any_active:
		_hit_this_interaction = false


# Still used for bodies entering from outside the area (normal-range dashes)
func _on_area_2d_body_entered(body):
	if is_exploding:
		return
	if body.is_in_group("DASH") and body.is_dashing and not _hit_this_interaction:
		_hit_this_interaction = true
		take_damage(body.damage)
	elif body.is_in_group("Explodable") and body.is_exploding and not _hit_this_interaction:
		_hit_this_interaction = true
		take_damage(body.damage * 10)
	elif body.is_in_group("CRASH") and not _hit_this_interaction:
		if body.has_method("crash_despawn") and body.is_crashing:
			_hit_this_interaction = true
			body.crash_despawn(recoil)
			game_manager.add_point(score_value / 2)
			take_damage(body.damage)


func go_kaboom():
	is_exploding = true
	destruct_zone.monitoring = true
	# Await one physics frame so the engine can register overlapping bodies
	# after monitoring is enabled — querying immediately returns empty.
	await get_tree().physics_frame
	# damage physics bodies (player, enemies) via the destruct zone area
	for body in destruct_zone.get_overlapping_bodies():
		if body.is_in_group("Player"):
			if body.has_method("take_damage"):
				body.take_damage(damage)
		if body.is_in_group("Enemy"):
			if body.has_method("crash_despawn"):
				body.crash_despawn(damage * recoil)
	# damage crates via group + distance check — avoids collision layer issues
	# since crates are Node2D (not physics bodies) and area layer setup is unreliable
	var explosion_radius = _get_explosion_radius()
	for node in get_tree().get_nodes_in_group("Explodable"):
		if node == self:
			continue
		if global_position.distance_to(node.global_position) <= explosion_radius:
			if node.has_method("take_damage"):
				node.take_damage(damage * 10)
	destroyed() # called once, after both loops finish


# derives explosion radius from the Destruct_Zone's collision shape at runtime
func _get_explosion_radius() -> float:
	for child in destruct_zone.get_children():
		if child is CollisionShape2D and child.shape is RectangleShape2D:
			return child.shape.size.length() / 2.0
	return 100.0 # fallback


func take_damage(damage_dealt: int):
	hp -= damage_dealt
	onCrateCrashed.emit()
	if hp <= 0:
		go_kaboom()
