extends Node2D

const ENEMY_SCENE = preload("res://Enemy.tscn")

var score = 0

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	$EnemySpawner.timeout.connect(_on_spawn_timer)
	var debug_label = Label.new()
	debug_label.name = "DebugLabel"
	debug_label.position = Vector2(20, 80)
	$CanvasLayer.add_child(debug_label)

func update_debug(speed, climb, stalling):
	$CanvasLayer/DebugLabel.text = "Speed: " + str(snapped(speed, 0.1)) + "\nClimb: " + str(snapped(climb, 0.01)) + "\nStall: " + str(stalling)	

func _on_spawn_timer():
	if get_tree().get_nodes_in_group("enemies").size() >= 3:
		return
	var enemy = ENEMY_SCENE.instantiate()
	enemy.position = Vector2($Player.position.x + 800, randf_range(80, 520))
	add_child(enemy)

func add_score(points):
	score += points
	$CanvasLayer/ScoreLabel.text = "Score: " + str(score)

func update_hp(hp):
	$CanvasLayer/HPLabel.text = "HP: " + str(hp)

func game_over():
	get_tree().paused = true
	$CanvasLayer/GameOverLabel.visible = true

func _input(event):
	if event.is_action_pressed("ui_accept") and get_tree().paused:
		get_tree().paused = false
		get_tree().reload_current_scene()
