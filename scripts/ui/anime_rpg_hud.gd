## AnimeRPGHUD.gd
## Polished anime fantasy RPG interface inspired by Genshin Impact.
## Includes character status card with portrait, stamina meter, elemental burst gauge,
## boss health bar, quest tracker, and action cluster for desktop & mobile.
extends CanvasLayer

@onready var portrait_rect: TextureRect = $Root/TopLeft/CharacterCard/Margin/HBox/PortraitFrame/Portrait
@onready var hp_bar: ProgressBar = $Root/TopLeft/CharacterCard/Margin/HBox/VBox/HPBar
@onready var hp_label: Label = $Root/TopLeft/CharacterCard/Margin/HBox/VBox/HPBar/HPLabel
@onready var stamina_bar: ProgressBar = $Root/TopLeft/CharacterCard/Margin/HBox/VBox/StaminaBar
@onready var quest_title: Label = $Root/QuestBox/Margin/VBox/Title
@onready var quest_desc: Label = $Root/QuestBox/Margin/VBox/Desc

# Boss UI
@onready var boss_container: VBoxContainer = $Root/BossBarContainer
@onready var boss_name_label: Label = $Root/BossBarContainer/BossName
@onready var boss_hp_bar: ProgressBar = $Root/BossBarContainer/BossHPBar

# Action Buttons
@onready var btn_attack: Button = $Root/ActionCluster/BtnAttack
@onready var btn_skill: Button = $Root/ActionCluster/BtnSkill
@onready var btn_burst: Button = $Root/ActionCluster/BtnBurst
@onready var btn_dash: Button = $Root/ActionCluster/BtnDash
@onready var btn_jump: Button = $Root/ActionCluster/BtnJump
@onready var btn_pause: Button = $Root/TopRight/BtnPause

# Cooldown indicators
@onready var skill_cd_label: Label = $Root/ActionCluster/BtnSkill/CDLabel

var player_ref: KaelController = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	boss_container.visible = false

	# Connect CombatManager signals
	CombatManager.boss_appeared.connect(_on_boss_appeared)
	CombatManager.boss_health_updated.connect(_on_boss_health_updated)
	CombatManager.boss_defeated.connect(_on_boss_defeated)

	# Connect EventBus3D
	EventBus3D.quest_updated.connect(_on_quest_updated)
	GameManager.health_changed.connect(_on_health_changed)

	if btn_pause:
		btn_pause.pressed.connect(GameManager.toggle_pause)

	# Action button clicks simulate inputs for touch devices
	if btn_attack:
		btn_attack.pressed.connect(func(): Input.action_press("attack"))
	if btn_skill:
		btn_skill.pressed.connect(func(): Input.action_press("elemental_skill"))
	if btn_burst:
		btn_burst.pressed.connect(func(): Input.action_press("elemental_burst"))
	if btn_dash:
		btn_dash.pressed.connect(func(): Input.action_press("dash"))
	if btn_jump:
		btn_jump.pressed.connect(func(): Input.action_press("jump"))

func _process(_delta: float) -> void:
	if player_ref == null and GameManager.player_ref is KaelController:
		player_ref = GameManager.player_ref
		player_ref.stamina_changed.connect(_on_stamina_changed)
		player_ref.energy_changed.connect(_on_energy_changed)

	if player_ref:
		# Update skill cooldown label
		if player_ref.skill_cooldown > 0.0:
			skill_cd_label.visible = true
			skill_cd_label.text = "%.1f" % player_ref.skill_cooldown
			btn_skill.modulate = Color(0.6, 0.6, 0.6, 0.8)
		else:
			skill_cd_label.visible = false
			btn_skill.modulate = Color(1.0, 1.0, 1.0, 1.0)

		# Burst ready glow
		if player_ref.elemental_energy >= player_ref.max_elemental_energy:
			btn_burst.modulate = Color(1.3, 1.3, 0.4, 1.0) # Bright celestial gold
		else:
			btn_burst.modulate = Color(0.7, 0.7, 0.85, 0.8)

func _on_health_changed(hp: int, max_hp: int) -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = hp
	hp_label.text = "%d / %d" % [hp * 290, max_hp * 290]

func _on_stamina_changed(cur: float, max_s: float) -> void:
	stamina_bar.max_value = max_s
	stamina_bar.value = cur

func _on_energy_changed(_cur: float, _max_e: float) -> void:
	pass

func _on_quest_updated(title: String, desc: String) -> void:
	quest_title.text = "✦ " + title
	quest_desc.text = desc

func _on_boss_appeared(b_name: String, cur_hp: int, max_hp: int) -> void:
	boss_container.visible = true
	boss_name_label.text = "⚔️  " + b_name
	boss_hp_bar.max_value = max_hp
	boss_hp_bar.value = cur_hp

func _on_boss_health_updated(cur_hp: int, max_hp: int) -> void:
	boss_hp_bar.max_value = max_hp
	boss_hp_bar.value = cur_hp

func _on_boss_defeated() -> void:
	var tw := create_tween()
	tw.tween_property(boss_container, "modulate:a", 0.0, 1.2)
	await tw.finished
	boss_container.visible = false
	boss_container.modulate.a = 1.0
