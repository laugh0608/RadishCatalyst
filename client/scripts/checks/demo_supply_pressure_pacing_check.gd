extends SceneTree

var failures: Array[String] = []
var data_registry := DataRegistry.new()


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		_run_checks()

	if failures.is_empty():
		print("Demo supply pressure pacing checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_repair_gel_craft_and_treatment_pressure_value()
	_check_resistance_vial_craft_and_gate_pressure_value()
	_check_outpost_core_restocks_pressure_vial()
	_check_core_write_pressure_uses_vial()


func _check_repair_gel_craft_and_treatment_pressure_value() -> void:
	var processing_system := ProcessingSystem.new(data_registry)
	var world := WorldState.create_default()
	world.quest_state.complete_quest("quest.scout_crystal_field")
	world.quest_state.unlock_effect("recipe.repair_gel")
	var character := CharacterState.create_default()
	character.inventory.items.erase("item.repair_gel")

	var start_result := processing_system.process_recipe("recipe.repair_gel", character, world)
	_expect_success(start_result, "repair gel recipe starts after scout unlock")
	var completed_results := processing_system.advance_processing(6.0, character, world)
	_expect_equal(completed_results.is_empty(), false, "repair gel processing completes")
	_expect_equal(int(character.inventory.items.get("item.repair_gel", 0)), 1, "repair gel craft grants one supply")

	var enemy := _create_enemy("enemy.treatment_skitter", "enemy_instance.treatment_skitter", "处理点扰动体", 35.0)
	var counter_runtime := EnemyCounterattackRuntime.new(data_registry)
	character.health = 58.0
	counter_runtime.apply(enemy, character, world, "region.crystal_vein_field")
	var health_after_pressure := character.health
	_expect_equal(health_after_pressure < 58.0, true, "treatment pressure damages health before supply use")

	var use_result := character.use_quick_slot(0, data_registry)
	_expect_success(use_result, "repair gel quick slot succeeds after treatment pressure")
	_expect_equal(character.health > health_after_pressure, true, "repair gel offsets treatment pressure")
	_expect_equal(character.health >= 84.0, true, "repair gel leaves enough health for another treatment hit")
	enemy.free()


func _check_resistance_vial_craft_and_gate_pressure_value() -> void:
	var processing_system := ProcessingSystem.new(data_registry)
	var world := _create_pressure_supply_world(false)
	var character := CharacterState.create_default()
	character.inventory.add_item("item.polluted_residue", 2)
	character.inventory.items.erase("item.resistance_vial_t1")

	var start_result := processing_system.process_recipe("recipe.cleanse_residue", character, world)
	_expect_success(start_result, "resistance vial recipe starts after pollution filter unlock")
	var completed_results := processing_system.advance_processing(13.0, character, world)
	_expect_equal(completed_results.is_empty(), false, "resistance vial processing completes")
	_expect_equal(int(character.inventory.items.get("item.resistance_vial_t1", 0)), 1, "pollution filter grants one resistance vial")
	_expect_equal(float(character.inventory.fluids.get("fluid.polluted_slurry", 0.0)) >= 1.0, true, "vial processing keeps polluted slurry byproduct")

	var no_vial_world := _create_pressure_supply_world(true)
	var no_vial_character := CharacterState.create_default()
	no_vial_character.inventory.items.erase("item.resistance_vial_t1")
	var no_vial_enemy := _create_enemy("enemy.polluted_skitter", "enemy_instance.polluted_skitter_gate_pressure", "门前受扰掠行体", 30.0)
	var counter_runtime := EnemyCounterattackRuntime.new(data_registry)
	var no_vial_health_before := no_vial_character.health
	var no_vial_protection_before := no_vial_character.protection
	counter_runtime.apply(no_vial_enemy, no_vial_character, no_vial_world, "region.pollution_edge")
	var no_vial_health_loss := no_vial_health_before - no_vial_character.health
	var no_vial_protection_loss := no_vial_protection_before - no_vial_character.protection

	var vial_world := _create_pressure_supply_world(true)
	var vial_character := CharacterState.create_default()
	vial_character.inventory.add_item("item.resistance_vial_t1", 1)
	var vial_enemy := _create_enemy("enemy.polluted_skitter", "enemy_instance.polluted_skitter_gate_pressure", "门前受扰掠行体", 30.0)
	var vial_health_before := vial_character.health
	var vial_protection_before := vial_character.protection
	var vial_message := counter_runtime.apply(vial_enemy, vial_character, vial_world, "region.pollution_edge")
	var vial_health_loss := vial_health_before - vial_character.health
	var vial_protection_loss := vial_protection_before - vial_character.protection

	_expect_equal(int(vial_character.inventory.items.get("item.resistance_vial_t1", 0)), 0, "gate pressure consumes one resistance vial")
	_expect_equal(vial_health_loss < no_vial_health_loss, true, "resistance vial reduces gate health pressure")
	_expect_equal(vial_protection_loss < no_vial_protection_loss, true, "resistance vial reduces gate protection pressure")
	_expect_equal(bool(vial_world.get_enemy("enemy_instance.polluted_skitter_gate_pressure").get("pressure_vial_used", false)), true, "gate pressure records vial spend")
	_expect_text_contains(vial_message, "抗污染药剂已自动接入门前排压", "gate pressure message explains vial value")
	no_vial_enemy.free()
	vial_enemy.free()


func _check_outpost_core_restocks_pressure_vial() -> void:
	var gather_system := GatherSystem.new(data_registry)
	var world := _create_pressure_supply_world(true)
	var character := CharacterState.create_default()
	character.inventory.items.erase("item.resistance_vial_t1")

	var result := gather_system.interact_with_object(
		"map_object_instance.outpost_core",
		"building.outpost_core",
		"outpost_core",
		character,
		world
	)
	_expect_success(result, "outpost core refit succeeds after pressure vial supply unlock")
	_expect_equal(int(character.inventory.items.get("item.resistance_vial_t1", 0)), 1, "outpost core restocks one resistance vial")
	_expect_text_contains(String(result.get("message", "")), "基础储存箱补抗污染药剂", "outpost core restock names pressure vial refill")


func _check_core_write_pressure_uses_vial() -> void:
	var gather_system := GatherSystem.new(data_registry)
	var no_vial_world := _create_core_write_world()
	var no_vial_character := _create_core_write_character(false)
	var no_vial_health_before := no_vial_character.health
	var no_vial_protection_before := no_vial_character.protection
	var no_vial_result := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"inspect",
		no_vial_character,
		no_vial_world
	)
	_expect_success(no_vial_result, "core write succeeds without vial and applies pressure")
	var no_vial_health_loss := no_vial_health_before - no_vial_character.health
	var no_vial_protection_loss := no_vial_protection_before - no_vial_character.protection

	var vial_world := _create_core_write_world()
	var vial_character := _create_core_write_character(true)
	var vial_health_before := vial_character.health
	var vial_protection_before := vial_character.protection
	var vial_result := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"inspect",
		vial_character,
		vial_world
	)
	_expect_success(vial_result, "core write succeeds with pressure vial")
	var vial_health_loss := vial_health_before - vial_character.health
	var vial_protection_loss := vial_protection_before - vial_character.protection

	_expect_equal(int(vial_character.inventory.items.get("item.resistance_vial_t1", 0)), 0, "core write consumes one resistance vial")
	_expect_equal(vial_health_loss < no_vial_health_loss, true, "resistance vial reduces core write health pressure")
	_expect_equal(vial_protection_loss < no_vial_protection_loss, true, "resistance vial reduces core write protection pressure")
	_expect_text_contains(String(vial_result.get("message", "")), "抗污染药剂已自动接入写入排压", "core write message explains vial value")


