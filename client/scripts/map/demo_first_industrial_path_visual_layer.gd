extends Node2D
class_name DemoFirstIndustrialPathVisualLayer

const HandoffArtPass := preload("res://scripts/map/demo_first_industrial_path_handoff_art_pass.gd")
const AssetLanguageArtPass := preload("res://scripts/map/demo_default_path_asset_language_art_pass.gd")

const FOCUS_MIN_X := -360.0
const FOCUS_MAX_X := 160.0
const CRYSTAL_LOCAL_FOCUS_MIN_X := -80.0

const WORKSPACE_WASH := Color(0.006, 0.014, 0.014, 0.42)
const PATH_DARK := Color(0.008, 0.018, 0.018, 0.86)
const PATH_FILL := Color(0.13, 0.19, 0.17, 0.16)
const PATH_EDGE := Color(0.42, 0.54, 0.48, 0.24)
const PATH_MARK := Color(0.62, 0.58, 0.42, 0.24)
const WORKFACE_FILL := Color(0.035, 0.052, 0.046, 0.62)
const WORKFACE_EDGE := Color(0.48, 0.58, 0.5, 0.3)
const WORKFACE_DARK := Color(0.008, 0.014, 0.013, 0.72)
const LOGISTICS_PORT := Color(0.7, 0.76, 0.58, 0.42)
const CONTEXT_FILL := Color(0.022, 0.038, 0.034, 0.58)
const CONTEXT_EDGE := Color(0.42, 0.52, 0.46, 0.28)
const CONTEXT_DASH := Color(0.56, 0.54, 0.38, 0.18)
const SIGNAL_ACCENT := Color(0.96, 0.74, 0.28, 0.56)
const SIGNAL_SOFT := Color(0.96, 0.74, 0.28, 0.055)
const COMPLETE_DOT := Color(0.46, 0.64, 0.52, 0.58)
const CRYSTAL_ACCENT := Color(0.34, 0.78, 0.86, 0.32)
const SALVAGE_ACCENT := Color(0.84, 0.7, 0.34, 0.3)
const REACTOR_ACCENT := Color(1.0, 0.58, 0.22, 0.34)
const PRODUCT_ACCENT := Color(0.58, 0.88, 0.52, 0.3)
const OUTFITTING_ACCENT := Color(0.92, 0.74, 0.3, 0.32)
const SLOT_DARK := Color(0.02, 0.04, 0.035, 0.64)
const READY_DIM := Color(0.22, 0.28, 0.26, 0.22)
const HAND_SAMPLE_ACCENT := Color(0.82, 0.96, 1.0, 0.42)
const AUTO_MINER_ACCENT := Color(0.7, 0.9, 0.82, 0.38)
const FALLOFF_MASK := Color(0.002, 0.006, 0.006, 0.48)
const FALLOFF_SOFT := Color(0.002, 0.006, 0.006, 0.34)
const STATUS_WAITING := "waiting"
const STATUS_BUILD_READY := "build_ready"
const STATUS_RUNNING := "running"
const STATUS_OUTPUT_READY := "output_ready"
const STATUS_LOADED := "loaded"
const STATUS_INPUT_READY := "input_ready"
const STATUS_PROCESSING := "processing"
const STATUS_PRODUCT_READY := "product_ready"
const STATUS_SUPPLY_READY := "supply_ready"
const STATUS_LOCKED := "locked"
const STATUS_IDLE_LIGHT := Color(0.22, 0.28, 0.26, 0.24)
const STATUS_READY_LIGHT := Color(0.96, 0.78, 0.34, 0.74)
const STATUS_ACTIVE_LIGHT := Color(0.42, 0.96, 0.86, 0.76)
const STATUS_OUTPUT_LIGHT := Color(0.58, 0.88, 0.52, 0.68)
const CRYSTAL_COLLECTOR_ID := "building.crystal_collector_t1"
const CRYSTAL_COLLECTOR_OUTPUT_INSTANCE_ID := "map_object_instance.crystal_collector_output"
const FIRST_PATH_CONTEXT_ROUTE_ALPHA := 0.0002
const FIRST_PATH_CONTEXT_BOUNDARY_ALPHA := 0.0003
const FIRST_PATH_CONTEXT_MARKER_ALPHA := 0.014
const FIRST_PATH_LOCAL_MARKER_DISTANCE := 320.0

const FIRST_PATH_CONTEXT_LAYER_ALPHAS := [
	{"path": "OpeningSceneLayer", "alpha": 0.018},
	{"path": "DemoIndustrialBaseVisualLayer", "alpha": 0.16},
	{"path": "DemoCrystalResourceVisualLayer", "alpha": 0.12},
	{"path": "DemoPollutionBoundaryVisualLayer", "alpha": 0.004},
	{"path": "DemoCoreStabilizationVisualLayer", "alpha": 0.008},
	{"path": "DemoSceneFocusDepthLayer", "alpha": 0.018},
	{"path": "PrototypeVisualPriorityLayer", "alpha": 0.004},
	{"path": "DemoRegionIndustrialValueLayer", "alpha": 0.002},
	{"path": "DemoRoutePresentationLayer", "alpha": 0.0},
	{"path": "CurrentObjectiveGuidanceLayer", "alpha": 0.018}
]

const FIRST_PATH_CONTEXT_ROUTE_PATHS := [
	"MainRouteSpine",
	"BaseToCrystalRouteBand",
	"CrystalToPollutionRouteBand",
	"DemoRoutePresentationLayer/DemoRouteBaseBand",
	"DemoRoutePresentationLayer/DemoRouteCrystalBand",
	"DemoRoutePresentationLayer/DemoRoutePollutionBand",
	"DemoRoutePresentationLayer/DemoRouteRuinBand",
	"CurrentObjectiveGuidanceLayer/CurrentObjectiveRouteHorizontal",
	"CurrentObjectiveGuidanceLayer/CurrentObjectiveRouteVertical",
	"CurrentObjectiveGuidanceLayer/CurrentObjectiveTargetPin"
]

const FIRST_PATH_CONTEXT_BOUNDARY_PATHS := [
	"RegionBoundaryCrystal",
	"RegionBoundaryPollution",
	"RegionBoundaryRuin"
]

const STAGE_FIELD_PICKUP := "field_pickup"
const STAGE_RETURN_TO_BASE := "return_to_base"
const STAGE_BASE_RECEIVING := "base_receiving"
const STAGE_REACTOR_FEED := "reactor_feed"
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

const FIRST_PATH_LOCAL_INTERACTABLE_DEFINITION_IDS := {
	"building.outpost_core": true,
	"building.basic_reactor": true,
	"building.basic_storage": true,
	"building.field_outfitting_station": true,
	"building.slurry_buffer_tank": true,
	"map_object.outpost_departure_gate": true,
	"map_object.outpost_logistics_route_sign": true,
	"map_object.crystal_cluster": true,
	"map_object.rich_crystal_vein": true,
	"building.crystal_collector_t1": true,
	"map_object.crystal_collector_output": true,
	"map_object.field_wreckage": true,
	"map_object.anomaly_crystal": true,
	"map_object.anomaly_residue_patch": true
}

var path_shape_ids: Array[String] = []
var path_state_shape_ids: Array[String] = []
var muted_planning_layer_count := 0
var muted_context_rect_count := 0
var muted_context_marker_count := 0
var path_state: Dictionary = {}
var context_layer_original_modulates: Dictionary = {}
var first_path_available := false


