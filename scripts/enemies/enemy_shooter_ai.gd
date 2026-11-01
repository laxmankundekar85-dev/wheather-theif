## EnemyShooterAI.gd
## High-fidelity tactical enemy soldier (Shadow Vanguard Operative).
## Features full 3D humanoid skeletal procedural animation (idle breathing, walk gait,
## shoulder-stocked ADS aiming, firing recoil kick, reload motion, damage flinch, ragdoll crumple),
## raycast line-of-sight engagement, burst fire ballistics, and headshot vulnerability.
extends CharacterBody3D
class_name EnemyShooterAI

enum State {
	PATROL,
	ENGAGE,
	TAKE_COVER,
	RELOAD,
	DEAD
}

@export_group("Attributes")
@export var soldier_name: String = "Shadow Vanguard Operative"
@export var max_health: int = 100
@export var current_health: int = 100
@export var move_speed: float = 3.6
@export var sprint_speed: float = 5.8
@export var detection_range: float = 32.0
@export var attack_range: float = 26.0

@export_group("Combat Tuning")
@export var bullet_damage: int = 9
@export var burst_count: int = 3
@export var burst_delay: float = 0.11
@export var fire_cooldown: float = 1.6
@export var mag_capacity: int = 24
@export var reload_duration: float = 2.2

# Node References
@onready var visual_root: Node3D = $VisualRoot
@onready var los_ray: RayCast3D = $LineOfSightRay
@onready var head_hitbox: Area3D = $VisualRoot/HeadHitbox
@onready var weapon_socket: Node3D = $VisualRoot/WeaponSocket

# State Variables
var current_state: State = State.PATROL
var target_player: CharacterBody3D = null
var current_ammo: int = 24
var cooldown_timer: float = 1.0
var burst_shots_remaining: int = 0
var burst_timer: float = 0.0
var reload_timer: float = 0.0
var patrol_center: Vector3
var patrol_target: Vector3
var anim_time: float = 0.0
var gait_cycle: float = 0.0
var recoil_anim: float = 0.0
var flinch_anim: float = 0.0
var hp_label: Label3D = null
var death_anim_progress: float = 0.0
var aim_elevation: float = 0.0

# Skeleton & Bones
var skeleton: Skeleton3D = null
var b_hips: int = -1
var b_spine: int = -1
var b_chest: int = -1
var b_neck: int = -1
var b_head: int = -1
var b_r_upper_arm: int = -1
var b_r_lower_arm: int = -1
var b_l_upper_arm: int = -1
var b_l_lower_arm: int = -1
var b_r_upper_leg: int = -1
var b_r_lower_leg: int = -1
var b_l_upper_leg: int = -1
var b_l_lower_leg: int = -1

var muzzle_point: Marker3D = null
var muzzle_flash: CPUParticles3D = null

const BulletTrailClass = preload("res://scripts/combat/bullet_trail.gd")

signal enemy_defeated(soldier: Node)

func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	current_ammo = mag_capacity
	cooldown_timer = randf_range(2.0, 3.5)
	patrol_center = global_position
	_pick_new_patrol_point()

	_init_skeleton()
	_apply_tactical_uniform()
	_setup_weapon()

	# Overhead tactical health indicator
	hp_label = Label3D.new()
	hp_label.name = "HealthIndicator"
	hp_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hp_label.font_size = 18
	hp_label.position = Vector3(0, 2.1, 0)
	hp_label.modulate = Color(1.0, 0.45, 0.45, 0.9)
	hp_label.text = "%s [%d/%d]" % [soldier_name, current_health, max_health]
	add_child(hp_label)

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
		b_l_upper_arm = skeleton.find_bone("J_Bip_L_UpperArm")
		b_l_lower_arm = skeleton.find_bone("J_Bip_L_LowerArm")
		b_r_upper_leg = skeleton.find_bone("J_Bip_R_UpperLeg")
		b_r_lower_leg = skeleton.find_bone("J_Bip_R_LowerLeg")
		b_l_upper_leg = skeleton.find_bone("J_Bip_L_UpperLeg")
		b_l_lower_leg = skeleton.find_bone("J_Bip_L_LowerLeg")

