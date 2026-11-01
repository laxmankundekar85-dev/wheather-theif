## HeartPickup.gd
## Restores 1 health heart to player when collected.
extends Area2D

var _bob_offset: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	_bob_offset += delta * 3.0
	position.y += sin(_bob_offset) * 0.4

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		if GameManager.player_health < GameManager.player_max_health:
			GameManager.heal_player(1)
		AudioManager.play_sound("heart_pickup")
		var tween := create_tween()
		tween.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15)
		tween.tween_property(self, "modulate:a", 0.0, 0.2)
		tween.tween_callback(queue_free)
