extends SceneTree

const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")

var failures: Array[String] = []


func _init() -> void:
	_run_checks()

	if failures.is_empty():
		print("Demo region industrial value checks passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _run_checks() -> void:
	_check_region_industrial_value_layer_exists()
	_check_region_value_roles_cover_twelve_regions()
	_check_region_value_routes_stay_local()
	_check_region_backgrounds_are_tagged()
	_check_no_thirteenth_region_is_added()


func _check_region_industrial_value_layer_exists() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node_or_null("DemoRegionIndustrialValueLayer") as DemoRegionIndustrialValueLayer
	_expect_equal(layer != null, true, "region industrial value layer exists")
	if layer == null:
		map.free()
		return
	layer.apply_visuals()
	_expect_equal(layer.get_value_node_count(), 12, "region industrial value layer covers twelve existing regions")
	_expect_equal(layer.get_emphasized_region_count(), 6, "region industrial value layer emphasizes core and key handoff regions")
	map.free()


func _check_region_value_roles_cover_twelve_regions() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node("DemoRegionIndustrialValueLayer") as DemoRegionIndustrialValueLayer
	layer.apply_visuals()

	_expect_region_role(layer, "region.outpost_platform", DemoRegionIndustrialValueLayer.ROLE_LOGISTICS)
	_expect_region_role(layer, "region.crystal_vein_field", DemoRegionIndustrialValueLayer.ROLE_RESOURCE)
	_expect_region_role(layer, "region.pollution_edge", DemoRegionIndustrialValueLayer.ROLE_RISK)
	_expect_region_role(layer, "region.ruin_outer_ring", DemoRegionIndustrialValueLayer.ROLE_UNLOCK)
	_expect_region_role(layer, "region.deep_ruin_threshold", DemoRegionIndustrialValueLayer.ROLE_LOGISTICS)
	_expect_region_role(layer, "region.inner_phase_well", DemoRegionIndustrialValueLayer.ROLE_RESOURCE)
	_expect_region_role(layer, "region.phase_well_sink", DemoRegionIndustrialValueLayer.ROLE_RISK)
	_expect_region_role(layer, "region.phase_well_chamber", DemoRegionIndustrialValueLayer.ROLE_RESOURCE)
	_expect_region_role(layer, "region.phase_well_loom", DemoRegionIndustrialValueLayer.ROLE_LOGISTICS)
	_expect_region_role(layer, "region.phase_well_frame", DemoRegionIndustrialValueLayer.ROLE_RISK)
	_expect_region_role(layer, "region.phase_well_tether", DemoRegionIndustrialValueLayer.ROLE_STABILITY)
	_expect_region_role(layer, "region.demo_stabilization_core", DemoRegionIndustrialValueLayer.ROLE_STABILITY)
	map.free()


func _check_region_value_routes_stay_local() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node("DemoRegionIndustrialValueLayer") as DemoRegionIndustrialValueLayer
	layer.apply_visuals()

	_expect_equal(
		layer.is_region_value_route_visible("region.pollution_edge", Vector2(-250.0, -48.0)),
		false,
		"pollution value route stays hidden at base start"
	)
	_expect_equal(
		layer.is_region_value_route_visible("region.pollution_edge", Vector2(112.0, -112.0)),
		false,
		"pollution value route does not cross the crystal field screenshot"
	)
	_expect_equal(
		layer.is_region_value_route_visible("region.pollution_edge", Vector2(298.0, -72.0)),
		true,
		"pollution value route appears inside the treatment boundary"
	)
	_expect_equal(
		layer.is_region_value_route_visible("region.deep_ruin_threshold", Vector2(-250.0, -48.0)),
		false,
		"deep ruin logistics route stays hidden at base start"
	)
	map.free()


func _check_region_backgrounds_are_tagged() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node("DemoRegionIndustrialValueLayer") as DemoRegionIndustrialValueLayer
	layer.apply_visuals()

	_expect_background_role(map, "RegionBase", DemoRegionIndustrialValueLayer.ROLE_LOGISTICS)
	_expect_background_role(map, "RegionCrystal", DemoRegionIndustrialValueLayer.ROLE_RESOURCE)
	_expect_background_role(map, "RegionPollution", DemoRegionIndustrialValueLayer.ROLE_RISK)
	_expect_background_role(map, "RegionRuinOuterRing", DemoRegionIndustrialValueLayer.ROLE_UNLOCK)
	_expect_background_role(map, "RegionPhaseWellTether", DemoRegionIndustrialValueLayer.ROLE_STABILITY)
	_expect_background_role(map, "RegionDemoStabilizationCore", DemoRegionIndustrialValueLayer.ROLE_STABILITY)
	map.free()


func _check_no_thirteenth_region_is_added() -> void:
	_expect_equal(
		PrototypeVisualPriorityProfile.get_region_ids().size(),
		12,
		"region industrial value layer keeps existing twelve-region scope"
	)
	_expect_equal(
		DemoRegionIndustrialValueLayer.REGION_VALUE_PROFILES.size(),
		PrototypeVisualPriorityProfile.get_region_ids().size(),
		"region industrial value profile matches existing region count"
	)


func _expect_region_role(layer: DemoRegionIndustrialValueLayer, region_id: String, expected_role: String) -> void:
	_expect_equal(layer.has_region_value(region_id), true, "%s has industrial value node" % region_id)
	_expect_equal(layer.get_region_value_role(region_id), expected_role, "%s has expected industrial value role" % region_id)


func _expect_background_role(map: VerticalSliceMap, path: String, expected_role: String) -> void:
	var node := map.get_node_or_null(path)
	_expect_equal(node != null, true, "%s exists for industrial value metadata" % path)
	if node == null:
		return
	_expect_equal(
		String(node.get_meta("industrial_value_role", "")),
		expected_role,
		"%s carries industrial value role" % path
	)


func _expect_equal(actual, expected, context: String) -> void:
	if actual == expected:
		return
	failures.append("%s: expected %s, got %s" % [context, str(expected), str(actual)])
