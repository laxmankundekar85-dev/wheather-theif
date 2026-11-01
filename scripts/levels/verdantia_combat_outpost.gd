## VerdantiaCombatOutpost.gd
## Level controller for Verdantia: The Forgotten District (Valorant-inspired Tactical Shooter Map).
## Coordinates mission objectives across 5 tactical areas (Market, Overgrown Passage, Fortress,
## Sunken Courtyard, Underground Tunnel), enemy wave tracking, and celestial weather siphon overload.
extends Node3D

@export var required_kills: int = 5

var enemies_defeated: int = 0
var is_siphon_overloaded: bool = false
var is_mission_completed: bool = false

@onready var kael: Node3D = $KaelShooter
@onready var weather_siphon: Node3D = $AreaC_RuinedFortress/WeatherSiphon
@onready var siphon_core: MeshInstance3D = $AreaC_RuinedFortress/WeatherSiphon/CoreMesh
@onready var siphon_label: Label3D = $AreaC_RuinedFortress/WeatherSiphon/Label3D
@onready var dialogue_layer: Node = $DialogueLayer

const EnvironmentMaterialLoaderClass = preload("res://scripts/environment/environment_material_loader.gd")

func _ready() -> void:
	if OS.has_feature("mobile") or OS.has_feature("android"):
		_optimize_for_mobile()

	EnvironmentMaterialLoaderClass.apply_map_materials(self)

	# Dynamically detect all active enemies
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
	# Optimize 3D viewport and environment for smooth 60 FPS mobile performance
	var we := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we and we.environment:
		var env := we.environment
		# Screen-space glow and exponential fog are the primary causes of mobile GPU lag
		env.glow_enabled = false
		env.fog_enabled = false
		env.ambient_light_energy = 0.65 # Keep scene bright, vibrant and readable

	# Optimize directional light shadows for mobile fillrate
	var dir_light := get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if dir_light:
		dir_light.shadow_blur = 0.5
		dir_light.directional_shadow_max_distance = 65.0

func _play_mission_intro() -> void:
	var seq: Array = [
		{
			"speaker": "Lyra",
			"text": "Kael, we've infiltrated Verdantia: The Forgotten District! The Shadow Vanguard has established fortifications across the Ancient Market, Sunken Courtyard, and Ruined Fortress."
		},
		{
			"speaker": "Kael",
			"text": "I can use the Overgrown Passage or the Underground Tunnel to flank their defensive positions."
		},
		{
			"speaker": "Lyra",
			"text": "Neutralize the Vanguard operatives [Left Mouse: Shoot | Right Mouse: Aim | R: Reload]. Once secure, reach the central Siphon in the Fortress and restore atmospheric flow!"
		}
	]
	EventBus3D.emit_signal("show_dialogue", seq)
	EventBus3D.emit_signal("quest_updated", "The Forgotten District", "Neutralize the Shadow Vanguard operatives [0/%d]." % required_kills)

func _on_enemy_defeated(_soldier: Node) -> void:
	enemies_defeated += 1
	if MissionManager:
		MissionManager.complete_objective(enemies_defeated)
		if enemies_defeated == 1:
			MissionManager.add_intel("intel_market_cipher", "Eclipse Comms Cipher", "Intercepted transmission: Vanguard Overseer Vane has deployed heavy enforcers to lock down the celestial siphon.")

	var desc := "Neutralize the Shadow Vanguard operatives [%d/%d]." % [enemies_defeated, required_kills]
	EventBus3D.emit_signal("quest_updated", "The Forgotten District", desc)

	if enemies_defeated >= required_kills and not is_siphon_overloaded:
		_on_patrol_cleared()

func _on_patrol_cleared() -> void:
	AudioManager.play_sound("puzzle_solve")
	var seq: Array = [
		{
			"speaker": "Lyra",
			"text": "All Vanguard operatives eliminated! Approach the central Weather Siphon at the Ruined Fortress and infuse it with Rain Magic [Q] to restore Verdantia!"
		}
	]
	EventBus3D.emit_signal("show_dialogue", seq)
	EventBus3D.emit_signal("quest_updated", "Overload Siphon", "Infuse the central Weather Siphon with Rain Magic [Q].")

	if siphon_label:
		siphon_label.text = "⚡ Press [Q] Near Siphon to Infuse Rain Energy"
		siphon_label.modulate = Color(0.2, 0.9, 1.0)

func _on_weather_activated(weather_type: String, pos: Variant) -> void:
	if is_siphon_overloaded or enemies_defeated < required_kills:
		return

	if weather_type == "rain" and weather_siphon:
		var check_pos := global_position
		if pos is Vector3:
			check_pos = pos
		elif kael:
			check_pos = kael.global_position

		if weather_siphon.global_position.distance_to(check_pos) <= 22.0:
			_overload_siphon()

func _overload_siphon() -> void:
	is_siphon_overloaded = true
	is_mission_completed = true
	AudioManager.play_sound("weather_rain")
	AudioManager.play_sound("checkpoint")

	if siphon_core:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.2, 0.85, 1.0)
		mat.emission_enabled = true
		mat.emission = Color(0.15, 0.9, 1.0)
		mat.emission_energy_multiplier = 4.0
		siphon_core.set_surface_override_material(0, mat)

	if siphon_label:
		siphon_label.text = "✦ Verdantia Restored — Mission Accomplished!"
		siphon_label.modulate = Color(0.3, 1.0, 0.5)

	EventBus3D.emit_signal("quest_completed", "The Forgotten District")

	await get_tree().create_timer(2.5).timeout
	var win_seq: Array = [
		{
			"speaker": "Lyra",
			"text": "The atmospheric siphon is purged! Verdantia's skies are cleared. Outstanding shooting, Kael!"
		},
		{
			"speaker": "Kael",
			"text": "I recovered an encrypted celestial map from the Vanguard Overseer. It points directly north... toward the Frozen Mountains."
		}
	]
	EventBus3D.emit_signal("show_dialogue", win_seq)

	await EventBus3D.dialogue_completed
	if LevelManager:
		LevelManager.complete_current_level(enemies_defeated, 92.4)
