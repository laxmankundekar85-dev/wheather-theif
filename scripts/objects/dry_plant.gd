## DryPlant.gd
## Starts withered and small. When Rain weather is activated nearby,
## grows upward into a lush vine with solid platform leaves for the player to climb.
extends StaticBody2D

@export var max_height: float = 140.0
@export var is_grown: bool = false

@onready var vine_stem: ColorRect = $Stem
@onready var leaf_platform: ColorRect = $LeafPlatform
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var sprout_flower: Label = $SproutFlower
@onready var particles: CPUParticles2D = $GrowParticles

func _ready() -> void:
	add_to_group("dry_plant")
	if is_grown:
		_set_grown_state_immediate()
	else:
		_set_withered_state()

func _set_withered_state() -> void:
	vine_stem.size = Vector2(10, 20)
	vine_stem.position = Vector2(-5, -20)
	vine_stem.color = Color(0.4, 0.35, 0.2) # Dried brown
	leaf_platform.visible = false
	collision_shape.disabled = true
	sprout_flower.text = "🥀"
	sprout_flower.position = Vector2(-12, -45)

func _set_grown_state_immediate() -> void:
	vine_stem.size = Vector2(12, max_height)
	vine_stem.position = Vector2(-6, -max_height)
	vine_stem.color = Color(0.18, 0.55, 0.22)
	leaf_platform.size = Vector2(140, 16)
	leaf_platform.position = Vector2(-70, -max_height)
	leaf_platform.color = Color(0.25, 0.68, 0.25)
	leaf_platform.visible = true
	collision_shape.disabled = false
	collision_shape.position = Vector2(0, -max_height + 8)
	sprout_flower.text = "🌸"
	sprout_flower.position = Vector2(-12, -max_height - 28)

func grow() -> void:
	if is_grown:
		return
	is_grown = true
	AudioManager.play_sound("puzzle_solve")

	if particles:
		particles.emitting = true

	# Animate stem rising smoothly
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(vine_stem, "size:y", max_height, 0.8).from(20.0)
	tween.tween_property(vine_stem, "position:y", -max_height, 0.8).from(-20.0)
	tween.tween_property(vine_stem, "color", Color(0.18, 0.55, 0.22), 0.8)
	tween.tween_property(sprout_flower, "position:y", -max_height - 28, 0.8)

	await tween.finished

	# Bloom the leaf platform
	leaf_platform.visible = true
	leaf_platform.scale = Vector2(0.1, 0.1)
	leaf_platform.position = Vector2(-70, -max_height)
	collision_shape.position = Vector2(0, -max_height + 8)
	collision_shape.disabled = false

	var bloom_tween := create_tween()
	bloom_tween.tween_property(leaf_platform, "scale", Vector2(1.0, 1.0), 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	sprout_flower.text = "🌸"
