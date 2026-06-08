extends RefCounted

var host


func _init(check_host) -> void:
	host = check_host


func run() -> void:
	_check_build_prompts()
	_check_processing_missing_prompt()
	_check_success_logs_share_interaction_reading()


func _check_build_prompts() -> void:
	var build_world := WorldState.create_default()
	var build_character := CharacterState.create_default()
	var formatter := _create_formatter()
	var rough_ground := PrototypeInteractable.new()
	rough_ground.definition_id = "map_object.rough_ground"
	rough_ground.interaction_type = "clear"
	rough_ground.instance_id = "map_object_instance.rough_ground_north"
	var rough_prompt := formatter.format_clear_prompt(rough_ground, build_character, build_world)
	host._expect_text_contains(rough_prompt, "阻挡建造", "rough ground prompt")
	host._expect_text_contains(rough_prompt, "下一步：清理后可铺设基础地基", "rough ground next step prompt")

	var foundation_site := PrototypeInteractable.new()
	foundation_site.definition_id = "building.foundation_t1"
	foundation_site.interaction_type = "build"
	foundation_site.instance_id = "map_object_instance.foundation_site_north"
	foundation_site.prerequisite_instance_id = "map_object_instance.rough_ground_north"
	var blocked_foundation_prompt := formatter.format_build_prompt(foundation_site, build_character, build_world)
	host._expect_text_contains(blocked_foundation_prompt, "地面仍然粗糙", "foundation blocked prompt")
	host._expect_text_contains(blocked_foundation_prompt, "下一步：先清理粗糙地块", "foundation blocked next step prompt")

	build_world.ensure_map_object("map_object_instance.rough_ground_north", "map_object.rough_ground", "region.pollution_edge")
	build_world.set_map_object_flag("map_object_instance.rough_ground_north", "is_cleared", true)
	var missing_foundation_prompt := formatter.format_build_prompt(foundation_site, build_character, build_world)
	host._expect_text_contains(missing_foundation_prompt, "缺少建造材料", "foundation missing material prompt")
	host._expect_text_contains(missing_foundation_prompt, "基础反应器制造基础地基材料", "foundation missing material next step prompt")

	build_character.inventory.add_item("item.foundation_material", 1)
	host._expect_text_contains(
		formatter.format_build_prompt(foundation_site, build_character, build_world),
		"按 E 建造",
		"foundation ready prompt"
	)
	build_world.ensure_map_object(foundation_site.instance_id, foundation_site.definition_id, "region.pollution_edge")
	build_world.set_map_object_flag(foundation_site.instance_id, "is_built", true)
	build_world.add_base_structure("structure.foundation_site_north", "building.foundation_t1", "region.pollution_edge")
	var built_foundation_prompt := formatter.format_build_prompt(foundation_site, build_character, build_world)
	host._expect_text_contains(built_foundation_prompt, "状态：已建成", "foundation built prompt shows completed state")
	host._expect_text_contains(
		built_foundation_prompt,
		"继续清理并铺设另一块基础地基",
		"foundation built prompt points to second foundation"
	)

	var filter_site := PrototypeInteractable.new()
	filter_site.definition_id = "building.pollution_filter"
	filter_site.interaction_type = "build"
	filter_site.instance_id = "map_object_instance.pollution_filter_build_site"
	var blocked_filter_prompt := formatter.format_build_prompt(filter_site, build_character, build_world)
	host._expect_text_contains(blocked_filter_prompt, "基础地基：1 / 2", "pollution filter partial foundation status")
	host._expect_text_contains(blocked_filter_prompt, "还差 1 块基础地基", "pollution filter partial foundation next step prompt")

	build_world.add_base_structure("structure.foundation_site_south", "building.foundation_t1", "region.pollution_edge")
	var missing_filter_prompt := formatter.format_build_prompt(filter_site, build_character, build_world)
	host._expect_text_contains(missing_filter_prompt, "基础地基：2 / 2", "pollution filter complete foundation status")
	host._expect_text_contains(missing_filter_prompt, "缺少建造材料", "pollution filter missing material prompt")
	host._expect_text_contains(missing_filter_prompt, "补过滤介质和基础零件", "pollution filter missing material next step prompt")
	rough_ground.free()
	foundation_site.free()
	filter_site.free()


