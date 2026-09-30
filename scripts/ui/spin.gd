extends Node

@export var speed = 6.0

func _process(delta):
	get_parent().rotation_degrees += speed * delta
