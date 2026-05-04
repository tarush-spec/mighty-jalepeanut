extends Node2D

# health
@export var hp: int = 1
@export var recoil: int = 30
@export var damage: int = 2

# destruction
@onready var destruct_zone: Area2D = $Destruct_Zone
var is_exploding: bool = false

# animated sprite
@onready var animsprite: AnimatedSprite2D = $AnimatedSprite2D


# Counting Scores
@onready var game_manager: Node = %GameManager
@export var score_value: int = 100

# signals
signal onCrateCrashed

func _ready():
	destruct_zone.monitorable = false
	destruct_zone.monitoring = false

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
	elif body.is_in_group("Explodable"):
		if body.is_exploding:
			take_damage(body.damage * 10)
	elif body.is_in_group("CRASH"):
		if body.has_method("crash_despawn"):
			if body.is_crashing:
				body.crash_despawn(recoil)
				game_manager.add_point(score_value/2)
				take_damage(body.damage)

func go_kaboom():
	is_exploding = true
	destruct_zone.monitoring = true
	for body in destruct_zone.get_overlapping_bodies():
		if body.is_in_group("Explodable") or body.is_in_group("Player"):
			if body.has_method("take_damage"):
				body.take_damage(damage)
		if body.is_in_group("Enemy"):
			if body.has_method("crash_despawn"):
				body.crash_despawn(damage * recoil)
		destroyed()



func take_damage(damage_dealt: int):
	hp -= damage_dealt
	onCrateCrashed.emit()
	if hp <= 0:
		go_kaboom()
