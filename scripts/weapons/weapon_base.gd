## WeaponBase.gd
## Modular base class for all firearm and magical weaponry in Weather Thief TPS RPG.
## Handles magazine capacity, reload lifecycle, recoil patterns, dynamic spread bloom,
## and firing cadence.
extends Node3D
class_name WeaponBase

enum WeaponType {
	ASSAULT_RIFLE,
	TACTICAL_RIFLE,
	SMG,
	SHOTGUN,
	SNIPER,
	PISTOL,
	HEAVY_ENERGY,
	WEATHER_MAGIC
}

enum Rarity {
	COMMON,
	RARE,
	EPIC,
	LEGENDARY
}

@export_group("Weapon Info")
@export var weapon_id: String = "rifle_skybreaker"
@export var weapon_name: String = "Skybreaker Mark-IV Tactical Assault Rifle"
@export var weapon_type: WeaponType = WeaponType.ASSAULT_RIFLE
@export var rarity: Rarity = Rarity.RARE
@export var is_automatic: bool = true

@export_group("Ballistics & Damage")
@export var base_damage: int = 26
@export var headshot_multiplier: float = 2.2
@export var fire_rate: float = 9.5 # Rounds per second
@export var effective_range: float = 100.0

@export_group("Ammunition")
@export var mag_capacity: int = 30
@export var current_ammo: int = 30
@export var reserve_ammo: int = 120
@export var max_reserve_ammo: int = 240
@export var reload_time: float = 1.75 # Seconds

@export_group("Recoil & Spread (Valorant-inspired)")
@export var base_spread_deg: float = 0.6
@export var max_spread_deg: float = 3.8
@export var spread_bloom_rate: float = 0.55
@export var spread_recovery_rate: float = 8.5
@export var ads_spread_multiplier: float = 0.35
@export var move_spread_multiplier: float = 2.2
@export var vertical_recoil_strength: float = 0.95
@export var horizontal_recoil_strength: float = 0.35

enum ScopeType {
	IRON_SIGHTS,
	RED_DOT,
	HOLO_2X,
	ACOG_4X,
	SNIPER_8X
}

@export_group("Optics & Scope")
@export var scope_type: ScopeType = ScopeType.RED_DOT
@export var scope_zoom_fov: float = 46.0
@export var pellets_per_shot: int = 1

# Internal State
var current_spread_deg: float = 0.6
var is_reloading: bool = false
var reload_timer: float = 0.0
var fire_interval: float = 0.1
var fire_timer: float = 0.0
var is_aiming_down_sights: bool = false
var is_owner_moving: bool = false

# Weather Enchantment
var weather_infusion: String = "none" # "none", "rain", "snow", "wind", "thunder", "sun"
var infusion_duration: float = 0.0

signal ammo_updated(current: int, reserve: int, mag_size: int)
signal reload_started(duration: float)
signal reload_completed
signal weapon_fired(recoil_v: float, recoil_h: float)
signal dry_fired
signal hit_registered(is_headshot: bool, damage: int)

func _ready() -> void:
	fire_interval = 1.0 / max(0.1, fire_rate)
	current_spread_deg = base_spread_deg
	emit_signal("ammo_updated", current_ammo, reserve_ammo, mag_capacity)

func _process(delta: float) -> void:
	# Tick fire timer
	if fire_timer > 0.0:
		fire_timer = max(0.0, fire_timer - delta)

	# Tick reload timer
	if is_reloading:
		reload_timer -= delta
		if reload_timer <= 0.0:
			_finish_reload()

	# Tick weather infusion
	if infusion_duration > 0.0:
		infusion_duration -= delta
		if infusion_duration <= 0.0:
			weather_infusion = "none"

	# Recover dynamic spread bloom
	var target_spread := base_spread_deg
	if is_aiming_down_sights:
		target_spread *= ads_spread_multiplier
	if is_owner_moving:
		target_spread *= move_spread_multiplier

	current_spread_deg = move_toward(current_spread_deg, target_spread, spread_recovery_rate * delta)

func can_shoot() -> bool:
	return not is_reloading and fire_timer <= 0.0 and current_ammo > 0

func trigger_shoot(camera: Camera3D, origin_node: Node3D = null) -> bool:
	if is_reloading:
		return false

	if current_ammo <= 0:
		if fire_timer <= 0.0:
			fire_timer = 0.2
			AudioManager.play_sound("dry_fire_click")
			emit_signal("dry_fired")
			# Auto reload if reserve available
			if reserve_ammo > 0:
				start_reload()
		return false

	if fire_timer > 0.0:
		return false

	# Consume ammo
	current_ammo -= 1
	fire_timer = fire_interval
	emit_signal("ammo_updated", current_ammo, reserve_ammo, mag_capacity)

	# Bloom spread
	current_spread_deg = min(max_spread_deg, current_spread_deg + spread_bloom_rate)

	# Compute recoil kick
	var r_v := vertical_recoil_strength * randf_range(0.85, 1.15)
	var r_h := randf_range(-horizontal_recoil_strength, horizontal_recoil_strength)
	if is_aiming_down_sights:
		r_v *= 0.65
		r_h *= 0.65

	emit_signal("weapon_fired", r_v, r_h)

	# Perform actual ballistics (overridden in hitscan/projectile subclasses)
	_execute_shot(camera, origin_node)
	return true

func _execute_shot(_camera: Camera3D, _origin_node: Node3D) -> void:
	pass

func start_reload() -> void:
	if is_reloading or current_ammo >= mag_capacity or reserve_ammo <= 0:
		return

	is_reloading = true
	reload_timer = reload_time
	AudioManager.play_sound("reload_start")
	emit_signal("reload_started", reload_time)

func _finish_reload() -> void:
	is_reloading = false
	var needed := mag_capacity - current_ammo
	var amount: int = min(needed, reserve_ammo)
	current_ammo += amount
	reserve_ammo -= amount
	AudioManager.play_sound("reload_finish")
	emit_signal("reload_completed")
	emit_signal("ammo_updated", current_ammo, reserve_ammo, mag_capacity)

func add_ammo(amount: int) -> void:
	reserve_ammo = min(max_reserve_ammo, reserve_ammo + amount)
	emit_signal("ammo_updated", current_ammo, reserve_ammo, mag_capacity)

func infuse_weather(element: String, duration: float) -> void:
	weather_infusion = element
	infusion_duration = duration
	AudioManager.play_sound("weather_" + element)

func get_current_spread_rad() -> float:
	return deg_to_rad(current_spread_deg)

