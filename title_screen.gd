extends Control



	




func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://game.tscn")


func _on_controls_pressed() -> void:
	get_tree().change_scene_to_file("res://controls.tscn")
