extends Label

# Mostra quantas moedas o jogador tem

func _process(_delta):
	text = str(GameState.coins)
