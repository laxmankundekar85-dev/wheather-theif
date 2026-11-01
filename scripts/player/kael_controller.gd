## KaelController.gd
## Main protagonist controller for Kael in Weather Thief (Anime Action RPG).
## Features 8-way camera-relative movement, 3-hit attack combo, elemental skill (Rain Blade),
## elemental burst, sprint dash, stamina management, and procedural anime animations.
extends CharacterBody3D
class_name KaelController

# Movement Tuning
@export var walk_speed: float = 4.8
@export var run_speed: float = 8.5
@export var sprint_speed: float = 13.5
@export var jump_force: float = 14.0
@export var gravity: float = 32.0
@export var rotation_speed: float = 16.0

# Stamina System
var max_stamina: float = 100.0
var current_stamina: float = 100.0
var stamina_drain_rate: float = 28.0
var stamina_regen_rate: float = 22.0
var is_sprinting: bool = false

# Elemental Energy (Burst Gauge)
var elemental_energy: float = 40.0
var max_elemental_energy: float = 100.0
var skill_cooldown: float = 0.0
var skill_max_cooldown: float = 4.5

# Combat States
var is_attacking: bool = false
var attack_combo_step: int = 0
var attack_timer: float = 0.0
var is_invulnerable: bool = false
var is_dashing: bool = false

# References
@onready var visual_root: Node3D = $VisualRoot
@onready var back_sword: Node3D = $VisualRoot/BackSword
@onready var hand_sword: Node3D = $VisualRoot/HandSword
@onready var attack_area: Area3D = $VisualRoot/AttackArea
@onready var camera_pivot: Node3D = $CameraPivot
@onready var spring_arm: SpringArm3D = $CameraPivot/SpringArm3D
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var interaction_area: Area3D = $InteractionArea
@onready var water_slash_vfx: CPUParticles3D = $VisualRoot/WaterSlashVFX

# Mobile / Virtual Joystick vector
var touch_move_vector: Vector2 = Vector2.ZERO
var camera_rot_x: float = -14.0
var camera_rot_y: float = 0.0
var current_interactable: Node = null
var anim_time: float = 0.0

signal stamina_changed(current: float, maximum: float)
signal energy_changed(current: float, maximum: float)

# Skeleton & Bone IDs
var skeleton: Skeleton3D = null
var b_l_upper_arm: int = -1
var b_l_lower_arm: int = -1
var b_r_upper_arm: int = -1
var b_r_lower_arm: int = -1
var b_l_upper_leg: int = -1
var b_l_lower_leg: int = -1
var b_r_upper_leg: int = -1
var b_r_lower_leg: int = -1
var b_spine: int = -1
var b_head: int = -1

func _ready() -> void:
	GameManager.player_ref = self
	camera_rot_y = rotation.y
	_apply_camera_rotation()

	_init_skeleton()
	_apply_character_textures()

	if attack_area:
		attack_area.monitoring = false
	if water_slash_vfx:
		water_slash_vfx.emitting = false

	if interaction_area:
		interaction_area.area_entered.connect(_on_interaction_area_entered)
		interaction_area.area_exited.connect(_on_interaction_area_exited)

func _apply_character_textures() -> void:
	var hair_tex := load("res://assets/characters/kael_avatar_c_F00_000_Hair_00.png") as Texture2D
	var tops_tex := load("res://assets/characters/kael_avatar_c_M00_008_03_Tops_01.png") as Texture2D
	var iris_tex := load("res://assets/characters/kael_avatar_c_M00_000_00_EyeIris_00.png") as Texture2D

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
				if "Hair" in mat_name and hair_tex:
					m.albedo_texture = hair_tex
					m.albedo_color = Color(1.15, 1.15, 1.25, 1.0)
				elif "Tops" in mat_name and tops_tex:
					m.albedo_texture = tops_tex
				elif "EyeIris" in mat_name and iris_tex:
					m.albedo_texture = iris_tex
				mi.set_surface_override_material(s, m)

