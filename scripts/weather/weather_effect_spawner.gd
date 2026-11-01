## WeatherEffectSpawner.gd
## Attached to the player's WeatherEffectSpawner node.
## Listens for weather_activated signal and spawns vibrant visual effects,
## while also notifying nearby interactive environmental objects.
extends Node2D

@export var effect_radius: float = 380.0

func _ready() -> void:
	WeatherManager.weather_activated.connect(_on_weather_activated)

func _on_weather_activated(weather_type: String, activation_position: Vector2) -> void:
	match weather_type:
		WeatherManager.WEATHER_RAIN:
			_spawn_rain_effect(activation_position)
		WeatherManager.WEATHER_SNOW:
			_spawn_snow_effect(activation_position)
		WeatherManager.WEATHER_WIND:
			_spawn_wind_effect(activation_position)
		WeatherManager.WEATHER_SUN:
			_spawn_sun_effect(activation_position)

	# Trigger environmental interactions in radius
	_interact_with_environment(weather_type, activation_position)

func _spawn_rain_effect(pos: Vector2) -> void:
	var container := Node2D.new()
	container.global_position = pos
	get_tree().current_scene.add_child(container)

	# Rain drops falling
	var drops := CPUParticles2D.new()
	drops.amount = 80
	drops.lifetime = 0.9
	drops.one_shot = true
	drops.explosiveness = 0.4
	drops.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	drops.emission_rect_extents = Vector2(240, 20)
	drops.position = Vector2(0, -180)
	drops.direction = Vector2(0.2, 1.0)
	drops.spread = 10.0
	drops.initial_velocity_min = 380.0
	drops.initial_velocity_max = 520.0
	drops.gravity = Vector2(0, 500)
	drops.color = Color(0.25, 0.65, 1.0, 0.9)
	drops.scale_amount_min = 2.5
	drops.scale_amount_max = 4.5
	container.add_child(drops)
	drops.emitting = true

	# Ground splash rings
	var splash := CPUParticles2D.new()
	splash.amount = 45
	splash.lifetime = 0.6
	splash.one_shot = true
	splash.explosiveness = 0.8
	splash.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	splash.emission_rect_extents = Vector2(220, 10)
	splash.position = Vector2(0, 40)
	splash.direction = Vector2(0, -1)
	splash.spread = 60.0
	splash.initial_velocity_min = 80.0
	splash.initial_velocity_max = 160.0
	splash.color = Color(0.6, 0.85, 1.0, 0.8)
	splash.scale_amount_min = 1.5
	splash.scale_amount_max = 3.0
	container.add_child(splash)
	splash.emitting = true

	_auto_cleanup(container, 1.5)

func _spawn_snow_effect(pos: Vector2) -> void:
	var container := Node2D.new()
	container.global_position = pos
	get_tree().current_scene.add_child(container)

	# Frost cloud
	var frost := CPUParticles2D.new()
	frost.amount = 70
	frost.lifetime = 1.4
	frost.one_shot = true
	frost.explosiveness = 0.3
	frost.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	frost.emission_sphere_radius = 160.0
	frost.gravity = Vector2(0, 40)
	frost.initial_velocity_min = 20.0
	frost.initial_velocity_max = 70.0
	frost.spread = 180.0
	frost.color = Color(0.85, 0.95, 1.0, 0.85)
	frost.scale_amount_min = 3.0
	frost.scale_amount_max = 6.0
	container.add_child(frost)
	frost.emitting = true

	# Ice crystals burst
	var crystals := CPUParticles2D.new()
	crystals.amount = 35
	crystals.lifetime = 1.0
	crystals.one_shot = true
	crystals.explosiveness = 0.7
	crystals.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	crystals.emission_sphere_radius = 40.0
	crystals.spread = 180.0
	crystals.initial_velocity_min = 120.0
	crystals.initial_velocity_max = 240.0
	crystals.gravity = Vector2(0, 60)
	crystals.color = Color(0.7, 0.9, 1.0, 1.0)
	crystals.scale_amount_min = 4.0
	crystals.scale_amount_max = 8.0
	container.add_child(crystals)
	crystals.emitting = true

	_auto_cleanup(container, 1.8)

