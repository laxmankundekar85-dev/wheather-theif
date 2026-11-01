## BulletTrail.gd
## High-velocity glowing ballistic tracer beam linking weapon muzzle to impact position.
extends MeshInstance3D
class_name BulletTrail

var lifetime: float = 0.08
var timer: float = 0.0

func init(start_pos: Vector3, end_pos: Vector3, color: Color = Color(1.0, 0.85, 0.35, 0.95)) -> void:
	var im := ImmediateMesh.new()
	mesh = im

	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material_override = mat

	im.surface_begin(Mesh.PRIMITIVE_LINES)
	im.surface_set_color(color)
	im.surface_add_vertex(start_pos)
	im.surface_set_color(Color(color.r, color.g, color.b, 0.2))
	im.surface_add_vertex(end_pos)
	im.surface_end()

func _process(delta: float) -> void:
	timer += delta
	var alpha: float = 1.0 - (timer / lifetime)
	if alpha <= 0.0:
		queue_free()
	elif material_override is StandardMaterial3D:
		material_override.albedo_color.a = alpha

