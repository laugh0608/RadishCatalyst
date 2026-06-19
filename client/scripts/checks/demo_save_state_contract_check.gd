extends SceneTree

const SLOT_ID := "demo_save_state_contract"
const SLOT_SAVE_FILE := "user://saves/slots/demo_save_state_contract/slice_01_autosave.json"

var failures: Array[String] = []
var data_registry := DataRegistry.new()
var save_service := SaveService.new()
var baseline_builder: DevelopmentBaselineBuilder


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		save_service.setup(data_registry)
		baseline_builder = DevelopmentBaselineBuilder.new(data_registry)
		_run_checks()

	if failures.is_empty():
		print("Demo save state contract checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	var state_result := _create_demo_guard_contract_state()
	_expect_success(state_result, "create demo save state contract")
	if not bool(state_result.get("success", false)):
		return

	var world_state: WorldState = state_result.get("world_state", null)
	var character_state: CharacterState = state_result.get("character_state", null)
	if world_state == null or character_state == null:
		failures.append("demo save state contract should return world and character states")
		return

	_check_demo_main_path_roundtrip(world_state, character_state)
	_check_contract_validation_rejects_display_name_region(world_state, character_state)
	_check_contract_validation_rejects_enemy_source_mismatch(world_state, character_state)


func _create_demo_guard_contract_state() -> Dictionary:
	var baseline_result := baseline_builder.create_baseline_state("baseline.s21_demo_stabilization_core_ready")
	if not bool(baseline_result.get("success", false)):
		return baseline_result

	var world_state: WorldState = baseline_result.get("world_state", null)
	var character_state: CharacterState = baseline_result.get("character_state", null)
	if world_state == null or character_state == null:
		return _failure("S21 baseline did not return world and character states.")

	world_state.current_region_id = "region.demo_stabilization_core"
	character_state.current_region_id = "region.demo_stabilization_core"
	character_state.position = Vector2(3688, 18)
	world_state.unlock_region("region.demo_stabilization_core")

	_mark_demo_stabilization_quests(world_state)
	_mark_demo_support_structures(world_state)
	_mark_demo_outfitting_state(world_state, character_state)
	_mark_demo_resource_chain_state(world_state, character_state)
	_mark_demo_enemy_state(world_state)
	CharacterProgressionStats.sync_character_state(character_state, world_state.quest_state, "gain")
	character_state.restore_vitals_to_full()

	return {
		"success": true,
		"world_state": world_state,
		"character_state": character_state
	}


func _mark_demo_stabilization_quests(world_state: WorldState) -> void:
	if not world_state.quest_state.has_completed_quest("quest.enter_demo_stabilization_core"):
		if not world_state.quest_state.has_active_quest("quest.enter_demo_stabilization_core"):
			world_state.quest_state.activate_quest("quest.enter_demo_stabilization_core")
		world_state.quest_state.set_objective_progress(
			"quest.enter_demo_stabilization_core",
			"visit_region",
			"region.demo_stabilization_core",
			1.0
		)
		world_state.quest_state.complete_quest("quest.enter_demo_stabilization_core")
	world_state.quest_state.unlock_effect("recipe.core_stabilization_buffer")

	if not world_state.quest_state.has_completed_quest("quest.prepare_demo_stabilization_buffer"):
		if not world_state.quest_state.has_active_quest("quest.prepare_demo_stabilization_buffer"):
			world_state.quest_state.activate_quest("quest.prepare_demo_stabilization_buffer")
		world_state.quest_state.set_objective_progress(
			"quest.prepare_demo_stabilization_buffer",
			"gather_item",
			"item.polluted_residue",
			2.0
		)
		world_state.quest_state.set_objective_progress(
			"quest.prepare_demo_stabilization_buffer",
			"defeat_enemy",
			"enemy.polluted_skitter",
			1.0
		)
		world_state.quest_state.set_objective_progress(
			"quest.prepare_demo_stabilization_buffer",
			"craft_item",
			"item.core_stabilization_buffer",
			1.0
		)
		world_state.quest_state.complete_quest("quest.prepare_demo_stabilization_buffer")

	if not world_state.quest_state.has_active_quest("quest.defeat_demo_stabilization_guard"):
		world_state.quest_state.activate_quest("quest.defeat_demo_stabilization_guard")


func _mark_demo_support_structures(world_state: WorldState) -> void:
	_mark_structure_built(
		world_state,
		"structure.basic_storage_build_site",
		"building.basic_storage",
		"region.outpost_platform",
		"map_object_instance.basic_storage_build_site"
	)
	_mark_structure_built(
		world_state,
		"structure.field_outfitting_station_build_site",
		"building.field_outfitting_station",
		"region.outpost_platform",
		"map_object_instance.field_outfitting_station_build_site"
	)
	_mark_structure_built(
		world_state,
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.pollution_edge",
		"map_object_instance.pollution_filter_build_site"
	)


func _mark_demo_outfitting_state(world_state: WorldState, character_state: CharacterState) -> void:
	var station := world_state.ensure_map_object(
		"map_object_instance.field_outfitting_station",
		"building.field_outfitting_station",
		"region.outpost_platform"
	)
	station["module_calibrated"] = true
	station["core_archive_maintained"] = true
	character_state.equipment["suit_module"] = "equipment.filter_module_t1"
	character_state.quick_slots = ["item.repair_gel", "item.resistance_vial_t1"]


func _mark_demo_resource_chain_state(world_state: WorldState, character_state: CharacterState) -> void:
	world_state.set_base_structure_status(
		"structure.basic_reactor",
		"completed",
		"recipe.core_stabilization_buffer"
	)
	world_state.set_base_structure_status(
		"structure.pollution_filter_build_site",
		"completed",
		"recipe.cleanse_residue"
	)
	character_state.inventory.add_item("item.basic_parts", 12)
	character_state.inventory.add_item("item.repair_gel", 2)
	character_state.inventory.add_item("item.resistance_vial_t1", 2)
	character_state.inventory.add_item("item.core_stabilization_buffer", 1)
	character_state.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	character_state.inventory.add_fluid("fluid.basic_solvent", 2.0)


func _mark_demo_enemy_state(world_state: WorldState) -> void:
	var core := world_state.ensure_map_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"region.demo_stabilization_core"
	)
	core["is_sampled"] = false
	var guard := world_state.ensure_enemy(
		"enemy_instance.demo_stabilization_guard",
		"enemy.demo_stabilization_guard",
		"region.demo_stabilization_core",
		180.0
	)
	guard["health"] = 96.0
	guard["is_defeated"] = false
	guard["core_buffer_used"] = true
	guard["drops_granted"] = false


