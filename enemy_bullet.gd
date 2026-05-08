extends Area2D

const SPEED = 500.0
var velocity = Vector2.ZERO

func setup(direction: Vector2):
    velocity = direction * SPEED
    rotation = direction.angle()

func _process(delta):
    position += velocity * delta
    if position.x < -100 or position.x > 1300 or position.y < -100 or position.y > 750:
        queue_free()

func _on_body_entered(body):
    if body.has_method("take_damage"):
        body.take_damage()
    queue_free()
