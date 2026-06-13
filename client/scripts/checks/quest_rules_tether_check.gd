extends RefCounted

const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")

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
	_check_demo_stabilization_four_step_flow()
	_check_demo_stabilization_short_run_from_overpressure_archive()
	_check_core_stabilization_buffer_reduces_guard_pressure()
	_check_demo_stabilization_core_write_pressure()


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
	if not host._result_logs_contain(result, "锚定结核已补回背包"):
		host.failures.append("phase well knot core restoration should log restored knot core reward, got %s" % var_to_str(result))
	if not host._result_logs_contain(result, "锁相框架后的锚定桥后续任务"):
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
	if not host._result_logs_contain(result, "稳场锚核已补回背包"):
		host.failures.append("phase well anchor core restoration should log restored anchor core reward, got %s" % var_to_str(result))
	if not host._result_logs_contain(result, "锚定桥后的锚场回稳后续任务"):
		host.failures.append("phase well anchor core restoration should log anchor-field followup activation, got %s" % var_to_str(result))


func _check_demo_stabilization_event_rules() -> void:
	var quest_state := QuestState.create_default()
	var updates: Array = host.event_rules.get_region_objective_updates("region.demo_stabilization_core", quest_state)
	host._expect_update(updates, "set", "quest.enter_demo_stabilization_core", "visit_region", "region.demo_stabilization_core", 1.0, "demo core region visit update")

	updates = host.event_rules.get_defeated_enemy_objective_updates("enemy.demo_stabilization_guard")
	host._expect_update(updates, "set", "quest.defeat_demo_stabilization_guard", "defeat_enemy", "enemy.demo_stabilization_guard", 1.0, "demo guard defeat update")
	updates = host.event_rules.get_defeated_enemy_objective_updates("enemy.polluted_skitter")
	host._expect_update(updates, "set", "quest.prepare_demo_stabilization_buffer", "defeat_enemy", "enemy.polluted_skitter", 1.0, "core buffer supply guard update")
	updates = host.event_rules.get_recipe_objective_updates("recipe.core_stabilization_buffer")
	host._expect_update(updates, "set", "quest.prepare_demo_stabilization_buffer", "craft_item", "item.core_stabilization_buffer", 1.0, "core buffer recipe update")

	updates = host.event_rules.get_interaction_objective_updates(
		{
			"definition_id": "map_object.pollution_residue_patch",
			"interaction_type": "gather"
		},
		{},
		quest_state
	)
	host._expect_update(updates, "add", "quest.prepare_demo_stabilization_buffer", "gather_item", "item.polluted_residue", 2.0, "core buffer residue gather update")

	updates = host.event_rules.get_interaction_objective_updates(
		{
			"definition_id": "map_object.demo_stabilization_guard_cache",
			"interaction_type": "gather"
		},
		{},
		quest_state
	)
	host._expect_update(updates, "add", "quest.write_demo_stabilization_core", "gather_item", "item.core_write_charge", 1.0, "demo guard cache gather update")

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


