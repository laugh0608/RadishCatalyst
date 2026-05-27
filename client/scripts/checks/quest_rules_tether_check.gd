extends RefCounted

var host


func _init(check_host) -> void:
	host = check_host


func run() -> void:
	_check_phase_well_knot_core_recipe_progression()
	_check_runtime_recovers_late_tether_analysis_progress_from_inventory()
	_check_runtime_restores_phase_well_knot_core_followup()
	_check_phase_well_anchor_core_recipe_progression()
	_check_runtime_recovers_late_anchor_stake_progress_from_inventory()
	_check_runtime_restores_phase_well_anchor_core_followup()
	_check_runtime_preserves_manual_phase_relay_anchor_selection()
	_check_demo_stabilization_event_rules()
	_check_runtime_activates_demo_stabilization_core_entry()
	_check_demo_stabilization_three_step_flow()
	_check_demo_stabilization_short_run_from_overpressure_archive()


func _check_phase_well_knot_core_recipe_progression() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	world_state.quest_state.active_quest_ids = ["quest.analyze_phase_well_knot_core"]
	world_state.quest_state.completed_quest_ids = ["quest.inspect_phase_well_frame"]
	var result: Dictionary = host.quest_runtime.advance_for_interaction(
		world_state,
		character_state,
		{
			"interaction_type": "process_recipe",
			"recipe_id": "recipe.phase_well_knot_core_analysis"
		},
		{}
	)
	host._expect_equal(bool(result.get("accepted", false)), true, "phase well knot core recipe update should be accepted")
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.analyze_phase_well_knot_core", "phase well knot core analysis quest should complete after crafting tether sheet")
	host._expect_array_has(world_state.unlocked_region_ids, "region.phase_well_tether", "phase well knot core analysis should unlock phase well tether region")
	host._expect_array_has(world_state.quest_state.active_quest_ids, "quest.collect_tether_fiber", "phase well knot core analysis should advance to tether fiber collection")


func _check_runtime_recovers_late_tether_analysis_progress_from_inventory() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	world_state.quest_state.active_quest_ids = ["quest.analyze_phase_well_knot_core"]
	world_state.quest_state.completed_quest_ids = ["quest.inspect_phase_well_frame"]
	character_state.inventory.add_item("item.phase_well_tether_sheet", 1)
	var result: Dictionary = host.quest_runtime.reconcile_active_objectives(world_state, character_state)
	host._expect_equal(bool(result.get("accepted", false)), true, "runtime accepts late tether analysis progress recovery")
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.analyze_phase_well_knot_core", "runtime completes knot core analysis when crafted result already exists")
	host._expect_array_has(world_state.quest_state.active_quest_ids, "quest.collect_tether_fiber", "runtime advances to tether fiber collection after late craft recovery")
	if not host._result_logs_contain(result, "后段加工产物已补记到当前任务"):
		host.failures.append("late tether analysis recovery should log restored craft progress, got %s" % var_to_str(result))


func _check_runtime_restores_phase_well_knot_core_followup() -> void:
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
		"quest.inspect_phase_well_loom",
		"quest.analyze_phase_well_weave_core",
		"quest.collect_selvedge_strip",
		"quest.refine_selvedge_strip",
		"quest.assemble_phase_well_frame_key",
		"quest.inspect_phase_well_frame"
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
		"recipe.phase_well_shuttle",
		"recipe.phase_well_weave_core_analysis",
		"region.phase_well_frame",
		"recipe.selvedge_strip_stabilization",
		"recipe.phase_well_frame_key"
	]

	var result: Dictionary = host.quest_runtime.reconcile_active_objectives(world_state, character_state)
	host._expect_equal(bool(result.get("accepted", false)), true, "runtime accepts phase well knot core followup restoration")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.phase_well_knot_core_analysis", "runtime restores missing phase well knot core analysis unlock")
	host._expect_equal(int(character_state.inventory.items.get("item.phase_well_knot_core", 0)), 1, "runtime restores missing phase well knot core reward")
	host._expect_array_has(world_state.quest_state.active_quest_ids, "quest.analyze_phase_well_knot_core", "runtime activates phase well knot core analysis quest")
	host._expect_equal(host._result_array_size(result, "completion_feedbacks"), 0, "phase well knot core followup restoration should not emit completion feedback")
	if not host._result_logs_contain(result, "相位井结核已补回背包"):
		host.failures.append("phase well knot core restoration should log restored knot core reward, got %s" % var_to_str(result))
	if not host._result_logs_contain(result, "井纹架后的井系桥后续任务"):
		host.failures.append("phase well knot core restoration should log tether followup activation, got %s" % var_to_str(result))


