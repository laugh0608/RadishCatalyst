extends Node2D
class_name DemoFirstIndustrialPathVisualLayer

const FOCUS_MIN_X := -360.0
const FOCUS_MAX_X := 260.0

const WORKSPACE_WASH := Color(0.016, 0.026, 0.026, 0.18)
const PATH_DARK := Color(0.018, 0.036, 0.032, 0.72)
const PATH_FILL := Color(0.18, 0.32, 0.26, 0.28)
const PATH_EDGE := Color(0.58, 0.78, 0.52, 0.5)
const PATH_MARK := Color(0.88, 0.76, 0.32, 0.5)
const CRYSTAL_ACCENT := Color(0.34, 0.78, 0.86, 0.82)
const SALVAGE_ACCENT := Color(0.84, 0.7, 0.34, 0.78)
const REACTOR_ACCENT := Color(1.0, 0.58, 0.22, 0.86)
const PRODUCT_ACCENT := Color(0.58, 0.88, 0.52, 0.82)
const OUTFITTING_ACCENT := Color(0.92, 0.74, 0.3, 0.86)
const SLOT_DARK := Color(0.02, 0.04, 0.035, 0.64)
const READY_DIM := Color(0.22, 0.3, 0.28, 0.34)

const STAGE_FIELD_PICKUP := "field_pickup"
const STAGE_RETURN_TO_BASE := "return_to_base"
const STAGE_BASE_RECEIVING := "base_receiving"
const STAGE_REACTOR_PROCESSING := "reactor_processing"
const STAGE_STORAGE_OUTPUT := "storage_output"
const STAGE_OUTFITTING_READY := "outfitting_ready"

const PATH_POINTS := [
	Vector2(132.0, -124.0),
	Vector2(48.0, -100.0),
	Vector2(-42.0, -106.0),
	Vector2(-214.0, -112.0),
	Vector2(-166.0, -66.0),
	Vector2(-250.0, 18.0),
	Vector2(-128.0, 54.0),
	Vector2(-74.0, -14.0),
	Vector2(-42.0, -42.0)
]

var path_shape_ids: Array[String] = []
var path_state_shape_ids: Array[String] = []
var muted_planning_layer_count := 0
var path_state: Dictionary = {}


func _ready() -> void:
	apply_visuals()
	refresh_focus_visibility(_get_player_position())


func _process(_delta: float) -> void:
	refresh_focus_visibility(_get_player_position())


func apply_visuals() -> void:
	_register_path_shapes()
	_quiet_global_planning_layers()
	queue_redraw()


func refresh_path_state(world_state: WorldState, character_state: CharacterState) -> void:
	path_state_shape_ids.clear()
	if world_state == null or character_state == null:
		path_state.clear()
		queue_redraw()
		return
	var inventory := character_state.inventory
	var reactor_state := _get_base_structure_for_definition(world_state, "building.basic_reactor")
	var reactor_active := (
		String(reactor_state.get("status", "")) == "in_progress"
		and String(reactor_state.get("active_recipe_id", "")) in ["recipe.process_crystal_ore", "recipe.repair_gel"]
	)
	var inputs_ready := inventory.has_ref("item.crystal_ore", 3) or inventory.has_ref("item.salvage_scrap", 1)
	var storage_ready := (
		(inventory.has_ref("item.basic_parts", 1) or inventory.has_ref("item.repair_gel", 1))
		and _has_first_path_output_context(world_state)
	)
	var outfitting_ready := (
		world_state.has_base_structure_definition("building.field_outfitting_station")
		and inventory.has_ref("item.repair_gel", 1)
		and _has_repair_gel_output_context(world_state)
	)
	path_state = {
		"crystal_ready": inventory.has_ref("item.crystal_ore", 3),
		"salvage_ready": inventory.has_ref("item.salvage_scrap", 1),
		"inputs_ready": inputs_ready,
		"reactor_active": reactor_active,
		"storage_ready": storage_ready,
		"outfitting_ready": outfitting_ready,
		"active_stage": _resolve_active_stage(character_state, inputs_ready, reactor_active, storage_ready, outfitting_ready)
	}
	_register_path_state_shape("first_path.crystal_pickup.%s" % _state_suffix(bool(path_state["crystal_ready"])))
	_register_path_state_shape("first_path.salvage_pickup.%s" % _state_suffix(bool(path_state["salvage_ready"])))
	_register_path_state_shape("first_path.base_receiving_bay.%s" % _state_suffix(inputs_ready))
	_register_path_state_shape("first_path.reactor_feed.%s" % _state_suffix(inputs_ready or reactor_active))
	_register_path_state_shape("first_path.reactor_work_window.%s" % _state_suffix(reactor_active))
	_register_path_state_shape("first_path.storage_output.%s" % _state_suffix(storage_ready))
	_register_path_state_shape("first_path.outfitting_handoff.%s" % _state_suffix(outfitting_ready))
	_register_path_state_shape("first_path.stage.%s" % get_active_stage())
	queue_redraw()


