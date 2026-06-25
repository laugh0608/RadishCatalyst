extends RefCounted
class_name PrototypeInteractableSemanticSilhouette

const SILHOUETTE_OUTPOST_CORE := "semantic.outpost_core"
const SILHOUETTE_BASIC_REACTOR := "semantic.basic_reactor"
const SILHOUETTE_BASIC_STORAGE := "semantic.basic_storage"
const SILHOUETTE_FIELD_OUTFITTING_STATION := "semantic.field_outfitting_station"
const SILHOUETTE_POLLUTION_FILTER := "semantic.pollution_filter"
const SILHOUETTE_CRYSTAL_COLLECTOR := "semantic.crystal_collector"
const SILHOUETTE_CORE_WRITE_DEVICE := "semantic.core_write_device"

const OUTPOST_CORE_COLOR := Color(0.28, 0.72, 0.76, 1)
const REACTOR_COLOR := Color(1.0, 0.62, 0.24, 1.0)
const STORAGE_COLOR := Color(0.36, 0.62, 0.56, 1)
const OUTFITTING_COLOR := Color(0.66, 0.58, 0.34, 1)
const FILTER_COLOR := Color(0.64, 0.78, 0.3, 1)
const COLLECTOR_COLOR := Color(0.48, 0.72, 0.62, 1)
const CORE_WRITE_COLOR := Color(0.36, 0.96, 0.9, 1.0)

const SEMANTIC_SILHOUETTE_PARTS := {
	SILHOUETTE_OUTPOST_CORE: [
		"semantic.outpost_core.service_ring",
		"semantic.outpost_core.uplink_mast",
		"semantic.outpost_core.status_lights",
		"semantic.outpost_core.machine_base",
		"semantic.outpost_core.service_clamps"
	],
	SILHOUETTE_BASIC_REACTOR: [
		"semantic.basic_reactor.heat_chamber",
		"semantic.basic_reactor.input_output_ports",
		"semantic.basic_reactor.reaction_coils",
		"semantic.basic_reactor.feed_hopper",
		"semantic.basic_reactor.output_tray",
		"semantic.basic_reactor.vent_stack"
	],
	SILHOUETTE_BASIC_STORAGE: [
		"semantic.basic_storage.shelf_bins",
		"semantic.basic_storage.cargo_slots",
		"semantic.basic_storage.logistics_port",
		"semantic.basic_storage.cargo_tray",
		"semantic.basic_storage.latch_lights"
	],
	SILHOUETTE_FIELD_OUTFITTING_STATION: [
		"semantic.field_outfitting_station.module_rack",
		"semantic.field_outfitting_station.supply_rail",
		"semantic.field_outfitting_station.ready_lights",
		"semantic.field_outfitting_station.suit_frame",
		"semantic.field_outfitting_station.tool_cradle"
	],
	SILHOUETTE_POLLUTION_FILTER: [
		"semantic.pollution_filter.twin_columns",
		"semantic.pollution_filter.sludge_inlet",
		"semantic.pollution_filter.clean_output"
	],
	SILHOUETTE_CRYSTAL_COLLECTOR: [
		"semantic.crystal_collector.drill_arm",
		"semantic.crystal_collector.output_tray",
		"semantic.crystal_collector.status_lights"
	],
	SILHOUETTE_CORE_WRITE_DEVICE: [
		"semantic.core_write_device.write_ring",
		"semantic.core_write_device.cross_bus",
		"semantic.core_write_device.verify_panel"
	]
}


static func get_silhouette_id(definition_id: String) -> String:
	match definition_id:
		"building.outpost_core":
			return SILHOUETTE_OUTPOST_CORE
		"building.basic_reactor":
			return SILHOUETTE_BASIC_REACTOR
		"building.basic_storage":
			return SILHOUETTE_BASIC_STORAGE
		"building.field_outfitting_station":
			return SILHOUETTE_FIELD_OUTFITTING_STATION
		"building.pollution_filter":
			return SILHOUETTE_POLLUTION_FILTER
		"building.crystal_collector_t1", "map_object.crystal_collector_output":
			return SILHOUETTE_CRYSTAL_COLLECTOR
		"map_object.demo_stabilization_core":
			return SILHOUETTE_CORE_WRITE_DEVICE
	return ""


static func get_part_ids(silhouette_id: String) -> Array[String]:
	var part_ids: Array[String] = []
	var source_parts: Array = SEMANTIC_SILHOUETTE_PARTS.get(silhouette_id, [])
	for part_id in source_parts:
		part_ids.append(String(part_id))
	return part_ids


