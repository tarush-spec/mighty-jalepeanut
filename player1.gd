extends CharacterBody2D

var scoreboard: int
var parthboard: int

#visual variables
@onready var animsprite: AnimatedSprite2D = $AnimatedSprite2D

#health and damage variable
@export var hp: int = 3
@export var hp_max: int = 5
@export var damage: int = 1

#camera
@export var camera_follow: bool = true

#mechanics related variables
@export var walk_speed: float = 250
@export var accel: float = 100
@export var brake: float = 50
@export var gravity: float = 500
@export var jumpstrength: float = 250

#dash related variables
@export var dash: float = 450
@export var dash_duration: float = 0.7
@export var dash_cooldown: float = 0.5
var dash_direction: int = -1 #-1 -> , +1 <-
var is_dashing: bool = false
var dash_timer: float = 0
var dash_cooldown_timer: float = 0
@export var dash_hitpause: float = 0.5
var dash_hitpause_timer: float = 0
#hitbox
@onready var charge: Area2D = $charge

# ground pound
@export var pound_speed: float = 900.0
@export var pound_cooldown: float = 0.8
@export var super_jump_strength: float = 500.0  # boost when jump is timed with the landing
@export var super_jump_window: float = 0.15     # seconds before landing that counts as "on time"
@export var shockwave_scene: PackedScene  # assign shockwave.tscn in the Inspector
var is_ground_pounding: bool = false
var _pound_cooldown_timer: float = 0.0
var _pound_jump_buffer: float = 0.0  # counts down; >0 means jump was pressed recently
var _knockback_timer: float = 0.0   # movement input suppressed while this is > 0

#damage related variables
var is_ouch: bool = false
@export var ouch_animtime: float = 0.8
var is_ded: bool = false
var is_invincible: bool = false
var _iframes_ouch: bool = false
@export var invincibility_time: float = 1.2

#registering movement input
var move_input: float

var _pause_menu_scene: PackedScene = preload("res://menu.tscn")

#sounds
var groundpound_sfx = preload("res://Assets/sound/groundpound.wav")
var take_damage_sfx = preload("res://Assets/sound/Jalepeanut_ouch.wav")
var dash_sfx = preload("res://Assets/sound/Jalepeanut_damage.wav") # TODO: verify this is the correct audio file for dashing
var coin_sfx = preload("res://Assets/sound/coin.wav")
var jump_sfx = preload("res://Assets/sound/Jalepeanut_Jump.wav")
var ded_sfx = preload("res://Assets/sound/Jalepeanut_Death.wav")
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer

#signals
signal onDamageDealt
signal onHealthChange (hp: int)
signal onScoreUpdate (scoreboard: int)
signal onParth (parthboard: int)

func _ready():
	# restore persistent state from the autoload so score and health carry over between levels
	hp = GameManager.hp
	scoreboard = GameManager.points
	parthboard = GameManager.parth_points
	# push restored values to the UI immediately
	onHealthChange.emit(hp)
	onScoreUpdate.emit(scoreboard)
	onParth.emit(parthboard)


# processes and executes all physics related stuff
func _physics_process(delta):
	#handle cooldown timers
	_update_timers(delta)
	
	# check if dashing or walking
	if not is_dashing:
		# move left towards -x axis and move right towards +x axis
		move_input = Input.get_axis("Move_Left","Move_Right")
		# velocity on x axis as x axis is horizontal
	
	if Input.is_action_just_pressed("SlapDash") and can_dash():
		begin_dash()

	if Input.is_action_just_pressed("GroundPound") and not is_on_floor() \
			and not is_ground_pounding and not is_dashing and _pound_cooldown_timer <= 0:
		begin_ground_pound()

	# store jump intent while ground pounding so landing can check it
	if is_ground_pounding and Input.is_action_just_pressed("Jump"):
		_pound_jump_buffer = super_jump_window

	# decide the appropriate state
	if is_dashing:
		_process_dash(delta)
	else:
		_process_walk(delta)
	# summon movement function
	move_and_slide()
	
	
	if Input.is_action_just_pressed("DEBUG_RESET"):
		_open_pause_menu()

