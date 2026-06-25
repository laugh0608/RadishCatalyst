extends RefCounted
class_name DemoBaseFirstScreenArtPass

const SHADOW := Color(0.005, 0.014, 0.014, 0.46)
const FLOOR_PLATE := Color(0.12, 0.22, 0.21, 0.28)
const FLOOR_EDGE := Color(0.55, 0.78, 0.72, 0.18)
const FLOOR_SCAR := Color(0.78, 0.6, 0.32, 0.2)
const COLD_BUS := Color(0.52, 0.66, 0.62, 0.22)
const CORE_SIGNAL := Color(0.42, 1.0, 0.92, 0.7)
const REACTOR_SIGNAL := Color(1.0, 0.62, 0.24, 0.72)
const STORAGE_SIGNAL := Color(0.62, 0.92, 0.64, 0.68)
const OUTFITTING_SIGNAL := Color(0.95, 0.76, 0.28, 0.72)
const MACHINE_DARK := Color(0.015, 0.034, 0.034, 0.72)
const MACHINE_PANEL := Color(0.24, 0.42, 0.4, 0.48)

const DETAIL_SHAPE_IDS := [
	"first_screen.floor.plate_seams",
	"first_screen.floor.local_contact_shadows",
	"first_screen.floor.disconnected_bus_scars",
	"first_screen.floor.player_tool_pad",
	"first_screen.device.outpost_core.machine_base",
	"first_screen.device.outpost_core.service_clamps",
	"first_screen.device.basic_reactor.feed_hopper",
	"first_screen.device.basic_reactor.vent_stack",
	"first_screen.device.basic_reactor.output_tray",
	"first_screen.device.basic_storage.cargo_trays",
	"first_screen.device.basic_storage.latch_lights",
	"first_screen.device.field_outfitting_station.suit_frame",
	"first_screen.device.field_outfitting_station.tool_cradle",
	"first_screen.action_feedback.core_inspection_pulse",
	"first_screen.action_feedback.reactor_port_wake",
	"first_screen.action_feedback.storage_outfitting_handshake"
]


static func get_detail_shape_ids() -> Array[String]:
	var ids: Array[String] = []
	for shape_id in DETAIL_SHAPE_IDS:
		ids.append(String(shape_id))
	return ids


static func draw_floor_and_shadows(canvas: CanvasItem) -> void:
	if canvas == null:
		return
	_draw_contact_shadow(canvas, Vector2(-300.0, -80.0), Vector2(88.0, 28.0))
	_draw_contact_shadow(canvas, Vector2(-166.0, -52.0), Vector2(90.0, 32.0))
	_draw_contact_shadow(canvas, Vector2(-250.0, 32.0), Vector2(102.0, 26.0))
	_draw_contact_shadow(canvas, Vector2(-78.0, -36.0), Vector2(92.0, 26.0))
	_draw_plate(canvas, Rect2(Vector2(-322.0, -120.0), Vector2(92.0, 54.0)))
	_draw_plate(canvas, Rect2(Vector2(-224.0, -122.0), Vector2(116.0, 88.0)))
	_draw_plate(canvas, Rect2(Vector2(-300.0, -22.0), Vector2(120.0, 78.0)))
	_draw_plate(canvas, Rect2(Vector2(-124.0, -78.0), Vector2(96.0, 70.0)))
	_draw_disconnected_bus_scars(canvas)
	_draw_player_tool_pad(canvas)


static func draw_machine_overlays(canvas: CanvasItem) -> void:
	if canvas == null:
		return
	_draw_outpost_core_machine_overlay(canvas)
	_draw_reactor_machine_overlay(canvas)
	_draw_storage_machine_overlay(canvas)
	_draw_outfitting_machine_overlay(canvas)


static func draw_operation_feedback(canvas: CanvasItem) -> void:
	if canvas == null:
		return
	_draw_core_inspection_pulse(canvas)
	_draw_reactor_port_wake(canvas)
	_draw_storage_outfitting_handshake(canvas)


static func _draw_plate(canvas: CanvasItem, rect: Rect2) -> void:
	canvas.draw_rect(rect, FLOOR_PLATE, true)
	canvas.draw_rect(rect, FLOOR_EDGE, false, 1.1, true)
	for x in range(int(rect.position.x) + 14, int(rect.end.x), 28):
		canvas.draw_line(
			Vector2(float(x), rect.position.y + 5.0),
			Vector2(float(x) + 8.0, rect.end.y - 5.0),
			Color(FLOOR_EDGE.r, FLOOR_EDGE.g, FLOOR_EDGE.b, 0.12),
			1.0,
			true
		)
	for y in range(int(rect.position.y) + 18, int(rect.end.y), 24):
		canvas.draw_line(
			Vector2(rect.position.x + 7.0, float(y)),
			Vector2(rect.end.x - 7.0, float(y)),
			Color(FLOOR_EDGE.r, FLOOR_EDGE.g, FLOOR_EDGE.b, 0.1),
			1.0,
			true
		)