static func draw(canvas: CanvasItem, silhouette_id: String) -> void:
	if canvas == null or silhouette_id.is_empty():
		return
	var accent := get_silhouette_color(silhouette_id)
	_draw_semantic_shadow(canvas)
	match silhouette_id:
		SILHOUETTE_OUTPOST_CORE:
			_draw_outpost_core_silhouette(canvas, accent)
		SILHOUETTE_BASIC_REACTOR:
			_draw_basic_reactor_silhouette(canvas, accent)
		SILHOUETTE_BASIC_STORAGE:
			_draw_basic_storage_silhouette(canvas, accent)
		SILHOUETTE_FIELD_OUTFITTING_STATION:
			_draw_field_outfitting_station_silhouette(canvas, accent)
		SILHOUETTE_POLLUTION_FILTER:
			_draw_pollution_filter_silhouette(canvas, accent)
		SILHOUETTE_CRYSTAL_COLLECTOR:
			_draw_crystal_collector_silhouette(canvas, accent)
		SILHOUETTE_CORE_WRITE_DEVICE:
			_draw_core_write_device_silhouette(canvas, accent)


static func get_silhouette_color(silhouette_id: String) -> Color:
	match silhouette_id:
		SILHOUETTE_OUTPOST_CORE:
			return OUTPOST_CORE_COLOR
		SILHOUETTE_BASIC_REACTOR:
			return REACTOR_COLOR
		SILHOUETTE_BASIC_STORAGE:
			return STORAGE_COLOR
		SILHOUETTE_FIELD_OUTFITTING_STATION:
			return OUTFITTING_COLOR
		SILHOUETTE_POLLUTION_FILTER:
			return FILTER_COLOR
		SILHOUETTE_CRYSTAL_COLLECTOR:
			return COLLECTOR_COLOR
		SILHOUETTE_CORE_WRITE_DEVICE:
			return CORE_WRITE_COLOR
	return Color(0.862745, 0.737255, 0.266667, 1)


static func _draw_semantic_shadow(canvas: CanvasItem) -> void:
	canvas.draw_circle(Vector2(0.0, 13.0), 26.0, Color(0.01, 0.024, 0.022, 0.34))


static func _draw_outpost_core_silhouette(canvas: CanvasItem, accent: Color) -> void:
	canvas.draw_rect(Rect2(Vector2(-25.0, 25.0), Vector2(50.0, 11.0)), Color(0.018, 0.045, 0.043, 0.7), true)
	canvas.draw_rect(Rect2(Vector2(-25.0, 25.0), Vector2(50.0, 11.0)), _alpha(accent, 0.44), false, 1.2, true)
	canvas.draw_circle(Vector2.ZERO, 25.0, _alpha(accent, 0.18))
	canvas.draw_arc(Vector2.ZERO, 31.0, PI * 0.12, PI * 1.88, 42, _alpha(accent, 0.78), 2.0, true)
	canvas.draw_arc(Vector2.ZERO, 17.0, 0.0, TAU, 34, _alpha(Color(0.9, 1.0, 0.96, 1.0), 0.72), 1.8, true)
	canvas.draw_line(Vector2(0.0, -33.0), Vector2(0.0, -18.0), _alpha(accent, 0.9), 2.2, true)
	canvas.draw_line(Vector2(-10.0, -31.0), Vector2(10.0, -31.0), _alpha(accent, 0.72), 1.6, true)
	for clamp in [Vector2(-29.0, -4.0), Vector2(21.0, -4.0), Vector2(-18.0, 21.0), Vector2(10.0, 21.0)]:
		canvas.draw_rect(Rect2(clamp, Vector2(8.0, 7.0)), _alpha(accent, 0.32), true)
	for index in range(3):
		canvas.draw_circle(Vector2(-12.0 + float(index) * 12.0, 22.0), 3.2, _alpha(accent, 0.62))


