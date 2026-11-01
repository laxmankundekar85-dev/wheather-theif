## ShadowSproutling.gd
## Basic corrupted flora enemy in Verdantia Kingdom.
## Reacts to physical and elemental attacks with damage numbers and knockback.
extends CharacterBody3D
class_name ShadowSproutling

@export var max_health: int = 120
@export var move_speed: float = 3.6
@export var attack_damage: int = 1
@export var attack_range: float = 1.8

var current_health: int = 120
var is_dead: bool = false
var is_chasing: bool = false
var attack_cooldown: float = 0.0
var anim_time: float = 0.0

@onready var visual_root: Node3D = $VisualRoot
@onready var detection_area: Area3D = $DetectionArea

func _ready() -> void:
	current_health = max_health

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	anim_time += delta
	if attack_cooldown > 0.0:
		attack_cooldown -= delta

	var player := GameManager.player_ref as Node3D
	if is_chasing and player != null:
		var dir := player.global_position - global_position
		dir.y = 0.0
		var dist := dir.length()

		if dist > attack_range:
			dir = dir.normalized()
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
			visual_root.rotation.y = atan2(-dir.x, -dir.z)
		else:
			velocity.x = 0
			velocity.z = 0
			if attack_cooldown <= 0.0:
				_attack_player(player)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 10.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 10.0 * delta)

	if not is_on_floor():
		velocity.y -= 22.0 * delta

	move_and_slide()

	# Organic hopping animation
	if visual_root:
		visual_root.position.y = 0.4 + abs(sin(anim_time * 6.0)) * 0.12

func _attack_player(player: Node3D) -> void:
	attack_cooldown = 1.4
	# Lunging bite animation
	var tw := create_tween()
	tw.tween_property(visual_root, "position:z", -0.4, 0.15)
	tw.tween_property(visual_root, "position:z", 0.0, 0.2)
	if player.has_method("take_damage"):
		player.take_damage(attack_damage)

func take_hit(amount: int, element: String, is_crit: bool) -> void:
	if is_dead:
		return

	# Rain element deals bonus vulnerability damage
	var final_dmg := amount
	if element == "rain":
		final_dmg = int(amount * 1.4)

	current_health -= final_dmg
	CombatManager.spawn_damage_number(global_position, final_dmg, element, is_crit)
	AudioManager.play_sound("hit")

	# Flash white/red
	var tw := create_tween()
	tw.tween_property(visual_root, "modulate", Color(2.5, 0.3, 0.3, 1.0), 0.08)
	tw.tween_property(visual_root, "modulate", Color.WHITE, 0.1)

	if current_health <= 0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	AudioManager.play_sound("hit")
	var tw := create_tween()
	tw.tween_property(visual_root, "scale", Vector3(1.2, 0.1, 1.2), 0.25)
	tw.parallel().tween_property(visual_root, "modulate:a", 0.0, 0.25)
	await tw.finished
	queue_free()

func _on_detection_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_chasing = true

func _on_detection_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		is_chasing = false