func _apply_tactical_uniform() -> void:
	if not visual_root:
		return

	for c in visual_root.find_children("*", "MeshInstance3D", true, false):
		var mi := c as MeshInstance3D
		if not mi or not mi.mesh:
			continue
		for s in range(mi.mesh.get_surface_count()):
			var orig_mat = mi.get_active_material(s)
			if orig_mat and orig_mat is StandardMaterial3D:
				var m := orig_mat.duplicate() as StandardMaterial3D
				var m_name: String = m.resource_name
				if "Tops" in m_name:
					m.albedo_color = Color(0.20, 0.22, 0.26, 1.0) # Dark ballistic vest
					m.roughness = 0.65
				elif "Bottoms" in m_name:
					m.albedo_color = Color(0.14, 0.15, 0.18, 1.0) # Charcoal combat trousers
					m.roughness = 0.75
				elif "Shoes" in m_name:
					m.albedo_color = Color(0.08, 0.08, 0.10, 1.0) # Black combat boots
					m.roughness = 0.5
				elif "Hair" in m_name:
					m.albedo_color = Color(0.10, 0.10, 0.12, 1.0) # Dark tactical hair
					m.roughness = 0.7
				elif "Eye" in m_name:
					m.albedo_color = Color(1.0, 0.15, 0.25, 1.0) # Glowing red cyber-optic visor
					m.emission_enabled = true
					m.emission = Color(1.0, 0.1, 0.2)
					m.emission_energy_multiplier = 4.0
				elif "Face" in m_name or "Body" in m_name:
					m.albedo_color = Color(0.16, 0.17, 0.20, 1.0) # Matte tactical balaclava mask
					m.roughness = 0.75
				mi.set_surface_override_material(s, m)

func _setup_weapon() -> void:
	if weapon_socket:
		muzzle_point = weapon_socket.find_child("MuzzlePoint", true, false)
		if muzzle_point:
			muzzle_flash = muzzle_point.find_child("MuzzleFlash", true, false)
			if muzzle_flash:
				muzzle_flash.emitting = false

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		_process_death_anim(delta)
		return

	anim_time += delta
	recoil_anim = move_toward(recoil_anim, 0.0, delta * 10.0)
	flinch_anim = move_toward(flinch_anim, 0.0, delta * 8.0)

	# Locate player
	if target_player == null or not is_instance_valid(target_player):
		target_player = GameManager.player_ref as CharacterBody3D

	match current_state:
		State.PATROL:
			_process_patrol(delta)
		State.ENGAGE:
			_process_engage(delta)
		State.TAKE_COVER:
			_process_cover(delta)
		State.RELOAD:
			_process_reload(delta)

	if not is_on_floor():
		velocity.y -= 25.0 * delta

	move_and_slide()
	_update_procedural_animations(delta)

func _process_patrol(delta: float) -> void:
	# Detect player within line of sight
	if target_player and is_instance_valid(target_player):
		var dist := global_position.distance_to(target_player.global_position)
		if dist <= detection_range and _has_line_of_sight(target_player.global_position + Vector3(0, 1.2, 0)):
			current_state = State.ENGAGE
			return

	# Stroll toward patrol target
	var dist_p := global_position.distance_to(patrol_target)
	if dist_p < 1.4:
		_pick_new_patrol_point()

	var dir := (patrol_target - global_position)
	dir.y = 0.0
	if dir.length_squared() > 0.1:
		dir = dir.normalized()
		velocity.x = dir.x * move_speed
		velocity.z = dir.z * move_speed
		var target_angle := atan2(-dir.x, -dir.z)
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_angle, delta * 5.0)
	else:
		velocity.x = 0
		velocity.z = 0

func _process_engage(delta: float) -> void:
	if target_player == null or not is_instance_valid(target_player):
		current_state = State.PATROL
		return

	var player_pos := target_player.global_position
	var dist := global_position.distance_to(player_pos)

	# Face player smoothly
	var to_player := (player_pos - global_position)
	var horiz_dist := Vector2(to_player.x, to_player.z).length()
	aim_elevation = atan2(to_player.y, maxf(0.1, horiz_dist))

	to_player.y = 0.0
	if to_player.length_squared() > 0.1:
		var face_dir := to_player.normalized()
		var aim_angle := atan2(-face_dir.x, -face_dir.z)
		visual_root.rotation.y = lerp_angle(visual_root.rotation.y, aim_angle, delta * 9.0)

	# Reload if out of ammo
	if current_ammo <= 0:
		current_state = State.RELOAD
		reload_timer = reload_duration
		AudioManager.play_sound("rifle_reload")
		return

	# Handle shooting burst
	if burst_shots_remaining > 0:
		burst_timer -= delta
		if burst_timer <= 0.0:
			burst_timer = burst_delay
			burst_shots_remaining -= 1
			_fire_one_bullet()
	else:
		cooldown_timer -= delta
		if cooldown_timer <= 0.0:
			if dist <= attack_range and _has_line_of_sight(player_pos + Vector3(0, 1.2, 0)):
				burst_shots_remaining = burst_count
				burst_timer = 0.0
				cooldown_timer = fire_cooldown
			else:
				# Advance toward player
				var move_dir := to_player.normalized()
				velocity.x = move_dir.x * sprint_speed
				velocity.z = move_dir.z * sprint_speed

	# Repositioning & holding ground
	if burst_shots_remaining > 0:
		velocity.x = move_toward(velocity.x, 0.0, delta * 14.0)
		velocity.z = move_toward(velocity.z, 0.0, delta * 14.0)
	elif dist < 7.0:
		# Tactical retreat/backpedal
		var back_dir := -to_player.normalized()
		velocity.x = back_dir.x * move_speed
		velocity.z = back_dir.z * move_speed

