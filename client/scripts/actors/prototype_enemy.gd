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
const ENEMY_LABEL_FONT_SIZE := 8
const ENEMY_FOCUS_LABEL_WIDTH := 96.0
const ENEMY_FOCUS_LABEL_LINE_HEIGHT := 11.0
const ENEMY_VISUAL_PART_IDS := [
	"enemy_shape.shadow",
	"enemy_shape.body",
	"enemy_shape.head",
	"enemy_shape.limbs",
	"enemy_shape.category_accent",
	"enemy_shape.pressure_core"
]

var health: float = 20.0
var max_health: float = 20.0
var display_name: String = ""
var instance_id: String = ""
var defeated: bool = false
var enemy_category: String = "basic"
var readability_threat_label: String = ""
var readability_pressure_label: String = ""

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
		sprite.color = _get_sprite_backplate_color(_get_active_color(category))
	_update_label()
	queue_redraw()


func configure_readability_tags(threat_label: String, pressure_label: String) -> void:
	readability_threat_label = threat_label
	readability_pressure_label = pressure_label
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
		queue_redraw()

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
	set_tactical_scan_marked(bool(enemy_state.get(CharacterKitRuntime.TACTICAL_SCAN_MARKED_FLAG, false)))
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
		if focused:
			_layout_focus_label()
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
	queue_redraw()


func set_tactical_scan_marked(marked: bool) -> void:
	if marked:
		set_meta(CharacterKitRuntime.TACTICAL_SCAN_MARKED_FLAG, true)
	else:
		if has_meta(CharacterKitRuntime.TACTICAL_SCAN_MARKED_FLAG):
			remove_meta(CharacterKitRuntime.TACTICAL_SCAN_MARKED_FLAG)
	_update_label()


func get_combat_status_label() -> String:
	var pressure_label := _get_pressure_focus_label()
	if pressure_label.is_empty():
		return "近战压制"
	return pressure_label


func mark_defeated() -> void:
	_ensure_visual_nodes()
	defeated = true
	health = 0.0
	if collision_shape != null:
		collision_shape.set_deferred("disabled", true)
	if enemy_category == "polluted":
		if sprite != null:
			sprite.color = _get_sprite_backplate_color(DEFEATED_POLLUTED_COLOR)
		if label != null:
			label.text = "%s\n污染已压制" % display_name
		queue_redraw()
		return
	if sprite != null:
		sprite.color = _get_sprite_backplate_color(DEFEATED_COLOR)
	if label != null:
		label.text = "%s\n已击败" % display_name
	queue_redraw()


func _update_label() -> void:
	_ensure_visual_nodes()
	if label != null:
		_style_label()
		label.text = "%s\nHP %.0f/%.0f %s" % [
			display_name,
			health,
			max_health,
			get_combat_status_label()
		]
	queue_redraw()


func _get_pressure_focus_label() -> String:
	var parts: Array[String] = []
	if has_meta(CharacterKitRuntime.TACTICAL_SCAN_MARKED_FLAG):
		parts.append("扫描锁定")
	if definition_id == "enemy.demo_stabilization_guard":
		parts.append("核心回写压力")
		return " / ".join(parts)
	if enemy_category != "polluted":
		return " / ".join(parts)
	match instance_id:
		"enemy_instance.polluted_skitter":
			parts.append("入口压力点")
		"enemy_instance.polluted_skitter_gate_pressure":
			parts.append("门前压力点")
		"enemy_instance.polluted_skitter_slurry_return_guard":
			parts.append("副产回收点")
		"enemy_instance.polluted_skitter_vial_reserve_guard":
			parts.append("药剂储备点")
		"enemy_instance.polluted_skitter_logistics_maintenance_pressure_guard":
			parts.append("后勤维护压力")
		"enemy_instance.core_buffer_polluted_skitter":
			parts.append("补料压力点")
		_:
			parts.append("深处压力点")
	return " / ".join(parts)


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


