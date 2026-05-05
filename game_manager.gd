extends Node

# Persistent game state.
# Register this script as an Autoload in:
#   Project > Project Settings > Autoload
#   Path: res://game_manager.gd   Name: GameManager
# This makes it survive scene transitions and accessible globally as "GameManager".

var points: int = 0
var parth_points: int = 0
var hp: int = 3
var hp_max: int = 5


# Add score and forward the display to the player UI if a player exists in the scene
func add_point(amount: int):
	points += amount
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("score_display"):
		player.score_display(amount)


# Parth collectible found
func parth(parthcoin: int):
	parth_points += parthcoin
	add_point(10000)
	var player = get_tree().get_first_node_in_group("Player")
	if player and player.has_method("parth_display"):
		player.parth_display(parthcoin)


# Called by the player whenever hp changes so it persists across scenes
func save_player_health(new_hp: int):
	hp = new_hp


# Called on game over — wipes all persistent state so the next run starts fresh
func reset():
	points = 0
	parth_points = 0
	hp = 3
