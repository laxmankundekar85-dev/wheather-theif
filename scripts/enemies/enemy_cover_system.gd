## EnemyCoverSystem.gd
## Tactical cover seeking, evaluation, and peek-fire cycle management.
## Simulates realistic military cover behavior (low-wall crouch, corner peek, suppression ducking).
extends Node
class_name EnemyCoverSystem

enum CoverState {
	OUT_OF_COVER,
	MOVING_TO_COVER,
	DUCKED_IN_COVER,
	PEEKING_FIRE
}

@export var max_cover_search_dist: float = 14.0
@export var min_duck_duration: float = 1.8
@export var max_duck_duration: float = 3.2
@export var peek_duration: float = 2.0

var current_state: CoverState = CoverState.OUT_OF_COVER
var current_cover_pos: Vector3 = Vector3.ZERO
var state_timer: float = 0.0
var is_low_cover: bool = true

signal entered_cover(pos: Vector3)
signal peeked_out()
signal ducked_down()
signal left_cover()

func _process(delta: float) -> void:
	if current_state == CoverState.OUT_OF_COVER or current_state == CoverState.MOVING_TO_COVER:
		return

	state_timer -= delta
	if state_timer <= 0.0:
		if current_state == CoverState.DUCKED_IN_COVER:
			# Peek up to shoot
			current_state = CoverState.PEEKING_FIRE
			state_timer = peek_duration
			emit_signal("peeked_out")
		elif current_state == CoverState.PEEKING_FIRE:
			# Duck back into cover to reload or avoid fire
			current_state = CoverState.DUCKED_IN_COVER
			state_timer = randf_range(min_duck_duration, max_duck_duration)
			emit_signal("ducked_down")

## Finds the best cover position relative to threat position
func find_best_cover(threat_pos: Vector3) -> Dictionary:
	var enemy_body: CharacterBody3D = get_parent() as CharacterBody3D
	if not enemy_body:
		return {"found": false}

	var my_pos := enemy_body.global_position

	# Search for explicit CoverPoint nodes in level
	var cover_nodes := enemy_body.get_tree().get_nodes_in_group("cover_points")
	var best_pos := Vector3.ZERO
	var best_score := -9999.0
	var found_any := false
	var is_low := true

	for node in cover_nodes:
		if not (node is Node3D):
			continue
		var cpos: Vector3 = (node as Node3D).global_position
		var dist_to_me := my_pos.distance_to(cpos)
		if dist_to_me > max_cover_search_dist:
			continue

		# Cover must be between me and threat or occlude threat
		var threat_dir := (threat_pos - cpos).normalized()
		var occlusion := _test_cover_occlusion(cpos, threat_pos)
		if occlusion:
			var score := -dist_to_me # Prefer closer cover
			if score > best_score:
				best_score = score
				best_pos = cpos
				found_any = true
				if "is_low_cover" in node:
					is_low = node.is_low_cover

	# Fallback: Procedurally detect nearby crates / low barriers using rays
	if not found_any:
		var angles := [45.0, -45.0, 90.0, -90.0, 135.0, -135.0]
		var away_from_threat := (my_pos - threat_pos).normalized()
		away_from_threat.y = 0.0

		for angle_deg in angles:
			var test_dir := Basis(Vector3.UP, deg_to_rad(angle_deg)) * away_from_threat
			var test_pos := my_pos + test_dir * 5.0

			if _test_cover_occlusion(test_pos, threat_pos):
				best_pos = test_pos
				found_any = true
				is_low = true
				break

	if found_any:
		return {
			"found": true,
			"position": best_pos,
			"is_low": is_low
		}

	return {"found": false}

func _test_cover_occlusion(cover_pos: Vector3, threat_pos: Vector3) -> bool:
	var enemy_body: CharacterBody3D = get_parent() as CharacterBody3D
	if not enemy_body:
		return false

	var space := enemy_body.get_world_3d().direct_space_state
	# Cast ray from ducked height (0.6m) to player chest (1.2m)
	var low_eye := cover_pos + Vector3(0, 0.6, 0)
	var threat_center := threat_pos + Vector3(0, 1.2, 0)

	var query := PhysicsRayQueryParameters3D.create(low_eye, threat_center, 1)
	var result := space.intersect_ray(query)

	# If ray is blocked by environment, it is good cover!
	return not result.is_empty()

func enter_cover(cover_pos: Vector3, low: bool = true) -> void:
	current_cover_pos = cover_pos
	is_low_cover = low
	current_state = CoverState.DUCKED_IN_COVER
	state_timer = randf_range(min_duck_duration, max_duck_duration)
	emit_signal("entered_cover", cover_pos)
	emit_signal("ducked_down")

func leave_cover() -> void:
	current_state = CoverState.OUT_OF_COVER
	emit_signal("left_cover")

func is_in_cover() -> bool:
	return current_state == CoverState.DUCKED_IN_COVER or current_state == CoverState.PEEKING_FIRE

func is_ducking() -> bool:
	return current_state == CoverState.DUCKED_IN_COVER

