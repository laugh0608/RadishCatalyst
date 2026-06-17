extends SceneTree

const SLOT_ID := "demo_combat_evacuation_recovery"
const OUTPOST_REGION_ID := "region.outpost_platform"
const OUTPOST_POSITION := Vector2(-250, -48)

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
		print("Demo combat evacuation recovery checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_pollution_protection_evacuation_recovery()
	_check_deep_combat_evacuation_recovery()
	_check_core_guard_evacuation_save_roundtrip()


func _check_pollution_protection_evacuation_recovery() -> void:
	var world := _create_outpost_restored_world("region.pollution_edge", "quest.enter_pollution_edge")
	var character := _create_character("region.pollution_edge", 85.0, 0.0)
	var feedback := _evacuate(world, character, "pollution")
	_expect_text_contains(String(feedback.get("reason_text", "")), "防护耗尽", "pollution evacuation reason")
	_expect_text_contains(String(feedback.get("origin_text", "")), "污染边界", "pollution evacuation origin")
	_expect_text_contains(
		String(feedback.get("retained_progress_text", "")),
		"污染采集",
		"pollution evacuation retains progress"
	)
	_expect_text_contains(
		String(feedback.get("recovery_action_text", "")),
		"抗污染药剂",
		"pollution evacuation recovery action"
	)
	_expect_equal(world.current_region_id, OUTPOST_REGION_ID, "pollution evacuation world returns to outpost")
	_expect_equal(character.current_region_id, OUTPOST_REGION_ID, "pollution evacuation character returns to outpost")
	_expect_equal(character.position, OUTPOST_POSITION, "pollution evacuation character save position returns to outpost")

	var panel_text := String(HudFeedbackPresenter.new().format_evacuation_panel_texts(feedback).get("detail", ""))
	_expect_text_contains(panel_text, "保留进度", "pollution evacuation panel has retained progress")
	_expect_text_contains(panel_text, "继续目标", "pollution evacuation panel has next target")

	var status_text := HudStatusPresenter.new().format_status_text(data_registry, world, character)
	_expect_text_contains(status_text, "撤离恢复", "pollution outpost HUD has recovery summary")
	_expect_text_contains(status_text, "污染边界排压", "pollution outpost HUD keeps route target")

	var map_hint := HudMapPresenter.new().format_demo_route_hint(world, "quest.enter_pollution_edge", character)
	_expect_text_contains(map_hint, "撤离恢复", "pollution outpost map has recovery hint")
	_expect_text_contains(map_hint, "污染边界排压", "pollution outpost map keeps target")

	var formatter := _create_interaction_formatter()
	var outpost_prompt := formatter.format_outpost_core_prompt(world, character)
	_expect_text_contains(outpost_prompt, "撤离恢复", "pollution outpost core prompt has recovery")
	_expect_text_contains(outpost_prompt, "保留进度", "pollution outpost core prompt keeps retained progress")

	var departure_gate := _create_interactable(
		"map_object_instance.outpost_departure_gate",
		"map_object.outpost_departure_gate",
		"inspect"
	)
	var departure_prompt := formatter.format_general_interaction_prompt(departure_gate, character, world)
	_expect_text_contains(departure_prompt, "撤离恢复未完成", "departure gate blocks unfinished recovery")
	_expect_text_contains(departure_prompt, "先完成前哨恢复", "departure gate points to recovery before sortie")
	departure_gate.free()


func _check_deep_combat_evacuation_recovery() -> void:
	var world := _create_outpost_restored_world("region.deep_ruin_threshold", "quest.activate_deep_array")
	world.unlock_region("region.deep_ruin_threshold")
	world.ensure_enemy("enemy_instance.deep_ruin_sentinel", "enemy.deep_ruin_sentinel", "region.deep_ruin_threshold", 72.0)
	world.update_enemy_health("enemy_instance.deep_ruin_sentinel", 0.0, true)
	var character := _create_character("region.deep_ruin_threshold", 0.0, 88.0)
	var feedback := _evacuate(world, character, "combat")

	_expect_text_contains(String(feedback.get("reason_text", "")), "生命耗尽", "deep combat evacuation reason")
	_expect_text_contains(String(feedback.get("origin_text", "")), "裂相脊", "deep combat evacuation origin")
	_expect_text_contains(
		String(feedback.get("retained_progress_text", "")),
		"深段",
		"deep combat evacuation keeps deep progress"
	)
	_expect_text_contains(
		String(feedback.get("next_target_text", "")),
		"裂相阵列",
		"deep combat evacuation keeps active target"
	)

	var status_text := HudStatusPresenter.new().format_status_text(data_registry, world, character)
	_expect_text_contains(status_text, "撤离恢复", "deep combat HUD has recovery summary")
	_expect_text_contains(status_text, "裂相阵列", "deep combat HUD keeps target")

	var map_hint := HudMapPresenter.new().format_demo_route_hint(world, "quest.activate_deep_array", character)
	_expect_text_contains(map_hint, "撤离恢复", "deep combat map has recovery hint")
	_expect_text_contains(map_hint, "裂相阵列", "deep combat map keeps target")


func _check_core_guard_evacuation_save_roundtrip() -> void:
	var checkpoint := _create_core_guard_checkpoint()
	if checkpoint.is_empty():
		return
	var world: WorldState = checkpoint.get("world_state", null)
	var character: CharacterState = checkpoint.get("character_state", null)
	var feedback := _evacuate(world, character, "combat")

	_expect_text_contains(String(feedback.get("reason_text", "")), "生命和防护耗尽", "core guard evacuation reason")
	_expect_text_contains(String(feedback.get("origin_text", "")), "核心稳定站", "core guard evacuation origin")
	_expect_text_contains(
		String(feedback.get("retained_progress_text", "")),
		"核心守卫状态",
		"core guard evacuation keeps guard progress"
	)
	_expect_text_contains(
		String(feedback.get("next_target_text", "")),
		"核心稳定写入",
		"core guard evacuation keeps write target"
	)

	save_service.delete_game_for_slot(SLOT_ID)
	_expect_success(save_service.save_game_for_slot(SLOT_ID, world, character), "core guard evacuation save")
	var load_result := save_service.load_game_for_slot(SLOT_ID)
	_expect_success(load_result, "core guard evacuation load")
	if not bool(load_result.get("success", false)):
		return

	var loaded_world: WorldState = load_result.get("world_state", null)
	var loaded_character: CharacterState = load_result.get("character_state", null)
	if loaded_world == null or loaded_character == null:
		failures.append("core guard evacuation load should return world and character states")
		return

	_expect_equal(loaded_world.current_region_id, OUTPOST_REGION_ID, "loaded core evacuation world remains at outpost")
	_expect_equal(loaded_character.current_region_id, OUTPOST_REGION_ID, "loaded core evacuation character remains at outpost")
	_expect_equal(loaded_character.position, OUTPOST_POSITION, "loaded core evacuation position remains at outpost")
	_expect_array_has(
		loaded_world.quest_state.active_quest_ids,
		"quest.write_demo_stabilization_core",
		"loaded core evacuation keeps write quest"
	)
	_expect_equal(
		bool(loaded_world.get_enemy("enemy_instance.demo_stabilization_guard").get("core_buffer_used", false)),
		true,
		"loaded core evacuation keeps guard buffer evidence"
	)
	_expect_equal(
		bool(loaded_world.get_map_object("map_object_instance.demo_stabilization_guard_cache").get("is_gathered", false)),
		true,
		"loaded core evacuation keeps guard cache"
	)
	var status_text := HudStatusPresenter.new().format_status_text(data_registry, loaded_world, loaded_character)
	_expect_text_contains(status_text, "撤离恢复", "loaded core evacuation HUD keeps recovery")
	save_service.delete_game_for_slot(SLOT_ID)


func _evacuate(world_state: WorldState, character_state: CharacterState, reason: String) -> Dictionary:
	var map := VerticalSliceMap.new()
	map.player = PlayerController.new()
	var feedback := map._evacuate_if_needed(character_state, world_state, reason)
	map.player.free()
	map.free()
	return feedback


func _create_outpost_restored_world(region_id: String, active_quest_id: String) -> WorldState:
	var world := WorldState.create_default()
	world.current_region_id = region_id
	world.quest_state.complete_quest("quest.restore_outpost")
	world.quest_state.active_quest_ids = [active_quest_id]
	world.unlock_region(region_id)
	return world


func _create_core_guard_checkpoint() -> Dictionary:
	var result := baseline_builder.create_baseline_state("baseline.s21_demo_stabilization_core_ready")
	_expect_success(result, "S21 baseline for core guard evacuation")
	if not bool(result.get("success", false)):
		return {}
	var world: WorldState = result.get("world_state", null)
	var character: CharacterState = result.get("character_state", null)
	if world == null or character == null:
		failures.append("S21 baseline should return world and character states")
		return {}
	world.current_region_id = "region.demo_stabilization_core"
	character.current_region_id = "region.demo_stabilization_core"
	character.position = Vector2(3720, 32)
	character.health = 0.0
	character.protection = 0.0
	character.inventory.add_item("item.core_write_charge", 1)
	world.unlock_region("region.demo_stabilization_core")
	for quest_id in [
		"quest.enter_demo_stabilization_core",
		"quest.prepare_demo_stabilization_buffer",
		"quest.defeat_demo_stabilization_guard"
	]:
		world.quest_state.complete_quest(quest_id)
	world.quest_state.active_quest_ids = ["quest.write_demo_stabilization_core"]
	world.ensure_enemy(
		"enemy_instance.demo_stabilization_guard",
		"enemy.demo_stabilization_guard",
		"region.demo_stabilization_core",
		156.0
	)
	world.update_enemy_health("enemy_instance.demo_stabilization_guard", 0.0, true)
	world.get_enemy("enemy_instance.demo_stabilization_guard")["core_buffer_used"] = true
	world.ensure_map_object(
		"map_object_instance.demo_stabilization_guard_cache",
		"map_object.demo_stabilization_guard_cache",
		"region.demo_stabilization_core"
	)["is_gathered"] = true
	world.quest_state.set_objective_progress(
		"quest.enter_demo_stabilization_core",
		"visit_region",
		"region.demo_stabilization_core",
		1.0
	)
	world.quest_state.set_objective_progress(
		"quest.prepare_demo_stabilization_buffer",
		"gather_item",
		"item.polluted_residue",
		2.0
	)
	world.quest_state.set_objective_progress(
		"quest.prepare_demo_stabilization_buffer",
		"defeat_enemy",
		"enemy.polluted_skitter",
		1.0
	)
	world.quest_state.set_objective_progress(
		"quest.prepare_demo_stabilization_buffer",
		"craft_item",
		"item.core_stabilization_buffer",
		1.0
	)
	world.quest_state.set_objective_progress(
		"quest.defeat_demo_stabilization_guard",
		"defeat_enemy",
		"enemy.demo_stabilization_guard",
		1.0
	)
	world.quest_state.set_objective_progress(
		"quest.write_demo_stabilization_core",
		"gather_item",
		"item.core_write_charge",
		1.0
	)
	world.quest_state.unlock_effect("recipe.core_stabilization_buffer")
	return {
		"world_state": world,
		"character_state": character
	}


func _create_character(region_id: String, health: float, protection: float) -> CharacterState:
	var character := CharacterState.create_default()
	character.current_region_id = region_id
	character.position = Vector2(900, 64)
	character.health = health
	character.protection = protection
	return character


func _create_interaction_formatter() -> InteractionPromptFormatter:
	return InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)


