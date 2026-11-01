## Level03SkyIslands.gd
## Chapter 3: The Sky Islands
## Floating sky islands above the cloudscape with ancient Aetherian marble ruins and Sky Warden boss.
extends Node3D

@export var required_kills: int = 5

var enemies_defeated: int = 0
var is_siphon_overloaded: bool = false
var is_mission_completed: bool = false

@onready var kael: Node3D = $KaelShooter
@onready var wind_sanctum: Node3D = $TempleSanctum/WindSanctum
@onready var sanctum_core: MeshInstance3D = $TempleSanctum/WindSanctum/CoreMesh
@onready var sanctum_label: Label3D = $TempleSanctum/WindSanctum/Label3D

func _ready() -> void:
	if OS.has_feature("mobile") or OS.has_feature("android"):
		_optimize_for_mobile()

	var enemy_nodes := get_tree().get_nodes_in_group("enemies")
	if enemy_nodes.size() > 0:
		required_kills = enemy_nodes.size()

	for enemy in enemy_nodes:
		if enemy.has_signal("enemy_defeated"):
			enemy.enemy_defeated.connect(_on_enemy_defeated)

	EventBus3D.weather_activated.connect(_on_weather_activated)

	await get_tree().create_timer(0.8).timeout
	_play_mission_intro()

func _optimize_for_mobile() -> void:
	var we := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we and we.environment:
		var env := we.environment
		env.glow_enabled = false
		env.fog_enabled = false
		env.ambient_light_energy = 0.7

func _play_mission_intro() -> void:
	var seq: Array = [
		{
			"speaker": "Lyra",
			"text": "Incredible! We are floating miles above the cloud deck at the ancient Aetherian Sky Islands! But the Eclipse Order has landed gunships ahead."
		},
		{
			"speaker": "Kael",
			"text": "The wind bridges are under sniper fire. If I mistep, the updrafts will catch me, but I need to clear the Sky Warden's guard."
		},
		{
			"speaker": "Lyra",
			"text": "Defeat the Skyguard garrison [Aim & Shoot]! Then channel Wind Magic [F] into the Sky Sanctum to claim the Wind Fragment!"
		}
	]
	EventBus3D.emit_signal("show_dialogue", seq)
	EventBus3D.emit_signal("quest_updated", "The Sky Islands", "Eliminate Skyguard garrison [0/%d]." % required_kills)

func _on_enemy_defeated(_soldier: Node) -> void:
	enemies_defeated += 1
	var desc := "Eliminate Skyguard garrison [%d/%d]." % [enemies_defeated, required_kills]
	EventBus3D.emit_signal("quest_updated", "The Sky Islands", desc)

	if enemies_defeated >= required_kills and not is_siphon_overloaded:
		_on_patrol_cleared()

func _on_patrol_cleared() -> void:
	AudioManager.play_sound("puzzle_solve")
	var seq: Array = [
		{
			"speaker": "Lyra",
			"text": "Sky Warden neutralized! Rush to the Sky Sanctum and channel Wind Magic [F] to reignite the atmospheric beacon!"
		}
	]
	EventBus3D.emit_signal("show_dialogue", seq)
	EventBus3D.emit_signal("quest_updated", "Ignite Sky Sanctum", "Channel Wind Magic [F] near the altar.")

	if sanctum_label:
		sanctum_label.text = "💨 Press [F] Near Sanctum to Channel Wind Energy"
		sanctum_label.modulate = Color(0.4, 1.0, 0.8)

func _on_weather_activated(weather_type: String, pos: Variant) -> void:
	if is_siphon_overloaded or enemies_defeated < required_kills:
		return

	if (weather_type == "wind" or weather_type == "rain" or weather_type == "snow") and wind_sanctum:
		var check_pos := global_position
		if pos is Vector3:
			check_pos = pos
		elif kael:
			check_pos = kael.global_position

		if wind_sanctum.global_position.distance_to(check_pos) <= 24.0:
			_overload_sanctum()

func _overload_sanctum() -> void:
	is_siphon_overloaded = true
	is_mission_completed = true
	AudioManager.play_sound("weather_wind")
	AudioManager.play_sound("checkpoint")

	if sanctum_core:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 1.0, 0.8)
		mat.emission_enabled = true
		mat.emission = Color(0.2, 0.95, 0.75)
		mat.emission_energy_multiplier = 4.5
		sanctum_core.set_surface_override_material(0, mat)

	if sanctum_label:
		sanctum_label.text = "✦ Wind Fragment Secured — Sunken Desert Coordinates Decoded!"
		sanctum_label.modulate = Color(0.3, 1.0, 0.5)

	EventBus3D.emit_signal("quest_completed", "The Sky Islands")

	await get_tree().create_timer(2.5).timeout
	var win_seq: Array = [
		{
			"speaker": "Lyra",
			"text": "The Wind Fragment resonates with your ether core, Kael! The wind is pointing south... toward the Sunken Desert!"
		},
		{
			"speaker": "Kael",
			"text": "The Eclipse Order has built a solar laboratory buried deep beneath the dunes. We move now."
		}
	]
	EventBus3D.emit_signal("show_dialogue", win_seq)

	await EventBus3D.dialogue_completed
	if LevelManager:
		LevelManager.complete_current_level(enemies_defeated, 93.8)

