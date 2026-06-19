extends SceneTree

var failures: Array[String] = []
var data_registry := DataRegistry.new()


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		_run_checks()

	if failures.is_empty():
		print("Demo interaction prompt surface decomposition checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_processing_prompt_delegation()
	_check_processing_prompt_keeps_base_reentry_line()
	_check_processing_log_delegation()


func _check_processing_prompt_delegation() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	character.inventory.add_item("item.crystal_ore", 3)
	world.quest_state.unlock_effect("recipe.process_crystal_ore")
	var reactor := _create_processing_interactable(
		"building.basic_reactor",
		"recipe.process_crystal_ore",
		["recipe.process_crystal_ore", "recipe.reclaim_basic_parts"]
	)
	var formatter := _create_formatter()

	var prompt := formatter.format_processing_prompt(reactor, character, world)
	_expect_text_contains(prompt, "设备：基础反应器", "delegated prompt keeps device title")
	_expect_text_contains(prompt, "配方：处理晶体矿物（1/2）", "delegated prompt keeps recipe cycle position")
	_expect_text_contains(prompt, "Q 详情", "delegated prompt keeps detail action")
	_expect_equal(prompt.split("\n").size() <= 5, true, "delegated prompt stays compact")
	reactor.free()


func _check_processing_prompt_keeps_base_reentry_line() -> void:
	var world := _create_base_reentry_world()
	var character := CharacterState.create_default()
	character.inventory.add_item("item.polluted_residue", 2)
	character.inventory.add_fluid("fluid.basic_solvent", 1.0)
	var filter := _create_processing_interactable("building.pollution_filter", "recipe.cleanse_residue")
	var formatter := _create_formatter()

	var prompt := formatter.format_processing_prompt(filter, character, world)
	_expect_text_contains(prompt, "返回基地读法", "processing prompt shows base reentry line")
	_expect_text_contains(prompt, "外勤带回污染沉积物", "processing prompt explains returned residue")
	_expect_text_contains(prompt, "药剂和浆液", "processing prompt explains processing payoff")
	filter.free()


func _check_processing_log_delegation() -> void:
	var world := _create_base_reentry_world()
	var character := CharacterState.create_default()
	character.inventory.add_item("item.polluted_residue", 2)
	character.inventory.add_fluid("fluid.basic_solvent", 1.0)
	var formatter := _create_formatter()

	var log_text := formatter.format_processing_log("recipe.cleanse_residue", character, world)
	_expect_text_contains(log_text, "处理污染沉积物", "delegated log keeps recipe name")
	_expect_text_contains(log_text, "输入：污染沉积物 x2", "delegated log keeps inputs")
	_expect_text_contains(log_text, "工艺：污染沉积物", "delegated log keeps industrial spine")


func _create_formatter() -> InteractionPromptFormatter:
	return InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)


func _create_base_reentry_world() -> WorldState:
	var world := WorldState.create_default()
	world.current_region_id = "region.outpost_platform"
	world.quest_state.active_quest_ids = []
	world.quest_state.unlock_effect("recipe.cleanse_residue")
	world.add_base_structure("structure.pollution_filter", "building.pollution_filter", "region.outpost_platform")
	return world


func _create_processing_interactable(
	building_id: String,
	recipe_id: String,
	recipe_ids: Array[String] = []
) -> PrototypeInteractable:
	var interactable := PrototypeInteractable.new()
	interactable.definition_id = building_id
	interactable.interaction_type = "process_recipe"
	interactable.recipe_id = recipe_id
	if recipe_ids.is_empty():
		interactable.set_recipe_cycle([recipe_id])
	else:
		interactable.set_recipe_cycle(recipe_ids)
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
