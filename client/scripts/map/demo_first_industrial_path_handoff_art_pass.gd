extends RefCounted
class_name DemoFirstIndustrialPathHandoffArtPass

const BASE_HANDOFF_ASSET_BASIC_REACTOR := preload("res://assets/sprites/demo_first_screen/basic_reactor_module.svg")
const BASE_HANDOFF_ASSET_STORAGE_BANK := preload("res://assets/sprites/demo_first_screen/storage_crate_bank.svg")
const BASE_HANDOFF_ASSET_OUTFITTING_STATION := preload("res://assets/sprites/demo_first_screen/outfitting_station_rack.svg")
const BASE_HANDOFF_ASSET_PIPE_BUNDLE := preload("res://assets/sprites/demo_first_screen/pipe_bundle.svg")

const STAGE_BASE_RECEIVING := "base_receiving"
const STAGE_REACTOR_FEED := "reactor_feed"
const STAGE_REACTOR_PROCESSING := "reactor_processing"
const STAGE_STORAGE_OUTPUT := "storage_output"

const LOGISTICS_PORT := Color(0.7, 0.76, 0.58, 0.42)
const CRYSTAL_ACCENT := Color(0.34, 0.78, 0.86, 0.32)
const SALVAGE_ACCENT := Color(0.84, 0.7, 0.34, 0.3)
const REACTOR_ACCENT := Color(1.0, 0.58, 0.22, 0.34)
const PRODUCT_ACCENT := Color(0.58, 0.88, 0.52, 0.3)
const OUTFITTING_ACCENT := Color(0.92, 0.74, 0.3, 0.32)
const ACTIVE_STAGE_ACCENT := Color(0.96, 0.74, 0.28, 0.62)

const PATH_SHAPE_IDS := [
	"first_path.assetized_base_handoff_device_group",
	"first_path.assetized_receiving_dock",
	"first_path.assetized_reactor_module",
	"first_path.assetized_storage_bank",
	"first_path.assetized_outfitting_rack",
	"first_path.assetized_handoff_ports",
	"first_path.short_material_flow_segments",
	"first_path.storage_outfitting_handoff_feedback",
	"first_path.handoff_continuity.return_manifest_panel",
	"first_path.handoff_continuity.reactor_hopper_bridge",
	"first_path.handoff_continuity.storage_supply_manifest"
]


static func get_path_shape_ids() -> Array[String]:
	var ids: Array[String] = []
	for shape_id in PATH_SHAPE_IDS:
		ids.append(String(shape_id))
	return ids


static func get_state_shape_ids(path_state: Dictionary) -> Array[String]:
	var ids: Array[String] = []
	if bool(path_state.get("inputs_ready", false)):
		ids.append("first_path.assetized_flow.receiving_packets.ready")
		ids.append("first_path.assetized_flow.reactor_feed_packets.ready")
		ids.append("first_path.handoff_continuity.return_manifest.loaded")
		ids.append("first_path.handoff_continuity.reactor_hopper.armed")
	if bool(path_state.get("reactor_active", false)):
		ids.append("first_path.assetized_feedback.reactor_processing_glow.active")
		ids.append("first_path.handoff_continuity.reactor_hopper.processing")
	if bool(path_state.get("storage_ready", false)):
		ids.append("first_path.assetized_flow.storage_output_packets.ready")
		ids.append("first_path.handoff_continuity.storage_supply_manifest.ready")
	if bool(path_state.get("outfitting_ready", false)):
		ids.append("first_path.assetized_feedback.outfitting_handoff.ready")
		ids.append("first_path.handoff_continuity.outfitting_supply.latched")
	return ids