func refresh_focus_visibility(player_position: Vector2) -> void:
	visible = is_first_path_visible_at(player_position)


func is_first_path_visible_at(player_position: Vector2) -> bool:
	return player_position.x >= FOCUS_MIN_X and player_position.x <= FOCUS_MAX_X


func get_path_shape_count() -> int:
	return path_shape_ids.size()


func has_path_shape(shape_id: String) -> bool:
	return path_shape_ids.has(shape_id)


func get_path_state_shape_count() -> int:
	return path_state_shape_ids.size()


func has_path_state_shape(shape_id: String) -> bool:
	return path_state_shape_ids.has(shape_id)


func get_muted_planning_layer_count() -> int:
	return muted_planning_layer_count


func get_active_stage() -> String:
	return String(path_state.get("active_stage", ""))


func _draw() -> void:
	_draw_workspace_focus()
	_draw_primary_path_floor()
	_draw_stage_feedback()
	_draw_resource_workspots()
	_draw_base_receiving_bay()
	_draw_reactor_feed_station()
	_draw_storage_and_outfitting_handoff()
	_draw_path_state()


func _draw_workspace_focus() -> void:
	draw_rect(Rect2(Vector2(-360.0, -268.0), Vector2(632.0, 548.0)), WORKSPACE_WASH, true)
	for rect in [
		Rect2(Vector2(-338.0, -246.0), Vector2(92.0, 64.0)),
		Rect2(Vector2(-318.0, 112.0), Vector2(132.0, 76.0)),
		Rect2(Vector2(24.0, -208.0), Vector2(188.0, 52.0)),
		Rect2(Vector2(44.0, 92.0), Vector2(164.0, 72.0))
	]:
		draw_rect(rect, Color(0.012, 0.022, 0.023, 0.2), true)


func _draw_primary_path_floor() -> void:
	_draw_lane(PATH_POINTS, 22.0, PATH_FILL, PATH_EDGE)
	for point in PATH_POINTS:
		draw_circle(point, 3.4, Color(PATH_MARK.r, PATH_MARK.g, PATH_MARK.b, 0.58))
	for index in range(PATH_POINTS.size() - 1):
		var from: Vector2 = PATH_POINTS[index]
		var to: Vector2 = PATH_POINTS[index + 1]
		var direction := (to - from).normalized()
		var normal := Vector2(-direction.y, direction.x)
		var center := from.lerp(to, 0.52)
		draw_line(center - normal * 5.0, center + normal * 5.0, Color(PATH_MARK.r, PATH_MARK.g, PATH_MARK.b, 0.32), 1.2, true)


