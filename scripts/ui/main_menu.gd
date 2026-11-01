## MainMenu.gd
## The main menu screen with animated title, buttons, and parallax decorations.
extends Node2D

@onready var new_game_btn:   Button = $UI/Root/ButtonsContainer/NewGameBtn
@onready var tps_demo_btn:   Button = $UI/Root/ButtonsContainer/TpsDemoBtn
@onready var continue_btn:   Button = $UI/Root/ButtonsContainer/ContinueBtn
@onready var settings_btn:   Button = $UI/Root/ButtonsContainer/SettingsBtn
@onready var credits_btn:    Button = $UI/Root/ButtonsContainer/CreditsBtn
@onready var quit_btn:       Button = $UI/Root/ButtonsContainer/QuitBtn
@onready var title_label:    Label  = $UI/Root/TitleArea/TitleLabel
@onready var subtitle_label: Label  = $UI/Root/TitleArea/SubtitleLabel
@onready var version_label:  Label  = $UI/Root/VersionLabel

const LEVEL_01_PATH := "res://scenes/levels/verdantia_combat_outpost.tscn"
const VERDANTIA_STORY_PATH := "res://scenes/levels/verdantia_demo.tscn"

func _ready() -> void:
	continue_btn.disabled = not SaveManager.has_save_file()

	_connect_buttons()
	_animate_title()
	SceneTransition.fade_in(0.6)
	version_label.text = "v0.1.0 – Phase 1 Build"
	print("[MainMenu] Ready.")

func _connect_buttons() -> void:
	if new_game_btn:
		new_game_btn.pressed.connect(_on_new_game)
	if tps_demo_btn:
		tps_demo_btn.pressed.connect(_on_tps_demo)
	if continue_btn:
		continue_btn.pressed.connect(_on_continue)
	if settings_btn:
		settings_btn.pressed.connect(_on_settings)
	if credits_btn:
		credits_btn.pressed.connect(_on_credits)
	if quit_btn:
		quit_btn.pressed.connect(_on_quit)

func _on_tps_demo() -> void:
	AudioManager.play_sound("button_click")
	SceneTransition.fade_to_scene(LEVEL_01_PATH)

func _animate_title() -> void:
	title_label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 1.0)
	tween.parallel().tween_property(title_label, "position:y", title_label.position.y, 0.8).from(title_label.position.y - 30)
	tween.tween_property(subtitle_label, "modulate:a", 1.0, 0.6).from(0.0)

func _on_new_game() -> void:
	AudioManager.play_sound("button_click")
	SaveManager.delete_save()
	GameManager.player_health = GameManager.player_max_health
	SceneTransition.fade_to_scene(LEVEL_01_PATH)

func _on_continue() -> void:
	AudioManager.play_sound("button_click")
	if LevelManager:
		LevelManager.open_level_select()
	else:
		SceneTransition.fade_to_scene(LEVEL_01_PATH)

func _on_settings() -> void:
	AudioManager.play_sound("button_click")
	SceneTransition.fade_to_scene("res://scenes/menus/settings_menu.tscn")

func _on_credits() -> void:
	AudioManager.play_sound("button_click")
	SceneTransition.fade_to_scene("res://scenes/menus/credits_menu.tscn")

func _on_quit() -> void:
	AudioManager.play_sound("button_click")
	get_tree().quit()