func _process_cover(_delta: float) -> void:
	pass

func _process_reload(delta: float) -> void:
	reload_timer -= delta
	if target_player:
		var back_dir := -(target_player.global_position - global_position).normalized()
		velocity.x = back_dir.x * (move_speed * 0.7)
		velocity.z = back_dir.z * (move_speed * 0.7)

	if reload_timer <= 0.0:
		current_ammo = mag_capacity
		current_state = State.ENGAGE
		cooldown_timer = 0.4

func _fire_one_bullet() -> void:
	if not target_player or not is_instance_valid(target_player):
		return

	current_ammo -= 1
	recoil_anim = 1.0
	AudioManager.play_sound("rifle_shoot")

	if muzzle_flash:
		muzzle_flash.restart()
		muzzle_flash.emitting = true

	var start_pos := muzzle_point.global_position if muzzle_point else (global_position + Vector3(0, 1.2, 0))
	var aim_target := target_player.global_position + Vector3(0, 1.1, 0)
	var spread := Vector3(randf_range(-0.35, 0.35), randf_range(-0.25, 0.25), randf_range(-0.35, 0.35))
	var shoot_dir := ((aim_target + spread) - start_pos).normalized()

	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(start_pos, start_pos + shoot_dir * 50.0, 3) # Layer 1 & 2
	query.exclude = [get_rid()]

	var result := space_state.intersect_ray(query)
	var end_pos := start_pos + shoot_dir * 50.0

	if result.size() > 0:
		end_pos = result["position"]
		var col: Node = result["collider"] as Node
		if col and col.is_in_group("player") and col.has_method("take_damage"):
			col.take_damage(bullet_damage)

	_spawn_enemy_tracer(start_pos, end_pos)

func _spawn_enemy_tracer(start: Vector3, end: Vector3) -> void:
	var trail = BulletTrailClass.new()
	var tree := get_tree()
	if tree and tree.current_scene:
		tree.current_scene.add_child(trail)
		trail.init(start, end, Color(1.0, 0.3, 0.2, 0.95))

func _has_line_of_sight(target_pos: Vector3) -> bool:
	var space_state := get_world_3d().direct_space_state
	var my_eye := global_position + Vector3(0, 1.5, 0)
	var query := PhysicsRayQueryParameters3D.create(my_eye, target_pos, 1)
	var result := space_state.intersect_ray(query)
	return result.is_empty()

func _pick_new_patrol_point() -> void:
	var offset := Vector3(randf_range(-8.0, 8.0), 0, randf_range(-8.0, 8.0))
	patrol_target = patrol_center + offset