func _ready() -> void:
	process_priority = 90
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
	first_path_available = _is_first_path_available(world_state)
	if world_state == null or character_state == null:
		path_state.clear()
		refresh_focus_visibility(_get_player_position())
		queue_redraw()
		return
	if not first_path_available:
		path_state.clear()
		refresh_focus_visibility(character_state.position)
		queue_redraw()
		return
	var inventory := character_state.inventory
	var reactor_state := _get_base_structure_for_definition(world_state, "building.basic_reactor")
	var reactor_active := (
		String(reactor_state.get("status", "")) == "in_progress"
		and String(reactor_state.get("active_recipe_id", "")) in ["recipe.process_crystal_ore", "recipe.repair_gel"]
	)
	var collector_built := world_state.has_base_structure_definition(CRYSTAL_COLLECTOR_ID)
	var collector_output_state := world_state.get_map_object(CRYSTAL_COLLECTOR_OUTPUT_INSTANCE_ID)
	var collector_output_ready := collector_built and not bool(collector_output_state.get("is_gathered", false))
	var collector_build_ready := (
		not collector_built
		and inventory.has_ref("item.basic_parts", 2)
		and inventory.has_ref("item.salvage_scrap", 1)
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
		"collector_build_ready": collector_build_ready,
		"collector_output_ready": collector_output_ready,
		"inputs_ready": inputs_ready,
		"reactor_active": reactor_active,
		"storage_ready": storage_ready,
		"outfitting_ready": outfitting_ready,
		"collector_device_state": _resolve_collector_device_state(collector_built, collector_build_ready, collector_output_ready),
		"receiving_device_state": STATUS_LOADED if inputs_ready else STATUS_WAITING,
		"reactor_device_state": _resolve_reactor_device_state(inputs_ready, reactor_active, storage_ready),
		"storage_device_state": STATUS_PRODUCT_READY if storage_ready else STATUS_WAITING,
		"outfitting_device_state": _resolve_outfitting_device_state(world_state, outfitting_ready),
		"active_stage": _resolve_active_stage(character_state, inputs_ready, reactor_active, storage_ready, outfitting_ready)
	}
	_register_path_state_shape("first_path.crystal_pickup.%s" % _state_suffix(bool(path_state["crystal_ready"])))
	_register_path_state_shape("first_path.hand_sample.%s" % _state_suffix(bool(path_state["crystal_ready"])))
	_register_path_state_shape("first_path.collector_build.%s" % _state_suffix(collector_build_ready))
	_register_path_state_shape("first_path.auto_miner_output.%s" % _state_suffix(collector_output_ready or bool(path_state["crystal_ready"])))
	_register_path_state_shape("first_path.salvage_pickup.%s" % _state_suffix(bool(path_state["salvage_ready"])))
	_register_path_state_shape("first_path.base_receiving_bay.%s" % _state_suffix(inputs_ready))
	_register_path_state_shape("first_path.reactor_feed.%s" % _state_suffix(inputs_ready or reactor_active))
	_register_path_state_shape("first_path.reactor_work_window.%s" % _state_suffix(reactor_active))
	_register_path_state_shape("first_path.storage_output.%s" % _state_suffix(storage_ready))
	_register_path_state_shape("first_path.outfitting_handoff.%s" % _state_suffix(outfitting_ready))
	if collector_output_ready:
		_register_path_state_shape("first_path.auto_miner_output.current_stage")
	if outfitting_ready:
		_register_path_state_shape("first_path.handoff_ports.ready")
	_register_device_state_shapes()
	_register_resource_flow_shapes()
	_register_path_state_shape("first_path.stage.%s" % get_active_stage())
	queue_redraw()


func refresh_focus_visibility(player_position: Vector2) -> void:
	var should_show := is_first_path_visible_at(player_position)
	visible = should_show
	if first_path_available and _is_crystal_local_focus_position(player_position):
		_restore_context_layer("DemoCrystalResourceVisualLayer")
		muted_planning_layer_count = 0
		muted_context_rect_count = 0
		muted_context_marker_count = 0
		return
	_set_context_layers_muted(should_show)
	_mute_first_path_context_rects(should_show)
	_mute_first_path_context_interactable_markers(should_show, player_position)


func is_first_path_visible_at(player_position: Vector2) -> bool:
	return should_use_compact_guidance_at(player_position) and not _is_crystal_local_focus_position(player_position)


func should_use_compact_guidance_at(player_position: Vector2) -> bool:
	return first_path_available and player_position.x >= FOCUS_MIN_X and player_position.x <= FOCUS_MAX_X


func is_first_path_available() -> bool:
	return first_path_available


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


func get_muted_context_rect_count() -> int:
	return muted_context_rect_count


func get_muted_context_marker_count() -> int:
	return muted_context_marker_count


func get_active_stage() -> String:
	return String(path_state.get("active_stage", ""))


func _draw() -> void:
	_draw_workspace_focus()
	AssetLanguageArtPass.draw_base_handoff_language(self)
	_draw_context_falloff()
	_draw_primary_path_floor()
	HandoffArtPass.draw_devices(self)
	_draw_local_work_surfaces()
	HandoffArtPass.draw_ports(self)
	_draw_resource_workspots()
	_draw_base_receiving_bay()
	_draw_reactor_feed_station()
	_draw_storage_and_outfitting_handoff()
	_draw_operation_relation_overlay()
	_draw_device_status_and_resource_flow()
	HandoffArtPass.draw_feedback(self, path_state, get_active_stage())
	_draw_stage_feedback()
	_draw_path_state()


func _draw_workspace_focus() -> void:
	draw_rect(Rect2(Vector2(-360.0, -268.0), Vector2(632.0, 548.0)), WORKSPACE_WASH, true)
	for rect in [
		Rect2(Vector2(-338.0, -246.0), Vector2(92.0, 64.0)),
		Rect2(Vector2(-318.0, 112.0), Vector2(132.0, 76.0)),
		Rect2(Vector2(24.0, -208.0), Vector2(188.0, 52.0)),
		Rect2(Vector2(44.0, 92.0), Vector2(164.0, 72.0))
	]:
		draw_rect(rect, Color(0.012, 0.022, 0.023, 0.28), true)


func _draw_context_falloff() -> void:
	draw_rect(Rect2(Vector2(266.0, -320.0), Vector2(560.0, 640.0)), FALLOFF_MASK, true)
	draw_rect(Rect2(Vector2(-620.0, -320.0), Vector2(252.0, 640.0)), FALLOFF_SOFT, true)
	draw_rect(Rect2(Vector2(232.0, -320.0), Vector2(34.0, 640.0)), Color(FALLOFF_MASK.r, FALLOFF_MASK.g, FALLOFF_MASK.b, 0.22), true)


func _draw_primary_path_floor() -> void:
	var points := _get_primary_path_floor_points()
	_draw_lane(points, 18.0 if _is_base_handoff_state() else 22.0, PATH_FILL, PATH_EDGE)
	for point in points:
		draw_circle(point, 3.4, Color(PATH_MARK.r, PATH_MARK.g, PATH_MARK.b, 0.58))
	for index in range(points.size() - 1):
		var from: Vector2 = points[index]
		var to: Vector2 = points[index + 1]
		var direction := (to - from).normalized()
		var normal := Vector2(-direction.y, direction.x)
		var center := from.lerp(to, 0.52)
		draw_line(center - normal * 5.0, center + normal * 5.0, Color(PATH_MARK.r, PATH_MARK.g, PATH_MARK.b, 0.32), 1.2, true)


func _get_primary_path_floor_points() -> Array:
	if not _is_base_handoff_state():
		return PATH_POINTS
	return [
		Vector2(-214.0, -112.0),
		Vector2(-184.0, -114.0),
		Vector2(-166.0, -66.0),
		Vector2(-250.0, 18.0),
		Vector2(-74.0, -14.0)
	]


func _draw_local_work_surfaces() -> void:
	_draw_crystal_cut_workface()
	_draw_salvage_sorting_workface()
	_draw_base_receiving_workface()
	_draw_reactor_input_workface()
	_draw_storage_output_workface()
	_draw_outfitting_departure_port()


func _draw_crystal_cut_workface() -> void:
	var center := Vector2(132.0, -124.0)
	var mine_face := PackedVector2Array([
		center + Vector2(-46.0, -26.0),
		center + Vector2(16.0, -36.0),
		center + Vector2(52.0, -12.0),
		center + Vector2(34.0, 24.0),
		center + Vector2(-36.0, 30.0),
		center + Vector2(-58.0, 4.0),
		center + Vector2(-46.0, -26.0)
	])
	draw_colored_polygon(mine_face, Color(CRYSTAL_ACCENT.r, CRYSTAL_ACCENT.g, CRYSTAL_ACCENT.b, 0.08))
	draw_polyline(mine_face, Color(CRYSTAL_ACCENT.r, CRYSTAL_ACCENT.g, CRYSTAL_ACCENT.b, 0.2), 1.5, true)
	for offset in [Vector2(-28.0, -10.0), Vector2(-6.0, -18.0), Vector2(22.0, -6.0), Vector2(8.0, 14.0)]:
		draw_line(center + offset, center + offset + Vector2(24.0, -8.0), Color(CRYSTAL_ACCENT.r, CRYSTAL_ACCENT.g, CRYSTAL_ACCENT.b, 0.18), 1.2, true)
	for x in [96.0, 116.0, 136.0, 156.0]:
		draw_rect(Rect2(Vector2(x, -94.0), Vector2(12.0, 5.0)), WORKFACE_EDGE, true)
	_draw_logistics_port(Vector2(86.0, -118.0), CRYSTAL_ACCENT)
	_draw_hand_sample_point(center + Vector2(-48.0, 24.0))
	_draw_auto_miner_workface(center)


