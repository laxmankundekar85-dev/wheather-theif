## Level01.gd
## Forgotten Forest — Level 1 controller.
## Manages parallax background, level story triggers, puzzle objectives, and shrine completion.
extends Node2D

@onready var hud: CanvasLayer = $HUD
@onready var player: CharacterBody2D = $Player
@onready var checkpoint_01: Area2D = $Checkpoints/Checkpoint_01
@onready var checkpoint_02: Area2D = $Checkpoints/Checkpoint_02
@onready var sun_monolith: Area2D = $InteractiveObjects/SunMonolith
@onready var guardian: CharacterBody2D = get_node_or_null("Enemies/CorruptedGuardian")
@onready var death_zone: Area2D = get_node_or_null("DeathZone")

const LEVEL_ID := 1
const LEVEL_NAME := "Forgotten Forest"

var _intro_shown: bool = false
var _rain_hint_shown: bool = false
var _snow_hint_shown: bool = false
var _wind_hint_shown: bool = false
var _sun_hint_shown: bool = false

func _ready() -> void:
	GameManager.current_level = LEVEL_ID

	# Connect death zone
	if death_zone:
		death_zone.body_entered.connect(_on_death_zone_entered)

	# Connect checkpoint triggers
	if checkpoint_01:
		checkpoint_01.body_entered.connect(func(b): _on_checkpoint_entered(b, checkpoint_01, 1))
	if checkpoint_02:
		checkpoint_02.body_entered.connect(func(b): _on_checkpoint_entered(b, checkpoint_02, 2))

	# Connect monolith
	if sun_monolith and sun_monolith.has_signal("shrine_activated"):
		sun_monolith.shrine_activated.connect(_on_shrine_restored)

	# Connect guardian
	if guardian and guardian.has_signal("guardian_defeated"):
		guardian.guardian_defeated.connect(_on_guardian_defeated)

	# Initial objective
	if hud and hud.has_method("set_objective"):
		hud.set_objective("Explore the grove & find the Rain Bottle")
		hud.show_notification("🌲 Forgotten Forest", Color(0.4, 0.9, 0.4), 3.0)

	print("[Level01] Forgotten Forest loaded with full puzzle & boss triggers.")

func _on_checkpoint_entered(body: Node2D, cp_node: Area2D, cp_num: int) -> void:
	if body.is_in_group("player") and cp_node.monitoring:
		cp_node.monitoring = false
		GameManager.register_checkpoint(body.global_position, LEVEL_ID)
		SaveManager.save_game()
		AudioManager.play_sound("checkpoint")

		var flag := cp_node.get_node_or_null("CPFlag")
		if flag:
			var tween := create_tween()
			tween.tween_property(flag, "modulate", Color(0.3, 1.0, 0.4), 0.3)
		if hud:
			hud.show_notification("✦ Checkpoint %d Saved!" % cp_num, Color(0.3, 1.0, 0.5), 2.0)

func _on_death_zone_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		GameManager.damage_player(GameManager.player_health)

func _on_guardian_defeated() -> void:
	if hud:
		hud.set_objective("Restore the Forest Weather Shrine with Sun power!")

func _on_shrine_restored() -> void:
	SaveManager.save_data["level_01_cleared"] = true
	SaveManager.save_game()
	AudioManager.play_sound("checkpoint")

	if hud:
		hud.set_objective("Level Complete! Balance restored.")
		hud.show_notification("🎉 FORGOTTEN FOREST COMPLETED!", Color(1.0, 0.85, 0.2), 6.0)

	# Transition back to menu or victory screen after 4 seconds
	await get_tree().create_timer(4.5).timeout
	SceneTransition.fade_to_scene("res://scenes/menus/main_menu.tscn", 1.0)
