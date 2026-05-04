extends Node2D

#variables for sound
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
var bossbattle: AudioStream = preload("res://Assets/sound/ihatetuesdays-video-game-boss-fiight-259885.wav")
@onready var player: CharacterBody2D = $Player


func play_sound(sound: AudioStream):
	audio.stream = sound
	audio.play()

func _ready():
	
	play_sound(bossbattle)
