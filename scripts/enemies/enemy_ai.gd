## EnemyAI.gd
## Tactical finite state machine for human combatants.
## Coordinates perception, cover seeking, weapon fire, locomotion, and squad tactics.
extends Node
class_name EnemyAI

enum AIState {
	PATROL,
	INVESTIGATE,
	ENGAGE,
	TAKE_COVER,
	FLANK,
	RELOAD,
	DEAD
}

@export var ai_state: AIState = AIState.PATROL
@export var patrol_speed: float = 1.8
@export var combat_speed: float = 3.8
@export var sprint_speed: float = 5.2
@export var flank_preference: float = 0.35 # Probability of flanking vs direct cover

# References to sibling components
var perception: Node = null
var combat: Node = null
var cover_system: Node = null
var anim_ctrl: Node = null
var health: Node = null
var audio_comp: Node = null
var enemy_body: CharacterBody3D

# AI working variables
var target_player: CharacterBody3D = null
var current_destination: Vector3 = Vector3.ZERO
var state_timer: float = 0.0
var strafe_dir: float = 1.0
var strafe_timer: float = 0.0
var patrol_points: Array[Vector3] = []
var current_patrol_idx: int = 0
var is_active: bool = true

signal state_changed(new_state: AIState)

func _ready() -> void:
	enemy_body = get_parent() as CharacterBody3D
	perception = enemy_body.get_node_or_null("EnemyPerception")
	combat = enemy_body.get_node_or_null("EnemyCombat")
	cover_system = enemy_body.get_node_or_null("EnemyCoverSystem")
	anim_ctrl = enemy_body.get_node_or_null("EnemyAnimationController")
	health = enemy_body.get_node_or_null("EnemyHealth")
	audio_comp = enemy_body.get_node_or_null("EnemyAudio")

	if perception:
		perception.target_spotted.connect(_on_target_spotted)
		perception.sound_investigated.connect(_on_sound_heard)
		perception.target_lost.connect(_on_target_lost)

	if health:
		health.took_damage.connect(_on_took_damage)
		health.died.connect(_on_died)

	if combat:
		combat.reload_started.connect(_on_reload_started)
		combat.reload_finished.connect(_on_reload_finished)

	# Store initial position as home patrol point
	if enemy_body:
		patrol_points.append(enemy_body.global_position)
		patrol_points.append(enemy_body.global_position + enemy_body.global_transform.basis.x * 6.0)
		patrol_points.append(enemy_body.global_position - enemy_body.global_transform.basis.x * 6.0)

func _process(delta: float) -> void:
	if not is_active or ai_state == AIState.DEAD:
		return

	state_timer += delta

	match ai_state:
		AIState.PATROL:
			_tick_patrol(delta)
		AIState.INVESTIGATE:
			_tick_investigate(delta)
		AIState.ENGAGE:
			_tick_engage(delta)
		AIState.TAKE_COVER:
			_tick_take_cover(delta)
		AIState.FLANK:
			_tick_flank(delta)
		AIState.RELOAD:
			_tick_reload(delta)

	_update_animation(delta)

func set_state(new_state: AIState) -> void:
	if ai_state == AIState.DEAD:
		return
	ai_state = new_state
	state_timer = 0.0
	emit_signal("state_changed", new_state)

func _tick_patrol(delta: float) -> void:
	if patrol_points.is_empty():
		return

	var target_wp := patrol_points[current_patrol_idx]
	var dist := enemy_body.global_position.distance_to(target_wp)

	if dist < 1.0:
		current_patrol_idx = (current_patrol_idx + 1) % patrol_points.size()
	else:
		_move_toward(target_wp, patrol_speed, delta)

func _tick_investigate(delta: float) -> void:
	if perception and perception.has_line_of_sight:
		set_state(AIState.ENGAGE)
		return

	var dist := enemy_body.global_position.distance_to(current_destination)
	if dist > 1.2:
		_move_toward(current_destination, combat_speed, delta)
	else:
		# Arrived at suspicious sound location, scan area
		if state_timer > 4.0:
			set_state(AIState.PATROL)

