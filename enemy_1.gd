extends Node2D
const speed = 60
var direction = -1
@onready var ray_cast_r_: RayCast2D = $"RayCast(R)"
@onready var ray_cast_l_: RayCast2D = $"RayCast(L)"
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
signal playerdamage ()

func _process(delta):
	
	if ray_cast_r_.is_colliding():
		direction = -1
		animated_sprite_2d.flip_h = false
	if ray_cast_l_.is_colliding():
		direction = 1
		animated_sprite_2d.flip_h = true
	position.x += direction * speed * delta
