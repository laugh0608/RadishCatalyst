extends Node2D
class_name DemoBaseStartupPresentationLayer

const RESTORE_OUTPOST_QUEST_ID := "quest.restore_outpost"

const PRESENTATION_SHAPES := {
	"startup_presentation.opaque_scene_backdrop": true,
	"startup_presentation.hangar_floor": true,
	"startup_presentation.floor_material_tiles": true,
	"startup_presentation.core_machine_body": true,
	"startup_presentation.core_machine_plinth": true,
	"startup_presentation.cold_cable_runs": true,
	"startup_presentation.device_silhouettes": true,
	"startup_presentation.local_shadows": true,
	"startup_presentation.core_reactor_housing": true,
	"startup_presentation.diegetic_repair_port": true,
	"startup_presentation.player_service_rig": true,
	"startup_presentation.floor_debris_and_bolts": true,
}

const BACKDROP_RECT := Rect2(Vector2(-760.0, -420.0), Vector2(1520.0, 840.0))
const CORE_CENTER := Vector2(-310.0, -92.0)
const PLAYER_PAD_CENTER := Vector2(-214.0, -54.0)

var startup_active := true


func _ready() -> void:
	z_index = 24
	process_priority = 140
	visible = startup_active
	queue_redraw()


func refresh_startup_state(world_state: WorldState) -> void:
	startup_active = _should_show_startup_presentation(world_state)
	visible = startup_active
	queue_redraw()


func is_startup_active() -> bool:
	return startup_active


func has_presentation_shape(shape_id: String) -> bool:
	return PRESENTATION_SHAPES.has(shape_id)


func get_presentation_shape_count() -> int:
	return PRESENTATION_SHAPES.size()


func _draw() -> void:
	if not startup_active:
		return

	_draw_scene_backdrop()
	_draw_local_shadows()
	_draw_hangar_floor()
	_draw_floor_material_breakup()
	_draw_device_silhouettes()
	_draw_cable_runs()
	_draw_core_machine()
	_draw_player_work_pad()
	_draw_diegetic_repair_anchor()


func _should_show_startup_presentation(world_state: WorldState) -> bool:
	if world_state == null:
		return true

	return not world_state.quest_state.has_completed_quest(RESTORE_OUTPOST_QUEST_ID)


func _draw_scene_backdrop() -> void:
	draw_rect(BACKDROP_RECT, Color(0.008, 0.018, 0.019, 0.985), true)
	draw_rect(Rect2(Vector2(-760.0, -420.0), Vector2(255.0, 840.0)), Color(0.02, 0.026, 0.026, 0.72), true)
	draw_rect(Rect2(Vector2(330.0, -420.0), Vector2(430.0, 840.0)), Color(0.012, 0.018, 0.019, 0.78), true)
	draw_rect(Rect2(Vector2(-700.0, -318.0), Vector2(1360.0, 34.0)), Color(0.018, 0.031, 0.032, 0.92), true)
	draw_rect(Rect2(Vector2(-700.0, 252.0), Vector2(1360.0, 48.0)), Color(0.018, 0.028, 0.028, 0.94), true)


func _draw_local_shadows() -> void:
	_draw_soft_shadow(Vector2(-304.0, -56.0), Vector2(210.0, 72.0), 0.44)
	_draw_soft_shadow(Vector2(-168.0, -38.0), Vector2(118.0, 50.0), 0.36)
	_draw_soft_shadow(Vector2(-98.0, -8.0), Vector2(180.0, 48.0), 0.28)
	_draw_soft_shadow(Vector2(-268.0, 92.0), Vector2(300.0, 82.0), 0.26)
	_draw_soft_shadow(Vector2(-316.0, -76.0), Vector2(150.0, 116.0), 0.24)
	_draw_soft_shadow(Vector2(-222.0, -42.0), Vector2(140.0, 62.0), 0.32)


