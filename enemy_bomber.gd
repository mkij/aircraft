extends "res://base_enemy.gd"

const PlanePhysicsClass = preload("res://plane_physics.gd")
var flight = PlanePhysicsClass.new()

const ENEMY_BULLET_SCENE = preload("res://EnemyBullet.tscn")
const GUNNER_RANGE = 500.0
const GUNNER_COOLDOWN = 0.2
const GUNNER_BURST = 3
const GUNNER_PAUSE = 2.5
const GUNNER_TURN_SPEED = 2.0
const BOMB_SCENE = preload("res://Bomb.tscn")
const BOMB_COOLDOWN = 3.0

var facing = Vector2.LEFT
var turret_angle = 0.0
var gunner_timer = 0.0
var gunner_burst_count = 0
var gunner_pause_timer = 0.0
var fly_direction = Vector2.LEFT
var bomb_target: Node2D = null
var bomb_timer = 0.0
var bombing = false

func _ready():
	super._ready()
	hp = 8
	score_value = 80
	speed = 0.0
	facing = Vector2.LEFT
	fly_direction = Vector2.LEFT
	flight.passive_speed = 130.0
	flight.max_speed = 180.0
	flight.min_speed = 80.0
	flight.gravity_effect = 40.0
	flight.use_climb_recovery = false
	flight.speed = 130.0
	turret_angle = PI

func _process(delta):
	gunner_timer -= delta
	gunner_pause_timer -= delta

	if player == null or not is_instance_valid(player):
		find_player()

	facing = facing.lerp(fly_direction, 0.5 * delta).normalized()

	flight.update_speed(-facing.y, delta)

	rotation = facing.angle()
	position += facing * flight.speed * delta

	if bombing and bomb_target and is_instance_valid(bomb_target):
		bomb_timer -= delta
		var dist_to_target = global_position.distance_to(bomb_target.global_position)
		if dist_to_target < 150 and bomb_timer <= 0:
			_drop_bomb()
			bomb_timer = BOMB_COOLDOWN

	_update_gunner(delta)

	var cam_x = 0.0
	if player != null and is_instance_valid(player):
		cam_x = player.global_position.x
	if position.x < cam_x - 1500 or position.x > cam_x + 2000:
		queue_free()

	queue_redraw()

func _update_gunner(delta):
	if player == null or not is_instance_valid(player):
		return

	var to_player = (player.global_position - global_position).normalized()
	var target_angle = to_player.angle()
	var angle_diff = wrapf(target_angle - turret_angle, -PI, PI)
	turret_angle += clamp(angle_diff, -GUNNER_TURN_SPEED * delta, GUNNER_TURN_SPEED * delta)

	var dist = global_position.distance_to(player.global_position)
	var aim_error = abs(wrapf(turret_angle - target_angle, -PI, PI))

	if dist < GUNNER_RANGE and aim_error < 0.2 and gunner_timer <= 0 and gunner_pause_timer <= 0:
		_gunner_shoot()
		gunner_timer = GUNNER_COOLDOWN
		gunner_burst_count += 1
		if gunner_burst_count >= GUNNER_BURST:
			gunner_burst_count = 0
			gunner_pause_timer = GUNNER_PAUSE

func _gunner_shoot():
	var bullet = ENEMY_BULLET_SCENE.instantiate()
	var direction = Vector2(cos(turret_angle), sin(turret_angle))
	bullet.position = global_position + direction * 15
	var spread = randf_range(-0.04, 0.04)
	bullet.setup(direction.rotated(spread))
	get_parent().add_child(bullet)

func _draw():
	draw_rect(Rect2(-30, -10, 60, 20), Color(0.4, 0.35, 0.3))
	draw_rect(Rect2(-35, -6, 10, 12), Color(0.35, 0.3, 0.28))
	draw_rect(Rect2(20, -14, 15, 8), Color(0.38, 0.33, 0.3))

	var gun_dir = Vector2(cos(turret_angle - rotation), sin(turret_angle - rotation))
	draw_circle(gun_dir * -5, 6, Color(0.45, 0.4, 0.35))
	draw_line(gun_dir * -5, gun_dir * 15, Color(0.5, 0.45, 0.4), 3.0)

func die():
	if is_instance_valid(get_parent()) and get_parent().has_method("add_score"):
		get_parent().add_score(score_value)
	modulate = Color(0.4, 0.1, 0.1, 0.8)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	remove_from_group("enemies")
	var tween = create_tween()
	tween.tween_property(self, "rotation", rotation + 2.0, 1.5)
	tween.parallel().tween_property(self, "position:y", position.y + 300, 1.5)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 1.5)
	tween.tween_callback(queue_free)

func setup_target(target: Node2D):
	bomb_target = target
	if target:
		fly_direction = (target.global_position - global_position).normalized()
		fly_direction.y = clamp(fly_direction.y, -0.1, 0.1)
		bombing = true

func _drop_bomb():
	var bomb = BOMB_SCENE.instantiate()
	bomb.position = global_position
	bomb.setup(facing * flight.speed)
	get_parent().add_child(bomb)            