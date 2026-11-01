## EnemyController.gd
## Master controller for AAA-quality realistic human combatants in Weather Thief.
## Manages 5 distinct classes:
## 1. Vanguard Trooper (Standard Soldier)
## 2. Vanguard Enforcer (Heavy Defender)
## 3. Vanguard Infiltrator (Scout / Flanker)
## 4. Vanguard Marksman (Sniper)
## 5. Vanguard Overseer (Elite Squad Commander)
##
## Configures complete humanoid skeletal mesh, tactical textures, military gear,
## 3D tactical weapons (matching SCAR-L reference), backpacks, and coordinates AI systems.
extends CharacterBody3D
class_name EnemyController

enum EnemyClass {
	TROOPER,
	ENFORCER,
	INFILTRATOR,
	MARKSMAN,
	OVERSEER
}

@export var enemy_class: EnemyClass = EnemyClass.TROOPER
@export var patrol_route_name: String = ""

signal enemy_defeated(enemy_node: Node)

# Explicit preloads for loose runtime execution
const EnemyHealthScript = preload("res://scripts/enemies/enemy_health.gd")
const EnemyPerceptionScript = preload("res://scripts/enemies/enemy_perception.gd")
const EnemyCombatScript = preload("res://scripts/enemies/enemy_combat.gd")
const EnemyCoverSystemScript = preload("res://scripts/enemies/enemy_cover_system.gd")
const EnemyAnimationControllerScript = preload("res://scripts/enemies/enemy_animation_controller.gd")
const EnemyAIScript = preload("res://scripts/enemies/enemy_ai.gd")
const EnemyAudioScript = preload("res://scripts/enemies/enemy_audio.gd")

# Internal system components
var health: Node = null
var perception: Node = null
var combat: Node = null
var cover_system: Node = null
var anim_ctrl: Node = null
var ai_brain: Node = null
var audio_comp: Node = null

# Mesh and attachments
var visual_root: Node3D
var character_model: Node3D
var skeleton: Skeleton3D
var weapon_mount: Node3D
var weapon_mesh: Node3D
var backpack_mesh: Node3D
var vest_mesh: Node3D
var muzzle_point: Marker3D

# Static texture cache
static var _tex_face: Texture2D = null
static var _tex_body: Texture2D = null
static var _tex_hair: Texture2D = null

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4 # Enemies layer (bit 3)
	collision_mask = 1 | 2 | 4 # World, Player, Enemies

	_ensure_components()
	if health:
		health.died.connect(func(_dir): emit_signal("enemy_defeated", self))

	_build_visuals()
	_configure_class_attributes()

func _ensure_components() -> void:
	# 1. Health
	health = get_node_or_null("EnemyHealth")
	if not health:
		health = EnemyHealthScript.new()
		health.name = "EnemyHealth"
		add_child(health)

	# 2. Audio
	audio_comp = get_node_or_null("EnemyAudio")
	if not audio_comp:
		audio_comp = EnemyAudioScript.new()
		audio_comp.name = "EnemyAudio"
		add_child(audio_comp)

	# 3. Perception
	perception = get_node_or_null("EnemyPerception")
	if not perception:
		perception = EnemyPerceptionScript.new()
		perception.name = "EnemyPerception"
		add_child(perception)

	# 4. Combat
	combat = get_node_or_null("EnemyCombat")
	if not combat:
		combat = EnemyCombatScript.new()
		combat.name = "EnemyCombat"
		add_child(combat)

	# 5. Cover System
	cover_system = get_node_or_null("EnemyCoverSystem")
	if not cover_system:
		cover_system = EnemyCoverSystemScript.new()
		cover_system.name = "EnemyCoverSystem"
		add_child(cover_system)

	# 6. Animation Controller
	anim_ctrl = get_node_or_null("EnemyAnimationController")
	if not anim_ctrl:
		anim_ctrl = EnemyAnimationControllerScript.new()
		anim_ctrl.name = "EnemyAnimationController"
		add_child(anim_ctrl)

	# 7. AI Brain
	ai_brain = get_node_or_null("EnemyAI")
	if not ai_brain:
		ai_brain = EnemyAIScript.new()
		ai_brain.name = "EnemyAI"
		add_child(ai_brain)

