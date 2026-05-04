extends Camera2D

var shake_intensity: int = 0
@export var shake_decay: int = 1
@export var intensity: int = 3 # for stronger weaker shake

@onready var player: CharacterBody2D = $".."
@onready var crate: Node2D = $"."


func _ready():
	
	if player:
		player.onDamageDealt.connect(start_shake)
		print("SIGNAL CONNECTED")
	


func start_shake():
	shake_intensity = intensity

func random_offset() -> Vector2:
	var x = randf_range(offset.x - shake_intensity, offset.x + shake_intensity)
	var y = randf_range(offset.y - shake_intensity, offset.y + shake_intensity)
	return Vector2(x,y)

func _process(delta):
	if shake_intensity > 0: # this is why shake_intensity and intensity are diff var
		shake_intensity = lerp(shake_intensity, 0, shake_decay * delta)
		
		offset = random_offset()
	else:
		#pass
		offset = Vector2(101.985,-93.355) # Reset shake
