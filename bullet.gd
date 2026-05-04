extends Area2D

@export var speed : float = 300.0
@export var damage : int = 1
@export var lifetime : float = 3.0

var direction : Vector2 = Vector2.LEFT

func _ready():
	# destroys bullet after lifetime over
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta):
	# to move
	position += direction * speed * delta

func _on_body_entered(body):
	if body.is_in_group("Player") or body.is_in_group("Enemy"):
		if body.get("is_dashing"):
			direction = direction * -1
			lifetime = 10.0
		else:
			if body.has_method("take_damage"):
				body.take_damage(damage)
			queue_free()
	
