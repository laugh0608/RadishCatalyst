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
const STATUS_PANEL_FILL := Color(0.018, 0.03, 0.03, 0.62)
const STATUS_IDLE_LIGHT := Color(0.14, 0.2, 0.2, 0.32)
const ARCHIVE_SPINE_LINE := Color(0.38, 0.62, 0.58, 0.2)
const ANOMALY_HOOK_LINE := Color(0.78, 0.58, 0.96, 0.34)
const CORE_FOCUS_CONTEXT_LAYER_ALPHAS := [
	{"path": "DemoRoutePresentationLayer", "alpha": 0.0},
	{"path": "DemoRegionIndustrialValueLayer", "alpha": 0.012},
	{"path": "CoreApproachHandoffLayer", "alpha": 0.0},
	{"path": "CurrentObjectiveGuidanceLayer", "alpha": 0.055},
	{"path": "PrototypeVisualPriorityLayer", "alpha": 0.035}
]
const CORE_STATE_WAITING := "waiting"
const CORE_STATE_READY := "ready"
const CORE_STATE_COMPLETED := "completed"
const CORE_STATE_PRESSURE := "pressure"
const CORE_STATE_CLEARED := "cleared"

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
var core_station_state_shape_ids: Array[String] = []
var muted_legacy_block_count := 0
var muted_interactable_marker_count := 0
var muted_enemy_sprite_count := 0
var muted_core_focus_context_layer_count := 0
var applied_core_station_state_count := 0
var core_station_state: Dictionary = {}
var context_layer_original_modulates: Dictionary = {}


func _ready() -> void:
	apply_visuals()
	refresh_focus_visibility(_get_player_position())


func _process(_delta: float) -> void:
	refresh_focus_visibility(_get_player_position())
	_update_core_focus_context_layers()
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


func refresh_core_station_state(world_state: WorldState, character_state: CharacterState) -> void:
	core_station_state_shape_ids.clear()
	applied_core_station_state_count = 0
	if world_state == null or character_state == null:
		core_station_state.clear()
		queue_redraw()
		return
	if not _has_core_station_context(world_state, character_state):
		core_station_state.clear()
		queue_redraw()
		return

	var inventory := character_state.inventory
	var quest_state := world_state.quest_state
	var guard_state := world_state.get_enemy("enemy_instance.demo_stabilization_guard")
	var guard_defeated := (
		bool(guard_state.get("is_defeated", false))
		or quest_state.has_completed_quest("quest.defeat_demo_stabilization_guard")
	)
	var recovery_cache := world_state.get_map_object("map_object_instance.demo_stabilization_recovery_cache")
	var guard_cache := world_state.get_map_object("map_object_instance.demo_stabilization_guard_cache")
	var core_object := world_state.get_map_object("map_object_instance.demo_stabilization_core")
	var retest_readout := world_state.get_map_object("map_object_instance.demo_stabilization_retest_readout_cache")
	var recovery_cache_ready := bool(recovery_cache.get("is_gathered", false))
	var buffer_ready := (
		recovery_cache_ready
		or inventory.has_ref("item.core_stabilization_buffer", 1)
		or quest_state.has_completed_quest("quest.prepare_demo_stabilization_buffer")
	)
	var write_charge_ready := (
		inventory.has_ref("item.core_write_charge", 1)
		or quest_state.get_objective_progress("quest.write_demo_stabilization_core", "gather_item", "item.core_write_charge") >= 1.0
	)
	var guard_cache_ready := bool(guard_cache.get("is_gathered", false)) or write_charge_ready
	var write_quest_active := quest_state.has_active_quest("quest.write_demo_stabilization_core")
	var core_written := (
		bool(core_object.get("is_sampled", false))
		or quest_state.has_completed_quest("quest.write_demo_stabilization_core")
	)
	var write_ready := guard_defeated and guard_cache_ready and write_charge_ready and write_quest_active and not core_written
	var retest_readout_gathered := bool(retest_readout.get("is_gathered", false))
	var retest_ready := core_written or retest_readout_gathered
	var logistics_retest_processed := CoreStabilizationPressureFormatter.is_logistics_maintenance_retest_processed(world_state)
	var logistics_return_ready := core_written or logistics_retest_processed
	var recovery_state := CORE_STATE_WAITING
	if recovery_cache_ready:
		recovery_state = CORE_STATE_COMPLETED
	elif buffer_ready:
		recovery_state = CORE_STATE_READY
	var guard_cache_state := CORE_STATE_WAITING
	if core_written and guard_cache_ready:
		guard_cache_state = CORE_STATE_COMPLETED
	elif guard_cache_ready:
		guard_cache_state = CORE_STATE_READY
	var guard_pressure_state := CORE_STATE_CLEARED if guard_defeated else CORE_STATE_PRESSURE
	var writeback_state := CORE_STATE_WAITING
	if core_written:
		writeback_state = CORE_STATE_COMPLETED
	elif write_ready:
		writeback_state = CORE_STATE_READY
	var retest_state := CORE_STATE_WAITING
	if retest_readout_gathered:
		retest_state = CORE_STATE_COMPLETED
	elif retest_ready:
		retest_state = CORE_STATE_READY
	var logistics_state := CORE_STATE_WAITING
	if logistics_retest_processed:
		logistics_state = CORE_STATE_COMPLETED
	elif logistics_return_ready:
		logistics_state = CORE_STATE_READY

	core_station_state = {
		"recovery_state": recovery_state,
		"guard_cache_state": guard_cache_state,
		"guard_pressure_state": guard_pressure_state,
		"writeback_state": writeback_state,
		"retest_state": retest_state,
		"logistics_state": logistics_state,
		"buffer_ready": buffer_ready,
		"guard_defeated": guard_defeated,
		"write_ready": write_ready,
		"core_written": core_written,
		"retest_ready": retest_ready,
		"logistics_return_ready": logistics_return_ready
	}
	_register_core_station_state_shape("core_station.device.recovery.%s" % recovery_state)
	_register_core_station_state_shape("core_station.device.guard_cache.%s" % guard_cache_state)
	_register_core_station_state_shape("core_station.pressure.guard.%s" % guard_pressure_state)
	_register_core_station_state_shape("core_station.device.writeback.%s" % writeback_state)
	_register_core_station_state_shape("core_station.device.retest.%s" % retest_state)
	_register_core_station_state_shape("core_station.device.logistics.%s" % logistics_state)
	_register_core_station_state_shape("core_station.feedback.recovery_supply.%s" % recovery_state)
	_register_core_station_state_shape("core_station.feedback.guard_pressure_relief.%s" % guard_pressure_state)
	_register_core_station_state_shape("core_station.feedback.writeback_cache.%s" % guard_cache_state)
	_register_core_station_state_shape("core_station.feedback.core_write.%s" % writeback_state)
	_register_core_station_state_shape("core_station.feedback.retest_readout.%s" % retest_state)
	_register_core_station_state_shape("core_station.feedback.logistics_return.%s" % logistics_state)
	_register_core_station_state_shape("core_station.flow.recovery_to_guard.%s" % _core_ready_suffix(buffer_ready))
	_register_core_station_state_shape("core_station.flow.guard_cache_to_core.%s" % _core_ready_suffix(write_ready or core_written))
	_register_core_station_state_shape("core_station.flow.core_write.%s" % _core_activity_suffix(write_ready))
	_register_core_station_state_shape("core_station.flow.core_to_retest.%s" % _core_ready_suffix(core_written))
	_register_core_station_state_shape("core_station.flow.retest_to_logistics.%s" % _core_ready_suffix(core_written))
	_register_core_station_state_shape("core_station.flow.logistics_return.%s" % _core_ready_suffix(logistics_return_ready))
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


