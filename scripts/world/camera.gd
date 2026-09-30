extends Camera2D

# Camera que segue o player
var target: Node2D

func _ready() -> void:
	get_target()
	
func _process(_delta: float) -> void:
	position = target.position

# Treme a tela por um instante (usado quando alguem leva dano)
func shake(strength = 3.0):
	var tween = create_tween()
	for i in 6:
		var random_offset = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
		tween.tween_property(self, "offset", random_offset, 0.03)
	tween.tween_property(self, "offset", Vector2.ZERO, 0.03)

# procura o player pelo grupo
func get_target():
	var nodes = get_tree().get_nodes_in_group("Player")
	if nodes.size() == 0:
		push_error("Player not found")
		return
		
	target = nodes[0]
