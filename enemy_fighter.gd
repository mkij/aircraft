extends "res://base_enemy.gd"

enum State { PATROL, ATTACK, FLINCH, EVADE, REPOSITION, DESPERATE, ESCAPE, LAST_LOOP, PAUSE_ATTACK, RECOVER, DIVE, DEFENSIVE_LOOP, DYING, CLIMB, CLOUD_SEEK, CLOUD_HIDE }
enum Personality { AGGRESSIVE, CAUTIOUS, BALANCED }

const PlanePhysicsClass = preload("res://plane_physics.gd")
var flight = PlanePhysicsClass.new()

const ENEMY_BULLET_SCENE = preload("res://EnemyBullet.tscn")
const DETECTION_RANGE = 600.0
const ATTACK_RANGE = 600.0
const SHOOT_COOLDOWN = 0.1
const TURN_SPEED = 3.5
const MAX_HEAT = 15.0
const HEAT_COOLDOWN = 5.0

var state = State.PATROL
var personality = Personality.BALANCED
var shoot_timer = 0.0
var max_hp = 3
var facing = Vector2.LEFT
var state_timer = 0.0
var evade_rotation_dir = 1.0
var hits_taken = 0
var personal_turn_speed = 3.5
var attack_timer = 0.0
var weave_timer = 0.0
var weave_dir = 1.0
var burst_count = 0
var burst_max = 4
var burst_pause = 0.0
var target_position = Vector2.ZERO
var reaction_timer = 0.0
var reaction_delay = 0.5
var hunt_timer = 0.0
var hunt_length = 8.0
var last_maneuver = ""
var maneuver_cooldown = 0.0
var heat = 0.0
var overheated = false
var in_cloud = false


func _ready():
	super._ready()
	hp = 3
	max_hp = 3
	score_value = 30
	facing = Vector2.LEFT
	personality = randi() % 3
	personal_turn_speed = randf_range(2.8, 3.8)
	burst_max = randi_range(3, 6)
	match personality:
		Personality.AGGRESSIVE:
			reaction_delay = randf_range(0.2, 0.4)
		Personality.BALANCED:
			reaction_delay = randf_range(0.4, 0.7)
		Personality.CAUTIOUS:
			reaction_delay = randf_range(0.5, 0.9)
	hunt_length = randf_range(4.0, 8.0)
	if get_tree().get_nodes_in_group("player").size() > 0:
		target_position = get_tree().get_nodes_in_group("player")[0].global_position
	flight.passive_speed = 220.0
	flight.max_speed = 300.0
	flight.min_speed = 120.0
	flight.gravity_effect = 80.0
	flight.use_climb_recovery = false
	flight.speed = 220.0

func take_hit():
	hp -= 1
	hits_taken += 1
	if hp <= 0:
		die()
		return
	_react_to_hit()
	flight.apply_hit()

