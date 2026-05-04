extends Node2D

# sound

@onready var audio: AudioStreamPlayer = $AudioStreamPlayer
var music_smash: AudioStream = preload("res://Assets/sound/Crate Smash.wav")

# health
@export var hp: int = 1
@export var recoil: int = 20

# Counting Scores
@onready var game_manager: Node = %GameManager
@export var score_value: int = 100

# Particles Stuff


# signals
signal onCrateCrashed


func destroyed():
	
	game_manager.add_point(score_value)
	# to add particles here later
	queue_free()


func _on_area_2d_body_entered(body):
	if not body.is_in_group("DASH") and not body.is_in_group("CRASH") and not body.is_in_group("Explodable"):
		return
	elif body.is_in_group("DASH"):
		if body.is_dashing:
			take_damage(body.damage)
		else:
			return
	elif body.is_in_group("CRASH"):
		if body.has_method("crash_despawn"):
			if body.is_crashing:
				body.crash_despawn(recoil)
				game_manager.add_point(score_value/2)
				take_damage(body.damage)

# to play sound
func play_sound(sound: AudioStream):
	audio.stream = sound
	audio.play()

# to take damage
func take_damage(damage_dealt: int):
	hp -= damage_dealt
	play_sound(music_smash)
	onCrateCrashed.emit()
	if hp <= 0:
		destroyed() # crate smashed
