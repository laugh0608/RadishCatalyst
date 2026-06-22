extends SceneTree

const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")

var failures: Array[String] = []


func _init() -> void:
	_run_checks()

	if failures.is_empty():
		print("Demo pollution boundary visual checks passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _run_checks() -> void:
	_check_pollution_boundary_layer_exists_and_registers_visuals()
	_check_pollution_boundary_focus_visibility()
	_check_pollution_boundary_chain_state_visuals()
	_check_pollution_boundary_visual_priority_replaces_old_blocks()
	_check_pollution_boundary_runtime_anchors_are_tagged()


func _check_pollution_boundary_layer_exists_and_registers_visuals() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node_or_null("DemoPollutionBoundaryVisualLayer") as DemoPollutionBoundaryVisualLayer
	_expect_equal(layer != null, true, "pollution boundary visual layer exists")
	if layer == null:
		map.free()
		return

	layer.apply_visuals()
	_expect_equal(layer.get_boundary_shape_count() >= 13, true, "pollution boundary registers treatment shapes")
	_expect_equal(layer.get_flow_count() >= 5, true, "pollution boundary registers treatment routes")
	_expect_equal(layer.get_terrain_material_shape_count() >= 19, true, "pollution boundary registers terrain material shapes")
	_expect_equal(layer.has_boundary_shape("boundary.filter_build_site"), true, "filter construction site visual exists")
	_expect_equal(layer.has_boundary_shape("boundary.pressure_gate"), true, "pressure gate visual exists")
	_expect_equal(layer.has_boundary_shape("boundary.hazard_boundary"), true, "danger boundary visual exists")
	_expect_equal(layer.has_boundary_shape("residue.entry_patch"), true, "entry residue patch visual exists")
	_expect_equal(layer.has_flow_shape("flow.residue_to_filter"), true, "residue to filter route exists")
	_expect_equal(layer.has_flow_shape("flow.filter_to_base_return"), true, "filter to base logistics route exists")
	_expect_equal(layer.has_flow_shape("flow.pollution_status_lights"), true, "pollution chain status lights exist")
	_expect_equal(layer.has_flow_shape("flow.pollution_material_state_slots"), true, "pollution material state slots exist")
	_expect_equal(layer.has_flow_shape("flow.pollution_pressure_warning_nodes"), true, "pollution pressure warning nodes exist")
	_expect_equal(layer.has_terrain_material_shape("terrain.pollution.sediment_fan"), true, "pollution sediment fan material exists")
	_expect_equal(layer.has_terrain_material_shape("terrain.pollution.segmented_settling_cells"), true, "pollution settling field is split into cells")
	_expect_equal(layer.has_terrain_material_shape("terrain.pollution.local_settling_islands"), true, "pollution settling field has local material islands")
	_expect_equal(layer.has_terrain_material_shape("terrain.pollution.danger_bund"), true, "pollution danger bund material exists")
	_expect_equal(layer.has_terrain_material_shape("terrain.pollution.local_danger_pockets"), true, "pollution danger field is split into local pockets")
	_expect_equal(layer.has_terrain_material_shape("terrain.pollution.segmented_danger_bund"), true, "pollution danger bund is segmented")
	_expect_equal(layer.has_terrain_material_shape("terrain.pollution.dark_break_cells"), true, "pollution field is cut by dark material breaks")
	_expect_equal(layer.has_terrain_material_shape("terrain.pollution.filter_gravel_bed"), true, "pollution filter worksite gravel exists")
	_expect_equal(layer.has_terrain_material_shape("terrain.pollution.filter_bed_partitions"), true, "pollution filter worksite is split into partitions")
	_expect_equal(layer.has_terrain_material_shape("terrain.pollution.filter_rubble_cells"), true, "pollution filter worksite has rubble cells")
	_expect_equal(layer.has_terrain_material_shape("terrain.pollution.input_trench"), true, "pollution filter input trench exists")
	_expect_equal(layer.has_terrain_material_shape("terrain.pollution.local_service_ports"), true, "pollution filter uses local service ports instead of a cross-map route")
	_expect_equal(layer.has_terrain_material_shape("terrain.pollution.output_vial_rack"), true, "pollution vial output rack exists")
	_expect_equal(layer.has_terrain_material_shape("terrain.pollution.output_slurry_basin"), true, "pollution slurry output basin exists")
	_expect_equal(layer.has_terrain_material_shape("terrain.pollution.output_service_islands"), true, "pollution outputs sit on local service islands")
	_expect_equal(layer.has_terrain_material_shape("terrain.pollution.recovery_loading_pad"), true, "pollution recovery loading pad exists")
	_expect_equal(layer.has_terrain_material_shape("terrain.pollution.recovery_crate_stacks"), true, "pollution recovery loading pad has crate stacks")
	map.free()


func _check_pollution_boundary_focus_visibility() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node("DemoPollutionBoundaryVisualLayer") as DemoPollutionBoundaryVisualLayer
	var carryover_wreckage := map.get_node("Interactables/FieldWreckageTreatmentApproach") as PrototypeInteractable
	layer.apply_visuals()

	layer.refresh_focus_visibility(Vector2(-250, -48))
	_expect_equal(layer.visible, false, "pollution boundary visual layer stays hidden at startup objective")
	carryover_wreckage.set_focus_visual(true)
	layer.refresh_focus_visibility(Vector2(258, 34))
	_expect_equal(layer.visible, true, "pollution boundary visual layer appears inside pollution treatment boundary")
	_expect_equal(layer.get_muted_cross_region_focus_count() >= 1, true, "pollution focus mutes carryover crystal and wreckage labels")
	_expect_equal((carryover_wreckage.get_node("Label") as Label).visible, false, "pollution focus hides carryover wreckage label")
	_expect_equal((carryover_wreckage.get_node("FocusRing") as ColorRect).visible, false, "pollution focus hides carryover wreckage focus ring")
	layer.refresh_focus_visibility(Vector2(900, 34))
	_expect_equal(layer.visible, false, "pollution boundary visual layer steps back after leaving treatment boundary")
	map.free()


func _check_pollution_boundary_chain_state_visuals() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node("DemoPollutionBoundaryVisualLayer") as DemoPollutionBoundaryVisualLayer
	layer.apply_visuals()
	var world := WorldState.create_default()
	world.quest_state.active_quest_ids = ["quest.prepare_demo_stabilization_buffer"]
	world.add_base_structure("structure.pollution_filter", "building.pollution_filter", "region.pollution_edge")
	world.set_base_structure_status("structure.pollution_filter", "in_progress", "recipe.cleanse_residue")
	var character := CharacterState.create_default()
	character.inventory.add_item("item.polluted_residue", 2)
	character.inventory.add_item("item.resistance_vial_t1", 1)
	character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	character.inventory.add_item("item.basic_parts", 2)
	character.inventory.add_item("item.repair_gel", 1)

	layer.refresh_pollution_chain_state(world, character)
	_expect_equal(layer.get_pollution_chain_state_shape_count() >= 17, true, "pollution boundary visual layer creates dynamic chain shapes")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.boundary_residue_queue.ready"), true, "pollution boundary marks residue queue")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.boundary_filter_window.ready"), true, "pollution boundary marks filter process window")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.boundary_vial_output.ready"), true, "pollution boundary marks vial output")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.boundary_slurry_output.ready"), true, "pollution boundary marks slurry output")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.boundary_base_return_route.ready"), true, "pollution boundary marks base return route")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.boundary_slurry_split_route.ready"), true, "pollution boundary marks slurry split route")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.boundary_recycle_route.ready"), true, "pollution boundary marks slurry recycle route")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.boundary_core_prep_route.ready"), true, "pollution boundary marks core prep route")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.device.residue.loaded"), true, "pollution boundary marks residue device loaded")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.device.filter.processing"), true, "pollution boundary marks filter device processing")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.device.vial_output.output_ready"), true, "pollution boundary marks vial output device ready")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.device.slurry_output.output_ready"), true, "pollution boundary marks slurry output device ready")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.device.return_pad.core_prep"), true, "pollution boundary marks core prep return pad")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.flow.filter_processing.active"), true, "pollution boundary marks active filter process")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.flow.vial_to_base.ready"), true, "pollution boundary marks vial return flow")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.flow.slurry_to_recycle.ready"), true, "pollution boundary marks slurry recycle flow")
	_expect_equal(layer.has_pollution_chain_shape("pollution_chain.flow.slurry_to_core_prep.ready"), true, "pollution boundary marks slurry core prep flow")
	map.free()