func _init_skeleton() -> void:
	if visual_root:
		skeleton = visual_root.find_child("Skeleton3D", true, false)
	if skeleton:
		b_l_upper_arm = skeleton.find_bone("J_Bip_L_UpperArm")
		b_l_lower_arm = skeleton.find_bone("J_Bip_L_LowerArm")
		b_r_upper_arm = skeleton.find_bone("J_Bip_R_UpperArm")
		b_r_lower_arm = skeleton.find_bone("J_Bip_R_LowerArm")
		b_l_upper_leg = skeleton.find_bone("J_Bip_L_UpperLeg")
		b_l_lower_leg = skeleton.find_bone("J_Bip_L_LowerLeg")
		b_r_upper_leg = skeleton.find_bone("J_Bip_R_UpperLeg")
		b_r_lower_leg = skeleton.find_bone("J_Bip_R_LowerLeg")
		b_spine = skeleton.find_bone("J_Bip_C_Spine")
		b_head = skeleton.find_bone("J_Bip_C_Head")

func rotate_camera(delta_yaw: float, delta_pitch: float) -> void:
	camera_rot_y += delta_yaw
	camera_rot_x = clamp(camera_rot_x + delta_pitch, -75.0, 45.0)
	_apply_camera_rotation()

func _apply_camera_rotation() -> void:
	if camera_pivot:
		camera_pivot.rotation_degrees.y = camera_rot_y
		camera_pivot.rotation_degrees.x = camera_rot_x

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		rotate_camera(-event.relative.x * 0.18, -event.relative.y * 0.14)

func _physics_process(delta: float) -> void:
	# Tick timers
	if skill_cooldown > 0.0:
		skill_cooldown = max(0.0, skill_cooldown - delta)

	if attack_timer > 0.0:
		attack_timer -= delta
		if attack_timer <= 0.0:
			is_attacking = false
			attack_combo_step = 0
			if attack_area:
				attack_area.monitoring = false
			if back_sword:
				back_sword.visible = true
			if hand_sword:
				hand_sword.visible = false

	# Falling out of bounds detection
	if global_position.y < -12.0:
		_on_fall_out_of_bounds()
		return

	# Handle Dash / Sprint
	if Input.is_action_just_pressed("dash") and current_stamina >= 18.0 and not is_dashing:
		_perform_dash()

	if Input.is_action_pressed("dash") and current_stamina > 0.0 and velocity.length() > 0.5:
		is_sprinting = true
		current_stamina = max(0.0, current_stamina - stamina_drain_rate * delta)
	else:
		is_sprinting = false
		current_stamina = min(max_stamina, current_stamina + stamina_regen_rate * delta)

	emit_signal("stamina_changed", current_stamina, max_stamina)

	# Read Input
	var input_dir := Vector2.ZERO
	if touch_move_vector.length_squared() > 0.001:
		input_dir = touch_move_vector
	else:
		input_dir.x = Input.get_action_strength("move_right") - Input.get_action_strength("move_left")
		input_dir.y = Input.get_action_strength("move_back") - Input.get_action_strength("move_forward")
		if input_dir.length() > 1.0:
			input_dir = input_dir.normalized()

	# Camera relative direction
	var cam_forward := -camera.global_transform.basis.z
	cam_forward.y = 0.0
	cam_forward = cam_forward.normalized()

	var cam_right := camera.global_transform.basis.x
	cam_right.y = 0.0
	cam_right = cam_right.normalized()

	var target_dir := (cam_right * input_dir.x + cam_forward * -input_dir.y).normalized()

	# Speed determination
	var target_speed := walk_speed
	if is_sprinting:
		target_speed = sprint_speed
	elif target_dir.length_squared() > 0.01:
		target_speed = run_speed

	# Don't slide while executing normal attack swing
	if is_attacking and is_on_floor():
		velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta * run_speed)
		velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta * run_speed)
	elif target_dir.length_squared() > 0.01:
		velocity.x = move_toward(velocity.x, target_dir.x * target_speed, 18.0 * delta * target_speed)
		velocity.z = move_toward(velocity.z, target_dir.z * target_speed, 18.0 * delta * target_speed)

		var target_angle := atan2(-target_dir.x, -target_dir.z)
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_angle, rotation_speed * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 14.0 * delta * run_speed)
		velocity.z = move_toward(velocity.z, 0.0, 14.0 * delta * run_speed)

	# Jump
	if Input.is_action_just_pressed("jump") and is_on_floor() and not is_attacking:
		velocity.y = jump_force
		AudioManager.play_sound("jump")

	# Gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	move_and_slide()

	# Combat Inputs
	if Input.is_action_just_pressed("attack") and not is_dashing:
		perform_attack()

	if Input.is_action_just_pressed("elemental_skill") or Input.is_action_just_pressed("activate_weather"):
		cast_elemental_skill()

	if Input.is_action_just_pressed("elemental_burst"):
		cast_elemental_burst()

	if Input.is_action_just_pressed("interact"):
		trigger_interaction()

	_update_procedural_animations(delta)

