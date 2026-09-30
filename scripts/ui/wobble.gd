extends Node

@export var bob = 3.0
@export var tilt = 4.0
@export var pulse = 0.05
@export var time = 0.6
@export var delay = 0.0

func _ready():
	call_deferred("start")

func start():
	var target = get_parent()
	if target is Control:
		target.pivot_offset = target.size / 2
	var y = target.position.y
	var size = target.scale

	if delay > 0:
		await get_tree().create_timer(delay).timeout

	var tween = create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(target, "position:y", y - bob, time)
	tween.parallel().tween_property(target, "rotation_degrees", tilt, time)
	tween.parallel().tween_property(target, "scale", size * (1 + pulse), time)

	tween.tween_property(target, "position:y", y, time)
	tween.parallel().tween_property(target, "rotation_degrees", -tilt, time)
	tween.parallel().tween_property(target, "scale", size * (1 - pulse), time)
