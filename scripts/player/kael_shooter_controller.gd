## KaelShooterController.gd
## Comprehensive Third-Person Shooter RPG Protagonist Controller for Kael.
## Integrates over-the-shoulder dynamic camera, ADS zoom, tactical recoil recovery,
## 8-way strafing locomotion, sprinting, crouching, combat slide, procedural weapon rig,
## and weather elemental abilities.
extends CharacterBody3D
class_name KaelShooterController

# Movement Tuning
@export_group("Locomotion")
@export var walk_speed: float = 4.2
@export var run_speed: float = 7.8
@export var sprint_speed: float = 12.8
@export var crouch_speed: float = 3.2
@export var slide_speed: float = 15.0
@export var jump_force: float = 13.5
@export var gravity: float = 32.0
@export var rotation_speed: float = 18.0

# Camera Tuning
@export_group("Camera & Aiming")
@export var mouse_sensitivity: float = 0.12
@export var normal_fov: float = 72.0
@export var ads_fov: float = 48.0
@export var normal_spring_length: float = 2.6
@export var ads_spring_length: float = 1.45
@export var scope_spring_length: float = 0.60
@export var normal_cam_offset: Vector3 = Vector3(0.40, 0.22, 0.0)
@export var ads_cam_offset: Vector3 = Vector3(0.56, 0.26, 0.0)
@export var scope_cam_offset: Vector3 = Vector3(0.22, 0.18, 0.0)

# Camera State Machine
enum CameraMode {
	THIRD_PERSON,
	AIMING,
	SCOPING
}

var camera_mode: CameraMode = CameraMode.THIRD_PERSON

# Stamina & Energy
@export_group("Attributes")
@export var max_health: int = 100
@export var current_health: int = 100
@export var max_shield: int = 50
@export var current_shield: int = 50
@export var max_stamina: float = 100.0
@export var current_stamina: float = 100.0
@export var max_ultimate_energy: float = 100.0
@export var current_ultimate_energy: float = 50.0

# References
@onready var visual_root: Node3D = $VisualRoot
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var weapon_socket: Node3D = $VisualRoot/WeaponSocket
@onready var weapon_manager: Node = $VisualRoot/WeaponSocket/WeaponManager
@onready var interaction_area: Area3D = $InteractionArea

# State
var is_aiming: bool = false
var is_sprinting: bool = false
var is_crouching: bool = false
var is_sliding: bool = false
var slide_timer: float = 0.0
var is_invulnerable: bool = false
var camera_pitch: float = -10.0
var camera_yaw: float = 0.0

# Recoil Accumulators
var recoil_pitch_offset: float = 0.0
var recoil_yaw_offset: float = 0.0
var recoil_recovery_speed: float = 12.0

# Weather Cooldowns
var weather_skill_cd: float = 0.0
var weather_skill_max_cd: float = 6.0

# Skeleton & Bone IDs
var skeleton: Skeleton3D = null
var b_hips: int = -1
var b_spine: int = -1
var b_chest: int = -1
var b_neck: int = -1
var b_head: int = -1
var b_r_upper_arm: int = -1
var b_r_lower_arm: int = -1
var b_r_hand: int = -1
var b_l_upper_arm: int = -1
var b_l_lower_arm: int = -1
var b_l_hand: int = -1
var b_r_upper_leg: int = -1
var b_r_lower_leg: int = -1
var b_r_foot: int = -1
var b_l_upper_leg: int = -1
var b_l_lower_leg: int = -1
var b_l_foot: int = -1

var gait_cycle: float = 0.0
var shoot_recoil_anim: float = 0.0
var reload_anim_progress: float = 0.0
var anim_time: float = 0.0
var is_mobile_firing: bool = false
var mobile_move_vector: Vector2 = Vector2.ZERO
var is_scope_toggled: bool = false

# Safe Ground & Respawn System
var spawn_point: Vector3 = Vector3.ZERO
var last_safe_ground_pos: Vector3 = Vector3.ZERO
var is_recovering_from_fall: bool = false
var fall_kill_y_threshold: float = -10.0

signal health_changed(current: int, maximum: int)
signal shield_changed(current: int, maximum: int)
signal stamina_changed(current: float, maximum: float)
signal ultimate_changed(current: float, maximum: float)
signal camera_mode_changed(mode_index: int)

func _ready() -> void:
	add_to_group("player")
	GameManager.player_ref = self
	spawn_point = global_position
	last_safe_ground_pos = global_position
	GameManager.last_checkpoint_position = global_position

	# Guarantee full combat attributes at mission initialization
	current_health = max_health
	current_shield = max_shield
	current_stamina = max_stamina
	is_recovering_from_fall = false

	# 3.0 second spawn grace period to protect against instant enemy ambushes during briefings
	is_invulnerable = true
	get_tree().create_timer(3.0).timeout.connect(func(): is_invulnerable = false)

	# Capture mouse for AAA shooter feel on desktop
	if not (OS.has_feature("android") or OS.has_feature("ios")):
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	camera_yaw = rotation.y
	_apply_camera_rotation()

	# Prevent near-plane camera slicing through player head/shoulders
	if camera:
		camera.near = 0.02

	_init_skeleton()
	_apply_character_textures()

	# Ensure all meshes have extra cull margin to prevent invisible body parts
	if visual_root:
		for c in visual_root.find_children("*", "MeshInstance3D", true, false):
			var mi := c as MeshInstance3D
			if mi:
				mi.extra_cull_margin = 4.0
				mi.ignore_occlusion_culling = true

	# Connect weapon recoil, damage, and weapon switching
	if weapon_manager:
		weapon_manager.weapon_fired.connect(_on_weapon_fired)
		weapon_manager.hit_registered.connect(_on_hit_registered)
		if weapon_manager.has_signal("active_weapon_changed"):
			weapon_manager.active_weapon_changed.connect(_on_active_weapon_changed)

	emit_signal("health_changed", current_health, max_health)
	emit_signal("shield_changed", current_shield, max_shield)
	emit_signal("stamina_changed", current_stamina, max_stamina)
	emit_signal("ultimate_changed", current_ultimate_energy, max_ultimate_energy)
	emit_signal("camera_mode_changed", int(camera_mode))

