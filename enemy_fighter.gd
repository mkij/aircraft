extends "res://base_enemy.gd"

enum State { PATROL, ATTACK, FLINCH, EVADE, REPOSITION, DESPERATE, ESCAPE, LAST_LOOP }
enum Personality { AGGRESSIVE, CAUTIOUS, BALANCED }

const ENEMY_BULLET_SCENE = preload("res://EnemyBullet.tscn")
const DETECTION_RANGE = 600.0
const ATTACK_RANGE = 600.0
const SHOOT_COOLDOWN = 0.1
const TURN_SPEED = 3.5

var state = State.PATROL
var personality = Personality.BALANCED
var shoot_timer = 0.0
var max_hp = 3
var facing = Vector2.LEFT
var state_timer = 0.0
var evade_rotation_dir = 1.0
var hits_taken = 0
var shoots_on_approach = false
var attacks_on_approach = false
var chase_offset = Vector2.ZERO
var personal_turn_speed = 3.5
var attack_timer = 0.0
var weave_timer = 0.0
var weave_dir = 1.0
var burst_count = 0
var burst_max = 4
var burst_pause = 0.0


func _ready():
	super._ready()
	hp = 3
	max_hp = 3
	score_value = 30
	speed = 220.0
	facing = Vector2.LEFT
	personality = randi() % 3
	shoots_on_approach = randf() < randf_range(0.3, 0.5)
	attacks_on_approach = randf() < 0.45
	chase_offset = Vector2(randf_range(-60, 60), randf_range(-30, 30))
	personal_turn_speed = randf_range(2.5, 4.5)
	burst_max = randi_range(3, 6)

func take_hit():
	hp -= 1
	hits_taken += 1
	if hp <= 0:
		die()
		return
	_react_to_hit()

func _react_to_hit():
	evade_rotation_dir = 1.0 if randf() > 0.5 else -1.0
	if hits_taken == 1:
		state = State.FLINCH
		state_timer = 0.6
	elif hits_taken == 2:
		state = State.FLINCH
		state_timer = 0.4
	else:
		_enter_last_stand()

func _enter_last_stand():
	var pool = []
	match personality:
		Personality.AGGRESSIVE:
			pool = [State.DESPERATE, State.DESPERATE, State.LAST_LOOP]
		Personality.CAUTIOUS:
			pool = [State.ESCAPE, State.ESCAPE, State.LAST_LOOP]
		Personality.BALANCED:
			pool = [State.DESPERATE, State.ESCAPE, State.LAST_LOOP]
	var chosen = pool[randi() % pool.size()]
	state = chosen
	state_timer = 3.0
	if chosen == State.LAST_LOOP:
		evade_rotation_dir = 1.0 if randf() > 0.5 else -1.0

func _process(delta):
	shoot_timer -= delta
	state_timer -= delta
	weave_timer -= delta
	if weave_timer <= 0:
		weave_dir = -weave_dir
		weave_timer = randf_range(2.0, 4.0)

	if player == null or not is_instance_valid(player):
		find_player()

	match state:
		State.PATROL:
			_patrol(delta)
		State.ATTACK:
			_attack(delta)
		State.FLINCH:
			_flinch(delta)
		State.EVADE:
			_evade(delta)
		State.REPOSITION:
			_reposition(delta)
		State.DESPERATE:
			_desperate(delta)
		State.ESCAPE:
			_escape(delta)
		State.LAST_LOOP:
			_last_loop(delta)

	rotation = facing.angle()
	position += facing * speed * delta

	var cam_x = 0.0
	if player != null and is_instance_valid(player):
		cam_x = player.global_position.x
	if position.x < cam_x - 1000 or position.x > cam_x + 1500 or position.y < -500 or position.y > 1200:
		queue_free()

func _patrol(delta):
	if player == null or not is_instance_valid(player):
		find_player()
		return
	var dist = global_position.distance_to(player.global_position)
	var to_player = (player.global_position - global_position).normalized()

	if attacks_on_approach:
		if shoots_on_approach and dist < ATTACK_RANGE and abs(facing.angle_to(to_player)) < 0.2 and shoot_timer <= 0:
			_shoot(facing)
			shoot_timer = SHOOT_COOLDOWN
		if dist < DETECTION_RANGE:
			state = State.ATTACK
			attack_timer = 0.0
	else:
		if facing.dot(to_player) < -0.3 and dist < DETECTION_RANGE:
			state = State.REPOSITION
			state_timer = 2.5