func _draw_salvage_sorting_workface() -> void:
	var center := Vector2(54.0, 112.0)
	var yard := Rect2(center + Vector2(-44.0, -28.0), Vector2(92.0, 58.0))
	draw_rect(yard, Color(SALVAGE_ACCENT.r, SALVAGE_ACCENT.g, SALVAGE_ACCENT.b, 0.06), true)
	draw_rect(yard, Color(SALVAGE_ACCENT.r, SALVAGE_ACCENT.g, SALVAGE_ACCENT.b, 0.18), false, 1.2, true)
	for rect in [
		Rect2(center + Vector2(-34.0, -18.0), Vector2(18.0, 10.0)),
		Rect2(center + Vector2(-10.0, 2.0), Vector2(20.0, 12.0)),
		Rect2(center + Vector2(18.0, -10.0), Vector2(16.0, 12.0))
	]:
		draw_rect(rect, WORKFACE_DARK, true)
		draw_rect(rect, Color(SALVAGE_ACCENT.r, SALVAGE_ACCENT.g, SALVAGE_ACCENT.b, 0.22), false, 1.0, true)
	for x in [24.0, 44.0, 64.0, 84.0]:
		draw_line(Vector2(x, 138.0), Vector2(x + 12.0, 130.0), Color(SALVAGE_ACCENT.r, SALVAGE_ACCENT.g, SALVAGE_ACCENT.b, 0.16), 1.0, true)
	_draw_logistics_port(Vector2(6.0, 78.0), SALVAGE_ACCENT)


func _draw_base_receiving_workface() -> void:
	var bay := Rect2(Vector2(-256.0, -146.0), Vector2(88.0, 70.0))
	draw_rect(bay, WORKFACE_FILL, true)
	draw_rect(bay, Color(LOGISTICS_PORT.r, LOGISTICS_PORT.g, LOGISTICS_PORT.b, 0.36), false, 1.8, true)
	for y in [-128.0, -112.0, -96.0]:
		draw_line(Vector2(-246.0, y), Vector2(-182.0, y), Color(WORKFACE_EDGE.r, WORKFACE_EDGE.g, WORKFACE_EDGE.b, 0.22), 1.2, true)
	_draw_logistics_port(Vector2(-214.0, -112.0), LOGISTICS_PORT)
	draw_rect(Rect2(Vector2(-240.0, -138.0), Vector2(22.0, 12.0)), Color(CRYSTAL_ACCENT.r, CRYSTAL_ACCENT.g, CRYSTAL_ACCENT.b, 0.18), true)
	draw_rect(Rect2(Vector2(-212.0, -138.0), Vector2(22.0, 12.0)), Color(SALVAGE_ACCENT.r, SALVAGE_ACCENT.g, SALVAGE_ACCENT.b, 0.16), true)
	draw_line(Vector2(-250.0, -112.0), Vector2(-232.0, -112.0), Color(LOGISTICS_PORT.r, LOGISTICS_PORT.g, LOGISTICS_PORT.b, 0.3), 2.6, true)
	draw_circle(Vector2(-174.0, -112.0), 5.0, Color(REACTOR_ACCENT.r, REACTOR_ACCENT.g, REACTOR_ACCENT.b, 0.28))


func _draw_reactor_input_workface() -> void:
	var workbench := Rect2(Vector2(-196.0, -134.0), Vector2(76.0, 40.0))
	draw_rect(workbench, WORKFACE_FILL, true)
	draw_rect(workbench, Color(REACTOR_ACCENT.r, REACTOR_ACCENT.g, REACTOR_ACCENT.b, 0.3), false, 1.8, true)
	_draw_logistics_port(Vector2(-184.0, -114.0), REACTOR_ACCENT)
	_draw_logistics_port(Vector2(-134.0, -114.0), PRODUCT_ACCENT)
	draw_line(Vector2(-174.0, -114.0), Vector2(-144.0, -114.0), Color(REACTOR_ACCENT.r, REACTOR_ACCENT.g, REACTOR_ACCENT.b, 0.24), 2.6, true)
	var hopper := PackedVector2Array([
		Vector2(-186.0, -130.0),
		Vector2(-158.0, -130.0),
		Vector2(-166.0, -116.0),
		Vector2(-178.0, -116.0),
		Vector2(-186.0, -130.0)
	])
	draw_colored_polygon(hopper, Color(REACTOR_ACCENT.r, REACTOR_ACCENT.g, REACTOR_ACCENT.b, 0.12))
	draw_polyline(hopper, Color(REACTOR_ACCENT.r, REACTOR_ACCENT.g, REACTOR_ACCENT.b, 0.32), 1.2, true)


func _draw_storage_output_workface() -> void:
	var shelf := Rect2(Vector2(-300.0, -6.0), Vector2(100.0, 82.0))
	draw_rect(shelf, Color(PRODUCT_ACCENT.r, PRODUCT_ACCENT.g, PRODUCT_ACCENT.b, 0.05), true)
	draw_rect(shelf, Color(PRODUCT_ACCENT.r, PRODUCT_ACCENT.g, PRODUCT_ACCENT.b, 0.28), false, 1.6, true)
	for y in [16.0, 40.0]:
		draw_line(Vector2(-290.0, y), Vector2(-210.0, y), Color(PRODUCT_ACCENT.r, PRODUCT_ACCENT.g, PRODUCT_ACCENT.b, 0.2), 1.4, true)
	for x in [-280.0, -252.0, -224.0]:
		draw_rect(Rect2(Vector2(x, 48.0), Vector2(16.0, 12.0)), Color(PRODUCT_ACCENT.r, PRODUCT_ACCENT.g, PRODUCT_ACCENT.b, 0.18), true)
		draw_rect(Rect2(Vector2(x, 48.0), Vector2(16.0, 12.0)), Color(PRODUCT_ACCENT.r, PRODUCT_ACCENT.g, PRODUCT_ACCENT.b, 0.24), false, 1.0, true)
	_draw_logistics_port(Vector2(-206.0, 18.0), PRODUCT_ACCENT)


func _draw_outfitting_departure_port() -> void:
	var rack := Rect2(Vector2(-112.0, -44.0), Vector2(70.0, 52.0))
	draw_rect(rack, Color(OUTFITTING_ACCENT.r, OUTFITTING_ACCENT.g, OUTFITTING_ACCENT.b, 0.06), true)
	draw_rect(rack, Color(OUTFITTING_ACCENT.r, OUTFITTING_ACCENT.g, OUTFITTING_ACCENT.b, 0.2), false, 1.4, true)
	for x in [-98.0, -82.0, -66.0]:
		draw_line(Vector2(x, -36.0), Vector2(x + 10.0, 0.0), Color(OUTFITTING_ACCENT.r, OUTFITTING_ACCENT.g, OUTFITTING_ACCENT.b, 0.18), 1.2, true)
	_draw_logistics_port(Vector2(-74.0, -14.0), OUTFITTING_ACCENT)
	draw_line(Vector2(-52.0, -38.0), Vector2(-30.0, -38.0), Color(OUTFITTING_ACCENT.r, OUTFITTING_ACCENT.g, OUTFITTING_ACCENT.b, 0.3), 2.4, true)


func _draw_logistics_port(center: Vector2, color: Color) -> void:
	draw_rect(Rect2(center + Vector2(-7.0, -7.0), Vector2(14.0, 14.0)), WORKFACE_DARK, true)
	draw_rect(Rect2(center + Vector2(-7.0, -7.0), Vector2(14.0, 14.0)), Color(color.r, color.g, color.b, 0.32), false, 1.2, true)
	draw_circle(center, 3.2, Color(color.r, color.g, color.b, 0.26))


