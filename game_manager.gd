extends Node
var points: int = 0
var parth_points: int = 0
@onready var player: CharacterBody2D = $"../Player"

#signal OnUpdateScore (score: int)
#signal OnUpdateParth (score: int)

# Chicken
func add_point(amount: int):
	points += amount
	#print(points)
	#player.score_display(points) # this could create points combo
	player.score_display(amount)

# Parth
func parth(parthcoin: int):
	parth_points += parthcoin
	add_point(10000)
	player.parth_display(parthcoin)
	#print("found Parth, ", parth_points, " times.")
	
