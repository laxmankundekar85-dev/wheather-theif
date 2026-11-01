## MissionManager.gd
## Central Story & Mission Architecture for WEATHER THIEF: THE LAST SKY.
## Coordinates narrative chapters, multi-phase objectives, intel logs, and mission progression.
extends Node

signal mission_started(mission_id: String, title: String)
signal objective_updated(mission_id: String, objective_text: String, is_complete: bool)
signal mission_phase_advanced(phase_index: int, phase_title: String)
signal mission_completed(mission_id: String, rewards: Dictionary)
signal intel_discovered(intel_title: String, intel_body: String)

# Region Identifiers
const REGION_FORGOTTEN_DISTRICT = "forgotten_district"
const REGION_FROZEN_MOUNTAINS    = "frozen_mountains"
const REGION_SKY_ISLANDS        = "sky_islands"
const REGION_SUNKEN_DESERT      = "sunken_desert"
const REGION_STORM_KINGDOM      = "storm_kingdom"

# Active State
var current_region: String = REGION_FORGOTTEN_DISTRICT
var current_mission_id: String = "verdantia_reclamation"
var current_phase: int = 1
var max_phases: int = 5
var objectives: Array[Dictionary] = []
var discovered_intel: Array[Dictionary] = []
var completed_missions: Array[String] = []

# Persistent Story Lore Records
var story_journal: Array[Dictionary] = [
	{
		"id": "lore_great_collapse",
		"title": "The Great Weather Collapse",
		"date": "Cycle 412",
		"text": "Before the Collapse, the Four Siphons kept the elements in harmonious balance: Rain for renewal, Snow for preservation, Wind for movement, and Sun for energy. The Eclipse Order shattered the equilibrium by force-extracting celestial ether, leaving regions choked in unnatural anomalies."
	},
	{
		"id": "lore_eclipse_order",
		"title": "The Eclipse Order",
		"date": "Classified Intel",
		"text": "A technocratic splinter organization led by High Magus Corvin and Vanguard Commander Overseer Vane. They weaponize stolen weather energy into devastating ballistic and beam armaments."
	},
	{
		"id": "lore_kael_heritage",
		"title": "Kael's Weather Attunement",
		"date": "Field Observation",
		"text": "Unlike standard Skyweavers, Kael can absorb, channel, and synthesize all four primal weather currents through his bodily ether core, making him the only hope to overload corrupted siphons."
	}
]

func _ready() -> void:
	print("[MissionManager] Weather Thief: The Last Sky narrative engine initialized.")
	_init_chapter_one()

func _init_chapter_one() -> void:
	current_region = REGION_FORGOTTEN_DISTRICT
	current_mission_id = "verdantia_reclamation"
	current_phase = 1
	max_phases = 5

	objectives = [
		{
			"phase": 1,
			"title": "Phase 1: Sector Breach & Recon",
			"desc": "Infiltrate Ancient Market and neutralize Vanguard Infiltrator scout.",
			"completed": false
		},
		{
			"phase": 2,
			"title": "Phase 2: Overgrown Passage Flank",
			"desc": "Advance through the ruins corridor and eliminate the Vanguard Trooper ambush.",
			"completed": false
		},
		{
			"phase": 3,
			"title": "Phase 3: Courtyard Assault",
			"desc": "Use tactical stone cover to neutralize the Heavy Vanguard Enforcer.",
			"completed": false
		},
		{
			"phase": 4,
			"title": "Phase 4: Guard Tower Perch",
			"desc": "Counter the Vanguard Marksman sniper stationed on the fortress watchtower.",
			"completed": false
		},
		{
			"phase": 5,
			"title": "Phase 5: Weather Siphon Overload",
			"desc": "Defeat Vanguard Overseer and infuse the Corrupted Siphon with Rain Magic [Q].",
			"completed": false
		}
	]

func get_active_objective() -> Dictionary:
	for obj in objectives:
		if not obj["completed"]:
			return obj
	return {}

func complete_objective(phase_idx: int) -> void:
	for obj in objectives:
		if obj["phase"] == phase_idx and not obj["completed"]:
			obj["completed"] = true
			emit_signal("objective_updated", current_mission_id, obj["desc"], true)
			AudioManager.play_sound("puzzle_solve")

			if phase_idx < max_phases:
				current_phase = phase_idx + 1
				var next_obj = get_active_objective()
				if next_obj:
					emit_signal("mission_phase_advanced", current_phase, next_obj["title"])
					EventBus3D.emit_signal("quest_updated", next_obj["title"], next_obj["desc"])
			else:
				_on_all_phases_complete()
			break

func _on_all_phases_complete() -> void:
	if not completed_missions.has(current_mission_id):
		completed_missions.append(current_mission_id)

	var rewards := {
		"xp": 1500,
		"weather_shards": 250,
		"unlocked_weapon": "Stormfall Precision Sniper Rifle",
		"weather_unlocked": "snow"
	}

	WeatherManager.unlock_weather("snow")
	SaveManager.save_game()
	emit_signal("mission_completed", current_mission_id, rewards)
	EventBus3D.emit_signal("quest_updated", "Chapter Complete!", "Verdantia Outpost secured! Snow Magic unlocked.")

func add_intel(intel_id: String, title: String, text: String) -> void:
	var entry := {
		"id": intel_id,
		"title": title,
		"date": "Field Log",
		"text": text
	}
	discovered_intel.append(entry)
	emit_signal("intel_discovered", title, text)
	EventBus3D.emit_signal("clue_discovered", intel_id)
	AudioManager.play_sound("collect")