func _on_active_weapon_changed(_w: Node) -> void:
	if camera_mode == CameraMode.SCOPING:
		if not can_weapon_scope():
			set_camera_mode(CameraMode.AIMING)
		else:
			# Refresh visibility for 8x sniper
			set_camera_mode(CameraMode.SCOPING)

func can_weapon_scope() -> bool:
	if weapon_manager and weapon_manager.active_weapon:
		var w = weapon_manager.active_weapon
		# Check scope_type: 4 (SNIPER_8X), 3 (ACOG_4X), 2 (HOLO_2X)
		if "scope_type" in w and int(w.scope_type) >= 2:
			return true
	return false

func set_camera_mode(new_mode: CameraMode) -> void:
	if new_mode == CameraMode.SCOPING and not can_weapon_scope():
		new_mode = CameraMode.AIMING
	if camera_mode == new_mode:
		return
	camera_mode = new_mode
	is_aiming = (camera_mode == CameraMode.AIMING or camera_mode == CameraMode.SCOPING)
	is_scope_toggled = (camera_mode == CameraMode.SCOPING)

	if weapon_manager:
		weapon_manager.set_aiming(is_aiming)

	# When scoping with 8x sniper, hide character mesh so the optic view is unobstructed
	if visual_root:
		if camera_mode == CameraMode.SCOPING and weapon_manager and weapon_manager.active_weapon:
			var w = weapon_manager.active_weapon
			if "scope_type" in w and int(w.scope_type) == 4:
				visual_root.visible = false
			else:
				visual_root.visible = true
		else:
			visual_root.visible = true

	emit_signal("camera_mode_changed", int(camera_mode))

func toggle_aim() -> void:
	if camera_mode == CameraMode.THIRD_PERSON:
		set_camera_mode(CameraMode.AIMING)
	else:
		set_camera_mode(CameraMode.THIRD_PERSON)

func toggle_scope() -> void:
	if not can_weapon_scope():
		AudioManager.play_sound("dry_fire")
		return
	if camera_mode == CameraMode.SCOPING:
		set_camera_mode(CameraMode.AIMING)
	else:
		set_camera_mode(CameraMode.SCOPING)

func reset_camera() -> void:
	set_camera_mode(CameraMode.THIRD_PERSON)
	camera_pitch = -10.0
	recoil_pitch_offset = 0.0
	recoil_yaw_offset = 0.0
	_apply_camera_rotation()

