extends SceneTree

var failures: Array[String] = []
var data_registry := DataRegistry.new()


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		_run_checks()

	if failures.is_empty():
		print("Demo field task differentiation checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_formatter_scope()
	_check_gather_feedback_and_object_prompt()
	_check_device_panel_and_processing_feedback()
	_check_outfitting_confirmation_and_roundtrip()


func _check_formatter_scope() -> void:
	var recipe_ids := DemoFieldTaskDifferentiationFormatter.get_task_recipe_ids()
	_expect_equal(recipe_ids.size(), 4, "field task recipe scope stays narrow")
	_expect_array_has(recipe_ids, "recipe.process_crystal_ore", "crystal processing recipe covered")
	_expect_array_has(recipe_ids, "recipe.cleanse_residue", "pollution processing recipe covered")
	_expect_array_has(recipe_ids, "recipe.core_stabilization_buffer", "core preparation recipe covered")

	var object_line := DemoFieldTaskDifferentiationFormatter.format_object_task_line(
		"map_object.pollution_residue_patch",
		{"definition_id": "map_object.pollution_residue_patch"},
		_create_task_world(),
		_create_task_character()
	)
	_expect_text_contains(object_line, "污染沉积", "pollution object exposes task difference")
	_expect_text_contains(object_line, "过滤器", "pollution object points to processing device")


func _check_gather_feedback_and_object_prompt() -> void:
	var world := _create_task_world()
	world.current_region_id = "region.crystal_vein_field"
	var character := _create_task_character()
	character.current_region_id = "region.crystal_vein_field"
	var gather_system := GatherSystem.new(data_registry)

	var result := gather_system.interact_with_object(
		"map_object_instance.crystal_cluster",
		"map_object.crystal_cluster",
		"gather",
		character,
		world
	)
	_expect_equal(bool(result.get("success", false)), true, "crystal gather succeeds")
	_expect_text_contains(String(result.get("message", "")), "外勤任务差异", "gather result names field task difference")
	var feedback: Dictionary = result.get("success_feedback", {})
	_expect_equal(bool(feedback.get("show_field_task", false)), true, "gather feedback exposes field task line")
	_expect_text_contains(String(feedback.get("field_task", "")), "基础反应器", "gather feedback points to reactor")
	_expect_equal(
		bool(world.get_map_object("map_object_instance.crystal_cluster").get("is_gathered", false)),
		true,
		"gather writes object state"
	)

	var prompt_interactable := PrototypeInteractable.new()
	prompt_interactable.definition_id = "map_object.crystal_cluster"
	prompt_interactable.interaction_type = "gather"
	prompt_interactable.instance_id = "map_object_instance.crystal_cluster"
	var prompt := InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	).format_general_interaction_prompt(prompt_interactable, character, world)
	_expect_text_contains(prompt, "任务差异", "object prompt shows field task difference")
	_expect_text_contains(prompt, "基础零件", "object prompt names processing payoff")
	prompt_interactable.free()


func _check_device_panel_and_processing_feedback() -> void:
	var world := _create_task_world()
	var character := _create_task_character()
	character.inventory.add_item("item.crystal_ore", 3)
	var processing_system := ProcessingSystem.new(data_registry)
	var reactor := PrototypeInteractable.new()
	reactor.definition_id = "building.basic_reactor"
	reactor.interaction_type = "process_recipe"
	reactor.recipe_id = "recipe.process_crystal_ore"
	reactor.recipe_ids = ["recipe.process_crystal_ore", "recipe.core_stabilization_buffer"]

	var panel := HudDevicePanelPresenter.new().format_device_panel_texts(
		data_registry,
		processing_system,
		reactor,
		character,
		world
	)
	_expect_text_contains(String(panel.get("status", "")), "任务差异", "device panel shows task difference")
	_expect_text_contains(String(panel.get("status", "")), "工具校准", "device panel names sortie payoff")

	var prompt := ProcessingInteractionPromptFormatter.new(data_registry, processing_system).format_processing_prompt(
		reactor,
		character,
		world
	)
	_expect_text_contains(prompt, "任务差异", "processing prompt shows task difference")

	var start_result := processing_system.process_recipe("recipe.process_crystal_ore", character, world)
	_expect_equal(bool(start_result.get("success", false)), true, "crystal processing starts")
	var completed_results := processing_system.advance_processing(10.0, character, world)
	_expect_equal(completed_results.size(), 1, "crystal processing completes")
	var completed_feedback: Dictionary = completed_results[0].get("success_feedback", {})
	_expect_equal(bool(completed_feedback.get("show_field_task", false)), true, "processing feedback exposes field task")
	_expect_text_contains(String(completed_feedback.get("field_task", "")), "晶体采集", "processing feedback names field source")

	reactor.free()


