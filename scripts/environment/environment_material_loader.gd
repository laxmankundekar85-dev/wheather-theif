## EnvironmentMaterialLoader.gd
## Runtime PBR texture loader and material binder for Verdantia: The Forgotten District.
## Loads high-resolution stylized textures directly into memory and applies them
## across the architecture, market, overgrown passage, fortress, sunken courtyard, and tunnels.
extends Node
class_name EnvironmentMaterialLoader

static var tex_cache: Dictionary = {}

static func get_tex(path: String) -> Texture2D:
	if tex_cache.has(path):
		return tex_cache[path]
	if ResourceLoader.exists(path):
		var res := load(path) as Texture2D
		if res:
			tex_cache[path] = res
			return res
	var img := Image.load_from_file(path)
	if img and not img.is_empty():
		var tex := ImageTexture.create_from_image(img)
		tex_cache[path] = tex
		return tex
	return null

static func apply_map_materials(root_node: Node) -> void:
	var t_stucco := get_tex("res://assets/environments/stylized_brick_stucco.png")
	var t_tiles := get_tex("res://assets/environments/stylized_terracotta_tiles.png")
	var t_wood := get_tex("res://assets/environments/stylized_weathered_wood_planks.png")
	var t_metal := get_tex("res://assets/environments/stylized_metal_plate.png")
	var t_ivy := get_tex("res://assets/environments/stylized_ivy_foliage.png")
	var t_moss := get_tex("res://assets/environments/stylized_mossy_cobble.png")

	print("[EnvironmentMaterialLoader] Binding stylized PBR textures to scene...")

	for node in root_node.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		if not mi or not mi.mesh:
			continue
		var n_name := mi.name.to_lower()
		var p_name := mi.get_parent().name.to_lower()

		for s in range(mi.mesh.get_surface_count()):
			var mat = mi.get_active_material(s)
			if mat and mat is StandardMaterial3D:
				var m := mat.duplicate() as StandardMaterial3D
				var m_name := m.resource_name.to_lower()

				# 1. Climbing Ivy & Wall Foliage
				if "ivy" in m_name or "leaf" in m_name or "ivy" in n_name:
					if t_ivy:
						m.albedo_texture = t_ivy
						m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
						m.alpha_scissor_threshold = 0.5
						m.cull_mode = BaseMaterial3D.CULL_DISABLED
						m.roughness = 0.75
						mi.set_surface_override_material(s, m)
						continue

				# 2. Wall Plaster & Stucco Facades
				if "stucco" in m_name or "buildingmain" in n_name or "mainmesh" in n_name or "plaster" in m_name:
					if t_stucco:
						m.albedo_texture = t_stucco
						m.albedo_color = Color(0.96, 0.94, 0.90)
						m.uv1_scale = Vector3(10, 8, 10)
						m.roughness = 0.88
						mi.set_surface_override_material(s, m)
						continue

				# 3. Terracotta Roofs & Market Awnings
				if "roof" in m_name or "tile" in m_name or "roof" in n_name or "awning" in n_name:
					if t_tiles:
						m.albedo_texture = t_tiles
						m.albedo_color = Color(0.95, 0.90, 0.85)
						m.uv1_scale = Vector3(12, 8, 12)
						m.roughness = 0.75
						mi.set_surface_override_material(s, m)
						continue

				# 4. Wood Planks (Doors, Shutters, Catwalks, Stalls, Bents)
				if "wood" in m_name or "counter" in n_name or "shutter" in n_name or "timber" in n_name or "door" in n_name or "post" in n_name or "floor" in n_name:
					if t_wood:
						m.albedo_texture = t_wood
						m.albedo_color = Color(0.95, 0.90, 0.85)
						m.uv1_scale = Vector3(4, 4, 4)
						m.roughness = 0.82
						mi.set_surface_override_material(s, m)
						continue

				# 5. Reinforced Metal Plates (Parapets, Armor, Blast Doors)
				if "metal" in m_name or "parapet" in n_name or "plate" in n_name or "iron" in m_name:
					if t_metal:
						m.albedo_texture = t_metal
						m.metallic = 0.85
						m.roughness = 0.45
						mi.set_surface_override_material(s, m)
						continue

				# 6. Mossy Cobbles & Fountain Stone & Tunnels
				if "moss" in m_name or "fountain" in m_name or "basin" in n_name or "tunnel" in m_name or "tunnelwall" in n_name or "pedestal" in n_name:
					if t_moss:
						m.albedo_texture = t_moss
						m.albedo_color = Color(0.92, 0.94, 0.90)
						m.uv1_scale = Vector3(4, 3, 4)
						m.roughness = 0.85
						mi.set_surface_override_material(s, m)
						continue
