extends CharacterBody2D

@onready var animsprite_e1: AnimatedSprite2D = $AnimatedSprite2D

var direction = -1
var SPEED = 50.0

@export var hp: int = 1

func _ready():
	# Move to layer 3 (value 4) so the player can pass through during i-frames.
	# Layer 1 is shared with the floor — keeping it there would prevent selective passthrough.
	# collision_mask stays 1 so lizapple still lands on the floor correctly.
	collision_layer = 4
	collision_mask = 1
	add_to_group("Enemy")

func take_damage(amount: int):
	hp -= amount
	if hp <= 0:
		GameManager.add_point(200)
		queue_free()

#when i fall i shall fall.
func add_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

#when i move i shall move
func move():
	velocity.x = SPEED * direction

#wall shall not stop me, but it shall change my mind.
func switch_side():
	if is_on_wall():
		direction = -1 * direction
		animsprite_e1.flip_h = true

#now action lmao:
func _physics_process(delta: float) -> void:
	add_gravity(delta)
	move()
	move_and_slide()
	switch_side()
	