func _check_phase_well_anchor_core_recipe_progression() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	world_state.quest_state.active_quest_ids = ["quest.analyze_phase_well_anchor_core"]
	world_state.quest_state.completed_quest_ids = ["quest.inspect_phase_well_tether"]
	world_state.quest_state.unlocked_effects = ["region.outpost_platform", "slice_01_complete", "recipe.phase_well_anchor_core_analysis"]
	var result: Dictionary = host.quest_runtime.advance_for_interaction(
		world_state,
		character_state,
		{
			"interaction_type": "process_recipe",
			"recipe_id": "recipe.phase_well_anchor_core_analysis"
		},
		{}
	)
	host._expect_equal(bool(result.get("accepted", false)), true, "phase well anchor core recipe update should be accepted")
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.analyze_phase_well_anchor_core", "phase well anchor core analysis quest should complete after crafting return sheet")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.anchor_core_dust_stabilization", "anchor core analysis should unlock dust stabilization recipe")
	host._expect_array_has(world_state.quest_state.active_quest_ids, "quest.refine_anchor_core_dust", "anchor core analysis should advance to dust refinement")


func _check_runtime_recovers_late_anchor_stake_progress_from_inventory() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	world_state.quest_state.active_quest_ids = ["quest.refine_anchor_core_dust"]
	world_state.quest_state.completed_quest_ids = [
		"quest.inspect_phase_well_tether",
		"quest.analyze_phase_well_anchor_core"
	]
	character_state.inventory.add_item("item.anchor_field_filter", 1)
	character_state.inventory.add_item("item.phase_well_anchor_stake", 1)
	var result: Dictionary = host.quest_runtime.reconcile_active_objectives(world_state, character_state)
	host._expect_equal(bool(result.get("accepted", false)), true, "runtime accepts late anchor stake progress recovery")
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.refine_anchor_core_dust", "runtime completes anchor field package when crafted result already exists")
	host._expect_array_has(world_state.quest_state.active_quest_ids, "quest.stabilize_phase_well_anchor_field", "runtime advances to anchor field stabilization after late craft recovery")
	if not host._result_logs_contain(result, "后段加工产物已补记到当前任务"):
		host.failures.append("late anchor stake recovery should log restored craft progress, got %s" % var_to_str(result))


