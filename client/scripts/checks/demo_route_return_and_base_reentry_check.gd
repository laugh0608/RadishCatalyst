extends SceneTree

var failures: Array[String] = []
var data_registry := DataRegistry.new()


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		_run_checks()

	if failures.is_empty():
		print("Demo route return and base reentry checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_residue_return_hud_map_and_device()
	_check_signal_return_reactor_and_route()
	_check_reentry_processing_result_feedback()
	_check_base_reentry_state_roundtrip()


func _check_residue_return_hud_map_and_device() -> void:
	var world := _create_base_reentry_world()
	var character := CharacterState.create_default()
	character.inventory.add_item("item.polluted_residue", 2)
	character.inventory.add_fluid("fluid.basic_solvent", 1.0)
	var filter := _create_processing_interactable("building.pollution_filter", "recipe.cleanse_residue")
	var processing := ProcessingSystem.new(data_registry)

	var hud_text := HudStatusPresenter.new().format_vitals_text(data_registry, world, character)
	_expect_text_contains(hud_text, "返回基地读法", "HUD shows base reentry summary")
	_expect_text_contains(hud_text, "污染沉积物已带回 -> 污染过滤器", "HUD points residue to filter")
	_expect_text_contains(hud_text, "外勤出发口", "HUD names next departure entry")

	var map_hint := HudMapPresenter.new().format_demo_route_hint(world, "", character)
	_expect_text_contains(map_hint, "基地回收", "map route hint shows base return state")
	_expect_text_contains(map_hint, "污染过滤器处理", "map route hint points to processing device")

	var panel := HudDevicePanelPresenter.new().format_device_panel_texts(
		data_registry,
		processing,
		filter,
		character,
		world
	)
	var status := String(panel.get("status", ""))
	_expect_text_contains(status, "返回基地读法", "device panel shows base reentry line")
	_expect_text_contains(status, "药剂和浆液", "device panel explains residue payoff")
	_expect_equal(
		processing.get_recommended_recipe_id(filter, character, world),
		"recipe.cleanse_residue",
		"base reentry recommends residue treatment without active quest"
	)
	filter.free()


func _check_signal_return_reactor_and_route() -> void:
	var world := _create_base_reentry_world()
	var character := CharacterState.create_default()
	character.inventory.add_item("item.signal_echo_trace", 1)
	character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	world.set_active_phase_relay_anchor("map_object_instance.phase_return_anchor")
	var reactor := _create_processing_interactable(
		"building.basic_reactor",
		"recipe.deep_signal_analysis",
		["recipe.deep_signal_analysis", "recipe.reclaim_basic_parts"]
	)
	var processing := ProcessingSystem.new(data_registry)

	var hud_lines := DemoRouteReturnAndBaseReentryFormatter.format_hud_summary(world, character)
	_expect_text_contains("\n".join(hud_lines), "回波痕迹已带回 -> 基础反应器", "formatter points echo to reactor")
	_expect_text_contains("\n".join(hud_lines), "相位回投台", "formatter uses relay entry when anchor exists")

	var map_hint := HudMapPresenter.new().format_demo_route_hint(world, "", character)
	_expect_text_contains(map_hint, "回波痕迹先到基础反应器解析", "map route hint names echo processing")
	_expect_text_contains(map_hint, "相位回投台", "map route hint names relay reentry")

	var panel := HudDevicePanelPresenter.new().format_device_panel_texts(
		data_registry,
		processing,
		reactor,
		character,
		world
	)
	var status := String(panel.get("status", ""))
	_expect_text_contains(status, "回波痕迹已经回到基地", "reactor panel explains returned echo")
	_expect_text_contains(status, "裂相坐标", "reactor panel names processing payoff")
	_expect_equal(
		processing.get_recommended_recipe_id(reactor, character, world),
		"recipe.deep_signal_analysis",
		"base reentry recommends deep signal analysis without active quest"
	)
	reactor.free()


func _check_reentry_processing_result_feedback() -> void:
	var world := _create_base_reentry_world()
	var character := CharacterState.create_default()
	character.inventory.add_item("item.polluted_residue", 2)
	character.inventory.add_fluid("fluid.basic_solvent", 1.0)
	var processing := ProcessingSystem.new(data_registry)

	var started := processing.process_recipe("recipe.cleanse_residue", character, world)
	_expect_equal(bool(started.get("success", false)), true, "residue treatment starts")
	var completed := processing.advance_processing(20.0, character, world)
	_expect_equal(completed.size(), 1, "residue treatment completes")
	if completed.is_empty():
		return

	var result_log := HudLogPresenter.new(data_registry).format_result_log(completed[0])
	_expect_text_contains(result_log, "再进入", "processing result log shows reentry feedback")
	_expect_text_contains(result_log, "沉积物已转成药剂和浆液", "processing result explains returned material payoff")
	_expect_text_contains(result_log, "外勤出发口", "processing result points to next departure")


func _check_base_reentry_state_roundtrip() -> void:
	var world := _create_base_reentry_world()
	var character := CharacterState.create_default()
	character.inventory.add_item("item.signal_echo_trace", 1)
	character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	world.set_active_phase_relay_anchor("map_object_instance.phase_return_anchor")

	var restored_world := WorldState.from_dict(world.to_dict())
	var restored_character := CharacterState.from_dict(character.to_dict())
	var map_hint := DemoRouteReturnAndBaseReentryFormatter.format_map_route_hint(
		restored_world,
		restored_character
	)
	_expect_text_contains(map_hint, "回波痕迹先到基础反应器解析", "round-trip keeps returned signal state")
	_expect_text_contains(map_hint, "相位回投台", "round-trip keeps relay reentry")


func _create_base_reentry_world() -> WorldState:
	var world := WorldState.create_default()
	world.current_region_id = "region.outpost_platform"
	world.quest_state.active_quest_ids = []
	for recipe_id in [
		"recipe.cleanse_residue",
		"recipe.reclaim_basic_parts",
		"recipe.deep_signal_analysis"
	]:
		world.quest_state.unlock_effect(recipe_id)
	world.add_base_structure("structure.pollution_filter", "building.pollution_filter", "region.outpost_platform")
	world.unlock_region("region.pollution_edge")
	world.unlock_region("region.ruin_outer_ring")
	world.unlock_region("region.deep_ruin_threshold")
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
