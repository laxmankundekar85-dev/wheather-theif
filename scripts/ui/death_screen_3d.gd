## DeathScreen3D.gd
## Game Over / Respawn overlay triggered when Zephyr loses all health or falls with 0 HP.
extends CanvasLayer

@onready var root_ctrl: Control = $Root
@onready var panel: Control = $Root/Panel
@onready var respawn_btn: Button = $Root/Panel/VBox/RespawnBtn
@onready var main_menu_btn: Button = $Root/Panel/VBox/MainMenuBtn

func _ready() -> void:
	visible = false
	if root_ctrl:
		root_ctrl.visible = false
	layer = 30
	process_mode = Node.PROCESS_MODE_ALWAYS
	GameManager.player_died.connect(_on_player_died)
	if respawn_btn:
		respawn_btn.pressed.connect(_on_respawn)
	if main_menu_btn:
		main_menu_btn.pressed.connect(_on_main_menu)

func _on_player_died() -> void:
	visible = true
	if root_ctrl:
		root_ctrl.visible = true
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	panel.modulate.a = 1.0
	panel.scale = Vector2.ONE
	var tw := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.15).from(Vector2(0.9, 0.9))

func _on_respawn() -> void:
	AudioManager.play_sound("button_click")
	visible = false
	if root_ctrl:
		root_ctrl.visible = false
	get_tree().paused = false
	if not (OS.has_feature("android") or OS.has_feature("ios")):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameManager.set_player_health(GameManager.player_max_health)
	GameManager.respawn_player()

func _on_main_menu() -> void:
	AudioManager.play_sound("button_click")
	visible = false
	get_tree().paused = false
	SceneTransition.fade_to_scene("res://scenes/menus/main_menu.tscn")
