## PlayerVisual.gd
## Procedurally draws the player character using draw calls.
## This acts as the AnimatedSprite2D replacement until real pixel art is added.
## Attach to a Node2D child of the Player named "PlayerVisual".
extends Node2D

var frame_timer: float = 0.0
var walk_frame: int = 0
var is_jumping: bool = false
var is_falling: bool = false
var is_idle: bool = true

# Body colors
const BODY_COLOR    := Color(0.22, 0.55, 0.95)  # Blue jacket
const SKIN_COLOR    := Color(0.95, 0.82, 0.65)  # Skin tone
const HAIR_COLOR    := Color(0.25, 0.18, 0.08)  # Dark brown hair
const BOOT_COLOR    := Color(0.25, 0.18, 0.08)
const ACCENT_COLOR  := Color(0.3, 0.95, 0.5)    # Magical green accent
const BOTTLE_COLOR  := Color(0.2, 0.6, 1.0, 0.85)

var _walk_bob: float = 0.0
var _idle_bob: float = 0.0
var _current_weather_color: Color = Color(0.2, 0.5, 1.0)

func _ready() -> void:
	WeatherManager.weather_switched.connect(_on_weather_switched)

func _process(delta: float) -> void:
	_idle_bob += delta * 2.5
	_walk_bob += delta * 8.0
	queue_redraw()

func _on_weather_switched(weather_type: String) -> void:
	_current_weather_color = WeatherManager.WEATHER_COLORS.get(weather_type, Color(0.2, 0.5, 1.0))

func set_state(state: String, flipped: bool) -> void:
	scale.x = -1.0 if flipped else 1.0

func _draw() -> void:
	var bob := sin(_idle_bob) * 1.5

	# Shadow
	_draw_custom_ellipse(Vector2(0, 28), Vector2(18, 5), Color(0, 0, 0, 0.25))

	# Boots
	draw_rect(Rect2(-14, 16 + bob, 12, 10), BOOT_COLOR, true)
	draw_rect(Rect2(2, 16 + bob, 12, 10), BOOT_COLOR, true)

	# Legs
	draw_rect(Rect2(-12, 2 + bob, 10, 18), Color(0.3, 0.3, 0.5), true)
	draw_rect(Rect2(2, 2 + bob, 10, 18), Color(0.3, 0.3, 0.5), true)

	# Body / jacket
	draw_rect(Rect2(-14, -22 + bob, 28, 26), BODY_COLOR, true)

	# Accent stripe on jacket
	draw_rect(Rect2(-3, -22 + bob, 6, 26), ACCENT_COLOR, true)

	# Head
	draw_circle(Vector2(0, -32 + bob), 14, SKIN_COLOR)

	# Hair
	draw_rect(Rect2(-14, -46 + bob, 28, 12), HAIR_COLOR, true)
	draw_circle(Vector2(0, -44 + bob), 14, HAIR_COLOR)

	# Eyes
	draw_circle(Vector2(-5, -33 + bob), 3, Color(0.1, 0.1, 0.2))
	draw_circle(Vector2(5, -33 + bob), 3, Color(0.1, 0.1, 0.2))
	draw_circle(Vector2(-4, -34 + bob), 1.2, Color.WHITE)
	draw_circle(Vector2(6, -34 + bob), 1.2, Color.WHITE)

	# Magical bottle (right hand)
	_draw_bottle(Vector2(16, -10 + bob))

	# Magical glow around bottle based on current weather
	draw_circle(Vector2(16, -10 + bob), 10, Color(_current_weather_color.r, _current_weather_color.g, _current_weather_color.b, 0.15))

func _draw_bottle(pos: Vector2) -> void:
	# Bottle body
	draw_rect(Rect2(pos.x - 4, pos.y - 8, 8, 14), BOTTLE_COLOR, true)
	# Bottle neck
	draw_rect(Rect2(pos.x - 2, pos.y - 14, 4, 8), BOTTLE_COLOR, true)
	# Cork
	draw_rect(Rect2(pos.x - 3, pos.y - 17, 6, 4), Color(0.75, 0.55, 0.2), true)
	# Glow inside bottle
	draw_circle(Vector2(pos.x, pos.y - 2), 3, Color(_current_weather_color.r, _current_weather_color.g, _current_weather_color.b, 0.6))

func _draw_custom_ellipse(center: Vector2, radii: Vector2, color: Color) -> void:
	var points := PackedVector2Array()
	var steps := 24
	for i in range(steps):
		var angle := (TAU / steps) * i
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, color)
