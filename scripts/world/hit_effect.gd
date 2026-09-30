extends CPUParticles2D

# Explosao rapida de particulas

func _ready() -> void:
	finished.connect(queue_free)
