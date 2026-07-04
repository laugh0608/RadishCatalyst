extends RefCounted
class_name DemoPollutionShortChallengeReadinessArtPass

const POLLUTION_REGION_ID := "region.pollution_edge"
const ENTER_POLLUTION_QUEST_ID := "quest.enter_pollution_edge"
const FILTER_MODULE_ID := "equipment.filter_module_t1"
const RESISTANCE_VIAL_ID := "item.resistance_vial_t1"
const REPAIR_GEL_ID := "item.repair_gel"
const POLLUTED_RESIDUE_ID := "item.polluted_residue"
const POLLUTED_SKITTER_ID := "enemy.polluted_skitter"

const MODULE_COLOR := Color(0.48, 0.84, 0.92, 0.9)
const VIAL_COLOR := Color(0.72, 0.94, 0.42, 0.9)
const GEL_COLOR := Color(0.86, 0.92, 0.78, 0.9)
const PRESSURE_COLOR := Color(0.94, 0.48, 0.18, 0.9)
const RESIDUE_COLOR := Color(0.88, 0.72, 0.24, 0.9)
const READY_ROUTE := Color(0.74, 0.9, 0.52, 0.64)
const IDLE_ROUTE := Color(0.32, 0.38, 0.24, 0.22)


static func create_state(world_state: WorldState, character_state: CharacterState) -> Dictionary:
	if world_state == null or character_state == null:
		return {}
	var inventory := character_state.inventory
	var quest_active := world_state.quest_state.has_active_quest(ENTER_POLLUTION_QUEST_ID)
	var in_pollution_edge := world_state.current_region_id == POLLUTION_REGION_ID
	var residue_count := world_state.quest_state.get_objective_progress(
		ENTER_POLLUTION_QUEST_ID,
		"gather_item",
		POLLUTED_RESIDUE_ID
	)
	var enemy_count := world_state.quest_state.get_objective_progress(
		ENTER_POLLUTION_QUEST_ID,
		"defeat_enemy",
		POLLUTED_SKITTER_ID
	)
	var has_module := (
		FieldOutfittingRuntime.has_filter_module_equipped(character_state)
		or inventory.has_ref(FILTER_MODULE_ID, 1)
	)
	var has_vial := inventory.has_ref(RESISTANCE_VIAL_ID, 1)
	var has_gel := inventory.has_ref(REPAIR_GEL_ID, 1)
	var residue_ready := inventory.has_ref(POLLUTED_RESIDUE_ID, 1) or residue_count > 0.0
	if not (
		quest_active
		or in_pollution_edge
		or has_module
		or has_vial
		or residue_ready
	):
		return {}
	return {
		"quest_active": quest_active,
		"in_pollution_edge": in_pollution_edge,
		"has_module": has_module,
		"has_vial": has_vial,
		"has_gel": has_gel,
		"ready_loadout": has_module and has_vial,
		"challenge_active": in_pollution_edge or quest_active,
		"enemy_pressure_done": enemy_count >= 1.0,
		"residue_ready": residue_ready,
		"filter_return_ready": residue_ready or inventory.has_ref(POLLUTED_RESIDUE_ID, 2)
	}


static func get_shape_ids(state: Dictionary) -> Array[String]:
	if state.is_empty():
		return []
	return [
		"pollution_short_challenge.staging_pad.%s" % _ready_suffix(bool(state.get("ready_loadout", false))),
		"pollution_short_challenge.supply.filter_module.%s" % _ready_suffix(bool(state.get("has_module", false))),
		"pollution_short_challenge.supply.resistance_vial.%s" % _ready_suffix(bool(state.get("has_vial", false))),
		"pollution_short_challenge.supply.repair_gel.%s" % _ready_suffix(bool(state.get("has_gel", false))),
		"pollution_short_challenge.pressure_gate_route.%s" % _ready_suffix(bool(state.get("ready_loadout", false))),
		"pollution_short_challenge.combat_pocket.%s" % _active_suffix(bool(state.get("challenge_active", false))),
		"pollution_short_challenge.residue_return.%s" % _ready_suffix(bool(state.get("residue_ready", false))),
		"pollution_short_challenge.filter_handoff.%s" % _ready_suffix(bool(state.get("filter_return_ready", false)))
	]


static func draw(canvas: CanvasItem, state: Dictionary) -> void:
	if canvas == null or state.is_empty():
		return
	var ready_loadout := bool(state.get("ready_loadout", false))
	var has_module := bool(state.get("has_module", false))
	var has_vial := bool(state.get("has_vial", false))
	var has_gel := bool(state.get("has_gel", false))
	var residue_ready := bool(state.get("residue_ready", false))
	var pressure_done := bool(state.get("enemy_pressure_done", false))
	_draw_staging_pad(canvas, ready_loadout)
	_draw_supply_badge(canvas, Vector2(218.0, -28.0), MODULE_COLOR, has_module, "module")
	_draw_supply_badge(canvas, Vector2(218.0, -2.0), VIAL_COLOR, has_vial, "vial")
	_draw_supply_badge(canvas, Vector2(218.0, 24.0), GEL_COLOR, has_gel, "gel")
	_draw_pressure_route(canvas, ready_loadout)
	_draw_combat_pocket(canvas, ready_loadout, pressure_done)
	_draw_residue_return(canvas, residue_ready)


