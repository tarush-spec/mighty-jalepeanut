extends Node2D

# counting scores
@onready var game_manager: Node = %GameManager
@export var score_value: int = 200

# health
@export var hp: int = 5
@export var recoil: int = 10

# destructive tendencies
@export var destroy: int = 5

# knockback
var accel: float = 5.0
@export var knockback_resist: float = 0.5
var is_knockback: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO
@export var knocked_time: float = 0.5

# to withstand damage
func take_damage(damage_dealt: int):
	hp -= damage_dealt
	if hp <= 0:
		bulldozer()

# to take damage
func _on_area_2d_body_entered(body):
	if not body.is_in_group("Player") and not body.is_in_group("CRASH"):
		return
	elif body.is_in_group("Player"):
		take_damage(body.damage)
	elif body.is_in_group("CRASH"):
		if body.is_crashing:
			body.crash_despawn(recoil)
			game_manager.add_point(score_value/2)
			take_damage(body.damage)


# shhhhhh (death lol)
func bulldozer():
	game_manager.add_point(score_value)
	queue_free()

# knockback stuff
func apply_knockback(direction: Vector2, recoil_knockback: float):
	# calculating knockback distance
	knockback_velocity = direction * recoil_knockback * (1.0 - knockback_resist)
	is_knockback = true
	
	# end knockback after some time
	var knockback_timer = get_tree().create_timer(knocked_time) #knockback for 0.5 seconds
	await knockback_timer.timeout
	is_knockback = false
	knockback_velocity = Vector2.ZERO

#to execute all commands
func _physics_process(delta):
	if is_knockback:
		global_position += knockback_velocity * delta
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, accel * delta)
