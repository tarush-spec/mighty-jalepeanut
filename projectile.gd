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
var is_body_dashing: bool = true

# Called when the node enters the scene tree for the first time.
func _ready():
	original_speed = speed
	# Auto-destroy after lifetime
	await get_tree().create_timer(lifetime).timeout
	queue_free()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float):
	position += direction * speed * delta
	# projectile's movement

# referring to clowndiment
func boss_reference(boss: Node2D):
	boss_ref = boss

# rebounding projectile back to clowndiment
func rebound_to_boss():
	#if not can_rebound or not boss_ref:
		#return
	
	# direction towards boss
	#direction = (boss_ref.global_position - global_position).normalized()
	#speed = original_speed * rebound_mult #faster speed when redirected
	speed *= 3
	direction *= -1
	has_been_hit = true



func _on_body_entered(body: Node2D):
	if body.is_in_group("Player"):
		if body.is_dashing:
			is_body_dashing = true
			return
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
	elif body.is_in_group("Boss"):
		if has_been_hit and body.has_method("take_damage"):
			is_rebound = true
			body.take_damage(damage * rebound_damage_multiplier) #just incase I beef the boss up


func _on_area_entered(area: Area2D):
	if area.is_in_group("DASH") and can_rebound and not has_been_hit:
		if is_body_dashing == true:
			rebound_to_boss()
