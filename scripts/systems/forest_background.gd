## ForestBackground.gd
## Procedurally draws the Forgotten Forest background with trees, hills, stars.
## Attach to a Node2D in the parallax layer.
extends Node2D

var _time: float = 0.0

# Colors
const SKY_TOP    := Color(0.05, 0.08, 0.18)
const SKY_BOT    := Color(0.08, 0.18, 0.12)
const HILL_FAR   := Color(0.06, 0.20, 0.08)
const HILL_MID   := Color(0.09, 0.28, 0.11)
const HILL_NEAR  := Color(0.12, 0.35, 0.14)
const TREE_DARK  := Color(0.05, 0.15, 0.06)
const TREE_MID   := Color(0.08, 0.22, 0.09)
const MOON_COLOR := Color(0.92, 0.95, 0.75)

var _stars: Array[Vector2] = []
var _star_sizes: Array[float] = []
var _trees_far: Array[Vector2] = []
var _trees_mid: Array[Vector2] = []

func _ready() -> void:
	_generate_stars(80)
	_generate_trees_far(20)
	_generate_trees_mid(14)

func _generate_stars(count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for _i in range(count):
		_stars.append(Vector2(rng.randf_range(-640, 2560), rng.randf_range(-360, 200)))
		_star_sizes.append(rng.randf_range(1.0, 3.0))

func _generate_trees_far(count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 99
	for i in range(count):
		_trees_far.append(Vector2(i * 130 + rng.randf_range(-20, 20), rng.randf_range(150, 200)))

func _generate_trees_mid(count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in range(count):
		_trees_mid.append(Vector2(i * 180 + rng.randf_range(-30, 30), rng.randf_range(220, 260)))

func _process(delta: float) -> void:
	_time += delta
	queue_redraw()

func _draw() -> void:
	var w := 2560.0
	var h := 720.0

	# Sky gradient (manual two-rect gradient)
	draw_rect(Rect2(-320, -360, w, h * 0.6), SKY_TOP)
	draw_rect(Rect2(-320, -360 + h * 0.4, w, h * 0.6), SKY_BOT)

	# Moon
	var moon_wobble := sin(_time * 0.3) * 3.0
	draw_circle(Vector2(1800, -180 + moon_wobble), 38, MOON_COLOR)
	draw_circle(Vector2(1820, -195 + moon_wobble), 32, SKY_TOP)  # Crescent cutout

	# Stars with twinkle
	for i in range(_stars.size()):
		var twinkle := 0.5 + 0.5 * sin(_time * 2.5 + i * 1.3)
		var sc := Color(0.9, 0.95, 1.0, twinkle * 0.8)
		draw_circle(_stars[i], _star_sizes[i], sc)

	# Far hills
	_draw_hill_row(-320, 380, w, 180, HILL_FAR)

	# Far trees
	for pos in _trees_far:
		_draw_tree(pos, 55, 70, TREE_DARK, 0.6)

	# Mid hills
	_draw_hill_row(-320, 300, w, 150, HILL_MID)

	# Mid trees with gentle sway
	for i in range(_trees_mid.size()):
		var sway := sin(_time * 0.8 + i * 0.7) * 2.0
		var pos := _trees_mid[i] + Vector2(sway, 0)
		_draw_tree(pos, 80, 100, TREE_MID, 0.8)

	# Near grass strip
	draw_rect(Rect2(-320, 300, w, 150), HILL_NEAR)

	# Magical fireflies
	for i in range(12):
		var fx := -320 + fmod(_time * (18 + i * 3) + i * 200, w)
		var fy := 180 + sin(_time * 1.5 + i * 2.1) * 80
		var fg := Color(0.4, 1.0, 0.5, 0.4 + 0.4 * sin(_time * 4.0 + i))
		draw_circle(Vector2(fx, fy), 3.5, fg)

func _draw_hill_row(x: float, y: float, w: float, h: float, color: Color) -> void:
	var points := PackedVector2Array()
	points.append(Vector2(x, y + h))
	var steps := 60
	for i in range(steps + 1):
		var t := float(i) / steps
		var hx := x + t * w
		var hill := sin(t * PI * 3.5) * h * 0.4 + sin(t * PI * 7.0) * h * 0.15
		points.append(Vector2(hx, y - hill))
	points.append(Vector2(x + w, y + h))
	draw_polygon(points, PackedColorArray([color]))

func _draw_tree(pos: Vector2, trunk_h: float, canopy_r: float, color: Color, alpha: float) -> void:
	var c := Color(color.r, color.g, color.b, alpha)
	# Trunk
	draw_rect(Rect2(pos.x - 5, pos.y - trunk_h, 10, trunk_h), Color(c.r * 0.5, c.g * 0.3, c.b * 0.1, alpha))
	# Canopy (triangle-ish with 3 circles)
	draw_circle(Vector2(pos.x, pos.y - trunk_h - canopy_r * 0.5), canopy_r * 0.75, c)
	draw_circle(Vector2(pos.x - canopy_r * 0.4, pos.y - trunk_h - canopy_r * 0.2), canopy_r * 0.6, c)
	draw_circle(Vector2(pos.x + canopy_r * 0.4, pos.y - trunk_h - canopy_r * 0.2), canopy_r * 0.6, c)
