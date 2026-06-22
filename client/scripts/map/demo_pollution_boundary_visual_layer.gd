extends Node2D
class_name DemoPollutionBoundaryVisualLayer

const ROLE_BOUNDARY := "boundary"
const ROLE_FILTER_SITE := "filter_site"
const ROLE_RESIDUE := "residue"
const ROLE_ROUTE := "route"
const ROLE_PRESSURE_GATE := "pressure_gate"
const ROLE_TERRAIN := "terrain"
const FOCUS_VISIBLE_MIN_X := 180.0
const FOCUS_VISIBLE_MAX_X := 620.0
const POLLUTION_FOCUS_CONTEXT_ROUTE_ALPHA := 0.0005
const POLLUTION_FOCUS_CONTEXT_ENEMY_ALPHA := 0.22
const POLLUTION_FOCUS_CONTEXT_ROUTE_PATHS := [
	"MainRouteSpine",
	"BaseToCrystalRouteBand",
	"CrystalToPollutionRouteBand",
	"DemoRoutePresentationLayer/DemoRouteBaseBand",
	"DemoRoutePresentationLayer/DemoRouteCrystalBand",
	"DemoRoutePresentationLayer/DemoRoutePollutionBand",
	"DemoRoutePresentationLayer/DemoRouteRuinBand"
]
const POLLUTION_FOCUS_CONTEXT_LABEL_PATHS := [
	"BaseDirectionLabel",
	"CrystalDirectionLabel",
	"PollutionDirectionLabel",
	"RuinDirectionLabel",
	"DemoRoutePresentationLayer/DemoRouteBaseLabel",
	"DemoRoutePresentationLayer/DemoRouteCrystalLabel",
	"DemoRoutePresentationLayer/DemoRoutePollutionLabel",
	"DemoRoutePresentationLayer/DemoRouteRuinLabel",
	"SceneArtFoundationLayer/SceneArtCrystalIdentityLabel",
	"SceneArtFoundationLayer/SceneArtPollutionIdentityLabel",
	"NonCoreSceneIdentityLayer/NonCoreRuinIdentityLabel"
]

const FIELD_FILL := Color(0.08, 0.1, 0.06, 0.0)
const FIELD_LINE := Color(0.72, 0.72, 0.3, 0.055)
const SEDIMENT_FILL := Color(0.42, 0.36, 0.1, 0.038)
const SEDIMENT_LINE := Color(0.86, 0.72, 0.22, 0.28)
const BUND_LINE := Color(0.94, 0.58, 0.22, 0.46)
const GRAVEL_FILL := Color(0.16, 0.2, 0.14, 0.24)
const GRAVEL_LINE := Color(0.66, 0.74, 0.52, 0.34)
const CONSTRUCTION_FILL := Color(0.13, 0.18, 0.13, 0.028)
const CONSTRUCTION_LINE := Color(0.62, 0.72, 0.54, 0.52)
const FILTER_LINE := Color(0.86, 0.94, 0.34, 0.94)
const FILTER_FILL := Color(0.22, 0.3, 0.1, 0.24)
const RESIDUE_LINE := Color(0.86, 0.72, 0.22, 0.74)
const RESIDUE_FILL := Color(0.5, 0.4, 0.08, 0.15)
const DANGER_LINE := Color(0.94, 0.46, 0.18, 0.74)
const DANGER_FILL := Color(0.42, 0.16, 0.06, 0.0)
const DANGER_POCKET_FILL := Color(0.5, 0.18, 0.08, 0.082)
const ROUTE_TO_FILTER := Color(0.88, 0.7, 0.26, 0.4)
const ROUTE_TO_BASE := Color(0.66, 0.86, 0.52, 0.28)
const SLURRY_ROUTE := Color(0.78, 0.42, 0.18, 0.28)
const GATE_CORE := Color(0.72, 0.46, 0.88, 0.78)
const CHAIN_DIM := Color(0.24, 0.28, 0.16, 0.36)
const CHAIN_WINDOW := Color(1.0, 0.62, 0.24, 0.78)
const CHAIN_ROUTE_DARK := Color(0.03, 0.04, 0.03, 0.42)
const CHAIN_VIAL := Color(0.72, 0.92, 0.38, 0.86)
const CHAIN_SLURRY := Color(0.82, 0.42, 0.18, 0.78)
const CHAIN_CORE_PREP := Color(0.74, 0.58, 0.9, 0.84)
const STATUS_PANEL_FILL := Color(0.018, 0.026, 0.018, 0.62)
const STATUS_IDLE_LIGHT := Color(0.16, 0.2, 0.15, 0.32)
const STATUS_WAITING := "waiting"
const STATUS_LOADED := "loaded"
const STATUS_PROCESSING := "processing"
const STATUS_OUTPUT_READY := "output_ready"
const STATUS_RETURN_READY := "return_ready"
const STATUS_CORE_PREP := "core_prep"

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

