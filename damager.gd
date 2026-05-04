extends Node
@onready var hp: health = %HP
@export var damage: int

func dealdamage():
	hp.take_damage(damage)

func _on_body_entered(body: Node2D):
	if has_node("%HP"):
		dealdamage()
