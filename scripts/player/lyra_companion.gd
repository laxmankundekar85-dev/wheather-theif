## LyraCompanion.gd
## Stylized Anime-Fantasy Blade Heroine & Tactical Companion in Weather Thief.
## Matches Reference Image 1: Wields the Aetheria Greatsword with central purple crystal,
## offhand glowing Astral Energy Dagger, layered spiked shoulder pauldron, and flowing crimson cape.
## Provides combat support, weather shields, tactical callouts, and follows Kael seamlessly.
extends Node3D
class_name LyraCompanion

@export var follow_distance: float = 2.4
@export var follow_speed: float = 6.8
@export var float_height: float = 0.95

@onready var visual_root: Node3D = $VisualRoot
@onready var sparkle_particles: CPUParticles3D = $SparkleParticles
@onready var speech_bubble: Label3D = $SpeechBubble

var target_player: Node3D = null
var anim_time: float = 0.0
var idle_hint_timer: float = 0.0
var combat_check_timer: float = 0.0
var attack_cooldown: float = 0.0
var shield_cooldown: float = 0.0

var in_combat_stance: bool = false
var current_target_enemy: Node3D = null

# Procedural Heroine Weapon & Armor Nodes (Reference Image 1)
var greatsword_root: Node3D = null
var crystal_gem: MeshInstance3D = null
var energy_dagger_root: Node3D = null
var energy_blade_mesh: MeshInstance3D = null
var spiked_pauldron: Node3D = null
var crimson_cape: MeshInstance3D = null

# Skeletal tracking
var skeleton: Skeleton3D = null
var b_l_upper_arm: int = -1
var b_l_lower_arm: int = -1
var b_r_upper_arm: int = -1
var b_r_lower_arm: int = -1
var b_head: int = -1
var b_spine: int = -1

const HINTS: Array[String] = [
	"Look at these ancient ruins, Kael! The weather balance was shattered here.",
	"Keep your Skybreaker ready. The Vanguard patrol is entrenched ahead.",
	"The seven skies cracked open... together, we'll reclaim the weather siphons!",
	"I'll watch your flank! Focus on the heavy enforcers.",
	"Dash [Shift] or sprint when they open fire with heavy suppression!"
]

const COMBAT_CALLOUTS: Array[String] = [
	"Behind you, Kael! Vanguard closing in!",
	"Aether skyblade, cut through the storm!",
	"I'll draw their heavy fire! Take the shot!",
	"Their line is breaking! Push forward!",
	"Weather ward deployed! Stand fast!"
]

func _ready() -> void:
	if speech_bubble:
		speech_bubble.visible = false
	_init_skeleton()
	_build_heroine_arsenal()

func _init_skeleton() -> void:
	if visual_root:
		skeleton = visual_root.find_child("Skeleton3D", true, false)
	if skeleton:
		b_l_upper_arm = skeleton.find_bone("J_Bip_L_UpperArm")
		b_l_lower_arm = skeleton.find_bone("J_Bip_L_LowerArm")
		b_r_upper_arm = skeleton.find_bone("J_Bip_R_UpperArm")
		b_r_lower_arm = skeleton.find_bone("J_Bip_R_LowerArm")
		b_head = skeleton.find_bone("J_Bip_C_Head")
		b_spine = skeleton.find_bone("J_Bip_C_Spine")

