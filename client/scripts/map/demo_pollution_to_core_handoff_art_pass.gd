extends RefCounted
class_name DemoPollutionToCoreHandoffArtPass

const POLLUTION_QUEST_ID := "quest.enter_pollution_edge"
const CORE_ENTRY_QUEST_ID := "quest.enter_demo_stabilization_core"
const CORE_BUFFER_QUEST_ID := "quest.prepare_demo_stabilization_buffer"
const CORE_GUARD_QUEST_ID := "quest.defeat_demo_stabilization_guard"
const CORE_WRITE_QUEST_ID := "quest.write_demo_stabilization_core"
const CORE_REGION_ID := "region.demo_stabilization_core"
const POLLUTED_RESIDUE_ID := "item.polluted_residue"
const RESISTANCE_VIAL_ID := "item.resistance_vial_t1"
const REPAIR_GEL_ID := "item.repair_gel"
const BASIC_PARTS_ID := "item.basic_parts"
const POLLUTED_SLURRY_ID := "fluid.polluted_slurry"
const CORE_BUFFER_ID := "item.core_stabilization_buffer"
const CORE_CHARGE_ID := "item.core_write_charge"
const CORE_BUFFER_RECIPE_ID := "recipe.core_stabilization_buffer"

const READY := Color(0.72, 0.92, 0.54, 0.72)
const SLURRY := Color(0.84, 0.48, 0.18, 0.72)
const BUFFER := Color(0.72, 0.58, 0.94, 0.78)
const CORE := Color(0.38, 0.98, 0.92, 0.82)
const RESTORE := Color(0.68, 0.92, 0.7, 0.68)
const HOOK := Color(0.82, 0.58, 0.96, 0.5)
const IDLE := Color(0.18, 0.22, 0.18, 0.22)
const PANEL := Color(0.012, 0.02, 0.018, 0.56)


static func create_state(world_state: WorldState, character_state: CharacterState) -> Dictionary:
	if world_state == null or character_state == null:
		return {}
	var inventory := character_state.inventory
	var quest_state := world_state.quest_state
	var pollution_objectives_done := (
		quest_state.get_objective_progress(POLLUTION_QUEST_ID, "visit_region", "region.pollution_edge") >= 1.0
		and quest_state.get_objective_progress(POLLUTION_QUEST_ID, "gather_item", POLLUTED_RESIDUE_ID) >= 2.0
		and quest_state.get_objective_progress(POLLUTION_QUEST_ID, "craft_item", RESISTANCE_VIAL_ID) >= 1.0
		and quest_state.get_objective_progress(POLLUTION_QUEST_ID, "defeat_enemy", "enemy.polluted_skitter") >= 1.0
	)
	var pollution_result_ready := (
		pollution_objectives_done
		or quest_state.has_completed_quest(POLLUTION_QUEST_ID)
		or quest_state.has_active_quest(CORE_BUFFER_QUEST_ID)
		or inventory.has_ref(POLLUTED_SLURRY_ID, 1.0)
	)
	var filter_output_ready := (
		inventory.has_ref(RESISTANCE_VIAL_ID, 1)
		or inventory.has_ref(POLLUTED_SLURRY_ID, 1.0)
	)
	var buffer_material_ready := (
		inventory.has_ref(REPAIR_GEL_ID, 1)
		and inventory.has_ref(RESISTANCE_VIAL_ID, 1)
		and inventory.has_ref(POLLUTED_SLURRY_ID, 1.0)
		and inventory.has_ref(BASIC_PARTS_ID, 2)
	)
	var buffer_processing := _is_recipe_active(world_state, CORE_BUFFER_RECIPE_ID)
	var buffer_ready := (
		inventory.has_ref(CORE_BUFFER_ID, 1)
		or quest_state.has_completed_quest(CORE_BUFFER_QUEST_ID)
	)
	var core_entry_ready := (
		world_state.unlocked_region_ids.has(CORE_REGION_ID)
		or quest_state.has_active_quest(CORE_ENTRY_QUEST_ID)
		or quest_state.has_completed_quest(CORE_ENTRY_QUEST_ID)
		or buffer_material_ready
		or buffer_processing
		or buffer_ready
	)
	var core_entered := (
		world_state.current_region_id == CORE_REGION_ID
		or character_state.current_region_id == CORE_REGION_ID
		or quest_state.has_completed_quest(CORE_ENTRY_QUEST_ID)
	)
	var guard_cleared := (
		quest_state.has_completed_quest(CORE_GUARD_QUEST_ID)
		or bool(world_state.get_enemy("enemy_instance.demo_stabilization_guard").get("is_defeated", false))
	)
	var write_charge_ready := (
		inventory.has_ref(CORE_CHARGE_ID, 1)
		or quest_state.get_objective_progress(CORE_WRITE_QUEST_ID, "gather_item", CORE_CHARGE_ID) >= 1.0
	)
	var write_ready := (
		quest_state.has_active_quest(CORE_WRITE_QUEST_ID)
		and guard_cleared
		and write_charge_ready
	)
	var core_written := quest_state.has_completed_quest(CORE_WRITE_QUEST_ID)
	if not (
		pollution_result_ready
		or filter_output_ready
		or buffer_material_ready
		or buffer_processing
		or buffer_ready
		or core_entry_ready
		or core_entered
		or write_ready
		or core_written
	):
		return {}
	return {
		"pollution_result_ready": pollution_result_ready,
		"filter_output_ready": filter_output_ready,
		"buffer_material_ready": buffer_material_ready,
		"buffer_processing": buffer_processing,
		"buffer_ready": buffer_ready,
		"core_entry_ready": core_entry_ready,
		"core_entered": core_entered,
		"guard_cleared": guard_cleared,
		"write_charge_ready": write_charge_ready,
		"write_ready": write_ready,
		"core_written": core_written,
		"demo_hook_ready": core_written
	}


