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
		print("Demo functional transition spatial playability checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_formatter_tracks_representative_path()
	_check_scene_layer_marks_representative_path()
	_check_hud_and_map_spatial_readouts()
	_check_object_prompts_show_spatial_playability()
	_check_runtime_results_keep_spatial_followup()


func _check_formatter_tracks_representative_path() -> void:
	var region_ids := DemoFunctionalTransitionSpatialPlayabilityFormatter.get_region_ids()
	_expect_equal(region_ids.size(), 2, "spatial playability formatter covers two regions")
	_expect_array_has(region_ids, "region.ruin_outer_ring", "spatial formatter covers ruin outer ring")
	_expect_array_has(region_ids, "region.deep_ruin_threshold", "spatial formatter covers deep ruin threshold")

	var ruin_hint := DemoFunctionalTransitionSpatialPlayabilityFormatter.format_map_route_hint("region.ruin_outer_ring")
	_expect_text_contains(ruin_hint, "封锁遗迹可达空间", "ruin spatial hint names path")
	_expect_text_contains(ruin_hint, "抖动雾幕", "ruin spatial hint names boundary")
	_expect_text_contains(ruin_hint, "相位守卫", "ruin spatial hint names hazard")

	var ridge_line := DemoFunctionalTransitionSpatialPlayabilityFormatter.format_static_object_spatial_line(
		"map_object.phase_return_anchor",
		"region.deep_ruin_threshold"
	)
	_expect_text_contains(ridge_line, "裂相脊可达空间", "ridge object line names spatial path")
	_expect_text_contains(ridge_line, "返回设施", "ridge object line names return anchor role")


func _check_scene_layer_marks_representative_path() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node("FunctionalTransitionSpatialPlayabilityLayer") as Node2D
	var ruin_entrance := map.get_node("FunctionalTransitionSpatialPlayabilityLayer/RuinEntranceLane") as ColorRect
	var ruin_barrier := map.get_node("FunctionalTransitionSpatialPlayabilityLayer/RuinBarrierBoundary") as ColorRect
	var ruin_hazard := map.get_node("FunctionalTransitionSpatialPlayabilityLayer/RuinHazardReturnPocket") as ColorRect
	var ridge_entrance := map.get_node("FunctionalTransitionSpatialPlayabilityLayer/RidgeEntranceLane") as ColorRect
	var ridge_latch := map.get_node("FunctionalTransitionSpatialPlayabilityLayer/RidgeLatchBoundary") as ColorRect
	var ridge_anchor := map.get_node("FunctionalTransitionSpatialPlayabilityLayer/RidgeReturnAnchorPocket") as ColorRect

	_expect_equal(layer != null, true, "spatial playability scene layer exists")
	_expect_equal(
		ruin_entrance.offset_left <= VerticalSliceMap.RUIN_OUTER_RING_X
			and ruin_barrier.offset_left < VerticalSliceMap.OUTER_RING_BARRIER_X
			and ruin_hazard.offset_right < VerticalSliceMap.DEEP_RUIN_REGION_X,
		true,
		"ruin spatial marks stay inside outer ring route"
	)
	_expect_equal(
		ridge_entrance.offset_left < VerticalSliceMap.DEEP_RUIN_REGION_X
			and ridge_latch.offset_left > VerticalSliceMap.DEEP_RUIN_REGION_X
			and ridge_anchor.offset_right < VerticalSliceMap.INNER_PHASE_WELL_REGION_X,
		true,
		"ridge spatial marks stay inside deep ruin threshold"
	)
	_expect_equal(ruin_entrance.color.a > 0.3, true, "ruin entrance lane has visible alpha")
	_expect_equal(ridge_anchor.color.a > 0.3, true, "ridge return anchor pocket has visible alpha")
	map.free()


func _check_hud_and_map_spatial_readouts() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	world.current_region_id = "region.ruin_outer_ring"
	character.current_region_id = "region.ruin_outer_ring"
	world.ensure_map_object(
		"map_object_instance.spatial_relay_prompt",
		"map_object.relay_shard_cache",
		"region.ruin_outer_ring"
	)

	var vitals_text := HudStatusPresenter.new().format_vitals_text(data_registry, world, character)
	_expect_text_contains(vitals_text, "现场玩法：封锁遗迹现场玩法", "HUD keeps existing gameplay line")
	_expect_text_contains(vitals_text, "可达空间：封锁遗迹可达空间", "HUD adds spatial playability line")
	_expect_text_contains(vitals_text, "场地落点：危险", "HUD names spatial placements")

	var map_hint := HudMapPresenter.new().format_demo_route_hint(world, "", character)
	_expect_text_contains(map_hint, "可达空间：封锁遗迹可达空间", "map route hint includes spatial playability")
	_expect_text_contains(map_hint, "入口", "map route hint names entrance")
	_expect_text_contains(map_hint, "边界", "map route hint names boundary")


func _check_object_prompts_show_spatial_playability() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var formatter := InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)
	world.current_region_id = "region.ruin_outer_ring"
	character.current_region_id = "region.ruin_outer_ring"

	var relay := _create_interactable(
		"map_object_instance.spatial_relay_prompt",
		"map_object.relay_shard_cache",
		"gather"
	)
	var relay_prompt := formatter.format_general_interaction_prompt(relay, character, world)
	_expect_text_contains(relay_prompt, "可达空间：封锁遗迹可达空间", "general prompt shows ruin spatial playability")
	_expect_text_contains(relay_prompt, "对象落点：资源", "general prompt names resource role")
	relay.free()

	world.current_region_id = "region.deep_ruin_threshold"
	character.current_region_id = "region.deep_ruin_threshold"
	var anchor_prompt := formatter.format_phase_return_anchor_prompt(world, character)
	_expect_text_contains(anchor_prompt, "可达空间：裂相脊可达空间", "specific prompt shows ridge spatial playability")
	_expect_text_contains(anchor_prompt, "对象落点：返回设施", "specific prompt names return facility role")