func _draw_stage_feedback() -> void:
	if path_state.is_empty():
		return
	match get_active_stage():
		STAGE_FIELD_PICKUP:
			_draw_field_pickup_stage_feedback()
		STAGE_RETURN_TO_BASE:
			_draw_active_stage_lane([Vector2(132.0, -124.0), Vector2(74.0, -116.0), Vector2(6.0, -112.0), Vector2(-214.0, -112.0)])
			_draw_stage_pulse(Vector2(-214.0, -112.0), 24.0)
		STAGE_BASE_RECEIVING:
			_draw_active_stage_lane([Vector2(-214.0, -112.0), Vector2(-194.0, -108.0)])
			_draw_stage_pulse(Vector2(-214.0, -112.0), 24.0)
		STAGE_REACTOR_FEED:
			_draw_active_stage_lane([Vector2(-214.0, -112.0), Vector2(-194.0, -108.0), Vector2(-184.0, -114.0)])
			_draw_stage_pulse(Vector2(-184.0, -114.0), 22.0)
		STAGE_REACTOR_PROCESSING:
			_draw_active_stage_lane([Vector2(-184.0, -114.0), Vector2(-176.0, -86.0), Vector2(-166.0, -66.0)])
			_draw_stage_pulse(Vector2(-166.0, -66.0), 31.0)
		STAGE_STORAGE_OUTPUT:
			_draw_active_stage_lane([Vector2(-148.0, -38.0), Vector2(-206.0, 18.0), Vector2(-250.0, 18.0)])
			_draw_stage_pulse(Vector2(-250.0, 18.0), 26.0)
		STAGE_OUTFITTING_READY:
			_draw_handoff_stage_feedback()
			_draw_stage_pulse(Vector2(-74.0, -14.0), 26.0)


func _draw_field_pickup_stage_feedback() -> void:
	if bool(path_state.get("collector_output_ready", false)):
		_draw_active_stage_lane([Vector2(132.0, -124.0), Vector2(114.0, -104.0), Vector2(86.0, -118.0)])
		_draw_stage_pulse(Vector2(86.0, -118.0), 18.0)
		_draw_stage_pulse(Vector2(132.0, -124.0), 18.0)
		return
	if bool(path_state.get("collector_build_ready", false)):
		_draw_active_stage_lane([Vector2(132.0, -124.0), Vector2(132.0, -146.0)])
		_draw_stage_pulse(Vector2(132.0, -146.0), 18.0)
		return
	_draw_active_stage_lane([Vector2(84.0, -100.0), Vector2(132.0, -124.0)])
	_draw_stage_pulse(Vector2(84.0, -100.0), 16.0)
	_draw_stage_pulse(Vector2(132.0, -124.0), 22.0)


func _draw_handoff_stage_feedback() -> void:
	_draw_handoff_port_chain()
	_draw_active_stage_lane([Vector2(-250.0, 18.0), Vector2(-168.0, 28.0), Vector2(-92.0, -2.0), Vector2(-74.0, -14.0)])


func _draw_active_stage_lane(points: Array) -> void:
	_draw_lane(points, 7.0, SIGNAL_SOFT, SIGNAL_ACCENT)
	_draw_stage_chevrons(points)


func _draw_stage_chevrons(points: Array) -> void:
	for index in range(points.size() - 1):
		var from: Vector2 = points[index]
		var to: Vector2 = points[index + 1]
		var direction := (to - from).normalized()
		var normal := Vector2(-direction.y, direction.x)
		if from.distance_to(to) < 30.0:
			continue
		for ratio in [0.58]:
			var center := from.lerp(to, ratio)
			draw_line(center - direction * 6.0 - normal * 3.0, center + direction * 4.0, SIGNAL_ACCENT, 1.4, true)
			draw_line(center - direction * 6.0 + normal * 3.0, center + direction * 4.0, SIGNAL_ACCENT, 1.4, true)


func _draw_stage_pulse(center: Vector2, radius: float) -> void:
	draw_circle(center, 4.2, SIGNAL_ACCENT)
	draw_arc(center, radius, PI * 0.12, PI * 1.9, 30, SIGNAL_ACCENT, 1.8, true)
	draw_arc(center, radius + 5.0, PI * 0.52, PI * 1.36, 20, Color(SIGNAL_ACCENT.r, SIGNAL_ACCENT.g, SIGNAL_ACCENT.b, 0.28), 1.2, true)


func _draw_handoff_port_chain() -> void:
	var ports := [
		{"position": Vector2(-214.0, -112.0), "color": LOGISTICS_PORT},
		{"position": Vector2(-184.0, -114.0), "color": REACTOR_ACCENT},
		{"position": Vector2(-250.0, 18.0), "color": PRODUCT_ACCENT},
		{"position": Vector2(-74.0, -14.0), "color": OUTFITTING_ACCENT}
	]
	if not _is_base_handoff_state():
		for index in range(ports.size() - 1):
			var from: Vector2 = ports[index]["position"]
			var to: Vector2 = ports[index + 1]["position"]
			draw_line(from, to, Color(SIGNAL_ACCENT.r, SIGNAL_ACCENT.g, SIGNAL_ACCENT.b, 0.14), 3.0, true)
	for port in ports:
		var position: Vector2 = port["position"]
		var color: Color = port["color"]
		draw_circle(position, 8.0, Color(color.r, color.g, color.b, 0.10 if _is_base_handoff_state() else 0.13))
		draw_arc(position, 12.0, 0.0, TAU, 24, Color(color.r, color.g, color.b, 0.28), 1.2, true)
		draw_rect(Rect2(position + Vector2(-4.0, -4.0), Vector2(8.0, 8.0)), Color(color.r, color.g, color.b, 0.18), true)


func _draw_operation_relation_overlay() -> void:
	if _is_base_handoff_state():
		_draw_compact_handoff_relation_overlay()
		return
	_draw_relation_track([Vector2(132.0, -124.0), Vector2(114.0, -104.0), Vector2(86.0, -118.0)], AUTO_MINER_ACCENT)
	_draw_relation_track([Vector2(86.0, -118.0), Vector2(8.0, -112.0), Vector2(-214.0, -112.0)], CRYSTAL_ACCENT)
	_draw_relation_track([Vector2(54.0, 112.0), Vector2(8.0, 68.0), Vector2(-42.0, -106.0), Vector2(-214.0, -112.0)], SALVAGE_ACCENT)
	_draw_relation_track([Vector2(-214.0, -112.0), Vector2(-194.0, -108.0), Vector2(-184.0, -114.0)], REACTOR_ACCENT)
	_draw_relation_track([Vector2(-134.0, -114.0), Vector2(-206.0, 18.0), Vector2(-250.0, 18.0)], PRODUCT_ACCENT)
	_draw_relation_track([Vector2(-250.0, 18.0), Vector2(-168.0, 28.0), Vector2(-74.0, -14.0)], OUTFITTING_ACCENT)
	for port in [
		{"position": Vector2(132.0, -124.0), "color": AUTO_MINER_ACCENT},
		{"position": Vector2(86.0, -118.0), "color": CRYSTAL_ACCENT},
		{"position": Vector2(54.0, 112.0), "color": SALVAGE_ACCENT},
		{"position": Vector2(-214.0, -112.0), "color": LOGISTICS_PORT},
		{"position": Vector2(-184.0, -114.0), "color": REACTOR_ACCENT},
		{"position": Vector2(-250.0, 18.0), "color": PRODUCT_ACCENT},
		{"position": Vector2(-74.0, -14.0), "color": OUTFITTING_ACCENT}
	]:
		var position: Vector2 = port["position"]
		var color: Color = port["color"]
		_draw_relation_port(position, color)


func _draw_compact_handoff_relation_overlay() -> void:
	for relation in [
		{"points": [Vector2(-214.0, -112.0), Vector2(-194.0, -108.0), Vector2(-184.0, -114.0)], "color": REACTOR_ACCENT},
		{"points": [Vector2(-134.0, -114.0), Vector2(-186.0, -22.0), Vector2(-250.0, 18.0)], "color": PRODUCT_ACCENT},
		{"points": [Vector2(-250.0, 18.0), Vector2(-166.0, 26.0), Vector2(-74.0, -14.0)], "color": OUTFITTING_ACCENT}
	]:
		var color: Color = relation["color"]
		var relation_points: Array = relation["points"]
		_draw_compact_relation_track(relation_points, color)
	for port in [
		{"position": Vector2(-214.0, -112.0), "color": LOGISTICS_PORT},
		{"position": Vector2(-184.0, -114.0), "color": REACTOR_ACCENT},
		{"position": Vector2(-250.0, 18.0), "color": PRODUCT_ACCENT},
		{"position": Vector2(-74.0, -14.0), "color": OUTFITTING_ACCENT}
	]:
		var position: Vector2 = port["position"]
		var color: Color = port["color"]
		_draw_relation_port(position, Color(color.r, color.g, color.b, color.a * 0.82))