static func draw_devices(canvas: CanvasItem) -> void:
	if canvas == null:
		return
	_draw_path_asset(
		canvas,
		BASE_HANDOFF_ASSET_PIPE_BUNDLE,
		Rect2(Vector2(-286.0, -164.0), Vector2(220.0, 136.0)),
		Color(0.82, 0.92, 0.84, 0.20)
	)
	_draw_assetized_receiving_dock(canvas)
	_draw_path_asset(
		canvas,
		BASE_HANDOFF_ASSET_BASIC_REACTOR,
		Rect2(Vector2(-222.0, -166.0), Vector2(126.0, 120.0)),
		Color(1.0, 1.0, 1.0, 0.68)
	)
	_draw_path_asset(
		canvas,
		BASE_HANDOFF_ASSET_STORAGE_BANK,
		Rect2(Vector2(-322.0, -38.0), Vector2(138.0, 118.0)),
		Color(0.92, 1.0, 0.94, 0.62)
	)
	_draw_path_asset(
		canvas,
		BASE_HANDOFF_ASSET_OUTFITTING_STATION,
		Rect2(Vector2(-132.0, -82.0), Vector2(116.0, 108.0)),
		Color(0.94, 1.0, 0.96, 0.58)
	)


static func draw_ports(canvas: CanvasItem) -> void:
	if canvas == null:
		return
	_draw_device_port_cluster(canvas, Vector2(-214.0, -112.0), LOGISTICS_PORT, true)
	_draw_device_port_cluster(canvas, Vector2(-184.0, -114.0), REACTOR_ACCENT, true)
	_draw_device_port_cluster(canvas, Vector2(-134.0, -114.0), PRODUCT_ACCENT, false)
	_draw_device_port_cluster(canvas, Vector2(-250.0, 18.0), PRODUCT_ACCENT, true)
	_draw_device_port_cluster(canvas, Vector2(-74.0, -14.0), OUTFITTING_ACCENT, true)
	_draw_short_port_bridge(canvas, Vector2(-214.0, -112.0), Vector2(-184.0, -114.0), REACTOR_ACCENT)
	_draw_short_port_bridge(canvas, Vector2(-134.0, -114.0), Vector2(-250.0, 18.0), PRODUCT_ACCENT)
	_draw_short_port_bridge(canvas, Vector2(-250.0, 18.0), Vector2(-74.0, -14.0), OUTFITTING_ACCENT)


static func draw_feedback(canvas: CanvasItem, path_state: Dictionary, active_stage: String) -> void:
	if canvas == null or path_state.is_empty():
		return
	var inputs_ready := bool(path_state.get("inputs_ready", false))
	var reactor_active := bool(path_state.get("reactor_active", false))
	var storage_ready := bool(path_state.get("storage_ready", false))
	var outfitting_ready := bool(path_state.get("outfitting_ready", false))
	if inputs_ready:
		_draw_return_manifest_panel(
			canvas,
			bool(path_state.get("salvage_ready", false)),
			active_stage in [STAGE_BASE_RECEIVING, STAGE_REACTOR_FEED]
		)
		_draw_reactor_hopper_bridge(canvas, active_stage in [STAGE_REACTOR_FEED, STAGE_REACTOR_PROCESSING])
		_draw_material_packet(canvas, Vector2(-235.0, -138.0), CRYSTAL_ACCENT, true)
		_draw_material_packet(canvas, Vector2(-210.0, -138.0), SALVAGE_ACCENT, bool(path_state.get("salvage_ready", false)))
		_draw_packet_train(
			canvas,
			[Vector2(-214.0, -112.0), Vector2(-198.0, -112.0), Vector2(-184.0, -114.0)],
			REACTOR_ACCENT,
			active_stage in [STAGE_BASE_RECEIVING, STAGE_REACTOR_FEED, STAGE_REACTOR_PROCESSING]
		)
	if reactor_active:
		_draw_reactor_heat_feedback(canvas, Vector2(-166.0, -66.0))
	if storage_ready:
		_draw_storage_supply_manifest(canvas, outfitting_ready, active_stage == STAGE_STORAGE_OUTPUT)
		_draw_material_packet(canvas, Vector2(-276.0, 58.0), PRODUCT_ACCENT, true)
		_draw_material_packet(canvas, Vector2(-246.0, 58.0), OUTFITTING_ACCENT, outfitting_ready)
		_draw_packet_train(
			canvas,
			[Vector2(-134.0, -114.0), Vector2(-176.0, -18.0), Vector2(-250.0, 18.0)],
			PRODUCT_ACCENT,
			active_stage == STAGE_STORAGE_OUTPUT
		)
	if outfitting_ready:
		_draw_storage_supply_manifest(canvas, true, true)
		_draw_outfitting_handoff_feedback(canvas)