func _draw_hangar_floor() -> void:
	var deck_points := PackedVector2Array([
		Vector2(-412.0, -214.0),
		Vector2(220.0, -208.0),
		Vector2(304.0, -76.0),
		Vector2(226.0, 198.0),
		Vector2(-430.0, 178.0),
		Vector2(-486.0, 54.0),
		Vector2(-468.0, -128.0),
	])
	draw_colored_polygon(deck_points, Color(0.036, 0.065, 0.061, 0.96))

	var deck_edge := [
		Vector2(-412.0, -214.0),
		Vector2(220.0, -208.0),
		Vector2(304.0, -76.0),
		Vector2(226.0, 198.0),
		Vector2(-430.0, 178.0),
		Vector2(-486.0, 54.0),
		Vector2(-468.0, -128.0),
	]
	_draw_polyline_closed(deck_edge, Color(0.19, 0.36, 0.32, 0.42), 2.0)

	var plates := [
		Rect2(Vector2(-392.0, -176.0), Vector2(124.0, 78.0)),
		Rect2(Vector2(-248.0, -178.0), Vector2(132.0, 88.0)),
		Rect2(Vector2(-96.0, -170.0), Vector2(118.0, 92.0)),
		Rect2(Vector2(-408.0, -66.0), Vector2(142.0, 98.0)),
		Rect2(Vector2(-244.0, -58.0), Vector2(130.0, 94.0)),
		Rect2(Vector2(-92.0, -44.0), Vector2(146.0, 96.0)),
		Rect2(Vector2(72.0, -132.0), Vector2(130.0, 90.0)),
		Rect2(Vector2(62.0, -20.0), Vector2(154.0, 88.0)),
		Rect2(Vector2(-356.0, 62.0), Vector2(166.0, 78.0)),
		Rect2(Vector2(-156.0, 74.0), Vector2(184.0, 70.0)),
		Rect2(Vector2(34.0, 90.0), Vector2(160.0, 64.0)),
	]

	for plate in plates:
		_draw_floor_plate(plate)

	for x in [-368.0, -290.0, -212.0, -134.0, -56.0, 22.0, 100.0, 178.0]:
		draw_line(Vector2(x, -194.0), Vector2(x + 24.0, 158.0), Color(0.20, 0.38, 0.34, 0.10), 1.0)

	for y in [-142.0, -82.0, -22.0, 38.0, 98.0, 158.0]:
		draw_line(Vector2(-438.0, y), Vector2(250.0, y - 4.0), Color(0.22, 0.39, 0.35, 0.10), 1.0)

	draw_line(Vector2(-412.0, 146.0), Vector2(-104.0, 212.0), Color(0.14, 0.30, 0.29, 0.23), 3.0)
	draw_line(Vector2(4.0, 168.0), Vector2(142.0, 214.0), Color(0.14, 0.30, 0.29, 0.20), 3.0)


func _draw_device_silhouettes() -> void:
	_draw_disabled_machine(Vector2(142.0, -78.0), Vector2(122.0, 76.0), Color(0.052, 0.082, 0.076, 0.62), Color(0.20, 0.36, 0.31, 0.13))
	_draw_disabled_machine(Vector2(-326.0, 92.0), Vector2(128.0, 72.0), Color(0.060, 0.095, 0.085, 0.70), Color(0.20, 0.36, 0.31, 0.16))
	_draw_disabled_machine(Vector2(-72.0, 106.0), Vector2(154.0, 70.0), Color(0.058, 0.088, 0.081, 0.64), Color(0.20, 0.36, 0.31, 0.14))
	_draw_wall_console(Vector2(-402.0, -150.0), Vector2(96.0, 72.0))
	draw_circle(Vector2(-33.0, -118.0), 8.0, Color(0.22, 0.48, 0.40, 0.18))
	draw_circle(Vector2(-326.0, 92.0), 7.0, Color(0.30, 0.54, 0.43, 0.16))
	draw_line(Vector2(-446.0, -38.0), Vector2(-388.0, -38.0), Color(0.46, 0.92, 0.82, 0.30), 3.0)
	draw_rect(Rect2(Vector2(-456.0, -52.0), Vector2(54.0, 32.0)), Color(0.052, 0.112, 0.104, 0.66), false, 2.0)


func _draw_cable_runs() -> void:
	_draw_cable([
		Vector2(CORE_CENTER.x + 72.0, CORE_CENTER.y + 18.0),
		Vector2(-180.0, -34.0),
		Vector2(-132.0, -2.0),
		Vector2(-96.0, 48.0),
	], Color(0.16, 0.26, 0.24, 0.86), 8.0)
	_draw_cable([
		Vector2(CORE_CENTER.x + 88.0, CORE_CENTER.y - 22.0),
		Vector2(-186.0, -128.0),
		Vector2(-96.0, -132.0),
	], Color(0.14, 0.25, 0.24, 0.72), 6.0)
	_draw_cable([
		Vector2(CORE_CENTER.x - 56.0, CORE_CENTER.y + 52.0),
		Vector2(-398.0, -14.0),
		Vector2(-430.0, 76.0),
	], Color(0.13, 0.24, 0.22, 0.68), 7.0)

	draw_line(Vector2(-192.0, -31.0), Vector2(-154.0, -21.0), Color(0.73, 0.62, 0.32, 0.45), 2.0)
	draw_line(Vector2(-134.0, -1.0), Vector2(-116.0, 24.0), Color(0.73, 0.62, 0.32, 0.36), 2.0)


