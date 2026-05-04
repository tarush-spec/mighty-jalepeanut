extends CharacterBody2D

var ACCEL: float = 250.0
var SPEED: float = 250.0
const JUMP_VELOCITY: float = -300.0
var CHARGESPEED: float = SPEED * 2.0 
var SPEEDTYPE: float = SPEED

@export var dash_knockback: float = 600.0  # Force applied to enemies
@export var topple_force: float = 1200.0 #Force applied to destroy property coz fuck em
@onready var animsprite_p1: AnimatedSprite2D = $AnimatedSprite2D
@onready var charge_area: Area2D = $charge
@onready var chargecollision: CollisionShape2D = $charge/chargecollision


var is_dashing = false
var dash_direction = 0



func _ready() -> void:
	# Ensure the hitbox is off by default
	chargecollision.disabled = true

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle SlapDash Input
	if Input.is_action_just_pressed("SlapDash"):
		is_dashing = true
		chargecollision.disabled = false
		# Lock direction based on sprite flip
		dash_direction = -1 if animsprite_p1.flip_h else 1
		
	if Input.is_action_just_released("SlapDash"):
		stop_dash()

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	# Movement Logic
	var direction := Input.get_axis("Move_Left", "Move_Right")
	
	#slapdash dash mechanic
	if is_dashing:
		velocity.x = dash_direction * CHARGESPEED
		animsprite_p1.play("slapdash")
	else:
		if direction:
			velocity.x = direction * SPEED
			animsprite_p1.play("walk")
			animsprite_p1.flip_h = direction < 0
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)
			animsprite_p1.play("idle")
			
		if not is_on_floor():
			animsprite_p1.play("jump")

	move_and_slide()

func stop_dash():
	is_dashing = false
	chargecollision.disabled = true

# Connect this via the Node Signal "body_entered" from your Area2D
func _on_charge_body_entered(body: Node2D) -> void:
	#buildings
	if body.is_in_group("Toppleable") or body is RigidBody2D:
		var local_impact_vector = global_position - body.global_position
		var impact_point = body.global_position - global_position
		var force = Vector2(dash_direction * topple_force * -200)
		body.apply_impulse(force, local_impact_vector)
	#enemies
	if body.is_in_group("Enemies") or body.has_method("apply_knockback"):
		# Calculate knockback (Forward and slightly upward)
		var knockback_vector = Vector2(dash_direction * dash_knockback, -150)
		
		if body.has_method("apply_knockback"):
			body.apply_knockback(knockback_vector)
		
		if body.has_method("take_damage"):
			body.take_damage(1)