static func _draw_assetized_receiving_dock(canvas: CanvasItem) -> void:
	var dock_points := PackedVector2Array([
		Vector2(-262.0, -146.0),
		Vector2(-198.0, -156.0),
		Vector2(-168.0, -132.0),
		Vector2(-178.0, -86.0),
		Vector2(-238.0, -78.0),
		Vector2(-270.0, -104.0),
	])
	canvas.draw_colored_polygon(dock_points, Color(0.034, 0.066, 0.058, 0.72))
	canvas.draw_polyline(dock_points, Color(LOGISTICS_PORT.r, LOGISTICS_PORT.g, LOGISTICS_PORT.b, 0.28), 1.6, true)
	canvas.draw_line(Vector2(-250.0, -126.0), Vector2(-184.0, -132.0), Color(LOGISTICS_PORT.r, LOGISTICS_PORT.g, LOGISTICS_PORT.b, 0.20), 2.0, true)
	canvas.draw_line(Vector2(-248.0, -106.0), Vector2(-188.0, -112.0), Color(LOGISTICS_PORT.r, LOGISTICS_PORT.g, LOGISTICS_PORT.b, 0.16), 1.4, true)
	for x in [-246.0, -224.0, -202.0]:
		canvas.draw_rect(Rect2(Vector2(x, -144.0), Vector2(15.0, 11.0)), Color(0.020, 0.038, 0.034, 0.62), true)
		canvas.draw_rect(Rect2(Vector2(x, -144.0), Vector2(15.0, 11.0)), Color(LOGISTICS_PORT.r, LOGISTICS_PORT.g, LOGISTICS_PORT.b, 0.18), false, 1.0, true)


static func _draw_path_asset(canvas: CanvasItem, texture: Texture2D, rect: Rect2, modulate_color: Color) -> void:
	if texture == null:
		return
	canvas.draw_texture_rect(texture, rect, false, modulate_color)


static func _draw_device_port_cluster(canvas: CanvasItem, center: Vector2, color: Color, has_slot: bool) -> void:
	canvas.draw_rect(Rect2(center + Vector2(-10.0, -8.0), Vector2(20.0, 16.0)), Color(0.008, 0.018, 0.016, 0.78), true)
	canvas.draw_rect(Rect2(center + Vector2(-10.0, -8.0), Vector2(20.0, 16.0)), Color(color.r, color.g, color.b, 0.36), false, 1.4, true)
	canvas.draw_circle(center, 3.2, Color(color.r, color.g, color.b, 0.48))
	if not has_slot:
		return
	canvas.draw_rect(Rect2(center + Vector2(-19.0, -5.0), Vector2(8.0, 10.0)), Color(color.r, color.g, color.b, 0.14), true)
	canvas.draw_rect(Rect2(center + Vector2(11.0, -5.0), Vector2(8.0, 10.0)), Color(color.r, color.g, color.b, 0.16), true)


static func _draw_short_port_bridge(canvas: CanvasItem, from: Vector2, to: Vector2, color: Color) -> void:
	canvas.draw_polyline(PackedVector2Array([from, to]), Color(0.006, 0.014, 0.012, 0.78), 5.0, true)
	canvas.draw_polyline(PackedVector2Array([from, to]), Color(color.r, color.g, color.b, 0.22), 2.2, true)