func _draw_stage_feedback() -> void:
	if path_state.is_empty():
		return
	match get_active_stage():
		STAGE_FIELD_PICKUP:
			_draw_active_stage_lane([Vector2(-42.0, -42.0), Vector2(-74.0, -14.0), Vector2(-42.0, -106.0), Vector2(48.0, -100.0), Vector2(132.0, -124.0)], CRYSTAL_ACCENT)
			_draw_stage_pulse(Vector2(132.0, -124.0), CRYSTAL_ACCENT, 28.0)
			_draw_stage_pulse(Vector2(54.0, 112.0), SALVAGE_ACCENT, 22.0)
		STAGE_RETURN_TO_BASE:
			_draw_active_stage_lane([Vector2(132.0, -124.0), Vector2(48.0, -100.0), Vector2(-42.0, -106.0), Vector2(-214.0, -112.0)], CRYSTAL_ACCENT)
			_draw_stage_pulse(Vector2(-214.0, -112.0), CRYSTAL_ACCENT, 24.0)
		STAGE_BASE_RECEIVING:
			_draw_active_stage_lane([Vector2(-214.0, -112.0), Vector2(-194.0, -108.0), Vector2(-178.0, -92.0)], SALVAGE_ACCENT)
			_draw_stage_pulse(Vector2(-214.0, -112.0), SALVAGE_ACCENT, 24.0)
		STAGE_REACTOR_PROCESSING:
			_draw_active_stage_lane([Vector2(-194.0, -108.0), Vector2(-178.0, -92.0), Vector2(-166.0, -66.0)], REACTOR_ACCENT)
			_draw_stage_pulse(Vector2(-166.0, -66.0), REACTOR_ACCENT, 31.0)
		STAGE_STORAGE_OUTPUT:
			_draw_active_stage_lane([Vector2(-148.0, -38.0), Vector2(-170.0, 10.0), Vector2(-250.0, 18.0)], PRODUCT_ACCENT)
			_draw_stage_pulse(Vector2(-250.0, 18.0), PRODUCT_ACCENT, 26.0)
		STAGE_OUTFITTING_READY:
			_draw_active_stage_lane([Vector2(-250.0, 18.0), Vector2(-128.0, 54.0), Vector2(-74.0, -14.0), Vector2(-42.0, -42.0)], OUTFITTING_ACCENT)
			_draw_stage_pulse(Vector2(-74.0, -14.0), OUTFITTING_ACCENT, 26.0)


func _draw_active_stage_lane(points: Array, color: Color) -> void:
	_draw_lane(points, 15.0, Color(color.r, color.g, color.b, 0.24), Color(color.r, color.g, color.b, 0.72))
	_draw_stage_chevrons(points, color)


func _draw_stage_chevrons(points: Array, color: Color) -> void:
	for index in range(points.size() - 1):
		var from: Vector2 = points[index]
		var to: Vector2 = points[index + 1]
		var direction := (to - from).normalized()
		var normal := Vector2(-direction.y, direction.x)
		for ratio in [0.34, 0.68]:
			var center := from.lerp(to, ratio)
			draw_line(center - direction * 7.0 - normal * 4.0, center + direction * 4.0, Color(color.r, color.g, color.b, 0.58), 1.4, true)
			draw_line(center - direction * 7.0 + normal * 4.0, center + direction * 4.0, Color(color.r, color.g, color.b, 0.58), 1.4, true)


func _draw_stage_pulse(center: Vector2, color: Color, radius: float) -> void:
	draw_circle(center, radius * 0.52, Color(color.r, color.g, color.b, 0.1))
	draw_arc(center, radius, PI * 0.12, PI * 1.9, 34, Color(color.r, color.g, color.b, 0.58), 2.2, true)
	draw_arc(center, radius + 6.0, PI * 0.52, PI * 1.36, 24, Color(color.r, color.g, color.b, 0.32), 1.4, true)


func _draw_resource_workspots() -> void:
	_draw_resource_pad(Vector2(132.0, -124.0), CRYSTAL_ACCENT, true)
	_draw_resource_pad(Vector2(54.0, 112.0), SALVAGE_ACCENT, false)
	_draw_lane([Vector2(54.0, 112.0), Vector2(8.0, 68.0), Vector2(-42.0, -106.0)], 11.0, Color(0.22, 0.26, 0.18, 0.24), SALVAGE_ACCENT)
	for offset in [Vector2(-12.0, -8.0), Vector2(8.0, -2.0), Vector2(0.0, 10.0)]:
		_draw_crystal_shard(Vector2(132.0, -124.0) + offset, 0.78)
	for rect in [
		Rect2(Vector2(42.0, 100.0), Vector2(22.0, 14.0)),
		Rect2(Vector2(66.0, 116.0), Vector2(18.0, 12.0))
	]:
		draw_rect(rect, Color(SALVAGE_ACCENT.r, SALVAGE_ACCENT.g, SALVAGE_ACCENT.b, 0.25), true)
		draw_rect(rect, Color(SALVAGE_ACCENT.r, SALVAGE_ACCENT.g, SALVAGE_ACCENT.b, 0.58), false, 1.2, true)


