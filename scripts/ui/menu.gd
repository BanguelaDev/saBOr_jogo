extends Control

func _unhandled_input(event):
	var pressed_enter = event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE)
	var clicked = event is InputEventMouseButton and event.pressed
	if pressed_enter or clicked:
		GameState.coins = 0
		GameState.saved_coins = 0
		get_tree().change_scene_to_file("res://scene/game.tscn")
