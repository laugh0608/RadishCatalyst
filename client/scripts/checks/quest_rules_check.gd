extends SceneTree

const QuestRulesTetherCheckScript := preload("res://scripts/checks/quest_rules_tether_check.gd")
const QuestRulesDeepFieldCheckScript := preload("res://scripts/checks/quest_rules_deep_field_check.gd")
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
	_check_runtime_recovers_current_region_and_inventory_progress()
	_check_phase_well_weave_core_recipe_progression()
	_check_runtime_recovers_late_craft_progress_from_inventory()
	_check_runtime_activates_missing_outer_ring_followup()
	_check_runtime_activates_missing_second_deep_followup()
	_check_runtime_activates_phase_relay_followup()
	_check_runtime_activates_post_phase_relay_followup()
	_check_runtime_restores_inner_fault_analysis_followup()
	_check_runtime_restores_phase_well_spindle_followup()
	_check_runtime_restores_phase_well_weave_core_followup()
	QuestRulesDeepFieldCheckScript.new(self).run()
	QuestRulesTetherCheckScript.new(self).run()
	_check_runtime_syncs_progression_vitals_and_late_anchor()
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

	updates = event_rules.get_interaction_objective_updates(
		{
			"definition_id": "map_object.phase_relay_pad",
			"interaction_type": "inspect"
		},
		{},
		quest_state
	)
	_expect_update(updates, "set", "quest.reenter_phase_frontline", "inspect", "map_object.phase_relay_pad", 1.0, "phase relay pad inspect update")

	updates = event_rules.get_interaction_objective_updates(
		{
			"definition_id": "map_object.phase_splinter_cluster",
			"interaction_type": "gather"
		},
		{},
		quest_state
	)
	_expect_update(updates, "set", "quest.trace_phase_splinters", "visit_region", "region.deep_ruin_threshold", 1.0, "phase splinter visit update")
	_expect_update(updates, "add", "quest.trace_phase_splinters", "gather_item", "item.phase_splinter", 1.0, "phase splinter gather update")

	updates = event_rules.get_interaction_objective_updates(
		{
			"definition_id": "map_object.phase_fault_spire",
			"interaction_type": "inspect"
		},
		{},
		quest_state
	)
	_expect_update(updates, "set", "quest.inspect_phase_fault_spire", "inspect", "map_object.phase_fault_spire", 1.0, "phase fault spire inspect update")

	updates = event_rules.get_interaction_objective_updates(
		{
			"definition_id": "map_object.fault_residue_cluster",
			"interaction_type": "gather"
		},
		{},
		quest_state
	)
	_expect_update(updates, "set", "quest.collect_fault_residue", "visit_region", "region.deep_ruin_threshold", 1.0, "fault residue visit update")
	_expect_update(updates, "add", "quest.collect_fault_residue", "gather_item", "item.fault_residue", 1.0, "fault residue gather update")

	updates = event_rules.get_interaction_objective_updates(
		{
			"definition_id": "map_object.phase_well_lock",
			"interaction_type": "inspect"
		},
		{},
		quest_state
	)
	_expect_update(updates, "set", "quest.unlock_phase_well", "inspect", "map_object.phase_well_lock", 1.0, "phase well lock inspect update")

	updates = event_rules.get_interaction_objective_updates(
		{
			"definition_id": "map_object.weft_bundle_cluster",
			"interaction_type": "gather"
		},
		{},
		quest_state
	)
	_expect_update(updates, "set", "quest.collect_weft_bundle", "visit_region", "region.phase_well_loom", 1.0, "weft bundle visit update")
	_expect_update(updates, "add", "quest.collect_weft_bundle", "gather_item", "item.weft_bundle", 1.0, "weft bundle gather update")

	updates = event_rules.get_interaction_objective_updates(
		{
			"definition_id": "map_object.phase_well_loom",
			"interaction_type": "inspect"
		},
		{},
		quest_state
	)
	_expect_update(updates, "set", "quest.inspect_phase_well_loom", "inspect", "map_object.phase_well_loom", 1.0, "phase well loom inspect update")

	updates = event_rules.get_interaction_objective_updates(
		{
			"definition_id": "map_object.selvedge_strip_cluster",
			"interaction_type": "gather"
		},
		{},
		quest_state
	)
	_expect_update(updates, "set", "quest.collect_selvedge_strip", "visit_region", "region.phase_well_frame", 1.0, "selvedge strip visit update")
	_expect_update(updates, "add", "quest.collect_selvedge_strip", "gather_item", "item.selvedge_strip", 1.0, "selvedge strip gather update")

	updates = event_rules.get_interaction_objective_updates(
		{
			"definition_id": "map_object.phase_well_frame_route_blocker",
			"interaction_type": "clear"
		},
		{},
		quest_state
	)
	_expect_update(updates, "set", "quest.collect_selvedge_strip", "clear", "map_object.phase_well_frame_route_blocker", 1.0, "phase well frame route clear update")

	updates = event_rules.get_interaction_objective_updates(
		{
			"definition_id": "map_object.phase_well_frame",
			"interaction_type": "inspect"
		},
		{},
		quest_state
	)
	_expect_update(updates, "set", "quest.inspect_phase_well_frame", "inspect", "map_object.phase_well_frame", 1.0, "phase well frame inspect update")

	updates = event_rules.get_interaction_objective_updates(
		{
			"definition_id": "map_object.tether_fiber_cluster",
			"interaction_type": "gather"
		},
		{},
		quest_state
	)
	_expect_update(updates, "set", "quest.collect_tether_fiber", "visit_region", "region.phase_well_tether", 1.0, "tether fiber visit update")
	_expect_update(updates, "add", "quest.collect_tether_fiber", "gather_item", "item.tether_fiber", 1.0, "tether fiber gather update")

	updates = event_rules.get_interaction_objective_updates(
		{
			"definition_id": "map_object.phase_well_tether",
			"interaction_type": "inspect"
		},
		{},
		quest_state
	)
	_expect_update(updates, "set", "quest.inspect_phase_well_tether", "inspect", "map_object.phase_well_tether", 1.0, "phase well tether inspect update")


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

	updates = event_rules.get_region_objective_updates("region.deep_ruin_threshold", quest_state)
	_expect_update(updates, "set", "quest.trace_phase_splinters", "visit_region", "region.deep_ruin_threshold", 1.0, "post relay deep region visit update")
	_expect_update(updates, "set", "quest.collect_fault_residue", "visit_region", "region.deep_ruin_threshold", 1.0, "fault residue region visit update")

	updates = event_rules.get_region_objective_updates("region.phase_well_loom", quest_state)
	_expect_update(updates, "set", "quest.collect_weft_bundle", "visit_region", "region.phase_well_loom", 1.0, "phase well loom region visit update")

	updates = event_rules.get_region_objective_updates("region.phase_well_frame", quest_state)
	_expect_update(updates, "set", "quest.collect_selvedge_strip", "visit_region", "region.phase_well_frame", 1.0, "phase well frame region visit update")

	updates = event_rules.get_region_objective_updates("region.phase_well_tether", quest_state)
	_expect_update(updates, "set", "quest.collect_tether_fiber", "visit_region", "region.phase_well_tether", 1.0, "phase well tether region visit update")


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
		event_rules.get_recipe_objective_updates("recipe.phase_splinter_refining"),
		"set",
		"quest.refine_phase_splinters",
		"craft_item",
		"item.phase_lens_blank",
		1.0,
		"phase splinter refining recipe update"
	)
	_expect_update(
		event_rules.get_recipe_objective_updates("recipe.relay_tuning_lens"),
		"set",
		"quest.refine_phase_splinters",
		"craft_item",
		"item.relay_tuning_lens",
		1.0,
		"relay tuning lens recipe update for expedition prep"
	)
	_expect_update(
		event_rules.get_recipe_objective_updates("recipe.inner_fault_analysis"),
		"set",
		"quest.analyze_inner_fault_trace",
		"craft_item",
		"item.phase_well_coordinate",
		1.0,
		"inner fault analysis recipe update"
	)
	_expect_update(
		event_rules.get_recipe_objective_updates("recipe.fault_residue_stabilization"),
		"set",
		"quest.refine_fault_residue",
		"craft_item",
		"item.stabilized_fault_core",
		1.0,
		"fault residue stabilization recipe update"
	)
	_expect_update(
		event_rules.get_recipe_objective_updates("recipe.phase_well_key"),
		"set",
		"quest.refine_fault_residue",
		"craft_item",
		"item.phase_well_key",
		1.0,
		"phase well key recipe update"
	)
	_expect_update(
		event_rules.get_recipe_objective_updates("recipe.phase_well_spindle_analysis"),
		"set",
		"quest.analyze_phase_well_spindle",
		"craft_item",
		"item.phase_well_warp_sheet",
		1.0,
		"phase well spindle analysis recipe update"
	)
	_expect_update(
		event_rules.get_recipe_objective_updates("recipe.weft_bundle_stabilization"),
		"set",
		"quest.refine_weft_bundle",
		"craft_item",
		"item.phase_well_tension_rib",
		1.0,
		"weft bundle stabilization recipe update"
	)
	_expect_update(
		event_rules.get_recipe_objective_updates("recipe.phase_well_shuttle"),
		"set",
		"quest.assemble_phase_well_shuttle",
		"craft_item",
		"item.phase_well_shuttle",
		1.0,
		"phase well shuttle recipe update"
	)
	_expect_update(
		event_rules.get_recipe_objective_updates("recipe.phase_well_weave_core_analysis"),
		"set",
		"quest.analyze_phase_well_weave_core",
		"craft_item",
		"item.phase_well_pattern_sheet",
		1.0,
		"phase well weave core analysis recipe update"
	)
	_expect_update(
		event_rules.get_recipe_objective_updates("recipe.selvedge_strip_stabilization"),
		"set",
		"quest.refine_selvedge_strip",
		"craft_item",
		"item.phase_well_frame_rib",
		1.0,
		"selvedge strip stabilization recipe update"
	)
	_expect_update(
		event_rules.get_recipe_objective_updates("recipe.phase_well_frame_key"),
		"set",
		"quest.assemble_phase_well_frame_key",
		"craft_item",
		"item.phase_well_frame_key",
		1.0,
		"phase well frame key recipe update"
	)
	_expect_update(
		event_rules.get_recipe_objective_updates("recipe.phase_well_knot_core_analysis"),
		"set",
		"quest.analyze_phase_well_knot_core",
		"craft_item",
		"item.phase_well_tether_sheet",
		1.0,
		"phase well knot core analysis recipe update"
	)
	_expect_update(
		event_rules.get_recipe_objective_updates("recipe.tether_fiber_stabilization"),
		"set",
		"quest.refine_tether_fiber",
		"craft_item",
		"item.phase_well_tether_rib",
		1.0,
		"tether fiber stabilization recipe update"
	)
	_expect_update(
		event_rules.get_recipe_objective_updates("recipe.phase_well_tether_spike"),
		"set",
		"quest.assemble_phase_well_tether_spike",
		"craft_item",
		"item.phase_well_tether_spike",
		1.0,
		"phase well tether spike recipe update"
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
	_expect_update(
		event_rules.get_defeated_enemy_objective_updates("enemy.deep_fault_hunter"),
		"set",
		"quest.trace_phase_splinters",
		"defeat_enemy",
		"enemy.deep_fault_hunter",
		1.0,
		"deep fault hunter defeat update"
	)
	_expect_update(
		event_rules.get_defeated_enemy_objective_updates("enemy.inner_fault_stalker"),
		"set",
		"quest.collect_fault_residue",
		"defeat_enemy",
		"enemy.inner_fault_stalker",
		1.0,
		"inner fault stalker defeat update"
	)
	_expect_update(
		event_rules.get_defeated_enemy_objective_updates("enemy.phase_well_tangler"),
		"set",
		"quest.collect_weft_bundle",
		"defeat_enemy",
		"enemy.phase_well_tangler",
		1.0,
		"phase well tangler defeat update"
	)
	_expect_update(
		event_rules.get_defeated_enemy_objective_updates("enemy.phase_well_raker"),
		"set",
		"quest.collect_selvedge_strip",
		"defeat_enemy",
		"enemy.phase_well_raker",
		1.0,
		"phase well raker defeat update"
	)
	_expect_update(
		event_rules.get_defeated_enemy_objective_updates("enemy.phase_well_binder"),
		"set",
		"quest.collect_tether_fiber",
		"defeat_enemy",
		"enemy.phase_well_binder",
		1.0,
		"phase well binder defeat update"
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


func _check_runtime_recovers_current_region_and_inventory_progress() -> void:
	var region_world := WorldState.create_default()
	var region_character := CharacterState.create_default()
	region_world.quest_state.active_quest_ids = ["quest.trace_phase_splinters"]
	region_world.current_region_id = "region.deep_ruin_threshold"
	var region_result := quest_runtime.reconcile_active_objectives(region_world, region_character)
	_expect_equal(bool(region_result.get("accepted", false)), true, "runtime accepts current region recovery")
	_expect_equal(region_world.quest_state.get_objective_progress("quest.trace_phase_splinters", "visit_region", "region.deep_ruin_threshold"), 1.0, "runtime recovers active visit objective from current region")
	var gather_world := WorldState.create_default()
	var gather_character := CharacterState.create_default()
	gather_world.quest_state.active_quest_ids = ["quest.trace_phase_splinters"]
	gather_character.inventory.add_item("item.phase_splinter", 2)
	var gather_result := quest_runtime.reconcile_active_objectives(gather_world, gather_character)
	_expect_equal(bool(gather_result.get("accepted", false)), true, "runtime accepts inventory gather recovery")
	_expect_equal(gather_world.quest_state.get_objective_progress("quest.trace_phase_splinters", "gather_item", "item.phase_splinter"), 2.0, "runtime recovers active gather objective from existing inventory")
	_expect_array_missing(gather_world.quest_state.completed_quest_ids, "quest.trace_phase_splinters", "inventory recovery alone should not complete multi-objective quest")


func _check_phase_well_weave_core_recipe_progression() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	world_state.quest_state.active_quest_ids = ["quest.analyze_phase_well_weave_core"]
	world_state.quest_state.completed_quest_ids = ["quest.inspect_phase_well_loom"]
	var result := quest_runtime.advance_for_interaction(
		world_state,
		character_state,
		{
			"interaction_type": "process_recipe",
			"recipe_id": "recipe.phase_well_weave_core_analysis"
		},
		{}
	)
	_expect_equal(bool(result.get("accepted", false)), true, "phase well weave core recipe update should be accepted")
	_expect_array_has(world_state.quest_state.completed_quest_ids, "quest.analyze_phase_well_weave_core", "phase well weave core analysis quest should complete after crafting pattern sheet")
	_expect_array_has(world_state.unlocked_region_ids, "region.phase_well_frame", "phase well weave core analysis should unlock phase well frame region")
	_expect_array_has(world_state.quest_state.active_quest_ids, "quest.collect_selvedge_strip", "phase well weave core analysis should advance to selvedge strip collection")


func _check_runtime_recovers_late_craft_progress_from_inventory() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	world_state.quest_state.active_quest_ids = ["quest.analyze_phase_well_weave_core"]
	world_state.quest_state.completed_quest_ids = ["quest.inspect_phase_well_loom"]
	character_state.inventory.add_item("item.phase_well_pattern_sheet", 1)
	var result := quest_runtime.reconcile_active_objectives(world_state, character_state)
	_expect_equal(bool(result.get("accepted", false)), true, "runtime accepts late craft progress recovery")
	_expect_array_has(world_state.quest_state.completed_quest_ids, "quest.analyze_phase_well_weave_core", "runtime completes weave core analysis when crafted result already exists")
	_expect_array_has(world_state.quest_state.active_quest_ids, "quest.collect_selvedge_strip", "runtime advances to selvedge strip collection after late craft recovery")
	if not _result_logs_contain(result, "后段加工产物已补记到当前任务"):
		failures.append("late craft progress recovery should log restored craft progress, got %s" % var_to_str(result))

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
	if not _result_logs_contain(result, "深段回波回收任务"):
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
	if not _result_logs_contain(result, "第二轮任务"):
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
	if not _result_logs_contain(result, "第二轮任务"):
		failures.append("phase relay activation should log deep followup activation, got %s" % var_to_str(result))


func _check_runtime_activates_post_phase_relay_followup() -> void:
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
		"quest.assemble_deep_signal_matrix",
		"quest.deploy_phase_relay_anchor"
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
	_expect_equal(bool(result.get("accepted", false)), true, "runtime accepts post phase relay followup activation")
	_expect_equal(world_state.active_phase_relay_anchor_id, "map_object_instance.phase_return_anchor", "runtime restores active phase relay anchor for post relay saves")
	_expect_equal(
		world_state.get_deployed_phase_relay_anchor_ids(),
		["map_object_instance.phase_return_anchor"],
		"runtime restores deployed phase relay anchors for post relay saves"
	)
	_expect_array_has(world_state.quest_state.active_quest_ids, "quest.reenter_phase_frontline", "runtime activates relay pad reentry quest")
	_expect_equal(_result_array_size(result, "completion_feedbacks"), 0, "post relay activation should not emit completion feedback")
	if not _result_logs_contain(result, "前线回传锚点") or not _result_logs_contain(result, "深段后续任务"):
		failures.append("post relay activation should log relay restore and new deep followup, got %s" % var_to_str(result))


func _check_runtime_restores_inner_fault_analysis_followup() -> void:
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
		"quest.assemble_deep_signal_matrix",
		"quest.deploy_phase_relay_anchor",
		"quest.reenter_phase_frontline",
		"quest.trace_phase_splinters",
		"quest.refine_phase_splinters",
		"quest.tune_relay_lens",
		"quest.inspect_phase_fault_spire"
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
		"recipe.deep_signal_matrix",
		"recipe.phase_splinter_refining",
		"recipe.relay_tuning_lens"
	]

	var result := quest_runtime.reconcile_active_objectives(world_state, character_state)
	_expect_equal(bool(result.get("accepted", false)), true, "runtime accepts inner fault analysis followup restoration")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.inner_fault_analysis", "runtime restores missing inner fault analysis unlock")
	_expect_array_has(world_state.quest_state.active_quest_ids, "quest.analyze_inner_fault_trace", "runtime activates inner fault analysis quest")
	_expect_equal(_result_array_size(result, "completion_feedbacks"), 0, "inner fault followup restoration should not emit completion feedback")


func _check_runtime_restores_phase_well_spindle_followup() -> void:
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
		"quest.assemble_deep_signal_matrix",
		"quest.deploy_phase_relay_anchor",
		"quest.reenter_phase_frontline",
		"quest.trace_phase_splinters",
		"quest.refine_phase_splinters",
		"quest.tune_relay_lens",
		"quest.inspect_phase_fault_spire",
		"quest.analyze_inner_fault_trace",
		"quest.collect_fault_residue",
		"quest.refine_fault_residue",
		"quest.unlock_phase_well",
		"quest.analyze_phase_well_locator",
		"quest.collect_well_flux",
		"quest.refine_well_flux",
		"quest.inspect_inner_phase_well",
		"quest.analyze_phase_well_core",
		"quest.collect_well_ash",
		"quest.refine_well_ash",
		"quest.assemble_phase_well_pike",
		"quest.inspect_phase_well_sink",
		"quest.analyze_phase_well_heart",
		"quest.collect_heart_spine",
		"quest.refine_heart_spine",
		"quest.assemble_phase_well_shunt",
		"quest.inspect_phase_well_chamber"
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
		"recipe.deep_signal_matrix",
		"recipe.phase_splinter_refining",
		"recipe.relay_tuning_lens",
		"recipe.inner_fault_analysis",
		"recipe.fault_residue_stabilization",
		"recipe.phase_well_key",
		"recipe.phase_well_locator_analysis",
		"region.inner_phase_well",
		"recipe.well_flux_stabilization",
		"recipe.phase_well_probe",
		"recipe.phase_well_core_analysis",
		"region.phase_well_sink",
		"recipe.well_ash_stabilization",
		"recipe.phase_well_pike",
		"recipe.phase_well_heart_analysis",
		"region.phase_well_chamber",
		"recipe.heart_spine_stabilization",
		"recipe.phase_well_shunt"
	]

	var result := quest_runtime.reconcile_active_objectives(world_state, character_state)
	_expect_equal(bool(result.get("accepted", false)), true, "runtime accepts phase well spindle followup restoration")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.phase_well_spindle_analysis", "runtime restores missing phase well spindle analysis unlock")
	_expect_array_has(world_state.quest_state.active_quest_ids, "quest.analyze_phase_well_spindle", "runtime activates phase well spindle analysis quest")
	_expect_equal(_result_array_size(result, "completion_feedbacks"), 0, "phase well spindle followup restoration should not emit completion feedback")


