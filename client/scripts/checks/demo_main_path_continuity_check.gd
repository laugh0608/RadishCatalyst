extends SceneTree

const OUTPOST_REGION_ID := "region.outpost_platform"
const CORE_REGION_ID := "region.demo_stabilization_core"
const TETHER_REGION_ID := "region.phase_well_tether"
const CORE_BUFFER_RECIPE_ID := "recipe.core_stabilization_buffer"
const CLEANSE_RECIPE_ID := "recipe.cleanse_residue"
const CORE_GUARD_ID := "enemy.demo_stabilization_guard"
const CORE_GUARD_INSTANCE_ID := "enemy_instance.demo_stabilization_guard"

var failures: Array[String] = []
var data_registry := DataRegistry.new()
var baseline_builder: DevelopmentBaselineBuilder
var quest_runtime: QuestRuntime
var processing_system: ProcessingSystem
var counterattack_runtime: EnemyCounterattackRuntime


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		baseline_builder = DevelopmentBaselineBuilder.new(data_registry)
		quest_runtime = QuestRuntime.new(data_registry)
		processing_system = ProcessingSystem.new(data_registry)
		counterattack_runtime = EnemyCounterattackRuntime.new(data_registry)
		_run_checks()

	if failures.is_empty():
		print("Demo main path continuity checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_baseline_main_path_milestones()
	_check_s21_to_demo_completion_path()


func _check_baseline_main_path_milestones() -> void:
	for milestone in _get_main_path_milestones():
		var baseline_id := String(milestone.get("baseline_id", ""))
		var baseline_result := baseline_builder.create_baseline_state(baseline_id)
		_expect_success(baseline_result, "%s creates baseline state" % baseline_id)
		if not bool(baseline_result.get("success", false)):
			continue

		var world_state: WorldState = baseline_result.get("world_state", null)
		var character_state: CharacterState = baseline_result.get("character_state", null)
		if world_state == null or character_state == null:
			failures.append("%s should return world and character states" % baseline_id)
			continue

		var expected_region_id := String(milestone.get("region_id", ""))
		if not expected_region_id.is_empty():
			_expect_equal(world_state.current_region_id, expected_region_id, "%s world region" % baseline_id)
			_expect_equal(character_state.current_region_id, expected_region_id, "%s character region" % baseline_id)

		for completed_quest_id in milestone.get("completed_quest_ids", []):
			_expect_array_has(
				world_state.quest_state.completed_quest_ids,
				String(completed_quest_id),
				"%s completed quest %s" % [baseline_id, String(completed_quest_id)]
			)

		for active_quest_id in milestone.get("active_quest_ids", []):
			_expect_array_has(
				world_state.quest_state.active_quest_ids,
				String(active_quest_id),
				"%s active quest %s" % [baseline_id, String(active_quest_id)]
			)

		for unlocked_region_id in milestone.get("unlocked_region_ids", []):
			_expect_array_has(
				world_state.unlocked_region_ids,
				String(unlocked_region_id),
				"%s unlocked region %s" % [baseline_id, String(unlocked_region_id)]
			)

		for inventory_ref in milestone.get("inventory_refs", []):
			_expect_inventory_has(
				character_state,
				String(inventory_ref),
				"%s inventory ref %s" % [baseline_id, String(inventory_ref)]
			)

		for building_id in milestone.get("building_ids", []):
			_expect_equal(
				world_state.has_base_structure_definition(String(building_id)),
				true,
				"%s base building %s" % [baseline_id, String(building_id)]
			)

		var active_anchor_id := String(milestone.get("active_anchor_id", ""))
		if not active_anchor_id.is_empty():
			_expect_equal(world_state.is_active_phase_relay_anchor(active_anchor_id), true, "%s active anchor" % baseline_id)

		var status_text := HudStatusPresenter.new().format_status_text(data_registry, world_state, character_state)
		_expect_text_contains(status_text, "当前目标", "%s HUD has current objective section" % baseline_id)
		_expect_text_contains(status_text, "关键资源", "%s HUD has key resource section" % baseline_id)
		if not bool(milestone.get("skip_active_quest_hud_names", false)):
			for active_quest_id in milestone.get("active_quest_ids", []):
				_expect_text_contains(
					status_text,
					_get_display_name(String(active_quest_id)),
					"%s HUD names active quest %s" % [baseline_id, String(active_quest_id)]
				)
		for expected_status_text in milestone.get("status_texts", []):
			_expect_text_contains(
				status_text,
				String(expected_status_text),
				"%s HUD includes %s" % [baseline_id, String(expected_status_text)]
			)

		var route_title := HudMapPresenter.new().format_demo_route_title(world_state, _get_first_active_quest_id(world_state))
		_expect_text_contains(
			route_title,
			String(milestone.get("route_stage", "")),
			"%s route title names current route stage" % baseline_id
		)


func _check_s21_to_demo_completion_path() -> void:
	var baseline_result := baseline_builder.create_baseline_state("baseline.s21_demo_stabilization_core_ready")
	_expect_success(baseline_result, "S21 baseline creates demo core entry state")
	if not bool(baseline_result.get("success", false)):
		return

	var world_state: WorldState = baseline_result.get("world_state", null)
	var character_state: CharacterState = baseline_result.get("character_state", null)
	if world_state == null or character_state == null:
		failures.append("S21 baseline should return world and character states")
		return

	_enter_demo_stabilization_core(world_state, character_state)
	_complete_core_buffer_preparation(world_state, character_state)
	_apply_guard_pressure_and_complete_guard(world_state, character_state)
	_complete_core_write(world_state, character_state)
	_check_completed_demo_readout(world_state, character_state)


func _enter_demo_stabilization_core(world_state: WorldState, character_state: CharacterState) -> void:
	world_state.current_region_id = CORE_REGION_ID
	character_state.current_region_id = CORE_REGION_ID
	world_state.unlock_region(CORE_REGION_ID)
	var result := quest_runtime.advance_for_region(world_state, character_state, CORE_REGION_ID)
	_expect_array_has(
		world_state.quest_state.completed_quest_ids,
		"quest.enter_demo_stabilization_core",
		"entering demo core completes entry quest"
	)
	_expect_array_has(
		world_state.quest_state.active_quest_ids,
		"quest.prepare_demo_stabilization_buffer",
		"entering demo core activates buffer preparation"
	)
	_expect_array_has(
		world_state.quest_state.unlocked_effects,
		CORE_BUFFER_RECIPE_ID,
		"entering demo core unlocks core buffer recipe"
	)
	_expect_completion_feedback_count(result, 1, "entering demo core emits completion feedback")
	var status_text := HudStatusPresenter.new().format_status_text(data_registry, world_state, character_state)
	_expect_text_contains(status_text, _get_display_name("quest.prepare_demo_stabilization_buffer"), "entry HUD points to buffer preparation")
	var route_hint := HudMapPresenter.new().format_demo_route_hint(world_state, "quest.prepare_demo_stabilization_buffer")
	_expect_text_contains(route_hint, "核心稳定站", "entry route keeps core station stage readable")


func _complete_core_buffer_preparation(world_state: WorldState, character_state: CharacterState) -> void:
	var gather_system := GatherSystem.new(data_registry)
	var residue_result := gather_system.interact_with_object(
		"map_object_instance.core_buffer_residue_cache",
		"map_object.pollution_residue_patch",
		"gather",
		character_state,
		world_state
	)
	_expect_success(residue_result, "core buffer residue cache gather")
	quest_runtime.advance_for_interaction(
		world_state,
		character_state,
		{"definition_id": "map_object.pollution_residue_patch", "interaction_type": "gather"},
		residue_result
	)
	quest_runtime.advance_for_defeated_enemy(world_state, character_state, "enemy.polluted_skitter")

	world_state.add_base_structure("structure.pollution_filter_build_site", "building.pollution_filter", "region.pollution_edge")
	world_state.add_base_structure("structure.basic_reactor", "building.basic_reactor", OUTPOST_REGION_ID)
	world_state.quest_state.unlock_effect(CLEANSE_RECIPE_ID)
	world_state.quest_state.unlock_effect(CORE_BUFFER_RECIPE_ID)
	if not character_state.inventory.has_ref("fluid.basic_solvent", 1):
		character_state.inventory.add_fluid("fluid.basic_solvent", 1.0)
	if not character_state.inventory.has_ref("item.repair_gel", 1):
		character_state.inventory.add_item("item.repair_gel", 1)
	if not character_state.inventory.has_ref("item.basic_parts", 2):
		character_state.inventory.add_item("item.basic_parts", 2)

	var cleanse_start := processing_system.process_recipe(CLEANSE_RECIPE_ID, character_state, world_state)
	_expect_success(cleanse_start, "polluted residue can be filtered for core buffer")
	processing_system.advance_processing(13.0, character_state, world_state)

	if not character_state.inventory.has_ref("item.repair_gel", 1):
		character_state.inventory.add_item("item.repair_gel", 1)
	if not character_state.inventory.has_ref("item.basic_parts", 2):
		character_state.inventory.add_item("item.basic_parts", 2)
	var buffer_start := processing_system.process_recipe(CORE_BUFFER_RECIPE_ID, character_state, world_state)
	_expect_success(buffer_start, "core stabilization buffer can be processed")
	var completed_results := processing_system.advance_processing(8.0, character_state, world_state)
	if completed_results.is_empty():
		failures.append("core stabilization buffer processing should complete")
		return

	var recipe_result: Dictionary = completed_results[0]
	var quest_result := quest_runtime.advance_for_interaction(
		world_state,
		character_state,
		{"interaction_type": "process_recipe", "recipe_id": CORE_BUFFER_RECIPE_ID},
		recipe_result
	)
	_expect_array_has(
		world_state.quest_state.completed_quest_ids,
		"quest.prepare_demo_stabilization_buffer",
		"buffer preparation quest completes after real processing"
	)
	_expect_array_has(
		world_state.quest_state.active_quest_ids,
		"quest.defeat_demo_stabilization_guard",
		"buffer preparation activates guard quest"
	)
	_expect_completion_feedback_count(quest_result, 1, "buffer preparation emits completion feedback")
	_expect_inventory_has(character_state, "item.core_stabilization_buffer", "buffer remains available for guard pressure")


func _apply_guard_pressure_and_complete_guard(world_state: WorldState, character_state: CharacterState) -> void:
	var guard := PrototypeEnemy.new()
	var guard_definition := data_registry.get_definition(CORE_GUARD_ID)
	var max_health := float(guard_definition.get("base_stats", {}).get("max_health", 156.0))
	guard.definition_id = CORE_GUARD_ID
	guard.instance_id = CORE_GUARD_INSTANCE_ID
	guard.display_name = _get_display_name(CORE_GUARD_ID)
	guard.max_health = max_health
	guard.health = max_health
	world_state.ensure_enemy(CORE_GUARD_INSTANCE_ID, CORE_GUARD_ID, CORE_REGION_ID, max_health)
	var buffer_before := int(character_state.inventory.items.get("item.core_stabilization_buffer", 0))
	counterattack_runtime.apply(guard, character_state, world_state, CORE_REGION_ID)
	_expect_equal(
		bool(world_state.get_enemy(CORE_GUARD_INSTANCE_ID).get("core_buffer_used", false)),
		true,
		"core guard consumes and records the stabilization buffer"
	)
	_expect_equal(
		int(character_state.inventory.items.get("item.core_stabilization_buffer", 0)),
		maxi(0, buffer_before - 1),
		"core guard pressure consumes one buffer"
	)
	guard.free()
	world_state.update_enemy_health(CORE_GUARD_INSTANCE_ID, 0.0, true)

	var quest_result := quest_runtime.advance_for_defeated_enemy(world_state, character_state, CORE_GUARD_ID)
	_expect_array_has(
		world_state.quest_state.completed_quest_ids,
		"quest.defeat_demo_stabilization_guard",
		"defeating demo guard completes guard quest"
	)
	_expect_array_has(
		world_state.quest_state.active_quest_ids,
		"quest.write_demo_stabilization_core",
		"defeating demo guard activates core write quest"
	)
	_expect_completion_feedback_count(quest_result, 1, "guard defeat emits completion feedback")
	var status_text := HudStatusPresenter.new().format_status_text(data_registry, world_state, character_state)
	_expect_text_contains(status_text, _get_display_name("quest.write_demo_stabilization_core"), "guard defeat HUD points to core write")


func _complete_core_write(world_state: WorldState, character_state: CharacterState) -> void:
	var gather_system := GatherSystem.new(data_registry)
	var guard_cache_result := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_guard_cache",
		"map_object.demo_stabilization_guard_cache",
		"gather",
		character_state,
		world_state
	)
	_expect_success(guard_cache_result, "demo guard cache gather")
	var cache_quest_result := quest_runtime.advance_for_interaction(
		world_state,
		character_state,
		{"definition_id": "map_object.demo_stabilization_guard_cache", "interaction_type": "gather"},
		guard_cache_result
	)
	_expect_equal(
		world_state.quest_state.get_objective_progress(
			"quest.write_demo_stabilization_core",
			"gather_item",
			"item.core_write_charge"
		),
		1.0,
		"guard cache advances core write charge objective"
	)
	if cache_quest_result.is_empty():
		failures.append("guard cache interaction should return a quest runtime result")

	var core_write_result := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"inspect",
		character_state,
		world_state
	)
	_expect_success(core_write_result, "demo stabilization core write")
	_expect_text_contains(String(core_write_result.get("message", "")), "核心稳定数据已写入", "core write interaction writes stable data")
	var quest_result := quest_runtime.advance_for_interaction(
		world_state,
		character_state,
		{"definition_id": "map_object.demo_stabilization_core", "interaction_type": "inspect"},
		core_write_result
	)
	_expect_array_has(
		world_state.quest_state.completed_quest_ids,
		"quest.write_demo_stabilization_core",
		"core write completes demo main path"
	)
	_expect_array_has(
		world_state.quest_state.unlocked_effects,
		"slice_01_complete",
		"core write records slice completion effect"
	)
	_expect_completion_feedback_count(quest_result, 1, "core write emits demo completion feedback")
	var feedbacks: Array = quest_result.get("completion_feedbacks", [])
	if feedbacks.is_empty():
		return
	var feedback = feedbacks[0]
	if not feedback is Dictionary:
		failures.append("core write feedback should be a dictionary")
		return
	_expect_equal(String(feedback.get("panel_title", "")), "Demo 完成", "core write feedback uses demo completion panel")
	_expect_text_contains(String(feedback.get("note_text", "")), "首版 Demo 主线目标已完成", "core write feedback explains demo completion")


