## VerdantiaDemo.gd
## Chapter 1: The Fall of the Seven Skies
## Mission 1: The Village That Forgot The Rain
## Implements the open-world narrative quest with NPC interactions, clue investigations,
## hydraulic waterwheel puzzle, and boss combat.
extends Node3D

@onready var kael: KaelController = $Kael
@onready var lyra: LyraCompanion = $LyraCompanion
@onready var puzzle_gate: StaticBody3D = $Environment/PuzzleGate
@onready var gate_label: Label3D = $Environment/PuzzleGate/Label3D
@onready var boss: CorruptedForestGuardian = $CorruptedForestGuardian
@onready var water_river: Area3D = $Environment/WaterRiver

var clues_found: int = 0
var is_puzzle_solved: bool = false
var is_demo_completed: bool = false

func _ready() -> void:
	GameManager.current_level = 1
	GameManager.player_ref = kael
	GameManager.register_checkpoint(kael.global_position, 1)

	WeatherManager.weather_activated.connect(_on_weather_activated)
	EventBus3D.clue_discovered.connect(_on_clue_discovered)

	if boss:
		boss.boss_slain.connect(_on_boss_slain)

	# Start Chapter 1 Opening Story
	await get_tree().create_timer(0.6).timeout
	_play_opening_cinematic()

func _play_opening_cinematic() -> void:
	var sequence: Array = [
		{
			"speaker": "Lyra",
			"text": "Kael! You're finally awake! Look out across the valley—we are standing above Verdantia, the first of the Seven Kingdoms."
		},
		{
			"speaker": "Kael",
			"text": "The wind carries an eerie quiet. And this crest pulsing with rain energy on my hand... What happened here?"
		},
		{
			"speaker": "Lyra",
			"text": "The celestial sky cracked open and the Seven Guardians fell into darkness. Look at the village below—their life-giving river has vanished into thin air!"
		},
		{
			"speaker": "Lyra",
			"text": "Let us head down to the village and speak with the inhabitants. Mira, the River Keeper, might know where the water stopped flowing."
		}
	]
	EventBus3D.emit_signal("show_dialogue", sequence)
	EventBus3D.emit_signal("quest_updated", "The Village That Forgot The Rain", "Head down to the village and speak with Mira the River Keeper.")

func _on_clue_discovered(clue_id: String) -> void:
	clues_found += 1
	match clue_id:
		"waterwheel":
			EventBus3D.emit_signal("quest_updated", "The Village That Forgot The Rain", "Search the river gorge for abandoned explorer equipment.")
		"explorer_gear":
			EventBus3D.emit_signal("quest_updated", "The Village That Forgot The Rain", "Investigate the ancient runic seal blocking the Sunken Grotto.")
		"grotto_seal":
			EventBus3D.emit_signal("quest_updated", "The Village That Forgot The Rain", "Channel Rain Blade [E] at the Ancient Hydraulic Gate to unseal the sanctuary.")

func _on_weather_activated(weather_type: String, pos: Variant) -> void:
	if is_puzzle_solved:
		return

	if weather_type == "rain":
		var cast_pos: Vector3 = kael.global_position
		if pos is Vector3:
			cast_pos = pos

		# Check distance to puzzle gate
		if puzzle_gate and puzzle_gate.global_position.distance_to(cast_pos) <= 24.0:
			_solve_puzzle()

func _solve_puzzle() -> void:
	is_puzzle_solved = true
	AudioManager.play_sound("puzzle_solve")

	if gate_label:
		gate_label.text = "💧 Hydraulic Conduits Activated — Sanctuary Unsealed!"
		gate_label.modulate = Color(0.35, 0.95, 1.0)

	# Lower ancient gate smoothly
	var tw := create_tween()
	tw.tween_property(puzzle_gate, "position:y", -4.5, 1.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	await tw.finished

	var dialogue: Array = [
		{
			"speaker": "Lyra",
			"text": "The ancient water wheel turned! The hydraulic sluice gate has opened! The Corrupted Guardian awaits inside the sanctuary."
		},
		{
			"speaker": "Kael",
			"text": "Draw your focus, Lyra. Once we cleanse the guardian, the river will flow once more."
		}
	]
	EventBus3D.emit_signal("show_dialogue", dialogue)
	EventBus3D.emit_signal("quest_updated", "Sanctuary Guardian", "Enter the inner courtyard and defeat the Corrupted Forest Guardian.")

func _on_boss_slain() -> void:
	if is_demo_completed:
		return
	is_demo_completed = true

	# Restore river water level
	if water_river:
		var tw_water := create_tween()
		tw_water.tween_property(water_river, "position:y", -0.4, 2.0).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	var victory_dialogue: Array = [
		{
			"speaker": "Lyra",
			"text": "We did it, Kael! The Primordial Rain Core is restored! Listen—the rushing waters have returned to the riverbed!"
		},
		{
			"speaker": "Mira",
			"text": "Look! The waterwheel is spinning again! Verdantia is saved from the drought! You truly wield the crest of the skies!"
		},
		{
			"speaker": "Kael",
			"text": "Wait... Look at the cliffside above the trees. A cloaked figure is watching us from the shadows of the mountain."
		},
		{
			"speaker": "Lyra",
			"text": "The Corruptor... They know we have claimed the first Weather Core. The journey to the frozen peaks of Glaciera lies ahead!"
		},
		{
			"speaker": "Narrator",
			"text": "🎉 [b]MISSION 1 COMPLETE: THE VILLAGE THAT FORGOT THE RAIN[/b] 🎉\nVerdantia's waters flow once more. The adventure across the Seven Skies continues!"
		}
	]
	EventBus3D.emit_signal("show_dialogue", victory_dialogue)
	EventBus3D.emit_signal("quest_updated", "Chapter 1 Complete", "Verdantia's waters restored. Speak with villagers or explore the open forest.")
