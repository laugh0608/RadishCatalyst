extends Node2D
class_name DemoRegionIndustrialValueLayer

const FOCUS_VISIBLE_RADIUS := 210.0
const ROUTE_VISIBLE_RADIUS := 72.0
const VALUE_NODE_ROUTE_ALPHA := 0.12
const VALUE_NODE_DIM_ALPHA := 0.008

const ROLE_RESOURCE := "resource"
const ROLE_RISK := "risk"
const ROLE_UNLOCK := "unlock"
const ROLE_STABILITY := "stability"
const ROLE_LOGISTICS := "logistics"

const RESOURCE_COLOR := Color(0.36, 0.78, 0.92, 0.86)
const RISK_COLOR := Color(0.9, 0.38, 0.2, 0.82)
const UNLOCK_COLOR := Color(0.7, 0.58, 0.92, 0.82)
const STABILITY_COLOR := Color(0.52, 0.9, 0.72, 0.84)
const LOGISTICS_COLOR := Color(0.88, 0.7, 0.28, 0.8)
const ROUTE_DARK := Color(0.02, 0.04, 0.04, 0.32)
const NODE_DARK := Color(0.03, 0.045, 0.04, 0.46)

const REGION_VALUE_PROFILES := {
	"region.outpost_platform": {
		"role": ROLE_LOGISTICS,
		"center": Vector2(-214.0, -22.0),
		"anchor": Vector2(-300.0, -92.0),
		"route": [Vector2(-300.0, -92.0), Vector2(-226.0, -92.0), Vector2(-166.0, -66.0)],
		"importance": 1.0
	},
	"region.crystal_vein_field": {
		"role": ROLE_RESOURCE,
		"center": Vector2(112.0, -112.0),
		"anchor": Vector2(-166.0, -66.0),
		"route": [Vector2(112.0, -112.0), Vector2(72.0, -136.0), Vector2(20.0, -112.0)],
		"importance": 1.0
	},
	"region.pollution_edge": {
		"role": ROLE_RISK,
		"center": Vector2(306.0, -102.0),
		"anchor": Vector2(298.0, -72.0),
		"route": [Vector2(306.0, -102.0), Vector2(298.0, -72.0), Vector2(342.0, 24.0)],
		"importance": 1.0
	},
	"region.ruin_outer_ring": {
		"role": ROLE_UNLOCK,
		"center": Vector2(596.0, 24.0),
		"anchor": Vector2(388.0, 24.0),
		"route": [Vector2(596.0, 24.0), Vector2(512.0, -18.0), Vector2(388.0, 24.0)],
		"importance": 0.92
	},
	"region.deep_ruin_threshold": {
		"role": ROLE_LOGISTICS,
		"center": Vector2(968.0, -66.0),
		"anchor": Vector2(850.0, 92.0),
		"route": [Vector2(968.0, -66.0), Vector2(914.0, 24.0), Vector2(850.0, 92.0)],
		"importance": 0.82
	},
	"region.inner_phase_well": {
		"role": ROLE_RESOURCE,
		"center": Vector2(1608.0, 8.0),
		"anchor": Vector2(1712.0, -84.0),
		"route": [Vector2(1608.0, 8.0), Vector2(1660.0, -24.0), Vector2(1712.0, -84.0)],
		"importance": 0.7
	},
	"region.phase_well_sink": {
		"role": ROLE_RISK,
		"center": Vector2(1884.0, -34.0),
		"anchor": Vector2(2012.0, -52.0),
		"route": [Vector2(1884.0, -34.0), Vector2(1952.0, -42.0), Vector2(2012.0, -52.0)],
		"importance": 0.76
	},
	"region.phase_well_chamber": {
		"role": ROLE_RESOURCE,
		"center": Vector2(2148.0, -98.0),
		"anchor": Vector2(2292.0, -12.0),
		"route": [Vector2(2148.0, -98.0), Vector2(2224.0, -52.0), Vector2(2292.0, -12.0)],
		"importance": 0.76
	},
	"region.phase_well_loom": {
		"role": ROLE_LOGISTICS,
		"center": Vector2(2438.0, -84.0),
		"anchor": Vector2(2572.0, -12.0),
		"route": [Vector2(2438.0, -84.0), Vector2(2514.0, -46.0), Vector2(2572.0, -12.0)],
		"importance": 0.72
	},
	"region.phase_well_frame": {
		"role": ROLE_RISK,
		"center": Vector2(2722.0, -16.0),
		"anchor": Vector2(2852.0, -12.0),
		"route": [Vector2(2722.0, -16.0), Vector2(2790.0, 24.0), Vector2(2852.0, -12.0)],
		"importance": 0.76
	},
	"region.phase_well_tether": {
		"role": ROLE_STABILITY,
		"center": Vector2(3362.0, -18.0),
		"anchor": Vector2(3612.0, -16.0),
		"route": [Vector2(3362.0, -18.0), Vector2(3504.0, -18.0), Vector2(3612.0, -16.0)],
		"importance": 0.9
	},
	"region.demo_stabilization_core": {
		"role": ROLE_STABILITY,
		"center": Vector2(3928.0, -76.0),
		"anchor": Vector2(3744.0, 112.0),
		"route": [Vector2(3744.0, 112.0), Vector2(3860.0, 12.0), Vector2(3928.0, -76.0)],
		"importance": 1.0
	}
}

