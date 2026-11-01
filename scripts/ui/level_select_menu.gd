## LevelSelectMenu.gd
## Comprehensive 55-Level Campaign Mission Selection Interface.
## Features region tabs (Forgotten District, Frozen Mountains, Sky Islands, Sunken Desert, Storm Kingdom),
## live unlock verification, completion status, rewards, best records, desktop mouse and mobile touch controls.
extends Control

const CampaignDatabase = preload("res://scripts/campaign/campaign_database.gd")

@onready var cards_container: VBoxContainer = $Margin/VBox/Scroll/CardsContainer
@onready var btn_back: Button = $Margin/VBox/Header/BtnBack
@onready var region_tabs_container: HBoxContainer = $Margin/VBox/RegionTabs
@onready var label_region_info: Label = $Margin/VBox/RegionInfo

var active_region_id: String = "region_1"

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if btn_back:
		btn_back.pressed.connect(_on_back_pressed)

	_setup_region_tabs()
	_populate_levels_for_active_region()

func _setup_region_tabs() -> void:
	if not region_tabs_container:
		return

	for child in region_tabs_container.get_children():
		child.queue_free()

	for r_key in CampaignDatabase.REGIONS:
		var reg_info: Dictionary = CampaignDatabase.REGIONS[r_key]
		var btn := Button.new()
		btn.text = reg_info["name"].to_upper()
		btn.custom_minimum_size = Vector2(180, 42)
		btn.add_theme_font_size_override("font_size", 13)

		var style_normal := StyleBoxFlat.new()
		style_normal.bg_color = Color(0.1, 0.14, 0.22, 0.9)
		style_normal.border_width_bottom = 3
		style_normal.border_color = reg_info.get("theme_color", Color(0.2, 0.8, 1))
		style_normal.corner_radius_top_left = 6
		style_normal.corner_radius_top_right = 6
		btn.add_theme_stylebox_override("normal", style_normal)

		btn.pressed.connect(func(): _switch_region(r_key))
		region_tabs_container.add_child(btn)

func _switch_region(reg_id: String) -> void:
	AudioManager.play_sound("button_click")
	active_region_id = reg_id
	_populate_levels_for_active_region()

