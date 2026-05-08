extends Area2D

var speed = 250.0
var hp = 1
var score_value = 10

func _ready():
    add_to_group("enemies")
    area_entered.connect(_on_area_entered)
    body_entered.connect(_on_body_entered)

func setup(type: String):
    match type:
        "scout":
            speed = 350.0
            hp = 1
            score_value = 10
            scale = Vector2(0.8, 0.8)
        "fighter":
            speed = 200.0
            hp = 3
            score_value = 30
            scale = Vector2(1.0, 1.0)
        "heavy":
            speed = 120.0
            hp = 6
            score_value = 60
            scale = Vector2(1.4, 1.4)

func _process(delta):
    position.x -= speed * delta
    if position.x < -100:
        queue_free()

func _on_area_entered(area):
    hp -= 1
    if hp <= 0:
        get_parent().add_score(score_value)
        queue_free()

func _on_body_entered(body):
    if body.has_method("take_damage"):
        body.take_damage()
    queue_free()
