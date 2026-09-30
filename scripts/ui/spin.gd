extends Node

# Gira o node pai sem parar (usado nos raios do fundo)
@export var speed = 6.0   # graus por segundo

func _process(delta):
	get_parent().rotation_degrees += speed * delta
