extends Area2D

const ENEMY_BULLET_SCENE = preload("res://EnemyBullet.tscn")
const TURRET_RANGE = 550.0
const TURRET_COOLDOWN = 0.2
const TURRET_BURST = 4
const TURRET_PAUSE = 2.0
const TURN_SPEED = 1.8

var turret_hp = 3
var turret_angle = -PI / 2.0
var shoot_timer = 0.0
var burst_count = 0
var pause_timer = 0.0
var destroyed = false
var barrel_length = 18.0
var player = null

func _ready():
	add_to_group("enemies")
	area_entered.connect(_on_area_entered)

func _process(delta):
	if destroyed:
		return
	shoot_timer -= delta
	pause_timer -= delta

	if player == null or not is_instance_valid(player):
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			player = players[0]
		return

	var turret_pos = global_position
	var to_player = (player.global_position - turret_pos).normalized()
	var target_angle = to_player.angle()
	var angle_diff = wrapf(target_angle - turret_angle, -PI, PI)
	turret_angle += clamp(angle_diff, -TURN_SPEED * delta, TURN_SPEED * delta)

	var dist = turret_pos.distance_to(player.global_position)
	var aim_error = abs(wrapf(turret_angle - target_angle, -PI, PI))

	if dist < TURRET_RANGE and aim_error < 0.2 and shoot_timer <= 0 and pause_timer <= 0:
		_shoot()
		shoot_timer = TURRET_COOLDOWN
		burst_count += 1
		if burst_count >= TURRET_BURST:
			burst_count = 0
			pause_timer = TURRET_PAUSE

	queue_redraw()

func _shoot():
	var direction = Vector2(cos(turret_angle), sin(turret_angle))
	var bullet = ENEMY_BULLET_SCENE.instantiate()
	bullet.position = global_position + direction * barrel_length
	var spread = randf_range(-0.035, 0.035)
	bullet.setup(direction.rotated(spread))
	get_parent().get_parent().get_parent().add_child(bullet)

func _on_area_entered(area):
	if area.is_in_group("player_bullet") and not destroyed:
		turret_hp -= 1
		_flash()
		if turret_hp <= 0:
			destroyed = true
			modulate = Color(0.3, 0.15, 0.1, 0.5)

func _flash():
	modulate = Color(2.0, 0.8, 0.8, 1.0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1) if not destroyed else Color(0.3, 0.15, 0.1, 0.5), 0.15)

func _draw():
	if destroyed:
		draw_circle(Vector2.ZERO, 5, Color(0.3, 0.15, 0.1, 0.5))
		return
	draw_circle(Vector2.ZERO, 6, Color(0.5, 0.48, 0.42))
	var gun_dir = Vector2(cos(turret_angle - global_rotation), sin(turret_angle - global_rotation))
	draw_line(Vector2.ZERO, gun_dir * barrel_length, Color(0.55, 0.5, 0.45), 3.0)