func _draw_compact_relation_track(points: Array, color: Color) -> void:
	var vector_points := PackedVector2Array()
	for point in points:
		vector_points.append(point)
	draw_polyline(vector_points, Color(0.006, 0.014, 0.012, 0.62), 4.2, true)
	draw_polyline(vector_points, Color(color.r, color.g, color.b, 0.13), 1.6, true)


func _draw_relation_track(points: Array, color: Color) -> void:
	var vector_points := PackedVector2Array()
	for point in points:
		vector_points.append(point)
	draw_polyline(vector_points, Color(0.006, 0.014, 0.012, 0.74), 6.2, true)
	draw_polyline(vector_points, Color(color.r, color.g, color.b, 0.2), 2.2, true)
	for index in range(points.size() - 1):
		var from: Vector2 = points[index]
		var to: Vector2 = points[index + 1]
		if from.distance_to(to) < 34.0:
			continue
		var direction := (to - from).normalized()
		var normal := Vector2(-direction.y, direction.x)
		var center := from.lerp(to, 0.64)
		draw_line(center - direction * 5.0 - normal * 3.0, center + direction * 4.0, Color(color.r, color.g, color.b, 0.34), 1.2, true)
		draw_line(center - direction * 5.0 + normal * 3.0, center + direction * 4.0, Color(color.r, color.g, color.b, 0.34), 1.2, true)


func _draw_relation_port(position: Vector2, color: Color) -> void:
	draw_circle(position, 7.6, Color(color.r, color.g, color.b, 0.13))
	draw_arc(position, 10.8, 0.0, TAU, 22, Color(color.r, color.g, color.b, 0.26), 1.1, true)
	draw_rect(Rect2(position + Vector2(-3.6, -3.6), Vector2(7.2, 7.2)), Color(color.r, color.g, color.b, 0.22), true)


func _draw_resource_workspots() -> void:
	if _is_base_handoff_state():
		return
	_draw_resource_pad(Vector2(132.0, -124.0), CRYSTAL_ACCENT, true)
	_draw_resource_pad(Vector2(54.0, 112.0), SALVAGE_ACCENT, false)
	_draw_lane([Vector2(54.0, 112.0), Vector2(8.0, 68.0), Vector2(-42.0, -106.0)], 9.0, Color(0.14, 0.16, 0.12, 0.14), Color(SALVAGE_ACCENT.r, SALVAGE_ACCENT.g, SALVAGE_ACCENT.b, 0.22))
	for offset in [Vector2(-12.0, -8.0), Vector2(8.0, -2.0), Vector2(0.0, 10.0)]:
		_draw_crystal_shard(Vector2(132.0, -124.0) + offset, 0.78)
	_draw_lane([Vector2(132.0, -124.0), Vector2(114.0, -104.0), Vector2(86.0, -118.0)], 6.0, Color(AUTO_MINER_ACCENT.r, AUTO_MINER_ACCENT.g, AUTO_MINER_ACCENT.b, 0.12), Color(AUTO_MINER_ACCENT.r, AUTO_MINER_ACCENT.g, AUTO_MINER_ACCENT.b, 0.3))
	for rect in [
		Rect2(Vector2(42.0, 100.0), Vector2(22.0, 14.0)),
		Rect2(Vector2(66.0, 116.0), Vector2(18.0, 12.0))
	]:
		draw_rect(rect, Color(SALVAGE_ACCENT.r, SALVAGE_ACCENT.g, SALVAGE_ACCENT.b, 0.1), true)
		draw_rect(rect, Color(SALVAGE_ACCENT.r, SALVAGE_ACCENT.g, SALVAGE_ACCENT.b, 0.24), false, 1.2, true)


func _draw_base_receiving_bay() -> void:
	var bay := Rect2(Vector2(-236.0, -132.0), Vector2(48.0, 42.0))
	draw_rect(bay, CONTEXT_FILL, true)
	draw_rect(bay, CONTEXT_EDGE, false, 1.6, true)
	draw_line(Vector2(-226.0, -122.0), Vector2(-198.0, -98.0), CONTEXT_DASH, 1.8, true)
	draw_line(Vector2(-228.0, -98.0), Vector2(-198.0, -122.0), CONTEXT_DASH, 1.4, true)
	draw_rect(Rect2(Vector2(-250.0, -112.0), Vector2(14.0, 16.0)), Color(PATH_EDGE.r, PATH_EDGE.g, PATH_EDGE.b, 0.24), true)
	draw_circle(Vector2(-194.0, -108.0), 4.4, CONTEXT_EDGE)


func _draw_reactor_feed_station() -> void:
	var hopper := Rect2(Vector2(-184.0, -116.0), Vector2(38.0, 28.0))
	draw_rect(hopper, SLOT_DARK, true)
	draw_rect(hopper, CONTEXT_EDGE, false, 1.6, true)
	_draw_lane([Vector2(-194.0, -108.0), Vector2(-178.0, -92.0), Vector2(-166.0, -66.0)], 8.0, Color(REACTOR_ACCENT.r, REACTOR_ACCENT.g, REACTOR_ACCENT.b, 0.08), Color(REACTOR_ACCENT.r, REACTOR_ACCENT.g, REACTOR_ACCENT.b, 0.22))
	draw_rect(Rect2(Vector2(-176.0, -86.0), Vector2(24.0, 40.0)), Color(REACTOR_ACCENT.r, REACTOR_ACCENT.g, REACTOR_ACCENT.b, 0.08), true)
	draw_rect(Rect2(Vector2(-176.0, -86.0), Vector2(24.0, 40.0)), CONTEXT_EDGE, false, 1.6, true)
	for y in [-78.0, -66.0, -54.0]:
		draw_line(Vector2(-172.0, y), Vector2(-156.0, y + 6.0), CONTEXT_DASH, 1.2, true)


func _draw_storage_and_outfitting_handoff() -> void:
	var storage := Rect2(Vector2(-284.0, 4.0), Vector2(68.0, 56.0))
	draw_rect(storage, CONTEXT_FILL, true)
	draw_rect(storage, CONTEXT_EDGE, false, 1.6, true)
	for index in range(3):
		var x := -274.0 + float(index) * 18.0
		draw_rect(Rect2(Vector2(x, 14.0), Vector2(12.0, 10.0)), Color(PRODUCT_ACCENT.r, PRODUCT_ACCENT.g, PRODUCT_ACCENT.b, 0.14), true)
		draw_rect(Rect2(Vector2(x, 34.0), Vector2(12.0, 10.0)), Color(OUTFITTING_ACCENT.r, OUTFITTING_ACCENT.g, OUTFITTING_ACCENT.b, 0.12), true)
	var handoff := Rect2(Vector2(-106.0, -32.0), Vector2(56.0, 30.0))
	draw_rect(handoff, SLOT_DARK, true)
	draw_rect(handoff, CONTEXT_EDGE, false, 1.6, true)
	draw_line(Vector2(-98.0, -16.0), Vector2(-56.0, -16.0), CONTEXT_DASH, 1.8, true)
	draw_line(Vector2(-48.0, -38.0), Vector2(-30.0, -38.0), CONTEXT_DASH, 2.0, true)


