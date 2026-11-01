## DialogueManager.gd
## Narrative dialogue UI system with typewriter effect, character portraits,
## audio blips, and story sequencing. Supports full mouse, mobile touch, and keyboard input.
extends CanvasLayer

@onready var panel: PanelContainer = $DialogueBox
@onready var portrait_rect: TextureRect = $DialogueBox/Margin/HBox/PortraitFrame/Portrait
@onready var name_label: Label = $DialogueBox/Margin/HBox/VBox/Header/SpeakerName
@onready var text_label: RichTextLabel = $DialogueBox/Margin/HBox/VBox/Content
@onready var prompt_label: Label = $DialogueBox/Margin/HBox/VBox/Footer/Prompt
@onready var btn_skip: Button = $DialogueBox/Margin/HBox/VBox/Header/BtnSkip
@onready var btn_continue: Button = $DialogueBox/Margin/HBox/VBox/Footer/BtnContinue

const PORTRAITS: Dictionary = {
	"Kael": "res://assets/ui/kael_portrait.jpg",
	"Lyra": "res://assets/ui/lyra_portrait.jpg",
	"Mira": "res://assets/ui/lyra_portrait.jpg",
	"Elder Bramble": "res://assets/ui/elder_bramble.jpg",
	"Zephyr": "res://assets/ui/kael_portrait.jpg",
}

const SPEAKER_COLORS: Dictionary = {
	"Kael": Color(0.35, 0.85, 1.0),
	"Lyra": Color(0.4, 0.95, 0.8),
	"Mira": Color(0.95, 0.65, 0.85),
	"Elder Bramble": Color(1.0, 0.78, 0.25),
	"Narrator": Color(0.85, 0.6, 1.0),
	"Ancient Tablet": Color(0.4, 0.95, 0.7),
}

var _lines: Array = []
var _current_line_idx: int = 0
var _is_typing: bool = false
var _full_text: String = ""
var _char_index: int = 0
var _type_speed: float = 0.02
var _timer: float = 0.0

func _ready() -> void:
	panel.visible = false
	EventBus3D.show_dialogue.connect(start_dialogue)
	if btn_skip:
		btn_skip.pressed.connect(_on_skip_pressed)
	if btn_continue:
		btn_continue.pressed.connect(_on_continue_pressed)

func start_dialogue(sequence: Array) -> void:
	_lines = sequence
	_current_line_idx = 0
	panel.visible = true
	_show_line(_current_line_idx)

func _show_line(idx: int) -> void:
	if idx >= _lines.size():
		_close_dialogue()
		return

	var line_data: Dictionary = _lines[idx]
	var speaker: String = line_data.get("speaker", "Narrator")
	_full_text = line_data.get("text", "")

	name_label.text = speaker
	var col: Color = SPEAKER_COLORS.get(speaker, Color.WHITE)
	name_label.modulate = col

	# Load portrait
	if speaker in PORTRAITS and ResourceLoader.exists(PORTRAITS[speaker]):
		portrait_rect.texture = load(PORTRAITS[speaker])
		portrait_rect.visible = true
	else:
		portrait_rect.visible = false

	text_label.text = ""
	_char_index = 0
	_is_typing = true
	_timer = 0.0
	prompt_label.text = "Tap to finish..."

func _process(delta: float) -> void:
	if not panel.visible:
		return

	if _is_typing:
		_timer += delta
		if _timer >= _type_speed:
			_timer = 0.0
			_char_index += 1
			text_label.text = _full_text.substr(0, _char_index)
			if _char_index >= _full_text.length():
				_is_typing = false
				prompt_label.text = "Press [E] or [NEXT ▶] to continue"

func _input(event: InputEvent) -> void:
	if not panel.visible:
		return

	var advance := false
	if event is InputEventKey and event.pressed and (event.is_action("interact") or event.keycode == KEY_E or event.is_action("jump") or event.keycode == KEY_SPACE):
		advance = true
	elif event is InputEventScreenTouch and event.pressed:
		# If touch is on dialogue box area, advance
		if panel.get_global_rect().has_point(event.position):
			advance = true

	if advance:
		get_viewport().set_input_as_handled()
		_advance_dialogue()

func _on_continue_pressed() -> void:
	_advance_dialogue()

func _advance_dialogue() -> void:
	if _is_typing:
		# Instantly finish typing current line
		_is_typing = false
		text_label.text = _full_text
		prompt_label.text = "Press [E] or [NEXT ▶] to continue"
	else:
		_current_line_idx += 1
		if _current_line_idx < _lines.size():
			_show_line(_current_line_idx)
		else:
			_close_dialogue()

func _on_skip_pressed() -> void:
	_close_dialogue()

func _close_dialogue() -> void:
	panel.visible = false
	_is_typing = false
	EventBus3D.emit_signal("dialogue_completed")
