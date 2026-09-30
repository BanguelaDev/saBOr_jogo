extends HBoxContainer

const FULL = preload("res://sprites/ui/heart_full.svg")
const EMPTY = preload("res://sprites/ui/heart_empty.svg")

var player = null

func _process(_delta):
	if player == null or not is_instance_valid(player):
		find_player()
		return
	# coracao cheio enquanto o indice for menor que a vida
	for i in get_child_count():
		if i < player.health:
			get_child(i).texture = FULL
		else:
			get_child(i).texture = EMPTY

func find_player():
	var nodes = get_tree().get_nodes_in_group("Player")
	if nodes.size() == 0:
		return
	player = nodes[0]
	# cria um coracao para cada ponto de vida maxima
	for i in player.max_health:
		var heart = TextureRect.new()
		add_child(heart)