## Builds the stylized fantasy weaponry and armor shown in Reference Image 1
func _build_heroine_arsenal() -> void:
	# 1. THE AETHERIA GREATSWORD (Right Hand Weapon)
	# Long broad steel blade, winged crossguard, central glowing purple crystal, wrapped hilt
	greatsword_root = Node3D.new()
	greatsword_root.name = "AetheriaGreatsword"
	visual_root.add_child(greatsword_root)

	# Steel Blade with Fuller
	var blade := MeshInstance3D.new()
	var blade_box := BoxMesh.new()
	blade_box.size = Vector3(0.095, 0.98, 0.016)
	blade.mesh = blade_box
	var steel_mat := StandardMaterial3D.new()
	steel_mat.albedo_color = Color(0.82, 0.84, 0.88)
	steel_mat.metallic = 0.92
	steel_mat.roughness = 0.22
	blade.material_override = steel_mat
	blade.position = Vector3(0, 0.52, 0)
	greatsword_root.add_child(blade)

	# Blade Tip Point
	var blade_tip := MeshInstance3D.new()
	var prism := PrismMesh.new()
	prism.size = Vector3(0.095, 0.18, 0.016)
	blade_tip.mesh = prism
	blade_tip.material_override = steel_mat
	blade_tip.position = Vector3(0, 1.08, 0)
	greatsword_root.add_child(blade_tip)

	# Ornate Winged Crossguard (Antique gold with dark metal accents)
	var crossguard := MeshInstance3D.new()
	var cg_box := BoxMesh.new()
	cg_box.size = Vector3(0.28, 0.065, 0.045)
	crossguard.mesh = cg_box
	var gold_mat := StandardMaterial3D.new()
	gold_mat.albedo_color = Color(0.78, 0.62, 0.30) # Antique fantasy gold
	gold_mat.metallic = 0.88
	gold_mat.roughness = 0.32
	crossguard.material_override = gold_mat
	crossguard.position = Vector3(0, 0.02, 0)
	greatsword_root.add_child(crossguard)

	# Central Glowing Purple/Amethyst Crystal Gem (Image 1 Focal Point)
	crystal_gem = MeshInstance3D.new()
	var gem_mesh := SphereMesh.new()
	gem_mesh.radius = 0.038
	gem_mesh.height = 0.076
	crystal_gem.mesh = gem_mesh
	var gem_mat := StandardMaterial3D.new()
	gem_mat.albedo_color = Color(0.72, 0.25, 1.0)
	gem_mat.metallic = 0.2
	gem_mat.roughness = 0.1
	gem_mat.emission_enabled = true
	gem_mat.emission = Color(0.78, 0.22, 1.0) # Violet aether glow
	gem_mat.emission_energy_multiplier = 4.5
	crystal_gem.material_override = gem_mat
	crystal_gem.position = Vector3(0, 0.02, 0.012)
	greatsword_root.add_child(crystal_gem)

	# Leather Wrapped Hilt
	var hilt := MeshInstance3D.new()
	var hilt_cyl := CylinderMesh.new()
	hilt_cyl.top_radius = 0.018
	hilt_cyl.bottom_radius = 0.018
	hilt_cyl.height = 0.22
	hilt.mesh = hilt_cyl
	var hilt_mat := StandardMaterial3D.new()
	hilt_mat.albedo_color = Color(0.22, 0.16, 0.12)
	hilt_mat.roughness = 0.8
	hilt.material_override = hilt_mat
	hilt.position = Vector3(0, -0.12, 0)
	greatsword_root.add_child(hilt)

	# Weighted Steel Pommel
	var pommel := MeshInstance3D.new()
	var p_sphere := SphereMesh.new()
	p_sphere.radius = 0.032
	p_sphere.height = 0.064
	pommel.mesh = p_sphere
	pommel.material_override = steel_mat
	pommel.position = Vector3(0, -0.24, 0)
	greatsword_root.add_child(pommel)

	# Position Greatsword held dynamically in right hand / combat stance
	greatsword_root.position = Vector3(0.42, 0.72, 0.22)
	greatsword_root.rotation_degrees = Vector3(15, -25, -45)

	# 2. THE ASTRAL ENERGY DAGGER (Left Hand Weapon - Radiant Cyan/Violet Blade)
	energy_dagger_root = Node3D.new()
	energy_dagger_root.name = "AstralEnergyDagger"
	visual_root.add_child(energy_dagger_root)

	# Dagger Hilt
	var d_hilt := MeshInstance3D.new()
	var dh_box := BoxMesh.new()
	dh_box.size = Vector3(0.032, 0.14, 0.032)
	d_hilt.mesh = dh_box
	d_hilt.material_override = gold_mat
	energy_dagger_root.add_child(d_hilt)

	# Glowing Ether Blade (Translucent glowing crystal plasma)
	energy_blade_mesh = MeshInstance3D.new()
	var eb_box := BoxMesh.new()
	eb_box.size = Vector3(0.045, 0.38, 0.012)
	energy_blade_mesh.mesh = eb_box
	var ether_mat := StandardMaterial3D.new()
	ether_mat.albedo_color = Color(0.25, 0.65, 1.0, 0.85)
	ether_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	ether_mat.emission_enabled = true
	ether_mat.emission = Color(0.35, 0.75, 1.0) # Celestial energy glow
	ether_mat.emission_energy_multiplier = 4.0
	energy_blade_mesh.material_override = ether_mat
	energy_blade_mesh.position = Vector3(0, 0.22, 0)
	energy_dagger_root.add_child(energy_blade_mesh)

	# Position Dagger held in left hand, pointing forward/angled
	energy_dagger_root.position = Vector3(-0.38, 0.88, -0.22)
	energy_dagger_root.rotation_degrees = Vector3(-65, 30, 20)

	# 3. SPIKED SILVER PAULDRON (Right Shoulder Fantasy Armor)
	spiked_pauldron = Node3D.new()
	spiked_pauldron.name = "SpikedPauldron"
	spiked_pauldron.position = Vector3(0.26, 1.28, 0.0)

	var p_base := MeshInstance3D.new()
	var pb_box := BoxMesh.new()
	pb_box.size = Vector3(0.14, 0.08, 0.16)
	p_base.mesh = pb_box
	p_base.material_override = steel_mat
	spiked_pauldron.add_child(p_base)

	# 3 Upward Curved Spikes (Matching Reference Image 1 silhouette)
	for i in range(3):
		var spike := MeshInstance3D.new()
		var sp_cone := CylinderMesh.new()
		sp_cone.top_radius = 0.002
		sp_cone.bottom_radius = 0.018
		sp_cone.height = 0.12 + (i * 0.04)
		spike.mesh = sp_cone
		spike.material_override = steel_mat
		spike.position = Vector3(0.04 + (i * 0.03), 0.08 + (i * 0.02), -0.05 + (i * 0.05))
		spike.rotation_degrees = Vector3(10, 0, -28 - (i * 8))
		spiked_pauldron.add_child(spike)
	visual_root.add_child(spiked_pauldron)

	# 4. FLOWING CRIMSON CAPE (Back Hips / Shoulders)
	crimson_cape = MeshInstance3D.new()
	crimson_cape.name = "CrimsonCape"
	var cape_mesh := QuadMesh.new()
	cape_mesh.size = Vector2(0.55, 0.95)
	crimson_cape.mesh = cape_mesh
	var cape_mat := StandardMaterial3D.new()
	cape_mat.albedo_color = Color(0.76, 0.16, 0.14) # Rich crimson red
	cape_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	cape_mat.roughness = 0.85
	crimson_cape.material_override = cape_mat
	crimson_cape.position = Vector3(0.0, 0.72, 0.18)
	crimson_cape.rotation_degrees = Vector3(18, 0, 0)
	visual_root.add_child(crimson_cape)