static func get_pollution_shape_ids(state: Dictionary) -> Array[String]:
	if state.is_empty():
		return []
	return [
		"pollution_to_core_handoff.challenge_result.%s" % _ready_suffix(bool(state.get("pollution_result_ready", false))),
		"pollution_to_core_handoff.filter_output.%s" % _ready_suffix(bool(state.get("filter_output_ready", false))),
		"pollution_to_core_handoff.buffer_materials.%s" % _ready_suffix(bool(state.get("buffer_material_ready", false))),
		"pollution_to_core_handoff.buffer_manifest.%s" % _buffer_suffix(state),
		"pollution_to_core_handoff.core_entry_route.%s" % _ready_suffix(bool(state.get("core_entry_ready", false))),
		"pollution_to_core_handoff.core_station_port.%s" % _ready_suffix(bool(state.get("core_entered", false)) or bool(state.get("core_entry_ready", false)))
	]


static func get_core_shape_ids(state: Dictionary) -> Array[String]:
	if state.is_empty():
		return []
	return [
		"core_handoff.pollution_result_manifest.%s" % _ready_suffix(bool(state.get("pollution_result_ready", false))),
		"core_handoff.entry_port.%s" % _ready_suffix(bool(state.get("core_entered", false)) or bool(state.get("core_entry_ready", false))),
		"core_handoff.buffer_socket.%s" % _ready_suffix(bool(state.get("buffer_ready", false)) or bool(state.get("buffer_material_ready", false))),
		"core_handoff.write_energy.%s" % _write_suffix(state),
		"core_handoff.recovery_wave.%s" % _ready_suffix(bool(state.get("core_written", false))),
		"core_handoff.demo_hook.%s" % _ready_suffix(bool(state.get("demo_hook_ready", false)))
	]


static func draw_pollution_handoff(canvas: CanvasItem, state: Dictionary) -> void:
	if canvas == null or state.is_empty():
		return
	var result_ready := bool(state.get("pollution_result_ready", false))
	var filter_ready := bool(state.get("filter_output_ready", false))
	var materials_ready := bool(state.get("buffer_material_ready", false))
	var buffer_ready := bool(state.get("buffer_ready", false))
	var buffer_processing := bool(state.get("buffer_processing", false))
	var entry_ready := bool(state.get("core_entry_ready", false))
	_draw_pollution_result_tray(canvas, result_ready, filter_ready)
	_draw_buffer_manifest(canvas, materials_ready, buffer_processing, buffer_ready)
	_draw_pollution_core_route(canvas, entry_ready or buffer_ready or buffer_processing)


static func draw_core_handoff(canvas: CanvasItem, state: Dictionary) -> void:
	if canvas == null or state.is_empty():
		return
	var entry_ready := bool(state.get("core_entered", false)) or bool(state.get("core_entry_ready", false))
	var buffer_ready := bool(state.get("buffer_ready", false)) or bool(state.get("buffer_material_ready", false))
	var write_ready := bool(state.get("write_ready", false))
	var core_written := bool(state.get("core_written", false))
	_draw_core_entry_manifest(canvas, entry_ready)
	_draw_core_buffer_socket(canvas, buffer_ready)
	_draw_core_write_energy(canvas, write_ready, core_written)
	_draw_core_recovery_and_hook(canvas, core_written)


