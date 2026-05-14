extends CharacterBody2D

const PASSIVE_SPEED = 220.0
const MAX_SPEED = 320.0
const MIN_SPEED = 50.0
const GRAVITY_EFFECT = 120.0
const SPEED_DAMPING = 1.5
const SHOT_ROTATION_RECOVERY = 4.5
const STALL_SPEED = 80.0
const STALL_FRAMES = 40
const STALL_RECOVERY_TIME = 3.0
const TURN_SPEED = 3.0
const BULLET_SCENE = preload("res://Bullet.tscn")
const BOMB_SCENE = preload("res://Bomb.tscn")
const SHOOT_COOLDOWN = 0.083
const BOMB_COOLDOWN = 1.0
const GRAVITY = 30.0
const BULLET_SPEED = 850.0
const MAP_TOP = 40.0
const MAP_BOTTOM = 580.0
const REENTRY_DELAY = 1.0

var map_type = "ground"
var hp = 3
var shoot_timer = 0.0
var bomb_timer = 0.0
var offscreen = false
var reentry_timer = 0.0
var current_speed = 220.0
var shot_rotation = 0.0
var stall_counter = 0
var stalling = false
var stall_timer = 3.0
var stall_spin_dir = 1.0

func _ready():
	add_to_group("player")
	position = Vector2(200, 300)
	rotation = 0.0
	$Camera2D.limit_top = -14
	$Camera2D.limit_bottom = 634

func _physics_process(delta):
	shoot_timer -= delta
	bomb_timer -= delta
	shot_rotation = move_toward(shot_rotation, 0.0, SHOT_ROTATION_RECOVERY * delta)

	if offscreen:
		reentry_timer -= delta
		if reentry_timer <= 0:
			_reenter()
		return

	if stalling:
		_handle_stall(delta)
		return

	var climb = -sin(rotation)
	var current_turn = TURN_SPEED + climb * 0.8

	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_up"):
		rotation -= current_turn * delta
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_down"):
		rotation += current_turn * delta

	rotation += shot_rotation * delta

	current_speed -= climb * GRAVITY_EFFECT * delta
	if current_speed < PASSIVE_SPEED:
		var recovery_strength = 40.0 + (1.0 - clamp(climb, 0.0, 1.0)) * 120.0
		current_speed = move_toward(current_speed, PASSIVE_SPEED, recovery_strength * delta)
	if current_speed > PASSIVE_SPEED:
		current_speed = lerp(current_speed, PASSIVE_SPEED, SPEED_DAMPING * delta)

	if current_speed < STALL_SPEED:
		stall_counter += 1
	else:
		stall_counter = 0
	if stall_counter >= STALL_FRAMES:
		stalling = true
		stall_timer = STALL_RECOVERY_TIME
		stall_spin_dir = 1.0 if randf() > 0.5 else -1.0

	velocity = Vector2(cos(rotation), sin(rotation)) * current_speed
	move_and_slide()

	if position.y < -50:
		offscreen = true
		reentry_timer = REENTRY_DELAY
		visible = false
	elif position.y > MAP_BOTTOM:
		if map_type == "ground":
			get_parent().game_over()
			set_physics_process(false)
			visible = false
			return

	if Input.is_action_pressed("ui_accept"):
		shoot()

	var climb_display = -sin(rotation)
	if get_parent().has_method("update_debug"):
		get_parent().update_debug(current_speed, climb_display, stalling)

	queue_redraw()

func _handle_stall(delta):
	rotation += 3.5 * stall_spin_dir * delta
	shot_rotation = 0.0

	var climb = -sin(rotation)
	current_speed -= climb * GRAVITY_EFFECT * 1.5 * delta
	current_speed = clamp(current_speed, MIN_SPEED, MAX_SPEED)

	if Input.is_action_pressed("ui_left") or Input.is_action_pressed("ui_up"):
		rotation -= TURN_SPEED * 0.3 * delta
	if Input.is_action_pressed("ui_right") or Input.is_action_pressed("ui_down"):
		rotation += TURN_SPEED * 0.3 * delta

	velocity = Vector2(cos(rotation), sin(rotation)) * current_speed
	move_and_slide()

	if current_speed > STALL_SPEED + 30:
		stalling = false
		stall_counter = 0

	stall_timer -= delta
	if stall_timer <= 0:
		get_parent().game_over()
		set_physics_process(false)
		visible = false

	if position.y > MAP_BOTTOM:
		if map_type == "ground":
			get_parent().game_over()
			set_physics_process(false)
			visible = false

	var climb_display = -sin(rotation)
	if get_parent().has_method("update_debug"):
		get_parent().update_debug(current_speed, climb_display, stalling)

	queue_redraw()

func _reenter():
	offscreen = false
	visible = true
	if position.y < MAP_TOP:
		position.y = -40
		rotation = deg_to_rad(randf_range(45, 70))
	else:
		position.y = MAP_BOTTOM - 30
		rotation = deg_to_rad(randf_range(-70, -45))

func _draw():
	if offscreen:
		return
	draw_rect(Rect2(-22, -7, 44, 14), Color(0.7, 0.7, 0.8))
	draw_circle(Vector2(18, -4), 7, Color(0.75, 0.75, 0.85))
	var top_wing = PackedVector2Array([
		Vector2(-5, -7), Vector2(10, -7),
		Vector2(5, -22), Vector2(-12, -22)
	])
	draw_colored_polygon(top_wing, Color(0.6, 0.6, 0.75))
	var tail_top = PackedVector2Array([
		Vector2(-22, -7), Vector2(-10, -7),
		Vector2(-12, -18), Vector2(-24, -18)
	])
	draw_colored_polygon(tail_top, Color(0.55, 0.55, 0.7))
	var shoot_dir = Vector2(cos(rotation), sin(rotation))
	var bullet_vel = shoot_dir * BULLET_SPEED + velocity
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
		if abs(pos.y) > 800:
			break
	return points

func _input(event):
	if event is InputEventKey and event.keycode == KEY_CTRL and event.pressed:
		drop_bomb()

func shoot():
	if shoot_timer > 0 or offscreen:
		return
	shoot_timer = SHOOT_COOLDOWN
	var bullet = BULLET_SCENE.instantiate()
	bullet.position = global_position
	var spread = randf_range(-0.012, 0.012)
	var shoot_dir = Vector2(cos(rotation + spread), sin(rotation + spread))
	bullet.setup(velocity, shoot_dir)
	get_parent().add_child(bullet)

func drop_bomb():
	if bomb_timer > 0 or offscreen:
		return
	bomb_timer = BOMB_COOLDOWN
	var bomb = BOMB_SCENE.instantiate()
	bomb.position = global_position
	bomb.setup(velocity)
	get_parent().add_child(bomb)

func take_damage():
	hp -= 1
	shot_rotation += randf_range(1.5, 3.0) * (1.0 if randf() > 0.5 else -1.0)
	get_parent().update_hp(hp)
	if hp <= 0:
		get_parent().game_over()
		queue_free()