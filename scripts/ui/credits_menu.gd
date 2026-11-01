## CreditsMenu.gd
## Credits screen with scrolling text.
extends Node2D

@onready var back_btn:       Button       = $UI/Root/BackBtn
@onready var credits_scroll: RichTextLabel = $UI/Root/ScrollContainer/CreditsText

func _ready() -> void:
	SceneTransition.fade_in(0.4)
	back_btn.pressed.connect(_on_back)
	credits_scroll.text = _get_credits_text()

func _get_credits_text() -> String:
	return """[center][color=#40bfff][font_size=28]WEATHER THIEF[/font_size][/color]

[color=#aaddff]A magical 2D adventure game[/color]

[font_size=20]DEVELOPMENT TEAM[/font_size]

[color=#ffe066]Game Design & Development[/color]
[color=#ccddff]Weather Thief Team[/color]

[font_size=20]TECHNOLOGY[/font_size]

[color=#ffe066]Engine[/color]: Godot 4.x
[color=#ffe066]Language[/color]: GDScript
[color=#ffe066]Target Platforms[/color]: Windows PC, Android

[font_size=20]SPECIAL THANKS[/font_size]

[color=#aaffaa]Godot Engine Community[/color]
[color=#aaffaa]All explorers of the magical world[/color]

[font_size=16][color=#667799]Phase 1 Build — Forgotten Forest Prototype[/color][/font_size]

[color=#40bfff]✦ Restore the world's weather balance ✦[/color][/center]"""

func _on_back() -> void:
	AudioManager.play_sound("button_click")
	SceneTransition.fade_to_scene("res://scenes/menus/main_menu.tscn")
