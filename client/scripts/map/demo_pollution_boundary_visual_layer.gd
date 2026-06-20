extends Node2D
class_name DemoPollutionBoundaryVisualLayer

const ROLE_BOUNDARY := "boundary"
const ROLE_FILTER_SITE := "filter_site"
const ROLE_RESIDUE := "residue"
const ROLE_ROUTE := "route"
const ROLE_PRESSURE_GATE := "pressure_gate"
const FOCUS_VISIBLE_MIN_X := 180.0

const FIELD_FILL := Color(0.1, 0.12, 0.07, 0.18)
const FIELD_LINE := Color(0.72, 0.72, 0.3, 0.34)
const CONSTRUCTION_FILL := Color(0.13, 0.18, 0.13, 0.28)
const CONSTRUCTION_LINE := Color(0.62, 0.72, 0.54, 0.58)
const FILTER_LINE := Color(0.8, 0.88, 0.3, 0.86)
const FILTER_FILL := Color(0.25, 0.34, 0.1, 0.44)
const RESIDUE_LINE := Color(0.84, 0.74, 0.23, 0.78)
const RESIDUE_FILL := Color(0.52, 0.44, 0.08, 0.3)
const DANGER_LINE := Color(0.94, 0.48, 0.18, 0.8)
const DANGER_FILL := Color(0.42, 0.18, 0.08, 0.16)
const ROUTE_TO_FILTER := Color(0.88, 0.7, 0.26, 0.74)
const ROUTE_TO_BASE := Color(0.66, 0.86, 0.52, 0.72)
const SLURRY_ROUTE := Color(0.78, 0.42, 0.18, 0.58)
const GATE_CORE := Color(0.72, 0.46, 0.88, 0.78)
const CHAIN_DIM := Color(0.24, 0.28, 0.16, 0.36)
const CHAIN_WINDOW := Color(1.0, 0.62, 0.24, 0.78)
const CHAIN_ROUTE_DARK := Color(0.03, 0.04, 0.03, 0.58)
const CHAIN_VIAL := Color(0.72, 0.92, 0.38, 0.86)
const CHAIN_SLURRY := Color(0.82, 0.42, 0.18, 0.78)
const CHAIN_CORE_PREP := Color(0.74, 0.58, 0.9, 0.84)

const LEGACY_POLLUTION_PANELS := [
	"PollutionConstructionYardGround",
	"PollutionEntryPressureGround",
	"PollutionDeepResidueField",
	"PollutionReturnDrainField",
	"PollutionSafeConstructionBelt",
	"PollutionConstructionObjectBand",
	"PollutionDangerField",
	"PollutionResidueObjectPocket",
	"PollutionVialReturnPocket",
	"PollutionSlurryReturnPocket",
	"PollutionVialReservePocket",
	"PollutionCoreArchiveRoutePocket",
	"PollutionCoreArchiveReturnPocket",
	"PollutionCoreArchivePressureRetestPocket",
	"PollutionLogisticsMaintenanceRetestPocket",
	"PollutionGatePressurePocket"
]

const LEGACY_POLLUTION_MARKERS := [
	"PollutionFoundationNorthMarker",
	"PollutionFoundationSouthMarker",
	"PollutionFilterObjectMarker",
	"PollutionDangerBoundaryLine",
	"PollutionConstructionToDangerStep",
	"PollutionEntryResidueMarker",
	"PollutionEntryPressureMarker",
	"PollutionPressureRouteLine",
	"PollutionVialReturnSpurLine",
	"PollutionVialReturnResidueMarker",
	"PollutionVialReturnGuardMarker",
	"PollutionSlurryReturnSpurLine",
	"PollutionSlurryReturnResidueMarker",
	"PollutionSlurryReturnGuardMarker",
	"PollutionVialReserveSpurLine",
	"PollutionVialReserveResidueMarker",
	"PollutionVialReserveGuardMarker",
	"PollutionCoreArchiveRouteLine",
	"PollutionCoreArchiveRouteResidueMarker",
	"PollutionCoreArchiveRouteGuardMarker",
	"PollutionCoreArchiveResidueMarker",
	"PollutionCoreArchiveGuardMarker",
	"PollutionCoreArchivePressureRetestLine",
	"PollutionCoreArchivePressureRetestResidueMarker",
	"PollutionCoreArchivePressureRetestGuardMarker",
	"PollutionLogisticsMaintenanceRetestLine",
	"PollutionLogisticsMaintenanceRetestResidueMarker",
	"PollutionLogisticsMaintenanceRetestGuardMarker",
	"PollutionGatePressureMarker"
]

