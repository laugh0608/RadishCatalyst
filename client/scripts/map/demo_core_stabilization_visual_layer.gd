extends Node2D
class_name DemoCoreStabilizationVisualLayer

const ROLE_APPROACH := "approach"
const ROLE_RECOVERY := "recovery"
const ROLE_GUARD_FIELD := "guard_field"
const ROLE_WRITEBACK := "writeback"
const ROLE_RETEST := "retest"
const ROLE_LOGISTICS := "logistics"
const FOCUS_VISIBLE_MIN_X := 3300.0

const STATION_FILL := Color(0.07, 0.14, 0.15, 0.07)
const STATION_FRAME := Color(0.42, 0.76, 0.72, 0.38)
const APPROACH_LINE := Color(0.48, 0.9, 0.82, 0.74)
const RECOVERY_LINE := Color(0.68, 0.9, 0.5, 0.76)
const GUARD_LINE := Color(0.95, 0.42, 0.24, 0.82)
const GUARD_FILL := Color(0.42, 0.12, 0.08, 0.08)
const WRITEBACK_LINE := Color(0.9, 0.72, 0.28, 0.78)
const CORE_LIGHT := Color(0.34, 0.96, 0.9, 0.9)
const RETEST_LINE := Color(0.56, 0.86, 0.96, 0.78)
const LOGISTICS_LINE := Color(0.74, 0.82, 0.34, 0.72)
const RETURN_LINE := Color(0.62, 0.9, 0.66, 0.68)
const PRESSURE_LINE := Color(0.96, 0.36, 0.18, 0.74)
const WORKFACE_LINE := Color(0.62, 0.86, 0.78, 0.42)
const SERVICE_DECK_FILL := Color(0.08, 0.18, 0.17, 0.18)
const LOCAL_PAD_FILL := Color(0.08, 0.2, 0.19, 0.12)

const LEGACY_CORE_PANELS := [
	"CoreStabilizationArrivalYard",
	"CoreStabilizationRecoveryYard",
	"CoreStabilizationGuardFieldGround",
	"CoreStabilizationWritebackDeck",
	"CoreStabilizationRetestYard",
	"CoreStabilizationLogisticsRetestYard",
	"CoreStabilizationRecoveryPocket",
	"CoreStabilizationGuardPressureZone",
	"CoreStabilizationRetestPocket",
	"CoreStabilizationLogisticsRetestPocket"
]

const LEGACY_CORE_MARKERS := [
	"CoreStabilizationApproachLane",
	"CoreStabilizationWritebackLine",
	"CoreStabilizationCorePad",
	"CoreStabilizationRetestLine",
	"CoreStabilizationRetestReadoutMarker",
	"CoreStabilizationLogisticsRetestLine",
	"CoreStabilizationLogisticsRetestResidueMarker",
	"CoreStabilizationLogisticsRetestGuardMarker"
]

const RUN_LAYER_BLOCKS := [
	"CoreRunEntryCheck",
	"CoreRunSideSupply",
	"CoreRunBufferReturn",
	"CoreRunGuardField",
	"CoreRunGuardCache",
	"CoreRunWritePad"
]

const CORE_INTERACTABLE_DEFINITION_IDS := {
	"map_object.demo_stabilization_core": true,
	"map_object.demo_stabilization_recovery_cache": true,
	"map_object.demo_stabilization_guard_cache": true,
	"map_object.demo_stabilization_retest_readout_cache": true,
	"map_object.demo_stabilization_logistics_retest_residue": true
}

const CORE_ANCHOR_PATHS := {
	"Interactables/DemoStabilizationCore": ROLE_WRITEBACK,
	"Interactables/DemoStabilizationRecoveryCache": ROLE_RECOVERY,
	"Interactables/DemoStabilizationGuardCache": ROLE_WRITEBACK,
	"Interactables/DemoStabilizationRetestReadoutCache": ROLE_RETEST,
	"Interactables/PollutionResidueLogisticsMaintenanceRetestCache": ROLE_LOGISTICS,
	"Enemies/DemoStabilizationGuard": ROLE_GUARD_FIELD,
	"Enemies/PollutedSkitterLogisticsMaintenanceRetestGuard": ROLE_LOGISTICS
}

