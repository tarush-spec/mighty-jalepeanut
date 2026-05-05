## ground_pound.gd
## ─────────────────────────────────────────────────────────────────────────────
## STANDALONE REFERENCE — not attached to the player yet.
## When ready to integrate into player1.gd, each section is clearly marked.
## You will also need to:
##   • Create shockwave.tscn (Area2D root, CollisionShape2D, Sprite2D/AnimatedSprite2D)
##   • Attach shockwave.gd to it
##   • Add a "GroundPound" input action in Project Settings → Input Map
##   • Add a "ground_pound" animation to the player's AnimatedSprite2D
## ─────────────────────────────────────────────────────────────────────────────

## ── 1. VARIABLES — add these to the top of player1.gd ───────────────────────
##
## # ground pound
## @export var pound_speed: float = 900.0          # downward slam velocity
## @export var pound_cooldown: float = 0.8         # seconds before can pound again
## @export var shockwave_scene: PackedScene        # assign shockwave.tscn in Inspector
## var is_ground_pounding: bool = false
## var _pound_cooldown_timer: float = 0.0
## ────────────────────────────────────────────────────────────────────────────


## ── 2. INPUT — add inside _physics_process, after the dash check ─────────────
##
## if Input.is_action_just_pressed("GroundPound") and not is_on_floor() \
##         and not is_ground_pounding and _pound_cooldown_timer <= 0:
##     begin_ground_pound()
## ────────────────────────────────────────────────────────────────────────────


## ── 3. TIMER — add inside _update_timers ────────────────────────────────────
##
## if _pound_cooldown_timer > 0:
##     _pound_cooldown_timer -= delta
## ────────────────────────────────────────────────────────────────────────────


## ── 4. LANDING DETECTION — add at the top of _process_walk ──────────────────
##
## if is_ground_pounding and is_on_floor():
##     land_ground_pound()
##     return
## ────────────────────────────────────────────────────────────────────────────


## ── 5. ANIMATION — add to _manage_animation, before the dashing check ────────
##
## if is_ground_pounding:
##     animsprite.play("ground_pound")
##     return
## ────────────────────────────────────────────────────────────────────────────


## ── 6. FUNCTIONS — add these anywhere in player1.gd ─────────────────────────

extends Node  # placeholder so the file is valid GDScript — remove when integrating

@export var pound_speed: float = 900.0
@export var pound_cooldown: float = 0.8
@export var shockwave_scene: PackedScene
var is_ground_pounding: bool = false
var _pound_cooldown_timer: float = 0.0


func begin_ground_pound():
	is_ground_pounding = true
	velocity.x = 0              # halt horizontal movement mid-air for a clean slam
	velocity.y = pound_speed    # blast downward


func land_ground_pound():
	is_ground_pounding = false
	_pound_cooldown_timer = pound_cooldown
	spawn_shockwaves()
	# camera shake on impact — reuses the existing shake helper
	var cam = get_viewport().get_camera_2d()
	if cam and cam.has_method("add_trauma"):
		cam.add_trauma(0.85)


func spawn_shockwaves():
	if shockwave_scene == null:
		push_warning("GroundPound: shockwave_scene is not assigned in the Inspector.")
		return
	# spawn one wave going left and one going right from the player's feet
	for dir in [-1, 1]:
		var wave = shockwave_scene.instantiate()
		get_parent().add_child(wave)
		wave.global_position = global_position
		wave.direction = dir
		wave.damage = damage   # inherits player's current damage value