func _check_completed_demo_readout(world_state: WorldState, character_state: CharacterState) -> void:
	var status_text := HudStatusPresenter.new().format_status_text(data_registry, world_state, character_state)
	_expect_text_contains(status_text, "首版 Demo 主线已完成", "completed HUD names demo mainline completion")
	var route_hint := HudMapPresenter.new().format_demo_route_hint(world_state, "")
	_expect_text_contains(route_hint, "Demo 终点已完成", "completed map route names demo endpoint completion")
	_expect_equal(world_state.quest_state.active_quest_ids.is_empty(), true, "demo completion leaves no required follow-up quest")


func _get_main_path_milestones() -> Array[Dictionary]:
	return [
		{
			"baseline_id": "baseline.s0_new_game",
			"region_id": OUTPOST_REGION_ID,
			"active_quest_ids": ["quest.restore_outpost"],
			"route_stage": "基地整备"
		},
		{
			"baseline_id": "baseline.s1_treatment_ready",
			"region_id": OUTPOST_REGION_ID,
			"completed_quest_ids": ["quest.expand_treatment_point"],
			"active_quest_ids": ["quest.enter_pollution_edge"],
			"building_ids": ["building.pollution_filter"],
			"route_stage": "基地整备"
		},
		{
			"baseline_id": "baseline.s2_outer_ring_secured",
			"region_id": "region.ruin_outer_ring",
			"completed_quest_ids": ["quest.secure_outer_ring_signal"],
			"active_quest_ids": ["quest.salvage_signal_echo"],
			"route_stage": "遗迹外圈"
		},
		{
			"baseline_id": "baseline.s5_phase_relay_online",
			"region_id": OUTPOST_REGION_ID,
			"completed_quest_ids": ["quest.deploy_phase_relay_anchor"],
			"active_quest_ids": ["quest.reenter_phase_frontline"],
			"active_anchor_id": "map_object_instance.phase_return_anchor",
			"route_stage": "基地整备"
		},
		{
			"baseline_id": "baseline.s13_phase_well_anchor_core_ready",
			"region_id": OUTPOST_REGION_ID,
			"completed_quest_ids": ["quest.inspect_phase_well_tether"],
			"active_quest_ids": ["quest.analyze_phase_well_anchor_core"],
			"inventory_refs": ["item.phase_well_anchor_core"],
			"active_anchor_id": "map_object_instance.phase_return_anchor_chamber",
			"route_stage": "基地整备"
		},
		{
			"baseline_id": "baseline.s19_route_action_feedback_ready",
			"region_id": OUTPOST_REGION_ID,
			"completed_quest_ids": ["quest.analyze_route_signal_trace"],
			"active_quest_ids": [
				"quest.choose_steady_supply_action",
				"quest.choose_phase_survey_action",
				"quest.choose_pressure_clearance_action"
			],
			"inventory_refs": ["item.route_action_feedback"],
			"active_anchor_id": "map_object_instance.phase_return_anchor_tether",
			"route_stage": "基地整备",
			"skip_active_quest_hud_names": true,
			"status_texts": ["基地行动方案待选择", "稳场补给", "相位测绘", "压力清障"]
		},
		{
			"baseline_id": "baseline.s21_demo_stabilization_core_ready",
			"region_id": TETHER_REGION_ID,
			"completed_quest_ids": ["quest.analyze_phase_survey_trace"],
			"active_quest_ids": ["quest.enter_demo_stabilization_core"],
			"unlocked_region_ids": [CORE_REGION_ID],
			"inventory_refs": ["item.phase_survey_feedback"],
			"active_anchor_id": "map_object_instance.phase_return_anchor_tether",
			"route_stage": "深段推进"
		}
	]


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


func _expect_completion_feedback_count(result: Dictionary, expected_count: int, message: String) -> void:
	var feedbacks: Array = result.get("completion_feedbacks", [])
	_expect_equal(feedbacks.size(), expected_count, message)


func _expect_inventory_has(character_state: CharacterState, definition_id: String, message: String) -> void:
	if character_state.inventory.has_ref(definition_id, 1):
		return
	failures.append("%s: inventory missing %s" % [message, definition_id])


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
	data_registry.free()
