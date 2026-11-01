## HUD.gd
## In-game Heads-Up Display.
## Shows health hearts, weather inventory slots, and current objective.
extends CanvasLayer

@onready var health_container: HBoxContainer = $Root/TopLeft/VBox/HealthRow/HealthContainer
@onready var objective_label:  Label          = $Root/TopLeft/VBox/ObjectiveLabel
@onready var weather_bar:      HBoxContainer  = $Root/WeatherBarAnchor/WeatherBar
@onready var notify_label:     Label          = $Root/NotificationLabel

# Preloaded heart textures (procedural fallbacks used if missing)
var heart_full_color:  Color = Color(1.0, 0.2, 0.3)
var heart_empty_color: Color = Color(0.3, 0.3, 0.4, 0.5)

var _heart_nodes: Array[Control] = []
var _weather_slot_nodes: Array[Control] = []
var _notification_tween: Tween = null

func _ready() -> void:
	_connect_signals()
	_build_health_display()
	_build_weather_bar()
	set_objective("Find the magical Rain Bottle")
	print("[HUD] Ready.")

func _connect_signals() -> void:
	GameManager.health_changed.connect(_on_health_changed)
	WeatherManager.weather_unlocked.connect(_on_weather_unlocked)
	WeatherManager.weather_switched.connect(_on_weather_switched)
	WeatherManager.charges_changed.connect(_on_charges_changed)

# ─── Health Display ──────────────────────────────────────────────────────────
func _build_health_display() -> void:
	for child in health_container.get_children():
		child.queue_free()
	_heart_nodes.clear()

	for i in range(GameManager.player_max_health):
		var heart := _make_heart_icon()
		health_container.add_child(heart)
		_heart_nodes.append(heart)

func _make_heart_icon() -> Control:
	var c := ColorRect.new()
	c.custom_minimum_size = Vector2(28, 28)
	c.color = heart_full_color
	# Round the heart with a script-drawn circle later; placeholder rect for now
	return c

func _on_health_changed(current: int, maximum: int) -> void:
	# Rebuild if size changed
	if _heart_nodes.size() != maximum:
		_build_health_display()
	for i in range(_heart_nodes.size()):
		if i < current:
			_heart_nodes[i].color = heart_full_color
			_heart_nodes[i].modulate = Color.WHITE
		else:
			_heart_nodes[i].color = heart_empty_color

# ─── Weather Bar ─────────────────────────────────────────────────────────────
func _build_weather_bar() -> void:
	for child in weather_bar.get_children():
		child.queue_free()
	_weather_slot_nodes.clear()

	for wtype in WeatherManager.WEATHER_ORDER:
		var slot := _make_weather_slot(wtype)
		weather_bar.add_child(slot)
		_weather_slot_nodes.append(slot)
		slot.visible = wtype in WeatherManager.unlocked_weathers

func _make_weather_slot(wtype: String) -> Control:
	var container := VBoxContainer.new()
	container.custom_minimum_size = Vector2(64, 80)
	container.name = "Slot_" + wtype

	# Icon circle
	var icon_bg := ColorRect.new()
	icon_bg.custom_minimum_size = Vector2(52, 52)
	icon_bg.color = WeatherManager.WEATHER_COLORS[wtype]
	icon_bg.name = "IconBG"
	container.add_child(icon_bg)

	# Label
	var lbl := Label.new()
	lbl.text = wtype.capitalize()
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_color_override("font_color", Color.WHITE)
	lbl.add_theme_font_size_override("font_size", 11)
	lbl.name = "TypeLabel"
	container.add_child(lbl)

	# Charge dots row
	var dots_row := HBoxContainer.new()
	dots_row.alignment = BoxContainer.ALIGNMENT_CENTER
	dots_row.name = "DotsRow"
	container.add_child(dots_row)

	for _i in range(WeatherManager.MAX_CHARGES[wtype]):
		var dot := ColorRect.new()
		dot.custom_minimum_size = Vector2(7, 7)
		dot.color = Color.WHITE
		dots_row.add_child(dot)

	return container

func _on_weather_unlocked(weather_type: String) -> void:
	for slot in _weather_slot_nodes:
		if slot.name == "Slot_" + weather_type:
			slot.visible = true
	show_notification("✦ " + weather_type.capitalize() + " Power Unlocked!", WeatherManager.WEATHER_COLORS[weather_type])

func _on_weather_switched(weather_type: String) -> void:
	for slot in _weather_slot_nodes:
		var icon_bg := slot.get_node_or_null("IconBG")
		if icon_bg == null:
			continue
		if slot.name == "Slot_" + weather_type:
			icon_bg.color = WeatherManager.WEATHER_COLORS[weather_type]
			var tween := create_tween()
			tween.tween_property(slot, "scale", Vector2(1.15, 1.15), 0.1)
			tween.tween_property(slot, "scale", Vector2(1.0, 1.0), 0.1)
		else:
			var base_color: Color = WeatherManager.WEATHER_COLORS.get(
				slot.name.replace("Slot_", ""), Color.GRAY)
			base_color.a = 0.4
			icon_bg.color = base_color

func _on_charges_changed(weather_type: String, current: int, _maximum: int) -> void:
	for slot in _weather_slot_nodes:
		if slot.name == "Slot_" + weather_type:
			var dots_row := slot.get_node_or_null("DotsRow")
			if dots_row == null:
				return
			var dots := dots_row.get_children()
			for i in range(dots.size()):
				var dot: ColorRect = dots[i]
				if i < current:
					dot.color = Color.WHITE
				else:
					dot.color = Color(0.2, 0.2, 0.3, 0.5)

# ─── Objective ───────────────────────────────────────────────────────────────
func set_objective(text: String) -> void:
	objective_label.text = "▶  " + text

# ─── Notifications ───────────────────────────────────────────────────────────
func show_notification(text: String, color: Color = Color.WHITE, duration: float = 2.5) -> void:
	if notify_label == null:
		return
	notify_label.text = text
	notify_label.add_theme_color_override("font_color", color)
	notify_label.modulate.a = 1.0
	notify_label.visible = true

	if _notification_tween and _notification_tween.is_valid():
		_notification_tween.kill()
	_notification_tween = create_tween()
	_notification_tween.tween_interval(duration)
	_notification_tween.tween_property(notify_label, "modulate:a", 0.0, 0.5)
