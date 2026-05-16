class_name PlanePhysics

# Configuration
var passive_speed := 220.0
var max_speed := 320.0
var min_speed := 50.0
var gravity_effect := 120.0
var base_turn_speed := 3.0
var climb_turn_factor := 0.8
var stall_speed := 80.0
var stall_frames := 40
var stall_recovery_time := 3.0
var shot_rotation_recovery := 4.5
var use_climb_recovery := true
var target_speed_override := -1.0

# Runtime state
var speed := 220.0
var shot_rotation := 0.0
var stalling := false
var stall_counter := 0
var stall_timer := 3.0
var stall_spin_dir := 1.0

func get_turn_speed(climb: float) -> float:
	return base_turn_speed + climb * climb_turn_factor

func update_speed(climb: float, delta: float) -> void:
	if target_speed_override > 0:
		speed = move_toward(speed, target_speed_override, 200.0 * delta)
		target_speed_override = -1.0
	else:
		speed -= climb * gravity_effect * delta
		if speed < passive_speed:
			if use_climb_recovery:
				var recovery = 40.0 + (1.0 - clamp(climb, 0.0, 1.0)) * 120.0
				speed = move_toward(speed, passive_speed, recovery * delta)
			else:
				speed = move_toward(speed, passive_speed, 80.0 * delta)
		if speed > passive_speed:
			speed = lerp(speed, passive_speed, 1.5 * delta)
	speed = clamp(speed, min_speed, max_speed)

func check_stall() -> bool:
	if speed < stall_speed:
		stall_counter += 1
	else:
		stall_counter = 0
	if stall_counter >= stall_frames:
		stalling = true
		stall_timer = stall_recovery_time
		stall_spin_dir = 1.0 if randf() > 0.5 else -1.0
		return true
	return false

func exit_stall() -> void:
	stalling = false
	stall_counter = 0

func update_shot_rotation(delta: float) -> void:
	shot_rotation = move_toward(shot_rotation, 0.0, shot_rotation_recovery * delta)

func apply_hit() -> void:
	shot_rotation += randf_range(1.5, 3.0) * (1.0 if randf() > 0.5 else -1.0)

func handle_stall(delta: float, rotation: float, turn_speed: float) -> Dictionary:
	var new_rotation = rotation + 3.5 * stall_spin_dir * delta
	var climb = -sin(new_rotation)
	speed -= climb * gravity_effect * 1.5 * delta
	speed = clamp(speed, min_speed, max_speed)
	stall_timer -= delta
	if speed > stall_speed + 30:
		exit_stall()
	return {"rotation": new_rotation, "speed": speed, "stalling": stalling, "timeout": stall_timer <= 0}