## HUD3D.gd
## In-game 3D HUD displaying player health, weather charges, and active story quest objective.
extends CanvasLayer

@onready var hearts_container: HBoxContainer = $Root/TopLeft/Hearts
@onready var quest_title: Label = $Root/TopLeft/QuestBox/Title
@onready var quest_desc: Label = $Root/TopLeft/QuestBox/Desc
@onready var weather_badge: PanelContainer = $Root/BottomCenter/WeatherBadge
@onready var weather_icon: Label = $Root/BottomCenter/WeatherBadge/HBox/Icon
@onready var weather_name: Label = $Root/BottomCenter/WeatherBadge/HBox/Name
@onready var charges_label: Label = $Root/BottomCenter/WeatherBadge/HBox/Charges
@onready var btn_pause: Button = $Root/TopRight/BtnPause

const WEATHER_ICONS: Dictionary = {
	"rain": "🌧️",
	"snow": "❄️",
	"wind": "🍃",
	"sun": "☀️",
}

func _ready() -> void:
	GameManager.health_changed.connect(_on_health_changed)
	WeatherManager.weather_switched.connect(_on_weather_switched)
	WeatherManager.charges_changed.connect(_on_charges_changed)
	WeatherManager.weather_unlocked.connect(_on_weather_unlocked)
	EventBus3D.quest_updated.connect(_on_quest_updated)

	if btn_pause:
		btn_pause.pressed.connect(GameManager.toggle_pause)

	_update_health_display(GameManager.player_health, GameManager.player_max_health)
	_update_weather_display()

func _on_quest_updated(title: String, desc: String) -> void:
	if quest_title:
		quest_title.text = "🎯 " + title
	if quest_desc:
		quest_desc.text = desc

func _on_health_changed(hp: int, max_hp: int) -> void:
	_update_health_display(hp, max_hp)

func _update_health_display(hp: int, max_hp: int) -> void:
	if not hearts_container:
		return
	for c in hearts_container.get_children():
		c.queue_free()

	for i in range(max_hp):
		var lbl := Label.new()
		lbl.text = "❤️" if i < hp else "🖤"
		lbl.add_theme_font_size_override("font_size", 26)
		hearts_container.add_child(lbl)

func _on_weather_switched(_w: String) -> void:
	_update_weather_display()

func _on_weather_unlocked(_w: String) -> void:
	_update_weather_display()

func _on_charges_changed(_w: String, _cur: int, _max: int) -> void:
	_update_weather_display()

func _update_weather_display() -> void:
	var cur_w := WeatherManager.current_weather
	if cur_w == "":
		if weather_badge:
			weather_badge.visible = false
		return

	if weather_badge:
		weather_badge.visible = true
	if weather_icon:
		weather_icon.text = WEATHER_ICONS.get(cur_w, "✨")
	if weather_name:
		weather_name.text = cur_w.capitalize()
	if charges_label:
		var c: int = WeatherManager.charges.get(cur_w, 0)
		var m: int = WeatherManager.MAX_CHARGES.get(cur_w, 5)
		charges_label.text = str(c) + " / " + str(m)
