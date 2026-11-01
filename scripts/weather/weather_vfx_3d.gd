## WeatherVFX3D.gd
## 3D visual effects for weather powers: Rain, Snow, Wind, and Sun.
extends Node3D

@onready var rain_particles: CPUParticles3D = $RainParticles
@onready var wind_particles: CPUParticles3D = $WindParticles
@onready var sun_flash: OmniLight3D = $SunFlash

func _ready() -> void:
	WeatherManager.weather_activated.connect(_on_weather_activated)
	if rain_particles:
		rain_particles.emitting = false
	if wind_particles:
		wind_particles.emitting = false

func _on_weather_activated(weather_type: String, pos: Variant) -> void:
	var target_pos := Vector3.ZERO
	if pos is Vector3:
		target_pos = pos

	global_position = target_pos

	match weather_type:
		"rain":
			_play_rain_effect()
		"wind":
			_play_wind_effect()
		"sun":
			_play_sun_effect()
		"snow":
			_play_rain_effect() # Snow can reuse particle system with white tint

func _play_rain_effect() -> void:
	if rain_particles:
		rain_particles.global_position = global_position + Vector3(0, 10.0, 0)
		rain_particles.restart()
		rain_particles.emitting = true

func _play_wind_effect() -> void:
	if wind_particles:
		wind_particles.global_position = global_position
		wind_particles.restart()
		wind_particles.emitting = true

func _play_sun_effect() -> void:
	if sun_flash:
		sun_flash.global_position = global_position + Vector3(0, 4.0, 0)
		sun_flash.light_energy = 5.0
		var tw := create_tween()
		tw.tween_property(sun_flash, "light_energy", 0.0, 1.2)