func get_muted_core_focus_context_layer_count() -> int:
	return muted_core_focus_context_layer_count


func has_station_shape(shape_id: String) -> bool:
	return station_shape_ids.has(shape_id)


func has_flow_shape(shape_id: String) -> bool:
	return flow_shape_ids.has(shape_id)


func get_core_station_state_shape_count() -> int:
	return applied_core_station_state_count


func has_core_station_state_shape(shape_id: String) -> bool:
	return core_station_state_shape_ids.has(shape_id)


func refresh_focus_visibility(player_position: Vector2) -> void:
	visible = player_position.x >= FOCUS_VISIBLE_MIN_X
	_update_core_focus_context_layers()


func _draw() -> void:
	_draw_station_surfaces()
	_draw_station_workface_details()
	_draw_station_routes()
	_draw_recovery_supply()
	_draw_guard_field()
	_draw_writeback_device()
	_draw_retest_and_logistics()
	_draw_core_station_state()
	_draw_operation_relation_overlay()


func _draw_station_surfaces() -> void:
	var station_rect := Rect2(Vector2(3648.0, -224.0), Vector2(610.0, 404.0))
	draw_rect(station_rect, STATION_FILL, true)
	draw_rect(station_rect, STATION_FRAME, false, 2.0, true)
	draw_rect(Rect2(Vector2(3660.0, -146.0), Vector2(150.0, 250.0)), Color(0.08, 0.2, 0.2, 0.08), true)
	if _is_guard_pressure_cleared():
		_draw_completed_guard_residue_wash()
	else:
		draw_rect(Rect2(Vector2(3810.0, -154.0), Vector2(166.0, 228.0)), GUARD_FILL, true)
	draw_rect(Rect2(Vector2(3978.0, -144.0), Vector2(136.0, 188.0)), Color(0.08, 0.24, 0.22, 0.08), true)
	draw_rect(Rect2(Vector2(4114.0, -102.0), Vector2(140.0, 196.0)), Color(0.08, 0.2, 0.22, 0.055), true)
	for y in [-188.0, -112.0, -36.0, 42.0, 122.0]:
		draw_line(Vector2(3660.0, y), Vector2(4246.0, y), Color(0.34, 0.56, 0.54, 0.16), 1.2, true)
	for x in [3778.0, 3936.0, 4088.0, 4196.0]:
		draw_line(Vector2(x, -210.0), Vector2(x, 168.0), Color(0.34, 0.56, 0.54, 0.14), 1.2, true)
	_draw_archived_stabilization_spine()


func _draw_completed_guard_residue_wash() -> void:
	draw_rect(Rect2(Vector2(3810.0, -154.0), Vector2(166.0, 228.0)), Color(0.004, 0.01, 0.01, 0.24), true)
	for rect in [
		Rect2(Vector2(3832.0, -72.0), Vector2(48.0, 12.0)),
		Rect2(Vector2(3888.0, -18.0), Vector2(58.0, 10.0)),
		Rect2(Vector2(3848.0, 48.0), Vector2(44.0, 10.0))
	]:
		draw_rect(rect, Color(RETURN_LINE.r, RETURN_LINE.g, RETURN_LINE.b, 0.16), true)
		draw_rect(rect, Color(RETURN_LINE.r, RETURN_LINE.g, RETURN_LINE.b, 0.24), false, 0.9, true)