func _populate_levels_for_active_region() -> void:
	if not cards_container:
		return

	for child in cards_container.get_children():
		child.queue_free()

	var reg_info: Dictionary = CampaignDatabase.REGIONS.get(active_region_id, {})
	if label_region_info:
		label_region_info.text = "%s — %s (Levels %d - %d)" % [
			reg_info.get("name", ""),
			reg_info.get("description", ""),
			reg_info["level_range"][0],
			reg_info["level_range"][1]
		]
		label_region_info.modulate = reg_info.get("theme_color", Color.WHITE)

	var region_levels: Array[Dictionary] = CampaignDatabase.get_levels_for_region(active_region_id)

	for lvl in region_levels:
		var idx: int = lvl["index"]
		var is_unlocked: bool = LevelManager.is_level_unlocked(idx) if LevelManager else (idx <= 1)
		var is_completed: bool = SaveManager.is_level_completed(idx) if SaveManager else false
		var best_score: Dictionary = SaveManager.get_level_score(idx) if SaveManager else {}

		var card := PanelContainer.new()
		var card_style := StyleBoxFlat.new()

		if is_completed:
			card_style.bg_color = Color(0.05, 0.12, 0.15, 0.92)
			card_style.border_color = Color(0.3, 1.0, 0.6, 0.8)
		elif is_unlocked:
			card_style.bg_color = Color(0.06, 0.09, 0.16, 0.92)
			card_style.border_color = Color(0.2, 0.8, 1.0, 0.8)
		else:
			card_style.bg_color = Color(0.03, 0.04, 0.07, 0.6)
			card_style.border_color = Color(0.2, 0.25, 0.35, 0.4)

		card_style.border_width_left = 2
		card_style.border_width_top = 2
		card_style.border_width_right = 2
		card_style.border_width_bottom = 2
		card_style.corner_radius_top_left = 10
		card_style.corner_radius_top_right = 10
		card_style.corner_radius_bottom_right = 10
		card_style.corner_radius_bottom_left = 10
		card.add_theme_stylebox_override("panel", card_style)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 16)
		margin.add_theme_constant_override("margin_top", 12)
		margin.add_theme_constant_override("margin_right", 16)
		margin.add_theme_constant_override("margin_bottom", 12)
		card.add_child(margin)

		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 16)
		margin.add_child(hbox)

		# Text Column
		var vbox := VBoxContainer.new()
		vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		vbox.add_theme_constant_override("separation", 4)
		hbox.add_child(vbox)

		var title := Label.new()
		var status_badge := "[COMPLETED ✦]" if is_completed else ("[UNLOCKED]" if is_unlocked else "[LOCKED 🔒]")
		title.text = "LEVEL %d: %s %s" % [idx, lvl["name"].to_upper(), status_badge]
		title.add_theme_font_size_override("font_size", 16)
		title.add_theme_color_override("font_color", Color(0.3, 1.0, 0.6) if is_completed else (Color(0.3, 0.9, 1.0) if is_unlocked else Color(0.45, 0.5, 0.6)))
		vbox.add_child(title)

		var desc := Label.new()
		desc.text = lvl["description"]
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.add_theme_font_size_override("font_size", 13)
		desc.add_theme_color_override("font_color", Color(0.85, 0.9, 0.98) if is_unlocked else Color(0.4, 0.45, 0.55))
		vbox.add_child(desc)

		var obj_label := Label.new()
		obj_label.text = "Objective: %s | Reward: +%d XP, +%d Shards" % [lvl["main_objective"], lvl["reward_xp"], lvl["reward_shards"]]
		obj_label.add_theme_font_size_override("font_size", 12)
		obj_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.35) if is_unlocked else Color(0.35, 0.35, 0.4))
		vbox.add_child(obj_label)

		if not best_score.is_empty():
			var best_lbl := Label.new()
			var b_time: float = best_score.get("time_seconds", 0.0)
			var b_mins: int = int(b_time / 60.0)
			var b_secs: int = int(b_time) % 60
			var b_acc: float = best_score.get("accuracy", 0.0)
			best_lbl.text = "Best Record: %02d:%02d | Accuracy: %.1f%%" % [b_mins, b_secs, b_acc]
			best_lbl.add_theme_font_size_override("font_size", 11)
			best_lbl.add_theme_color_override("font_color", Color(0.4, 1.0, 0.7))
			vbox.add_child(best_lbl)

		# Action Button
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(160, 44)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER

		if is_unlocked:
			btn.text = "REPLAY ↺" if is_completed else "DEPLOY ▶"
			var b_style := StyleBoxFlat.new()
			b_style.bg_color = Color(0.12, 0.55, 0.95, 1) if not is_completed else Color(0.15, 0.45, 0.35, 1)
			b_style.corner_radius_top_left = 6
			b_style.corner_radius_top_right = 6
			b_style.corner_radius_bottom_right = 6
			b_style.corner_radius_bottom_left = 6
			btn.add_theme_stylebox_override("normal", b_style)
			btn.add_theme_font_size_override("font_size", 14)
			btn.pressed.connect(func(): _launch_level(idx))
		else:
			btn.text = "LOCKED 🔒"
			btn.disabled = true
			var b_style := StyleBoxFlat.new()
			b_style.bg_color = Color(0.12, 0.15, 0.2, 0.6)
			b_style.corner_radius_top_left = 6
			b_style.corner_radius_top_right = 6
			b_style.corner_radius_bottom_right = 6
			b_style.corner_radius_bottom_left = 6
			btn.add_theme_stylebox_override("disabled", b_style)
			btn.add_theme_color_override("font_disabled_color", Color(0.45, 0.5, 0.6))

		hbox.add_child(btn)
		cards_container.add_child(card)

func _launch_level(level_idx: int) -> void:
	AudioManager.play_sound("click")
	if LevelManager:
		LevelManager.start_level(level_idx)

func _on_back_pressed() -> void:
	AudioManager.play_sound("button_click")
	var main_scn := "res://scenes/levels/verdantia_combat_outpost.tscn"
	if SceneTransition:
		SceneTransition.change_scene_to_file(main_scn)
	else:
		get_tree().change_scene_to_file(main_scn)
