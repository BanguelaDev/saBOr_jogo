extends Area2D

# Osso girando que o esqueleto joga (anda reto ate bater em algo)

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D

var speed = 60
var direction = 1

func _process(delta: float) -> void:
	position.x += speed * delta * direction

func set_direction(skeleton_direction):
	direction = skeleton_direction
	anim.flip_h = direction < 0

func _on_self_destruct_timer_timeout() -> void:
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	# atravessa o player enquanto ele esta na forma de particula
	if area.get_parent().get("special_active"):
		return
	queue_free()

func _on_body_entered(body: Node2D) -> void:
	# o corpo do player tambem e atravessado na forma de particula
	if body.get("special_active"):
		return
	queue_free()
