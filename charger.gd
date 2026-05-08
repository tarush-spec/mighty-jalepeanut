extends CharacterBody2D

## Charger Enemy
## Patrols until the player enters its eye zone, then chases and deals contact damage.
## Ground pound shockwave flips it (stunned/vulnerable). A dash while stunned triggers crash.
##
## Scene setup (charger.tscn):
##   CharacterBody2D  ← root, collision_layer=4, collision_mask=7, groups=["Enemy"]
##     CollisionShape2D      ← main body shape
##     AnimatedSprite2D      ← animations: "walk", "chase", "stunned", "crash"
##     AudioStreamPlayer
##     EyeZone (Area2D)      ← wide rectangle in front, collision_mask=1 (player layer)
##       CollisionShape2D    ← e.g. RectangleShape2D 200×60, offset forward
##     DamageArea (Area2D)   ← contact damage zone, collision_layer=4, collision_mask=1
##       CollisionShape2D    ← similar size to body

enum State { PATROL, CHASE, STUNNED, CRASHING }

# node refs
@onready var animsprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var eye_zone: Area2D = $EyeZone
@onready var damage_area: Area2D = $DamageArea
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer

# stats
@export var patrol_speed: float = 60.0
@export var chase_speed: float = 180.0
@export var damage: int = 1
@export var hp: int = 2
@export var hp_crash: int = 60
@export var stun_duration: float = 3.5  # seconds before it recovers from stun on its own

# sounds
var sfx_aggro: AudioStream
var sfx_hit: AudioStream = preload("res://Assets/sound/Clowndiment Hit.wav")
var sfx_crash: AudioStream = preload("res://Assets/sound/enemy hit.wav")

# state
var state: State = State.PATROL
var direction: int = -1
var _player: Node2D = null
var _stun_timer: float = 0.0
var _crash_hit: Array = []
var _crash_direction: int = 1
var _hitpause_timer: float = 0.0
var _hit_player: bool = false   # prevents repeated damage while player stays inside area
var is_crashing: bool = false


func _ready():
	add_to_group("Enemy")
	eye_zone.body_entered.connect(_on_eye_zone_body_entered)
	eye_zone.body_exited.connect(_on_eye_zone_body_exited)
	damage_area.body_entered.connect(_on_damage_area_body_entered)


func _physics_process(delta):
	_apply_gravity(delta)

	if _hitpause_timer > 0:
		_hitpause_timer -= delta
		velocity.x = -direction * chase_speed * 0.6  # recoil away from player
		move_and_slide()
		return

	match state:
		State.PATROL:  _patrol()
		State.CHASE:   _chase()
		State.STUNNED: _stunned(delta)
		State.CRASHING:_crashing()

	# poll the damage area every frame — catches the player already inside and
	# works even if the body_entered signal isn't wired in the scene
	if state != State.STUNNED and state != State.CRASHING:
		var player_overlapping: bool = false
		for body in damage_area.get_overlapping_bodies():
			if body.is_in_group("Player"):
				player_overlapping = true
				if not body.is_dashing and not _hit_player:
					_hit_player = true
					body.take_damage(damage)
					var push_dir: float = sign(body.global_position.x - global_position.x)
					if body.has_method("apply_knockback"):
						body.apply_knockback(push_dir * 350.0)
					_hitpause_timer = 0.15
		if not player_overlapping:
			_hit_player = false

	move_and_slide()
	_manage_animation()


# ── Movement states ───────────────────────────────────────────────────────────

func _patrol():
	velocity.x = patrol_speed * direction
	if is_on_wall():
		direction = -direction
	animsprite.flip_h = direction > 0


func _chase():
	if not is_instance_valid(_player):
		_return_to_patrol()
		return
	# always face and move toward the player
	direction = sign(_player.global_position.x - global_position.x)
	velocity.x = chase_speed * direction
	animsprite.flip_h = direction > 0


func _stunned(delta):
	
	velocity.x = 0
	_stun_timer -= delta
	if _stun_timer <= 0:
		_recover_from_stun()


func _crashing():
	velocity.x = chase_speed * 3.0 * _crash_direction
	crash_despawn(1)
	_hurt_nearby_enemies()


# ── Damage intake ─────────────────────────────────────────────────────────────

# called by the player's dash (charge area) and other normal hits
func take_damage(amount: int):
	if state == State.CRASHING:
		return
	if state == State.STUNNED:
		# dash while flipped → crash
		_enter_crash()
		return
	hp -= amount
	_play(sfx_hit)
	if hp <= 0:
		_enter_crash()


# called exclusively by the ground pound shockwave
func take_ground_pound_damage(_amount: int):
	if state == State.STUNNED or state == State.CRASHING:
		return
	_enter_stun()


# ── State transitions ─────────────────────────────────────────────────────────

func _enter_stun():
	state = State.STUNNED
	_stun_timer = stun_duration
	velocity = Vector2.ZERO
	animsprite.flip_v = true   # flip upside down visually


func _recover_from_stun():
	animsprite.flip_v = false
	if is_instance_valid(_player):
		state = State.CHASE
	else:
		_return_to_patrol()


func _return_to_patrol():
	state = State.PATROL
	_player = null


func _enter_crash():
	state = State.CRASHING
	is_crashing = true
	animsprite.flip_v = false
	set_deferred("collision_mask", 0)
	damage_area.monitoring = false
	damage_area.monitorable = false
	# fling AWAY from the player — opposite of where they are
	if is_instance_valid(_player):
		_crash_direction = -sign(_player.global_position.x - global_position.x)
	else:
		_crash_direction = -direction
	velocity = Vector2(chase_speed * 3.0 * _crash_direction, -200)
	GameManager.add_point(300)


# ── Crash helpers ─────────────────────────────────────────────────────────────

func crash_despawn(crash_time: int):
	hp_crash -= crash_time
	if hp_crash <= 0:
		GameManager.add_point(300)
		queue_free()


func _hurt_nearby_enemies():
	for enemy in get_tree().get_nodes_in_group("Enemy"):
		if enemy == self or enemy in _crash_hit:
			continue
		if global_position.distance_to(enemy.global_position) <= 50.0:
			_crash_hit.append(enemy)
			if enemy.has_method("take_damage"):
				enemy.take_damage(damage)


# ── Area2D callbacks ──────────────────────────────────────────────────────────

func _on_eye_zone_body_entered(body: Node2D):
	if body.is_in_group("Player") and state == State.PATROL:
		_player = body
		state = State.CHASE
		_play(sfx_aggro)


func _on_eye_zone_body_exited(body: Node2D):
	if body.is_in_group("Player") and state == State.CHASE:
		# keep chasing for a moment even after the player leaves the zone
		_player = body  # hold reference until we lose it naturally
		# optionally: add a "leash" timer here to stop chasing after X seconds


func _on_damage_area_body_entered(body: Node2D):
	if state == State.STUNNED or state == State.CRASHING:
		return
	if body.is_in_group("Player") and not body.is_dashing:
		body.take_damage(damage)
		var push_dir = sign(body.global_position.x - global_position.x)
		if body.has_method("apply_knockback"):
			body.apply_knockback(push_dir * 350.0)
		_hitpause_timer = 0.15


# ── Helpers ───────────────────────────────────────────────────────────────────

func _apply_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta


func _manage_animation():
	match state:
		State.PATROL:   animsprite.play("walk")
		State.CHASE:    animsprite.play("chase")
		State.STUNNED:  animsprite.play("stunned")
		State.CRASHING: animsprite.play("crash")


func _play(sfx: AudioStream):
	audio.stream = sfx
	audio.play()