func _draw_core_machine() -> void:
	_draw_soft_shadow(CORE_CENTER + Vector2(5.0, 42.0), Vector2(180.0, 68.0), 0.52)
	var plinth := PackedVector2Array([
		CORE_CENTER + Vector2(-82.0, 34.0),
		CORE_CENTER + Vector2(64.0, 34.0),
		CORE_CENTER + Vector2(82.0, 54.0),
		CORE_CENTER + Vector2(44.0, 70.0),
		CORE_CENTER + Vector2(-68.0, 68.0),
		CORE_CENTER + Vector2(-92.0, 50.0),
	])
	draw_colored_polygon(plinth, Color(0.024, 0.054, 0.050, 0.98))
	_draw_polyline_closed([plinth[0], plinth[1], plinth[2], plinth[3], plinth[4], plinth[5]], Color(0.42, 0.82, 0.70, 0.32), 2.0)

	var housing := PackedVector2Array([
		CORE_CENTER + Vector2(-72.0, -34.0),
		CORE_CENTER + Vector2(-42.0, -64.0),
		CORE_CENTER + Vector2(36.0, -62.0),
		CORE_CENTER + Vector2(68.0, -30.0),
		CORE_CENTER + Vector2(64.0, 34.0),
		CORE_CENTER + Vector2(28.0, 58.0),
		CORE_CENTER + Vector2(-46.0, 54.0),
		CORE_CENTER + Vector2(-74.0, 18.0),
	])
	draw_colored_polygon(housing, Color(0.074, 0.132, 0.104, 0.98))
	_draw_polyline_closed([housing[0], housing[1], housing[2], housing[3], housing[4], housing[5], housing[6], housing[7]], Color(0.58, 0.86, 0.68, 0.38), 2.0)

	draw_circle(CORE_CENTER, 45.0, Color(0.19, 0.34, 0.24, 0.62))
	draw_circle(CORE_CENTER, 31.0, Color(0.52, 0.76, 0.38, 0.38))
	draw_arc(CORE_CENTER, 43.0, PI * 0.08, PI * 1.88, 46, Color(0.78, 0.96, 0.58, 0.46), 3.0, true)
	draw_arc(CORE_CENTER, 24.0, 0.0, TAU, 38, Color(0.90, 1.0, 0.70, 0.72), 2.4, true)
	draw_circle(CORE_CENTER, 8.0, Color(0.96, 0.84, 0.42, 0.92))

	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var marker_center := CORE_CENTER + Vector2(cos(angle), sin(angle)) * 47.0
		draw_rect(Rect2(marker_center - Vector2(9.0, 5.0), Vector2(18.0, 10.0)), Color(0.18, 0.30, 0.24, 0.78), true)
		draw_rect(Rect2(marker_center - Vector2(9.0, 5.0), Vector2(18.0, 10.0)), Color(0.70, 0.96, 0.76, 0.28), false, 1.0)

	draw_line(CORE_CENTER + Vector2(-54.0, -42.0), CORE_CENTER + Vector2(-84.0, -72.0), Color(0.33, 0.58, 0.52, 0.46), 4.0)
	draw_line(CORE_CENTER + Vector2(50.0, -40.0), CORE_CENTER + Vector2(78.0, -72.0), Color(0.33, 0.58, 0.52, 0.42), 4.0)
	draw_rect(Rect2(CORE_CENTER + Vector2(-18.0, -90.0), Vector2(36.0, 44.0)), Color(0.42, 0.88, 0.76, 0.24), true)
	draw_rect(Rect2(CORE_CENTER + Vector2(-10.0, -80.0), Vector2(20.0, 26.0)), Color(0.90, 1.0, 0.78, 0.22), true)

	for point in [
		CORE_CENTER + Vector2(-56.0, 44.0),
		CORE_CENTER + Vector2(-24.0, 54.0),
		CORE_CENTER + Vector2(20.0, 54.0),
		CORE_CENTER + Vector2(52.0, 42.0),
	]:
		draw_circle(point, 3.4, Color(0.94, 0.70, 0.34, 0.58))


