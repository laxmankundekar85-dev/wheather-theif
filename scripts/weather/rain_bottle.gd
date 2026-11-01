## RainBottle.gd
## Collectible bottle that grants or adds charges to a specific weather power.
## Uses Area2D for detection. Draws itself procedurally as a glowing bottle shape.
extends Area2D

@export var weather_type: String = "rain"
@export var charges_granted: int = 3

@onready var bottle_visual: Node2D = get_node_or_null("BottleVisual")
@onready var collection_label: Label  = $CollectionLabel
@onready var glow_particles: CPUParticles2D = $GlowParticles
@onready var collection_sound: AudioStreamPlayer2D = $CollectionSound
@onready var magnet_area: Area2D = $MagnetArea

const WEATHER_COLORS: Dictionary = {
	"rain": Color(0.2, 0.5, 1.0),
	"snow": Color(0.8, 0.95, 1.0),
	"wind": Color(0.5, 1.0, 0.5),
	"sun":  Color(1.0, 0.85, 0.2),
}

var _bob_offset: float = 0.0
var _is_collected: bool = false
var _magnet_target: Node2D = null

func _ready() -> void:
	if bottle_visual and "weather_type" in bottle_visual:
		bottle_visual.weather_type = weather_type
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if magnet_area:
		if not magnet_area.body_entered.is_connected(_on_magnet_body_entered):
			magnet_area.body_entered.connect(_on_magnet_body_entered)
		if not magnet_area.body_exited.is_connected(_on_magnet_body_exited):
			magnet_area.body_exited.connect(_on_magnet_body_exited)

	_setup_particles()
	collection_label.visible = false

func _process(delta: float) -> void:
	if _is_collected:
		return

	# Bob animation
	_bob_offset += delta * 2.5
	position.y += sin(_bob_offset) * 0.5

	# Magnet pull toward player
	if _magnet_target != null:
		var dir := (_magnet_target.global_position - global_position).normalized()
		global_position += dir * 280.0 * delta

func _setup_particles() -> void:
	if glow_particles == null:
		return
	var color: Color = WEATHER_COLORS.get(weather_type, Color.WHITE)
	glow_particles.color = color
	glow_particles.color_ramp = _make_color_ramp(color)

func _make_color_ramp(base_color: Color) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, base_color)
	var fade := base_color
	fade.a = 0.0
	g.set_color(1, fade)
	return g

func _on_body_entered(body: Node2D) -> void:
	if _is_collected:
		return
	if body.is_in_group("player"):
		_collect(body)

func _on_magnet_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_magnet_target = body

func _on_magnet_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_magnet_target = null

func _collect(player: Node) -> void:
	_is_collected = true
	set_deferred("monitoring", false)

	# Unlock or add charges
	if weather_type not in WeatherManager.unlocked_weathers:
		WeatherManager.unlock_weather(weather_type)
	else:
		WeatherManager.add_charges(weather_type, charges_granted)

	# Notify player
	if player.has_method("collect_bottle"):
		player.collect_bottle(weather_type)

	# Show popup label
	collection_label.text = weather_type.capitalize() + " Bottle!"
	collection_label.visible = true
	var color: Color = WEATHER_COLORS.get(weather_type, Color.WHITE)
	collection_label.add_theme_color_override("font_color", color)

	# Animate collection
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.6, 1.6), 0.15)
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

	AudioManager.play_sound("collect")
	if collection_sound and collection_sound.stream:
		collection_sound.play()