func _input(event: InputEvent) -> void:
	# Mouse look with optical magnification sensitivity scaling
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var fov_scale: float = clampf(camera.fov / normal_fov, 0.22, 1.0)
		var sens := mouse_sensitivity * fov_scale
		camera_yaw -= event.relative.x * sens
		camera_pitch = clamp(camera_pitch - event.relative.y * sens, -75.0, 75.0)
		_apply_camera_rotation()

	# Desktop Mouse RMB for AIM
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT:
			if event.pressed:
				set_camera_mode(CameraMode.AIMING)
			else:
				if camera_mode == CameraMode.AIMING:
					set_camera_mode(CameraMode.THIRD_PERSON)
		elif event.button_index == MOUSE_BUTTON_MIDDLE and event.pressed:
			toggle_scope()

	# Desktop Key V for Scope Toggle
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_V:
			toggle_scope()

	# Toggle mouse lock with Escape
	if event.is_action_pressed("pause_game"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _apply_camera_rotation() -> void:
	if camera_pivot:
		camera_pivot.rotation_degrees.y = camera_yaw + recoil_yaw_offset
		camera_pivot.rotation_degrees.x = camera_pitch + recoil_pitch_offset

func _physics_process(delta: float) -> void:
	anim_time += delta

	# Tick Cooldowns
	if weather_skill_cd > 0.0:
		weather_skill_cd = max(0.0, weather_skill_cd - delta)

	# Recoil Recovery
	recoil_pitch_offset = move_toward(recoil_pitch_offset, 0.0, recoil_recovery_speed * delta)
	recoil_yaw_offset = move_toward(recoil_yaw_offset, 0.0, recoil_recovery_speed * delta)
	_apply_camera_rotation()

	# Maintain weapon aiming state
	is_aiming = (camera_mode == CameraMode.AIMING or camera_mode == CameraMode.SCOPING)
	if weapon_manager:
		weapon_manager.set_aiming(is_aiming)

	_update_camera_mode(delta)

	# Handle Crouch / Slide
	_handle_stance_and_stamina(delta)

	# Locomotion
	_handle_movement(delta)

	# Safe Ground Tracking & Out-of-Bounds Abyss Check
	if is_on_floor() and global_position.y >= -3.5:
		last_safe_ground_pos = global_position
		GameManager.last_checkpoint_position = global_position

	if global_position.y < fall_kill_y_threshold:
		_handle_fall_recovery()

	# Shooting & Weapon actions
	_handle_weapons(delta)

	# Weather Magic Actions
	_handle_weather_abilities()

	# Procedural skeletal animation
	_update_procedural_animations(delta)

func _update_camera_mode(delta: float) -> void:
	var target_fov: float = normal_fov
	var target_length: float = normal_spring_length
	var target_offset: Vector3 = normal_cam_offset

	match camera_mode:
		CameraMode.THIRD_PERSON:
			target_fov = normal_fov
			target_length = normal_spring_length
			target_offset = normal_cam_offset

		CameraMode.AIMING:
			target_fov = ads_fov
			if weapon_manager and weapon_manager.active_weapon and "scope_zoom_fov" in weapon_manager.active_weapon:
				var w_fov: float = float(weapon_manager.active_weapon.scope_zoom_fov)
				if w_fov > 35.0:
					target_fov = w_fov
			target_length = ads_spring_length
			target_offset = ads_cam_offset

		CameraMode.SCOPING:
			if weapon_manager and weapon_manager.active_weapon and "scope_zoom_fov" in weapon_manager.active_weapon:
				target_fov = float(weapon_manager.active_weapon.scope_zoom_fov)
			else:
				target_fov = 18.0
			target_length = scope_spring_length
			target_offset = scope_cam_offset

	camera.fov = lerp(camera.fov, target_fov, delta * 14.0)
	spring_arm.spring_length = lerp(spring_arm.spring_length, target_length, delta * 12.0)
	camera.position = camera.position.lerp(target_offset, delta * 12.0)

func _handle_stance_and_stamina(delta: float) -> void:
	var sprint_pressed := Input.is_action_pressed("sprint") or Input.is_action_pressed("dash")
	var crouch_pressed := Input.is_action_pressed("crouch")

	# Sliding
	if is_sliding:
		slide_timer -= delta
		if slide_timer <= 0.0 or not is_on_floor():
			is_sliding = false
			is_crouching = crouch_pressed
	elif sprint_pressed and crouch_pressed and current_stamina >= 20.0 and is_on_floor() and velocity.length() > 5.0:
		# Trigger Slide
		is_sliding = true
		slide_timer = 0.65
		current_stamina -= 20.0
		AudioManager.play_sound("dash")
		var slide_dir := -visual_root.global_transform.basis.z
		velocity.x = slide_dir.x * slide_speed
		velocity.z = slide_dir.z * slide_speed
	elif crouch_pressed:
		is_crouching = true
		is_sprinting = false
	else:
		is_crouching = false

	# Adjust collision shape for stance
	if collision_shape and collision_shape.shape is CapsuleShape3D:
		var cap := collision_shape.shape as CapsuleShape3D
		var target_height := 1.1 if (is_crouching or is_sliding) else 1.8
		cap.height = lerp(cap.height, target_height, delta * 14.0)
		collision_shape.position.y = cap.height * 0.5

	# Stamina Regeneration
	if not is_sprinting and not is_sliding and current_stamina < max_stamina:
		current_stamina = min(max_stamina, current_stamina + 25.0 * delta)
		emit_signal("stamina_changed", current_stamina, max_stamina)

func _handle_movement(delta: float) -> void:
	if is_sliding:
		# Slide deceleration
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return

	var input_dir := Vector2.ZERO
	if mobile_move_vector.length_squared() > 0.01:
		input_dir = mobile_move_vector
	else:
		input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		input_dir.y = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
	if input_dir.length() > 1.0:
		input_dir = input_dir.normalized()

	var cam_forward := -camera.global_transform.basis.z
	cam_forward.y = 0.0
	cam_forward = cam_forward.normalized()

	var cam_right := camera.global_transform.basis.x
	cam_right.y = 0.0
	cam_right = cam_right.normalized()

	var move_dir := (cam_right * input_dir.x + cam_forward * -input_dir.y).normalized()
	var has_input := input_dir.length_squared() > 0.01

	if weapon_manager:
		weapon_manager.set_moving(has_input)

	# Speed Calculation
	var target_speed := walk_speed
	if is_crouching:
		target_speed = crouch_speed
	elif has_input and (Input.is_action_pressed("sprint") or Input.is_action_pressed("dash")) and not is_aiming and current_stamina > 2.0:
		target_speed = sprint_speed
		is_sprinting = true
		current_stamina = max(0.0, current_stamina - 28.0 * delta)
		emit_signal("stamina_changed", current_stamina, max_stamina)
	elif has_input:
		target_speed = run_speed
		is_sprinting = false
	else:
		is_sprinting = false

	if has_input:
		velocity.x = move_toward(velocity.x, move_dir.x * target_speed, 22.0 * delta * target_speed)
		velocity.z = move_toward(velocity.z, move_dir.z * target_speed, 22.0 * delta * target_speed)

		# When aiming or moving backwards, face aim direction; otherwise face movement direction
		if is_aiming:
			var aim_angle := atan2(-cam_forward.x, -cam_forward.z)
			visual_root.rotation.y = lerp_angle(visual_root.rotation.y, aim_angle, rotation_speed * delta)
		else:
			var target_angle := atan2(-move_dir.x, -move_dir.z)
			visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_angle, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta * run_speed)
		velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta * run_speed)
		if is_aiming:
			var aim_angle := atan2(-cam_forward.x, -cam_forward.z)
			visual_root.rotation.y = lerp_angle(visual_root.rotation.y, aim_angle, rotation_speed * delta)

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_sliding:
		velocity.y = jump_force
		AudioManager.play_sound("jump")

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	move_and_slide()

func _handle_weapons(_delta: float) -> void:
	if not weapon_manager:
		return

	# Fire weapon (Auto or Single)
	# On mobile touchscreens, shooting is triggered exclusively by the dedicated on-screen FIRE button.
	# This prevents camera swipes, look drags, and joystick touches from accidentally firing.
	var is_mobile := OS.has_feature("android") or OS.has_feature("ios") or DisplayServer.is_touchscreen_available()
	var should_fire := is_mobile_firing
	if not is_mobile:
		should_fire = should_fire or Input.is_action_pressed("shoot") or Input.is_action_pressed("attack")

	if should_fire:
		weapon_manager.shoot(camera, self)

	# Reload
	if Input.is_action_just_pressed("reload"):
		weapon_manager.reload()

	# Switching (1 to 5, mouse wheel, or mobile buttons)
	if Input.is_action_just_pressed("weapon_1") or Input.is_key_pressed(KEY_1):
		weapon_manager.equip_slot(0)
	elif Input.is_action_just_pressed("weapon_2") or Input.is_key_pressed(KEY_2):
		weapon_manager.equip_slot(1)
	elif Input.is_action_just_pressed("weapon_3") or Input.is_key_pressed(KEY_3):
		weapon_manager.equip_slot(2)
	elif Input.is_action_just_pressed("weapon_4") or Input.is_key_pressed(KEY_4):
		weapon_manager.equip_slot(3)
	elif Input.is_action_just_pressed("weapon_5") or Input.is_key_pressed(KEY_5):
		weapon_manager.equip_slot(4)
	elif Input.is_action_just_pressed("next_weapon"):
		weapon_manager.next_weapon()
	elif Input.is_action_just_pressed("prev_weapon"):
		weapon_manager.prev_weapon()