func _create_pressure_supply_world(mark_vial_supply_available: bool) -> WorldState:
	var world := WorldState.create_default()
	world.add_base_structure("structure.basic_storage", "building.basic_storage", "region.outpost_platform")
	world.add_base_structure("structure.pollution_filter_build_site", "building.pollution_filter", "region.pollution_edge")
	world.quest_state.complete_quest("quest.restore_outpost")
	world.quest_state.complete_quest("quest.expand_treatment_point")
	world.quest_state.unlock_effect("recipe.cleanse_residue")
	if mark_vial_supply_available:
		world.quest_state.set_objective_progress("quest.enter_pollution_edge", "craft_item", "item.resistance_vial_t1", 1.0)
	world.ensure_enemy("enemy_instance.polluted_skitter_gate_pressure", "enemy.polluted_skitter", "region.pollution_edge", 30.0)
	return world


func _create_core_write_world() -> WorldState:
	var world := _create_pressure_supply_world(true)
	world.current_region_id = "region.demo_stabilization_core"
	world.unlock_region("region.demo_stabilization_core")
	world.quest_state.active_quest_ids = ["quest.write_demo_stabilization_core"]
	world.quest_state.set_objective_progress("quest.write_demo_stabilization_core", "gather_item", "item.core_write_charge", 1.0)
	world.ensure_enemy("enemy_instance.demo_stabilization_guard", "enemy.demo_stabilization_guard", "region.demo_stabilization_core", 156.0)
	world.update_enemy_health("enemy_instance.demo_stabilization_guard", 0.0, true)
	return world


func _create_core_write_character(has_vial: bool) -> CharacterState:
	var character := CharacterState.create_default()
	character.current_region_id = "region.demo_stabilization_core"
	character.inventory.items.erase("item.resistance_vial_t1")
	if has_vial:
		character.inventory.add_item("item.resistance_vial_t1", 1)
	return character


func _create_enemy(
	definition_id: String,
	instance_id: String,
	display_name: String,
	max_health: float
) -> PrototypeEnemy:
	var enemy := PrototypeEnemy.new()
	enemy.definition_id = definition_id
	enemy.instance_id = instance_id
	enemy.display_name = display_name
	enemy.max_health = max_health
	enemy.health = max_health
	return enemy


func _expect_success(result: Dictionary, context: String) -> void:
	_expect_equal(bool(result.get("success", false)), true, context)


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