var station_shape_ids: Array[String] = []
var flow_shape_ids: Array[String] = []
var muted_legacy_block_count := 0
var muted_interactable_marker_count := 0
var muted_enemy_sprite_count := 0


func _ready() -> void:
	apply_visuals()
	refresh_focus_visibility(_get_player_position())


func _process(_delta: float) -> void:
	refresh_focus_visibility(_get_player_position())
	_tone_down_core_interactable_markers()
	_tone_down_core_enemy_sprites()


func apply_visuals() -> void:
	_register_station_shapes()
	_register_flow_shapes()
	_deemphasize_legacy_core_blocks()
	_mute_core_identity_shapes()
	_tag_core_anchors()
	_tone_down_core_interactable_markers()
	_tone_down_core_enemy_sprites()
	queue_redraw()


func get_station_shape_count() -> int:
	return station_shape_ids.size()


func get_flow_count() -> int:
	return flow_shape_ids.size()


func get_muted_legacy_block_count() -> int:
	return muted_legacy_block_count


func get_muted_interactable_marker_count() -> int:
	return muted_interactable_marker_count


func get_muted_enemy_sprite_count() -> int:
	return muted_enemy_sprite_count


func has_station_shape(shape_id: String) -> bool:
	return station_shape_ids.has(shape_id)


func has_flow_shape(shape_id: String) -> bool:
	return flow_shape_ids.has(shape_id)


func refresh_focus_visibility(player_position: Vector2) -> void:
	visible = player_position.x >= FOCUS_VISIBLE_MIN_X


func _draw() -> void:
	_draw_station_surfaces()
	_draw_station_workface_details()
	_draw_station_routes()
	_draw_recovery_supply()
	_draw_guard_field()
	_draw_writeback_device()
	_draw_retest_and_logistics()


func _draw_station_surfaces() -> void:
	var station_rect := Rect2(Vector2(3648.0, -224.0), Vector2(610.0, 404.0))
	draw_rect(station_rect, STATION_FILL, true)
	draw_rect(station_rect, STATION_FRAME, false, 2.0, true)
	draw_rect(Rect2(Vector2(3660.0, -146.0), Vector2(150.0, 250.0)), Color(0.08, 0.2, 0.2, 0.08), true)
	draw_rect(Rect2(Vector2(3810.0, -154.0), Vector2(166.0, 228.0)), GUARD_FILL, true)
	draw_rect(Rect2(Vector2(3978.0, -144.0), Vector2(136.0, 188.0)), Color(0.08, 0.24, 0.22, 0.08), true)
	draw_rect(Rect2(Vector2(4114.0, -102.0), Vector2(140.0, 196.0)), Color(0.08, 0.2, 0.22, 0.055), true)
	for y in [-188.0, -112.0, -36.0, 42.0, 122.0]:
		draw_line(Vector2(3660.0, y), Vector2(4246.0, y), Color(0.34, 0.56, 0.54, 0.16), 1.2, true)
	for x in [3778.0, 3936.0, 4088.0, 4196.0]:
		draw_line(Vector2(x, -210.0), Vector2(x, 168.0), Color(0.34, 0.56, 0.54, 0.14), 1.2, true)