func _attack(delta):
	if player == null or not is_instance_valid(player):
		state = State.PATROL
		return
	var to_player = (player.global_position - global_position).normalized()
	var dist = global_position.distance_to(player.global_position)
	attack_timer += delta
	burst_pause -= delta

	if facing.dot(to_player) < -0.2:
		state = State.REPOSITION
		state_timer = 2.5
		return

	if dist < 120:
		state = State.REPOSITION
		state_timer = 1.5
		return

	var weave = Vector2(-to_player.y, to_player.x) * weave_dir * 20.0
	var target = player.global_position + weave
	var to_target = (target - global_position).normalized()
	var angle_diff = facing.angle_to(to_target)
	var max_turn = personal_turn_speed * delta
	facing = facing.rotated(clamp(angle_diff, -max_turn, max_turn))

	if dist < ATTACK_RANGE and abs(facing.angle_to(to_player)) < 0.2 and shoot_timer <= 0 and burst_pause <= 0:
		_shoot(facing)
		shoot_timer = SHOOT_COOLDOWN
		attack_timer = 0.0
		burst_count += 1
		if burst_count >= burst_max:
			burst_count = 0
			burst_max = randi_range(3, 6)
			burst_pause = randf_range(1.2, 2.5)

	if attack_timer > 2.5:
		attack_timer = 0.0
		state = State.REPOSITION
		state_timer = 1.5

func _flinch(delta):
	var away = Vector2.ZERO
	if player != null:
		away = (global_position - player.global_position).normalized()
	var side = Vector2(-away.y, away.x) * evade_rotation_dir
	var evade_dir = (away + side).normalized()
	facing = facing.lerp(evade_dir, 4.0 * delta).normalized()
	speed = 300.0
	if state_timer <= 0:
		if hits_taken >= 2:
			state = State.EVADE
			state_timer = 1.8
		else:
			state = State.REPOSITION
			state_timer = 2.0
		speed = 220.0

func _evade(delta):
	facing = facing.rotated(evade_rotation_dir * 3.5 * delta)
	if state_timer <= 0:
		state = State.REPOSITION
		state_timer = 2.0
		speed = 220.0

func _reposition(delta):
	if player == null or not is_instance_valid(player):
		state = State.PATROL
		return
	var behind_player = player.global_position + Vector2(400, 0)
	var to_target = (behind_player - global_position).normalized()
	var angle_diff = facing.angle_to(to_target)
	var max_turn = personal_turn_speed * 0.4 * delta
	facing = facing.rotated(clamp(angle_diff, -max_turn, max_turn))
	speed = 220.0
	if state_timer <= 0:
		state = State.ATTACK
		attack_timer = 0.0

func _desperate(delta):
	if player == null or not is_instance_valid(player):
		return
	var to_player = (player.global_position - global_position).normalized()
	facing = facing.lerp(to_player, TURN_SPEED * 2.0 * delta).normalized()
	speed = 320.0
	var dist = global_position.distance_to(player.global_position)
	if dist < ATTACK_RANGE and abs(facing.angle_to(to_player)) < 0.5 and shoot_timer <= 0:
		_shoot(to_player)
		shoot_timer = SHOOT_COOLDOWN * 0.5

func _escape(delta):
	if player == null or not is_instance_valid(player):
		return
	var away = (global_position - player.global_position).normalized()
	facing = facing.lerp(away, 3.0 * delta).normalized()
	speed = 320.0

func _last_loop(delta):
	var climb = -facing.y
	var rot_speed = 4.0 + climb * 2.5
	var move_speed = 280.0 - climb * 80.0
	facing = facing.rotated(evade_rotation_dir * rot_speed * delta)
	speed = move_speed
	if state_timer <= 0:
		state = State.DESPERATE
		state_timer = 2.0

func _shoot(direction: Vector2):
	var bullet = ENEMY_BULLET_SCENE.instantiate()
	bullet.position = global_position + facing * 20
	var spread = randf_range(-0.012, 0.012)
	bullet.setup(direction.rotated(spread))
	get_parent().add_child(bullet)