func _load_humanoid_textures() -> void:
	if _tex_face == null:
		if ResourceLoader.exists("res://assets/characters/kael_avatar_c_M00_000_00_Face_00.png"):
			_tex_face = load("res://assets/characters/kael_avatar_c_M00_000_00_Face_00.png")
		else:
			var img_face := Image.load_from_file("res://assets/characters/kael_avatar_c_M00_000_00_Face_00.png")
			if img_face and not img_face.is_empty():
				_tex_face = ImageTexture.create_from_image(img_face)

	if _tex_body == null:
		if ResourceLoader.exists("res://assets/characters/kael_avatar_c_M00_000_00_Body_00.png"):
			_tex_body = load("res://assets/characters/kael_avatar_c_M00_000_00_Body_00.png")
		else:
			var img_body := Image.load_from_file("res://assets/characters/kael_avatar_c_M00_000_00_Body_00.png")
			if img_body and not img_body.is_empty():
				_tex_body = ImageTexture.create_from_image(img_body)

	if _tex_hair == null:
		if ResourceLoader.exists("res://assets/characters/kael_avatar_c_F00_000_Hair_00.png"):
			_tex_hair = load("res://assets/characters/kael_avatar_c_F00_000_Hair_00.png")
		else:
			var img_hair := Image.load_from_file("res://assets/characters/kael_avatar_c_F00_000_Hair_00.png")
			if img_hair and not img_hair.is_empty():
				_tex_hair = ImageTexture.create_from_image(img_hair)

func _build_visuals() -> void:
	visual_root = Node3D.new()
	visual_root.name = "VisualRoot"
	add_child(visual_root)

	# Load character humanoid rig
	var avatar_scene: PackedScene = load("res://assets/characters/kael_avatar_c.glb")
	if avatar_scene:
		character_model = avatar_scene.instantiate()
		visual_root.add_child(character_model)

	_load_humanoid_textures()
	_apply_humanoid_materials()

	# Create collision shape if missing
	var col := get_node_or_null("CollisionShape3D") as CollisionShape3D
	if not col:
		col = CollisionShape3D.new()
		col.name = "CollisionShape3D"
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.38
		capsule.height = 1.78
		col.shape = capsule
		col.position = Vector3(0, 0.89, 0)
		add_child(col)

	# Find Skeleton3D
	skeleton = _find_skeleton(visual_root)

	# Attach Tactical Weapon and Gear
	_build_tactical_gear()
	_build_class_weapon()

func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node as Skeleton3D
	for child in node.get_children():
		var found := _find_skeleton(child)
		if found:
			return found
	return null

func _apply_humanoid_materials() -> void:
	if not character_model:
		return

	# Material Palette based on class
	var uniform_color := Color(0.25, 0.28, 0.32) # Urban Slate
	var hair_tint := Color(0.18, 0.16, 0.15)
	var accent_color := Color(0.85, 0.45, 0.15) # Vanguard Amber

	match enemy_class:
		EnemyClass.TROOPER:
			uniform_color = Color(0.24, 0.27, 0.30)
			hair_tint = Color(0.15, 0.15, 0.15)
			accent_color = Color(0.9, 0.5, 0.1)
		EnemyClass.ENFORCER:
			uniform_color = Color(0.16, 0.18, 0.20) # Heavy charcoal
			hair_tint = Color(0.12, 0.12, 0.12)
			accent_color = Color(0.9, 0.2, 0.15) # Danger red
		EnemyClass.INFILTRATOR:
			uniform_color = Color(0.12, 0.16, 0.20) # Shadow navy
			hair_tint = Color(0.25, 0.28, 0.32)
			accent_color = Color(0.1, 0.8, 0.7) # Cyan recon
		EnemyClass.MARKSMAN:
			uniform_color = Color(0.22, 0.25, 0.20) # Forest olive / ghillie
			hair_tint = Color(0.35, 0.28, 0.22)
			accent_color = Color(0.3, 0.8, 0.3) # Scope green
		EnemyClass.OVERSEER:
			uniform_color = Color(0.15, 0.12, 0.18) # Commander midnight
			hair_tint = Color(0.45, 0.45, 0.48) # Silver hair
			accent_color = Color(0.95, 0.82, 0.25) # Gold insignia

	for child in character_model.get_children():
		if child is Skeleton3D:
			for mesh_child in child.get_children():
				if mesh_child is MeshInstance3D:
					_style_mesh(mesh_child, uniform_color, hair_tint, accent_color)
		elif child is MeshInstance3D:
			_style_mesh(child, uniform_color, hair_tint, accent_color)

