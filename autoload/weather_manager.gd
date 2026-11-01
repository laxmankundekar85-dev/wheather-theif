## WeatherManager.gd
## Global autoload managing all weather powers: unlocking, switching, charging, activation.
extends Node

signal weather_unlocked(weather_type: String)
signal weather_switched(weather_type: String)
signal weather_activated(weather_type: String, position: Variant)
signal charges_changed(weather_type: String, current: int, maximum: int)

# Weather types enum-like constants
const WEATHER_RAIN  = "rain"
const WEATHER_SNOW  = "snow"
const WEATHER_WIND  = "wind"
const WEATHER_SUN   = "sun"

const WEATHER_ORDER: Array[String] = [WEATHER_RAIN, WEATHER_SNOW, WEATHER_WIND, WEATHER_SUN]

const MAX_CHARGES: Dictionary = {
	WEATHER_RAIN: 5,
	WEATHER_SNOW: 5,
	WEATHER_WIND: 5,
	WEATHER_SUN:  5,
}

const COOLDOWN_TIME: Dictionary = {
	WEATHER_RAIN: 1.5,
	WEATHER_SNOW: 2.0,
	WEATHER_WIND: 1.8,
	WEATHER_SUN:  1.5,
}

# Weather colors for UI / particles
const WEATHER_COLORS: Dictionary = {
	WEATHER_RAIN: Color(0.2, 0.5, 1.0),
	WEATHER_SNOW: Color(0.8, 0.9, 1.0),
	WEATHER_WIND: Color(0.7, 1.0, 0.7),
	WEATHER_SUN:  Color(1.0, 0.85, 0.2),
}

# State
var unlocked_weathers: Array[String] = []
var current_weather: String = ""
var charges: Dictionary = {}
var cooldowns: Dictionary = {}
var is_on_cooldown: Dictionary = {}

func _ready() -> void:
	for w in WEATHER_ORDER:
		charges[w] = 0
		cooldowns[w] = 0.0
		is_on_cooldown[w] = false
	print("[WeatherManager] Initialized.")

func _process(delta: float) -> void:
	# Tick cooldowns
	for w in WEATHER_ORDER:
		if is_on_cooldown[w]:
			cooldowns[w] -= delta
			if cooldowns[w] <= 0.0:
				cooldowns[w] = 0.0
				is_on_cooldown[w] = false

func unlock_weather(weather_type: String) -> void:
	if weather_type not in unlocked_weathers:
		unlocked_weathers.append(weather_type)
		charges[weather_type] = MAX_CHARGES[weather_type]
		emit_signal("weather_unlocked", weather_type)
		if current_weather == "":
			current_weather = weather_type
			emit_signal("weather_switched", weather_type)
		print("[WeatherManager] Unlocked: ", weather_type)

func add_charges(weather_type: String, amount: int) -> void:
	if weather_type in charges:
		charges[weather_type] = min(charges[weather_type] + amount, MAX_CHARGES[weather_type])
		emit_signal("charges_changed", weather_type, charges[weather_type], MAX_CHARGES[weather_type])

func switch_to_next() -> void:
	if unlocked_weathers.size() <= 1:
		return
	var idx := unlocked_weathers.find(current_weather)
	idx = (idx + 1) % unlocked_weathers.size()
	current_weather = unlocked_weathers[idx]
	emit_signal("weather_switched", current_weather)

func switch_to_previous() -> void:
	if unlocked_weathers.size() <= 1:
		return
	var idx := unlocked_weathers.find(current_weather)
	idx = (idx - 1 + unlocked_weathers.size()) % unlocked_weathers.size()
	current_weather = unlocked_weathers[idx]
	emit_signal("weather_switched", current_weather)

func can_activate() -> bool:
	if current_weather == "":
		return false
	if current_weather not in unlocked_weathers:
		return false
	if charges[current_weather] <= 0:
		return false
	if is_on_cooldown[current_weather]:
		return false
	return true

func activate_weather(activation_position: Variant = Vector3.ZERO) -> bool:
	if not can_activate():
		return false
	charges[current_weather] -= 1
	is_on_cooldown[current_weather] = true
	cooldowns[current_weather] = COOLDOWN_TIME[current_weather]
	AudioManager.play_sound("weather_" + current_weather)
	emit_signal("charges_changed", current_weather, charges[current_weather], MAX_CHARGES[current_weather])
	emit_signal("weather_activated", current_weather, activation_position)
	return true

func get_cooldown_fraction(weather_type: String) -> float:
	if not is_on_cooldown[weather_type]:
		return 0.0
	return cooldowns[weather_type] / COOLDOWN_TIME[weather_type]
