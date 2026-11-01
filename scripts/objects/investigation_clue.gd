## InvestigationClue.gd
## Interactive clue / discovery spot for open-world exploration quests.
extends Area3D
class_name InvestigationClue

@export var clue_id: String = "dried_river"
@export var prompt_text: String = "[🔍 Investigate] Dried Riverbed"
@export var clue_dialogue: Array = []

@onready var label: Label3D = $Label3D
var is_investigated: bool = false

signal clue_found(id: String)

func _ready() -> void:
	if label:
		label.text = prompt_text

func interact(_player: Node) -> void:
	if is_investigated:
		return
	is_investigated = true
	AudioManager.play_sound("puzzle_solve")
	emit_signal("clue_found", clue_id)
	EventBus3D.emit_signal("clue_discovered", clue_id)

	if clue_dialogue.size() > 0:
		EventBus3D.emit_signal("show_dialogue", clue_dialogue)

	if label:
		label.text = "✓ " + prompt_text.replace("[🔍 Investigate] ", "").replace("[🔍 Clue] ", "")
		label.modulate = Color(0.4, 0.9, 0.4)

	var tw := create_tween()
	tw.tween_property($BeamMesh, "scale:y", 0.05, 0.4)
	tw.parallel().tween_property($CPUParticles3D, "emitting", false, 0.1)
