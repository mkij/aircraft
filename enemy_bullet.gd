extends Area2D

const SPEED = 850.0
const GRAVITY = 280.0
var velocity = Vector2.ZERO
var lifetime = 5.0

func setup(direction: Vector2):
	velocity = direction * SPEED
	rotation = direction.angle()

func _process(delta):
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	velocity.y += GRAVITY * delta
	position += velocity * delta
	rotation = velocity.angle()
	if position.y > 2000 or position.y < -2000:
		queue_free()

func _on_body_entered(body):
	if body.has_method("take_damage"):
		body.take_damage()
	queue_free()