func _draw_station_workface_details() -> void:
	_draw_service_deck(Rect2(Vector2(3690.0, -66.0), Vector2(126.0, 98.0)))
	_draw_service_deck(Rect2(Vector2(3908.0, -104.0), Vector2(118.0, 86.0)))
	_draw_service_deck(Rect2(Vector2(4058.0, 26.0), Vector2(102.0, 72.0)))
	_draw_writeback_service_ring()
	_draw_retest_reader_bank()
	_draw_output_bus_nodes()
	for route in [
		[Vector2(3714.0, -24.0), Vector2(3796.0, -8.0), Vector2(3886.0, 18.0)],
		[Vector2(3894.0, -70.0), Vector2(3998.0, -34.0), Vector2(4088.0, 34.0)],
		[Vector2(3714.0, 82.0), Vector2(3838.0, 52.0), Vector2(3956.0, 66.0)]
	]:
		draw_polyline(PackedVector2Array(route), Color(0.02, 0.04, 0.04, 0.4), 5.0, true)
		draw_polyline(PackedVector2Array(route), WORKFACE_LINE, 1.6, true)
	for point in [Vector2(3796.0, -8.0), Vector2(3886.0, 18.0), Vector2(3998.0, -34.0), Vector2(4088.0, 34.0), Vector2(3838.0, 52.0)]:
		draw_circle(point, 6.0, Color(WORKFACE_LINE.r, WORKFACE_LINE.g, WORKFACE_LINE.b, 0.26))
		draw_arc(point, 12.0, 0.0, TAU, 24, Color(WORKFACE_LINE.r, WORKFACE_LINE.g, WORKFACE_LINE.b, 0.22), 1.1, true)


func _draw_service_deck(rect: Rect2) -> void:
	draw_rect(rect, SERVICE_DECK_FILL, true)
	draw_rect(rect, WORKFACE_LINE, false, 1.2, true)
	var x := rect.position.x + 14.0
	while x < rect.position.x + rect.size.x - 8.0:
		draw_line(Vector2(x, rect.position.y + 8.0), Vector2(x + 16.0, rect.position.y + rect.size.y - 8.0), Color(WORKFACE_LINE.r, WORKFACE_LINE.g, WORKFACE_LINE.b, 0.14), 1.0, true)
		x += 28.0


func _draw_writeback_service_ring() -> void:
	var center := Vector2(4038.0, -24.0)
	for radius in [54.0, 74.0]:
		draw_arc(center, radius, PI * 0.1, PI * 1.85, 48, Color(CORE_LIGHT.r, CORE_LIGHT.g, CORE_LIGHT.b, 0.22), 1.5, true)
	for angle in [PI * 0.15, PI * 0.62, PI * 1.12, PI * 1.58]:
		var outer := center + Vector2(cos(angle), sin(angle)) * 78.0
		var inner := center + Vector2(cos(angle), sin(angle)) * 48.0
		draw_line(inner, outer, Color(CORE_LIGHT.r, CORE_LIGHT.g, CORE_LIGHT.b, 0.28), 1.3, true)
	for pad in [
		Rect2(Vector2(3978.0, -112.0), Vector2(42.0, 22.0)),
		Rect2(Vector2(4072.0, -96.0), Vector2(34.0, 26.0)),
		Rect2(Vector2(4082.0, 28.0), Vector2(42.0, 24.0)),
		Rect2(Vector2(3970.0, 42.0), Vector2(38.0, 22.0))
	]:
		draw_rect(pad, LOCAL_PAD_FILL, true)
		draw_rect(pad, Color(CORE_LIGHT.r, CORE_LIGHT.g, CORE_LIGHT.b, 0.22), false, 1.0, true)


func _draw_retest_reader_bank() -> void:
	for rect in [
		Rect2(Vector2(4132.0, 30.0), Vector2(32.0, 26.0)),
		Rect2(Vector2(4174.0, 24.0), Vector2(36.0, 28.0)),
		Rect2(Vector2(4214.0, -44.0), Vector2(28.0, 34.0))
	]:
		draw_rect(rect, Color(0.07, 0.16, 0.18, 0.18), true)
		draw_rect(rect, Color(RETEST_LINE.r, RETEST_LINE.g, RETEST_LINE.b, 0.32), false, 1.0, true)
		draw_line(rect.position + Vector2(6.0, rect.size.y * 0.5), rect.position + Vector2(rect.size.x - 6.0, rect.size.y * 0.5), Color(RETEST_LINE.r, RETEST_LINE.g, RETEST_LINE.b, 0.28), 1.0, true)


