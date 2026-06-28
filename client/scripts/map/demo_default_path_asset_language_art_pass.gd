extends RefCounted
class_name DemoDefaultPathAssetLanguageArtPass

const ASSET_TERRAIN_FLOOR := preload("res://assets/sprites/demo_first_screen/terrain_outpost_floor.svg")
const ASSET_CRYSTAL_ECOLOGY := preload("res://assets/sprites/demo_first_screen/crystal_ecology_cluster.svg")
const ASSET_POLLUTION_EDGE := preload("res://assets/sprites/demo_first_screen/pollution_edge_pool.svg")
const ASSET_PIPE_BUNDLE := preload("res://assets/sprites/demo_first_screen/pipe_bundle.svg")
const ASSET_OUTPOST_CORE := preload("res://assets/sprites/demo_first_screen/outpost_core_machine.svg")

const BASE_SHAPES := [
	"default_path.asset_language.base.shared_service_floor",
	"default_path.asset_language.base.reused_pipe_bundle",
	"default_path.asset_language.base.role_port_tokens",
	"default_path.asset_language.base.short_flow_packets",
	"default_path.asset_language.base.player_handoff_feedback"
]

const CRYSTAL_SHAPES := [
	"terrain.crystal.assetized_service_floor",
	"terrain.crystal.assetized_ecology_sprite",
	"terrain.crystal.assetized_loading_pipe",
	"terrain.crystal.shared_role_port_tokens",
	"terrain.crystal.player_harvest_action_feedback"
]

const POLLUTION_SHAPES := [
	"terrain.pollution.assetized_pollution_pool",
	"terrain.pollution.assetized_filter_service_plate",
	"terrain.pollution.assetized_pipe_bundle",
	"terrain.pollution.shared_role_port_tokens",
	"terrain.pollution.short_challenge_action_feedback"
]

const CORE_SHAPES := [
	"station.assetized_core_service_floor",
	"station.assetized_core_pipe_bundle",
	"station.assetized_write_device_machine",
	"station.shared_role_port_tokens",
	"station.core_write_action_feedback"
]

const SERVICE_PLATE_FILL := Color(0.055, 0.088, 0.078, 0.34)
const SERVICE_PLATE_EDGE := Color(0.68, 0.78, 0.62, 0.23)
const PORT_DARK := Color(0.008, 0.018, 0.016, 0.72)
const BASE_FLOW := Color(0.82, 0.74, 0.42, 0.46)
const CRYSTAL_FLOW := Color(0.44, 0.88, 0.96, 0.42)
const POLLUTION_FLOW := Color(0.86, 0.68, 0.24, 0.42)
const CORE_FLOW := Color(0.48, 0.96, 0.88, 0.46)


static func get_base_shape_ids() -> Array[String]:
	return _copy_shape_ids(BASE_SHAPES)


static func get_crystal_shape_ids() -> Array[String]:
	return _copy_shape_ids(CRYSTAL_SHAPES)


static func get_pollution_shape_ids() -> Array[String]:
	return _copy_shape_ids(POLLUTION_SHAPES)


static func get_core_shape_ids() -> Array[String]:
	return _copy_shape_ids(CORE_SHAPES)


static func draw_base_handoff_language(canvas: CanvasItem) -> void:
	if canvas == null:
		return
	_draw_texture(canvas, ASSET_TERRAIN_FLOOR, Rect2(Vector2(-346.0, -214.0), Vector2(374.0, 276.0)), Color(0.82, 0.9, 0.82, 0.20))
	_draw_texture(canvas, ASSET_PIPE_BUNDLE, Rect2(Vector2(-332.0, -162.0), Vector2(296.0, 136.0)), Color(0.82, 0.92, 0.82, 0.22))
	_draw_service_plate(canvas, Rect2(Vector2(-272.0, -154.0), Vector2(96.0, 76.0)), BASE_FLOW)
	_draw_service_plate(canvas, Rect2(Vector2(-306.0, 2.0), Vector2(112.0, 82.0)), Color(0.58, 0.88, 0.52, 0.42))
	_draw_service_plate(canvas, Rect2(Vector2(-124.0, -58.0), Vector2(92.0, 70.0)), Color(0.92, 0.74, 0.3, 0.42))
	_draw_port_token(canvas, Vector2(-214.0, -112.0), BASE_FLOW)
	_draw_port_token(canvas, Vector2(-184.0, -114.0), Color(1.0, 0.58, 0.22, 0.42))
	_draw_port_token(canvas, Vector2(-250.0, 18.0), Color(0.58, 0.88, 0.52, 0.42))
	_draw_port_token(canvas, Vector2(-74.0, -14.0), Color(0.92, 0.74, 0.3, 0.42))
	_draw_packet_flow(canvas, [Vector2(-214.0, -112.0), Vector2(-184.0, -114.0), Vector2(-250.0, 18.0), Vector2(-74.0, -14.0)], BASE_FLOW)
	_draw_action_ticks(canvas, Vector2(-74.0, -14.0), Color(0.92, 0.74, 0.3, 0.5))