const POLLUTION_INTERACTABLE_DEFINITION_IDS := {
	"map_object.pollution_residue_patch": true,
	"building.pollution_filter": true,
	"building.foundation_t1": true,
	"map_object.rough_ground": true,
	"map_object.ruin_gate": true
}

const POLLUTION_ANCHOR_PATHS := {
	"Interactables/PollutionFilterBuildSite": ROLE_FILTER_SITE,
	"Interactables/PollutionFilter": ROLE_FILTER_SITE,
	"Interactables/PollutionResidue": ROLE_RESIDUE,
	"Interactables/PollutionResidueOuterPocket": ROLE_RESIDUE,
	"Interactables/PollutionResidueSlurryReturnCache": ROLE_RESIDUE,
	"Interactables/RuinGate": ROLE_PRESSURE_GATE
}

var boundary_shape_ids: Array[String] = []
var flow_shape_ids: Array[String] = []
var pollution_chain_shape_ids: Array[String] = []
var muted_legacy_block_count := 0
var muted_interactable_marker_count := 0
var applied_pollution_chain_state_count := 0
var pollution_chain_state: Dictionary = {}


func _ready() -> void:
	apply_visuals()
	refresh_focus_visibility(_get_player_position())


func _process(_delta: float) -> void:
	refresh_focus_visibility(_get_player_position())
	_tone_down_pollution_interactable_markers()


func apply_visuals() -> void:
	_register_boundary_shapes()
	_register_flow_shapes()
	_deemphasize_legacy_pollution_blocks()
	_mute_pollution_identity_shapes()
	_tag_pollution_anchors()
	_tone_down_pollution_interactable_markers()
	queue_redraw()


func refresh_pollution_chain_state(world_state: WorldState, character_state: CharacterState) -> void:
	pollution_chain_shape_ids.clear()
	applied_pollution_chain_state_count = 0
	if world_state == null or character_state == null:
		pollution_chain_state.clear()
		queue_redraw()
		return
	var inventory := character_state.inventory
	if not _has_pollution_chain_context(world_state, inventory):
		pollution_chain_state.clear()
		queue_redraw()
		return
	var filter_state := _get_base_structure_for_definition(world_state, "building.pollution_filter")
	var reactor_state := _get_base_structure_for_definition(world_state, "building.basic_reactor")
	var filter_active := (
		String(filter_state.get("status", "")) == "in_progress"
		and String(filter_state.get("active_recipe_id", "")) == "recipe.cleanse_residue"
	)
	var reclaim_active := (
		String(reactor_state.get("status", "")) == "in_progress"
		and String(reactor_state.get("active_recipe_id", "")) == "recipe.reclaim_basic_parts"
	)
	var core_prep_active := (
		String(reactor_state.get("status", "")) == "in_progress"
		and String(reactor_state.get("active_recipe_id", "")) == "recipe.core_stabilization_buffer"
	)
	var residue_ready := inventory.has_ref("item.polluted_residue", 2)
	var vial_ready := inventory.has_ref("item.resistance_vial_t1", 1)
	var slurry_ready := inventory.has_ref("fluid.polluted_slurry", 1.0)
	var core_prep_ready := (
		inventory.has_ref("item.repair_gel", 1)
		and inventory.has_ref("item.resistance_vial_t1", 1)
		and inventory.has_ref("fluid.polluted_slurry", 1.0)
		and inventory.has_ref("item.basic_parts", 2)
	)
	pollution_chain_state = {
		"residue_ready": residue_ready,
		"filter_ready": world_state.has_base_structure_definition("building.pollution_filter") and residue_ready,
		"filter_active": filter_active,
		"vial_ready": vial_ready,
		"slurry_ready": slurry_ready,
		"recycle_ready": slurry_ready and world_state.has_base_structure_definition("building.basic_reactor"),
		"reclaim_active": reclaim_active,
		"core_prep_ready": core_prep_ready,
		"core_prep_active": core_prep_active
	}
	_register_pollution_chain_shape("pollution_chain.boundary_residue_queue.%s" % _state_suffix(residue_ready))
	_register_pollution_chain_shape("pollution_chain.boundary_filter_window.%s" % _state_suffix(filter_active))
	_register_pollution_chain_shape("pollution_chain.boundary_vial_output.%s" % _state_suffix(vial_ready))
	_register_pollution_chain_shape("pollution_chain.boundary_slurry_output.%s" % _state_suffix(slurry_ready))
	_register_pollution_chain_shape("pollution_chain.boundary_base_return_route.%s" % _state_suffix(vial_ready or filter_active))
	_register_pollution_chain_shape("pollution_chain.boundary_slurry_split_route.%s" % _state_suffix(slurry_ready or filter_active))
	_register_pollution_chain_shape("pollution_chain.boundary_recycle_route.%s" % _state_suffix(bool(pollution_chain_state["recycle_ready"]) or reclaim_active))
	_register_pollution_chain_shape("pollution_chain.boundary_core_prep_route.%s" % _state_suffix(core_prep_ready or core_prep_active))
	queue_redraw()