func die():
	print("DIE CALLED: hp=", hp, " hits=", hits_taken)
	if is_instance_valid(get_parent()) and get_parent().has_method("add_score"):
		get_parent().add_score(score_value)
	state = State.DYING
	state_timer = 2.5
	modulate = Color(0.4, 0.1, 0.1, 0.8)
	set_deferred("monitoring", false)
	set_deferred("monitorable", false)
	remove_from_group("enemies")

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

	reaction_timer -= delta
	if reaction_timer <= 0:
		if player != null and is_instance_valid(player):
			if not player.in_cloud:
				target_position = player.global_position
		reaction_timer = reaction_delay

	maneuver_cooldown -= delta
	flight.update_shot_rotation(delta)
	if abs(flight.shot_rotation) > 0.01:
		facing = facing.rotated(flight.shot_rotation * delta)

	if overheated:
		heat -= HEAT_COOLDOWN * delta
		if heat <= 0:
			heat = 0
			overheated = false
	else:
		heat = max(0, heat - HEAT_COOLDOWN * 0.5 * delta)

	if state == State.DYING:
		_dying(delta)
		rotation = facing.angle()
		position += facing * flight.speed * delta
		if position.y > 570 or state_timer <= 0:
			queue_free()
		return

	var ground_immune = [State.CLIMB, State.FLINCH, State.EVADE, State.DEFENSIVE_LOOP]
	if position.y > 430 and not ground_immune.has(state):
		state = State.CLIMB

	_execute_state(delta)
	

	flight.update_speed(-facing.y, delta)
	if not flight.stalling:
		flight.check_stall()
	else:
		var result = flight.handle_stall(delta, rotation, personal_turn_speed)
		facing = Vector2.from_angle(result.rotation)
		rotation = facing.angle()
		position += facing * flight.speed * delta
		if result.timeout:
			die()
		return

	var cam_x = 0.0
	if player != null and is_instance_valid(player):
		cam_x = player.global_position.x

	var near_x_border = position.x < cam_x - 400 or position.x > cam_x + 1000
	if near_x_border:
		var center_x = Vector2(cam_x + 200, position.y)
		var to_center = (center_x - global_position).normalized()
		var border_angle = facing.angle_to(to_center)
		var border_turn = personal_turn_speed * 0.8 * delta
		facing = facing.rotated(clamp(border_angle, -border_turn, border_turn))

	rotation = facing.angle()
	position += facing * flight.speed * delta

	if position.y > 560:
		position.y = 560

	if position.x < cam_x - 1500 or position.x > cam_x + 2000 or position.y < -800 or position.y > 1500:
		print("DESPAWN: state=", state, " pos=", position, " cam_x=", cam_x)
		queue_free()

func _execute_state(delta):
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
		State.PAUSE_ATTACK:
			_pause_attack(delta)          
		State.RECOVER:
			_recover(delta)
		State.DIVE:
			_dive(delta)
		State.DEFENSIVE_LOOP:
			_defensive_loop(delta)
		State.CLIMB:
			_climb(delta)	
		State.CLOUD_SEEK:
			_cloud_seek(delta)
		State.CLOUD_HIDE:
			_cloud_hide(delta)		

func _exit_tree():
	print("ENEMY REMOVED: state=", state, " pos=", position, " hp=", hp, " stalling=", flight.stalling)

func _climb(delta):
	var target_angle = 0.0
	if facing.x >= 0:
		target_angle = deg_to_rad(-35)
	else:
		target_angle = deg_to_rad(-180 + 35)
	var climb_dir = Vector2(cos(target_angle), sin(target_angle))
	var angle_diff = facing.angle_to(climb_dir)
	var urgency = 1.0 + clamp((position.y - 430) / 100.0, 0, 3.0)
	var max_turn = personal_turn_speed * urgency * delta
	facing = facing.rotated(clamp(angle_diff, -max_turn, max_turn))
	flight.target_speed_override = 220.0
	if position.y < 300:
		state = State.ATTACK
		attack_timer = 0.0

func _patrol(delta):
	if player == null or not is_instance_valid(player):
		find_player()
		return
	var dist = global_position.distance_to(player.global_position)
	if dist < DETECTION_RANGE:
		state = State.ATTACK
		attack_timer = 0.0

func _attack(delta):
	if player == null or not is_instance_valid(player):
		state = State.PATROL
		return
	var to_player = (player.global_position - global_position).normalized()
	var dist = global_position.distance_to(player.global_position)
	attack_timer += delta
	burst_pause -= delta

	if facing.dot(to_player) < -0.2:
		if _try_evasion():
			return
		state = State.REPOSITION
		state_timer = 2.5
		return

	if dist < 120:
		state = State.REPOSITION
		state_timer = 1.5
		return

	var weave = Vector2(-to_player.y, to_player.x) * weave_dir * 50.0
	var target = player.global_position + weave
	var to_target = (target - global_position).normalized()
	var angle_diff = facing.angle_to(to_target)
	var max_turn = personal_turn_speed * delta
	facing = facing.rotated(clamp(angle_diff, -max_turn, max_turn))

	if dist < ATTACK_RANGE and abs(facing.angle_to(to_player)) < 0.2 and shoot_timer <= 0 and burst_pause <= 0 and _is_line_clear():
		_shoot(facing)
		shoot_timer = SHOOT_COOLDOWN
		attack_timer = 0.0
		burst_count += 1
		if burst_count >= burst_max:
			burst_count = 0
			burst_max = randi_range(3, 6)
			burst_pause = randf_range(1.2, 2.5)

	hunt_timer += delta
	if hunt_timer > hunt_length:
		hunt_timer = 0.0
		state = State.REPOSITION
		state_timer = 2.5
		return

	if attack_timer > 2.5:
		attack_timer = 0.0
		state = State.REPOSITION
		state_timer = 1.5

