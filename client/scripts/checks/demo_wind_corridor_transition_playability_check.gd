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
		print("Demo wind corridor transition playability checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_formatter_tracks_wind_corridor_transition()
	_check_scene_layer_marks_wind_corridor_transition()
	_check_hud_and_map_wind_readouts()
	_check_object_prompts_show_wind_transition()
	_check_runtime_results_keep_wind_followup()


func _check_formatter_tracks_wind_corridor_transition() -> void:
	var region_ids := DemoWindCorridorTransitionPlayabilityFormatter.get_region_ids()
	_expect_equal(region_ids.size(), 1, "wind formatter covers one focused transition region")
	_expect_array_has(region_ids, "region.phase_well_loom", "wind formatter covers phase well loom")

	var wind_hint := DemoWindCorridorTransitionPlayabilityFormatter.format_map_route_hint("region.phase_well_loom")
	_expect_text_contains(wind_hint, "风蚀过渡：风蚀管廊过渡路径", "wind hint names transition path")
	_expect_text_contains(wind_hint, "张力绕轮", "wind hint names boundary")
	_expect_text_contains(wind_hint, "锁相框架", "wind hint points to next region")

	var frame_entry := DemoWindCorridorTransitionPlayabilityFormatter.format_static_object_route_line(
		"map_object.phase_well_frame_route_blocker",
		"region.phase_well_frame"
	)
	_expect_text_contains(frame_entry, "风蚀管廊过渡路径", "frame entry line keeps wind transition source")
	_expect_text_contains(frame_entry, "锁相入口承接", "frame entry line names handoff role")


func _check_scene_layer_marks_wind_corridor_transition() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node("WindCorridorTransitionPlayabilityLayer") as Node2D
	var wind_entry := map.get_node("WindCorridorTransitionPlayabilityLayer/WindEntryLane") as ColorRect
	var wind_boundary := map.get_node("WindCorridorTransitionPlayabilityLayer/WindTensionBoundary") as ColorRect
	var wind_resource := map.get_node("WindCorridorTransitionPlayabilityLayer/WindWeftResourcePocket") as ColorRect
	var wind_facility := map.get_node("WindCorridorTransitionPlayabilityLayer/WindLoomFacilityPocket") as ColorRect
	var frame_entry := map.get_node("WindCorridorTransitionPlayabilityLayer/FrameEntryBoundary") as ColorRect

	_expect_equal(layer != null, true, "wind scene layer exists")
	_expect_equal(
		wind_entry.offset_left >= VerticalSliceMap.PHASE_WELL_LOOM_REGION_X
			and wind_facility.offset_right < VerticalSliceMap.PHASE_WELL_FRAME_REGION_X,
		true,
		"wind route marks stay inside phase well loom"
	)
	_expect_equal(
		wind_boundary.offset_left >= VerticalSliceMap.PHASE_WELL_LOOM_REGION_X
			and wind_resource.offset_right < VerticalSliceMap.PHASE_WELL_FRAME_REGION_X,
		true,
		"wind boundary and resource stay inside corridor"
	)
	_expect_equal(
		frame_entry.offset_left >= VerticalSliceMap.PHASE_WELL_FRAME_REGION_X
			and frame_entry.offset_right < VerticalSliceMap.PHASE_WELL_TETHER_REGION_X,
		true,
		"frame entry handoff stays inside phase well frame"
	)
	_expect_equal(wind_entry.color.a > 0.3, true, "wind entry lane has visible alpha")
	_expect_equal(frame_entry.color.a > 0.3, true, "frame entry boundary has visible alpha")
	map.free()


func _check_hud_and_map_wind_readouts() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	world.current_region_id = "region.phase_well_loom"
	character.current_region_id = "region.phase_well_loom"
	world.ensure_map_object(
		"map_object_instance.wind_weft_prompt",
		"map_object.weft_bundle_cluster",
		"region.phase_well_loom"
	)
	world.ensure_map_object(
		"map_object_instance.wind_spool_prompt",
		"map_object.phase_well_loom_tension_spool",
		"region.phase_well_loom"
	)

	var vitals_text := HudStatusPresenter.new().format_vitals_text(data_registry, world, character)
	_expect_text_contains(vitals_text, "现场玩法：风蚀管廊现场玩法", "HUD keeps existing wind gameplay line")
	_expect_text_contains(vitals_text, "风蚀过渡：风蚀管廊过渡路径", "HUD adds wind transition line")
	_expect_text_contains(vitals_text, "过渡落点：危险", "HUD names wind placements")

	var map_hint := HudMapPresenter.new().format_demo_route_hint(world, "", character)
	_expect_text_contains(map_hint, "风蚀过渡：风蚀管廊过渡路径", "map route hint includes wind transition")
	_expect_text_contains(map_hint, "张力绕轮", "map route hint names wind boundary")
	_expect_text_contains(map_hint, "锁相框架", "map route hint names next region")


func _check_object_prompts_show_wind_transition() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var formatter := InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)
	world.current_region_id = "region.phase_well_loom"
	character.current_region_id = "region.phase_well_loom"

	var weft := _create_interactable(
		"map_object_instance.wind_weft_prompt",
		"map_object.weft_bundle_cluster",
		"gather"
	)
	var weft_prompt := formatter.format_general_interaction_prompt(weft, character, world)
	_expect_text_contains(weft_prompt, "风蚀过渡：风蚀管廊过渡路径", "general prompt shows wind transition")
	_expect_text_contains(weft_prompt, "对象落点：资源", "general prompt names wind resource role")
	weft.free()

	var spool := _create_interactable(
		"map_object_instance.wind_spool_prompt",
		"map_object.phase_well_loom_tension_spool",
		"inspect"
	)
	var spool_prompt := formatter.format_field_reading_prompt(spool, world)
	_expect_text_contains(spool_prompt, "风蚀过渡：风蚀管廊过渡路径", "field reading prompt shows wind transition")
	_expect_text_contains(spool_prompt, "对象落点：入口边界", "field reading prompt names wind boundary role")
	spool.free()

	var loom_prompt := formatter.format_phase_well_loom_prompt(world, character)
	_expect_text_contains(loom_prompt, "风蚀过渡：风蚀管廊过渡路径", "terminal prompt shows wind transition")
	_expect_text_contains(loom_prompt, "对象落点：设施", "terminal prompt names wind facility role")

	world.current_region_id = "region.phase_well_frame"
	character.current_region_id = "region.phase_well_frame"
	var frame_route := _create_interactable(
		"map_object_instance.wind_frame_entry_prompt",
		"map_object.phase_well_frame_route_blocker",
		"clear"
	)
	var frame_prompt := formatter.format_clear_prompt(frame_route, character, world)
	_expect_text_contains(frame_prompt, "风蚀过渡：风蚀管廊过渡路径", "frame clear prompt keeps wind handoff")
	_expect_text_contains(frame_prompt, "对象落点：锁相入口承接", "frame clear prompt names handoff role")
	frame_route.free()


