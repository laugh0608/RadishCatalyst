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
	_expect_equal(layer.has_boundary_shape("boundary.filter_build_site"), true, "filter construction site visual exists")
	_expect_equal(layer.has_boundary_shape("boundary.pressure_gate"), true, "pressure gate visual exists")
	_expect_equal(layer.has_boundary_shape("boundary.hazard_boundary"), true, "danger boundary visual exists")
	_expect_equal(layer.has_boundary_shape("residue.entry_patch"), true, "entry residue patch visual exists")
	_expect_equal(layer.has_flow_shape("flow.residue_to_filter"), true, "residue to filter route exists")
	_expect_equal(layer.has_flow_shape("flow.filter_to_base_return"), true, "filter to base logistics route exists")
	map.free()


func _check_pollution_boundary_focus_visibility() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node("DemoPollutionBoundaryVisualLayer") as DemoPollutionBoundaryVisualLayer
	layer.apply_visuals()

	layer.refresh_focus_visibility(Vector2(-250, -48))
	_expect_equal(layer.visible, false, "pollution boundary visual layer stays hidden at startup objective")
	layer.refresh_focus_visibility(Vector2(258, 34))
	_expect_equal(layer.visible, true, "pollution boundary visual layer appears inside pollution treatment boundary")
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
	var residue_interactable := map.get_node("Interactables/PollutionResidue") as PrototypeInteractable
	var filter_build_site := map.get_node("Interactables/PollutionFilterBuildSite") as PrototypeInteractable
	_expect_equal(old_danger.color.a <= 0.11, true, "old pollution field no longer dominates")
	_expect_equal(old_residue.color.a <= 0.05, true, "old pollution marker no longer dominates")
	_expect_equal(belt_label.visible, false, "old pollution belt label hidden")
	_expect_equal(route_label.visible, false, "old route label hidden")
	_expect_equal(_get_marker_alpha(residue_interactable) <= 0.08, true, "residue interactable marker is muted")
	_expect_equal(_get_marker_alpha(filter_build_site) <= 0.08, true, "filter build site marker is muted")
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
