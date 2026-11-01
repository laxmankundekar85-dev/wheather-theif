## MobileTacticalHUD.gd
## AAA Mobile Touch Controls, In-Game Layout Customizer, and Genuine Gyroscope Aiming.
## Enhancements:
## 1. Direct 360-degree analog locomotion via player.mobile_move_vector.
## 2. Aim Drag While Firing: Holding the FIRE button allows dragging to track enemies and control recoil.
## 3. Reliable Scope ADS toggle with is_scope_toggled.
## 4. Full in-game HUD editor with MOVE directional buttons (⬅️ ⬆️ ⬇️ ➡️), scale (+/-), and hide/remove options.
## 5. Layout persistence in user://mobile_hud_layout.json.
extends CanvasLayer
class_name MobileTacticalHUD

enum GyroMode {
	OFF,
	SCOPE_ONLY,
	ALWAYS_ON
}

@export var gyro_mode: GyroMode = GyroMode.SCOPE_ONLY
@export var gyro_sensitivity: float = 2.4
@export var gyro_invert_x: bool = false
@export var gyro_invert_y: bool = false

# Per-Scope Sensitivities
@export var gyro_sens_hip: float = 2.0
@export var gyro_sens_reddot: float = 1.8
@export var gyro_sens_4x: float = 1.2
@export var gyro_sens_8x: float = 0.8

var is_gyro_supported: bool = false
var has_hardware_gyro: bool = false

# Player & Camera References
var player: CharacterBody3D = null

# Virtual Joystick State
var joystick_active: bool = false
var joystick_touch_idx: int = -1
var joystick_center: Vector2 = Vector2(170, 550)
var joystick_radius: float = 85.0
var joystick_vector: Vector2 = Vector2.ZERO
var default_joystick_pos: Vector2 = Vector2(75, 475)

# Touch Aim Drag State (Right Screen Half)
var aim_touch_idx: int = -1
var last_aim_pos: Vector2 = Vector2.ZERO
var touch_aim_sensitivity: float = 0.38

# Aim Drag While Firing State
var fire_touch_idx: int = -1
var last_fire_touch_pos: Vector2 = Vector2.ZERO

# Button Nodes
@onready var btn_fire: Button = $ButtonsContainer/BtnFire
@onready var btn_fire_left: Button = $ButtonsContainer/BtnFireLeft
@onready var btn_aim: Button = $ButtonsContainer/BtnAim
@onready var btn_scope: Button = $ButtonsContainer/BtnScope
@onready var btn_reload: Button = $ButtonsContainer/BtnReload
@onready var btn_jump: Button = $ButtonsContainer/BtnJump
@onready var btn_crouch: Button = $ButtonsContainer/BtnCrouch
@onready var btn_sprint: Button = $ButtonsContainer/BtnSprint
@onready var weapon_controls: Control = $ButtonsContainer/WeaponControls
@onready var btn_weapon_prev: Button = $ButtonsContainer/WeaponControls/BtnPrev
@onready var btn_weapon_next: Button = $ButtonsContainer/WeaponControls/BtnNext
@onready var weather_controls: Control = $ButtonsContainer/WeatherControls
@onready var btn_weather_rain: Button = $ButtonsContainer/WeatherControls/BtnRain
@onready var btn_weather_snow: Button = $ButtonsContainer/WeatherControls/BtnSnow
@onready var btn_weather_wind: Button = $ButtonsContainer/WeatherControls/BtnWind
@onready var btn_weather_sun: Button = $ButtonsContainer/WeatherControls/BtnSun
@onready var btn_ultimate: Button = $ButtonsContainer/WeatherControls/BtnUlt

# Joystick Visuals
@onready var joystick_base: Control = $ButtonsContainer/JoystickBase
@onready var joystick_thumb: Control = $ButtonsContainer/JoystickBase/Thumb
@onready var gyro_status_label: Label = $TopBar/GyroStatusLabel
@onready var btn_open_customize: Button = $TopBar/BtnCustomize

