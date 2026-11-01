## CoverPoint.gd
## Tactical cover point node placed in combat arenas and outposts.
## Enemies detect these positions to take defensive stances against player fire.
extends Node3D
class_name CoverPoint

@export var is_high_cover: bool = false
@export var is_occupied: bool = false

var occupier: Node = null

func claim(node: Node) -> bool:
	if is_occupied and is_instance_valid(occupier) and occupier != node:
		return false
	is_occupied = true
	occupier = node
	return true

func release(node: Node) -> void:
	if occupier == node:
		is_occupied = false
		occupier = null