func _pause_attack(delta):
	flight.target_speed_override = 220.0
	if state_timer <= 0:
		state = State.ATTACK
		attack_timer = 0.0

func _recover(delta):
	if player != null and is_instance_valid(player):
		var to_player = (player.global_position - global_position).normalized()
		var angle_diff = facing.angle_to(to_player)
		facing = facing.rotated(clamp(angle_diff, -personal_turn_speed * delta, personal_turn_speed * delta))
	flight.target_speed_override = 220.0
	if state_timer <= 0:
		if _try_evasion():
			return
		state = State.ATTACK
		attack_timer = 0.0

func _flinch(delta):
	var away = Vector2.ZERO
	if player != null:
		away = (global_position - player.global_position).normalized()
	var side = Vector2(-away.y, away.x) * evade_rotation_dir
	var evade_dir = (away * 0.3 + side * 0.7).normalized()
	var angle_diff = facing.angle_to(evade_dir)
	var max_turn = personal_turn_speed * delta
	facing = facing.rotated(clamp(angle_diff, -max_turn, max_turn))
	flight.target_speed_override = 230.0
	if position.y > 430:
		var turn_up = -1.0 if facing.x >= 0 else 1.0
		facing = facing.rotated(turn_up * personal_turn_speed * delta)
	if state_timer <= 0:
		if hits_taken >= 2:
			state = State.EVADE
			state_timer = 1.8
		else:
			state = State.RECOVER
			state_timer = randf_range(0.4, 0.7)
		flight.target_speed_override = 220.0

func _evade(delta):
	facing = facing.rotated(evade_rotation_dir * 3.5 * delta)
	if position.y > 430:
		var turn_up = -1.0 if facing.x >= 0 else 1.0
		facing = facing.rotated(turn_up * personal_turn_speed * delta)
	if state_timer <= 0:
		state = State.RECOVER
		state_timer = randf_range(0.4, 0.7)
		flight.target_speed_override = 220.0

func _reposition(delta):
	if player == null or not is_instance_valid(player):
		state = State.PATROL
		return
	var to_player = (target_position - global_position).normalized()
	var angle_diff = facing.angle_to(to_player)
	var max_turn = personal_turn_speed * 0.8 * delta
	facing = facing.rotated(clamp(angle_diff, -max_turn, max_turn))
	flight.target_speed_override = 220.0
	if state_timer <= 0:
		state = State.PAUSE_ATTACK
		state_timer = randf_range(0.2, 0.5)

func _desperate(delta):
	if player == null or not is_instance_valid(player):
		return
	var to_player = (player.global_position - global_position).normalized()
	facing = facing.lerp(to_player, TURN_SPEED * 2.0 * delta).normalized()
	flight.target_speed_override = 320.0
	var dist = global_position.distance_to(player.global_position)
	if dist < ATTACK_RANGE and abs(facing.angle_to(to_player)) < 0.5 and shoot_timer <= 0:
		_shoot(to_player)
		shoot_timer = SHOOT_COOLDOWN * 0.5

func _escape(delta):
	if player == null or not is_instance_valid(player):
		return
	var away = (global_position - player.global_position).normalized()
	facing = facing.lerp(away, 3.0 * delta).normalized()
	flight.target_speed_override = 320.0

