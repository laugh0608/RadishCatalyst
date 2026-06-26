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
	"startup_presentation.perimeter_industrial_assets": true,
	"startup_presentation.broken_pipe_runs": true,
	"startup_presentation.player_repair_action": true,
	"startup_presentation.depth_shadow_layers": true,
	"startup_presentation.damaged_core_equipment": true,
	"startup_presentation.player_character_pose": true,
	"startup_presentation.high_priority_floor_material": true,
	"startup_presentation.close_repair_feedback": true,
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
	_draw_high_priority_floor_material()
	_draw_device_silhouettes()
	_draw_perimeter_industrial_assets()
	_draw_broken_pipe_runs()
	_draw_cable_runs()
	_draw_core_machine()
	_draw_damaged_core_equipment()
	_draw_player_work_pad()
	_draw_diegetic_repair_anchor()
	_draw_player_character_pose()
	_draw_player_repair_action()
	_draw_close_repair_feedback()


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
	draw_rect(Rect2(Vector2(180.0, -250.0), Vector2(260.0, 40.0)), Color(0.0, 0.006, 0.006, 0.20), true)
	draw_rect(Rect2(Vector2(-110.0, 226.0), Vector2(300.0, 44.0)), Color(0.0, 0.006, 0.006, 0.22), true)
	draw_rect(Rect2(Vector2(250.0, 154.0), Vector2(250.0, 36.0)), Color(0.0, 0.006, 0.006, 0.18), true)


func _draw_local_shadows() -> void:
	_draw_soft_shadow(Vector2(-304.0, -56.0), Vector2(210.0, 72.0), 0.44)
	_draw_soft_shadow(Vector2(-168.0, -38.0), Vector2(118.0, 50.0), 0.36)
	_draw_soft_shadow(Vector2(-98.0, -8.0), Vector2(180.0, 48.0), 0.28)
	_draw_soft_shadow(Vector2(-268.0, 92.0), Vector2(300.0, 82.0), 0.26)
	_draw_soft_shadow(Vector2(-316.0, -76.0), Vector2(150.0, 116.0), 0.24)
	_draw_soft_shadow(Vector2(-222.0, -42.0), Vector2(140.0, 62.0), 0.32)
	_draw_soft_shadow(Vector2(150.0, -76.0), Vector2(178.0, 70.0), 0.24)
	_draw_soft_shadow(Vector2(102.0, 130.0), Vector2(250.0, 64.0), 0.22)
	_draw_soft_shadow(Vector2(320.0, 40.0), Vector2(210.0, 56.0), 0.20)


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
	_draw_soft_shadow(CORE_CENTER + Vector2(4.0, 36.0), Vector2(152.0, 58.0), 0.46)
	var plinth := PackedVector2Array([
		CORE_CENTER + Vector2(-68.0, 28.0),
		CORE_CENTER + Vector2(54.0, 28.0),
		CORE_CENTER + Vector2(70.0, 45.0),
		CORE_CENTER + Vector2(36.0, 58.0),
		CORE_CENTER + Vector2(-56.0, 57.0),
		CORE_CENTER + Vector2(-76.0, 42.0),
	])
	draw_colored_polygon(plinth, Color(0.024, 0.054, 0.050, 0.98))
	_draw_polyline_closed([plinth[0], plinth[1], plinth[2], plinth[3], plinth[4], plinth[5]], Color(0.42, 0.82, 0.70, 0.26), 1.8)

	var housing := PackedVector2Array([
		CORE_CENTER + Vector2(-60.0, -29.0),
		CORE_CENTER + Vector2(-35.0, -54.0),
		CORE_CENTER + Vector2(30.0, -52.0),
		CORE_CENTER + Vector2(58.0, -25.0),
		CORE_CENTER + Vector2(54.0, 28.0),
		CORE_CENTER + Vector2(24.0, 49.0),
		CORE_CENTER + Vector2(-38.0, 45.0),
		CORE_CENTER + Vector2(-62.0, 15.0),
	])
	draw_colored_polygon(housing, Color(0.074, 0.132, 0.104, 0.98))
	_draw_polyline_closed([housing[0], housing[1], housing[2], housing[3], housing[4], housing[5], housing[6], housing[7]], Color(0.58, 0.86, 0.68, 0.30), 1.8)

	draw_circle(CORE_CENTER, 38.0, Color(0.16, 0.30, 0.22, 0.58))
	draw_circle(CORE_CENTER, 25.0, Color(0.48, 0.68, 0.34, 0.30))
	draw_arc(CORE_CENTER, 36.0, PI * 0.08, PI * 1.88, 42, Color(0.72, 0.88, 0.52, 0.38), 2.5, true)
	draw_arc(CORE_CENTER, 19.0, 0.0, TAU, 34, Color(0.86, 0.96, 0.66, 0.58), 2.0, true)
	draw_circle(CORE_CENTER, 6.0, Color(0.96, 0.78, 0.36, 0.82))

	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var marker_center := CORE_CENTER + Vector2(cos(angle), sin(angle)) * 39.0
		draw_rect(Rect2(marker_center - Vector2(7.0, 4.0), Vector2(14.0, 8.0)), Color(0.18, 0.30, 0.24, 0.76), true)
		draw_rect(Rect2(marker_center - Vector2(7.0, 4.0), Vector2(14.0, 8.0)), Color(0.70, 0.96, 0.76, 0.22), false, 1.0)

	draw_line(CORE_CENTER + Vector2(-46.0, -36.0), CORE_CENTER + Vector2(-72.0, -62.0), Color(0.33, 0.58, 0.52, 0.36), 3.4)
	draw_line(CORE_CENTER + Vector2(42.0, -34.0), CORE_CENTER + Vector2(66.0, -60.0), Color(0.33, 0.58, 0.52, 0.34), 3.4)
	draw_rect(Rect2(CORE_CENTER + Vector2(-15.0, -76.0), Vector2(30.0, 36.0)), Color(0.42, 0.88, 0.76, 0.18), true)
	draw_rect(Rect2(CORE_CENTER + Vector2(-8.0, -68.0), Vector2(16.0, 21.0)), Color(0.90, 1.0, 0.78, 0.16), true)

	for point in [
		CORE_CENTER + Vector2(-46.0, 37.0),
		CORE_CENTER + Vector2(-20.0, 45.0),
		CORE_CENTER + Vector2(16.0, 45.0),
		CORE_CENTER + Vector2(44.0, 35.0),
	]:
		draw_circle(point, 3.0, Color(0.94, 0.70, 0.34, 0.48))


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


