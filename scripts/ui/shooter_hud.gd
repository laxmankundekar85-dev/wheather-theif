## ShooterHUD.gd
## Master Reusable TPS RPG Gameplay HUD for Weather Thief.
## Unifies player status (Health, Shield, Stamina, Ultimate), tactical crosshair,
## optical sniper scope zoom, weapon ammo counter, mission objective tracker,
## mobile touch controls (virtual joystick, sprint, fire, aim, scope, reload, abilities),
## and game-over respawn overlay across all 55 campaign missions.
extends CanvasLayer
class_name ShooterHUD

@onready var crosshair: Node = $CrosshairContainer/CrosshairReticle
@onready var sniper_scope: Control = $SniperScopeOverlay
@onready var hp_bar: ProgressBar = $StatusCluster/VBox/HPBar
@onready var shield_bar: ProgressBar = $StatusCluster/VBox/ShieldBar
@onready var hp_label: Label = $StatusCluster/VBox/HPBar/Label
@onready var shield_label: Label = $StatusCluster/VBox/ShieldBar/Label

@onready var ammo_label: Label = $WeaponCluster/HBox/AmmoCount
@onready var reserve_label: Label = $WeaponCluster/HBox/ReserveCount
@onready var weapon_name_label: Label = $WeaponCluster/WeaponName
@onready var reload_banner: Label = $WeaponCluster/ReloadBanner

@onready var skill_label: Label = $AbilityCluster/HBox/SkillBox/Label
@onready var ultimate_bar: ProgressBar = $AbilityCluster/HBox/UltBox/UltBar
@onready var ultimate_label: Label = $AbilityCluster/HBox/UltBox/Label

@onready var quest_title: Label = $QuestBox/VBox/Title
@onready var quest_desc: Label = $QuestBox/VBox/Desc

var player: Node = null
var mobile_hud: CanvasLayer = null

func _ready() -> void:
	layer = 10

	# Ensure display HUD elements are touch-transparent so mobile controls receive clean gestures
	for c in find_children("*", "Control", true, false):
		var ctrl := c as Control
		if ctrl and not ("Btn" in ctrl.name or "Button" in ctrl.name or "Editor" in ctrl.name or "Joystick" in ctrl.name):
			ctrl.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if reload_banner:
		reload_banner.visible = false
	if sniper_scope:
		sniper_scope.visible = false

	# Ensure MobileTacticalHUD is instantiated as part of the unified gameplay HUD
	_ensure_mobile_touch_hud()

	# Ensure DeathScreen3D is instantiated for checkpoint recovery
	_ensure_death_screen()

	# Listen for quest tracker updates
	if EventBus3D and not EventBus3D.quest_updated.is_connected(_on_quest_updated):
		EventBus3D.quest_updated.connect(_on_quest_updated)

	# Initial sync attempt
	_sync_player_state()

func _ensure_mobile_touch_hud() -> void:
	mobile_hud = get_node_or_null("MobileTacticalHUD") as CanvasLayer
	if not mobile_hud:
		var parent = get_parent()
		if parent:
			mobile_hud = parent.get_node_or_null("MobileTacticalHUD") as CanvasLayer

	if not mobile_hud:
		var mobile_scn := load("res://scenes/ui/mobile_tactical_hud.tscn") as PackedScene
		if mobile_scn:
			mobile_hud = mobile_scn.instantiate() as CanvasLayer
			mobile_hud.name = "MobileTacticalHUD"
			add_child(mobile_hud)

func _ensure_death_screen() -> void:
	var death_screen := get_node_or_null("DeathScreen3D")
	if not death_screen:
		var parent = get_parent()
		if parent:
			death_screen = parent.get_node_or_null("DeathScreen3D")

	if not death_screen:
		var death_scn := load("res://scenes/ui/death_screen_3d.tscn") as PackedScene
		if death_scn:
			var inst := death_scn.instantiate()
			inst.name = "DeathScreen3D"
			add_child(inst)

func _process(_delta: float) -> void:
	if player == null:
		_sync_player_state()

	if player:
		# Update Weather skill cooldown text
		if skill_label and "weather_skill_cd" in player:
			if player.weather_skill_cd > 0.0:
				skill_label.text = "[Q]RAIN [E]SNOW [F]WIND: %.1fs" % player.weather_skill_cd
				skill_label.modulate = Color(0.7, 0.7, 0.7)
			else:
				skill_label.text = "[Q]RAIN  [E]SNOW  [F]WIND  [C]SUN"
				skill_label.modulate = Color(0.2, 0.85, 1.0)

		# Reticle spread updates
		if crosshair and crosshair.visible and "weapon_manager" in player and player.weapon_manager and player.weapon_manager.active_weapon:
			var w = player.weapon_manager.active_weapon
			crosshair.set_spread_rad(w.get_current_spread_rad(), player.is_aiming)

