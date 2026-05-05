extends Area2D

## Shockwave spawned by the ground pound on landing.
## Travels horizontally left or right, damages enemies, crates, and projectiles
## it touches once, then fades out over its lifetime.
##
## Scene setup (shockwave.tscn):
##   Area2D  ← root, this script attached
##     CollisionShape2D  ← RectangleShape2D, wide and short (e.g. 40×16)
##                          collision_layer = 0  (collision_mask set in _ready)
##     Sprite2D / AnimatedSprite2D  ← your shockwave visual

@export var speed: float = 380.0      # horizontal travel speed
@export var lifetime: float = 0.55    # seconds before the wave disappears
@export var damage: int = 1           # set by the player at spawn time

var direction: int = 1                # -1 = left, +1 = right, set at spawn
var _elapsed: float = 0.0
var _hit_bodies: Array = []           # tracks who has already been hit — one hit per target

@onready var _sprite = _find_sprite()


func _ready():
	# layer 2 (value 2) = crates/objects   layer 4 (value 4) = enemies & projectile
	collision_mask = 6
	# connect signals here so no manual wiring is needed in the scene editor
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)
	# flip visual to match travel direction
	if _sprite:
		_sprite.flip_h = direction < 0


func _process(delta):
	_elapsed += delta

	# travel horizontally
	global_position.x += speed * direction * delta

	# fade out smoothly over the lifetime
	modulate.a = 1.0 - (_elapsed / lifetime)

	if _elapsed >= lifetime:
		queue_free()


func _on_body_entered(body: Node2D):
	# crate RigidBody2Ds carry no group — walk up to the root Node2D which has
	# the "Object"/"Explodable" groups and the take_damage method
	var target: Node = body if body.has_method("take_damage") else body.get_parent()
	if target == null or target in _hit_bodies:
		return
	if target.is_in_group("Enemy") or target.is_in_group("Object") or target.is_in_group("Explodable"):
		_hit_bodies.append(target)
		target.take_damage(damage)


func _on_area_entered(area: Area2D):
	# catches the boss projectile — it is an Area2D so body_entered never fires for it
	if area.is_in_group("Enemy") and area not in _hit_bodies:
		_hit_bodies.append(area)
		if area.has_method("rebound_to_boss"):
			area.rebound_to_boss()  # send it back at the boss
		elif area.has_method("take_damage"):
			area.take_damage(damage)
		else:
			area.queue_free()


# supports both AnimatedSprite2D and Sprite2D in the scene
func _find_sprite() -> Node:
	if has_node("AnimatedSprite2D"):
		return $AnimatedSprite2D
	elif has_node("Sprite2D"):
		return $Sprite2D
	return null
