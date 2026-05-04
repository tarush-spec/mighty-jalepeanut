extends CharacterBody2D

# health and damage variables
@export var hp: int = 1
@export var damage: int = 100
@export var hp_crash: int = 3000

# movement variables
@export var direction: int = 1
var speed: float = 0
@export var applied_speed: float = 1000
var is_crashing: bool = false
var is_dashing: bool = false

# visual variables
@onready var animsprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var red_button: Area2D = $"red button"

# score variables
@onready var game_manager: Node = %GameManager

# sound variables
var music_startengine: AudioStream = preload("res://Assets/sound/engine start.wav")
var music_bulldoze: AudioStream = preload("res://Assets/sound/incoming!!.wav")
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer



# for sound purposes
func play_sound(sound:AudioStream):
	audio.stream = sound
	audio.play()

# direction based animations
func manage_animation():
	if direction >= 0:
		animsprite.flip_h = false
	elif direction < 0:
		animsprite.flip_h = true

# to not fly, lets not get too ridiculour
func add_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

# to move
func move():
	if is_crashing:
		velocity.x = speed * direction
		# will only move once hit

# to implement all functions regarding movement
func _physics_process(delta):
	move_and_slide()
	add_gravity(delta)
	move()
	

# to take damage
func take_damage(amount: int):
	hp -= amount
	
	if hp <= 0:
		queue_bulldoze()

# to enable movement and all
func queue_bulldoze():
	play_sound(music_startengine)
	animsprite.play("uh oh")
	speed = applied_speed
	await get_tree().create_timer(3).timeout
	play_sound(music_bulldoze)
	is_crashing = true

# to detect if player or not
func _on_red_button_body_entered(body):
	if is_crashing:
		if body.is_in_group("Object") or body.is_in_group("Enemy"):
			body.take_damage(damage)
			if body.has_method("crash_despawn"):
				body.crash_despawn(damage)
				
	if body.is_in_group("Player"):
		take_damage(body.damage)

# to destroy when needed to destroy
func crash_despawn(crash_time: int):
	hp_crash -= crash_time
	if hp_crash <= 0:
		game_manager.add_point(5000)
		queue_free()
