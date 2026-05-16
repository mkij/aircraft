extends "res://base_enemy.gd"

const ENEMY_BULLET_SCENE = preload("res://EnemyBullet.tscn")
const DETECTION_RANGE = 700.0
const SHOOT_RANGE = 600.0
const SHOOT_COOLDOWN = 0.15
const BURST_SIZE = 4
const BURST_PAUSE = 2.0
const TURN_SPEED = 1.8
const MIN_AIM_ANGLE = deg_to_rad(-160)
const MAX_AIM_ANGLE = deg_to_rad(-20)

var turret_angle = -PI / 2.0
var shoot_timer = 0.0
var burst_count = 0
var burst_pause_timer = 0.0
var barrel_length = 25.0

func _ready():
	super._ready()
	hp = 4
	score_value = 50
	speed = 0.0

func _process(delta):
	shoot_timer -= delta
	burst_pause_timer -= delta

	if player == null or not is_instance_valid(player):
		find_player()
		return

	var to_player = (player.global_position - global_position).normalized()
	var target_angle = to_player.angle()
	target_angle = clamp(target_angle, MIN_AIM_ANGLE, MAX_AIM_ANGLE)

	var angle_diff = target_angle - turret_angle
	angle_diff = wrapf(angle_diff, -PI, PI)
	turret_angle += clamp(angle_diff, -TURN_SPEED * delta, TURN_SPEED * delta)

	var dist = global_position.distance_to(player.global_position)
	var aim_error = abs(turret_angle - target_angle)

	if dist < SHOOT_RANGE and aim_error < 0.15 and shoot_timer <= 0 and burst_pause_timer <= 0:
		_shoot()
		shoot_timer = SHOOT_COOLDOWN
		burst_count += 1
		if burst_count >= BURST_SIZE:
			burst_count = 0
			burst_pause_timer = BURST_PAUSE

	queue_redraw()

func _shoot():
	var bullet = ENEMY_BULLET_SCENE.instantiate()
	var direction = Vector2(cos(turret_angle), sin(turret_angle))
	bullet.position = global_position + direction * barrel_length
	var spread = randf_range(-0.03, 0.03)
	bullet.setup(direction.rotated(spread))
	get_parent().add_child(bullet)

func _draw():
	draw_rect(Rect2(-20, -8, 40, 16), Color(0.35, 0.35, 0.3))
	var dir = Vector2(cos(turret_angle - rotation), sin(turret_angle - rotation))
	draw_line(Vector2.ZERO, dir * barrel_length, Color(0.5, 0.5, 0.45), 4.0)
	draw_circle(Vector2.ZERO, 8, Color(0.4, 0.4, 0.35))

func die():
	if is_instance_valid(get_parent()) and get_parent().has_method("add_score"):
		get_parent().add_score(score_value)
	queue_free()