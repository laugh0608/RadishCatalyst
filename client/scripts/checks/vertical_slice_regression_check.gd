extends RefCounted

const GameRootScript := preload("res://scripts/game/game_root.gd")

var host


func _init(check_host) -> void:
	host = check_host


func run_ui_and_recipe_checks() -> void:
	_check_hud_log_presenter()
	_check_resource_interaction_logs()
	_check_completed_recipe_followup_auto_selection()


func check_task_recipe_selection(reactor: PrototypeInteractable, processing: ProcessingSystem) -> void:
	var recipe_world := WorldState.create_default()
	var recipe_character := CharacterState.create_default()
	var filter := PrototypeInteractable.new()
	filter.definition_id = "building.pollution_filter"
	filter.interaction_type = "process_recipe"
	filter.recipe_id = "recipe.cleanse_residue"
	filter.set_recipe_cycle([
		"recipe.cleanse_residue",
		"recipe.phase_filament_refining"
	])
	recipe_world.quest_state.active_quest_ids = ["quest.analyze_anomaly_sample"]
	recipe_world.quest_state.set_objective_progress("quest.analyze_anomaly_sample", "gather_item", "item.anomaly_residue", 2)
	host._expect_equal(
		processing.get_recommended_recipe_id(reactor, recipe_character, recipe_world),
		"recipe.analyze_anomaly_sample",
		"sample analysis task recipe selection"
	)
	recipe_world.quest_state.active_quest_ids = ["quest.make_filter_module"]
	host._expect_equal(
		processing.get_recommended_recipe_id(reactor, recipe_character, recipe_world),
		"recipe.make_filter_media",
		"filter module task first selects media recipe"
	)
	recipe_character.inventory.add_item("item.filter_media", 1)
	host._expect_equal(
		processing.get_recommended_recipe_id(reactor, recipe_character, recipe_world),
		"recipe.basic_filter_module",
		"filter module task selects module recipe after media"
	)
	recipe_character.inventory.items.erase("item.filter_media")
	recipe_character.inventory.items.erase("item.foundation_material")
	recipe_character.inventory.items["item.basic_parts"] = 4
	recipe_world.quest_state.active_quest_ids = ["quest.expand_treatment_point"]
	host._expect_equal(
		processing.get_recommended_recipe_id(reactor, recipe_character, recipe_world),
		"recipe.foundation_t1",
		"expand treatment point first selects foundation recipe"
	)
	recipe_world.add_base_structure(
		"structure.foundation_site_north",
		"building.foundation_t1",
		"region.pollution_edge",
		"map_object_instance.foundation_site_north"
	)
	recipe_world.add_base_structure(
		"structure.foundation_site_south",
		"building.foundation_t1",
		"region.pollution_edge",
		"map_object_instance.foundation_site_south"
	)
	host._expect_equal(
		processing.get_recommended_recipe_id(reactor, recipe_character, recipe_world),
		"recipe.make_filter_media",
		"expand treatment point selects filter media after foundations"
	)
	recipe_character.inventory.add_item("item.filter_media", 1)
	recipe_character.inventory.items["item.basic_parts"] = 2
	host._expect_equal(
		processing.get_recommended_recipe_id(reactor, recipe_character, recipe_world),
		"recipe.process_crystal_ore",
		"expand treatment point falls back to basic parts after filter media"
	)
	recipe_world.quest_state.active_quest_ids = ["quest.refine_phase_filament"]
	host._expect_equal(
		processing.get_recommended_recipe_id(filter, recipe_character, recipe_world),
		"recipe.phase_filament_refining",
		"phase filament refinement selects pollution filter recipe"
	)
	var deep_reactor := PrototypeInteractable.new()
	deep_reactor.definition_id = "building.basic_reactor"
	deep_reactor.interaction_type = "process_recipe"
	deep_reactor.recipe_id = "recipe.process_crystal_ore"
	deep_reactor.set_recipe_cycle([
		"recipe.process_crystal_ore",
		"recipe.deep_signal_analysis",
		"recipe.deep_override_key",
		"recipe.deep_core_imprint",
		"recipe.deep_signal_matrix"
	])
	recipe_character.inventory.items["item.basic_parts"] = 1
	recipe_character.inventory.add_item("item.signal_echo_trace", 1)
	recipe_world.quest_state.active_quest_ids = ["quest.analyze_deep_signal"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.process_crystal_ore",
		"deep signal analysis falls back to basic parts recipe when only parts are missing"
	)
	recipe_character.inventory.items["item.basic_parts"] = 2
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.deep_signal_analysis",
		"deep signal analysis returns to reactor analysis recipe after basic parts are restored"
	)
	recipe_world.quest_state.active_quest_ids = ["quest.analyze_deep_core"]
	host._expect_equal(processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world), "recipe.deep_core_imprint", "deep core analysis selects reactor recipe")
	recipe_world.quest_state.active_quest_ids = ["quest.assemble_deep_override"]
	host._expect_equal(processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world), "recipe.deep_override_key", "deep override assembly selects reactor recipe")
	recipe_character.inventory.add_item("item.phase_conduit", 2)
	recipe_character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	recipe_character.inventory.items["item.basic_parts"] = 1
	recipe_world.quest_state.active_quest_ids = ["quest.assemble_deep_signal_matrix"]
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.process_crystal_ore",
		"deep signal matrix assembly falls back to basic parts recipe when only parts are missing"
	)
	recipe_character.inventory.items["item.basic_parts"] = 2
	host._expect_equal(
		processing.get_recommended_recipe_id(deep_reactor, recipe_character, recipe_world),
		"recipe.deep_signal_matrix",
		"deep signal matrix assembly returns to reactor recipe after basic parts are restored"
	)
	deep_reactor.free()
	filter.free()


