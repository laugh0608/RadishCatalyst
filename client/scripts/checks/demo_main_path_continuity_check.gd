extends SceneTree

const OUTPOST_REGION_ID := "region.outpost_platform"
const POLLUTION_REGION_ID := "region.pollution_edge"
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
	_check_first_playable_core_loop_rhythm()
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


func _check_first_playable_core_loop_rhythm() -> void:
	var baseline_result := baseline_builder.create_baseline_state("baseline.s0_new_game")
	_expect_success(baseline_result, "S0 baseline creates first playable core loop state")
	if not bool(baseline_result.get("success", false)):
		return

	var world_state: WorldState = baseline_result.get("world_state", null)
	var character_state: CharacterState = baseline_result.get("character_state", null)
	if world_state == null or character_state == null:
		failures.append("S0 core loop baseline should return world and character states")
		return

	var gather_system := GatherSystem.new(data_registry)
	_expect_core_loop_stage(
		world_state,
		character_state,
		DemoCoreLoopRhythmFormatter.STAGE_OUTPOST_START,
		"S0 core loop starts at outpost restore"
	)
	var startup_status := HudStatusPresenter.new().format_status_text(data_registry, world_state, character_state)
	_expect_text_contains(startup_status, "核心循环", "S0 HUD shows core loop rhythm")
	_expect_text_contains(startup_status, "现场记录", "S0 HUD shows narrative beat")
	_expect_text_contains(startup_status, "前哨核心低功率", "S0 narrative beat names outpost accident")

	var restore_result := gather_system.interact_with_object(
		"map_object_instance.outpost_core",
		"building.outpost_core",
		"outpost_core",
		character_state,
		world_state
	)
	_expect_success(restore_result, "outpost core restore starts first loop")
	quest_runtime.advance_for_interaction(
		world_state,
		character_state,
		{"definition_id": "building.outpost_core", "interaction_type": "outpost_core"},
		restore_result
	)
	_expect_array_has(world_state.quest_state.active_quest_ids, "quest.scout_crystal_field", "restore activates crystal field scout")
	_expect_core_loop_stage(
		world_state,
		character_state,
		DemoCoreLoopRhythmFormatter.STAGE_FIELD_INPUT,
		"restore points core loop to field input"
	)
	var restore_status := HudStatusPresenter.new().format_status_text(data_registry, world_state, character_state)
	_expect_text_contains(restore_status, "晶体矿脉是基础工艺输入", "restore HUD points narrative to crystal input")

	world_state.current_region_id = "region.crystal_vein_field"
	character_state.current_region_id = "region.crystal_vein_field"
	for crystal_instance_id in [
		"map_object_instance.core_loop_crystal_cluster_a",
		"map_object_instance.core_loop_crystal_cluster_b"
	]:
		var crystal_result := gather_system.interact_with_object(
			String(crystal_instance_id),
			"map_object.crystal_cluster",
			"gather",
			character_state,
			world_state
		)
		_expect_success(crystal_result, "crystal gather feeds first loop")
		quest_runtime.advance_for_interaction(
			world_state,
			character_state,
			{"definition_id": "map_object.crystal_cluster", "interaction_type": "gather"},
			crystal_result
		)
	_expect_array_has(world_state.quest_state.completed_quest_ids, "quest.scout_crystal_field", "crystal field scout completes after real gathers")
	_expect_core_loop_stage(
		world_state,
		character_state,
		DemoCoreLoopRhythmFormatter.STAGE_BASE_PROCESSING,
		"crystal gather points core loop to base processing"
	)
	var crystal_status := HudStatusPresenter.new().format_status_text(data_registry, world_state, character_state)
	_expect_text_contains(crystal_status, "第一批晶体和废件", "crystal completion HUD names base recovery beat")

	world_state.current_region_id = OUTPOST_REGION_ID
	character_state.current_region_id = OUTPOST_REGION_ID
	var crystal_start := processing_system.process_recipe("recipe.process_crystal_ore", character_state, world_state)
	_expect_success(crystal_start, "crystal ore processing starts during first loop")
	_expect_core_loop_stage(
		world_state,
		character_state,
		DemoCoreLoopRhythmFormatter.STAGE_BASE_PROCESSING,
		"active reactor keeps core loop at base processing"
	)
	var crystal_completed := processing_system.advance_processing(7.0, character_state, world_state)
	_expect_processing_completed(crystal_completed, "recipe.process_crystal_ore", "crystal ore processing completes during first loop")
	if not crystal_completed.is_empty():
		var crystal_feedback: Dictionary = crystal_completed[0].get("success_feedback", {})
		_expect_text_contains(
			String(crystal_feedback.get("core_loop", "")),
			"基地加工完成",
			"crystal processing feedback names base processing payoff"
		)

	world_state.quest_state.active_quest_ids = ["quest.prepare_treatment_supplies"]
	world_state.quest_state.completed_quest_ids.append("quest.make_filter_module")
	world_state.quest_state.unlock_effect("recipe.repair_gel")
	_expect_core_loop_stage(
		world_state,
		character_state,
		DemoCoreLoopRhythmFormatter.STAGE_OUTFITTING,
		"treatment supply prep moves core loop to outfitting"
	)
	var repair_start := processing_system.process_recipe("recipe.repair_gel", character_state, world_state)
	_expect_success(repair_start, "repair gel processing starts during first loop")
	var repair_completed := processing_system.advance_processing(6.0, character_state, world_state)
	_expect_processing_completed(repair_completed, "recipe.repair_gel", "repair gel processing completes during first loop")
	if not repair_completed.is_empty():
		var repair_quest_result := quest_runtime.advance_for_interaction(
			world_state,
			character_state,
			{"interaction_type": "process_recipe", "recipe_id": "recipe.repair_gel"},
			repair_completed[0]
		)
		_expect_equal(
			world_state.quest_state.get_objective_progress(
				"quest.prepare_treatment_supplies",
				"craft_item",
				"item.repair_gel"
			),
			1.0,
			"repair gel processing advances treatment supply objective"
		)
		_expect_equal(bool(repair_quest_result.get("accepted", false)), true, "repair gel quest runtime accepts processing update")
		var repair_feedback: Dictionary = repair_completed[0].get("success_feedback", {})
		_expect_text_contains(
			String(repair_feedback.get("core_loop", "")),
			"整备收益已入包",
			"repair gel feedback names outfitting payoff"
		)

	world_state.quest_state.active_quest_ids = ["quest.enter_pollution_edge"]
	world_state.quest_state.complete_quest("quest.expand_treatment_point")
	world_state.quest_state.unlock_effect("recipe.cleanse_residue")
	world_state.add_base_structure("structure.pollution_filter_build_site", "building.pollution_filter", POLLUTION_REGION_ID)
	character_state.inventory.add_item("item.polluted_residue", 2)
	_expect_core_loop_stage(
		world_state,
		character_state,
		DemoCoreLoopRhythmFormatter.STAGE_POLLUTION_PRESSURE,
		"pollution edge quest moves core loop to pollution pressure"
	)
	var pollution_status := HudStatusPresenter.new().format_status_text(data_registry, world_state, character_state)
	_expect_text_contains(pollution_status, "污染沉积和受扰生态", "pollution HUD names abnormal spread beat")
	var cleanse_start := processing_system.process_recipe(CLEANSE_RECIPE_ID, character_state, world_state)
	_expect_success(cleanse_start, "pollution residue filtering starts during first loop")
	var cleanse_completed := processing_system.advance_processing(13.0, character_state, world_state)
	_expect_processing_completed(cleanse_completed, CLEANSE_RECIPE_ID, "pollution residue filtering completes during first loop")
	if not cleanse_completed.is_empty():
		quest_runtime.advance_for_interaction(
			world_state,
			character_state,
			{"interaction_type": "process_recipe", "recipe_id": CLEANSE_RECIPE_ID},
			cleanse_completed[0]
		)
		var cleanse_log := HudLogPresenter.new(data_registry).format_result_log(cleanse_completed[0])
		var cleanse_feedback: Dictionary = cleanse_completed[0].get("success_feedback", {})
		_expect_text_contains(
			String(cleanse_feedback.get("core_loop", "")),
			"污染承压收益已入包",
			"cleanse feedback names pollution pressure payoff"
		)
		_expect_text_contains(cleanse_log, "去向：抗污染药剂 I x1", "cleanse log keeps compact vial destination")
		_expect_inventory_has(character_state, "item.resistance_vial_t1", "cleanse grants resistance vial")
		_expect_equal(
			character_state.inventory.has_ref("fluid.polluted_slurry", 1.0),
			true,
			"cleanse grants polluted slurry for core preparation"
		)

	world_state.quest_state.active_quest_ids = ["quest.prepare_demo_stabilization_buffer"]
	world_state.quest_state.unlock_effect(CORE_BUFFER_RECIPE_ID)
	if not character_state.inventory.has_ref("item.repair_gel", 1):
		character_state.inventory.add_item("item.repair_gel", 1)
	if not character_state.inventory.has_ref("item.basic_parts", 2):
		character_state.inventory.add_item("item.basic_parts", 2)
	_expect_core_loop_stage(
		world_state,
		character_state,
		DemoCoreLoopRhythmFormatter.STAGE_CORE_WRITE,
		"core buffer prep moves core loop to core write"
	)
	var core_status := HudStatusPresenter.new().format_status_text(data_registry, world_state, character_state)
	_expect_text_contains(core_status, "核心稳定站是旧稳定工程节点", "core HUD names stabilization narrative beat")
	var buffer_start := processing_system.process_recipe(CORE_BUFFER_RECIPE_ID, character_state, world_state)
	_expect_success(buffer_start, "core buffer processing starts from first loop resources")
	var buffer_completed := processing_system.advance_processing(8.0, character_state, world_state)
	_expect_processing_completed(buffer_completed, CORE_BUFFER_RECIPE_ID, "core buffer processing completes from first loop resources")
	if not buffer_completed.is_empty():
		var buffer_feedback: Dictionary = buffer_completed[0].get("success_feedback", {})
		_expect_text_contains(
			String(buffer_feedback.get("core_loop", "")),
			"核心写入准备就绪",
			"core buffer feedback names core write readiness"
		)
		_expect_inventory_has(character_state, "item.core_stabilization_buffer", "core buffer enters inventory")


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
	_expect_text_contains(String(feedback.get("note_text", "")), "异常源头仍未解释", "core write feedback leaves narrative hook")