func _check_outfitting_confirmation_and_roundtrip() -> void:
	var world := _create_task_world()
	var character := _create_task_character()
	character.inventory.add_item("item.crystal_ore", 3)
	character.inventory.add_item("item.polluted_residue", 2)

	var hud_text := HudStatusPresenter.new().format_vitals_text(data_registry, world, character)
	_expect_text_contains(hud_text, "任务差异", "HUD vitals panel shows task difference")
	_expect_text_contains(hud_text, "晶体->基础零件", "HUD names crystal route")
	_expect_equal(
		FieldOutfittingRuntime.can_confirm_field_task_differentiation(character, world),
		true,
		"outfitting station can confirm after two field lanes are ready"
	)

	var prompt := InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	).format_outfitting_station_prompt(character, world)
	_expect_text_contains(prompt, "任务差异登记", "outfitting prompt exposes task differentiation")
	_expect_text_contains(prompt, "E 登记任务差异", "outfitting prompt exposes operation")

	var result := GatherSystem.new(data_registry).interact_with_object(
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_INSTANCE_ID,
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		"inspect",
		character,
		world
	)
	_expect_equal(bool(result.get("success", false)), true, "outfitting task differentiation confirmation succeeds")
	_expect_equal(
		bool(result.get("field_task_differentiation_confirmed", false)),
		true,
		"outfitting result exposes task differentiation marker"
	)
	_expect_equal(
		FieldOutfittingRuntime.is_field_task_differentiation_confirmed(world),
		true,
		"outfitting confirmation writes station state"
	)
	var confirmed_hud := HudStatusPresenter.new().format_vitals_text(data_registry, world, character)
	_expect_text_contains(confirmed_hud, "晶体 / 污染 / 核心准备已登记", "HUD shows confirmed differentiation")

	var restored_world := WorldState.from_dict(world.to_dict())
	_expect_equal(
		FieldOutfittingRuntime.is_field_task_differentiation_confirmed(restored_world),
		true,
		"field task differentiation survives world roundtrip"
	)


func _create_task_world() -> WorldState:
	var world := WorldState.create_default()
	world.current_region_id = "region.outpost_platform"
	world.quest_state.active_quest_ids = []
	for effect_id in [
		"region.outpost_platform",
		"recipe.process_crystal_ore",
		"recipe.cleanse_residue",
		"recipe.reclaim_basic_parts",
		"recipe.core_stabilization_buffer"
	]:
		world.quest_state.unlock_effect(effect_id)
	world.add_base_structure("structure.basic_reactor", "building.basic_reactor", "region.outpost_platform")
	world.add_base_structure(
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.pollution_edge",
		"map_object_instance.pollution_filter_build_site"
	)
	world.add_base_structure(
		"structure.field_outfitting_station",
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		"region.outpost_platform",
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_INSTANCE_ID
	)
	world.ensure_map_object(
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_INSTANCE_ID,
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		"region.outpost_platform"
	)["is_built"] = true
	return world


func _create_task_character() -> CharacterState:
	var character := CharacterState.create_default()
	character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	return character


func _expect_equal(actual, expected, context: String) -> void:
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [context, str(expected), str(actual)])


func _expect_array_has(values: Array, expected_value, context: String) -> void:
	if not values.has(expected_value):
		failures.append("%s: missing %s in %s" % [context, str(expected_value), str(values)])


func _expect_text_contains(text: String, expected_text: String, context: String) -> void:
	if text.find(expected_text) < 0:
		failures.append("%s: expected text '%s' in '%s'" % [context, expected_text, text])


func _cleanup() -> void:
	data_registry.free()