func _check_runtime_restores_phase_well_weave_core_followup() -> void:
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
		"quest.assemble_deep_signal_matrix",
		"quest.deploy_phase_relay_anchor",
		"quest.reenter_phase_frontline",
		"quest.trace_phase_splinters",
		"quest.refine_phase_splinters",
		"quest.tune_relay_lens",
		"quest.inspect_phase_fault_spire",
		"quest.analyze_inner_fault_trace",
		"quest.collect_fault_residue",
		"quest.refine_fault_residue",
		"quest.unlock_phase_well",
		"quest.analyze_phase_well_locator",
		"quest.collect_well_flux",
		"quest.refine_well_flux",
		"quest.inspect_inner_phase_well",
		"quest.analyze_phase_well_core",
		"quest.collect_well_ash",
		"quest.refine_well_ash",
		"quest.assemble_phase_well_pike",
		"quest.inspect_phase_well_sink",
		"quest.analyze_phase_well_heart",
		"quest.collect_heart_spine",
		"quest.refine_heart_spine",
		"quest.assemble_phase_well_shunt",
		"quest.inspect_phase_well_chamber",
		"quest.analyze_phase_well_spindle",
		"quest.collect_weft_bundle",
		"quest.refine_weft_bundle",
		"quest.assemble_phase_well_shuttle",
		"quest.inspect_phase_well_loom"
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
		"recipe.deep_signal_matrix",
		"recipe.phase_splinter_refining",
		"recipe.relay_tuning_lens",
		"recipe.inner_fault_analysis",
		"recipe.fault_residue_stabilization",
		"recipe.phase_well_key",
		"recipe.phase_well_locator_analysis",
		"region.inner_phase_well",
		"recipe.well_flux_stabilization",
		"recipe.phase_well_probe",
		"recipe.phase_well_core_analysis",
		"region.phase_well_sink",
		"recipe.well_ash_stabilization",
		"recipe.phase_well_pike",
		"recipe.phase_well_heart_analysis",
		"region.phase_well_chamber",
		"recipe.heart_spine_stabilization",
		"recipe.phase_well_shunt",
		"recipe.phase_well_spindle_analysis",
		"region.phase_well_loom",
		"recipe.weft_bundle_stabilization",
		"recipe.phase_well_shuttle"
	]

	var result := quest_runtime.reconcile_active_objectives(world_state, character_state)
	_expect_equal(bool(result.get("accepted", false)), true, "runtime accepts phase well weave core followup restoration")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.phase_well_weave_core_analysis", "runtime restores missing phase well weave core analysis unlock")
	_expect_equal(int(character_state.inventory.items.get("item.phase_well_weave_core", 0)), 1, "runtime restores missing phase well weave core reward")
	_expect_array_has(world_state.quest_state.active_quest_ids, "quest.analyze_phase_well_weave_core", "runtime activates phase well weave core analysis quest")
	_expect_equal(_result_array_size(result, "completion_feedbacks"), 0, "phase well weave core followup restoration should not emit completion feedback")
	if not _result_logs_contain(result, "相位井织核已补回背包"):
		failures.append("phase well weave core restoration should log restored weave core reward, got %s" % var_to_str(result))