func _sync_player_state() -> void:
	if GameManager.player_ref != null:
		player = GameManager.player_ref
	elif get_parent():
		player = get_parent().get_node_or_null("KaelShooter")

	if player == null:
		return

	# Connect signals if not yet connected
	if player.has_signal("health_changed") and not player.health_changed.is_connected(_on_health_changed):
		player.health_changed.connect(_on_health_changed)
	if player.has_signal("shield_changed") and not player.shield_changed.is_connected(_on_shield_changed):
		player.shield_changed.connect(_on_shield_changed)
	if player.has_signal("ultimate_changed") and not player.ultimate_changed.is_connected(_on_ultimate_changed):
		player.ultimate_changed.connect(_on_ultimate_changed)
	if player.has_signal("camera_mode_changed") and not player.camera_mode_changed.is_connected(_on_camera_mode_changed):
		player.camera_mode_changed.connect(_on_camera_mode_changed)

	if "weapon_manager" in player and player.weapon_manager:
		var wm: Node = player.weapon_manager
		if not wm.ammo_updated.is_connected(_on_ammo_updated):
			wm.ammo_updated.connect(_on_ammo_updated)
		if not wm.reload_started.is_connected(_on_reload_started):
			wm.reload_started.connect(_on_reload_started)
		if not wm.reload_completed.is_connected(_on_reload_completed):
			wm.reload_completed.connect(_on_reload_completed)
		if not wm.hit_registered.is_connected(_on_hit_registered):
			wm.hit_registered.connect(_on_hit_registered)
		if not wm.active_weapon_changed.is_connected(_on_weapon_changed):
			wm.active_weapon_changed.connect(_on_weapon_changed)
		if wm.active_weapon:
			_on_weapon_changed(wm.active_weapon)

	# Direct synchronous attribute initialization (prevents 0/100 and 0/50 display on mission start)
	var cur_hp: int = int(player.get("current_health")) if "current_health" in player else 100
	var max_hp: int = int(player.get("max_health")) if "max_health" in player else 100
	var cur_sh: int = int(player.get("current_shield")) if "current_shield" in player else 50
	var max_sh: int = int(player.get("max_shield")) if "max_shield" in player else 50
	var cur_ult: float = float(player.get("current_ultimate_energy")) if "current_ultimate_energy" in player else 50.0
	var max_ult: float = float(player.get("max_ultimate_energy")) if "max_ultimate_energy" in player else 100.0

	_on_health_changed(cur_hp, max_hp)
	_on_shield_changed(cur_sh, max_sh)
	_on_ultimate_changed(cur_ult, max_ult)

	var cur_cam_mode: int = int(player.get("camera_mode")) if "camera_mode" in player else 0
	_on_camera_mode_changed(cur_cam_mode)

func _on_camera_mode_changed(mode_index: int) -> void:
	# mode_index: 0 = THIRD_PERSON, 1 = AIMING, 2 = SCOPING
	var is_scoping := (mode_index == 2)
	var is_aiming := (mode_index >= 1)

	if sniper_scope:
		sniper_scope.visible = is_scoping
	if crosshair:
		crosshair.visible = not is_scoping
		if crosshair.has_method("set_spread_rad") and player and "weapon_manager" in player and player.weapon_manager and player.weapon_manager.active_weapon:
			crosshair.set_spread_rad(player.weapon_manager.active_weapon.get_current_spread_rad(), is_aiming)

func _on_weapon_changed(w: Node) -> void:
	if weapon_name_label and w:
		weapon_name_label.text = w.weapon_name.to_upper()
	if w and "current_ammo" in w and "reserve_ammo" in w and "mag_capacity" in w:
		_on_ammo_updated(w.current_ammo, w.reserve_ammo, w.mag_capacity)

func _on_ammo_updated(current: int, reserve: int, _mag_size: int) -> void:
	if ammo_label:
		ammo_label.text = str(current)
		if current <= 5:
			ammo_label.modulate = Color(1.0, 0.25, 0.25)
		else:
			ammo_label.modulate = Color(1.0, 0.95, 0.4)

	if reserve_label:
		reserve_label.text = "/ " + str(reserve)

func _on_reload_started(_duration: float) -> void:
	if reload_banner:
		reload_banner.visible = true

func _on_reload_completed() -> void:
	if reload_banner:
		reload_banner.visible = false

func _on_hit_registered(is_headshot: bool, _dmg: int) -> void:
	if crosshair and crosshair.has_method("show_hitmarker"):
		crosshair.show_hitmarker(is_headshot)

func _on_health_changed(curr: int, max_hp: int) -> void:
	if hp_bar:
		hp_bar.max_value = max_hp
		hp_bar.value = curr
	if hp_label:
		hp_label.text = "HP %d / %d" % [curr, max_hp]

func _on_shield_changed(curr: int, max_sh: int) -> void:
	if shield_bar:
		shield_bar.max_value = max_sh
		shield_bar.value = curr
	if shield_label:
		shield_label.text = "SHIELD %d / %d" % [curr, max_sh]

func _on_ultimate_changed(curr: float, max_u: float) -> void:
	if ultimate_bar:
		ultimate_bar.max_value = max_u
		ultimate_bar.value = curr
	if ultimate_label:
		if curr >= max_u:
			ultimate_label.text = "⚡ [G] STORM ULTIMATE: READY!"
			ultimate_label.modulate = Color(1.0, 0.85, 0.2)
		else:
			ultimate_label.text = "⚡ [G] STORM: %d%%" % int((curr / max_u) * 100.0)
			ultimate_label.modulate = Color(0.8, 0.8, 0.8)

func _on_quest_updated(title: String, desc: String) -> void:
	if quest_title:
		quest_title.text = "◆ " + title
	if quest_desc:
		quest_desc.text = desc
