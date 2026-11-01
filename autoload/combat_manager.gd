## CombatManager.gd
## Global combat coordinator: spawns 3D damage numbers, coordinates boss encounters,
## and computes elemental reactions (Rain + Thunder, etc.).
extends Node

signal boss_appeared(boss_name: String, current_hp: int, max_hp: int)
signal boss_health_updated(current_hp: int, max_hp: int)
signal boss_defeated
signal elemental_reaction_triggered(reaction_name: String, position: Vector3)

const DAMAGE_NUMBER_SCENE = preload("res://scenes/combat/damage_number.tscn")

var active_boss: Node = null

func spawn_damage_number(pos: Vector3, amount: int, element: String = "physical", is_crit: bool = false) -> void:
	var tree := get_tree()
	if not tree or not tree.current_scene:
		return
	var inst := DAMAGE_NUMBER_SCENE.instantiate()
	tree.current_scene.add_child(inst)
	inst.global_position = pos + Vector3(0, 1.2, 0)
	inst.setup(amount, element, is_crit)

func register_boss(boss_node: Node, boss_name: String, max_hp: int) -> void:
	active_boss = boss_node
	emit_signal("boss_appeared", boss_name, max_hp, max_hp)

func update_boss_health(current_hp: int, max_hp: int) -> void:
	emit_signal("boss_health_updated", current_hp, max_hp)
	if current_hp <= 0:
		emit_signal("boss_defeated")
		active_boss = null
