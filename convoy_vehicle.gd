extends "res://base_enemy.gd"

const GROUND_Y = 568.0

var drive_speed = 80.0
var drive_direction = -1.0
var vehicle_width = 36.0
var vehicle_height = 16.0

func _ready():
	super._ready()
	hp = 2
	score_value = 15
	speed = 0.0
	position.y = GROUND_Y

func _process(delta):
	position.x += drive_speed * drive_direction * delta

	var cam_x = 0.0
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		cam_x = players[0].global_position.x
	if position.x < cam_x - 1200 or position.x > cam_x + 2000:
		queue_free()

	queue_redraw()

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage()

func setup(type: String):
	match type:
		"truck":
			hp = 2
			score_value = 15
			drive_speed = 80.0
			vehicle_width = 36.0
			vehicle_height = 16.0
		"car":
			hp = 1
			score_value = 10
			drive_speed = 120.0
			vehicle_width = 24.0
			vehicle_height = 12.0

func _draw():
	draw_rect(Rect2(-vehicle_width / 2, -vehicle_height, vehicle_width, vehicle_height), Color(0.45, 0.4, 0.3))
	draw_rect(Rect2(-vehicle_width / 2 + 4, -vehicle_height - 8, vehicle_width * 0.5, 8), Color(0.4, 0.38, 0.28))
	draw_circle(Vector2(-vehicle_width / 3, 0), 4, Color(0.2, 0.2, 0.2))
	draw_circle(Vector2(vehicle_width / 3, 0), 4, Color(0.2, 0.2, 0.2))

func die():
	if is_instance_valid(get_parent()) and get_parent().has_method("add_score"):
		get_parent().add_score(score_value)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 0.3, 0, 0.8), 0.3)
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)