const CRYSTAL_CARRYOVER_INTERACTABLE_DEFINITION_IDS := {
	"map_object.field_wreckage": true,
	"map_object.crystal_cluster": true,
	"map_object.rich_crystal_vein": true,
	"map_object.anomaly_crystal": true
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
var terrain_material_shape_ids: Array[String] = []
var pollution_chain_shape_ids: Array[String] = []
var muted_legacy_block_count := 0
var muted_interactable_marker_count := 0
var muted_cross_region_focus_count := 0
var muted_pollution_focus_distraction_count := 0
var applied_pollution_chain_state_count := 0
var pollution_chain_state: Dictionary = {}


func _ready() -> void:
	apply_visuals()
	refresh_focus_visibility(_get_player_position())


func _process(_delta: float) -> void:
	refresh_focus_visibility(_get_player_position())
	_tone_down_pollution_interactable_markers()
	_mute_crystal_carryover_focus()
	_mute_pollution_focus_distractions()


func apply_visuals() -> void:
	_register_boundary_shapes()
	_register_flow_shapes()
	_register_terrain_material_shapes()
	_deemphasize_legacy_pollution_blocks()
	_mute_pollution_identity_shapes()
	_tag_pollution_anchors()
	_tone_down_pollution_interactable_markers()
	_mute_pollution_focus_distractions()
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
	var recycle_ready := slurry_ready and world_state.has_base_structure_definition("building.basic_reactor")
	var core_prep_ready := (
		inventory.has_ref("item.repair_gel", 1)
		and inventory.has_ref("item.resistance_vial_t1", 1)
		and inventory.has_ref("fluid.polluted_slurry", 1.0)
		and inventory.has_ref("item.basic_parts", 2)
	)
	var residue_device_state := STATUS_LOADED if residue_ready else STATUS_WAITING
	var filter_device_state := STATUS_WAITING
	if filter_active:
		filter_device_state = STATUS_PROCESSING
	elif residue_ready and world_state.has_base_structure_definition("building.pollution_filter"):
		filter_device_state = STATUS_LOADED
	var vial_device_state := STATUS_OUTPUT_READY if vial_ready else STATUS_WAITING
	var slurry_device_state := STATUS_OUTPUT_READY if slurry_ready else STATUS_WAITING
	var return_device_state := STATUS_WAITING
	if core_prep_ready or core_prep_active:
		return_device_state = STATUS_CORE_PREP
	elif recycle_ready or reclaim_active:
		return_device_state = STATUS_RETURN_READY
	pollution_chain_state = {
		"residue_ready": residue_ready,
		"filter_ready": world_state.has_base_structure_definition("building.pollution_filter") and residue_ready,
		"filter_active": filter_active,
		"vial_ready": vial_ready,
		"slurry_ready": slurry_ready,
		"recycle_ready": recycle_ready,
		"reclaim_active": reclaim_active,
		"core_prep_ready": core_prep_ready,
		"core_prep_active": core_prep_active,
		"residue_device_state": residue_device_state,
		"filter_device_state": filter_device_state,
		"vial_device_state": vial_device_state,
		"slurry_device_state": slurry_device_state,
		"return_device_state": return_device_state
	}
	_register_pollution_chain_shape("pollution_chain.boundary_residue_queue.%s" % _state_suffix(residue_ready))
	_register_pollution_chain_shape("pollution_chain.boundary_filter_window.%s" % _state_suffix(filter_active))
	_register_pollution_chain_shape("pollution_chain.boundary_vial_output.%s" % _state_suffix(vial_ready))
	_register_pollution_chain_shape("pollution_chain.boundary_slurry_output.%s" % _state_suffix(slurry_ready))
	_register_pollution_chain_shape("pollution_chain.boundary_base_return_route.%s" % _state_suffix(vial_ready or filter_active))
	_register_pollution_chain_shape("pollution_chain.boundary_slurry_split_route.%s" % _state_suffix(slurry_ready or filter_active))
	_register_pollution_chain_shape("pollution_chain.boundary_recycle_route.%s" % _state_suffix(recycle_ready or reclaim_active))
	_register_pollution_chain_shape("pollution_chain.boundary_core_prep_route.%s" % _state_suffix(core_prep_ready or core_prep_active))
	_register_pollution_chain_shape("pollution_chain.device.residue.%s" % residue_device_state)
	_register_pollution_chain_shape("pollution_chain.device.filter.%s" % filter_device_state)
	_register_pollution_chain_shape("pollution_chain.device.vial_output.%s" % vial_device_state)
	_register_pollution_chain_shape("pollution_chain.device.slurry_output.%s" % slurry_device_state)
	_register_pollution_chain_shape("pollution_chain.device.return_pad.%s" % return_device_state)
	_register_pollution_chain_shape("pollution_chain.flow.filter_processing.%s" % _activity_suffix(filter_active))
	_register_pollution_chain_shape("pollution_chain.flow.vial_to_base.%s" % _state_suffix(vial_ready))
	_register_pollution_chain_shape("pollution_chain.flow.slurry_to_recycle.%s" % _state_suffix(recycle_ready or reclaim_active))
	_register_pollution_chain_shape("pollution_chain.flow.slurry_to_core_prep.%s" % _state_suffix(core_prep_ready or core_prep_active))
	queue_redraw()


func get_boundary_shape_count() -> int:
	return boundary_shape_ids.size()


func get_flow_count() -> int:
	return flow_shape_ids.size()


func get_terrain_material_shape_count() -> int:
	return terrain_material_shape_ids.size()


func get_muted_legacy_block_count() -> int:
	return muted_legacy_block_count


func get_muted_interactable_marker_count() -> int:
	return muted_interactable_marker_count


func get_muted_cross_region_focus_count() -> int:
	return muted_cross_region_focus_count


func get_muted_pollution_focus_distraction_count() -> int:
	return muted_pollution_focus_distraction_count


func has_boundary_shape(shape_id: String) -> bool:
	return boundary_shape_ids.has(shape_id)


func has_flow_shape(shape_id: String) -> bool:
	return flow_shape_ids.has(shape_id)


func has_terrain_material_shape(shape_id: String) -> bool:
	return terrain_material_shape_ids.has(shape_id)


func get_pollution_chain_state_shape_count() -> int:
	return applied_pollution_chain_state_count


func has_pollution_chain_shape(shape_id: String) -> bool:
	return pollution_chain_shape_ids.has(shape_id)


func refresh_focus_visibility(player_position: Vector2) -> void:
	visible = is_pollution_focus_visible_at(player_position)
	_mute_crystal_carryover_focus()
	_mute_pollution_focus_distractions()


func is_pollution_focus_visible_at(player_position: Vector2) -> bool:
	return player_position.x >= FOCUS_VISIBLE_MIN_X and player_position.x <= FOCUS_VISIBLE_MAX_X


func _draw() -> void:
	_draw_local_processing_workspace()
	_draw_boundary_field()
	_draw_pollution_material_surface()
	_draw_treatment_routes()
	_draw_filter_construction_site()
	_draw_residue_patches()
	_draw_pressure_gate()
	_draw_pollution_chain_state()


func _draw_local_processing_workspace() -> void:
	var workspace := Rect2(Vector2(226.0, -220.0), Vector2(174.0, 476.0))
	var device_lane := Rect2(Vector2(250.0, -166.0), Vector2(126.0, 408.0))
	draw_rect(workspace, Color(0.004, 0.01, 0.008, 0.38), true)
	_draw_corner_frame(workspace, Color(0.66, 0.72, 0.46, 0.09), 20.0, 1.1)
	draw_rect(device_lane, Color(0.036, 0.044, 0.025, 0.24), true)
	draw_rect(device_lane, Color(0.64, 0.7, 0.38, 0.08), false, 1.0, true)


func _draw_boundary_field() -> void:
	var construction_rect := Rect2(Vector2(246.0, -254.0), Vector2(122.0, 160.0))
	var danger_rect := Rect2(Vector2(246.0, -32.0), Vector2(136.0, 272.0))
	var field_rect := Rect2(Vector2(242.0, -276.0), Vector2(144.0, 520.0))
	draw_rect(field_rect, FIELD_FILL, true)
	_draw_corner_frame(field_rect, FIELD_LINE, 18.0, 1.4)
	draw_rect(construction_rect, CONSTRUCTION_FILL, true)
	_draw_corner_frame(construction_rect, Color(CONSTRUCTION_LINE.r, CONSTRUCTION_LINE.g, CONSTRUCTION_LINE.b, 0.32), 15.0, 1.3)
	draw_rect(danger_rect, DANGER_FILL, true)
	_draw_corner_frame(danger_rect, Color(DANGER_LINE.r, DANGER_LINE.g, DANGER_LINE.b, 0.13), 15.0, 1.0)
	for y in [-218.0, -154.0, -94.0]:
		draw_line(Vector2(254.0, y), Vector2(326.0, y), Color(0.58, 0.68, 0.52, 0.09), 1.0, true)
	_draw_hazard_boundary(Vector2(242.0, -38.0), Vector2(384.0, -38.0))
	for x in [260.0, 298.0, 336.0]:
		draw_line(Vector2(x, -238.0), Vector2(x, -142.0), Color(0.58, 0.68, 0.52, 0.095), 1.0, true)
	for y in [36.0, 104.0, 172.0, 226.0]:
		draw_line(Vector2(258.0, y), Vector2(344.0, y), Color(0.58, 0.5, 0.14, 0.1), 1.0, true)


func _draw_pollution_material_surface() -> void:
	_draw_sediment_fans()
	_draw_segmented_settling_cells()
	_draw_local_settling_islands()
	_draw_settling_layers()
	_draw_danger_bunds()
	_draw_local_danger_pockets()
	_draw_broken_danger_bund_segments()
	_draw_dark_field_breaks()
	_draw_filter_worksite_gravel()
	_draw_filter_bed_partitions()
	_draw_filter_rubble_cells()
	_draw_filter_input_output_site()
	_draw_local_service_ports()
	_draw_output_service_islands()
	_draw_recovery_loading_pad()
	_draw_recovery_crate_stacks()


func _draw_sediment_fans() -> void:
	for fan in [
		[
			Vector2(248.0, 18.0),
			Vector2(284.0, -12.0),
			Vector2(350.0, 4.0),
			Vector2(372.0, 58.0),
			Vector2(326.0, 96.0),
			Vector2(264.0, 76.0),
			Vector2(248.0, 18.0)
		],
		[
			Vector2(270.0, 118.0),
			Vector2(326.0, 86.0),
			Vector2(376.0, 134.0),
			Vector2(362.0, 210.0),
			Vector2(288.0, 206.0),
			Vector2(270.0, 118.0)
		]
	]:
		var polygon := PackedVector2Array(fan)
		draw_colored_polygon(polygon, SEDIMENT_FILL)
		draw_polyline(polygon, SEDIMENT_LINE, 1.4, true)
	for point in [Vector2(276.0, 46.0), Vector2(322.0, 30.0), Vector2(338.0, 156.0), Vector2(292.0, 184.0)]:
		draw_circle(point, 4.0, Color(0.92, 0.78, 0.26, 0.26))


func _draw_settling_layers() -> void:
	for y in [34.0, 58.0, 86.0, 124.0, 158.0, 194.0]:
		draw_line(Vector2(252.0, y), Vector2(374.0, y + 10.0), Color(SEDIMENT_LINE.r, SEDIMENT_LINE.g, SEDIMENT_LINE.b, 0.22), 1.1, true)
	for x in [270.0, 302.0, 334.0, 366.0]:
		draw_line(Vector2(x, -22.0), Vector2(x + 8.0, 224.0), Color(0.52, 0.42, 0.12, 0.14), 1.0, true)


func _draw_segmented_settling_cells() -> void:
	for cell in [
		Rect2(Vector2(258.0, 18.0), Vector2(44.0, 54.0)),
		Rect2(Vector2(312.0, 28.0), Vector2(48.0, 50.0)),
		Rect2(Vector2(262.0, 102.0), Vector2(54.0, 48.0)),
		Rect2(Vector2(320.0, 142.0), Vector2(42.0, 54.0)),
		Rect2(Vector2(262.0, 178.0), Vector2(38.0, 42.0))
	]:
		draw_rect(cell, Color(0.32, 0.26, 0.08, 0.068), true)
		draw_rect(cell, Color(SEDIMENT_LINE.r, SEDIMENT_LINE.g, SEDIMENT_LINE.b, 0.14), false, 1.0, true)
		draw_line(cell.position + Vector2(4.0, cell.size.y * 0.5), cell.position + Vector2(cell.size.x - 4.0, cell.size.y * 0.5 + 5.0), Color(SEDIMENT_LINE.r, SEDIMENT_LINE.g, SEDIMENT_LINE.b, 0.1), 1.0, true)


func _draw_local_settling_islands() -> void:
	for island in [
		[
			Vector2(256.0, 24.0),
			Vector2(292.0, 4.0),
			Vector2(324.0, 18.0),
			Vector2(314.0, 56.0),
			Vector2(270.0, 64.0),
			Vector2(256.0, 24.0)
		],
		[
			Vector2(306.0, 104.0),
			Vector2(354.0, 108.0),
			Vector2(374.0, 146.0),
			Vector2(344.0, 184.0),
			Vector2(308.0, 166.0),
			Vector2(306.0, 104.0)
		],
		[
			Vector2(256.0, 166.0),
			Vector2(296.0, 180.0),
			Vector2(312.0, 216.0),
			Vector2(272.0, 226.0),
			Vector2(250.0, 196.0),
			Vector2(256.0, 166.0)
		]
	]:
		var polygon := PackedVector2Array(island)
		draw_polyline(polygon, Color(0.08, 0.06, 0.025, 0.36), 5.0, true)
		draw_colored_polygon(polygon, Color(SEDIMENT_FILL.r, SEDIMENT_FILL.g, SEDIMENT_FILL.b, 0.072))
		draw_polyline(polygon, Color(SEDIMENT_LINE.r, SEDIMENT_LINE.g, SEDIMENT_LINE.b, 0.2), 1.2, true)


func _draw_danger_bunds() -> void:
	_draw_route([Vector2(246.0, -42.0), Vector2(306.0, -52.0), Vector2(382.0, -36.0)], BUND_LINE, 2.4)
	_draw_route([Vector2(382.0, -24.0), Vector2(390.0, 42.0), Vector2(382.0, 112.0)], Color(BUND_LINE.r, BUND_LINE.g, BUND_LINE.b, 0.36), 2.0)
	for point in [Vector2(268.0, -44.0), Vector2(310.0, -50.0), Vector2(354.0, -42.0), Vector2(386.0, 38.0)]:
		draw_line(point + Vector2(-7.0, -6.0), point + Vector2(7.0, 6.0), Color(0.96, 0.72, 0.28, 0.34), 1.2, true)


func _draw_broken_danger_bund_segments() -> void:
	for segment in [
		[Vector2(252.0, -16.0), Vector2(288.0, -8.0), Vector2(318.0, 6.0)],
		[Vector2(334.0, 12.0), Vector2(366.0, 34.0), Vector2(376.0, 74.0)],
		[Vector2(276.0, 92.0), Vector2(320.0, 118.0), Vector2(370.0, 128.0)]
	]:
		draw_polyline(PackedVector2Array(segment), Color(0.08, 0.04, 0.025, 0.38), 5.0, true)
		draw_polyline(PackedVector2Array(segment), Color(DANGER_LINE.r, DANGER_LINE.g, DANGER_LINE.b, 0.34), 1.5, true)


func _draw_local_danger_pockets() -> void:
	for pocket in [
		[
			Vector2(250.0, -18.0),
			Vector2(288.0, -24.0),
			Vector2(318.0, 8.0),
			Vector2(300.0, 42.0),
			Vector2(258.0, 34.0),
			Vector2(250.0, -18.0)
		],
		[
			Vector2(326.0, 18.0),
			Vector2(370.0, 36.0),
			Vector2(378.0, 86.0),
			Vector2(338.0, 104.0),
			Vector2(318.0, 66.0),
			Vector2(326.0, 18.0)
		],
		[
			Vector2(266.0, 124.0),
			Vector2(328.0, 120.0),
			Vector2(370.0, 156.0),
			Vector2(352.0, 214.0),
			Vector2(286.0, 202.0),
			Vector2(266.0, 124.0)
		]
	]:
		var polygon := PackedVector2Array(pocket)
		draw_polyline(polygon, Color(0.08, 0.035, 0.02, 0.44), 5.4, true)
		draw_colored_polygon(polygon, DANGER_POCKET_FILL)
		draw_polyline(polygon, Color(DANGER_LINE.r, DANGER_LINE.g, DANGER_LINE.b, 0.28), 1.3, true)


func _draw_dark_field_breaks() -> void:
	for rect in [
		Rect2(Vector2(250.0, -226.0), Vector2(42.0, 30.0)),
		Rect2(Vector2(318.0, -226.0), Vector2(44.0, 46.0)),
		Rect2(Vector2(260.0, -8.0), Vector2(34.0, 38.0)),
		Rect2(Vector2(332.0, 58.0), Vector2(36.0, 48.0)),
		Rect2(Vector2(252.0, 214.0), Vector2(54.0, 22.0))
	]:
		draw_rect(rect, Color(0.012, 0.018, 0.016, 0.38), true)
		draw_rect(rect, Color(0.42, 0.52, 0.38, 0.06), false, 0.8, true)


func _draw_filter_worksite_gravel() -> void:
	var bed := Rect2(Vector2(266.0, -158.0), Vector2(70.0, 108.0))
	draw_rect(bed, GRAVEL_FILL, true)
	draw_rect(bed, GRAVEL_LINE, false, 1.4, true)
	for y in [-144.0, -120.0, -96.0, -72.0]:
		draw_line(Vector2(272.0, y), Vector2(330.0, y + 12.0), Color(GRAVEL_LINE.r, GRAVEL_LINE.g, GRAVEL_LINE.b, 0.18), 1.0, true)
	for point in [Vector2(274.0, -148.0), Vector2(330.0, -148.0), Vector2(274.0, -58.0), Vector2(330.0, -58.0)]:
		draw_circle(point, 2.8, Color(CONSTRUCTION_LINE.r, CONSTRUCTION_LINE.g, CONSTRUCTION_LINE.b, 0.48))


func _draw_filter_bed_partitions() -> void:
	for rect in [
		Rect2(Vector2(258.0, -188.0), Vector2(34.0, 34.0)),
		Rect2(Vector2(300.0, -184.0), Vector2(40.0, 28.0)),
		Rect2(Vector2(258.0, -132.0), Vector2(32.0, 42.0)),
		Rect2(Vector2(304.0, -124.0), Vector2(42.0, 36.0))
	]:
		draw_rect(rect, Color(GRAVEL_FILL.r, GRAVEL_FILL.g, GRAVEL_FILL.b, 0.18), true)
		draw_rect(rect, Color(GRAVEL_LINE.r, GRAVEL_LINE.g, GRAVEL_LINE.b, 0.26), false, 1.0, true)
		draw_line(rect.position + Vector2(4.0, rect.size.y - 8.0), rect.position + Vector2(rect.size.x - 4.0, 8.0), Color(GRAVEL_LINE.r, GRAVEL_LINE.g, GRAVEL_LINE.b, 0.18), 1.0, true)


func _draw_filter_rubble_cells() -> void:
	for rect in [
		Rect2(Vector2(250.0, -206.0), Vector2(34.0, 22.0)),
		Rect2(Vector2(300.0, -222.0), Vector2(44.0, 26.0)),
		Rect2(Vector2(344.0, -176.0), Vector2(28.0, 34.0)),
		Rect2(Vector2(252.0, -74.0), Vector2(24.0, 18.0)),
		Rect2(Vector2(338.0, -58.0), Vector2(30.0, 22.0))
	]:
		draw_rect(rect, Color(0.16, 0.2, 0.14, 0.16), true)
		draw_rect(rect, Color(GRAVEL_LINE.r, GRAVEL_LINE.g, GRAVEL_LINE.b, 0.2), false, 1.0, true)
		draw_circle(rect.position + rect.size * 0.48, 2.4, Color(GRAVEL_LINE.r, GRAVEL_LINE.g, GRAVEL_LINE.b, 0.28))


func _draw_filter_input_output_site() -> void:
	_draw_route([Vector2(256.0, 28.0), Vector2(256.0, -64.0), Vector2(282.0, -104.0)], Color(RESIDUE_LINE.r, RESIDUE_LINE.g, RESIDUE_LINE.b, 0.5), 4.0)
	draw_rect(Rect2(Vector2(244.0, -112.0), Vector2(28.0, 26.0)), Color(0.4, 0.32, 0.08, 0.2), true)
	draw_rect(Rect2(Vector2(244.0, -112.0), Vector2(28.0, 26.0)), RESIDUE_LINE, false, 1.3, true)
	draw_rect(Rect2(Vector2(324.0, -144.0), Vector2(38.0, 20.0)), Color(CHAIN_VIAL.r, CHAIN_VIAL.g, CHAIN_VIAL.b, 0.16), true)
	draw_rect(Rect2(Vector2(324.0, -144.0), Vector2(38.0, 20.0)), CHAIN_VIAL, false, 1.2, true)
	for x in [330.0, 342.0, 354.0]:
		draw_line(Vector2(x, -140.0), Vector2(x, -128.0), Color(CHAIN_VIAL.r, CHAIN_VIAL.g, CHAIN_VIAL.b, 0.46), 1.4, true)
	draw_rect(Rect2(Vector2(322.0, -94.0), Vector2(44.0, 28.0)), Color(CHAIN_SLURRY.r, CHAIN_SLURRY.g, CHAIN_SLURRY.b, 0.14), true)
	draw_rect(Rect2(Vector2(322.0, -94.0), Vector2(44.0, 28.0)), CHAIN_SLURRY, false, 1.2, true)
	draw_circle(Vector2(334.0, -80.0), 4.0, Color(CHAIN_SLURRY.r, CHAIN_SLURRY.g, CHAIN_SLURRY.b, 0.38))
	draw_circle(Vector2(354.0, -80.0), 3.6, Color(CHAIN_SLURRY.r, CHAIN_SLURRY.g, CHAIN_SLURRY.b, 0.28))
	draw_line(Vector2(360.0, -66.0), Vector2(382.0, 24.0), Color(CHAIN_CORE_PREP.r, CHAIN_CORE_PREP.g, CHAIN_CORE_PREP.b, 0.34), 2.4, true)


func _draw_local_service_ports() -> void:
	for rect in [
		Rect2(Vector2(218.0, -116.0), Vector2(34.0, 16.0)),
		Rect2(Vector2(238.0, -86.0), Vector2(28.0, 18.0)),
		Rect2(Vector2(354.0, -126.0), Vector2(30.0, 16.0)),
		Rect2(Vector2(352.0, -98.0), Vector2(32.0, 18.0))
	]:
		draw_rect(rect, Color(0.06, 0.08, 0.05, 0.32), true)
		draw_rect(rect, Color(ROUTE_TO_BASE.r, ROUTE_TO_BASE.g, ROUTE_TO_BASE.b, 0.32), false, 1.0, true)
		draw_line(
			rect.position + Vector2(4.0, rect.size.y * 0.5),
			rect.position + Vector2(rect.size.x - 4.0, rect.size.y * 0.5),
			Color(ROUTE_TO_BASE.r, ROUTE_TO_BASE.g, ROUTE_TO_BASE.b, 0.34),
			1.2,
			true
		)
	for point in [Vector2(234.0, -108.0), Vector2(252.0, -78.0), Vector2(370.0, -118.0), Vector2(370.0, -88.0)]:
		draw_circle(point, 2.8, Color(0.86, 0.92, 0.54, 0.38))


func _draw_output_service_islands() -> void:
	for rect in [
		Rect2(Vector2(318.0, -150.0), Vector2(50.0, 32.0)),
		Rect2(Vector2(316.0, -102.0), Vector2(56.0, 40.0)),
		Rect2(Vector2(356.0, -46.0), Vector2(24.0, 58.0))
	]:
		draw_rect(rect, Color(0.08, 0.1, 0.055, 0.18), true)
		draw_rect(rect, Color(0.72, 0.78, 0.36, 0.22), false, 1.0, true)


func _draw_recovery_loading_pad() -> void:
	var pad := Rect2(Vector2(310.0, 184.0), Vector2(54.0, 44.0))
	draw_rect(pad, Color(0.14, 0.16, 0.1, 0.28), true)
	draw_rect(pad, Color(ROUTE_TO_BASE.r, ROUTE_TO_BASE.g, ROUTE_TO_BASE.b, 0.36), false, 1.4, true)
	for x in [320.0, 338.0, 356.0]:
		draw_line(Vector2(x, 190.0), Vector2(x + 8.0, 222.0), Color(ROUTE_TO_BASE.r, ROUTE_TO_BASE.g, ROUTE_TO_BASE.b, 0.22), 1.0, true)
	draw_circle(Vector2(336.0, 206.0), 5.0, Color(CHAIN_SLURRY.r, CHAIN_SLURRY.g, CHAIN_SLURRY.b, 0.36))


func _draw_recovery_crate_stacks() -> void:
	for rect in [
		Rect2(Vector2(314.0, 188.0), Vector2(18.0, 14.0)),
		Rect2(Vector2(338.0, 192.0), Vector2(18.0, 14.0)),
		Rect2(Vector2(324.0, 210.0), Vector2(24.0, 12.0))
	]:
		draw_rect(rect, Color(0.2, 0.24, 0.12, 0.24), true)
		draw_rect(rect, Color(ROUTE_TO_BASE.r, ROUTE_TO_BASE.g, ROUTE_TO_BASE.b, 0.32), false, 1.0, true)


func _draw_treatment_routes() -> void:
	_draw_route([Vector2(258.0, 34.0), Vector2(278.0, -12.0), Vector2(298.0, -72.0)], ROUTE_TO_FILTER, 2.6)
	_draw_route([Vector2(344.0, 158.0), Vector2(330.0, 78.0), Vector2(306.0, -70.0)], SLURRY_ROUTE, 2.0)
	_draw_route([Vector2(298.0, -110.0), Vector2(250.0, -108.0), Vector2(220.0, -98.0)], ROUTE_TO_BASE, 1.8)
	_draw_route([Vector2(304.0, 96.0), Vector2(314.0, 152.0), Vector2(336.0, 206.0)], SLURRY_ROUTE, 1.8)
	_draw_route([Vector2(342.0, 24.0), Vector2(382.0, 24.0)], DANGER_LINE, 2.4)
	for point in [Vector2(298.0, -72.0), Vector2(220.0, -98.0), Vector2(304.0, 96.0), Vector2(382.0, 24.0)]:
		draw_circle(point, 3.4, Color(0.88, 0.86, 0.48, 0.42))


func _draw_filter_construction_site() -> void:
	draw_rect(Rect2(Vector2(252.0, -126.0), Vector2(34.0, 34.0)), Color(0.2, 0.26, 0.18, 0.34), true)
	draw_rect(Rect2(Vector2(252.0, -126.0), Vector2(34.0, 34.0)), CONSTRUCTION_LINE, false, 1.8, true)
	draw_rect(Rect2(Vector2(318.0, -126.0), Vector2(34.0, 34.0)), Color(0.2, 0.26, 0.18, 0.34), true)
	draw_rect(Rect2(Vector2(318.0, -126.0), Vector2(34.0, 34.0)), CONSTRUCTION_LINE, false, 1.8, true)
	draw_rect(Rect2(Vector2(276.0, -148.0), Vector2(46.0, 82.0)), Color(0.025, 0.035, 0.022, 0.52), true)
	draw_rect(Rect2(Vector2(276.0, -148.0), Vector2(46.0, 82.0)), Color(FILTER_LINE.r, FILTER_LINE.g, FILTER_LINE.b, 0.42), false, 4.2, true)
	draw_rect(Rect2(Vector2(280.0, -140.0), Vector2(38.0, 66.0)), FILTER_FILL, true)
	draw_rect(Rect2(Vector2(280.0, -140.0), Vector2(38.0, 66.0)), FILTER_LINE, false, 2.8, true)
	draw_line(Vector2(290.0, -130.0), Vector2(290.0, -84.0), FILTER_LINE, 3.8, true)
	draw_line(Vector2(306.0, -130.0), Vector2(306.0, -84.0), FILTER_LINE, 3.8, true)
	draw_line(Vector2(252.0, -102.0), Vector2(280.0, -102.0), Color(0.86, 0.72, 0.22, 0.72), 4.0, true)
	draw_line(Vector2(318.0, -124.0), Vector2(352.0, -124.0), CHAIN_VIAL, 3.4, true)
	draw_line(Vector2(318.0, -96.0), Vector2(352.0, -96.0), CHAIN_SLURRY, 3.2, true)
	draw_line(Vector2(284.0, -74.0), Vector2(314.0, -74.0), Color(0.92, 0.78, 0.28, 0.82), 3.0, true)
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
	_draw_chain_flow_band([Vector2(334.0, -124.0), Vector2(298.0, -110.0), Vector2(250.0, -108.0), Vector2(220.0, -98.0)], vial_ready or filter_active, CHAIN_VIAL, 3.2)
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
	_draw_pollution_device_status()


func _draw_pollution_device_status() -> void:
	var residue_state := String(pollution_chain_state.get("residue_device_state", STATUS_WAITING))
	var filter_state := String(pollution_chain_state.get("filter_device_state", STATUS_WAITING))
	var vial_state := String(pollution_chain_state.get("vial_device_state", STATUS_WAITING))
	var slurry_state := String(pollution_chain_state.get("slurry_device_state", STATUS_WAITING))
	var return_state := String(pollution_chain_state.get("return_device_state", STATUS_WAITING))
	_draw_device_status_strip(Vector2(242.0, 4.0), residue_state, RESIDUE_LINE)
	_draw_material_state_slot(Rect2(Vector2(254.0, 22.0), Vector2(34.0, 18.0)), residue_state, RESIDUE_LINE)
	_draw_device_status_strip(Vector2(280.0, -166.0), filter_state, FILTER_LINE)
	_draw_material_state_slot(Rect2(Vector2(286.0, -138.0), Vector2(24.0, 58.0)), filter_state, FILTER_LINE)
	_draw_device_status_strip(Vector2(324.0, -162.0), vial_state, CHAIN_VIAL)
	_draw_material_state_slot(Rect2(Vector2(318.0, -138.0), Vector2(36.0, 24.0)), vial_state, CHAIN_VIAL)
	_draw_device_status_strip(Vector2(324.0, -70.0), slurry_state, CHAIN_SLURRY)
	_draw_material_state_slot(Rect2(Vector2(318.0, -106.0), Vector2(38.0, 26.0)), slurry_state, CHAIN_SLURRY)
	_draw_device_status_strip(Vector2(310.0, 170.0), return_state, CHAIN_CORE_PREP if return_state == STATUS_CORE_PREP else ROUTE_TO_BASE)
	_draw_material_state_slot(Rect2(Vector2(314.0, 190.0), Vector2(46.0, 32.0)), return_state, CHAIN_CORE_PREP if return_state == STATUS_CORE_PREP else ROUTE_TO_BASE)
	_draw_pressure_warning_node(Vector2(382.0, 24.0), return_state)


func _draw_device_status_strip(origin: Vector2, state: String, color: Color) -> void:
	var rect := Rect2(origin, Vector2(34.0, 14.0))
	draw_rect(rect, STATUS_PANEL_FILL, true)
	draw_rect(rect, Color(color.r, color.g, color.b, 0.26), false, 1.0, true)
	var light_count := _status_light_count(state)
	for index in range(3):
		var light_position := origin + Vector2(8.0 + float(index) * 10.0, 7.0)
		var light_color := _status_light_color(state, color) if index < light_count else STATUS_IDLE_LIGHT
		draw_circle(light_position, 3.4, light_color)


func _draw_material_state_slot(rect: Rect2, state: String, color: Color) -> void:
	var ready := _is_active_material_state(state)
	draw_rect(rect, Color(0.02, 0.028, 0.018, 0.58), true)
	draw_rect(rect, Color(color.r, color.g, color.b, 0.22 if ready else 0.05), true)
	draw_rect(rect, Color(color.r, color.g, color.b, 0.72 if ready else 0.16), false, 1.2, true)
	if not ready:
		return
	var center := rect.position + rect.size * 0.5
	draw_line(center + Vector2(-rect.size.x * 0.32, 0.0), center + Vector2(rect.size.x * 0.32, 0.0), Color(color.r, color.g, color.b, 0.56), 1.4, true)
	draw_circle(center, minf(rect.size.x, rect.size.y) * 0.16, Color(color.r, color.g, color.b, 0.54))


func _draw_pressure_warning_node(center: Vector2, state: String) -> void:
	var active := state == STATUS_CORE_PREP
	var color := CHAIN_CORE_PREP if active else DANGER_LINE
	draw_arc(center, 16.0, 0.0, TAU, 28, Color(color.r, color.g, color.b, 0.62 if active else 0.24), 1.6, true)
	if not active:
		return
	for angle in [PI * 0.2, PI * 0.72, PI * 1.22, PI * 1.72]:
		var from := center + Vector2(cos(angle), sin(angle)) * 9.0
		var to := center + Vector2(cos(angle), sin(angle)) * 18.0
		draw_line(from, to, Color(color.r, color.g, color.b, 0.62), 1.2, true)


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


func _draw_corner_frame(rect: Rect2, color: Color, corner_length: float, width: float) -> void:
	var left := rect.position.x
	var top := rect.position.y
	var right := rect.position.x + rect.size.x
	var bottom := rect.position.y + rect.size.y
	draw_line(Vector2(left, top), Vector2(left + corner_length, top), color, width, true)
	draw_line(Vector2(left, top), Vector2(left, top + corner_length), color, width, true)
	draw_line(Vector2(right - corner_length, top), Vector2(right, top), color, width, true)
	draw_line(Vector2(right, top), Vector2(right, top + corner_length), color, width, true)
	draw_line(Vector2(left, bottom - corner_length), Vector2(left, bottom), color, width, true)
	draw_line(Vector2(left, bottom), Vector2(left + corner_length, bottom), color, width, true)
	draw_line(Vector2(right - corner_length, bottom), Vector2(right, bottom), color, width, true)
	draw_line(Vector2(right, bottom - corner_length), Vector2(right, bottom), color, width, true)


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
		"flow.pressure_gate_route",
		"flow.pollution_status_lights",
		"flow.pollution_material_state_slots",
		"flow.pollution_pressure_warning_nodes"
	]


