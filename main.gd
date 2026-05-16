extends Node2D

const ENEMY_SCENE = preload("res://Enemy.tscn")
const ACE_SCENE = preload("res://EnemyAce.tscn")
const AA_GUN_SCENE = preload("res://AAGun.tscn")
const BOMBER_SCENE = preload("res://EnemyBomber.tscn")
const BALLOON_SCENE = preload("res://Balloon.tscn")
const CONVOY_VEHICLE_SCENE = preload("res://ConvoyVehicle.tscn")
const CONVOY_AA_SCENE = preload("res://ConvoyAA.tscn")
const ZEPPELIN_SCENE = preload("res://Zeppelin.tscn")

var score = 0
var enemies_spawned = 0
var total_enemies = 3

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	$EnemySpawner.timeout.connect(_on_spawn_timer)
	var debug_label = Label.new()
	debug_label.name = "DebugLabel"
	debug_label.position = Vector2(20, 80)
	$CanvasLayer.add_child(debug_label)
	_spawn_gameplay_clouds()
	_spawn_aa_guns()
	_spawn_balloons()
	_spawn_convoy()
	_spawn_zeppelin()

func _spawn_gameplay_clouds():
	var cloud_script = preload("res://game_cloud.gd")
	for i in range(5):
		var cloud = Area2D.new()
		cloud.set_script(cloud_script)
		cloud.position = Vector2(
			$Player.position.x + 600 + i * 800,
			randf_range(100, 400)
		)
		add_child(cloud)	

func _spawn_aa_guns():
	for i in range(2):
		var gun = AA_GUN_SCENE.instantiate()
		gun.position = Vector2(
			$Player.position.x + 1200 + i * 1000,
			568
		)
		add_child(gun)

func _spawn_balloons():
	for i in range(3):
		var balloon = BALLOON_SCENE.instantiate()
		balloon.position = Vector2(
			$Player.position.x + 800 + i * 600,
			randf_range(150, 380)
		)
		add_child(balloon)

func _spawn_convoy():
	var convoy_x = $Player.position.x + 1500
	var types = ["truck", "car", "truck", "aa", "truck"]
	for i in range(types.size()):
		var vehicle
		if types[i] == "aa":
			vehicle = CONVOY_AA_SCENE.instantiate()
		else:
			vehicle = CONVOY_VEHICLE_SCENE.instantiate()
			vehicle.setup(types[i])
		vehicle.position = Vector2(convoy_x + i * 80, 568)
		add_child(vehicle)	

func _spawn_zeppelin():
	var zep = ZEPPELIN_SCENE.instantiate()
	zep.position = Vector2($Player.position.x + 1800, 200)
	add_child(zep)			

func update_debug(speed, climb, stalling):
	$CanvasLayer/DebugLabel.text = "Speed: " + str(snapped(speed, 0.1)) + "\nClimb: " + str(snapped(climb, 0.01)) + "\nStall: " + str(stalling)	

func _on_spawn_timer():
	if enemies_spawned >= total_enemies:
		$EnemySpawner.stop()
		return
	if get_tree().get_nodes_in_group("enemies").size() >= 3:
		return
	var enemy
	if enemies_spawned == 0:
		enemy = BOMBER_SCENE.instantiate()
		enemy.position = Vector2($Player.position.x + 900, randf_range(150, 350))
	elif enemies_spawned == total_enemies - 1:
		enemy = ACE_SCENE.instantiate()
		enemy.position = Vector2($Player.position.x + 800, randf_range(80, 520))
	else:
		enemy = ENEMY_SCENE.instantiate()
		enemy.position = Vector2($Player.position.x + 800, randf_range(80, 520))
	add_child(enemy)
	enemies_spawned += 1

func _process(delta):
	if enemies_spawned >= total_enemies and get_tree().get_nodes_in_group("enemies").size() == 0:
		game_over()	

func add_score(points):
	score += points
	$CanvasLayer/ScoreLabel.text = "Score: " + str(score)

func update_hp(hp):
	$CanvasLayer/HPLabel.text = "HP: " + str(hp)

func game_over():
	get_tree().paused = true
	if enemies_spawned >= total_enemies:
		$CanvasLayer/GameOverLabel.text = "VICTORY!\nSpacja = restart"
	$CanvasLayer/GameOverLabel.visible = true

func _input(event):
	if event.is_action_pressed("ui_accept") and get_tree().paused:
		get_tree().paused = false
		get_tree().reload_current_scene()
