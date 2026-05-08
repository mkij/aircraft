extends Node2D

const SCREEN_W = 1152.0
const SCREEN_H = 648.0
const GROUND_Y = 580.0
const SKY_TOP = 40.0

var clouds = []

func _ready():
	z_index = -10
	for i in range(15):
		clouds.append({
			"x": randf_range(-2000, 2000),
			"y": randf_range(SKY_TOP, GROUND_Y * 0.75),
			"w": randf_range(80, 200),
			"h": randf_range(25, 55),
		})

func _process(delta):
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	var px = players[0].global_position.x
	for cloud in clouds:
		if cloud["x"] < px - SCREEN_W:
			cloud["x"] = px + SCREEN_W + randf_range(0, 400)
			cloud["y"] = randf_range(SKY_TOP, GROUND_Y * 0.75)
	queue_redraw()

func _draw():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() == 0:
		return
	var px = players[0].global_position.x
	var left = px - SCREEN_W
	var right = px + SCREEN_W

	draw_rect(Rect2(left, -3000, right - left, GROUND_Y + 3000), Color(0.38, 0.62, 0.92))
	draw_rect(Rect2(left, GROUND_Y, right - left, 3000), Color(0.18, 0.48, 0.28))

	for cloud in clouds:
		draw_rect(Rect2(cloud["x"], cloud["y"], cloud["w"], cloud["h"]), Color(1, 1, 1, 0.8))
