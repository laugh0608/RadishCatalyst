extends SceneTree

var failures: Array[String] = []
var data_registry := DataRegistry.new()


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		_run_checks()

	if failures.is_empty():
		print("Demo endpoint readiness checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_hud_outpost_and_departure_gate_readiness()
	_check_core_device_write_readiness()
	_check_context_boundaries()


func _check_hud_outpost_and_departure_gate_readiness() -> void:
	var world := _create_endpoint_entry_world()
	var character := _create_endpoint_character()

	var status_text := HudStatusPresenter.new().format_status_text(data_registry, world, character)
	_expect_text_contains(status_text, "终点前准备", "HUD names endpoint readiness")
	_expect_text_contains(status_text, "主线：核心站入口待进入", "HUD shows endpoint entry state")
	_expect_text_contains(status_text, "终点下一步：从锚定桥进入核心稳定站", "HUD points to core entry")
	_expect_text_contains(status_text, "外勤收益整备已接入", "HUD keeps outfitting payoff state")

	var prompt_formatter := InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)
	var outpost_prompt := prompt_formatter.format_outpost_core_prompt(world, character)
	_expect_text_contains(outpost_prompt, "终点前总览", "outpost prompt shows endpoint overview")
	_expect_text_contains(outpost_prompt, "补给：生命 / 防护已满", "outpost prompt shows supply readiness")

	var departure_gate := PrototypeInteractable.new()
	departure_gate.instance_id = "map_object_instance.outpost_departure_gate"
	departure_gate.definition_id = "map_object.outpost_departure_gate"
	departure_gate.interaction_type = "inspect"
	var departure_prompt := prompt_formatter.format_general_interaction_prompt(
		departure_gate,
		character,
		world
	)
	_expect_text_contains(departure_prompt, "终点前准备", "departure gate prompt shows endpoint readiness")
	_expect_text_contains(departure_prompt, "从锚定桥进入核心稳定站", "departure gate points to core station")
	departure_gate.free()


func _check_core_device_write_readiness() -> void:
	var world := _create_core_write_world()
	var character := _create_endpoint_character()
	character.current_region_id = "region.demo_stabilization_core"
	character.inventory.add_item("item.core_write_charge", 1)

	var prompt_formatter := InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)
	var core := PrototypeInteractable.new()
	core.instance_id = "map_object_instance.demo_stabilization_core"
	core.definition_id = "map_object.demo_stabilization_core"
	core.interaction_type = "inspect"
	core.single_use = false
	var core_prompt := prompt_formatter.format_general_interaction_prompt(core, character, world)
	_expect_text_contains(core_prompt, "终点总览", "core prompt shows endpoint overview")
	_expect_text_contains(core_prompt, "主线：核心设备待写入", "core prompt shows write state")
	_expect_text_contains(core_prompt, "终点准备 4/4", "core prompt shows full write readiness")
	_expect_text_contains(core_prompt, "在核心稳定设备写入核心稳定数据", "core prompt points to write action")
	core.free()


func _check_context_boundaries() -> void:
	var early_world := WorldState.create_default()
	var early_character := CharacterState.create_default()
	_expect_equal(
		DemoEndpointReadinessFormatter.format_hud_summary(early_world, early_character).is_empty(),
		true,
		"endpoint readiness stays hidden before endpoint route"
	)

	var completed_world := _create_core_write_world()
	completed_world.quest_state.complete_quest("quest.write_demo_stabilization_core")
	var completed_character := _create_endpoint_character()
	_expect_equal(
		DemoEndpointReadinessFormatter.format_hud_summary(completed_world, completed_character).is_empty(),
		true,
		"endpoint readiness hides after demo completion"
	)


func _create_endpoint_entry_world() -> WorldState:
	var world := WorldState.create_default()
	world.current_region_id = "region.outpost_platform"
	for quest_id in [
		"quest.restore_outpost",
		"quest.calibrate_phase_well_stability_window",
	]:
		world.quest_state.complete_quest(quest_id)
	world.quest_state.activate_quest("quest.enter_demo_stabilization_core")
	_add_base_facilities(world)
	FieldOutfittingRuntime.mark_module_calibrated(world)
	DemoFieldLoopPayoffFormatter.mark_payoff_confirmed(world)
	return world


func _create_core_write_world() -> WorldState:
	var world := _create_endpoint_entry_world()
	world.current_region_id = "region.demo_stabilization_core"
	world.quest_state.complete_quest("quest.enter_demo_stabilization_core")
	world.quest_state.complete_quest("quest.prepare_demo_stabilization_buffer")
	world.quest_state.complete_quest("quest.defeat_demo_stabilization_guard")
	world.quest_state.active_quest_ids = ["quest.write_demo_stabilization_core"]
	world.quest_state.set_objective_progress("quest.write_demo_stabilization_core", "gather_item", "item.core_write_charge", 1.0)
	world.ensure_enemy("enemy_instance.demo_stabilization_guard", "enemy.demo_stabilization_guard", "region.demo_stabilization_core", 156.0)
	world.update_enemy_health("enemy_instance.demo_stabilization_guard", 0.0, true)
	world.get_enemy("enemy_instance.demo_stabilization_guard")["core_buffer_used"] = true
	world.ensure_map_object(
		"map_object_instance.demo_stabilization_recovery_cache",
		"map_object.demo_stabilization_recovery_cache",
		"region.demo_stabilization_core"
	)["is_gathered"] = true
	world.ensure_map_object(
		"map_object_instance.demo_stabilization_guard_cache",
		"map_object.demo_stabilization_guard_cache",
		"region.demo_stabilization_core"
	)["is_gathered"] = true
	world.ensure_map_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"region.demo_stabilization_core"
	)
	return world


func _create_endpoint_character() -> CharacterState:
	var character := CharacterState.create_default()
	character.inventory.add_item("item.repair_gel", 1)
	character.inventory.add_item("item.resistance_vial_t1", 1)
	character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	return character


func _add_base_facilities(world: WorldState) -> void:
	world.add_base_structure(
		"structure.basic_storage_build_site",
		"building.basic_storage",
		"region.outpost_platform",
		"map_object_instance.basic_storage_build_site"
	)
	world.add_base_structure(
		"structure.field_outfitting_station_build_site",
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		"region.outpost_platform",
		"map_object_instance.field_outfitting_station_build_site"
	)
	var outfitting_site := world.ensure_map_object(
		"map_object_instance.field_outfitting_station_build_site",
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		"region.outpost_platform"
	)
	outfitting_site["is_built"] = true
	outfitting_site["built_definition_id"] = FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID


func _expect_equal(actual, expected, context: String) -> void:
	if actual == expected:
		return
	failures.append("%s: expected %s, got %s" % [context, str(expected), str(actual)])


func _expect_text_contains(text: String, expected: String, context: String) -> void:
	if text.contains(expected):
		return
	failures.append("%s: missing '%s' in '%s'" % [context, expected, text])


func _cleanup() -> void:
	data_registry.free()