func _draw_player_work_pad() -> void:
	_draw_soft_shadow(PLAYER_PAD_CENTER + Vector2(12.0, 19.0), Vector2(110.0, 46.0), 0.34)
	var pad_poly := PackedVector2Array([
		PLAYER_PAD_CENTER + Vector2(-54.0, -26.0),
		PLAYER_PAD_CENTER + Vector2(38.0, -30.0),
		PLAYER_PAD_CENTER + Vector2(58.0, -6.0),
		PLAYER_PAD_CENTER + Vector2(32.0, 28.0),
		PLAYER_PAD_CENTER + Vector2(-48.0, 26.0),
		PLAYER_PAD_CENTER + Vector2(-64.0, 2.0),
	])
	draw_colored_polygon(pad_poly, Color(0.036, 0.084, 0.079, 0.88))
	_draw_polyline_closed([pad_poly[0], pad_poly[1], pad_poly[2], pad_poly[3], pad_poly[4], pad_poly[5]], Color(0.42, 0.88, 0.80, 0.30), 1.5)
	draw_line(PLAYER_PAD_CENTER + Vector2(-38.0, -14.0), PLAYER_PAD_CENTER + Vector2(34.0, -16.0), Color(0.42, 0.88, 0.80, 0.16), 1.0)
	draw_line(PLAYER_PAD_CENTER + Vector2(-34.0, 15.0), PLAYER_PAD_CENTER + Vector2(28.0, 12.0), Color(0.42, 0.88, 0.80, 0.14), 1.0)
	draw_circle(PLAYER_PAD_CENTER + Vector2(56.0, -10.0), 8.0, Color(0.52, 0.84, 0.70, 0.28))
	draw_rect(Rect2(PLAYER_PAD_CENTER + Vector2(44.0, -22.0), Vector2(26.0, 22.0)), Color(0.020, 0.056, 0.052, 0.72), true)
	draw_rect(Rect2(PLAYER_PAD_CENTER + Vector2(44.0, -22.0), Vector2(26.0, 22.0)), Color(0.72, 0.96, 0.78, 0.26), false, 1.2)


func _draw_diegetic_repair_anchor() -> void:
	var repair_port := CORE_CENTER + Vector2(74.0, 14.0)
	_draw_pipe(
		[repair_port, CORE_CENTER + Vector2(104.0, 24.0), PLAYER_PAD_CENTER + Vector2(66.0, -10.0)],
		Color(0.72, 0.62, 0.34, 0.48),
		4.0
	)
	draw_circle(repair_port, 11.0, Color(0.84, 0.72, 0.36, 0.18))
	draw_arc(repair_port, 14.0, PI * 0.12, PI * 1.72, 24, Color(0.96, 0.76, 0.34, 0.54), 1.5, true)
	draw_circle(repair_port, 4.4, Color(0.98, 0.78, 0.36, 0.74))
	for point in [PLAYER_PAD_CENTER + Vector2(48.0, -10.0), PLAYER_PAD_CENTER + Vector2(62.0, 2.0), CORE_CENTER + Vector2(56.0, 38.0)]:
		draw_circle(point, 3.0, Color(0.96, 0.78, 0.35, 0.52))


func _draw_floor_plate(rect: Rect2) -> void:
	draw_rect(rect, Color(0.028, 0.056, 0.052, 0.62), true)
	draw_rect(rect, Color(0.22, 0.40, 0.35, 0.20), false, 1.0)
	draw_line(rect.position + Vector2(16.0, 16.0), rect.position + Vector2(rect.size.x - 18.0, 20.0), Color(0.28, 0.50, 0.43, 0.12), 1.0)
	draw_line(rect.position + Vector2(24.0, rect.size.y - 18.0), rect.position + Vector2(rect.size.x - 20.0, rect.size.y - 16.0), Color(0.28, 0.50, 0.43, 0.10), 1.0)


func _draw_floor_material_breakup() -> void:
	for point in [
		Vector2(-394.0, -118.0),
		Vector2(-332.0, -46.0),
		Vector2(-258.0, -152.0),
		Vector2(-188.0, 28.0),
		Vector2(-84.0, -112.0),
		Vector2(106.0, -54.0),
		Vector2(28.0, 116.0),
	]:
		draw_circle(point, 2.2, Color(0.50, 0.72, 0.62, 0.12))
		draw_circle(point + Vector2(8.0, 4.0), 1.5, Color(0.72, 0.58, 0.32, 0.12))

	for scar in [
		[Vector2(-360.0, -146.0), Vector2(-332.0, -132.0), Vector2(-306.0, -138.0)],
		[Vector2(-238.0, 92.0), Vector2(-196.0, 106.0), Vector2(-162.0, 98.0)],
		[Vector2(66.0, 36.0), Vector2(100.0, 48.0), Vector2(132.0, 40.0)],
	]:
		draw_polyline(PackedVector2Array(scar), Color(0.42, 0.66, 0.58, 0.12), 1.4, true)

	for stain in [
		Rect2(Vector2(-356.0, 52.0), Vector2(58.0, 16.0)),
		Rect2(Vector2(-134.0, -158.0), Vector2(72.0, 18.0)),
		Rect2(Vector2(92.0, 132.0), Vector2(62.0, 14.0)),
	]:
		draw_rect(stain, Color(0.002, 0.010, 0.010, 0.24), true)