func _draw_player_repair_action() -> void:
	var tool_origin := PLAYER_PAD_CENTER + Vector2(-20.0, -5.0)
	var repair_port := CORE_CENTER + Vector2(62.0, 12.0)
	var cable_path := [
		PLAYER_PAD_CENTER + Vector2(18.0, 10.0),
		PLAYER_PAD_CENTER + Vector2(-2.0, -4.0),
		tool_origin,
		repair_port,
	]
	_draw_cable(cable_path, Color(0.12, 0.22, 0.18, 0.88), 5.0)
	draw_line(tool_origin, repair_port, Color(0.96, 0.76, 0.34, 0.42), 2.0, true)
	draw_line(tool_origin + Vector2(4.0, -4.0), repair_port + Vector2(-6.0, -2.0), Color(0.72, 0.96, 0.78, 0.24), 1.4, true)
	for point in [tool_origin + Vector2(8.0, -5.0), repair_port + Vector2(-8.0, 2.0), repair_port + Vector2(4.0, -8.0)]:
		draw_circle(point, 2.8, Color(0.98, 0.78, 0.34, 0.68))
	for offset in [Vector2(-18.0, 12.0), Vector2(-4.0, 16.0), Vector2(12.0, 14.0)]:
		draw_circle(tool_origin + offset, 2.0, Color(0.70, 0.94, 0.82, 0.30))


