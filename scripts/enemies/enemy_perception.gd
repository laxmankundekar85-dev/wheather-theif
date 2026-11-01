## EnemyPerception.gd
## Vision cone, sound detection, and tactical memory component.
## Simulates human soldier perception: field-of-view angle, obstacle line-of-sight,
## hearing gunshot echoes, and remembering last confirmed player positions.
extends Node
class_name EnemyPerception

enum AlertLevel {
	UNALERTED,
	SUSPICIOUS,
	ALERTED,
	COMBAT
}

@export var view_distance: float = 34.0
@export var field_of_view_deg: float = 120.0
@export var hearing_gunshot_range: float = 38.0
@export var hearing_footstep_range: float = 9.0
@export var memory_duration: float = 7.0

var current_alert: AlertLevel = AlertLevel.UNALERTED
var target_player: CharacterBody3D = null
var has_line_of_sight: bool = false
var last_known_pos: Vector3 = Vector3.ZERO
var time_since_seen: float = 999.0
var time_since_sound: float = 999.0

signal target_spotted(target_node: CharacterBody3D, pos: Vector3)
signal sound_investigated(pos: Vector3)
signal target_lost()

func _ready() -> void:
	# Listen for global weapon fire events
	if EventBus3D.has_signal("combat_noise_emitted"):
		EventBus3D.combat_noise_emitted.connect(_on_combat_noise)

func _process(delta: float) -> void:
	time_since_seen += delta
	time_since_sound += delta

	if target_player == null or not is_instance_valid(target_player):
		target_player = GameManager.player_ref as CharacterBody3D

	if target_player and is_instance_valid(target_player):
		_evaluate_vision()

func _evaluate_vision() -> void:
	var enemy_body: CharacterBody3D = get_parent() as CharacterBody3D
	if not enemy_body:
		return

	var my_eye := enemy_body.global_position + Vector3(0, 1.5, 0)
	var player_center := target_player.global_position + Vector3(0, 1.1, 0)
	var dist := my_eye.distance_to(player_center)

	if dist > view_distance:
		_set_los(false)
		return

	# Check FOV angle
	var forward := -enemy_body.global_transform.basis.z
	if "visual_root" in enemy_body and enemy_body.visual_root:
		forward = -enemy_body.visual_root.global_transform.basis.z
	forward.y = 0.0
	forward = forward.normalized()

	var to_player := (player_center - my_eye)
	to_player.y = 0.0
	var to_player_dir := to_player.normalized()

	var angle := rad_to_deg(forward.angle_to(to_player_dir))
	var in_fov := angle <= (field_of_view_deg * 0.5)

	# If player is close (within 6m), soldier notices regardless of FOV
	if not in_fov and dist > 6.0:
		_set_los(false)
		return

	# Raycast obstacle check excluding self collider
	var space := enemy_body.get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(my_eye, player_center, 1) # Layer 1 (Environment)
	query.exclude = [enemy_body.get_rid()]
	var result := space.intersect_ray(query)

	if result.is_empty():
		_set_los(true)
		last_known_pos = target_player.global_position
		time_since_seen = 0.0
		current_alert = AlertLevel.COMBAT
		emit_signal("target_spotted", target_player, last_known_pos)
	else:
		_set_los(false)

func _set_los(has_los: bool) -> void:
	if has_line_of_sight and not has_los:
		emit_signal("target_lost")
	has_line_of_sight = has_los

func report_gunshot(sound_pos: Vector3) -> void:
	var enemy_body: CharacterBody3D = get_parent() as CharacterBody3D
	if not enemy_body:
		return

	var dist := enemy_body.global_position.distance_to(sound_pos)
	if dist <= hearing_gunshot_range:
		last_known_pos = sound_pos
		time_since_sound = 0.0
		current_alert = AlertLevel.COMBAT
		emit_signal("sound_investigated", sound_pos)

func _on_combat_noise(pos: Vector3, noise_type: String) -> void:
	if noise_type == "gunshot":
		report_gunshot(pos)

