extends Node2D

# Ataque especial (M2), onda de choque ao redor do player.
# Machuca todos os inimigos dentro do raio.
@export var radius = 56.0

func _ready():
	# deferred: espera o player posicionar a nova antes de medir a distancia
	call_deferred("hit_enemies")

func hit_enemies():
	for area in get_tree().get_nodes_in_group("Enemies"):
		if is_instance_valid(area) and global_position.distance_to(area.global_position) <= radius:
			area.get_parent().take_damage()

	var camera = get_viewport().get_camera_2d()
	if camera:
		camera.shake(2)

	# some depois que as estrelas acabam
	get_tree().create_timer(1.0).timeout.connect(queue_free)
