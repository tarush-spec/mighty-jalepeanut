extends CharacterBody2D

#visual variables
@onready var animsprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var area_2d: Area2D = $Area2D

#sound variables
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
var music_norm: AudioStream = preload("res://Assets/sound/big capsikid.wav")
var music_crash: AudioStream = preload("res://Assets/sound/blast.wav")
var music_hit: AudioStream = preload("res://Assets/sound/enemy hit.wav")

#health and damage variables
@export var hp: int = 3
@export var damage: int = 2
@export var hp_crash: int = 300
@export var jump_strength: float = 450.0  # upward force when a player dash hits

#movement variables
var speed: float = 100
var direction: float = -1
var is_crashing: bool = false
var is_dashing: bool = false  # kept for CRASH group compatibility

var _should_jump: bool = false
var _crash_hit: Array = []
var _hitpause_timer: float = 0.0


func play_sound(sound: AudioStream):
	audio.stream = sound
	audio.play()


func add_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta


func move():
	velocity.x = speed * direction
	# jump away from the player once we're back on the floor
	if _should_jump and is_on_floor():
		velocity.y = -jump_strength
		_should_jump = false


func switch_side():
	if is_on_wall():
		direction = -1 * direction
		animsprite.flip_h = direction > 0


func _physics_process(delta):
	add_gravity(delta)

	if _hitpause_timer > 0:
		_hitpause_timer -= delta
		velocity.x = -direction * speed * 0.6  # recoil away from player
		move_and_slide()
		return

	move_and_slide()
	move()
	switch_side()

	if is_crashing:
		crash_despawn(1)
		_hurt_nearby_enemies()


# called by the player's dash (charge area) — jump away, no HP loss
func take_damage(_amount: int):
	if is_crashing:
		return
	_should_jump = true
	play_sound(music_hit)


# called only by the ground pound shockwave — actual HP damage
func take_ground_pound_damage(amount: int):
	if is_crashing:
		return
	hp -= amount
	play_sound(music_hit)
	animsprite.modulate = Color.CRIMSON
	await get_tree().create_timer(0.1).timeout
	animsprite.modulate = Color.WHITE
	if hp <= 0:
		big_dead_guy()


func big_dead_guy():
	play_sound(music_crash)
	is_crashing = true
	# zero the mask so it passes through walls/floor during the crash,
	# but keep the shape enabled and collision_layer intact so the bulldozer's
	# Area2D can still detect and hit it
	set_deferred("collision_mask", 0)
	area_2d.monitoring = false
	area_2d.monitorable = false
	speed = 30 * speed
	GameManager.add_point(10000)


func crash_despawn(crash_time: int):
	hp_crash -= crash_time
	if hp_crash <= 0:
		GameManager.add_point(10000)
		queue_free()


func _hurt_nearby_enemies():
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if enemy == self or enemy in _crash_hit:
			continue
		if global_position.distance_to(enemy.global_position) <= 60.0:
			_crash_hit.append(enemy)
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	if body.is_dashing:
		_should_jump = true
		return
	body.take_damage(damage)
	var push_dir = sign(body.global_position.x - global_position.x)
	if body.has_method("apply_knockback"):
		body.apply_knockback(push_dir * 350.0)
	_hitpause_timer = 0.15