func _update_procedural_animations(delta: float) -> void:
	if not skeleton:
		return

	var horiz_vel := Vector2(velocity.x, velocity.z)
	var speed := horiz_vel.length()
	var on_ground := is_on_floor()

	if on_ground and speed > 0.4:
		gait_cycle += delta * speed * 1.8
	else:
		gait_cycle = move_toward(gait_cycle, 0.0, delta * 6.0)

	# 1. SPINE & CHEST (Breathing, aim pitch, and recoil kick)
	if b_spine != -1:
		var spine_lean := (deg_to_rad(10.0) if speed > 1.0 else sin(anim_time * 2.0) * deg_to_rad(1.5)) - flinch_anim * deg_to_rad(15.0)
		skeleton.set_bone_pose_rotation(b_spine, Quaternion.from_euler(Vector3(spine_lean, 0, 0)))

	if b_chest != -1:
		var chest_pitch := aim_elevation - recoil_anim * 0.1
		skeleton.set_bone_pose_rotation(b_chest, Quaternion.from_euler(Vector3(chest_pitch, 0, 0)))

	if b_head != -1:
		var head_pitch := aim_elevation * 0.7
		skeleton.set_bone_pose_rotation(b_head, Quaternion.from_euler(Vector3(head_pitch, 0, 0)))

	# 2. LEGS LOCOMOTION
	if on_ground:
		if speed > 0.4:
			var stride := deg_to_rad(22.0)
			var knee_amp := deg_to_rad(45.0)
			var l_swing := sin(gait_cycle) * stride
			var r_swing := -sin(gait_cycle) * stride
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
			# Idle combat stance
			if b_l_upper_leg != -1:
				skeleton.set_bone_pose_rotation(b_l_upper_leg, Quaternion.from_euler(Vector3(deg_to_rad(4.0), 0, deg_to_rad(-5.0))))
			if b_l_lower_leg != -1:
				skeleton.set_bone_pose_rotation(b_l_lower_leg, Quaternion.from_euler(Vector3(deg_to_rad(6.0), 0, 0)))
			if b_r_upper_leg != -1:
				skeleton.set_bone_pose_rotation(b_r_upper_leg, Quaternion.from_euler(Vector3(deg_to_rad(-8.0), 0, deg_to_rad(5.0))))
			if b_r_lower_leg != -1:
				skeleton.set_bone_pose_rotation(b_r_lower_leg, Quaternion.from_euler(Vector3(deg_to_rad(10.0), 0, 0)))

	# 3. ARMS & WEAPON HOLDING (NEVER T-POSE!)
	var is_aiming_or_firing := (current_state == State.ENGAGE and burst_shots_remaining > 0) or current_state == State.ENGAGE
	var is_reloading := (current_state == State.RELOAD)

	if is_aiming_or_firing and not is_reloading:
		# Shoulder-stocked ADS firing stance
		var kick := recoil_anim * 0.12
		if b_r_upper_arm != -1:
			var q_r := Quaternion.from_euler(Vector3(deg_to_rad(-76.0) + aim_elevation + kick, deg_to_rad(-16.0), deg_to_rad(-16.0)))
			skeleton.set_bone_pose_rotation(b_r_upper_arm, q_r)
		if b_r_lower_arm != -1:
			var q_rf := Quaternion.from_euler(Vector3(deg_to_rad(12.0), deg_to_rad(-24.0), deg_to_rad(-32.0)))
			skeleton.set_bone_pose_rotation(b_r_lower_arm, q_rf)

		if b_l_upper_arm != -1:
			var q_l := Quaternion.from_euler(Vector3(deg_to_rad(-66.0) + aim_elevation * 0.8, deg_to_rad(30.0), deg_to_rad(24.0)))
			skeleton.set_bone_pose_rotation(b_l_upper_arm, q_l)
		if b_l_lower_arm != -1:
			var q_lf := Quaternion.from_euler(Vector3(deg_to_rad(16.0), deg_to_rad(42.0), deg_to_rad(28.0)))
			skeleton.set_bone_pose_rotation(b_l_lower_arm, q_lf)
	elif is_reloading:
		# Reload stance: rifle lowered, left hand working mag
		if b_r_upper_arm != -1:
			skeleton.set_bone_pose_rotation(b_r_upper_arm, Quaternion.from_euler(Vector3(deg_to_rad(-40.0), deg_to_rad(-10.0), deg_to_rad(-45.0))))
		if b_r_lower_arm != -1:
			skeleton.set_bone_pose_rotation(b_r_lower_arm, Quaternion.from_euler(Vector3(deg_to_rad(20.0), 0, deg_to_rad(-20.0))))
		if b_l_upper_arm != -1:
			var mag_motion := sin(reload_timer * 8.0) * deg_to_rad(15.0)
			skeleton.set_bone_pose_rotation(b_l_upper_arm, Quaternion.from_euler(Vector3(deg_to_rad(-20.0) + mag_motion, deg_to_rad(20.0), deg_to_rad(30.0))))
	else:
		# Low Ready Patrol
		var breathe := sin(anim_time * 2.0) * deg_to_rad(1.2)
		if b_r_upper_arm != -1:
			skeleton.set_bone_pose_rotation(b_r_upper_arm, Quaternion.from_euler(Vector3(deg_to_rad(-35.0), deg_to_rad(-20.0), deg_to_rad(-65.0) - breathe)))
		if b_r_lower_arm != -1:
			skeleton.set_bone_pose_rotation(b_r_lower_arm, Quaternion.from_euler(Vector3(0, deg_to_rad(-30.0), deg_to_rad(-35.0))))
		if b_l_upper_arm != -1:
			skeleton.set_bone_pose_rotation(b_l_upper_arm, Quaternion.from_euler(Vector3(deg_to_rad(-20.0), deg_to_rad(38.0), deg_to_rad(58.0) + breathe)))
		if b_l_lower_arm != -1:
			skeleton.set_bone_pose_rotation(b_l_lower_arm, Quaternion.from_euler(Vector3(deg_to_rad(15.0), deg_to_rad(35.0), deg_to_rad(45.0))))

	# Weapon Socket position interpolation
	if weapon_socket:
		var target_weapon_pos := Vector3(0.20, 1.28, -0.32) if is_aiming_or_firing else Vector3(0.24, 0.95, -0.22)
		var target_weapon_rot := Vector3(aim_elevation, deg_to_rad(4.0), 0) if is_aiming_or_firing else Vector3(deg_to_rad(10.0), deg_to_rad(-8.0), 0)
		weapon_socket.position = weapon_socket.position.lerp(target_weapon_pos, delta * 14.0)
		weapon_socket.rotation = weapon_socket.rotation.lerp(target_weapon_rot, delta * 14.0)

