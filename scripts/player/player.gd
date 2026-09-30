extends CharacterBody2D

enum PlayerState {
	idle,
	walk,
	jump,
	fall,
	duck,
	slide,
	swimming,
	recovering,
	hurt,
	dead
}

# Player: maquina de estados (idle, walk, jump...) + magias
const SPELL_BOLT_SCENE = preload("res://entities/spell_bolt.tscn")
const NOVA_SCENE = preload("res://entities/nova.tscn")
const HIT_EFFECT = preload("res://entities/hit_effect.tscn")

@onready var anim: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var hitbox: Area2D = $Hitbox
@onready var hitbox_collision_shape: CollisionShape2D = $Hitbox/CollisionShape2D

@onready var reload_timer: Timer = $ReloadTimer

@export var max_speed = 180.0
@export var acceleration = 400
@export var deceleration = 400
@export var slide_deceleration = 100
@export var water_max_speed = 100
@export var water_acceleration = 200
@export var water_jump_force = -100

@export var max_health = 3
@export var invulnerability_time = 1.0
@export var death_pause_time = 1.5

@export var hard_landing_speed = 220.0

const JUMP_VELOCITY = -300.0

# altura do tiro em relacao ao centro do player (meio do corpo do sprite)
@export var muzzle_offset = Vector2(8, -4)

@export var max_mana = 100.0
@export var mana_regen_rate = 14.0
@export var basic_cast_cost = 12.0
@export var channel_tick_cost = 6.0
@export var channel_tick_interval = 0.22
@export var special_cost = 45.0
@export var special_cooldown = 2.2
@export var special_duration = 0.5   # tempo na forma de particula (imune)

var jump_count = 0
@export var max_jump_count = 2
var direction = 0
var status: PlayerState

var health: int
var mana: float
var is_busy_action = false
var is_invulnerable = false
var is_channeling = false
var channel_tick_accum = 0.0
var special_ready = true
var special_active = false

func _ready() -> void:
	health = max_health
	mana = max_mana
	reload_timer.wait_time = death_pause_time
	go_to_idle_state()

func _physics_process(delta: float) -> void:

	regen_mana(delta)
	handle_combat_input()

	if is_channeling:
		process_channel(delta)

	match status:
		PlayerState.idle:
			idle_state(delta)
		PlayerState.walk:
			walk_state(delta)
		PlayerState.jump:
			jump_state(delta)
		PlayerState.fall:
			fall_state(delta)
		PlayerState.duck:
			duck_state(delta)
		PlayerState.slide:
			slide_state(delta)
		PlayerState.swimming:
			swimming_state(delta)
		PlayerState.recovering:
			recovering_state(delta)
		PlayerState.hurt:
			hurt_state(delta)
		PlayerState.dead:
			dead_state(delta)

	move_and_slide()

func go_to_idle_state():
	status = PlayerState.idle
	if not is_busy_action:
		anim.play("idle")

func go_to_walk_state():
	status = PlayerState.walk
	if not is_busy_action:
		anim.play("run")

func go_to_jump_state():
	status = PlayerState.jump
	if not is_busy_action:
		anim.play("jump")
	velocity.y = JUMP_VELOCITY
	jump_count += 1

func go_to_fall_state():
	status = PlayerState.fall
	if not is_busy_action:
		anim.play("fall")

func go_to_duck_state():
	status = PlayerState.duck
	if not is_busy_action:
		anim.play("duck")
	set_small_collider()

func exit_from_duck_state():
	set_large_collider()

func go_to_slide_state():
	status = PlayerState.slide
	if not is_busy_action:
		anim.play("slide")
	set_small_collider()

func exit_from_slide_state():
	set_large_collider()

func go_to_swimming_state():
	status = PlayerState.swimming
	if not is_busy_action:
		anim.play("swimming")
	velocity.y = min(velocity.y, 150)

func go_to_recovering_state():
	status = PlayerState.recovering
	end_channel()
	is_busy_action = false
	anim.play("ground_recovery")
	velocity.x = 0

func go_to_hurt_state():
	if status == PlayerState.dead:
		return

	status = PlayerState.hurt
	end_channel()
	is_busy_action = false
	anim.play("hurt")
	# joga o player pra tras e pra cima
	velocity = Vector2(-facing_direction() * 90, -120)
	is_invulnerable = true
	get_tree().create_timer(invulnerability_time).timeout.connect(func(): is_invulnerable = false)

func go_to_dead_state():
	if status == PlayerState.dead:
		return

	status = PlayerState.dead
	end_channel()
	is_busy_action = false
	anim.play("hurt")
	velocity = Vector2.ZERO
	collision_shape.set_deferred("disabled", true)
	hitbox.set_deferred("monitoring", false)
	hitbox.set_deferred("monitorable", false)
	reload_timer.start()