func _draw_station_workface_details() -> void:
	_draw_service_deck(Rect2(Vector2(3690.0, -66.0), Vector2(126.0, 98.0)))
	_draw_service_deck(Rect2(Vector2(3908.0, -104.0), Vector2(118.0, 86.0)))
	_draw_service_deck(Rect2(Vector2(4058.0, 26.0), Vector2(102.0, 72.0)))
	_draw_writeback_service_ring()
	_draw_retest_reader_bank()
	_draw_output_bus_nodes()
	_draw_stability_window_hook()
	_draw_unresolved_anomaly_probe()
	for route in [
		[Vector2(3714.0, -24.0), Vector2(3796.0, -8.0), Vector2(3886.0, 18.0)],
		[Vector2(3894.0, -70.0), Vector2(3998.0, -34.0), Vector2(4088.0, 34.0)],
		[Vector2(3714.0, 82.0), Vector2(3838.0, 52.0), Vector2(3956.0, 66.0)]
	]:
		var completed_alpha := 0.18 if _is_core_written() else WORKFACE_LINE.a
		var completed_width := 1.0 if _is_core_written() else 1.6
		draw_polyline(PackedVector2Array(route), Color(0.02, 0.04, 0.04, 0.22 if _is_core_written() else 0.4), 4.0 if _is_core_written() else 5.0, true)
		draw_polyline(PackedVector2Array(route), Color(WORKFACE_LINE.r, WORKFACE_LINE.g, WORKFACE_LINE.b, completed_alpha), completed_width, true)
	for point in [Vector2(3796.0, -8.0), Vector2(3886.0, 18.0), Vector2(3998.0, -34.0), Vector2(4088.0, 34.0), Vector2(3838.0, 52.0)]:
		draw_circle(point, 6.0, Color(WORKFACE_LINE.r, WORKFACE_LINE.g, WORKFACE_LINE.b, 0.26))
		draw_arc(point, 12.0, 0.0, TAU, 24, Color(WORKFACE_LINE.r, WORKFACE_LINE.g, WORKFACE_LINE.b, 0.22), 1.1, true)


func _draw_archived_stabilization_spine() -> void:
	var spine_points := PackedVector2Array([
		Vector2(3672.0, 142.0),
		Vector2(3796.0, 118.0),
		Vector2(3924.0, 102.0),
		Vector2(4042.0, 116.0),
		Vector2(4172.0, 84.0)
	])
	draw_polyline(spine_points, Color(0.012, 0.026, 0.026, 0.44), 7.0, true)
	draw_polyline(spine_points, ARCHIVE_SPINE_LINE, 1.4, true)
	for point in [Vector2(3796.0, 118.0), Vector2(3924.0, 102.0), Vector2(4042.0, 116.0)]:
		draw_rect(Rect2(point + Vector2(-8.0, -5.0), Vector2(16.0, 10.0)), Color(ARCHIVE_SPINE_LINE.r, ARCHIVE_SPINE_LINE.g, ARCHIVE_SPINE_LINE.b, 0.18), true)
		draw_rect(Rect2(point + Vector2(-8.0, -5.0), Vector2(16.0, 10.0)), Color(ARCHIVE_SPINE_LINE.r, ARCHIVE_SPINE_LINE.g, ARCHIVE_SPINE_LINE.b, 0.28), false, 0.8, true)


func _draw_stability_window_hook() -> void:
	var hook_points := PackedVector2Array([
		Vector2(4038.0, -24.0),
		Vector2(4118.0, 18.0),
		Vector2(4134.0, 78.0),
		Vector2(4218.0, -28.0),
		Vector2(4252.0, -126.0)
	])
	draw_polyline(hook_points, Color(0.012, 0.026, 0.026, 0.46), 5.0, true)
	draw_polyline(hook_points, Color(ANOMALY_HOOK_LINE.r, ANOMALY_HOOK_LINE.g, ANOMALY_HOOK_LINE.b, 0.24), 1.5, true)
	for point in [Vector2(4134.0, 78.0), Vector2(4218.0, -28.0), Vector2(4252.0, -126.0)]:
		draw_arc(point, 11.0, 0.0, TAU, 22, Color(ANOMALY_HOOK_LINE.r, ANOMALY_HOOK_LINE.g, ANOMALY_HOOK_LINE.b, 0.24), 1.0, true)


func _draw_unresolved_anomaly_probe() -> void:
	var probe := Rect2(Vector2(4232.0, -154.0), Vector2(40.0, 46.0))
	draw_rect(probe, Color(0.08, 0.04, 0.12, 0.22), true)
	draw_rect(probe, ANOMALY_HOOK_LINE, false, 1.2, true)
	draw_line(Vector2(4252.0, -154.0), Vector2(4252.0, -108.0), Color(ANOMALY_HOOK_LINE.r, ANOMALY_HOOK_LINE.g, ANOMALY_HOOK_LINE.b, 0.28), 1.0, true)
	for y in [-144.0, -132.0, -120.0]:
		draw_line(Vector2(4240.0, y), Vector2(4264.0, y + 5.0), Color(ANOMALY_HOOK_LINE.r, ANOMALY_HOOK_LINE.g, ANOMALY_HOOK_LINE.b, 0.24), 1.0, true)
	draw_circle(Vector2(4252.0, -126.0), 5.0, Color(ANOMALY_HOOK_LINE.r, ANOMALY_HOOK_LINE.g, ANOMALY_HOOK_LINE.b, 0.38))


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
	if not _is_core_written():
		_draw_route([Vector2(3648.0, -36.0), Vector2(3748.0, -36.0), Vector2(3832.0, -22.0)], APPROACH_LINE, 3.4)
		_draw_route([Vector2(3744.0, 112.0), Vector2(3834.0, 82.0), Vector2(3918.0, 70.0)], RECOVERY_LINE, 3.0)
		_draw_route([Vector2(3870.0, 18.0), Vector2(3926.0, 70.0), Vector2(4038.0, -24.0)], WRITEBACK_LINE, 3.4)
		_draw_route([Vector2(4038.0, -24.0), Vector2(4134.0, 78.0)], RETEST_LINE, 3.0)
		_draw_route([Vector2(4134.0, 78.0), Vector2(4228.0, -52.0), Vector2(4108.0, -112.0)], LOGISTICS_LINE, 2.8)
		_draw_route([Vector2(3744.0, 112.0), Vector2(3616.0, 124.0), Vector2(3478.0, 96.0)], RETURN_LINE, 2.8)
		for point in [Vector2(3748.0, -36.0), Vector2(3926.0, 70.0), Vector2(4038.0, -24.0), Vector2(4134.0, 78.0)]:
			draw_circle(point, 4.4, Color(0.8, 0.96, 0.86, 0.66))
		return
	_draw_route([Vector2(4038.0, -24.0), Vector2(4092.0, 22.0), Vector2(4134.0, 78.0)], Color(RETEST_LINE.r, RETEST_LINE.g, RETEST_LINE.b, 0.34), 1.8)
	_draw_route([Vector2(4134.0, 78.0), Vector2(4184.0, 16.0), Vector2(4228.0, -52.0)], Color(LOGISTICS_LINE.r, LOGISTICS_LINE.g, LOGISTICS_LINE.b, 0.32), 1.6)
	_draw_route([Vector2(4228.0, -52.0), Vector2(4162.0, -88.0), Vector2(4108.0, -112.0)], Color(RETURN_LINE.r, RETURN_LINE.g, RETURN_LINE.b, 0.28), 1.4)
	for point in [Vector2(4038.0, -24.0), Vector2(4134.0, 78.0), Vector2(4228.0, -52.0)]:
		draw_circle(point, 4.4, Color(0.8, 0.96, 0.86, 0.66))