# Customization Editor UI
@onready var editor_panel: Panel = $EditorPanel
@onready var editor_label_selected: Label = $EditorPanel/HBox/LabelSelected
@onready var editor_btn_move_left: Button = $EditorPanel/HBox/BtnMoveLeft
@onready var editor_btn_move_up: Button = $EditorPanel/HBox/BtnMoveUp
@onready var editor_btn_move_down: Button = $EditorPanel/HBox/BtnMoveDown
@onready var editor_btn_move_right: Button = $EditorPanel/HBox/BtnMoveRight
@onready var editor_btn_scale_down: Button = $EditorPanel/HBox/BtnScaleDown
@onready var editor_label_scale: Label = $EditorPanel/HBox/LabelScale
@onready var editor_btn_scale_up: Button = $EditorPanel/HBox/BtnScaleUp
@onready var editor_btn_hide: Button = $EditorPanel/HBox/BtnHide
@onready var editor_btn_show_all: Button = $EditorPanel/HBox/BtnShowAll
@onready var editor_btn_reset: Button = $EditorPanel/HBox/BtnReset
@onready var editor_btn_save: Button = $EditorPanel/HBox/BtnSave

var is_customizing_layout: bool = false
var is_firing_held: bool = false
var selected_custom_control: Control = null
var is_dragging_custom_control: bool = false
var drag_touch_offset: Vector2 = Vector2.ZERO

var customizable_controls: Array[Control] = []
var default_transforms: Dictionary = {}

const LAYOUT_SAVE_FILE := "user://mobile_hud_layout.json"

func _ready() -> void:
	_check_hardware_gyroscope()

	var is_mobile_os := OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("mobile")
	var is_touch_dev := DisplayServer.is_touchscreen_available() and not (OS.has_feature("windows") or OS.has_feature("macos") or OS.has_feature("linux"))
	var show_touch := is_mobile_os or is_touch_dev
	visible = show_touch

	_collect_customizable_controls()
	_store_default_transforms()
	_load_custom_layout()

	_setup_touch_buttons()
	_setup_editor_ui()

func _collect_customizable_controls() -> void:
	customizable_controls = [
		btn_fire,
		btn_fire_left,
		btn_aim,
		btn_scope,
		btn_reload,
		btn_jump,
		btn_crouch,
		btn_sprint,
		weapon_controls,
		weather_controls,
		joystick_base
	]

func _store_default_transforms() -> void:
	if joystick_base:
		default_joystick_pos = joystick_base.position
	for c in customizable_controls:
		if c:
			default_transforms[c.name] = {
				"pos": c.position,
				"scale": c.scale,
				"visible": c.visible
			}

func _check_hardware_gyroscope() -> void:
	var is_mobile_os := OS.has_feature("android") or OS.has_feature("ios")
	var sample_gyro := Input.get_gyroscope()

	if is_mobile_os or sample_gyro.length_squared() > 0.0001:
		has_hardware_gyro = true
		is_gyro_supported = true
		if gyro_status_label:
			gyro_status_label.text = "Gyro: Hardware Active (%s)" % ["Scope Only" if gyro_mode == GyroMode.SCOPE_ONLY else "Always On"]
			gyro_status_label.modulate = Color(0.2, 0.9, 0.3)
	else:
		has_hardware_gyro = false
		is_gyro_supported = false
		if gyro_status_label:
			gyro_status_label.text = "Gyro: Not Available (Desktop PC)"
			gyro_status_label.modulate = Color(0.7, 0.7, 0.7, 0.6)

