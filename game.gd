extends Node2D

# to play sound and stuff
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
var music1: AudioStream = preload("res://Assets/sound/abydos_music-fun-retro-game-175468_01.wav")
var music2: AudioStream = preload("res://Assets/sound/djartmusic-i-love-my-8-bit-game-console-301272.mp3")
var music3: AudioStream = preload("res://Assets/sound/esesli-platform-8-262410.mp3")
var music4: AudioStream = preload("res://Assets/sound/nickpanekaiassets-energetic-chiptune-video-game-music-platformer-8-bit-318348.mp3")
var music5: AudioStream = preload("res://Assets/sound/aberrantrealities-what-a-whimsy-246166_01.wav")
var cryforhelp: AudioStream = preload("res://Assets/sound/jr cry for help.wav")


func play_sound(sound: AudioStream):
	audio.stream = sound
	audio.play()

func _ready():
	#play_sound(cryforhelp)
	#await get_tree().create_timer(1).timeout
	play_sound(music5)
	#audio.play()
	