func _draw_recovery_supply() -> void:
	_draw_supply_crate(Vector2(3744.0, 112.0), 1.0)
	_draw_supply_crate(Vector2(3718.0, 82.0), 0.78)
	_draw_supply_crate(Vector2(3790.0, 132.0), 0.7)


func _draw_guard_field() -> void:
	var center := Vector2(3870.0, 18.0)
	if _is_guard_pressure_cleared():
		_draw_cleared_guard_field(center)
		return
	draw_arc(center, 64.0, 0.0, TAU, 52, PRESSURE_LINE, 2.0, true)
	draw_arc(center, 38.0, 0.0, TAU, 42, Color(0.9, 0.34, 0.2, 0.34), 1.8, true)
	for angle in [0.0, PI * 0.33, PI * 0.66, PI, PI * 1.33, PI * 1.66]:
		var from := center + Vector2(cos(angle), sin(angle)) * 42.0
		var to := center + Vector2(cos(angle), sin(angle)) * 66.0
		draw_line(from, to, PRESSURE_LINE, 1.8, true)
	draw_rect(Rect2(Vector2(3828.0, -12.0), Vector2(84.0, 60.0)), Color(0.36, 0.12, 0.08, 0.18), true)
	draw_rect(Rect2(Vector2(3828.0, -12.0), Vector2(84.0, 60.0)), GUARD_LINE, false, 1.8, true)


func _draw_cleared_guard_field(center: Vector2) -> void:
	draw_rect(Rect2(Vector2(3832.0, -8.0), Vector2(76.0, 52.0)), Color(0.08, 0.18, 0.15, 0.1), true)
	draw_rect(Rect2(Vector2(3832.0, -8.0), Vector2(76.0, 52.0)), Color(RETURN_LINE.r, RETURN_LINE.g, RETURN_LINE.b, 0.32), false, 1.0, true)
	for arc_range in [
		[PI * 0.08, PI * 0.32],
		[PI * 0.72, PI * 0.96],
		[PI * 1.18, PI * 1.42],
		[PI * 1.72, PI * 1.94]
	]:
		draw_arc(center, 62.0, float(arc_range[0]), float(arc_range[1]), 12, Color(RETURN_LINE.r, RETURN_LINE.g, RETURN_LINE.b, 0.34), 1.5, true)
	for angle in [PI * 0.2, PI * 0.85, PI * 1.22, PI * 1.82]:
		var from := center + Vector2(cos(angle), sin(angle)) * 42.0
		var to := center + Vector2(cos(angle), sin(angle)) * 58.0
		draw_line(from, to, Color(RETURN_LINE.r, RETURN_LINE.g, RETURN_LINE.b, 0.28), 1.2, true)


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