static func _draw_basic_reactor_silhouette(canvas: CanvasItem, accent: Color) -> void:
	var body := Rect2(Vector2(-24.0, -31.0), Vector2(48.0, 62.0))
	canvas.draw_rect(body, Color(0.05, 0.034, 0.018, 0.62), true)
	canvas.draw_rect(body, _alpha(accent, 0.82), false, 1.8, true)
	canvas.draw_rect(Rect2(Vector2(-41.0, -21.0), Vector2(16.0, 18.0)), Color(0.02, 0.046, 0.044, 0.68), true)
	canvas.draw_rect(Rect2(Vector2(-41.0, -21.0), Vector2(16.0, 18.0)), _alpha(Color(0.32, 0.84, 0.94, 1.0), 0.56), false, 1.2, true)
	canvas.draw_rect(Rect2(Vector2(24.0, 13.0), Vector2(20.0, 12.0)), Color(0.02, 0.046, 0.036, 0.68), true)
	canvas.draw_rect(Rect2(Vector2(24.0, 13.0), Vector2(20.0, 12.0)), _alpha(Color(0.62, 0.92, 0.54, 1.0), 0.56), false, 1.2, true)
	var chamber := Rect2(Vector2(-11.0, -25.0), Vector2(22.0, 50.0))
	canvas.draw_rect(chamber, _alpha(accent, 0.28), true)
	canvas.draw_rect(chamber, _alpha(Color(1.0, 0.82, 0.34, 1.0), 0.76), false, 1.4, true)
	for y in [-17.0, -5.0, 7.0]:
		canvas.draw_line(Vector2(-9.0, y), Vector2(9.0, y + 6.0), _alpha(Color(1.0, 0.82, 0.34, 1.0), 0.5), 1.2, true)
	for x in [-12.0, 0.0, 12.0]:
		canvas.draw_line(Vector2(x, -32.0), Vector2(x + 3.0, -43.0), _alpha(accent, 0.34), 1.8, true)
	_draw_semantic_port(canvas, Vector2(-33.0, -12.0), Color(0.32, 0.84, 0.94, 1.0))
	_draw_semantic_port(canvas, Vector2(33.0, 12.0), Color(0.62, 0.92, 0.54, 1.0))


static func _draw_basic_storage_silhouette(canvas: CanvasItem, accent: Color) -> void:
	var body := Rect2(Vector2(-28.0, -21.0), Vector2(56.0, 42.0))
	canvas.draw_rect(body, Color(0.025, 0.06, 0.046, 0.62), true)
	canvas.draw_rect(body, _alpha(accent, 0.78), false, 1.8, true)
	for y in [-7.0, 8.0]:
		canvas.draw_line(Vector2(-24.0, y), Vector2(24.0, y), _alpha(accent, 0.42), 1.4, true)
	for slot in [
		Rect2(Vector2(-22.0, -17.0), Vector2(13.0, 8.0)),
		Rect2(Vector2(-5.0, -2.0), Vector2(14.0, 8.0)),
		Rect2(Vector2(10.0, 12.0), Vector2(12.0, 7.0))
	]:
		canvas.draw_rect(slot, _alpha(accent, 0.36), true)
	canvas.draw_rect(Rect2(Vector2(-26.0, 23.0), Vector2(52.0, 8.0)), Color(0.014, 0.032, 0.028, 0.68), true)
	canvas.draw_rect(Rect2(Vector2(-26.0, 23.0), Vector2(52.0, 8.0)), _alpha(accent, 0.34), false, 1.0, true)
	for x in [-20.0, -5.0, 10.0, 25.0]:
		canvas.draw_circle(Vector2(x, 17.0), 2.0, _alpha(accent, 0.6))
	canvas.draw_circle(Vector2(30.0, 18.0), 4.2, _alpha(accent, 0.62))


static func _draw_field_outfitting_station_silhouette(canvas: CanvasItem, accent: Color) -> void:
	canvas.draw_line(Vector2(-30.0, -24.0), Vector2(30.0, -24.0), _alpha(accent, 0.86), 2.2, true)
	canvas.draw_line(Vector2(-30.0, -24.0), Vector2(-30.0, 23.0), _alpha(accent, 0.76), 2.0, true)
	canvas.draw_line(Vector2(30.0, -24.0), Vector2(30.0, 23.0), _alpha(accent, 0.76), 2.0, true)
	var bench := Rect2(Vector2(-24.0, -7.0), Vector2(48.0, 18.0))
	canvas.draw_rect(bench, Color(0.08, 0.065, 0.028, 0.66), true)
	canvas.draw_rect(bench, _alpha(accent, 0.72), false, 1.6, true)
	for x in [-18.0, 0.0, 18.0]:
		canvas.draw_line(Vector2(x, -21.0), Vector2(x + 6.0, 18.0), _alpha(accent, 0.34), 1.4, true)
	canvas.draw_line(Vector2(0.0, -22.0), Vector2(0.0, 14.0), _alpha(accent, 0.46), 1.8, true)
	canvas.draw_line(Vector2(-13.0, 14.0), Vector2(13.0, 14.0), _alpha(accent, 0.38), 1.6, true)
	canvas.draw_rect(Rect2(Vector2(-29.0, 14.0), Vector2(17.0, 10.0)), Color(0.05, 0.044, 0.02, 0.66), true)
	canvas.draw_rect(Rect2(Vector2(-29.0, 14.0), Vector2(17.0, 10.0)), _alpha(accent, 0.36), false, 1.0, true)
	canvas.draw_circle(Vector2(-16.0, -16.0), 3.4, _alpha(accent, 0.72))
	canvas.draw_circle(Vector2(16.0, -16.0), 3.4, _alpha(Color(0.72, 0.92, 1.0, 1.0), 0.72))


