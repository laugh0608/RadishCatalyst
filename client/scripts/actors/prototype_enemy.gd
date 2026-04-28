extends CharacterBody2D
class_name PrototypeEnemy

@export var definition_id: String = "enemy.native_skitter"

var health: float = 20.0
var max_health: float = 20.0
var display_name: String = ""
var instance_id: String = ""
var defeated: bool = false

@onready var label: Label = $Label
@onready var sprite: ColorRect = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func setup(display_name: String, max_health: float) -> void:
	self.display_name = display_name
	self.max_health = max_health
	health = max_health
	defeated = false
	collision_shape.disabled = false
	sprite.color = Color(0.8, 0.313726, 0.215686, 1)
	_update_label()


func apply_hit(amount: float) -> Dictionary:
	if defeated:
		return {
			"defeated": true,
			"health": health
		}

	health = maxf(0.0, health - amount)
	if health <= 0.0:
		mark_defeated()
	else:
		_update_label()

	return {
		"defeated": defeated,
		"health": health
	}


func apply_saved_state(enemy_state: Dictionary) -> void:
	health = float(enemy_state.get("health", health))
	defeated = bool(enemy_state.get("is_defeated", false))
	if defeated:
		mark_defeated()
	else:
		_update_label()


func can_be_attacked() -> bool:
	return not defeated


func mark_defeated() -> void:
	defeated = true
	health = 0.0
	collision_shape.set_deferred("disabled", true)
	sprite.color = Color(0.2, 0.2, 0.2, 1)
	label.text = "%s\n已击败" % display_name


func _update_label() -> void:
	label.text = "%s\nHP %.0f / %.0f" % [display_name, health, max_health]
