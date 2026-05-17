extends CharacterBody2D
class_name PrototypeEnemy

@export var definition_id: String = "enemy.native_skitter"

const DEFEATED_COLOR := Color(0.2, 0.2, 0.2, 1)
const DEFEATED_POLLUTED_COLOR := Color(0.34, 0.32, 0.16, 1)

var health: float = 20.0
var max_health: float = 20.0
var display_name: String = ""
var instance_id: String = ""
var defeated: bool = false
var enemy_category: String = "basic"

@onready var label: Label = $Label
@onready var sprite: ColorRect = $Sprite
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func setup(enemy_display_name: String, enemy_max_health: float, category: String = "basic") -> void:
	display_name = enemy_display_name
	max_health = enemy_max_health
	health = enemy_max_health
	defeated = false
	enemy_category = category
	collision_shape.disabled = false
	sprite.color = _get_active_color(category)
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
	return not defeated and visible


func mark_defeated() -> void:
	defeated = true
	health = 0.0
	collision_shape.set_deferred("disabled", true)
	if enemy_category == "polluted":
		sprite.color = DEFEATED_POLLUTED_COLOR
		label.text = "%s\n污染已压制" % display_name
		return
	sprite.color = DEFEATED_COLOR
	label.text = "%s\n已击败" % display_name


func _update_label() -> void:
	label.text = "%s\nHP %.0f / %.0f" % [display_name, health, max_health]


func set_spawn_enabled(enabled: bool) -> void:
	visible = enabled
	if defeated:
		collision_shape.set_deferred("disabled", true)
		return
	collision_shape.set_deferred("disabled", not enabled)


func _get_active_color(category: String) -> Color:
	match category:
		"polluted":
			return Color(0.78, 0.68, 0.22, 1)
		"elite_node":
			return Color(0.66, 0.48, 0.18, 1)
		"ruin_guard":
			return Color(0.38, 0.72, 0.82, 1)
		_:
			return Color(0.8, 0.313726, 0.215686, 1)