func _check_demo_stabilization_four_step_flow() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	var gather_system := GatherSystem.new(host.data_registry)
	world_state.unlock_region("region.demo_stabilization_core")
	world_state.current_region_id = "region.demo_stabilization_core"
	character_state.current_region_id = "region.demo_stabilization_core"
	world_state.quest_state.active_quest_ids = ["quest.enter_demo_stabilization_core"]

	var result: Dictionary = host.quest_runtime.advance_for_region(world_state, character_state, "region.demo_stabilization_core")
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.enter_demo_stabilization_core", "enter demo core quest completes on region visit")
	host._expect_array_has(world_state.quest_state.active_quest_ids, "quest.prepare_demo_stabilization_buffer", "enter demo core activates buffer preparation")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.core_stabilization_buffer", "enter demo core unlocks core buffer recipe")
	host._expect_equal(host._result_array_size(result, "completion_feedbacks"), 1, "enter demo core emits completion feedback")
	var status_text := HudStatusPresenter.new().format_status_text(host.data_registry, world_state, character_state)
	_expect_text_contains(status_text, "目标：整备核心稳压缓冲包", "enter demo core status points to buffer prep")
	_expect_text_contains(status_text, "进度：收集 污染沉积物（核心缓冲补料沉积） 0/2", "enter demo core status shows buffer supply progress")

	result = _complete_core_buffer_preparation(world_state, character_state)
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.prepare_demo_stabilization_buffer", "core buffer prep quest completes")
	host._expect_array_has(world_state.quest_state.active_quest_ids, "quest.defeat_demo_stabilization_guard", "core buffer prep activates guard quest")
	host._expect_equal(int(character_state.inventory.items.get("item.core_stabilization_buffer", 0)), 1, "core buffer remains in inventory for guard pressure")
	status_text = HudStatusPresenter.new().format_status_text(host.data_registry, world_state, character_state)
	_expect_text_contains(status_text, "目标：击败核心阶段守卫", "buffer completion status points to guard")
	_expect_text_contains(status_text, "进度：击败 核心阶段守卫 0/1", "buffer completion status shows guard progress")

	result = host.quest_runtime.advance_for_defeated_enemy(world_state, character_state, "enemy.demo_stabilization_guard")
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.defeat_demo_stabilization_guard", "demo guard defeat quest completes")
	host._expect_array_has(world_state.quest_state.active_quest_ids, "quest.write_demo_stabilization_core", "guard defeat activates core write quest")
	status_text = HudStatusPresenter.new().format_status_text(host.data_registry, world_state, character_state)
	_expect_text_contains(status_text, "目标：写入核心稳定数据", "guard defeat status points to core write")
	_expect_text_contains(status_text, "收集 核心写入校验片（核心守卫回写缓存） 0/1", "guard defeat status shows guard cache progress")

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
	var blocked_feedback: Dictionary = blocked.get("failure_feedback", {})
	_expect_text_contains(String(blocked_feedback.get("detail", "")), "击败核心阶段守卫", "core write blocker detail explains guard step")

	world_state.ensure_enemy("enemy_instance.demo_stabilization_guard", "enemy.demo_stabilization_guard", "region.demo_stabilization_core", 156.0)
	world_state.update_enemy_health("enemy_instance.demo_stabilization_guard", 0.0, true)
	var blocked_without_charge := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"inspect",
		character_state,
		world_state
	)
	host._expect_equal(bool(blocked_without_charge.get("success", true)), false, "core write should be blocked before guard cache recovery")
	_expect_text_contains(String(blocked_without_charge.get("message", "")), "核心写入校验片", "core write blocker explains guard cache requirement")

	var cache_result := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_guard_cache",
		"map_object.demo_stabilization_guard_cache",
		"gather",
		character_state,
		world_state
	)
	host._expect_equal(bool(cache_result.get("success", false)), true, "guard cache can be gathered after guard defeat")
	_expect_text_contains(String(cache_result.get("message", "")), "核心写入校验片已回收", "guard cache gather message points to core write")
	result = host.quest_runtime.advance_for_interaction(
		world_state,
		character_state,
		{
			"definition_id": "map_object.demo_stabilization_guard_cache",
			"interaction_type": "gather"
		},
		cache_result
	)
	if not host._result_logs_contain(result, "核心写入校验片已回收"):
		host.failures.append("guard cache objective should log next step, got %s" % var_to_str(result))
	var vial_before_write := int(character_state.inventory.items.get("item.resistance_vial_t1", 0))
	var interaction_result := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"inspect",
		character_state,
		world_state
	)
	host._expect_equal(bool(interaction_result.get("success", false)), true, "core write interaction succeeds after guard defeat")
	_expect_text_contains(String(interaction_result.get("message", "")), "核心稳定数据已写入", "core write interaction explains stable data write")
	_expect_text_contains(String(interaction_result.get("message", "")), "第一条稳定通道已打开", "core write interaction explains demo payoff")
	_expect_text_contains(String(interaction_result.get("message", "")), "抗污染药剂已自动接入写入排压", "core write consumes guard cache vial for pressure venting")
	host._expect_equal(int(character_state.inventory.items.get("item.resistance_vial_t1", 0)), maxi(0, vial_before_write - 1), "core write consumes one resistance vial when available")
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
		_expect_text_contains(String(feedback.get("note_text", "")), "首版 demo 主线目标已完成", "core write completion note explains slice completion")


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
	host._expect_array_has(world_state.quest_state.active_quest_ids, "quest.prepare_demo_stabilization_buffer", "short run activates buffer objective")
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.core_stabilization_buffer", "short run unlocks core buffer recipe")
	var status_text := HudStatusPresenter.new().format_status_text(host.data_registry, world_state, character_state)
	_expect_text_contains(status_text, "目标：整备核心稳压缓冲包", "short run status points to buffer prep")
	_expect_text_contains(status_text, "进度：收集 污染沉积物（核心缓冲补料沉积） 0/2", "short run status shows buffer supply objective")

	var repair_before := int(character_state.inventory.items.get("item.repair_gel", 0))
	var vial_before := int(character_state.inventory.items.get("item.resistance_vial_t1", 0))
	var recovery_result := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_recovery_cache",
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
	host._expect_equal(
		int(character_state.inventory.items.get("item.resistance_vial_t1", 0)),
		vial_before + 1,
		"short run side recovery grants resistance vial"
	)
	_expect_text_contains(
		String(recovery_result.get("message", "")),
		"抗污染药剂",
		"short run side recovery explains pressure vial supply"
	)
	host._expect_array_missing(world_state.quest_state.completed_quest_ids, "quest.write_demo_stabilization_core", "side recovery should not complete demo")

	result = _complete_core_buffer_preparation(world_state, character_state)
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.prepare_demo_stabilization_buffer", "short run completes buffer prep")
	host._expect_array_has(world_state.quest_state.active_quest_ids, "quest.defeat_demo_stabilization_guard", "short run activates guard after buffer")

	result = host.quest_runtime.advance_for_defeated_enemy(world_state, character_state, "enemy.demo_stabilization_guard")
	host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.defeat_demo_stabilization_guard", "short run completes guard defeat")
	host._expect_array_has(world_state.quest_state.active_quest_ids, "quest.write_demo_stabilization_core", "short run activates core write")
	status_text = HudStatusPresenter.new().format_status_text(host.data_registry, world_state, character_state)
	_expect_text_contains(status_text, "目标：写入核心稳定数据", "short run status points to core write after guard")
	_expect_text_contains(status_text, "收集 核心写入校验片（核心守卫回写缓存） 0/1", "short run status shows guard cache objective")
	world_state.ensure_enemy("enemy_instance.demo_stabilization_guard", "enemy.demo_stabilization_guard", "region.demo_stabilization_core", 156.0)
	world_state.update_enemy_health("enemy_instance.demo_stabilization_guard", 0.0, true)

	var guard_cache_result := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_guard_cache",
		"map_object.demo_stabilization_guard_cache",
		"gather",
		character_state,
		world_state
	)
	host._expect_equal(bool(guard_cache_result.get("success", false)), true, "short run recovers guard cache")
	host._expect_equal(int(character_state.inventory.items.get("item.core_write_charge", 0)), 1, "short run guard cache grants write charge")
	result = host.quest_runtime.advance_for_interaction(
		world_state,
		character_state,
		{
			"definition_id": "map_object.demo_stabilization_guard_cache",
			"interaction_type": "gather"
		},
		guard_cache_result
	)

	var write_result := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"inspect",
		character_state,
		world_state
	)
	host._expect_equal(bool(write_result.get("success", false)), true, "short run writes demo stabilization core")
	_expect_text_contains(String(write_result.get("message", "")), "核心稳定数据已写入", "short run core write explains stable data")
	_expect_text_contains(String(write_result.get("message", "")), "核心站侧边补给", "short run core write reads side recovery cache")
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
	if host._result_array_size(result, "completion_feedbacks") > 0:
		var feedbacks: Array = result.get("completion_feedbacks", [])
		var feedback = feedbacks[0]
		if feedback is Dictionary:
			_expect_text_contains(String(feedback.get("note_text", "")), "首版 demo 主线目标已完成", "short run completion explains demo finish")