func _perform_dash() -> void:
	is_dashing = true
	is_invulnerable = true
	current_stamina -= 18.0
	AudioManager.play_sound("dash")

	# Forward impulse
	var dash_dir := -visual_root.global_transform.basis.z
	velocity.x = dash_dir.x * 20.0
	velocity.z = dash_dir.z * 20.0

	# Ghost flash
	var tw := create_tween()
	tw.tween_property(visual_root, "modulate:a", 0.35, 0.1)
	tw.tween_property(visual_root, "modulate:a", 1.0, 0.15)
	await tw.finished
	is_invulnerable = false
	is_dashing = false

func perform_attack() -> void:
	is_attacking = true
	attack_combo_step = (attack_combo_step % 3) + 1
	attack_timer = 0.42
	AudioManager.play_sound("sword_swing")

	if back_sword:
		back_sword.visible = false
	if hand_sword:
		hand_sword.visible = true
		var tw := create_tween()
		match attack_combo_step:
			1:
				hand_sword.rotation_degrees = Vector3(25, 45, -35)
				tw.tween_property(hand_sword, "rotation_degrees", Vector3(-35, -60, 45), 0.18)
			2:
				hand_sword.rotation_degrees = Vector3(-30, -55, 40)
				tw.tween_property(hand_sword, "rotation_degrees", Vector3(35, 70, -45), 0.18)
			3:
				hand_sword.rotation_degrees = Vector3(85, 0, 0)
				tw.tween_property(hand_sword, "rotation_degrees", Vector3(-65, 0, 0), 0.22)

	# Enable attack hitbox
	if attack_area:
		attack_area.monitoring = true
		_check_attack_hits(35 * attack_combo_step, "physical")

func cast_elemental_skill() -> void:
	if skill_cooldown > 0.0:
		return
	skill_cooldown = skill_max_cooldown
	AudioManager.play_sound("weather_rain")
	WeatherManager.activate_weather(global_position)

	# Trigger Rain Slash VFX
	if water_slash_vfx:
		water_slash_vfx.restart()
		water_slash_vfx.emitting = true

	# Sword hydro spin animation
	var tw := create_tween()
	tw.tween_property(visual_root, "rotation:y", visual_root.rotation.y + TAU, 0.35)

	# Hit all nearby enemies with Rain/Hydro damage
	var space_state := get_world_3d().direct_space_state
	var sphere := SphereShape3D.new()
	sphere.radius = 6.0
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = global_transform
	query.collision_mask = 4 # Enemies layer

	var results := space_state.intersect_shape(query, 16)
	for res in results:
		var collider: Node = res.collider
		if collider and collider.has_method("take_hit"):
			collider.take_hit(180, "rain", true)

	elemental_energy = min(max_elemental_energy, elemental_energy + 25.0)
	emit_signal("energy_changed", elemental_energy, max_elemental_energy)

func cast_elemental_burst() -> void:
	if elemental_energy < max_elemental_energy:
		return
	elemental_energy = 0.0
	emit_signal("energy_changed", elemental_energy, max_elemental_energy)
	AudioManager.play_sound("checkpoint")

	# Cinematic Camera zoom-in
	var tw := create_tween()
	tw.tween_property(camera, "fov", 55.0, 0.2)
	tw.tween_property(camera, "fov", 72.0, 0.4).set_delay(0.3)

	# Mass AOE Tempest damage
	CombatManager.spawn_damage_number(global_position + Vector3(0, 2.5, 0), 450, "rain", true)

	var space_state := get_world_3d().direct_space_state
	var sphere := SphereShape3D.new()
	sphere.radius = 12.0
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = sphere
	query.transform = global_transform
	query.collision_mask = 4

	var results := space_state.intersect_shape(query, 32)
	for res in results:
		var collider: Node = res.collider
		if collider and collider.has_method("take_hit"):
			collider.take_hit(450, "rain", true)

	GameManager.heal_player(2)

func _check_attack_hits(base_damage: int, element: String) -> void:
	await get_tree().create_timer(0.08).timeout
	if not is_instance_valid(self):
		return
	var bodies := attack_area.get_overlapping_bodies()
	for b in bodies:
		if b.is_in_group("enemies") and b.has_method("take_hit"):
			var is_crit := randf() < 0.25
			var dmg: int = int(base_damage * (1.6 if is_crit else 1.0))
			b.take_hit(dmg, element, is_crit)
			# Gaining energy on hits
			elemental_energy = min(max_elemental_energy, elemental_energy + 8.0)
			emit_signal("energy_changed", elemental_energy, max_elemental_energy)