func _style_mesh(mesh_node: MeshInstance3D, uniform_color: Color, hair_tint: Color, accent_color: Color) -> void:
	var m_name := mesh_node.name.to_lower()

	if "face" in m_name:
		var face_mat := StandardMaterial3D.new()
		if _tex_face:
			face_mat.albedo_texture = _tex_face
		else:
			face_mat.albedo_color = Color(0.92, 0.78, 0.70) # Realistic human skin tone
		face_mat.roughness = 0.55
		face_mat.metallic_specular = 0.35
		mesh_node.material_override = face_mat

	elif "body" in m_name:
		var body_mat := StandardMaterial3D.new()
		if _tex_body:
			body_mat.albedo_texture = _tex_body
			body_mat.albedo_color = uniform_color * 1.35
		else:
			body_mat.albedo_color = uniform_color
		body_mat.roughness = 0.65
		body_mat.metallic_specular = 0.25
		mesh_node.material_override = body_mat

	elif "hair" in m_name:
		var hair_mat := StandardMaterial3D.new()
		if _tex_hair:
			hair_mat.albedo_texture = _tex_hair
			hair_mat.albedo_color = hair_tint * 1.5
		else:
			hair_mat.albedo_color = hair_tint
		hair_mat.roughness = 0.4
		hair_mat.metallic_specular = 0.45
		hair_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mesh_node.material_override = hair_mat

## Adds military tactical equipment matching Reference Image 2:
## Tactical backpack with antenna/radio on back, utility pouches on tactical belt.
func _build_tactical_gear() -> void:
	# 1. Tactical Backpack (Urban Military Radio Pack on soldier's back at +Z)
	backpack_mesh = Node3D.new()
	backpack_mesh.name = "TacticalBackpack"

	var pack_body := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.28, 0.38, 0.14)
	pack_body.mesh = box
	var pack_mat := StandardMaterial3D.new()
	pack_mat.albedo_color = Color(0.16, 0.18, 0.16) # Tactical Olive Drab
	pack_mat.roughness = 0.75
	pack_body.material_override = pack_mat
	backpack_mesh.add_child(pack_body)

	# Radio Antenna
	var antenna := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.006
	cyl.bottom_radius = 0.010
	cyl.height = 0.42
	antenna.mesh = cyl
	antenna.position = Vector3(0.10, 0.32, 0.0)
	backpack_mesh.add_child(antenna)

	# Position on soldier's upper back (+Z direction)
	backpack_mesh.position = Vector3(0, 1.22, 0.15)
	visual_root.add_child(backpack_mesh)

	# 2. Tactical Side Utility / Ammo Pouches on belt
	var pouch_mat := StandardMaterial3D.new()
	pouch_mat.albedo_color = Color(0.12, 0.13, 0.14)
	pouch_mat.roughness = 0.8

	var left_pouch := MeshInstance3D.new()
	var lp_box := BoxMesh.new()
	lp_box.size = Vector3(0.08, 0.12, 0.12)
	left_pouch.mesh = lp_box
	left_pouch.position = Vector3(-0.21, 0.94, -0.02)
	left_pouch.material_override = pouch_mat
	visual_root.add_child(left_pouch)

	var right_pouch := MeshInstance3D.new()
	var rp_box := BoxMesh.new()
	rp_box.size = Vector3(0.08, 0.12, 0.12)
	right_pouch.mesh = rp_box
	right_pouch.position = Vector3(0.21, 0.94, -0.02)
	right_pouch.material_override = pouch_mat
	visual_root.add_child(right_pouch)

