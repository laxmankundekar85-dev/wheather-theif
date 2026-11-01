## SceneTransition.gd
## Global autoload for smooth fade-in/fade-out scene transitions.
extends CanvasLayer

var _fade_rect: ColorRect
var _is_transitioning: bool = false

signal transition_finished

func _ready() -> void:
	layer = 100  # Always on top

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color(0.02, 0.02, 0.08, 0.0)
	_fade_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_fade_rect)
	print("[SceneTransition] Initialized.")

func is_transitioning() -> bool:
	return _is_transitioning

func change_scene_to_file(path: String, duration: float = 0.4) -> void:
	fade_to_scene(path, duration)

func fade_to_scene(path: String, duration: float = 0.5) -> void:
	if _is_transitioning:
		return
	if not ResourceLoader.exists(path):
		push_error("[SceneTransition] Target scene does not exist: %s" % path)
		return

	_is_transitioning = true
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP

	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_fade_rect, "color:a", 1.0, duration * 0.45)
	await tween.finished

	# Ensure game is unpaused before loading next scene
	get_tree().paused = false
	if GameManager:
		GameManager.is_paused = false
		GameManager.go_to_scene(path)
	else:
		get_tree().change_scene_to_file(path)

	await get_tree().process_frame
	await get_tree().process_frame

	var tween2 := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween2.tween_property(_fade_rect, "color:a", 0.0, duration * 0.45)
	await tween2.finished

	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_is_transitioning = false
	emit_signal("transition_finished")

func fade_in(duration: float = 0.35) -> void:
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade_rect.color.a = 1.0
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_fade_rect, "color:a", 0.0, duration)

func fade_out(duration: float = 0.35) -> void:
	_fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(_fade_rect, "color:a", 1.0, duration)