func _tick_engage(delta: float) -> void:
	if not target_player or not is_instance_valid(target_player):
		set_state(AIState.PATROL)
		return

	# Face target
	_look_at_pos(target_player.global_position, delta * 8.0)

	var dist := enemy_body.global_position.distance_to(target_player.global_position)

	# Aim calculations
	if anim_ctrl:
		anim_ctrl.is_aiming = true
		var to_target := (target_player.global_position + Vector3(0, 1.1, 0)) - (enemy_body.global_position + Vector3(0, 1.4, 0))
		anim_ctrl.aim_pitch = -atan2(to_target.y, Vector2(to_target.x, to_target.z).length())

	# Tactical Strafe while shooting
	strafe_timer += delta
	if strafe_timer > randf_range(1.5, 3.0):
		strafe_timer = 0.0
		strafe_dir = -strafe_dir

	var right_vec := enemy_body.global_transform.basis.x
	var strafe_target := enemy_body.global_position + right_vec * (strafe_dir * 3.5)

	if dist > 22.0:
		# Advance into effective range
		_move_toward(target_player.global_position, combat_speed, delta)
	elif dist < 6.0:
		# Back up to keep distance
		_move_toward(enemy_body.global_position + enemy_body.global_transform.basis.z * 3.5, combat_speed, delta)
	else:
		# Sidestep strafe
		_move_toward(strafe_target, combat_speed * 0.7, delta)

	# Weapon fire
	if combat and combat.can_shoot():
		var aim_target := target_player.global_position + Vector3(0, 1.2, 0)
		combat.trigger_fire(aim_target)

	# Tactical reposition: if taking fire or after several bursts, seek cover
	if state_timer > 5.5 and randf() < 0.6:
		_attempt_take_cover()

func _tick_take_cover(delta: float) -> void:
	if not cover_system:
		set_state(AIState.ENGAGE)
		return

	if not cover_system.is_in_cover():
		var dist := enemy_body.global_position.distance_to(cover_system.current_cover_pos)
		if dist > 0.8:
			_move_toward(cover_system.current_cover_pos, sprint_speed, delta)
		else:
			cover_system.enter_cover(cover_system.current_cover_pos, true)
	else:
		# Inside cover: crouch when ducking, peek and shoot when peeking
		if cover_system.is_ducking():
			if anim_ctrl:
				anim_ctrl.is_crouching = true
				anim_ctrl.is_aiming = false
			# Reload safely in cover
			if combat and combat.current_ammo < combat.max_ammo and not combat.is_reloading:
				combat.start_reload()
		else:
			# Peeking fire
			if anim_ctrl:
				anim_ctrl.is_crouching = false
				anim_ctrl.is_aiming = true
			if target_player and combat and combat.can_shoot():
				_look_at_pos(target_player.global_position, delta * 10.0)
				combat.trigger_fire(target_player.global_position + Vector3(0, 1.2, 0))

		# After spending time in cover, re-engage or flank
		if state_timer > 7.0:
			cover_system.leave_cover()
			if randf() < flank_preference:
				_attempt_flank()
			else:
				set_state(AIState.ENGAGE)

func _tick_flank(delta: float) -> void:
	if not target_player:
		set_state(AIState.PATROL)
		return

	var dist := enemy_body.global_position.distance_to(current_destination)
	if dist > 1.2:
		_move_toward(current_destination, combat_speed, delta)
		if perception and perception.has_line_of_sight and combat and combat.can_shoot():
			combat.trigger_fire(target_player.global_position + Vector3(0, 1.1, 0))
	else:
		set_state(AIState.ENGAGE)

func _tick_reload(delta: float) -> void:
	# Keep moving to cover or ducking while reloading
	if cover_system and cover_system.is_in_cover():
		if anim_ctrl:
			anim_ctrl.is_crouching = true
	else:
		_attempt_take_cover()

func _move_toward(target_pos: Vector3, speed: float, delta: float) -> void:
	var to_target := (target_pos - enemy_body.global_position)
	to_target.y = 0.0
	if to_target.length_squared() < 0.01:
		enemy_body.velocity = Vector3.ZERO
		return

	var move_dir := to_target.normalized()
	enemy_body.velocity = Vector3(move_dir.x * speed, enemy_body.velocity.y, move_dir.z * speed)

	# Apply gravity if not on floor
	if not enemy_body.is_on_floor():
		enemy_body.velocity.y -= 19.6 * delta
	else:
		enemy_body.velocity.y = 0.0

	# Face movement direction
	_look_at_pos(enemy_body.global_position + move_dir, delta * 6.0)
	enemy_body.move_and_slide()

