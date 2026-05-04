extends Node2D
# THIS IS FOR CRATES THAT CONTAIN HEALTH

# health
@export var hp: int = 1
@export var hp_player: int = 1

# Counting Scores
@onready var game_manager: Node = %GameManager

# sound
@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
var music_smash: AudioStream = preload("res://Assets/sound/Crate Smash.wav")

# PLAYER REFERENCE
#@onready var player: CharacterBody2D = $"."


func destroyed():
	play_sound(music_smash)
	game_manager.add_point(100)
	# to add particles here later
	queue_free()

func _on_area_2d_body_entered(body):
	if not body.is_in_group("DASH"):
		return
	else:
		if body.is_dashing:
			if body.is_in_group("Player"):
				if body.has_method("restore_health"):
					body.restore_health(hp_player)
			take_damage(body.damage)
		else:
			return

func play_sound(sound: AudioStream):
	audio.stream = sound
	audio.play()


func take_damage(damage_dealt: int):
	hp -= damage_dealt
	if hp <= 0:
		destroyed() # crate smashed
