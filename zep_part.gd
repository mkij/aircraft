extends Area2D

var part_hp = 10
var part_name = "hull"
var destroyed = false
var zeppelin_parent = null

func _ready():
	add_to_group("enemies")
	area_entered.connect(_on_area_entered)

func setup(p_name: String, p_hp: int, p_parent: Node2D, shape_size: Vector2):
	part_name = p_name
	part_hp = p_hp
	zeppelin_parent = p_parent
	var col = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = shape_size
	col.shape = shape
	add_child(col)

func _on_area_entered(area):
	if area.is_in_group("player_bullet") and not destroyed:
		take_hit()

func take_hit():
	part_hp -= 1
	_flash()
	if part_hp <= 0:
		destroyed = true
		modulate = Color(0.3, 0.2, 0.15, 0.6)
		if zeppelin_parent and zeppelin_parent.has_method("on_part_destroyed"):
			zeppelin_parent.on_part_destroyed(part_name)

func _flash():
	modulate = Color(2.0, 0.8, 0.8, 1.0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1, 1, 1, 1) if not destroyed else Color(0.3, 0.2, 0.15, 0.6), 0.15)