func _handle_weather_abilities() -> void:
	# 1. RAIN SURGE [Q] — Restoration & Hydro Infusion
	if Input.is_action_just_pressed("weather_ability") or Input.is_key_pressed(KEY_Q):
		if weather_skill_cd <= 0.0:
			weather_skill_cd = weather_skill_max_cd
			AudioManager.play_sound("weather_rain")
			current_health = mini(max_health, current_health + 35)
			current_shield = mini(max_shield, current_shield + 20)
			emit_signal("health_changed", current_health, max_health)
			emit_signal("shield_changed", current_shield, max_shield)
			if weapon_manager:
				weapon_manager.infuse_weather("rain", 10.0)
			EventBus3D.emit_signal("weather_activated", "rain", global_position)

	# 2. SNOW GLACIER [E] — Cryo Slow & Barrier Freeze
	elif Input.is_key_pressed(KEY_E):
		if weather_skill_cd <= 0.0:
			weather_skill_cd = weather_skill_max_cd
			AudioManager.play_sound("weather_snow")
			current_shield = mini(max_shield, current_shield + 35)
			emit_signal("shield_changed", current_shield, max_shield)
			if weapon_manager:
				weapon_manager.infuse_weather("snow", 10.0)
			EventBus3D.emit_signal("weather_activated", "snow", global_position)
			_apply_area_element("snow", 14.0, 30, true)

	# 3. WIND GUST [F] — Kinetic Push & Speed Boost
	elif Input.is_key_pressed(KEY_F):
		if weather_skill_cd <= 0.0:
			weather_skill_cd = weather_skill_max_cd
			AudioManager.play_sound("weather_wind")
			var boost_dir := -visual_root.global_transform.basis.z
			velocity.x = boost_dir.x * 16.0
			velocity.z = boost_dir.z * 16.0
			current_stamina = max_stamina
			emit_signal("stamina_changed", current_stamina, max_stamina)
			if weapon_manager:
				weapon_manager.infuse_weather("wind", 10.0)
			EventBus3D.emit_signal("weather_activated", "wind", global_position)
			_apply_area_element("wind", 12.0, 25, false)

	# 4. SUN RADIANCE [C] — Concentrated Solar Beam
	elif Input.is_key_pressed(KEY_C):
		if weather_skill_cd <= 0.0:
			weather_skill_cd = weather_skill_max_cd
			AudioManager.play_sound("weather_sun")
			if weapon_manager:
				weapon_manager.infuse_weather("sun", 10.0)
			EventBus3D.emit_signal("weather_activated", "sun", global_position)
			_apply_area_element("sun", 16.0, 60, false)

	# 5. STORM BURST ULTIMATE [G]
	if Input.is_action_just_pressed("ultimate_ability") or Input.is_key_pressed(KEY_G):
		if current_ultimate_energy >= max_ultimate_energy:
			current_ultimate_energy = 0.0
			emit_signal("ultimate_changed", current_ultimate_energy, max_ultimate_energy)
			_trigger_storm_ultimate()

func _apply_area_element(element: String, radius: float, damage: int, freeze_effect: bool) -> void:
	var space_state := get_world_3d().direct_space_state
	var sphere := SphereShape3D.new()
	sphere.radius = radius
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(Basis(), global_position)
	query.collision_mask = 4 # Enemies

	var hits := space_state.intersect_shape(query, 16)
	for hit in hits:
		var node: Node = hit["collider"] as Node
		while node and not node.has_method("take_damage") and node.get_parent():
			node = node.get_parent()
		if node and node.has_method("take_damage"):
			node.take_damage(damage, global_position, false)
			if freeze_effect and "velocity" in node:
				node.velocity *= 0.35

func _trigger_storm_ultimate() -> void:
	AudioManager.play_sound("weather_burst")
	# Refill active weapon magazine
	if weapon_manager and weapon_manager.active_weapon:
		weapon_manager.active_weapon.current_ammo = weapon_manager.active_weapon.mag_capacity
		weapon_manager.infuse_weather("thunder", 12.0)

	# Shock area enemies
	var space_state := get_world_3d().direct_space_state
	var sphere := SphereShape3D.new()
	sphere.radius = 18.0
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = Transform3D(Basis(), global_position)
	query.collision_mask = 4 # Enemies layer

	var hits := space_state.intersect_shape(query, 16)
	for hit in hits:
		var node: Node = hit["collider"] as Node
		while node and not node.has_method("take_damage") and node.get_parent():
			node = node.get_parent()
		if node and node.has_method("take_damage"):
			node.take_damage(65, "thunder", true)
			CombatManager.spawn_damage_number(node.global_position + Vector3(0, 1.5, 0), 65, "thunder", true)

func _on_weapon_fired(v_recoil: float, h_recoil: float) -> void:
	# Trigger skeletal arms recoil kick
	shoot_recoil_anim = 1.0

	# Apply camera kick
	recoil_pitch_offset = min(6.0, recoil_pitch_offset + v_recoil)
	recoil_yaw_offset += h_recoil

	# Gain slight ultimate charge per shot fired
	current_ultimate_energy = min(max_ultimate_energy, current_ultimate_energy + 1.2)
	emit_signal("ultimate_changed", current_ultimate_energy, max_ultimate_energy)

