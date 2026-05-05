extends CharacterBody2D
@onready var animsprite2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D


#sound variables
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
var music_norm: AudioStream = preload("res://Assets/sound/capsikid_voice.wav")
var music_crash: AudioStream = preload("res://Assets/sound/enemy hit.wav")

#movement variables
var speed: float = 30.0
var direction: int = -1
var is_crashing: bool = false

#health and damage variables
@export var hp: int = 1
@export var damage: int = 1 #LOLLLLLLLLLZZZZ
@export var hp_crash: int = 30

# for playing sound
func play_sound(sound: AudioStream):
	audio.stream = sound
	audio.play()

# to fall and not walk on sky
func add_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

# to walk and not stay still
func move():
	velocity.x = speed * direction

# to watch your step and change where you're going
func switch_side():
	if is_on_wall():
		direction = -1 * direction
		animsprite2d.flip_h = direction > 0
		# if true: flip right (+x). if false: flip left (-x)

# to execute everything mentioned above
func _physics_process(delta: float) -> void:
	add_gravity(delta)
	move()
	move_and_slide()
	switch_side()
	
	#FAILSAFE
	if is_crashing:
		crash_despawn(1)
		

# to take damage (he can't deal damage he's worthless)
func take_damage(damage_dealt: int):
	hp -= damage_dealt
	if hp <= 0:
		death()

# he is saved from suffering
func death():
	play_sound(music_crash)
	animsprite2d.play("death")
	print("anim played")
	is_crashing = true
	speed = 30 * speed
	#queue_free()
func crash_despawn(crash_time: int):
	hp_crash -= crash_time
	if hp_crash <= 0:
		queue_free()
		GameManager.add_point(50)
		print("DEAD ENEMY")
