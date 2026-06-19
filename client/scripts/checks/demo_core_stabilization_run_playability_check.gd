extends SceneTree

const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")

var failures: Array[String] = []
var data_registry := DataRegistry.new()


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		_run_checks()

	if failures.is_empty():
		print("Demo core stabilization run playability checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_formatter_tracks_core_station_run()
	_check_scene_layer_marks_core_station_run()
	_check_hud_and_map_show_core_station_run()
	_check_object_prompts_show_core_station_run()
	_check_results_show_core_station_run_followup()


func _check_formatter_tracks_core_station_run() -> void:
	_expect_text_contains(
		DemoCoreStabilizationRunFormatter.get_run_sequence_text(),
		"入口确认 -> 侧边补给 -> 稳压缓冲包 -> 阶段守卫 -> 回写缓存 -> 核心写入",
		"formatter exposes core station sequence"
	)
	_expect_array_has(
		DemoCoreStabilizationRunFormatter.get_core_object_definition_ids(),
		"map_object.demo_stabilization_recovery_cache",
		"formatter covers recovery cache"
	)
	_expect_array_has(
		DemoCoreStabilizationRunFormatter.get_core_object_definition_ids(),
		"map_object.demo_stabilization_guard_cache",
		"formatter covers guard cache"
	)
	_expect_array_has(
		DemoCoreStabilizationRunFormatter.get_core_object_definition_ids(),
		"map_object.demo_stabilization_core",
		"formatter covers core device"
	)

	var world := _create_core_entry_world()
	var character := _create_core_character()
	_expect_equal(
		DemoCoreStabilizationRunFormatter.format_current_stage(world, character),
		"入口确认",
		"entry world starts at core station entry"
	)
	world.quest_state.complete_quest("quest.enter_demo_stabilization_core")
	character.inventory.add_item("item.core_stabilization_buffer", 1)
	_expect_equal(
		DemoCoreStabilizationRunFormatter.format_current_stage(world, character),
		"稳压缓冲包回站",
		"buffer in inventory points back to core station"
	)
	world.quest_state.complete_quest("quest.prepare_demo_stabilization_buffer")
	_expect_equal(
		DemoCoreStabilizationRunFormatter.format_current_stage(world, character),
		"侧边补给",
		"buffer quest completion points to side supply before guard"
	)


func _check_scene_layer_marks_core_station_run() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node("CoreStabilizationRunLayer") as Node2D
	var entry := map.get_node("CoreStabilizationRunLayer/CoreRunEntryCheck") as ColorRect
	var side_supply := map.get_node("CoreStabilizationRunLayer/CoreRunSideSupply") as ColorRect
	var guard_field := map.get_node("CoreStabilizationRunLayer/CoreRunGuardField") as ColorRect
	var guard_cache := map.get_node("CoreStabilizationRunLayer/CoreRunGuardCache") as ColorRect
	var write_pad := map.get_node("CoreStabilizationRunLayer/CoreRunWritePad") as ColorRect

	_expect_equal(layer != null, true, "core station run scene layer exists")
	for marker in [entry, side_supply, guard_field, guard_cache, write_pad]:
		_expect_equal(
			marker.offset_left >= VerticalSliceMap.DEMO_STABILIZATION_CORE_REGION_X,
			true,
			"%s stays inside demo stabilization core" % marker.name
		)
		_expect_equal(marker.color.a > 0.35, true, "%s has visible alpha" % marker.name)
	_expect_equal(
		entry.offset_left < side_supply.offset_left
			and side_supply.offset_left < guard_field.offset_left
			and guard_field.offset_left < write_pad.offset_left,
		true,
		"core station run markers preserve operation order"
	)
	map.free()


func _check_hud_and_map_show_core_station_run() -> void:
	var world := _create_guard_ready_world()
	var character := _create_core_character()
	character.inventory.add_item("item.core_stabilization_buffer", 1)

	var vitals_text := HudStatusPresenter.new().format_vitals_text(data_registry, world, character)
	_expect_text_contains(vitals_text, "核心站内路径", "HUD shows core station run")
	_expect_text_contains(vitals_text, "当前段：侧边补给", "HUD points to side supply before guard")
	_expect_text_contains(vitals_text, "站内状态", "HUD summarizes station state")

	var map_hint := HudMapPresenter.new().format_demo_route_hint(world, "quest.defeat_demo_stabilization_guard", character)
	_expect_text_contains(map_hint, "核心站内路径", "map route hint shows core station run")
	_expect_text_contains(map_hint, "侧边补给", "map route hint points to side supply")


func _check_object_prompts_show_core_station_run() -> void:
	var world := _create_guard_ready_world()
	var character := _create_core_character()
	character.inventory.add_item("item.core_stabilization_buffer", 1)
	var formatter := InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)

	var recovery_cache := _create_interactable(
		"map_object_instance.demo_stabilization_recovery_cache",
		"map_object.demo_stabilization_recovery_cache",
		"gather"
	)
	var recovery_prompt := formatter.format_general_interaction_prompt(recovery_cache, character, world)
	_expect_text_contains(recovery_prompt, "核心站内路径：侧边补给", "recovery cache prompt shows run stage")
	_expect_text_contains(recovery_prompt, "对象职责：守卫战前补给缓存", "recovery cache prompt names role")
	recovery_cache.free()

	world.ensure_enemy("enemy_instance.demo_stabilization_guard", "enemy.demo_stabilization_guard", "region.demo_stabilization_core", 156.0)
	world.update_enemy_health("enemy_instance.demo_stabilization_guard", 0.0, true)
	world.quest_state.complete_quest("quest.defeat_demo_stabilization_guard")
	var guard_cache := _create_interactable(
		"map_object_instance.demo_stabilization_guard_cache",
		"map_object.demo_stabilization_guard_cache",
		"gather"
	)
	var guard_prompt := formatter.format_general_interaction_prompt(guard_cache, character, world)
	_expect_text_contains(guard_prompt, "核心站内路径：回写缓存", "guard cache prompt shows run stage")
	_expect_text_contains(guard_prompt, "状态：待回收", "guard cache prompt waits for recovery")
	guard_cache.free()

	world.set_map_object_flag("map_object_instance.demo_stabilization_guard_cache", "is_gathered", true)
	world.quest_state.active_quest_ids = ["quest.write_demo_stabilization_core"]
	world.quest_state.set_objective_progress("quest.write_demo_stabilization_core", "gather_item", "item.core_write_charge", 1.0)
	character.inventory.add_item("item.core_write_charge", 1)
	var core_device := _create_interactable(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"inspect"
	)
	var core_prompt := formatter.format_general_interaction_prompt(core_device, character, world)
	_expect_text_contains(core_prompt, "核心站内路径：核心写入", "core device prompt shows write stage")
	_expect_text_contains(core_prompt, "状态：可写入", "core device prompt shows write readiness")
	core_device.free()


