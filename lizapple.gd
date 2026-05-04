extends CharacterBody2D

@onready var animsprite_e1: AnimatedSprite2D = $AnimatedSprite2D

var direction = -1
var SPEED = 50.0

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
	