## Stylized tactical weapon matching Reference Image 3 (SCAR-L rifle)
func _build_class_weapon() -> void:
	weapon_mount = Node3D.new()
	weapon_mount.name = "WeaponMount"
	visual_root.add_child(weapon_mount)
	# Position in front of torso where hands hold it, pointing forward (-Z)
	weapon_mount.position = Vector3(0.20, 1.05, -0.28)
	weapon_mount.rotation_degrees = Vector3(0, 0, 0)

	weapon_mesh = Node3D.new()
	weapon_mesh.name = "TacticalWeapon"
	weapon_mount.add_child(weapon_mesh)

	# Palette for stylized weapon (Reference 3: Tan upper receiver, dark steel lower and barrel)
	var receiver_mat := StandardMaterial3D.new()
	receiver_mat.albedo_color = Color(0.72, 0.62, 0.45) # Desert tan SCAR receiver
	receiver_mat.roughness = 0.4
	receiver_mat.metallic = 0.2

	var dark_steel_mat := StandardMaterial3D.new()
	dark_steel_mat.albedo_color = Color(0.18, 0.20, 0.22)
	dark_steel_mat.roughness = 0.35
	dark_steel_mat.metallic = 0.85

	match enemy_class:
		EnemyClass.TROOPER:
			_build_scar_assault_rifle(receiver_mat, dark_steel_mat)
		EnemyClass.ENFORCER:
			_build_heavy_lmg(dark_steel_mat)
		EnemyClass.INFILTRATOR:
			_build_tactical_smg(receiver_mat, dark_steel_mat)
		EnemyClass.MARKSMAN:
			_build_sniper_rifle(dark_steel_mat)
		EnemyClass.OVERSEER:
			_build_energy_carbine()

	# Muzzle Point pointing forward along -Z
	muzzle_point = Marker3D.new()
	muzzle_point.name = "MuzzlePoint"
	muzzle_point.position = Vector3(0, 0.01, -0.62)
	weapon_mesh.add_child(muzzle_point)

	if combat:
		combat.muzzle_point = muzzle_point
		combat.weapon_mesh = weapon_mesh

func _build_scar_assault_rifle(receiver_mat: Material, steel_mat: Material) -> void:
	# Main Upper Receiver (Tan)
	var upper := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.06, 0.09, 0.40)
	upper.mesh = b
	upper.material_override = receiver_mat
	weapon_mesh.add_child(upper)

	# Lower Receiver & Pistol Grip (Dark Steel, angled back towards +Z)
	var grip := MeshInstance3D.new()
	var gb := BoxMesh.new()
	gb.size = Vector3(0.045, 0.12, 0.06)
	grip.mesh = gb
	grip.position = Vector3(0, -0.09, 0.08)
	grip.rotation_degrees = Vector3(18, 0, 0)
	grip.material_override = steel_mat
	weapon_mesh.add_child(grip)

	# Magazine (Curved 30-round mag, angled forward towards -Z)
	var mag := MeshInstance3D.new()
	var mb := BoxMesh.new()
	mb.size = Vector3(0.035, 0.16, 0.07)
	mag.mesh = mb
	mag.position = Vector3(0, -0.11, -0.06)
	mag.rotation_degrees = Vector3(-12, 0, 0)
	mag.material_override = steel_mat
	weapon_mesh.add_child(mag)

	# Picatinny Top Rail
	var rail := MeshInstance3D.new()
	var rb := BoxMesh.new()
	rb.size = Vector3(0.04, 0.02, 0.38)
	rail.mesh = rb
	rail.position = Vector3(0, 0.055, 0.0)
	rail.material_override = steel_mat
	weapon_mesh.add_child(rail)

	# Front Barrel (pointing forward towards -Z)
	var barrel := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.016
	cyl.bottom_radius = 0.018
	cyl.height = 0.30
	barrel.mesh = cyl
	barrel.rotation_degrees = Vector3(90, 0, 0)
	barrel.position = Vector3(0, 0.01, -0.32)
	barrel.material_override = steel_mat
	weapon_mesh.add_child(barrel)

	# Flash Hider / Muzzle Brake (Reference 3)
	var brake := MeshInstance3D.new()
	var bcyl := CylinderMesh.new()
	bcyl.top_radius = 0.024
	bcyl.bottom_radius = 0.022
	bcyl.height = 0.08
	brake.mesh = bcyl
	brake.rotation_degrees = Vector3(90, 0, 0)
	brake.position = Vector3(0, 0.01, -0.50)
	brake.material_override = steel_mat
	weapon_mesh.add_child(brake)

	# Foldable Stock (extending back towards +Z)
	var stock := MeshInstance3D.new()
	var sb := BoxMesh.new()
	sb.size = Vector3(0.05, 0.10, 0.22)
	stock.mesh = sb
	stock.position = Vector3(0, 0.01, 0.28)
	stock.material_override = receiver_mat
	weapon_mesh.add_child(stock)