func _check_core_stabilization_buffer_reduces_guard_pressure() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	host.root.add_child(map)
	map.setup(host.data_registry)
	var guard := map.get_node("Enemies/DemoStabilizationGuard") as PrototypeEnemy
	var no_buffer_character := CharacterState.create_default()
	var no_buffer_message := map._apply_enemy_counterattack(guard, no_buffer_character)
	host._expect_equal(int(roundf(no_buffer_character.health * 10.0)), 800, "core guard full pressure health damage")
	host._expect_equal(int(roundf(no_buffer_character.protection * 10.0)), 900, "core guard full pressure protection damage")
	_expect_text_contains(no_buffer_message, "没有核心稳压缓冲包", "core guard no-buffer pressure message")

	var buffered_world := WorldState.create_default()
	buffered_world.ensure_enemy("enemy_instance.demo_stabilization_guard", "enemy.demo_stabilization_guard", "region.demo_stabilization_core", 156.0)
	var buffered_character := CharacterState.create_default()
	buffered_character.inventory.add_item("item.core_stabilization_buffer", 1)
	var buffered_message := map._apply_enemy_counterattack(guard, buffered_character, buffered_world)
	host._expect_equal(int(roundf(buffered_character.health * 10.0)), 890, "core buffer reduces guard health pressure")
	host._expect_equal(int(roundf(buffered_character.protection * 10.0)), 945, "core buffer reduces guard protection pressure")
	host._expect_equal(int(buffered_character.inventory.items.get("item.core_stabilization_buffer", 0)), 0, "core buffer is consumed by first guard pressure")
	host._expect_equal(bool(buffered_world.get_enemy("enemy_instance.demo_stabilization_guard").get("core_buffer_used", false)), true, "core buffer pressure records guard sync")
	_expect_text_contains(buffered_message, "核心稳压缓冲包已消耗", "core guard buffer pressure message")
	map.free()


