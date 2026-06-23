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
	_check_core_visual_runtime_state_feedback()
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
	_expect_equal(layer.get_station_shape_count() >= 13, true, "core visual layer registers terminal station shapes")
	_expect_equal(layer.get_flow_count() >= 6, true, "core visual layer registers terminal station flows")
	_expect_equal(layer.has_station_shape("station.arrival_threshold"), true, "core visual layer marks arrival threshold")
	_expect_equal(layer.has_station_shape("station.central_maintenance_deck"), true, "core visual layer marks central maintenance deck")
	_expect_equal(layer.has_station_shape("station.writeback_service_ring"), true, "core visual layer marks writeback service ring")
	_expect_equal(layer.has_station_shape("station.guard_pressure_field"), true, "core visual layer marks guard pressure field")
	_expect_equal(layer.has_station_shape("station.guard_pressure_resolved"), true, "core visual layer marks resolved guard pressure")
	_expect_equal(layer.has_station_shape("station.completed_guard_residue_wash"), true, "core visual layer marks completed guard residue wash")
	_expect_equal(layer.has_station_shape("station.writeback_device"), true, "core visual layer marks writeback device")
	_expect_equal(layer.has_station_shape("station.energy_confluence_nodes"), true, "core visual layer marks energy confluence nodes")
	_expect_equal(layer.has_station_shape("station.retest_readout"), true, "core visual layer marks retest readout")
	_expect_equal(layer.has_station_shape("station.retest_readout_panel"), true, "core visual layer marks independent retest readout panel")
	_expect_equal(layer.has_station_shape("station.retest_reader_bank"), true, "core visual layer marks retest reader bank")
	_expect_equal(layer.has_station_shape("station.output_bus_nodes"), true, "core visual layer marks output bus nodes")
	_expect_equal(layer.has_station_shape("station.logistics_return_dock"), true, "core visual layer marks logistics return dock")
	_expect_equal(layer.has_station_shape("station.core_status_lights"), true, "core visual layer marks runtime status lights")
	_expect_equal(layer.has_station_shape("station.core_pressure_warning"), true, "core visual layer marks pressure warning feedback")
	_expect_equal(layer.has_station_shape("station.core_write_feedback"), true, "core visual layer marks core write feedback")
	_expect_equal(layer.has_flow_shape("flow.guard_cache_to_core"), true, "core visual layer marks guard cache to core route")
	_expect_equal(layer.has_flow_shape("flow.core_return_to_base"), true, "core visual layer marks return logistics route")
	_expect_equal(layer.has_flow_shape("flow.core_local_completed_return"), true, "core visual layer marks completed local return scope")
	_expect_equal(layer.has_flow_shape("flow.core_runtime_status_lights"), true, "core visual layer marks runtime status light flow")
	_expect_equal(layer.has_flow_shape("flow.core_runtime_write_feedback"), true, "core visual layer marks runtime write feedback flow")
	_expect_equal(layer.has_flow_shape("flow.core_runtime_logistics_return"), true, "core visual layer marks runtime logistics return flow")
	_expect_equal(layer.has_flow_shape("flow.completed_core_local_routes"), true, "core visual layer marks completed local route scope")
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
	_expect_equal(layer.get_muted_core_focus_context_layer_count() >= 3, true, "core station focus mutes neighboring context layers")
	map.free()


