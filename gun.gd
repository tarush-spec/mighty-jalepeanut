extends Node2D

@export var bullet_scene: PackedScene
@export var fire_rate : float = 1.0  # shots per second
@export var bullet_speed : float = 300.0
@export var bullet_damage : int = 1

@onready var muzzle_pos: Marker2D = $muzzle_pos
var can_shoot : bool = true
var target : Node2D = null

# just in case bullet isn't loaded
func _ready():
	if bullet_scene == null:
		bullet_scene = preload("res://bullet.tscn")

# to set a target
func set_target(new_target: Node2D):
	target = new_target

# to shoot
func shoot():
	if not can_shoot or bullet_scene == null:
		return
	
	can_shoot = false
	
	
	
	# creat bullet
	var bullet_instance = bullet_scene.instantiate()
	var parent = get_parent()
	get_tree().current_scene.add_child(bullet_instance)
	
	bullet_instance.global_position = muzzle_pos.global_position
	bullet_instance.direction = (global_position - parent.global_position).normalized() * -1
	
	bullet_instance.speed = bullet_speed
	bullet_instance.damage = bullet_damage
	
	# cooldown
	await get_tree().create_timer(1.0 / fire_rate).timeout
	can_shoot = true

func shoot_target():
	if target and can_shoot:
		# horizontal only — purely left or right, no vertical component
		var target_direction = Vector2(sign(target.global_position.x - global_position.x), 0)
		
		var bullet_instance = bullet_scene.instantiate()
		
		get_tree().current_scene.add_child(bullet_instance)
		
		bullet_instance.global_position = muzzle_pos.global_position
		bullet_instance.direction = target_direction
		
		bullet_instance.speed = bullet_speed
		bullet_instance.damage = bullet_damage
		
		can_shoot = false
		await get_tree().create_timer(1.0 / fire_rate).timeout
		can_shoot = true