func _draw_output_bus_nodes() -> void:
	for route in [
		[Vector2(4038.0, -24.0), Vector2(4114.0, -38.0), Vector2(4228.0, -52.0)],
		[Vector2(4038.0, -24.0), Vector2(4118.0, 18.0), Vector2(4134.0, 78.0)]
	]:
		draw_polyline(PackedVector2Array(route), Color(0.02, 0.04, 0.04, 0.38), 5.0, true)
		draw_polyline(PackedVector2Array(route), Color(WRITEBACK_LINE.r, WRITEBACK_LINE.g, WRITEBACK_LINE.b, 0.26), 1.4, true)
	for point in [Vector2(4114.0, -38.0), Vector2(4228.0, -52.0), Vector2(4118.0, 18.0), Vector2(4134.0, 78.0)]:
		draw_circle(point, 5.0, Color(WRITEBACK_LINE.r, WRITEBACK_LINE.g, WRITEBACK_LINE.b, 0.26))


func _draw_station_routes() -> void:
	_draw_route([Vector2(3648.0, -36.0), Vector2(3748.0, -36.0), Vector2(3832.0, -22.0)], APPROACH_LINE, 3.4)
	_draw_route([Vector2(3744.0, 112.0), Vector2(3834.0, 82.0), Vector2(3918.0, 70.0)], RECOVERY_LINE, 3.0)
	_draw_route([Vector2(3870.0, 18.0), Vector2(3926.0, 70.0), Vector2(4038.0, -24.0)], WRITEBACK_LINE, 3.4)
	_draw_route([Vector2(4038.0, -24.0), Vector2(4134.0, 78.0)], RETEST_LINE, 3.0)
	_draw_route([Vector2(4134.0, 78.0), Vector2(4228.0, -52.0), Vector2(4108.0, -112.0)], LOGISTICS_LINE, 2.8)
	_draw_route([Vector2(3744.0, 112.0), Vector2(3608.0, 124.0), Vector2(3420.0, 104.0), Vector2(298.0, -110.0)], RETURN_LINE, 2.8)
	for point in [Vector2(3748.0, -36.0), Vector2(3926.0, 70.0), Vector2(4038.0, -24.0), Vector2(4134.0, 78.0)]:
		draw_circle(point, 4.4, Color(0.8, 0.96, 0.86, 0.66))


func _draw_recovery_supply() -> void:
	_draw_supply_crate(Vector2(3744.0, 112.0), 1.0)
	_draw_supply_crate(Vector2(3718.0, 82.0), 0.78)
	_draw_supply_crate(Vector2(3790.0, 132.0), 0.7)


func _draw_guard_field() -> void:
	var center := Vector2(3870.0, 18.0)
	draw_arc(center, 64.0, 0.0, TAU, 52, PRESSURE_LINE, 2.0, true)
	draw_arc(center, 38.0, 0.0, TAU, 42, Color(0.9, 0.34, 0.2, 0.34), 1.8, true)
	for angle in [0.0, PI * 0.33, PI * 0.66, PI, PI * 1.33, PI * 1.66]:
		var from := center + Vector2(cos(angle), sin(angle)) * 42.0
		var to := center + Vector2(cos(angle), sin(angle)) * 66.0
		draw_line(from, to, PRESSURE_LINE, 1.8, true)
	draw_rect(Rect2(Vector2(3828.0, -12.0), Vector2(84.0, 60.0)), Color(0.36, 0.12, 0.08, 0.18), true)
	draw_rect(Rect2(Vector2(3828.0, -12.0), Vector2(84.0, 60.0)), GUARD_LINE, false, 1.8, true)


func _draw_writeback_device() -> void:
	var center := Vector2(4038.0, -24.0)
	draw_rect(Rect2(center + Vector2(-42.0, -58.0), Vector2(84.0, 116.0)), Color(0.06, 0.22, 0.2, 0.42), true)
	draw_rect(Rect2(center + Vector2(-42.0, -58.0), Vector2(84.0, 116.0)), CORE_LIGHT, false, 2.4, true)
	draw_arc(center, 38.0, 0.0, TAU, 48, CORE_LIGHT, 2.4, true)
	draw_arc(center, 20.0, 0.0, TAU, 36, Color(0.74, 1.0, 0.94, 0.72), 1.8, true)
	draw_line(center + Vector2(-34.0, 0.0), center + Vector2(34.0, 0.0), CORE_LIGHT, 2.2, true)
	draw_line(center + Vector2(0.0, -46.0), center + Vector2(0.0, 46.0), CORE_LIGHT, 2.2, true)
	draw_circle(Vector2(3926.0, 70.0), 10.0, WRITEBACK_LINE)
	draw_arc(Vector2(3926.0, 70.0), 16.0, 0.0, TAU, 28, Color(0.98, 0.78, 0.32, 0.52), 1.6, true)


