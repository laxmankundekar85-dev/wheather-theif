## ShadowBarrier3D.gd
## A wall of cursed shadow flames blocking the path to the upper ruins.
## Extinguished when Zephyr casts Rain magic nearby.
extends Node3D

@onready var flames_root: Node3D = $FlamesRoot
@onready var collision_shape: CollisionShape3D = $StaticBody3D/CollisionShape3D
@onready var label_3d: Label3D = $Label3D
@onready var omni_light: OmniLight3D = $OmniLight3D

var is_extinguished: bool = false

func _ready() -> void:
	WeatherManager.weather_activated.connect(_on_weather_activated)

func _on_weather_activated(weather_type: String, pos: Variant) -> void:
	if is_extinguished:
		return

	if weather_type == "rain":
		var cast_pos: Vector3 = global_position
		if pos is Vector3:
			cast_pos = pos
		var dist := global_position.distance_to(cast_pos)
		if dist <= 30.0: # Close enough to the barrier
			extinguish()

func extinguish() -> void:
	if is_extinguished:
		return
	is_extinguished = true

	AudioManager.play_sound("weather_rain")

	if label_3d:
		label_3d.text = "💧 Shadow Flame Extinguished!"
		label_3d.modulate = Color(0.4, 0.8, 1.0)

	# Fade out flames and disable collision
	var tw := create_tween()
	tw.tween_property(flames_root, "scale", Vector3(1.2, 0.05, 1.2), 0.5).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(omni_light, "light_energy", 0.0, 0.5)
	await tw.finished

	if collision_shape:
		collision_shape.disabled = true
	flames_root.visible = false

	# Dialogue notice
	var seq: Array = [
		{
			"speaker": "Zephyr",
			"text": "It worked! The rain quenched the shadow barrier. The inner gateway is unlocked!"
		}
	]
	EventBus3D.emit_signal("show_dialogue", seq)