func _draw_base_receiving_bay() -> void:
	var bay := Rect2(Vector2(-236.0, -132.0), Vector2(48.0, 42.0))
	draw_rect(bay, Color(0.05, 0.08, 0.07, 0.56), true)
	draw_rect(bay, Color(CRYSTAL_ACCENT.r, CRYSTAL_ACCENT.g, CRYSTAL_ACCENT.b, 0.48), false, 1.8, true)
	draw_line(Vector2(-226.0, -122.0), Vector2(-198.0, -98.0), Color(CRYSTAL_ACCENT.r, CRYSTAL_ACCENT.g, CRYSTAL_ACCENT.b, 0.42), 2.2, true)
	draw_line(Vector2(-228.0, -98.0), Vector2(-198.0, -122.0), Color(SALVAGE_ACCENT.r, SALVAGE_ACCENT.g, SALVAGE_ACCENT.b, 0.34), 1.8, true)
	draw_rect(Rect2(Vector2(-250.0, -112.0), Vector2(14.0, 16.0)), Color(PATH_EDGE.r, PATH_EDGE.g, PATH_EDGE.b, 0.24), true)
	draw_circle(Vector2(-194.0, -108.0), 4.4, Color(CRYSTAL_ACCENT.r, CRYSTAL_ACCENT.g, CRYSTAL_ACCENT.b, 0.5))


func _draw_reactor_feed_station() -> void:
	var hopper := Rect2(Vector2(-184.0, -116.0), Vector2(38.0, 28.0))
	draw_rect(hopper, SLOT_DARK, true)
	draw_rect(hopper, Color(REACTOR_ACCENT.r, REACTOR_ACCENT.g, REACTOR_ACCENT.b, 0.54), false, 1.7, true)
	_draw_lane([Vector2(-194.0, -108.0), Vector2(-178.0, -92.0), Vector2(-166.0, -66.0)], 10.0, Color(REACTOR_ACCENT.r, REACTOR_ACCENT.g, REACTOR_ACCENT.b, 0.18), REACTOR_ACCENT)
	draw_rect(Rect2(Vector2(-176.0, -86.0), Vector2(24.0, 40.0)), Color(REACTOR_ACCENT.r, REACTOR_ACCENT.g, REACTOR_ACCENT.b, 0.12), true)
	draw_rect(Rect2(Vector2(-176.0, -86.0), Vector2(24.0, 40.0)), Color(REACTOR_ACCENT.r, REACTOR_ACCENT.g, REACTOR_ACCENT.b, 0.58), false, 1.8, true)
	for y in [-78.0, -66.0, -54.0]:
		draw_line(Vector2(-172.0, y), Vector2(-156.0, y + 6.0), Color(REACTOR_ACCENT.r, REACTOR_ACCENT.g, REACTOR_ACCENT.b, 0.4), 1.4, true)


