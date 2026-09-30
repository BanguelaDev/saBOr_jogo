extends CharacterBody2D

enum OrcState {
	idle,
	walk,
	attack,
	hurt
}

const HIT_EFFECT = preload("res://entities/hit_effect.tscn")

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var wall_detector: RayCast2D = $WallDetector
@onready var ground_detector: RayCast2D = $GroundDetector
@onready var player_detector: RayCast2D = $PlayerDetector
@onready var attack_detector: RayCast2D = $AttackDetector

const SPEED = 12.0

# Orc: anda atras do player e ataca com a lança

var status: OrcState

var direction = 1
var can_hit = true
var is_dead = false

func _ready() -> void:
	go_to_idle_state()

func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity += get_gravity() * delta

	match status:
		OrcState.idle:
			idle_state(delta)
		OrcState.walk:
			walk_state(delta)
		OrcState.attack:
			attack_state(delta)
		OrcState.hurt:
			hurt_state(delta)

	move_and_slide()

func go_to_idle_state():
	status = OrcState.idle
	anim.play("idle")
	velocity.x = 0

func go_to_walk_state():
	status = OrcState.walk
	anim.play("walking_&_blink")

func go_to_attack_state():
	status = OrcState.attack
	anim.play("spear_jab")
	velocity = Vector2.ZERO
	can_hit = true

func go_to_hurt_state():
	if is_dead:
		return

	status = OrcState.hurt
	anim.play("hurt")
	hit_feedback()
	hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	velocity = Vector2.ZERO
	is_dead = true

	get_tree().create_timer(0.5).timeout.connect(func():
		if is_instance_valid(self):
			queue_free()
	)

# estados: parado, andando, atacando e machucado
func idle_state(_delta):
	velocity.x = 0

	if player_detector.is_colliding():
		go_to_walk_state()

func walk_state(_delta):
	velocity.x = SPEED * direction

	if wall_detector.is_colliding():
		flip()
	elif not ground_detector.is_colliding():
		flip()

	if not player_detector.is_colliding():
		go_to_idle_state()
		return

	if attack_detector.is_colliding():
		go_to_attack_state()
		return

func attack_state(_delta):
	if anim.frame == 3 and can_hit:
		try_hit_player()
		can_hit = false

func hurt_state(_delta):
	pass

func flip():
	scale.x *= -1
	direction *= -1

func hit_feedback():
	var effect = HIT_EFFECT.instantiate()
	effect.color = Color(0.55, 1, 0.4)
	get_parent().add_child(effect)
	effect.global_position = global_position

	anim.modulate = Color(5, 5, 5)
	create_tween().tween_property(anim, "modulate", Color.WHITE, 0.2)

func take_damage():
	go_to_hurt_state()

# só machuca no frame certo da animação, se o player ainda estiver na frente
func try_hit_player():
	if attack_detector.is_colliding():
		var collider = attack_detector.get_collider()
		if collider and collider.has_method("take_damage_from"):
			collider.take_damage_from(1)

func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "spear_jab":
		if attack_detector.is_colliding():
			go_to_attack_state()
		elif player_detector.is_colliding():
			go_to_walk_state()
		else:
			go_to_idle_state()