static func _draw_pollution_result_tray(canvas: CanvasItem, result_ready: bool, filter_ready: bool) -> void:
	var color := READY if result_ready else IDLE
	var tray := Rect2(Vector2(248.0, -142.0), Vector2(118.0, 34.0))
	canvas.draw_rect(tray, PANEL, true)
	canvas.draw_rect(tray, Color(color.r, color.g, color.b, 0.2 if result_ready else 0.08), true)
	canvas.draw_rect(tray, Color(color.r, color.g, color.b, 0.56 if result_ready else 0.22), false, 1.1, true)
	for index in range(3):
		var center := Vector2(270.0 + float(index) * 28.0, -124.0 + float(index % 2) * 5.0)
		canvas.draw_rect(Rect2(center + Vector2(-7.0, -5.0), Vector2(14.0, 10.0)), Color(READY.r, READY.g, READY.b, 0.48 if result_ready else 0.13), true)
		canvas.draw_rect(Rect2(center + Vector2(-7.0, -5.0), Vector2(14.0, 10.0)), Color(READY.r, READY.g, READY.b, 0.5 if result_ready else 0.18), false, 0.8, true)
	var filter_color := SLURRY if filter_ready else IDLE
	_draw_route(canvas, [
		Vector2(282.0, -108.0),
		Vector2(282.0, -78.0),
		Vector2(314.0, -56.0)
	], filter_color, 2.0)


static func _draw_buffer_manifest(canvas: CanvasItem, materials_ready: bool, buffer_processing: bool, buffer_ready: bool) -> void:
	var is_ready := materials_ready or buffer_processing or buffer_ready
	var color := BUFFER if is_ready else IDLE
	var manifest := Rect2(Vector2(302.0, -70.0), Vector2(68.0, 62.0))
	canvas.draw_rect(manifest, Color(0.028, 0.018, 0.038, 0.52), true)
	canvas.draw_rect(manifest, Color(color.r, color.g, color.b, 0.16 if is_ready else 0.06), true)
	canvas.draw_rect(manifest, Color(color.r, color.g, color.b, 0.54 if is_ready else 0.2), false, 1.1, true)
	for index in range(4):
		var y := -58.0 + float(index) * 13.0
		var line_color := color if index < _buffer_material_light_count(materials_ready, buffer_processing, buffer_ready) else IDLE
		canvas.draw_line(Vector2(312.0, y), Vector2(358.0, y + 4.0), Color(line_color.r, line_color.g, line_color.b, 0.62), 1.2, true)
	if buffer_ready:
		canvas.draw_circle(Vector2(336.0, -38.0), 9.0, Color(BUFFER.r, BUFFER.g, BUFFER.b, 0.54))
	elif buffer_processing:
		canvas.draw_arc(Vector2(336.0, -38.0), 13.0, PI * 0.12, PI * 1.78, 32, Color(BUFFER.r, BUFFER.g, BUFFER.b, 0.52), 1.7, true)


static func _draw_pollution_core_route(canvas: CanvasItem, entry_ready: bool) -> void:
	var color := CORE if entry_ready else IDLE
	_draw_route(canvas, [
		Vector2(368.0, -38.0),
		Vector2(392.0, -28.0),
		Vector2(414.0, -10.0),
		Vector2(438.0, -10.0)
	], color, 2.4 if entry_ready else 1.4)
	for point in [Vector2(392.0, -28.0), Vector2(438.0, -10.0)]:
		canvas.draw_circle(point, 4.0, Color(color.r, color.g, color.b, 0.54 if entry_ready else 0.18))


static func _draw_core_entry_manifest(canvas: CanvasItem, entry_ready: bool) -> void:
	var color := CORE if entry_ready else IDLE
	var manifest := Rect2(Vector2(3658.0, -82.0), Vector2(96.0, 94.0))
	canvas.draw_rect(manifest, PANEL, true)
	canvas.draw_rect(manifest, Color(color.r, color.g, color.b, 0.14 if entry_ready else 0.05), true)
	canvas.draw_rect(manifest, Color(color.r, color.g, color.b, 0.5 if entry_ready else 0.18), false, 1.2, true)
	for y in [-62.0, -38.0, -14.0]:
		canvas.draw_line(Vector2(3672.0, y), Vector2(3740.0, y + 7.0), Color(color.r, color.g, color.b, 0.46 if entry_ready else 0.14), 1.2, true)
	_draw_route(canvas, [Vector2(3754.0, -36.0), Vector2(3828.0, -16.0), Vector2(3894.0, 34.0)], color, 2.4 if entry_ready else 1.4)


