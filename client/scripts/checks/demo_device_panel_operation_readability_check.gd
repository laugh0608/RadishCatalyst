extends SceneTree

var failures: Array[String] = []
var data_registry := DataRegistry.new()


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		_run_checks()

	if failures.is_empty():
		print("Demo device panel operation readability checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_formatter_coverage()
	_check_first_industrial_handoff_operation_lines()
	_check_core_buffer_device_panel_operation_line()
	_check_pollution_filter_prompt_and_log_operation_line()
	_check_outpost_core_and_outfitting_prompts()
	_check_processing_result_log_operation_line()


func _check_formatter_coverage() -> void:
	for building_id in [
		"building.outpost_core",
		"building.basic_reactor",
		"building.pollution_filter",
		"building.field_outfitting_station"
	]:
		_expect_array_has(
			DemoDevicePanelOperationFormatter.get_covered_building_ids(),
			building_id,
			"formatter covers %s" % building_id
		)
	_expect_array_has(
		DemoDevicePanelOperationFormatter.get_primary_recipe_ids(),
		"recipe.basic_filter_module",
		"formatter covers basic filter module handoff recipe"
	)
	_expect_array_has(
		DemoDevicePanelOperationFormatter.get_primary_recipe_ids(),
		"recipe.core_stabilization_buffer",
		"formatter covers core buffer recipe"
	)


func _check_first_industrial_handoff_operation_lines() -> void:
	var processing := ProcessingSystem.new(data_registry)
	var presenter := HudDevicePanelPresenter.new()
	var formatter := _create_formatter()
	var world := _create_first_industrial_handoff_world()
	var character := CharacterState.create_default()
	character.inventory.add_item("item.crystal_ore", 3)
	var reactor := _create_processing_interactable(
		"building.basic_reactor",
		"recipe.process_crystal_ore"
	)

	var ready_panel := presenter.format_device_panel_texts(
		data_registry,
		processing,
		reactor,
		character,
		world
	)
	var ready_status := String(ready_panel.get("status", ""))
	_expect_text_contains(ready_status, "交接口：晶体矿物进基地收料口", "reactor panel names base feed port")
	_expect_text_contains(ready_status, "出料托盘接到储存 / 整备段", "reactor panel links output tray to storage and outfitting")
	var prompt := formatter.format_processing_prompt(reactor, character, world)
	_expect_text_contains(prompt, "交接口：晶体矿物进基地收料口", "reactor prompt names base feed port")

	var start_result := processing.process_recipe("recipe.process_crystal_ore", character, world)
	_expect_equal(bool(start_result.get("success", false)), true, "crystal processing starts for handoff check")
	var progress_panel := presenter.format_device_panel_texts(
		data_registry,
		processing,
		reactor,
		character,
		world
	)
	_expect_text_contains(
		String(progress_panel.get("status", "")),
		"反应仓工作窗已亮",
		"reactor panel shows active processing handoff feedback"
	)
	reactor.free()

	var gel_world := _create_first_industrial_handoff_world()
	var gel_character := CharacterState.create_default()
	var gel_reactor := _create_processing_interactable(
		"building.basic_reactor",
		"recipe.repair_gel"
	)
	var gel_prompt := formatter.format_processing_prompt(gel_reactor, gel_character, gel_world)
	_expect_text_contains(
		gel_prompt,
		"修复凝胶回到储存输出口并接入整备台补给位",
		"repair gel prompt links storage output and outfitting supply"
	)
	gel_reactor.free()

	var outfitting_prompt := formatter.format_outfitting_station_prompt(gel_character, gel_world)
	_expect_text_contains(
		outfitting_prompt,
		"从储存输出口接收模块 / 补给",
		"outfitting prompt links storage output handoff"
	)


func _check_core_buffer_device_panel_operation_line() -> void:
	var processing := ProcessingSystem.new(data_registry)
	var presenter := HudDevicePanelPresenter.new()
	var reactor := _create_processing_interactable(
		"building.basic_reactor",
		"recipe.core_stabilization_buffer"
	)
	var world := _create_core_buffer_world()
	var character := CharacterState.create_default()
	character.inventory.add_item("item.repair_gel", 1)

	var missing_panel := presenter.format_device_panel_texts(
		data_registry,
		processing,
		reactor,
		character,
		world
	)
	var missing_status := String(missing_panel.get("status", ""))
	_expect_text_contains(missing_status, "操作读法：基础反应器把修复凝胶", "core buffer panel shows operation intent")
	_expect_text_contains(missing_status, "缺料读法：缺 抗污染药剂", "core buffer panel shows missing inputs")
	_expect_text_contains(missing_status, "回处理点过滤器处理污染沉积物", "core buffer panel points missing vial to filter")

	character.inventory.add_item("item.resistance_vial_t1", 1)
	character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	character.inventory.add_item("item.basic_parts", 2)
	var ready_panel := presenter.format_device_panel_texts(
		data_registry,
		processing,
		reactor,
		character,
		world
	)
	var ready_status := String(ready_panel.get("status", ""))
	_expect_text_contains(ready_status, "现场状态：可启动", "core buffer panel leads with field state")
	_expect_text_contains(ready_status, "输入输出：", "core buffer panel leads with input and output flow")
	_expect_text_contains(ready_status, "下一步：", "core buffer panel keeps the next action near the top")
	_expect_text_contains(ready_status, "设备状态：可启动", "core buffer panel is ready")
	_expect_text_contains(ready_status, "完成后回核心稳定站", "core buffer panel explains route after processing")
	_expect_text_contains(String(ready_panel.get("operations", "")), "E 启动当前配方", "core buffer panel exposes start operation")
	reactor.free()


func _check_pollution_filter_prompt_and_log_operation_line() -> void:
	var formatter := _create_formatter()
	var filter := _create_processing_interactable("building.pollution_filter", "recipe.cleanse_residue")
	var world := _create_core_buffer_world()
	var character := CharacterState.create_default()
	character.inventory.add_item("item.polluted_residue", 2)
	character.inventory.add_fluid("fluid.basic_solvent", 1.0)

	var prompt := formatter.format_processing_prompt(filter, character, world)
	_expect_text_contains(prompt, "操作读法：污染过滤器把沉积物", "filter prompt shows operation intent")
	_expect_text_contains(prompt, "回基础反应器整备核心稳压缓冲包", "filter prompt points to reactor after processing")

	var log_text := formatter.format_processing_log("recipe.cleanse_residue", character, world)
	_expect_text_contains(log_text, "设备操作：污染过滤器把沉积物", "filter detail log shows operation intent")
	_expect_text_contains(log_text, "污染浆液", "filter detail log keeps byproduct value")
	filter.free()


func _check_outpost_core_and_outfitting_prompts() -> void:
	var formatter := _create_formatter()
	var world := _create_core_buffer_world()
	world.add_base_structure("structure.field_outfitting_station", "building.field_outfitting_station", "region.outpost_platform")
	var character := CharacterState.create_default()

	var outpost_prompt := formatter.format_outpost_core_prompt(world, character)
	_expect_text_contains(outpost_prompt, "设备操作：前哨核心先补生命", "outpost core prompt shows operation line")
	_expect_text_contains(outpost_prompt, "回污染过滤器与基础反应器补齐", "outpost core prompt links missing buffer devices")

	var outfitting_prompt := formatter.format_outfitting_station_prompt(character, world)
	_expect_text_contains(outfitting_prompt, "设备操作：出发整备台读取过滤模块", "outfitting prompt shows operation line")
	_expect_text_contains(outfitting_prompt, "回前哨核心补给再出发", "outfitting prompt links back to outpost core")


func _check_processing_result_log_operation_line() -> void:
	var processing := ProcessingSystem.new(data_registry)
	var world := _create_core_buffer_world()
	var character := CharacterState.create_default()
	character.inventory.add_item("item.repair_gel", 1)
	character.inventory.add_item("item.resistance_vial_t1", 1)
	character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	character.inventory.add_item("item.basic_parts", 2)

	var start_result := processing.process_recipe("recipe.core_stabilization_buffer", character, world)
	_expect_equal(bool(start_result.get("success", false)), true, "core buffer processing starts")
	var start_log := HudLogPresenter.new(data_registry).format_result_log(start_result)
	_expect_text_contains(start_log, "设备：核心缓冲包完成后回核心站", "start result log shows device operation")

	var completed_results := processing.advance_processing(7.0, character, world)
	_expect_equal(completed_results.size(), 1, "core buffer processing completes")
	var completion_log := HudLogPresenter.new(data_registry).format_result_log(completed_results[0])
	_expect_text_contains(completion_log, "设备：核心缓冲包完成后回核心站", "completion log shows device operation")
	_expect_text_contains(completion_log, "入口确认、侧边补给、阶段守卫、回写缓存", "completion log shows route after device operation")


func _create_core_buffer_world() -> WorldState:
	var world := WorldState.create_default()
	world.current_region_id = "region.outpost_platform"
	world.quest_state.active_quest_ids = []
	world.quest_state.complete_quest("quest.restore_outpost")
	world.quest_state.complete_quest("quest.enter_demo_stabilization_core")
	world.quest_state.activate_quest("quest.prepare_demo_stabilization_buffer")
	world.quest_state.unlock_effect("recipe.cleanse_residue")
	world.quest_state.unlock_effect("recipe.core_stabilization_buffer")
	world.add_base_structure("structure.pollution_filter_build_site", "building.pollution_filter", "region.pollution_edge")
	return world


func _create_first_industrial_handoff_world() -> WorldState:
	var world := WorldState.create_default()
	world.current_region_id = "region.outpost_platform"
	world.quest_state.unlocked_effects = [
		"recipe.process_crystal_ore",
		"recipe.repair_gel",
		"recipe.basic_filter_module"
	]
	world.add_base_structure("structure.basic_storage", "building.basic_storage", "region.outpost_platform")
	world.add_base_structure("structure.field_outfitting_station", "building.field_outfitting_station", "region.outpost_platform")
	return world


func _create_formatter() -> InteractionPromptFormatter:
	return InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)


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