func _spawn_wind_effect(pos: Vector2) -> void:
	var container := Node2D.new()
	container.global_position = pos
	get_tree().current_scene.add_child(container)

	# Swirling air currents
	var wind := CPUParticles2D.new()
	wind.amount = 65
	wind.lifetime = 1.0
	wind.one_shot = true
	wind.explosiveness = 0.4
	wind.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	wind.emission_sphere_radius = 50.0
	wind.direction = Vector2(1, -0.3)
	wind.spread = 45.0
	wind.initial_velocity_min = 260.0
	wind.initial_velocity_max = 480.0
	wind.gravity = Vector2(150, -80)
	wind.color = Color(0.65, 1.0, 0.7, 0.85)
	wind.scale_amount_min = 3.0
	wind.scale_amount_max = 7.0
	container.add_child(wind)
	wind.emitting = true

	# Swirling leaves
	var leaves := CPUParticles2D.new()
	leaves.amount = 25
	leaves.lifetime = 1.3
	leaves.one_shot = true
	leaves.explosiveness = 0.6
	leaves.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	leaves.emission_sphere_radius = 30.0
	leaves.direction = Vector2(1, -0.5)
	leaves.spread = 60.0
	leaves.initial_velocity_min = 180.0
	leaves.initial_velocity_max = 350.0
	leaves.gravity = Vector2(80, 20)
	leaves.angular_velocity_min = 120.0
	leaves.angular_velocity_max = 360.0
	leaves.color = Color(0.3, 0.85, 0.35, 0.9)
	leaves.scale_amount_min = 4.0
	leaves.scale_amount_max = 8.0
	container.add_child(leaves)
	leaves.emitting = true

	_auto_cleanup(container, 1.6)

func _spawn_sun_effect(pos: Vector2) -> void:
	var container := Node2D.new()
	container.global_position = pos
	get_tree().current_scene.add_child(container)

	# Radiant sun rays burst
	var sun := CPUParticles2D.new()
	sun.amount = 70
	sun.lifetime = 1.2
	sun.one_shot = true
	sun.explosiveness = 0.85
	sun.emission_shape = CPUParticles2D.EMISSION_SHAPE_SPHERE
	sun.emission_sphere_radius = 20.0
	sun.spread = 180.0
	sun.initial_velocity_min = 180.0
	sun.initial_velocity_max = 340.0
	sun.gravity = Vector2(0, -60)
	sun.color = Color(1.0, 0.9, 0.3, 0.95)
	sun.scale_amount_min = 4.0
	sun.scale_amount_max = 9.0
	container.add_child(sun)
	sun.emitting = true

	# Golden upward sparkles
	var sparkles := CPUParticles2D.new()
	sparkles.amount = 40
	sparkles.lifetime = 1.5
	sparkles.one_shot = true
	sparkles.explosiveness = 0.2
	sparkles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	sparkles.emission_rect_extents = Vector2(180, 40)
	sparkles.direction = Vector2(0, -1)
	sparkles.spread = 25.0
	sparkles.initial_velocity_min = 60.0
	sparkles.initial_velocity_max = 140.0
	sparkles.gravity = Vector2(0, -80)
	sparkles.color = Color(1.0, 0.98, 0.6, 0.9)
	sparkles.scale_amount_min = 2.0
	sparkles.scale_amount_max = 5.0
	container.add_child(sparkles)
	sparkles.emitting = true

	_auto_cleanup(container, 1.8)

func _interact_with_environment(weather_type: String, pos: Vector2) -> void:
	# Check all environmental puzzle elements and enemies in radius
	var tree := get_tree()
	if tree == null:
		return

	# 1. Plants (Rain makes dry plants grow into leafy platforms)
	if weather_type == WeatherManager.WEATHER_RAIN:
		for plant in tree.get_nodes_in_group("dry_plant"):
			if plant.global_position.distance_to(pos) <= effect_radius:
				if plant.has_method("grow"):
					plant.grow()

	# 2. Water / Rivers (Snow freezes them into ice platforms, Sun melts them back)
	for water in tree.get_nodes_in_group("water_hazard"):
		if water.global_position.distance_to(pos) <= effect_radius:
			if weather_type == WeatherManager.WEATHER_SNOW and water.has_method("freeze"):
				water.freeze()
			elif weather_type == WeatherManager.WEATHER_SUN and water.has_method("melt"):
				water.melt()

	# 3. Ice Barriers (Sun melts ice walls)
	if weather_type == WeatherManager.WEATHER_SUN:
		for barrier in tree.get_nodes_in_group("ice_barrier"):
			if barrier.global_position.distance_to(pos) <= effect_radius:
				if barrier.has_method("melt"):
					barrier.melt()

	# 4. Wind Platforms / Windmills (Wind moves floating platforms or spins windmills)
	if weather_type == WeatherManager.WEATHER_WIND:
		for wind_elem in tree.get_nodes_in_group("wind_activated"):
			if wind_elem.global_position.distance_to(pos) <= effect_radius:
				if wind_elem.has_method("activate_wind"):
					wind_elem.activate_wind()

	# 5. Sun Monoliths / Ancient Machinery
	if weather_type == WeatherManager.WEATHER_SUN:
		for monolith in tree.get_nodes_in_group("sun_monolith"):
			if monolith.global_position.distance_to(pos) <= effect_radius:
				if monolith.has_method("activate_sun"):
					monolith.activate_sun()

	# 6. Enemies (Weather interactions with enemies!)
	for enemy in tree.get_nodes_in_group("enemies"):
		if enemy.global_position.distance_to(pos) <= effect_radius:
			if enemy.has_method("on_weather_hit"):
				enemy.on_weather_hit(weather_type)

func _auto_cleanup(node: Node2D, delay: float) -> void:
	var t := get_tree().create_timer(delay)
	t.timeout.connect(node.queue_free)