func _check_demo_stabilization_core_write_pressure() -> void:
	var gather_system := GatherSystem.new(host.data_registry)

	var fully_prepared_world := _create_core_write_ready_world()
	fully_prepared_world.get_enemy("enemy_instance.demo_stabilization_guard")["core_buffer_used"] = true
	fully_prepared_world.ensure_map_object(
		"map_object_instance.demo_stabilization_recovery_cache",
		"map_object.demo_stabilization_recovery_cache",
		"region.demo_stabilization_core"
	)
	fully_prepared_world.set_map_object_flag("map_object_instance.demo_stabilization_recovery_cache", "is_gathered", true)
	fully_prepared_world.ensure_map_object(
		"map_object_instance.demo_stabilization_guard_cache",
		"map_object.demo_stabilization_guard_cache",
		"region.demo_stabilization_core"
	)
	fully_prepared_world.set_map_object_flag("map_object_instance.demo_stabilization_guard_cache", "is_gathered", true)
	var fully_prepared_character := CharacterState.create_default()
	fully_prepared_character.inventory.add_item("item.resistance_vial_t1", 1)
	var fully_prepared_result := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"inspect",
		fully_prepared_character,
		fully_prepared_world
	)
	host._expect_equal(bool(fully_prepared_result.get("success", false)), true, "core write with full terminal preparation succeeds")
	_expect_text_contains(String(fully_prepared_result.get("message", "")), "核心站侧边补给", "core write reads side recovery cache")
	_expect_text_contains(String(fully_prepared_result.get("message", "")), "守卫回写缓存", "core write reads guard writeback cache")
	_expect_text_contains(String(fully_prepared_result.get("message", "")), "终点前整备同时降低守卫和核心设备承压", "core write explains full preparation payoff")
	host._expect_equal(int(fully_prepared_character.inventory.items.get("item.resistance_vial_t1", 0)), 0, "core write with full preparation consumes one vial")
	host._expect_equal(int(roundf(fully_prepared_character.health * 10.0)), 976, "side cache, guard cache, guard sync and vial reduce write health pressure")
	host._expect_equal(int(roundf(fully_prepared_character.protection * 10.0)), 964, "side cache, guard cache, guard sync and vial reduce write protection pressure")

	var synced_world := _create_core_write_ready_world()
	synced_world.get_enemy("enemy_instance.demo_stabilization_guard")["core_buffer_used"] = true
	var synced_character := CharacterState.create_default()
	synced_character.inventory.add_item("item.resistance_vial_t1", 1)
	var synced_result := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"inspect",
		synced_character,
		synced_world
	)
	host._expect_equal(bool(synced_result.get("success", false)), true, "core write with guard sync and vial succeeds")
	_expect_text_contains(String(synced_result.get("message", "")), "终点前整备同时降低守卫和核心设备承压", "core write reads guard sync")
	host._expect_equal(int(synced_character.inventory.items.get("item.resistance_vial_t1", 0)), 0, "core write with guard sync consumes one vial")
	host._expect_equal(int(roundf(synced_character.health * 10.0)), 969, "guard sync and vial reduce write health pressure")
	host._expect_equal(int(roundf(synced_character.protection * 10.0)), 953, "guard sync and vial reduce write protection pressure")

	var vial_world := _create_core_write_ready_world()
	var vial_character := CharacterState.create_default()
	vial_character.inventory.add_item("item.resistance_vial_t1", 1)
	var vial_result := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"inspect",
		vial_character,
		vial_world
	)
	host._expect_equal(bool(vial_result.get("success", false)), true, "core write with vial succeeds")
	_expect_text_contains(String(vial_result.get("message", "")), "抗污染药剂已自动接入写入排压", "core write with vial explains pressure venting")
	host._expect_equal(int(vial_character.inventory.items.get("item.resistance_vial_t1", 0)), 0, "core write with vial consumes one vial")
	host._expect_equal(int(roundf(vial_character.health * 10.0)), 958, "core write with vial reduces health pressure")
	host._expect_equal(int(roundf(vial_character.protection * 10.0)), 937, "core write with vial reduces protection pressure")

	var synced_no_vial_world := _create_core_write_ready_world()
	synced_no_vial_world.get_enemy("enemy_instance.demo_stabilization_guard")["core_buffer_used"] = true
	var synced_no_vial_character := CharacterState.create_default()
	var synced_no_vial_result := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"inspect",
		synced_no_vial_character,
		synced_no_vial_world
	)
	host._expect_equal(bool(synced_no_vial_result.get("success", false)), true, "core write with guard sync and no vial still succeeds")
	_expect_text_contains(String(synced_no_vial_result.get("message", "")), "核心设备承压低于无准备写入", "core write guard sync without vial explains partial pressure relief")
	host._expect_equal(int(roundf(synced_no_vial_character.health * 10.0)), 910, "guard sync without vial reduces health pressure")
	host._expect_equal(int(roundf(synced_no_vial_character.protection * 10.0)), 865, "guard sync without vial reduces protection pressure")

	var guard_cache_world := _create_core_write_ready_world()
	guard_cache_world.ensure_map_object(
		"map_object_instance.demo_stabilization_guard_cache",
		"map_object.demo_stabilization_guard_cache",
		"region.demo_stabilization_core"
	)
	guard_cache_world.set_map_object_flag("map_object_instance.demo_stabilization_guard_cache", "is_gathered", true)
	var guard_cache_character := CharacterState.create_default()
	var guard_cache_result := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"inspect",
		guard_cache_character,
		guard_cache_world
	)
	host._expect_equal(bool(guard_cache_result.get("success", false)), true, "core write with guard cache only succeeds")
	_expect_text_contains(String(guard_cache_result.get("message", "")), "守卫回写缓存", "core write guard cache explains writeback calibration")
	_expect_text_contains(String(guard_cache_result.get("message", "")), "核心设备承压低于无准备写入", "core write guard cache explains partial pressure relief")
	host._expect_equal(int(roundf(guard_cache_character.health * 10.0)), 892, "guard cache lowers write health pressure")
	host._expect_equal(int(roundf(guard_cache_character.protection * 10.0)), 838, "guard cache lowers write protection pressure")

	var plain_world := _create_core_write_ready_world()
	var plain_character := CharacterState.create_default()
	var plain_result := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"inspect",
		plain_character,
		plain_world
	)
	host._expect_equal(bool(plain_result.get("success", false)), true, "core write without vial still succeeds")
	_expect_text_contains(String(plain_result.get("message", "")), "没有抗污染药剂参与排压", "core write without vial explains full pressure")
	host._expect_equal(int(roundf(plain_character.health * 10.0)), 880, "core write without vial health pressure")
	host._expect_equal(int(roundf(plain_character.protection * 10.0)), 820, "core write without vial protection pressure")


