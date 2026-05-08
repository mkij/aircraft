extends CharacterBody2D

const SPEED = 400.0
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOMB_SCENE = preload("res://Bomb.tscn")
const SCREEN_W = 1152.0
const SCREEN_H = 648.0
const SHOOT_COOLDOWN = 0.08
const BOMB_COOLDOWN = 1.0
const GRAVITY = 280.0

var hp = 3
var shoot_timer = 0.0
var bomb_timer = 0.0

func _physics_process(delta):
	shoot_timer -= delta
	bomb_timer -= delta

	var direction = Vector2.ZERO

	if Input.is_action_pressed("ui_right"):
		direction.x += 1
	if Input.is_action_pressed("ui_left"):
		direction.x -= 1
	if Input.is_action_pressed("ui_up"):
		direction.y -= 1
	if Input.is_action_pressed("ui_down"):
		direction.y += 1

	velocity = direction.normalized() * SPEED if direction != Vector2.ZERO else Vector2.ZERO
	move_and_slide()

	if velocity.length() > 10:
		rotation = velocity.angle()

	position.x = clamp(position.x, 20, SCREEN_W - 20)
	position.y = clamp(position.y, 20, SCREEN_H - 20)

	queue_redraw()

	if Input.is_action_pressed("ui_accept"):
		shoot()

func _draw():
	var shoot_dir = Vector2.RIGHT.rotated(rotation)
	var bullet_vel = shoot_dir * 800.0 + velocity
	var points = _calculate_trajectory(bullet_vel)
	for i in range(points.size() - 1):
		var alpha = 1.0 - float(i) / points.size()
		var p1 = points[i].rotated(-rotation)
		var p2 = points[i + 1].rotated(-rotation)
		draw_line(p1, p2, Color(1, 0.8, 0, alpha), 1.5)

func _calculate_trajectory(initial_velocity: Vector2) -> Array:
	var points = []
	var pos = Vector2.ZERO
	var vel = initial_velocity
	var dt = 0.05
	for i in range(60):
		points.append(pos)
		vel.y += GRAVITY * dt
		pos += vel * dt
		if pos.y > SCREEN_H - position.y or pos.y < -position.y:
			break
	return points

func _input(event):
	if event is InputEventKey and event.keycode == KEY_CTRL and event.pressed:
		drop_bomb()

func shoot():
	if shoot_timer > 0:
		return
	shoot_timer = SHOOT_COOLDOWN
	var bullet = BULLET_SCENE.instantiate()
	bullet.position = global_position
	var shoot_dir = Vector2.RIGHT.rotated(rotation)
	bullet.setup(velocity, shoot_dir)
	get_parent().add_child(bullet)

func drop_bomb():
	if bomb_timer > 0:
		return
	bomb_timer = BOMB_COOLDOWN
	var bomb = BOMB_SCENE.instantiate()
	bomb.position = global_position
	bomb.setup(velocity)
	get_parent().add_child(bomb)

func take_damage():
	hp -= 1
	get_parent().update_hp(hp)
	if hp <= 0:
		get_parent().game_over()
		queue_free()
