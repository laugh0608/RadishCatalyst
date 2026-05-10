extends SceneTree

var failures: Array[String] = []
var data_registry := DataRegistry.new()
var event_rules: QuestEventRules
var progress_rules: QuestProgressRules
var completion_rules: QuestCompletionRules
var completion_applier: QuestCompletionApplier
var quest_runtime: QuestRuntime


func _init() -> void:
	_run_checks()
	if failures.is_empty():
		print("Quest rules checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
		return

	event_rules = QuestEventRules.new(data_registry)
	progress_rules = QuestProgressRules.new(data_registry)
	completion_rules = QuestCompletionRules.new(data_registry, progress_rules)
	completion_applier = QuestCompletionApplier.new(data_registry)
	quest_runtime = QuestRuntime.new(data_registry)

	_check_interaction_event_objective_updates()
	_check_region_event_objective_updates()
	_check_recipe_build_and_enemy_event_objective_updates()
	_check_non_active_quest_does_not_complete()
	_check_incomplete_active_quest_does_not_complete()
	_check_completed_quest_returns_structured_result()
	_check_completion_applier_grants_rewards_unlocks_and_feedback()
	_check_quest_runtime_applies_updates_and_completion_feedback()
	_check_quest_runtime_recovers_pre_sampled_anomaly()
	_check_runtime_activates_missing_outer_ring_followup()
	_check_runtime_activates_missing_second_deep_followup()
	_check_runtime_activates_phase_relay_followup()
	_check_active_objective_progress_is_capped()
	_check_inactive_objective_progress_is_ignored()


func _check_interaction_event_objective_updates() -> void:
	var quest_state := QuestState.create_default()
	_mark_restore_outpost_completed(quest_state)
	var updates := event_rules.get_interaction_objective_updates(
		{
			"definition_id": "map_object.crystal_cluster",
			"interaction_type": "gather"
		},
		{},
		quest_state
	)
	_expect_update(updates, "set", "quest.scout_crystal_field", "visit_region", "region.crystal_vein_field", 1.0, "crystal gather visit update")
	_expect_update(updates, "add", "quest.scout_crystal_field", "gather_item", "item.crystal_ore", 3.0, "crystal gather item update")

	updates = event_rules.get_interaction_objective_updates(
		{
			"definition_id": "map_object.field_wreckage",
			"interaction_type": "gather"
		},
		{},
		quest_state
	)
	_expect_update(updates, "add", "quest.calibrate_reactor", "gather_item", "item.salvage_scrap", 2.0, "field wreckage gather update")

	updates = event_rules.get_interaction_objective_updates(
		{
			"definition_id": "map_object.ruin_gate",
			"interaction_type": "inspect"
		},
		{},
		quest_state
	)
	_expect_update(updates, "set", "quest.unlock_ruin_signal", "inspect", "map_object.ruin_gate", 1.0, "ruin inspect update")

	updates = event_rules.get_interaction_objective_updates(
		{
			"definition_id": "map_object.anomaly_residue_patch",
			"interaction_type": "gather"
		},
		{},
		quest_state
	)
	_expect_update(updates, "add", "quest.analyze_anomaly_sample", "gather_item", "item.anomaly_residue", 1.0, "anomaly residue gather update")

	updates = event_rules.get_interaction_objective_updates(
		{
			"definition_id": "map_object.signal_echo_cache",
			"interaction_type": "inspect"
		},
		{},
		quest_state
	)
	_expect_update(updates, "set", "quest.salvage_signal_echo", "inspect", "map_object.signal_echo_cache", 1.0, "signal echo inspect update")

	updates = event_rules.get_interaction_objective_updates(
		{
			"definition_id": "map_object.deep_signal_array",
			"interaction_type": "inspect"
		},
		{},
		quest_state
	)
	_expect_update(updates, "set", "quest.activate_deep_array", "inspect", "map_object.deep_signal_array", 1.0, "deep signal array inspect update")

	updates = event_rules.get_interaction_objective_updates(
		{
			"definition_id": "map_object.phase_conduit_cluster",
			"interaction_type": "gather"
		},
		{},
		quest_state
	)
	_expect_update(updates, "add", "quest.activate_deep_array", "gather_item", "item.phase_conduit", 1.0, "phase conduit gather update")

	updates = event_rules.get_interaction_objective_updates(
		{
			"definition_id": "map_object.phase_return_anchor",
			"interaction_type": "inspect"
		},
		{},
		quest_state
	)
	_expect_update(updates, "set", "quest.deploy_phase_relay_anchor", "inspect", "map_object.phase_return_anchor", 1.0, "phase relay anchor inspect update")


func _check_region_event_objective_updates() -> void:
	var quest_state := QuestState.create_default()
	_mark_restore_outpost_completed(quest_state)
	var updates := event_rules.get_region_objective_updates("region.crystal_vein_field", quest_state)
	_expect_update(updates, "set", "quest.scout_crystal_field", "visit_region", "region.crystal_vein_field", 1.0, "crystal region visit update")

	updates = event_rules.get_region_objective_updates("region.outpost_platform", quest_state)
	_expect_equal(updates.size(), 0, "outpost return before sample update count")
	quest_state.set_objective_progress("quest.bring_back_sample", "sample_object", "map_object.anomaly_crystal", 1)
	updates = event_rules.get_region_objective_updates("region.outpost_platform", quest_state)
	_expect_equal(updates.size(), 0, "outpost return after sample should not update sample quest")


func _check_recipe_build_and_enemy_event_objective_updates() -> void:
	_expect_update(
		event_rules.get_recipe_objective_updates("recipe.reactor_calibrator"),
		"set",
		"quest.calibrate_reactor",
		"craft_item",
		"item.reactor_calibrator",
		1.0,
		"reactor calibrator recipe update"
	)
	_expect_update(
		event_rules.get_recipe_objective_updates("recipe.repair_gel"),
		"set",
		"quest.prepare_treatment_supplies",
		"craft_item",
		"item.repair_gel",
		1.0,
		"repair gel recipe update"
	)
	_expect_update(
		event_rules.get_recipe_objective_updates("recipe.analyze_anomaly_sample"),
		"set",
		"quest.analyze_anomaly_sample",
		"craft_item",
		"item.sample_analysis",
		1.0,
		"sample analysis recipe update"
	)
	_expect_update(
		event_rules.get_recipe_objective_updates("recipe.basic_filter_module"),
		"set",
		"quest.make_filter_module",
		"craft_item",
		"equipment.filter_module_t1",
		1.0,
		"filter module recipe update"
	)
	_expect_update(
		event_rules.get_recipe_objective_updates("recipe.deep_signal_analysis"),
		"set",
		"quest.analyze_deep_signal",
		"craft_item",
		"item.deep_ruin_coordinates",
		1.0,
		"deep signal analysis recipe update"
	)
	_expect_update(
		event_rules.get_recipe_objective_updates("recipe.deep_core_imprint"),
		"set",
		"quest.analyze_deep_core",
		"craft_item",
		"item.deep_route_imprint",
		1.0,
		"deep core imprint recipe update"
	)
	_expect_update(
		event_rules.get_recipe_objective_updates("recipe.deep_signal_matrix"),
		"set",
		"quest.assemble_deep_signal_matrix",
		"craft_item",
		"item.deep_signal_matrix",
		1.0,
		"deep signal matrix recipe update"
	)
	_expect_update(
		event_rules.get_build_objective_updates("building.foundation_t1"),
		"add",
		"quest.expand_treatment_point",
		"build",
		"building.foundation_t1",
		1.0,
		"foundation build update"
	)
	_expect_update(
		event_rules.get_defeated_enemy_objective_updates("enemy.treatment_skitter"),
		"set",
		"quest.prepare_treatment_supplies",
		"defeat_enemy",
		"enemy.treatment_skitter",
		1.0,
		"treatment enemy defeat update"
	)
	_expect_equal(event_rules.get_defeated_enemy_objective_updates("enemy.native_skitter").size(), 0, "ordinary native enemy should not complete treatment prep")
	_expect_update(
		event_rules.get_defeated_enemy_objective_updates("enemy.polluted_skitter"),
		"set",
		"quest.enter_pollution_edge",
		"defeat_enemy",
		"enemy.polluted_skitter",
		1.0,
		"polluted enemy defeat update"
	)
	_expect_update(
		event_rules.get_defeated_enemy_objective_updates("enemy.elite_residue_node"),
		"set",
		"quest.defeat_elite_node",
		"defeat_enemy",
		"enemy.elite_residue_node",
		1.0,
		"elite node defeat update"
	)
	_expect_update(
		event_rules.get_defeated_enemy_objective_updates("enemy.ruin_phase_guard"),
		"set",
		"quest.salvage_signal_echo",
		"defeat_enemy",
		"enemy.ruin_phase_guard",
		1.0,
		"ruin phase guard defeat update"
	)
	_expect_update(
		event_rules.get_defeated_enemy_objective_updates("enemy.deep_ruin_stalker"),
		"set",
		"quest.activate_deep_array",
		"defeat_enemy",
		"enemy.deep_ruin_stalker",
		1.0,
		"deep ruin stalker defeat update"
	)


func _check_non_active_quest_does_not_complete() -> void:
	var quest_state := QuestState.create_default()
	var result := completion_rules.try_complete_quest(quest_state, "quest.scout_crystal_field")
	_expect_equal(bool(result.get("completed", true)), false, "non active quest completion")
	_expect_array_missing(quest_state.completed_quest_ids, "quest.scout_crystal_field", "non active quest completed list")
	_expect_array_missing(quest_state.active_quest_ids, "quest.calibrate_reactor", "non active next quest")


func _check_incomplete_active_quest_does_not_complete() -> void:
	var quest_state := QuestState.create_default()
	var result := completion_rules.try_complete_quest(quest_state, "quest.restore_outpost")
	_expect_equal(bool(result.get("completed", true)), false, "incomplete active quest completion")
	_expect_array_has(quest_state.active_quest_ids, "quest.restore_outpost", "incomplete active quest remains active")
	_expect_array_missing(quest_state.completed_quest_ids, "quest.restore_outpost", "incomplete active quest completed list")


func _check_completed_quest_returns_structured_result() -> void:
	var quest_state := QuestState.create_default()
	progress_rules.set_active_objective_progress(
		quest_state,
		"quest.restore_outpost",
		"interact",
		"building.outpost_core",
		1
	)

	var result := completion_rules.try_complete_quest(quest_state, "quest.restore_outpost")
	_expect_equal(bool(result.get("completed", false)), true, "restore completion result")
	_expect_equal(String(result.get("quest_id", "")), "quest.restore_outpost", "restore completion quest id")
	_expect_array_has(quest_state.completed_quest_ids, "quest.restore_outpost", "restore completed list")
	_expect_array_missing(quest_state.active_quest_ids, "quest.restore_outpost", "restore removed from active")
	_expect_array_has(quest_state.active_quest_ids, "quest.scout_crystal_field", "restore activates scout quest")
	_expect_array_has(quest_state.unlocked_effects, "region.crystal_vein_field", "restore quest state region unlock")
	_expect_array_has(quest_state.unlocked_effects, "recipe.process_crystal_ore", "restore quest state recipe unlock")
	_expect_result_ref(result.get("rewards", []), "item.basic_parts", 4.0, "restore reward refs")
	_expect_result_value(result.get("unlock_effects", []), "recipe.process_crystal_ore", "restore unlock result")
	_expect_result_value(result.get("next_quest_ids", []), "quest.scout_crystal_field", "restore next quest result")


func _check_completion_applier_grants_rewards_unlocks_and_feedback() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	progress_rules.set_active_objective_progress(
		world_state.quest_state,
		"quest.restore_outpost",
		"interact",
		"building.outpost_core",
		1
	)

	var result := completion_rules.try_complete_quest(world_state.quest_state, "quest.restore_outpost")
	var feedback := completion_applier.apply_completion(world_state, character_state, result)
	_expect_equal(character_state.inventory.items.get("item.basic_parts", 0), 8, "applier grants item rewards")
	_expect_array_has(world_state.unlocked_region_ids, "region.crystal_vein_field", "applier unlocks world region")
	_expect_equal(String(feedback.get("title", "")), "任务完成：恢复前哨", "applier feedback title")
	_expect_equal(String(feedback.get("panel_title", "")), "任务完成", "applier panel title")
	_expect_equal(String(feedback.get("completed_text", "")), "完成：恢复前哨", "applier completed text")
	_expect_equal(String(feedback.get("reward_text", "")), "奖励：基础零件 x4", "applier reward text")
	_expect_equal(String(feedback.get("next_goal_text", "")), "新目标：勘探晶体矿脉", "applier next goal text")
	if String(feedback.get("log_message", "")).find("解锁：") < 0:
		failures.append("applier log message should include unlock text, got %s" % var_to_str(feedback))


func _check_quest_runtime_applies_updates_and_completion_feedback() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	var result := quest_runtime.apply_objective_updates(world_state, character_state, [
		{
			"mode": "set",
			"quest_id": "quest.restore_outpost",
			"objective_type": "interact",
			"target_id": "building.outpost_core",
			"amount": 1
		}
	])
	_expect_equal(bool(result.get("accepted", false)), true, "runtime accepts objective updates")
	_expect_array_has(world_state.quest_state.completed_quest_ids, "quest.restore_outpost", "runtime completes restore quest")
	_expect_array_has(world_state.unlocked_region_ids, "region.crystal_vein_field", "runtime applies world unlock")
	_expect_equal(character_state.inventory.items.get("item.basic_parts", 0), 8, "runtime applies reward")
	_expect_equal(_result_array_size(result, "completion_feedbacks"), 1, "runtime completion feedback count")
	_expect_equal(_result_array_size(result, "log_messages"), 1, "runtime log message count")


func _check_quest_runtime_recovers_pre_sampled_anomaly() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	_mark_bring_back_sample_active_with_pre_sampled_anomaly(world_state, character_state)

	var result := quest_runtime.reconcile_active_objectives(world_state, character_state)
	_expect_equal(bool(result.get("accepted", false)), true, "runtime accepts pre-sampled anomaly recovery")
	_expect_equal(
		world_state.quest_state.get_objective_progress("quest.bring_back_sample", "sample_object", "map_object.anomaly_crystal"),
		1.0,
		"pre-sampled anomaly sample objective"
	)
	_expect_array_has(world_state.quest_state.completed_quest_ids, "quest.bring_back_sample", "pre-sampled anomaly completes sample quest")
	_expect_array_has(world_state.quest_state.active_quest_ids, "quest.analyze_anomaly_sample", "pre-sampled anomaly activates sample analysis quest")


func _check_runtime_activates_missing_outer_ring_followup() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	world_state.quest_state.active_quest_ids = []
	world_state.quest_state.completed_quest_ids = [
		"quest.restore_outpost",
		"quest.scout_crystal_field",
		"quest.calibrate_reactor",
		"quest.bring_back_sample",
		"quest.analyze_anomaly_sample",
		"quest.make_filter_module",
		"quest.prepare_treatment_supplies",
		"quest.expand_treatment_point",
		"quest.enter_pollution_edge",
		"quest.defeat_elite_node",
		"quest.unlock_ruin_signal",
		"quest.scout_ruin_outer_ring",
		"quest.assemble_phase_anchor",
		"quest.stabilize_outer_ring_barrier",
		"quest.secure_outer_ring_signal"
	]
	world_state.quest_state.unlocked_effects = [
		"region.outpost_platform",
		"region.crystal_vein_field",
		"recipe.process_crystal_ore",
		"recipe.repair_gel",
		"recipe.reactor_calibrator",
		"recipe.analyze_anomaly_sample",
		"recipe.make_filter_media",
		"recipe.basic_filter_module",
		"recipe.foundation_t1",
		"region.pollution_edge",
		"recipe.cleanse_residue",
		"region.locked_ruin_gate",
		"region.ruin_outer_ring",
		"recipe.phase_anchor",
		"slice_01_complete"
	]

	var result := quest_runtime.reconcile_active_objectives(world_state, character_state)
	_expect_equal(bool(result.get("accepted", false)), true, "runtime accepts missing outer ring followup activation")
	_expect_array_has(world_state.quest_state.active_quest_ids, "quest.salvage_signal_echo", "runtime activates signal echo salvage quest")
	_expect_equal(_result_array_size(result, "completion_feedbacks"), 0, "followup activation should not emit completion feedback")
	if String(result.get("log_messages", [""])[0]).find("深段回波回收任务") < 0:
		failures.append("followup activation should log outer ring extension activation, got %s" % var_to_str(result))


func _check_runtime_activates_missing_second_deep_followup() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	world_state.quest_state.active_quest_ids = []
	world_state.quest_state.completed_quest_ids = [
		"quest.restore_outpost",
		"quest.scout_crystal_field",
		"quest.calibrate_reactor",
		"quest.bring_back_sample",
		"quest.analyze_anomaly_sample",
		"quest.make_filter_module",
		"quest.prepare_treatment_supplies",
		"quest.expand_treatment_point",
		"quest.enter_pollution_edge",
		"quest.defeat_elite_node",
		"quest.unlock_ruin_signal",
		"quest.scout_ruin_outer_ring",
		"quest.assemble_phase_anchor",
		"quest.stabilize_outer_ring_barrier",
		"quest.secure_outer_ring_signal",
		"quest.salvage_signal_echo",
		"quest.analyze_deep_signal",
		"quest.unlock_deep_ruin_entrance",
		"quest.harvest_phase_filament",
		"quest.refine_phase_filament",
		"quest.assemble_deep_override",
		"quest.unlock_deep_ruin_cache"
	]
	world_state.quest_state.unlocked_effects = [
		"region.outpost_platform",
		"region.crystal_vein_field",
		"recipe.process_crystal_ore",
		"recipe.repair_gel",
		"recipe.reactor_calibrator",
		"recipe.analyze_anomaly_sample",
		"recipe.make_filter_media",
		"recipe.basic_filter_module",
		"recipe.foundation_t1",
		"region.pollution_edge",
		"recipe.cleanse_residue",
		"region.locked_ruin_gate",
		"region.ruin_outer_ring",
		"recipe.phase_anchor",
		"slice_01_complete",
		"recipe.deep_signal_analysis",
		"region.deep_ruin_threshold",
		"recipe.phase_filament_refining",
		"recipe.deep_override_key",
		"recipe.deep_core_imprint"
	]

	var result := quest_runtime.reconcile_active_objectives(world_state, character_state)
	_expect_equal(bool(result.get("accepted", false)), true, "runtime accepts missing second deep followup activation")
	_expect_array_has(world_state.quest_state.active_quest_ids, "quest.analyze_deep_core", "runtime activates deep core analysis quest")
	_expect_equal(_result_array_size(result, "completion_feedbacks"), 0, "second deep activation should not emit completion feedback")
	if String(result.get("log_messages", [""])[0]).find("第二轮任务") < 0:
		failures.append("second deep activation should log deep followup activation, got %s" % var_to_str(result))


func _check_runtime_activates_phase_relay_followup() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	world_state.quest_state.active_quest_ids = []
	world_state.quest_state.completed_quest_ids = [
		"quest.restore_outpost",
		"quest.scout_crystal_field",
		"quest.calibrate_reactor",
		"quest.bring_back_sample",
		"quest.analyze_anomaly_sample",
		"quest.make_filter_module",
		"quest.prepare_treatment_supplies",
		"quest.expand_treatment_point",
		"quest.enter_pollution_edge",
		"quest.defeat_elite_node",
		"quest.unlock_ruin_signal",
		"quest.scout_ruin_outer_ring",
		"quest.assemble_phase_anchor",
		"quest.stabilize_outer_ring_barrier",
		"quest.secure_outer_ring_signal",
		"quest.salvage_signal_echo",
		"quest.analyze_deep_signal",
		"quest.unlock_deep_ruin_entrance",
		"quest.harvest_phase_filament",
		"quest.refine_phase_filament",
		"quest.assemble_deep_override",
		"quest.unlock_deep_ruin_cache",
		"quest.analyze_deep_core",
		"quest.activate_deep_array",
		"quest.assemble_deep_signal_matrix"
	]
	world_state.quest_state.unlocked_effects = [
		"region.outpost_platform",
		"region.crystal_vein_field",
		"recipe.process_crystal_ore",
		"recipe.repair_gel",
		"recipe.reactor_calibrator",
		"recipe.analyze_anomaly_sample",
		"recipe.make_filter_media",
		"recipe.basic_filter_module",
		"recipe.foundation_t1",
		"region.pollution_edge",
		"recipe.cleanse_residue",
		"region.locked_ruin_gate",
		"region.ruin_outer_ring",
		"recipe.phase_anchor",
		"slice_01_complete",
		"recipe.deep_signal_analysis",
		"region.deep_ruin_threshold",
		"recipe.phase_filament_refining",
		"recipe.deep_override_key",
		"recipe.deep_core_imprint",
		"recipe.deep_signal_matrix"
	]

	var result := quest_runtime.reconcile_active_objectives(world_state, character_state)
	_expect_equal(bool(result.get("accepted", false)), true, "runtime accepts phase relay followup activation")
	_expect_array_has(world_state.quest_state.active_quest_ids, "quest.deploy_phase_relay_anchor", "runtime activates phase relay anchor deployment quest")
	_expect_equal(_result_array_size(result, "completion_feedbacks"), 0, "phase relay activation should not emit completion feedback")
	if String(result.get("log_messages", [""])[0]).find("第二轮任务") < 0:
		failures.append("phase relay activation should log deep followup activation, got %s" % var_to_str(result))


func _check_active_objective_progress_is_capped() -> void:
	var quest_state := QuestState.create_default()
	_mark_restore_outpost_completed(quest_state)
	progress_rules.add_active_objective_progress(
		quest_state,
		"quest.scout_crystal_field",
		"gather_item",
		"item.crystal_ore",
		10
	)
	_expect_equal(
		quest_state.get_objective_progress("quest.scout_crystal_field", "gather_item", "item.crystal_ore"),
		6.0,
		"active objective progress capped"
	)


func _check_inactive_objective_progress_is_ignored() -> void:
	var quest_state := QuestState.create_default()
	progress_rules.set_active_objective_progress(
		quest_state,
		"quest.scout_crystal_field",
		"visit_region",
		"region.crystal_vein_field",
		1
	)
	_expect_equal(
		quest_state.get_objective_progress("quest.scout_crystal_field", "visit_region", "region.crystal_vein_field"),
		0.0,
		"inactive objective progress ignored"
	)


func _mark_restore_outpost_completed(quest_state: QuestState) -> void:
	progress_rules.set_active_objective_progress(
		quest_state,
		"quest.restore_outpost",
		"interact",
		"building.outpost_core",
		1
	)
	completion_rules.try_complete_quest(quest_state, "quest.restore_outpost")


func _mark_bring_back_sample_active_with_pre_sampled_anomaly(world_state: WorldState, character_state: CharacterState) -> void:
	world_state.unlock_region("region.crystal_vein_field")
	world_state.quest_state.active_quest_ids = ["quest.bring_back_sample"]
	world_state.quest_state.completed_quest_ids = [
		"quest.restore_outpost",
		"quest.scout_crystal_field",
		"quest.calibrate_reactor"
	]
	world_state.quest_state.objective_progress = {
		"quest.restore_outpost|interact|building.outpost_core": 1,
		"quest.scout_crystal_field|visit_region|region.crystal_vein_field": 1,
		"quest.scout_crystal_field|gather_item|item.crystal_ore": 6,
		"quest.calibrate_reactor|gather_item|item.salvage_scrap": 4,
		"quest.calibrate_reactor|craft_item|item.reactor_calibrator": 1
	}
	world_state.quest_state.unlocked_effects = [
		"region.outpost_platform",
		"region.crystal_vein_field",
		"recipe.process_crystal_ore",
		"recipe.repair_gel",
		"recipe.reactor_calibrator"
	]
	world_state.ensure_map_object("map_object_instance.anomaly_crystal", "map_object.anomaly_crystal", "region.crystal_vein_field")
	world_state.set_map_object_flag("map_object_instance.anomaly_crystal", "is_sampled", true)
	character_state.inventory.add_item("item.anomaly_sample", 1)


func _expect_result_ref(refs, expected_id: String, expected_amount: float, label: String) -> void:
	if not (refs is Array):
		failures.append("%s should be an array, got %s" % [label, var_to_str(refs)])
		return
	for ref in refs:
		if not (ref is Dictionary):
			continue
		if String(ref.get("id", "")) == expected_id and is_equal_approx(float(ref.get("amount", 0.0)), expected_amount):
			return
	failures.append("%s should contain %s x%s, got %s" % [label, expected_id, expected_amount, var_to_str(refs)])


func _expect_result_value(values, expected_value: String, label: String) -> void:
	if not (values is Array):
		failures.append("%s should be an array, got %s" % [label, var_to_str(values)])
		return
	if not values.has(expected_value):
		failures.append("%s should contain %s, got %s" % [label, expected_value, var_to_str(values)])


func _expect_update(
	updates: Array,
	expected_mode: String,
	expected_quest_id: String,
	expected_objective_type: String,
	expected_target_id: String,
	expected_amount: float,
	label: String
) -> void:
	for update in updates:
		if not (update is Dictionary):
			continue
		if (
			String(update.get("mode", "")) == expected_mode
			and String(update.get("quest_id", "")) == expected_quest_id
			and String(update.get("objective_type", "")) == expected_objective_type
			and String(update.get("target_id", "")) == expected_target_id
			and is_equal_approx(float(update.get("amount", 0.0)), expected_amount)
		):
			return
	failures.append("%s should contain %s update for %s|%s|%s x%s, got %s" % [
		label,
		expected_mode,
		expected_quest_id,
		expected_objective_type,
		expected_target_id,
		expected_amount,
		var_to_str(updates)
	])


func _expect_equal(actual, expected, label: String) -> void:
	if actual != expected:
		failures.append("%s expected %s, got %s" % [label, var_to_str(expected), var_to_str(actual)])


func _expect_array_has(values: Array, expected_value: String, label: String) -> void:
	if not values.has(expected_value):
		failures.append("%s should contain %s, got %s" % [label, expected_value, var_to_str(values)])


func _expect_array_missing(values: Array, unexpected_value: String, label: String) -> void:
	if values.has(unexpected_value):
		failures.append("%s should not contain %s, got %s" % [label, unexpected_value, var_to_str(values)])


func _result_array_size(result: Dictionary, key: String) -> int:
	var values = result.get(key, [])
	if not values is Array:
		failures.append("%s should be an array, got %s" % [key, var_to_str(values)])
		return 0
	return values.size()


func _cleanup() -> void:
	data_registry.free()