func _setup_touch_buttons() -> void:
	# Primary Right Fire with Aim Drag While Firing
	if btn_fire:
		btn_fire.gui_input.connect(_on_fire_gui_input)

	# Secondary Left Fire
	if btn_fire_left:
		btn_fire_left.button_down.connect(func(): _set_firing(true))
		btn_fire_left.button_up.connect(func(): _set_firing(false))

	if btn_aim:
		btn_aim.pressed.connect(_on_aim_pressed)

	if btn_scope:
		btn_scope.pressed.connect(_on_scope_pressed)

	if btn_reload:
		btn_reload.pressed.connect(func():
			if not is_customizing_layout and player and "weapon_manager" in player and player.weapon_manager:
				player.weapon_manager.reload()
		)

	if btn_jump:
		btn_jump.pressed.connect(func():
			if not is_customizing_layout:
				Input.action_press("jump")
				await get_tree().create_timer(0.08).timeout
				Input.action_release("jump")
		)

	if btn_crouch:
		btn_crouch.pressed.connect(func():
			if not is_customizing_layout and player:
				player.is_crouching = not player.is_crouching
		)

	if btn_sprint:
		btn_sprint.pressed.connect(func():
			if not is_customizing_layout and player:
				player.is_sprinting = not player.is_sprinting
		)

	if btn_weapon_prev:
		btn_weapon_prev.pressed.connect(func():
			if not is_customizing_layout and player and "weapon_manager" in player and player.weapon_manager:
				player.weapon_manager.prev_weapon()
		)

	if btn_weapon_next:
		btn_weapon_next.pressed.connect(func():
			if not is_customizing_layout and player and "weapon_manager" in player and player.weapon_manager:
				player.weapon_manager.next_weapon()
		)

	if btn_weather_rain:
		btn_weather_rain.pressed.connect(func(): if not is_customizing_layout: _cast_weather("rain"))
	if btn_weather_snow:
		btn_weather_snow.pressed.connect(func(): if not is_customizing_layout: _cast_weather("snow"))
	if btn_weather_wind:
		btn_weather_wind.pressed.connect(func(): if not is_customizing_layout: _cast_weather("wind"))
	if btn_weather_sun:
		btn_weather_sun.pressed.connect(func(): if not is_customizing_layout: _cast_weather("sun"))
	if btn_ultimate:
		btn_ultimate.pressed.connect(func():
			if not is_customizing_layout and player and player.has_method("_trigger_storm_ultimate"):
				player._trigger_storm_ultimate()
		)

	if btn_open_customize:
		btn_open_customize.pressed.connect(toggle_customization_mode)

## Dedicated GUI input handler on Fire Button for seamless recoil control and enemy tracking
func _on_fire_gui_input(event: InputEvent) -> void:
	if is_customizing_layout:
		return
	if event is InputEventScreenTouch:
		if event.pressed:
			fire_touch_idx = event.index
			last_fire_touch_pos = event.position
			_set_firing(true)
		else:
			if event.index == fire_touch_idx:
				fire_touch_idx = -1
				_set_firing(false)
	elif event is InputEventScreenDrag:
		if event.index == fire_touch_idx:
			var drag_event: InputEventScreenDrag = event as InputEventScreenDrag
			var rel: Vector2 = drag_event.position - last_fire_touch_pos
			last_fire_touch_pos = drag_event.position
			_apply_touch_look(rel)

func _set_firing(active: bool) -> void:
	if is_customizing_layout:
		return
	is_firing_held = active
	if player and "is_mobile_firing" in player:
		player.is_mobile_firing = active

func _setup_editor_ui() -> void:
	if editor_panel:
		editor_panel.visible = false

	# Move Buttons (Dedicated Directional Controls)
	if editor_btn_move_left:
		editor_btn_move_left.pressed.connect(func(): _move_selected_control(Vector2(-25, 0)))
	if editor_btn_move_right:
		editor_btn_move_right.pressed.connect(func(): _move_selected_control(Vector2(25, 0)))
	if editor_btn_move_up:
		editor_btn_move_up.pressed.connect(func(): _move_selected_control(Vector2(0, -25)))
	if editor_btn_move_down:
		editor_btn_move_down.pressed.connect(func(): _move_selected_control(Vector2(0, 25)))

	# Resize and Visibility Buttons
	if editor_btn_scale_down:
		editor_btn_scale_down.pressed.connect(func(): _adjust_selected_scale(-0.1))
	if editor_btn_scale_up:
		editor_btn_scale_up.pressed.connect(func(): _adjust_selected_scale(0.1))
	if editor_btn_hide:
		editor_btn_hide.pressed.connect(_hide_selected_control)
	if editor_btn_show_all:
		editor_btn_show_all.pressed.connect(_restore_all_hidden_controls)
	if editor_btn_reset:
		editor_btn_reset.pressed.connect(_reset_to_default_layout)
	if editor_btn_save:
		editor_btn_save.pressed.connect(func():
			_save_custom_layout()
			toggle_customization_mode()
		)

