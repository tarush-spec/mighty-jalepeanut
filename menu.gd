extends Control

func _ready():
	process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

	# dim the game behind the menu
	var bg = ColorRect.new()
	bg.color = Color(0, 0, 0, 0.65)
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)
	move_child(bg, 0)  # push behind the buttons

	# wait one frame so VBoxContainer has its final size, then center it
	await get_tree().process_frame
	var vp := get_viewport_rect().size
	$VBoxContainer.position = Vector2(vp.x * 0.15, (vp.y - $VBoxContainer.size.y) / 2.0)

	$VBoxContainer/Resume.pressed.connect(_on_resume)
	$VBoxContainer/Retry.pressed.connect(_on_retry)
	$VBoxContainer/Return.pressed.connect(_on_return)


func _on_resume():
	get_tree().paused = false
	get_parent().queue_free()


func _on_retry():
	get_tree().paused = false
	GameManager.reset()
	get_parent().queue_free()
	get_tree().reload_current_scene()


func _on_return():
	get_tree().paused = false
	GameManager.reset()
	get_parent().queue_free()
	get_tree().change_scene_to_file("res://title_screen.tscn")
