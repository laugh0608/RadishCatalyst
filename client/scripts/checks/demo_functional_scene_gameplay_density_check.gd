extends SceneTree

var failures: Array[String] = []
var data_registry := DataRegistry.new()


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		_run_checks()

	if failures.is_empty():
		print("Demo functional scene gameplay density checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_formatter_tracks_frame_and_tether_density()
	_check_hud_combines_scene_gameplay_and_density()
	_check_interaction_prompt_shows_density_loop()
	_check_runtime_results_advance_density_loop()
	_check_phase_well_runtime_result_keeps_density_followup()


func _check_formatter_tracks_frame_and_tether_density() -> void:
	var region_ids := DemoFunctionalSceneGameplayDensityFormatter.get_region_ids()
	_expect_equal(region_ids.size(), 2, "density formatter covers two focused regions")
	_expect_array_has(region_ids, "region.phase_well_frame", "density formatter covers phase well frame")
	_expect_array_has(region_ids, "region.phase_well_tether", "density formatter covers phase well tether")

	var density_line := DemoFunctionalSceneGameplayDensityFormatter.format_object_density_line(
		"map_object.selvedge_strip_cluster",
		{
			"definition_id": "map_object.selvedge_strip_cluster",
			"is_gathered": false
		},
		"region.phase_well_frame"
	)
	_expect_text_contains(density_line, "玩法密度：锁相框架小循环", "density line names frame loop")
	_expect_text_contains(density_line, "步骤：回收边缕残条", "density line names salvage step")
	_expect_text_contains(density_line, "状态：待处理", "density line names pending state")

	var tether_line := DemoFunctionalSceneGameplayDensityFormatter.format_static_object_density_line(
		"map_object.phase_well_tether",
		"region.phase_well_tether"
	)
	_expect_text_contains(tether_line, "玩法密度：锚定桥小循环", "static density line names tether loop")
	_expect_text_contains(tether_line, "勘验锚定桥断面", "static density line names tether terminal step")


func _check_hud_combines_scene_gameplay_and_density() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	world.current_region_id = "region.phase_well_frame"
	world.quest_state.active_quest_ids = ["quest.collect_selvedge_strip"]
	world.ensure_map_object(
		"map_object_instance.density_frame_route",
		"map_object.phase_well_frame_route_blocker",
		"region.phase_well_frame"
	)["is_cleared"] = true
	world.ensure_map_object(
		"map_object_instance.density_selvedge_a",
		"map_object.selvedge_strip_cluster",
		"region.phase_well_frame"
	)

	var vitals_text := HudStatusPresenter.new().format_vitals_text(data_registry, world, character)
	_expect_text_contains(vitals_text, "现场玩法：锁相框架现场玩法", "HUD keeps existing scene gameplay summary")
	_expect_text_contains(vitals_text, "玩法密度：锁相框架小循环", "HUD adds density summary")
	_expect_text_contains(vitals_text, "步骤进度：1/3", "HUD shows density progress")
	_expect_text_contains(vitals_text, "回收两处边缕残条", "HUD points to next dense gameplay step")


func _check_interaction_prompt_shows_density_loop() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	world.current_region_id = "region.phase_well_frame"
	var formatter := InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)
	var cluster := _create_interactable(
		"map_object_instance.density_selvedge_prompt",
		"map_object.selvedge_strip_cluster",
		"gather"
	)

	var prompt := formatter.format_general_interaction_prompt(cluster, character, world)
	_expect_text_contains(prompt, "玩法密度：锁相框架小循环", "general prompt shows density loop")
	_expect_text_contains(prompt, "步骤：回收边缕残条", "general prompt shows density step")
	cluster.free()


func _check_runtime_results_advance_density_loop() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var gather_system := GatherSystem.new(data_registry)
	world.current_region_id = "region.phase_well_frame"
	character.current_region_id = "region.phase_well_frame"

	var clear_result := gather_system.interact_with_object(
		"map_object_instance.density_frame_route",
		"map_object.phase_well_frame_route_blocker",
		"clear",
		character,
		world
	)
	_expect_equal(bool(clear_result.get("success", false)), true, "density frame route clear succeeds")
	_expect_text_contains(String(clear_result.get("message", "")), "玩法密度：清理锁相侧路已完成", "clear result names completed density step")

	var gather_result := gather_system.interact_with_object(
		"map_object_instance.density_selvedge_a",
		"map_object.selvedge_strip_cluster",
		"gather",
		character,
		world
	)
	_expect_equal(bool(gather_result.get("success", false)), true, "density selvedge gather succeeds")
	_expect_text_contains(String(gather_result.get("message", "")), "玩法密度：回收边缕残条已推进", "gather result names advanced density step")

	var vitals_text := HudStatusPresenter.new().format_vitals_text(data_registry, world, character)
	_expect_text_contains(vitals_text, "步骤进度：1/3", "HUD keeps partial density progress before second salvage")
	_expect_text_contains(vitals_text, "回收两处边缕残条", "HUD still asks for remaining salvage")


func _check_phase_well_runtime_result_keeps_density_followup() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var runtime := PhaseWellFrontierRuntime.new(data_registry)
	world.current_region_id = "region.phase_well_frame"
	character.current_region_id = "region.phase_well_frame"
	world.quest_state.complete_quest("quest.refine_selvedge_strip")
	character.inventory.add_item("item.phase_well_frame_key", 1)

	var result := runtime.inspect_frame(character, world)
	_expect_equal(bool(result.get("success", false)), true, "phase well frame inspect succeeds")
	_expect_text_contains(String(result.get("message", "")), "玩法密度：勘验锁相框架断面已推进", "frame inspect result keeps density followup")
	_expect_text_contains(String(result.get("message", "")), "锚定桥前置收益", "frame inspect keeps terminal gameplay value")


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