func take_damage(amount: int = 1) -> void:
	if is_invulnerable:
		return
	is_invulnerable = true
	GameManager.damage_player(amount)
	AudioManager.play_sound("hit")

	var tw := create_tween()
	for i in 3:
		tw.tween_property(visual_root, "modulate", Color(2.0, 0.4, 0.4, 1.0), 0.08)
		tw.tween_property(visual_root, "modulate", Color.WHITE, 0.08)
	await get_tree().create_timer(0.8).timeout
	is_invulnerable = false

func _on_fall_out_of_bounds() -> void:
	velocity = Vector3.ZERO
	take_damage(1)
	if GameManager.player_health > 0:
		var respawn_pt: Variant = GameManager.last_checkpoint_position
		if respawn_pt is Vector3:
			global_position = respawn_pt + Vector3(0, 1.5, 0)
		elif respawn_pt is Vector2:
			global_position = Vector3(respawn_pt.x, 2.0, respawn_pt.y)
		else:
			global_position = Vector3(0, 2.0, 6.0)
		velocity = Vector3.ZERO

func respawn(pos: Variant) -> void:
	if pos is Vector3:
		global_position = pos + Vector3(0, 1.5, 0)
	elif pos is Vector2:
		global_position = Vector3(pos.x, 2.0, pos.y)
	else:
		global_position = Vector3(0, 2.0, 6.0)
	velocity = Vector3.ZERO
	GameManager.set_player_health(GameManager.player_max_health)
	current_stamina = max_stamina

func trigger_interaction() -> void:
	if current_interactable and current_interactable.has_method("interact"):
		current_interactable.interact(self)

func _on_interaction_area_entered(area: Area3D) -> void:
	if area.is_in_group("interactable"):
		current_interactable = area
		EventBus3D.emit_signal("interaction_available", true, area)

func _on_interaction_area_exited(area: Area3D) -> void:
	if current_interactable == area:
		current_interactable = null
		EventBus3D.emit_signal("interaction_available", false, null)

