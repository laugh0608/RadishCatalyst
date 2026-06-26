extends SceneTree

const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")

var failures: Array[String] = []
var data_registry := DataRegistry.new()


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		_run_checks()

	if failures.is_empty():
		print("Demo map surface decomposition checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_region_resolution()
	_check_gate_fallbacks()
	_check_map_gate_wrapper()
	_check_return_positions_and_object_regions()


func _check_region_resolution() -> void:
	var cases := [
		{"position": Vector2(-21, 0), "region_id": "region.outpost_platform"},
		{"position": Vector2(-20, 0), "region_id": "region.crystal_vein_field"},
		{"position": Vector2(250, -80), "region_id": "region.crystal_vein_field"},
		{"position": Vector2(250, 0), "region_id": "region.pollution_edge"},
		{"position": Vector2(390, 0), "region_id": "region.ruin_outer_ring"},
		{"position": Vector2(700, 0), "region_id": "region.deep_ruin_threshold"},
		{"position": Vector2(1460, 0), "region_id": "region.inner_phase_well"},
		{"position": Vector2(1760, 0), "region_id": "region.phase_well_sink"},
		{"position": Vector2(2040, 0), "region_id": "region.phase_well_chamber"},
		{"position": Vector2(2320, 0), "region_id": "region.phase_well_loom"},
		{"position": Vector2(2600, 0), "region_id": "region.phase_well_frame"},
		{"position": Vector2(2880, 0), "region_id": "region.phase_well_tether"},
		{"position": Vector2(3640, 0), "region_id": "region.demo_stabilization_core"}
	]
	for case_data in cases:
		_expect_equal(
			VerticalSliceMapSurface.get_region_id_for_position(case_data["position"]),
			String(case_data["region_id"]),
			"surface helper resolves %s" % String(case_data["region_id"])
		)


func _check_gate_fallbacks() -> void:
	var world := WorldState.create_default()
	_expect_gate(world, Vector2(0, 0), -35.0, "晶体矿脉区", "crystal gate fallback")

	world.unlock_region("region.crystal_vein_field")
	_expect_no_gate(world, Vector2(250, -80), "pollution north branch stays open before deep pollution route")
	_expect_gate(world, Vector2(250, 0), 235.0, "污染边界", "pollution gate fallback")

	world.unlock_region("region.pollution_edge")
	_expect_gate(world, Vector2(390, 0), 355.0, "遗迹外圈", "ruin gate fallback")

	world.unlock_region("region.ruin_outer_ring")
	_expect_gate(world, Vector2(550, 0), 514.0, "抖动雾幕", "outer ring barrier fallback")

	world.quest_state.complete_quest("quest.stabilize_outer_ring_barrier")
	_expect_gate(world, Vector2(800, 0), 676.0, "裂相脊入口", "deep ruin gate fallback")

	world.quest_state.complete_quest("quest.unlock_deep_ruin_entrance")
	_expect_gate(world, Vector2(1500, 0), 1432.0, "回声台地", "inner phase well gate fallback")


func _check_map_gate_wrapper() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map._ensure_scene_nodes()
	var world := WorldState.create_default()
	map.player.position = Vector2(0, -12)

	var message := map.apply_region_gate_bounds(world)
	_expect_text_contains(message, "晶体矿脉区", "map keeps gate blocked signal text")
	_expect_vector2(map.player.position, Vector2(-35, -12), "map applies helper return position")
	map.free()


func _check_return_positions_and_object_regions() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(data_registry)

	_expect_vector2(
		map._get_phase_relay_pad_return_position(),
		Vector2(-180, 72),
		"relay pad return position uses scene interactable"
	)
	_expect_vector2(
		map._get_phase_return_anchor_return_position("map_object_instance.phase_return_anchor"),
		Vector2(854, 126),
		"deep anchor return position uses scene interactable"
	)
	_expect_vector2(
		map._get_phase_return_anchor_return_position("map_object_instance.phase_return_anchor_chamber"),
		Vector2(2068, 126),
		"chamber anchor return position uses scene interactable"
	)
	_expect_vector2(
		map._get_phase_return_anchor_return_position("map_object_instance.phase_return_anchor_tether"),
		Vector2(3238, 162),
		"tether anchor return position uses scene interactable"
	)
	_expect_vector2(
		map._get_phase_return_anchor_return_position("map_object_instance.missing_anchor"),
		Vector2(852, 92),
		"missing anchor keeps fallback return position"
	)

	_expect_equal(
		map._get_interactable_region_id("map_object_instance.phase_relay_pad", ""),
		"region.outpost_platform",
		"relay pad object region remains outpost"
	)
	_expect_equal(
		map._get_interactable_region_id("map_object_instance.phase_return_anchor", ""),
		"region.deep_ruin_threshold",
		"deep anchor object region remains deep threshold"
	)
	_expect_equal(
		map._get_interactable_region_id("map_object_instance.phase_return_anchor_chamber", ""),
		"region.phase_well_chamber",
		"chamber anchor object region remains chamber"
	)
	_expect_equal(
		map._get_interactable_region_id("map_object_instance.phase_return_anchor_tether", ""),
		"region.phase_well_tether",
		"tether anchor object region remains tether"
	)
	_expect_equal(
		map._get_interactable_region_id("map_object_instance.missing_anchor", "region.deep_ruin_threshold"),
		"region.deep_ruin_threshold",
		"missing object keeps fallback region"
	)
	map.free()


func _expect_gate(
	world_state: WorldState,
	map_position: Vector2,
	expected_return_x: float,
	expected_message: String,
	context: String
) -> void:
	var gate_block := VerticalSliceMapSurface.resolve_region_gate_block(world_state, map_position)
	_expect_equal(gate_block.is_empty(), false, "%s should block" % context)
	if gate_block.is_empty():
		return
	var return_position: Vector2 = gate_block["return_position"]
	_expect_equal(is_equal_approx(return_position.x, expected_return_x), true, "%s return x" % context)
	_expect_equal(is_equal_approx(return_position.y, map_position.y), true, "%s preserves y" % context)
	_expect_text_contains(String(gate_block.get("message", "")), expected_message, "%s message" % context)


func _expect_no_gate(world_state: WorldState, map_position: Vector2, context: String) -> void:
	var gate_block := VerticalSliceMapSurface.resolve_region_gate_block(world_state, map_position)
	_expect_equal(gate_block.is_empty(), true, context)


func _expect_vector2(actual: Vector2, expected: Vector2, context: String) -> void:
	if actual.is_equal_approx(expected):
		return
	failures.append("%s: expected %s, got %s" % [context, str(expected), str(actual)])


func _expect_equal(actual, expected, context: String) -> void:
	if actual == expected:
		return
	failures.append("%s: expected %s, got %s" % [context, str(expected), str(actual)])


func _expect_text_contains(text: String, expected: String, context: String) -> void:
	if text.find(expected) >= 0:
		return
	failures.append("%s: expected text to contain '%s', got '%s'" % [context, expected, text])


func _cleanup() -> void:
	data_registry.free()