func get_boundary_shape_count() -> int:
	return boundary_shape_ids.size()


func get_flow_count() -> int:
	return flow_shape_ids.size()


func get_muted_legacy_block_count() -> int:
	return muted_legacy_block_count


func get_muted_interactable_marker_count() -> int:
	return muted_interactable_marker_count


func has_boundary_shape(shape_id: String) -> bool:
	return boundary_shape_ids.has(shape_id)


func has_flow_shape(shape_id: String) -> bool:
	return flow_shape_ids.has(shape_id)


func get_pollution_chain_state_shape_count() -> int:
	return applied_pollution_chain_state_count


func has_pollution_chain_shape(shape_id: String) -> bool:
	return pollution_chain_shape_ids.has(shape_id)


func refresh_focus_visibility(player_position: Vector2) -> void:
	visible = player_position.x >= FOCUS_VISIBLE_MIN_X


func _draw() -> void:
	_draw_boundary_field()
	_draw_treatment_routes()
	_draw_filter_construction_site()
	_draw_residue_patches()
	_draw_pressure_gate()
	_draw_pollution_chain_state()


func _draw_boundary_field() -> void:
	var construction_rect := Rect2(Vector2(246.0, -254.0), Vector2(122.0, 160.0))
	var danger_rect := Rect2(Vector2(246.0, -32.0), Vector2(136.0, 272.0))
	draw_rect(Rect2(Vector2(242.0, -276.0), Vector2(144.0, 520.0)), FIELD_FILL, true)
	draw_rect(Rect2(Vector2(242.0, -276.0), Vector2(144.0, 520.0)), FIELD_LINE, false, 1.8, true)
	draw_rect(construction_rect, CONSTRUCTION_FILL, true)
	draw_rect(construction_rect, CONSTRUCTION_LINE, false, 2.0, true)
	draw_rect(danger_rect, DANGER_FILL, true)
	_draw_hazard_boundary(Vector2(242.0, -38.0), Vector2(384.0, -38.0))
	for x in [260.0, 298.0, 336.0]:
		draw_line(Vector2(x, -244.0), Vector2(x, -104.0), Color(0.58, 0.68, 0.52, 0.18), 1.4, true)
	for y in [36.0, 104.0, 172.0, 226.0]:
		draw_line(Vector2(250.0, y), Vector2(376.0, y), Color(0.58, 0.5, 0.14, 0.18), 1.2, true)


func _draw_treatment_routes() -> void:
	_draw_route([Vector2(258.0, 34.0), Vector2(278.0, -12.0), Vector2(298.0, -72.0)], ROUTE_TO_FILTER, 3.4)
	_draw_route([Vector2(344.0, 158.0), Vector2(330.0, 78.0), Vector2(306.0, -70.0)], SLURRY_ROUTE, 2.8)
	_draw_route([Vector2(298.0, -110.0), Vector2(222.0, -108.0), Vector2(118.0, -86.0), Vector2(-44.0, -44.0)], ROUTE_TO_BASE, 3.2)
	_draw_route([Vector2(304.0, 96.0), Vector2(314.0, 152.0), Vector2(336.0, 206.0)], SLURRY_ROUTE, 2.5)
	_draw_route([Vector2(342.0, 24.0), Vector2(382.0, 24.0)], DANGER_LINE, 3.0)
	for point in [Vector2(298.0, -72.0), Vector2(222.0, -108.0), Vector2(304.0, 96.0), Vector2(382.0, 24.0)]:
		draw_circle(point, 4.2, Color(0.88, 0.86, 0.48, 0.62))


