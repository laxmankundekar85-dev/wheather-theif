## WaterHazard.gd
## A water pond or river gorge that damages player when liquid.
## When Snow weather is activated, it freezes into a solid ice bridge.
## When Sun weather is activated, it melts back into water.
extends Area2D

@export var width: float = 300.0
@export var height: float = 60.0
@export var is_frozen: bool = false

@onready var water_visual: ColorRect = $WaterVisual
@onready var ice_visual: ColorRect = $IceVisual
@onready var ice_top: ColorRect = $IceTop
@onready var hazard_collision: CollisionShape2D = $HazardCollision
@onready var ice_body: StaticBody2D = $IceBody
@onready var ice_collision: CollisionShape2D = $IceBody/IceCollision
@onready var freeze_particles: CPUParticles2D = $FreezeParticles

func _ready() -> void:
	add_to_group("water_hazard")
	body_entered.connect(_on_body_entered)
	_setup_dimensions()
	if is_frozen:
		freeze(true)
	else:
		melt(true)

func _setup_dimensions() -> void:
	water_visual.size = Vector2(width, height)
	water_visual.position = Vector2(-width / 2.0, 0)
	ice_visual.size = Vector2(width, height)
	ice_visual.position = Vector2(-width / 2.0, 0)
	ice_top.size = Vector2(width, 6)
	ice_top.position = Vector2(-width / 2.0, 0)

	var rect_shape := RectangleShape2D.new()
	rect_shape.size = Vector2(width - 8, height - 10)
	hazard_collision.shape = rect_shape
	hazard_collision.position = Vector2(0, height / 2.0)

	var ice_shape := RectangleShape2D.new()
	ice_shape.size = Vector2(width, 24)
	ice_collision.shape = ice_shape
	ice_collision.position = Vector2(0, 12)

func _on_body_entered(body: Node2D) -> void:
	if not is_frozen and body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(1, global_position)

func freeze(instant: bool = false) -> void:
	if is_frozen and not instant:
		return
	is_frozen = true
	ice_visual.visible = true
	ice_top.visible = true
	ice_collision.set_deferred("disabled", false)
	monitoring = false

	if not instant:
		AudioManager.play_sound("puzzle_solve")
		if freeze_particles:
			freeze_particles.emitting = true
		var tween := create_tween()
		ice_visual.modulate.a = 0.0
		tween.tween_property(ice_visual, "modulate:a", 1.0, 0.5)

func melt(instant: bool = false) -> void:
	if not is_frozen and not instant:
		return
	is_frozen = false
	ice_collision.set_deferred("disabled", true)
	monitoring = true

	if instant:
		ice_visual.visible = false
		ice_top.visible = false
	else:
		AudioManager.play_sound("weather_rain")
		var tween := create_tween()
		tween.tween_property(ice_visual, "modulate:a", 0.0, 0.4)
		tween.tween_callback(func():
			ice_visual.visible = false
			ice_top.visible = false
		)