func _process(delta: float) -> void:
	anim_time += delta
	idle_hint_timer += delta
	combat_check_timer += delta
	if attack_cooldown > 0.0:
		attack_cooldown -= delta
	if shield_cooldown > 0.0:
		shield_cooldown -= delta

	# Discover player if not set
	if target_player == null and GameManager.player_ref is Node3D:
		target_player = GameManager.player_ref

	# Check combat status every 0.3s
	if combat_check_timer >= 0.3:
		combat_check_timer = 0.0
		_evaluate_combat_state()

	_handle_movement(delta)
	_animate_pose(delta)

	# Periodic hints during calm exploration
	if not in_combat_stance and idle_hint_timer >= 22.0:
		idle_hint_timer = 0.0
		show_temporary_speech(HINTS.pick_random(), 4.2)

func _evaluate_combat_state() -> void:
	# Scan for nearby active enemies
	var enemies := get_tree().get_nodes_in_group("enemies")
	var closest_dist: float = 999.0
	var closest_enemy: Node3D = null

	for e in enemies:
		if is_instance_valid(e) and e is CharacterBody3D:
			var d := global_position.distance_to(e.global_position)
			if d < 18.0 and d < closest_dist:
				closest_dist = d
				closest_enemy = e

	current_target_enemy = closest_enemy
	var was_combat := in_combat_stance
	in_combat_stance = (current_target_enemy != null)

	if in_combat_stance and not was_combat:
		show_temporary_speech(COMBAT_CALLOUTS.pick_random(), 3.5)
		if AudioManager:
			AudioManager.play_sound("ability_cast")

	# Dynamic Combat Actions
	if in_combat_stance and current_target_enemy and attack_cooldown <= 0.0:
		if closest_dist < 6.5:
			_perform_sword_strike(current_target_enemy)

	# Protective shield check
	if target_player and shield_cooldown <= 0.0:
		var kael_health: int = target_player.get("health") if "health" in target_player else 100
		if kael_health < 50:
			_cast_weather_shield()

func _perform_sword_strike(enemy: Node3D) -> void:
	attack_cooldown = 3.2
	show_temporary_speech("Haaah! Aether Strike!", 2.0)
	if AudioManager:
		AudioManager.play_sound("bullet_whiz")

	# Visual flash on purple crystal
	if crystal_gem and crystal_gem.material_override:
		var mat := crystal_gem.material_override as StandardMaterial3D
		mat.emission_energy_multiplier = 8.0
		var tw := create_tween()
		tw.tween_property(mat, "emission_energy_multiplier", 4.5, 0.4)

	# Deal damage to enemy
	if enemy.has_method("take_damage"):
		enemy.take_damage(55, "weather_slash")