func _draw_filter_construction_site() -> void:
	draw_rect(Rect2(Vector2(252.0, -126.0), Vector2(34.0, 34.0)), Color(0.2, 0.26, 0.18, 0.34), true)
	draw_rect(Rect2(Vector2(252.0, -126.0), Vector2(34.0, 34.0)), CONSTRUCTION_LINE, false, 1.8, true)
	draw_rect(Rect2(Vector2(318.0, -126.0), Vector2(34.0, 34.0)), Color(0.2, 0.26, 0.18, 0.34), true)
	draw_rect(Rect2(Vector2(318.0, -126.0), Vector2(34.0, 34.0)), CONSTRUCTION_LINE, false, 1.8, true)
	draw_rect(Rect2(Vector2(280.0, -140.0), Vector2(38.0, 66.0)), FILTER_FILL, true)
	draw_rect(Rect2(Vector2(280.0, -140.0), Vector2(38.0, 66.0)), FILTER_LINE, false, 2.2, true)
	draw_line(Vector2(290.0, -130.0), Vector2(290.0, -84.0), FILTER_LINE, 3.8, true)
	draw_line(Vector2(306.0, -130.0), Vector2(306.0, -84.0), FILTER_LINE, 3.8, true)
	draw_line(Vector2(284.0, -74.0), Vector2(314.0, -74.0), Color(0.92, 0.78, 0.28, 0.74), 3.0, true)
	draw_circle(Vector2(298.0, -148.0), 5.0, Color(0.9, 0.92, 0.38, 0.78))


func _draw_residue_patches() -> void:
	_draw_residue_patch(Vector2(258.0, 34.0), 1.0)
	_draw_residue_patch(Vector2(304.0, 96.0), 0.9)
	_draw_residue_patch(Vector2(276.0, 146.0), 0.82)
	_draw_residue_patch(Vector2(354.0, 176.0), 0.86)
	_draw_residue_patch(Vector2(260.0, 188.0), 0.72)
	_draw_residue_patch(Vector2(322.0, 206.0), 0.72)
	_draw_pressure_vent(Vector2(350.0, 116.0), 0.86)
	_draw_pressure_vent(Vector2(362.0, 38.0), 0.74)


func _draw_pressure_gate() -> void:
	draw_rect(Rect2(Vector2(374.0, -28.0), Vector2(12.0, 112.0)), Color(0.18, 0.12, 0.22, 0.52), true)
	draw_rect(Rect2(Vector2(374.0, -28.0), Vector2(12.0, 112.0)), GATE_CORE, false, 2.0, true)
	draw_line(Vector2(366.0, -18.0), Vector2(386.0, -18.0), GATE_CORE, 2.4, true)
	draw_line(Vector2(366.0, 24.0), Vector2(386.0, 24.0), GATE_CORE, 2.4, true)
	draw_line(Vector2(366.0, 66.0), Vector2(386.0, 66.0), GATE_CORE, 2.4, true)
	draw_circle(Vector2(372.0, 24.0), 5.2, DANGER_LINE)


