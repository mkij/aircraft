extends "res://enemy_fighter.gd"

var target_cloud: Node2D = null

func _ready():
    super._ready()
    hp = 5
    max_hp = 5
    score_value = 100
    personal_turn_speed = randf_range(3.2, 4.2)
    flight.passive_speed = 240.0
    flight.max_speed = 340.0
    flight.speed = 240.0
    personality = Personality.AGGRESSIVE
    reaction_delay = randf_range(0.1, 0.25)
    modulate = Color(1.0, 0.85, 0.3, 1.0)

func _try_evasion() -> bool:
    if maneuver_cooldown > 0:
        return false
    if player == null or not is_instance_valid(player):
        return false

    var dist = global_position.distance_to(player.global_position)
    var near_ground = position.y > 380
    var player_above = player.global_position.y < global_position.y - 80
    var player_behind_me = facing.dot((player.global_position - global_position).normalized()) < -0.3

    evade_rotation_dir = 1.0 if randf() > 0.5 else -1.0

    var cloud = _find_nearest_cloud()
    if cloud and last_maneuver != "cloud" and dist < 450:
        target_cloud = cloud
        state = State.CLOUD_SEEK
        state_timer = 3.0
        last_maneuver = "cloud"
        maneuver_cooldown = randf_range(6.0, 10.0)
        return true

    if player_above and not near_ground and last_maneuver != "dive":
        state = State.DIVE
        state_timer = randf_range(1.5, 2.5)
        last_maneuver = "dive"
        maneuver_cooldown = randf_range(3.0, 5.0)
        return true

    if player_behind_me and dist < 300 and last_maneuver != "loop":
        state = State.DEFENSIVE_LOOP
        state_timer = randf_range(1.5, 2.5)
        last_maneuver = "loop"
        maneuver_cooldown = randf_range(4.0, 6.0)
        return true

    if position.y < 200 and last_maneuver != "low":
        state = State.DIVE
        state_timer = randf_range(0.8, 1.3)
        last_maneuver = "low"
        maneuver_cooldown = randf_range(3.0, 5.0)
        return true

    if last_maneuver != "evade":
        state = State.EVADE
        state_timer = randf_range(0.8, 1.2)
        last_maneuver = "evade"
        maneuver_cooldown = randf_range(2.0, 3.0)
        return true

    last_maneuver = ""
    return false

func _enter_last_stand():
    var options = []
    
    var cloud = _find_nearest_cloud()
    if cloud:
        options.append("cloud")
    
    if position.y < 350:
        options.append("dive_escape")
    
    options.append("loop_and_run")
    options.append("loop_and_run")
    
    var chosen = options[randi() % options.size()]
    
    match chosen:
        "cloud":
            target_cloud = cloud
            state = State.CLOUD_SEEK
            state_timer = 3.0
            last_maneuver = "cloud"
            maneuver_cooldown = randf_range(4.0, 6.0)
        "dive_escape":
            state = State.DIVE
            state_timer = randf_range(1.5, 2.5)
            last_maneuver = "dive"
            maneuver_cooldown = randf_range(3.0, 5.0)
        "loop_and_run":
            evade_rotation_dir = 1.0 if randf() > 0.5 else -1.0
            state = State.LAST_LOOP
            state_timer = 2.0

func _last_loop(delta):
    super._last_loop(delta)
    # Override: po loopie ace wraca do ATTACK zamiast DESPERATE
    if state_timer <= 0:
        state = State.ATTACK
        attack_timer = 0.0              

func _find_nearest_cloud() -> Node2D:
    var clouds = get_tree().get_nodes_in_group("game_clouds")
    var best = null
    var best_dist = 999999.0
    for c in clouds:
        var d = global_position.distance_to(c.global_position)
        if d < 500 and d < best_dist:
            best = c
            best_dist = d
    return best

func _execute_state(delta):
    match state:
        State.CLOUD_SEEK:
            _cloud_seek(delta)
        State.CLOUD_HIDE:
            _cloud_hide(delta)
        _:
            super._execute_state(delta)    

func _cloud_seek(delta):
    if target_cloud == null or not is_instance_valid(target_cloud):
        state = State.REPOSITION
        state_timer = 2.0
        return
    var to_cloud = (target_cloud.global_position - global_position).normalized()
    var angle_diff = facing.angle_to(to_cloud)
    var max_turn = personal_turn_speed * delta
    facing = facing.rotated(clamp(angle_diff, -max_turn, max_turn))
    flight.target_speed_override = 260.0
    var dist = global_position.distance_to(target_cloud.global_position)
    if dist < 80:
        state = State.CLOUD_HIDE
        state_timer = randf_range(1.5, 3.0)
    if state_timer <= 0:
        state = State.REPOSITION
        state_timer = 2.0

func _cloud_hide(delta):
    flight.target_speed_override = 180.0
    if state_timer <= 0 or not in_cloud:
        state = State.ATTACK
        attack_timer = 0.0

func _get_spread() -> float:
    match state:
        State.PATROL:
            return 0.003
        State.ATTACK:
            return 0.007
        State.DESPERATE:
            return 0.015
        State.FLINCH:
            return 0.040
        _:
            return 0.008