# imune enquanto invulneravel ou na forma de particula (M2)
func take_damage_from(amount := 1):
	if is_invulnerable or special_active or status == PlayerState.hurt or status == PlayerState.dead:
		return

	health -= amount
	hit_feedback()
	if health <= 0:
		go_to_dead_state()
	else:
		go_to_hurt_state()

func hit_feedback():
	var effect = HIT_EFFECT.instantiate()
	effect.color = Color(1, 0.3, 0.3)
	get_parent().add_child(effect)
	effect.global_position = global_position

	var camera = get_viewport().get_camera_2d()
	if camera:
		camera.shake(3)

	anim.modulate = Color(4, 0.4, 0.4)
	var tween = create_tween()
	tween.tween_property(anim, "modulate", Color.WHITE, 0.15)
	for i in 4:
		tween.tween_property(anim, "modulate:a", 0.3, 0.1)
		tween.tween_property(anim, "modulate:a", 1.0, 0.1)

# --- estados ---
func idle_state(delta):
	apply_gravity(delta)
	move(delta)
	if velocity.x != 0:
		go_to_walk_state()
		return

	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return

	if Input.is_action_pressed("duck"):
		go_to_duck_state()
		return

func walk_state(delta):
	apply_gravity(delta)
	move(delta)
	if velocity.x == 0:
		go_to_idle_state()
		return

	if Input.is_action_just_pressed("jump"):
		go_to_jump_state()
		return

	if Input.is_action_just_pressed("duck"):
		go_to_slide_state()
		return

	if !is_on_floor():
		jump_count += 1
		go_to_fall_state()
		return

func jump_state(delta):
	apply_gravity(delta)
	move(delta)

	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
		return

	if velocity.y > 0:
		go_to_fall_state()
		return

func fall_state(delta):
	apply_gravity(delta)
	move(delta)

	if Input.is_action_just_pressed("jump") && can_jump():
		go_to_jump_state()
		return

	if is_on_floor():
		jump_count = 0
		if velocity.y > hard_landing_speed:
			go_to_recovering_state()
		elif velocity.x == 0:
			go_to_idle_state()
		else:
			go_to_walk_state()
		return

func duck_state(delta):
	apply_gravity(delta)
	update_direction()

	if is_busy_action:
		return

	if not Input.is_action_pressed("duck"):
		exit_from_duck_state()
		go_to_idle_state()
		return

func slide_state(delta):
	apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0, slide_deceleration * delta)

	if Input.is_action_just_released("duck"):
		exit_from_slide_state()
		go_to_walk_state()
		return

	if velocity.x == 0:
		exit_from_slide_state()
		go_to_duck_state()
		return

func swimming_state(delta):
	update_direction()

	if direction:
		velocity.x = move_toward(velocity.x, water_max_speed * direction, water_acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, water_acceleration * delta)

	velocity.y += water_acceleration * delta
	velocity.y = min(velocity.y, water_max_speed)

	if Input.is_action_just_pressed("jump"):
		velocity.y = water_jump_force

func recovering_state(delta):
	apply_gravity(delta)

func hurt_state(delta):
	apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0, 300 * delta)

func dead_state(_delta):
	pass

func move(delta):
	update_direction()

	if direction:
		velocity.x = move_toward(velocity.x, direction * max_speed, acceleration * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, deceleration * delta)

func apply_gravity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta

func update_direction():
	direction = Input.get_axis("left", "right")

	if direction < 0:
		anim.flip_h = true
	elif direction > 0:
		anim.flip_h = false

func can_jump() -> bool:
	return jump_count < max_jump_count

func set_small_collider():
	collision_shape.shape.radius = 5
	collision_shape.shape.height = 10
	collision_shape.position.y = 3

	hitbox_collision_shape.shape.size.y = 10
	hitbox_collision_shape.position.y = 3

func set_large_collider():
	collision_shape.shape.radius = 6
	collision_shape.shape.height = 16
	collision_shape.position.y = 0

	hitbox_collision_shape.shape.size.y = 15
	hitbox_collision_shape.position.y = 0.5

# --- mana e combate ---
func regen_mana(delta):
	if mana < max_mana:
		mana = min(max_mana, mana + mana_regen_rate * delta)

func blocked_from_casting() -> bool:
	return status == PlayerState.hurt or status == PlayerState.dead \
		or status == PlayerState.recovering or status == PlayerState.slide \
		or status == PlayerState.swimming

func handle_combat_input():
	if blocked_from_casting():
		return

	if is_channeling:
		return

	if is_busy_action:
		return

	if Input.is_action_just_pressed("heavy_cast"):
		start_special()
		return

	if Input.is_action_just_pressed("cast"):
		start_cast()
		return