func _check_processing_missing_prompt() -> void:
	var formatter := _create_formatter()
	var device_world := WorldState.create_default()
	var device_character := CharacterState.create_default()
	var reactor := PrototypeInteractable.new()
	reactor.definition_id = "building.basic_reactor"
	reactor.interaction_type = "process_recipe"
	reactor.recipe_id = "recipe.process_crystal_ore"
	reactor.set_recipe_cycle([
		"recipe.process_crystal_ore",
		"recipe.reactor_calibrator",
		"recipe.analyze_anomaly_sample",
		"recipe.make_filter_media",
		"recipe.basic_filter_module",
		"recipe.foundation_t1",
		"recipe.repair_gel"
	])
	device_world.quest_state.unlock_effect("recipe.process_crystal_ore")
	var missing_prompt := formatter.format_processing_prompt(reactor, device_character, device_world)
	host._expect_text_contains(missing_prompt, "状态：缺少原料", "processing prompt shows missing inputs")
	host._expect_text_contains(missing_prompt, "下一步：", "processing prompt shows missing input next step")
	host._expect_text_missing(missing_prompt, "E 启动加工", "processing prompt hides process action when blocked")
	reactor.free()


func _check_success_logs_share_interaction_reading() -> void:
	var formatter := _create_formatter()
	var log_presenter := HudLogPresenter.new(host.data_registry)
	var processing := ProcessingSystem.new(host.data_registry)
	var device_world := WorldState.create_default()
	var device_character := CharacterState.create_default()
	device_world.quest_state.unlock_effect("recipe.process_crystal_ore")
	device_character.inventory.add_item("item.crystal_ore", 3)

	var started := processing.process_recipe("recipe.process_crystal_ore", device_character, device_world)
	var started_log := log_presenter.format_result_log(started)
	host._expect_text_contains(started_log, "加工已启动：处理晶体矿物", "processing start log title")
	host._expect_text_contains(started_log, "状态：加工中", "processing start log status")
	host._expect_text_contains(
		started_log,
		"去向：基础零件 x4",
		"processing start log destination"
	)
	host._expect_text_contains(started_log, "下一步：Q 设备面板查看进度", "processing start log next step")
	host._expect_equal(
		started_log.find("下一步：") < started_log.find("去向："),
		true,
		"processing start log shows next step before destination"
	)
	host._expect_equal(started_log.count("\n"), 1, "processing start log uses two-row HUD text")
	host._expect_equal(started_log.length() <= 96, true, "processing start log stays short")

	var reactor := PrototypeInteractable.new()
	reactor.definition_id = "building.basic_reactor"
	reactor.interaction_type = "process_recipe"
	reactor.recipe_id = "recipe.process_crystal_ore"
	reactor.set_recipe_cycle(["recipe.process_crystal_ore", "recipe.reactor_calibrator"])
	reactor.select_recipe("recipe.reactor_calibrator")
	var in_progress_prompt := formatter.format_processing_prompt(reactor, device_character, device_world)
	host._expect_text_contains(in_progress_prompt, "配方：处理晶体矿物（1/2）", "processing prompt names active recipe")
	host._expect_text_contains(in_progress_prompt, "状态：加工中：处理晶体矿物", "processing prompt active status")
	host._expect_text_contains(in_progress_prompt, "进度：[", "processing prompt shows progress bar")
	host._expect_text_contains(in_progress_prompt, "下一步：等待设备完成", "processing prompt wait step")

	var completed_results := processing.advance_processing(6.0, device_character, device_world)
	host._expect_equal(completed_results.size(), 1, "processing completion emits one result")
	var completed_log := log_presenter.format_result_log(completed_results[0])
	host._expect_text_contains(completed_log, "加工完成：处理晶体矿物", "processing completion log title")
	host._expect_text_contains(completed_log, "去向：基础零件 x4", "processing completion destination")
	host._expect_text_contains(completed_log, "下一步：基础零件已补足", "processing completion next step")
	host._expect_equal(completed_log.count("\n"), 1, "processing completion log uses two-row HUD text")
	host._expect_equal(completed_log.length() <= 96, true, "processing completion log stays short")
	reactor.free()

	var build_system := BuildSystem.new(host.data_registry)
	var build_world := WorldState.create_default()
	var build_character := CharacterState.create_default()
	build_world.ensure_map_object(
		"map_object_instance.rough_ground_north",
		"map_object.rough_ground",
		"region.pollution_edge"
	)
	build_world.set_map_object_flag("map_object_instance.rough_ground_north", "is_cleared", true)
	build_character.inventory.add_item("item.foundation_material", 1)
	var build_result := build_system.build_structure(
		"map_object_instance.foundation_site_north",
		"building.foundation_t1",
		build_character,
		build_world,
		"map_object_instance.rough_ground_north"
	)
	var build_log := log_presenter.format_result_log(build_result)
	host._expect_text_contains(build_log, "建造完成：基础地基", "build completion log title")
	host._expect_text_contains(build_log, "状态：已建成", "build completion log status")
	host._expect_text_contains(
		build_log,
		"去向：处理点地基状态",
		"build completion log destination"
	)
	host._expect_text_contains(build_log, "下一步：继续铺设另一块基础地基", "build completion log next step")
	host._expect_equal(build_log.count("\n"), 1, "build completion log uses two-row HUD text")
	host._expect_equal(build_log.length() <= 96, true, "build completion log stays short")

	build_world.ensure_map_object(
		"map_object_instance.rough_ground_south",
		"map_object.rough_ground",
		"region.pollution_edge"
	)
	build_world.set_map_object_flag("map_object_instance.rough_ground_south", "is_cleared", true)
	build_character.inventory.add_item("item.foundation_material", 1)
	var second_build_result := build_system.build_structure(
		"map_object_instance.foundation_site_south",
		"building.foundation_t1",
		build_character,
		build_world,
		"map_object_instance.rough_ground_south"
	)
	var second_build_log := log_presenter.format_result_log(second_build_result)
	host._expect_text_contains(second_build_log, "下一步：现在可以建造污染过滤器", "second foundation log points to filter")

	build_character.inventory.add_item("item.basic_parts", 3)
	build_character.inventory.add_item("item.filter_media", 1)
	var filter_build_result := build_system.build_structure(
		"map_object_instance.pollution_filter_build_site",
		"building.pollution_filter",
		build_character,
		build_world
	)
	var filter_build_log := log_presenter.format_result_log(filter_build_result)
	host._expect_text_contains(filter_build_log, "建造完成：污染过滤器", "filter completion log title")
	host._expect_text_contains(filter_build_log, "下一步：过滤器已上线", "filter completion log next step")
	host._expect_text_contains(filter_build_log, "去向：污染过滤器", "filter completion log destination")

	var filter_processing_world := WorldState.create_default()
	var filter_processing_character := CharacterState.create_default()
	filter_processing_world.quest_state.active_quest_ids = ["quest.enter_pollution_edge"]
	filter_processing_world.quest_state.unlock_effect("recipe.cleanse_residue")
	filter_processing_world.add_base_structure(
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.pollution_edge"
	)
	filter_processing_character.inventory.add_item("item.polluted_residue", 2)
	filter_processing_character.inventory.add_fluid("fluid.basic_solvent", 1.0)
	var filter_start := processing.process_recipe("recipe.cleanse_residue", filter_processing_character, filter_processing_world)
	host._expect_equal(bool(filter_start.get("success", false)), true, "pollution filter processing starts")
	var filter_completed_results := processing.advance_processing(12.0, filter_processing_character, filter_processing_world)
	host._expect_equal(filter_completed_results.size(), 1, "pollution filter completion emits one result")
	var filter_completed_log := log_presenter.format_result_log(filter_completed_results[0])
	host._expect_text_contains(filter_completed_log, "加工完成：处理污染沉积物", "pollution filter completion log title")
	host._expect_text_contains(filter_completed_log, "下一步：带药剂回污染边界", "pollution filter completion log field return")
	host._expect_text_contains(filter_completed_log, "清理受扰敌人和门前压力点", "pollution filter completion log pressure cleanup")
	host._expect_text_contains(filter_completed_log, "去向：抗污染药剂 I x1", "pollution filter completion log vial destination")
	host._expect_equal(filter_completed_log.count("\n"), 1, "pollution filter completion log uses two-row HUD text")
	host._expect_equal(filter_completed_log.length() <= 96, true, "pollution filter completion log stays short")


func _create_formatter() -> InteractionPromptFormatter:
	return InteractionPromptFormatter.new(
		host.data_registry,
		ProcessingSystem.new(host.data_registry),
		BuildSystem.new(host.data_registry)
	)
