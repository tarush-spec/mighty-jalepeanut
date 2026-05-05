extends CharacterBody2D

#visual variables
@onready var animsprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

#sound variables
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
var music_norm: AudioStream = preload("res://Assets/sound/big capsikid.wav")
var music_crash: AudioStream = preload("res://Assets/sound/blast.wav")
var music_hit: AudioStream = preload("res://Assets/sound/enemy hit.wav")
#health and damage variables
@export var hp: int = 3
@export var damage: int = 2
@export var hp_crash: int = 300

#movement variables
var speed: float = 100
var jumpstrength: float = 50
var direction: float = -1
var is_crashing: bool = false
var is_dashing: bool = false

# to play sound
func play_sound(sound: AudioStream):
	audio.stream = sound
	audio.play()

# to add gravity
func add_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

# to move
func move():
	velocity.x = speed * direction
	if Input.is_action_just_pressed("Jump"):
		if is_crashing:
			return
		velocity.y = speed * jumpstrength

# to switch sides
func switch_side():
	if is_on_wall():
		direction = -1 * direction
		animsprite.flip_h = direction > 0
		# if true flip right (+x), if false flip left (-x)

func _physics_process(delta):
	add_gravity(delta)
	move_and_slide()
	move()
	switch_side()
	
	#FAILSAFE
	if is_crashing:
		crash_despawn(1)

func take_damage(amount: int):
	hp -= amount
	play_sound(music_hit)
	animsprite.modulate = Color.CRIMSON
	await get_tree().create_timer(0.1).timeout
	animsprite.modulate = Color.WHITE
	if hp <= 0:
		big_dead_guy()

# to enter crash status
func big_dead_guy():
	play_sound(music_hit)
	is_crashing = true
	disable_coll()
	speed = 30 * speed
	GameManager.add_point(10000)

# to not damage anymore
func disable_coll():
	collision_shape_2d.disabled = true

# to enter death status
func crash_despawn(crash_time: int):
	hp_crash -= crash_time
	if hp_crash <= 0:
		GameManager.add_point(10000)
		queue_free()

# to deal damage
func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	if body.is_in_group("Player"):
		if body.is_dashing:
			return
		body.take_damage(damage)