func _check_runtime_syncs_progression_vitals_and_late_anchor() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	world_state.quest_state.active_quest_ids = ["quest.collect_heart_spine"]
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
		"quest.assemble_deep_signal_matrix",
		"quest.deploy_phase_relay_anchor",
		"quest.reenter_phase_frontline",
		"quest.trace_phase_splinters",
		"quest.refine_phase_splinters",
		"quest.tune_relay_lens",
		"quest.inspect_phase_fault_spire",
		"quest.analyze_inner_fault_trace",
		"quest.collect_fault_residue",
		"quest.refine_fault_residue",
		"quest.unlock_phase_well",
		"quest.analyze_phase_well_locator",
		"quest.collect_well_flux",
		"quest.refine_well_flux",
		"quest.inspect_inner_phase_well",
		"quest.analyze_phase_well_core",
		"quest.collect_well_ash",
		"quest.refine_well_ash",
		"quest.assemble_phase_well_pike",
		"quest.inspect_phase_well_sink",
		"quest.analyze_phase_well_heart"
	]
	character_state.health = 100.0
	character_state.protection = 100.0

	var result := quest_runtime.reconcile_active_objectives(world_state, character_state)
	_expect_equal(bool(result.get("accepted", false)), true, "runtime accepts late-stage progression sync")
	_expect_equal(character_state.max_health, 175.0, "runtime syncs late-stage max health")
	_expect_equal(character_state.max_protection, 175.0, "runtime syncs late-stage max protection")
	_expect_equal(character_state.health, 175.0, "runtime preserves late-stage full health ratio")
	_expect_equal(character_state.protection, 175.0, "runtime preserves late-stage full protection ratio")
	_expect_equal(
		world_state.active_phase_relay_anchor_id,
		"map_object_instance.phase_return_anchor_chamber",
		"runtime restores chamber relay anchor for late-stage saves"
	)
	_expect_equal(
		world_state.get_deployed_phase_relay_anchor_ids(),
		[
			"map_object_instance.phase_return_anchor",
			"map_object_instance.phase_return_anchor_chamber"
		],
		"runtime restores deployed anchors for late-stage saves"
	)


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


func _result_logs_contain(result: Dictionary, expected_fragment: String) -> bool:
	var values = result.get("log_messages", [])
	if not values is Array:
		return false
	for value in values:
		if String(value).find(expected_fragment) >= 0:
			return true
	return false


func _cleanup() -> void:
	data_registry.free()