func _draw() -> void:
	var size := _get_active_size()
	var active_color := _get_active_color(enemy_category)
	if defeated:
		active_color = DEFEATED_POLLUTED_COLOR if enemy_category == "polluted" else DEFEATED_COLOR
	_draw_enemy_shadow(size)
	match get_silhouette_profile():
		"treatment":
			_draw_treatment_silhouette(size, active_color)
		"polluted":
			_draw_polluted_silhouette(size, active_color)
		"elite":
			_draw_elite_silhouette(size, active_color)
		"ruin_guard":
			_draw_ruin_guard_silhouette(size, active_color)
		_:
			_draw_basic_silhouette(size, active_color)


func get_silhouette_part_count() -> int:
	return ENEMY_VISUAL_PART_IDS.size()


func has_silhouette_part(part_id: String) -> bool:
	return ENEMY_VISUAL_PART_IDS.has(part_id)


func get_silhouette_profile() -> String:
	if definition_id == "enemy.treatment_skitter":
		return "treatment"
	match enemy_category:
		"polluted":
			return "polluted"
		"elite_node":
			return "elite"
		"ruin_guard":
			return "ruin_guard"
		_:
			return "basic"


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


func _get_sprite_backplate_color(color: Color) -> Color:
	return Color(color.r, color.g, color.b, 0.12)


func _draw_enemy_shadow(size: Vector2) -> void:
	var points := PackedVector2Array()
	for index in range(18):
		var angle := TAU * float(index) / 18.0
		points.append(Vector2(cos(angle) * size.x * 0.52, size.y * 0.34 + sin(angle) * size.y * 0.16))
	draw_colored_polygon(points, Color(0.02, 0.035, 0.03, 0.46))


func _draw_basic_silhouette(size: Vector2, color: Color) -> void:
	var body := PackedVector2Array([
		Vector2(0.0, -size.y * 0.52),
		Vector2(size.x * 0.44, -size.y * 0.08),
		Vector2(size.x * 0.26, size.y * 0.42),
		Vector2(-size.x * 0.26, size.y * 0.42),
		Vector2(-size.x * 0.44, -size.y * 0.08)
	])
	_draw_polygon_with_outline(body, color, Color(1.0, 0.82, 0.62, 0.78))
	draw_line(Vector2(-size.x * 0.36, size.y * 0.12), Vector2(-size.x * 0.62, size.y * 0.34), Color(color.r, color.g, color.b, 0.72), 2.0, true)
	draw_line(Vector2(size.x * 0.36, size.y * 0.12), Vector2(size.x * 0.62, size.y * 0.34), Color(color.r, color.g, color.b, 0.72), 2.0, true)
	draw_circle(Vector2(0.0, -size.y * 0.12), 4.0, Color(0.02, 0.04, 0.04, 0.82))


func _draw_treatment_silhouette(size: Vector2, color: Color) -> void:
	var body := PackedVector2Array([
		Vector2(-size.x * 0.48, -size.y * 0.3),
		Vector2(size.x * 0.2, -size.y * 0.42),
		Vector2(size.x * 0.52, -size.y * 0.08),
		Vector2(size.x * 0.32, size.y * 0.38),
		Vector2(-size.x * 0.4, size.y * 0.32)
	])
	_draw_polygon_with_outline(body, color, Color(1.0, 0.72, 0.46, 0.78))
	draw_line(Vector2(-size.x * 0.3, -size.y * 0.1), Vector2(size.x * 0.34, -size.y * 0.14), Color(0.95, 0.62, 0.28, 0.9), 3.0, true)
	draw_circle(Vector2(size.x * 0.42, -size.y * 0.06), 4.0, Color(0.36, 0.9, 0.92, 0.9))
	draw_line(Vector2(-size.x * 0.24, size.y * 0.22), Vector2(-size.x * 0.52, size.y * 0.42), Color(color.r, color.g, color.b, 0.66), 2.0, true)


