## SproutingVine3D.gd
## A dormant ancient vine seed that sprouts into climbable leaf platforms when watered by Rain.
extends Node3D

@onready var platforms_root: Node3D = $PlatformsRoot
@onready var bud_mesh: Node3D = $BudMesh
@onready var label_3d: Label3D = $Label3D

var is_grown: bool = false

func _ready() -> void:
	if platforms_root:
		platforms_root.scale = Vector3(1, 0.05, 1)
		platforms_root.visible = false
	WeatherManager.weather_activated.connect(_on_weather_activated)

func _on_weather_activated(weather_type: String, pos: Variant) -> void:
	if is_grown:
		return

	if weather_type == "rain":
		var cast_pos: Vector3 = global_position
		if pos is Vector3:
			cast_pos = pos
		var dist := global_position.distance_to(cast_pos)
		if dist <= 35.0:
			grow()

func grow() -> void:
	if is_grown:
		return
	is_grown = true

	AudioManager.play_sound("weather_rain")

	if label_3d:
		label_3d.text = "🌿 Ancient Vine Awakened!"
		label_3d.modulate = Color(0.4, 1.0, 0.5)

	platforms_root.visible = true
	var tw := create_tween()
	tw.tween_property(platforms_root, "scale", Vector3.ONE, 1.2).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
