extends Area2D
@onready var timer: Timer = $Timer



# Called when the node enters the scene tree for the first time.


func _on_body_entered(_body: Node2D):
	
	print("YOU DIED!")
	Engine.time_scale = 0.25
	timer.start()


func _on_timer_timeout() -> void:
	Engine.time_scale = 1.0
	get_tree().reload_current_scene()
