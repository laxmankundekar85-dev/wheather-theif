## EventBus3D.gd
## Global signal dispatcher for 3D events, interactions, dialogues, and cutscenes.
extends Node

signal interaction_available(is_available: bool, target_node: Node)
signal show_dialogue(sequence: Array)
signal dialogue_completed
signal quest_updated(title: String, description: String)
signal quest_completed(title: String)
signal cutscene_trigger(cutscene_id: String)
signal weather_shards_collected(current: int, total: int)
signal clue_discovered(clue_id: String)
signal weather_activated(weather_type: String, pos: Variant)
signal combat_noise_emitted(pos: Vector3, noise_type: String)

func notify_combat_noise(pos: Vector3, noise_type_or_radius: Variant = "gunshot") -> void:
	var n_type: String = "gunshot"
	if noise_type_or_radius is String:
		n_type = noise_type_or_radius
	combat_noise_emitted.emit(pos, n_type)
