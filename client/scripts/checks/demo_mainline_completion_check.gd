extends SceneTree

var failures: Array[String] = []
var data_registry := DataRegistry.new()


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		_run_checks()

	if failures.is_empty():
		print("Demo mainline completion checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_hud_and_map_completion_readout()
	_check_core_object_and_outpost_prompts()
	_check_completion_log_reuses_mainline_note()


func _check_hud_and_map_completion_readout() -> void:
	var world := _create_completed_world("region.demo_stabilization_core")
	var character := _create_completed_character("region.demo_stabilization_core")

	var status_text := HudStatusPresenter.new().format_status_text(data_registry, world, character)
	_expect_text_contains(status_text, "首版 Demo 主线已完成", "HUD names mainline completion")
	_expect_text_contains(status_text, "核心设备已接管", "HUD progress keeps core takeover state")
	_expect_text_contains(status_text, "压力回看", "HUD keeps core retest pressure details")

	var route_hint := HudMapPresenter.new().format_demo_route_hint(world, "")
	_expect_text_contains(route_hint, "Demo 终点已完成", "map route names demo endpoint completion")
	_expect_text_contains(route_hint, "回前哨整理归档", "map route points completion back to outpost archive")

	world.current_region_id = "region.outpost_platform"
	character.current_region_id = "region.outpost_platform"
	var outpost_status := HudStatusPresenter.new().format_status_text(data_registry, world, character)
	_expect_text_contains(outpost_status, "核心写入已归档", "outpost HUD explains archive value")
	_expect_text_contains(outpost_status, "前哨补给和模块整备", "outpost HUD keeps outfitting value")
	var outpost_route_hint := HudMapPresenter.new().format_demo_route_hint(world, "")
	_expect_text_contains(outpost_route_hint, "前哨已收到核心写入", "outpost map route names archived core write")


func _check_core_object_and_outpost_prompts() -> void:
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
	_expect_text_contains(core_prompt, "Demo 终点已完成", "core object status names demo completion")
	_expect_text_contains(core_prompt, "守卫缓存已归档", "core object status keeps combat evidence")
	_expect_text_contains(core_prompt, "回前哨核心", "core object next step points to outpost core")
	_expect_text_contains(core_prompt, "复测核心稳定设备", "core object action stays operable")
	core.free()
	core = null

	world.current_region_id = "region.outpost_platform"
	character.current_region_id = "region.outpost_platform"
	character.health = 64.0
	character.protection = 58.0
	var outpost_prompt := formatter.format_outpost_core_prompt(world, character)
	_expect_text_contains(outpost_prompt, "Demo 完成：核心写入已归档", "outpost core prompt names demo completion")
	_expect_text_contains(outpost_prompt, "恢复生命 / 防护", "outpost core prompt keeps refit value")
	_expect_text_contains(outpost_prompt, "复测整备收益", "outpost core prompt explains completion retest value")
	formatter = null


func _check_completion_log_reuses_mainline_note() -> void:
	var world := _create_completed_world("region.outpost_platform")
	var character := _create_completed_character("region.outpost_platform")
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
	_expect_equal(String(completion.get("panel_title", "")), "Demo 完成", "completion panel title names demo completion")
	var log_message := String(completion.get("log_message", ""))
	_expect_text_contains(log_message, "首版 Demo 主线目标已完成", "completion log names mainline completion")
	_expect_text_contains(log_message, "回前哨可整理补给、整备和复测记录", "completion log points to archive value")


func _create_completed_world(region_id: String) -> WorldState:
	var world := WorldState.create_default()
	world.current_region_id = region_id
	world.quest_state.complete_quest("quest.restore_outpost")
	world.quest_state.complete_quest("quest.enter_demo_stabilization_core")
	world.quest_state.complete_quest("quest.prepare_demo_stabilization_buffer")
	world.quest_state.complete_quest("quest.defeat_demo_stabilization_guard")
	world.quest_state.complete_quest("quest.write_demo_stabilization_core")
	world.add_base_structure(
		"structure.basic_storage_build_site",
		"building.basic_storage",
		"region.outpost_platform",
		"map_object_instance.basic_storage_build_site"
	)
	world.add_base_structure(
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.outpost_platform",
		"map_object_instance.pollution_filter_build_site"
	)
	world.add_base_structure(
		"structure.field_outfitting_station_build_site",
		"building.field_outfitting_station",
		"region.outpost_platform",
		"map_object_instance.field_outfitting_station_build_site"
	)
	world.ensure_enemy(
		"enemy_instance.demo_stabilization_guard",
		"enemy.demo_stabilization_guard",
		"region.demo_stabilization_core",
		156.0
	)
	world.get_enemy("enemy_instance.demo_stabilization_guard")["core_buffer_used"] = true
	world.ensure_map_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"region.demo_stabilization_core"
	)
	world.set_map_object_flag("map_object_instance.demo_stabilization_core", "is_sampled", true)
	world.ensure_map_object(
		"map_object_instance.demo_stabilization_recovery_cache",
		"map_object.demo_stabilization_recovery_cache",
		"region.demo_stabilization_core"
	)
	world.set_map_object_flag("map_object_instance.demo_stabilization_recovery_cache", "is_gathered", true)
	world.ensure_map_object(
		"map_object_instance.demo_stabilization_guard_cache",
		"map_object.demo_stabilization_guard_cache",
		"region.demo_stabilization_core"
	)
	world.set_map_object_flag("map_object_instance.demo_stabilization_guard_cache", "is_gathered", true)
	return world


func _create_completed_character(region_id: String) -> CharacterState:
	var character := CharacterState.create_default()
	character.current_region_id = region_id
	character.inventory.add_item("item.repair_gel", 1)
	character.inventory.add_item("item.resistance_vial_t1", 1)
	character.inventory.add_item("item.core_write_charge", 1)
	character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	return character


func _expect_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return
	failures.append("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _expect_text_contains(text: String, expected: String, message: String) -> void:
	if text.contains(expected):
		return
	failures.append("%s: missing '%s' in '%s'" % [message, expected, text])


func _cleanup() -> void:
	data_registry.free()