static func _draw_return_manifest_panel(canvas: CanvasItem, salvage_ready: bool, is_active: bool) -> void:
	var panel := Rect2(Vector2(-270.0, -174.0), Vector2(82.0, 28.0))
	var edge := ACTIVE_STAGE_ACCENT if is_active else LOGISTICS_PORT
	canvas.draw_rect(panel, Color(0.008, 0.018, 0.016, 0.76), true)
	canvas.draw_rect(panel, Color(edge.r, edge.g, edge.b, 0.34), false, 1.4, true)
	_draw_manifest_slot(canvas, Vector2(-258.0, -160.0), CRYSTAL_ACCENT, true)
	_draw_manifest_slot(canvas, Vector2(-238.0, -160.0), SALVAGE_ACCENT, salvage_ready)
	for index in range(3):
		var x := -212.0 + float(index) * 8.0
		canvas.draw_circle(Vector2(x, -160.0), 2.5, Color(LOGISTICS_PORT.r, LOGISTICS_PORT.g, LOGISTICS_PORT.b, 0.18 + 0.08 * float(index)))
	canvas.draw_line(Vector2(-206.0, -146.0), Vector2(-206.0, -126.0), Color(edge.r, edge.g, edge.b, 0.20), 1.6, true)


static func _draw_reactor_hopper_bridge(canvas: CanvasItem, is_active: bool) -> void:
	var edge := ACTIVE_STAGE_ACCENT if is_active else REACTOR_ACCENT
	var trough := PackedVector2Array([
		Vector2(-224.0, -126.0),
		Vector2(-186.0, -128.0),
		Vector2(-170.0, -118.0),
		Vector2(-184.0, -106.0),
		Vector2(-222.0, -108.0),
		Vector2(-224.0, -126.0)
	])
	canvas.draw_colored_polygon(trough, Color(0.012, 0.024, 0.020, 0.70))
	canvas.draw_polyline(trough, Color(edge.r, edge.g, edge.b, 0.32), 1.4, true)
	canvas.draw_line(Vector2(-218.0, -116.0), Vector2(-184.0, -116.0), Color(edge.r, edge.g, edge.b, 0.26), 2.0, true)
	var packet_alpha := 0.56 if is_active else 0.22
	for center in [Vector2(-210.0, -116.0), Vector2(-198.0, -116.0), Vector2(-186.0, -116.0)]:
		canvas.draw_circle(center, 2.6, Color(edge.r, edge.g, edge.b, packet_alpha))


static func _draw_storage_supply_manifest(canvas: CanvasItem, outfitting_ready: bool, is_active: bool) -> void:
	var edge := ACTIVE_STAGE_ACCENT if is_active else PRODUCT_ACCENT
	var panel := Rect2(Vector2(-292.0, 76.0), Vector2(78.0, 26.0))
	canvas.draw_rect(panel, Color(0.008, 0.018, 0.016, 0.74), true)
	canvas.draw_rect(panel, Color(edge.r, edge.g, edge.b, 0.32), false, 1.3, true)
	_draw_manifest_slot(canvas, Vector2(-280.0, 89.0), PRODUCT_ACCENT, true)
	_draw_manifest_slot(canvas, Vector2(-260.0, 89.0), OUTFITTING_ACCENT, outfitting_ready)
	canvas.draw_line(Vector2(-236.0, 76.0), Vector2(-158.0, 40.0), Color(edge.r, edge.g, edge.b, 0.18), 2.0, true)
	canvas.draw_line(Vector2(-158.0, 40.0), Vector2(-80.0, -12.0), Color(OUTFITTING_ACCENT.r, OUTFITTING_ACCENT.g, OUTFITTING_ACCENT.b, 0.22 if outfitting_ready else 0.12), 1.8, true)
	if not outfitting_ready:
		return
	for latch in [Vector2(-104.0, -12.0), Vector2(-92.0, -12.0), Vector2(-80.0, -12.0)]:
		canvas.draw_rect(Rect2(latch + Vector2(-3.4, -3.4), Vector2(6.8, 6.8)), Color(OUTFITTING_ACCENT.r, OUTFITTING_ACCENT.g, OUTFITTING_ACCENT.b, 0.38), true)


