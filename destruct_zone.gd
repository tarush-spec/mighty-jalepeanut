extends Area2D

@onready var tnt_crate: Node2D = get_parent() #parent
@export var destruction: int = 3 #explosion damage
signal onExplode

# Called when the node enters the scene tree for the first time.