func _mark_structure_built(
	world_state: WorldState,
	structure_id: String,
	building_id: String,
	region_id: String,
	site_instance_id: String
) -> void:
	var site := world_state.ensure_map_object(site_instance_id, building_id, region_id)
	site["is_built"] = true
	site["built_definition_id"] = building_id
	world_state.add_base_structure(structure_id, building_id, region_id, site_instance_id)


func _check_demo_main_path_roundtrip(world_state: WorldState, character_state: CharacterState) -> void:
	_remove_slot_files()
	_expect_success(
		save_service.save_game_for_slot(SLOT_ID, world_state, character_state),
		"save demo save state contract"
	)
	if not FileAccess.file_exists(SLOT_SAVE_FILE):
		failures.append("demo save state contract should write the named slot save file")

	var load_result := save_service.load_game_for_slot(SLOT_ID)
	_expect_success(load_result, "load demo save state contract")
	if not bool(load_result.get("success", false)):
		return

	var loaded_world: WorldState = load_result.get("world_state", null)
	var loaded_character: CharacterState = load_result.get("character_state", null)
	if loaded_world == null or loaded_character == null:
		failures.append("loaded demo save state contract should return world and character states")
		return

	_check_loaded_world_contract(loaded_world)
	_check_loaded_character_contract(loaded_character)
	_check_loaded_inventory_contract(loaded_character.inventory)
	_check_loaded_building_contract(loaded_world)
	_check_loaded_task_contract(loaded_world.quest_state)
	_check_loaded_region_contract(loaded_world, loaded_character)
	_check_loaded_enemy_contract(loaded_world)
	_check_loaded_readiness_contract(loaded_world, loaded_character)