func _draw_pollution_chain_state() -> void:
	if pollution_chain_state.is_empty():
		return
	var residue_ready := bool(pollution_chain_state.get("residue_ready", false))
	var filter_ready := bool(pollution_chain_state.get("filter_ready", false))
	var filter_active := bool(pollution_chain_state.get("filter_active", false))
	var vial_ready := bool(pollution_chain_state.get("vial_ready", false))
	var slurry_ready := bool(pollution_chain_state.get("slurry_ready", false))
	var recycle_ready := bool(pollution_chain_state.get("recycle_ready", false))
	var reclaim_active := bool(pollution_chain_state.get("reclaim_active", false))
	var core_prep_ready := bool(pollution_chain_state.get("core_prep_ready", false))
	var core_prep_active := bool(pollution_chain_state.get("core_prep_active", false))
	_draw_chain_slot(Rect2(Vector2(250.0, 18.0), Vector2(30.0, 18.0)), residue_ready, RESIDUE_LINE)
	_draw_chain_flow_band([Vector2(258.0, 34.0), Vector2(278.0, -12.0), Vector2(296.0, -84.0)], residue_ready or filter_ready or filter_active, RESIDUE_LINE, 4.2)
	_draw_boundary_filter_window(filter_ready, filter_active)
	_draw_boundary_output_slot(Rect2(Vector2(320.0, -134.0), Vector2(28.0, 18.0)), vial_ready, CHAIN_VIAL)
	_draw_boundary_output_slot(Rect2(Vector2(320.0, -104.0), Vector2(28.0, 18.0)), slurry_ready, CHAIN_SLURRY)
	_draw_chain_flow_band([Vector2(334.0, -124.0), Vector2(298.0, -110.0), Vector2(222.0, -108.0), Vector2(118.0, -86.0)], vial_ready or filter_active, CHAIN_VIAL, 3.6)
	_draw_chain_flow_band([Vector2(334.0, -96.0), Vector2(314.0, 52.0), Vector2(336.0, 206.0)], slurry_ready or filter_active, CHAIN_SLURRY, 3.4)
	_draw_chain_flow_band([Vector2(336.0, 206.0), Vector2(260.0, 188.0), Vector2(212.0, 136.0)], recycle_ready or reclaim_active, ROUTE_TO_BASE, 3.0)
	_draw_chain_flow_band([Vector2(336.0, 206.0), Vector2(372.0, 176.0), Vector2(382.0, 24.0)], core_prep_ready or core_prep_active, CHAIN_CORE_PREP, 3.0)
	_draw_status_pip(Vector2(258.0, 34.0), residue_ready, RESIDUE_LINE)
	_draw_status_pip(Vector2(300.0, -110.0), filter_active, FILTER_LINE)
	_draw_status_pip(Vector2(350.0, -124.0), vial_ready, CHAIN_VIAL)
	_draw_status_pip(Vector2(350.0, -96.0), slurry_ready, CHAIN_SLURRY)
	_draw_status_pip(Vector2(336.0, 206.0), slurry_ready, CHAIN_SLURRY)
	_draw_status_pip(Vector2(212.0, 136.0), recycle_ready or reclaim_active, ROUTE_TO_BASE)
	_draw_status_pip(Vector2(382.0, 24.0), core_prep_ready or core_prep_active, CHAIN_CORE_PREP)


func _draw_boundary_filter_window(filter_ready: bool, filter_active: bool) -> void:
	var color := FILTER_LINE if filter_active else RESIDUE_LINE
	var window := Rect2(Vector2(286.0, -130.0), Vector2(24.0, 48.0))
	draw_rect(window.grow(4.0), _state_color(color, filter_ready or filter_active, 0.16, 0.05), true)
	draw_rect(window, _state_color(CHAIN_WINDOW, filter_active, 0.5, 0.12), true)
	draw_rect(window, _state_color(color, filter_active, 0.86, 0.26), false, 1.8, true)
	for y in [-122.0, -108.0, -94.0]:
		draw_line(Vector2(290.0, y), Vector2(306.0, y + 7.0), _state_color(color, filter_active, 0.72, 0.16), 1.5, true)


func _draw_boundary_output_slot(rect: Rect2, is_ready: bool, color: Color) -> void:
	_draw_chain_slot(rect, is_ready, color)
	draw_line(rect.position + Vector2(6.0, 5.0), rect.position + Vector2(22.0, 13.0), _state_color(color, is_ready, 0.78, 0.14), 1.8, true)
	draw_line(rect.position + Vector2(22.0, 5.0), rect.position + Vector2(6.0, 13.0), _state_color(color, is_ready, 0.58, 0.1), 1.8, true)


func _draw_chain_slot(rect: Rect2, is_ready: bool, color: Color) -> void:
	draw_rect(rect, Color(0.03, 0.04, 0.025, 0.52), true)
	draw_rect(rect, _state_color(color, is_ready, 0.24, 0.08), true)
	draw_rect(rect, _state_color(color, is_ready, 0.82, 0.22), false, 1.5, true)


func _draw_chain_flow_band(points: Array[Vector2], is_ready: bool, color: Color, width: float) -> void:
	draw_polyline(PackedVector2Array(points), CHAIN_ROUTE_DARK, width + 3.0, true)
	draw_polyline(PackedVector2Array(points), _state_color(color, is_ready, 0.7, 0.14), width, true)
	for point in points:
		draw_circle(point, width * 0.5, _state_color(color, is_ready, 0.72, 0.14))


