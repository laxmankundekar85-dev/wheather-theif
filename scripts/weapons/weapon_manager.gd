## WeaponManager.gd
## Manages weapon slots, inventory switching, equipping, holstering, and active weapon state.
extends Node3D
class_name WeaponManager

const WeaponBaseClass = preload("res://scripts/weapons/weapon_base.gd")

const WEAPON_SCENES: Array[PackedScene] = [
	preload("res://scenes/weapons/rifle_skybreaker.tscn"),
	preload("res://scenes/weapons/smg_viper.tscn"),
	preload("res://scenes/weapons/shotgun_tempest.tscn"),
	preload("res://scenes/weapons/sniper_stormfall.tscn"),
	preload("res://scenes/weapons/carbine_aetheria.tscn")
]

var weapons: Array = []
var active_slot: int = 0
var active_weapon: Node3D = null

signal active_weapon_changed(weapon: Node3D)
signal ammo_updated(current: int, reserve: int, mag_size: int)
signal reload_started(duration: float)
signal reload_completed
signal weapon_fired(recoil_v: float, recoil_h: float)
signal hit_registered(is_headshot: bool, damage: int)

func _ready() -> void:
	# Instantiate full 5-weapon tactical arsenal
	if weapons.is_empty():
		for scn in WEAPON_SCENES:
			if scn:
				var w_inst = scn.instantiate()
				add_child(w_inst)
				w_inst.visible = false
				add_weapon(w_inst)
		equip_slot(0)

func add_weapon(weapon: Node3D) -> void:
	if not weapons.has(weapon):
		weapons.append(weapon)
		_connect_weapon_signals(weapon)
		if weapons.size() == 1:
			equip_slot(0)

func _connect_weapon_signals(w: Node3D) -> void:
	if not w.ammo_updated.is_connected(_on_weapon_ammo_updated):
		w.ammo_updated.connect(_on_weapon_ammo_updated)
	if not w.reload_started.is_connected(_on_weapon_reload_started):
		w.reload_started.connect(_on_weapon_reload_started)
	if not w.reload_completed.is_connected(_on_weapon_reload_completed):
		w.reload_completed.connect(_on_weapon_reload_completed)
	if not w.weapon_fired.is_connected(_on_weapon_fired):
		w.weapon_fired.connect(_on_weapon_fired)
	if not w.hit_registered.is_connected(_on_hit_registered):
		w.hit_registered.connect(_on_hit_registered)

func equip_slot(index: int) -> void:
	if index < 0 or index >= weapons.size():
		return

	# Hide previous
	if active_weapon:
		active_weapon.visible = false

	active_slot = index
	active_weapon = weapons[active_slot]
	active_weapon.visible = true

	emit_signal("active_weapon_changed", active_weapon)
	emit_signal("ammo_updated", active_weapon.current_ammo, active_weapon.reserve_ammo, active_weapon.mag_capacity)

func next_weapon() -> void:
	if weapons.size() <= 1:
		return
	var next_idx := (active_slot + 1) % weapons.size()
	equip_slot(next_idx)

func prev_weapon() -> void:
	if weapons.size() <= 1:
		return
	var prev_idx := (active_slot - 1 + weapons.size()) % weapons.size()
	equip_slot(prev_idx)

func shoot(camera: Camera3D, origin_node: Node3D) -> bool:
	if active_weapon:
		return active_weapon.trigger_shoot(camera, origin_node)
	return false

func reload() -> void:
	if active_weapon:
		active_weapon.start_reload()

func infuse_weather(element: String, duration: float) -> void:
	if active_weapon:
		active_weapon.infuse_weather(element, duration)

func set_aiming(is_aiming: bool) -> void:
	if active_weapon:
		active_weapon.is_aiming_down_sights = is_aiming

func set_moving(is_moving: bool) -> void:
	if active_weapon:
		active_weapon.is_owner_moving = is_moving

func _on_weapon_ammo_updated(c: int, r: int, m: int) -> void:
	emit_signal("ammo_updated", c, r, m)

func _on_weapon_reload_started(d: float) -> void:
	emit_signal("reload_started", d)

func _on_weapon_reload_completed() -> void:
	emit_signal("reload_completed")

func _on_weapon_fired(v: float, h: float) -> void:
	emit_signal("weapon_fired", v, h)

func _on_hit_registered(is_headshot: bool, dmg: int) -> void:
	emit_signal("hit_registered", is_headshot, dmg)
