extends Area2D

# visual variables
@onready var animsprite: AnimatedSprite2D = $AnimatedSprite2D

# for teleporting
@export var destination_pos: Vector2
@export var activate_teleport: String = "Interact"
var player_in_range: bool = false


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	animsprite.visible = false

# when player enters the area
func _on_body_entered(body):
	if body.is_in_group("Player"):
		player_in_range = true
		animsprite.visible = true

# when player leaves the area
func _on_body_exited(body):
	if body.is_in_group("Player"):
		player_in_range = false
		animsprite.visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player_in_range and Input.is_action_just_pressed("Enter_Door"):
		var player = get_tree().get_nodes_in_group("Player")[0]
		if player:
			await get_tree().create_timer(0.2).timeout
			# to teleport to the destination
			player.global_position = destination_pos
