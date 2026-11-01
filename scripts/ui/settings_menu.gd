## SettingsMenu.gd
## Settings screen with audio sliders and display options.
extends Node2D

@onready var music_slider:     HSlider     = $UI/Root/Panel/VBox/MusicRow/MusicSlider
@onready var sfx_slider:       HSlider     = $UI/Root/Panel/VBox/SFXRow/SFXSlider
@onready var fullscreen_check: CheckButton = $UI/Root/Panel/VBox/FullscreenRow/FullscreenCheck
@onready var back_btn:         Button      = $UI/Root/Panel/VBox/BackBtn

func _ready() -> void:
	music_slider.value = AudioManager.music_volume
	sfx_slider.value   = AudioManager.sfx_volume
	fullscreen_check.button_pressed = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN

	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	back_btn.pressed.connect(_on_back)

	SceneTransition.fade_in(0.4)

func _on_music_changed(value: float) -> void:
	AudioManager.set_music_volume(value)
	SaveManager.save_data["settings"]["music_volume"] = value

func _on_sfx_changed(value: float) -> void:
	AudioManager.set_sfx_volume(value)
	SaveManager.save_data["settings"]["sfx_volume"] = value

func _on_fullscreen_toggled(pressed: bool) -> void:
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	SaveManager.save_data["settings"]["fullscreen"] = pressed

func _on_back() -> void:
	AudioManager.play_sound("button_click")
	SaveManager.save_game()
	SceneTransition.fade_to_scene("res://scenes/menus/main_menu.tscn")