func _draw_storage_and_outfitting_handoff() -> void:
	var storage := Rect2(Vector2(-284.0, 4.0), Vector2(68.0, 56.0))
	draw_rect(storage, Color(0.04, 0.08, 0.06, 0.5), true)
	draw_rect(storage, Color(PRODUCT_ACCENT.r, PRODUCT_ACCENT.g, PRODUCT_ACCENT.b, 0.46), false, 1.7, true)
	for index in range(3):
		var x := -274.0 + float(index) * 18.0
		draw_rect(Rect2(Vector2(x, 14.0), Vector2(12.0, 10.0)), Color(PRODUCT_ACCENT.r, PRODUCT_ACCENT.g, PRODUCT_ACCENT.b, 0.32), true)
		draw_rect(Rect2(Vector2(x, 34.0), Vector2(12.0, 10.0)), Color(OUTFITTING_ACCENT.r, OUTFITTING_ACCENT.g, OUTFITTING_ACCENT.b, 0.28), true)
	var handoff := Rect2(Vector2(-106.0, -32.0), Vector2(56.0, 30.0))
	draw_rect(handoff, SLOT_DARK, true)
	draw_rect(handoff, OUTFITTING_ACCENT, false, 1.7, true)
	draw_line(Vector2(-98.0, -16.0), Vector2(-56.0, -16.0), Color(OUTFITTING_ACCENT.r, OUTFITTING_ACCENT.g, OUTFITTING_ACCENT.b, 0.44), 2.4, true)
	draw_line(Vector2(-48.0, -38.0), Vector2(-30.0, -38.0), Color(OUTFITTING_ACCENT.r, OUTFITTING_ACCENT.g, OUTFITTING_ACCENT.b, 0.5), 3.0, true)


func _draw_path_state() -> void:
	if path_state.is_empty():
		return
	_draw_ready_pip(Vector2(132.0, -124.0), bool(path_state.get("crystal_ready", false)), CRYSTAL_ACCENT)
	_draw_ready_pip(Vector2(54.0, 112.0), bool(path_state.get("salvage_ready", false)), SALVAGE_ACCENT)
	_draw_ready_pip(Vector2(-214.0, -112.0), bool(path_state.get("inputs_ready", false)), CRYSTAL_ACCENT)
	_draw_ready_pip(Vector2(-166.0, -66.0), bool(path_state.get("reactor_active", false)), REACTOR_ACCENT)
	_draw_ready_pip(Vector2(-250.0, 18.0), bool(path_state.get("storage_ready", false)), PRODUCT_ACCENT)
	_draw_ready_pip(Vector2(-74.0, -14.0), bool(path_state.get("outfitting_ready", false)), OUTFITTING_ACCENT)


func _draw_ready_pip(position: Vector2, is_ready: bool, color: Color) -> void:
	draw_circle(position, 6.0, color if is_ready else READY_DIM)
	draw_arc(position, 10.0, 0.0, TAU, 24, Color(color.r, color.g, color.b, 0.42), 1.4, true)


func _draw_resource_pad(center: Vector2, color: Color, is_crystal: bool) -> void:
	var pad := Rect2(center + Vector2(-26.0, -20.0), Vector2(52.0, 40.0))
	draw_rect(pad, Color(0.03, 0.05, 0.045, 0.54), true)
	draw_rect(pad, Color(color.r, color.g, color.b, 0.44), false, 1.6, true)
	if is_crystal:
		draw_line(center + Vector2(-18.0, 12.0), center + Vector2(20.0, -14.0), Color(color.r, color.g, color.b, 0.34), 1.5, true)
	else:
		draw_line(center + Vector2(-18.0, -12.0), center + Vector2(18.0, 12.0), Color(color.r, color.g, color.b, 0.28), 1.4, true)


func _draw_crystal_shard(center: Vector2, scale: float) -> void:
	var shard := PackedVector2Array([
		center + Vector2(0.0, -12.0) * scale,
		center + Vector2(8.0, -2.0) * scale,
		center + Vector2(4.0, 11.0) * scale,
		center + Vector2(-8.0, 8.0) * scale,
		center + Vector2(-10.0, -4.0) * scale,
		center + Vector2(0.0, -12.0) * scale
	])
	draw_colored_polygon(shard, Color(CRYSTAL_ACCENT.r, CRYSTAL_ACCENT.g, CRYSTAL_ACCENT.b, 0.22))
	draw_polyline(shard, Color(CRYSTAL_ACCENT.r, CRYSTAL_ACCENT.g, CRYSTAL_ACCENT.b, 0.7), 1.4, true)


