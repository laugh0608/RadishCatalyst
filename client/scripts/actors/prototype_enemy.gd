extends CharacterBody2D
class_name PrototypeEnemy

@export var definition_id: String = "enemy.native_skitter"

const DEFEATED_COLOR := Color(0.2, 0.2, 0.2, 1)
const DEFEATED_POLLUTED_COLOR := Color(0.34, 0.32, 0.16, 1)
const FOCUSED_SPRITE_SCALE := Vector2(1.22, 1.22)
const FOCUSED_SPRITE_MODULATE := Color(1.16, 1.16, 1.16, 1)
const DEFAULT_SPRITE_MODULATE := Color(1, 1, 1, 1)
const FOCUSED_Z_INDEX := 18
const BASIC_ENEMY_SIZE := Vector2(24.0, 24.0)
const TREATMENT_ENEMY_SIZE := Vector2(28.0, 22.0)
const POLLUTED_ENEMY_SIZE := Vector2(30.0, 26.0)
const ELITE_ENEMY_SIZE := Vector2(36.0, 34.0)

var health: float = 20.0
var max_health: float = 20.0
var display_name: String = ""
var instance_id: String = ""
var defeated: bool = false
var enemy_category: String = "basic"

@onready var label: Label = $Label
@onready var sprite: ColorRect = $Sprite
@onready var focus_ring: ColorRect = $FocusRing
@onready var collision_shape: CollisionShape2D = $CollisionShape2D


func _ensure_visual_nodes() -> void:
	if label == null:
		label = get_node_or_null("Label") as Label
	if sprite == null:
		sprite = get_node_or_null("Sprite") as ColorRect
	if focus_ring == null:
		focus_ring = get_node_or_null("FocusRing") as ColorRect
	if collision_shape == null:
		collision_shape = get_node_or_null("CollisionShape2D") as CollisionShape2D


func setup(enemy_display_name: String, enemy_max_health: float, category: String = "basic") -> void:
	_ensure_visual_nodes()
	display_name = enemy_display_name
	max_health = enemy_max_health
	health = enemy_max_health
	defeated = false
	enemy_category = category
	if collision_shape != null:
		collision_shape.disabled = false
	if sprite != null:
		_apply_sprite_size(_get_active_size())
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
	if bool(enemy_state.get("pressure_vial_used", false)):
		set_meta("pressure_vial_used", true)
	elif has_meta("pressure_vial_used"):
		remove_meta("pressure_vial_used")
	if bool(enemy_state.get("core_side_supply_used", false)):
		set_meta("core_side_supply_used", true)
	elif has_meta("core_side_supply_used"):
		remove_meta("core_side_supply_used")
	if defeated:
		mark_defeated()
	else:
		_update_label()


func can_be_attacked() -> bool:
	return not defeated and visible


func set_focus_visual(focused: bool) -> void:
	if label != null:
		label.visible = focused and visible and not defeated
	if focus_ring != null:
		focus_ring.visible = focused and visible and not defeated
		if sprite != null:
			var ring_size := sprite.size + Vector2(14.0, 14.0)
			focus_ring.position = sprite.position - Vector2(7.0, 7.0)
			focus_ring.size = ring_size
	if sprite != null:
		sprite.pivot_offset = sprite.size * 0.5
		sprite.scale = FOCUSED_SPRITE_SCALE if focused else Vector2.ONE
		sprite.modulate = FOCUSED_SPRITE_MODULATE if focused else DEFAULT_SPRITE_MODULATE
	z_index = FOCUSED_Z_INDEX if focused else 0


func mark_defeated() -> void:
	_ensure_visual_nodes()
	defeated = true
	health = 0.0
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	if enemy_category == "polluted":
		if sprite != null:
			sprite.color = DEFEATED_POLLUTED_COLOR
		if label != null:
			label.text = "%s\n污染已压制" % display_name
		return
	if sprite != null:
		sprite.color = DEFEATED_COLOR
	if label != null:
		label.text = "%s\n已击败" % display_name


func _update_label() -> void:
	_ensure_visual_nodes()
	if label != null:
		var pressure_label := _get_pressure_focus_label()
		if pressure_label.is_empty():
			label.text = "%s\nHP %.0f / %.0f" % [display_name, health, max_health]
			return
		label.text = "%s\n%s HP %.0f / %.0f" % [display_name, pressure_label, health, max_health]


func _get_pressure_focus_label() -> String:
	if definition_id == "enemy.demo_stabilization_guard":
		return "核心回写压力"
	if enemy_category != "polluted":
		return ""
	match instance_id:
		"enemy_instance.polluted_skitter":
			return "入口压力点"
		"enemy_instance.polluted_skitter_gate_pressure":
			return "门前压力点"
		"enemy_instance.polluted_skitter_slurry_return_guard":
			return "副产回收点"
		"enemy_instance.polluted_skitter_vial_reserve_guard":
			return "药剂储备点"
		"enemy_instance.polluted_skitter_logistics_maintenance_pressure_guard":
			return "后勤维护压力"
		"enemy_instance.core_buffer_polluted_skitter":
			return "补料压力点"
		_:
			return "深处压力点"


func set_spawn_enabled(enabled: bool) -> void:
	_ensure_visual_nodes()
	visible = enabled
	if defeated:
		if collision_shape != null:
			collision_shape.set_deferred("disabled", true)
		return
	if collision_shape != null:
		collision_shape.set_deferred("disabled", not enabled)


func _get_active_color(category: String) -> Color:
	if definition_id == "enemy.treatment_skitter":
		return Color(0.88, 0.38, 0.24, 1)
	match category:
		"polluted":
			return Color(0.78, 0.68, 0.22, 1)
		"elite_node":
			return Color(0.66, 0.48, 0.18, 1)
		"ruin_guard":
			return Color(0.38, 0.72, 0.82, 1)
		_:
			return Color(0.8, 0.313726, 0.215686, 1)


func _get_active_size() -> Vector2:
	if definition_id == "enemy.treatment_skitter":
		return TREATMENT_ENEMY_SIZE
	match enemy_category:
		"polluted":
			return POLLUTED_ENEMY_SIZE
		"elite_node":
			return ELITE_ENEMY_SIZE
		_:
			return BASIC_ENEMY_SIZE


func _apply_sprite_size(sprite_size: Vector2) -> void:
	if sprite == null:
		return
	sprite.position = -sprite_size * 0.5
	sprite.size = sprite_size
	if focus_ring != null:
		focus_ring.position = sprite.position - Vector2(7.0, 7.0)
		focus_ring.size = sprite_size + Vector2(14.0, 14.0)
