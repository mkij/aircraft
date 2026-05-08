extends Area2D

const BULLET_SPEED = 850.0
const GRAVITY = 280.0

var velocity = Vector2.ZERO
var lifetime = 5.0

func _ready():
	add_to_group("player_bullet")

func setup(player_velocity: Vector2, shoot_direction: Vector2):
	velocity = shoot_direction * BULLET_SPEED + player_velocity

func _physics_process(delta):
	lifetime -= delta
	if lifetime <= 0:
		queue_free()
		return
	velocity.y += GRAVITY * delta
	position += velocity * delta
	rotation = velocity.angle()
	if position.y > 2000 or position.y < -2000:
		queue_free()

func _on_area_entered(area):
	queue_free()
