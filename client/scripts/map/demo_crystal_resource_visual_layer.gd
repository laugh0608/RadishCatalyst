extends Node2D
class_name DemoCrystalResourceVisualLayer

const RESOURCE_SHAPE_PREFIX := "DemoCrystalResourceVisual"
const ROLE_RESOURCE := "resource"
const ROLE_FLOW := "flow"
const ROLE_SALVAGE := "salvage"
const ROLE_TERRAIN := "terrain"
const FOCUS_VISIBLE_MIN_X := -80.0
const FOCUS_VISIBLE_MAX_X := 160.0
const CRYSTAL_FOCUS_CONTEXT_ROUTE_ALPHA := 0.0005
const CRYSTAL_FOCUS_CONTEXT_BOUNDARY_ALPHA := 0.0015
const CRYSTAL_FOCUS_CONTEXT_MARKER_ALPHA := 0.028
const CRYSTAL_FOCUS_LOCAL_MARKER_DISTANCE := 250.0

const CRYSTAL_FOCUS_CONTEXT_LAYER_ALPHAS := [
	{"path": "OpeningSceneLayer", "alpha": 0.012},
	{"path": "SceneArtFoundationLayer", "alpha": 0.0},
	{"path": "NonCoreSceneIdentityLayer", "alpha": 0.0},
	{"path": "FunctionalTransitionSpatialPlayabilityLayer", "alpha": 0.0},
	{"path": "MidfieldRoutePlayabilityLayer", "alpha": 0.0},
	{"path": "WindCorridorTransitionPlayabilityLayer", "alpha": 0.0},
	{"path": "CoreApproachHandoffLayer", "alpha": 0.0},
	{"path": "CoreStabilizationRunLayer", "alpha": 0.0},
	{"path": "DemoIndustrialBaseVisualLayer", "alpha": 0.032},
	{"path": "DemoPollutionBoundaryVisualLayer", "alpha": 0.0},
	{"path": "DemoCoreStabilizationVisualLayer", "alpha": 0.0},
	{"path": "DemoSceneFocusDepthLayer", "alpha": 0.006},
	{"path": "PrototypeVisualPriorityLayer", "alpha": 0.01},
	{"path": "DemoRegionIndustrialValueLayer", "alpha": 0.004},
	{"path": "DemoRoutePresentationLayer", "alpha": 0.0},
	{"path": "CurrentObjectiveGuidanceLayer", "alpha": 0.032}
]

