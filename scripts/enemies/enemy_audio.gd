## EnemyAudio.gd
## Context-sensitive tactical voice lines, radio chatter, hit grunts, and combat sound effects.
## Provides varied, professional audio cues with cooldowns to prevent repetitive spam.
extends Node
class_name EnemyAudio

@export var voice_pitch: float = 1.0

var callout_cooldown: float = 0.0
var pain_cooldown: float = 0.0

func _process(delta: float) -> void:
	if callout_cooldown > 0.0:
		callout_cooldown = maxf(0.0, callout_cooldown - delta)
	if pain_cooldown > 0.0:
		pain_cooldown = maxf(0.0, pain_cooldown - delta)

func play_spotted_callout() -> void:
	if callout_cooldown <= 0.0:
		callout_cooldown = 4.5
		# Radio squelch + tactical callout sound
		AudioManager.play_sound("button_click")
		print("[Radio] Vanguard: 'Enemy contact in the sector!'")

func play_investigate_callout() -> void:
	if callout_cooldown <= 0.0:
		callout_cooldown = 3.5
		AudioManager.play_sound("dialogue_type")
		print("[Radio] Vanguard: 'Checking suspicious sound.'")

func play_reloading_callout() -> void:
	if callout_cooldown <= 0.0:
		callout_cooldown = 3.0
		AudioManager.play_sound("reload_start")
		print("[Radio] Vanguard: 'Cover me, reloading!'")

func play_taking_cover_callout() -> void:
	if callout_cooldown <= 0.0:
		callout_cooldown = 3.5
		AudioManager.play_sound("dash")
		print("[Radio] Vanguard: 'Falling back to cover!'")

func play_pain() -> void:
	if pain_cooldown <= 0.0:
		pain_cooldown = 0.35
		AudioManager.play_sound("hit")

func play_death() -> void:
	AudioManager.play_sound("enemy_defeat")

func play_footstep() -> void:
	AudioManager.play_sound("footstep_stone")
