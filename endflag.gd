extends Area2D

@export var next_scene: PackedScene #for next level
@onready var animsprite: AnimatedSprite2D = $AnimatedSprite2D

# Called when the node enters the scene tree for the first time.
func _on_body_entered(body):
	if not body.is_in_group("Player"):
		return
	
	# Next Level Loading
	get_tree().change_scene_to_packed(next_scene)