const CRYSTAL_FOCUS_CONTEXT_ROUTE_PATHS := [
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

const CRYSTAL_FOCUS_CONTEXT_BOUNDARY_PATHS := [
	"RegionBoundaryCrystal",
	"RegionBoundaryPollution",
	"RegionBoundaryRuin"
]

const FIELD_FRAME := Color(0.32, 0.58, 0.62, 0.075)
const FIELD_FILL := Color(0.06, 0.12, 0.15, 0.0)
const ORE_FACE_FILL := Color(0.06, 0.18, 0.2, 0.045)
const ORE_FACE_LINE := Color(0.38, 0.78, 0.86, 0.13)
const CUT_SCARP_LINE := Color(0.72, 0.96, 1.0, 0.34)
const CRYSTAL_LINE := Color(0.42, 0.88, 0.98, 0.78)
const CRYSTAL_FILL := Color(0.25, 0.78, 0.95, 0.44)
const MINE_ISLAND_FILL := Color(0.08, 0.22, 0.26, 0.064)
const MINE_ISLAND_LINE := Color(0.56, 0.9, 0.98, 0.34)
const DARK_CUT_CHANNEL := Color(0.01, 0.035, 0.045, 0.56)
const ORE_CHIP_FILL := Color(0.16, 0.36, 0.42, 0.072)
const ORE_CHIP_LINE := Color(0.54, 0.86, 0.94, 0.26)
const MINE_BENCH_LINE := Color(0.68, 0.92, 0.96, 0.3)
const BROKEN_MINE_SHADOW_FILL := Color(0.02, 0.07, 0.08, 0.36)
const BROKEN_MINE_SHADOW_LINE := Color(0.28, 0.56, 0.62, 0.22)
const MINE_CUTOUT_FILL := Color(0.012, 0.034, 0.04, 0.64)
const MINE_CUTOUT_LINE := Color(0.22, 0.48, 0.54, 0.16)
const OLD_FIELD_VOID_FILL := Color(0.01, 0.026, 0.032, 0.58)
const OLD_FIELD_VOID_LINE := Color(0.24, 0.5, 0.54, 0.12)
const HARVEST_PAD_FILL := Color(0.07, 0.13, 0.14, 0.2)
const HARVEST_PAD_LINE := Color(0.68, 0.94, 1.0, 0.32)
const HAND_SAMPLE_POINT := Color(0.82, 0.96, 1.0, 0.44)
const AUTO_MINER_BODY := Color(0.1, 0.18, 0.16, 0.66)
const AUTO_MINER_LINE := Color(0.72, 0.94, 0.84, 0.46)
const AUTO_MINER_OUTPUT := Color(0.78, 0.9, 0.64, 0.44)
const RICH_CRYSTAL_LINE := Color(0.76, 0.94, 1.0, 0.86)
const SALVAGE_LINE := Color(0.72, 0.78, 0.68, 0.58)
const SALVAGE_FILL := Color(0.36, 0.42, 0.34, 0.26)
const SCRAP_YARD_FILL := Color(0.14, 0.18, 0.14, 0.22)
const SCRAP_YARD_EDGE := Color(0.64, 0.72, 0.58, 0.36)
const RETURN_FLOW := Color(0.72, 0.88, 0.58, 0.66)
const RETURN_RAIL := Color(0.76, 0.88, 0.64, 0.48)
const LOADING_TIE := Color(0.74, 0.86, 0.62, 0.26)
const ANOMALY_LINE := Color(0.68, 0.42, 0.72, 0.5)
const WARNING_DIM := Color(0.9, 0.42, 0.28, 0.42)

const LEGACY_CRYSTAL_PANELS := [
	"CrystalEntryGround",
	"CrystalNorthRidgeGround",
	"CrystalCentralFieldGround",
	"CrystalSouthSalvageYard",
	"CrystalScrapPocket",
	"CrystalLogisticsResourcePocket",
	"CrystalLogisticsReturnPocket"
]

const LEGACY_CRYSTAL_MARKERS := [
	"CrystalMainVeinTrack",
	"CrystalMainVeinStartAnchor",
	"CrystalMainVeinDeepAnchor",
	"CrystalSideRouteConnector",
	"CrystalSalvageObjectPocket",
	"CrystalLogisticsSpurLine",
	"CrystalLogisticsCrystalMarker",
	"CrystalLogisticsSalvageMarker",
	"CrystalLogisticsGuardMarker",
	"CrystalLogisticsReturnLine",
	"CrystalLogisticsReturnCrystalMarker",
	"CrystalLogisticsReturnSalvageMarker",
	"CrystalLogisticsReturnGuardMarker",
	"CrystalAnomalyPocketMarker",
	"CrystalAnomalyReturnAnchor"
]

const BASE_DEPARTURE_LABELS := [
	"BaseExitLaneLabel"
]

const RESOURCE_DEFINITION_IDS := {
	"map_object.crystal_cluster": true,
	"map_object.rich_crystal_vein": true,
	"map_object.crystal_collector_output": true,
	"map_object.field_wreckage": true,
	"map_object.anomaly_crystal": true,
	"map_object.anomaly_residue_patch": true
}

const CRYSTAL_FOCUS_LOCAL_INTERACTABLE_DEFINITION_IDS := {
	"map_object.outpost_departure_gate": true,
	"map_object.crystal_cluster": true,
	"map_object.rich_crystal_vein": true,
	"building.crystal_collector_t1": true,
	"map_object.crystal_collector_output": true,
	"map_object.field_wreckage": true,
	"map_object.anomaly_crystal": true,
	"map_object.anomaly_residue_patch": true
}

var resource_shape_ids: Array[String] = []
var flow_shape_ids: Array[String] = []
var terrain_material_shape_ids: Array[String] = []
var muted_resource_marker_count := 0
var muted_legacy_block_count := 0
var muted_departure_label_count := 0
var muted_departure_focus_count := 0
var muted_crystal_focus_context_layer_count := 0
var muted_crystal_focus_context_rect_count := 0
var muted_crystal_focus_context_marker_count := 0
var context_layer_original_modulates: Dictionary = {}


func _ready() -> void:
	process_priority = 80
	apply_visuals()
	refresh_focus_visibility(_get_player_position())


func _process(_delta: float) -> void:
	refresh_focus_visibility(_get_player_position())
	_tone_down_resource_interactable_markers()
	_mute_crystal_identity_blocks()
	_mute_base_departure_labels()


func apply_visuals() -> void:
	_deemphasize_legacy_crystal_blocks()
	_mute_base_departure_labels()
	_mute_crystal_identity_blocks()
	_register_resource_shapes()
	_register_flow_shapes()
	_register_terrain_material_shapes()
	_tone_down_resource_interactable_markers()
	queue_redraw()


func get_resource_shape_count() -> int:
	return resource_shape_ids.size()


func get_flow_count() -> int:
	return flow_shape_ids.size()


func get_terrain_material_shape_count() -> int:
	return terrain_material_shape_ids.size()


func get_muted_resource_marker_count() -> int:
	return muted_resource_marker_count


func get_muted_legacy_block_count() -> int:
	return muted_legacy_block_count


func get_muted_departure_label_count() -> int:
	return muted_departure_label_count


func get_muted_departure_focus_count() -> int:
	return muted_departure_focus_count


func get_muted_crystal_focus_context_layer_count() -> int:
	return muted_crystal_focus_context_layer_count


func get_muted_crystal_focus_context_rect_count() -> int:
	return muted_crystal_focus_context_rect_count


func get_muted_crystal_focus_context_marker_count() -> int:
	return muted_crystal_focus_context_marker_count


func has_resource_shape(shape_id: String) -> bool:
	return resource_shape_ids.has(shape_id)


func has_flow_shape(shape_id: String) -> bool:
	return flow_shape_ids.has(shape_id)


func has_terrain_material_shape(shape_id: String) -> bool:
	return terrain_material_shape_ids.has(shape_id)


func refresh_focus_visibility(player_position: Vector2) -> void:
	visible = player_position.x >= FOCUS_VISIBLE_MIN_X and player_position.x <= FOCUS_VISIBLE_MAX_X
	_mute_departure_interactable_focus(player_position)
	_update_crystal_focus_context_layers()
	_mute_crystal_focus_context_rects()
	_mute_crystal_focus_context_interactable_markers(player_position)


func _draw() -> void:
	_draw_field_frame()
	_draw_mining_material_surface()
	_draw_main_vein()
	_draw_crystal_clusters()
	_draw_collection_equipment()
	_draw_salvage_pockets()
	_draw_return_flows()
	_draw_anomaly_pocket()


func _draw_field_frame() -> void:
	var field_rect := Rect2(Vector2(-18.0, -270.0), Vector2(250.0, 332.0))
	var salvage_rect := Rect2(Vector2(-10.0, 80.0), Vector2(258.0, 178.0))
	draw_rect(field_rect, FIELD_FILL, true)
	_draw_corner_frame(field_rect, FIELD_FRAME, 28.0, 1.0)
	draw_rect(salvage_rect, Color(0.05, 0.09, 0.1, 0.035), true)
	_draw_corner_frame(salvage_rect, Color(0.44, 0.58, 0.52, 0.09), 30.0, 1.1)
	for y in [-206.0, -126.0, -36.0, 116.0, 206.0]:
		draw_line(Vector2(-8.0, y), Vector2(88.0, y), Color(0.34, 0.52, 0.54, 0.045), 1.0, true)
	draw_line(Vector2(8.0, -72.0), Vector2(96.0, -72.0), Color(0.35, 0.9, 0.98, 0.11), 1.8, true)


func _draw_mining_material_surface() -> void:
	_draw_harvest_face_floor()
	_draw_broken_mine_shadow_patches()
	_draw_mine_cutout_baffles()
	_draw_old_field_voids()
	_draw_mine_face_islands()
	_draw_dark_cut_channels()
	_draw_broken_ore_tiles()
	_draw_local_harvest_work_pads()
	_draw_rich_seam_ridges()
	_draw_cut_scarps()
	_draw_mine_bench_steps()
	_draw_scrap_recovery_yard()
	_draw_salvage_sorting_lanes()
	_draw_return_cart_lane()
	_draw_loading_sleepers()
	_draw_base_loading_mouth()


func _draw_harvest_face_floor() -> void:
	var face := PackedVector2Array([
		Vector2(6.0, -214.0),
		Vector2(64.0, -252.0),
		Vector2(166.0, -236.0),
		Vector2(224.0, -184.0),
		Vector2(210.0, -110.0),
		Vector2(112.0, -80.0),
		Vector2(22.0, -116.0),
		Vector2(6.0, -214.0)
	])
	draw_colored_polygon(face, ORE_FACE_FILL)
	draw_polyline(face, ORE_FACE_LINE, 2.0, true)
	for y in [-220.0, -194.0, -166.0, -136.0, -108.0]:
		draw_line(Vector2(22.0, y), Vector2(204.0, y + 28.0), Color(ORE_FACE_LINE.r, ORE_FACE_LINE.g, ORE_FACE_LINE.b, 0.12), 1.0, true)
	for point in [Vector2(44.0, -188.0), Vector2(86.0, -210.0), Vector2(138.0, -190.0), Vector2(184.0, -156.0)]:
		draw_circle(point, 3.0, Color(0.74, 0.96, 1.0, 0.36))


func _draw_mine_face_islands() -> void:
	for island in [
		[
			Vector2(18.0, -216.0),
			Vector2(66.0, -246.0),
			Vector2(122.0, -232.0),
			Vector2(104.0, -188.0),
			Vector2(36.0, -184.0),
			Vector2(18.0, -216.0)
		],
		[
			Vector2(122.0, -220.0),
			Vector2(178.0, -206.0),
			Vector2(216.0, -168.0),
			Vector2(188.0, -132.0),
			Vector2(134.0, -150.0),
			Vector2(122.0, -220.0)
		],
		[
			Vector2(28.0, -134.0),
			Vector2(90.0, -156.0),
			Vector2(152.0, -126.0),
			Vector2(132.0, -82.0),
			Vector2(52.0, -90.0),
			Vector2(28.0, -134.0)
		],
		[
			Vector2(92.0, -56.0),
			Vector2(160.0, -46.0),
			Vector2(218.0, -4.0),
			Vector2(178.0, 26.0),
			Vector2(110.0, 0.0),
			Vector2(92.0, -56.0)
		]
	]:
		var polygon := PackedVector2Array(island)
		draw_polyline(polygon, DARK_CUT_CHANNEL, 5.0, true)
		draw_colored_polygon(polygon, MINE_ISLAND_FILL)
		draw_polyline(polygon, MINE_ISLAND_LINE, 1.5, true)
		var center := _polygon_center(polygon)
		draw_line(center + Vector2(-20.0, -8.0), center + Vector2(24.0, 10.0), Color(MINE_ISLAND_LINE.r, MINE_ISLAND_LINE.g, MINE_ISLAND_LINE.b, 0.22), 1.0, true)


func _draw_dark_cut_channels() -> void:
	for channel in [
		[Vector2(110.0, -236.0), Vector2(116.0, -178.0), Vector2(108.0, -124.0), Vector2(118.0, -72.0)],
		[Vector2(22.0, -172.0), Vector2(76.0, -168.0), Vector2(144.0, -144.0), Vector2(212.0, -108.0)],
		[Vector2(48.0, -80.0), Vector2(106.0, -62.0), Vector2(174.0, -32.0), Vector2(216.0, 4.0)]
	]:
		var points := PackedVector2Array(channel)
		draw_polyline(points, DARK_CUT_CHANNEL, 6.0, true)
		draw_polyline(points, Color(0.42, 0.74, 0.82, 0.14), 1.2, true)


func _draw_broken_ore_tiles() -> void:
	for tile in [
		[
			Vector2(24.0, -220.0),
			Vector2(72.0, -236.0),
			Vector2(108.0, -216.0),
			Vector2(92.0, -180.0),
			Vector2(34.0, -186.0),
			Vector2(24.0, -220.0)
		],
		[
			Vector2(104.0, -206.0),
			Vector2(166.0, -214.0),
			Vector2(208.0, -176.0),
			Vector2(186.0, -140.0),
			Vector2(130.0, -154.0),
			Vector2(104.0, -206.0)
		],
		[
			Vector2(36.0, -128.0),
			Vector2(96.0, -148.0),
			Vector2(146.0, -126.0),
			Vector2(114.0, -92.0),
			Vector2(48.0, -96.0),
			Vector2(36.0, -128.0)
		],
		[
			Vector2(132.0, -88.0),
			Vector2(196.0, -72.0),
			Vector2(222.0, -26.0),
			Vector2(176.0, 4.0),
			Vector2(126.0, -28.0),
			Vector2(132.0, -88.0)
		]
	]:
		var polygon := PackedVector2Array(tile)
		draw_colored_polygon(polygon, ORE_CHIP_FILL)
		draw_polyline(polygon, ORE_CHIP_LINE, 1.1, true)


func _draw_broken_mine_shadow_patches() -> void:
	for patch in [
		[
			Vector2(34.0, -232.0),
			Vector2(92.0, -246.0),
			Vector2(138.0, -220.0),
			Vector2(98.0, -186.0),
			Vector2(42.0, -194.0),
			Vector2(34.0, -232.0)
		],
		[
			Vector2(116.0, -174.0),
			Vector2(204.0, -158.0),
			Vector2(224.0, -104.0),
			Vector2(170.0, -72.0),
			Vector2(110.0, -104.0),
			Vector2(116.0, -174.0)
		],
		[
			Vector2(30.0, -78.0),
			Vector2(104.0, -58.0),
			Vector2(166.0, -18.0),
			Vector2(110.0, 22.0),
			Vector2(40.0, -8.0),
			Vector2(30.0, -78.0)
		]
	]:
		var polygon := PackedVector2Array(patch)
		draw_colored_polygon(polygon, BROKEN_MINE_SHADOW_FILL)
		draw_polyline(polygon, BROKEN_MINE_SHADOW_LINE, 1.1, true)


func _draw_mine_cutout_baffles() -> void:
	for baffle in [
		[
			Vector2(-16.0, -252.0),
			Vector2(22.0, -246.0),
			Vector2(14.0, -94.0),
			Vector2(-18.0, -106.0),
			Vector2(-16.0, -252.0)
		],
		[
			Vector2(72.0, -252.0),
			Vector2(228.0, -246.0),
			Vector2(228.0, -218.0),
			Vector2(128.0, -224.0),
			Vector2(74.0, -204.0),
			Vector2(72.0, -252.0)
		],
		[
			Vector2(194.0, -176.0),
			Vector2(232.0, -148.0),
			Vector2(232.0, -70.0),
			Vector2(180.0, -92.0),
			Vector2(194.0, -176.0)
		],
		[
			Vector2(12.0, -36.0),
			Vector2(92.0, -28.0),
			Vector2(118.0, 30.0),
			Vector2(20.0, 22.0),
			Vector2(12.0, -36.0)
		],
		[
			Vector2(118.0, -132.0),
			Vector2(160.0, -118.0),
			Vector2(116.0, -78.0),
			Vector2(78.0, -94.0),
			Vector2(118.0, -132.0)
		]
	]:
		var polygon := PackedVector2Array(baffle)
		draw_colored_polygon(polygon, MINE_CUTOUT_FILL)
		draw_polyline(polygon, MINE_CUTOUT_LINE, 1.0, true)


func _draw_old_field_voids() -> void:
	for void_patch in [
		[
			Vector2(20.0, -246.0),
			Vector2(62.0, -238.0),
			Vector2(48.0, -190.0),
			Vector2(12.0, -204.0),
			Vector2(20.0, -246.0)
		],
		[
			Vector2(90.0, -186.0),
			Vector2(150.0, -174.0),
			Vector2(138.0, -126.0),
			Vector2(72.0, -142.0),
			Vector2(90.0, -186.0)
		],
		[
			Vector2(156.0, -116.0),
			Vector2(222.0, -92.0),
			Vector2(206.0, -42.0),
			Vector2(144.0, -66.0),
			Vector2(156.0, -116.0)
		],
		[
			Vector2(38.0, -52.0),
			Vector2(104.0, -36.0),
			Vector2(96.0, 12.0),
			Vector2(30.0, 2.0),
			Vector2(38.0, -52.0)
		]
	]:
		var polygon := PackedVector2Array(void_patch)
		draw_colored_polygon(polygon, OLD_FIELD_VOID_FILL)
		draw_polyline(polygon, OLD_FIELD_VOID_LINE, 1.0, true)


func _draw_corner_frame(rect: Rect2, color: Color, corner_length: float, width: float) -> void:
	var left := rect.position.x
	var right := rect.position.x + rect.size.x
	var top := rect.position.y
	var bottom := rect.position.y + rect.size.y
	draw_line(Vector2(left, top), Vector2(left + corner_length, top), color, width, true)
	draw_line(Vector2(left, top), Vector2(left, top + corner_length), color, width, true)
	draw_line(Vector2(right, top), Vector2(right - corner_length, top), color, width, true)
	draw_line(Vector2(right, top), Vector2(right, top + corner_length), color, width, true)
	draw_line(Vector2(left, bottom), Vector2(left + corner_length, bottom), color, width, true)
	draw_line(Vector2(left, bottom), Vector2(left, bottom - corner_length), color, width, true)
	draw_line(Vector2(right, bottom), Vector2(right - corner_length, bottom), color, width, true)
	draw_line(Vector2(right, bottom), Vector2(right, bottom - corner_length), color, width, true)


func _draw_local_harvest_work_pads() -> void:
	for pad in [
		Rect2(Vector2(30.0, -174.0), Vector2(42.0, 18.0)),
		Rect2(Vector2(114.0, -188.0), Vector2(50.0, 18.0)),
		Rect2(Vector2(150.0, -92.0), Vector2(42.0, 18.0)),
		Rect2(Vector2(72.0, -18.0), Vector2(46.0, 18.0))
	]:
		draw_rect(pad, HARVEST_PAD_FILL, true)
		draw_rect(pad, HARVEST_PAD_LINE, false, 1.1, true)
		draw_line(
			pad.position + Vector2(6.0, pad.size.y * 0.5),
			pad.position + Vector2(pad.size.x - 6.0, pad.size.y * 0.5 - 3.0),
			Color(HARVEST_PAD_LINE.r, HARVEST_PAD_LINE.g, HARVEST_PAD_LINE.b, 0.32),
			1.2,
			true
		)
	for point in [Vector2(50.0, -164.0), Vector2(138.0, -180.0), Vector2(172.0, -84.0), Vector2(94.0, -10.0)]:
		draw_circle(point, 3.2, Color(0.82, 0.96, 1.0, 0.34))


func _draw_collection_equipment() -> void:
	_draw_hand_sampling_probe(Vector2(24.0, -88.0))
	_draw_field_auto_miner(Vector2(112.0, -142.0), 1.0)
	_draw_field_auto_miner(Vector2(170.0, -82.0), 0.82)
	_draw_output_loading_tray(Vector2(92.0, -38.0))
	_draw_output_loading_tray(Vector2(194.0, 196.0), 0.86)
	_draw_flow([Vector2(112.0, -142.0), Vector2(104.0, -86.0), Vector2(92.0, -38.0)], AUTO_MINER_OUTPUT, 2.6)
	_draw_flow([Vector2(170.0, -82.0), Vector2(142.0, -38.0), Vector2(92.0, -38.0)], Color(AUTO_MINER_OUTPUT.r, AUTO_MINER_OUTPUT.g, AUTO_MINER_OUTPUT.b, 0.34), 2.0)


func _draw_hand_sampling_probe(center: Vector2) -> void:
	draw_circle(center, 10.0, Color(HAND_SAMPLE_POINT.r, HAND_SAMPLE_POINT.g, HAND_SAMPLE_POINT.b, 0.1))
	draw_arc(center, 15.0, PI * 0.08, PI * 1.78, 28, HAND_SAMPLE_POINT, 1.3, true)
	draw_line(center + Vector2(-10.0, 8.0), center + Vector2(8.0, -8.0), HAND_SAMPLE_POINT, 1.8, true)
	draw_circle(center + Vector2(8.0, -8.0), 3.2, Color(HAND_SAMPLE_POINT.r, HAND_SAMPLE_POINT.g, HAND_SAMPLE_POINT.b, 0.72))


func _draw_field_auto_miner(center: Vector2, scale: float) -> void:
	var body := Rect2(center + Vector2(-18.0, -12.0) * scale, Vector2(38.0, 24.0) * scale)
	draw_rect(body, AUTO_MINER_BODY, true)
	draw_rect(body, Color(AUTO_MINER_LINE.r, AUTO_MINER_LINE.g, AUTO_MINER_LINE.b, 0.46), false, 1.3, true)
	for leg in [Vector2(-18.0, 10.0), Vector2(18.0, 10.0), Vector2(-14.0, -10.0)]:
		var foot_offset := Vector2(-12.0 if leg.x < 0.0 else 12.0, 18.0 if leg.y > 0.0 else -18.0) * scale
		draw_line(center + leg * scale, center + leg * scale + foot_offset, Color(AUTO_MINER_LINE.r, AUTO_MINER_LINE.g, AUTO_MINER_LINE.b, 0.26), 2.0 * scale, true)
	var head := center + Vector2(20.0, -6.0) * scale
	draw_arc(head, 18.0 * scale, PI * 0.08, PI * 1.86, 30, AUTO_MINER_LINE, 2.2 * scale, true)
	draw_line(head + Vector2(12.0, 0.0) * scale, head + Vector2(30.0, -14.0) * scale, AUTO_MINER_LINE, 2.0 * scale, true)
	draw_circle(head + Vector2(30.0, -14.0) * scale, 3.2 * scale, Color(0.88, 1.0, 0.9, 0.48))
	var output := Rect2(center + Vector2(-46.0, -4.0) * scale, Vector2(24.0, 12.0) * scale)
	draw_rect(output, Color(0.02, 0.04, 0.035, 0.6), true)
	draw_rect(output, AUTO_MINER_OUTPUT, false, 1.0 * scale, true)
	draw_line(center + Vector2(-18.0, 2.0) * scale, center + Vector2(-24.0, 2.0) * scale, AUTO_MINER_OUTPUT, 1.8 * scale, true)


func _draw_output_loading_tray(center: Vector2, scale: float = 1.0) -> void:
	var tray := Rect2(center + Vector2(-18.0, -9.0) * scale, Vector2(36.0, 18.0) * scale)
	draw_rect(tray, Color(0.04, 0.07, 0.055, 0.56), true)
	draw_rect(tray, AUTO_MINER_OUTPUT, false, 1.4 * scale, true)
	for x in [-10.0, 0.0, 10.0]:
		draw_circle(center + Vector2(x, 0.0) * scale, 2.8 * scale, Color(AUTO_MINER_OUTPUT.r, AUTO_MINER_OUTPUT.g, AUTO_MINER_OUTPUT.b, 0.42))


func _draw_rich_seam_ridges() -> void:
	var ridge_points := [
		[Vector2(88.0, -236.0), Vector2(136.0, -218.0), Vector2(190.0, -174.0)],
		[Vector2(58.0, -180.0), Vector2(124.0, -160.0), Vector2(214.0, -148.0)],
		[Vector2(120.0, -114.0), Vector2(160.0, -88.0), Vector2(198.0, -42.0)]
	]
	for points in ridge_points:
		draw_polyline(PackedVector2Array(points), Color(0.08, 0.14, 0.16, 0.42), 4.6, true)
		draw_polyline(PackedVector2Array(points), Color(RICH_CRYSTAL_LINE.r, RICH_CRYSTAL_LINE.g, RICH_CRYSTAL_LINE.b, 0.34), 1.6, true)
	for point in [Vector2(150.0, -176.0), Vector2(198.0, -158.0), Vector2(174.0, -18.0)]:
		draw_arc(point, 18.0, PI * 0.15, PI * 1.8, 24, Color(0.78, 0.96, 1.0, 0.2), 1.2, true)


func _draw_cut_scarps() -> void:
	for pair in [
		[Vector2(28.0, -96.0), Vector2(96.0, -74.0)],
		[Vector2(94.0, -68.0), Vector2(174.0, -42.0)],
		[Vector2(110.0, 4.0), Vector2(206.0, 28.0)]
	]:
		var from_point: Vector2 = pair[0]
		var to_point: Vector2 = pair[1]
		draw_line(from_point, to_point, Color(0.02, 0.06, 0.07, 0.38), 4.2, true)
		draw_line(from_point, to_point, CUT_SCARP_LINE, 1.5, true)
		var mid := from_point.lerp(to_point, 0.5)
		draw_line(mid + Vector2(-10.0, -8.0), mid + Vector2(12.0, 8.0), Color(CUT_SCARP_LINE.r, CUT_SCARP_LINE.g, CUT_SCARP_LINE.b, 0.24), 1.0, true)


func _draw_mine_bench_steps() -> void:
	for points in [
		[Vector2(18.0, -242.0), Vector2(62.0, -260.0), Vector2(156.0, -246.0), Vector2(224.0, -194.0)],
		[Vector2(16.0, -176.0), Vector2(74.0, -164.0), Vector2(148.0, -142.0), Vector2(218.0, -118.0)],
		[Vector2(24.0, -76.0), Vector2(88.0, -54.0), Vector2(164.0, -34.0), Vector2(224.0, -8.0)]
	]:
		draw_polyline(PackedVector2Array(points), Color(0.02, 0.06, 0.07, 0.34), 4.0, true)
		draw_polyline(PackedVector2Array(points), MINE_BENCH_LINE, 1.4, true)


func _draw_scrap_recovery_yard() -> void:
	var yard := Rect2(Vector2(18.0, 92.0), Vector2(230.0, 150.0))
	draw_rect(yard, SCRAP_YARD_FILL, true)
	draw_rect(yard, SCRAP_YARD_EDGE, false, 1.5, true)
	for y in [116.0, 150.0, 184.0, 218.0]:
		draw_line(Vector2(28.0, y), Vector2(238.0, y), Color(SCRAP_YARD_EDGE.r, SCRAP_YARD_EDGE.g, SCRAP_YARD_EDGE.b, 0.2), 1.0, true)
	for x in [58.0, 112.0, 166.0, 220.0]:
		draw_line(Vector2(x, 102.0), Vector2(x + 12.0, 232.0), Color(SCRAP_YARD_EDGE.r, SCRAP_YARD_EDGE.g, SCRAP_YARD_EDGE.b, 0.16), 1.0, true)
	for rect in [
		Rect2(Vector2(68.0, 116.0), Vector2(22.0, 14.0)),
		Rect2(Vector2(130.0, 150.0), Vector2(26.0, 16.0)),
		Rect2(Vector2(196.0, 206.0), Vector2(24.0, 14.0))
	]:
		draw_rect(rect, Color(0.42, 0.48, 0.36, 0.34), true)
		draw_rect(rect, SALVAGE_LINE, false, 1.0, true)


func _draw_salvage_sorting_lanes() -> void:
	for lane in [
		[Vector2(44.0, 104.0), Vector2(112.0, 126.0), Vector2(206.0, 118.0)],
		[Vector2(34.0, 156.0), Vector2(104.0, 168.0), Vector2(216.0, 206.0)],
		[Vector2(72.0, 222.0), Vector2(136.0, 198.0), Vector2(226.0, 232.0)]
	]:
		draw_polyline(PackedVector2Array(lane), Color(0.02, 0.04, 0.035, 0.36), 4.4, true)
		draw_polyline(PackedVector2Array(lane), Color(SALVAGE_LINE.r, SALVAGE_LINE.g, SALVAGE_LINE.b, 0.36), 1.2, true)
	for point in [Vector2(80.0, 116.0), Vector2(146.0, 134.0), Vector2(114.0, 168.0), Vector2(198.0, 210.0)]:
		draw_circle(point, 3.2, Color(0.78, 0.86, 0.64, 0.24))


func _draw_return_cart_lane() -> void:
	var lane_points := [Vector2(206.0, 200.0), Vector2(120.0, 158.0), Vector2(28.0, 90.0), Vector2(-42.0, 18.0)]
	draw_polyline(PackedVector2Array(lane_points), Color(0.02, 0.04, 0.035, 0.5), 8.0, true)
	draw_polyline(PackedVector2Array(lane_points), RETURN_RAIL, 2.0, true)
	for point in [Vector2(170.0, 182.0), Vector2(92.0, 138.0), Vector2(24.0, 90.0), Vector2(-22.0, 38.0)]:
		draw_line(point + Vector2(-8.0, -5.0), point + Vector2(8.0, 5.0), Color(RETURN_RAIL.r, RETURN_RAIL.g, RETURN_RAIL.b, 0.34), 1.0, true)
		draw_circle(point, 2.5, Color(0.86, 0.94, 0.68, 0.32))


func _draw_loading_sleepers() -> void:
	for point in [Vector2(182.0, 188.0), Vector2(146.0, 168.0), Vector2(108.0, 146.0), Vector2(68.0, 120.0), Vector2(30.0, 92.0), Vector2(-10.0, 54.0)]:
		draw_line(point + Vector2(-10.0, -5.0), point + Vector2(10.0, 5.0), LOADING_TIE, 1.4, true)


func _draw_base_loading_mouth() -> void:
	var mouth := Rect2(Vector2(-86.0, -4.0), Vector2(38.0, 44.0))
	draw_rect(mouth, Color(0.06, 0.1, 0.08, 0.42), true)
	draw_rect(mouth, RETURN_FLOW, false, 1.8, true)
	draw_line(Vector2(-80.0, 6.0), Vector2(-54.0, 6.0), Color(RETURN_FLOW.r, RETURN_FLOW.g, RETURN_FLOW.b, 0.5), 1.3, true)
	draw_line(Vector2(-80.0, 18.0), Vector2(-54.0, 18.0), Color(RETURN_FLOW.r, RETURN_FLOW.g, RETURN_FLOW.b, 0.5), 1.3, true)
	draw_line(Vector2(-80.0, 30.0), Vector2(-54.0, 30.0), Color(RETURN_FLOW.r, RETURN_FLOW.g, RETURN_FLOW.b, 0.5), 1.3, true)


func _draw_main_vein() -> void:
	_draw_flow(
		[
			Vector2(10.0, -88.0),
			Vector2(50.0, -150.0),
			Vector2(110.0, -176.0),
			Vector2(154.0, -176.0),
			Vector2(210.0, -156.0)
		],
		CRYSTAL_LINE,
		4.0
	)
	_draw_flow([Vector2(42.0, -132.0), Vector2(92.0, -38.0), Vector2(174.0, -18.0)], Color(0.32, 0.76, 0.88, 0.58), 3.0)
	_draw_flow([Vector2(92.0, -38.0), Vector2(92.0, 92.0), Vector2(194.0, 196.0)], RETURN_FLOW, 3.0)
	draw_circle(Vector2(50.0, -150.0), 4.0, CRYSTAL_LINE)
	draw_circle(Vector2(154.0, -176.0), 4.0, RICH_CRYSTAL_LINE)


func _draw_crystal_clusters() -> void:
	_draw_crystal_node(Vector2(24.0, -88.0), 1.0, CRYSTAL_LINE)
	_draw_crystal_node(Vector2(50.0, -158.0), 0.82, CRYSTAL_LINE)
	_draw_crystal_node(Vector2(122.0, -112.0), 0.78, CRYSTAL_LINE)
	_draw_crystal_node(Vector2(174.0, -18.0), 0.72, CRYSTAL_LINE)
	_draw_crystal_node(Vector2(92.0, 92.0), 0.76, CRYSTAL_LINE)
	_draw_crystal_node(Vector2(194.0, 196.0), 0.74, CRYSTAL_LINE)
	_draw_rich_crystal_vein(Vector2(150.0, -176.0))
	_draw_rich_crystal_vein(Vector2(210.0, -156.0), 0.72)


func _draw_salvage_pockets() -> void:
	_draw_scrap_pile(Vector2(52.0, 112.0), 1.0)
	_draw_scrap_pile(Vector2(150.0, 138.0), 0.9)
	_draw_scrap_pile(Vector2(214.0, 82.0), 0.86)
	_draw_scrap_pile(Vector2(40.0, 160.0), 0.82)
	_draw_scrap_pile(Vector2(232.0, 218.0), 0.78)
	_draw_scrap_pile(Vector2(224.0, -112.0), 0.7)
	_draw_flow([Vector2(52.0, 112.0), Vector2(92.0, 118.0), Vector2(150.0, 138.0), Vector2(232.0, 218.0)], SALVAGE_LINE, 2.4)
	_draw_flow([Vector2(214.0, 82.0), Vector2(194.0, 126.0), Vector2(150.0, 138.0)], SALVAGE_LINE, 2.0)


func _draw_return_flows() -> void:
	_draw_flow([Vector2(194.0, 196.0), Vector2(110.0, 152.0), Vector2(24.0, 96.0), Vector2(-42.0, 18.0)], RETURN_FLOW, 3.2)
	_draw_flow([Vector2(52.0, 112.0), Vector2(-12.0, 84.0), Vector2(-74.0, 18.0)], Color(0.64, 0.8, 0.58, 0.46), 2.8)
	draw_circle(Vector2(-42.0, 18.0), 4.0, RETURN_FLOW)
	draw_circle(Vector2(-74.0, 18.0), 4.0, Color(0.84, 0.94, 0.66, 0.5))


func _draw_anomaly_pocket() -> void:
	var center := Vector2(194.0, 126.0)
	draw_arc(center, 26.0, -0.2, TAU - 0.2, 42, ANOMALY_LINE, 2.0, true)
	draw_arc(center, 14.0, 0.2, TAU + 0.2, 32, Color(0.72, 0.42, 0.78, 0.34), 1.6, true)
	draw_line(Vector2(134.0, 154.0), Vector2(224.0, 138.0), Color(0.78, 0.5, 0.8, 0.3), 2.0, true)
	draw_circle(Vector2(134.0, 154.0), 5.0, WARNING_DIM)
	draw_circle(Vector2(224.0, 138.0), 5.0, WARNING_DIM)


func _draw_crystal_node(center: Vector2, scale: float, color: Color) -> void:
	var width := 12.0 * scale
	var height := 22.0 * scale
	var points := PackedVector2Array([
		center + Vector2(0.0, -height),
		center + Vector2(width, -2.0 * scale),
		center + Vector2(4.0 * scale, height),
		center + Vector2(-width, 4.0 * scale),
		center + Vector2(0.0, -height)
	])
	draw_colored_polygon(points, Color(CRYSTAL_FILL.r, CRYSTAL_FILL.g, CRYSTAL_FILL.b, CRYSTAL_FILL.a * scale))
	draw_polyline(points, color, 2.0, true)
	draw_line(center + Vector2(0.0, -height + 4.0 * scale), center + Vector2(0.0, height - 4.0 * scale), Color(0.72, 0.96, 1.0, 0.62), 1.4, true)


func _draw_rich_crystal_vein(center: Vector2, scale: float = 1.0) -> void:
	_draw_crystal_node(center + Vector2(-10.0, 0.0) * scale, 1.08 * scale, RICH_CRYSTAL_LINE)
	_draw_crystal_node(center + Vector2(8.0, -8.0) * scale, 0.86 * scale, RICH_CRYSTAL_LINE)
	_draw_crystal_node(center + Vector2(20.0, 8.0) * scale, 0.62 * scale, CRYSTAL_LINE)
	draw_arc(center, 30.0 * scale, 0.0, TAU, 40, Color(0.74, 0.94, 1.0, 0.26), 1.5, true)


func _draw_scrap_pile(center: Vector2, scale: float) -> void:
	var body := PackedVector2Array([
		center + Vector2(-18.0, 12.0) * scale,
		center + Vector2(-12.0, -10.0) * scale,
		center + Vector2(4.0, -16.0) * scale,
		center + Vector2(18.0, -4.0) * scale,
		center + Vector2(14.0, 14.0) * scale,
		center + Vector2(-18.0, 12.0) * scale
	])
	draw_colored_polygon(body, SALVAGE_FILL)
	draw_polyline(body, SALVAGE_LINE, 1.8, true)
	draw_line(center + Vector2(-10.0, -2.0) * scale, center + Vector2(12.0, -8.0) * scale, SALVAGE_LINE, 2.0, true)
	draw_line(center + Vector2(-12.0, 8.0) * scale, center + Vector2(8.0, 8.0) * scale, Color(0.84, 0.9, 0.72, 0.42), 1.6, true)


func _draw_flow(points: Array[Vector2], color: Color, width: float) -> void:
	draw_polyline(PackedVector2Array(points), Color(0.02, 0.04, 0.04, 0.5), width + 2.8, true)
	draw_polyline(PackedVector2Array(points), color, width, true)


func _polygon_center(points: PackedVector2Array) -> Vector2:
	var sum := Vector2.ZERO
	var count := points.size() - 1
	if count < 1:
		count = 1
	for index in range(count):
		sum += points[index]
	return sum / float(count)


func _register_resource_shapes() -> void:
	resource_shape_ids = [
		"crystal.main_vein",
		"crystal.rich_vein",
		"crystal.hand_sample_probe",
		"crystal.auto_miner.primary",
		"crystal.auto_miner.secondary",
		"crystal.auto_miner.output_tray",
		"crystal.cluster.entry",
		"crystal.cluster.side_pocket",
		"crystal.cluster.logistics_return",
		"salvage.north_pocket",
		"salvage.south_pocket",
		"salvage.logistics_return",
		"anomaly.crystal_pocket"
	]


func _register_flow_shapes() -> void:
	flow_shape_ids = [
		"flow.crystal_to_base",
		"flow.auto_miner_to_loading_tray",
		"flow.salvage_to_base",
		"flow.crystal_branch",
		"flow.salvage_branch"
	]


func _register_terrain_material_shapes() -> void:
	terrain_material_shape_ids = [
		"terrain.crystal.harvest_face",
		"terrain.crystal.broken_mine_shadow_patches",
		"terrain.crystal.mine_cutout_baffles",
		"terrain.crystal.old_field_voids",
		"terrain.crystal.mine_face_islands",
		"terrain.crystal.dark_cut_channels",
		"terrain.crystal.fractured_ore_tiles",
		"terrain.crystal.local_harvest_work_pads",
		"terrain.crystal.rich_seam_ridges",
		"terrain.crystal.cut_scarps",
		"terrain.crystal.mine_bench_steps",
		"terrain.crystal.scrap_recovery_yard",
		"terrain.crystal.salvage_sorting_lanes",
		"terrain.crystal.return_cart_lane",
		"terrain.crystal.loading_sleepers",
		"terrain.crystal.base_loading_mouth"
	]


func _deemphasize_legacy_crystal_blocks() -> void:
	muted_legacy_block_count = 0
	var region := _get_map_node("RegionCrystal") as ColorRect
	if region != null:
		region.color = Color(0.05, 0.09, 0.12, 0.045)
	var demo_route_band := _get_map_node("DemoRoutePresentationLayer/DemoRouteCrystalBand") as ColorRect
	if demo_route_band != null:
		demo_route_band.color = Color(demo_route_band.color.r, demo_route_band.color.g, demo_route_band.color.b, 0.0)
		demo_route_band.visible = false
	var route_label := _get_map_node("DemoRoutePresentationLayer/DemoRouteCrystalLabel") as Label
	if route_label != null:
		route_label.visible = false
	var base_route := _get_map_node("BaseToCrystalRouteBand") as ColorRect
	if base_route != null:
		base_route.color.a = minf(base_route.color.a, 0.004)
	var pollution_route := _get_map_node("CrystalToPollutionRouteBand") as ColorRect
	if pollution_route != null:
		pollution_route.color.a = minf(pollution_route.color.a, 0.002)

	var layer := _get_map_node("OpeningSceneLayer")
	if layer == null:
		return
	for node_name in LEGACY_CRYSTAL_PANELS:
		var rect := layer.get_node_or_null(String(node_name)) as ColorRect
		if rect != null:
			rect.color.a = minf(rect.color.a, 0.001)
			rect.visible = false
			muted_legacy_block_count += 1
	for node_name in LEGACY_CRYSTAL_MARKERS:
		var rect := layer.get_node_or_null(String(node_name)) as ColorRect
		if rect != null:
			rect.color.a = minf(rect.color.a, 0.001)
			rect.visible = false
			muted_legacy_block_count += 1


func _mute_base_departure_labels() -> void:
	muted_departure_label_count = 0
	var layer := _get_map_node("OpeningSceneLayer")
	if layer == null:
		return
	for node_name in BASE_DEPARTURE_LABELS:
		var label := layer.get_node_or_null(String(node_name)) as Label
		if label != null:
			label.visible = false
			muted_departure_label_count += 1


func _mute_departure_interactable_focus(player_position: Vector2) -> void:
	muted_departure_focus_count = 0
	if not visible:
		return
	var gate := _get_map_node("Interactables/OutpostDepartureGate") as PrototypeInteractable
	if gate == null:
		return
	var label := gate.get_node_or_null("Label") as Label
	if label != null:
		label.visible = false
	var focus_ring := gate.get_node_or_null("FocusRing") as ColorRect
	if focus_ring != null:
		focus_ring.visible = false
	var marker := gate.get_node_or_null("Marker") as ColorRect
	if marker != null:
		marker.scale = Vector2.ONE
	if player_position.x >= FOCUS_VISIBLE_MIN_X:
		muted_departure_focus_count = 1


func _update_crystal_focus_context_layers() -> void:
	if not visible:
		_restore_crystal_focus_context_layers()
		return
	muted_crystal_focus_context_layer_count = 0
	for layer_profile in CRYSTAL_FOCUS_CONTEXT_LAYER_ALPHAS:
		var path := String(layer_profile.get("path", ""))
		var alpha := float(layer_profile.get("alpha", 1.0))
		if _apply_context_layer_alpha(path, alpha):
			muted_crystal_focus_context_layer_count += 1


func _mute_crystal_focus_context_rects() -> void:
	muted_crystal_focus_context_rect_count = 0
	if not visible:
		return
	for path in CRYSTAL_FOCUS_CONTEXT_ROUTE_PATHS:
		var rect := _get_map_node(String(path)) as ColorRect
		if rect == null:
			continue
		rect.color.a = minf(rect.color.a, CRYSTAL_FOCUS_CONTEXT_ROUTE_ALPHA)
		muted_crystal_focus_context_rect_count += 1
	for path in CRYSTAL_FOCUS_CONTEXT_BOUNDARY_PATHS:
		var rect := _get_map_node(String(path)) as ColorRect
		if rect == null:
			continue
		rect.color.a = minf(rect.color.a, CRYSTAL_FOCUS_CONTEXT_BOUNDARY_ALPHA)
		muted_crystal_focus_context_rect_count += 1


func _mute_crystal_focus_context_interactable_markers(player_position: Vector2) -> void:
	muted_crystal_focus_context_marker_count = 0
	if not visible:
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
		if _is_crystal_focus_local_marker(interactable, player_position):
			continue
		var marker_modulate := marker.modulate
		marker_modulate.a = minf(marker_modulate.a, CRYSTAL_FOCUS_CONTEXT_MARKER_ALPHA)
		marker.modulate = marker_modulate
		marker.scale = Vector2.ONE
		var label := interactable.get_node_or_null("Label") as Label
		if label != null:
			label.visible = false
		var focus_ring := interactable.get_node_or_null("FocusRing") as ColorRect
		if focus_ring != null:
			focus_ring.visible = false
		muted_crystal_focus_context_marker_count += 1


func _is_crystal_focus_local_marker(interactable: PrototypeInteractable, player_position: Vector2) -> bool:
	if not CRYSTAL_FOCUS_LOCAL_INTERACTABLE_DEFINITION_IDS.has(interactable.definition_id):
		return false
	return interactable.position.distance_to(player_position) <= CRYSTAL_FOCUS_LOCAL_MARKER_DISTANCE


func _apply_context_layer_alpha(path: String, alpha: float) -> bool:
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


func _restore_crystal_focus_context_layers() -> void:
	if context_layer_original_modulates.is_empty():
		muted_crystal_focus_context_layer_count = 0
		muted_crystal_focus_context_rect_count = 0
		muted_crystal_focus_context_marker_count = 0
		return
	for path in context_layer_original_modulates.keys():
		var node := _get_map_node(String(path))
		var canvas_item := node as CanvasItem
		if canvas_item != null:
			canvas_item.modulate = context_layer_original_modulates[path]
	context_layer_original_modulates.clear()
	muted_crystal_focus_context_layer_count = 0
	muted_crystal_focus_context_rect_count = 0
	muted_crystal_focus_context_marker_count = 0


func _mute_crystal_identity_blocks() -> void:
	var identity_layer := _get_map_node("DemoInitialArtIdentityLayer")
	if identity_layer == null:
		return
	for child in identity_layer.get_children():
		if not child.has_meta("initial_art_identity_id"):
			continue
		if String(child.get_meta("initial_art_identity_id", "")) == "identity.crystal_ore":
			child.visible = false


func _tone_down_resource_interactable_markers() -> void:
	var interactables := _get_map_node("Interactables")
	muted_resource_marker_count = 0
	if interactables == null:
		return
	for child in interactables.get_children():
		var interactable := child as PrototypeInteractable
		if interactable == null:
			continue
		if not RESOURCE_DEFINITION_IDS.has(interactable.definition_id):
			continue
		var marker := interactable.marker
		if marker == null:
			marker = interactable.get_node_or_null("Marker") as ColorRect
		if marker != null:
			marker.color.a = 0.055
			muted_resource_marker_count += 1


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
