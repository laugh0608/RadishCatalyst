extends RefCounted

var host


func _init(check_host) -> void:
	host = check_host


func run() -> void:
	_check_build_prompts()
	_check_processing_missing_prompt()
	_check_success_logs_share_interaction_reading()
	_check_contextual_residue_prompts()


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
	var storage_site := PrototypeInteractable.new()
	storage_site.definition_id = "building.basic_storage"
	storage_site.interaction_type = "build"
	storage_site.instance_id = "map_object_instance.basic_storage_build_site"
	var storage_prompt := formatter.format_build_prompt(storage_site, build_character, build_world)
	host._expect_text_contains(storage_prompt, "基础储存箱", "basic storage build prompt names storage")
	host._expect_text_contains(storage_prompt, "按 E 建造", "basic storage build prompt exposes action")
	host._expect_text_contains(storage_prompt, "修复凝胶", "basic storage build prompt explains refit benefit")
	rough_ground.free()
	foundation_site.free()
	filter_site.free()
	storage_site.free()


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
	var storage_build_world := WorldState.create_default()
	var storage_build_character := CharacterState.create_default()
	var storage_build_result := build_system.build_structure(
		"map_object_instance.basic_storage_build_site",
		"building.basic_storage",
		storage_build_character,
		storage_build_world
	)
	var storage_build_log := log_presenter.format_result_log(storage_build_result)
	host._expect_text_contains(storage_build_log, "建造完成：基础储存箱", "storage completion log title")
	host._expect_text_contains(storage_build_log, "前哨整备", "storage completion log points to outpost refit")
	host._expect_equal(
		storage_build_world.has_base_structure_definition("building.basic_storage"),
		true,
		"storage build registers base structure"
	)

	var outpost_world := WorldState.create_default()
	outpost_world.quest_state.complete_quest("quest.restore_outpost")
	outpost_world.add_base_structure(
		"structure.basic_storage_build_site",
		"building.basic_storage",
		"region.outpost_platform",
		"map_object_instance.basic_storage_build_site"
	)
	var outpost_character := CharacterState.create_default()
	outpost_character.inventory.consume_ref("item.repair_gel", 1)
	host._expect_text_contains(
		formatter.format_outpost_core_prompt(outpost_world, outpost_character),
		"操作：E 补修复凝胶",
		"outpost prompt exposes storage restock"
	)
	var outpost_refit_result := GatherSystem.new(host.data_registry).interact_with_object(
		"map_object_instance.outpost_core",
		"building.outpost_core",
		"outpost_core",
		outpost_character,
		outpost_world
	)
	host._expect_text_contains(
		String(outpost_refit_result.get("message", "")),
		"基础储存箱补修复凝胶",
		"outpost refit consumes storage benefit"
	)
	host._expect_text_contains(
		String(outpost_refit_result.get("message", "")),
		"出发检查",
		"outpost refit includes departure readiness detail"
	)
	host._expect_equal(
		int(outpost_character.inventory.items.get("item.repair_gel", 0)),
		1,
		"outpost storage restocks repair gel to one"
	)
	var outpost_ready_result := GatherSystem.new(host.data_registry).interact_with_object(
		"map_object_instance.outpost_core",
		"building.outpost_core",
		"outpost_core",
		outpost_character,
		outpost_world
	)
	host._expect_text_contains(
		String(outpost_ready_result.get("message", "")),
		"前哨核心出发检查",
		"outpost core reports readiness when nothing needs restock"
	)
	var outpost_ready_feedback: Dictionary = outpost_ready_result.get("supply_feedback", {})
	host._expect_equal(
		String(outpost_ready_feedback.get("title", "")),
		"出发准备检查",
		"outpost core ready feedback title"
	)

	var outpost_supply_world := WorldState.create_default()
	outpost_supply_world.quest_state.complete_quest("quest.restore_outpost")
	outpost_supply_world.quest_state.set_objective_progress("quest.enter_pollution_edge", "craft_item", "item.resistance_vial_t1", 1.0)
	outpost_supply_world.add_base_structure(
		"structure.basic_storage_build_site",
		"building.basic_storage",
		"region.outpost_platform",
		"map_object_instance.basic_storage_build_site"
	)
	outpost_supply_world.add_base_structure(
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.outpost_platform",
		"map_object_instance.pollution_filter_build_site"
	)
	var outpost_supply_character := CharacterState.create_default()
	outpost_supply_character.inventory.consume_ref("item.repair_gel", 1)
	host._expect_text_contains(
		formatter.format_outpost_core_prompt(outpost_supply_world, outpost_supply_character),
		"操作：E 补修复凝胶 / 抗污染药剂",
		"outpost prompt exposes storage vial restock"
	)
	var outpost_supply_result := GatherSystem.new(host.data_registry).interact_with_object(
		"map_object_instance.outpost_core",
		"building.outpost_core",
		"outpost_core",
		outpost_supply_character,
		outpost_supply_world
	)
	host._expect_text_contains(
		String(outpost_supply_result.get("message", "")),
		"基础储存箱补抗污染药剂",
		"outpost refit restocks resistance vial after filter setup"
	)
	host._expect_equal(
		int(outpost_supply_character.inventory.items.get("item.repair_gel", 0)),
		1,
		"outpost storage still restocks repair gel with filter setup"
	)
	host._expect_equal(
		int(outpost_supply_character.inventory.items.get("item.resistance_vial_t1", 0)),
		1,
		"outpost storage restocks resistance vial to one"
	)

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