func _on_hit_registered(_is_headshot: bool, _dmg: int) -> void:
	current_ultimate_energy = min(max_ultimate_energy, current_ultimate_energy + 4.5)
	emit_signal("ultimate_changed", current_ultimate_energy, max_ultimate_energy)

func take_damage(amount: int, _element_or_origin: Variant = "physical", _is_crit: bool = false) -> void:
	if is_invulnerable:
		return

	# Absorb with shield first
	if current_shield > 0:
		var absorbed: int = min(current_shield, amount)
		current_shield -= absorbed
		amount -= absorbed
		emit_signal("shield_changed", current_shield, max_shield)
		AudioManager.play_sound("damage")

	if amount > 0:
		current_health = max(0, current_health - amount)
		emit_signal("health_changed", current_health, max_health)
		AudioManager.play_sound("hit")

	if current_health <= 0:
		_die()

func _handle_fall_recovery() -> void:
	if is_recovering_from_fall:
		return
	is_recovering_from_fall = true

	AudioManager.play_sound("damage")
	velocity = Vector3.ZERO

	# Deduct fall damage
	current_health = max(1, current_health - 25)
	emit_signal("health_changed", current_health, max_health)

	# Reposition to last safe ground position
	var dest := spawn_point
	if last_safe_ground_pos != Vector3.ZERO:
		dest = last_safe_ground_pos

	global_position = dest + Vector3(0, 0.8, 0)
	reset_camera()

	# Reposition Lyra companion if present and give guidance
	var lyra := get_tree().get_first_node_in_group("companion")
	if not lyra:
		lyra = get_parent().get_node_or_null("LyraCompanion")
	if lyra and "global_position" in lyra:
		lyra.global_position = global_position + Vector3(1.6, 0.8, 1.2)
		if lyra.has_method("show_temporary_speech"):
			lyra.show_temporary_speech("Watch your step, Kael! The wind current caught your fall!", 3.5)

	# Brief invulnerability window (2.0s)
	is_invulnerable = true
	await get_tree().create_timer(2.0).timeout
	is_invulnerable = false
	is_recovering_from_fall = false

func respawn(target_pos: Variant = null) -> void:
	is_recovering_from_fall = false
	velocity = Vector3.ZERO
	current_health = max_health
	current_shield = max_shield
	current_stamina = max_stamina
	emit_signal("health_changed", current_health, max_health)
	emit_signal("shield_changed", current_shield, max_shield)
	emit_signal("stamina_changed", current_stamina, max_stamina)

	var dest := spawn_point
	if target_pos is Vector3:
		dest = target_pos
	elif last_safe_ground_pos != Vector3.ZERO:
		dest = last_safe_ground_pos

	global_position = dest + Vector3(0, 0.8, 0)
	reset_camera()

	# Refill magazine for active weapon so player is ready
	if weapon_manager and weapon_manager.active_weapon:
		weapon_manager.active_weapon.current_ammo = weapon_manager.active_weapon.mag_capacity
		weapon_manager.active_weapon.emit_signal("ammo_updated", weapon_manager.active_weapon.current_ammo, weapon_manager.active_weapon.reserve_ammo, weapon_manager.active_weapon.mag_capacity)

	# Reposition Lyra
	var lyra := get_tree().get_first_node_in_group("companion")
	if not lyra:
		lyra = get_parent().get_node_or_null("LyraCompanion")
	if lyra and "global_position" in lyra:
		lyra.global_position = global_position + Vector3(1.6, 0.8, 1.2)
		if lyra.has_method("show_temporary_speech"):
			lyra.show_temporary_speech("Stand fast, Kael! The skies are with us!", 3.0)

	# Brief invulnerability so player isn't immediately ambushed
	is_invulnerable = true
	await get_tree().create_timer(2.5).timeout
	is_invulnerable = false

func _die() -> void:
	reset_camera()
	AudioManager.play_sound("enemy_defeat")
	GameManager.emit_signal("player_died")

	# If no death screen pauses the tree, perform clean checkpoint respawn after brief delay
	await get_tree().create_timer(0.8).timeout
	if is_instance_valid(self):
		respawn(GameManager.last_checkpoint_position)

func _init_skeleton() -> void:
	if visual_root:
		skeleton = visual_root.find_child("Skeleton3D", true, false)
	if skeleton:
		b_hips = skeleton.find_bone("J_Bip_C_Hips")
		b_spine = skeleton.find_bone("J_Bip_C_Spine")
		b_chest = skeleton.find_bone("J_Bip_C_Chest")
		b_neck = skeleton.find_bone("J_Bip_C_Neck")
		b_head = skeleton.find_bone("J_Bip_C_Head")
		b_r_upper_arm = skeleton.find_bone("J_Bip_R_UpperArm")
		b_r_lower_arm = skeleton.find_bone("J_Bip_R_LowerArm")
		b_r_hand = skeleton.find_bone("J_Bip_R_Hand")
		b_l_upper_arm = skeleton.find_bone("J_Bip_L_UpperArm")
		b_l_lower_arm = skeleton.find_bone("J_Bip_L_LowerArm")
		b_l_hand = skeleton.find_bone("J_Bip_L_Hand")
		b_r_upper_leg = skeleton.find_bone("J_Bip_R_UpperLeg")
		b_r_lower_leg = skeleton.find_bone("J_Bip_R_LowerLeg")
		b_r_foot = skeleton.find_bone("J_Bip_R_Foot")
		b_l_upper_leg = skeleton.find_bone("J_Bip_L_UpperLeg")
		b_l_lower_leg = skeleton.find_bone("J_Bip_L_LowerLeg")
		b_l_foot = skeleton.find_bone("J_Bip_L_Foot")

