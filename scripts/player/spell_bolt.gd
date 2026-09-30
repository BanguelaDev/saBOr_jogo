extends Area2D

# Tiro de magia: anda reto, machuca inimigo e some ao bater

const HIT_EFFECT = preload("res://entities/hit_effect.tscn")

@export var speed = 240.0
@export var lifetime = 2.0

var direction = 1

func _ready() -> void:
	get_tree().create_timer(lifetime).timeout.connect(_on_lifetime_timeout)

func set_direction(new_direction: int) -> void:
	direction = new_direction
	if direction < 0:
		scale.x = -1

func _physics_process(delta: float) -> void:
	position.x += speed * direction * delta

func _on_lifetime_timeout() -> void:
	if is_instance_valid(self):
		queue_free()

func _on_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemies"):
		area.get_parent().take_damage()
		impact()
		queue_free()

func _on_body_entered(_body: Node2D) -> void:
	impact()
	queue_free()

func impact() -> void:
	var effect = HIT_EFFECT.instantiate()
	effect.amount = 7
	effect.color = Color(0.6, 0.8, 1)
	get_parent().add_child(effect)
	effect.global_position = global_position