func _draw_status_pip(position: Vector2, is_ready: bool, color: Color) -> void:
	draw_circle(position, 4.8, color if is_ready else CHAIN_DIM)
	draw_arc(position, 7.6, 0.0, TAU, 20, Color(color.r, color.g, color.b, 0.34), 1.3, true)


func _state_color(color: Color, is_ready: bool, ready_alpha: float, idle_alpha: float) -> Color:
	return Color(color.r, color.g, color.b, ready_alpha if is_ready else idle_alpha)


func _draw_residue_patch(center: Vector2, scale: float) -> void:
	var body := PackedVector2Array([
		center + Vector2(-18.0, 4.0) * scale,
		center + Vector2(-10.0, -12.0) * scale,
		center + Vector2(8.0, -16.0) * scale,
		center + Vector2(20.0, -4.0) * scale,
		center + Vector2(14.0, 12.0) * scale,
		center + Vector2(-12.0, 14.0) * scale,
		center + Vector2(-18.0, 4.0) * scale
	])
	draw_colored_polygon(body, RESIDUE_FILL)
	draw_polyline(body, RESIDUE_LINE, 1.8, true)
	draw_circle(center + Vector2(-4.0, -2.0) * scale, 3.0 * scale, Color(0.9, 0.78, 0.26, 0.62))
	draw_circle(center + Vector2(8.0, 5.0) * scale, 2.4 * scale, Color(0.7, 0.62, 0.18, 0.54))


func _draw_pressure_vent(center: Vector2, scale: float) -> void:
	draw_arc(center, 15.0 * scale, 0.0, TAU, 28, DANGER_LINE, 1.8, true)
	draw_line(center + Vector2(-12.0, 0.0) * scale, center + Vector2(12.0, 0.0) * scale, DANGER_LINE, 2.0, true)
	draw_line(center + Vector2(0.0, -12.0) * scale, center + Vector2(0.0, 12.0) * scale, DANGER_LINE, 2.0, true)


func _draw_hazard_boundary(from: Vector2, to: Vector2) -> void:
	draw_line(from, to, Color(0.08, 0.04, 0.02, 0.58), 6.0, true)
	draw_line(from, to, DANGER_LINE, 3.0, true)
	var x := from.x + 8.0
	while x < to.x - 4.0:
		draw_line(Vector2(x, from.y - 8.0), Vector2(x + 12.0, from.y + 8.0), DANGER_LINE, 1.5, true)
		x += 20.0


func _draw_route(points: Array[Vector2], color: Color, width: float) -> void:
	draw_polyline(PackedVector2Array(points), Color(0.03, 0.04, 0.03, 0.52), width + 2.8, true)
	draw_polyline(PackedVector2Array(points), color, width, true)


func _register_boundary_shapes() -> void:
	boundary_shape_ids = [
		"boundary.construction_yard",
		"boundary.safe_construction_belt",
		"boundary.filter_foundation_slots",
		"boundary.filter_build_site",
		"boundary.hazard_boundary",
		"boundary.danger_field",
		"boundary.pressure_gate",
		"residue.entry_patch",
		"residue.outer_patch",
		"residue.return_cache_patch",
		"residue.slurry_return_patch",
		"residue.core_archive_patch",
		"hazard.pressure_vent"
	]


func _register_flow_shapes() -> void:
	flow_shape_ids = [
		"flow.residue_to_filter",
		"flow.filter_to_base_return",
		"flow.vial_return_route",
		"flow.slurry_return_route",
		"flow.pressure_gate_route"
	]


func _register_pollution_chain_shape(shape_id: String) -> void:
	if pollution_chain_shape_ids.has(shape_id):
		return
	pollution_chain_shape_ids.append(shape_id)
	applied_pollution_chain_state_count = pollution_chain_shape_ids.size()


func _get_base_structure_for_definition(world_state: WorldState, building_id: String) -> Dictionary:
	for structure in world_state.base_structures.values():
		if not structure is Dictionary:
			continue
		if String(structure.get("definition_id", "")) == building_id:
			return structure
	return {}