func _check_runtime_results_keep_spatial_followup() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var gather_system := GatherSystem.new(data_registry)
	world.current_region_id = "region.ruin_outer_ring"
	character.current_region_id = "region.ruin_outer_ring"

	var relay_result := gather_system.interact_with_object(
		"map_object_instance.spatial_relay_result",
		"map_object.relay_shard_cache",
		"gather",
		character,
		world
	)
	_expect_equal(bool(relay_result.get("success", false)), true, "relay shard gather succeeds")
	_expect_text_contains(String(relay_result.get("message", "")), "可达空间：资源已处理", "relay result keeps spatial followup")
	_expect_text_contains(String(relay_result.get("message", "")), "裂相坐标", "relay result points back to base parsing")

	world.current_region_id = "region.deep_ruin_threshold"
	character.current_region_id = "region.deep_ruin_threshold"
	var filament_result := gather_system.interact_with_object(
		"map_object_instance.spatial_filament_result",
		"map_object.phase_filament_cluster",
		"gather",
		character,
		world
	)
	_expect_equal(bool(filament_result.get("success", false)), true, "phase filament gather succeeds")
	_expect_text_contains(String(filament_result.get("message", "")), "可达空间：资源已处理", "filament result keeps spatial followup")
	_expect_text_contains(String(filament_result.get("message", "")), "回传锚点", "filament result points to deep route value")


func _create_interactable(instance_id: String, definition_id: String, interaction_type: String) -> PrototypeInteractable:
	var interactable := PrototypeInteractable.new()
	interactable.instance_id = instance_id
	interactable.definition_id = definition_id
	interactable.interaction_type = interaction_type
	return interactable


func _expect_equal(actual, expected, context: String) -> void:
	if actual == expected:
		return
	failures.append("%s: expected %s, got %s" % [context, str(expected), str(actual)])


func _expect_array_has(values: Array, expected, context: String) -> void:
	if values.has(expected):
		return
	failures.append("%s: expected array to contain %s, got %s" % [context, str(expected), str(values)])


func _expect_text_contains(text: String, expected: String, context: String) -> void:
	if text.find(expected) >= 0:
		return
	failures.append("%s: expected text to contain '%s', got '%s'" % [context, expected, text])


func _cleanup() -> void:
	data_registry.free()
