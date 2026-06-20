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
var muted_legacy_block_count := 0
var muted_interactable_marker_count := 0


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


func refresh_focus_visibility(player_position: Vector2) -> void:
	visible = player_position.x >= FOCUS_VISIBLE_MIN_X


func _draw() -> void:
	_draw_boundary_field()
	_draw_treatment_routes()
	_draw_filter_construction_site()
	_draw_residue_patches()
	_draw_pressure_gate()


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


func _deemphasize_legacy_pollution_blocks() -> void:
	muted_legacy_block_count = 0
	var region := _get_map_node("RegionPollution") as ColorRect
	if region != null:
		region.color = Color(0.11, 0.12, 0.07, 0.62)
	var route_band := _get_map_node("DemoRoutePresentationLayer/DemoRoutePollutionBand") as ColorRect
	if route_band != null:
		route_band.color.a = minf(route_band.color.a, 0.1)
	var route_label := _get_map_node("DemoRoutePresentationLayer/DemoRoutePollutionLabel") as Label
	if route_label != null:
		route_label.visible = false

	var layer := _get_map_node("OpeningSceneLayer")
	if layer == null:
		return
	for node_name in LEGACY_POLLUTION_PANELS:
		var rect := layer.get_node_or_null(String(node_name)) as ColorRect
		if rect != null:
			rect.color.a = minf(rect.color.a, 0.11)
			muted_legacy_block_count += 1
	for node_name in LEGACY_POLLUTION_MARKERS:
		var rect := layer.get_node_or_null(String(node_name)) as ColorRect
		if rect != null:
			rect.color.a = minf(rect.color.a, 0.045)
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
			marker.color.a = 0.075
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