func _draw_device_status_and_resource_flow() -> void:
	if path_state.is_empty():
		return
	_draw_resource_flow_state()
	_draw_status_light_strip(Vector2(144.0, -158.0), String(path_state.get("collector_device_state", STATUS_WAITING)), AUTO_MINER_ACCENT)
	_draw_status_light_strip(Vector2(-256.0, -158.0), String(path_state.get("receiving_device_state", STATUS_WAITING)), LOGISTICS_PORT)
	_draw_status_light_strip(Vector2(-194.0, -144.0), String(path_state.get("reactor_device_state", STATUS_WAITING)), REACTOR_ACCENT)
	_draw_status_light_strip(Vector2(-302.0, -18.0), String(path_state.get("storage_device_state", STATUS_WAITING)), PRODUCT_ACCENT)
	_draw_status_light_strip(Vector2(-112.0, -58.0), String(path_state.get("outfitting_device_state", STATUS_LOCKED)), OUTFITTING_ACCENT)
	_draw_material_slot(Rect2(Vector2(78.0, -130.0), Vector2(26.0, 9.0)), AUTO_MINER_ACCENT, bool(path_state.get("collector_output_ready", false)))
	_draw_material_slot(Rect2(Vector2(-242.0, -142.0), Vector2(22.0, 9.0)), CRYSTAL_ACCENT, bool(path_state.get("inputs_ready", false)))
	_draw_material_slot(Rect2(Vector2(-214.0, -142.0), Vector2(22.0, 9.0)), SALVAGE_ACCENT, bool(path_state.get("salvage_ready", false)))
	_draw_material_slot(Rect2(Vector2(-180.0, -132.0), Vector2(18.0, 8.0)), REACTOR_ACCENT, bool(path_state.get("inputs_ready", false)) or bool(path_state.get("reactor_active", false)))
	_draw_material_slot(Rect2(Vector2(-290.0, 64.0), Vector2(20.0, 8.0)), PRODUCT_ACCENT, bool(path_state.get("storage_ready", false)))
	_draw_material_slot(Rect2(Vector2(-104.0, -8.0), Vector2(20.0, 8.0)), OUTFITTING_ACCENT, bool(path_state.get("outfitting_ready", false)))


func _draw_resource_flow_state() -> void:
	var active_stage := get_active_stage()
	if bool(path_state.get("collector_output_ready", false)):
		_draw_resource_flow([Vector2(132.0, -124.0), Vector2(114.0, -104.0), Vector2(86.0, -118.0)], AUTO_MINER_ACCENT, active_stage == STAGE_FIELD_PICKUP)
	if bool(path_state.get("inputs_ready", false)):
		_draw_resource_flow([Vector2(86.0, -118.0), Vector2(6.0, -112.0), Vector2(-214.0, -112.0)], CRYSTAL_ACCENT, active_stage in [STAGE_RETURN_TO_BASE, STAGE_BASE_RECEIVING])
		_draw_resource_flow([Vector2(-214.0, -112.0), Vector2(-194.0, -108.0), Vector2(-184.0, -114.0)], REACTOR_ACCENT, active_stage in [STAGE_REACTOR_FEED, STAGE_REACTOR_PROCESSING])
	if bool(path_state.get("reactor_active", false)):
		_draw_processing_core(Vector2(-166.0, -66.0))
	if bool(path_state.get("storage_ready", false)):
		_draw_resource_flow([Vector2(-134.0, -114.0), Vector2(-206.0, 18.0), Vector2(-250.0, 18.0)], PRODUCT_ACCENT, active_stage == STAGE_STORAGE_OUTPUT)
	if bool(path_state.get("outfitting_ready", false)):
		_draw_resource_flow([Vector2(-250.0, 18.0), Vector2(-168.0, 28.0), Vector2(-74.0, -14.0)], OUTFITTING_ACCENT, active_stage == STAGE_OUTFITTING_READY)


func _draw_resource_flow(points: Array, color: Color, is_active: bool) -> void:
	var fill_alpha := 0.13 if is_active else 0.06
	var edge_alpha := 0.36 if is_active else 0.16
	_draw_lane(points, 4.2, Color(color.r, color.g, color.b, fill_alpha), Color(color.r, color.g, color.b, edge_alpha))
	if not is_active:
		return
	for index in range(points.size() - 1):
		var from: Vector2 = points[index]
		var to: Vector2 = points[index + 1]
		for ratio in [0.38, 0.68]:
			var center := from.lerp(to, ratio)
			draw_circle(center, 3.0, Color(color.r, color.g, color.b, 0.58))


func _draw_processing_core(center: Vector2) -> void:
	draw_circle(center, 12.0, Color(REACTOR_ACCENT.r, REACTOR_ACCENT.g, REACTOR_ACCENT.b, 0.1))
	draw_arc(center, 17.0, PI * 0.08, PI * 1.86, 32, Color(REACTOR_ACCENT.r, REACTOR_ACCENT.g, REACTOR_ACCENT.b, 0.42), 1.8, true)
	draw_arc(center, 23.0, PI * 0.42, PI * 1.28, 22, Color(STATUS_ACTIVE_LIGHT.r, STATUS_ACTIVE_LIGHT.g, STATUS_ACTIVE_LIGHT.b, 0.38), 1.2, true)


func _draw_status_light_strip(origin: Vector2, state: String, accent: Color) -> void:
	var panel := Rect2(origin, Vector2(34.0, 10.0))
	draw_rect(panel, Color(0.01, 0.018, 0.016, 0.74), true)
	draw_rect(panel, Color(accent.r, accent.g, accent.b, 0.2), false, 1.0, true)
	var lit_count := _get_status_lit_count(state)
	var light_color := _get_status_light_color(state, accent)
	for index in range(3):
		var center := origin + Vector2(7.0 + float(index) * 10.0, 5.0)
		var color := light_color if index < lit_count else STATUS_IDLE_LIGHT
		draw_circle(center, 2.8, color)
	if _is_active_device_state(state):
		draw_arc(origin + Vector2(17.0, 5.0), 22.0, 0.0, TAU, 28, Color(light_color.r, light_color.g, light_color.b, 0.24), 1.1, true)


func _draw_material_slot(rect: Rect2, color: Color, is_filled: bool) -> void:
	draw_rect(rect, Color(0.01, 0.018, 0.016, 0.62), true)
	if is_filled:
		draw_rect(rect.grow(-2.0), Color(color.r, color.g, color.b, 0.34), true)
	draw_rect(rect, Color(color.r, color.g, color.b, 0.28 if is_filled else 0.12), false, 1.0, true)


func _get_status_lit_count(state: String) -> int:
	match state:
		STATUS_LOCKED:
			return 0
		STATUS_RUNNING, STATUS_PROCESSING:
			return 3
		STATUS_BUILD_READY, STATUS_OUTPUT_READY, STATUS_LOADED, STATUS_INPUT_READY, STATUS_PRODUCT_READY, STATUS_SUPPLY_READY:
			return 2
		_:
			return 1


func _get_status_light_color(state: String, accent: Color) -> Color:
	match state:
		STATUS_RUNNING, STATUS_PROCESSING:
			return STATUS_ACTIVE_LIGHT
		STATUS_PRODUCT_READY, STATUS_SUPPLY_READY:
			return STATUS_OUTPUT_LIGHT
		STATUS_BUILD_READY, STATUS_OUTPUT_READY, STATUS_LOADED, STATUS_INPUT_READY:
			return STATUS_READY_LIGHT
		STATUS_LOCKED:
			return STATUS_IDLE_LIGHT
		_:
			return Color(accent.r, accent.g, accent.b, 0.34)


func _is_active_device_state(state: String) -> bool:
	return state == STATUS_RUNNING or state == STATUS_PROCESSING


func _draw_path_state() -> void:
	if path_state.is_empty():
		return
	var active_stage := get_active_stage()
	_draw_ready_pip(Vector2(84.0, -100.0), bool(path_state.get("crystal_ready", false)), active_stage == STAGE_FIELD_PICKUP)
	_draw_ready_pip(Vector2(132.0, -124.0), bool(path_state.get("crystal_ready", false)), active_stage == STAGE_FIELD_PICKUP or active_stage == STAGE_RETURN_TO_BASE)
	_draw_ready_pip(Vector2(132.0, -146.0), bool(path_state.get("collector_build_ready", false)), active_stage == STAGE_FIELD_PICKUP)
	_draw_ready_pip(Vector2(86.0, -118.0), bool(path_state.get("collector_output_ready", false)), active_stage == STAGE_FIELD_PICKUP)
	_draw_ready_pip(Vector2(54.0, 112.0), bool(path_state.get("salvage_ready", false)), active_stage == STAGE_FIELD_PICKUP)
	_draw_ready_pip(Vector2(-214.0, -112.0), bool(path_state.get("inputs_ready", false)), active_stage == STAGE_RETURN_TO_BASE or active_stage == STAGE_BASE_RECEIVING)
	_draw_ready_pip(Vector2(-184.0, -114.0), bool(path_state.get("inputs_ready", false)), active_stage == STAGE_REACTOR_FEED)
	_draw_ready_pip(Vector2(-166.0, -66.0), bool(path_state.get("reactor_active", false)), active_stage == STAGE_REACTOR_PROCESSING)
	_draw_ready_pip(Vector2(-250.0, 18.0), bool(path_state.get("storage_ready", false)), active_stage == STAGE_STORAGE_OUTPUT)
	_draw_ready_pip(Vector2(-74.0, -14.0), bool(path_state.get("outfitting_ready", false)), active_stage == STAGE_OUTFITTING_READY)