func _apply_character_textures() -> void:
	var tops_tex := load("res://assets/characters/kael_avatar_b_F00_008_01_Tops_01.png") as Texture2D
	var bottoms_tex := load("res://assets/characters/kael_avatar_b_F00_001_01_Bottoms_01.png") as Texture2D
	var shoes_tex := load("res://assets/characters/kael_avatar_b_F00_006_01_Shoes_01.png") as Texture2D
	var body_tex := load("res://assets/characters/kael_avatar_b_F00_000_00_Body_00.png") as Texture2D
	var face_tex := load("res://assets/characters/kael_avatar_b_F00_000_00_Face_00.png") as Texture2D
	var iris_tex := load("res://assets/characters/kael_avatar_b_F00_000_00_EyeIris_00.png") as Texture2D
	var hair_tex := load("res://assets/characters/kael_avatar_b_F00_000_Hair_00_01.png") as Texture2D

	if not visual_root:
		return

	for c in visual_root.find_children("*", "MeshInstance3D", true, false):
		var mi := c as MeshInstance3D
		if not mi or not mi.mesh:
			continue
		for s in range(mi.mesh.get_surface_count()):
			var mat = mi.get_active_material(s)
			if mat and mat is StandardMaterial3D:
				var m := mat.duplicate() as StandardMaterial3D
				var mat_name: String = m.resource_name
				if "Tops" in mat_name and tops_tex:
					m.albedo_texture = tops_tex
					m.albedo_color = Color(0.48, 0.35, 0.24, 1.0) # Warm combat leather jacket (Ref 1)
					m.roughness = 0.65
				elif "Bottoms" in mat_name and bottoms_tex:
					m.albedo_texture = bottoms_tex
					m.albedo_color = Color(0.25, 0.28, 0.32, 1.0) # Dark tactical combat trousers
					m.roughness = 0.75
				elif "Shoes" in mat_name and shoes_tex:
					m.albedo_texture = shoes_tex
					m.albedo_color = Color(0.12, 0.12, 0.14, 1.0) # Dark leather combat boots
					m.roughness = 0.5
				elif "Body" in mat_name and body_tex:
					m.albedo_texture = body_tex
					m.albedo_color = Color(0.96, 0.90, 0.85, 1.0)
					m.roughness = 0.75
				elif "Face" in mat_name and face_tex:
					m.albedo_texture = face_tex
					m.albedo_color = Color(0.98, 0.92, 0.88, 1.0)
					m.roughness = 0.75
				elif "EyeIris" in mat_name and iris_tex:
					m.albedo_texture = iris_tex
					m.albedo_color = Color(0.2, 0.7, 1.0, 1.0) # Celestial sky-blue eyes
					m.roughness = 0.15
				elif "Hair" in mat_name and hair_tex:
					m.albedo_texture = hair_tex
					m.albedo_color = Color(0.18, 0.18, 0.22, 1.0) # Dark styled anime hair (Ref 1)
					m.roughness = 0.65
				mi.set_surface_override_material(s, m)