func _draw_core_station_state() -> void:
	if core_station_state.is_empty():
		return
	var recovery_state := String(core_station_state.get("recovery_state", CORE_STATE_WAITING))
	var guard_cache_state := String(core_station_state.get("guard_cache_state", CORE_STATE_WAITING))
	var guard_pressure_state := String(core_station_state.get("guard_pressure_state", CORE_STATE_PRESSURE))
	var writeback_state := String(core_station_state.get("writeback_state", CORE_STATE_WAITING))
	var retest_state := String(core_station_state.get("retest_state", CORE_STATE_WAITING))
	var logistics_state := String(core_station_state.get("logistics_state", CORE_STATE_WAITING))
	var write_ready := bool(core_station_state.get("write_ready", false))
	var core_written := bool(core_station_state.get("core_written", false))
	var logistics_return_ready := bool(core_station_state.get("logistics_return_ready", false))
	_draw_core_status_strip(Vector2(3718.0, 70.0), recovery_state, RECOVERY_LINE)
	_draw_core_material_slot(Rect2(Vector2(3724.0, 98.0), Vector2(40.0, 26.0)), recovery_state, RECOVERY_LINE)
	_draw_recovery_supply_feedback(recovery_state)
	_draw_core_pressure_state(Vector2(3870.0, 18.0), guard_pressure_state)
	_draw_guard_pressure_relief_feedback(Vector2(3870.0, 18.0), guard_pressure_state)
	_draw_core_status_strip(Vector2(3906.0, 50.0), guard_cache_state, WRITEBACK_LINE)
	_draw_core_material_slot(Rect2(Vector2(3908.0, 62.0), Vector2(38.0, 22.0)), guard_cache_state, WRITEBACK_LINE)
	_draw_writeback_cache_feedback(guard_cache_state)
	_draw_core_status_strip(Vector2(4018.0, -104.0), writeback_state, CORE_LIGHT)
	_draw_core_material_slot(Rect2(Vector2(4016.0, -40.0), Vector2(44.0, 30.0)), writeback_state, CORE_LIGHT)
	_draw_core_write_feedback(writeback_state)
	_draw_core_status_strip(Vector2(4118.0, 96.0), retest_state, RETEST_LINE)
	_draw_core_material_slot(Rect2(Vector2(4118.0, 62.0), Vector2(36.0, 24.0)), retest_state, RETEST_LINE)
	_draw_retest_readout_feedback(retest_state)
	_draw_core_status_strip(Vector2(4190.0, -98.0), logistics_state, LOGISTICS_LINE)
	_draw_core_material_slot(Rect2(Vector2(4214.0, -62.0), Vector2(36.0, 24.0)), logistics_state, LOGISTICS_LINE)
	_draw_logistics_return_feedback(logistics_state)
	if write_ready:
		_draw_core_state_flow([Vector2(3926.0, 70.0), Vector2(3988.0, 24.0), Vector2(4038.0, -24.0)], CORE_LIGHT, 4.6)
	if core_written:
		_draw_core_state_flow([Vector2(4038.0, -24.0), Vector2(4118.0, 18.0), Vector2(4134.0, 78.0)], RETEST_LINE, 3.8)
		_draw_core_state_flow([Vector2(4134.0, 78.0), Vector2(4228.0, -52.0)], LOGISTICS_LINE, 3.2)
	if logistics_return_ready:
		_draw_core_state_flow([Vector2(4228.0, -52.0), Vector2(4168.0, -86.0), Vector2(4108.0, -118.0)], LOGISTICS_LINE, 2.8)


func _draw_recovery_supply_feedback(state: String) -> void:
	if not _is_core_ready_state(state):
		return
	for center in [Vector2(3720.0, 112.0), Vector2(3768.0, 126.0)]:
		draw_rect(Rect2(center + Vector2(-13.0, -8.0), Vector2(26.0, 16.0)), Color(RECOVERY_LINE.r, RECOVERY_LINE.g, RECOVERY_LINE.b, 0.3), true)
		draw_rect(Rect2(center + Vector2(-13.0, -8.0), Vector2(26.0, 16.0)), Color(RECOVERY_LINE.r, RECOVERY_LINE.g, RECOVERY_LINE.b, 0.64), false, 1.0, true)
		draw_line(center + Vector2(-7.0, 0.0), center + Vector2(7.0, 0.0), Color(RECOVERY_LINE.r, RECOVERY_LINE.g, RECOVERY_LINE.b, 0.72), 1.2, true)
		draw_line(center + Vector2(0.0, -5.0), center + Vector2(0.0, 5.0), Color(RECOVERY_LINE.r, RECOVERY_LINE.g, RECOVERY_LINE.b, 0.72), 1.2, true)


func _draw_guard_pressure_relief_feedback(center: Vector2, state: String) -> void:
	if state != CORE_STATE_CLEARED:
		return
	for angle in [PI * 0.18, PI * 0.42, PI * 1.18, PI * 1.42]:
		var from := center + Vector2(cos(angle), sin(angle)) * 54.0
		var to := center + Vector2(cos(angle), sin(angle)) * 80.0
		draw_line(from, to, Color(RETURN_LINE.r, RETURN_LINE.g, RETURN_LINE.b, 0.72), 2.0, true)
	draw_arc(center, 88.0, PI * 0.1, PI * 0.38, 12, Color(RETURN_LINE.r, RETURN_LINE.g, RETURN_LINE.b, 0.52), 1.8, true)
	draw_arc(center, 88.0, PI * 1.1, PI * 1.38, 12, Color(RETURN_LINE.r, RETURN_LINE.g, RETURN_LINE.b, 0.52), 1.8, true)


func _draw_writeback_cache_feedback(state: String) -> void:
	if not _is_core_ready_state(state):
		return
	for rect in [
		Rect2(Vector2(3888.0, 76.0), Vector2(24.0, 14.0)),
		Rect2(Vector2(3918.0, 82.0), Vector2(26.0, 14.0))
	]:
		draw_rect(rect, Color(WRITEBACK_LINE.r, WRITEBACK_LINE.g, WRITEBACK_LINE.b, 0.24), true)
		draw_rect(rect, Color(WRITEBACK_LINE.r, WRITEBACK_LINE.g, WRITEBACK_LINE.b, 0.64), false, 1.0, true)
		draw_line(rect.position + Vector2(5.0, rect.size.y * 0.5), rect.position + Vector2(rect.size.x - 5.0, rect.size.y * 0.5), Color(WRITEBACK_LINE.r, WRITEBACK_LINE.g, WRITEBACK_LINE.b, 0.7), 1.0, true)


func _draw_core_write_feedback(state: String) -> void:
	if state == CORE_STATE_WAITING:
		return
	var center := Vector2(4038.0, -24.0)
	var alpha := 0.86 if state == CORE_STATE_COMPLETED else 0.58
	for radius in [24.0, 44.0, 64.0]:
		draw_arc(center, radius, PI * 0.08, PI * 1.88, 48, Color(CORE_LIGHT.r, CORE_LIGHT.g, CORE_LIGHT.b, alpha * 0.5), 1.4, true)
	if state == CORE_STATE_COMPLETED:
		draw_circle(center, 10.0, Color(CORE_LIGHT.r, CORE_LIGHT.g, CORE_LIGHT.b, 0.68))


