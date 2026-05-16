extends "res://convoy_vehicle.gd"

const ENEMY_BULLET_SCENE = preload("res://EnemyBullet.tscn")
const TURRET_RANGE = 450.0
const TURRET_COOLDOWN = 0.25
const TURRET_BURST = 3
const TURRET_PAUSE = 3.0
const TURRET_TURN_SPEED = 2.5
const MIN_AIM_ANGLE = deg_to_rad(-170)
const MAX_AIM_ANGLE = deg_to_rad(-10)

var turret_angle = -PI / 2.0
var turret_timer = 0.0
var turret_burst_count = 0
var turret_pause_timer = 0.0

func _ready():
	super._ready()
	hp = 3
	score_value = 40
	drive_speed = 60.0
	vehicle_width = 32.0
	vehicle_height = 14.0

func _process(delta):
	super._process(delta)
	turret_timer -= delta
	turret_pause_timer -= delta
	_update_turret(delta)

func _update_turret(delta):
	if player == null or not is_instance_valid(player):
		find_player()
		return

	var to_player = (player.global_position - global_position).normalized()
	var target_angle = to_player.angle()
	target_angle = clamp(target_angle, MIN_AIM_ANGLE, MAX_AIM_ANGLE)

	var angle_diff = wrapf(target_angle - turret_angle, -PI, PI)
	turret_angle += clamp(angle_diff, -TURRET_TURN_SPEED * delta, TURRET_TURN_SPEED * delta)

	var dist = global_position.distance_to(player.global_position)
	var aim_error = abs(wrapf(turret_angle - target_angle, -PI, PI))

	if dist < TURRET_RANGE and aim_error < 0.2 and turret_timer <= 0 and turret_pause_timer <= 0:
		_turret_shoot()
		turret_timer = TURRET_COOLDOWN
		turret_burst_count += 1
		if turret_burst_count >= TURRET_BURST:
			turret_burst_count = 0
			turret_pause_timer = TURRET_PAUSE

func _turret_shoot():
	var bullet = ENEMY_BULLET_SCENE.instantiate()
	var direction = Vector2(cos(turret_angle), sin(turret_angle))
	bullet.position = global_position + direction * 18
	var spread = randf_range(-0.04, 0.04)
	bullet.setup(direction.rotated(spread))
	get_parent().add_child(bullet)

func _draw():
	super._draw()
	var gun_dir = Vector2(cos(turret_angle), sin(turret_angle))
	draw_circle(Vector2(0, -vehicle_height - 4), 5, Color(0.5, 0.48, 0.4))
	draw_line(Vector2(0, -vehicle_height - 4), Vector2(0, -vehicle_height - 4) + gun_dir * 18, Color(0.55, 0.5, 0.45), 3.0)