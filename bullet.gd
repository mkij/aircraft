extends Area2D

const BULLET_SPEED = 800.0
const GRAVITY = 280.0

var velocity = Vector2.ZERO

func setup(player_velocity: Vector2, shoot_direction: Vector2):
    velocity = shoot_direction * BULLET_SPEED + player_velocity

func _physics_process(delta):
    velocity.y += GRAVITY * delta
    position += velocity * delta
    rotation = velocity.angle()

    if position.x > 1300 or position.x < -100 or position.y > 700 or position.y < -100:
        queue_free()

func _on_area_entered(area):
    queue_free()