# Normal Movement and Jumping Function
func _process_walk(delta):
	# ground pound in-flight: lock horizontal, keep slamming down; land on contact
	if is_ground_pounding:
		if is_on_floor():
			land_ground_pound()
		else:
			velocity.x = 0
			velocity.y = pound_speed
		return

	# gravity purposes
	if not is_on_floor():
		# this shan't apply when I wanna jump, after jumping sure but when jumping  NOO
		velocity.y += gravity * delta
	
	# suppress movement input briefly after a knockback so it isn't immediately cancelled
	if _knockback_timer > 0:
		_knockback_timer -= delta
	# movement with momentum
	elif move_input != 0:
		# to ensure movement isn't snappy
		velocity.x = lerp(velocity.x, move_input * walk_speed, accel * delta)
	else:
		# brake
		velocity.x = lerp(velocity.x, 0.0, brake * delta)
		
	
	# jumping towards -y axis, falling towards +y axis
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		play_sound(jump_sfx)
		velocity.y = -jumpstrength

# Dash Process
func _process_dash(delta):
	velocity.x = dash * dash_direction 
	velocity.y = 0.0
	if Input.is_action_pressed("Jump"):
		velocity.y = -jumpstrength
	
	

# regarding time
func _update_timers(delta):
	if is_dashing:
		dash_timer -= delta
		if dash_timer <= 0:
			end_dash()
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta
	if _pound_cooldown_timer > 0:
		_pound_cooldown_timer -= delta
	if _pound_jump_buffer > 0:
		_pound_jump_buffer -= delta
	# dash_hitpause_timer is reserved for a future hitpause feature
	#if dash_hitpause_timer > 0:
	#	dash_hitpause_timer -= delta

# check if dashing is possible
func can_dash():
	return dash_cooldown_timer <= 0 and is_on_floor()

# begin the action
func begin_dash():
	is_dashing = true
	play_sound(dash_sfx)
	dash_timer = dash_duration
	dash_cooldown_timer = dash_cooldown

	# pass through destroyable objects and enemies (layer 2) while dashing
	# damage is still handled by the charge Area2D, so detection is unaffected
	collision_mask &= ~2

	# direction of the dash is towards where the player stands
	if move_input != 0:
		dash_direction = sign(move_input)
	else:
		dash_direction = 1 if not animsprite.flip_h else -1

	# hitbox enabling
	charge.monitoring = true

	# play animation
	animsprite.play("slapdash")


# end the action
func end_dash():
	is_dashing = false
	charge.monitoring = false
	collision_mask |= 2  # restore layer 2 collision after dash

# collecting jumpsticks


# processes and executes all non physics related stuff
func _process(delta):
	#animsprite.flip_h = velocity.x < 0
	# velocity.x>0 will check for true or false
	# if it is true due to velocity.x being -1, the sprite will be flipped
	# if it is false due to velocity.x being +1. the sprite won't be flipped
	#abandoned method above due to momentum preventing flip_h to remain true when idle
	
	#new sprite flip code here
	if Input.is_action_pressed("Move_Left"):
		animsprite.flip_h = true
	elif Input.is_action_pressed("Move_Right"):
		animsprite.flip_h = false
	
	
	#contains all other animations
	_manage_animation()

func _manage_animation():
	if is_ouch or _iframes_ouch:
		animsprite.play("ouch")
	else:
		if is_ground_pounding:
			animsprite.play("ground_pound")  # add a "ground_pound" anim to the sprite; falls back to "jump" if missing
			return
		if is_dashing:
			animsprite.play("slapdash")
		else:
			if not is_on_floor():
				#animsprite.play("jumpbeg")
				animsprite.play("jump")
			elif move_input != 0:
				animsprite.play("walk")
			else: 
				animsprite.play("idle")