func _draw_retest_and_logistics() -> void:
	_draw_readout_table(Vector2(4134.0, 78.0))
	_draw_residue_capsule(Vector2(4228.0, -52.0), 1.0)
	_draw_residue_capsule(Vector2(4186.0, -36.0), 0.74)
	draw_rect(Rect2(Vector2(4166.0, -78.0), Vector2(80.0, 60.0)), Color(0.17, 0.22, 0.1, 0.26), true)
	draw_rect(Rect2(Vector2(4166.0, -78.0), Vector2(80.0, 60.0)), LOGISTICS_LINE, false, 1.8, true)
	draw_line(Vector2(4206.0, -80.0), Vector2(4206.0, -18.0), LOGISTICS_LINE, 2.0, true)


func _draw_supply_crate(center: Vector2, scale: float) -> void:
	var rect := Rect2(center + Vector2(-18.0, -12.0) * scale, Vector2(36.0, 24.0) * scale)
	draw_rect(rect, Color(0.2, 0.34, 0.18, 0.36), true)
	draw_rect(rect, RECOVERY_LINE, false, 1.8, true)
	draw_line(center + Vector2(-14.0, 0.0) * scale, center + Vector2(14.0, 0.0) * scale, RECOVERY_LINE, 1.4, true)


func _draw_readout_table(center: Vector2) -> void:
	draw_rect(Rect2(center + Vector2(-28.0, -18.0), Vector2(56.0, 36.0)), Color(0.08, 0.22, 0.26, 0.38), true)
	draw_rect(Rect2(center + Vector2(-28.0, -18.0), Vector2(56.0, 36.0)), RETEST_LINE, false, 1.8, true)
	draw_line(center + Vector2(-18.0, -6.0), center + Vector2(18.0, -6.0), RETEST_LINE, 1.4, true)
	draw_line(center + Vector2(-12.0, 8.0), center + Vector2(16.0, 8.0), Color(0.8, 0.96, 1.0, 0.54), 1.2, true)


func _draw_residue_capsule(center: Vector2, scale: float) -> void:
	draw_rect(
		Rect2(center + Vector2(-14.0, -10.0) * scale, Vector2(28.0, 20.0) * scale),
		Color(0.32, 0.34, 0.12, 0.32),
		true
	)
	draw_arc(center, 17.0 * scale, 0.0, TAU, 28, LOGISTICS_LINE, 1.7, true)
	draw_circle(center, 4.0 * scale, Color(0.86, 0.9, 0.34, 0.62))


func _draw_route(points: Array[Vector2], color: Color, width: float) -> void:
	draw_polyline(PackedVector2Array(points), Color(0.02, 0.04, 0.04, 0.54), width + 2.8, true)
	draw_polyline(PackedVector2Array(points), color, width, true)


func _register_station_shapes() -> void:
	station_shape_ids = [
		"station.arrival_threshold",
		"station.central_maintenance_deck",
		"station.writeback_service_ring",
		"station.recovery_supply",
		"station.guard_pressure_field",
		"station.writeback_device",
		"station.guard_cache",
		"station.retest_readout",
		"station.retest_reader_bank",
		"station.logistics_retest_pocket",
		"station.energy_confluence_nodes",
		"station.output_bus_nodes",
		"station.return_service_lane"
	]


func _register_flow_shapes() -> void:
	flow_shape_ids = [
		"flow.entry_to_guard",
		"flow.recovery_to_guard_cache",
		"flow.guard_cache_to_core",
		"flow.core_to_retest",
		"flow.retest_to_logistics",
		"flow.core_return_to_base"
	]


