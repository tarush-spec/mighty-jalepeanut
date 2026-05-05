extends Area2D

@export var speed : float = 500.0
@export var rebound_mult: float = 1.5
@export var damage : int = 1
@export var lifetime : float = 5.0
@export var can_rebound : bool = true
@export var rebound_damage_multiplier : int = 1

var direction : Vector2 = Vector2.LEFT
var original_speed : float
var has_been_hit : bool = false
var boss_ref : Node2D = null
var is_rebound: bool = false


func _ready():
	original_speed = speed
	await get_tree().create_timer(lifetime).timeout
	queue_free()


func _process(delta: float):
	position += direction * speed * delta


# reference to boss passed in at spawn time
func boss_reference(boss: Node2D):
	boss_ref = boss


# aim the projectile directly at the boss's current position at the moment of rebound
func rebound_to_boss():
	if boss_ref:
		direction = (boss_ref.global_position - global_position).normalized()
	else:
		direction *= -1  # fallback if no boss reference was set
	speed = original_speed * rebound_mult
	has_been_hit = true


func _on_body_entered(body: Node2D):
	if body.is_in_group("Player"):
		# if the player is dashing the charge area handles the rebound — skip body damage
		if body.is_dashing:
			return
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	elif body.is_in_group("Boss"):
		if has_been_hit and body.has_method("take_damage"):
			is_rebound = true
			body.take_damage(damage * rebound_damage_multiplier)


func _on_area_entered(area: Area2D):
	if not area.is_in_group("DASH"):
		return
	if not can_rebound or has_been_hit:
		return
	# check directly whether the body that owns this area is actually dashing
	# avoids the old is_body_dashing flag which was always true by default
	var owner_body = area.get_parent()
	if owner_body and owner_body.get("is_dashing") == true:
		rebound_to_boss()
