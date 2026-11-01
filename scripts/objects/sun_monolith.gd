## SunMonolith.gd
## Ancient Weather Shrine / Monolith.
## When activated with Sun weather, awakens and completes the level objective!
extends Area2D

signal shrine_activated

@export var is_activated: bool = false

@onready var stone_body: ColorRect = $StoneBody
@onready var rune_core: ColorRect = $RuneCore
@onready var rune_symbol: Label = $RuneSymbol
@onready var glow_aura: ColorRect = $GlowAura
@onready var sun_particles: CPUParticles2D = $SunParticles

func _ready() -> void:
	add_to_group("sun_monolith")
	glow_aura.visible = false

func activate_sun() -> void:
	if is_activated:
		return
	is_activated = true
	AudioManager.play_sound("checkpoint")
	emit_signal("shrine_activated")

	glow_aura.visible = true
	if sun_particles:
		sun_particles.emitting = true

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(rune_core, "color", Color(1.0, 0.9, 0.2), 0.6)
	tween.tween_property(rune_symbol, "modulate", Color(1.0, 1.0, 0.5), 0.6)
	tween.tween_property(glow_aura, "modulate:a", 0.6, 0.8).from(0.0)

	# Notify HUD
	var hud := get_tree().get_first_node_in_group("hud")
	if hud and hud.has_method("show_notification"):
		hud.show_notification("☀️ Ancient Forest Weather Shrine Restored!", Color(1.0, 0.85, 0.2), 4.0)
