extends SceneTree

const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")

var failures: Array[String] = []


func _init() -> void:
	_run_checks()

	if failures.is_empty():
		print("Demo core stabilization visual checks passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _run_checks() -> void:
	_check_core_visual_layer_exists_and_registers_station_shapes()
	_check_core_visual_focus_visibility()
	_check_core_visual_layer_replaces_old_terminal_blocks()
	_check_core_visual_runtime_anchors_are_tagged()


func _check_core_visual_layer_exists_and_registers_station_shapes() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node_or_null("DemoCoreStabilizationVisualLayer") as DemoCoreStabilizationVisualLayer
	_expect_equal(layer != null, true, "core stabilization visual layer exists")
	if layer == null:
		map.free()
		return

	layer.apply_visuals()
	_expect_equal(layer.get_station_shape_count() >= 10, true, "core visual layer registers terminal station shapes")
	_expect_equal(layer.get_flow_count() >= 6, true, "core visual layer registers terminal station flows")
	_expect_equal(layer.has_station_shape("station.arrival_threshold"), true, "core visual layer marks arrival threshold")
	_expect_equal(layer.has_station_shape("station.central_maintenance_deck"), true, "core visual layer marks central maintenance deck")
	_expect_equal(layer.has_station_shape("station.guard_pressure_field"), true, "core visual layer marks guard pressure field")
	_expect_equal(layer.has_station_shape("station.writeback_device"), true, "core visual layer marks writeback device")
	_expect_equal(layer.has_station_shape("station.energy_confluence_nodes"), true, "core visual layer marks energy confluence nodes")
	_expect_equal(layer.has_station_shape("station.retest_readout"), true, "core visual layer marks retest readout")
	_expect_equal(layer.has_flow_shape("flow.guard_cache_to_core"), true, "core visual layer marks guard cache to core route")
	_expect_equal(layer.has_flow_shape("flow.core_return_to_base"), true, "core visual layer marks return logistics route")
	map.free()


func _check_core_visual_focus_visibility() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node("DemoCoreStabilizationVisualLayer") as DemoCoreStabilizationVisualLayer
	layer.apply_visuals()

	layer.refresh_focus_visibility(Vector2(-250, -48))
	_expect_equal(layer.visible, false, "core stabilization visual layer stays hidden at startup objective")
	layer.refresh_focus_visibility(Vector2(3744, 112))
	_expect_equal(layer.visible, true, "core stabilization visual layer appears inside terminal station")
	map.free()


func _check_core_visual_layer_replaces_old_terminal_blocks() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node("DemoCoreStabilizationVisualLayer") as DemoCoreStabilizationVisualLayer
	layer.apply_visuals()

	_expect_equal(layer.get_muted_legacy_block_count() >= 24, true, "old core terminal blocks are muted")
	_expect_equal(layer.get_muted_interactable_marker_count() >= 5, true, "old core interactable markers are muted")
	_expect_equal(layer.get_muted_enemy_sprite_count() >= 2, true, "core enemy sprites are visually subordinate")
	var old_guard := map.get_node("OpeningSceneLayer/CoreStabilizationGuardPressureZone") as ColorRect
	var old_core_pad := map.get_node("OpeningSceneLayer/CoreStabilizationCorePad") as ColorRect
	var run_write_pad := map.get_node("CoreStabilizationRunLayer/CoreRunWritePad") as ColorRect
	var pressure_label := map.get_node("OpeningSceneLayer/CoreStabilizationPressureLabel") as Label
	var route_label := map.get_node("DemoRoutePresentationLayer/DemoRouteCoreLabel") as Label
	var core_interactable := map.get_node("Interactables/DemoStabilizationCore") as PrototypeInteractable
	_expect_equal(old_guard.color.a <= 0.07, true, "old core guard field no longer dominates")
	_expect_equal(old_core_pad.color.a <= 0.035, true, "old core pad marker no longer dominates")
	_expect_equal(run_write_pad.color.a <= 0.05, true, "old run layer write pad no longer dominates")
	_expect_equal(pressure_label.visible, false, "old core pressure long label hidden")
	_expect_equal(route_label.visible, false, "old core route label hidden")
	_expect_equal(_get_marker_alpha(core_interactable) <= 0.08, true, "core interactable marker is muted")
	map.free()


func _check_core_visual_runtime_anchors_are_tagged() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node("DemoCoreStabilizationVisualLayer") as DemoCoreStabilizationVisualLayer
	layer.apply_visuals()

	_expect_anchor_role(map, "Interactables/DemoStabilizationCore", DemoCoreStabilizationVisualLayer.ROLE_WRITEBACK)
	_expect_anchor_role(map, "Interactables/DemoStabilizationRecoveryCache", DemoCoreStabilizationVisualLayer.ROLE_RECOVERY)
	_expect_anchor_role(map, "Interactables/DemoStabilizationGuardCache", DemoCoreStabilizationVisualLayer.ROLE_WRITEBACK)
	_expect_anchor_role(map, "Interactables/DemoStabilizationRetestReadoutCache", DemoCoreStabilizationVisualLayer.ROLE_RETEST)
	_expect_anchor_role(map, "Interactables/PollutionResidueLogisticsMaintenanceRetestCache", DemoCoreStabilizationVisualLayer.ROLE_LOGISTICS)
	_expect_anchor_role(map, "Enemies/DemoStabilizationGuard", DemoCoreStabilizationVisualLayer.ROLE_GUARD_FIELD)
	map.free()


func _expect_anchor_role(map: VerticalSliceMap, path: String, expected_role: String) -> void:
	var node := map.get_node_or_null(path)
	_expect_equal(node != null, true, "%s exists for core stabilization visual" % path)
	if node == null:
		return
	_expect_equal(
		String(node.get_meta("core_stabilization_visual_role", "")),
		expected_role,
		"%s carries core stabilization visual role" % path
	)
	_expect_equal(
		String(node.get_meta("core_stabilization_visual_scope", "")),
		"terminal_station",
		"%s carries core stabilization visual scope" % path
	)


func _get_marker_alpha(interactable: PrototypeInteractable) -> float:
	if interactable == null:
		return 1.0
	var marker := interactable.marker
	if marker == null:
		marker = interactable.get_node_or_null("Marker") as ColorRect
	if marker == null:
		return 1.0
	return marker.color.a


func _expect_equal(actual, expected, context: String) -> void:
	if actual == expected:
		return
	failures.append("%s: expected %s, got %s" % [context, str(expected), str(actual)])