func _check_loaded_world_contract(world_state: WorldState) -> void:
	_expect_equal(world_state.world_id, "world.slice_01.prototype", "world id persists")
	_expect_array_has(world_state.unlocked_region_ids, "region.demo_stabilization_core", "demo core region unlock persists")
	_expect_array_has(
		world_state.get_deployed_phase_relay_anchor_ids(),
		"map_object_instance.phase_return_anchor_tether",
		"phase relay anchor deployment persists"
	)
	_expect_equal(
		world_state.active_phase_relay_anchor_id,
		"map_object_instance.phase_return_anchor_tether",
		"active phase relay anchor persists"
	)


func _check_loaded_character_contract(character_state: CharacterState) -> void:
	_expect_equal(character_state.stable_id, "character.player", "character stable id persists")
	_expect_equal(character_state.current_region_id, "region.demo_stabilization_core", "character region persists")
	_expect_equal(character_state.position, Vector2(3688, 18), "character position persists")
	_expect_equal(
		String(character_state.equipment.get("suit_module", "")),
		"equipment.filter_module_t1",
		"equipped filter module persists"
	)
	_expect_equal(character_state.quick_slots, ["item.repair_gel", "item.resistance_vial_t1"], "quick slots persist")


func _check_loaded_inventory_contract(inventory: InventoryState) -> void:
	if inventory == null:
		failures.append("loaded inventory should not be null")
		return
	_expect_equal(int(inventory.items.get("item.core_stabilization_buffer", 0)), 1, "core buffer inventory persists")
	_expect_equal(int(inventory.items.get("item.repair_gel", 0)), 6, "repair gel inventory persists")
	_expect_equal(int(inventory.items.get("item.resistance_vial_t1", 0)), 7, "resistance vial inventory persists")
	_expect_equal(float(inventory.fluids.get("fluid.polluted_slurry", 0.0)), 1.0, "polluted slurry inventory persists")


func _check_loaded_building_contract(world_state: WorldState) -> void:
	_expect_equal(
		world_state.has_base_structure_definition("building.basic_storage"),
		true,
		"basic storage structure persists"
	)
	_expect_equal(
		world_state.has_base_structure_definition("building.field_outfitting_station"),
		true,
		"field outfitting station structure persists"
	)
	_expect_equal(
		world_state.has_base_structure_definition("building.pollution_filter"),
		true,
		"pollution filter structure persists"
	)
	var reactor_data = world_state.base_structures.get("structure.basic_reactor", {})
	if reactor_data is Dictionary:
		var reactor: Dictionary = reactor_data
		_expect_equal(String(reactor.get("last_recipe_id", "")), "recipe.core_stabilization_buffer", "reactor last recipe persists")
	else:
		failures.append("basic reactor structure should persist as a dictionary")
	var station := world_state.get_map_object("map_object_instance.field_outfitting_station")
	_expect_equal(bool(station.get("module_calibrated", false)), true, "outfitting module calibration flag persists")
	_expect_equal(bool(station.get("core_archive_maintained", false)), true, "outfitting maintenance flag persists")


func _check_loaded_task_contract(quest_state: QuestState) -> void:
	_expect_array_has(quest_state.completed_quest_ids, "quest.enter_demo_stabilization_core", "enter demo core quest persists")
	_expect_array_has(quest_state.completed_quest_ids, "quest.prepare_demo_stabilization_buffer", "prepare core buffer quest persists")
	_expect_array_has(quest_state.active_quest_ids, "quest.defeat_demo_stabilization_guard", "guard quest remains active")
	_expect_array_has(quest_state.unlocked_effects, "recipe.core_stabilization_buffer", "core buffer recipe unlock persists")
	_expect_equal(
		quest_state.get_objective_progress(
			"quest.prepare_demo_stabilization_buffer",
			"craft_item",
			"item.core_stabilization_buffer"
		),
		1.0,
		"core buffer craft objective progress persists"
	)