func _check_pollution_boundary_visual_priority_replaces_old_blocks() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node("DemoPollutionBoundaryVisualLayer") as DemoPollutionBoundaryVisualLayer
	layer.apply_visuals()

	_expect_equal(layer.get_muted_legacy_block_count() >= 40, true, "old pollution blocks are muted")
	_expect_equal(layer.get_muted_interactable_marker_count() >= 15, true, "old pollution interactable markers are muted")
	var old_danger := map.get_node("OpeningSceneLayer/PollutionDangerField") as ColorRect
	var old_residue := map.get_node("OpeningSceneLayer/PollutionEntryResidueMarker") as ColorRect
	var belt_label := map.get_node("OpeningSceneLayer/PollutionBeltLabel") as Label
	var route_label := map.get_node("DemoRoutePresentationLayer/DemoRoutePollutionLabel") as Label
	var route_band := map.get_node("DemoRoutePresentationLayer/DemoRoutePollutionBand") as ColorRect
	var residue_interactable := map.get_node("Interactables/PollutionResidue") as PrototypeInteractable
	var filter_build_site := map.get_node("Interactables/PollutionFilterBuildSite") as PrototypeInteractable
	_expect_equal(old_danger.visible, false, "old pollution field is removed from the treatment view")
	_expect_equal(old_residue.visible, false, "old pollution marker is removed from the treatment view")
	_expect_equal(route_band.visible, false, "old pollution route band is removed from the treatment view")
	_expect_equal(old_danger.color.a <= 0.001, true, "old pollution field no longer dominates")
	_expect_equal(old_residue.color.a <= 0.001, true, "old pollution marker no longer dominates")
	_expect_equal(route_band.color.a <= 0.001, true, "old pollution route band no longer dominates")
	_expect_equal(belt_label.visible, false, "old pollution belt label hidden")
	_expect_equal(route_label.visible, false, "old route label hidden")
	_expect_equal(_get_marker_alpha(residue_interactable) <= 0.045, true, "residue interactable marker is muted")
	_expect_equal(_get_marker_alpha(filter_build_site) <= 0.045, true, "filter build site marker is muted")
	map.free()