func _has_pollution_chain_context(world_state: WorldState, inventory: InventoryState) -> bool:
	if world_state == null or inventory == null:
		return false
	if (
		inventory.has_ref("item.polluted_residue", 1)
		or inventory.has_ref("item.resistance_vial_t1", 1)
		or inventory.has_ref("fluid.polluted_slurry", 1.0)
		or _is_recipe_active(world_state, "building.pollution_filter", "recipe.cleanse_residue")
		or _is_recipe_active(world_state, "building.basic_reactor", "recipe.reclaim_basic_parts")
		or _is_recipe_active(world_state, "building.basic_reactor", "recipe.core_stabilization_buffer")
	):
		return true
	for quest_id in [
		"quest.expand_treatment_point",
		"quest.enter_pollution_edge",
		"quest.unlock_ruin_signal",
		"quest.prepare_demo_stabilization_buffer",
		"quest.write_demo_stabilization_core"
	]:
		if world_state.quest_state.has_active_quest(quest_id):
			return true
	return false


func _is_recipe_active(world_state: WorldState, building_id: String, recipe_id: String) -> bool:
	var structure := _get_base_structure_for_definition(world_state, building_id)
	return (
		String(structure.get("status", "")) == "in_progress"
		and String(structure.get("active_recipe_id", "")) == recipe_id
	)


func _state_suffix(is_ready: bool) -> String:
	return "ready" if is_ready else "idle"


func _deemphasize_legacy_pollution_blocks() -> void:
	muted_legacy_block_count = 0
	var region := _get_map_node("RegionPollution") as ColorRect
	if region != null:
		region.color = Color(0.11, 0.12, 0.07, 0.54)
	var route_band := _get_map_node("DemoRoutePresentationLayer/DemoRoutePollutionBand") as ColorRect
	if route_band != null:
		route_band.color.a = minf(route_band.color.a, 0.08)
	var route_label := _get_map_node("DemoRoutePresentationLayer/DemoRoutePollutionLabel") as Label
	if route_label != null:
		route_label.visible = false

	var layer := _get_map_node("OpeningSceneLayer")
	if layer == null:
		return
	for node_name in LEGACY_POLLUTION_PANELS:
		var rect := layer.get_node_or_null(String(node_name)) as ColorRect
		if rect != null:
			rect.color.a = minf(rect.color.a, 0.085)
			muted_legacy_block_count += 1
	for node_name in LEGACY_POLLUTION_MARKERS:
		var rect := layer.get_node_or_null(String(node_name)) as ColorRect
		if rect != null:
			rect.color.a = minf(rect.color.a, 0.035)
			muted_legacy_block_count += 1
	var belt_label := layer.get_node_or_null("PollutionBeltLabel") as Label
	if belt_label != null:
		belt_label.visible = false


func _mute_pollution_identity_shapes() -> void:
	var identity_layer := _get_map_node("DemoInitialArtIdentityLayer")
	if identity_layer == null:
		return
	for child in identity_layer.get_children():
		if not child.has_meta("initial_art_identity_id"):
			continue
		var identity_id := String(child.get_meta("initial_art_identity_id", ""))
		if identity_id in ["identity.pollution_filter", "identity.pollution_residue", "identity.pollution_pressure"]:
			child.visible = false


func _tag_pollution_anchors() -> void:
	for path in POLLUTION_ANCHOR_PATHS.keys():
		var node := _get_map_node(String(path))
		if node == null:
			continue
		node.set_meta("pollution_boundary_visual_role", String(POLLUTION_ANCHOR_PATHS[path]))
		node.set_meta("pollution_boundary_visual_scope", "treatment_boundary")


func _tone_down_pollution_interactable_markers() -> void:
	var interactables := _get_map_node("Interactables")
	muted_interactable_marker_count = 0
	if interactables == null:
		return
	for child in interactables.get_children():
		var interactable := child as PrototypeInteractable
		if interactable == null:
			continue
		if not POLLUTION_INTERACTABLE_DEFINITION_IDS.has(interactable.definition_id):
			continue
		var marker := interactable.marker
		if marker == null:
			marker = interactable.get_node_or_null("Marker") as ColorRect
		if marker != null:
			marker.color.a = 0.06
			muted_interactable_marker_count += 1


func _get_map_node(path: String) -> Node:
	if path.is_empty() or get_parent() == null:
		return null
	return get_parent().get_node_or_null(path)


func _get_player_position() -> Vector2:
	if get_parent() == null:
		return Vector2.ZERO
	var player := get_parent().get_node_or_null("Player") as Node2D
	if player == null:
		return Vector2.ZERO
	return player.position