static func _draw_staging_pad(canvas: CanvasItem, is_ready: bool) -> void:
	var pad := Rect2(Vector2(196.0, -48.0), Vector2(46.0, 92.0))
	var accent := READY_ROUTE if is_ready else PRESSURE_COLOR
	canvas.draw_rect(pad, Color(0.012, 0.018, 0.012, 0.58), true)
	canvas.draw_rect(pad, Color(accent.r, accent.g, accent.b, 0.12 if is_ready else 0.07), true)
	canvas.draw_rect(pad, Color(accent.r, accent.g, accent.b, 0.34 if is_ready else 0.2), false, 1.2, true)
	for y in [-36.0, -10.0, 16.0, 38.0]:
		canvas.draw_line(Vector2(202.0, y), Vector2(234.0, y + 5.0), Color(accent.r, accent.g, accent.b, 0.16), 0.9, true)


static func _draw_supply_badge(canvas: CanvasItem, center: Vector2, color: Color, is_ready: bool, kind: String) -> void:
	var alpha := 0.64 if is_ready else 0.13
	var rect := Rect2(center + Vector2(-10.0, -8.0), Vector2(20.0, 16.0))
	canvas.draw_rect(rect, Color(0.018, 0.024, 0.016, 0.68), true)
	canvas.draw_rect(rect.grow(-2.0), Color(color.r, color.g, color.b, alpha), true)
	canvas.draw_rect(rect, Color(color.r, color.g, color.b, 0.52 if is_ready else 0.18), false, 1.0, true)
	match kind:
		"module":
			canvas.draw_line(center + Vector2(-5.0, -4.0), center + Vector2(0.0, 5.0), Color(color.r, color.g, color.b, 0.74 if is_ready else 0.2), 1.2, true)
			canvas.draw_line(center + Vector2(5.0, -4.0), center + Vector2(0.0, 5.0), Color(color.r, color.g, color.b, 0.74 if is_ready else 0.2), 1.2, true)
		"vial":
			canvas.draw_line(center + Vector2(-3.0, -5.0), center + Vector2(3.0, 5.0), Color(color.r, color.g, color.b, 0.74 if is_ready else 0.2), 1.5, true)
			canvas.draw_line(center + Vector2(3.0, -5.0), center + Vector2(-3.0, 5.0), Color(color.r, color.g, color.b, 0.42 if is_ready else 0.12), 1.0, true)
		"gel":
			canvas.draw_line(center + Vector2(-5.0, 0.0), center + Vector2(5.0, 0.0), Color(color.r, color.g, color.b, 0.74 if is_ready else 0.2), 1.4, true)
			canvas.draw_line(center + Vector2(0.0, -5.0), center + Vector2(0.0, 5.0), Color(color.r, color.g, color.b, 0.74 if is_ready else 0.2), 1.4, true)


static func _draw_pressure_route(canvas: CanvasItem, is_ready: bool) -> void:
	var route := PackedVector2Array([
		Vector2(238.0, 10.0),
		Vector2(282.0, 18.0),
		Vector2(326.0, 44.0),
		Vector2(374.0, 24.0)
	])
	var color := READY_ROUTE if is_ready else IDLE_ROUTE
	canvas.draw_polyline(route, Color(0.025, 0.03, 0.018, 0.48), 5.0, true)
	canvas.draw_polyline(route, color, 2.2, true)
	for point in route:
		canvas.draw_circle(point, 3.4, Color(color.r, color.g, color.b, 0.54))


static func _draw_combat_pocket(canvas: CanvasItem, is_ready: bool, pressure_done: bool) -> void:
	var pocket := Rect2(Vector2(344.0, -6.0), Vector2(36.0, 62.0))
	var color := READY_ROUTE if is_ready else PRESSURE_COLOR
	canvas.draw_rect(pocket, Color(0.03, 0.02, 0.014, 0.46), true)
	canvas.draw_rect(pocket, Color(color.r, color.g, color.b, 0.12 if is_ready else 0.08), true)
	canvas.draw_rect(pocket, Color(color.r, color.g, color.b, 0.3 if is_ready else 0.2), false, 1.1, true)
	for offset in [Vector2(10.0, 14.0), Vector2(24.0, 22.0), Vector2(18.0, 42.0)]:
		var center: Vector2 = pocket.position + offset
		canvas.draw_circle(center, 3.6, Color(color.r, color.g, color.b, 0.54 if is_ready else 0.28))
		if pressure_done:
			canvas.draw_line(center + Vector2(-5.0, 0.0), center + Vector2(5.0, 0.0), Color(READY_ROUTE.r, READY_ROUTE.g, READY_ROUTE.b, 0.54), 1.1, true)


static func _draw_residue_return(canvas: CanvasItem, is_ready: bool) -> void:
	var color := RESIDUE_COLOR if is_ready else IDLE_ROUTE
	var route := PackedVector2Array([
		Vector2(354.0, 118.0),
		Vector2(322.0, 96.0),
		Vector2(286.0, 36.0),
		Vector2(282.0, -102.0)
	])
	canvas.draw_polyline(route, Color(0.035, 0.028, 0.014, 0.42), 4.8, true)
	canvas.draw_polyline(route, Color(color.r, color.g, color.b, 0.62 if is_ready else 0.18), 1.8, true)
	for point in [Vector2(354.0, 118.0), Vector2(322.0, 96.0), Vector2(282.0, -102.0)]:
		canvas.draw_rect(Rect2(point + Vector2(-5.0, -4.0), Vector2(10.0, 8.0)), Color(color.r, color.g, color.b, 0.42 if is_ready else 0.12), true)
		canvas.draw_rect(Rect2(point + Vector2(-5.0, -4.0), Vector2(10.0, 8.0)), Color(color.r, color.g, color.b, 0.52 if is_ready else 0.16), false, 0.9, true)


static func _ready_suffix(is_ready: bool) -> String:
	return "ready" if is_ready else "idle"


static func _active_suffix(is_active: bool) -> String:
	return "active" if is_active else "idle"
