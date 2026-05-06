extends CharacterBody2D

#visual and score variables
@onready var animsprite2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var gun: Node2D = $Gun

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
@export var damage: int = 1
@export var hp_crash: int = 30


func play_sound(sound: AudioStream):
	audio.stream = sound
	audio.play()


func add_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta


func move():
	velocity.x = speed * direction


func switch_side():
	if is_on_wall():
		direction = -1 * direction
		animsprite2d.flip_h = direction > 0


func _physics_process(delta: float) -> void:
	add_gravity(delta)
	move()
	move_and_slide()
	switch_side()

	if is_crashing:
		crash_despawn(1)
	else:
		# aim at and shoot the player every frame (gun handles its own cooldown)
		var player = get_tree().get_first_node_in_group("Player")
		if player:
			gun.set_target(player)
			gun.shoot_target()


func take_damage(damage_dealt: int):
	if is_crashing:
		return
	hp -= damage_dealt
	if hp <= 0:
		death()


func death():
	play_sound(music_crash)
	animsprite2d.play("death")
	is_crashing = true
	speed = 30 * speed


func crash_despawn(crash_time: int):
	hp_crash -= crash_time
	if hp_crash <= 0:
		GameManager.add_point(50)  # add points before freeing
		queue_free()
