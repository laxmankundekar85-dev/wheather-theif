## Level04SunkenDesert.gd
## Chapter 4: The Sunken Desert
## Ancient sandstone ruins half-buried beneath golden dunes, solar laboratory, and Sunbreaker Commander boss.
extends Node3D

@export var required_kills: int = 5

var enemies_defeated: int = 0
var is_siphon_overloaded: bool = false
var is_mission_completed: bool = false

@onready var kael: Node3D = $KaelShooter
@onready var sun_monolith: Node3D = $BuriedLab/SunMonolith
@onready var monolith_core: MeshInstance3D = $BuriedLab/SunMonolith/CoreMesh
@onready var monolith_label: Label3D = $BuriedLab/SunMonolith/Label3D

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
		env.ambient_light_energy = 0.75

func _play_mission_intro() -> void:
	var seq: Array = [
		{
			"speaker": "Lyra",
			"text": "The heat signature is immense! We have entered the Sunken Desert ruins. Sunbreaker Commander Solon is weaponizing solar radiation in the subterranean lab."
		},
		{
			"speaker": "Kael",
			"text": "Their heavy defenders are utilizing heat-tempered armor. We must eliminate their defensive perimeter."
		},
		{
			"speaker": "Lyra",
			"text": "Eliminate the Sunbreaker forces [Shoot to neutralise]. Then channel Sun Radiance [C] into the Sun Monolith to overload their solar capacitor!"
		}
	]
	EventBus3D.emit_signal("show_dialogue", seq)
	EventBus3D.emit_signal("quest_updated", "The Sunken Desert", "Defeat Sunbreaker defense squad [0/%d]." % required_kills)

func _on_enemy_defeated(_soldier: Node) -> void:
	enemies_defeated += 1
	var desc := "Defeat Sunbreaker defense squad [%d/%d]." % [enemies_defeated, required_kills]
	EventBus3D.emit_signal("quest_updated", "The Sunken Desert", desc)

	if enemies_defeated >= required_kills and not is_siphon_overloaded:
		_on_patrol_cleared()

func _on_patrol_cleared() -> void:
	AudioManager.play_sound("puzzle_solve")
	var seq: Array = [
		{
			"speaker": "Lyra",
			"text": "Sunbreaker Commander has fallen! Reach the ancient Sun Monolith and channel Sun Radiance [C] to awaken the solar shard!"
		}
	]
	EventBus3D.emit_signal("show_dialogue", seq)
	EventBus3D.emit_signal("quest_updated", "Awaken Sun Monolith", "Channel Sun Radiance [C] near the monolith.")

	if monolith_label:
		monolith_label.text = "☀️ Press [C] Near Monolith to Channel Solar Energy"
		monolith_label.modulate = Color(1.0, 0.85, 0.3)

func _on_weather_activated(weather_type: String, pos: Variant) -> void:
	if is_siphon_overloaded or enemies_defeated < required_kills:
		return

	if (weather_type == "sun" or weather_type == "wind" or weather_type == "rain") and sun_monolith:
		var check_pos := global_position
		if pos is Vector3:
			check_pos = pos
		elif kael:
			check_pos = kael.global_position

		if sun_monolith.global_position.distance_to(check_pos) <= 24.0:
			_overload_monolith()

func _overload_monolith() -> void:
	is_siphon_overloaded = true
	is_mission_completed = true
	AudioManager.play_sound("weather_sun")
	AudioManager.play_sound("checkpoint")

	if monolith_core:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.8, 0.2)
		mat.emission_enabled = true
		mat.emission = Color(1.0, 0.75, 0.2)
		mat.emission_energy_multiplier = 4.5
		monolith_core.set_surface_override_material(0, mat)

	if monolith_label:
		monolith_label.text = "✦ Sun Monolith Restored — Storm Kingdom Citadel Revealed!"
		monolith_label.modulate = Color(1.0, 0.9, 0.4)

	EventBus3D.emit_signal("quest_completed", "The Sunken Desert")

	await get_tree().create_timer(2.5).timeout
	var win_seq: Array = [
		{
			"speaker": "Lyra",
			"text": "The Sun Fragment is bonded! All four primal currents are aligned within you, Kael! The final storm barrier has opened above the Storm Kingdom!"
		},
		{
			"speaker": "Kael",
			"text": "High Magus Corvin and the Eclipse Sovereign fortress await. This ends now."
		}
	]
	EventBus3D.emit_signal("show_dialogue", win_seq)

	await EventBus3D.dialogue_completed
	if LevelManager:
		LevelManager.complete_current_level(enemies_defeated, 95.0)

