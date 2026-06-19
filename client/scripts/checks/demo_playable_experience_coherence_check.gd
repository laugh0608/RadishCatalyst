extends SceneTree

const SLOT_ID := "demo_playable_experience_coherence"
const SLOT_SAVE_FILE := "user://saves/slots/demo_playable_experience_coherence/slice_01_autosave.json"
const OUTPOST_REGION_ID := "region.outpost_platform"
const OUTER_RING_REGION_ID := "region.ruin_outer_ring"
const TETHER_REGION_ID := "region.phase_well_tether"
const CORE_REGION_ID := "region.demo_stabilization_core"

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
		print("Demo playable experience coherence checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_new_game_checkpoint()
	_check_outer_ring_checkpoint()
	_check_core_entry_checkpoint()
	_check_completed_outpost_review_checkpoint()
	_check_completed_review_save_roundtrip()


func _check_new_game_checkpoint() -> void:
	var checkpoint := _create_baseline("baseline.s0_new_game")
	if checkpoint.is_empty():
		return
	var world_state: WorldState = checkpoint.get("world_state", null)
	var character_state: CharacterState = checkpoint.get("character_state", null)
	_expect_equal(world_state.current_region_id, OUTPOST_REGION_ID, "S0 starts at outpost")
	_expect_array_has(world_state.quest_state.active_quest_ids, "quest.restore_outpost", "S0 active quest")

	var status_text := HudStatusPresenter.new().format_status_text(data_registry, world_state, character_state)
	_expect_text_contains(status_text, "当前目标", "S0 HUD has current target")
	_expect_text_contains(status_text, _get_display_name("quest.restore_outpost"), "S0 HUD names restore objective")
	_expect_text_contains(status_text, "基地摘要", "S0 HUD has base summary")

	var map_presenter := _create_map_presenter()
	var map_hint := map_presenter.format_demo_route_hint(world_state, _get_first_active_quest_id(world_state))
	_expect_text_contains(
		map_presenter.format_demo_route_title(world_state, _get_first_active_quest_id(world_state)),
		"基地整备",
		"S0 map title names base preparation"
	)
	_expect_text_contains(map_hint, "基地整备回路", "S0 map hint names outpost scene")

	var outpost_prompt := _create_interaction_formatter().format_outpost_core_prompt(world_state, character_state)
	_expect_text_contains(outpost_prompt, "恢复", "S0 outpost core prompt starts restore path")
	_expect_text_contains(outpost_prompt, "基地整备回路", "S0 outpost core prompt has scene identity")


func _check_outer_ring_checkpoint() -> void:
	var checkpoint := _create_baseline("baseline.s2_outer_ring_secured")
	if checkpoint.is_empty():
		return
	var world_state: WorldState = checkpoint.get("world_state", null)
	var character_state: CharacterState = checkpoint.get("character_state", null)
	_expect_equal(world_state.current_region_id, OUTER_RING_REGION_ID, "S2 stays at outer ring")
	_expect_array_has(world_state.quest_state.active_quest_ids, "quest.salvage_signal_echo", "S2 active quest")

	var status_text := HudStatusPresenter.new().format_status_text(data_registry, world_state, character_state)
	_expect_text_contains(status_text, _get_display_name("quest.salvage_signal_echo"), "S2 HUD names active quest")
	_expect_text_contains(status_text, "现场玩法", "S2 HUD keeps functional scene gameplay")

	var map_hint := _create_map_presenter().format_demo_route_hint(world_state, _get_first_active_quest_id(world_state))
	_expect_text_contains(map_hint, "封锁遗迹旧设施区", "S2 map keeps non-core scene identity")
	_expect_text_contains(map_hint, "旧设施短副本入口", "S2 map keeps visual read")

	var echo_cache := _create_interactable(
		"map_object_instance.signal_echo_cache",
		"map_object.signal_echo_cache",
		"inspect"
	)
	var prompt := _create_interaction_formatter().format_general_interaction_prompt(
		echo_cache,
		character_state,
		world_state
	)
	_expect_text_contains(prompt, "封锁遗迹旧设施区", "S2 object prompt keeps scene identity")
	_expect_text_contains(prompt, "现场玩法", "S2 object prompt keeps gameplay stage")
	_expect_text_contains(prompt, "回基地", "S2 object prompt keeps return-to-base reason")
	echo_cache.free()


func _check_core_entry_checkpoint() -> void:
	var checkpoint := _create_baseline("baseline.s21_demo_stabilization_core_ready")
	if checkpoint.is_empty():
		return
	var world_state: WorldState = checkpoint.get("world_state", null)
	var character_state: CharacterState = checkpoint.get("character_state", null)
	_expect_equal(world_state.current_region_id, TETHER_REGION_ID, "S21 starts at tether region")
	_expect_array_has(world_state.unlocked_region_ids, CORE_REGION_ID, "S21 unlocks demo core")
	_expect_array_has(
		world_state.quest_state.active_quest_ids,
		"quest.enter_demo_stabilization_core",
		"S21 active quest points to demo core"
	)

	var status_text := HudStatusPresenter.new().format_status_text(data_registry, world_state, character_state)
	_expect_text_contains(status_text, _get_display_name("quest.enter_demo_stabilization_core"), "S21 HUD names core entry")
	_expect_text_contains(status_text, "核心站承压", "S21 HUD keeps terminal pressure summary")
	_expect_text_contains(status_text, "终点下一步", "S21 HUD keeps terminal next step")

	var map_hint := _create_map_presenter().format_demo_route_hint(world_state, _get_first_active_quest_id(world_state))
	_expect_text_contains(map_hint, "目标：核心稳定站", "S21 map points to demo core target")
	_expect_text_contains(map_hint, "核心稳定站终点", "S21 map names core station scene")


func _check_completed_outpost_review_checkpoint() -> void:
	var checkpoint := _create_baseline("baseline.s22_demo_completion_outpost_review")
	if checkpoint.is_empty():
		return
	var world_state: WorldState = checkpoint.get("world_state", null)
	var character_state: CharacterState = checkpoint.get("character_state", null)
	_expect_equal(world_state.current_region_id, OUTPOST_REGION_ID, "S22 returns to outpost")
	_expect_array_has(
		world_state.quest_state.completed_quest_ids,
		"quest.write_demo_stabilization_core",
		"S22 completed demo write"
	)
	_expect_equal(world_state.quest_state.active_quest_ids.is_empty(), true, "S22 has no required follow-up quest")

	var status_text := HudStatusPresenter.new().format_status_text(data_registry, world_state, character_state)
	_expect_text_contains(status_text, "首版 Demo 主线已完成", "S22 HUD names demo completion")
	_expect_text_contains(status_text, "Demo 成果", "S22 HUD shows outcome summary")
	_expect_text_contains(status_text, "成果整理", "S22 HUD keeps outpost review")

	var map_hint := _create_map_presenter().format_demo_route_hint(world_state, "")
	_expect_text_contains(map_hint, "Demo 终点已完成", "S22 map keeps completed endpoint")
	_expect_text_contains(map_hint, "前哨已收到核心写入", "S22 map keeps outpost archive")

	var outpost_prompt := _create_interaction_formatter().format_outpost_core_prompt(world_state, character_state)
	_expect_text_contains(outpost_prompt, "Demo 成果整理", "S22 outpost core shows outcome review")
	_expect_text_contains(outpost_prompt, "守卫缓存已归档", "S22 outpost core keeps guard evidence")


func _check_completed_review_save_roundtrip() -> void:
	var checkpoint := _create_baseline("baseline.s22_demo_completion_outpost_review")
	if checkpoint.is_empty():
		return
	var world_state: WorldState = checkpoint.get("world_state", null)
	var character_state: CharacterState = checkpoint.get("character_state", null)

	save_service.delete_game_for_slot(SLOT_ID)
	_expect_success(
		save_service.save_game_for_slot(SLOT_ID, world_state, character_state),
		"S22 completion review save"
	)
	if not FileAccess.file_exists(SLOT_SAVE_FILE):
		failures.append("S22 completion review should write a slot save file")

	var load_result := save_service.load_game_for_slot(SLOT_ID)
	_expect_success(load_result, "S22 completion review load")
	if not bool(load_result.get("success", false)):
		return

	var loaded_world: WorldState = load_result.get("world_state", null)
	var loaded_character: CharacterState = load_result.get("character_state", null)
	if loaded_world == null or loaded_character == null:
		failures.append("S22 completion review load should return world and character states")
		return

	_expect_equal(loaded_world.current_region_id, OUTPOST_REGION_ID, "S22 loaded world remains at outpost")
	_expect_equal(loaded_character.current_region_id, OUTPOST_REGION_ID, "S22 loaded character remains at outpost")
	_expect_array_has(
		loaded_world.quest_state.completed_quest_ids,
		"quest.write_demo_stabilization_core",
		"S22 loaded save keeps demo completion"
	)
	_expect_equal(loaded_world.quest_state.active_quest_ids.is_empty(), true, "S22 loaded save has no required quest")
	_expect_equal(
		bool(loaded_world.get_map_object("map_object_instance.demo_stabilization_core").get("is_sampled", false)),
		true,
		"S22 loaded save keeps core write object state"
	)
	_expect_equal(
		FieldOutfittingRuntime.has_active_field_loop_payoff(loaded_character, loaded_world),
		true,
		"S22 loaded save keeps field loop payoff"
	)
	var status_text := HudStatusPresenter.new().format_status_text(data_registry, loaded_world, loaded_character)
	_expect_text_contains(status_text, "Demo 成果", "S22 loaded HUD keeps outcome summary")
	save_service.delete_game_for_slot(SLOT_ID)


func _create_baseline(baseline_id: String) -> Dictionary:
	var result := baseline_builder.create_baseline_state(baseline_id)
	_expect_success(result, "%s baseline" % baseline_id)
	if not bool(result.get("success", false)):
		return {}
	var world_state: WorldState = result.get("world_state", null)
	var character_state: CharacterState = result.get("character_state", null)
	if world_state == null or character_state == null:
		failures.append("%s should return world and character states" % baseline_id)
		return {}
	return result


func _create_map_presenter() -> HudMapPresenter:
	var presenter := HudMapPresenter.new()
	presenter.target_region_resolver = QuestTargetRegionResolver.new(data_registry)
	return presenter


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


func _get_first_active_quest_id(world_state: WorldState) -> String:
	if world_state.quest_state.active_quest_ids.is_empty():
		return ""
	return String(world_state.quest_state.active_quest_ids[0])


func _get_display_name(definition_id: String) -> String:
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id
	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))


func _expect_success(result: Dictionary, message: String) -> void:
	if bool(result.get("success", false)):
		return
	failures.append("%s should succeed, got %s" % [message, var_to_str(result)])


func _expect_array_has(values: Array, expected, message: String) -> void:
	if values.has(expected):
		return
	failures.append("%s: missing %s in %s" % [message, str(expected), var_to_str(values)])


func _expect_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return
	failures.append("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _expect_text_contains(text: String, expected: String, message: String) -> void:
	if text.contains(expected):
		return
	failures.append("%s: missing '%s' in '%s'" % [message, expected, text])


func _cleanup() -> void:
	save_service.delete_game_for_slot(SLOT_ID)
	data_registry.free()