func _draw_lane(points: Array, width: float, fill_color: Color, edge_color: Color) -> void:
	var vector_points := PackedVector2Array()
	for point in points:
		vector_points.append(point)
	draw_polyline(vector_points, PATH_DARK, width + 6.0, true)
	draw_polyline(vector_points, fill_color, width, true)
	draw_polyline(vector_points, edge_color, 2.0, true)


func _register_path_shapes() -> void:
	path_shape_ids = [
		"first_path.workspace_focus_wash",
		"first_path.primary_player_lane",
		"first_path.crystal_pickup_pad",
		"first_path.salvage_pickup_pad",
		"first_path.salvage_spur_lane",
		"first_path.base_receiving_bay",
		"first_path.reactor_feed_hopper",
		"first_path.reactor_work_window",
		"first_path.storage_output_shelf",
		"first_path.outfitting_handoff_rack",
		"first_path.departure_supply_bus",
		"first_path.stage_feedback_lane",
		"first_path.stage_feedback_station",
		"first_path.operation_state_pips"
	]


func _register_path_state_shape(shape_id: String) -> void:
	if path_state_shape_ids.has(shape_id):
		return
	path_state_shape_ids.append(shape_id)


func _quiet_global_planning_layers() -> void:
	muted_planning_layer_count = 0
	_apply_layer_alpha("PrototypeVisualPriorityLayer", 0.18)
	_apply_layer_alpha("DemoRegionIndustrialValueLayer", 0.28)
	_apply_layer_alpha("DemoRoutePresentationLayer", 0.16)


func _apply_layer_alpha(path: String, alpha: float) -> void:
	var node := _get_map_node(path)
	var canvas_item := node as CanvasItem
	if canvas_item == null:
		return
	var color := canvas_item.modulate
	color.a = minf(color.a, alpha)
	canvas_item.modulate = color
	muted_planning_layer_count += 1


func _get_base_structure_for_definition(world_state: WorldState, building_id: String) -> Dictionary:
	for structure in world_state.base_structures.values():
		if not structure is Dictionary:
			continue
		if String(structure.get("definition_id", "")) == building_id:
			return structure
	return {}


func _has_first_path_output_context(world_state: WorldState) -> bool:
	var reactor_state := _get_base_structure_for_definition(world_state, "building.basic_reactor")
	var last_recipe_id := String(reactor_state.get("last_recipe_id", ""))
	return (
		last_recipe_id in ["recipe.process_crystal_ore", "recipe.repair_gel"]
		or _has_repair_gel_output_context(world_state)
	)


func _has_repair_gel_output_context(world_state: WorldState) -> bool:
	var reactor_state := _get_base_structure_for_definition(world_state, "building.basic_reactor")
	if String(reactor_state.get("last_recipe_id", "")) == "recipe.repair_gel":
		return true
	if world_state.quest_state.has_completed_quest("quest.prepare_treatment_supplies"):
		return true
	return world_state.quest_state.get_objective_progress(
		"quest.prepare_treatment_supplies",
		"craft_item",
		"item.repair_gel"
	) >= 1.0


func _resolve_active_stage(
	character_state: CharacterState,
	inputs_ready: bool,
	reactor_active: bool,
	storage_ready: bool,
	outfitting_ready: bool
) -> String:
	if reactor_active:
		return STAGE_REACTOR_PROCESSING
	if inputs_ready:
		if character_state.current_region_id == "region.crystal_vein_field" or character_state.position.x > -20.0:
			return STAGE_RETURN_TO_BASE
		return STAGE_BASE_RECEIVING
	if outfitting_ready:
		return STAGE_OUTFITTING_READY
	if storage_ready:
		return STAGE_STORAGE_OUTPUT
	return STAGE_FIELD_PICKUP


func _state_suffix(is_ready: bool) -> String:
	return "ready" if is_ready else "idle"


func _get_player_position() -> Vector2:
	if get_parent() == null:
		return Vector2.ZERO
	var player := get_parent().get_node_or_null("Player") as Node2D
	if player == null:
		return Vector2.ZERO
	return player.position


func _get_map_node(path: String) -> Node:
	if path.is_empty() or get_parent() == null:
		return null
	return get_parent().get_node_or_null(path)
