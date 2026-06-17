extends SceneTree

const CompletionOutcomeFormatter := preload("res://scripts/systems/demo_completion_outcome_formatter.gd")

var failures: Array[String] = []
var data_registry := DataRegistry.new()


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		_run_checks()

	if failures.is_empty():
		print("Demo completion outcome readout checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_hud_map_and_outpost_outcome()
	_check_core_device_and_completion_log_outcome()
	_check_completion_outcome_boundaries()


func _check_hud_map_and_outpost_outcome() -> void:
	var world := _create_completed_world("region.outpost_platform")
	var character := _create_completed_character("region.outpost_platform")

	var status_text := HudStatusPresenter.new().format_status_text(data_registry, world, character)
	_expect_text_contains(status_text, "Demo 成果", "HUD shows completion outcome")
	_expect_text_contains(status_text, "核心稳定通道已打开", "HUD names stabilized route")
	_expect_text_contains(status_text, "整备成果：模块校准 / 外勤收益整备已接入", "HUD includes outfitting outcome")
	_expect_text_contains(status_text, "成果整理", "HUD shows outpost review line")

	var map_hint := HudMapPresenter.new().format_demo_route_hint(world, "")
	_expect_text_contains(map_hint, "Demo 终点已完成", "map keeps demo completion")
	_expect_text_contains(map_hint, "前哨已收到核心写入", "map names outpost archive")
	_expect_text_contains(map_hint, "核心设备完成态可复测", "map exposes completion review")

	var formatter := InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)
	var outpost_prompt := formatter.format_outpost_core_prompt(world, character)
	_expect_text_contains(outpost_prompt, "Demo 成果整理", "outpost prompt shows completion outcome")
	_expect_text_contains(outpost_prompt, "守卫缓存已归档", "outpost prompt keeps terminal evidence")
	_expect_text_contains(outpost_prompt, "成果整理", "outpost prompt keeps review line")


func _check_core_device_and_completion_log_outcome() -> void:
	var world := _create_completed_world("region.demo_stabilization_core")
	var character := _create_completed_character("region.demo_stabilization_core")
	var formatter := InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)

	var core := PrototypeInteractable.new()
	core.instance_id = "map_object_instance.demo_stabilization_core"
	core.definition_id = "map_object.demo_stabilization_core"
	core.interaction_type = "inspect"
	core.single_use = false
	var core_prompt := formatter.format_general_interaction_prompt(core, character, world)
	_expect_text_contains(core_prompt, "成果整理", "core prompt shows completion outcome")
	_expect_text_contains(core_prompt, "守卫战记录", "core prompt keeps battle evidence")
	_expect_text_contains(core_prompt, "回前哨核心，整理补给、整备收益和复测读数", "core prompt points back to outpost")
	core.free()

	var completion := QuestCompletionApplier.new(data_registry).apply_completion(
		world,
		character,
		{
			"completed": true,
			"quest_id": "quest.write_demo_stabilization_core",
			"rewards": [],
			"unlock_effects": [],
			"next_quest_ids": []
		}
	)
	var log_message := String(completion.get("log_message", ""))
	_expect_text_contains(log_message, "首版 Demo 主线目标已完成", "completion log names demo completion")
	_expect_text_contains(log_message, "核心稳定通道已打开", "completion log names outcome")
	_expect_text_contains(log_message, "不新增必需后续任务", "completion log keeps scope boundary")


func _check_completion_outcome_boundaries() -> void:
	var early_world := WorldState.create_default()
	var early_character := CharacterState.create_default()
	_expect_equal(
		CompletionOutcomeFormatter.format_hud_summary(early_world, early_character).is_empty(),
		true,
		"completion outcome hides before demo completion"
	)
	var completed_world := _create_completed_world("region.outpost_platform")
	var completed_character := _create_completed_character("region.outpost_platform")
	_expect_equal(
		DemoEndpointReadinessFormatter.format_hud_summary(completed_world, completed_character).is_empty(),
		true,
		"endpoint readiness stays hidden after completion"
	)


func _create_completed_world(region_id: String) -> WorldState:
	var world := WorldState.create_default()
	world.current_region_id = region_id
	for quest_id in [
		"quest.restore_outpost",
		"quest.enter_demo_stabilization_core",
		"quest.prepare_demo_stabilization_buffer",
		"quest.defeat_demo_stabilization_guard",
		"quest.write_demo_stabilization_core",
	]:
		world.quest_state.complete_quest(quest_id)
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
	world.ensure_enemy(
		"enemy_instance.demo_stabilization_guard",
		"enemy.demo_stabilization_guard",
		"region.demo_stabilization_core",
		156.0
	)
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
	)["is_sampled"] = true
	var outfitting_site := world.ensure_map_object(
		"map_object_instance.field_outfitting_station_build_site",
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		"region.outpost_platform"
	)
	outfitting_site["is_built"] = true
	outfitting_site["built_definition_id"] = FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID
	FieldOutfittingRuntime.mark_module_calibrated(world)
	DemoFieldLoopPayoffFormatter.mark_payoff_confirmed(world)
	return world


func _create_completed_character(region_id: String) -> CharacterState:
	var character := CharacterState.create_default()
	character.current_region_id = region_id
	character.inventory.add_item("item.repair_gel", 1)
	character.inventory.add_item("item.resistance_vial_t1", 1)
	character.inventory.add_item("item.core_write_charge", 1)
	character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	return character


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