func _build_heavy_lmg(steel_mat: Material) -> void:
	var body := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.10, 0.12, 0.52)
	body.mesh = b
	body.material_override = steel_mat
	weapon_mesh.add_child(body)

	# Heavy ammo drum
	var drum := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.09
	cyl.bottom_radius = 0.09
	cyl.height = 0.14
	drum.mesh = cyl
	drum.rotation_degrees = Vector3(0, 0, 90)
	drum.position = Vector3(-0.04, -0.08, -0.02)
	drum.material_override = steel_mat
	weapon_mesh.add_child(drum)

	# Heavy barrel forward towards -Z
	var barrel := MeshInstance3D.new()
	var bcyl := CylinderMesh.new()
	bcyl.top_radius = 0.025
	bcyl.bottom_radius = 0.028
	bcyl.height = 0.40
	barrel.mesh = bcyl
	barrel.rotation_degrees = Vector3(90, 0, 0)
	barrel.position = Vector3(0, 0.02, -0.44)
	barrel.material_override = steel_mat
	weapon_mesh.add_child(barrel)

func _build_tactical_smg(receiver_mat: Material, steel_mat: Material) -> void:
	var body := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.05, 0.08, 0.28)
	body.mesh = b
	body.material_override = steel_mat
	weapon_mesh.add_child(body)

	var grip := MeshInstance3D.new()
	var gb := BoxMesh.new()
	gb.size = Vector3(0.04, 0.11, 0.05)
	grip.mesh = gb
	grip.position = Vector3(0, -0.08, 0.06)
	grip.material_override = receiver_mat
	weapon_mesh.add_child(grip)

	var barrel := MeshInstance3D.new()
	var bcyl := CylinderMesh.new()
	bcyl.top_radius = 0.015
	bcyl.bottom_radius = 0.015
	bcyl.height = 0.16
	barrel.mesh = bcyl
	barrel.rotation_degrees = Vector3(90, 0, 0)
	barrel.position = Vector3(0, 0.01, -0.22)
	barrel.material_override = steel_mat
	weapon_mesh.add_child(barrel)

func _build_sniper_rifle(steel_mat: Material) -> void:
	var body := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.06, 0.08, 0.56)
	body.mesh = b
	body.material_override = steel_mat
	weapon_mesh.add_child(body)

	# Long Precision Barrel forward towards -Z
	var barrel := MeshInstance3D.new()
	var bcyl := CylinderMesh.new()
	bcyl.top_radius = 0.014
	bcyl.bottom_radius = 0.018
	bcyl.height = 0.62
	barrel.mesh = bcyl
	barrel.rotation_degrees = Vector3(90, 0, 0)
	barrel.position = Vector3(0, 0.01, -0.56)
	barrel.material_override = steel_mat
	weapon_mesh.add_child(barrel)

	# Scope
	var scope := MeshInstance3D.new()
	var scyl := CylinderMesh.new()
	scyl.top_radius = 0.024
	scyl.bottom_radius = 0.022
	scyl.height = 0.24
	scope.mesh = scyl
	scope.rotation_degrees = Vector3(90, 0, 0)
	scope.position = Vector3(0, 0.075, -0.08)
	var scope_mat := StandardMaterial3D.new()
	scope_mat.albedo_color = Color(0.1, 0.1, 0.12)
	scope_mat.metallic = 0.9
	scope.material_override = scope_mat
	weapon_mesh.add_child(scope)