# taking damage
func take_damage(amount: int):
	if is_ded or is_invincible:
		return
	hp -= amount

	onHealthChange.emit(hp)
	damage_flash()
	play_sound(take_damage_sfx)
	onDamageDealt.emit()

	var knockback_strength = 5.0
	var knockback_dir = sign(velocity.x) if velocity.x != 0 else 1.0
	velocity.x = -knockback_dir * knockback_strength * walk_speed

	GameManager.save_player_health(hp)

	if hp <= 0:
		call_deferred("game_over")
	else:
		_start_invincibility()


# called by enemies to push the player back; suppresses movement input briefly
func apply_knockback(push_velocity: float):
	velocity.x = push_velocity
	_knockback_timer = 0.18  # ~11 frames — long enough to feel the push


# damage flash animation
func damage_flash():
	is_ouch = true
	await get_tree().create_timer(ouch_animtime).timeout
	is_ouch = false


# i-frames: blocks damage and strips enemy collision for invincibility_time seconds
func _start_invincibility():
	is_invincible = true
	_iframes_ouch = true
	var mask_before := collision_mask
	var layer_before := collision_layer
	collision_layer = 0
	collision_mask &= ~(2 | 4)

	# flicker the sprite so the player can see they're protected
	var flicker := create_tween()
	var flicker_count := int(invincibility_time / 0.12)
	for i in flicker_count:
		flicker.tween_property(animsprite, "modulate:a", 0.15, 0.06)
		flicker.tween_property(animsprite, "modulate:a", 1.0, 0.06)
	flicker.tween_property(animsprite, "modulate:a", 1.0, 0.0)

	await get_tree().create_timer(invincibility_time * 0.5).timeout
	_iframes_ouch = false  # ouch animation ends at halfway, normal anims resume

	await get_tree().create_timer(invincibility_time * 0.5).timeout
	is_invincible = false
	collision_layer = layer_before
	collision_mask = mask_before
	animsprite.modulate.a = 1.0

# restoring health
func restore_health(hp_regain: int):
	hp += hp_regain
	if hp >= hp_max:
		hp = hp_max #to prevent overflow
	GameManager.save_player_health(hp)
	onHealthChange.emit(hp)
	print("player hp = ", hp)


# death
func game_over():
	play_sound(ded_sfx)
	await get_tree().create_timer(3).timeout
	is_ded = true
	GameManager.reset()
	get_tree().reload_current_scene()


# dealing damage WITH DASH
func _on_charge_body_entered(body):
	if body.is_in_group("Enemy") or body.is_in_group("Object") or body.is_in_group("Donut"):
		# deal damage
		if body.has_method("take_damage"):
			body.take_damage(damage)
			onDamageDealt.emit()
			

# to transfer score values
func score_display(score: int):
	scoreboard += score
	print(scoreboard)
	onScoreUpdate.emit(scoreboard)

func parth_display(parth: int):
	parthboard += parth
	print("found parth ",parth," times")
	onParth.emit(parthboard)


# to implement sound
func play_sound(sound: AudioStream):
	audio.stream = sound
	audio.play()



# ── Ground Pound ─────────────────────────────────────────────────────────────

func begin_ground_pound():
	is_ground_pounding = true
	velocity.x = 0
	velocity.y = pound_speed
	play_sound(groundpound_sfx)

func land_ground_pound():
	is_ground_pounding = false
	_pound_cooldown_timer = pound_cooldown
	spawn_shockwaves()
	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.85)
	# super jump: triggered if jump was pressed just before landing OR on the exact frame
	if _pound_jump_buffer > 0 or Input.is_action_just_pressed("Jump"):
		velocity.y = -super_jump_strength
		_pound_jump_buffer = 0.0

func spawn_shockwaves():
	if shockwave_scene == null:
		push_warning("GroundPound: shockwave_scene is not assigned in the Inspector.")
		return
	for dir in [-1, 1]:
		var wave = shockwave_scene.instantiate()
		get_parent().add_child(wave)
		wave.global_position = global_position
		wave.direction = dir
		wave.damage = damage


func _open_pause_menu():
	var layer = CanvasLayer.new()
	layer.layer = 10  # render above all game elements
	layer.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	get_tree().root.add_child(layer)
	var menu = _pause_menu_scene.instantiate()
	layer.add_child(menu)
	get_tree().paused = true