func _update_procedural_animations(delta: float) -> void:
	if not visual_root:
		return
	anim_time += delta
	var horiz_speed := Vector2(velocity.x, velocity.z).length()

	# Base body bob & tilt
	if is_on_floor() and not is_attacking:
		if horiz_speed > 0.5:
			var freq := 14.0 if is_sprinting else 9.5
			visual_root.position.y = abs(sin(anim_time * freq)) * (0.12 if is_sprinting else 0.07)
			visual_root.rotation.z = sin(anim_time * freq * 0.5) * 0.05
			visual_root.rotation.x = -0.14 if is_sprinting else -0.06
		else:
			visual_root.position.y = sin(anim_time * 2.2) * 0.02
			visual_root.rotation.z = 0.0
			visual_root.rotation.x = 0.0

	# Procedural Skeletal Animation
	if skeleton == null:
		return

	if not is_on_floor():
		# Jump / Fall pose: arms slightly out, knees bent
		var jump_arm_l := Quaternion.from_euler(Vector3(0.3, 0.0, 0.75))
		var jump_arm_r := Quaternion.from_euler(Vector3(0.3, 0.0, -0.75))
		var jump_leg_l := Quaternion.from_euler(Vector3(-0.4, 0.0, 0.1))
		var jump_leg_r := Quaternion.from_euler(Vector3(-0.4, 0.0, -0.1))
		var jump_knee := Quaternion.from_euler(Vector3(0.65, 0.0, 0.0))

		_set_bone_rot(b_l_upper_arm, jump_arm_l)
		_set_bone_rot(b_r_upper_arm, jump_arm_r)
		_set_bone_rot(b_l_upper_leg, jump_leg_l)
		_set_bone_rot(b_r_upper_leg, jump_leg_r)
		_set_bone_rot(b_l_lower_leg, jump_knee)
		_set_bone_rot(b_r_lower_leg, jump_knee)
	elif is_attacking:
		# Attack swing: right arm drives combat slash
		var slash_progress: float = clampf(1.0 - (attack_timer / 0.42), 0.0, 1.0)
		var arm_l := Quaternion.from_euler(Vector3(0.2, 0.0, 1.05))
		var arm_r := Quaternion.from_euler(Vector3(lerp(-1.2, 0.8, slash_progress), 0.3, lerp(-0.8, -0.2, slash_progress)))
		_set_bone_rot(b_l_upper_arm, arm_l)
		_set_bone_rot(b_r_upper_arm, arm_r)
	elif horiz_speed > 0.5:
		# Locomotion gait: walk / run / sprint stride
		var gait_freq: float = 13.0 if is_sprinting else 8.5
		var stride: float = anim_time * gait_freq
		var leg_amp: float = 0.75 if is_sprinting else 0.5
		var arm_amp: float = 0.65 if is_sprinting else 0.4

		# Alternating leg swing
		var leg_l_rot := Quaternion.from_euler(Vector3(sin(stride) * leg_amp, 0.0, 0.05))
		var leg_r_rot := Quaternion.from_euler(Vector3(-sin(stride) * leg_amp, 0.0, -0.05))
		var knee_l_rot := Quaternion.from_euler(Vector3(max(0.0, -sin(stride)) * 0.85, 0.0, 0.0))
		var knee_r_rot := Quaternion.from_euler(Vector3(max(0.0, sin(stride)) * 0.85, 0.0, 0.0))

		# Alternating arm swing (opposite to legs)
		var arm_l_rot := Quaternion.from_euler(Vector3(-sin(stride) * arm_amp, deg_to_rad(12.0), deg_to_rad(-62.0)))
		var arm_r_rot := Quaternion.from_euler(Vector3(sin(stride) * arm_amp, deg_to_rad(-12.0), deg_to_rad(62.0)))
		var elbow_l_rot := Quaternion.from_euler(Vector3(0, deg_to_rad(20.0), deg_to_rad(-15.0)))
		var elbow_r_rot := Quaternion.from_euler(Vector3(0, deg_to_rad(-20.0), deg_to_rad(15.0)))

		_set_bone_rot(b_l_upper_arm, arm_l_rot)
		_set_bone_rot(b_r_upper_arm, arm_r_rot)
		_set_bone_rot(b_l_lower_arm, elbow_l_rot)
		_set_bone_rot(b_r_lower_arm, elbow_r_rot)
		_set_bone_rot(b_l_upper_leg, leg_l_rot)
		_set_bone_rot(b_r_upper_leg, leg_r_rot)
		_set_bone_rot(b_l_lower_leg, knee_l_rot)
		_set_bone_rot(b_r_lower_leg, knee_r_rot)
	else:
		# Natural Idle Stance: arms resting comfortably alongside torso, gentle breathing
		var breath: float = sin(anim_time * 2.0) * 0.03
		var idle_arm_l := Quaternion.from_euler(Vector3(deg_to_rad(-12.0), deg_to_rad(15.0), deg_to_rad(-68.0) - breath))
		var idle_arm_r := Quaternion.from_euler(Vector3(deg_to_rad(-12.0), deg_to_rad(-15.0), deg_to_rad(68.0) + breath))
		var idle_elbow_l := Quaternion.from_euler(Vector3(0, deg_to_rad(25.0), deg_to_rad(-20.0)))
		var idle_elbow_r := Quaternion.from_euler(Vector3(0, deg_to_rad(-25.0), deg_to_rad(20.0)))
		var idle_spine := Quaternion.from_euler(Vector3(breath * 0.5, 0.0, 0.0))

		_set_bone_rot(b_l_upper_arm, idle_arm_l)
		_set_bone_rot(b_r_upper_arm, idle_arm_r)
		_set_bone_rot(b_l_lower_arm, idle_elbow_l)
		_set_bone_rot(b_r_lower_arm, idle_elbow_r)
		_set_bone_rot(b_spine, idle_spine)
		_set_bone_rot(b_l_upper_leg, Quaternion.from_euler(Vector3(0, 0, deg_to_rad(-3.0))))
		_set_bone_rot(b_r_upper_leg, Quaternion.from_euler(Vector3(0, 0, deg_to_rad(3.0))))
		_set_bone_rot(b_l_lower_leg, Quaternion.from_euler(Vector3(deg_to_rad(2.0), 0, 0)))
		_set_bone_rot(b_r_lower_leg, Quaternion.from_euler(Vector3(deg_to_rad(2.0), 0, 0)))

func _set_bone_rot(bone_id: int, rot: Quaternion) -> void:
	if skeleton and bone_id >= 0:
		skeleton.set_bone_pose_rotation(bone_id, rot)
