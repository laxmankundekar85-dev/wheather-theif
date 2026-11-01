## HitscanWeapon.gd
## Tactical Hitscan Firearm implementation (Skybreaker Assault Rifle).
## Features raycast hit detection, Valorant-style spread perturbation, headshot crits,
## bullet tracers, muzzle flash particles, and weather elemental infusion.
extends "res://scripts/weapons/weapon_base.gd"
class_name HitscanWeapon

@onready var muzzle_point: Marker3D = $Model/MuzzlePoint
@onready var muzzle_flash: CPUParticles3D = $Model/MuzzlePoint/MuzzleFlash
@onready var weapon_model: Node3D = $Model

const BulletTrailClass = preload("res://scripts/combat/bullet_trail.gd")

func _ready() -> void:
	super._ready()
	if muzzle_flash:
		muzzle_flash.emitting = false

func _execute_shot(camera: Camera3D, origin_node: Node3D = null) -> void:
	if not camera:
		return

	# Audio
	AudioManager.play_sound("rifle_shoot")

	# Notify global combat perception (enemies hear this gunshot)
	var muzzle_pos: Vector3 = muzzle_point.global_position if muzzle_point else (global_position + Vector3(0, 1.2, -0.6))
	EventBus3D.notify_combat_noise(muzzle_pos, "gunshot")

	# Trigger muzzle flash
	if muzzle_flash:
		muzzle_flash.restart()
		muzzle_flash.emitting = true

	# Weapon model recoil kick tween
	if weapon_model:
		var tw := create_tween()
		tw.tween_property(weapon_model, "position:z", 0.08, 0.04)
		tw.tween_property(weapon_model, "position:z", 0.0, 0.08)

	# Raycast from Camera screen center (Crosshair)
	var viewport := camera.get_viewport()
	var screen_center := viewport.get_visible_rect().size * 0.5

	var from := camera.project_ray_origin(screen_center)
	var base_dir := camera.project_ray_normal(screen_center)
	var spread_rad := get_current_spread_rad()
	var cam_right := camera.global_transform.basis.x
	var cam_up := camera.global_transform.basis.y
	var space_state := camera.get_world_3d().direct_space_state

	var count: int = maxi(1, pellets_per_shot)
	var per_pellet_dmg: int = maxi(1, int(float(base_damage) / float(count)))

	for p in range(count):
		# Apply Spread cone (radians)
		var spread_offset := Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized() * randf_range(0.0, spread_rad)
		var shoot_dir := (base_dir + cam_right * spread_offset.x + cam_up * spread_offset.y).normalized()
		var to := from + shoot_dir * effective_range

		# Query mask: Layer 1 (Environment), Layer 3 (Enemies), Layer 5 (Targets), Layer 7 (Cover) -> 1 + 4 + 16 + 64 = 85
		var query := PhysicsRayQueryParameters3D.create(from, to, 85)
		query.collide_with_areas = true
		query.collide_with_bodies = true
		if origin_node:
			query.exclude = [origin_node.get_rid()]

		var result := space_state.intersect_ray(query)
		var hit_pos: Vector3 = to
		var hit_normal: Vector3 = -shoot_dir
		var did_hit := false
		var hit_collider: Object = null

		if result.size() > 0:
			hit_pos = result["position"]
			hit_normal = result["normal"]
			hit_collider = result["collider"]
			did_hit = true

		# Spawn visual tracer from muzzle to hit position
		_spawn_tracer(muzzle_pos, hit_pos)

		# Handle impact
		if did_hit and hit_collider != null:
			_process_hit_pellet(hit_collider, hit_pos, hit_normal, result, per_pellet_dmg)
		else:
			_spawn_dust_spark(hit_pos, hit_normal)