static func _draw_manifest_slot(canvas: CanvasItem, center: Vector2, color: Color, is_ready: bool) -> void:
	var alpha := 0.42 if is_ready else 0.12
	var rect := Rect2(center + Vector2(-6.0, -5.0), Vector2(12.0, 10.0))
	canvas.draw_rect(rect, Color(0.010, 0.020, 0.018, 0.70), true)
	canvas.draw_rect(rect.grow(-2.0), Color(color.r, color.g, color.b, alpha), true)
	canvas.draw_rect(rect, Color(color.r, color.g, color.b, 0.32 if is_ready else 0.12), false, 1.0, true)


static func _draw_material_packet(canvas: CanvasItem, center: Vector2, color: Color, is_ready: bool) -> void:
	var alpha := 0.42 if is_ready else 0.12
	var rect := Rect2(center + Vector2(-8.0, -5.0), Vector2(16.0, 10.0))
	canvas.draw_rect(rect, Color(0.010, 0.020, 0.018, 0.68), true)
	canvas.draw_rect(rect.grow(-2.0), Color(color.r, color.g, color.b, alpha), true)
	canvas.draw_rect(rect, Color(color.r, color.g, color.b, 0.34 if is_ready else 0.14), false, 1.0, true)


static func _draw_packet_train(canvas: CanvasItem, points: Array, color: Color, is_active: bool) -> void:
	var packet_alpha := 0.58 if is_active else 0.22
	for index in range(points.size() - 1):
		var from: Vector2 = points[index]
		var to: Vector2 = points[index + 1]
		for ratio in [0.35, 0.70]:
			var center := from.lerp(to, ratio)
			canvas.draw_circle(center, 2.8, Color(color.r, color.g, color.b, packet_alpha))
			if is_active:
				canvas.draw_arc(center, 6.0, 0.0, TAU, 16, Color(color.r, color.g, color.b, 0.24), 1.0, true)


static func _draw_reactor_heat_feedback(canvas: CanvasItem, center: Vector2) -> void:
	canvas.draw_rect(Rect2(center + Vector2(-20.0, -28.0), Vector2(40.0, 56.0)), Color(REACTOR_ACCENT.r, REACTOR_ACCENT.g, REACTOR_ACCENT.b, 0.12), true)
	canvas.draw_arc(center, 28.0, PI * 0.08, PI * 1.9, 36, Color(REACTOR_ACCENT.r, REACTOR_ACCENT.g, REACTOR_ACCENT.b, 0.48), 2.0, true)
	for y in [-18.0, -6.0, 6.0, 18.0]:
		canvas.draw_line(center + Vector2(-12.0, y), center + Vector2(12.0, y + 6.0), Color(1.0, 0.78, 0.34, 0.30), 1.4, true)


static func _draw_outfitting_handoff_feedback(canvas: CanvasItem) -> void:
	var chain_points := [Vector2(-250.0, 18.0), Vector2(-170.0, 28.0), Vector2(-92.0, -2.0), Vector2(-74.0, -14.0)]
	_draw_packet_train(canvas, chain_points, OUTFITTING_ACCENT, true)
	for latch in [Vector2(-92.0, -18.0), Vector2(-78.0, -18.0), Vector2(-64.0, -18.0)]:
		canvas.draw_rect(Rect2(latch + Vector2(-4.0, -4.0), Vector2(8.0, 8.0)), Color(OUTFITTING_ACCENT.r, OUTFITTING_ACCENT.g, OUTFITTING_ACCENT.b, 0.36), true)
	canvas.draw_arc(Vector2(-74.0, -14.0), 24.0, PI * 0.1, PI * 1.74, 32, Color(OUTFITTING_ACCENT.r, OUTFITTING_ACCENT.g, OUTFITTING_ACCENT.b, 0.42), 1.6, true)
