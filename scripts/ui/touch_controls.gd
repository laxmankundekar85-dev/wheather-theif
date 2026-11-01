## TouchControls.gd
## On-screen virtual controls with true independent multi-touch tracking.
## Allows moving backward/forward while simultaneously jumping or casting weather.
extends CanvasLayer

@onready var btn_left: Button = $Root/LeftControls/BtnLeft
@onready var btn_right: Button = $Root/LeftControls/BtnRight
@onready var btn_jump: Button = $Root/RightControls/BtnJump
@onready var btn_weather: Button = $Root/RightControls/BtnWeather
@onready var btn_switch: Button = $Root/RightControls/BtnSwitch

var _buttons: Dictionary = {}
var _touch_map: Dictionary = {} # touch_index -> action_name

func _ready() -> void:
	# Show on mobile or touchscreens
	var is_mobile := OS.has_feature("android") or OS.has_feature("ios") or DisplayServer.is_touchscreen_available()
	visible = is_mobile

	_buttons = {
		"move_left": btn_left,
		"move_right": btn_right,
		"jump": btn_jump,
		"activate_weather": btn_weather,
		"switch_weather": btn_switch,
	}

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			var action := _get_action_at_position(event.position)
			if action != "":
				_touch_map[event.index] = action
				Input.action_press(action)
				_highlight_btn(action, true)
		else:
			if event.index in _touch_map:
				var action: String = _touch_map[event.index]
				_touch_map.erase(event.index)
				# Only release action if no other finger is pressing it
				if action not in _touch_map.values():
					Input.action_release(action)
				_highlight_btn(action, false)

	elif event is InputEventScreenDrag:
		if event.index in _touch_map:
			var old_action: String = _touch_map[event.index]
			var new_action := _get_action_at_position(event.position)
			if new_action != old_action:
				if new_action != "":
					_touch_map[event.index] = new_action
					Input.action_press(new_action)
					_highlight_btn(new_action, true)
				else:
					_touch_map.erase(event.index)

				if old_action not in _touch_map.values():
					Input.action_release(old_action)
				_highlight_btn(old_action, false)

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_index := -1
			if event.pressed:
				var action := _get_action_at_position(event.position)
				if action != "":
					_touch_map[mouse_index] = action
					Input.action_press(action)
					_highlight_btn(action, true)
			else:
				if mouse_index in _touch_map:
					var action: String = _touch_map[mouse_index]
					_touch_map.erase(mouse_index)
					if action not in _touch_map.values():
						Input.action_release(action)
					_highlight_btn(action, false)

func _get_action_at_position(screen_pos: Vector2) -> String:
	for action: String in _buttons:
		var btn: Button = _buttons[action]
		if btn and btn.is_visible_in_tree():
			var rect: Rect2 = btn.get_global_rect()
			# Expand touch boundary slightly (10px) for easier tapping
			rect = rect.grow(10.0)
			if rect.has_point(screen_pos):
				return action
	return ""

func _highlight_btn(action: String, is_pressed: bool) -> void:
	if action in _buttons:
		var btn: Button = _buttons[action]
		if btn:
			btn.modulate = Color(1.3, 1.3, 1.3, 1.0) if is_pressed else Color(1.0, 1.0, 1.0, 1.0)
