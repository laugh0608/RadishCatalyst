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
