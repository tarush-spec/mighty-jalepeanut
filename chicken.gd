extends Area2D

@onready var game_manager: Node = %GameManager
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
var coin_sfx = preload("res://Assets/sound/coin.wav")

# Called when the node enters the scene tree for the first time.

func play_sound(sound: AudioStream):
	audio.stream = sound
	audio.play()

func _on_body_entered(body):
	
	play_sound(coin_sfx)
	game_manager.add_point(1)
	queue_free()
