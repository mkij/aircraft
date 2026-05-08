extends Area2D

var hp = 1
var score_value = 10
var speed = 200.0
var player = null

func _ready():
	add_to_group("enemies")
	area_entered.connect(_on_area_entered)
	body_entered.connect(_on_body_entered)

func _process(delta):
	pass

func take_hit():
	hp -= 1
	if hp <= 0:
		die()

func die():
	if is_instance_valid(get_parent()) and get_parent().has_method("add_score"):
		get_parent().add_score(score_value)
	queue_free()

func find_player():
	var players = get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

func _on_area_entered(area):
	if area.is_in_group("player_bullet"):
		take_hit()

func _on_body_entered(body):
	pass
