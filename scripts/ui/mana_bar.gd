extends ProgressBar

# Barra de mana: acompanha o valor de mana do player

var player: Node = null

func _ready() -> void:
	# deferred: o player pode ainda nao estar na cena
	call_deferred("find_player")

func find_player() -> void:
	var nodes = get_tree().get_nodes_in_group("Player")
	if nodes.size() == 0:
		return
	player = nodes[0]
	if "max_mana" in player:
		max_value = player.max_mana
	value = max_value

func _process(_delta: float) -> void:
	if player == null or not is_instance_valid(player):
		find_player()
		return

	if "max_mana" in player:
		max_value = player.max_mana
	if "mana" in player:
		value = player.mana