static func _draw_contact_shadow(canvas: CanvasItem, center: Vector2, size: Vector2) -> void:
	var rect := Rect2(center - size * 0.5, size)
	canvas.draw_rect(rect, SHADOW, true)
	canvas.draw_rect(rect.grow(-5.0), Color(SHADOW.r, SHADOW.g, SHADOW.b, 0.22), true)


static func _draw_disconnected_bus_scars(canvas: CanvasItem) -> void:
	for segment in [
		[Vector2(-318.0, -152.0), Vector2(-284.0, -132.0)],
		[Vector2(-292.0, -150.0), Vector2(-254.0, -150.0)],
		[Vector2(-236.0, -138.0), Vector2(-210.0, -116.0)],
		[Vector2(-198.0, -18.0), Vector2(-168.0, -4.0)]
	]:
		canvas.draw_line(segment[0], segment[1], COLD_BUS, 2.0, true)
	for point in [Vector2(-284.0, -132.0), Vector2(-236.0, -138.0), Vector2(-168.0, -4.0)]:
		canvas.draw_line(point + Vector2(-5.0, -5.0), point + Vector2(5.0, 5.0), FLOOR_SCAR, 1.4, true)
		canvas.draw_line(point + Vector2(-5.0, 5.0), point + Vector2(5.0, -5.0), FLOOR_SCAR, 1.4, true)


static func _draw_player_tool_pad(canvas: CanvasItem) -> void:
	var pad := Rect2(Vector2(-274.0, -66.0), Vector2(52.0, 34.0))
	canvas.draw_rect(pad, Color(0.04, 0.1, 0.095, 0.42), true)
	canvas.draw_rect(pad, Color(CORE_SIGNAL.r, CORE_SIGNAL.g, CORE_SIGNAL.b, 0.28), false, 1.2, true)
	canvas.draw_line(Vector2(-260.0, -50.0), Vector2(-226.0, -50.0), Color(CORE_SIGNAL.r, CORE_SIGNAL.g, CORE_SIGNAL.b, 0.22), 2.0, true)
	canvas.draw_circle(Vector2(-250.0, -48.0), 4.0, Color(CORE_SIGNAL.r, CORE_SIGNAL.g, CORE_SIGNAL.b, 0.24))


static func _draw_outpost_core_machine_overlay(canvas: CanvasItem) -> void:
	var center := Vector2(-300.0, -92.0)
	canvas.draw_rect(Rect2(center + Vector2(-28.0, 25.0), Vector2(56.0, 12.0)), MACHINE_DARK, true)
	canvas.draw_rect(Rect2(center + Vector2(-28.0, 25.0), Vector2(56.0, 12.0)), Color(CORE_SIGNAL.r, CORE_SIGNAL.g, CORE_SIGNAL.b, 0.34), false, 1.1, true)
	for point in [
		center + Vector2(-32.0, -5.0),
		center + Vector2(24.0, -5.0),
		center + Vector2(-18.0, 24.0),
		center + Vector2(18.0, 24.0)
	]:
		canvas.draw_rect(Rect2(point + Vector2(-4.0, -5.0), Vector2(8.0, 10.0)), MACHINE_PANEL, true)
	canvas.draw_line(center + Vector2(-38.0, 12.0), center + Vector2(-56.0, 24.0), Color(CORE_SIGNAL.r, CORE_SIGNAL.g, CORE_SIGNAL.b, 0.28), 2.0, true)


static func _draw_reactor_machine_overlay(canvas: CanvasItem) -> void:
	canvas.draw_rect(Rect2(Vector2(-214.0, -114.0), Vector2(24.0, 22.0)), MACHINE_DARK, true)
	canvas.draw_rect(Rect2(Vector2(-214.0, -114.0), Vector2(24.0, 22.0)), Color(CORE_SIGNAL.r, CORE_SIGNAL.g, CORE_SIGNAL.b, 0.34), false, 1.2, true)
	canvas.draw_rect(Rect2(Vector2(-140.0, -36.0), Vector2(32.0, 16.0)), MACHINE_DARK, true)
	canvas.draw_rect(Rect2(Vector2(-140.0, -36.0), Vector2(32.0, 16.0)), Color(STORAGE_SIGNAL.r, STORAGE_SIGNAL.g, STORAGE_SIGNAL.b, 0.34), false, 1.2, true)
	for x in [-188.0, -176.0, -164.0, -152.0]:
		canvas.draw_line(Vector2(x, -124.0), Vector2(x + 4.0, -134.0), Color(REACTOR_SIGNAL.r, REACTOR_SIGNAL.g, REACTOR_SIGNAL.b, 0.38), 2.0, true)
	canvas.draw_line(Vector2(-188.0, -136.0), Vector2(-146.0, -136.0), Color(REACTOR_SIGNAL.r, REACTOR_SIGNAL.g, REACTOR_SIGNAL.b, 0.34), 1.4, true)


