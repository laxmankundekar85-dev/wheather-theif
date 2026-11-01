## Level05StormKingdom.gd
## Chapter 5: The Storm Kingdom — Campaign Climax & Finale
## Eclipse Citadel fortress, catastrophic lightning tempest, and Eclipse Sovereign final boss.
extends Node3D

@export var required_kills: int = 5

var enemies_defeated: int = 0
var is_siphon_overloaded: bool = false
var is_mission_completed: bool = false

@onready var kael: Node3D = $KaelShooter
@onready var storm_spire: Node3D = $EclipseCitadel/StormSpire
@onready var spire_core: MeshInstance3D = $EclipseCitadel/StormSpire/CoreMesh
@onready var spire_label: Label3D = $EclipseCitadel/StormSpire/Label3D

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
		env.ambient_light_energy = 0.6

func _play_mission_intro() -> void:
	var seq: Array = [
		{
			"speaker": "Lyra",
			"text": "This is it, Kael! The Eclipse Citadel at the heart of the Storm Kingdom! The atmospheric maelstrom is reaching critical instability."
		},
		{
			"speaker": "Kael",
			"text": "Eclipse Sovereign Corvin has barricaded himself on the high citadel dais with his elite honor guard."
		},
		{
			"speaker": "Lyra",
			"text": "All four elemental powers are in your hands: Rain [Q], Snow [E], Wind [F], and Sun [C]! Strike down Corvin and trigger your Storm Ultimate [G] at the Master Spire to save the realm!"
		}
	]
	EventBus3D.emit_signal("show_dialogue", seq)
	EventBus3D.emit_signal("quest_updated", "The Storm Kingdom", "Defeat Sovereign Corvin and the Citadel Guard [0/%d]." % required_kills)

func _on_enemy_defeated(_soldier: Node) -> void:
	enemies_defeated += 1
	var desc := "Defeat Sovereign Corvin and the Citadel Guard [%d/%d]." % [enemies_defeated, required_kills]
	EventBus3D.emit_signal("quest_updated", "The Storm Kingdom", desc)

	if enemies_defeated >= required_kills and not is_siphon_overloaded:
		_on_patrol_cleared()

func _on_patrol_cleared() -> void:
	AudioManager.play_sound("puzzle_solve")
	var seq: Array = [
		{
			"speaker": "Lyra",
			"text": "The Eclipse Sovereign is finished! Now ascend to the Master Storm Spire and unleash Storm Ultimate [G] or Primal Magic to purify the sky!"
		}
	]
	EventBus3D.emit_signal("show_dialogue", seq)
	EventBus3D.emit_signal("quest_updated", "Purify Storm Spire", "Unleash Ultimate [G] or Weather Magic at the Master Spire.")

	if spire_label:
		spire_label.text = "⚡ Press [G] or Magic Near Spire to Purify the Sky"
		spire_label.modulate = Color(0.85, 0.4, 1.0)

func _on_weather_activated(weather_type: String, pos: Variant) -> void:
	if is_siphon_overloaded or enemies_defeated < required_kills:
		return

	if storm_spire:
		var check_pos := global_position
		if pos is Vector3:
			check_pos = pos
		elif kael:
			check_pos = kael.global_position

		if storm_spire.global_position.distance_to(check_pos) <= 24.0:
			_overload_spire()

func _overload_spire() -> void:
	is_siphon_overloaded = true
	is_mission_completed = true
	AudioManager.play_sound("weather_burst")
	AudioManager.play_sound("checkpoint")

	if spire_core:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.9, 0.45, 1.0)
		mat.emission_enabled = true
		mat.emission = Color(0.8, 0.35, 1.0)
		mat.emission_energy_multiplier = 5.0
		spire_core.set_surface_override_material(0, mat)

	if spire_label:
		spire_label.text = "✦ The Great Weather Collapse Has Ended — The Skies Are Restored!"
		spire_label.modulate = Color(0.5, 1.0, 0.5)

	EventBus3D.emit_signal("quest_completed", "The Storm Kingdom")

	await get_tree().create_timer(2.8).timeout
	var win_seq: Array = [
		{
			"speaker": "Lyra",
			"text": "Look, Kael! The dark storm clouds are breaking! Primal rain, crystal snow, gentle winds, and radiant sunshine are flowing together once again."
		},
		{
			"speaker": "Kael",
			"text": "We did it, Lyra. The weather is no longer stolen. It belongs to everyone now."
		},
		{
			"speaker": "Lyra",
			"text": "You are a true Weather Thief, Kael! Thank you for playing the complete Campaign!"
		}
	]
	EventBus3D.emit_signal("show_dialogue", win_seq)

	await EventBus3D.dialogue_completed
	if LevelManager:
		LevelManager.complete_current_level(enemies_defeated, 96.5)