func check_equipment_processing_runtime() -> void:
	var processing := ProcessingSystem.new(host.data_registry)
	var module_world := WorldState.create_default()
	module_world.quest_state.unlock_effect("recipe.basic_filter_module")
	var module_character := CharacterState.create_default()
	module_character.inventory.items["item.basic_parts"] = 2
	module_character.inventory.items["item.filter_media"] = 1
	var start_result := processing.process_recipe("recipe.basic_filter_module", module_character, module_world)
	host._expect_equal(bool(start_result.get("success", false)), true, "filter module processing should start")
	var completed_results := processing.advance_processing(20.0, module_character, module_world)
	host._expect_equal(completed_results.size(), 1, "filter module processing should complete")
	host._expect_equal(
		int(module_character.inventory.equipment.get("equipment.filter_module_t1", 0)),
		1,
		"filter module should be stored in equipment inventory"
	)
	host._expect_equal(
		module_character.inventory.items.has("equipment.filter_module_t1"),
		false,
		"filter module should not leak into item inventory"
	)
	host._expect_equal(
		module_character.equip_suit_module("equipment.filter_module_t1"),
		true,
		"crafted filter module can be equipped"
	)
	host._expect_equal(
		String(module_character.equipment.get("suit_module", "")),
		"equipment.filter_module_t1",
		"equipped filter module persists on character slot"
	)
	host._expect_equal(
		int(module_character.inventory.equipment.get("equipment.filter_module_t1", 0)),
		0,
		"equipped filter module should leave equipment inventory"
	)


func _check_hud_log_presenter() -> void:
	var presenter := HudLogPresenter.new(host.data_registry)
	var startup_log := presenter.format_startup_log()
	host._expect_text_contains(
		startup_log,
		"Tab 切换调试面板",
		"startup log keeps debug boundary hint"
	)
	if startup_log.length() > 80:
		host.failures.append("startup log should stay compact, got %d chars: %s" % [startup_log.length(), startup_log])
	host._expect_equal(
		presenter.format_slot_result_log("slot_02", {"message": "保存完成。"}),
		"槽位 02：保存完成。",
		"log presenter formats save slot names"
	)
	host._expect_equal(
		presenter.join_messages(["", "已进入：晶体矿脉区。", "  ", "任务完成：恢复前哨。"]),
		"已进入：晶体矿脉区。 任务完成：恢复前哨。",
		"log presenter joins non-empty messages"
	)
	host._expect_text_contains(
		presenter.format_device_panel_opened_log("building.basic_reactor"),
		"基础反应器",
		"log presenter resolves device display names"
	)
	host._expect_text_contains(
		presenter.format_recommended_recipe_selected_log("recipe.analyze_anomaly_sample"),
		"分析异常样本",
		"log presenter resolves recipe display names"
	)


