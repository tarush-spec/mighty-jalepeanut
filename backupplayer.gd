extends CharacterBody2D

const SPEED = 250.0
const JUMP_VELOCITY = -300.0
var CHARGESPEED = SPEED * 1.5
var SPEEDTYPE = SPEED
@onready var animsprite_p1: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision2d: CollisionShape2D = $CollisionShape2D
@onready var charge: CollisionShape2D = $charge

signal slap_dash ()

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta
		if is_on_floor():
			animsprite_p1.play("jumpend")

	# Handle jump.
	if Input.is_action_just_pressed("Jump") and is_on_floor():
		animsprite_p1.play("jumpbeg")
		velocity.y = JUMP_VELOCITY
		
		if not is_on_floor():
			animsprite_p1.play("jump")
	
	#slap
	if Input.is_action_pressed("SlapDash"):
		#emit_signal("slap_dash")
		SPEEDTYPE = CHARGESPEED
		charge.disabled = false
	if Input.is_action_just_released("SlapDash"):
		SPEEDTYPE = SPEED
		charge.disabled = true
	

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("Move_Left", "Move_Right")
	
	if direction > 0:
		animsprite_p1.flip_h = false
	elif direction < 0:
		animsprite_p1.flip_h = true
	if is_on_floor():
		if Input.is_action_pressed("SlapDash"):
			animsprite_p1.play("slapdash")
		else:
			if direction == 0:
				animsprite_p1.play("idle")
			else:
				animsprite_p1.play("walk")
	else:
		if Input.is_action_pressed("SlapDash"):
			animsprite_p1.play("slapdash")
		else:
			animsprite_p1.play("jump")
	
	if direction:
		velocity.x = direction * SPEEDTYPE
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()

#Losing Health and Dying
