## MissionCompleteScreen.gd
## Comprehensive end-of-mission debriefing screen.
## Supports Next Mission, Replay Mission, Level Select, optional objective stats,
## rewards tally, debounce protection, and final victory handling.
extends CanvasLayer

const CampaignDatabase = preload("res://scripts/campaign/campaign_database.gd")

@onready var label_title: Label = $Panel/Margin/VBox/Title
@onready var label_subtitle: Label = $Panel/Margin/VBox/Subtitle
@onready var label_main_obj: Label = $Panel/Margin/VBox/ObjectivesBox/MainObjText
@onready var label_opt_obj: Label = $Panel/Margin/VBox/ObjectivesBox/OptObjText
@onready var label_time: Label = $Panel/Margin/VBox/StatsGrid/TimeVal
@onready var label_kills: Label = $Panel/Margin/VBox/StatsGrid/KillsVal
@onready var label_acc: Label = $Panel/Margin/VBox/StatsGrid/AccVal
@onready var label_reward_xp: Label = $Panel/Margin/VBox/RewardsGrid/XPVal
@onready var label_reward_shards: Label = $Panel/Margin/VBox/RewardsGrid/ShardsVal
@onready var label_reward_unlock: Label = $Panel/Margin/VBox/UnlockBox/UnlockVal
@onready var btn_next: Button = $Panel/Margin/VBox/Buttons/BtnNext
@onready var btn_replay: Button = $Panel/Margin/VBox/Buttons/BtnReplay
@onready var btn_menu: Button = $Panel/Margin/VBox/Buttons/BtnMenu

var level_info: Dictionary = {}
var is_processing_action: bool = false

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if btn_next:
		btn_next.pressed.connect(_on_next_pressed)
	if btn_replay:
		btn_replay.pressed.connect(_on_replay_pressed)
	if btn_menu:
		btn_menu.pressed.connect(_on_menu_pressed)
	AudioManager.play_sound("checkpoint")

func setup(lvl_data: Dictionary, stats: Dictionary) -> void:
	level_info = lvl_data
	var idx: int = lvl_data.get("index", 1)
	var lvl_name: String = lvl_data.get("name", "Mission Complete")
	var rew_weather: String = lvl_data.get("unlocked_weather", "")
	var total_levels: int = CampaignDatabase.get_all_levels().size()

	if label_title:
		label_title.text = "MISSION COMPLETED"
	if label_subtitle:
		label_subtitle.text = "Level %d of %d: %s" % [idx, total_levels, lvl_name]

	# Objectives display
	if label_main_obj:
		label_main_obj.text = "✔ Main: " + lvl_data.get("main_objective", "Clear enemy sector.")
	if label_opt_obj:
		label_opt_obj.text = "★ Bonus: " + lvl_data.get("optional_objective", "Complete tactical rating.")

	var time_sec: float = stats.get("time_seconds", 120.0)
	var mins: int = int(time_sec / 60.0)
	var secs: int = int(time_sec) % 60
	if label_time:
		label_time.text = "%02d:%02d" % [mins, secs]

	if label_kills:
		label_kills.text = "%d Hostiles" % stats.get("enemies_slain", 5)
	if label_acc:
		label_acc.text = "%.1f%%" % stats.get("accuracy", 88.5)

	if label_reward_xp:
		label_reward_xp.text = "+%d XP" % lvl_data.get("reward_xp", 1500)
	if label_reward_shards:
		label_reward_shards.text = "+%d Ether Shards" % lvl_data.get("reward_shards", 250)

	if label_reward_unlock:
		if rew_weather != "":
			label_reward_unlock.text = "✦ UNLOCKED: %s!" % rew_weather.to_upper()
			label_reward_unlock.visible = true
		else:
			label_reward_unlock.text = "✦ Tactical Combat Rating: S-Rank"

	# If final level 55
	if idx >= total_levels:
		if btn_next:
			btn_next.text = "VIEW ENDING 🏆"
		if label_title:
			label_title.text = "CAMPAIGN VICTORY!"

func _disable_buttons() -> void:
	is_processing_action = true
	if btn_next:
		btn_next.disabled = true
	if btn_replay:
		btn_replay.disabled = true
	if btn_menu:
		btn_menu.disabled = true

func _on_next_pressed() -> void:
	if is_processing_action:
		return
	_disable_buttons()
	AudioManager.play_sound("button_click")
	queue_free()

	if LevelManager:
		LevelManager.proceed_to_next_level()

func _on_replay_pressed() -> void:
	if is_processing_action:
		return
	_disable_buttons()
	AudioManager.play_sound("button_click")
	queue_free()

	if LevelManager:
		LevelManager.replay_current_level()

func _on_menu_pressed() -> void:
	if is_processing_action:
		return
	_disable_buttons()
	AudioManager.play_sound("button_click")
	queue_free()

	if LevelManager:
		LevelManager.open_level_select()