func _check_runtime_results_keep_wind_followup() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var gather_system := GatherSystem.new(data_registry)
	world.current_region_id = "region.phase_well_loom"
	character.current_region_id = "region.phase_well_loom"

	var spool_result := gather_system.interact_with_object(
		"map_object_instance.wind_spool_result",
		"map_object.phase_well_loom_tension_spool",
		"inspect",
		character,
		world
	)
	_expect_equal(bool(spool_result.get("success", false)), true, "wind tension spool inspect succeeds")
	_expect_text_contains(String(spool_result.get("message", "")), "风蚀过渡：入口边界已处理", "spool result keeps wind followup")
	_expect_text_contains(String(spool_result.get("message", "")), "锁相框架", "spool result points to next region")

	var weft_result := gather_system.interact_with_object(
		"map_object_instance.wind_weft_result",
		"map_object.weft_bundle_cluster",
		"gather",
		character,
		world
	)
	_expect_equal(bool(weft_result.get("success", false)), true, "weft gather succeeds")
	_expect_text_contains(String(weft_result.get("message", "")), "风蚀过渡：资源已处理", "weft result keeps wind followup")
	_expect_text_contains(String(weft_result.get("message", "")), "回基地稳定纬束残团", "weft result points back to base")

	world.current_region_id = "region.phase_well_frame"
	character.current_region_id = "region.phase_well_frame"
	var frame_clear := gather_system.interact_with_object(
		"map_object_instance.wind_frame_entry_result",
		"map_object.phase_well_frame_route_blocker",
		"clear",
		character,
		world
	)
	_expect_equal(bool(frame_clear.get("success", false)), true, "frame route clear succeeds")
	_expect_text_contains(String(frame_clear.get("message", "")), "风蚀过渡：锁相入口承接已处理", "frame clear keeps wind handoff")


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
	failures.append("%s: expected array to contain %s, got %s" % [context, expected, str(values)])


func _expect_text_contains(text: String, expected: String, context: String) -> void:
	if text.find(expected) >= 0:
		return
	failures.append("%s: expected text to contain '%s', got '%s'" % [context, expected, text])


func _cleanup() -> void:
	data_registry.free()