func _update_procedural_animations(delta: float) -> void:
	if not skeleton:
		return

	# Recoil Decay
	shoot_recoil_anim = move_toward(shoot_recoil_anim, 0.0, delta * 8.0)

	var horiz_vel := Vector2(velocity.x, velocity.z)
	var speed := horiz_vel.length()
	var on_ground := is_on_floor()

	# Gait accumulator
	if on_ground and speed > 0.4:
		var cadence := 1.7
		if is_sprinting:
			cadence = 2.4
		elif is_crouching:
			cadence = 1.2
		gait_cycle += delta * speed * cadence
	else:
		gait_cycle = move_toward(gait_cycle, 0.0, delta * 6.0)

	# 1. SPINE & CHEST (Breathing & Lean)
	if b_spine != -1:
		var spine_lean := 0.0
		var spine_twist := 0.0
		if not on_ground:
			spine_lean = deg_to_rad(8.0)
		elif is_sliding:
			spine_lean = deg_to_rad(-20.0) # lean back during slide
		elif is_crouching:
			spine_lean = deg_to_rad(24.0)
		elif speed > 0.5:
			spine_lean = deg_to_rad(14.0 if is_sprinting else 7.0)
			spine_twist = sin(gait_cycle) * deg_to_rad(4.0)
		else:
			# Idle breathing
			spine_lean = sin(anim_time * 2.2) * deg_to_rad(1.8)

		var q_spine := Quaternion.from_euler(Vector3(spine_lean, spine_twist, 0.0))
		skeleton.set_bone_pose_rotation(b_spine, q_spine)

	if b_chest != -1:
		var chest_pitch := sin(anim_time * 2.2) * deg_to_rad(2.0)
		if is_aiming:
			chest_pitch += deg_to_rad(-camera_pitch * 0.4)
		var q_chest := Quaternion.from_euler(Vector3(chest_pitch - shoot_recoil_anim * 0.1, 0.0, 0.0))
		skeleton.set_bone_pose_rotation(b_chest, q_chest)

	# 2. HEAD (Look pitch & yaw tracking)
	if b_head != -1:
		var head_pitch := deg_to_rad(-camera_pitch * 0.6)
		var q_head := Quaternion.from_euler(Vector3(head_pitch, 0.0, 0.0))
		skeleton.set_bone_pose_rotation(b_head, q_head)

	# 3. LEGS & FEET LOCOMOTION
	if on_ground:
		if is_sliding:
			# Slide: Right leg forward, left knee tucked under
			if b_r_upper_leg != -1:
				skeleton.set_bone_pose_rotation(b_r_upper_leg, Quaternion.from_euler(Vector3(deg_to_rad(-70.0), 0, deg_to_rad(8.0))))
			if b_r_lower_leg != -1:
				skeleton.set_bone_pose_rotation(b_r_lower_leg, Quaternion.from_euler(Vector3(deg_to_rad(25.0), 0, 0)))
			if b_l_upper_leg != -1:
				skeleton.set_bone_pose_rotation(b_l_upper_leg, Quaternion.from_euler(Vector3(deg_to_rad(20.0), 0, deg_to_rad(-18.0))))
			if b_l_lower_leg != -1:
				skeleton.set_bone_pose_rotation(b_l_lower_leg, Quaternion.from_euler(Vector3(deg_to_rad(105.0), 0, 0)))
		elif is_crouching:
			# Crouch: bent knees, lowered stance
			var leg_out := deg_to_rad(10.0)
			if b_l_upper_leg != -1:
				skeleton.set_bone_pose_rotation(b_l_upper_leg, Quaternion.from_euler(Vector3(deg_to_rad(-45.0), 0, -leg_out)))
			if b_l_lower_leg != -1:
				skeleton.set_bone_pose_rotation(b_l_lower_leg, Quaternion.from_euler(Vector3(deg_to_rad(75.0), 0, 0)))
			if b_r_upper_leg != -1:
				skeleton.set_bone_pose_rotation(b_r_upper_leg, Quaternion.from_euler(Vector3(deg_to_rad(-45.0), 0, leg_out)))
			if b_r_lower_leg != -1:
				skeleton.set_bone_pose_rotation(b_r_lower_leg, Quaternion.from_euler(Vector3(deg_to_rad(75.0), 0, 0)))
		elif speed > 0.4:
			# Walk / Run gait cycle
			var stride_amp := deg_to_rad(28.0) if is_sprinting else (deg_to_rad(22.0) if speed > 5.0 else deg_to_rad(15.0))
			var knee_amp := deg_to_rad(65.0) if is_sprinting else (deg_to_rad(45.0) if speed > 5.0 else deg_to_rad(30.0))

			var l_swing := sin(gait_cycle) * stride_amp
			var r_swing := -sin(gait_cycle) * stride_amp

			# Knees only bend backward (positive X in VRoid coordinates)
			var l_knee := maxf(0.0, -sin(gait_cycle)) * knee_amp
			var r_knee := maxf(0.0, sin(gait_cycle)) * knee_amp

			if b_l_upper_leg != -1:
				skeleton.set_bone_pose_rotation(b_l_upper_leg, Quaternion.from_euler(Vector3(l_swing, 0, deg_to_rad(-3.0))))
			if b_l_lower_leg != -1:
				skeleton.set_bone_pose_rotation(b_l_lower_leg, Quaternion.from_euler(Vector3(l_knee, 0, 0)))
			if b_r_upper_leg != -1:
				skeleton.set_bone_pose_rotation(b_r_upper_leg, Quaternion.from_euler(Vector3(r_swing, 0, deg_to_rad(3.0))))
			if b_r_lower_leg != -1:
				skeleton.set_bone_pose_rotation(b_r_lower_leg, Quaternion.from_euler(Vector3(r_knee, 0, 0)))
		else:
			# Idle stance: legs straight, natural slight outward stance
			var idle_sway := sin(anim_time * 1.5) * deg_to_rad(0.8)
			if b_l_upper_leg != -1:
				skeleton.set_bone_pose_rotation(b_l_upper_leg, Quaternion.from_euler(Vector3(idle_sway, 0, deg_to_rad(-4.0))))
			if b_l_lower_leg != -1:
				skeleton.set_bone_pose_rotation(b_l_lower_leg, Quaternion.from_euler(Vector3(deg_to_rad(2.0), 0, 0)))
			if b_r_upper_leg != -1:
				skeleton.set_bone_pose_rotation(b_r_upper_leg, Quaternion.from_euler(Vector3(-idle_sway, 0, deg_to_rad(4.0))))
			if b_r_lower_leg != -1:
				skeleton.set_bone_pose_rotation(b_r_lower_leg, Quaternion.from_euler(Vector3(deg_to_rad(2.0), 0, 0)))
	else:
		# In air (Jump / Fall)
		var tuck := deg_to_rad(-25.0) if velocity.y > 0 else deg_to_rad(-10.0)
		var knee_tuck := deg_to_rad(40.0) if velocity.y > 0 else deg_to_rad(20.0)
		if b_l_upper_leg != -1:
			skeleton.set_bone_pose_rotation(b_l_upper_leg, Quaternion.from_euler(Vector3(tuck, 0, deg_to_rad(-5.0))))
		if b_l_lower_leg != -1:
			skeleton.set_bone_pose_rotation(b_l_lower_leg, Quaternion.from_euler(Vector3(knee_tuck, 0, 0)))
		if b_r_upper_leg != -1:
			skeleton.set_bone_pose_rotation(b_r_upper_leg, Quaternion.from_euler(Vector3(tuck, 0, deg_to_rad(5.0))))
		if b_r_lower_leg != -1:
			skeleton.set_bone_pose_rotation(b_r_lower_leg, Quaternion.from_euler(Vector3(knee_tuck, 0, 0)))

	# 4. ARMS & WEAPON HOLDING (NEVER T-POSE!)
	if is_aiming:
		# Aim Down Sights (ADS) Pose: Rifle brought up to eye level
		var aim_pitch := deg_to_rad(-camera_pitch * 0.8)
		var recoil_offset := shoot_recoil_anim * 0.12

		# Right Upper Arm (Holds pistol grip and stock against shoulder)
		if b_r_upper_arm != -1:
			var q_r := Quaternion.from_euler(Vector3(deg_to_rad(-78.0) + aim_pitch + recoil_offset, deg_to_rad(-18.0), deg_to_rad(-18.0)))
			skeleton.set_bone_pose_rotation(b_r_upper_arm, q_r)
		if b_r_lower_arm != -1:
			var q_rf := Quaternion.from_euler(Vector3(deg_to_rad(10.0), deg_to_rad(-25.0), deg_to_rad(-35.0)))
			skeleton.set_bone_pose_rotation(b_r_lower_arm, q_rf)
		if b_r_hand != -1:
			var q_rh := Quaternion.from_euler(Vector3(deg_to_rad(15.0), deg_to_rad(-10.0), deg_to_rad(10.0)))
			skeleton.set_bone_pose_rotation(b_r_hand, q_rh)

		# Left Upper Arm (Supports handguard under barrel)
		if b_l_upper_arm != -1:
			var q_l := Quaternion.from_euler(Vector3(deg_to_rad(-65.0) + aim_pitch * 0.75, deg_to_rad(35.0), deg_to_rad(30.0)))
			skeleton.set_bone_pose_rotation(b_l_upper_arm, q_l)
		if b_l_lower_arm != -1:
			var q_lf := Quaternion.from_euler(Vector3(deg_to_rad(25.0), deg_to_rad(55.0), deg_to_rad(35.0)))
			skeleton.set_bone_pose_rotation(b_l_lower_arm, q_lf)
		if b_l_hand != -1:
			var q_lh := Quaternion.from_euler(Vector3(deg_to_rad(10.0), deg_to_rad(20.0), deg_to_rad(-15.0)))
			skeleton.set_bone_pose_rotation(b_l_hand, q_lh)
	else:
		# Ready / Hip Fire Pose: Arms resting naturally down, holding assault rifle across chest
		var idle_breathe := sin(anim_time * 2.2) * deg_to_rad(1.2)
		var recoil_offset := shoot_recoil_anim * 0.08

		# Right Arm (Holding rifle grip down near hip)
		if b_r_upper_arm != -1:
			var q_r := Quaternion.from_euler(Vector3(deg_to_rad(-30.0) + recoil_offset, deg_to_rad(-15.0), deg_to_rad(-65.0) - idle_breathe))
			skeleton.set_bone_pose_rotation(b_r_upper_arm, q_r)
		if b_r_lower_arm != -1:
			var q_rf := Quaternion.from_euler(Vector3(deg_to_rad(15.0), deg_to_rad(-25.0), deg_to_rad(-35.0)))
			skeleton.set_bone_pose_rotation(b_r_lower_arm, q_rf)
		if b_r_hand != -1:
			var q_rh := Quaternion.from_euler(Vector3(deg_to_rad(10.0), deg_to_rad(-5.0), deg_to_rad(5.0)))
			skeleton.set_bone_pose_rotation(b_r_hand, q_rh)

		# Left Arm (Cradling rifle handguard across lower torso)
		if b_l_upper_arm != -1:
			var q_l := Quaternion.from_euler(Vector3(deg_to_rad(-25.0), deg_to_rad(25.0), deg_to_rad(60.0) + idle_breathe))
			skeleton.set_bone_pose_rotation(b_l_upper_arm, q_l)
		if b_l_lower_arm != -1:
			var q_lf := Quaternion.from_euler(Vector3(deg_to_rad(20.0), deg_to_rad(35.0), deg_to_rad(45.0)))
			skeleton.set_bone_pose_rotation(b_l_lower_arm, q_lf)
		if b_l_hand != -1:
			var q_lh := Quaternion.from_euler(Vector3(deg_to_rad(5.0), deg_to_rad(15.0), deg_to_rad(-10.0)))
			skeleton.set_bone_pose_rotation(b_l_hand, q_lh)

	# 5. WEAPON SOCKET POSITIONING & DYNAMIC BOBBING (Anchored to right hand palm)
	if weapon_socket:
		var target_weapon_pos: Vector3
		if b_r_hand != -1:
			var hand_pose := skeleton.get_bone_global_pose(b_r_hand)
			var hand_origin := hand_pose.origin
			var grip_offset := Vector3(-0.02, 0.04, 0.02) if is_aiming else Vector3(-0.02, 0.02, 0.04)
			target_weapon_pos = hand_origin + grip_offset
		else:
			target_weapon_pos = Vector3(0.18, 1.32, -0.32) if is_aiming else Vector3(0.24, 0.95, -0.22)

		var target_weapon_rot := Vector3(deg_to_rad(-camera_pitch * 0.8), deg_to_rad(4.0), 0) if is_aiming else Vector3(deg_to_rad(8.0), deg_to_rad(-8.0), deg_to_rad(-6.0))

		# Add dynamic locomotion weapon bobbing & sway (like AAA shooters)
		if on_ground and speed > 0.4:
			var bob_amp := 0.012 if is_aiming else 0.028
			var bob_x := sin(gait_cycle) * bob_amp
			var bob_y := -absf(cos(gait_cycle)) * bob_amp * 1.2
			target_weapon_pos.x += bob_x
			target_weapon_pos.y += bob_y
			target_weapon_rot.z += sin(gait_cycle) * deg_to_rad(3.5)
		else:
			# Gentle idle weapon breathing sway
			target_weapon_pos.y += sin(anim_time * 2.2) * 0.006

		# Weapon recoil kickback along -Z
		target_weapon_pos.z += shoot_recoil_anim * 0.06
		target_weapon_rot.x += shoot_recoil_anim * deg_to_rad(6.0)

		weapon_socket.position = weapon_socket.position.lerp(target_weapon_pos, delta * 24.0)
		weapon_socket.rotation = weapon_socket.rotation.lerp(target_weapon_rot, delta * 24.0)
	if b_head != -1:
		var rest_head := skeleton.get_bone_rest(b_head)
		var h_rot := Basis(Vector3(1, 0, 0), deg_to_rad(-camera_pitch * 0.5))
		skeleton.set_bone_pose_rotation(b_head, rest_head.basis.get_rotation_quaternion() * Quaternion(h_rot))
