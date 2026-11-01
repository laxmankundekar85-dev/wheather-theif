## NPCElderBramble.gd
## Elder Bramble, Guardian of the Whispering Grove.
## Welcomes Zephyr and guides him through the quest to retrieve the Rain Bottle.
extends Node3D

@onready var prompt_3d: Label3D = $Prompt3D

var dialogue_count: int = 0

func _ready() -> void:
	if prompt_3d:
		prompt_3d.visible = false

func interact(_player: Node) -> void:
	AudioManager.play_sound("jump")
	dialogue_count += 1

	if dialogue_count == 1:
		# Initial quest dialogue
		var seq: Array = [
			{
				"speaker": "Elder Bramble",
				"text": "Zephyr, my boy... You made it. The Whispering Grove is withering. Feel how dry the air has become since Moros stole the Rain Bottle."
			},
			{
				"speaker": "Zephyr",
				"text": "I can see the blighted roots, Elder. Where did the Shadow Lord take it?"
			},
			{
				"speaker": "Elder Bramble",
				"text": "Deep in the Sunken Temple across the stone canyon. But beware—he left behind a Shadow Lurker to guard the altar, and sealed the courtyard with dark flame."
			},
			{
				"speaker": "Elder Bramble",
				"text": "Defeat the shadow beast, reclaim the Rain Bottle, and summon the downpour [⚡]! The rain will extinguish the dark fire and sprout ancient climbing vines to the grove's summit!"
			},
			{
				"speaker": "Zephyr",
				"text": "Consider the Rain Bottle stolen back. Watch the skies, Elder!"
			}
		]
		EventBus3D.emit_signal("show_dialogue", seq)
		EventBus3D.emit_signal("quest_updated", "Reclaim the Rain Bottle", "Cross the canyon ruins and find the stolen Rain Bottle in the Sunken Temple.")
	else:
		# Followup reminder dialogue
		var seq: Array = [
			{
				"speaker": "Elder Bramble",
				"text": "Cross the ruins to the north. Find the Rain Bottle and use its water magic [⚡] to awaken the ancient flora and drown the shadow flames!"
			}
		]
		EventBus3D.emit_signal("show_dialogue", seq)

func _on_interaction_area_area_entered(_area: Area3D) -> void:
	if prompt_3d:
		prompt_3d.visible = true

func _on_interaction_area_area_exited(_area: Area3D) -> void:
	if prompt_3d:
		prompt_3d.visible = false
