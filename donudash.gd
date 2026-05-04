extends CharacterBody2D

#sound variable
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
var music_norm: AudioStream = preload("res://Assets/sound/incoming!!.wav")
var music_crash: AudioStream = preload("res://Assets/sound/enemy hit.wav")

#visual variable
@onready var animsprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var damagehitbox: CollisionShape2D = $Area2D/damagehitbox
@onready var area_2d: Area2D = $Area2D

#score
@onready var game_manager: Node = %GameManager

#movement based variables
@export var direction: int = -1
@export var SPEED: float = 300.0
@export var crashout_speed: float = 500.0
@export var crashout_timer: float = 5.0
var is_dashing: bool = true
var is_crashing: bool = false
var is_colliding: bool = false

#health and damage variables
@export var hp: int = 1
@export var damage: int = 2
@export var hp_crash: int = 120



#for audio stuff
func play_sound(sound: AudioStream):
	audio.stream = sound
	audio.play()

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
		if not is_crashing:
			if is_dashing:
				pass
			else:
				direction = -1 * direction
		else:
			for i in get_slide_collision_count():
				var collision = get_slide_collision(i)
				var collider = collision.get_collider()
				if collider.is_in_group("World") or collider.is_in_group("DASH"):
					direction = -1 * direction
			




# to ensure flip
func manage_animations():
	if direction > 0:
		animsprite.flip_h = true
	else:
		animsprite.flip_h = false

#now action lmao:
func _physics_process(delta: float) -> void:
	add_gravity(delta)
	move()
	move_and_slide()
	switch_side()
	manage_animations()
	if is_crashing:
		crash_despawn(1) #failsafe
		print(hp_crash)







# damage
func _on_area_2d_body_entered(body):
	if not body.is_in_group("Player") and not body.is_in_group("CRASH"):
		return
	if body.is_in_group("Player"):
		if body.is_dashing:
			return
		body.take_damage(damage)
	elif body.is_in_group("CRASH"):
		if body.is_crashing:
			if is_crashing:
				body.crash_despawn(damage)
			body.take_damage(damage)
			

# taking damage
func take_damage(damage_dealt: int):
	
	hp -= damage_dealt
	if hp <= 0:
		ded_donut()

#what is ded donut?
func ded_donut():
	play_sound(music_crash)
	animsprite.play("crash")
	disable_coll()
	damage = 20 * damage
	SPEED = 5 * SPEED
	is_crashing = true
	
	#_spawn_death_particles()
	#queue_free()

func disable_coll(): # PREVENT DAMAGE ON DEATH
	area_2d.monitoring = false

func crash_despawn(crash_time: int):
	hp_crash -= crash_time
	if hp_crash <= 0:
		queue_free()
		game_manager.add_point(200)
		print("DEAD DONUT")


func _spawn_death_particles():
	# create particles
	var particle_scene = preload("res://gpu_particles_2d.tscn")
	var particles = particle_scene.instantiate()
	
	get_parent().add_child(particles)
	particles.global_position = global_position
	particles.emitting = true
	
	
	# remove particles
	await get_tree().create_timer(particles.lifetime).timeout
	particles.queue_free()
