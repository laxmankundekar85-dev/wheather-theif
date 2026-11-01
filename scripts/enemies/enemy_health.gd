## EnemyHealth.gd
## Comprehensive health and armor component for tactical human enemies.
## Handles shield absorption, critical headshot multipliers, directional impact vectors, and death dispatch.
extends Node
class_name EnemyHealth

@export var max_health: int = 100
@export var current_health: int = 100
@export var max_shield: int = 25
@export var current_shield: int = 25

var is_dead: bool = false

signal health_changed(current: int, maximum: int)
signal shield_changed(current: int, maximum: int)
signal took_damage(amount: int, is_crit: bool, hit_dir: Vector3)
signal died(killer_dir: Vector3)

func _ready() -> void:
	current_health = max_health
	current_shield = max_shield

func setup(hp: int, sh: int) -> void:
	max_health = hp
	current_health = hp
	max_shield = sh
	current_shield = sh
	emit_signal("health_changed", current_health, max_health)
	emit_signal("shield_changed", current_shield, max_shield)

func take_damage(amount: int, is_headshot: bool = false, hit_origin: Vector3 = Vector3.ZERO) -> int:
	if is_dead:
		return 0

	var final_damage := amount
	if is_headshot:
		final_damage = int(amount * 2.2) # AAA tactical headshot lethality

	# Calculate impact direction
	var hit_dir := Vector3.ZERO
	if get_parent() and hit_origin != Vector3.ZERO:
		hit_dir = (get_parent().global_position - hit_origin).normalized()

	# Absorb with ballistic shield first
	if current_shield > 0:
		var absorbed := mini(current_shield, final_damage)
		current_shield -= absorbed
		final_damage -= absorbed
		emit_signal("shield_changed", current_shield, max_shield)

	if final_damage > 0:
		current_health = maxi(0, current_health - final_damage)
		emit_signal("health_changed", current_health, max_health)

	emit_signal("took_damage", amount, is_headshot, hit_dir)

	if current_health <= 0:
		is_dead = true
		emit_signal("died", hit_dir)

	return final_damage

func is_alive() -> bool:
	return not is_dead and current_health > 0

