extends CharacterBody2D

# visual variables
@onready var animsprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var game_manager: Node = %GameManager
@onready var projectile_spawner: Area2D = $projectile_spawner
@onready var ty: Label = $CanvasLayer/ty

# sound variables
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
var music_norm: AudioStream = preload("res://Assets/sound/Clowndiment laugh.wav")
var music_hit: AudioStream = preload("res://Assets/sound/Clowndiment Hit.wav")
var music_defeat: AudioStream = preload("res://Assets/sound/Clowndiment Hit.wav")
var music_shoot: AudioStream = preload("res://Assets/sound/shoot.wav")
var music_loadgun: AudioStream = preload("res://Assets/sound/Clowndiment taunt.wav")
var music_dash: AudioStream = preload("res://Assets/sound/Clowndiment laugh.wav")
var music_jump: AudioStream = preload("res://Assets/sound/Clowndiment laugh.wav")

# health and damage variables
@export var hp: int = 5
@export var damage: int = 2
signal onHealthChange
var is_damaged: bool = false

# movement variables
@export var speed: float = 200
@export var jumpstrength: float = 250
var direction: float = -1
var is_crashing: bool = false
var is_dashing: bool = false

# Boss state variables
enum Boss_State {IDLE, DASHING, SHOOTING, JUMPING, CEILING_RUNNING}
var current_state = Boss_State.IDLE
var state_timer: float = 0.0
var player_ref: Node2D = null

# Dash attack variables
@export var dash_speed: float = 300.0
@export var dash_duration: float = 10.0
var dash_timer: float = 0.0

# Shooting variables
@export var projectile_scene: PackedScene
@export var shoot_cooldown: float = 2.0
var shoot_timer: float = 0.0

# Jumping Phase variables (HP = 2/3)
@export var jump_phase_speed: float = 150.0
@export var jump_phase_jump_strength: float = 300.0
@export var jump_phase_jump_interval: float = 1.5
var jump_phase_timer: float = 0.0


# Ceiling Phase variables (HP = 1)
@export var ceiling_phase_speed: float = 200.0
@export var ceiling_phase_duration: float = 30.0
var ceiling_phase_timer: float = 0.0
var is_ceiling: bool = false
@export var gravity_reversed: bool = false

# to manage animations
func manage_animation():
	if is_damaged:
		animsprite.play("hit")
	else:
		if current_state == Boss_State.DASHING:
			animsprite.play("dash")
		elif current_state == Boss_State.SHOOTING:
			animsprite.play("shoot")
	# to flip sprite based off direction
	if direction > 0:
		animsprite.flip_h = true
	else:
		animsprite.flip_h = false
	
	# to shoot and unload a gun
	if shoot_timer >= shoot_cooldown:
		animsprite.play("shoot")
	

func switch_sides():
	# wall check
	if is_on_wall():
		direction *= -1

# to play sound
func play_sound(sound:AudioStream):
	audio.stream = sound
	audio.play()

func _ready():
	var players = get_tree().get_nodes_in_group("Player")
	if players.size() > 0:
		player_ref = players[0] # ie making it ref to player
	
	# start dashing
	start_dash()
	

func _physics_process(delta):
	manage_animation()
	switch_sides()
	state_timer += delta
	
	match hp:
		5,4,3:
			handle_phase1_state(delta)
		2,1:
			handle_phase2_state(delta)
		#1:
			#handle_phase3_state(delta)
	
	# for movement's sake
	move_and_slide()

# Phase 1:
func handle_phase1_state(delta):
	match current_state:
		Boss_State.DASHING:
			handle_dash(delta)
		Boss_State.SHOOTING:
			handle_shooting(delta)

# Phase 2:
func handle_phase2_state(delta):
	if current_state != Boss_State.JUMPING:
		enter_jump()
	handle_jump(delta)

# Phase 3:
func handle_phase3_state(delta):
	pass


# DASH STATE FUNCTIONS
func start_dash():
	current_state = Boss_State.DASHING
	state_timer = 0.0
	dash_timer = 0.0
	is_dashing = true
	speed = dash_speed
	play_sound(music_dash)
	
	# face towards player if available
	if player_ref:
		direction = sign(player_ref.global_position.x - global_position.x)
		if direction == 0:
			direction = 1

func handle_dash(delta):
	dash_timer += delta
	
	# movement during direction
	velocity.x = speed * direction
	
	
	
	# end dash after duration is up
	if dash_timer >= dash_duration:
		end_dash()

func end_dash():
	is_dashing = false
	speed = 200
	current_state = Boss_State.SHOOTING
	state_timer = 0.0
	shoot_timer = 0.0

# SHOOTING STATE FUNCTIONS
func handle_shooting(delta):
	# to prevent movement
	velocity.x = 0 
	# to add gravity
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	# to shoot
	shoot_timer += delta
	if shoot_timer >= shoot_cooldown:
		play_sound(music_loadgun)
		shoot_projectile()
		shoot_timer = 0
	
	# return to dash state
	if state_timer >= shoot_cooldown + 1.0:
		start_dash()

func shoot_projectile():
	if projectile_scene == null:
		return
	
	var projectile = projectile_scene.instantiate()
	get_parent().add_child(projectile)
	
	# position the projectile with the gun
	projectile.global_position = projectile_spawner.global_position
	
	# towards player if available
	if player_ref:
		var shoot_direction = (player_ref.global_position - global_position).normalized()
		projectile.direction = shoot_direction
	else:
		projectile.direction = Vector2(direction,0)
	
	# preference for rebound to boss
	if projectile.has_method("boss_reference"):
		projectile.boss_reference(self)
	
	play_sound(music_shoot)

# JUMPING STATE FUNCTIONS
func enter_jump():
	current_state = Boss_State.JUMPING
	state_timer = 0.0
	jump_phase_timer = 0.0
	speed = jump_phase_speed
	play_sound(music_jump)

func handle_jump(delta):
	jump_phase_timer += delta
	
	velocity.x = speed * direction
	
	if not is_on_floor():
		velocity += get_gravity() * delta
	
	if jump_phase_timer >= jump_phase_jump_interval and is_on_floor():
		velocity.y = -jump_phase_jump_interval
	
	# shoot occasionally during this phase
	shoot_timer += delta
	if shoot_timer >= shoot_cooldown * 2: # lesser shots
		shoot_projectile()
		shoot_timer = 0.0

func take_damage(amount: int):
	hp -= amount
	play_sound(music_hit)
	is_damaged = true
	onHealthChange.emit(hp)
	await get_tree().create_timer(0.5).timeout
	is_damaged = false
	print("CLOWN HIT",hp)
	if hp <= 0:
		death()

func _on_damage_zone_body_entered(body: Node2D) -> void:
	if not body.is_in_group("Player"):
		return
	if body.is_in_group("Player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)

func death():
	is_damaged = true
	ty.visible = true
	await get_tree().create_timer(5).timeout
	get_tree().change_scene_to_file("res://title_screen.tscn")
