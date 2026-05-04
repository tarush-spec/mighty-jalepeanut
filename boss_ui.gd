extends CanvasLayer
# referenced variables
@onready var health_container: HBoxContainer = $HBoxContainer
@onready var clowndiment = get_parent()

# health bar visual variables
var hearts: Array = []
# counts from 0 onwards, so 5 hearts will be stored as [0,1,2,3,4]



# Called when the node enters the scene tree for the first time.
func _ready():
	hearts = health_container.get_children()
	# to bring the boss hp onto this array
	
	clowndiment.onHealthChange.connect(update_health)
	update_health(clowndiment.hp)

func update_health(hp: int):
	for i in len(hearts):
		hearts[i].visible = i < hp