func _check_resource_interaction_logs() -> void:
	var gather_system := GatherSystem.new(host.data_registry)
	var gather_world := WorldState.create_default()
	var gather_character := CharacterState.create_default()
	var salvage_result := gather_system.interact_with_object(
		"map_object_instance.field_wreckage_north",
		"map_object.field_wreckage",
		"gather",
		gather_character,
		gather_world
	)
	host._expect_text_contains(
		String(salvage_result.get("message", "")),
		"导电废件 x2",
		"gather result should use display names"
	)
	host._expect_text_missing(
		String(salvage_result.get("message", "")),
		"item.salvage_scrap",
		"gather result should not leak item ids"
	)

	var sample_world := WorldState.create_default()
	sample_world.quest_state.active_quest_ids = ["quest.bring_back_sample"]
	var sample_character := CharacterState.create_default()
	var sample_result := gather_system.interact_with_object(
		"map_object_instance.anomaly_crystal",
		"map_object.anomaly_crystal",
		"sample",
		sample_character,
		sample_world
	)
	host._expect_text_contains(
		String(sample_result.get("message", "")),
		"异常样本 x1",
		"sample result should use display names"
	)
	host._expect_text_missing(
		String(sample_result.get("message", "")),
		"item.anomaly_sample",
		"sample result should not leak item ids"
	)


func _check_completed_recipe_followup_auto_selection() -> void:
	var game_root = GameRootScript.new()
	var reactor := PrototypeInteractable.new()
	reactor.definition_id = "building.basic_reactor"
	reactor.interaction_type = "process_recipe"
	reactor.recipe_id = "recipe.foundation_t1"
	reactor.set_recipe_cycle([
		"recipe.foundation_t1",
		"recipe.make_filter_media",
		"recipe.process_crystal_ore"
	])
	var recipe_world := WorldState.create_default()
	recipe_world.quest_state.active_quest_ids = ["quest.expand_treatment_point"]
	recipe_world.add_base_structure(
		"structure.foundation_site_north",
		"building.foundation_t1",
		"region.pollution_edge",
		"map_object_instance.foundation_site_north"
	)
	recipe_world.add_base_structure(
		"structure.foundation_site_south",
		"building.foundation_t1",
		"region.pollution_edge",
		"map_object_instance.foundation_site_south"
	)
	recipe_world.base_structures["structure.basic_reactor"]["status"] = "completed"
	recipe_world.base_structures["structure.basic_reactor"]["last_recipe_id"] = "recipe.foundation_t1"
	var recipe_character := CharacterState.create_default()
	recipe_character.inventory.items["item.basic_parts"] = 4
	game_root.processing_system = ProcessingSystem.new(host.data_registry)
	game_root.world_state = recipe_world
	game_root.character_state = recipe_character
	host._expect_equal(
		game_root._maybe_select_followup_recipe(reactor),
		"recipe.make_filter_media",
		"completed recipe follow-up should auto select next recommendation"
	)
	host._expect_equal(
		reactor.get_current_recipe_id(),
		"recipe.make_filter_media",
		"completed recipe follow-up updates current recipe"
	)
	reactor.select_recipe("recipe.process_crystal_ore")
	host._expect_equal(
		game_root._maybe_select_followup_recipe(reactor),
		"",
		"completed recipe follow-up should not override later manual choice"
	)
	reactor.free()
	game_root.free()