func _deemphasize_legacy_core_blocks() -> void:
	muted_legacy_block_count = 0
	var region := _get_map_node("RegionDemoStabilizationCore") as ColorRect
	if region != null:
		region.color = Color(0.06, 0.12, 0.12, 0.09)
	var route_band := _get_map_node("DemoRoutePresentationLayer/DemoRouteCoreBand") as ColorRect
	if route_band != null:
		route_band.color = Color(route_band.color.r, route_band.color.g, route_band.color.b, minf(route_band.color.a, 0.035))
	var route_label := _get_map_node("DemoRoutePresentationLayer/DemoRouteCoreLabel") as Label
	if route_label != null:
		route_label.visible = false
	var direction_label := _get_map_node("DemoStabilizationCoreDirectionLabel") as Label
	if direction_label != null:
		direction_label.visible = false

	var opening_layer := _get_map_node("OpeningSceneLayer")
	if opening_layer != null:
		for node_name in LEGACY_CORE_PANELS:
			var rect := opening_layer.get_node_or_null(String(node_name)) as ColorRect
			if rect != null:
				rect.color = Color(rect.color.r, rect.color.g, rect.color.b, minf(rect.color.a, 0.035))
				muted_legacy_block_count += 1
		for node_name in LEGACY_CORE_MARKERS:
			var rect := opening_layer.get_node_or_null(String(node_name)) as ColorRect
			if rect != null:
				rect.color = Color(rect.color.r, rect.color.g, rect.color.b, minf(rect.color.a, 0.02))
				muted_legacy_block_count += 1
		var pressure_label := opening_layer.get_node_or_null("CoreStabilizationPressureLabel") as Label
		if pressure_label != null:
			pressure_label.visible = false

	var run_layer := _get_map_node("CoreStabilizationRunLayer")
	if run_layer != null:
		for node_name in RUN_LAYER_BLOCKS:
			var rect := run_layer.get_node_or_null(String(node_name)) as ColorRect
			if rect != null:
				rect.color = Color(rect.color.r, rect.color.g, rect.color.b, minf(rect.color.a, 0.03))
				muted_legacy_block_count += 1


func _mute_core_identity_shapes() -> void:
	var identity_layer := _get_map_node("DemoInitialArtIdentityLayer")
	if identity_layer == null:
		return
	for child in identity_layer.get_children():
		if not child.has_meta("initial_art_identity_id"):
			continue
		if String(child.get_meta("initial_art_identity_id", "")) == "identity.demo_stabilization_core":
			child.visible = false


func _tag_core_anchors() -> void:
	for path in CORE_ANCHOR_PATHS.keys():
		var node := _get_map_node(String(path))
		if node == null:
			continue
		node.set_meta("core_stabilization_visual_role", String(CORE_ANCHOR_PATHS[path]))
		node.set_meta("core_stabilization_visual_scope", "terminal_station")


func _tone_down_core_interactable_markers() -> void:
	var interactables := _get_map_node("Interactables")
	muted_interactable_marker_count = 0
	if interactables == null:
		return
	for child in interactables.get_children():
		var interactable := child as PrototypeInteractable
		if interactable == null:
			continue
		if not CORE_INTERACTABLE_DEFINITION_IDS.has(interactable.definition_id):
			continue
		var marker := interactable.marker
		if marker == null:
			marker = interactable.get_node_or_null("Marker") as ColorRect
		if marker != null:
			marker.color.a = 0.075
			muted_interactable_marker_count += 1


func _tone_down_core_enemy_sprites() -> void:
	muted_enemy_sprite_count = 0
	for path in ["Enemies/DemoStabilizationGuard", "Enemies/PollutedSkitterLogisticsMaintenanceRetestGuard"]:
		var enemy := _get_map_node(path) as PrototypeEnemy
		if enemy == null:
			continue
		var sprite := enemy.sprite
		if sprite == null:
			sprite = enemy.get_node_or_null("Sprite") as ColorRect
		if sprite != null:
			sprite.color.a = minf(sprite.color.a, 0.78)
			muted_enemy_sprite_count += 1


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
