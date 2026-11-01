## SaveManager.gd
## Robust, versioned persistence system for Weather Thief.
## Tracks campaign progression across all 55 levels, mission completion states,
## best performance records, collected weather abilities, and player upgrades.
extends Node

const SAVE_PATH := "user://weather_thief_save.dat"
const SAVE_VERSION := 2

var save_data: Dictionary = {}

signal save_data_loaded
signal save_data_updated

func _ready() -> void:
	_init_default_save()
	if has_save_file():
		load_game()
	print("[SaveManager] Initialized with Save Version %d." % SAVE_VERSION)

func _init_default_save() -> void:
	save_data = {
		"version": SAVE_VERSION,
		"highest_unlocked_level": 1,
		"completed_levels": [],
		"completed_missions": [],
		"level_best_scores": {},
		"current_level": 1,
		"current_mission_id": "mission_01",
		"checkpoint_position": {"x": 0.0, "y": 0.0, "z": 0.0},
		"unlocked_weathers": ["rain"],
		"weather_charges": {"rain": 3, "snow": 0, "wind": 0, "sun": 0},
		"player_health": 100,
		"player_shield": 50,
		"player_xp": 0,
		"collected_shards": 0,
		"collected_items": [],
		"achievements": [],
		"settings": {
			"music_volume": 0.8,
			"sfx_volume": 1.0,
			"fullscreen": false,
		},
		"play_time_seconds": 0.0,
	}

func save_game() -> void:
	# Sync live progression into save_data
	if LevelManager:
		var current_max: int = int(save_data.get("highest_unlocked_level", 1))
		var new_highest := maxi(current_max, LevelManager.max_unlocked_level)
		save_data["highest_unlocked_level"] = new_highest
		LevelManager.max_unlocked_level = new_highest
		save_data["current_level"] = LevelManager.current_level_index
	if WeatherManager:
		save_data["unlocked_weathers"] = WeatherManager.unlocked_weathers.duplicate()
	if GameManager:
		if GameManager.last_checkpoint_position is Vector3:
			save_data["checkpoint_position"] = {
				"x": GameManager.last_checkpoint_position.x,
				"y": GameManager.last_checkpoint_position.y,
				"z": GameManager.last_checkpoint_position.z
			}

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("[SaveManager] Cannot open save file for writing: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	emit_signal("save_data_updated")
	print("[SaveManager] Game saved successfully. Max Level: %d" % save_data.get("highest_unlocked_level", 1))

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		print("[SaveManager] No save file found on disk.")
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("[SaveManager] Cannot open save file for reading!")
		return false

	var content := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(content)
	if parsed == null or typeof(parsed) != TYPE_DICTIONARY:
		push_error("[SaveManager] Corrupted save file detected, restoring defaults.")
		_init_default_save()
		return false

	# Merge loaded keys into default template to ensure missing keys never crash the game
	for k in parsed:
		save_data[k] = parsed[k]

	# Apply loaded settings
	if "settings" in save_data and typeof(save_data["settings"]) == TYPE_DICTIONARY:
		var s: Dictionary = save_data["settings"]
		AudioManager.set_music_volume(s.get("music_volume", 0.8))
		AudioManager.set_sfx_volume(s.get("sfx_volume", 1.0))

	# Apply unlocked weathers to WeatherManager
	if WeatherManager and "unlocked_weathers" in save_data:
		for w in save_data["unlocked_weathers"]:
			WeatherManager.unlock_weather(str(w))

	emit_signal("save_data_loaded")
	print("[SaveManager] Game loaded. Highest Unlocked Level: %d" % get_highest_unlocked_level())
	return true

func get_highest_unlocked_level() -> int:
	return int(save_data.get("highest_unlocked_level", 1))

func is_level_unlocked(level_idx: int) -> bool:
	if level_idx <= 1:
		return true
	return level_idx <= get_highest_unlocked_level()

func is_level_completed(level_idx: int) -> bool:
	var comp_list = save_data.get("completed_levels", [])
	return comp_list.has(level_idx)

func mark_level_completed(level_idx: int, mission_id: String, score_data: Dictionary = {}) -> void:
	# Add to completed levels
	var comp_levels: Array = save_data.get("completed_levels", [])
	if not comp_levels.has(level_idx):
		comp_levels.append(level_idx)
	save_data["completed_levels"] = comp_levels

	# Add to completed missions
	var comp_missions: Array = save_data.get("completed_missions", [])
	if mission_id != "" and not comp_missions.has(mission_id):
		comp_missions.append(mission_id)
	save_data["completed_missions"] = comp_missions

	# Unlock next level
	var current_highest: int = get_highest_unlocked_level()
	if level_idx >= current_highest:
		save_data["highest_unlocked_level"] = level_idx + 1
		if LevelManager:
			LevelManager.max_unlocked_level = save_data["highest_unlocked_level"]

	# Store best scores
	var best_scores: Dictionary = save_data.get("level_best_scores", {})
	var existing = best_scores.get(str(level_idx), {})
	if existing.is_empty():
		best_scores[str(level_idx)] = score_data
	else:
		# Keep best time
		var old_time: float = existing.get("time_seconds", 9999.0)
		var new_time: float = score_data.get("time_seconds", 9999.0)
		if new_time < old_time:
			best_scores[str(level_idx)] = score_data
	save_data["level_best_scores"] = best_scores

	save_game()

func get_level_score(level_idx: int) -> Dictionary:
	var best_scores: Dictionary = save_data.get("level_best_scores", {})
	return best_scores.get(str(level_idx), {})

func add_rewards(xp: int, shards: int) -> void:
	save_data["player_xp"] = int(save_data.get("player_xp", 0)) + xp
	save_data["collected_shards"] = int(save_data.get("collected_shards", 0)) + shards
	save_game()

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_PATH)

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	_init_default_save()
	print("[SaveManager] Save deleted.")
