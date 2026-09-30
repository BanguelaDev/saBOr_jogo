extends AnimatableBody2D

@onready var target: Sprite2D = $Target

# Plataforma que vai e volta ate o ponto marcado pelo node Target
@export var time = 1   # segundos de ida e de volta

func _ready() -> void:
	
	# o Target so marca o destino, nao aparece no jogo
	target.visible = false
	
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "global_position", target.global_position, time)
	tween.tween_property(self, "global_position", global_position, time)
	tween.set_loops()