func _cast_weather_shield() -> void:
	shield_cooldown = 18.0
	show_temporary_speech("Weather Aegis, shield him!", 3.0)
	if target_player.has_method("add_shield"):
		target_player.add_shield(35)
	if AudioManager:
		AudioManager.play_sound("ability_cast")

func _handle_movement(delta: float) -> void:
	if not target_player:
		return

	var player_basis := target_player.global_transform.basis
	var desired_slot: Vector3

	if in_combat_stance and current_target_enemy:
		# Flank position: slightly forward and right of player
		desired_slot = target_player.global_position + (player_basis.x * 2.2) - (player_basis.z * 0.8)
	else:
		# Exploration follow slot: slightly behind right shoulder
		desired_slot = target_player.global_position + (player_basis.x * 1.8) + (player_basis.z * 1.4)

	desired_slot.y = target_player.global_position.y + float_height + sin(anim_time * 2.4) * 0.12

	# Smooth interpolation
	global_position = global_position.lerp(desired_slot, delta * follow_speed)

	# Face towards combat target or face player direction
	var look_target: Vector3
	if in_combat_stance and current_target_enemy:
		look_target = current_target_enemy.global_position
	else:
		look_target = target_player.global_position + (target_player.global_transform.basis.z * -5.0)

	look_target.y = global_position.y
	if global_position.distance_squared_to(look_target) > 0.05:
		var target_angle := atan2(-(look_target.x - global_position.x), -(look_target.z - global_position.z))
		rotation.y = lerp_angle(rotation.y, target_angle, delta * 8.0)

func _animate_pose(delta: float) -> void:
	# Subtle cape fluttering
	if crimson_cape:
		crimson_cape.rotation_degrees.x = 18.0 + sin(anim_time * 4.0) * 8.0
		crimson_cape.rotation_degrees.y = sin(anim_time * 3.0) * 4.0

	# Energy dagger pulse
	if energy_blade_mesh and energy_blade_mesh.material_override:
		var mat := energy_blade_mesh.material_override as StandardMaterial3D
		mat.emission_energy_multiplier = 4.0 + sin(anim_time * 6.0) * 1.2

	# Skeletal Pose matching Reference Image 1
	if skeleton:
		if in_combat_stance:
			# Combat Stance (Image 1):
			# Right arm lower holding Greatsword ready to swing
			var r_combat_arm := Quaternion.from_euler(Vector3(0.35, -0.4, 0.75 + sin(anim_time * 3.0) * 0.05))
			# Left arm angled with energy dagger ready to parry
			var l_combat_arm := Quaternion.from_euler(Vector3(-0.65, 0.45, -0.85))
			var elbow_combat := Quaternion.from_euler(Vector3(0.55, 0.0, 0.0))
			var head_focus := Quaternion.from_euler(Vector3(0.12, 0.0, 0.0))

			_set_bone_rot(b_r_upper_arm, r_combat_arm)
			_set_bone_rot(b_r_lower_arm, elbow_combat)
			_set_bone_rot(b_l_upper_arm, l_combat_arm)
			_set_bone_rot(b_l_lower_arm, elbow_combat)
			_set_bone_rot(b_head, head_focus)
		else:
			# Gentle companion floating pose
			var float_sway: float = sin(anim_time * 2.2) * 0.05
			var arm_l := Quaternion.from_euler(Vector3(0.1, 0.0, -1.15 - float_sway))
			var arm_r := Quaternion.from_euler(Vector3(0.1, 0.0, 1.15 + float_sway))
			var elbow := Quaternion.from_euler(Vector3(0.2, 0.0, 0.0))
			var head_tilt := Quaternion.from_euler(Vector3(0.05, sin(anim_time * 1.6) * 0.08, 0.0))

			_set_bone_rot(b_l_upper_arm, arm_l)
			_set_bone_rot(b_r_upper_arm, arm_r)
			_set_bone_rot(b_l_lower_arm, elbow)
			_set_bone_rot(b_r_lower_arm, elbow)
			_set_bone_rot(b_head, head_tilt)

func _set_bone_rot(bone_id: int, rot: Quaternion) -> void:
	if skeleton and bone_id >= 0:
		skeleton.set_bone_pose_rotation(bone_id, rot)

func show_temporary_speech(text: String, duration: float = 4.0) -> void:
	if not speech_bubble:
		return
	speech_bubble.text = "⚔️ " + text if in_combat_stance else "💬 " + text
	speech_bubble.visible = true
	var tw := create_tween()
	tw.tween_property(speech_bubble, "modulate:a", 1.0, 0.2)
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(speech_bubble):
		var tw_out := create_tween()
		tw_out.tween_property(speech_bubble, "modulate:a", 0.0, 0.3)
		await tw_out.finished
		speech_bubble.visible = false