func _check_results_show_core_station_run_followup() -> void:
	var gather_system := GatherSystem.new(data_registry)
	var world := _create_guard_ready_world()
	var character := _create_core_character()
	character.inventory.add_item("item.core_stabilization_buffer", 1)
	var recovery_result := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_recovery_cache",
		"map_object.demo_stabilization_recovery_cache",
		"gather",
		character,
		world
	)
	_expect_equal(bool(recovery_result.get("success", false)), true, "recovery cache gather succeeds")
	_expect_text_contains(String(recovery_result.get("message", "")), "核心站内路径：侧边补给已回收", "recovery result shows run followup")

	var defeat_followup := DemoCoreStabilizationRunFormatter.format_guard_defeat_followup(world, character)
	_expect_text_contains(defeat_followup, "阶段守卫已击败", "guard defeat followup names run stage")

	world.ensure_enemy("enemy_instance.demo_stabilization_guard", "enemy.demo_stabilization_guard", "region.demo_stabilization_core", 156.0)
	world.update_enemy_health("enemy_instance.demo_stabilization_guard", 0.0, true)
	world.quest_state.complete_quest("quest.defeat_demo_stabilization_guard")
	var guard_result := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_guard_cache",
		"map_object.demo_stabilization_guard_cache",
		"gather",
		character,
		world
	)
	_expect_equal(bool(guard_result.get("success", false)), true, "guard cache gather succeeds")
	_expect_text_contains(String(guard_result.get("message", "")), "核心站内路径：守卫回写缓存已回收", "guard cache result shows run followup")

	world.quest_state.active_quest_ids = ["quest.write_demo_stabilization_core"]
	world.quest_state.set_objective_progress("quest.write_demo_stabilization_core", "gather_item", "item.core_write_charge", 1.0)
	var core_result := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"inspect",
		character,
		world
	)
	_expect_equal(bool(core_result.get("success", false)), true, "core write interaction succeeds")
	_expect_text_contains(String(core_result.get("message", "")), "核心站内路径：核心写入已完成", "core write result shows run followup")


func _create_core_entry_world() -> WorldState:
	var world := WorldState.create_default()
	world.current_region_id = "region.demo_stabilization_core"
	world.quest_state.complete_quest("quest.calibrate_phase_well_stability_window")
	world.quest_state.activate_quest("quest.enter_demo_stabilization_core")
	_ensure_core_objects(world)
	return world


func _create_guard_ready_world() -> WorldState:
	var world := _create_core_entry_world()
	world.quest_state.complete_quest("quest.enter_demo_stabilization_core")
	world.quest_state.complete_quest("quest.prepare_demo_stabilization_buffer")
	world.quest_state.active_quest_ids = ["quest.defeat_demo_stabilization_guard"]
	return world


func _create_core_character() -> CharacterState:
	var character := CharacterState.create_default()
	character.current_region_id = "region.demo_stabilization_core"
	character.inventory.add_item("item.repair_gel", 1)
	character.inventory.add_item("item.resistance_vial_t1", 1)
	return character


func _ensure_core_objects(world: WorldState) -> void:
	world.ensure_map_object(
		"map_object_instance.demo_stabilization_recovery_cache",
		"map_object.demo_stabilization_recovery_cache",
		"region.demo_stabilization_core"
	)
	world.ensure_map_object(
		"map_object_instance.demo_stabilization_guard_cache",
		"map_object.demo_stabilization_guard_cache",
		"region.demo_stabilization_core"
	)
	world.ensure_map_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"region.demo_stabilization_core"
	)


func _create_interactable(instance_id: String, definition_id: String, interaction_type: String) -> PrototypeInteractable:
	var interactable := PrototypeInteractable.new()
	interactable.instance_id = instance_id
	interactable.definition_id = definition_id
	interactable.interaction_type = interaction_type
	return interactable


func _expect_equal(actual, expected, context: String) -> void:
	if actual == expected:
		return
	failures.append("%s: expected %s, got %s" % [context, str(expected), str(actual)])


func _expect_array_has(values: Array, expected, context: String) -> void:
	if values.has(expected):
		return
	failures.append("%s: expected array to contain %s, got %s" % [context, expected, str(values)])


func _expect_text_contains(text: String, expected: String, context: String) -> void:
	if text.find(expected) >= 0:
		return
	failures.append("%s: expected text to contain '%s', got '%s'" % [context, expected, text])


func _cleanup() -> void:
	data_registry.free()