func take_damage(amount: int, origin_or_element: Variant = "physical", is_crit: bool = false) -> int:
	if current_state == State.DEAD:
		return 0

	var actual_damage: int = amount
	if is_crit:
		actual_damage = int(amount * 1.5)

	current_health = max(0, current_health - actual_damage)
	flinch_anim = 1.0

	# Update overhead tactical indicator
	if hp_label:
		hp_label.text = "%s [%d/%d]" % [soldier_name, current_health, max_health]
		if current_health <= int(max_health * 0.35):
			hp_label.modulate = Color(1.0, 0.2, 0.2, 1.0)

	# 3D flinch scale pulse on visual_root
	if visual_root:
		var tw := create_tween()
		tw.tween_property(visual_root, "scale", Vector3(1.08, 0.94, 1.08), 0.05)
		tw.tween_property(visual_root, "scale", Vector3.ONE, 0.08)

	# If damaged from a position, face towards the damage origin
	if origin_or_element is Vector3 and target_player == null:
		var dir: Vector3 = (origin_or_element as Vector3) - global_position
		dir.y = 0.0
		if dir.length_squared() > 0.01:
			look_at(global_position - dir.normalized(), Vector3.UP)

	# Alert and engage player
	if not target_player:
		var players = get_tree().get_nodes_in_group("player")
		if players.size() > 0:
			target_player = players[0]
	if target_player:
		current_state = State.ENGAGE

	if current_health <= 0:
		die()

	return actual_damage

func die() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.DEAD
	AudioManager.play_sound("enemy_defeat")
	emit_signal("enemy_defeated", self)

	# Disable collision so player and bullets pass through dead body
	set_collision_layer_value(3, false)
	set_collision_mask_value(1, false)

	var head_hitbox := get_node_or_null("VisualRoot/HeadHitbox") as Area3D
	if head_hitbox:
		head_hitbox.set_collision_layer_value(3, false)

	var root_col := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if root_col:
		root_col.set_deferred("disabled", true)

	if hp_label:
		hp_label.text = "ELIMINATED"
		hp_label.modulate = Color(0.6, 0.6, 0.6, 0.6)

	_spawn_drop_cache()

func _process_death_anim(delta: float) -> void:
	death_anim_progress += delta
	# Ragdoll crumple backwards onto ground
	if skeleton:
		if b_hips != -1:
			var h_rot := Quaternion.from_euler(Vector3(deg_to_rad(75.0) * minf(1.0, death_anim_progress * 2.5), 0, 0))
			skeleton.set_bone_pose_rotation(b_hips, h_rot)
		if b_spine != -1:
			var s_rot := Quaternion.from_euler(Vector3(deg_to_rad(-35.0) * minf(1.0, death_anim_progress * 2.0), 0, 0))
			skeleton.set_bone_pose_rotation(b_spine, s_rot)

	if visual_root and death_anim_progress > 1.2:
		visual_root.position.y = move_toward(visual_root.position.y, -1.8, delta * 1.5)
		if death_anim_progress > 3.0:
			queue_free()

func _spawn_drop_cache() -> void:
	if target_player and "weapon_manager" in target_player and target_player.weapon_manager:
		if target_player.weapon_manager.active_weapon:
			target_player.weapon_manager.active_weapon.add_ammo(24)