static func _draw_core_buffer_socket(canvas: CanvasItem, buffer_ready: bool) -> void:
	var color := BUFFER if buffer_ready else IDLE
	var socket := Rect2(Vector2(3878.0, 46.0), Vector2(72.0, 54.0))
	canvas.draw_rect(socket, Color(0.03, 0.02, 0.04, 0.52), true)
	canvas.draw_rect(socket, Color(color.r, color.g, color.b, 0.18 if buffer_ready else 0.06), true)
	canvas.draw_rect(socket, Color(color.r, color.g, color.b, 0.58 if buffer_ready else 0.2), false, 1.2, true)
	for point in [Vector2(3894.0, 64.0), Vector2(3920.0, 74.0), Vector2(3938.0, 58.0)]:
		canvas.draw_circle(point, 4.2, Color(color.r, color.g, color.b, 0.58 if buffer_ready else 0.16))
	if buffer_ready:
		_draw_route(canvas, [Vector2(3948.0, 66.0), Vector2(3992.0, 24.0), Vector2(4038.0, -24.0)], BUFFER, 2.6)


static func _draw_core_write_energy(canvas: CanvasItem, write_ready: bool, core_written: bool) -> void:
	if not write_ready and not core_written:
		return
	var color := CORE if write_ready else RESTORE
	var center := Vector2(4038.0, -24.0)
	for radius in [34.0, 58.0, 82.0]:
		canvas.draw_arc(center, radius, PI * 0.04, PI * 1.92, 56, Color(color.r, color.g, color.b, 0.42 if write_ready else 0.28), 1.4, true)
	_draw_route(canvas, [Vector2(3926.0, 70.0), Vector2(3988.0, 24.0), center], color, 3.0 if write_ready else 1.8)
	if core_written:
		canvas.draw_circle(center, 12.0, Color(RESTORE.r, RESTORE.g, RESTORE.b, 0.62))


static func _draw_core_recovery_and_hook(canvas: CanvasItem, core_written: bool) -> void:
	if not core_written:
		return
	_draw_route(canvas, [
		Vector2(4038.0, -24.0),
		Vector2(4108.0, 24.0),
		Vector2(4164.0, 78.0)
	], RESTORE, 2.6)
	_draw_route(canvas, [
		Vector2(4164.0, 78.0),
		Vector2(4220.0, -26.0),
		Vector2(4252.0, -126.0)
	], HOOK, 2.0)
	for point in [Vector2(4108.0, 24.0), Vector2(4164.0, 78.0), Vector2(4252.0, -126.0)]:
		canvas.draw_arc(point, 13.0, 0.0, TAU, 24, Color(HOOK.r, HOOK.g, HOOK.b, 0.38), 1.1, true)


static func _draw_route(canvas: CanvasItem, points: Array[Vector2], color: Color, width: float) -> void:
	var packed := PackedVector2Array(points)
	canvas.draw_polyline(packed, Color(0.016, 0.02, 0.018, 0.46), width + 2.6, true)
	canvas.draw_polyline(packed, color, width, true)


static func _buffer_material_light_count(materials_ready: bool, buffer_processing: bool, buffer_ready: bool) -> int:
	if buffer_ready:
		return 4
	if buffer_processing:
		return 3
	if materials_ready:
		return 2
	return 0


static func _buffer_suffix(state: Dictionary) -> String:
	if bool(state.get("buffer_ready", false)):
		return "ready"
	if bool(state.get("buffer_processing", false)):
		return "processing"
	if bool(state.get("buffer_material_ready", false)):
		return "loaded"
	return "idle"


static func _write_suffix(state: Dictionary) -> String:
	if bool(state.get("core_written", false)):
		return "completed"
	if bool(state.get("write_ready", false)):
		return "active"
	return "idle"


static func _ready_suffix(is_ready: bool) -> String:
	return "ready" if is_ready else "idle"


static func _is_recipe_active(world_state: WorldState, recipe_id: String) -> bool:
	for structure in world_state.base_structures.values():
		if not structure is Dictionary:
			continue
		if String(structure.get("status", "")) != "in_progress":
			continue
		if String(structure.get("active_recipe_id", "")) == recipe_id:
			return true
	return false