func _check_contextual_residue_prompts() -> void:
	var formatter := _create_formatter()
	var character := CharacterState.create_default()

	var outer_world := WorldState.create_default()
	outer_world.quest_state.active_quest_ids = ["quest.salvage_signal_echo"]
	var outer_residue := _create_residue_interactable("map_object_instance.outer_ring_echo_residue_cache")
	var outer_prompt := formatter.format_general_interaction_prompt(outer_residue, character, outer_world)
	host._expect_text_contains(outer_prompt, "过滤器处理", "outer echo residue prompt points to filter")
	host._expect_text_contains(outer_prompt, "裂相坐标", "outer echo residue prompt points to deep signal analysis")
	host._expect_text_missing(outer_prompt, "门前压力点", "outer echo residue prompt should not use early pollution route")

	outer_world.ensure_map_object(
		"map_object_instance.outer_ring_echo_residue_cache",
		"map_object.pollution_residue_patch",
		"region.ruin_outer_ring"
	)
	outer_world.set_map_object_flag("map_object_instance.outer_ring_echo_residue_cache", "is_gathered", true)
	var gathered_outer_prompt := formatter.format_general_interaction_prompt(outer_residue, character, outer_world)
	host._expect_text_contains(gathered_outer_prompt, "污染回波沉积已回收", "gathered outer residue keeps echo wording")
	host._expect_text_contains(gathered_outer_prompt, "深段回波解析", "gathered outer residue keeps byproduct use")

	var core_world := WorldState.create_default()
	core_world.quest_state.active_quest_ids = ["quest.prepare_demo_stabilization_buffer"]
	var core_residue := _create_residue_interactable("map_object_instance.core_buffer_residue_cache")
	var core_prompt := formatter.format_general_interaction_prompt(core_residue, character, core_world)
	host._expect_text_contains(core_prompt, "核心稳压缓冲包", "core buffer residue prompt points to buffer prep")
	host._expect_text_contains(core_prompt, "药剂和污染浆液", "core buffer residue prompt keeps filter outputs")
	host._expect_text_missing(core_prompt, "门前压力点", "core buffer residue prompt should not use early pollution route")

	var generic_character := CharacterState.create_default()
	generic_character.inventory.add_item("item.resistance_vial_t1", 1)
	var generic_world := WorldState.create_default()
	var generic_residue := _create_residue_interactable("map_object_instance.pollution_residue_deep")
	var generic_prompt := formatter.format_general_interaction_prompt(generic_residue, generic_character, generic_world)
	host._expect_text_contains(generic_prompt, "门前压力点", "generic residue prompt keeps early pollution pressure route")

	outer_residue.free()
	core_residue.free()
	generic_residue.free()


func _create_residue_interactable(instance_id: String) -> PrototypeInteractable:
	var interactable := PrototypeInteractable.new()
	interactable.definition_id = "map_object.pollution_residue_patch"
	interactable.interaction_type = "gather"
	interactable.instance_id = instance_id
	return interactable


func _create_formatter() -> InteractionPromptFormatter:
	return InteractionPromptFormatter.new(
		host.data_registry,
		ProcessingSystem.new(host.data_registry),
		BuildSystem.new(host.data_registry)
	)