static func _draw_storage_machine_overlay(canvas: CanvasItem) -> void:
	for index in range(3):
		var slot := Rect2(Vector2(-282.0 + float(index) * 21.0, -10.0), Vector2(16.0, 12.0))
		canvas.draw_rect(slot, MACHINE_DARK, true)
		canvas.draw_rect(slot, Color(STORAGE_SIGNAL.r, STORAGE_SIGNAL.g, STORAGE_SIGNAL.b, 0.28), false, 1.0, true)
	for point in [Vector2(-280.0, 42.0), Vector2(-262.0, 42.0), Vector2(-244.0, 42.0), Vector2(-226.0, 42.0)]:
		canvas.draw_circle(point, 2.4, Color(STORAGE_SIGNAL.r, STORAGE_SIGNAL.g, STORAGE_SIGNAL.b, 0.5))
	canvas.draw_rect(Rect2(Vector2(-286.0, 54.0), Vector2(68.0, 10.0)), Color(STORAGE_SIGNAL.r, STORAGE_SIGNAL.g, STORAGE_SIGNAL.b, 0.14), true)


static func _draw_outfitting_machine_overlay(canvas: CanvasItem) -> void:
	canvas.draw_line(Vector2(-80.0, -78.0), Vector2(-80.0, -28.0), Color(OUTFITTING_SIGNAL.r, OUTFITTING_SIGNAL.g, OUTFITTING_SIGNAL.b, 0.44), 2.0, true)
	canvas.draw_line(Vector2(-98.0, -28.0), Vector2(-62.0, -28.0), Color(OUTFITTING_SIGNAL.r, OUTFITTING_SIGNAL.g, OUTFITTING_SIGNAL.b, 0.32), 2.0, true)
	canvas.draw_rect(Rect2(Vector2(-110.0, -24.0), Vector2(18.0, 12.0)), MACHINE_DARK, true)
	canvas.draw_rect(Rect2(Vector2(-110.0, -24.0), Vector2(18.0, 12.0)), Color(OUTFITTING_SIGNAL.r, OUTFITTING_SIGNAL.g, OUTFITTING_SIGNAL.b, 0.34), false, 1.0, true)
	canvas.draw_rect(Rect2(Vector2(-64.0, -24.0), Vector2(18.0, 12.0)), MACHINE_DARK, true)
	canvas.draw_rect(Rect2(Vector2(-64.0, -24.0), Vector2(18.0, 12.0)), Color(CORE_SIGNAL.r, CORE_SIGNAL.g, CORE_SIGNAL.b, 0.3), false, 1.0, true)


static func _draw_core_inspection_pulse(canvas: CanvasItem) -> void:
	canvas.draw_arc(Vector2(-300.0, -92.0), 40.0, PI * 0.62, PI * 1.18, 18, Color(CORE_SIGNAL.r, CORE_SIGNAL.g, CORE_SIGNAL.b, 0.28), 1.6, true)
	canvas.draw_line(Vector2(-264.0, -50.0), Vector2(-286.0, -78.0), Color(CORE_SIGNAL.r, CORE_SIGNAL.g, CORE_SIGNAL.b, 0.24), 1.6, true)


static func _draw_reactor_port_wake(canvas: CanvasItem) -> void:
	for point in [Vector2(-204.0, -104.0), Vector2(-132.0, -28.0)]:
		canvas.draw_arc(point, 9.0, 0.0, TAU, 18, Color(REACTOR_SIGNAL.r, REACTOR_SIGNAL.g, REACTOR_SIGNAL.b, 0.28), 1.0, true)
		canvas.draw_circle(point, 2.6, Color(REACTOR_SIGNAL.r, REACTOR_SIGNAL.g, REACTOR_SIGNAL.b, 0.42))


static func _draw_storage_outfitting_handshake(canvas: CanvasItem) -> void:
	canvas.draw_polyline(
		PackedVector2Array([Vector2(-218.0, 56.0), Vector2(-138.0, 56.0), Vector2(-92.0, -12.0)]),
		Color(OUTFITTING_SIGNAL.r, OUTFITTING_SIGNAL.g, OUTFITTING_SIGNAL.b, 0.22),
		2.0,
		true
	)
	for point in [Vector2(-218.0, 56.0), Vector2(-138.0, 56.0), Vector2(-92.0, -12.0)]:
		canvas.draw_circle(point, 3.0, Color(OUTFITTING_SIGNAL.r, OUTFITTING_SIGNAL.g, OUTFITTING_SIGNAL.b, 0.34))