func _draw_retest_readout_feedback(state: String) -> void:
	if not _is_core_ready_state(state):
		return
	var panel_alpha := 0.86 if state == CORE_STATE_COMPLETED else 0.66
	var panel := Rect2(Vector2(4088.0, 38.0), Vector2(108.0, 76.0))
	draw_rect(panel, Color(0.004, 0.012, 0.014, 0.72), true)
	draw_rect(panel, Color(RETEST_LINE.r, RETEST_LINE.g, RETEST_LINE.b, panel_alpha), false, 2.0, true)
	draw_line(Vector2(4102.0, 56.0), Vector2(4180.0, 56.0), Color(RETEST_LINE.r, RETEST_LINE.g, RETEST_LINE.b, 0.58), 1.3, true)
	draw_line(Vector2(4102.0, 96.0), Vector2(4180.0, 96.0), Color(RETEST_LINE.r, RETEST_LINE.g, RETEST_LINE.b, 0.34), 1.0, true)
	var bar_color := Color(RETEST_LINE.r, RETEST_LINE.g, RETEST_LINE.b, 0.72 if state == CORE_STATE_COMPLETED else 0.52)
	for index in range(5):
		var x := 4110.0 + float(index) * 14.0
		var height := 16.0 + float(index % 2) * 8.0
		draw_line(Vector2(x, 88.0), Vector2(x, 88.0 - height), bar_color, 2.2, true)
	for point in [Vector2(4168.0, 70.0), Vector2(4178.0, 80.0), Vector2(4166.0, 90.0)]:
		draw_circle(point, 3.4, Color(RETEST_LINE.r, RETEST_LINE.g, RETEST_LINE.b, panel_alpha))
	draw_line(Vector2(4078.0, 54.0), Vector2(4088.0, 54.0), Color(RETEST_LINE.r, RETEST_LINE.g, RETEST_LINE.b, 0.54), 1.4, true)
	draw_line(Vector2(4196.0, 72.0), Vector2(4218.0, -28.0), Color(RETEST_LINE.r, RETEST_LINE.g, RETEST_LINE.b, 0.34), 1.1, true)
	draw_arc(Vector2(4142.0, 78.0), 34.0, PI * 0.08, PI * 0.86, 20, bar_color, 1.4, true)


func _draw_logistics_return_feedback(state: String) -> void:
	var ready := _is_core_ready_state(state)
	var dock_alpha := 0.62 if ready else 0.2
	var dock_rect := Rect2(Vector2(4070.0, -134.0), Vector2(78.0, 34.0))
	draw_rect(dock_rect, Color(LOGISTICS_LINE.r, LOGISTICS_LINE.g, LOGISTICS_LINE.b, dock_alpha * 0.32), true)
	draw_rect(dock_rect, Color(LOGISTICS_LINE.r, LOGISTICS_LINE.g, LOGISTICS_LINE.b, dock_alpha), false, 1.2, true)
	for x in [4088.0, 4110.0, 4132.0]:
		draw_line(Vector2(x, -132.0), Vector2(x + 12.0, -102.0), Color(LOGISTICS_LINE.r, LOGISTICS_LINE.g, LOGISTICS_LINE.b, dock_alpha * 0.48), 1.0, true)
	if not ready:
		return
	for center in [Vector2(4102.0, -116.0), Vector2(4130.0, -118.0)]:
		draw_rect(Rect2(center + Vector2(-8.0, -6.0), Vector2(16.0, 12.0)), Color(RETURN_LINE.r, RETURN_LINE.g, RETURN_LINE.b, 0.38), true)
		draw_rect(Rect2(center + Vector2(-8.0, -6.0), Vector2(16.0, 12.0)), Color(RETURN_LINE.r, RETURN_LINE.g, RETURN_LINE.b, 0.68), false, 0.9, true)


func _draw_core_status_strip(origin: Vector2, state: String, color: Color) -> void:
	var rect := Rect2(origin, Vector2(34.0, 14.0))
	draw_rect(rect, STATUS_PANEL_FILL, true)
	draw_rect(rect, Color(color.r, color.g, color.b, 0.26), false, 1.0, true)
	var light_count := _core_status_light_count(state)
	for index in range(3):
		var light_position := origin + Vector2(8.0 + float(index) * 10.0, 7.0)
		var light_color := _core_status_light_color(state, color) if index < light_count else STATUS_IDLE_LIGHT
		draw_circle(light_position, 3.4, light_color)


func _draw_core_material_slot(rect: Rect2, state: String, color: Color) -> void:
	var ready := _is_core_ready_state(state)
	draw_rect(rect, Color(0.018, 0.028, 0.028, 0.58), true)
	draw_rect(rect, Color(color.r, color.g, color.b, 0.23 if ready else 0.05), true)
	draw_rect(rect, Color(color.r, color.g, color.b, 0.74 if ready else 0.18), false, 1.2, true)
	if not ready:
		return
	var center := rect.position + rect.size * 0.5
	draw_line(center + Vector2(-rect.size.x * 0.34, 0.0), center + Vector2(rect.size.x * 0.34, 0.0), Color(color.r, color.g, color.b, 0.6), 1.4, true)
	draw_circle(center, minf(rect.size.x, rect.size.y) * 0.16, Color(color.r, color.g, color.b, 0.54))


