## Level02FrozenMountains.gd
## Chapter 2: The Frozen Mountains
## High mountain cryo-research facility with blizzard atmosphere, ice bridges, and Frostguard Captain boss.
extends Node3D

@export var required_kills: int = 5

var enemies_defeated: int = 0
var is_siphon_overloaded: bool = false
var is_mission_completed: bool = false

@onready var kael: Node3D = $KaelShooter
@onready var cryo_siphon: Node3D = $CryoFacility/CryoSiphon
@onready var siphon_core: MeshInstance3D = $CryoFacility/CryoSiphon/CoreMesh
@onready var siphon_label: Label3D = $CryoFacility/CryoSiphon/Label3D

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
		env.ambient_light_energy = 0.65

func _play_mission_intro() -> void:
	var seq: Array = [
		{
			"speaker": "Lyra",
			"text": "Brrr! We've breached the Frozen Mountains! Frostguard Captain Varek is using the Cryo-Siphon to freeze the mountain pass and lock down the sky route."
		},
		{
			"speaker": "Kael",
			"text": "The snow here is biting, but my thermal shield holds. I see Vanguard snipers posted across the ice ledges."
		},
		{
			"speaker": "Lyra",
			"text": "Take out the Frostguard operatives [Right Mouse: Aim | Left Mouse: Shoot]. Then infuse the Cryo-Siphon with Snow Magic [E] to shatter their control!"
		}
	]
	EventBus3D.emit_signal("show_dialogue", seq)
	EventBus3D.emit_signal("quest_updated", "The Frozen Mountains", "Neutralize the Frostguard operatives [0/%d]." % required_kills)

func _on_enemy_defeated(_soldier: Node) -> void:
	enemies_defeated += 1
	var desc := "Neutralize the Frostguard operatives [%d/%d]." % [enemies_defeated, required_kills]
	EventBus3D.emit_signal("quest_updated", "The Frozen Mountains", desc)

	if enemies_defeated >= required_kills and not is_siphon_overloaded:
		_on_patrol_cleared()

func _on_patrol_cleared() -> void:
	AudioManager.play_sound("puzzle_solve")
	var seq: Array = [
		{
			"speaker": "Lyra",
			"text": "Frostguard forces decimated! Approach the central Cryo-Siphon at the mountain peak and infuse it with Snow Magic [E] to reclaim the Sky Key!"
		}
	]
	EventBus3D.emit_signal("show_dialogue", seq)
	EventBus3D.emit_signal("quest_updated", "Overload Cryo-Siphon", "Infuse the Cryo-Siphon with Snow Magic [E].")

	if siphon_label:
		siphon_label.text = "❄ Press [E] Near Siphon to Infuse Snow Energy"
		siphon_label.modulate = Color(0.4, 0.9, 1.0)

func _on_weather_activated(weather_type: String, pos: Variant) -> void:
	if is_siphon_overloaded or enemies_defeated < required_kills:
		return

	if (weather_type == "snow" or weather_type == "rain") and cryo_siphon:
		var check_pos := global_position
		if pos is Vector3:
			check_pos = pos
		elif kael:
			check_pos = kael.global_position

		if cryo_siphon.global_position.distance_to(check_pos) <= 24.0:
			_overload_siphon()

func _overload_siphon() -> void:
	is_siphon_overloaded = true
	is_mission_completed = true
	AudioManager.play_sound("weather_snow")
	AudioManager.play_sound("checkpoint")

	if siphon_core:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.6, 0.95, 1.0)
		mat.emission_enabled = true
		mat.emission = Color(0.5, 0.9, 1.0)
		mat.emission_energy_multiplier = 4.5
		siphon_core.set_surface_override_material(0, mat)

	if siphon_label:
		siphon_label.text = "✦ Cryo-Siphon Purged — Sky Island Key Acquired!"
		siphon_label.modulate = Color(0.3, 1.0, 0.7)

	EventBus3D.emit_signal("quest_completed", "The Frozen Mountains")

	await get_tree().create_timer(2.5).timeout
	var win_seq: Array = [
		{
			"speaker": "Lyra",
			"text": "The Frostguard Captain is defeated and the Sky Key is ours! Aetheria's floating Sky Islands are now accessible!"
		},
		{
			"speaker": "Kael",
			"text": "The wind currents are shifting upward. Let's take the aerial ascender to the clouds."
		}
	]
	EventBus3D.emit_signal("show_dialogue", win_seq)

	await EventBus3D.dialogue_completed
	if LevelManager:
		LevelManager.complete_current_level(enemies_defeated, 94.2)

