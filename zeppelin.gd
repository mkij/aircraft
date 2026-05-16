extends Node2D

const FLY_SPEED = 50.0
const GONDOLA_SWAY_SPEED = 1.5
const GONDOLA_SWAY_X = 8.0
const GONDOLA_SWAY_Y = 3.0

var hull: Node2D = null
var tail: Node2D = null
var gondola: Node2D = null
var turrets = []
var sway_timer = 0.0
var total_parts = 3
var destroyed_parts = 0
var dead = false
var score_value = 500

func _ready():
	_build_zeppelin()

func _build_zeppelin():
	var zep_part_script = preload("res://zep_part.gd")
	var zep_turret_script = preload("res://zep_turret.gd")

	hull = Area2D.new()
	hull.set_script(zep_part_script)
	add_child(hull)
	hull.setup("hull", 12, self, Vector2(200, 50))

	tail = Area2D.new()
	tail.set_script(zep_part_script)
	tail.position = Vector2(-130, 0)
	add_child(tail)
	tail.setup("tail", 8, self, Vector2(80, 35))

	gondola = Node2D.new()
	gondola.position = Vector2(0, 55)
	add_child(gondola)

	var gondola_body = Area2D.new()
	gondola_body.set_script(zep_part_script)
	gondola.add_child(gondola_body)
	gondola_body.setup("gondola", 6, self, Vector2(70, 15))

	var turret_offsets = [Vector2(-25, 0), Vector2(25, 0), Vector2(0, 12)]
	for offset in turret_offsets:
		var turret = Area2D.new()
		turret.set_script(zep_turret_script)
		turret.position = offset
		gondola.add_child(turret)
		turrets.append(turret)

func _process(delta):
	if dead:
		return

	position.x -= FLY_SPEED * delta

	sway_timer += delta
	gondola.position.x = sin(sway_timer * GONDOLA_SWAY_SPEED) * GONDOLA_SWAY_X
	gondola.position.y = 55 + sin(sway_timer * GONDOLA_SWAY_SPEED * 1.3) * GONDOLA_SWAY_Y

	var cam_x = 0.0
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		cam_x = players[0].global_position.x
	if position.x < cam_x - 1500:
		queue_free()

	queue_redraw()

func on_part_destroyed(part_name: String):
	destroyed_parts += 1
	if destroyed_parts >= total_parts:
		_die()

func _die():
	dead = true
	var main = get_parent()
	if main and main.has_method("add_score"):
		main.add_score(score_value)
	for turret in turrets:
		turret.destroyed = true

	var tween = create_tween()
	tween.tween_property(self, "rotation", rotation + 0.3, 3.0)
	tween.parallel().tween_property(self, "position:y", position.y + 500, 3.0).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 3.0)
	tween.tween_callback(queue_free)

func _draw():
	draw_line(Vector2(-20, 30), Vector2(gondola.position.x - 15, gondola.position.y - 8), Color(0.4, 0.38, 0.35), 1.5)
	draw_line(Vector2(20, 30), Vector2(gondola.position.x + 15, gondola.position.y - 8), Color(0.4, 0.38, 0.35), 1.5)

	var body_points = PackedVector2Array()
	for i in range(32):
		var angle = TAU * i / 32.0
		body_points.append(Vector2(cos(angle) * 150, sin(angle) * 30))
	draw_colored_polygon(body_points, Color(0.55, 0.55, 0.5))

	var tail_points = PackedVector2Array()
	for i in range(16):
		var angle = TAU * i / 16.0
		tail_points.append(Vector2(-130 + cos(angle) * 40, sin(angle) * 18))
	draw_colored_polygon(tail_points, Color(0.5, 0.5, 0.45))