func _draw_core_pressure_state(center: Vector2, state: String) -> void:
	var cleared := state == CORE_STATE_CLEARED
	if cleared:
		for arc_range in [
			[PI * 0.04, PI * 0.22],
			[PI * 0.82, PI * 1.0],
			[PI * 1.25, PI * 1.48]
		]:
			draw_arc(center, 70.0, float(arc_range[0]), float(arc_range[1]), 10, Color(RETURN_LINE.r, RETURN_LINE.g, RETURN_LINE.b, 0.36), 1.3, true)
		return
	var color := RETURN_LINE if cleared else PRESSURE_LINE
	draw_arc(center, 74.0, 0.0, TAU, 54, Color(color.r, color.g, color.b, 0.54 if cleared else 0.72), 2.0, true)
	draw_arc(center, 46.0, 0.0, TAU, 42, Color(color.r, color.g, color.b, 0.28 if cleared else 0.44), 1.6, true)
	for angle in [0.0, PI * 0.5, PI, PI * 1.5]:
		var from := center + Vector2(cos(angle), sin(angle)) * 52.0
		var to := center + Vector2(cos(angle), sin(angle)) * 74.0
		draw_line(from, to, Color(color.r, color.g, color.b, 0.5), 1.4, true)


func _draw_core_state_flow(points: Array[Vector2], color: Color, width: float) -> void:
	draw_polyline(PackedVector2Array(points), Color(0.02, 0.04, 0.04, 0.54), width + 3.0, true)
	draw_polyline(PackedVector2Array(points), Color(color.r, color.g, color.b, 0.72), width, true)
	for point in points:
		draw_circle(point, width * 0.55, Color(color.r, color.g, color.b, 0.62))


func _draw_operation_relation_overlay() -> void:
	_draw_relation_track([Vector2(3744.0, 112.0), Vector2(3834.0, 82.0), Vector2(3926.0, 70.0)], RECOVERY_LINE)
	_draw_relation_track([Vector2(3926.0, 70.0), Vector2(3988.0, 24.0), Vector2(4038.0, -24.0)], WRITEBACK_LINE)
	_draw_relation_track([Vector2(4038.0, -24.0), Vector2(4118.0, 18.0), Vector2(4134.0, 78.0)], RETEST_LINE)
	_draw_relation_track([Vector2(4134.0, 78.0), Vector2(4228.0, -52.0), Vector2(4108.0, -118.0)], LOGISTICS_LINE)
	_draw_relation_track([Vector2(4134.0, 78.0), Vector2(4218.0, -28.0), Vector2(4252.0, -126.0)], ANOMALY_HOOK_LINE)
	for port in [
		{"position": Vector2(3744.0, 112.0), "color": RECOVERY_LINE},
		{"position": Vector2(3926.0, 70.0), "color": WRITEBACK_LINE},
		{"position": Vector2(4038.0, -24.0), "color": CORE_LIGHT},
		{"position": Vector2(4134.0, 78.0), "color": RETEST_LINE},
		{"position": Vector2(4228.0, -52.0), "color": LOGISTICS_LINE},
		{"position": Vector2(4108.0, -118.0), "color": RETURN_LINE},
		{"position": Vector2(4252.0, -126.0), "color": ANOMALY_HOOK_LINE}
	]:
		var position: Vector2 = port["position"]
		var color: Color = port["color"]
		_draw_relation_port(position, color)


func _draw_relation_track(points: Array[Vector2], color: Color) -> void:
	draw_polyline(PackedVector2Array(points), Color(0.012, 0.026, 0.026, 0.68), 6.0, true)
	draw_polyline(PackedVector2Array(points), Color(color.r, color.g, color.b, 0.22), 2.0, true)
	for index in range(points.size() - 1):
		var from := points[index]
		var to := points[index + 1]
		if from.distance_to(to) < 36.0:
			continue
		var direction := (to - from).normalized()
		var normal := Vector2(-direction.y, direction.x)
		var center := from.lerp(to, 0.62)
		draw_line(center - direction * 5.0 - normal * 3.0, center + direction * 4.0, Color(color.r, color.g, color.b, 0.34), 1.1, true)
		draw_line(center - direction * 5.0 + normal * 3.0, center + direction * 4.0, Color(color.r, color.g, color.b, 0.34), 1.1, true)


func _draw_relation_port(position: Vector2, color: Color) -> void:
	draw_circle(position, 7.2, Color(color.r, color.g, color.b, 0.12))
	draw_arc(position, 10.4, 0.0, TAU, 22, Color(color.r, color.g, color.b, 0.28), 1.0, true)
	draw_rect(Rect2(position + Vector2(-3.5, -3.5), Vector2(7.0, 7.0)), Color(color.r, color.g, color.b, 0.22), true)


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
		"station.guard_pressure_resolved",
		"station.completed_guard_residue_wash",
		"station.writeback_device",
		"station.guard_cache",
		"station.retest_readout",
		"station.retest_readout_panel",
		"station.retest_reader_bank",
		"station.logistics_retest_pocket",
		"station.logistics_return_dock",
		"station.energy_confluence_nodes",
		"station.output_bus_nodes",
		"station.return_service_lane",
		"station.core_status_lights",
		"station.core_pressure_warning",
		"station.core_write_feedback",
		"station.archived_stabilization_spine",
		"station.stability_window_hook",
		"station.unresolved_anomaly_probe"
	]


func _register_flow_shapes() -> void:
	flow_shape_ids = [
		"flow.entry_to_guard",
		"flow.recovery_to_guard_cache",
		"flow.guard_cache_to_core",
		"flow.core_to_retest",
		"flow.retest_to_logistics",
		"flow.core_return_to_base",
		"flow.core_local_completed_return",
		"flow.core_runtime_status_lights",
		"flow.core_runtime_write_feedback",
		"flow.core_runtime_logistics_return",
		"flow.completed_core_local_routes",
		"flow.stability_window_hook",
		"operation_relation.core.recovery_to_guard_cache",
		"operation_relation.core.guard_cache_to_write_device",
		"operation_relation.core.write_device_to_retest",
		"operation_relation.core.logistics_return",
		"operation_relation.core.role_ports",
		"operation_relation.core.unresolved_anomaly_hook"
	]


