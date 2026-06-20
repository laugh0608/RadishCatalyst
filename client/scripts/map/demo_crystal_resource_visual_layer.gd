extends Node2D
class_name DemoCrystalResourceVisualLayer

const RESOURCE_SHAPE_PREFIX := "DemoCrystalResourceVisual"
const ROLE_RESOURCE := "resource"
const ROLE_FLOW := "flow"
const ROLE_SALVAGE := "salvage"

const FIELD_FRAME := Color(0.32, 0.58, 0.62, 0.32)
const FIELD_FILL := Color(0.06, 0.12, 0.15, 0.16)
const CRYSTAL_LINE := Color(0.42, 0.88, 0.98, 0.78)
const CRYSTAL_FILL := Color(0.25, 0.78, 0.95, 0.44)
const RICH_CRYSTAL_LINE := Color(0.76, 0.94, 1.0, 0.86)
const SALVAGE_LINE := Color(0.72, 0.78, 0.68, 0.58)
const SALVAGE_FILL := Color(0.36, 0.42, 0.34, 0.26)
const RETURN_FLOW := Color(0.72, 0.88, 0.58, 0.66)
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

const RESOURCE_DEFINITION_IDS := {
	"map_object.crystal_cluster": true,
	"map_object.rich_crystal_vein": true,
	"map_object.field_wreckage": true,
	"map_object.anomaly_crystal": true,
	"map_object.anomaly_residue_patch": true
}

var resource_shape_ids: Array[String] = []
var flow_shape_ids: Array[String] = []
var muted_resource_marker_count := 0


func _ready() -> void:
	apply_visuals()


func _process(_delta: float) -> void:
	_tone_down_resource_interactable_markers()
	_mute_crystal_identity_blocks()


func apply_visuals() -> void:
	_deemphasize_legacy_crystal_blocks()
	_mute_crystal_identity_blocks()
	_register_resource_shapes()
	_register_flow_shapes()
	_tone_down_resource_interactable_markers()
	queue_redraw()


func get_resource_shape_count() -> int:
	return resource_shape_ids.size()


func get_flow_count() -> int:
	return flow_shape_ids.size()


func get_muted_resource_marker_count() -> int:
	return muted_resource_marker_count


func has_resource_shape(shape_id: String) -> bool:
	return resource_shape_ids.has(shape_id)


func has_flow_shape(shape_id: String) -> bool:
	return flow_shape_ids.has(shape_id)


func _draw() -> void:
	_draw_field_frame()
	_draw_main_vein()
	_draw_crystal_clusters()
	_draw_salvage_pockets()
	_draw_return_flows()
	_draw_anomaly_pocket()


func _draw_field_frame() -> void:
	var field_rect := Rect2(Vector2(-18.0, -270.0), Vector2(250.0, 332.0))
	var salvage_rect := Rect2(Vector2(-10.0, 80.0), Vector2(258.0, 178.0))
	draw_rect(field_rect, FIELD_FILL, true)
	draw_rect(field_rect, FIELD_FRAME, false, 2.0, true)
	draw_rect(salvage_rect, Color(0.05, 0.09, 0.1, 0.18), true)
	draw_rect(salvage_rect, Color(0.44, 0.58, 0.52, 0.24), false, 1.8, true)
	for y in [-206.0, -126.0, -36.0, 116.0, 206.0]:
		draw_line(Vector2(-8.0, y), Vector2(224.0, y), Color(0.34, 0.52, 0.54, 0.16), 1.2, true)
	draw_line(Vector2(-8.0, -72.0), Vector2(108.0, -72.0), Color(0.35, 0.9, 0.98, 0.34), 4.0, true)


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


func _register_resource_shapes() -> void:
	resource_shape_ids = [
		"crystal.main_vein",
		"crystal.rich_vein",
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
		"flow.salvage_to_base",
		"flow.crystal_branch",
		"flow.salvage_branch"
	]


func _deemphasize_legacy_crystal_blocks() -> void:
	var region := _get_map_node("RegionCrystal") as ColorRect
	if region != null:
		region.color = Color(0.07, 0.12, 0.17, 0.72)

	var layer := _get_map_node("OpeningSceneLayer")
	if layer == null:
		return
	for node_name in LEGACY_CRYSTAL_PANELS:
		var rect := layer.get_node_or_null(String(node_name)) as ColorRect
		if rect != null:
			rect.color.a = minf(rect.color.a, 0.12)
	for node_name in LEGACY_CRYSTAL_MARKERS:
		var rect := layer.get_node_or_null(String(node_name)) as ColorRect
		if rect != null:
			rect.color.a = minf(rect.color.a, 0.055)


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
			marker.color.a = 0.08
			muted_resource_marker_count += 1


func _get_map_node(path: String) -> Node:
	if path.is_empty() or get_parent() == null:
		return null
	return get_parent().get_node_or_null(path)