func _check_runtime_preserves_manual_phase_relay_anchor_selection() -> void:
	var old_world := WorldState.create_default()
	var old_character := CharacterState.create_default()
	old_world.quest_state.active_quest_ids = ["quest.plan_stability_frontline_action"]
	old_world.quest_state.completed_quest_ids = ["quest.deploy_phase_relay_anchor"]
	old_world.set_active_phase_relay_anchor("map_object_instance.phase_return_anchor")
	var old_result: Dictionary = host.quest_runtime.reconcile_active_objectives(old_world, old_character)
	host._expect_equal(bool(old_result.get("accepted", false)), true, "runtime accepts old tether relay migration")
	host._expect_equal(
		old_world.active_phase_relay_anchor_id,
		"map_object_instance.phase_return_anchor_tether",
		"runtime migrates old tether progress to tether relay anchor once"
	)

	var manual_world := WorldState.create_default()
	var manual_character := CharacterState.create_default()
	manual_world.quest_state.active_quest_ids = ["quest.plan_stability_frontline_action"]
	manual_world.quest_state.completed_quest_ids = ["quest.deploy_phase_relay_anchor"]
	manual_world.add_deployed_phase_relay_anchor("map_object_instance.phase_return_anchor")
	manual_world.add_deployed_phase_relay_anchor("map_object_instance.phase_return_anchor_chamber")
	manual_world.add_deployed_phase_relay_anchor("map_object_instance.phase_return_anchor_tether")
	manual_world.set_active_phase_relay_anchor("map_object_instance.phase_return_anchor")
	var manual_result: Dictionary = host.quest_runtime.reconcile_active_objectives(manual_world, manual_character)
	host._expect_equal(bool(manual_result.get("accepted", false)), false, "runtime leaves manual tether relay selection unchanged")
	host._expect_equal(
		manual_world.active_phase_relay_anchor_id,
		"map_object_instance.phase_return_anchor",
		"runtime does not overwrite manually selected deployed relay anchor"
	)


func _check_runtime_restores_phase_well_anchor_core_followup() -> void:
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
		"quest.inspect_phase_well_loom",
		"quest.analyze_phase_well_weave_core",
		"quest.collect_selvedge_strip",
		"quest.refine_selvedge_strip",
		"quest.assemble_phase_well_frame_key",
		"quest.inspect_phase_well_frame",
		"quest.analyze_phase_well_knot_core",
		"quest.collect_tether_fiber",
		"quest.refine_tether_fiber",
		"quest.assemble_phase_well_tether_spike",
		"quest.inspect_phase_well_tether"
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
		"recipe.phase_well_shuttle",
		"recipe.phase_well_weave_core_analysis",
		"region.phase_well_frame",
		"recipe.selvedge_strip_stabilization",
		"recipe.phase_well_frame_key",
		"recipe.phase_well_knot_core_analysis",
		"region.phase_well_tether",
		"recipe.tether_fiber_stabilization",
		"recipe.phase_well_tether_spike"
	]

	var result: Dictionary = host.quest_runtime.reconcile_active_objectives(world_state, character_state)
	host._expect_equal(bool(result.get("accepted", false)), true, "runtime accepts phase well anchor core followup restoration")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.phase_well_anchor_core_analysis", "runtime restores missing anchor core analysis unlock")
	host._expect_equal(int(character_state.inventory.items.get("item.phase_well_anchor_core", 0)), 1, "runtime restores missing anchor core reward")
	host._expect_array_has(world_state.quest_state.active_quest_ids, "quest.analyze_phase_well_anchor_core", "runtime activates anchor core analysis quest")
	host._expect_equal(host._result_array_size(result, "completion_feedbacks"), 0, "anchor core followup restoration should not emit completion feedback")
	if not host._result_logs_contain(result, "相位井锚核已补回背包"):
		host.failures.append("phase well anchor core restoration should log restored anchor core reward, got %s" % var_to_str(result))
	if not host._result_logs_contain(result, "井系桥后的锚场回稳后续任务"):
		host.failures.append("phase well anchor core restoration should log anchor-field followup activation, got %s" % var_to_str(result))


func _check_demo_stabilization_event_rules() -> void:
	var quest_state := QuestState.create_default()
	var updates: Array = host.event_rules.get_region_objective_updates("region.demo_stabilization_core", quest_state)
	host._expect_update(updates, "set", "quest.enter_demo_stabilization_core", "visit_region", "region.demo_stabilization_core", 1.0, "demo core region visit update")

	updates = host.event_rules.get_defeated_enemy_objective_updates("enemy.demo_stabilization_guard")
	host._expect_update(updates, "set", "quest.defeat_demo_stabilization_guard", "defeat_enemy", "enemy.demo_stabilization_guard", 1.0, "demo guard defeat update")

	updates = host.event_rules.get_interaction_objective_updates(
		{
			"definition_id": "map_object.demo_stabilization_core",
			"interaction_type": "inspect"
		},
		{},
		quest_state
	)
	host._expect_update(updates, "set", "quest.write_demo_stabilization_core", "inspect", "map_object.demo_stabilization_core", 1.0, "demo core inspect update")


