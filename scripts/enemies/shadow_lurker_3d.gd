## ShadowLurker3D.gd
## A dark shadow creature left by Lord Moros to guard the Rain Altar.
## Chases player on sight, deals contact damage, and dissolves when watered with Rain or stomped.
extends CharacterBody3D
class_name ShadowLurker3D

@export var patrol_distance: float = 8.0
@export var move_speed: float = 3.5
@export var chase_speed: float = 6.0

@onready var visual_root: Node3D = $VisualRoot
@onready var detection_area: Area3D = $DetectionArea
@onready var hitbox_area: Area3D = $HitboxArea

var start_pos: Vector3
var target_pos: Vector3
var is_chasing: bool = false
var is_dead: bool = false
var patrol_dir: float = 1.0
var anim_time: float = 0.0

func _ready() -> void:
	start_pos = global_position
	target_pos = start_pos + Vector3(patrol_distance, 0, 0)
	WeatherManager.weather_activated.connect(_on_weather_activated)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	anim_time += delta
	# Floating/pulsing wobble
	visual_root.position.y = 0.6 + sin(anim_time * 4.0) * 0.15

	var player := GameManager.player_ref as Node3D
	if is_chasing and player != null:
		var dir := (player.global_position - global_position)
		dir.y = 0.0
		if dir.length() > 0.5:
			dir = dir.normalized()
			velocity.x = dir.x * chase_speed
			velocity.z = dir.z * chase_speed
			visual_root.rotation.y = atan2(-dir.x, -dir.z)
		else:
			velocity.x = 0
			velocity.z = 0
	else:
		# Patrol between start_pos and target_pos
		var dist_to_target := global_position.distance_to(target_pos)
		if dist_to_target < 1.0:
			patrol_dir *= -1.0
			target_pos = start_pos + Vector3(patrol_distance * patrol_dir, 0, 0)

		var move_dir := (target_pos - global_position)
		move_dir.y = 0.0
		move_dir = move_dir.normalized()
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed
		visual_root.rotation.y = atan2(-move_dir.x, -move_dir.z)

	if not is_on_floor():
		velocity.y -= 20.0 * delta

	move_and_slide()

func _on_detection_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_chasing = true

func _on_detection_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_chasing = false

func _on_hitbox_body_entered(body: Node3D) -> void:
	if is_dead:
		return
	if body.is_in_group("player"):
		var p := body as CharacterBody3D
		# If player landed from above, stomp the lurker
		if p and p.velocity.y < -1.0 and p.global_position.y > global_position.y + 0.8:
			p.velocity.y = 9.0 # bounce player up
			defeat()
		elif body.has_method("take_damage"):
			body.take_damage(1)

func _on_weather_activated(weather_type: String, pos: Variant) -> void:
	if is_dead or weather_type != "rain":
		return
	var cast_pos: Vector3 = global_position
	if pos is Vector3:
		cast_pos = pos
	if global_position.distance_to(cast_pos) <= 15.0:
		defeat()

func defeat() -> void:
	if is_dead:
		return
	is_dead = true
	AudioManager.play_sound("hit")

	# Dissolve animation
	var tw := create_tween()
	tw.tween_property(visual_root, "scale", Vector3(1.4, 0.1, 1.4), 0.3)
	tw.parallel().tween_property(visual_root, "modulate", Color(0, 0, 0, 0), 0.3)
	await tw.finished
	queue_free()
