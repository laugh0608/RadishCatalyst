extends CharacterBody2D
class_name PrototypeEnemy

@export var definition_id: String = "enemy.native_skitter"

var health: float = 20.0

@onready var label: Label = $Label


func setup(display_name: String, max_health: float) -> void:
	label.text = "%s\nHP %.0f" % [display_name, max_health]
	health = max_health


func apply_hit(amount: float) -> Dictionary:
	health = maxf(0.0, health - amount)
	label.text = "%s\nHP %.0f" % [label.text.split("\n")[0], health]
	return {
		"defeated": health <= 0.0,
		"health": health
	}