func _check_runtime_activates_demo_stabilization_core_entry() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	world_state.quest_state.active_quest_ids.clear()
	world_state.quest_state.completed_quest_ids.append("quest.calibrate_phase_well_stability_window")
	world_state.set_base_action_state_value(
		BaseActionDispatchPlan.FRONTLINE_WINDOW_REVIEW_COUNT_KEY,
		BaseActionDispatchPlan.FRONTLINE_WINDOW_REVIEW_LIMIT + 1
	)

	var result: Dictionary = host.quest_runtime.reconcile_active_objectives(world_state, character_state)
	host._expect_equal(bool(result.get("accepted", false)), true, "overpressure review activates demo core entry")
	host._expect_array_has(world_state.unlocked_region_ids, "region.demo_stabilization_core", "overpressure review unlocks demo core")
	host._expect_array_has(world_state.quest_state.active_quest_ids, "quest.enter_demo_stabilization_core", "overpressure review activates demo core entry quest")


func _check_demo_stabilization_three_step_flow() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	var gather_system := GatherSystem.new(host.data_registry)
	world_state.unlock_region("region.demo_stabilization_core")
	world_state.current_region_id = "region.demo_stabilization_core"
	character_state.current_region_id = "region.demo_stabilization_core"
	world_state.quest_state.active_quest_ids = ["quest.enter_demo_stabilization_core"]

	var result: Dictionary = host.quest_runtime.advance_for_region(world_state, character_state, "region.demo_stabilization_core")
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.enter_demo_stabilization_core", "enter demo core quest completes on region visit")
	host._expect_array_has(world_state.quest_state.active_quest_ids, "quest.defeat_demo_stabilization_guard", "enter demo core activates guard quest")
	host._expect_equal(host._result_array_size(result, "completion_feedbacks"), 1, "enter demo core emits completion feedback")

	result = host.quest_runtime.advance_for_defeated_enemy(world_state, character_state, "enemy.demo_stabilization_guard")
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.defeat_demo_stabilization_guard", "demo guard defeat quest completes")
	host._expect_array_has(world_state.quest_state.active_quest_ids, "quest.write_demo_stabilization_core", "guard defeat activates core write quest")

	var blocked_world := WorldState.create_default()
	blocked_world.quest_state.active_quest_ids = ["quest.write_demo_stabilization_core"]
	var blocked := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"inspect",
		character_state,
		blocked_world
	)
	host._expect_equal(bool(blocked.get("success", true)), false, "core write should be blocked before guard defeat")
	var blocked_message := String(blocked.get("message", ""))
	if blocked_message.find("核心阶段守卫") < 0:
		host.failures.append("core write blocker should mention guard, got %s" % blocked_message)

	world_state.ensure_enemy("enemy_instance.demo_stabilization_guard", "enemy.demo_stabilization_guard", "region.demo_stabilization_core", 156.0)
	world_state.update_enemy_health("enemy_instance.demo_stabilization_guard", 0.0, true)
	var interaction_result := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"inspect",
		character_state,
		world_state
	)
	host._expect_equal(bool(interaction_result.get("success", false)), true, "core write interaction succeeds after guard defeat")
	result = host.quest_runtime.advance_for_interaction(
		world_state,
		character_state,
		{
			"definition_id": "map_object.demo_stabilization_core",
			"interaction_type": "inspect"
		},
		interaction_result
	)
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.write_demo_stabilization_core", "core write quest completes")
	host._expect_equal(host._result_array_size(result, "completion_feedbacks"), 1, "core write emits completion feedback")
	if host._result_array_size(result, "completion_feedbacks") > 0:
		var feedbacks: Array = result.get("completion_feedbacks", [])
		var feedback = feedbacks[0]
		if not feedback is Dictionary:
			host.failures.append("core write completion feedback should be a dictionary, got %s" % var_to_str(feedback))
			return
		host._expect_equal(String(feedback.get("panel_title", "")), "Demo 完成", "core write completion uses demo panel title")