func _check_loaded_region_contract(world_state: WorldState, character_state: CharacterState) -> void:
	_expect_equal(world_state.current_region_id, "region.demo_stabilization_core", "world region persists")
	_expect_equal(character_state.current_region_id, "region.demo_stabilization_core", "world and character region stay aligned")
	_expect_equal(
		float(world_state.pollution_levels.get("region.demo_stabilization_core", 0.0)) >= 0.0,
		true,
		"demo core pollution level remains readable"
	)


func _check_loaded_enemy_contract(world_state: WorldState) -> void:
	var guard := world_state.get_enemy("enemy_instance.demo_stabilization_guard")
	_expect_equal(String(guard.get("definition_id", "")), "enemy.demo_stabilization_guard", "demo guard definition persists")
	_expect_equal(String(guard.get("region_id", "")), "region.demo_stabilization_core", "demo guard region persists")
	_expect_equal(float(guard.get("health", 0.0)), 96.0, "demo guard health persists")
	_expect_equal(bool(guard.get("is_defeated", true)), false, "demo guard defeat state persists")
	_expect_equal(bool(guard.get("core_buffer_used", false)), true, "demo guard core buffer state persists")


func _check_loaded_readiness_contract(world_state: WorldState, character_state: CharacterState) -> void:
	var chain_line := DemoResourceChainStateFormatter.format_chain_state_line(world_state, character_state)
	_expect_text_contains(chain_line, "核心整备完成", "resource chain readiness survives load")
	var snapshot := DemoResourceChainStateFormatter.format_core_resource_snapshot(character_state.inventory)
	_expect_text_contains(snapshot, "核心稳压缓冲包", "resource chain snapshot keeps core buffer")


func _check_contract_validation_rejects_display_name_region(
	world_state: WorldState,
	character_state: CharacterState
) -> void:
	var save_data := _make_save_data(world_state, character_state)
	var world_data: Dictionary = save_data["world"]
	var character_data: Dictionary = save_data["character"]
	world_data["current_region_id"] = "核心稳定站"
	character_data["current_region_id"] = "核心稳定站"
	var error := SaveContentValidator.new(data_registry).validate_save_content(save_data)
	_expect_text_contains(error, "world.current_region_id 使用了错误类型的定义 ID", "validator rejects display-name region truth source")


func _check_contract_validation_rejects_enemy_source_mismatch(
	world_state: WorldState,
	character_state: CharacterState
) -> void:
	var save_data := _make_save_data(world_state, character_state)
	var world_data: Dictionary = save_data["world"]
	var enemies: Dictionary = world_data["enemies"]
	var guard: Dictionary = enemies["enemy_instance.demo_stabilization_guard"]
	guard["definition_id"] = "enemy.native_skitter"
	var error := SaveContentValidator.new(data_registry).validate_save_content(save_data)
	_expect_text_contains(error, "world.enemies.enemy_instance.demo_stabilization_guard 与原型敌人定义不一致", "validator rejects enemy source mismatch")


func _make_save_data(world_state: WorldState, character_state: CharacterState) -> Dictionary:
	return {
		"save_schema_version": SaveService.SAVE_SCHEMA_VERSION,
		"game_version": SaveService.GAME_VERSION,
		"world": world_state.to_dict(),
		"character": character_state.to_dict()
	}


func _remove_slot_files() -> void:
	save_service.delete_game_for_slot(SLOT_ID)


func _expect_success(result: Dictionary, label: String) -> void:
	if bool(result.get("success", false)):
		return
	failures.append("%s failed: %s" % [label, String(result.get("message", ""))])


func _expect_equal(actual, expected, label: String) -> void:
	if actual == expected:
		return
	failures.append("%s: expected %s, got %s" % [label, str(expected), str(actual)])


func _expect_array_has(values: Array, expected_value: String, label: String) -> void:
	if values.has(expected_value):
		return
	failures.append("%s: expected array to contain %s, got %s" % [label, expected_value, str(values)])


func _expect_text_contains(text: String, expected_text: String, label: String) -> void:
	if text.find(expected_text) >= 0:
		return
	failures.append("%s: expected text to contain '%s', got '%s'" % [label, expected_text, text])


func _failure(message: String) -> Dictionary:
	return {
		"success": false,
		"message": message
	}


func _cleanup() -> void:
	_remove_slot_files()
	data_registry.free()
