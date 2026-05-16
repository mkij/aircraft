extends Area2D

const CLOUD_SPEED = 30.0

var cloud_width = 250.0
var cloud_height = 120.0

func _ready():
	var shape = RectangleShape2D.new()
	shape.size = Vector2(cloud_width, cloud_height)
	var col = CollisionShape2D.new()
	col.shape = shape
	add_child(col)
	add_to_group("game_clouds")

	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	area_entered.connect(_on_area_entered)
	area_exited.connect(_on_area_exited)

func _process(delta):
	position.x -= CLOUD_SPEED * delta

func _draw():
	draw_rect(Rect2(-cloud_width / 2, -cloud_height / 2, cloud_width, cloud_height), Color(1, 1, 1, 0.35))
	draw_rect(Rect2(-cloud_width * 0.35, -cloud_height * 0.7, cloud_width * 0.5, cloud_height * 0.5), Color(1, 1, 1, 0.25))

func _on_body_entered(body):
	if body.is_in_group("player") and body.has_method("enter_cloud"):
		body.enter_cloud()

func _on_body_exited(body):
	if body.is_in_group("player") and body.has_method("exit_cloud"):
		body.exit_cloud()

func _on_area_entered(area):
	if area.is_in_group("enemies") and "in_cloud" in area:
		area.in_cloud = true

func _on_area_exited(area):
	if area.is_in_group("enemies") and "in_cloud" in area:
		area.in_cloud = false