func _check_core_visual_runtime_state_feedback() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node("DemoCoreStabilizationVisualLayer") as DemoCoreStabilizationVisualLayer
	layer.apply_visuals()
	var world := WorldState.create_default()
	world.current_region_id = "region.demo_stabilization_core"
	world.unlock_region("region.demo_stabilization_core")
	world.quest_state.complete_quest("quest.enter_demo_stabilization_core")
	world.quest_state.complete_quest("quest.prepare_demo_stabilization_buffer")
	world.quest_state.complete_quest("quest.defeat_demo_stabilization_guard")
	world.quest_state.active_quest_ids = ["quest.write_demo_stabilization_core"]
	world.quest_state.set_objective_progress("quest.write_demo_stabilization_core", "gather_item", "item.core_write_charge", 1.0)
	world.ensure_enemy("enemy_instance.demo_stabilization_guard", "enemy.demo_stabilization_guard", "region.demo_stabilization_core", 156.0)
	world.update_enemy_health("enemy_instance.demo_stabilization_guard", 0.0, true)
	world.ensure_map_object(
		"map_object_instance.demo_stabilization_guard_cache",
		"map_object.demo_stabilization_guard_cache",
		"region.demo_stabilization_core"
	)
	world.set_map_object_flag("map_object_instance.demo_stabilization_guard_cache", "is_gathered", true)
	world.ensure_map_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"region.demo_stabilization_core"
	)
	world.ensure_map_object(
		"map_object_instance.demo_stabilization_retest_readout_cache",
		"map_object.demo_stabilization_retest_readout_cache",
		"region.demo_stabilization_core"
	)
	var character := CharacterState.create_default()
	character.current_region_id = "region.demo_stabilization_core"
	character.inventory.add_item("item.core_stabilization_buffer", 1)
	character.inventory.add_item("item.core_write_charge", 1)

	layer.refresh_core_station_state(world, character)
	_expect_equal(layer.get_core_station_state_shape_count() >= 11, true, "core visual layer creates runtime station state shapes")
	_expect_equal(layer.has_core_station_state_shape("core_station.device.recovery.ready"), true, "core visual marks recovery supply ready")
	_expect_equal(layer.has_core_station_state_shape("core_station.device.guard_cache.ready"), true, "core visual marks guard cache ready")
	_expect_equal(layer.has_core_station_state_shape("core_station.pressure.guard.cleared"), true, "core visual marks guard pressure cleared")
	_expect_equal(layer.has_core_station_state_shape("core_station.device.writeback.ready"), true, "core visual marks writeback ready")
	_expect_equal(layer.has_core_station_state_shape("core_station.feedback.recovery_supply.ready"), true, "core visual marks recovery supply feedback")
	_expect_equal(layer.has_core_station_state_shape("core_station.feedback.guard_pressure_relief.cleared"), true, "core visual marks cleared guard pressure feedback")
	_expect_equal(layer.has_core_station_state_shape("core_station.feedback.writeback_cache.ready"), true, "core visual marks writeback cache feedback")
	_expect_equal(layer.has_core_station_state_shape("core_station.flow.guard_cache_to_core.ready"), true, "core visual marks guard cache to core flow")
	_expect_equal(layer.has_core_station_state_shape("core_station.flow.core_write.active"), true, "core visual marks active core write flow")

	world.set_map_object_flag("map_object_instance.demo_stabilization_core", "is_sampled", true)
	world.quest_state.complete_quest("quest.write_demo_stabilization_core")
	layer.refresh_core_station_state(world, character)
	_expect_equal(layer.has_core_station_state_shape("core_station.device.writeback.completed"), true, "core visual marks writeback completed")
	_expect_equal(layer.has_core_station_state_shape("core_station.device.guard_cache.completed"), true, "core visual marks guard cache archived after write")
	_expect_equal(layer.has_core_station_state_shape("core_station.device.retest.ready"), true, "core visual marks retest ready after write")
	_expect_equal(layer.has_core_station_state_shape("core_station.device.logistics.ready"), true, "core visual marks logistics return ready after write")
	_expect_equal(layer.has_core_station_state_shape("core_station.feedback.core_write.completed"), true, "core visual marks completed write feedback")
	_expect_equal(layer.has_core_station_state_shape("core_station.feedback.retest_readout.ready"), true, "core visual marks retest readout feedback")
	_expect_equal(layer.has_core_station_state_shape("core_station.feedback.logistics_return.ready"), true, "core visual marks logistics return feedback")
	_expect_equal(layer.has_core_station_state_shape("core_station.flow.core_to_retest.ready"), true, "core visual marks core to retest flow after write")
	_expect_equal(layer.has_core_station_state_shape("core_station.flow.logistics_return.ready"), true, "core visual marks local logistics return flow after write")
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
	var route_band := map.get_node("DemoRoutePresentationLayer/DemoRouteCoreBand") as ColorRect
	var approach_flow := map.get_node("DemoRoutePresentationLayer/DemoRouteCoreApproachFlow") as ColorRect
	var pressure_label := map.get_node("OpeningSceneLayer/CoreStabilizationPressureLabel") as Label
	var route_label := map.get_node("DemoRoutePresentationLayer/DemoRouteCoreLabel") as Label
	var core_interactable := map.get_node("Interactables/DemoStabilizationCore") as PrototypeInteractable
	_expect_equal(old_guard.color.a <= 0.04, true, "old core guard field no longer dominates")
	_expect_equal(old_core_pad.color.a <= 0.025, true, "old core pad marker no longer dominates")
	_expect_equal(run_write_pad.color.a <= 0.035, true, "old run layer write pad no longer dominates")
	_expect_equal(route_band.color.a <= 0.01, true, "old core route band no longer dominates")
	_expect_equal(approach_flow.color.a <= 0.01, true, "old core approach flow no longer draws a cross-screen line")
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
