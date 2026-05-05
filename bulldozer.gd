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

# sound variables
var music_startengine: AudioStream = preload("res://Assets/sound/engine start.wav")
var music_bulldoze: AudioStream = preload("res://Assets/sound/incoming!!.wav")
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer



func _ready():
	# red button defaults to collision_mask = 1 (floor only), which misses enemies on layer 4
	# expand it to cover all relevant layers so enemies are detected on body_entered
	red_button.collision_mask = 7
	# the signal was never wired up in the scene file, so connect it here
	red_button.body_entered.connect(_on_red_button_body_entered)
	# register as CRASH so crates call crash_despawn back on us when we hit them
	add_to_group("CRASH")


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
	manage_animation()
	# tick down hp_crash each frame once crashing — same failsafe pattern as enemies
	if is_crashing:
		crash_despawn(1)
	

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
		if body.is_in_group("Object"):
			# crates and buildings: take_damage to trigger destruction + crash_despawn to track bulldozer hits
			body.take_damage(damage)
			if body.has_method("crash_despawn"):
				body.crash_despawn(damage)
		elif body.is_in_group("Enemy"):
			# enemies: only call take_damage so their death animation plays out naturally
			# their own _physics_process crash_despawn(1) failsafe will free them in time
			body.take_damage(damage)

	if body.is_in_group("Player"):
		take_damage(body.damage)

# to destroy when needed to destroy
func crash_despawn(crash_time: int):
	hp_crash -= crash_time
	if hp_crash <= 0:
		GameManager.add_point(5000)
		queue_free()
