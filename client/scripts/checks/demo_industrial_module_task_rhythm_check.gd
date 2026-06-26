extends SceneTree

var failures: Array[String] = []
var data_registry := DataRegistry.new()


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		_run_checks()

	if failures.is_empty():
		print("Demo industrial module task rhythm checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_formatter_scope()
	_check_hud_and_build_prompt_task_rhythm()
	_check_device_panel_and_processing_prompt_task_rhythm()
	_check_processing_and_build_result_logs()
	_check_outpost_and_outfitting_prompts()


func _check_formatter_scope() -> void:
	for building_id in [
		"building.outpost_core",
		"building.basic_reactor",
		"building.pollution_filter",
		"building.basic_storage",
		"building.field_outfitting_station"
	]:
		_expect_array_has(
			DemoIndustrialModuleTaskRhythmFormatter.get_core_module_ids(),
			building_id,
			"formatter covers %s" % building_id
		)
	for stage_id in [
		"stage.storage_bootstrap",
		"stage.outfitting_bootstrap",
		"stage.module_materials",
		"stage.module_assembly",
		"stage.module_outfitting",
		"stage.pollution_filter_build",
		"stage.pollution_processing",
		"stage.core_buffer_prep",
		"stage.sortie_ready"
	]:
		_expect_array_has(
			DemoIndustrialModuleTaskRhythmFormatter.get_required_stage_ids(),
			stage_id,
			"formatter covers %s" % stage_id
		)


func _check_hud_and_build_prompt_task_rhythm() -> void:
	var world := _create_module_world()
	var character := CharacterState.create_default()
	var hud_text := HudStatusPresenter.new().format_vitals_text(data_registry, world, character)
	_expect_text_contains(hud_text, "任务节奏", "HUD shows task rhythm in active recipe summary")
	_expect_text_contains(hud_text, "滤材下一步进入基础过滤模块", "HUD links recipe output to module task")

	var module_world := _create_module_world()
	module_world.quest_state.active_quest_ids = []
	module_world.add_base_structure("structure.basic_storage", "building.basic_storage", "region.outpost_platform")
	var module_summary := DemoIndustrialModuleTaskRhythmFormatter.format_hud_summary(
		module_world,
		character
	)
	_expect_text_contains("\n".join(module_summary), "模块职责", "formatter shows module responsibility")
	_expect_text_contains(
		"\n".join(module_summary),
		"出发整备台还未接入模块装配",
		"formatter identifies missing outfitting station"
	)

	var formatter := _create_formatter()
	var storage_site := _create_build_interactable(
		"map_object_instance.basic_storage_site",
		"building.basic_storage"
	)
	var storage_prompt := formatter.format_build_prompt(storage_site, character, world)
	_expect_text_contains(storage_prompt, "任务节奏", "storage build prompt shows task rhythm")
	_expect_text_contains(storage_prompt, "基础储存箱接入前哨核心", "storage build prompt explains supply role")
	storage_site.free()


func _check_device_panel_and_processing_prompt_task_rhythm() -> void:
	var world := _create_module_world()
	_mark_core_modules_built(world)
	world.quest_state.activate_quest("quest.prepare_demo_stabilization_buffer")
	world.quest_state.unlock_effect("recipe.cleanse_residue")
	world.quest_state.unlock_effect("recipe.core_stabilization_buffer")
	var character := CharacterState.create_default()
	character.equipment["suit_module"] = "equipment.filter_module_t1"
	character.inventory.add_item("item.repair_gel", 1)
	character.inventory.add_item("item.resistance_vial_t1", 1)
	character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	var reactor := _create_processing_interactable(
		"building.basic_reactor",
		"recipe.core_stabilization_buffer"
	)
	var panel := HudDevicePanelPresenter.new().format_device_panel_texts(
		data_registry,
		ProcessingSystem.new(data_registry),
		reactor,
		character,
		world
	)
	var status := String(panel.get("status", ""))
	_expect_text_contains(status, "任务节奏", "device panel shows task rhythm")
	_expect_text_contains(status, "基础反应器把外勤材料转成", "device panel explains reactor task")

	var prompt := _create_formatter().format_processing_prompt(reactor, character, world)
	_expect_text_contains(prompt, "任务节奏", "processing prompt shows task rhythm")
	_expect_text_contains(prompt, "核心稳压缓冲包完成后回核心稳定站", "processing prompt links result to core station")
	reactor.free()


func _check_processing_and_build_result_logs() -> void:
	var world := _create_module_world()
	_mark_core_modules_built(world)
	world.quest_state.activate_quest("quest.prepare_demo_stabilization_buffer")
	world.quest_state.unlock_effect("recipe.core_stabilization_buffer")
	var character := CharacterState.create_default()
	character.inventory.add_item("item.repair_gel", 1)
	character.inventory.add_item("item.resistance_vial_t1", 1)
	character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	var processing := ProcessingSystem.new(data_registry)

	var start_result := processing.process_recipe("recipe.core_stabilization_buffer", character, world)
	_expect_equal(bool(start_result.get("success", false)), true, "core buffer processing starts")
	var start_log := HudLogPresenter.new(data_registry).format_result_log(start_result)
	_expect_text_contains(start_log, "任务节奏", "processing start log shows task rhythm")
	_expect_text_contains(start_log, "核心稳压缓冲包", "processing start log explains core buffer task")

	var build_world := _create_module_world()
	var build_character := CharacterState.create_default()
	var build_system := BuildSystem.new(data_registry)
	var build_result := build_system.build_structure(
		"map_object_instance.basic_storage_site",
		"building.basic_storage",
		build_character,
		build_world
	)
	_expect_equal(bool(build_result.get("success", false)), true, "storage build succeeds")
	var build_log := HudLogPresenter.new(data_registry).format_result_log(build_result)
	_expect_text_contains(build_log, "任务节奏", "build result log shows task rhythm")
	_expect_text_contains(build_log, "储存箱已成为补给落点", "build result log explains storage result")


func _check_outpost_and_outfitting_prompts() -> void:
	var formatter := _create_formatter()
	var world := _create_module_world()
	_mark_core_modules_built(world)
	var character := CharacterState.create_default()
	character.inventory.add_equipment("equipment.filter_module_t1", 1)

	var outpost_prompt := formatter.format_outpost_core_prompt(world, character)
	_expect_text_contains(outpost_prompt, "任务节奏", "outpost core prompt shows task rhythm")
	_expect_text_contains(outpost_prompt, "前哨核心是补生命 / 防护 / 补给", "outpost core names role")

	var outfitting_prompt := formatter.format_outfitting_station_prompt(character, world)
	_expect_text_contains(outfitting_prompt, "任务节奏", "outfitting prompt shows task rhythm")
	_expect_text_contains(outfitting_prompt, "把它装入防护服", "outfitting prompt explains module action")


func _create_module_world() -> WorldState:
	var world := WorldState.create_default()
	world.current_region_id = "region.outpost_platform"
	world.quest_state.complete_quest("quest.restore_outpost")
	world.quest_state.activate_quest("quest.make_filter_module")
	return world


func _mark_core_modules_built(world: WorldState) -> void:
	world.add_base_structure("structure.basic_storage", "building.basic_storage", "region.outpost_platform")
	world.add_base_structure(
		"structure.field_outfitting_station",
		"building.field_outfitting_station",
		"region.outpost_platform"
	)
	world.add_base_structure("structure.pollution_filter", "building.pollution_filter", "region.pollution_edge")


func _create_formatter() -> InteractionPromptFormatter:
	return InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)


func _create_build_interactable(instance_id: String, building_id: String) -> PrototypeInteractable:
	var interactable := PrototypeInteractable.new()
	interactable.instance_id = instance_id
	interactable.definition_id = building_id
	interactable.interaction_type = "build_structure"
	return interactable


func _create_processing_interactable(building_id: String, recipe_id: String) -> PrototypeInteractable:
	var interactable := PrototypeInteractable.new()
	interactable.definition_id = building_id
	interactable.interaction_type = "process_recipe"
	interactable.recipe_id = recipe_id
	interactable.set_recipe_cycle([recipe_id])
	return interactable


func _expect_equal(actual, expected, context: String) -> void:
	if actual == expected:
		return
	failures.append("%s: expected %s, got %s" % [context, str(expected), str(actual)])


func _expect_array_has(values: Array[String], expected: String, context: String) -> void:
	if values.has(expected):
		return
	failures.append("%s: expected array to contain '%s', got %s" % [context, expected, str(values)])


func _expect_text_contains(text: String, expected: String, context: String) -> void:
	if text.find(expected) >= 0:
		return
	failures.append("%s: expected text to contain '%s', got '%s'" % [context, expected, text])


func _cleanup() -> void:
	data_registry.free()