func _draw_high_priority_floor_material() -> void:
	var service_trench := PackedVector2Array([
		Vector2(-410.0, -36.0),
		Vector2(-338.0, -62.0),
		Vector2(-248.0, -45.0),
		Vector2(-182.0, -20.0),
		Vector2(-206.0, 8.0),
		Vector2(-308.0, -20.0),
		Vector2(-388.0, 12.0),
	])
	draw_colored_polygon(service_trench, Color(0.012, 0.028, 0.027, 0.82))
	_draw_polyline_closed(
		[
			service_trench[0],
			service_trench[1],
			service_trench[2],
			service_trench[3],
			service_trench[4],
			service_trench[5],
			service_trench[6],
		],
		Color(0.34, 0.66, 0.58, 0.24),
		1.4
	)
	for x_offset in [-88.0, -48.0, -8.0, 32.0, 72.0]:
		draw_line(
			CORE_CENTER + Vector2(x_offset, 52.0),
			CORE_CENTER + Vector2(x_offset + 22.0, 74.0),
			Color(0.34, 0.58, 0.50, 0.18),
			1.6,
			true
		)

	for bolt in [
		CORE_CENTER + Vector2(-72.0, -36.0),
		CORE_CENTER + Vector2(68.0, -34.0),
		CORE_CENTER + Vector2(-84.0, 50.0),
		CORE_CENTER + Vector2(74.0, 48.0),
		PLAYER_PAD_CENTER + Vector2(-52.0, -22.0),
		PLAYER_PAD_CENTER + Vector2(52.0, 22.0),
	]:
		draw_circle(bolt, 2.8, Color(0.52, 0.72, 0.62, 0.28))
		draw_circle(bolt + Vector2(0.8, -0.8), 1.0, Color(0.02, 0.04, 0.04, 0.68))

	for streak in [
		[Vector2(-370.0, -90.0), Vector2(-330.0, -72.0), Vector2(-290.0, -86.0)],
		[Vector2(-284.0, -2.0), Vector2(-246.0, 8.0), Vector2(-198.0, 4.0)],
		[Vector2(-178.0, -72.0), Vector2(-130.0, -60.0), Vector2(-92.0, -62.0)],
	]:
		draw_polyline(PackedVector2Array(streak), Color(0.48, 0.72, 0.62, 0.17), 1.4, true)

	draw_rect(Rect2(CORE_CENTER + Vector2(58.0, 54.0), Vector2(58.0, 12.0)), Color(0.002, 0.010, 0.010, 0.34), true)


func _draw_damaged_core_equipment() -> void:
	var left_panel := PackedVector2Array([
		CORE_CENTER + Vector2(-83.0, -24.0),
		CORE_CENTER + Vector2(-62.0, -51.0),
		CORE_CENTER + Vector2(-30.0, -57.0),
		CORE_CENTER + Vector2(-18.0, -42.0),
		CORE_CENTER + Vector2(-46.0, -30.0),
		CORE_CENTER + Vector2(-56.0, 2.0),
		CORE_CENTER + Vector2(-78.0, 6.0),
	])
	var right_panel := PackedVector2Array([
		CORE_CENTER + Vector2(28.0, -52.0),
		CORE_CENTER + Vector2(58.0, -34.0),
		CORE_CENTER + Vector2(74.0, -6.0),
		CORE_CENTER + Vector2(58.0, 14.0),
		CORE_CENTER + Vector2(34.0, 6.0),
		CORE_CENTER + Vector2(40.0, -26.0),
	])
	draw_colored_polygon(left_panel, Color(0.088, 0.150, 0.118, 0.96))
	draw_colored_polygon(right_panel, Color(0.086, 0.140, 0.116, 0.90))
	_draw_polyline_closed([left_panel[0], left_panel[1], left_panel[2], left_panel[3], left_panel[4], left_panel[5], left_panel[6]], Color(0.62, 0.92, 0.72, 0.30), 1.8)
	_draw_polyline_closed([right_panel[0], right_panel[1], right_panel[2], right_panel[3], right_panel[4], right_panel[5]], Color(0.62, 0.92, 0.72, 0.26), 1.8)

	for crack in [
		[CORE_CENTER + Vector2(-64.0, -38.0), CORE_CENTER + Vector2(-48.0, -24.0), CORE_CENTER + Vector2(-54.0, -6.0)],
		[CORE_CENTER + Vector2(51.0, -28.0), CORE_CENTER + Vector2(42.0, -10.0), CORE_CENTER + Vector2(58.0, 4.0)],
	]:
		draw_polyline(PackedVector2Array(crack), Color(0.02, 0.035, 0.030, 0.72), 2.0, true)

	for vent_y in [-18.0, -8.0, 2.0]:
		draw_line(
			CORE_CENTER + Vector2(-74.0, vent_y),
			CORE_CENTER + Vector2(-48.0, vent_y - 2.0),
			Color(0.70, 0.94, 0.76, 0.18),
			1.6,
			true
		)

	var exposed_port := CORE_CENTER + Vector2(62.0, 12.0)
	draw_circle(exposed_port, 15.0, Color(0.010, 0.022, 0.020, 0.78))
	draw_arc(exposed_port, 16.0, PI * 0.05, PI * 1.70, 26, Color(0.94, 0.70, 0.30, 0.56), 2.2, true)
	draw_rect(Rect2(exposed_port + Vector2(-4.0, -11.0), Vector2(8.0, 22.0)), Color(0.76, 0.88, 0.66, 0.18), true)
	for angle in [PI * 0.22, PI * 0.78, PI * 1.26]:
		draw_circle(exposed_port + Vector2(cos(angle), sin(angle)) * 12.0, 2.2, Color(0.96, 0.76, 0.34, 0.54))