static func draw_crystal_language(canvas: CanvasItem) -> void:
	if canvas == null:
		return
	_draw_texture(canvas, ASSET_TERRAIN_FLOOR, Rect2(Vector2(-32.0, -250.0), Vector2(294.0, 518.0)), Color(0.72, 0.86, 0.82, 0.16))
	_draw_texture(canvas, ASSET_CRYSTAL_ECOLOGY, Rect2(Vector2(14.0, -264.0), Vector2(238.0, 214.0)), Color(0.84, 1.0, 1.0, 0.34))
	_draw_texture(canvas, ASSET_PIPE_BUNDLE, Rect2(Vector2(-42.0, -70.0), Vector2(178.0, 92.0)), Color(0.72, 0.92, 0.84, 0.16))
	_draw_service_plate(canvas, Rect2(Vector2(76.0, -150.0), Vector2(96.0, 64.0)), CRYSTAL_FLOW)
	_draw_service_plate(canvas, Rect2(Vector2(28.0, 78.0), Vector2(104.0, 76.0)), Color(0.84, 0.7, 0.34, 0.34))
	_draw_port_token(canvas, Vector2(84.0, -100.0), CRYSTAL_FLOW)
	_draw_port_token(canvas, Vector2(132.0, -124.0), CRYSTAL_FLOW)
	_draw_port_token(canvas, Vector2(54.0, 112.0), Color(0.84, 0.7, 0.34, 0.4))
	_draw_packet_flow(canvas, [Vector2(132.0, -124.0), Vector2(86.0, -118.0), Vector2(8.0, -112.0)], CRYSTAL_FLOW)
	_draw_action_ticks(canvas, Vector2(84.0, -100.0), Color(0.82, 0.96, 1.0, 0.48))


static func draw_pollution_language(canvas: CanvasItem, focused: bool) -> void:
	if canvas == null:
		return
	var alpha_scale := 0.82 if focused else 1.0
	_draw_texture(canvas, ASSET_POLLUTION_EDGE, Rect2(Vector2(226.0, -44.0), Vector2(196.0, 304.0)), Color(1.0, 1.0, 0.82, 0.30 * alpha_scale))
	_draw_texture(canvas, ASSET_PIPE_BUNDLE, Rect2(Vector2(224.0, -174.0), Vector2(188.0, 96.0)), Color(0.86, 0.92, 0.72, 0.20 * alpha_scale))
	_draw_service_plate(canvas, Rect2(Vector2(246.0, -162.0), Vector2(132.0, 126.0)), Color(0.74, 0.8, 0.42, 0.34 * alpha_scale))
	_draw_service_plate(canvas, Rect2(Vector2(236.0, -12.0), Vector2(162.0, 92.0)), Color(0.94, 0.48, 0.18, 0.28 * alpha_scale))
	_draw_port_token(canvas, Vector2(282.0, -102.0), POLLUTION_FLOW)
	_draw_port_token(canvas, Vector2(316.0, -124.0), Color(0.72, 0.92, 0.38, 0.42))
	_draw_port_token(canvas, Vector2(336.0, 206.0), Color(0.82, 0.42, 0.18, 0.42))
	_draw_port_token(canvas, Vector2(382.0, 24.0), Color(0.74, 0.58, 0.9, 0.46))
	_draw_packet_flow(canvas, [Vector2(282.0, -102.0), Vector2(316.0, -124.0), Vector2(336.0, 206.0), Vector2(382.0, 24.0)], POLLUTION_FLOW)
	_draw_action_ticks(canvas, Vector2(374.0, 24.0), Color(0.94, 0.48, 0.18, 0.46))


