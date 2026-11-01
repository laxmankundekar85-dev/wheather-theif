## Player.gd
## Main player controller using CharacterBody2D.
## Handles movement, jumping, animation state machine, health, damage recovery,
## weather activation, and checkpoint respawning.
extends CharacterBody2D

# ─── Exported Tuning ────────────────────────────────────────────────────────
@export var move_speed: float = 280.0
@export var jump_force: float = -700.0
@export var jump_hold_boost: float = -240.0  ## Extra upward force while holding jump
@export var jump_hold_time: float = 0.22     ## Max seconds jump can be held
@export var gravity: float = 1750.0
@export var max_fall_speed: float = 950.0
@export var coyote_time: float = 0.18
@export var jump_buffer_time: float = 0.18
@export var knockback_force: float = 280.0

# ─── Node References ────────────────────────────────────────────────────────
@onready var player_visual: Node2D             = $PlayerVisual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var coyote_timer: Timer               = $CoyoteTimer
@onready var jump_buffer_timer: Timer          = $JumpBufferTimer
@onready var damage_timer: Timer               = $DamageTimer
@onready var weather_cast_point: Marker2D      = $WeatherCastPoint
@onready var weather_effect_spawner: Node2D    = $WeatherEffectSpawner

# ─── State Flags ────────────────────────────────────────────────────────────
var is_dead: bool = false
var is_damaged: bool = false
var can_move: bool = true
var is_activating_weather: bool = false
var _facing_left: bool = false

var jump_held: bool = false
var jump_held_timer: float = 0.0
var was_on_floor: bool = false
var knockback_velocity: Vector2 = Vector2.ZERO

# ─── Signals ────────────────────────────────────────────────────────────────
signal collected_bottle(weather_type: String)

func _ready() -> void:
	GameManager.player_ref = self
	GameManager.last_checkpoint_position = global_position

	coyote_timer.wait_time = coyote_time
	coyote_timer.one_shot = true
	jump_buffer_timer.wait_time = jump_buffer_time
	jump_buffer_timer.one_shot = true
	damage_timer.wait_time = 1.2
	damage_timer.one_shot = true

	GameManager.player_died.connect(_on_player_died)
	SceneTransition.fade_in(0.5)
	add_to_group("player")
	print("[Player] Ready at: ", global_position)

# ─── Physics Process ────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_apply_gravity(delta)
	_handle_coyote_time()
	_handle_jump(delta)
	_handle_movement(delta)
	_apply_knockback(delta)
	move_and_slide()
	_update_visual()

func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = min(velocity.y + gravity * delta, max_fall_speed)
	else:
		if not was_on_floor and velocity.y > 100.0:
			AudioManager.play_sound("land")
		if velocity.y > 0:
			velocity.y = 0.0

func _handle_coyote_time() -> void:
	if was_on_floor and not is_on_floor():
		coyote_timer.start()
	was_on_floor = is_on_floor()

func _handle_jump(delta: float) -> void:
	if Input.is_action_just_pressed("jump"):
		jump_buffer_timer.start()

	var can_jump: bool = is_on_floor() or not coyote_timer.is_stopped()
	var jump_buffered: bool = not jump_buffer_timer.is_stopped()

	if jump_buffered and can_jump and not is_damaged:
		velocity.y = jump_force
		jump_held = true
		jump_held_timer = 0.0
		coyote_timer.stop()
		jump_buffer_timer.stop()
		AudioManager.play_sound("jump")

	if jump_held:
		jump_held_timer += delta
		if Input.is_action_pressed("jump") and jump_held_timer < jump_hold_time:
			velocity.y += jump_hold_boost * delta
		else:
			jump_held = false

	if Input.is_action_just_released("jump") and velocity.y < -340.0:
		jump_held = false
		velocity.y = -340.0

func _handle_movement(delta: float) -> void:
	if not can_move or is_damaged:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 16.0 * delta)
		return

	var direction: float = Input.get_axis("move_left", "move_right")

	if direction != 0.0:
		velocity.x = move_toward(velocity.x, direction * move_speed, move_speed * 22.0 * delta)
		_facing_left = direction < 0.0
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed * 18.0 * delta)

	# Weather input
	if Input.is_action_just_pressed("activate_weather") and not is_activating_weather:
		_try_activate_weather()

	if Input.is_action_just_pressed("switch_weather"):
		WeatherManager.switch_to_next()

func _apply_knockback(delta: float) -> void:
	if knockback_velocity.length() > 1.0:
		velocity += knockback_velocity * delta
		knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, 1400.0 * delta)

# ─── Weather Activation ─────────────────────────────────────────────────────
func _try_activate_weather() -> void:
	if WeatherManager.can_activate():
		is_activating_weather = true
		WeatherManager.activate_weather(weather_cast_point.global_position)
		await get_tree().create_timer(0.5).timeout
		is_activating_weather = false

# ─── Damage System ───────────────────────────────────────────────────────────
func take_damage(amount: int, damage_source_position: Vector2) -> void:
	if is_damaged or is_dead:
		return
	is_damaged = true
	AudioManager.play_sound("damage")
	GameManager.damage_player(amount)
	var dir := (global_position - damage_source_position).normalized()
	knockback_velocity = dir * knockback_force
	damage_timer.start()
	# Flash visual
	if player_visual:
		var tween := create_tween()
		tween.set_loops(5)
		tween.tween_property(player_visual, "modulate:a", 0.15, 0.08)
		tween.tween_property(player_visual, "modulate:a", 1.0, 0.08)

func _on_damage_timer_timeout() -> void:
	is_damaged = false
	if player_visual:
		player_visual.modulate = Color.WHITE

# ─── Health / Death ──────────────────────────────────────────────────────────
func _on_player_died() -> void:
	if is_dead:
		return
	is_dead = true
	can_move = false
	velocity = Vector2.ZERO
	await get_tree().create_timer(1.2).timeout
	SceneTransition.fade_to_scene(get_tree().current_scene.scene_file_path, 0.6)

func respawn(at_position: Vector2) -> void:
	global_position = at_position
	is_dead = false
	is_damaged = false
	can_move = true
	velocity = Vector2.ZERO
	knockback_velocity = Vector2.ZERO
	GameManager.set_player_health(GameManager.player_max_health)
	if player_visual:
		player_visual.modulate = Color.WHITE
	SceneTransition.fade_in(0.5)

# ─── Visual State Update ─────────────────────────────────────────────────────
func _update_visual() -> void:
	if player_visual == null:
		return
	# Flip based on facing direction
	player_visual.scale.x = -1.0 if _facing_left else 1.0

# ─── Bottle Collection ────────────────────────────────────────────────────────
func collect_bottle(weather_type: String) -> void:
	emit_signal("collected_bottle", weather_type)