func _draw_player_character_pose() -> void:
	var body_center := PLAYER_PAD_CENTER + Vector2(8.0, -4.0)
	var forward := (CORE_CENTER - body_center).normalized()
	var side := forward.orthogonal()
	_draw_soft_shadow(body_center + Vector2(8.0, 22.0), Vector2(78.0, 26.0), 0.30)
	_draw_oriented_rect(body_center - forward * 10.0, forward, 11.0, 8.0, Color(0.008, 0.022, 0.023, 0.84))
	_draw_oriented_rect(body_center - forward * 10.0, forward, 8.0, 5.8, Color(0.16, 0.64, 0.66, 0.58))
	_draw_oriented_rect(body_center - forward * 22.0, forward, 7.0, 7.0, Color(0.08, 0.20, 0.18, 0.66))
	draw_circle(body_center + forward * 2.0, 8.0, Color(0.86, 0.96, 0.94, 0.62))
	draw_circle(body_center + forward * 2.0, 5.6, Color(0.030, 0.070, 0.074, 0.88))
	draw_line(
		body_center + forward * 7.0 - side * 4.0,
		body_center + forward * 7.0 + side * 4.0,
		Color(0.72, 0.98, 0.98, 0.62),
		1.6,
		true
	)
	var tool_hand := PLAYER_PAD_CENTER + Vector2(-18.0, -8.0)
	_draw_oriented_rect(body_center + forward * 4.0 + side * 8.0, forward, 11.0, 2.3, Color(0.88, 0.72, 0.34, 0.62))
	draw_line(body_center + forward * 9.0 + side * 8.0, tool_hand, Color(0.98, 0.78, 0.36, 0.68), 3.0, true)
	draw_line(body_center - forward * 4.0 - side * 8.0, body_center + forward * 9.0 - side * 9.0, Color(0.70, 0.92, 0.86, 0.42), 2.4, true)
	draw_line(body_center - forward * 18.0 + side * 4.5, body_center - forward * 29.0 + side * 8.0, Color(0.04, 0.12, 0.12, 0.82), 4.0, true)
	draw_line(body_center - forward * 18.0 - side * 4.5, body_center - forward * 28.0 - side * 7.0, Color(0.04, 0.12, 0.12, 0.82), 4.0, true)
	draw_circle(body_center - forward * 8.0 - side * 5.2, 2.2, Color(0.98, 0.86, 0.48, 0.70))
	draw_line(tool_hand, tool_hand + forward * 18.0, Color(0.98, 0.82, 0.38, 0.76), 2.2, true)


func _draw_close_repair_feedback() -> void:
	var repair_port := CORE_CENTER + Vector2(62.0, 12.0)
	var tool_tip := PLAYER_PAD_CENTER + Vector2(-25.0, -9.0)
	draw_line(tool_tip, repair_port, Color(1.0, 0.86, 0.42, 0.40), 2.6, true)
	draw_arc(repair_port, 22.0, PI * 0.12, PI * 0.88, 14, Color(0.98, 0.82, 0.38, 0.38), 1.6, true)
	draw_arc(repair_port, 28.0, PI * 1.04, PI * 1.42, 10, Color(0.70, 0.98, 0.82, 0.22), 1.2, true)
	for spark in [
		Vector2(-8.0, -10.0),
		Vector2(3.0, -14.0),
		Vector2(12.0, -2.0),
		Vector2(-12.0, 7.0),
	]:
		draw_line(repair_port + spark, repair_port + spark * 1.38, Color(1.0, 0.80, 0.32, 0.62), 1.8, true)
	for point in [
		PLAYER_PAD_CENTER + Vector2(-34.0, -18.0),
		PLAYER_PAD_CENTER + Vector2(-44.0, -4.0),
		CORE_CENTER + Vector2(82.0, 30.0),
	]:
		draw_circle(point, 2.0, Color(0.70, 0.98, 0.82, 0.34))


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
		Rect2(Vector2(232.0, -34.0), Vector2(90.0, 18.0)),
		Rect2(Vector2(176.0, 168.0), Vector2(84.0, 14.0)),
	]:
		draw_rect(stain, Color(0.002, 0.010, 0.010, 0.24), true)


