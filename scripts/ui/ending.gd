extends Control

# Tela final: o texto do Hint e escrito na cena, aqui so soma as moedas
@onready var hint: Label = $Panel/Hint

func _ready():
	hint.text += "\nMoedas coletadas: " + str(GameState.coins)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		get_tree().change_scene_to_file("res://scene/menu.tscn")
