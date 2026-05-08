extends Area2D

const GRAVITY = 350.0
const BLAST_RADIUS = 80.0

var velocity = Vector2.ZERO

func setup(player_velocity: Vector2):
    velocity = player_velocity

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
    var enemies = get_tree().get_nodes_in_group("enemies")
    for enemy in enemies:
        if global_position.distance_to(enemy.global_position) <= BLAST_RADIUS:
            get_parent().add_score(enemy.score_value)
            enemy.queue_free()
    queue_free()
