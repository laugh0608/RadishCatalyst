extends RefCounted
class_name DemoBaseCompletionOutcomeArtPass

const CHAIN_ROUTE_DARK := Color(0.02, 0.04, 0.035, 0.72)
const COMPLETION_STABILITY := Color(0.62, 0.98, 0.82, 0.82)
const COMPLETION_ARCHIVE := Color(0.58, 0.86, 0.96, 0.72)
const COMPLETION_ANOMALY := Color(0.84, 0.58, 0.96, 0.58)
const OUTFITTING_LIGHT := Color(0.94, 0.76, 0.28, 0.9)


static func create_state(world_state: WorldState, character_state: CharacterState) -> Dictionary:
	if world_state == null or character_state == null:
		return {}
	if not world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core"):
		return {}
	var retest_gathered := CoreStabilizationPressureFormatter.has_retest_readout(world_state)
	var retest_available := CoreStabilizationPressureFormatter.is_retest_readout_available(world_state)
	return {
		"stability_window_ready": true,
		"archive_ready": true,
		"retest_gathered": retest_gathered,
		"retest_available": retest_available,
		"supply_refit_needed": not character_state.are_vitals_full(),
		"anomaly_hook_ready": true
	}


static func get_shape_ids(state: Dictionary) -> Array[String]:
	var shape_ids: Array[String] = []
	if state.is_empty():
		return shape_ids
	var retest_gathered := bool(state.get("retest_gathered", false))
	var retest_available := bool(state.get("retest_available", false))
	var supply_refit_needed := bool(state.get("supply_refit_needed", false))
	shape_ids.append("completion_outcome.outpost.stability_window.ready")
	shape_ids.append("completion_outcome.outpost.core_write_archive.ready")
	shape_ids.append("completion_outcome.outpost.retest_readout.%s" % _completion_retest_suffix(retest_gathered, retest_available))
	shape_ids.append("completion_outcome.outpost.supply_refit.%s" % ("needed" if supply_refit_needed else "full"))
	shape_ids.append("completion_outcome.outpost.anomaly_probe.ready")
	shape_ids.append("completion_outcome.flow.core_archive_to_outpost.ready")
	return shape_ids


static func draw_completion_outcome(canvas: CanvasItem, state: Dictionary) -> void:
	if state.is_empty():
		return
	var core_center := Vector2(-300.0, -92.0)
	var archive_panel := Rect2(Vector2(-328.0, -204.0), Vector2(122.0, 36.0))
	var stability_panel := Rect2(Vector2(-204.0, -182.0), Vector2(98.0, 42.0))
	var retest_panel := Rect2(Vector2(-132.0, 94.0), Vector2(88.0, 34.0))
	var anomaly_probe := Rect2(Vector2(-92.0, -182.0), Vector2(38.0, 72.0))
	_draw_completion_stability_window(canvas, core_center)
	_draw_chain_flow_band(
		canvas,
		[core_center + Vector2(24.0, -16.0), Vector2(-250.0, -186.0), archive_panel.position + Vector2(100.0, 18.0)],
		COMPLETION_ARCHIVE,
		2.4
	)
	_draw_chain_flow_band(
		canvas,
		[core_center + Vector2(28.0, 18.0), Vector2(-226.0, -148.0), stability_panel.position + Vector2(10.0, 28.0)],
		COMPLETION_STABILITY,
		2.8
	)
	_draw_chain_flow_band(
		canvas,
		[core_center + Vector2(22.0, 28.0), Vector2(-216.0, 38.0), Vector2(-92.0, 102.0)],
		COMPLETION_ARCHIVE,
		2.0
	)
	_draw_completion_panel(canvas, archive_panel, COMPLETION_ARCHIVE)
	_draw_completion_panel(canvas, stability_panel, COMPLETION_STABILITY)
	_draw_completion_panel(canvas, retest_panel, COMPLETION_ARCHIVE)
	_draw_completion_anomaly_probe(canvas, anomaly_probe)
	_draw_completion_supply_refit_status(canvas, bool(state.get("supply_refit_needed", false)))