func _check_pollution_boundary_runtime_anchors_are_tagged() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node("DemoPollutionBoundaryVisualLayer") as DemoPollutionBoundaryVisualLayer
	layer.apply_visuals()

	_expect_anchor_role(map, "Interactables/PollutionFilterBuildSite", DemoPollutionBoundaryVisualLayer.ROLE_FILTER_SITE)
	_expect_anchor_role(map, "Interactables/PollutionFilter", DemoPollutionBoundaryVisualLayer.ROLE_FILTER_SITE)
	_expect_anchor_role(map, "Interactables/PollutionResidue", DemoPollutionBoundaryVisualLayer.ROLE_RESIDUE)
	_expect_anchor_role(map, "Interactables/RuinGate", DemoPollutionBoundaryVisualLayer.ROLE_PRESSURE_GATE)
	map.free()


func _expect_anchor_role(map: VerticalSliceMap, path: String, expected_role: String) -> void:
	var node := map.get_node_or_null(path)
	_expect_equal(node != null, true, "%s exists for pollution boundary visual" % path)
	if node == null:
		return
	_expect_equal(
		String(node.get_meta("pollution_boundary_visual_role", "")),
		expected_role,
		"%s carries pollution boundary visual role" % path
	)
	_expect_equal(
		String(node.get_meta("pollution_boundary_visual_scope", "")),
		"treatment_boundary",
		"%s carries pollution boundary visual scope" % path
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