func toggle_customization_mode() -> void:
	is_customizing_layout = not is_customizing_layout
	if editor_panel:
		editor_panel.visible = is_customizing_layout

	if btn_open_customize:
		btn_open_customize.text = "✖ CLOSE EDIT" if is_customizing_layout else "⚙️ CUSTOMIZE HUD"
		btn_open_customize.modulate = Color(1.0, 0.4, 0.4) if is_customizing_layout else Color(1, 1, 1)

	if is_customizing_layout:
		_select_control_for_edit(btn_fire)
		_set_firing(false)
		if player and "mobile_move_vector" in player:
			player.mobile_move_vector = Vector2.ZERO
	else:
		selected_custom_control = null
		if joystick_base:
			default_joystick_pos = joystick_base.position
		_update_editor_selection_label()

func _select_control_for_edit(c: Control) -> void:
	selected_custom_control = c
	_update_editor_selection_label()

func _update_editor_selection_label() -> void:
	if not editor_label_selected:
		return
	if selected_custom_control:
		var readable_name := selected_custom_control.name.replace("Btn", "").replace("Controls", " Bar")
		editor_label_selected.text = "Selected: %s" % readable_name
		var cur_scale: float = selected_custom_control.scale.x
		if editor_label_scale:
			editor_label_scale.text = "%d%%" % int(round(cur_scale * 100.0))
		if editor_btn_hide:
			editor_btn_hide.disabled = false
	else:
		editor_label_selected.text = "Tap button to select"
		if editor_btn_hide:
			editor_btn_hide.disabled = true

func _move_selected_control(delta_pos: Vector2) -> void:
	if not selected_custom_control:
		return
	selected_custom_control.position += delta_pos

func _adjust_selected_scale(amount: float) -> void:
	if not selected_custom_control:
		return
	var new_s := clampf(selected_custom_control.scale.x + amount, 0.6, 2.2)
	selected_custom_control.scale = Vector2(new_s, new_s)
	_update_editor_selection_label()

func _hide_selected_control() -> void:
	if not selected_custom_control:
		return
	selected_custom_control.visible = false
	_select_control_for_edit(null)

func _restore_all_hidden_controls() -> void:
	for c in customizable_controls:
		if c:
			c.visible = true
	_select_control_for_edit(btn_fire)

func _reset_to_default_layout() -> void:
	for c in customizable_controls:
		if c and c.name in default_transforms:
			var d: Dictionary = default_transforms[c.name]
			c.position = d["pos"]
			c.scale = d["scale"]
			c.visible = d["visible"]
	if joystick_base:
		default_joystick_pos = joystick_base.position
	_select_control_for_edit(btn_fire)

func _save_custom_layout() -> void:
	var data: Dictionary = {}
	for c in customizable_controls:
		if c:
			data[c.name] = {
				"x": c.position.x,
				"y": c.position.y,
				"scale": c.scale.x,
				"visible": c.visible
			}
	var f := FileAccess.open(LAYOUT_SAVE_FILE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "\t"))
		f.close()

