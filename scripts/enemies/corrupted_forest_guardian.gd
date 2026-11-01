## CorruptedForestGuardian.gd
## Verdantia's Mini-Boss: Ancient stone and vine dragon guardian corrupted by the Shadow Lord.
## Features boss health bar integration, ground smash shockwave, and Rain-elemental stagger mechanic.
extends CharacterBody3D
class_name CorruptedForestGuardian

@export var max_health: int = 850
@export var boss_name: String = "Corrupted Forest Guardian — Guardian of Verdantia"
@export var move_speed: float = 2.8

var current_health: int = 850
var is_active: bool = false
var is_dead: bool = false
var is_staggered: bool = false
var attack_timer: float = 2.5
var anim_time: float = 0.0

@onready var visual_root: Node3D = $VisualRoot
@onready var arena_trigger: Area3D = $ArenaTrigger
@onready var slam_hitbox: Area3D = $VisualRoot/SlamHitbox

signal boss_slain

func _ready() -> void:
	current_health = max_health
	if slam_hitbox:
		slam_hitbox.monitoring = false

func _physics_process(delta: float) -> void:
	if is_dead or not is_active:
		return

	anim_time += delta

	if is_staggered:
		# Stunned pose
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	attack_timer -= delta
	var player := GameManager.player_ref as Node3D
	if player:
		var dir := player.global_position - global_position
		dir.y = 0.0
		var dist := dir.length()

		# Rotate towards player
		if dir.length_squared() > 0.1:
			var target_rot := atan2(-dir.x, -dir.z)
			visual_root.rotation.y = lerp_angle(visual_root.rotation.y, target_rot, delta * 3.5)

		if dist > 3.8:
			dir = dir.normalized()
			velocity.x = dir.x * move_speed
			velocity.z = dir.z * move_speed
		else:
			velocity.x = 0
			velocity.z = 0

		if attack_timer <= 0.0:
			_perform_ground_slam(player)

	if not is_on_floor():
		velocity.y -= 25.0 * delta

	move_and_slide()

	# Heavy stomping procedural motion
	if visual_root and not is_staggered:
		visual_root.position.y = 1.0 + abs(sin(anim_time * 3.5)) * 0.18

func _perform_ground_slam(_player: Node3D) -> void:
	attack_timer = 4.2
	AudioManager.play_sound("jump")

	# Telegraphed wind-up
	var tw := create_tween()
	tw.tween_property(visual_root, "position:y", 2.2, 0.45).set_trans(Tween.TRANS_BACK)
	tw.tween_property(visual_root, "position:y", 0.8, 0.15).set_trans(Tween.TRANS_BOUNCE)
	await tw.finished

	# Impact!
	AudioManager.play_sound("hit")
	if slam_hitbox:
		slam_hitbox.monitoring = true
		await get_tree().create_timer(0.2).timeout
		if is_instance_valid(slam_hitbox):
			slam_hitbox.monitoring = false

func take_hit(amount: int, element: String, is_crit: bool) -> void:
	if is_dead:
		return

	# If hit with Rain element, trigger stagger vulnerability!
	if element == "rain" and not is_staggered:
		_trigger_stagger()

	var final_dmg := amount
	if is_staggered:
		final_dmg = int(amount * 1.75) # Extra vulnerable while staggered

	current_health = max(0, current_health - final_dmg)
	CombatManager.spawn_damage_number(global_position + Vector3(0, 1.8, 0), final_dmg, element, is_crit)
	CombatManager.update_boss_health(current_health, max_health)
	AudioManager.play_sound("hit")

	# Flash effect
	var tw := create_tween()
	tw.tween_property(visual_root, "modulate", Color(2.5, 0.4, 0.4, 1.0), 0.08)
	tw.tween_property(visual_root, "modulate", Color.WHITE, 0.1)

	if current_health <= 0:
		die()

func _trigger_stagger() -> void:
	is_staggered = true
	var tw := create_tween()
	tw.tween_property(visual_root, "rotation:x", 0.35, 0.2)
	await get_tree().create_timer(2.6).timeout
	if is_instance_valid(self) and not is_dead:
		var tw_recover := create_tween()
		tw_recover.tween_property(visual_root, "rotation:x", 0.0, 0.3)
		is_staggered = false

func die() -> void:
	if is_dead:
		return
	is_dead = true
	AudioManager.play_sound("checkpoint")
	emit_signal("boss_slain")

	# Defeat dissolve animation
	var tw := create_tween()
	tw.tween_property(visual_root, "scale", Vector3(1.4, 0.05, 1.4), 0.8).set_trans(Tween.TRANS_QUAD)
	tw.parallel().tween_property(visual_root, "modulate:a", 0.0, 0.8)
	await tw.finished

	# Complete demo story quest
	EventBus3D.emit_signal("quest_updated", "Verdantia Cleansed", "The Corrupted Guardian is cleansed! The First Sky's balance begins to heal.")
	queue_free()

func _on_arena_trigger_body_entered(body: Node3D) -> void:
	if not is_active and body.is_in_group("player"):
		is_active = true
		CombatManager.register_boss(self, boss_name, max_health)

func _on_slam_hitbox_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(2)
