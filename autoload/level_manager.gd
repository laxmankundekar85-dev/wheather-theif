## LevelManager.gd
## Master Campaign Progression & Mission Manager for Weather Thief (All 55 Levels).
## Coordinates data-driven level loading, scene transitions, save persistence,
## unlock conditions, victory debriefing screens, and final campaign victory sequence.
extends Node

const CampaignDatabase = preload("res://scripts/campaign/campaign_database.gd")

var current_level_index: int = 1
var max_unlocked_level: int = 1
var level_start_time: float = 0.0
var is_transitioning: bool = false
var is_current_level_completed: bool = false

signal level_started(level_data: Dictionary)
signal level_completed(level_data: Dictionary, stats: Dictionary)
signal campaign_completed

func _ready() -> void:
	_sync_save_state()
	level_start_time = Time.get_ticks_msec() / 1000.0
	print("[LevelManager] Initialized with 55-level campaign architecture.")

func _sync_save_state() -> void:
	if SaveManager:
		max_unlocked_level = SaveManager.get_highest_unlocked_level()
		current_level_index = int(SaveManager.save_data.get("current_level", 1))
	else:
		max_unlocked_level = 1
		current_level_index = 1

func get_total_levels() -> int:
	return CampaignDatabase.get_all_levels().size()

func get_level_data(level_idx: int) -> Dictionary:
	return CampaignDatabase.get_level(level_idx)

func get_current_level_data() -> Dictionary:
	return get_level_data(current_level_index)

func is_level_unlocked(level_idx: int) -> bool:
	if level_idx <= 1:
		return true
	if SaveManager:
		return SaveManager.is_level_unlocked(level_idx)
	return level_idx <= max_unlocked_level

func start_level(level_idx: int) -> void:
	if is_transitioning:
		print("[LevelManager] Transition already in progress, ignoring duplicate start request.")
		return

	if level_idx < 1 or level_idx > get_total_levels():
		push_error("[LevelManager] Invalid level index requested: %d" % level_idx)
		return

	if not is_level_unlocked(level_idx):
		push_warning("[LevelManager] Level %d is locked! Player must complete previous mission." % level_idx)
		return

	var lvl_data: Dictionary = get_level_data(level_idx)
	var scene_path: String = lvl_data.get("scene", "")

	if scene_path == "" or not ResourceLoader.exists(scene_path):
		push_error("[LevelManager] Target scene not found: %s" % scene_path)
		# Fallback to level select instead of freezing
		open_level_select()
		return

	is_transitioning = true
	is_current_level_completed = false
	current_level_index = level_idx
	level_start_time = Time.get_ticks_msec() / 1000.0

	# Record current level in save data
	if SaveManager:
		SaveManager.save_data["current_level"] = current_level_index
		SaveManager.save_data["current_mission_id"] = lvl_data.get("mission_id", "mission_01")
		SaveManager.save_game()

	print("[LevelManager] Loading Level %d: %s -> %s" % [level_idx, lvl_data.get("name", ""), scene_path])
	emit_signal("level_started", lvl_data)

	if SceneTransition:
		SceneTransition.fade_to_scene(scene_path, 0.45)
		await SceneTransition.transition_finished
	else:
		get_tree().paused = false
		get_tree().change_scene_to_file(scene_path)

	is_transitioning = false

func complete_current_level(enemies_slain: int = 5, accuracy: float = 88.0) -> void:
	if is_current_level_completed:
		return
	is_current_level_completed = true

	var lvl_data: Dictionary = get_current_level_data()
	var elapsed := (Time.get_ticks_msec() / 1000.0) - level_start_time
	var mission_id: String = lvl_data.get("mission_id", "mission_%02d" % current_level_index)

	# 1. Unlock next level
	if current_level_index < get_total_levels():
		max_unlocked_level = maxi(max_unlocked_level, current_level_index + 1)

	# 2. Add rewards and record completion in SaveManager
	var xp: int = lvl_data.get("reward_xp", 1500)
	var shards: int = lvl_data.get("reward_shards", 250)
	var stats := {
		"time_seconds": elapsed,
		"enemies_slain": enemies_slain,
		"accuracy": accuracy
	}

	if SaveManager:
		SaveManager.mark_level_completed(current_level_index, mission_id, stats)
		SaveManager.add_rewards(xp, shards)

	# 3. Unlock weather if rewarded
	var rew_weather: String = lvl_data.get("unlocked_weather", "")
	if rew_weather != "" and WeatherManager:
		WeatherManager.unlock_weather(rew_weather)

	emit_signal("level_completed", lvl_data, stats)
	_show_completion_screen(lvl_data, stats)

func _show_completion_screen(lvl_data: Dictionary, stats: Dictionary) -> void:
	var screen_scn := load("res://scenes/ui/mission_complete_screen.tscn") as PackedScene
	if screen_scn:
		var screen_inst = screen_scn.instantiate()
		get_tree().root.add_child(screen_inst)
		if screen_inst.has_method("setup"):
			screen_inst.setup(lvl_data, stats)

func proceed_to_next_level() -> void:
	if is_transitioning:
		return

	if current_level_index < get_total_levels():
		var next_idx := current_level_index + 1
		start_level(next_idx)
	else:
		# Final mission 55 complete! Trigger campaign ending
		emit_signal("campaign_completed")
		open_level_select()

func replay_current_level() -> void:
	if is_transitioning:
		return
	start_level(current_level_index)

func open_level_select() -> void:
	var sel_scn := "res://scenes/ui/level_select_menu.tscn"
	if ResourceLoader.exists(sel_scn):
		if SceneTransition:
			SceneTransition.fade_to_scene(sel_scn, 0.4)
		else:
			get_tree().paused = false
			get_tree().change_scene_to_file(sel_scn)
