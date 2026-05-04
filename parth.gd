extends Node2D

@onready var game_manager: Node = %GameManager



func _on_area_2d_body_entered(body):
	if body.is_in_group("Player"):
		game_manager.parth(1)
		queue_free()
