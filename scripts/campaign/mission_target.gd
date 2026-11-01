## MissionTarget.gd
## Interactive or destructible mission objective (e.g. captive rescue cage, jammer pylon).
extends Node3D
class_name MissionTarget

@export var target_name: String = "Objective Target"
@export var health: int = 50
@export var is_interactive: bool = true

var is_cleared: bool = false

signal target_cleared(node: Node)

@onready var label: Label3D = get_node_or_null("Label3D") as Label3D

func _ready() -> void:
	add_to_group("mission_targets")
	if label:
		label.text = target_name

func take_damage(amount: int, _origin: Variant = Vector3.ZERO, _crit: bool = false) -> void:
	if is_cleared:
		return
	health -= amount
	if health <= 0:
		clear_target()

func interact() -> void:
	if is_cleared or not is_interactive:
		return
	clear_target()

func clear_target() -> void:
	if is_cleared:
		return
	is_cleared = true
	AudioManager.play_sound("puzzle_solve")
	if label:
		label.text = "✦ %s SECURED" % target_name
		label.modulate = Color(0.3, 1.0, 0.5)

	# Hide mesh / play particle
	var mesh = get_node_or_null("MeshInstance3D")
	if mesh:
		var tw := create_tween()
		tw.tween_property(mesh, "scale", Vector3.ZERO, 0.3)

	emit_signal("target_cleared", self)