static func draw_core_language(canvas: CanvasItem) -> void:
	if canvas == null:
		return
	_draw_texture(canvas, ASSET_TERRAIN_FLOOR, Rect2(Vector2(3638.0, -226.0), Vector2(642.0, 420.0)), Color(0.70, 0.88, 0.84, 0.13))
	_draw_texture(canvas, ASSET_PIPE_BUNDLE, Rect2(Vector2(3868.0, -128.0), Vector2(318.0, 152.0)), Color(0.72, 0.92, 0.88, 0.18))
	_draw_texture(canvas, ASSET_OUTPOST_CORE, Rect2(Vector2(3980.0, -96.0), Vector2(118.0, 134.0)), Color(0.84, 1.0, 0.96, 0.34))
	_draw_service_plate(canvas, Rect2(Vector2(3690.0, -76.0), Vector2(142.0, 118.0)), Color(0.68, 0.9, 0.5, 0.28))
	_draw_service_plate(canvas, Rect2(Vector2(3898.0, -110.0), Vector2(144.0, 104.0)), CORE_FLOW)
	_draw_service_plate(canvas, Rect2(Vector2(4078.0, 18.0), Vector2(142.0, 108.0)), Color(0.56, 0.86, 0.96, 0.28))
	_draw_port_token(canvas, Vector2(3744.0, 112.0), Color(0.68, 0.9, 0.5, 0.42))
	_draw_port_token(canvas, Vector2(3926.0, 70.0), Color(0.9, 0.72, 0.28, 0.42))
	_draw_port_token(canvas, Vector2(4038.0, -24.0), CORE_FLOW)
	_draw_port_token(canvas, Vector2(4134.0, 78.0), Color(0.56, 0.86, 0.96, 0.42))
	_draw_packet_flow(canvas, [Vector2(3926.0, 70.0), Vector2(3988.0, 24.0), Vector2(4038.0, -24.0), Vector2(4134.0, 78.0)], CORE_FLOW)
	_draw_action_ticks(canvas, Vector2(4038.0, -24.0), Color(0.48, 0.96, 0.88, 0.48))


static func _copy_shape_ids(source: Array) -> Array[String]:
	var ids: Array[String] = []
	for shape_id in source:
		ids.append(String(shape_id))
	return ids


static func _draw_texture(canvas: CanvasItem, texture: Texture2D, rect: Rect2, modulate_color: Color) -> void:
	if texture == null:
		return
	canvas.draw_texture_rect(texture, rect, false, modulate_color)


static func _draw_service_plate(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	canvas.draw_rect(rect, SERVICE_PLATE_FILL, true)
	canvas.draw_rect(rect, Color(color.r, color.g, color.b, 0.18), true)
	canvas.draw_rect(rect, SERVICE_PLATE_EDGE, false, 1.0, true)
	var x := rect.position.x + 12.0
	while x < rect.position.x + rect.size.x - 10.0:
		canvas.draw_line(
			Vector2(x, rect.position.y + 8.0),
			Vector2(x + 12.0, rect.position.y + rect.size.y - 8.0),
			Color(color.r, color.g, color.b, 0.16),
			0.9,
			true
		)
		x += 28.0


static func _draw_port_token(canvas: CanvasItem, center: Vector2, color: Color) -> void:
	var rect := Rect2(center + Vector2(-8.0, -7.0), Vector2(16.0, 14.0))
	canvas.draw_rect(rect, PORT_DARK, true)
	canvas.draw_rect(rect, Color(color.r, color.g, color.b, 0.34), false, 1.0, true)
	canvas.draw_circle(center, 2.9, Color(color.r, color.g, color.b, 0.42))


static func _draw_packet_flow(canvas: CanvasItem, points: Array[Vector2], color: Color) -> void:
	if points.size() < 2:
		return
	canvas.draw_polyline(PackedVector2Array(points), Color(0.008, 0.018, 0.016, 0.62), 4.0, true)
	canvas.draw_polyline(PackedVector2Array(points), Color(color.r, color.g, color.b, 0.24), 1.4, true)
	for index in range(points.size() - 1):
		var from := points[index]
		var to := points[index + 1]
		if from.distance_to(to) < 22.0:
			continue
		for ratio in [0.36, 0.68]:
			var center := from.lerp(to, ratio)
			canvas.draw_circle(center, 2.5, Color(color.r, color.g, color.b, 0.42))


static func _draw_action_ticks(canvas: CanvasItem, center: Vector2, color: Color) -> void:
	for angle in [PI * 0.12, PI * 0.42, PI * 0.72]:
		var from := center + Vector2(cos(angle), sin(angle)) * 12.0
		var to := center + Vector2(cos(angle), sin(angle)) * 22.0
		canvas.draw_line(from, to, color, 1.2, true)
	canvas.draw_arc(center, 24.0, PI * 0.05, PI * 0.92, 22, Color(color.r, color.g, color.b, 0.28), 1.0, true)
