## CrosshairReticle.gd
## Dynamic AAA Tactical Shooter Reticle (Valorant-inspired).
## Expands with weapon bloom / movement and contracts during ADS aiming.
## Includes instant hitmarker feedback with distinct headshot confirmation.
extends Control
class_name CrosshairReticle

@export var reticle_color: Color = Color(0.2, 0.95, 0.9, 0.9) # Tactical cyan
@export var line_length: float = 7.0
@export var line_thickness: float = 2.0
@export var center_dot: bool = true
@export var dot_radius: float = 1.5

var current_gap: float = 5.0
var target_gap: float = 5.0

# Hitmarker
var hitmarker_alpha: float = 0.0
var hitmarker_color: Color = Color.WHITE
var hitmarker_size: float = 10.0

func _process(delta: float) -> void:
	current_gap = lerp(current_gap, target_gap, delta * 24.0)

	if hitmarker_alpha > 0.0:
		hitmarker_alpha = max(0.0, hitmarker_alpha - delta * 5.0)

	queue_redraw()

func set_spread_rad(spread_rad: float, is_aiming: bool) -> void:
	if is_aiming:
		target_gap = 3.0
	else:
		# Map radians to pixels
		target_gap = clamp(spread_rad * 320.0, 4.0, 36.0)

func show_hitmarker(is_headshot: bool) -> void:
	hitmarker_alpha = 1.0
	if is_headshot:
		hitmarker_color = Color(1.0, 0.2, 0.25, 1.0) # Critical red
		hitmarker_size = 13.0
	else:
		hitmarker_color = Color(1.0, 1.0, 1.0, 1.0) # White
		hitmarker_size = 9.0

func _draw() -> void:
	var center := size * 0.5

	# Center dot
	if center_dot and target_gap > 3.5:
		draw_circle(center, dot_radius, reticle_color)

	# 4 Crosshair lines
	var g := current_gap
	var l := line_length
	var t := line_thickness

	# Top
	draw_line(center - Vector2(0, g), center - Vector2(0, g + l), reticle_color, t)
	# Bottom
	draw_line(center + Vector2(0, g), center + Vector2(0, g + l), reticle_color, t)
	# Left
	draw_line(center - Vector2(g, 0), center - Vector2(g + l, 0), reticle_color, t)
	# Right
	draw_line(center + Vector2(g, 0), center + Vector2(g + l, 0), reticle_color, t)

	# Hitmarker X
	if hitmarker_alpha > 0.0:
		var col := Color(hitmarker_color.r, hitmarker_color.g, hitmarker_color.b, hitmarker_alpha)
		var hs := hitmarker_size
		draw_line(center + Vector2(-hs, -hs), center + Vector2(-3, -3), col, 2.0)
		draw_line(center + Vector2(hs, -hs), center + Vector2(3, -3), col, 2.0)
		draw_line(center + Vector2(-hs, hs), center + Vector2(-3, 3), col, 2.0)
		draw_line(center + Vector2(hs, hs), center + Vector2(3, 3), col, 2.0)

