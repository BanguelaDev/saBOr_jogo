extends CharacterBody2D

enum SkeletonState {
	walk,
	attack,
	hurt
}

const SPINNING_BONE = preload("res://entities/spinning_bone.tscn")

const HIT_EFFECT = preload("res://entities/hit_effect.tscn")

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox: Area2D = $Hitbox
@onready var wall_detector: RayCast2D = $WallDetector
@onready var ground_detector: RayCast2D = $GroundDetector
@onready var player_detector: RayCast2D = $PlayerDetector
@onready var bone_start_position: Node2D = $BoneStartPosition

# Esqueleto: patrulha, joga osso quando ve o player

const SPEED = 7.0
const JUMP_VELOCITY = -400.0

var status: SkeletonState

var direction = 1
var can_throw = true
var is_dead = false

func _ready() -> void:
	go_to_walk_state()

func _physics_process(delta: float) -> void:

	if not is_on_floor():
		velocity += get_gravity() * delta

	match status:
		SkeletonState.walk:
			walk_state(delta)
		SkeletonState.attack:
			attack_state(delta)
		SkeletonState.hurt:
			hurt_state(delta)

	move_and_slide()

func go_to_walk_state():
	status = SkeletonState.walk
	anim.play("walk")

func go_to_attack_state():
	status = SkeletonState.attack
	anim.play("attack")
	velocity = Vector2.ZERO
	can_throw = true

func go_to_hurt_state():
	if is_dead:
		return

	status = SkeletonState.hurt
	anim.play("hurt")
	hit_feedback()
	hitbox.process_mode = Node.PROCESS_MODE_DISABLED
	velocity = Vector2.ZERO

# so anda nos frames 3 e 4 da animacao (passo manco)
func walk_state(_delta):
	if anim.frame == 3 or anim.frame == 4:
		velocity.x = SPEED * direction
	else:
		velocity.x = 0

	if wall_detector.is_colliding():
		scale.x *= -1
		direction *= -1

	if not ground_detector.is_colliding():
		scale.x *= -1
		direction *= -1

	if player_detector.is_colliding():
		go_to_attack_state()
		return

func attack_state(_delta):
	if anim.frame == 2 && can_throw:
		throw_bone()
		can_throw = false

func hurt_state(_delta):
	pass

func hit_feedback():
	var effect = HIT_EFFECT.instantiate()
	effect.color = Color(0.9, 0.95, 1)
	get_parent().add_child(effect)
	effect.global_position = global_position

	anim.modulate = Color(5, 5, 5)
	create_tween().tween_property(anim, "modulate", Color.WHITE, 0.2)

func take_damage():
	go_to_hurt_state()

# cria o osso na posição da mão
func throw_bone():
	var new_bone = SPINNING_BONE.instantiate()
	add_sibling(new_bone)
	new_bone.position = bone_start_position.global_position
	new_bone.set_direction(self.direction)

func _on_animated_sprite_2d_animation_finished() -> void:
	if anim.animation == "attack":
		go_to_walk_state()
		return
	if anim.animation == "hurt":
		is_dead = true
		queue_free()
		return