func _look_at_pos(look_target: Vector3, speed: float) -> void:
	var forward := (look_target - enemy_body.global_position)
	forward.y = 0.0
	if forward.length_squared() < 0.01:
		return
	var target_rot_y := atan2(-forward.x, -forward.z)
	enemy_body.rotation.y = lerp_angle(enemy_body.rotation.y, target_rot_y, speed)

func _update_animation(delta: float) -> void:
	if not anim_ctrl:
		return

	var planar_vel := Vector2(enemy_body.velocity.x, enemy_body.velocity.z)
	anim_ctrl.move_speed = planar_vel.length()
	anim_ctrl.is_crouching = cover_system.is_ducking() if cover_system else false

func _attempt_take_cover() -> void:
	if not cover_system or not target_player:
		set_state(AIState.ENGAGE)
		return
	var cover_info: Dictionary = cover_system.find_best_cover(target_player.global_position)
	if cover_info.get("found", false):
		cover_system.current_cover_pos = cover_info["position"]
		set_state(AIState.TAKE_COVER)
		if audio_comp:
			audio_comp.play_taking_cover_callout()
	else:
		set_state(AIState.ENGAGE)

func _attempt_flank() -> void:
	if not target_player:
		set_state(AIState.ENGAGE)
		return
	# Calculate flank waypoint 90 degrees offset from player
	var p_pos := target_player.global_position
	var to_me := (enemy_body.global_position - p_pos).normalized()
	var flank_dir := Vector3(-to_me.z, 0, to_me.x) if randf() < 0.5 else Vector3(to_me.z, 0, -to_me.x)
	current_destination = p_pos + (to_me * 12.0) + (flank_dir * 14.0)
	set_state(AIState.FLANK)

# Signal callbacks
func _on_target_spotted(target: CharacterBody3D, pos: Vector3) -> void:
	target_player = target
	if ai_state == AIState.PATROL or ai_state == AIState.INVESTIGATE:
		set_state(AIState.ENGAGE)
		if audio_comp:
			audio_comp.play_spotted_callout()

func _on_sound_heard(pos: Vector3) -> void:
	if ai_state == AIState.PATROL or ai_state == AIState.INVESTIGATE:
		current_destination = pos
		if target_player == null:
			target_player = GameManager.player_ref as CharacterBody3D
		if enemy_body and enemy_body.global_position.distance_to(pos) < 18.0:
			set_state(AIState.ENGAGE)
		else:
			set_state(AIState.INVESTIGATE)
		if audio_comp:
			audio_comp.play_investigate_callout()

func _on_target_lost() -> void:
	if ai_state == AIState.ENGAGE:
		# Search last known location
		if perception:
			current_destination = perception.last_known_pos
			set_state(AIState.INVESTIGATE)

func _on_took_damage(amount: int, is_crit: bool, hit_dir: Vector3) -> void:
	if anim_ctrl:
		anim_ctrl.trigger_hit_flinch(hit_dir)
	if audio_comp:
		audio_comp.play_pain()

	if target_player == null or not is_instance_valid(target_player):
		target_player = GameManager.player_ref as CharacterBody3D

	if perception and target_player:
		perception.last_known_pos = target_player.global_position
		perception.time_since_seen = 0.0
		perception.has_line_of_sight = true
		perception.current_alert = EnemyPerception.AlertLevel.COMBAT

	# Immediately retaliate or take cover
	if ai_state != AIState.DEAD:
		if ai_state != AIState.ENGAGE and ai_state != AIState.TAKE_COVER:
			if randf() < 0.35:
				_attempt_take_cover()
			else:
				set_state(AIState.ENGAGE)

func _on_died(killer_dir: Vector3) -> void:
	ai_state = AIState.DEAD
	is_active = false
	if anim_ctrl:
		anim_ctrl.trigger_death()
	if audio_comp:
		audio_comp.play_death()
	enemy_body.velocity = Vector3.ZERO
	# Disable collision after 0.5s so player doesn't trip on corpse
	enemy_body.set_collision_layer_value(2, false)
	enemy_body.set_collision_mask_value(2, false)

func _on_reload_started() -> void:
	if ai_state == AIState.ENGAGE:
		_attempt_take_cover()

func _on_reload_finished() -> void:
	if ai_state == AIState.RELOAD:
		set_state(AIState.ENGAGE)
