class_name health
extends Node

signal on_change (currenthp: int, fullhp: int)
signal on_take_damage ()
signal on_die ()

enum postdie {DestroyNode, RestartScene}

var currenthp: int
@export var fullhp: int = 5
@export var postdieantics: postdie

func _ready():
	currenthp = fullhp
	pass
func die():
	on_die.emit()
	if postdieantics == postdie.DestroyNode:
		get_parent().queue_free()
	elif postdieantics == postdie.RestartScene:
		get_tree().reload_current_scene()
func take_damage(amount: int):
	currenthp -= amount
	on_change.emit(currenthp,fullhp)
	on_take_damage.emit(currenthp,fullhp)
	if currenthp <= 0:
		die()
func restore_health(amount: int):
	currenthp += amount
	on_change.emit(currenthp,fullhp)
	on_take_damage.emit(currenthp,fullhp)
	if currenthp >= fullhp:
		currenthp = fullhp
