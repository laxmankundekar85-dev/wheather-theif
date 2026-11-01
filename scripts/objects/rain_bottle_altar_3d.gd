## RainBottleAltar3D.gd
## The sacred altar in Level 1 holding the stolen Rain Bottle.
## Picking it up unlocks Rain magic and triggers the story discovery sequence.
extends Node3D

@onready var bottle_mesh: Node3D = $BottleRoot
@onready var prompt_3d: Label3D = $Prompt3D
@onready var omni_light: OmniLight3D = $OmniLight3D

var is_collected: bool = false
var time_passed: float = 0.0

func _ready() -> void:
	if prompt_3d:
		prompt_3d.visible = false

func _process(delta: float) -> void:
	if not is_collected and bottle_mesh:
		time_passed += delta
		bottle_mesh.rotation.y += delta * 2.5
		bottle_mesh.position.y = 1.35 + sin(time_passed * 3.0) * 0.12

func interact(_player: Node) -> void:
	if is_collected:
		return
	collect()

func _on_interaction_area_area_entered(_area: Area3D) -> void:
	if not is_collected and prompt_3d:
		prompt_3d.visible = true

func _on_interaction_area_area_exited(_area: Area3D) -> void:
	if prompt_3d:
		prompt_3d.visible = false

func _on_body_entered(body: Node3D) -> void:
	if not is_collected and body.is_in_group("player"):
		collect()

func collect() -> void:
	if is_collected:
		return
	is_collected = true

	if prompt_3d:
		prompt_3d.visible = false

	# Unlock rain power in WeatherManager
	WeatherManager.unlock_weather("rain")
	GameManager.register_checkpoint(global_position + Vector3(0, 1.5, 4.0), 1)
	AudioManager.play_sound("checkpoint") # Fanfare

	# Rising animation
	var tw := create_tween()
	tw.tween_property(bottle_mesh, "position:y", 3.0, 0.4).set_trans(Tween.TRANS_BACK)
	tw.parallel().tween_property(omni_light, "light_energy", 8.0, 0.4)
	tw.tween_property(bottle_mesh, "scale", Vector3.ZERO, 0.25)
	await tw.finished

	# Trigger Story Discovery Sequence
	var seq: Array = [
		{
			"speaker": "Zephyr",
			"text": "I got it! The Rain Bottle... It feels cold to the touch, and the crystal pulses like a beating heart."
		},
		{
			"speaker": "Narrator",
			"text": "✨ [b]POWER UNLOCKED: RAIN MAGIC[/b] ✨\nPress [⚡] to summon a storm. Rain will extinguish purple shadow fires, hydrate dormant flora, and reveal ancient stone bridges."
		},
		{
			"speaker": "Zephyr",
			"text": "Now, let's extinguish those dark flames blocking the upper temple and sprout the giant climbing vines!"
		}
	]
	EventBus3D.emit_signal("show_dialogue", seq)
	EventBus3D.emit_signal("quest_updated", "Summon the Rain", "Use [⚡] Rain magic to quench the Shadow Barrier and awaken the ancient flora!")