func _create_core_write_ready_world() -> WorldState:
	var world_state := WorldState.create_default()
	world_state.quest_state.active_quest_ids = ["quest.write_demo_stabilization_core"]
	world_state.quest_state.set_objective_progress("quest.write_demo_stabilization_core", "gather_item", "item.core_write_charge", 1.0)
	world_state.ensure_enemy("enemy_instance.demo_stabilization_guard", "enemy.demo_stabilization_guard", "region.demo_stabilization_core", 156.0)
	world_state.update_enemy_health("enemy_instance.demo_stabilization_guard", 0.0, true)
	return world_state


func _complete_core_buffer_preparation(world_state: WorldState, character_state: CharacterState) -> Dictionary:
	var gather_system := GatherSystem.new(host.data_registry)
	var residue_result := gather_system.interact_with_object(
		"map_object_instance.core_buffer_residue_cache",
		"map_object.pollution_residue_patch",
		"gather",
		character_state,
		world_state
	)
	host._expect_equal(bool(residue_result.get("success", false)), true, "core buffer residue cache can be gathered")
	host.quest_runtime.advance_for_interaction(
		world_state,
		character_state,
		{"definition_id": "map_object.pollution_residue_patch", "interaction_type": "gather"},
		residue_result
	)
	host.quest_runtime.advance_for_defeated_enemy(world_state, character_state, "enemy.polluted_skitter")

	world_state.add_base_structure("structure.pollution_filter_build_site", "building.pollution_filter", "region.pollution_edge")
	world_state.add_base_structure("structure.basic_reactor", "building.basic_reactor", "region.outpost_platform")
	world_state.quest_state.unlock_effect("recipe.cleanse_residue")
	world_state.quest_state.unlock_effect("recipe.core_stabilization_buffer")
	character_state.inventory.add_fluid("fluid.basic_solvent", 1.0)
	var processing := ProcessingSystem.new(host.data_registry)
	var cleanse_start := processing.process_recipe("recipe.cleanse_residue", character_state, world_state)
	host._expect_equal(bool(cleanse_start.get("success", false)), true, "core buffer residue can be filtered into slurry")
	processing.advance_processing(13.0, character_state, world_state)
	if not character_state.inventory.has_ref("item.repair_gel", 1):
		character_state.inventory.add_item("item.repair_gel", 1)
	var basic_parts_shortage := maxi(0, 2 - int(character_state.inventory.items.get("item.basic_parts", 0)))
	if basic_parts_shortage > 0:
		character_state.inventory.add_item("item.basic_parts", basic_parts_shortage)
	var buffer_start := processing.process_recipe("recipe.core_stabilization_buffer", character_state, world_state)
	host._expect_equal(bool(buffer_start.get("success", false)), true, "core buffer can be crafted from filtered supply")
	processing.advance_processing(8.0, character_state, world_state)
	return host.quest_runtime.advance_for_interaction(
		world_state,
		character_state,
		{"interaction_type": "process_recipe", "recipe_id": "recipe.core_stabilization_buffer"},
		{"success": true, "completed_recipe_id": "recipe.core_stabilization_buffer"}
	)


func _expect_text_contains(text: String, expected_text: String, label: String) -> void:
	if text.find(expected_text) < 0:
		host.failures.append("%s should contain %s, got %s" % [label, expected_text, text])
