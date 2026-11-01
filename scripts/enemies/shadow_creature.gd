## ShadowCreature.gd
## A corrupted shadow creature patrolling platforms.
## Can be defeated via stomp from above or dissolved by Sun weather.
## Can be frozen solid by Snow weather to serve as a stepping stone!
extends CharacterBody2D

@export var patrol_distance: float = 180.0
@export var speed: float = 75.0
@export var health: int = 1
@export var is_frozen: bool = false

@onready var visual: Node2D = $Visual
@onready var body_rect: ColorRect = $Visual/BodyRect
@onready var eye_left: ColorRect = $Visual/EyeLeft
@onready var eye_right: ColorRect = $Visual/EyeRight
@onready var ice_cover: ColorRect = $Visual/IceCover
@onready var hitbox: Area2D = $Hitbox
@onready var stomp_area: Area2D = $StompArea
@onready var defeat_particles: CPUParticles2D = $DefeatParticles

var _start_x: float = 0.0
var _direction: float = 1.0
var _frozen_timer: float = 0.0
var _is_defeated: bool = false

func _ready() -> void:
	add_to_group("enemies")
	_start_x = global_position.x
	ice_cover.visible = false

	if stomp_area:
		stomp_area.body_entered.connect(_on_stomp_area_entered)
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	if _is_defeated:
		return

	# Handle frozen state
	if is_frozen:
		_frozen_timer -= delta
		if _frozen_timer <= 0.0:
			_unfreeze()
		velocity = Vector2.ZERO
		move_and_slide()
		return

	# Gravity
	if not is_on_floor():
		velocity.y += 1200.0 * delta
	else:
		velocity.y = 0.0

	# Patrol movement
	velocity.x = _direction * speed
	if is_on_wall():
		_direction *= -1.0
	elif abs(global_position.x - _start_x) >= patrol_distance:
		_direction = -sign(global_position.x - _start_x)

	visual.scale.x = -1.0 if _direction < 0 else 1.0

	# Eye pulse
	var t := Time.get_ticks_msec() / 1000.0
	eye_left.color.a = 0.7 + 0.3 * sin(t * 8.0)
	eye_right.color.a = 0.7 + 0.3 * sin(t * 8.0)

	move_and_slide()

func _on_stomp_area_entered(body: Node2D) -> void:
	if _is_defeated or is_frozen:
		return
	if body.is_in_group("player"):
		# Bounce the player!
		if "velocity" in body:
			body.velocity.y = -460.0
		AudioManager.play_sound("stomp")
		defeat()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if _is_defeated or is_frozen:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1, global_position)

func on_weather_hit(weather_type: String) -> void:
	if _is_defeated:
		return

	match weather_type:
		WeatherManager.WEATHER_SUN:
			# Sun completely purifies/dissolves shadow creature!
			AudioManager.play_sound("enemy_defeat")
			defeat()
		WeatherManager.WEATHER_SNOW:
			# Freeze solid!
			freeze_solid(5.5)
		WeatherManager.WEATHER_RAIN:
			# Drench & slow down
			speed = 35.0
			var t := get_tree().create_timer(3.0)
			t.timeout.connect(func(): speed = 75.0)

func freeze_solid(duration: float) -> void:
	is_frozen = true
	_frozen_timer = duration
	ice_cover.visible = true
	AudioManager.play_sound("puzzle_solve")

func _unfreeze() -> void:
	is_frozen = false
	ice_cover.visible = false

func defeat() -> void:
	if _is_defeated:
		return
	_is_defeated = true
	AudioManager.play_sound("enemy_defeat")

	# Drop heart or charges with 50% chance
	if randf() < 0.45:
		_spawn_heart_pickup()

	if defeat_particles:
		defeat_particles.emitting = true

	hitbox.set_deferred("monitoring", false)
	stomp_area.set_deferred("monitoring", false)

	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector2.ZERO, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(visual, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)

func _spawn_heart_pickup() -> void:
	var heart_scene := load("res://scenes/collectibles/heart_pickup.tscn")
	if heart_scene:
		var heart: Node2D = heart_scene.instantiate()
		get_parent().add_child(heart)
		heart.global_position = global_position