func _draw_disabled_machine(center: Vector2, size: Vector2, fill_color: Color, edge_color: Color) -> void:
	var half := size * 0.5
	var body := PackedVector2Array([
		center + Vector2(-half.x, -half.y + 12.0),
		center + Vector2(-half.x + 18.0, -half.y),
		center + Vector2(half.x - 10.0, -half.y + 4.0),
		center + Vector2(half.x, -half.y + 24.0),
		center + Vector2(half.x - 8.0, half.y - 8.0),
		center + Vector2(-half.x + 12.0, half.y),
		center + Vector2(-half.x, half.y - 18.0),
	])
	draw_colored_polygon(body, fill_color)
	_draw_polyline_closed([body[0], body[1], body[2], body[3], body[4], body[5], body[6]], edge_color, 1.4)
	draw_line(center + Vector2(-half.x + 22.0, -half.y + 22.0), center + Vector2(half.x - 18.0, -half.y + 20.0), Color(edge_color.r, edge_color.g, edge_color.b, edge_color.a * 0.72), 4.0)
	draw_line(center + Vector2(-half.x + 28.0, half.y - 18.0), center + Vector2(half.x - 24.0, half.y - 14.0), Color(edge_color.r, edge_color.g, edge_color.b, edge_color.a * 0.56), 1.2)
	draw_circle(center + Vector2(-8.0, -2.0), 8.0, Color(edge_color.r, edge_color.g, edge_color.b, edge_color.a * 0.54))


func _draw_wall_console(center: Vector2, size: Vector2) -> void:
	var half := size * 0.5
	var frame := PackedVector2Array([
		center + Vector2(-half.x, -half.y + 8.0),
		center + Vector2(-half.x + 12.0, -half.y),
		center + Vector2(half.x, -half.y),
		center + Vector2(half.x - 8.0, half.y),
		center + Vector2(-half.x + 6.0, half.y - 2.0),
	])
	draw_colored_polygon(frame, Color(0.034, 0.074, 0.068, 0.64))
	_draw_polyline_closed([frame[0], frame[1], frame[2], frame[3], frame[4]], Color(0.34, 0.58, 0.50, 0.16), 1.5)
	draw_line(center + Vector2(-half.x + 16.0, -half.y + 18.0), center + Vector2(half.x - 16.0, -half.y + 18.0), Color(0.34, 0.58, 0.50, 0.12), 5.0)


func _draw_machine_silhouette(rect: Rect2, fill_color: Color, edge_color: Color) -> void:
	draw_rect(rect, fill_color, true)
	draw_rect(rect, edge_color, false, 2.0)
	draw_rect(Rect2(rect.position + Vector2(8.0, 8.0), Vector2(rect.size.x - 16.0, 10.0)), Color(edge_color.r, edge_color.g, edge_color.b, edge_color.a * 0.65), true)
	draw_line(rect.position + Vector2(14.0, rect.size.y - 12.0), rect.position + Vector2(rect.size.x - 14.0, rect.size.y - 12.0), Color(edge_color.r, edge_color.g, edge_color.b, edge_color.a * 0.55), 1.0)


func _draw_cable(points: Array[Vector2], color: Color, width: float) -> void:
	if points.size() < 2:
		return

	for index in range(points.size() - 1):
		draw_line(points[index], points[index + 1], Color(0.002, 0.006, 0.006, color.a * 0.55), width + 4.0)
		draw_line(points[index], points[index + 1], color, width)


func _draw_pipe(points: Array[Vector2], color: Color, width: float) -> void:
	_draw_cable(points, color, width)


func _draw_soft_shadow(center: Vector2, size: Vector2, strength: float) -> void:
	var shadow_rect := Rect2(center - size * 0.5, size)
	draw_rect(shadow_rect, Color(0.0, 0.0, 0.0, strength), true)


func _draw_polyline_closed(points: Array[Vector2], color: Color, width: float) -> void:
	if points.size() < 2:
		return

	for index in range(points.size()):
		draw_line(points[index], points[(index + 1) % points.size()], color, width)