func _draw_ready_pip(position: Vector2, is_ready: bool, is_active: bool) -> void:
	var pip_color := SIGNAL_ACCENT if is_active else COMPLETE_DOT if is_ready else READY_DIM
	var radius := 6.8 if is_active else 4.6
	draw_circle(position, radius, pip_color)
	if is_active:
		draw_arc(position, 12.0, 0.0, TAU, 24, SIGNAL_ACCENT, 1.6, true)


func _draw_resource_pad(center: Vector2, color: Color, is_crystal: bool) -> void:
	var pad := Rect2(center + Vector2(-26.0, -20.0), Vector2(52.0, 40.0))
	draw_rect(pad, CONTEXT_FILL, true)
	draw_rect(pad, Color(color.r, color.g, color.b, 0.22), false, 1.4, true)
	if is_crystal:
		draw_line(center + Vector2(-18.0, 12.0), center + Vector2(20.0, -14.0), Color(color.r, color.g, color.b, 0.18), 1.4, true)
	else:
		draw_line(center + Vector2(-18.0, -12.0), center + Vector2(18.0, 12.0), Color(color.r, color.g, color.b, 0.16), 1.4, true)


func _draw_hand_sample_point(center: Vector2) -> void:
	draw_circle(center, 9.0, Color(HAND_SAMPLE_ACCENT.r, HAND_SAMPLE_ACCENT.g, HAND_SAMPLE_ACCENT.b, 0.12))
	draw_arc(center, 13.0, -0.2, PI * 1.55, 26, HAND_SAMPLE_ACCENT, 1.4, true)
	draw_line(center + Vector2(-8.0, 6.0), center + Vector2(8.0, -8.0), HAND_SAMPLE_ACCENT, 1.8, true)
	draw_circle(center + Vector2(8.0, -8.0), 3.0, Color(HAND_SAMPLE_ACCENT.r, HAND_SAMPLE_ACCENT.g, HAND_SAMPLE_ACCENT.b, 0.72))


func _draw_auto_miner_workface(center: Vector2) -> void:
	var base := Rect2(center + Vector2(-8.0, -12.0), Vector2(38.0, 24.0))
	draw_rect(base, Color(0.04, 0.08, 0.075, 0.72), true)
	draw_rect(base, Color(AUTO_MINER_ACCENT.r, AUTO_MINER_ACCENT.g, AUTO_MINER_ACCENT.b, 0.34), false, 1.4, true)
	for leg in [Vector2(-12.0, 12.0), Vector2(30.0, 12.0), Vector2(-12.0, -12.0)]:
		draw_line(center + leg, center + leg + Vector2(-10.0 if leg.x < 0.0 else 10.0, 18.0 if leg.y > 0.0 else -18.0), Color(AUTO_MINER_ACCENT.r, AUTO_MINER_ACCENT.g, AUTO_MINER_ACCENT.b, 0.24), 2.0, true)
	draw_arc(center + Vector2(10.0, -2.0), 18.0, PI * 0.12, PI * 1.78, 30, Color(AUTO_MINER_ACCENT.r, AUTO_MINER_ACCENT.g, AUTO_MINER_ACCENT.b, 0.42), 2.2, true)
	draw_line(center + Vector2(24.0, -2.0), center + Vector2(42.0, -18.0), Color(AUTO_MINER_ACCENT.r, AUTO_MINER_ACCENT.g, AUTO_MINER_ACCENT.b, 0.34), 2.0, true)
	var output := Rect2(center + Vector2(-58.0, -2.0), Vector2(28.0, 14.0))
	draw_rect(output, WORKFACE_DARK, true)
	draw_rect(output, Color(AUTO_MINER_ACCENT.r, AUTO_MINER_ACCENT.g, AUTO_MINER_ACCENT.b, 0.34), false, 1.2, true)
	draw_line(center + Vector2(-8.0, 2.0), center + Vector2(-30.0, 4.0), Color(AUTO_MINER_ACCENT.r, AUTO_MINER_ACCENT.g, AUTO_MINER_ACCENT.b, 0.26), 2.0, true)


func _draw_crystal_shard(center: Vector2, scale: float) -> void:
	var shard := PackedVector2Array([
		center + Vector2(0.0, -12.0) * scale,
		center + Vector2(8.0, -2.0) * scale,
		center + Vector2(4.0, 11.0) * scale,
		center + Vector2(-8.0, 8.0) * scale,
		center + Vector2(-10.0, -4.0) * scale,
		center + Vector2(0.0, -12.0) * scale
	])
	draw_colored_polygon(shard, Color(CRYSTAL_ACCENT.r, CRYSTAL_ACCENT.g, CRYSTAL_ACCENT.b, 0.1))
	draw_polyline(shard, Color(CRYSTAL_ACCENT.r, CRYSTAL_ACCENT.g, CRYSTAL_ACCENT.b, 0.28), 1.2, true)


func _draw_lane(points: Array, width: float, fill_color: Color, edge_color: Color) -> void:
	var vector_points := PackedVector2Array()
	for point in points:
		vector_points.append(point)
	draw_polyline(vector_points, PATH_DARK, width + 6.0, true)
	draw_polyline(vector_points, fill_color, width, true)
	draw_polyline(vector_points, edge_color, 2.0, true)


func _is_base_handoff_state() -> bool:
	var active_stage := get_active_stage()
	return active_stage in [
		STAGE_BASE_RECEIVING,
		STAGE_REACTOR_FEED,
		STAGE_REACTOR_PROCESSING,
		STAGE_STORAGE_OUTPUT,
		STAGE_OUTFITTING_READY
	]


func _register_path_shapes() -> void:
	path_shape_ids = [
		"first_path.workspace_focus_wash",
		"first_path.context_side_falloff",
		"first_path.primary_player_lane",
		"first_path.base_handoff_compact_lane",
		"first_path.local_material_patches",
		"first_path.field_workspots_hidden_during_base_handoff",
		"first_path.crystal_cut_workface",
		"first_path.hand_sample_point",
		"first_path.auto_miner_workface",
		"first_path.auto_miner_output_tray",
		"first_path.salvage_sorting_workface",
		"first_path.crystal_pickup_pad",
		"first_path.salvage_pickup_pad",
		"first_path.salvage_spur_lane",
		"first_path.base_receiving_bay",
		"first_path.base_receiving_logistics_port",
		"first_path.reactor_input_workbench",
		"first_path.reactor_feed_hopper",
		"first_path.reactor_work_window",
		"first_path.storage_output_bins",
		"first_path.storage_output_shelf",
		"first_path.outfitting_departure_port",
		"first_path.outfitting_handoff_rack",
		"first_path.departure_supply_bus",
		"first_path.context_clarity_mask",
		"first_path.stage_feedback_lane",
		"first_path.stage_feedback_station",
		"first_path.collector_output_local_signal",
		"first_path.handoff_port_chain",
		"first_path.operation_relation.collector_to_receiving",
		"first_path.operation_relation.salvage_to_receiving",
		"first_path.operation_relation.receiving_to_reactor",
		"first_path.operation_relation.reactor_to_storage",
		"first_path.operation_relation.storage_to_outfitting",
		"first_path.operation_relation.compact_base_handoff_tracks",
		"first_path.operation_relation.long_field_tracks_deemphasized",
		"first_path.operation_relation.device_role_ports",
		"first_path.single_signal_stage",
		"first_path.operation_state_pips",
		"first_path.device_status_lights",
		"first_path.resource_flow_packets",
		"first_path.material_state_slots"
	]
	path_shape_ids.append_array(HandoffArtPass.get_path_shape_ids())
	path_shape_ids.append_array(AssetLanguageArtPass.get_base_shape_ids())


func _register_path_state_shape(shape_id: String) -> void:
	if path_state_shape_ids.has(shape_id):
		return
	path_state_shape_ids.append(shape_id)