func _register_terrain_material_shapes() -> void:
	terrain_material_shape_ids = [
		"terrain.pollution.local_processing_workspace",
		"terrain.pollution.sediment_fan",
		"terrain.pollution.segmented_settling_cells",
		"terrain.pollution.local_settling_islands",
		"terrain.pollution.settling_layers",
		"terrain.pollution.danger_bund",
		"terrain.pollution.local_danger_pockets",
		"terrain.pollution.segmented_danger_bund",
		"terrain.pollution.dark_break_cells",
		"terrain.pollution.filter_gravel_bed",
		"terrain.pollution.filter_bed_partitions",
		"terrain.pollution.filter_rubble_cells",
		"terrain.pollution.input_trench",
		"terrain.pollution.local_service_ports",
		"terrain.pollution.output_vial_rack",
		"terrain.pollution.output_slurry_basin",
		"terrain.pollution.output_service_islands",
		"terrain.pollution.recovery_loading_pad",
		"terrain.pollution.recovery_crate_stacks",
		"terrain.pollution.core_prep_tap"
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


func _activity_suffix(is_active: bool) -> String:
	return "active" if is_active else "idle"


func _status_light_count(state: String) -> int:
	match state:
		STATUS_LOADED:
			return 1
		STATUS_PROCESSING:
			return 2
		STATUS_OUTPUT_READY, STATUS_RETURN_READY, STATUS_CORE_PREP:
			return 3
		_:
			return 0


func _status_light_color(state: String, color: Color) -> Color:
	match state:
		STATUS_PROCESSING, STATUS_CORE_PREP:
			return Color(color.r, color.g, color.b, 0.92)
		STATUS_OUTPUT_READY, STATUS_RETURN_READY:
			return Color(color.r, color.g, color.b, 0.76)
		STATUS_LOADED:
			return Color(color.r, color.g, color.b, 0.62)
		_:
			return STATUS_IDLE_LIGHT


func _is_active_material_state(state: String) -> bool:
	return state in [
		STATUS_LOADED,
		STATUS_PROCESSING,
		STATUS_OUTPUT_READY,
		STATUS_RETURN_READY,
		STATUS_CORE_PREP
	]


func _deemphasize_legacy_pollution_blocks() -> void:
	muted_legacy_block_count = 0
	var region := _get_map_node("RegionPollution") as ColorRect
	if region != null:
		region.color = Color(0.07, 0.075, 0.045, 0.032)
	var route_band := _get_map_node("DemoRoutePresentationLayer/DemoRoutePollutionBand") as ColorRect
	if route_band != null:
		route_band.visible = false
		route_band.color = Color(route_band.color.r, route_band.color.g, route_band.color.b, 0.0)
	var route_label := _get_map_node("DemoRoutePresentationLayer/DemoRoutePollutionLabel") as Label
	if route_label != null:
		route_label.visible = false

	var layer := _get_map_node("OpeningSceneLayer")
	if layer == null:
		return
	for node_name in LEGACY_POLLUTION_PANELS:
		var rect := layer.get_node_or_null(String(node_name)) as ColorRect
		if rect != null:
			rect.visible = false
			rect.color = Color(rect.color.r, rect.color.g, rect.color.b, 0.0)
			muted_legacy_block_count += 1
	for node_name in LEGACY_POLLUTION_MARKERS:
		var rect := layer.get_node_or_null(String(node_name)) as ColorRect
		if rect != null:
			rect.visible = false
			rect.color = Color(rect.color.r, rect.color.g, rect.color.b, 0.0)
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
			marker.color.a = 0.04
			muted_interactable_marker_count += 1


func _mute_crystal_carryover_focus() -> void:
	muted_cross_region_focus_count = 0
	if not visible:
		return
	var interactables := _get_map_node("Interactables")
	if interactables == null:
		return
	for child in interactables.get_children():
		var interactable := child as PrototypeInteractable
		if interactable == null:
			continue
		if not CRYSTAL_CARRYOVER_INTERACTABLE_DEFINITION_IDS.has(interactable.definition_id):
			continue
		var muted := false
		var label := interactable.get_node_or_null("Label") as Label
		if label != null:
			label.visible = false
			muted = true
		var focus_ring := interactable.get_node_or_null("FocusRing") as ColorRect
		if focus_ring != null:
			focus_ring.visible = false
			muted = true
		var marker := interactable.marker
		if marker == null:
			marker = interactable.get_node_or_null("Marker") as ColorRect
		if marker != null:
			marker.color.a = minf(marker.color.a, 0.032)
			marker.scale = Vector2.ONE
			muted = true
		if muted:
			muted_cross_region_focus_count += 1


func _mute_pollution_focus_distractions() -> void:
	muted_pollution_focus_distraction_count = 0
	if not visible:
		return
	muted_pollution_focus_distraction_count += _mute_focus_context_route_rects()
	muted_pollution_focus_distraction_count += _hide_focus_context_labels()
	muted_pollution_focus_distraction_count += _mute_focus_enemy_pressure()


func _mute_focus_context_route_rects() -> int:
	var muted_count := 0
	for path in POLLUTION_FOCUS_CONTEXT_ROUTE_PATHS:
		var rect := _get_map_node(String(path)) as ColorRect
		if rect == null:
			continue
		rect.color.a = minf(rect.color.a, POLLUTION_FOCUS_CONTEXT_ROUTE_ALPHA)
		muted_count += 1
	return muted_count


func _hide_focus_context_labels() -> int:
	var muted_count := 0
	for path in POLLUTION_FOCUS_CONTEXT_LABEL_PATHS:
		var label := _get_map_node(String(path)) as Label
		if label == null:
			continue
		label.visible = false
		muted_count += 1
	return muted_count


func _mute_focus_enemy_pressure() -> int:
	var enemies := _get_map_node("Enemies")
	if enemies == null:
		return 0
	var muted_count := 0
	for child in enemies.get_children():
		var enemy := child as PrototypeEnemy
		if enemy == null:
			continue
		enemy.modulate.a = minf(enemy.modulate.a, POLLUTION_FOCUS_CONTEXT_ENEMY_ALPHA)
		var sprite := enemy.sprite
		if sprite == null:
			sprite = enemy.get_node_or_null("Sprite") as ColorRect
		if sprite != null:
			sprite.color.a = minf(sprite.color.a, 0.42)
		var label := enemy.label
		if label == null:
			label = enemy.get_node_or_null("Label") as Label
		if label != null:
			label.visible = false
		var focus_ring := enemy.focus_ring
		if focus_ring == null:
			focus_ring = enemy.get_node_or_null("FocusRing") as ColorRect
		if focus_ring != null:
			focus_ring.visible = false
		muted_count += 1
	return muted_count


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
