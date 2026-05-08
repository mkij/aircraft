extends Node2D

const SCROLL_SPEED = 150.0
const SCREEN_W = 1152.0
const SCREEN_H = 648.0

var clouds = []

func _ready():
    z_index = -10
    for i in range(10):
        clouds.append({
            "x": randf_range(0, SCREEN_W),
            "y": randf_range(40, SCREEN_H * 0.55),
            "w": randf_range(70, 180),
            "h": randf_range(20, 55),
            "speed": randf_range(0.4, 1.0)
        })

func _process(delta):
    for cloud in clouds:
        cloud["x"] -= SCROLL_SPEED * cloud["speed"] * delta
        if cloud["x"] < -200:
            cloud["x"] = SCREEN_W + 100
            cloud["y"] = randf_range(40, SCREEN_H * 0.55)
    queue_redraw()

func _draw():
    draw_rect(Rect2(0, 0, SCREEN_W, SCREEN_H * 0.78), Color(0.38, 0.62, 0.92))
    draw_rect(Rect2(0, SCREEN_H * 0.78, SCREEN_W, SCREEN_H * 0.22), Color(0.18, 0.48, 0.28))
    for cloud in clouds:
        draw_rect(Rect2(cloud["x"], cloud["y"], cloud["w"], cloud["h"]), Color(1, 1, 1, 0.75))
