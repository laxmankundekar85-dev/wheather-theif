## PauseMenu.gd
## Pause overlay — activated via GameManager pause signal.
extends CanvasLayer

@onready var panel:         Control = $Root/Panel
@onready var resume_btn:    Button  = $Root/Panel/VBox/ResumeBtn
@onready var restart_btn:   Button  = $Root/Panel/VBox/RestartBtn
@onready var journal_btn:   Button  = $Root/Panel/VBox/JournalBtn
@onready var settings_btn:  Button  = $Root/Panel/VBox/SettingsBtn
@onready var main_menu_btn: Button  = $Root/Panel/VBox/MainMenuBtn

func _ready() -> void:
	visible = false
	if has_node("Root"):
		$Root.visible = false
	layer = 20
	GameManager.game_paused.connect(_on_game_paused)
	resume_btn.pressed.connect(_on_resume)
	restart_btn.pressed.connect(_on_restart)
	if journal_btn:
		journal_btn.pressed.connect(_on_journal)
	settings_btn.pressed.connect(_on_settings)
	main_menu_btn.pressed.connect(_on_main_menu)

func _on_game_paused(is_paused: bool) -> void:
	visible = is_paused
	if has_node("Root"):
		$Root.visible = is_paused
	if is_paused:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_animate_in()
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _animate_in() -> void:
	panel.modulate.a = 1.0
	panel.scale = Vector2.ONE
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.15).from(Vector2(0.9, 0.9))

func _on_resume() -> void:
	AudioManager.play_sound("button_click")
	GameManager.toggle_pause()

func _on_journal() -> void:
	AudioManager.play_sound("button_click")
	if MissionManager:
		print("[Journal] Active Mission: ", MissionManager.current_mission_id)
		for obj in MissionManager.objectives:
			print(" - [%s] %s" % ["COMPLETED" if obj["completed"] else "ACTIVE", obj["desc"]])

func _on_restart() -> void:
	AudioManager.play_sound("button_click")
	GameManager.toggle_pause()
	GameManager.set_player_health(GameManager.player_max_health)
	GameManager.respawn_player()

func _on_settings() -> void:
	AudioManager.play_sound("button_click")
	pass

func _on_main_menu() -> void:
	AudioManager.play_sound("button_click")
	GameManager.toggle_pause()
	if LevelManager:
		LevelManager.open_level_select()
	else:
		SceneTransition.fade_to_scene("res://scenes/menus/main_menu.tscn")
