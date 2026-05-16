extends "res://base_enemy.gd"

const GROUND_Y = 580.0

var sway_timer = 0.0
var sway_offset = 0.0
var base_x = 0.0

func _ready():
	super._ready()
	hp = 3
	score_value = 20
	speed = 0.0
	base_x = position.x
	sway_timer = randf_range(0, TAU)

func _process(delta):
	sway_timer += delta * 0.8
	sway_offset = sin(sway_timer) * 8.0
	position.x = base_x + sway_offset
	queue_redraw()

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage()

func _draw():
	var rope_bottom = GROUND_Y - global_position.y
	draw_line(Vector2(0, 0), Vector2(0, rope_bottom), Color(0.4, 0.4, 0.35), 1.5)
	_draw_balloon_shape(Vector2(0, 0), Vector2(18, 28), Color(0.6, 0.6, 0.55))
	_draw_balloon_shape(Vector2(0, 0), Vector2(15, 25), Color(0.7, 0.7, 0.65))

func _draw_balloon_shape(center: Vector2, size: Vector2, color: Color):
	var points = PackedVector2Array()
	for i in range(24):
		var angle = TAU * i / 24.0
		points.append(center + Vector2(cos(angle) * size.x, sin(angle) * size.y))
	draw_colored_polygon(points, color)

func die():
	if is_instance_valid(get_parent()) and get_parent().has_method("add_score"):
		get_parent().add_score(score_value)
	var tween = create_tween()
	tween.tween_property(self, "position:y", position.y - 100, 0.8).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.8)
	tween.tween_callback(queue_free)