func _register_core_station_state_shape(shape_id: String) -> void:
	if core_station_state_shape_ids.has(shape_id):
		return
	core_station_state_shape_ids.append(shape_id)
	applied_core_station_state_count = core_station_state_shape_ids.size()


func _has_core_station_context(world_state: WorldState, character_state: CharacterState) -> bool:
	if world_state.current_region_id == "region.demo_stabilization_core":
		return true
	if character_state.current_region_id == "region.demo_stabilization_core":
		return true
	if world_state.unlocked_region_ids.has("region.demo_stabilization_core"):
		return true
	if character_state.inventory.has_ref("item.core_stabilization_buffer", 1):
		return true
	if character_state.inventory.has_ref("item.core_write_charge", 1):
		return true
	for quest_id in [
		"quest.enter_demo_stabilization_core",
		"quest.prepare_demo_stabilization_buffer",
		"quest.defeat_demo_stabilization_guard",
		"quest.write_demo_stabilization_core"
	]:
		if world_state.quest_state.has_active_quest(quest_id) or world_state.quest_state.has_completed_quest(quest_id):
			return true
	return false


func _core_ready_suffix(is_ready: bool) -> String:
	return "ready" if is_ready else "idle"


func _core_activity_suffix(is_active: bool) -> String:
	return "active" if is_active else "idle"


func _core_status_light_count(state: String) -> int:
	match state:
		CORE_STATE_READY, CORE_STATE_CLEARED:
			return 2
		CORE_STATE_COMPLETED:
			return 3
		CORE_STATE_PRESSURE:
			return 1
		_:
			return 0


func _core_status_light_color(state: String, color: Color) -> Color:
	match state:
		CORE_STATE_COMPLETED:
			return Color(color.r, color.g, color.b, 0.92)
		CORE_STATE_READY, CORE_STATE_CLEARED:
			return Color(color.r, color.g, color.b, 0.72)
		CORE_STATE_PRESSURE:
			return Color(PRESSURE_LINE.r, PRESSURE_LINE.g, PRESSURE_LINE.b, 0.72)
		_:
			return STATUS_IDLE_LIGHT


func _is_core_ready_state(state: String) -> bool:
	return state in [
		CORE_STATE_READY,
		CORE_STATE_COMPLETED,
		CORE_STATE_CLEARED
	]


func _is_core_written() -> bool:
	return bool(core_station_state.get("core_written", false))


func _is_guard_pressure_cleared() -> bool:
	return String(core_station_state.get("guard_pressure_state", CORE_STATE_PRESSURE)) == CORE_STATE_CLEARED


func _deemphasize_legacy_core_blocks() -> void:
	muted_legacy_block_count = 0
	var region := _get_map_node("RegionDemoStabilizationCore") as ColorRect
	if region != null:
		region.color = Color(0.06, 0.12, 0.12, 0.09)
	var route_band := _get_map_node("DemoRoutePresentationLayer/DemoRouteCoreBand") as ColorRect
	if route_band != null:
		route_band.color = Color(route_band.color.r, route_band.color.g, route_band.color.b, minf(route_band.color.a, 0.008))
	var approach_flow := _get_map_node("DemoRoutePresentationLayer/DemoRouteCoreApproachFlow") as ColorRect
	if approach_flow != null:
		approach_flow.color = Color(approach_flow.color.r, approach_flow.color.g, approach_flow.color.b, minf(approach_flow.color.a, 0.006))
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
				rect.color = Color(rect.color.r, rect.color.g, rect.color.b, minf(rect.color.a, 0.014))
				muted_legacy_block_count += 1
		for node_name in LEGACY_CORE_MARKERS:
			var rect := opening_layer.get_node_or_null(String(node_name)) as ColorRect
			if rect != null:
				rect.color = Color(rect.color.r, rect.color.g, rect.color.b, minf(rect.color.a, 0.008))
				muted_legacy_block_count += 1
		var pressure_label := opening_layer.get_node_or_null("CoreStabilizationPressureLabel") as Label
		if pressure_label != null:
			pressure_label.visible = false

	var run_layer := _get_map_node("CoreStabilizationRunLayer")
	if run_layer != null:
		for node_name in RUN_LAYER_BLOCKS:
			var rect := run_layer.get_node_or_null(String(node_name)) as ColorRect
			if rect != null:
				rect.color = Color(rect.color.r, rect.color.g, rect.color.b, minf(rect.color.a, 0.012))
				muted_legacy_block_count += 1


func _update_core_focus_context_layers() -> void:
	if not visible:
		_restore_core_focus_context_layers()
		return
	muted_core_focus_context_layer_count = 0
	for layer_profile in CORE_FOCUS_CONTEXT_LAYER_ALPHAS:
		var path := String(layer_profile.get("path", ""))
		var alpha := float(layer_profile.get("alpha", 1.0))
		if _apply_context_layer_alpha(path, alpha):
			muted_core_focus_context_layer_count += 1


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


func _restore_core_focus_context_layers() -> void:
	if context_layer_original_modulates.is_empty():
		muted_core_focus_context_layer_count = 0
		return
	for path in context_layer_original_modulates.keys():
		var node := _get_map_node(String(path))
		var canvas_item := node as CanvasItem
		if canvas_item != null:
			canvas_item.modulate = context_layer_original_modulates[path]
	context_layer_original_modulates.clear()
	muted_core_focus_context_layer_count = 0


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
