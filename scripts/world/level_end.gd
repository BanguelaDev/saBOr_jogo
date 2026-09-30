extends Area2D

# Bandeira do fim da fase: next_level e o nome da cena seguinte

@export var next_level = ""

func _on_body_entered(_body: Node2D) -> void:
	call_deferred("load_next_scene")

func load_next_scene():
	# guarda as moedas: se morrer na proxima fase volta pra este valor
	GameState.saved_coins = GameState.coins
	get_tree().change_scene_to_file("res://scene/" + next_level + ".tscn")
