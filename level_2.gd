extends Node2D


# music variables
var Main_Audio: AudioStream = preload("res://Assets/sound/mfcc-retro-arcade-game-music-297305.mp3")

@onready var audio: AudioStreamPlayer = $AudioStreamPlayer

func play_sound(sound: AudioStream):
	audio.stream = sound
	audio.play()

func _ready():
	play_sound(Main_Audio)