func _load_custom_layout() -> void:
	if not FileAccess.file_exists(LAYOUT_SAVE_FILE):
		return
	var f := FileAccess.open(LAYOUT_SAVE_FILE, FileAccess.READ)
	if not f:
		return
	var json_str := f.get_as_text()
	f.close()

	var parsed: Variant = JSON.parse_string(json_str)
	if not (parsed is Dictionary):
		return

	var d: Dictionary = parsed as Dictionary
	for c in customizable_controls:
		if c and c.name in d:
			var entry: Dictionary = d[c.name]
			if "x" in entry and "y" in entry:
				c.position = Vector2(entry["x"], entry["y"])
			if "scale" in entry:
				var s: float = float(entry["scale"])
				c.scale = Vector2(s, s)
			if "visible" in entry:
				c.visible = bool(entry["visible"])
	if joystick_base:
		default_joystick_pos = joystick_base.position

func _process(delta: float) -> void:
	if player == null and GameManager.player_ref != null:
		player = GameManager.player_ref as CharacterBody3D

	if not visible or not player:
		return

	# Keep AIM and SCOPE button highlights in sync with player camera state
	var cam_mode: int = player.get("camera_mode") if "camera_mode" in player else 0
	var can_scope: bool = player.can_weapon_scope() if player.has_method("can_weapon_scope") else false

	if btn_aim:
		if cam_mode == 1: # AIMING
			btn_aim.modulate = Color(0.4, 0.95, 1.4)
			btn_aim.text = "🎯 AIM [ON]"
		elif cam_mode == 2: # SCOPING
			btn_aim.modulate = Color(0.8, 0.8, 0.8)
			btn_aim.text = "🎯 AIM"
		else:
			btn_aim.modulate = Color(1.0, 1.0, 1.0)
			btn_aim.text = "🎯 AIM"

	if btn_scope:
		if not can_scope:
			btn_scope.disabled = true
			btn_scope.modulate = Color(0.5, 0.5, 0.5, 0.45)
			btn_scope.text = "🚫 NO SCOPE"
		else:
			btn_scope.disabled = false
			if cam_mode == 2: # SCOPING
				btn_scope.modulate = Color(1.4, 1.25, 0.4)
				btn_scope.text = "🔭 SCOPE [ON]"
			else:
				btn_scope.modulate = Color(1.0, 1.0, 1.0)
				btn_scope.text = "🔭 SCOPE"

	# Handle Continuous Firing strictly while held
	if is_firing_held and not is_customizing_layout and player and "weapon_manager" in player and player.weapon_manager:
		if "camera" in player:
			player.weapon_manager.shoot(player.camera, player)

	# Process Genuine Hardware Gyroscope Aiming
	if has_hardware_gyro and gyro_mode != GyroMode.OFF and not is_customizing_layout:
		_process_gyroscope(delta)

func _process_gyroscope(delta: float) -> void:
	var can_gyro := true
	if gyro_mode == GyroMode.SCOPE_ONLY and player and not player.is_aiming:
		can_gyro = false

	if not can_gyro:
		return

	var gyro := Input.get_gyroscope()
	if gyro == Vector3.ZERO:
		return

	var current_sens := gyro_sens_hip
	if player and player.is_aiming and "weapon_manager" in player and player.weapon_manager and player.weapon_manager.active_weapon:
		var fov: float = player.weapon_manager.active_weapon.scope_zoom_fov
		if fov < 20.0:
			current_sens = gyro_sens_8x
		elif fov < 35.0:
			current_sens = gyro_sens_4x
		else:
			current_sens = gyro_sens_reddot

	var delta_yaw := gyro.y * current_sens * delta * 57.2958
	var delta_pitch := gyro.x * current_sens * delta * 57.2958

	if gyro_invert_x:
		delta_yaw = -delta_yaw
	if gyro_invert_y:
		delta_pitch = -delta_pitch

	if "camera_yaw" in player and "camera_pitch" in player:
		player.camera_yaw += delta_yaw
		player.camera_pitch = clampf(player.camera_pitch + delta_pitch, -75.0, 75.0)
		if player.has_method("_apply_camera_rotation"):
			player._apply_camera_rotation()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_WM_WINDOW_FOCUS_OUT:
		_release_joystick()
		_set_firing(false)
		aim_touch_idx = -1