static func _draw_pollution_filter_silhouette(canvas: CanvasItem, accent: Color) -> void:
	var body := Rect2(Vector2(-25.0, -28.0), Vector2(50.0, 56.0))
	canvas.draw_rect(body, Color(0.054, 0.07, 0.026, 0.64), true)
	canvas.draw_rect(body, _alpha(accent, 0.72), false, 1.6, true)
	for x in [-9.0, 9.0]:
		canvas.draw_rect(Rect2(Vector2(x - 4.0, -22.0), Vector2(8.0, 40.0)), _alpha(accent, 0.34), true)
		canvas.draw_line(Vector2(x, -22.0), Vector2(x, 18.0), _alpha(accent, 0.9), 2.0, true)
	_draw_semantic_port(canvas, Vector2(-32.0, 10.0), Color(0.84, 0.78, 0.26, 1.0))
	_draw_semantic_port(canvas, Vector2(32.0, -10.0), Color(0.72, 0.96, 0.38, 1.0))
	canvas.draw_circle(Vector2(22.0, -25.0), 4.0, _alpha(Color(1.0, 0.56, 0.24, 1.0), 0.7))


static func _draw_crystal_collector_silhouette(canvas: CanvasItem, accent: Color) -> void:
	var base := Rect2(Vector2(-24.0, -12.0), Vector2(36.0, 24.0))
	canvas.draw_rect(base, Color(0.035, 0.07, 0.06, 0.68), true)
	canvas.draw_rect(base, _alpha(accent, 0.72), false, 1.5, true)
	canvas.draw_arc(Vector2(-2.0, -3.0), 21.0, PI * 0.1, PI * 1.68, 28, _alpha(accent, 0.62), 2.0, true)
	canvas.draw_line(Vector2(12.0, -3.0), Vector2(33.0, -20.0), _alpha(accent, 0.58), 2.0, true)
	canvas.draw_line(Vector2(31.0, -20.0), Vector2(39.0, -15.0), _alpha(Color(0.7, 0.95, 1.0, 1.0), 0.58), 1.5, true)
	var tray := Rect2(Vector2(-42.0, 6.0), Vector2(26.0, 12.0))
	canvas.draw_rect(tray, Color(0.018, 0.035, 0.032, 0.68), true)
	canvas.draw_rect(tray, _alpha(accent, 0.58), false, 1.3, true)
	canvas.draw_line(Vector2(-16.0, 8.0), Vector2(-2.0, 4.0), _alpha(accent, 0.34), 1.6, true)


static func _draw_core_write_device_silhouette(canvas: CanvasItem, accent: Color) -> void:
	var tower := Rect2(Vector2(-29.0, -38.0), Vector2(58.0, 76.0))
	canvas.draw_rect(tower, Color(0.026, 0.075, 0.07, 0.66), true)
	canvas.draw_rect(tower, _alpha(accent, 0.72), false, 1.8, true)
	canvas.draw_arc(Vector2.ZERO, 28.0, 0.0, TAU, 42, _alpha(accent, 0.84), 2.2, true)
	canvas.draw_arc(Vector2.ZERO, 14.0, 0.0, TAU, 30, _alpha(Color(0.9, 1.0, 0.94, 1.0), 0.68), 1.4, true)
	canvas.draw_line(Vector2(-25.0, 0.0), Vector2(25.0, 0.0), _alpha(accent, 0.62), 1.8, true)
	canvas.draw_line(Vector2(0.0, -34.0), Vector2(0.0, 34.0), _alpha(accent, 0.62), 1.8, true)
	var panel := Rect2(Vector2(22.0, 24.0), Vector2(26.0, 15.0))
	canvas.draw_rect(panel, Color(0.012, 0.026, 0.028, 0.72), true)
	canvas.draw_rect(panel, _alpha(Color(0.9, 0.76, 0.28, 1.0), 0.7), false, 1.2, true)
	for index in range(3):
		canvas.draw_circle(Vector2(28.0 + float(index) * 7.0, 31.5), 2.0, _alpha(Color(0.9, 0.76, 0.28, 1.0), 0.72))


static func _draw_semantic_port(canvas: CanvasItem, center: Vector2, color: Color) -> void:
	canvas.draw_rect(Rect2(center + Vector2(-5.0, -5.0), Vector2(10.0, 10.0)), Color(0.012, 0.026, 0.024, 0.68), true)
	canvas.draw_rect(Rect2(center + Vector2(-5.0, -5.0), Vector2(10.0, 10.0)), _alpha(color, 0.58), false, 1.2, true)


static func _alpha(color: Color, alpha: float) -> Color:
	return Color(color.r, color.g, color.b, alpha)
