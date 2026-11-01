## EnemyAnimationController.gd
## High-fidelity procedural humanoid skeleton animator.
## Directly controls the 101-bone rig in kael_avatar_c.glb.
## Eliminates T-pose completely: provides realistic idle breathing, weight shifts,
## two-handed tactical weapon ready stance, ADS aiming, walking/running strides,
## crouch/cover postures, weapon recoil kick, directional hit flinches, and ragdoll death collapse.
extends Node
class_name EnemyAnimationController

enum AnimState {
	IDLE,
	WALK,
	RUN,
	SPRINT,
	AIM_FIRE,
	CROUCH_COVER,
	RELOAD,
	HIT_STAGGER,
	DEATH
}

@export var skeleton_path: NodePath
var skeleton: Skeleton3D = null

# Bone Indices
var b_hips: int = -1
var b_spine: int = -1
var b_chest: int = -1
var b_upper_chest: int = -1
var b_neck: int = -1
var b_head: int = -1
var b_r_shoulder: int = -1
var b_r_upper_arm: int = -1
var b_r_lower_arm: int = -1
var b_r_hand: int = -1
var b_l_shoulder: int = -1
var b_l_upper_arm: int = -1
var b_l_lower_arm: int = -1
var b_l_hand: int = -1
var b_r_upper_leg: int = -1
var b_r_lower_leg: int = -1
var b_r_foot: int = -1
var b_l_upper_leg: int = -1
var b_l_lower_leg: int = -1
var b_l_foot: int = -1

# Animation parameters
var current_state: AnimState = AnimState.IDLE
var anim_time: float = 0.0
var gait_cycle: float = 0.0
var move_speed: float = 0.0
var is_crouching: bool = false
var is_aiming: bool = false
var aim_pitch: float = 0.0 # Radians
var aim_yaw: float = 0.0   # Radians

# Impulse channels
var recoil_impulse: float = 0.0
var hit_flinch_impulse: float = 0.0
var hit_flinch_dir: Vector3 = Vector3.ZERO
var death_progress: float = 0.0
var is_dead: bool = false

func _ready() -> void:
	if not skeleton_path.is_empty():
		skeleton = get_node_or_null(skeleton_path) as Skeleton3D
	if not skeleton:
		# Auto-find Skeleton3D in parent hierarchy
		skeleton = _find_skeleton(get_parent())

	if skeleton:
		_cache_bones()

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found:
			return found
	return null

func _cache_bones() -> void:
	if not skeleton:
		return
	b_hips = skeleton.find_bone("J_Bip_C_Hips")
	b_spine = skeleton.find_bone("J_Bip_C_Spine")
	b_chest = skeleton.find_bone("J_Bip_C_Chest")
	b_upper_chest = skeleton.find_bone("J_Bip_C_UpperChest")
	b_neck = skeleton.find_bone("J_Bip_C_Neck")
	b_head = skeleton.find_bone("J_Bip_C_Head")

	b_r_shoulder = skeleton.find_bone("J_Bip_R_Shoulder")
	b_r_upper_arm = skeleton.find_bone("J_Bip_R_UpperArm")
	b_r_lower_arm = skeleton.find_bone("J_Bip_R_LowerArm")
	b_r_hand = skeleton.find_bone("J_Bip_R_Hand")

	b_l_shoulder = skeleton.find_bone("J_Bip_L_Shoulder")
	b_l_upper_arm = skeleton.find_bone("J_Bip_L_UpperArm")
	b_l_lower_arm = skeleton.find_bone("J_Bip_L_LowerArm")
	b_l_hand = skeleton.find_bone("J_Bip_L_Hand")

	b_r_upper_leg = skeleton.find_bone("J_Bip_R_UpperLeg")
	b_r_lower_leg = skeleton.find_bone("J_Bip_R_LowerLeg")
	b_r_foot = skeleton.find_bone("J_Bip_R_Foot")

	b_l_upper_leg = skeleton.find_bone("J_Bip_L_UpperLeg")
	b_l_lower_leg = skeleton.find_bone("J_Bip_L_LowerLeg")
	b_l_foot = skeleton.find_bone("J_Bip_L_Foot")