func _is_pos_on_interactive_button(pos: Vector2) -> bool:
	var left_buttons: Array = [
		btn_fire_left,
		btn_sprint,
		btn_open_customize,
		btn_weather_rain,
		btn_weather_snow,
		btn_weather_wind,
		btn_weather_sun,
		btn_ultimate
	]
	for c in left_buttons:
		if c and c is Control and (c as Control).is_visible_in_tree():
			var rect := Rect2((c as Control).global_position, (c as Control).size * (c as Control).scale)
			if rect.has_point(pos):
				return true
	return false

func _is_pos_on_right_buttons(pos: Vector2) -> bool:
	var right_buttons: Array = [
		btn_fire,
		btn_aim,
		btn_scope,
		btn_reload,
		btn_jump,
		btn_crouch,
		btn_weapon_prev,
		btn_weapon_next
	]
	for c in right_buttons:
		if c and c is Control and (c as Control).is_visible_in_tree():
			var rect := Rect2((c as Control).global_position, (c as Control).size * (c as Control).scale)
			if rect.has_point(pos):
				return true
	return false

func _release_joystick() -> void:
	joystick_active = false
	joystick_touch_idx = -1
	joystick_vector = Vector2.ZERO
	_reset_joystick_visual()
	_apply_joystick_input(Vector2.ZERO)

func _input(event: InputEvent) -> void:
	if not visible:
		return

	var vp_size := get_viewport().get_visible_rect().size

	if is_customizing_layout:
		_handle_customizer_input(event)
		return

	# Multi-touch Screen Events during gameplay
	if event is InputEventScreenTouch:
		if not event.pressed:
			# Finger lifted anywhere
			if event.index == joystick_touch_idx:
				_release_joystick()
			elif event.index == aim_touch_idx:
				aim_touch_idx = -1
			elif event.index == fire_touch_idx:
				fire_touch_idx = -1
				_set_firing(false)
		else:
			# Finger touched down
			if event.position.x < vp_size.x * 0.45:
				if not _is_pos_on_interactive_button(event.position):
					if not joystick_active:
						joystick_active = true
						joystick_touch_idx = event.index
						var base_center: Vector2 = (joystick_base.global_position + (joystick_base.size * joystick_base.scale * 0.5)) if joystick_base else event.position
						if event.position.distance_to(base_center) < joystick_radius * 2.2:
							joystick_center = base_center
						else:
							joystick_center = event.position
							if joystick_base:
								joystick_base.global_position = joystick_center - (joystick_base.size * joystick_base.scale * 0.5)
						_update_joystick(event.position)
			else:
				if not _is_pos_on_right_buttons(event.position):
					if aim_touch_idx == -1:
						aim_touch_idx = event.index
						last_aim_pos = event.position

	elif event is InputEventScreenDrag:
		if event.index == joystick_touch_idx:
			_update_joystick(event.position)
		elif event.index == aim_touch_idx:
			var drag_event: InputEventScreenDrag = event as InputEventScreenDrag
			var rel: Vector2 = drag_event.position - last_aim_pos
			last_aim_pos = drag_event.position
			_apply_touch_look(rel)

	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if not event.pressed:
				if joystick_active and joystick_touch_idx == 999:
					_release_joystick()
				if aim_touch_idx == 999:
					aim_touch_idx = -1
				if fire_touch_idx == 999:
					fire_touch_idx = -1
					_set_firing(false)
			else:
				if event.position.x < vp_size.x * 0.45:
					if not _is_pos_on_interactive_button(event.position) and not joystick_active:
						joystick_active = true
						joystick_touch_idx = 999
						var base_center: Vector2 = (joystick_base.global_position + (joystick_base.size * joystick_base.scale * 0.5)) if joystick_base else event.position
						joystick_center = base_center
						_update_joystick(event.position)
				else:
					if not _is_pos_on_right_buttons(event.position) and aim_touch_idx == -1:
						aim_touch_idx = 999
						last_aim_pos = event.position

	elif event is InputEventMouseMotion:
		if joystick_active and joystick_touch_idx == 999:
			_update_joystick(event.position)
		elif aim_touch_idx == 999:
			var motion_event: InputEventMouseMotion = event as InputEventMouseMotion
			_apply_touch_look(motion_event.relative)

