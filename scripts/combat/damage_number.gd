## DamageNumber.gd
## Floating RPG damage numbers appearing above targets with elemental colors.
extends Node3D

@onready var label: Label3D = $Label3D

func setup(amount: int, element: String = "physical", is_crit: bool = false) -> void:
	if not label:
		return
	label.text = str(amount)
	
	match element:
		"water", "rain":
			label.modulate = Color(0.2, 0.75, 1.0) # Hydro cyan
		"thunder", "lightning":
			label.modulate = Color(0.85, 0.4, 1.0) # Electro purple
		"sun", "pyro":
			label.modulate = Color(1.0, 0.6, 0.1) # Solar orange
		"snow", "cryo":
			label.modulate = Color(0.6, 0.95, 1.0) # Ice white-blue
		"wind", "anemo":
			label.modulate = Color(0.4, 1.0, 0.7) # Wind green
		_:
			label.modulate = Color(1.0, 1.0, 1.0) if not is_crit else Color(1.0, 0.9, 0.2)

	if is_crit:
		label.font_size = 36
		label.text += "!"
	else:
		label.font_size = 28

	# Float up and fade out
	var tw := create_tween()
	var target_pos := global_position + Vector3(randf_range(-0.5, 0.5), 1.8, randf_range(-0.5, 0.5))
	tw.tween_property(self, "global_position", target_pos, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.3)
	tw.tween_callback(queue_free)