func _check_completed_demo_readout(world_state: WorldState, character_state: CharacterState) -> void:
	var status_text := HudStatusPresenter.new().format_status_text(data_registry, world_state, character_state)
	_expect_text_contains(status_text, "首版 Demo 主线已完成", "completed HUD names demo mainline completion")
	_expect_text_contains(status_text, "结尾钩子", "completed HUD shows narrative hook")
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


func _expect_processing_completed(results: Array[Dictionary], recipe_id: String, message: String) -> void:
	if results.is_empty():
		failures.append("%s: no processing completion result" % message)
		return
	_expect_equal(String(results[0].get("completed_recipe_id", "")), recipe_id, message)


func _expect_core_loop_stage(
	world_state: WorldState,
	character_state: CharacterState,
	stage_id: String,
	message: String
) -> void:
	_expect_equal(DemoCoreLoopRhythmFormatter.get_stage_id(world_state, character_state), stage_id, message)
	var summary := DemoCoreLoopRhythmFormatter.format_hud_summary(world_state, character_state)
	if summary.is_empty():
		failures.append("%s: core loop summary is empty" % message)
		return
	_expect_text_contains(summary[0], "核心循环", "%s summary title" % message)
	_expect_text_contains(summary[0], DemoCoreLoopRhythmFormatter.format_stage_label(stage_id), "%s summary stage" % message)


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