func _process(delta: float) -> void:
	if not skeleton:
		skeleton = _find_skeleton(get_parent())
		if skeleton:
			_cache_bones()
		return

	anim_time += delta

	# Decay dynamic impulses
	if recoil_impulse > 0.0:
		recoil_impulse = maxf(0.0, recoil_impulse - delta * 9.0)
	if hit_flinch_impulse > 0.0:
		hit_flinch_impulse = maxf(0.0, hit_flinch_impulse - delta * 5.0)

	if is_dead:
		death_progress = minf(1.0, death_progress + delta * 2.8)
		_apply_death_pose(death_progress)
		return

	# Drive gait cycle
	if move_speed > 0.15:
		var cycle_rate := 5.2 if move_speed < 3.2 else 8.5
		gait_cycle += delta * cycle_rate
	else:
		gait_cycle = lerpf(gait_cycle, 0.0, delta * 6.0)

	_apply_tactical_pose(delta)

func trigger_recoil(strength: float = 1.0) -> void:
	recoil_impulse = strength

func trigger_hit_flinch(dir: Vector3) -> void:
	hit_flinch_impulse = 1.0
	hit_flinch_dir = dir

func trigger_death() -> void:
	is_dead = true
	death_progress = 0.0

func _apply_tactical_pose(delta: float) -> void:
	# 1. BREATHING & IDLE SHIFT
	var breath := sin(anim_time * 2.2) * 0.02
	var sway := sin(anim_time * 0.9) * 0.015

	# 2. LOCOMOTION SWING
	var leg_stride := sin(gait_cycle) * (0.42 if move_speed > 3.0 else 0.28)
	var knee_flex := maxf(0.0, sin(gait_cycle)) * 0.75
	var knee_flex_l := maxf(0.0, -sin(gait_cycle)) * 0.75

	# Crouch factor
	var crouch_offset := -0.38 if is_crouching else 0.0
	var crouch_lean := 0.22 if is_crouching else 0.0

	# 3. HIPS / PELVIS
	if b_hips != -1:
		var rest_pose := skeleton.get_bone_rest(b_hips)
		var target_pos := rest_pose.origin + Vector3(sway * 0.5, crouch_offset + absf(leg_stride) * -0.05, 0)
		skeleton.set_bone_pose_position(b_hips, target_pos)
		skeleton.set_bone_pose_rotation(b_hips, Quaternion.from_euler(Vector3(crouch_lean, sway, 0)))

	# 4. SPINE & CHEST (Aim Pitch tracking + Recoil kick)
	var aim_torso_pitch := aim_pitch * 0.5
	var recoil_kick := -recoil_impulse * 0.12
	var flinch_pitch := hit_flinch_impulse * 0.15 * hit_flinch_dir.z
	var flinch_roll := hit_flinch_impulse * 0.2 * hit_flinch_dir.x

	if b_spine != -1:
		var spine_rot := Quaternion.from_euler(Vector3(breath + flinch_pitch, sway * 0.5, flinch_roll))
		skeleton.set_bone_pose_rotation(b_spine, spine_rot)

	if b_chest != -1:
		var chest_rot := Quaternion.from_euler(Vector3(aim_torso_pitch + recoil_kick, aim_yaw * 0.4, breath))
		skeleton.set_bone_pose_rotation(b_chest, chest_rot)

	# 5. HEAD & NECK (Target tracking)
	if b_head != -1:
		var head_pitch := clampf(aim_pitch * 0.6, deg_to_rad(-40), deg_to_rad(40))
		var head_yaw := clampf(aim_yaw * 0.6, deg_to_rad(-60), deg_to_rad(60))
		var head_rot := Quaternion.from_euler(Vector3(head_pitch, head_yaw, 0))
		skeleton.set_bone_pose_rotation(b_head, head_rot)

	# 6. ARMS & WEAPON HANDLING (Natural military low-ready vs high-ready ADS)
	# Right arm holds weapon trigger and pistol grip
	# Left arm reaches across to support rifle handguard / foregrip
	var ads_blend := 1.0 if is_aiming else 0.55

	if b_r_upper_arm != -1:
		# Z brings arm down from T-pose (-65 deg). In ADS, lifts up towards -20 deg.
		var r_z := lerpf(-deg_to_rad(65.0), -deg_to_rad(22.0), ads_blend) + recoil_kick
		var r_x := lerpf(deg_to_rad(12.0), deg_to_rad(32.0), ads_blend)
		var r_y := lerpf(-deg_to_rad(8.0), -deg_to_rad(15.0), ads_blend)
		skeleton.set_bone_pose_rotation(b_r_upper_arm, Quaternion.from_euler(Vector3(r_x, r_y, r_z)))

	if b_r_lower_arm != -1:
		var r_elbow_z := lerpf(-deg_to_rad(35.0), -deg_to_rad(55.0), ads_blend)
		skeleton.set_bone_pose_rotation(b_r_lower_arm, Quaternion.from_euler(Vector3(0, 0, r_elbow_z)))

	if b_l_upper_arm != -1:
		# Left arm reaches across chest
		var l_z := lerpf(deg_to_rad(62.0), deg_to_rad(32.0), ads_blend)
		var l_x := lerpf(-deg_to_rad(18.0), -deg_to_rad(45.0), ads_blend)
		var l_y := lerpf(deg_to_rad(10.0), deg_to_rad(25.0), ads_blend)
		skeleton.set_bone_pose_rotation(b_l_upper_arm, Quaternion.from_euler(Vector3(l_x, l_y, l_z)))

	if b_l_lower_arm != -1:
		var l_elbow_z := lerpf(deg_to_rad(40.0), deg_to_rad(70.0), ads_blend)
		skeleton.set_bone_pose_rotation(b_l_lower_arm, Quaternion.from_euler(Vector3(0, 0, l_elbow_z)))

	# 7. LEGS & LOCOMOTION
	if b_r_upper_leg != -1:
		var r_leg_rot := Quaternion.from_euler(Vector3(leg_stride + (0.4 if is_crouching else 0.0), 0, 0))
		skeleton.set_bone_pose_rotation(b_r_upper_leg, r_leg_rot)

	if b_r_lower_leg != -1:
		var r_knee_rot := Quaternion.from_euler(Vector3(-knee_flex - (0.6 if is_crouching else 0.0), 0, 0))
		skeleton.set_bone_pose_rotation(b_r_lower_leg, r_knee_rot)

	if b_l_upper_leg != -1:
		var l_leg_rot := Quaternion.from_euler(Vector3(-leg_stride + (0.4 if is_crouching else 0.0), 0, 0))
		skeleton.set_bone_pose_rotation(b_l_upper_leg, l_leg_rot)

	if b_l_lower_leg != -1:
		var l_knee_rot := Quaternion.from_euler(Vector3(-knee_flex_l - (0.6 if is_crouching else 0.0), 0, 0))
		skeleton.set_bone_pose_rotation(b_l_lower_leg, l_knee_rot)

