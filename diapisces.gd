extends Area2D
#editable variables for direction and speed
@export var move_direction: Vector2
@export var speed: float = 100

#beginning and end of enemy movement
@onready var beginpos: Vector2 = global_position
@onready var endpos: Vector2 = global_position + move_direction

#visual variables
@onready var animsprite: AnimatedSprite2D = $AnimatedSprite2D

#health and damage variable:
@export var hp: int = 1
@export var damage: int = 1

func _physics_process(delta):
	#going up
	global_position = global_position.move_toward(endpos, speed * delta)
	
	#going down
	if global_position == endpos:
		if endpos == beginpos:
			
			endpos = beginpos + move_direction
		else:
			
			endpos = beginpos
	

	

# damage
func _on_body_entered(body):
	if not body.is_in_group("Player"):
		if body.is_in_group("Enemy"):
			if body.is_crashing:
				body.crash_despawn(damage * body.recoil)
			take_damage(body.damage)
		else:
			return
	elif body.is_in_group("Player"):
		if body.is_dashing:
			take_damage(body.damage)
		else:
			body.take_damage(damage)

# taking damage
func take_damage(damage_dealt: int):
	hp -= damage_dealt
	if hp <= 0:
		death()

# death
func death():
	animsprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	animsprite.modulate = Color.GREEN
	queue_free()
