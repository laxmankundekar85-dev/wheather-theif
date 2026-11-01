## IceBarrier.gd
## A wall of ancient ice blocking paths or secrets.
## Melts when Sun weather power is activated nearby.
extends StaticBody2D

@export var is_melted: bool = false

@onready var visual: ColorRect = $Visual
@onready var rim_visual: ColorRect = $RimVisual
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var frost_symbol: Label = $FrostSymbol
@onready var melt_particles: CPUParticles2D = $MeltParticles

func _ready() -> void:
	add_to_group("ice_barrier")
	if is_melted:
		queue_free()

func melt() -> void:
	if is_melted:
		return
	is_melted = true
	AudioManager.play_sound("puzzle_solve")
	collision_shape.set_deferred("disabled", true)

	if melt_particles:
		melt_particles.emitting = true

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(visual, "scale:y", 0.05, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(rim_visual, "scale:y", 0.05, 0.6)
	tween.tween_property(frost_symbol, "modulate:a", 0.0, 0.4)
	tween.tween_property(visual, "modulate:a", 0.0, 0.7)

	await tween.finished
	queue_free()