func _apply_death_pose(progress: float) -> void:
	# Realistic collapse to ground (hips sink, spine arches back, arms release)
	var ease_p := ease(progress, 0.4)

	if b_hips != -1:
		var rest_pose := skeleton.get_bone_rest(b_hips)
		var dead_pos := rest_pose.origin + Vector3(0, -0.78 * ease_p, -0.3 * ease_p)
		skeleton.set_bone_pose_position(b_hips, dead_pos)
		skeleton.set_bone_pose_rotation(b_hips, Quaternion.from_euler(Vector3(deg_to_rad(75.0) * ease_p, 0, deg_to_rad(15.0) * ease_p)))

	if b_spine != -1:
		skeleton.set_bone_pose_rotation(b_spine, Quaternion.from_euler(Vector3(-deg_to_rad(30.0) * ease_p, 0, 0)))

	if b_neck != -1:
		skeleton.set_bone_pose_rotation(b_neck, Quaternion.from_euler(Vector3(deg_to_rad(45.0) * ease_p, deg_to_rad(20.0) * ease_p, 0)))

	if b_r_upper_arm != -1:
		skeleton.set_bone_pose_rotation(b_r_upper_arm, Quaternion.from_euler(Vector3(0, 0, -deg_to_rad(40.0) * (1.0 - ease_p) - deg_to_rad(15.0) * ease_p)))

	if b_l_upper_arm != -1:
		skeleton.set_bone_pose_rotation(b_l_upper_arm, Quaternion.from_euler(Vector3(0, 0, deg_to_rad(40.0) * (1.0 - ease_p) + deg_to_rad(15.0) * ease_p)))

	if b_r_upper_leg != -1:
		skeleton.set_bone_pose_rotation(b_r_upper_leg, Quaternion.from_euler(Vector3(-deg_to_rad(65.0) * ease_p, 0, deg_to_rad(20.0) * ease_p)))

	if b_l_upper_leg != -1:
		skeleton.set_bone_pose_rotation(b_l_upper_leg, Quaternion.from_euler(Vector3(-deg_to_rad(45.0) * ease_p, 0, -deg_to_rad(25.0) * ease_p)))

