## GameManager.gd
## Global autoload that manages game state, scene transitions, and core systems.
extends Node

signal game_paused(is_paused: bool)
signal health_changed(current: int, maximum: int)
signal player_died
signal level_completed(level_id: int)
signal checkpoint_reached(position: Variant)

# Game state
var is_paused: bool = false
var current_level: int = 1
var player_max_health: int = 5
var player_health: int = 5

# Player reference (set by Player when it enters the scene)
var player_ref: Node = null

# Checkpoint data
var last_checkpoint_position: Variant = Vector3(0, 1.5, 0)
var last_checkpoint_level: int = 1

func _ready() -> void:
	print("[GameManager] Initialized.")

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("pause_game"):
		toggle_pause()

func toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	emit_signal("game_paused", is_paused)

func set_player_health(hp: int) -> void:
	player_health = clamp(hp, 0, player_max_health)
	emit_signal("health_changed", player_health, player_max_health)
	if player_health <= 0:
		emit_signal("player_died")

func heal_player(amount: int) -> void:
	set_player_health(player_health + amount)

func damage_player(amount: int) -> void:
	set_player_health(player_health - amount)

func register_checkpoint(pos: Variant, level_id: int) -> void:
	last_checkpoint_position = pos
	last_checkpoint_level = level_id
	emit_signal("checkpoint_reached", pos)

func go_to_scene(path: String) -> void:
	get_tree().paused = false
	is_paused = false
	get_tree().change_scene_to_file(path)

func respawn_player() -> void:
	if player_ref != null:
		player_ref.respawn(last_checkpoint_position)
	else:
		go_to_scene("res://scenes/levels/verdantia_combat_outpost.tscn")
