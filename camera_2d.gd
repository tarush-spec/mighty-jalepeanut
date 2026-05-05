extends Camera2D

# Trauma-based screen shake.
# trauma is added on events and decays over time.
# Actual shake intensity = trauma^2, so small trauma barely registers
# and large trauma hits hard — consecutive hits accumulate nicely.

var trauma: float = 0.0

@export var trauma_decay: float = 1.2          # how fast trauma fades per second
@export var trauma_on_deal: float = 0.6        # trauma added when player hits something
@export var trauma_on_take_damage: float = 0.9  # trauma added when player takes damage

@export var max_offset_x: float = 28.0        # max horizontal pixel shake
@export var max_offset_y: float = 20.0        # max vertical pixel shake
@export var max_rotation_deg: float = 3.5     # max rotation shake in degrees

@onready var player: CharacterBody2D = $".."
var _base_offset: Vector2
var _locked_position: Vector2
# read from player.camera_follow so it can be toggled per scene from the player Inspector
var follow_player: bool = true


func _ready():
	_base_offset = offset
	if player:
		follow_player = player.camera_follow
		player.onDamageDealt.connect(_on_player_dealt_damage)
		player.onHealthChange.connect(_on_player_health_change)
	if not follow_player:
		# top_level makes the camera use global coordinates,
		# ignoring the parent (player) transform entirely
		top_level = true
		await get_tree().process_frame  # wait one frame so positions are fully resolved
		# anchor to the player's spawn position so the camera centres on the room entry
		# rather than drifting to world origin (0,0)
		_locked_position = player.global_position


func _on_player_dealt_damage():
	add_trauma(trauma_on_deal)


func _on_player_health_change(_hp: int):
	add_trauma(trauma_on_take_damage)


func add_trauma(amount: float):
	trauma = minf(trauma + amount, 1.0)


func _process(delta):
	if trauma > 0.0:
		trauma = maxf(trauma - trauma_decay * delta, 0.0)
		var shake := trauma * trauma  # squared curve for better feel

		# sine waves at co-prime frequencies produce smooth, non-repeating motion
		var t := Time.get_ticks_msec() * 0.001
		var shake_offset := Vector2(
			max_offset_x * shake * sin(t * 43.0),
			max_offset_y * shake * sin(t * 29.0)
		)
		rotation_degrees = max_rotation_deg * shake * sin(t * 37.0)

		if follow_player:
			offset = _base_offset + shake_offset
		else:
			global_position = _locked_position + shake_offset
	else:
		rotation_degrees = 0.0
		if follow_player:
			offset = _base_offset
		else:
			global_position = _locked_position