func _draw_perimeter_industrial_assets() -> void:
	_draw_low_priority_machine_island(Vector2(330.0, -44.0), Vector2(132.0, 70.0), 0.22)
	_draw_low_priority_machine_island(Vector2(206.0, 132.0), Vector2(150.0, 58.0), 0.20)
	_draw_low_priority_machine_island(Vector2(-68.0, 168.0), Vector2(136.0, 50.0), 0.18)
	_draw_maintenance_crate(Vector2(-154.0, -154.0), Vector2(46.0, 26.0))
	_draw_maintenance_crate(Vector2(-54.0, -196.0), Vector2(38.0, 24.0))
	_draw_maintenance_crate(Vector2(238.0, 60.0), Vector2(44.0, 24.0))
	for point in [Vector2(288.0, 18.0), Vector2(370.0, -78.0), Vector2(138.0, 176.0), Vector2(-18.0, 208.0)]:
		draw_circle(point, 8.0, Color(0.08, 0.18, 0.16, 0.24))
		draw_circle(point, 3.2, Color(0.30, 0.52, 0.42, 0.22))


func _draw_broken_pipe_runs() -> void:
	_draw_pipe([Vector2(-482.0, 54.0), Vector2(-452.0, 8.0), Vector2(-408.0, -22.0)], Color(0.16, 0.32, 0.30, 0.46), 7.0)
	_draw_pipe([Vector2(262.0, -88.0), Vector2(326.0, -108.0), Vector2(420.0, -110.0)], Color(0.12, 0.25, 0.24, 0.34), 6.0)
	_draw_pipe([Vector2(76.0, 192.0), Vector2(126.0, 212.0), Vector2(190.0, 196.0)], Color(0.10, 0.22, 0.20, 0.32), 5.0)
	for crack in [
		[Vector2(282.0, 70.0), Vector2(326.0, 84.0), Vector2(376.0, 70.0)],
		[Vector2(-34.0, 186.0), Vector2(16.0, 202.0), Vector2(72.0, 184.0)],
		[Vector2(188.0, -152.0), Vector2(242.0, -168.0), Vector2(308.0, -160.0)],
	]:
		draw_polyline(PackedVector2Array(crack), Color(0.18, 0.34, 0.30, 0.20), 1.8, true)


func _draw_low_priority_machine_island(center: Vector2, size: Vector2, alpha: float) -> void:
	var half := size * 0.5
	var points := PackedVector2Array([
		center + Vector2(-half.x, -half.y + 14.0),
		center + Vector2(-half.x + 20.0, -half.y),
		center + Vector2(half.x - 18.0, -half.y + 4.0),
		center + Vector2(half.x, -half.y + 24.0),
		center + Vector2(half.x - 12.0, half.y - 6.0),
		center + Vector2(-half.x + 12.0, half.y),
		center + Vector2(-half.x, half.y - 18.0),
	])
	draw_colored_polygon(points, Color(0.028, 0.062, 0.058, alpha))
	_draw_polyline_closed([points[0], points[1], points[2], points[3], points[4], points[5], points[6]], Color(0.22, 0.42, 0.36, alpha * 0.58), 1.4)
	draw_line(center + Vector2(-half.x + 24.0, -half.y + 22.0), center + Vector2(half.x - 26.0, -half.y + 18.0), Color(0.20, 0.38, 0.34, alpha * 0.42), 3.0)
	draw_line(center + Vector2(-half.x + 30.0, half.y - 18.0), center + Vector2(half.x - 28.0, half.y - 12.0), Color(0.20, 0.38, 0.34, alpha * 0.34), 1.2)


func _draw_maintenance_crate(center: Vector2, size: Vector2) -> void:
	var rect := Rect2(center - size * 0.5, size)
	draw_rect(rect, Color(0.034, 0.064, 0.056, 0.46), true)
	draw_rect(rect, Color(0.30, 0.50, 0.42, 0.20), false, 1.0)
	draw_line(rect.position + Vector2(6.0, 7.0), rect.end - Vector2(7.0, 7.0), Color(0.30, 0.50, 0.42, 0.12), 1.0)


func _draw_oriented_rect(center: Vector2, forward: Vector2, half_length: float, half_width: float, color: Color) -> void:
	var safe_forward := forward
	if safe_forward.length_squared() <= 0.001:
		safe_forward = Vector2.LEFT
	else:
		safe_forward = safe_forward.normalized()
	var side := safe_forward.orthogonal()
	var points := PackedVector2Array([
		center + safe_forward * half_length + side * half_width,
		center + safe_forward * half_length - side * half_width,
		center - safe_forward * half_length - side * half_width,
		center - safe_forward * half_length + side * half_width,
	])
	draw_colored_polygon(points, color)


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