func _check_demo_stabilization_short_run_from_overpressure_archive() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	var gather_system := GatherSystem.new(host.data_registry)
	world_state.quest_state.active_quest_ids.clear()
	world_state.quest_state.completed_quest_ids.append("quest.calibrate_phase_well_stability_window")
	world_state.set_base_action_state_value(
		BaseActionDispatchPlan.FRONTLINE_WINDOW_REVIEW_COUNT_KEY,
		BaseActionDispatchPlan.FRONTLINE_WINDOW_REVIEW_LIMIT + 1
	)
	world_state.set_base_action_state_value(
		BaseActionDispatchPlan.FRONTLINE_WINDOW_ARCHIVED_FEEDBACK_KEY,
		"高压窗口稳定数据已归档"
	)

	var result: Dictionary = host.quest_runtime.reconcile_active_objectives(world_state, character_state)
	host._expect_equal(bool(result.get("accepted", false)), true, "short run accepts overpressure archive state")
	host._expect_array_has(world_state.unlocked_region_ids, "region.demo_stabilization_core", "short run unlocks demo core region")
	host._expect_array_has(world_state.quest_state.active_quest_ids, "quest.enter_demo_stabilization_core", "short run activates demo core entry")
	if not host._result_logs_contain(result, "核心稳定站已接入"):
		host.failures.append("short run should log demo core entry activation, got %s" % var_to_str(result))

	world_state.current_region_id = "region.demo_stabilization_core"
	character_state.current_region_id = "region.demo_stabilization_core"
	result = host.quest_runtime.advance_for_region(world_state, character_state, "region.demo_stabilization_core")
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.enter_demo_stabilization_core", "short run completes demo core entry")
	host._expect_array_has(world_state.quest_state.active_quest_ids, "quest.defeat_demo_stabilization_guard", "short run activates guard objective")

	var repair_before := int(character_state.inventory.items.get("item.repair_gel", 0))
	var recovery_result := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_recovery_wreckage",
		"map_object.demo_stabilization_recovery_cache",
		"gather",
		character_state,
		world_state
	)
	host._expect_equal(bool(recovery_result.get("success", false)), true, "short run side recovery cache can be gathered")
	host._expect_equal(
		int(character_state.inventory.items.get("item.repair_gel", 0)),
		repair_before + 1,
		"short run side recovery grants repair gel"
	)
	host._expect_array_missing(world_state.quest_state.completed_quest_ids, "quest.write_demo_stabilization_core", "side recovery should not complete demo")

	result = host.quest_runtime.advance_for_defeated_enemy(world_state, character_state, "enemy.demo_stabilization_guard")
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.defeat_demo_stabilization_guard", "short run completes guard defeat")
	host._expect_array_has(world_state.quest_state.active_quest_ids, "quest.write_demo_stabilization_core", "short run activates core write")
	world_state.ensure_enemy("enemy_instance.demo_stabilization_guard", "enemy.demo_stabilization_guard", "region.demo_stabilization_core", 156.0)
	world_state.update_enemy_health("enemy_instance.demo_stabilization_guard", 0.0, true)

	var write_result := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"inspect",
		character_state,
		world_state
	)
	host._expect_equal(bool(write_result.get("success", false)), true, "short run writes demo stabilization core")
	result = host.quest_runtime.advance_for_interaction(
		world_state,
		character_state,
		{
			"definition_id": "map_object.demo_stabilization_core",
			"interaction_type": "inspect"
		},
		write_result
	)
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.write_demo_stabilization_core", "short run completes demo core write")
	host._expect_equal(host._result_array_size(result, "completion_feedbacks"), 1, "short run emits demo completion feedback")