func _draw_polluted_silhouette(size: Vector2, color: Color) -> void:
	var body := PackedVector2Array([
		Vector2(-size.x * 0.16, -size.y * 0.54),
		Vector2(size.x * 0.34, -size.y * 0.36),
		Vector2(size.x * 0.52, size.y * 0.06),
		Vector2(size.x * 0.12, size.y * 0.5),
		Vector2(-size.x * 0.44, size.y * 0.28),
		Vector2(-size.x * 0.5, -size.y * 0.12)
	])
	_draw_polygon_with_outline(body, color, Color(0.92, 0.86, 0.38, 0.78))
	for point in [Vector2(-size.x * 0.38, -size.y * 0.18), Vector2(size.x * 0.44, -size.y * 0.18), Vector2(size.x * 0.28, size.y * 0.32)]:
		draw_line(Vector2.ZERO, point, Color(0.86, 0.82, 0.28, 0.62), 2.0, true)
	draw_circle(Vector2(0.0, 0.0), 5.0, Color(0.12, 0.1, 0.04, 0.9))
	draw_arc(Vector2.ZERO, size.x * 0.58, 0.0, TAU, 28, Color(0.92, 0.82, 0.22, 0.28), 1.5, true)


func _draw_elite_silhouette(size: Vector2, color: Color) -> void:
	var body := PackedVector2Array([
		Vector2(0.0, -size.y * 0.58),
		Vector2(size.x * 0.54, 0.0),
		Vector2(0.0, size.y * 0.58),
		Vector2(-size.x * 0.54, 0.0)
	])
	_draw_polygon_with_outline(body, color, Color(1.0, 0.86, 0.44, 0.82))
	draw_colored_polygon(PackedVector2Array([
		Vector2(0.0, -size.y * 0.28),
		Vector2(size.x * 0.24, size.y * 0.18),
		Vector2(-size.x * 0.24, size.y * 0.18)
	]), Color(0.12, 0.08, 0.04, 0.82))
	draw_arc(Vector2.ZERO, size.x * 0.62, 0.0, TAU, 32, Color(1.0, 0.58, 0.28, 0.36), 2.0, true)
	draw_line(Vector2(-size.x * 0.62, 0.0), Vector2(size.x * 0.62, 0.0), Color(color.r, color.g, color.b, 0.7), 2.0, true)


func _draw_ruin_guard_silhouette(size: Vector2, color: Color) -> void:
	var body := PackedVector2Array([
		Vector2(0.0, -size.y * 0.58),
		Vector2(size.x * 0.44, -size.y * 0.08),
		Vector2(size.x * 0.18, size.y * 0.52),
		Vector2(-size.x * 0.38, size.y * 0.22),
		Vector2(-size.x * 0.3, -size.y * 0.36)
	])
	_draw_polygon_with_outline(body, color, Color(0.62, 0.94, 1.0, 0.78))
	draw_line(Vector2(-size.x * 0.2, -size.y * 0.36), Vector2(size.x * 0.2, size.y * 0.34), Color(0.76, 0.98, 1.0, 0.52), 2.0, true)
	draw_circle(Vector2(size.x * 0.1, -size.y * 0.08), 4.0, Color(0.08, 0.22, 0.24, 0.86))


func _draw_polygon_with_outline(points: PackedVector2Array, fill: Color, outline: Color) -> void:
	draw_colored_polygon(points, fill)
	var closed := PackedVector2Array(points)
	closed.append(points[0])
	draw_polyline(closed, outline, 1.6, true)


func _style_label() -> void:
	if label == null:
		return
	label.add_theme_font_size_override("font_size", ENEMY_LABEL_FONT_SIZE)
	label.add_theme_color_override("font_color", Color(0.96, 0.9, 0.82, 0.68))
	label.add_theme_color_override("font_shadow_color", Color(0.05, 0.02, 0.02, 0.58))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.clip_text = true


func _layout_focus_label() -> void:
	if label == null or sprite == null:
		return
	var line_count := clampi(label.text.split("\n").size(), 1, 2)
	label.offset_left = sprite.position.x + sprite.size.x + 8.0
	label.offset_top = sprite.position.y + 1.0
	label.offset_right = label.offset_left + ENEMY_FOCUS_LABEL_WIDTH
	label.offset_bottom = label.offset_top + ENEMY_FOCUS_LABEL_LINE_HEIGHT * line_count
