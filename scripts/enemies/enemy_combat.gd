## EnemyCombat.gd
## Tactical weapon handling, firing loops, weapon recoil, spread, and reloading.
## Supports assault rifles, LMGs, SMGs, sniper rifles, and carbines.
extends Node
class_name EnemyCombat

enum WeaponType {
	ASSAULT_RIFLE,
	HEAVY_LMG,
	TACTICAL_SMG,
	SNIPER_RIFLE,
	ENERGY_CARBINE
}

@export var weapon_type: WeaponType = WeaponType.ASSAULT_RIFLE
@export var damage: int = 16
@export var burst_count: int = 3
@export var burst_fire_delay: float = 0.12
@export var burst_cooldown: float = 1.3
@export var max_ammo: int = 30
@export var reload_duration: float = 2.2
@export var spread_angle_deg: float = 2.5
@export var effective_range: float = 32.0

var current_ammo: int = 30
var is_reloading: bool = false
var reload_timer: float = 0.0
var burst_timer: float = 0.0
var shots_in_current_burst: int = 0
var is_bursting: bool = false
var burst_shot_delay_timer: float = 0.0

# Visual attachment nodes
var muzzle_point: Node3D = null
var weapon_mesh: Node3D = null

signal weapon_fired(origin: Vector3, direction: Vector3, damage: int)
signal reload_started()
signal reload_finished()
signal muzzle_flashed()

func configure_class(type: WeaponType) -> void:
	weapon_type = type
	match type:
		WeaponType.ASSAULT_RIFLE:
			damage = 16
			burst_count = 3
			burst_fire_delay = 0.13
			burst_cooldown = 1.2
			max_ammo = 30
			reload_duration = 2.1
			spread_angle_deg = 2.8
			effective_range = 30.0
		WeaponType.HEAVY_LMG:
			damage = 22
			burst_count = 8
			burst_fire_delay = 0.14
			burst_cooldown = 1.8
			max_ammo = 60
			reload_duration = 3.4
			spread_angle_deg = 4.5
			effective_range = 28.0
		WeaponType.TACTICAL_SMG:
			damage = 11
			burst_count = 5
			burst_fire_delay = 0.08
			burst_cooldown = 0.9
			max_ammo = 25
			reload_duration = 1.5
			spread_angle_deg = 5.2
			effective_range = 18.0
		WeaponType.SNIPER_RIFLE:
			damage = 68
			burst_count = 1
			burst_fire_delay = 0.1
			burst_cooldown = 2.2
			max_ammo = 5
			reload_duration = 2.8
			spread_angle_deg = 0.4
			effective_range = 45.0
		WeaponType.ENERGY_CARBINE:
			damage = 20
			burst_count = 4
			burst_fire_delay = 0.11
			burst_cooldown = 1.1
			max_ammo = 32
			reload_duration = 1.9
			spread_angle_deg = 1.8
			effective_range = 35.0

	current_ammo = max_ammo

func _process(delta: float) -> void:
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			finish_reload()
		return

	if burst_timer > 0.0:
		burst_timer = maxf(0.0, burst_timer - delta)

	if is_bursting:
		burst_shot_delay_timer -= delta
		if burst_shot_delay_timer <= 0.0:
			_execute_single_shot()
			shots_in_current_burst += 1
			if shots_in_current_burst >= burst_count or current_ammo <= 0:
				is_bursting = false
				burst_timer = burst_cooldown
				if current_ammo <= 0:
					start_reload()
			else:
				burst_shot_delay_timer = burst_fire_delay

func can_shoot() -> bool:
	return not is_reloading and not is_bursting and burst_timer <= 0.0 and current_ammo > 0

func trigger_fire(target_pos: Vector3) -> bool:
	if not can_shoot():
		if current_ammo <= 0 and not is_reloading:
			start_reload()
		return false

	is_bursting = true
	shots_in_current_burst = 0
	burst_shot_delay_timer = 0.0
	_current_target_pos = target_pos
	return true

var _current_target_pos: Vector3 = Vector3.ZERO

func start_reload() -> void:
	if is_reloading or current_ammo == max_ammo:
		return
	is_reloading = true
	reload_timer = reload_duration
	is_bursting = false
	emit_signal("reload_started")
	var audio = get_parent().get_node_or_null("EnemyAudio")
	if audio:
		audio.play_reloading_callout()

func finish_reload() -> void:
	is_reloading = false
	current_ammo = max_ammo
	emit_signal("reload_finished")

func _execute_single_shot() -> void:
	if current_ammo <= 0:
		start_reload()
		return

	current_ammo -= 1

	var enemy_body: CharacterBody3D = get_parent() as CharacterBody3D
	var origin: Vector3 = enemy_body.global_position + Vector3(0, 1.3, 0)
	if muzzle_point and is_instance_valid(muzzle_point):
		origin = muzzle_point.global_position

	# Calculate spread trajectory towards target
	var dir := (_current_target_pos - origin).normalized()
	if dir.length_squared() < 0.001:
		dir = -enemy_body.global_transform.basis.z

	# Apply tactical spread bloom
	var spread_rad := deg_to_rad(spread_angle_deg)
	var spread_x := randf_range(-spread_rad, spread_rad)
	var spread_y := randf_range(-spread_rad, spread_rad)
	var spread_basis := Basis(Vector3.UP, spread_x) * Basis(Vector3.RIGHT, spread_y)
	var final_dir := (spread_basis * dir).normalized()

	emit_signal("weapon_fired", origin, final_dir, damage)
	emit_signal("muzzle_flashed")

	# Play audio
	match weapon_type:
		WeaponType.SNIPER_RIFLE:
			AudioManager.play_sound("rifle_shoot")
		WeaponType.HEAVY_LMG:
			AudioManager.play_sound("rifle_shoot")
		_:
			AudioManager.play_sound("rifle_shoot")

	# Notify global combat perception (player & squad hear this shot)
	EventBus3D.notify_combat_noise(origin, 35.0)

	# Raycast hit resolution
	var space := enemy_body.get_world_3d().direct_space_state
	var end_point := origin + final_dir * effective_range
	var query := PhysicsRayQueryParameters3D.create(origin, end_point, 1 | 2) # Environment and Player
	query.exclude = [enemy_body.get_rid()]

	var result := space.intersect_ray(query)
	if not result.is_empty():
		var hit_collider = result.collider
		if hit_collider.has_method("take_damage"):
			hit_collider.take_damage(damage, origin)
		elif hit_collider.get_parent() and hit_collider.get_parent().has_method("take_damage"):
			hit_collider.get_parent().take_damage(damage, origin)

		# Spawn impact effect
		CombatManager.spawn_hit_spark(result.position, result.normal)
	else:
		# Spawn bullet tracer through air
		CombatManager.spawn_bullet_tracer(origin, end_point)
