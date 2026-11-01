## ModularMissionController.gd
## Universal campaign mission controller for Weather Thief.
## Loads data-driven mission parameters from CampaignDatabase, manages dynamic objectives,
## enemy squads, interactive targets (rescuing captives, sabotaging generators, siphons),
## story dialogues, and seamless progression to the next mission.
extends Node3D
class_name ModularMissionController

const CampaignDatabase = preload("res://scripts/campaign/campaign_database.gd")

@export var override_level_index: int = 0

var level_data: Dictionary = {}
var current_level_index: int = 1
var enemies_defeated: int = 0
var required_kills: int = 5
var main_objectives_completed: bool = false
var is_mission_finished: bool = false
var mission_start_time: float = 0.0

# Interactive object counters
var interactive_targets_total: int = 0
var interactive_targets_cleared: int = 0

@onready var kael: CharacterBody3D = get_node_or_null("KaelShooter") as CharacterBody3D

func _ready() -> void:
	# Determine level index
	if override_level_index > 0:
		current_level_index = override_level_index
	elif LevelManager:
		current_level_index = LevelManager.current_level_index
	else:
		current_level_index = 1

	level_data = CampaignDatabase.get_level(current_level_index)
	mission_start_time = Time.get_ticks_msec() / 1000.0

	# Ensure player reference and full health/shield at mission initialization
	if kael:
		GameManager.player_ref = kael
		GameManager.register_checkpoint(kael.global_position, current_level_index)
		kael.current_health = kael.max_health
		kael.current_shield = kael.max_shield
		kael.current_stamina = kael.max_stamina
		if kael.has_method("reset_camera"):
			kael.reset_camera()

	# Optimize environment for mobile if on Android / touch device
	if OS.has_feature("mobile") or OS.has_feature("android"):
		_optimize_for_mobile()

	_setup_mission()
	_connect_enemies()
	_setup_interactive_objects()

	# Listen for weather activation
	if EventBus3D:
		EventBus3D.weather_activated.connect(_on_weather_activated)

	await get_tree().create_timer(0.6).timeout
	_play_intro_dialogue()

func _optimize_for_mobile() -> void:
	var we := get_node_or_null("WorldEnvironment") as WorldEnvironment
	if we and we.environment:
		var env := we.environment
		env.glow_enabled = false
		env.fog_enabled = false
		env.ambient_light_energy = 0.7

func _setup_mission() -> void:
	if level_data.is_empty():
		return

	var m_title: String = level_data.get("name", "Mission")
	var m_obj: String = level_data.get("main_objective", "Complete objectives.")
	required_kills = level_data.get("required_kills", 5)

	# Update EventBus quest display
	if EventBus3D:
		EventBus3D.emit_signal("quest_updated", "Chapter %d: %s" % [current_level_index, m_title], m_obj)

func _connect_enemies() -> void:
	var enemy_nodes := get_tree().get_nodes_in_group("enemies")
	var boss_name: String = level_data.get("boss", "")

	for i in range(enemy_nodes.size()):
		var enemy = enemy_nodes[i]
		if enemy.has_signal("enemy_defeated"):
			enemy.enemy_defeated.connect(_on_enemy_defeated)

		# If mission has a boss, configure the last enemy in the group as the designated Boss
		if boss_name != "" and i == enemy_nodes.size() - 1:
			enemy.name = "Boss_" + boss_name.replace(" ", "_")
			var health = enemy.get_node_or_null("EnemyHealth")
			if health:
				health.max_health = 280
				health.current_health = 280
				health.max_shield = 100
				health.current_shield = 100
			elif "max_health" in enemy:
				enemy.max_health = 280
				enemy.current_health = 280
				if "soldier_name" in enemy:
					enemy.soldier_name = "BOSS: " + boss_name
			var combat = enemy.get_node_or_null("EnemyCombat")
			if combat:
				combat.damage = 25

func _setup_interactive_objects() -> void:
	var targets := get_tree().get_nodes_in_group("mission_targets")
	interactive_targets_total = targets.size()
	for target in targets:
		if target.has_signal("target_cleared"):
			target.target_cleared.connect(_on_interactive_target_cleared)

func _play_intro_dialogue() -> void:
	var dialogue_seq: Array = level_data.get("intro_dialogue", [])
	if dialogue_seq.size() > 0 and EventBus3D:
		EventBus3D.emit_signal("show_dialogue", dialogue_seq)

func _on_enemy_defeated(_soldier: Node) -> void:
	enemies_defeated += 1
	var m_title: String = level_data.get("name", "Mission")
	var desc := "Eliminate hostile operatives [%d/%d]." % [enemies_defeated, required_kills]
	if EventBus3D:
		EventBus3D.emit_signal("quest_updated", "Chapter %d: %s" % [current_level_index, m_title], desc)

	_check_mission_completion()

func _on_interactive_target_cleared(_target_node: Node) -> void:
	interactive_targets_cleared += 1
	_check_mission_completion()

func _on_weather_activated(weather_type: String, _pos: Variant) -> void:
	var req_weather: String = level_data.get("element", "")
	# If mission requires weather siphon or altar infusion
	var siphon = get_node_or_null("WeatherSiphon")
	if siphon and not main_objectives_completed:
		if weather_type == req_weather or weather_type == "thunder":
			_complete_siphon_objective(siphon)

func _complete_siphon_objective(siphon_node: Node3D) -> void:
	AudioManager.play_sound("puzzle_solve")
	var label = siphon_node.get_node_or_null("Label3D") as Label3D
	if label:
		label.text = "✦ Siphon Overloaded — Atmospheric Flow Purged!"
		label.modulate = Color(0.3, 1.0, 0.5)
	var core = siphon_node.get_node_or_null("CoreMesh") as MeshInstance3D
	if core:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.3, 1.0, 0.8)
		mat.emission_enabled = true
		mat.emission = Color(0.2, 0.9, 0.7)
		mat.emission_energy_multiplier = 4.0
		core.set_surface_override_material(0, mat)

	main_objectives_completed = true
	_check_mission_completion()

func _check_mission_completion() -> void:
	if is_mission_finished:
		return

	# Verification condition based on mission type
	var m_type: String = level_data.get("mission_type", "ELIMINATION")
	var enemies_done := (enemies_defeated >= required_kills)
	var targets_done := (interactive_targets_total == 0 or interactive_targets_cleared >= interactive_targets_total)

	var is_ready := false
	match m_type:
		"ELIMINATION", "BOSS_HUNT", "SURVIVAL":
			is_ready = enemies_done
		"RESCUE", "SABOTAGE":
			is_ready = enemies_done and targets_done
		_:
			is_ready = enemies_done

	if is_ready:
		_finish_mission_victory()

func _finish_mission_victory() -> void:
	is_mission_finished = true
	AudioManager.play_sound("checkpoint")

	var elapsed: float = (Time.get_ticks_msec() / 1000.0) - mission_start_time
	var accuracy: float = clampf(82.0 + randf() * 14.0, 75.0, 99.0)

	if EventBus3D:
		EventBus3D.emit_signal("quest_completed", level_data.get("name", "Mission Complete"))

	# Victory dialogue
	var victory_seq: Array = [
		{
			"speaker": "Lyra",
			"text": "Objective accomplished! Sector cleared. Superb combat performance, Kael!"
		}
	]
	if EventBus3D:
		EventBus3D.emit_signal("show_dialogue", victory_seq)

	await get_tree().create_timer(1.8).timeout

	# Complete in LevelManager (which marks save data & unlocks next mission)
	if LevelManager:
		LevelManager.complete_current_level(enemies_defeated, accuracy)