func _process_hit_pellet(collider: Object, hit_pos: Vector3, hit_normal: Vector3, hit_data: Dictionary, dmg_amount: int) -> void:
	var target_node: Node = collider as Node
	var is_headshot := false

	if "head" in target_node.name.to_lower():
		is_headshot = true
	elif hit_data.has("shape"):
		var owner_id = target_node.shape_find_owner(hit_data["shape"])
		var shape_owner = target_node.shape_owner_get_owner(owner_id)
		if shape_owner and "head" in shape_owner.name.to_lower():
			is_headshot = true

	var receiver: Node = target_node
	while receiver and not receiver.has_method("take_damage") and receiver.get_parent():
		receiver = receiver.get_parent()

	if receiver and receiver.has_method("take_damage"):
		var dmg: int = dmg_amount
		if is_headshot:
			dmg = int(dmg * headshot_multiplier)

		var element := "physical"
		if weather_infusion != "none":
			element = weather_infusion
			dmg += 10

		receiver.take_damage(dmg, hit_pos, is_headshot)
		emit_signal("hit_registered", is_headshot, dmg)

		if is_headshot:
			AudioManager.play_sound("headshot_ding")
		else:
			AudioManager.play_sound("hitmarker")

		CombatManager.spawn_damage_number(hit_pos, dmg, element, is_headshot)
		_spawn_blood_spark(hit_pos, hit_normal)
	else:
		# Environmental or Cover impact
		AudioManager.play_sound("bullet_impact")
		_spawn_dust_spark(hit_pos, hit_normal)

func _spawn_tracer(start: Vector3, end: Vector3) -> void:
	var trail = BulletTrailClass.new()
	var tree := get_tree()
	if tree and tree.current_scene:
		tree.current_scene.add_child(trail)
		var tracer_color := Color(1.0, 0.85, 0.4, 0.95)
		if weather_infusion == "rain":
			tracer_color = Color(0.2, 0.85, 1.0, 0.95)
		elif weather_infusion == "thunder":
			tracer_color = Color(0.85, 0.4, 1.0, 0.95)
		elif weather_infusion == "snow":
			tracer_color = Color(0.65, 0.95, 1.0, 0.95)
		trail.init(start, end, tracer_color)

func _spawn_dust_spark(pos: Vector3, normal: Vector3) -> void:
	var tree := get_tree()
	if not tree or not tree.current_scene:
		return

	var parts := CPUParticles3D.new()
	parts.emitting = true
	parts.one_shot = true
	parts.amount = 12
	parts.lifetime = 0.35
	parts.explosiveness = 0.95
	parts.direction = normal
	parts.spread = 45.0
	parts.initial_velocity_min = 4.0
	parts.initial_velocity_max = 7.0

	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.albedo_color = Color(1.0, 0.7, 0.25)
	var bmesh := BoxMesh.new()
	bmesh.size = Vector3(0.04, 0.04, 0.04)
	bmesh.material = smat
	parts.mesh = bmesh

	tree.current_scene.add_child(parts)
	parts.global_position = pos + normal * 0.05
	# Auto remove after lifetime
	parts.finished.connect(parts.queue_free)

func _spawn_blood_spark(pos: Vector3, normal: Vector3) -> void:
	var tree := get_tree()
	if not tree or not tree.current_scene:
		return

	var parts := CPUParticles3D.new()
	parts.emitting = true
	parts.one_shot = true
	parts.amount = 16
	parts.lifetime = 0.4
	parts.explosiveness = 0.9
	parts.direction = normal
	parts.spread = 50.0
	parts.initial_velocity_min = 3.0
	parts.initial_velocity_max = 6.0

	var smat := StandardMaterial3D.new()
	smat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	smat.albedo_color = Color(0.7, 0.1, 0.9, 0.9) # Dark shadow ether splash
	if weather_infusion == "rain":
		smat.albedo_color = Color(0.2, 0.8, 1.0, 0.9)
	var bmesh := BoxMesh.new()
	bmesh.size = Vector3(0.06, 0.06, 0.06)
	bmesh.material = smat
	parts.mesh = bmesh

	tree.current_scene.add_child(parts)
	parts.global_position = pos + normal * 0.05
	parts.finished.connect(parts.queue_free)