# J / botao esquerdo: tiro simples
func start_cast():
	if mana < basic_cast_cost:
		return

	is_busy_action = true
	mana -= basic_cast_cost

	if status == PlayerState.jump or status == PlayerState.fall:
		anim.play("casting_spell_aerial")
	else:
		anim.play("casting_spell")

	spawn_bolt()

# segurando o botao, continua atirando
func start_channel():
	is_channeling = true
	is_busy_action = true
	channel_tick_accum = 0.0
	anim.play("casting_spell_repeating")

func process_channel(delta):
	if blocked_from_casting() or not Input.is_action_pressed("cast") or mana < channel_tick_cost:
		end_channel()
		return

	channel_tick_accum += delta
	if channel_tick_accum >= channel_tick_interval:
		channel_tick_accum = 0.0
		mana -= channel_tick_cost
		spawn_bolt()

func end_channel():
	if not is_channeling:
		return
	is_channeling = false
	is_busy_action = false
	resume_state_animation()

# G / botao direito: ataque especial
func start_special():
	if not special_ready or mana < special_cost:
		return

	is_busy_action = true
	special_ready = false
	mana -= special_cost
	anim.play("magical_orbs_spell")

	# forma de particula: fica imune e meio transparente ate acabar o tempo
	special_active = true
	anim.modulate = Color(0.6, 0.85, 1, 0.6)
	get_tree().create_timer(special_duration).timeout.connect(end_special)

	get_tree().create_timer(special_cooldown).timeout.connect(func(): special_ready = true)

func end_special():
	special_active = false
	anim.modulate = Color.WHITE

func facing_direction() -> int:
	return -1 if anim.flip_h else 1

func muzzle_position() -> Vector2:
	var facing = facing_direction()
	var height = muzzle_offset.y
	# agachado o corpo desce um pouco, o tiro acompanha
	if status == PlayerState.duck:
		height += 5
	return global_position + Vector2(muzzle_offset.x * facing, height)

func spawn_bolt():
	var bolt = SPELL_BOLT_SCENE.instantiate()
	get_parent().add_child(bolt)
	bolt.global_position = muzzle_position()
	bolt.set_direction(facing_direction())

func spawn_nova():
	var nova = NOVA_SCENE.instantiate()
	get_parent().add_child(nova)
	nova.global_position = global_position

func resume_state_animation():
	match status:
		PlayerState.idle:
			anim.play("idle")
		PlayerState.walk:
			anim.play("run")
		PlayerState.jump:
			anim.play("jump")
		PlayerState.fall:
			anim.play("fall")
		PlayerState.duck:
			anim.play("duck")
		PlayerState.slide:
			anim.play("slide")
		PlayerState.swimming:
			anim.play("swimming")
		PlayerState.recovering:
			anim.play("ground_recovery")

func _on_animated_sprite_2d_animation_finished() -> void:
	match anim.animation:
		"casting_spell", "casting_spell_aerial":
			if status == PlayerState.idle or status == PlayerState.walk or status == PlayerState.duck:
				if Input.is_action_pressed("cast") and mana >= channel_tick_cost:
					start_channel()
					return
			is_busy_action = false
			resume_state_animation()
		"magical_orbs_spell":
			spawn_nova()
			is_busy_action = false
			resume_state_animation()
		"ground_recovery":
			if status == PlayerState.recovering:
				if direction != 0:
					go_to_walk_state()
				else:
					go_to_idle_state()
		"hurt":
			if status == PlayerState.hurt:
				if is_on_floor() and Input.is_action_pressed("duck"):
					go_to_duck_state()
				elif is_on_floor():
					go_to_idle_state()
				else:
					go_to_fall_state()

# --- colisoes ---
func _on_hitbox_area_entered(area: Area2D) -> void:
	if area.is_in_group("Enemies"):
		hit_enemy(area)
	elif area.is_in_group("Projectile"):
		take_damage_from(1)
	elif area.is_in_group("LethalArea"):
		hit_lethal_area()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if body.is_in_group("LethalArea"):
		hit_lethal_area()
	elif body.is_in_group("Water"):
		go_to_swimming_state()

func hit_enemy(area: Area2D):
	# na forma de particula o inimigo atravessa o player
	if special_active:
		return
	if velocity.y > 0:
		area.get_parent().take_damage()
		go_to_jump_state()
	else:
		take_damage_from(1)

func hit_lethal_area():
	go_to_dead_state()

func _on_reload_timer_timeout() -> void:
	# morreu: perde as moedas pegas nesta fase
	GameState.coins = GameState.saved_coins
	get_tree().reload_current_scene()

func _on_hitbox_body_exited(body: Node2D) -> void:
	if body.is_in_group("Water"):
		jump_count = 0
		go_to_jump_state()
