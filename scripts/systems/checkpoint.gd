## Checkpoint.gd
## Sets the player's respawn position when activated.
## Draws a glowing checkpoint pole procedurally.
extends Area2D

@export var checkpoint_id: int = 0
@export var level_id: int = 1

var _is_activated: bool = false

@onready var flag_sprite: AnimatedSprite2D = $FlagSprite
@onready var activate_particles: CPUParticles2D = $ActivateParticles
@onready var pulse_light: PointLight2D = $PulseLight

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_update_visual(false)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and not _is_activated:
		_activate(body.global_position)

func _activate(player_pos: Vector2) -> void:
	_is_activated = true
	GameManager.register_checkpoint(player_pos, level_id)
	SaveManager.save_game()

	_update_visual(true)
	if activate_particles:
		activate_particles.emitting = true

	# Light pulse
	if pulse_light:
		var tween := create_tween()
		tween.tween_property(pulse_light, "energy", 2.5, 0.3)
		tween.tween_property(pulse_light, "energy", 1.0, 0.5)

	print("[Checkpoint] Activated ID: %d at level %d" % [checkpoint_id, level_id])

func _update_visual(activated: bool) -> void:
	if flag_sprite == null:
		return
	if activated:
		flag_sprite.play("active")
		flag_sprite.modulate = Color(0.3, 1.0, 0.5)
	else:
		flag_sprite.play("idle")
		flag_sprite.modulate = Color(0.6, 0.6, 0.6)