var value_node_ids: Array[String] = []
var emphasized_region_ids: Array[String] = []


func _ready() -> void:
	apply_visuals()


func _process(_delta: float) -> void:
	queue_redraw()


func apply_visuals() -> void:
	value_node_ids.clear()
	emphasized_region_ids.clear()
	for region_id in REGION_VALUE_PROFILES.keys():
		value_node_ids.append(String(region_id))
		var importance := float(REGION_VALUE_PROFILES[region_id].get("importance", 0.0))
		if importance >= 0.9:
			emphasized_region_ids.append(String(region_id))
		_tag_region_background(String(region_id), String(REGION_VALUE_PROFILES[region_id].get("role", "")))
	queue_redraw()


func get_value_node_count() -> int:
	return value_node_ids.size()


func get_emphasized_region_count() -> int:
	return emphasized_region_ids.size()


func has_region_value(region_id: String) -> bool:
	return value_node_ids.has(region_id)


func get_region_value_role(region_id: String) -> String:
	var profile: Dictionary = REGION_VALUE_PROFILES.get(region_id, {})
	return String(profile.get("role", ""))


func is_region_value_route_visible(region_id: String, focus_position: Vector2) -> bool:
	var profile: Dictionary = REGION_VALUE_PROFILES.get(region_id, {})
	if profile.is_empty():
		return false
	var center: Vector2 = profile.get("center", Vector2.ZERO)
	return _should_draw_value_route(center, focus_position)


func _draw() -> void:
	var focus_position := _get_player_position()
	for region_id in value_node_ids:
		_draw_region_value(String(region_id), REGION_VALUE_PROFILES[region_id], focus_position)


func _draw_region_value(region_id: String, profile: Dictionary, focus_position: Vector2) -> void:
	var center: Vector2 = profile.get("center", Vector2.ZERO)
	var role := String(profile.get("role", ""))
	var color := _role_color(role)
	var alpha := _focus_alpha(center, focus_position, float(profile.get("importance", 0.7)))
	if alpha <= 0.01:
		return
	var route: Array = profile.get("route", [])
	if _should_draw_value_route(center, focus_position):
		_draw_value_route(route, color, alpha)
	_draw_value_node(center, role, color, alpha)
	_draw_anchor_socket(profile.get("anchor", center), color, alpha * 0.86)
	_tag_region_background(region_id, role)


func _draw_value_route(points: Array, color: Color, alpha: float) -> void:
	if points.size() < 2:
		return
	var vector_points := PackedVector2Array()
	for point in points:
		vector_points.append(point)
	draw_polyline(vector_points, Color(ROUTE_DARK.r, ROUTE_DARK.g, ROUTE_DARK.b, ROUTE_DARK.a * alpha), 3.8, true)
	draw_polyline(vector_points, Color(color.r, color.g, color.b, VALUE_NODE_ROUTE_ALPHA * alpha), 2.0, true)
	for point in vector_points:
		draw_circle(point, 3.3, Color(color.r, color.g, color.b, 0.52 * alpha))


func _draw_value_node(center: Vector2, role: String, color: Color, alpha: float) -> void:
	draw_circle(center, 19.0, Color(NODE_DARK.r, NODE_DARK.g, NODE_DARK.b, NODE_DARK.a * alpha))
	draw_arc(center, 24.0, 0.0, TAU, 32, Color(color.r, color.g, color.b, 0.52 * alpha), 2.0, true)
	match role:
		ROLE_RESOURCE:
			_draw_resource_icon(center, color, alpha)
		ROLE_RISK:
			_draw_risk_icon(center, color, alpha)
		ROLE_UNLOCK:
			_draw_unlock_icon(center, color, alpha)
		ROLE_STABILITY:
			_draw_stability_icon(center, color, alpha)
		ROLE_LOGISTICS:
			_draw_logistics_icon(center, color, alpha)


func _draw_anchor_socket(center: Vector2, color: Color, alpha: float) -> void:
	draw_rect(Rect2(center + Vector2(-8.0, -8.0), Vector2(16.0, 16.0)), Color(0.02, 0.04, 0.035, 0.42 * alpha), true)
	draw_rect(Rect2(center + Vector2(-8.0, -8.0), Vector2(16.0, 16.0)), Color(color.r, color.g, color.b, 0.5 * alpha), false, 1.6, true)


