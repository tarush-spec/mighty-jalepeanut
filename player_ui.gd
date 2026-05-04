extends CanvasLayer

# referenced variables
@onready var heart_container: HBoxContainer = $heart_container
@onready var score_text: Label = $score
@onready var parth_container: HBoxContainer = $parth_container
@onready var player = get_parent()




# hearts and parths
var hearts: Array = []
# 0 > 1 HP ; 1 > 2 HP ; 2 > 3 HP ; 3 > 4 HP ; 4 > 5 HP
var parth_array: Array = []

func _ready():
	hearts = heart_container.get_children()
	parth_array = parth_container.get_children()
	print(hearts)
	player.onHealthChange.connect(update_health) # to update health
	player.onScoreUpdate.connect(update_score) # to update standard score
	player.onParth.connect(update_parth) # parth
	
	update_health(player.hp)
	update_score(player.scoreboard)
	update_parth(player.parthboard)

func update_health(hp: int):
	for i in len(hearts):
		hearts[i].visible = i < hp # i starts count from 0

func update_score(score: int):
	score_text.text = str(score)

func update_parth(parth: int):
	for i in len(parth_array):
		parth_array[i].visible = i < parth
