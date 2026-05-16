extends Node2D

const SCREEN_W = 1152.0
const SCREEN_H = 648.0
const GROUND_Y = 580.0

var ground_details = []

func _ready():
	z_index = -10

	var bg_layer = CanvasLayer.new()
	bg_layer.layer = -10
	add_child(bg_layer)

	var sky = ColorRect.new()
	sky.color = Color(0.38, 0.62, 0.92)
	sky.position = Vector2(0, 0)
	sky.size = Vector2(SCREEN_W, GROUND_Y)
	bg_layer.add_child(sky)

	var ground = ColorRect.new()
	ground.color = Color(0.18, 0.48, 0.28)
	ground.position = Vector2(0, GROUND_Y)
	ground.size = Vector2(SCREEN_W, SCREEN_H - GROUND_Y + 100)
	bg_layer.add_child(ground)

	var parallax_bg = ParallaxBackground.new()
	get_parent().call_deferred("add_child", parallax_bg)

	var cloud_layer = ParallaxLayer.new()
	cloud_layer.motion_scale = Vector2(0.3, 0.8)
	cloud_layer.motion_mirroring = Vector2(3000, 0)
	parallax_bg.add_child(cloud_layer)

	for i in range(20):
		var cloud = ColorRect.new()
		cloud.color = Color(1, 1, 1, randf_range(0.4, 0.7))
		cloud.size = Vector2(randf_range(80, 220), randf_range(25, 60))
		cloud.position = Vector2(randf_range(0, 3000), randf_range(40, GROUND_Y * 0.65))
		cloud_layer.add_child(cloud)

	for i in range(30):
		ground_details.append({
			"x": randf_range(-3000, 5000),
			"y": randf_range(GROUND_Y + 5, GROUND_Y + 60),
			"w": randf_range(40, 150),
			"h": randf_range(8, 25),
			"color": Color(0.15, randf_range(0.38, 0.52), 0.22)
		})

func _process(delta):
	queue_redraw()

func _draw():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	var px = players[0].global_position.x
	for detail in ground_details:
		if detail["x"] + detail["w"] < px - SCREEN_W:
			detail["x"] = px + SCREEN_W + randf_range(0, 500)
		draw_rect(Rect2(detail["x"], detail["y"], detail["w"], detail["h"]), detail["color"])