func _handle_customizer_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			for c in customizable_controls:
				if c and c.visible:
					var rect := Rect2(c.global_position, c.size * c.scale)
					if rect.has_point(event.position):
						_select_control_for_edit(c)
						is_dragging_custom_control = true
						drag_touch_offset = event.position - c.global_position
						return
		else:
			is_dragging_custom_control = false

	elif event is InputEventScreenDrag:
		if is_dragging_custom_control and selected_custom_control:
			selected_custom_control.global_position = event.position - drag_touch_offset

func _update_joystick(touch_pos: Vector2) -> void:
	var offset := touch_pos - joystick_center
	var dist := offset.length()
	var max_r := joystick_radius * (joystick_base.scale.x if joystick_base else 1.0)
	if dist > max_r:
		offset = offset.normalized() * max_r

	joystick_vector = offset / max_r
	if joystick_thumb and joystick_base:
		var thumb_size := joystick_thumb.size * joystick_thumb.scale
		joystick_thumb.position = ((joystick_base.size * 0.5) + (offset / joystick_base.scale.x)) - (thumb_size * 0.5)

	_apply_joystick_input(joystick_vector)

func _reset_joystick_visual() -> void:
	if joystick_base:
		joystick_base.position = default_joystick_pos
	if joystick_thumb and joystick_base:
		var thumb_size := joystick_thumb.size * joystick_thumb.scale
		joystick_thumb.position = (joystick_base.size * 0.5) - (thumb_size * 0.5)

func _apply_joystick_input(v: Vector2) -> void:
	# Direct 360-degree analog vector pass to controller
	if player and "mobile_move_vector" in player:
		player.mobile_move_vector = v

	# Fallback Godot input map events
	if absf(v.x) > 0.15:
		if v.x > 0.0:
			Input.action_press("move_right", v.x)
			Input.action_release("move_left")
		else:
			Input.action_press("move_left", -v.x)
			Input.action_release("move_right")
	else:
		Input.action_release("move_left")
		Input.action_release("move_right")

	if absf(v.y) > 0.15:
		if v.y > 0.0:
			Input.action_press("move_back", v.y)
			Input.action_release("move_forward")
		else:
			Input.action_press("move_forward", -v.y)
			Input.action_release("move_back")
	else:
		Input.action_release("move_forward")
		Input.action_release("move_back")

func _apply_touch_look(rel: Vector2) -> void:
	if not player:
		return
	var sens: float = touch_aim_sensitivity * (0.6 if player.is_aiming else 1.0)
	if "camera_yaw" in player and "camera_pitch" in player:
		player.camera_yaw -= rel.x * sens
		player.camera_pitch = clampf(player.camera_pitch - rel.y * sens, -75.0, 75.0)
		if player.has_method("_apply_camera_rotation"):
			player._apply_camera_rotation()

func _on_aim_pressed() -> void:
	if is_customizing_layout or not player:
		return
	if player.has_method("toggle_aim"):
		player.toggle_aim()

func _on_scope_pressed() -> void:
	if is_customizing_layout or not player:
		return
	if player.has_method("toggle_scope"):
		player.toggle_scope()

func _cast_weather(element: String) -> void:
	if is_customizing_layout or not player or not ("weather_skill_cd" in player):
		return
	if player.weather_skill_cd <= 0.0:
		player.weather_skill_cd = player.weather_skill_max_cd
		AudioManager.play_sound("weather_" + element)
		if "weapon_manager" in player and player.weapon_manager:
			player.weapon_manager.infuse_weather(element, 10.0)
		EventBus3D.emit_signal("weather_activated", element, player.global_position)