func _create_interactable(instance_id: String, definition_id: String, interaction_type: String) -> PrototypeInteractable:
	var interactable := PrototypeInteractable.new()
	interactable.instance_id = instance_id
	interactable.definition_id = definition_id
	interactable.interaction_type = interaction_type
	interactable.single_use = false
	return interactable


func _cleanup() -> void:
	if save_service != null:
		save_service.delete_game_for_slot(SLOT_ID)
	baseline_builder = null
	save_service = null
	if data_registry != null:
		data_registry.free()
		data_registry = null


func _expect_success(result: Dictionary, message: String) -> void:
	if bool(result.get("success", false)):
		return
	failures.append("%s should succeed, got %s" % [message, var_to_str(result)])


func _expect_equal(actual, expected, context: String) -> void:
	if actual == expected:
		return
	failures.append("%s: expected %s, got %s" % [context, str(expected), str(actual)])


func _expect_array_has(values: Array, expected_value: String, context: String) -> void:
	if values.has(expected_value):
		return
	failures.append("%s should contain %s, got %s" % [context, expected_value, var_to_str(values)])


func _expect_text_contains(text: String, expected: String, context: String) -> void:
	if text.contains(expected):
		return
	failures.append("%s: missing '%s' in '%s'" % [context, expected, text])
