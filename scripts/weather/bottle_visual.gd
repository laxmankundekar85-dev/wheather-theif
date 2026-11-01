## BottleVisual.gd
## Procedurally draws a glowing magical weather bottle collectible.
## Attach to a Node2D child of the WeatherBottle scene.
extends Node2D

@export var weather_type: String = "rain"

var _time: float = 0.0
var _color: Color = Color(0.2, 0.5, 1.0)

func _ready() -> void:
	_color = WeatherManager.WEATHER_COLORS.get(weather_type, Color(0.2, 0.5, 1.0))

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var bob := sin(_time * 2.8) * 3.0
	var glow_alpha := 0.2 + 0.15 * sin(_time * 3.5)

	# Outer glow rings
	draw_circle(Vector2(0, bob), 28, Color(_color.r, _color.g, _color.b, glow_alpha * 0.5))
	draw_circle(Vector2(0, bob), 20, Color(_color.r, _color.g, _color.b, glow_alpha))

	# Bottle body (rounded rect approximation)
	draw_rect(Rect2(-10, -6 + bob, 20, 26), Color(0.15, 0.25, 0.45, 0.9), true)
	draw_rect(Rect2(-10, -6 + bob, 20, 26), Color(_color.r * 0.6, _color.g * 0.6, _color.b * 0.6, 0.5), false)

	# Liquid inside
	var liquid_height := 14 + sin(_time * 2.0) * 2.0
	draw_rect(Rect2(-7, -6 + bob + (20 - liquid_height), 14, liquid_height), Color(_color.r, _color.g, _color.b, 0.75), true)

	# Bottle neck
	draw_rect(Rect2(-5, -18 + bob, 10, 14), Color(0.15, 0.25, 0.45, 0.9), true)

	# Cork
	draw_rect(Rect2(-6, -24 + bob, 12, 8), Color(0.75, 0.55, 0.2), true)

	# Shine highlight
	draw_rect(Rect2(-7, -4 + bob, 3, 10), Color(1, 1, 1, 0.25), true)

	# Particle sparkles
	for i in range(4):
		var angle := _time * 2.0 + i * TAU / 4.0
		var dist := 18.0 + sin(_time * 3.0 + i) * 5.0
		var px := cos(angle) * dist
		var py := sin(angle) * dist + bob
		var pa := 0.4 + 0.4 * sin(_time * 4.0 + i)
		draw_circle(Vector2(px, py), 2.5, Color(_color.r, _color.g, _color.b, pa))
