## NPCMira.gd
## River Keeper NPC in Verdantia village. Provides clues about the disappeared river
## and guides Kael toward the Sunken Grotto.
extends CharacterBody3D
class_name NPCMira

@onready var visual_root: Node3D = $VisualRoot
@onready var prompt_label: Label3D = $PromptLabel

var skeleton: Skeleton3D = null
var b_l_upper_arm: int = -1
var b_r_upper_arm: int = -1
var b_l_lower_arm: int = -1
var b_r_lower_arm: int = -1
var anim_time: float = 0.0

var quest_stage: int = 0 # 0: unstarted, 1: investigating river, 2: cave unlocked, 3: river restored

func _ready() -> void:
	if visual_root:
		skeleton = visual_root.find_child("Skeleton3D", true, false)
	if skeleton:
		b_l_upper_arm = skeleton.find_bone("J_Bip_L_UpperArm")
		b_r_upper_arm = skeleton.find_bone("J_Bip_R_UpperArm")
		b_l_lower_arm = skeleton.find_bone("J_Bip_L_LowerArm")
		b_r_lower_arm = skeleton.find_bone("J_Bip_R_LowerArm")

	EventBus3D.clue_discovered.connect(_on_clue_discovered)

func _process(delta: float) -> void:
	anim_time += delta
	# Relaxed anime NPC idle stance
	if skeleton:
		var breath: float = sin(anim_time * 2.2) * 0.03
		var arm_l := Quaternion.from_euler(Vector3(0.1, 0.0, 1.2 + breath))
		var arm_r := Quaternion.from_euler(Vector3(0.1, 0.0, -1.2 - breath))
		var elbow := Quaternion.from_euler(Vector3(0.25, 0.0, 0.0))
		_set_bone_rot(b_l_upper_arm, arm_l)
		_set_bone_rot(b_r_upper_arm, arm_r)
		_set_bone_rot(b_l_lower_arm, elbow)
		_set_bone_rot(b_r_lower_arm, elbow)

func _set_bone_rot(bone_id: int, rot: Quaternion) -> void:
	if skeleton and bone_id >= 0:
		skeleton.set_bone_pose_rotation(bone_id, rot)

func interact(player: Node3D) -> void:
	AudioManager.play_sound("button_click")
	if player:
		# Turn toward player
		var p_pos: Vector3 = player.global_position
		var dir: Vector3 = (p_pos - global_position).normalized()
		dir.y = 0.0
		if dir.length_squared() > 0.01:
			var target_angle := atan2(-dir.x, -dir.z)
			visual_root.rotation.y = target_angle + PI

	var dialogue: Array = []
	match quest_stage:
		0:
			dialogue = [
				{
					"speaker": "Mira",
					"text": "Travelers! Please, you must help our village! Ever since the celestial sky cracked open, our ancient river vanished overnight."
				},
				{
					"speaker": "Lyra",
					"text": "A vanished river? That sounds like the water conduits in the mountain have ceased drawing primordial rain."
				},
				{
					"speaker": "Mira",
					"text": "The old waterwheel has stopped turning. Head down to the dried riverbed and examine the abandoned gear. Something unnatural is lurking in the caverns below!"
				},
				{
					"speaker": "Kael",
					"text": "Leave it to us, Mira. We will investigate the riverbed and find out what happened."
				}
			]
			quest_stage = 1
			EventBus3D.emit_signal("quest_updated", "The Village That Forgot The Rain", "Investigate the dried riverbed and the stranded waterwheel.")
		1:
			dialogue = [
				{
					"speaker": "Mira",
					"text": "Search the dry river basin just past the wooden bridge, Kael. Look for the stranded waterwheel and the abandoned explorer gear."
				}
			]
		2:
			dialogue = [
				{
					"speaker": "Mira",
					"text": "You found the hidden cave entrance? That ancient conduit leads straight to the Primordial Rain Altar! Cleanse the guardian and restore our waters!"
				}
			]
		3:
			dialogue = [
				{
					"speaker": "Mira",
					"text": "The water is flowing again! The river has returned to Verdantia! You are true saviors of Aetheria!"
				}
			]

	EventBus3D.emit_signal("show_dialogue", dialogue)

func _on_clue_discovered(_clue_id: String) -> void:
	if quest_stage == 1:
		quest_stage = 2
