extends SceneTree

var failures: Array[String] = []
var data_registry := DataRegistry.new()


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		_run_checks()

	if failures.is_empty():
		print("Industrial tech spine checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_hud_summary()
	_check_device_panel_line()
	_check_processing_prompt_and_log()
	_check_outfitting_station_prompt()
	_check_processing_result_feedback()


func _check_hud_summary() -> void:
	var world := _create_spine_world("quest.make_filter_module")
	var character := _create_spine_character()
	character.inventory.add_item("item.basic_parts", 2)
	character.inventory.add_item("item.filter_media", 1)

	var hud_text := HudStatusPresenter.new().format_vitals_text(data_registry, world, character)
	_expect_text_contains(hud_text, "工艺主干", "HUD shows industrial tech spine line")
	_expect_text_contains(hud_text, "基础零件 + 过滤介质 -> 基础过滤模块", "HUD points materials to filter module")
	_expect_text_contains(hud_text, "出发整备台", "HUD points module to outfitting station")


func _check_device_panel_line() -> void:
	var world := _create_spine_world("quest.prepare_demo_stabilization_buffer")
	var character := _create_spine_character()
	character.inventory.add_item("item.polluted_residue", 2)

	var filter := _create_processing_interactable("building.pollution_filter", "recipe.cleanse_residue")
	var panel := HudDevicePanelPresenter.new().format_device_panel_texts(
		data_registry,
		ProcessingSystem.new(data_registry),
		filter,
		character,
		world
	)
	var status := String(panel.get("status", ""))
	_expect_text_contains(status, "工艺主干", "device panel shows industrial tech spine")
	_expect_text_contains(status, "药剂支撑核心站排压", "device panel explains vial pressure value")
	_expect_text_contains(status, "污染浆液要留给核心稳压缓冲包", "device panel keeps slurry for core buffer")
	filter.free()


func _check_processing_prompt_and_log() -> void:
	var world := _create_spine_world("quest.prepare_demo_stabilization_buffer")
	var character := _create_spine_character()
	character.inventory.add_item("item.polluted_residue", 2)
	var filter := _create_processing_interactable("building.pollution_filter", "recipe.cleanse_residue")
	var formatter := InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)

	var prompt := formatter.format_processing_prompt(filter, character, world)
	_expect_text_contains(prompt, "主干", "processing prompt shows industrial tech spine")
	_expect_text_contains(prompt, "核心稳压缓冲包", "processing prompt explains buffer destination")

	var processing_log := formatter.format_processing_log("recipe.cleanse_residue", character, world)
	_expect_text_contains(processing_log, "工艺", "recipe cycle log shows industrial tech spine")
	_expect_text_contains(processing_log, "污染浆液要留给核心稳压缓冲包", "recipe cycle log explains slurry destination")
	filter.free()


func _check_outfitting_station_prompt() -> void:
	var world := _create_spine_world("quest.prepare_demo_stabilization_buffer")
	var character := _create_spine_character()
	character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	FieldOutfittingRuntime.mark_logistics_maintenance_confirmed(world)

	var formatter := InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)
	var prompt := formatter.format_outfitting_station_prompt(character, world)
	_expect_text_contains(prompt, "主干", "outfitting prompt shows industrial tech spine")
	_expect_text_contains(
		prompt,
		"维护状态服务下一趟污染 / 遗迹 / 核心站承压",
		"outfitting prompt ties maintenance to next sortie pressure"
	)


func _check_processing_result_feedback() -> void:
	var world := _create_spine_world("quest.prepare_demo_stabilization_buffer")
	var character := _create_spine_character()
	character.inventory.add_item("item.polluted_residue", 2)
	var processing := ProcessingSystem.new(data_registry)
	var started := processing.process_recipe("recipe.cleanse_residue", character, world)
	_expect_equal(bool(started.get("success", false)), true, "pollution filter starts cleanse recipe")

	var completed_results := processing.advance_processing(99.0, character, world)
	_expect_equal(completed_results.size(), 1, "pollution filter completion result exists")
	var completion_log := HudLogPresenter.new(data_registry).format_result_log(completed_results[0])
	_expect_text_contains(completion_log, "工艺", "processing completion log shows industrial tech spine")
	_expect_text_contains(completion_log, "核心稳压缓冲包", "processing completion log explains buffer destination")


func _create_spine_world(active_quest_id: String) -> WorldState:
	var world := WorldState.create_default()
	world.current_region_id = "region.outpost_platform"
	world.quest_state.active_quest_ids = [active_quest_id]
	world.quest_state.unlock_effect("recipe.cleanse_residue")
	world.quest_state.unlock_effect("recipe.core_stabilization_buffer")
	world.quest_state.unlock_effect("recipe.make_filter_media")
	world.quest_state.unlock_effect("recipe.basic_filter_module")
	world.add_base_structure("structure.basic_reactor", "building.basic_reactor", "region.outpost_platform")
	world.add_base_structure("structure.pollution_filter", "building.pollution_filter", "region.pollution_edge")
	world.add_base_structure("structure.field_outfitting_station", "building.field_outfitting_station", "region.outpost_platform")
	return world


func _create_spine_character() -> CharacterState:
	var character := CharacterState.create_default()
	character.inventory.add_fluid("fluid.basic_solvent", 2.0)
	return character


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


func _expect_text_contains(text: String, expected: String, context: String) -> void:
	if text.find(expected) >= 0:
		return
	failures.append("%s: expected text to contain '%s', got '%s'" % [context, expected, text])


func _cleanup() -> void:
	data_registry.free()
