extends Area2D

# Moeda coletavel

const HIT_EFFECT = preload("res://entities/hit_effect.tscn")

func _ready():
	body_entered.connect(_on_body_entered)
	# a moeda sobe e desce devagar
	var tween = create_tween().set_loops()
	tween.tween_property(self, "position:y", position.y - 3, 0.6)
	tween.tween_property(self, "position:y", position.y, 0.6)

func _on_body_entered(body):
	if not body.is_in_group("Player"):
		return
	GameState.coins += 1
	var effect = HIT_EFFECT.instantiate()
	effect.color = Color(1, 0.9, 0.3)
	get_parent().add_child(effect)
	effect.global_position = global_position
	queue_free()