func _last_loop(delta):
	var climb = -facing.y
	var rot_speed = 4.0 + climb * 2.5
	var move_speed = 280.0 - climb * 80.0
	facing = facing.rotated(evade_rotation_dir * rot_speed * delta)
	flight.target_speed_override = move_speed
	if state_timer <= 0:
		state = State.DESPERATE
		state_timer = 2.0

func _dying(delta):
	facing = facing.rotated(4.5 * delta)
	facing = (facing + Vector2(0, 0.15)).normalized()
	flight.speed = move_toward(flight.speed, 80.0, 150.0 * delta)

func _get_spread() -> float:
	match state:
		State.PATROL:
			return 0.004
		State.ATTACK:
			return 0.010
		State.DESPERATE:
			return 0.020
		State.FLINCH:
			return 0.055
		_:
			return 0.012

func _is_line_clear() -> bool:
	if player == null:
		return false
	var to_player = player.global_position - global_position
	var dist_to_player = to_player.length()
	var dir = to_player.normalized()
	for e in get_tree().get_nodes_in_group("enemies"):
		if e != self:
			var to_enemy = e.global_position - global_position
			var proj = to_enemy.dot(dir)
			if proj > 0 and proj < dist_to_player:
				var perp = abs(to_enemy.cross(dir))
				if perp < 30:
					return false
	return true

func _try_evasion() -> bool:
	if maneuver_cooldown > 0:
		return false
	if player == null or not is_instance_valid(player):
		return false

	var dist = global_position.distance_to(player.global_position)
	var near_ground = position.y > 380

	var options = []
	if not near_ground and last_maneuver != "dive":
		options.append("dive")
	if dist < 250 and last_maneuver != "loop" and maneuver_cooldown < -2.0:
		options.append("loop")
	if last_maneuver != "evade":
		options.append("evade")

	if options.size() == 0:
		last_maneuver = ""
		return false

	var chosen = options[randi() % options.size()]
	evade_rotation_dir = 1.0 if randf() > 0.5 else -1.0

	match chosen:
		"dive":
			state = State.DIVE
			state_timer = randf_range(1.0, 1.8)
			last_maneuver = "dive"
			maneuver_cooldown = randf_range(3.0, 5.0)
		"loop":
			state = State.DEFENSIVE_LOOP
			state_timer = randf_range(1.5, 2.5)
			last_maneuver = "loop"
			maneuver_cooldown = randf_range(5.0, 8.0)
		"evade":
			state = State.EVADE
			state_timer = randf_range(1.0, 1.5)
			last_maneuver = "evade"
			maneuver_cooldown = randf_range(2.0, 4.0)

	return true

func _dive(delta):
	var dive_dir = Vector2(facing.x, abs(facing.x) * 0.7 + 0.3).normalized()
	var angle_diff = facing.angle_to(dive_dir)
	var max_turn = personal_turn_speed * 1.2 * delta
	facing = facing.rotated(clamp(angle_diff, -max_turn, max_turn))
	flight.target_speed_override = 260.0
	if state_timer <= 0 or position.y > 380:
		state = State.RECOVER
		state_timer = randf_range(0.3, 0.6)
		flight.target_speed_override = 220.0

func _defensive_loop(delta):
	var climb = -facing.y
	var rot_speed = 2.5 + climb * 1.5
	var move_speed = 250.0 - climb * 60.0
	facing = facing.rotated(evade_rotation_dir * rot_speed * delta)
	flight.target_speed_override = move_speed
	if state_timer <= 0:
		state = State.RECOVER
		state_timer = randf_range(0.3, 0.6)
		flight.target_speed_override = 220.0

func _cloud_seek(delta):
	state = State.REPOSITION
	state_timer = 2.0

func _cloud_hide(delta):
	state = State.ATTACK
	attack_timer = 0.0		

func _shoot(direction: Vector2):
	if overheated:
		return
	var bullet = ENEMY_BULLET_SCENE.instantiate()
	bullet.position = global_position + facing * 20
	var spread = randf_range(-_get_spread(), _get_spread())
	bullet.setup(direction.rotated(spread))
	get_parent().add_child(bullet)
	heat += 1.0
	if heat >= MAX_HEAT:
		overheated = true
