## FloatingWindPlatform.gd
## A platform with a magical wind sail. When Wind power is cast nearby,
## catches the wind and moves across a chasm to carry the player across.
extends AnimatableBody2D

@export var move_distance: Vector2 = Vector2(360.0, 0.0)
@export var move_duration: float = 3.2
@export var is_moving: bool = false

@onready var visual: ColorRect = $Visual
@onready var sail: ColorRect = $Sail
@onready var sail_cloth: Label = $SailCloth
@onready var particles: CPUParticles2D = $WindTrailParticles

var _start_position: Vector2
var _target_position: Vector2
var _at_target: bool = false

func _ready() -> void:
	add_to_group("wind_activated")
	_start_position = position
	_target_position = _start_position + move_distance

func activate_wind() -> void:
	if is_moving:
		return
	is_moving = true
	AudioManager.play_sound("puzzle_solve")

	if particles:
		particles.emitting = true

	var destination := _start_position if _at_target else _target_position
	_at_target = not _at_target

	var tween := create_tween()
	tween.tween_property(self, "position", destination, move_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_callback(func():
		is_moving = false
		if particles:
			particles.emitting = false
	)