func _draw_resource_icon(center: Vector2, color: Color, alpha: float) -> void:
	var crystal := PackedVector2Array([
		center + Vector2(0.0, -13.0),
		center + Vector2(10.0, -2.0),
		center + Vector2(4.0, 12.0),
		center + Vector2(-8.0, 8.0),
		center + Vector2(-10.0, -4.0),
		center + Vector2(0.0, -13.0)
	])
	draw_colored_polygon(crystal, Color(color.r, color.g, color.b, 0.28 * alpha))
	draw_polyline(crystal, Color(color.r, color.g, color.b, 0.82 * alpha), 1.7, true)


func _draw_risk_icon(center: Vector2, color: Color, alpha: float) -> void:
	var triangle := PackedVector2Array([
		center + Vector2(0.0, -14.0),
		center + Vector2(13.0, 10.0),
		center + Vector2(-13.0, 10.0),
		center + Vector2(0.0, -14.0)
	])
	draw_colored_polygon(triangle, Color(color.r, color.g, color.b, 0.2 * alpha))
	draw_polyline(triangle, Color(color.r, color.g, color.b, 0.86 * alpha), 1.8, true)
	draw_line(center + Vector2(0.0, -5.0), center + Vector2(0.0, 5.0), Color(color.r, color.g, color.b, 0.86 * alpha), 1.8, true)


func _draw_unlock_icon(center: Vector2, color: Color, alpha: float) -> void:
	draw_arc(center + Vector2(0.0, -3.0), 9.0, PI, TAU, 24, Color(color.r, color.g, color.b, 0.82 * alpha), 2.0, true)
	draw_rect(Rect2(center + Vector2(-11.0, -1.0), Vector2(22.0, 16.0)), Color(color.r, color.g, color.b, 0.22 * alpha), true)
	draw_rect(Rect2(center + Vector2(-11.0, -1.0), Vector2(22.0, 16.0)), Color(color.r, color.g, color.b, 0.82 * alpha), false, 1.7, true)


func _draw_stability_icon(center: Vector2, color: Color, alpha: float) -> void:
	draw_arc(center, 13.0, 0.0, TAU, 28, Color(color.r, color.g, color.b, 0.72 * alpha), 1.8, true)
	draw_line(center + Vector2(-14.0, 0.0), center + Vector2(14.0, 0.0), Color(color.r, color.g, color.b, 0.72 * alpha), 1.8, true)
	draw_line(center + Vector2(0.0, -14.0), center + Vector2(0.0, 14.0), Color(color.r, color.g, color.b, 0.72 * alpha), 1.8, true)
	draw_circle(center, 4.5, Color(color.r, color.g, color.b, 0.74 * alpha))


func _draw_logistics_icon(center: Vector2, color: Color, alpha: float) -> void:
	draw_rect(Rect2(center + Vector2(-14.0, -10.0), Vector2(24.0, 18.0)), Color(color.r, color.g, color.b, 0.2 * alpha), true)
	draw_rect(Rect2(center + Vector2(-14.0, -10.0), Vector2(24.0, 18.0)), Color(color.r, color.g, color.b, 0.82 * alpha), false, 1.7, true)
	draw_circle(center + Vector2(-8.0, 11.0), 3.0, Color(color.r, color.g, color.b, 0.82 * alpha))
	draw_circle(center + Vector2(8.0, 11.0), 3.0, Color(color.r, color.g, color.b, 0.82 * alpha))


func _focus_alpha(center: Vector2, focus_position: Vector2, importance: float) -> float:
	var distance := center.distance_to(focus_position)
	if distance <= FOCUS_VISIBLE_RADIUS:
		return clampf(importance, 0.46, 1.0)
	if distance <= FOCUS_VISIBLE_RADIUS * 1.8:
		return VALUE_NODE_DIM_ALPHA * importance
	return 0.0


func _should_draw_value_route(center: Vector2, focus_position: Vector2) -> bool:
	return center.distance_to(focus_position) <= ROUTE_VISIBLE_RADIUS


func _role_color(role: String) -> Color:
	match role:
		ROLE_RESOURCE:
			return RESOURCE_COLOR
		ROLE_RISK:
			return RISK_COLOR
		ROLE_UNLOCK:
			return UNLOCK_COLOR
		ROLE_STABILITY:
			return STABILITY_COLOR
		ROLE_LOGISTICS:
			return LOGISTICS_COLOR
		_:
			return LOGISTICS_COLOR


func _tag_region_background(region_id: String, role: String) -> void:
	var background := _get_region_background(region_id)
	if background == null:
		return
	background.set_meta("industrial_value_role", role)
	background.set_meta("industrial_value_region_id", region_id)


func _get_region_background(region_id: String) -> Node:
	var profile := PrototypeVisualPriorityProfile.get_region_profile(region_id)
	if profile.is_empty():
		return null
	return _get_map_node(String(profile.get("background_path", "")))


func _get_player_position() -> Vector2:
	var map_root := get_parent()
	if map_root == null:
		return Vector2.ZERO
	var player := map_root.get_node_or_null("Player") as Node2D
	if player == null:
		return Vector2.ZERO
	return player.position


func _get_map_node(path: String) -> Node:
	if path.is_empty() or get_parent() == null:
		return null
	return get_parent().get_node_or_null(path)