func _quiet_global_planning_layers() -> void:
	_set_context_layers_muted(is_first_path_visible_at(_get_player_position()))


func _set_context_layers_muted(should_mute: bool) -> void:
	if not should_mute:
		_restore_context_layers()
		return
	muted_planning_layer_count = 0
	for layer_profile in FIRST_PATH_CONTEXT_LAYER_ALPHAS:
		var path := String(layer_profile.get("path", ""))
		var alpha := float(layer_profile.get("alpha", 1.0))
		if _apply_layer_alpha(path, alpha):
			muted_planning_layer_count += 1


func _mute_first_path_context_rects(should_mute: bool) -> void:
	muted_context_rect_count = 0
	if not should_mute:
		return
	muted_context_rect_count += _mute_context_rect("RegionBase", 0.004)
	muted_context_rect_count += _mute_context_rect("RegionCrystal", 0.003)
	muted_context_rect_count += _mute_context_rect("RegionPollution", 0.0006)
	for path in FIRST_PATH_CONTEXT_ROUTE_PATHS:
		muted_context_rect_count += _mute_context_rect(String(path), FIRST_PATH_CONTEXT_ROUTE_ALPHA)
	for path in FIRST_PATH_CONTEXT_BOUNDARY_PATHS:
		muted_context_rect_count += _mute_context_rect(String(path), FIRST_PATH_CONTEXT_BOUNDARY_ALPHA)


func _mute_context_rect(path: String, alpha: float) -> int:
	var rect := _get_map_node(path) as ColorRect
	if rect == null:
		return 0
	var color := rect.color
	color.a = minf(color.a, alpha)
	rect.color = color
	return 1


func _mute_first_path_context_interactable_markers(should_mute: bool, player_position: Vector2) -> void:
	muted_context_marker_count = 0
	if not should_mute:
		return
	var interactables := _get_map_node("Interactables")
	if interactables == null:
		return
	for child in interactables.get_children():
		var interactable := child as PrototypeInteractable
		if interactable == null:
			continue
		var marker := interactable.marker
		if marker == null:
			marker = interactable.get_node_or_null("Marker") as ColorRect
		if marker == null:
			continue
		if _is_first_path_local_marker(interactable, player_position):
			continue
		var marker_modulate := marker.modulate
		marker_modulate.a = minf(marker_modulate.a, FIRST_PATH_CONTEXT_MARKER_ALPHA)
		marker.modulate = marker_modulate
		marker.scale = Vector2.ONE
		var label := interactable.get_node_or_null("Label") as Label
		if label != null:
			label.visible = false
		var focus_ring := interactable.get_node_or_null("FocusRing") as ColorRect
		if focus_ring != null:
			focus_ring.visible = false
		muted_context_marker_count += 1


func _is_first_path_local_marker(interactable: PrototypeInteractable, player_position: Vector2) -> bool:
	if not FIRST_PATH_LOCAL_INTERACTABLE_DEFINITION_IDS.has(interactable.definition_id):
		return false
	return interactable.position.distance_to(player_position) <= FIRST_PATH_LOCAL_MARKER_DISTANCE


func _apply_layer_alpha(path: String, alpha: float) -> bool:
	var node := _get_map_node(path)
	var canvas_item := node as CanvasItem
	if canvas_item == null:
		return false
	if not context_layer_original_modulates.has(path):
		context_layer_original_modulates[path] = canvas_item.modulate
	var original_color: Color = context_layer_original_modulates.get(path, canvas_item.modulate)
	var color := original_color
	color.a = minf(original_color.a, alpha)
	canvas_item.modulate = color
	return true


func _restore_context_layers() -> void:
	for path in context_layer_original_modulates.keys():
		var node := _get_map_node(String(path))
		var canvas_item := node as CanvasItem
		if canvas_item != null:
			canvas_item.modulate = context_layer_original_modulates[path]
	context_layer_original_modulates.clear()
	muted_planning_layer_count = 0
	muted_context_rect_count = 0
	muted_context_marker_count = 0


func _restore_context_layer(path: String) -> void:
	if not context_layer_original_modulates.has(path):
		return
	var node := _get_map_node(path)
	var canvas_item := node as CanvasItem
	if canvas_item != null:
		canvas_item.modulate = context_layer_original_modulates[path]
	context_layer_original_modulates.erase(path)


func _is_crystal_local_focus_position(player_position: Vector2) -> bool:
	return player_position.x >= CRYSTAL_LOCAL_FOCUS_MIN_X and player_position.x <= FOCUS_MAX_X


func _get_base_structure_for_definition(world_state: WorldState, building_id: String) -> Dictionary:
	for structure in world_state.base_structures.values():
		if not structure is Dictionary:
			continue
		if String(structure.get("definition_id", "")) == building_id:
			return structure
	return {}


func _resolve_collector_device_state(collector_built: bool, collector_build_ready: bool, collector_output_ready: bool) -> String:
	if collector_output_ready:
		return STATUS_OUTPUT_READY
	if collector_built:
		return STATUS_RUNNING
	if collector_build_ready:
		return STATUS_BUILD_READY
	return STATUS_WAITING


func _resolve_reactor_device_state(inputs_ready: bool, reactor_active: bool, storage_ready: bool) -> String:
	if reactor_active:
		return STATUS_PROCESSING
	if storage_ready:
		return STATUS_PRODUCT_READY
	if inputs_ready:
		return STATUS_INPUT_READY
	return STATUS_WAITING


func _resolve_outfitting_device_state(world_state: WorldState, outfitting_ready: bool) -> String:
	if outfitting_ready:
		return STATUS_SUPPLY_READY
	if world_state.has_base_structure_definition("building.field_outfitting_station"):
		return STATUS_WAITING
	return STATUS_LOCKED


func _register_device_state_shapes() -> void:
	_register_path_state_shape("first_path.device.collector.%s" % String(path_state.get("collector_device_state", STATUS_WAITING)))
	_register_path_state_shape("first_path.device.receiving.%s" % String(path_state.get("receiving_device_state", STATUS_WAITING)))
	_register_path_state_shape("first_path.device.reactor.%s" % String(path_state.get("reactor_device_state", STATUS_WAITING)))
	_register_path_state_shape("first_path.device.storage.%s" % String(path_state.get("storage_device_state", STATUS_WAITING)))
	_register_path_state_shape("first_path.device.outfitting.%s" % String(path_state.get("outfitting_device_state", STATUS_LOCKED)))


func _register_resource_flow_shapes() -> void:
	if bool(path_state.get("collector_output_ready", false)):
		_register_path_state_shape("first_path.flow.auto_miner_to_tray.ready")
	if bool(path_state.get("inputs_ready", false)):
		_register_path_state_shape("first_path.flow.field_to_receiving.ready")
		_register_path_state_shape("first_path.flow.receiving_to_reactor.ready")
	if bool(path_state.get("reactor_active", false)):
		_register_path_state_shape("first_path.flow.reactor_processing.active")
	if bool(path_state.get("storage_ready", false)):
		_register_path_state_shape("first_path.flow.reactor_to_storage.ready")
	if bool(path_state.get("outfitting_ready", false)):
		_register_path_state_shape("first_path.flow.storage_to_outfitting.ready")
	for shape_id in HandoffArtPass.get_state_shape_ids(path_state):
		_register_path_state_shape(shape_id)


func _has_first_path_output_context(world_state: WorldState) -> bool:
	var reactor_state := _get_base_structure_for_definition(world_state, "building.basic_reactor")
	var last_recipe_id := String(reactor_state.get("last_recipe_id", ""))
	return (
		last_recipe_id in ["recipe.process_crystal_ore", "recipe.repair_gel"]
		or _has_repair_gel_output_context(world_state)
	)


func _is_first_path_available(world_state: WorldState) -> bool:
	return world_state != null and world_state.quest_state.has_completed_quest("quest.restore_outpost")


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
		if _is_near_reactor_feed(character_state.position):
			return STAGE_REACTOR_FEED
		return STAGE_BASE_RECEIVING
	if outfitting_ready:
		return STAGE_OUTFITTING_READY
	if storage_ready:
		return STAGE_STORAGE_OUTPUT
	return STAGE_FIELD_PICKUP


func _is_near_reactor_feed(position: Vector2) -> bool:
	return position.distance_to(Vector2(-166.0, -66.0)) <= 72.0


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