static func _draw_completion_stability_window(canvas: CanvasItem, center: Vector2) -> void:
	for radius in [42.0, 58.0, 76.0]:
		canvas.draw_arc(center, radius, PI * 0.06, PI * 1.92, 54, Color(COMPLETION_STABILITY.r, COMPLETION_STABILITY.g, COMPLETION_STABILITY.b, 0.18), 1.3, true)
	canvas.draw_circle(center, 10.0, Color(COMPLETION_STABILITY.r, COMPLETION_STABILITY.g, COMPLETION_STABILITY.b, 0.42))
	for angle in [PI * 0.18, PI * 0.64, PI * 1.12, PI * 1.58]:
		var from := center + Vector2(cos(angle), sin(angle)) * 48.0
		var to := center + Vector2(cos(angle), sin(angle)) * 76.0
		canvas.draw_line(from, to, Color(COMPLETION_STABILITY.r, COMPLETION_STABILITY.g, COMPLETION_STABILITY.b, 0.28), 1.2, true)


static func _draw_completion_panel(canvas: CanvasItem, rect: Rect2, color: Color) -> void:
	canvas.draw_rect(rect, Color(0.006, 0.018, 0.018, 0.62), true)
	canvas.draw_rect(rect, Color(color.r, color.g, color.b, 0.54), false, 1.3, true)
	for index in range(4):
		var x := rect.position.x + 12.0 + float(index) * 22.0
		var y := rect.position.y + 12.0 + float(index % 2) * 10.0
		canvas.draw_rect(Rect2(Vector2(x, y), Vector2(14.0, 5.0)), Color(color.r, color.g, color.b, 0.34), true)
	canvas.draw_line(rect.position + Vector2(8.0, rect.size.y - 8.0), rect.position + Vector2(rect.size.x - 8.0, rect.size.y - 8.0), Color(color.r, color.g, color.b, 0.28), 1.0, true)


static func _draw_completion_anomaly_probe(canvas: CanvasItem, rect: Rect2) -> void:
	canvas.draw_rect(rect, Color(0.08, 0.04, 0.12, 0.22), true)
	canvas.draw_rect(rect, COMPLETION_ANOMALY, false, 1.2, true)
	canvas.draw_line(rect.position + Vector2(rect.size.x * 0.5, 0.0), rect.position + Vector2(rect.size.x * 0.5, rect.size.y), Color(COMPLETION_ANOMALY.r, COMPLETION_ANOMALY.g, COMPLETION_ANOMALY.b, 0.3), 1.0, true)
	_draw_chain_flow_band(
		canvas,
		[Vector2(-204.0, -154.0), Vector2(-152.0, -142.0), rect.position + Vector2(18.0, 36.0)],
		COMPLETION_ANOMALY,
		1.8
	)
	for y in [rect.position.y + 16.0, rect.position.y + 34.0, rect.position.y + 52.0]:
		canvas.draw_line(Vector2(rect.position.x + 8.0, y), Vector2(rect.end.x - 8.0, y + 4.0), Color(COMPLETION_ANOMALY.r, COMPLETION_ANOMALY.g, COMPLETION_ANOMALY.b, 0.32), 1.0, true)
	canvas.draw_circle(rect.position + rect.size * 0.5, 4.2, Color(COMPLETION_ANOMALY.r, COMPLETION_ANOMALY.g, COMPLETION_ANOMALY.b, 0.48))


static func _draw_completion_supply_refit_status(canvas: CanvasItem, refit_needed: bool) -> void:
	var color := OUTFITTING_LIGHT if refit_needed else COMPLETION_STABILITY
	for point in [Vector2(-94.0, -68.0), Vector2(-66.0, -68.0), Vector2(-44.0, -40.0)]:
		canvas.draw_arc(point, 10.0, 0.0, TAU, 22, Color(color.r, color.g, color.b, 0.4), 1.2, true)
	canvas.draw_line(Vector2(-94.0, -68.0), Vector2(-44.0, -40.0), Color(color.r, color.g, color.b, 0.34), 2.0, true)


static func _draw_chain_flow_band(canvas: CanvasItem, points: Array[Vector2], color: Color, width: float) -> void:
	canvas.draw_polyline(PackedVector2Array(points), CHAIN_ROUTE_DARK, width + 3.0, true)
	canvas.draw_polyline(PackedVector2Array(points), Color(color.r, color.g, color.b, 0.68), width, true)
	for point in points:
		canvas.draw_circle(point, width * 0.55, Color(color.r, color.g, color.b, 0.74))


static func _completion_retest_suffix(retest_gathered: bool, retest_available: bool) -> String:
	if retest_gathered:
		return "gathered"
	return "available" if retest_available else "pending"
