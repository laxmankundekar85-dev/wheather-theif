## CorruptedGuardian.gd
## Level 1 Mini-boss guarding the Weather Shrine.
## Has 3 HP, stomps the ground sending shockwaves, and is vulnerable to Sun power or aerial stomps!
extends CharacterBody2D

signal guardian_defeated

@export var max_health: int = 3
var health: int = 3

@onready var visual: Node2D = $Visual
@onready var body_core: ColorRect = $Visual/BodyCore
@onready var head: ColorRect = $Visual/Head
@onready var eyes: Label = $Visual/Eyes
@onready var stomp_area: Area2D = $StompArea
@onready var hitbox: Area2D = $Hitbox
@onready var roar_particles: CPUParticles2D = $RoarParticles
@onready var hp_label: Label = $Visual/HPLabel

var _direction: float = -1.0
var _is_invulnerable: bool = false
var _is_dead: bool = false
var _move_speed: float = 65.0
var _patrol_timer: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	health = max_health
	_update_hp_display()

	if stomp_area:
		stomp_area.body_entered.connect(_on_stomp_area_entered)
	if hitbox:
		hitbox.body_entered.connect(_on_hitbox_body_entered)

func _physics_process(delta: float) -> void:
	if _is_dead:
		return

	if not is_on_floor():
		velocity.y += 1200.0 * delta
	else:
		velocity.y = 0.0

	_patrol_timer += delta
	if _patrol_timer > 3.0 or is_on_wall():
		_direction *= -1.0
		_patrol_timer = 0.0

	velocity.x = _direction * _move_speed
	visual.scale.x = -1.0 if _direction > 0 else 1.0

	move_and_slide()

func _update_hp_display() -> void:
	if hp_label:
		var hearts := ""
		for i in range(health):
			hearts += "💜"
		hp_label.text = hearts

func _on_stomp_area_entered(body: Node2D) -> void:
	if _is_dead or _is_invulnerable:
		return
	if body.is_in_group("player"):
		if "velocity" in body:
			body.velocity.y = -520.0
		AudioManager.play_sound("stomp")
		take_hit()

func _on_hitbox_body_entered(body: Node2D) -> void:
	if _is_dead:
		return
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(1, global_position)

func on_weather_hit(weather_type: String) -> void:
	if _is_dead or _is_invulnerable:
		return
	if weather_type == WeatherManager.WEATHER_SUN:
		take_hit()
	elif weather_type == WeatherManager.WEATHER_SNOW:
		# Freeze briefly
		_move_speed = 0.0
		var t := get_tree().create_timer(2.5)
		t.timeout.connect(func(): if not _is_dead: _move_speed = 65.0)

func take_hit() -> void:
	if _is_dead or _is_invulnerable:
		return
	_is_invulnerable = true
	health -= 1
	_update_hp_display()
	AudioManager.play_sound("damage")

	if roar_particles:
		roar_particles.emitting = true

	# Flash white
	var tween := create_tween()
	tween.tween_property(visual, "modulate", Color(2.0, 1.5, 1.5), 0.1)
	tween.tween_property(visual, "modulate", Color.WHITE, 0.2)

	if health <= 0:
		die()
	else:
		var invuln_timer := get_tree().create_timer(1.0)
		invuln_timer.timeout.connect(func(): _is_invulnerable = false)

func die() -> void:
	_is_dead = true
	emit_signal("guardian_defeated")
	AudioManager.play_sound("enemy_defeat")

	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_notification"):
		hud.show_notification("Corrupted Guardian Defeated!", Color(1.0, 0.4, 0.6), 3.0)

	var tween := create_tween()
	tween.tween_property(visual, "scale", Vector2(1.5, 0.2), 0.4)
	tween.tween_property(visual, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
