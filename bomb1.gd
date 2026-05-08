extends Area2D

const GRAVITY = 600.0
const BLAST_RADIUS = 80.0

var velocity = Vector2.ZERO

func setup(player_velocity: Vector2):
    velocity.x = player_velocity.x
    velocity.y = 0.0

func _process(delta):
    velocity.y += GRAVITY * delta
    position += velocity * delta
    rotation = velocity.angle()

    if position.y > 700:
        queue_free()

func _on_area_entered(area):
    explode()

func _on_body_entered(body):
    explode()

func explode():
    var areas = get_tree().get_nodes_in_group("enemies")
    for enemy in areas:
        if global_position.distance_to(enemy.global_position) <= BLAST_RADIUS:
            if enemy.has_method("setup"):
                enemy.queue_free()
                get_parent().add_score(enemy.score_value)
    queue_free()