func _build_energy_carbine() -> void:
	var body := MeshInstance3D.new()
	var b := BoxMesh.new()
	b.size = Vector3(0.06, 0.09, 0.38)
	body.mesh = b
	var b_mat := StandardMaterial3D.new()
	b_mat.albedo_color = Color(0.12, 0.12, 0.15)
	b_mat.metallic = 0.9
	body.material_override = b_mat
	weapon_mesh.add_child(body)

	# Glowing Energy Coils
	var coil := MeshInstance3D.new()
	var cb := BoxMesh.new()
	cb.size = Vector3(0.045, 0.04, 0.22)
	coil.mesh = cb
	coil.position = Vector3(0, 0.02, -0.06)
	var em_mat := StandardMaterial3D.new()
	em_mat.albedo_color = Color(0.9, 0.3, 0.1)
	em_mat.emission_enabled = true
	em_mat.emission = Color(1.0, 0.4, 0.1)
	em_mat.emission_energy_multiplier = 3.0
	coil.material_override = em_mat
	weapon_mesh.add_child(coil)

func _configure_class_attributes() -> void:
	match enemy_class:
		EnemyClass.TROOPER:
			health.setup(100, 25)
			combat.configure_class(EnemyCombatScript.WeaponType.ASSAULT_RIFLE)
			ai_brain.patrol_speed = 1.8
			ai_brain.combat_speed = 3.8
			ai_brain.flank_preference = 0.35

		EnemyClass.ENFORCER:
			health.setup(180, 75)
			combat.configure_class(EnemyCombatScript.WeaponType.HEAVY_LMG)
			ai_brain.patrol_speed = 1.4
			ai_brain.combat_speed = 3.0
			ai_brain.sprint_speed = 4.2
			ai_brain.flank_preference = 0.15 # Holds ground and suppresses

		EnemyClass.INFILTRATOR:
			health.setup(85, 20)
			combat.configure_class(EnemyCombatScript.WeaponType.TACTICAL_SMG)
			ai_brain.patrol_speed = 2.4
			ai_brain.combat_speed = 4.6
			ai_brain.sprint_speed = 6.2
			ai_brain.flank_preference = 0.75 # Aggressively flanks

		EnemyClass.MARKSMAN:
			health.setup(75, 20)
			combat.configure_class(EnemyCombatScript.WeaponType.SNIPER_RIFLE)
			ai_brain.patrol_speed = 1.6
			ai_brain.combat_speed = 3.4
			ai_brain.flank_preference = 0.2 # Holds elevated vantage

		EnemyClass.OVERSEER:
			health.setup(220, 100)
			combat.configure_class(EnemyCombatScript.WeaponType.ENERGY_CARBINE)
			ai_brain.patrol_speed = 2.0
			ai_brain.combat_speed = 4.0
			ai_brain.flank_preference = 0.45
			# Add aura light
			var aura := OmniLight3D.new()
			aura.light_color = Color(1.0, 0.4, 0.15)
			aura.light_energy = 1.2
			aura.omni_range = 6.0
			aura.position = Vector3(0, 1.5, 0)
			visual_root.add_child(aura)

## Damage interface matching Player's weapon raycast: takes damage with critical hit detection
func take_damage(amount: int, hit_origin: Variant = Vector3.ZERO, is_crit: bool = false) -> int:
	var is_headshot := is_crit
	var origin_vec := Vector3.ZERO
	if hit_origin is Vector3:
		origin_vec = hit_origin
		var rel_y := origin_vec.y - global_position.y
		if rel_y > 1.35:
			is_headshot = true

	var dealt: int = health.take_damage(amount, is_headshot, origin_vec)
	if is_headshot:
		CombatManager.spawn_floating_text(global_position + Vector3(0, 1.8, 0), "CRITICAL! " + str(dealt), Color.GOLD)
	else:
		CombatManager.spawn_floating_text(global_position + Vector3(0, 1.5, 0), str(dealt), Color.WHITE)

	return dealt

func is_alive() -> bool:
	return health.is_alive()
