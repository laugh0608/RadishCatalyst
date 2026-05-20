extends SceneTree
const GameRootScript := preload("res://scripts/game/game_root.gd")
const DeepProcessingCheckScript := preload("res://scripts/checks/deep_processing_check.gd")
const BaseActionTargetPromptCheckScript := preload("res://scripts/checks/base_action_target_prompt_check.gd")
const HudRuntimeHintFlowCheckScript := preload("res://scripts/checks/hud_runtime_hint_flow_check.gd")
const HudMapMarkerCheckScript := preload("res://scripts/checks/hud_map_marker_check.gd")
const PhaseWellFollowupChecks := preload("res://scripts/checks/phase_well_followup_check.gd")
const PhaseRelayFlowChecks := preload("res://scripts/checks/phase_relay_flow_check.gd")
const RegionPromptChecks := preload("res://scripts/checks/region_prompt_check.gd")
const VerticalSliceRegressionChecks := preload("res://scripts/checks/vertical_slice_regression_check.gd")
const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")
var failures: Array[String] = []
var data_registry := DataRegistry.new()
var world_state := WorldState.create_default()
var character_state := CharacterState.create_default()
func _init() -> void:
	_run_checks()
	if failures.is_empty():
		print("Vertical slice flow checks passed.")
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
	_expect_equal(world_state.quest_state.active_quest_ids, ["quest.restore_outpost"], "initial active quest")
	_check_onboarding_hints()
	_check_runtime_hint_prompt_flow()
	_check_status_panel_summary()
	HudMapMarkerCheckScript.new(self).run(root)
	_check_region_presence_bounds()
	_check_pollution_gate_runtime_bounds()
	BaseActionTargetPromptCheckScript.new(self).run()
	PhaseWellFollowupChecks.new(self).run_hud_and_map_checks()
	_check_deep_gate_releases_movement_block()
	_check_new_game_state_reset()
	_check_outpost_core_restored_visual()
	_check_early_interaction_processed_visuals()
	_check_pollution_enemy_defeated_visual()
	_check_treatment_enemy_spawn_gate()
	_check_treatment_enemy_combat_pressure()
	_check_quest_completion_panel_text()
	_check_build_prompts()
	_check_supply_feedback()
	_check_hud_feedback_presenter()
	_check_pollution_status_hints()
	RegionPromptChecks.new(self).run()
	PhaseRelayFlowChecks.new(self).run()
	VerticalSliceRegressionChecks.new(self).run_ui_and_recipe_checks()
	_check_failure_feedback_logs()
	_check_device_panel_formatting()
	_check_manual_recipe_cycle_keeps_player_choice()
	_complete_active_quest("quest.restore_outpost", [
		{"type": "interact", "target_id": "building.outpost_core", "amount": 1}
	])
	_expect_active_quest("quest.scout_crystal_field", "after restore outpost")
	_expect_array_has(world_state.unlocked_region_ids, "region.crystal_vein_field", "restore unlocks crystal region")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.process_crystal_ore", "restore unlocks crystal recipe")
	_complete_active_quest("quest.scout_crystal_field", [
		{"type": "visit_region", "target_id": "region.crystal_vein_field", "amount": 1},
		{"type": "gather_item", "target_id": "item.crystal_ore", "amount": 6}
	])
	_expect_active_quest("quest.calibrate_reactor", "after scout crystal field")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.reactor_calibrator", "scout unlocks reactor calibrator recipe")
	_complete_active_quest("quest.calibrate_reactor", [
		{"type": "gather_item", "target_id": "item.salvage_scrap", "amount": 4},
		{"type": "craft_item", "target_id": "item.reactor_calibrator", "amount": 1}
	])
	_expect_active_quest("quest.bring_back_sample", "after calibrate reactor")
	_complete_active_quest("quest.bring_back_sample", [
		{"type": "sample_object", "target_id": "map_object.anomaly_crystal", "amount": 1}
	])
	_expect_active_quest("quest.analyze_anomaly_sample", "after bring back sample")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.analyze_anomaly_sample", "sample unlocks analysis recipe")
	_complete_active_quest("quest.analyze_anomaly_sample", [
		{"type": "gather_item", "target_id": "item.anomaly_residue", "amount": 2},
		{"type": "craft_item", "target_id": "item.sample_analysis", "amount": 1}
	])
	_expect_active_quest("quest.make_filter_module", "after sample analysis")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.make_filter_media", "analysis unlocks filter media recipe")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.basic_filter_module", "analysis unlocks filter module recipe")
	_complete_active_quest("quest.make_filter_module", [
		{"type": "craft_item", "target_id": "equipment.filter_module_t1", "amount": 1}
	])
	_expect_active_quest("quest.prepare_treatment_supplies", "after make filter module")
	_complete_active_quest("quest.prepare_treatment_supplies", [
		{"type": "craft_item", "target_id": "item.repair_gel", "amount": 1},
		{"type": "defeat_enemy", "target_id": "enemy.treatment_skitter", "amount": 1}
	])
	_expect_active_quest("quest.expand_treatment_point", "after prepare treatment supplies")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.foundation_t1", "supplies unlock foundation recipe")
	_complete_active_quest("quest.expand_treatment_point", [
		{"type": "build", "target_id": "building.foundation_t1", "amount": 2},
		{"type": "build", "target_id": "building.pollution_filter", "amount": 1}
	])
	_expect_active_quest("quest.enter_pollution_edge", "after expand treatment point")
	_expect_array_has(world_state.unlocked_region_ids, "region.pollution_edge", "treatment point unlocks pollution edge region")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.cleanse_residue", "treatment point unlocks residue recipe")
	_complete_active_quest("quest.enter_pollution_edge", [
		{"type": "visit_region", "target_id": "region.pollution_edge", "amount": 1},
		{"type": "gather_item", "target_id": "item.polluted_residue", "amount": 2},
		{"type": "craft_item", "target_id": "item.resistance_vial_t1", "amount": 1},
		{"type": "defeat_enemy", "target_id": "enemy.polluted_skitter", "amount": 1}
	])
	_expect_active_quest("quest.defeat_elite_node", "after enter pollution edge")
	_expect_array_has(world_state.quest_state.completed_quest_ids, "quest.enter_pollution_edge", "pollution edge completed")
	_complete_active_quest("quest.defeat_elite_node", [
		{"type": "defeat_enemy", "target_id": "enemy.elite_residue_node", "amount": 1}
	])
	_expect_active_quest("quest.unlock_ruin_signal", "after defeat elite node")
	_expect_array_has(world_state.unlocked_region_ids, "region.locked_ruin_gate", "elite node unlocks ruin gate region")
	_expect_array_has(world_state.quest_state.completed_quest_ids, "quest.defeat_elite_node", "elite node completed")
	_complete_active_quest("quest.unlock_ruin_signal", [
		{"type": "inspect", "target_id": "map_object.ruin_gate", "amount": 1}
	])
	_expect_active_quest("quest.scout_ruin_outer_ring", "after ruin signal opens outer ring")
	_expect_array_has(world_state.quest_state.completed_quest_ids, "quest.unlock_ruin_signal", "ruin signal completed")
	_expect_array_has(world_state.unlocked_region_ids, "region.ruin_outer_ring", "ruin signal unlocks outer ring region")
	_complete_active_quest("quest.scout_ruin_outer_ring", [
		{"type": "visit_region", "target_id": "region.ruin_outer_ring", "amount": 1},
		{"type": "gather_item", "target_id": "item.relay_shard", "amount": 2}
	])
	_expect_active_quest("quest.assemble_phase_anchor", "after ruin outer ring scouting")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.phase_anchor", "outer ring scouting unlocks phase anchor recipe")
	_complete_active_quest("quest.assemble_phase_anchor", [
		{"type": "craft_item", "target_id": "item.phase_anchor", "amount": 1}
	])
	_expect_active_quest("quest.stabilize_outer_ring_barrier", "after phase anchor assembly")
	_complete_active_quest("quest.stabilize_outer_ring_barrier", [
		{"type": "inspect", "target_id": "map_object.outer_ring_barrier", "amount": 1}
	])
	_expect_active_quest("quest.secure_outer_ring_signal", "after stabilizing barrier")
	_complete_active_quest("quest.secure_outer_ring_signal", [
		{"type": "inspect", "target_id": "map_object.outer_ring_console", "amount": 1}
	])
	_expect_active_quest("quest.salvage_signal_echo", "after outer ring secure starts echo salvage")
	_expect_array_has(world_state.quest_state.completed_quest_ids, "quest.secure_outer_ring_signal", "outer ring secure completed")
	_expect_array_has(world_state.quest_state.unlocked_effects, "slice_01_complete", "slice completion unlock")
	_complete_active_quest("quest.salvage_signal_echo", [{"type": "defeat_enemy", "target_id": "enemy.ruin_phase_guard", "amount": 1}, {"type": "inspect", "target_id": "map_object.signal_echo_cache", "amount": 1}])
	_expect_active_quest("quest.analyze_deep_signal", "after signal echo salvage")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.deep_signal_analysis", "echo salvage unlocks deep signal recipe")
	_complete_active_quest("quest.analyze_deep_signal", [{"type": "craft_item", "target_id": "item.deep_ruin_coordinates", "amount": 1}])
	_expect_array_has(world_state.quest_state.completed_quest_ids, "quest.analyze_deep_signal", "deep signal analysis completed")
	_expect_active_quest("quest.unlock_deep_ruin_entrance", "after deep signal analysis opens deep ruin entrance")
	_complete_active_quest("quest.unlock_deep_ruin_entrance", [{"type": "inspect", "target_id": "map_object.deep_ruin_door", "amount": 1}])
	_expect_active_quest("quest.harvest_phase_filament", "after deep ruin door unlocks deep salvage run")
	_expect_array_has(world_state.unlocked_region_ids, "region.deep_ruin_threshold", "deep ruin door unlocks deep region")
	_complete_active_quest("quest.harvest_phase_filament", [{"type": "visit_region", "target_id": "region.deep_ruin_threshold", "amount": 1}, {"type": "defeat_enemy", "target_id": "enemy.deep_ruin_sentinel", "amount": 1}, {"type": "gather_item", "target_id": "item.phase_filament", "amount": 2}])
	_expect_active_quest("quest.refine_phase_filament", "after phase filament salvage returns to filter")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.phase_filament_refining", "phase filament salvage unlocks filter recipe")
	_complete_active_quest("quest.refine_phase_filament", [{"type": "craft_item", "target_id": "item.resonance_filter", "amount": 1}])
	_expect_active_quest("quest.assemble_deep_override", "after filter refinement returns to reactor")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.deep_override_key", "phase filament refinement unlocks override recipe")
	_complete_active_quest("quest.assemble_deep_override", [{"type": "craft_item", "target_id": "item.deep_override_key", "amount": 1}])
	_expect_active_quest("quest.unlock_deep_ruin_cache", "after override assembly returns to deep latch")
	_complete_active_quest("quest.unlock_deep_ruin_cache", [{"type": "inspect", "target_id": "map_object.deep_ruin_latch", "amount": 1}])
	_expect_array_has(world_state.quest_state.completed_quest_ids, "quest.unlock_deep_ruin_cache", "deep ruin cache unlock completed")
	_expect_equal(int(character_state.inventory.items.get("item.deep_ruin_core", 0)), 1, "deep ruin cache grants first deep reward")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.deep_core_imprint", "deep ruin cache unlocks deep core imprint recipe")
	_expect_active_quest("quest.analyze_deep_core", "after deep ruin cache starts deep core analysis")
	_complete_active_quest("quest.analyze_deep_core", [{"type": "craft_item", "target_id": "item.deep_route_imprint", "amount": 1}])
	_expect_active_quest("quest.activate_deep_array", "after deep core analysis returns to deep array")
	_complete_active_quest("quest.activate_deep_array", [{"type": "inspect", "target_id": "map_object.deep_signal_array", "amount": 1}, {"type": "defeat_enemy", "target_id": "enemy.deep_ruin_stalker", "amount": 1}, {"type": "gather_item", "target_id": "item.phase_conduit", "amount": 2}])
	_expect_active_quest("quest.assemble_deep_signal_matrix", "after deep array activation returns to reactor")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.deep_signal_matrix", "deep array activation unlocks deep signal matrix recipe")
	_complete_active_quest("quest.assemble_deep_signal_matrix", [{"type": "craft_item", "target_id": "item.deep_signal_matrix", "amount": 1}])
	_expect_active_quest("quest.deploy_phase_relay_anchor", "after deep signal matrix assembly returns to deep anchor")
	_expect_array_has(world_state.quest_state.completed_quest_ids, "quest.assemble_deep_signal_matrix", "deep signal matrix quest completed")
	_complete_active_quest("quest.deploy_phase_relay_anchor", [{"type": "inspect", "target_id": "map_object.phase_return_anchor", "amount": 1}])
	_expect_equal(world_state.quest_state.active_quest_ids, ["quest.reenter_phase_frontline"], "after phase relay anchor deployment should activate relay reentry quest")
	_expect_array_has(world_state.quest_state.completed_quest_ids, "quest.deploy_phase_relay_anchor", "phase relay anchor deployment quest completed")
	_complete_active_quest("quest.reenter_phase_frontline", [{"type": "inspect", "target_id": "map_object.phase_relay_pad", "amount": 1}])
	_expect_active_quest("quest.trace_phase_splinters", "after relay reentry returns to new deep pressure")
	_complete_active_quest("quest.trace_phase_splinters", [
		{"type": "visit_region", "target_id": "region.deep_ruin_threshold", "amount": 1}, {"type": "inspect", "target_id": "map_object.phase_splinter_resonance_node", "amount": 2},
		{"type": "defeat_enemy", "target_id": "enemy.deep_fault_hunter", "amount": 1},
		{"type": "gather_item", "target_id": "item.phase_splinter", "amount": 2}
	])
	_expect_active_quest("quest.refine_phase_splinters", "after phase splinter tracing returns to filter refinement")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.phase_splinter_refining", "phase splinter tracing unlocks filter recipe")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.relay_tuning_lens", "phase splinter tracing unlocks relay lens recipe")
	_complete_active_quest("quest.refine_phase_splinters", [
		{"type": "craft_item", "target_id": "item.phase_lens_blank", "amount": 1},
		{"type": "craft_item", "target_id": "item.relay_tuning_lens", "amount": 1}
	])
	_expect_active_quest("quest.inspect_phase_fault_spire", "after relay lens expedition prep returns to deep spire")
	_complete_active_quest("quest.inspect_phase_fault_spire", [{"type": "inspect", "target_id": "map_object.phase_fault_spire", "amount": 1}])
	_expect_array_has(world_state.quest_state.completed_quest_ids, "quest.inspect_phase_fault_spire", "phase fault spire quest completed")
	_expect_equal(int(character_state.inventory.items.get("item.inner_fault_trace", 0)), 1, "phase fault spire grants first inner fault trace")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.inner_fault_analysis", "phase fault spire unlocks inner fault analysis recipe")
	_expect_active_quest("quest.analyze_inner_fault_trace", "after phase fault spire returns to base analysis")
	_complete_active_quest("quest.analyze_inner_fault_trace", [{"type": "craft_item", "target_id": "item.phase_well_coordinate", "amount": 1}])
	_expect_active_quest("quest.collect_fault_residue", "after inner fault analysis returns to deeper front")
	_complete_active_quest("quest.collect_fault_residue", [
		{"type": "visit_region", "target_id": "region.deep_ruin_threshold", "amount": 1}, {"type": "inspect", "target_id": "map_object.fault_residue_pulse_node", "amount": 2},
		{"type": "defeat_enemy", "target_id": "enemy.inner_fault_stalker", "amount": 1},
		{"type": "gather_item", "target_id": "item.fault_residue", "amount": 2}
	])
	_expect_active_quest("quest.refine_fault_residue", "after fault residue collection returns to filter")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.fault_residue_stabilization", "fault residue collection unlocks stabilization recipe")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.phase_well_key", "fault residue collection unlocks phase well key recipe")
	_complete_active_quest("quest.refine_fault_residue", [
		{"type": "craft_item", "target_id": "item.stabilized_fault_core", "amount": 1},
		{"type": "craft_item", "target_id": "item.phase_well_key", "amount": 1}
	])
	_expect_active_quest("quest.unlock_phase_well", "after phase well key prep returns to deep lock")
	_complete_active_quest("quest.unlock_phase_well", [{"type": "inspect", "target_id": "map_object.phase_well_lock", "amount": 1}])
	_expect_array_has(world_state.quest_state.completed_quest_ids, "quest.unlock_phase_well", "phase well lock quest completed")
	_expect_equal(int(character_state.inventory.items.get("item.phase_well_locator", 0)), 1, "phase well lock grants first locator")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.phase_well_locator_analysis", "phase well lock unlocks locator analysis recipe")
	_expect_active_quest("quest.analyze_phase_well_locator", "after phase well lock returns to base analysis")
	_complete_active_quest("quest.analyze_phase_well_locator", [{"type": "craft_item", "target_id": "item.phase_well_route", "amount": 1}])
	_expect_active_quest("quest.collect_well_flux", "after locator analysis returns to inner phase well edge")
	_expect_array_has(world_state.unlocked_region_ids, "region.inner_phase_well", "locator analysis unlocks inner phase well region")
	_complete_active_quest("quest.collect_well_flux", [
		{"type": "visit_region", "target_id": "region.inner_phase_well", "amount": 1}, {"type": "inspect", "target_id": "map_object.well_flux_pressure_vent", "amount": 2},
		{"type": "defeat_enemy", "target_id": "enemy.phase_well_sentry", "amount": 1},
		{"type": "gather_item", "target_id": "item.well_flux_shard", "amount": 2}
	])
	_expect_active_quest("quest.refine_well_flux", "after well flux collection returns to filter")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.well_flux_stabilization", "well flux collection unlocks stabilization recipe")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.phase_well_probe", "well flux collection unlocks phase well probe recipe")
	_complete_active_quest("quest.refine_well_flux", [
		{"type": "craft_item", "target_id": "item.phase_well_stabilizer", "amount": 1},
		{"type": "craft_item", "target_id": "item.phase_well_probe", "amount": 1}
	])
	_expect_active_quest("quest.inspect_inner_phase_well", "after phase well probe prep returns to inner well")
	_complete_active_quest("quest.inspect_inner_phase_well", [{"type": "inspect", "target_id": "map_object.inner_phase_well", "amount": 1}])
	_expect_array_has(world_state.quest_state.completed_quest_ids, "quest.inspect_inner_phase_well", "inner phase well quest completed")
	_expect_equal(int(character_state.inventory.items.get("item.phase_well_core", 0)), 1, "inner phase well grants first core sample")
	_expect_active_quest("quest.analyze_phase_well_core", "after inner phase well returns to base analysis")
	_complete_active_quest("quest.analyze_phase_well_core", [{"type": "craft_item", "target_id": "item.phase_well_spectrum", "amount": 1}])
	_expect_active_quest("quest.collect_well_ash", "after phase well core analysis returns to deeper sink")
	_expect_array_has(world_state.unlocked_region_ids, "region.phase_well_sink", "phase well core analysis unlocks phase well sink region")
	_complete_active_quest("quest.collect_well_ash", [
		{"type": "visit_region", "target_id": "region.phase_well_sink", "amount": 1}, {"type": "clear", "target_id": "map_object.well_ash_crust_blocker", "amount": 2},
		{"type": "defeat_enemy", "target_id": "enemy.phase_well_lurker", "amount": 1},
		{"type": "gather_item", "target_id": "item.well_ash", "amount": 2}
	])
	_expect_active_quest("quest.refine_well_ash", "after well ash collection returns to filter")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.well_ash_stabilization", "well ash collection unlocks stabilization recipe")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.phase_well_pike", "well ash collection unlocks phase well pike recipe")
	_complete_active_quest("quest.refine_well_ash", [
		{"type": "craft_item", "target_id": "item.phase_well_lattice", "amount": 1},
		{"type": "craft_item", "target_id": "item.phase_well_pike", "amount": 1}
	])
	_expect_active_quest("quest.inspect_phase_well_sink", "after phase well pike assembly returns to sink")
	_complete_active_quest("quest.inspect_phase_well_sink", [{"type": "inspect", "target_id": "map_object.phase_well_sink", "amount": 1}])
	_expect_array_has(world_state.quest_state.completed_quest_ids, "quest.inspect_phase_well_sink", "phase well sink quest completed")
	_expect_equal(int(character_state.inventory.items.get("item.phase_well_heart", 0)), 1, "phase well sink grants first heart reward")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.phase_well_heart_analysis", "phase well sink unlocks heart analysis recipe")
	PhaseWellFollowupChecks.new(self).run_flow(world_state, character_state)
	_check_processing_runtime()
	DeepProcessingCheckScript.new(self).run()
	VerticalSliceRegressionChecks.new(self).check_equipment_processing_runtime()
	_check_evacuation_feedback()
func _check_onboarding_hints() -> void:
	var presenter := HudHintPresenter.new()
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	presenter.configure(data_registry, map)
	var hint_world := WorldState.create_default()
	var hint_character := CharacterState.create_default()
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.restore_outpost", "前哨核心", "restore outpost onboarding hint")
	hint_world.current_region_id = "region.crystal_vein_field"
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.scout_crystal_field", "采集晶体簇", "crystal field onboarding hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.calibrate_reactor", "外勤残骸", "calibration onboarding hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.prepare_treatment_supplies", "修复凝胶", "supply prep onboarding hint")
	hint_world.quest_state.set_objective_progress("quest.prepare_treatment_supplies", "craft_item", "item.repair_gel", 1)
	_expect_text_contains(
		presenter.format_direction_hint(hint_world, hint_character, "quest.prepare_treatment_supplies"),
		"快捷栏 1",
		"supply prep direction mentions quick slot"
	)
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.prepare_treatment_supplies", "生命偏低", "supply prep combat use hint")
	_expect_text_contains(
		presenter.format_direction_hint(hint_world, hint_character, "quest.prepare_treatment_supplies"),
		"处理点北缘",
		"supply prep direction follows treatment point combat region"
	)
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.expand_treatment_point", "2 块地基", "foundation onboarding hint")
	_expect_text_contains(
		presenter.format_direction_hint(hint_world, hint_character, "quest.expand_treatment_point"),
		"处理点北缘",
		"expand treatment point direction uses treatment point wording"
	)
	hint_world.add_base_structure("structure.foundation_site_north", "building.foundation_t1", "region.pollution_edge")
	hint_world.add_base_structure("structure.foundation_site_south", "building.foundation_t1", "region.pollution_edge")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.expand_treatment_point", "污染过滤器", "pollution filter onboarding hint")
	hint_character.equipment["suit_module"] = "equipment.filter_module_t1"
	hint_world.unlock_region("region.pollution_edge")
	hint_world.quest_state.set_objective_progress("quest.enter_pollution_edge", "visit_region", "region.pollution_edge", 1)
	hint_world.quest_state.set_objective_progress("quest.enter_pollution_edge", "gather_item", "item.polluted_residue", 2)
	_expect_text_contains(
		presenter.format_direction_hint(hint_world, hint_character, "quest.enter_pollution_edge"),
		"处理点过滤器",
		"enter pollution direction returns to filter when vial crafting is next"
	)
	_expect_hint_contains(
		presenter,
		hint_world,
		hint_character,
		"quest.enter_pollution_edge",
		"抗污染药剂",
		"enter pollution onboarding returns to filter before pushing deeper"
	)
	hint_character.protection = 30.0
	hint_world.quest_state.set_objective_progress("quest.enter_pollution_edge", "craft_item", "item.resistance_vial_t1", 1)
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.enter_pollution_edge", "过滤器处理沉积物", "low protection onboarding hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.defeat_elite_node", "维持防护", "elite node supply hint")
	hint_world.unlock_region("region.ruin_outer_ring")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.scout_ruin_outer_ring", "继电残片", "outer ring scouting hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.assemble_phase_anchor", "污染浆液", "phase anchor assembly hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.stabilize_outer_ring_barrier", "稳相信标", "outer ring barrier hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.salvage_signal_echo", "回波匣", "signal echo salvage hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.analyze_deep_signal", "更深遗迹坐标", "deep signal analysis hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.unlock_deep_ruin_entrance", "门禁", "deep ruin entrance hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.harvest_phase_filament", "相位纤丝", "phase filament salvage hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.refine_phase_filament", "污染过滤器", "phase filament filter hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.assemble_deep_override", "污染浆液", "deep override assembly hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.unlock_deep_ruin_cache", "深段收益", "deep ruin latch hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.analyze_deep_core", "路由印片", "deep core analysis hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.activate_deep_array", "相位导管", "deep array activation hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.assemble_deep_signal_matrix", "读数矩阵", "deep signal matrix assembly hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.deploy_phase_relay_anchor", "回传锚点", "phase relay anchor deployment hint")
	hint_world.current_region_id = "region.outpost_platform"
	_expect_text_contains(
		presenter.format_direction_hint(hint_world, hint_character, "quest.reenter_phase_frontline"),
		"相位回投台",
		"relay reentry direction returns to outpost relay pad"
	)
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.reenter_phase_frontline", "回投台", "relay reentry onboarding hint")
	hint_world.current_region_id = "region.deep_ruin_threshold"
	_expect_text_contains(
		presenter.format_direction_hint(hint_world, hint_character, "quest.trace_phase_splinters"),
		"裂相猎手",
		"phase splinter tracing direction points to new deep hunter"
	)
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.refine_phase_splinters", "污染过滤器", "phase splinter refinement hint")
	hint_character.inventory.add_item("item.phase_lens_blank", 1)
	hint_character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	_expect_text_contains(
		presenter.format_direction_hint(hint_world, hint_character, "quest.refine_phase_splinters"),
		"基础反应器",
		"phase splinter expedition prep second step returns to reactor"
	)
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.inspect_phase_fault_spire", "中继调谐镜", "phase fault spire onboarding hint")
	_expect_text_contains(
		presenter.format_direction_hint(hint_world, hint_character, "quest.analyze_inner_fault_trace"),
		"基础反应器",
		"inner fault analysis direction returns to reactor"
	)
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.analyze_inner_fault_trace", "坐标印片", "inner fault analysis onboarding hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.collect_fault_residue", "故障残渣", "fault residue collection onboarding hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.refine_fault_residue", "相位井钥", "phase well key prep onboarding hint")
	_expect_hint_contains(presenter, hint_world, hint_character, "quest.unlock_phase_well", "相位井钥", "phase well lock onboarding hint")
	hint_world.quest_state.completed_quest_ids.append("quest.analyze_deep_signal")
	hint_world.quest_state.completed_quest_ids.append("quest.unlock_deep_ruin_cache")
	hint_world.quest_state.completed_quest_ids.append("quest.assemble_deep_signal_matrix")
	hint_world.quest_state.completed_quest_ids.append("quest.deploy_phase_relay_anchor")
	hint_world.quest_state.unlocked_effects.append("slice_01_complete")
	hint_world.current_region_id = "region.outpost_platform"
	_expect_text_contains(presenter.format_direction_hint(hint_world, hint_character, ""), "相位回投台", "phase relay completion direction returns to relay pad")
	_expect_text_contains(presenter.format_onboarding_hint(hint_world, hint_character, ""), "相位回投台", "phase relay completion onboarding points to relay pad")
	_expect_hint_contains(presenter, hint_world, hint_character, "", "回传锚点", "phase relay completion onboarding hint")
	var spire_completion_world := WorldState.create_default()
	spire_completion_world.quest_state.active_quest_ids.clear()
	spire_completion_world.quest_state.completed_quest_ids.append("quest.inspect_phase_fault_spire")
	_expect_text_contains(
		presenter.format_direction_hint(spire_completion_world, hint_character, ""),
		"相位井锁",
		"phase fault spire completion direction points to phase well lock"
	)
	_expect_text_contains(
		presenter.format_onboarding_hint(spire_completion_world, hint_character, ""),
		"内层故障轨迹",
		"phase fault spire completion onboarding points to base analysis"
	)
	var phase_well_world := WorldState.create_default()
	phase_well_world.quest_state.active_quest_ids.clear()
	phase_well_world.quest_state.completed_quest_ids.append("quest.unlock_phase_well")
	_expect_text_contains(
		presenter.format_direction_hint(phase_well_world, hint_character, ""),
		"回基地解析定位器",
		"phase well completion direction highlights base analysis followup"
	)
	_expect_text_contains(
		presenter.format_onboarding_hint(phase_well_world, hint_character, ""),
		"先回基地解析它",
		"phase well completion onboarding keeps locator analysis explicit"
	)
	var inner_phase_well_world := WorldState.create_default()
	inner_phase_well_world.quest_state.active_quest_ids.clear()
	inner_phase_well_world.quest_state.completed_quest_ids.append("quest.inspect_inner_phase_well")
	_expect_text_contains(
		presenter.format_direction_hint(inner_phase_well_world, hint_character, ""),
		"回基地解析井芯样本",
		"inner phase well completion direction highlights next base analysis"
	)
	_expect_text_contains(
		presenter.format_onboarding_hint(inner_phase_well_world, hint_character, ""),
		"井芯样本只是下一轮的起点",
		"inner phase well completion onboarding keeps next package explicit"
	)
	map.free()
func _check_runtime_hint_prompt_flow() -> void:
	HudRuntimeHintFlowCheckScript.new().run(root, failures, data_registry)
func _check_status_panel_summary() -> void:
	var presenter := HudStatusPresenter.new()
	var status_world := WorldState.create_default()
	var status_character := CharacterState.create_default()
	var status_text := presenter.format_status_text(data_registry, status_world, status_character)
	_expect_text_contains(status_text, "目标：恢复前哨", "status keeps current goal")
	_expect_text_contains(status_text, "进度：交互 前哨核心 0/1", "status keeps objective progress")
	_expect_text_contains(status_text, "状态：生命 100 / 100；防护 100 / 100", "status keeps health and protection")
	_expect_text_contains(status_text, "快捷栏：1 修复凝胶x1", "status keeps quick slots")
	_expect_text_contains(status_text, "关键物资：基础零件x4", "status keeps key resources")
	var reentry_world := WorldState.create_default()
	reentry_world.current_region_id = "region.outpost_platform"
	reentry_world.quest_state.active_quest_ids = ["quest.reenter_phase_frontline"]
	var reentry_text := presenter.format_status_text(data_registry, reentry_world, status_character)
	_expect_text_contains(reentry_text, "目标：从回投台重返前线", "status shows relay reentry goal name")
	_expect_text_contains(reentry_text, "检查 相位回投台 0/1", "status shows relay reentry objective progress")
	_expect_text_missing(status_text, "模块：", "status folds module state into pollution line")
	_expect_text_missing(status_text, "区域：", "status removes minimap region duplicate")
	_expect_text_missing(status_text, "方向：", "status removes minimap direction duplicate")
	var relay_world := WorldState.create_default()
	relay_world.current_region_id = "region.outpost_platform"
	relay_world.quest_state.active_quest_ids.clear()
	relay_world.quest_state.completed_quest_ids.append("quest.deploy_phase_relay_anchor")
	var relay_text := presenter.format_status_text(data_registry, relay_world, status_character)
	_expect_text_contains(relay_text, "相位回投台", "phase relay status highlights return pad")
	_expect_text_contains(relay_text, "按 E 回投返回深段", "phase relay status keeps explicit return action")
	var spire_world := WorldState.create_default()
	spire_world.quest_state.active_quest_ids.clear()
	spire_world.quest_state.completed_quest_ids.append("quest.inspect_phase_fault_spire")
	var spire_text := presenter.format_status_text(data_registry, spire_world, status_character)
	_expect_text_contains(spire_text, "目标：内层故障轨迹待解析", "status falls back to inner fault analysis after phase fault spire")
	_expect_text_contains(spire_text, "相位井锁变成新目标", "status progress keeps phase fault spire followup summary")
	var phase_well_text_world := WorldState.create_default()
	phase_well_text_world.quest_state.active_quest_ids.clear()
	phase_well_text_world.quest_state.completed_quest_ids.append("quest.unlock_phase_well")
	var phase_well_text := presenter.format_status_text(data_registry, phase_well_text_world, status_character)
	_expect_text_contains(phase_well_text, "目标：相位井定位器待解析", "status falls back to phase well locator analysis after lock")
	_expect_text_contains(phase_well_text, "先回基地解析定位器", "status progress keeps locator analysis summary")
	var inner_phase_well_text_world := WorldState.create_default()
	inner_phase_well_text_world.quest_state.active_quest_ids.clear()
	inner_phase_well_text_world.quest_state.completed_quest_ids.append("quest.inspect_inner_phase_well")
	var inner_phase_well_text := presenter.format_status_text(data_registry, inner_phase_well_text_world, status_character)
	_expect_text_contains(inner_phase_well_text, "目标：相位井芯样本待解析", "status falls back to inner phase well analysis after completion")
	_expect_text_contains(inner_phase_well_text, "回基地解析后可继续把更东侧井底裂口转成新的推进包", "status progress keeps inner phase well followup summary")
	_expect_text_missing(status_text, "提示：", "status removes onboarding duplicate")
	_expect_text_missing(status_text, "坐标：", "status removes debug coordinate duplicate")
	_expect_text_missing(status_text, "背包：", "status removes full inventory duplicate")
	if status_text.split("\n").size() > 8:
		failures.append("status panel should stay compact, got %d lines: %s" % [status_text.split("\n").size(), status_text])
	var calibration_world := WorldState.create_default()
	calibration_world.quest_state.active_quest_ids = ["quest.calibrate_reactor"]
	var calibration_status_text := presenter.format_status_text(data_registry, calibration_world, status_character)
	_expect_text_contains(calibration_status_text, "收集 导电废件（外勤残骸） 0/4", "status shows conductive scrap source")
	var scout_world := WorldState.create_default()
	scout_world.quest_state.active_quest_ids = ["quest.scout_crystal_field"]
	var scout_status_text := presenter.format_status_text(data_registry, scout_world, status_character)
	_expect_text_contains(scout_status_text, "收集 晶体矿物（晶体簇） 0/6", "status shows crystal gather source")
	var reactor_craft_world := WorldState.create_default()
	reactor_craft_world.quest_state.active_quest_ids = ["quest.analyze_phase_well_weave_core"]
	var reactor_craft_status_text := presenter.format_status_text(data_registry, reactor_craft_world, status_character)
	_expect_text_contains(reactor_craft_status_text, "制造 相位井纹谱片（基础反应器） 0/1", "status shows reactor craft source")
	var filter_craft_world := WorldState.create_default()
	filter_craft_world.quest_state.active_quest_ids = ["quest.refine_selvedge_strip"]
	var filter_craft_status_text := presenter.format_status_text(data_registry, filter_craft_world, status_character)
	_expect_text_contains(filter_craft_status_text, "制造 相位井纹架肋（污染过滤器） 0/1", "status shows filter craft source")
func _check_region_presence_bounds() -> void:
	var map := VerticalSliceMap.new()
	_expect_equal(
		map._get_region_id_for_position(Vector2(253, -104)),
		"region.crystal_vein_field",
		"pollution treatment point should not count as pollution"
	)
	_expect_equal(
		map._get_region_id_for_position(Vector2(253, 30)),
		"region.pollution_edge",
		"pollution lower area should count as pollution"
	)
	_expect_equal(
		map._get_region_id_for_position(Vector2(190, -104)),
		"region.crystal_vein_field",
		"gap before pollution visual edge should remain crystal"
	)
	_expect_equal(
		map._get_region_id_for_position(Vector2(680, -8)),
		"region.ruin_outer_ring",
		"deep door should still sit in ruin outer ring"
	)
	_expect_equal(
		map._get_region_id_for_position(Vector2(734, -96)),
		"region.deep_ruin_threshold",
		"deep filament salvage should sit in deep region"
	)
	_expect_equal(
		map._get_region_id_for_position(Vector2(1408, -22)),
		"region.deep_ruin_threshold",
		"phase well lock should stay in deep region"
	)
	map.free()
func _check_pollution_gate_runtime_bounds() -> void:
	var map := VerticalSliceMap.new()
	map.player = PlayerController.new()
	var gate_world := WorldState.create_default()
	gate_world.unlock_region("region.crystal_vein_field")
	var gate_character := CharacterState.create_default()
	map.player.position = Vector2(253, 30)
	map.update_region_presence(gate_world, gate_character)
	_expect_equal(map.player.position.x, 195.0, "locked pollution edge should push player before visual region")
	_expect_equal(gate_world.current_region_id, "region.crystal_vein_field", "locked pollution edge should return to crystal side")
	var unlocked_world := WorldState.create_default()
	unlocked_world.unlock_region("region.crystal_vein_field")
	unlocked_world.unlock_region("region.pollution_edge")
	var unlocked_character := CharacterState.create_default()
	map.last_reported_region_id = unlocked_world.current_region_id
	map.player.position = Vector2(253, 30)
	map.update_region_presence(unlocked_world, unlocked_character)
	_expect_equal(unlocked_world.current_region_id, "region.pollution_edge", "unlocked pollution edge should update current region")
	_expect_equal(unlocked_character.current_region_id, "region.pollution_edge", "unlocked pollution edge should update character region")
	var deep_gate_world := WorldState.create_default()
	deep_gate_world.unlock_region("region.crystal_vein_field")
	deep_gate_world.unlock_region("region.pollution_edge")
	deep_gate_world.unlock_region("region.ruin_outer_ring")
	deep_gate_world.quest_state.completed_quest_ids.append("quest.stabilize_outer_ring_barrier")
	var deep_gate_character := CharacterState.create_default()
	map.last_reported_region_id = deep_gate_world.current_region_id
	map.player.position = Vector2(734, -96)
	map.update_region_presence(deep_gate_world, deep_gate_character)
	_expect_equal(map.player.position.x, 676.0, "locked deep ruin gate should push player before deep region")
	_expect_equal(deep_gate_world.current_region_id, "region.ruin_outer_ring", "locked deep ruin gate should keep outer ring region")
	var unlocked_deep_world := WorldState.create_default()
	unlocked_deep_world.unlock_region("region.crystal_vein_field")
	unlocked_deep_world.unlock_region("region.pollution_edge")
	unlocked_deep_world.unlock_region("region.ruin_outer_ring")
	unlocked_deep_world.unlock_region("region.deep_ruin_threshold")
	unlocked_deep_world.quest_state.completed_quest_ids.append("quest.stabilize_outer_ring_barrier")
	unlocked_deep_world.quest_state.completed_quest_ids.append("quest.unlock_deep_ruin_entrance")
	var unlocked_deep_character := CharacterState.create_default()
	map.last_reported_region_id = unlocked_deep_world.current_region_id
	map.player.position = Vector2(734, -96)
	map.update_region_presence(unlocked_deep_world, unlocked_deep_character)
	_expect_equal(unlocked_deep_world.current_region_id, "region.deep_ruin_threshold", "unlocked deep ruin gate should update current region")
	_expect_equal(unlocked_deep_character.current_region_id, "region.deep_ruin_threshold", "unlocked deep ruin gate should update character region")
	map.player.free()
	map.free()


func _check_deep_gate_releases_movement_block() -> void:
	var map := VerticalSliceMap.new()
	map.player = PlayerController.new()
	var unlocked_world := WorldState.create_default()
	unlocked_world.unlock_region("region.crystal_vein_field")
	unlocked_world.unlock_region("region.pollution_edge")
	unlocked_world.unlock_region("region.ruin_outer_ring")
	unlocked_world.unlock_region("region.deep_ruin_threshold")
	unlocked_world.quest_state.completed_quest_ids.append("quest.stabilize_outer_ring_barrier")
	unlocked_world.quest_state.completed_quest_ids.append("quest.unlock_deep_ruin_entrance")
	var unlocked_character := CharacterState.create_default()
	map.last_reported_region_id = "region.ruin_outer_ring"
	map.player.stop_positive_x_until_release()
	map.player.position = Vector2(734, -96)
	map.update_region_presence(unlocked_world, unlocked_character)
	_expect_equal(map.player.block_positive_x_until_release, false, "opened deep ruin gate should release positive x block")
	map.player.free()
	map.free()
func _check_new_game_state_reset() -> void:
	var game_root = GameRootScript.new()
	var new_state := game_root.create_new_game_state()
	var reset_world: WorldState = new_state.get("world_state", null)
	var reset_character: CharacterState = new_state.get("character_state", null)
	if reset_world == null or reset_character == null:
		failures.append("new game state should include world and character")
		game_root.free()
		return
	_expect_equal(reset_world.current_region_id, "region.outpost_platform", "new game resets world region")
	_expect_equal(reset_character.current_region_id, "region.outpost_platform", "new game resets character region")
	_expect_equal(reset_world.quest_state.active_quest_ids, ["quest.restore_outpost"], "new game resets active quest")
	_expect_array_missing(reset_world.unlocked_region_ids, "region.crystal_vein_field", "new game should not keep crystal unlock")
	_expect_equal(int(reset_character.inventory.items.get("item.basic_parts", 0)), 4, "new game resets starting parts")
	_expect_equal(String(reset_character.equipment.get("suit_module", "")), "", "new game clears suit module")
	game_root.world_state = null
	game_root.character_state = null
	game_root.free()
func _check_outpost_core_restored_visual() -> void:
	var temp_root := Node.new()
	var outpost_core := _create_visual_check_interactable(
		temp_root,
		"map_object_instance.outpost_core",
		"building.outpost_core",
		"outpost_core",
		"前哨核心"
	)
	var default_color := outpost_core.marker.color
	outpost_core.set_restored_outpost_core_visual()
	_expect_equal(outpost_core.visible, true, "restored outpost core remains visible")
	_expect_equal(outpost_core.monitoring, true, "restored outpost core keeps repeat interaction")
	_expect_equal(outpost_core.marker.color == default_color, false, "restored outpost core changes color")
	_expect_text_contains(outpost_core.label.text, "已恢复", "restored outpost core label")
	_expect_text_contains(outpost_core.label.text, "整备", "restored outpost core resupply label")
	outpost_core.set_default_visual()
	_expect_equal(outpost_core.monitoring, true, "new game outpost core enables interaction")
	_expect_equal(outpost_core.marker.color, default_color, "new game outpost core restores default color")
	temp_root.free()
func _check_early_interaction_processed_visuals() -> void:
	var map := VerticalSliceMap.new()
	map.player = PlayerController.new()
	map.interactables_root = Node2D.new()
	map.add_child(map.player)
	map.add_child(map.interactables_root)
	var crystal := _create_visual_check_interactable(
		map.interactables_root,
		"map_object_instance.crystal_cluster",
		"map_object.crystal_cluster",
		"gather",
		"晶体簇"
	)
	var rich_crystal_vein := _create_visual_check_interactable(
		map.interactables_root,
		"map_object_instance.rich_crystal_vein_north",
		"map_object.rich_crystal_vein",
		"gather",
		"富晶残脉"
	)
	var salvage := _create_visual_check_interactable(
		map.interactables_root,
		"map_object_instance.field_wreckage_north",
		"map_object.field_wreckage",
		"gather",
		"外勤残骸"
	)
	var anomaly := _create_visual_check_interactable(
		map.interactables_root,
		"map_object_instance.anomaly_crystal",
		"map_object.anomaly_crystal",
		"sample",
		"异常晶体"
	)
	var anomaly_residue := _create_visual_check_interactable(
		map.interactables_root,
		"map_object_instance.anomaly_residue_north",
		"map_object.anomaly_residue_patch",
		"gather",
		"异常残留点"
	)
	var rough_ground := _create_visual_check_interactable(
		map.interactables_root,
		"map_object_instance.rough_ground_north",
		"map_object.rough_ground",
		"clear",
		"粗糙地面"
	)
	var residue := _create_visual_check_interactable(
		map.interactables_root,
		"map_object_instance.pollution_residue",
		"map_object.pollution_residue_patch",
		"gather",
		"污染沉积斑"
	)
	var ruin_gate := _create_visual_check_interactable(
		map.interactables_root,
		"map_object_instance.ruin_gate",
		"map_object.ruin_gate",
		"inspect",
		"封锁遗迹入口"
	)
	var default_crystal_color := crystal.marker.color
	var default_salvage_color := salvage.marker.color
	var default_anomaly_residue_color := anomaly_residue.marker.color
	var default_ruin_color := ruin_gate.marker.color
	var visual_world := WorldState.create_default()
	visual_world.ensure_map_object(crystal.instance_id, crystal.definition_id, "region.crystal_vein_field")
	visual_world.set_map_object_flag(crystal.instance_id, "is_gathered", true)
	visual_world.ensure_map_object(salvage.instance_id, salvage.definition_id, "region.crystal_vein_field")
	visual_world.set_map_object_flag(salvage.instance_id, "is_gathered", true)
	visual_world.ensure_map_object(anomaly.instance_id, anomaly.definition_id, "region.crystal_vein_field")
	visual_world.set_map_object_flag(anomaly.instance_id, "is_sampled", true)
	visual_world.ensure_map_object(anomaly_residue.instance_id, anomaly_residue.definition_id, "region.crystal_vein_field")
	visual_world.set_map_object_flag(anomaly_residue.instance_id, "is_gathered", true)
	visual_world.ensure_map_object(rough_ground.instance_id, rough_ground.definition_id, "region.pollution_edge")
	visual_world.set_map_object_flag(rough_ground.instance_id, "is_cleared", true)
	visual_world.ensure_map_object(residue.instance_id, residue.definition_id, "region.pollution_edge")
	visual_world.set_map_object_flag(residue.instance_id, "is_gathered", true)
	visual_world.quest_state.completed_quest_ids.append("quest.unlock_ruin_signal")
	map.refresh_world_interactables(visual_world)
	_expect_equal(crystal.visible, true, "gathered crystal remains visible")
	_expect_equal(crystal.monitoring, false, "gathered crystal disables repeat interaction")
	_expect_equal(crystal.marker.color == default_crystal_color, false, "gathered crystal changes color")
	_expect_text_contains(crystal.label.text, "已采集", "gathered crystal label")
	_expect_equal(salvage.visible, true, "gathered salvage remains visible")
	_expect_equal(salvage.monitoring, false, "gathered salvage disables repeat interaction")
	_expect_equal(salvage.marker.color == default_salvage_color, false, "gathered salvage changes color")
	_expect_text_contains(salvage.label.text, "已回收", "gathered salvage label")
	_expect_equal(anomaly.visible, true, "sampled anomaly remains visible")
	_expect_equal(anomaly.monitoring, false, "sampled anomaly disables repeat interaction")
	_expect_text_contains(anomaly.label.text, "已采样", "sampled anomaly label")
	_expect_equal(anomaly_residue.visible, true, "gathered anomaly residue remains visible")
	_expect_equal(anomaly_residue.monitoring, false, "gathered anomaly residue disables repeat interaction")
	_expect_equal(anomaly_residue.marker.color == default_anomaly_residue_color, false, "gathered anomaly residue changes color")
	_expect_text_contains(anomaly_residue.label.text, "已回收", "gathered anomaly residue label")
	_expect_equal(rough_ground.visible, true, "cleared rough ground remains visible")
	_expect_equal(rough_ground.monitoring, false, "cleared rough ground disables repeat interaction")
	_expect_text_contains(rough_ground.label.text, "已清理", "cleared rough ground label")
	_expect_equal(residue.visible, true, "gathered residue remains visible")
	_expect_equal(residue.monitoring, false, "gathered residue disables repeat interaction")
	_expect_text_contains(residue.label.text, "已回收", "gathered residue label")
	_expect_equal(ruin_gate.visible, true, "confirmed ruin gate remains visible")
	_expect_equal(ruin_gate.monitoring, false, "confirmed ruin gate disables repeat interaction")
	_expect_equal(ruin_gate.marker.color == default_ruin_color, false, "confirmed ruin gate changes color")
	_expect_text_contains(ruin_gate.label.text, "信号已确认", "confirmed ruin gate label")
	var reset_world := WorldState.create_default()
	map.refresh_world_interactables(reset_world)
	_expect_equal(crystal.monitoring, true, "new game crystal enables interaction")
	_expect_equal(crystal.marker.color, default_crystal_color, "new game crystal restores default color")
	_expect_equal(crystal.label.text, "晶体簇", "new game crystal restores label")
	_expect_equal(rich_crystal_vein.visible, false, "new game rich crystal vein stays hidden before crystal scout completion")
	_expect_equal(rich_crystal_vein.monitoring, false, "new game rich crystal vein cannot complete crystal scout objective")
	var post_scout_world := WorldState.create_default()
	post_scout_world.quest_state.completed_quest_ids.append("quest.scout_crystal_field")
	map.refresh_world_interactables(post_scout_world)
	_expect_equal(rich_crystal_vein.visible, true, "rich crystal vein appears after crystal scout completion")
	_expect_equal(rich_crystal_vein.monitoring, true, "rich crystal vein becomes optional supply after crystal scout completion")
	_expect_equal(salvage.monitoring, true, "new game salvage enables interaction")
	_expect_equal(salvage.marker.color, default_salvage_color, "new game salvage restores default color")
	_expect_equal(salvage.label.text, "外勤残骸", "new game salvage restores label")
	_expect_equal(anomaly_residue.monitoring, true, "new game anomaly residue enables interaction")
	_expect_equal(anomaly_residue.marker.color, default_anomaly_residue_color, "new game anomaly residue restores default color")
	_expect_equal(anomaly_residue.label.text, "异常残留点", "new game anomaly residue restores label")
	_expect_equal(ruin_gate.monitoring, true, "new game ruin gate enables interaction")
	_expect_equal(ruin_gate.marker.color, default_ruin_color, "new game ruin gate restores default color")
	map.free()
func _check_pollution_enemy_defeated_visual() -> void:
	var enemy := _create_visual_check_enemy("enemy.polluted_skitter", "受扰掠行体", 40.0, "polluted")
	var default_polluted_color := enemy.sprite.color
	enemy.apply_saved_state({
		"health": 0.0,
		"is_defeated": true
	})
	_expect_equal(enemy.defeated, true, "polluted enemy restored defeated state")
	_expect_equal(enemy.can_be_attacked(), false, "polluted enemy disables repeat attack")
	_expect_equal(enemy.sprite.color == default_polluted_color, false, "polluted enemy defeated changes color")
	_expect_text_contains(enemy.label.text, "污染已压制", "polluted enemy defeated label")
	enemy.free()
func _check_treatment_enemy_spawn_gate() -> void:
	var map := VerticalSliceMap.new()
	var treatment_enemy := _create_visual_check_enemy("enemy.treatment_skitter", "处理点掠行体", 35.0, "basic")
	treatment_enemy.name = "TreatmentSkitter"
	var gate_world := WorldState.create_default()
	_expect_equal(map._should_enemy_spawn(treatment_enemy, gate_world), false, "treatment enemy hidden before quest")
	gate_world.quest_state.active_quest_ids = ["quest.prepare_treatment_supplies"]
	_expect_equal(map._should_enemy_spawn(treatment_enemy, gate_world), false, "treatment enemy hidden before repair gel")
	gate_world.quest_state.set_objective_progress("quest.prepare_treatment_supplies", "craft_item", "item.repair_gel", 1)
	_expect_equal(map._should_enemy_spawn(treatment_enemy, gate_world), true, "treatment enemy spawns after repair gel")
	treatment_enemy.free()
	map.free()
func _check_treatment_enemy_combat_pressure() -> void:
	var map := VerticalSliceMap.new()
	map.data_registry = data_registry
	var treatment_enemy := _create_visual_check_enemy("enemy.treatment_skitter", "处理点掠行体", 35.0, "basic")
	var combat_character := CharacterState.create_default()
	var counter_message := map._apply_enemy_counterattack(treatment_enemy, combat_character)
	_expect_equal(combat_character.health, 91.0, "treatment enemy counterattack pressure")
	_expect_text_contains(counter_message, "修复凝胶", "treatment enemy counterattack supply hint")
	treatment_enemy.free()
	map.free()
func _check_quest_completion_panel_text() -> void:
	var presenter := HudFeedbackPresenter.new()
	var panel_texts := presenter.format_quest_completion_panel_texts({
		"panel_title": "任务完成",
		"completed_text": "完成：恢复前哨",
		"reward_text": "奖励：基础零件 x4",
		"unlock_text": "解锁：晶体矿脉区",
		"note_text": "",
		"next_goal_text": "新目标：勘探晶体矿脉"
	})
	var details := String(panel_texts.get("detail", ""))
	_expect_text_contains(details, "完成：恢复前哨", "completion details completed row")
	_expect_text_contains(details, "奖励：基础零件 x4", "completion details reward row")
	_expect_text_contains(details, "解锁：晶体矿脉区", "completion details unlock row")
	_expect_text_contains(details, "新目标：勘探晶体矿脉", "completion details next row")
	_expect_text_contains(
		String(presenter.format_quest_completion_panel_texts({
			"title": "任务完成：采样异常晶体",
			"reward_text": "奖励：无直接物资"
		}).get("detail", "")),
		"完成：采样异常晶体",
		"completion details title fallback"
	)
	_expect_equal(
		String(presenter.format_quest_completion_panel_texts({"panel_title": "切片完成"}).get("title", "")),
		"切片完成",
		"completion panel title"
	)
	_expect_text_contains(
		String(presenter.format_quest_completion_panel_texts({
			"completed_text": "完成：解锁后续入口",
			"note_text": "遗迹外圈通路已恢复，可进入外圈回收继电残片"
		}).get("detail", "")),
		"提示：遗迹外圈通路已恢复",
		"completion note prefix"
	)
func _check_build_prompts() -> void:
	var build_world := WorldState.create_default()
	var build_character := CharacterState.create_default()
	var formatter := InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)
	var rough_ground := PrototypeInteractable.new()
	rough_ground.definition_id = "map_object.rough_ground"
	rough_ground.interaction_type = "clear"
	rough_ground.instance_id = "map_object_instance.rough_ground_north"
	_expect_text_contains(
		formatter.format_clear_prompt(rough_ground, build_character, build_world),
		"阻挡建造",
		"rough ground prompt"
	)
	var foundation_site := PrototypeInteractable.new()
	foundation_site.definition_id = "building.foundation_t1"
	foundation_site.interaction_type = "build"
	foundation_site.instance_id = "map_object_instance.foundation_site_north"
	foundation_site.prerequisite_instance_id = "map_object_instance.rough_ground_north"
	_expect_text_contains(
		formatter.format_build_prompt(foundation_site, build_character, build_world),
		"地面仍然粗糙",
		"foundation blocked prompt"
	)
	build_world.ensure_map_object("map_object_instance.rough_ground_north", "map_object.rough_ground", "region.pollution_edge")
	build_world.set_map_object_flag("map_object_instance.rough_ground_north", "is_cleared", true)
	_expect_text_contains(
		formatter.format_build_prompt(foundation_site, build_character, build_world),
		"缺少建造材料",
		"foundation missing material prompt"
	)
	build_character.inventory.add_item("item.foundation_material", 1)
	_expect_text_contains(
		formatter.format_build_prompt(foundation_site, build_character, build_world),
		"按 E 建造",
		"foundation ready prompt"
	)
	var filter_site := PrototypeInteractable.new()
	filter_site.definition_id = "building.pollution_filter"
	filter_site.interaction_type = "build"
	filter_site.instance_id = "map_object_instance.pollution_filter_build_site"
	_expect_text_contains(
		formatter.format_build_prompt(filter_site, build_character, build_world),
		"基础地基：0 / 2",
		"pollution filter foundation status"
	)
	build_world.add_base_structure("structure.foundation_site_north", "building.foundation_t1", "region.pollution_edge")
	build_world.add_base_structure("structure.foundation_site_south", "building.foundation_t1", "region.pollution_edge")
	_expect_text_contains(
		formatter.format_build_prompt(filter_site, build_character, build_world),
		"缺少建造材料",
		"pollution filter missing material prompt"
	)
	rough_ground.free()
	foundation_site.free()
	filter_site.free()
func _check_supply_feedback() -> void:
	var supply_character := CharacterState.create_default()
	supply_character.health = 45.0
	var repair_result := supply_character.use_quick_slot(0, data_registry)
	_expect_equal(bool(repair_result.get("success", false)), true, "repair gel should be usable")
	_expect_equal(supply_character.health, 80.0, "repair gel health recovery")
	_expect_feedback_contains(repair_result, "生命 +35", "repair gel feedback")
	_expect_feedback_contains(repair_result, "当前 80 / 100", "repair gel current health feedback")
	var full_health_character := CharacterState.create_default()
	var full_health_blocked := full_health_character.use_quick_slot(0, data_registry)
	_expect_equal(bool(full_health_blocked.get("success", true)), false, "full health should block repair gel")
	_expect_feedback_contains(full_health_blocked, "生命已满", "full health supply feedback")
	var missing_repair_result := supply_character.use_quick_slot(0, data_registry)
	_expect_equal(bool(missing_repair_result.get("success", true)), false, "missing repair gel should fail")
	_expect_feedback_contains(missing_repair_result, "基础反应器", "missing repair gel refill hint")
	var missing_vial_character := CharacterState.create_default()
	missing_vial_character.protection = 30.0
	missing_vial_character.inventory.items.erase("item.resistance_vial_t1")
	var missing_vial_result := missing_vial_character.use_quick_slot(1, data_registry)
	_expect_equal(bool(missing_vial_result.get("success", true)), false, "missing vial should fail")
	_expect_feedback_contains(missing_vial_result, "污染过滤器", "missing vial refill hint")
	var vial_character := CharacterState.create_default()
	vial_character.protection = 40.0
	vial_character.inventory.add_item("item.resistance_vial_t1", 1)
	var vial_result := vial_character.use_quick_slot(1, data_registry)
	_expect_equal(bool(vial_result.get("success", false)), true, "resistance vial should be usable")
	_expect_feedback_contains(vial_result, "继续深入污染边界", "resistance vial next step feedback")
	var outpost_world := WorldState.create_default()
	outpost_world.quest_state.completed_quest_ids.append("quest.restore_outpost")
	var outpost_character := CharacterState.create_default()
	outpost_character.health = 62.0
	outpost_character.protection = 28.0
	var gather_system := GatherSystem.new(data_registry)
	var outpost_result := gather_system.interact_with_object(
		"map_object_instance.outpost_core",
		"building.outpost_core",
		"outpost_core",
		outpost_character,
		outpost_world
	)
	_expect_equal(bool(outpost_result.get("success", false)), true, "restored outpost core should resupply vitals")
	_expect_equal(outpost_character.health, 100.0, "restored outpost core refills health")
	_expect_equal(outpost_character.protection, 100.0, "restored outpost core refills protection")
	_expect_feedback_contains(outpost_result, "生命 +38", "restored outpost core health feedback")
	_expect_feedback_contains(outpost_result, "防护 +72", "restored outpost core protection feedback")
	var outpost_full_result := gather_system.interact_with_object("map_object_instance.outpost_core", "building.outpost_core", "outpost_core", outpost_character, outpost_world)
	_expect_text_contains(String(outpost_full_result.get("message", "")), "生命与防护完整", "restored outpost core keeps ready message at full vitals")
func _check_hud_feedback_presenter() -> void:
	var presenter := HudFeedbackPresenter.new()
	var supply_feedback := {
		"title": "补给已使用",
		"detail": "生命 +35"
	}
	var evacuation_feedback := {
		"title": "撤离前哨",
		"reason_text": "生命耗尽"
	}
	_expect_equal(
		presenter.get_supply_feedback({"supply_feedback": supply_feedback}),
		supply_feedback,
		"presenter extracts supply feedback"
	)
	_expect_equal(
		presenter.get_evacuation_feedback({"evacuation_feedback": evacuation_feedback}),
		evacuation_feedback,
		"presenter extracts evacuation feedback"
	)
	_expect_equal(
		presenter.get_supply_feedback({"supply_feedback": "invalid"}),
		{},
		"presenter ignores invalid supply feedback"
	)
	_expect_equal(
		presenter.get_evacuation_feedback({}),
		{},
		"presenter ignores missing evacuation feedback"
	)
	var supply_panel_texts := presenter.format_supply_feedback_panel_texts(supply_feedback)
	_expect_equal(String(supply_panel_texts.get("title", "")), "补给已使用", "presenter formats supply title")
	_expect_equal(String(supply_panel_texts.get("detail", "")), "生命 +35", "presenter formats supply detail")
func _check_pollution_status_hints() -> void:
	var presenter := HudStatusPresenter.new()
	var pollution_world := WorldState.create_default()
	var pollution_character := CharacterState.create_default()
	_expect_text_contains(
		presenter.format_pollution_status(data_registry, pollution_world, pollution_character),
		"无持续污染",
		"stable region pollution status"
	)
	pollution_world.current_region_id = "region.pollution_edge"
	pollution_character.current_region_id = "region.pollution_edge"
	_expect_text_contains(
		presenter.format_pollution_status(data_registry, pollution_world, pollution_character),
		"未启用过滤模块",
		"pollution status without module"
	)
	pollution_character.equipment["suit_module"] = "equipment.filter_module_t1"
	_expect_text_contains(
		presenter.format_pollution_status(data_registry, pollution_world, pollution_character),
		"消耗 x0.65",
		"pollution status with module"
	)
	pollution_character.protection = 30.0
	_expect_text_contains(
		presenter.format_pollution_status(data_registry, pollution_world, pollution_character),
		"防护危险",
		"low protection pollution status"
	)
func _check_failure_feedback_logs() -> void:
	var log_presenter := HudLogPresenter.new(data_registry)
	var no_target_map := VerticalSliceMap.new()
	var no_target := no_target_map.try_interact(CharacterState.create_default(), WorldState.create_default())
	_expect_failure_feedback(no_target, "交互未执行", "no target interaction feedback")
	_expect_text_contains(
		log_presenter.format_failure_result_log(no_target),
		"下一步：靠近带名称的目标",
		"no target failure log"
	)
	no_target_map.free()
	var no_enemy_map := VerticalSliceMap.new()
	no_enemy_map.enemies_root = Node2D.new()
	var no_enemy := no_enemy_map.try_attack(CharacterState.create_default(), WorldState.create_default())
	_expect_failure_feedback(no_enemy, "攻击未命中", "no enemy attack feedback")
	no_enemy_map.enemies_root.free()
	no_enemy_map.free()
	var processing := ProcessingSystem.new(data_registry)
	var processing_world := WorldState.create_default()
	var processing_character := CharacterState.create_default()
	processing_world.quest_state.unlock_effect("recipe.process_crystal_ore")
	var missing_inputs := processing.process_recipe("recipe.process_crystal_ore", processing_character, processing_world)
	_expect_failure_feedback(missing_inputs, "原料不足", "processing missing inputs feedback")
	var missing_parts_world := WorldState.create_default()
	var missing_parts_character := CharacterState.create_default()
	missing_parts_world.quest_state.unlock_effect("recipe.relay_tuning_lens")
	missing_parts_character.inventory.add_item("item.phase_lens_blank", 1)
	missing_parts_character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	missing_parts_character.inventory.items["item.basic_parts"] = 0
	var missing_parts := processing.process_recipe("recipe.relay_tuning_lens", missing_parts_character, missing_parts_world)
	_expect_failure_feedback(missing_parts, "原料不足", "processing missing basic parts feedback")
	_expect_text_contains(String(missing_parts.get("message", "")), "前哨核心回收", "processing missing basic parts message points to outpost supply")
	_expect_text_contains(String(missing_parts.get("message", "")), "富晶残脉", "processing missing basic parts message points to rich vein fallback")
	var missing_parts_feedback: Dictionary = missing_parts.get("failure_feedback", {})
	_expect_text_contains(String(missing_parts_feedback.get("detail", "")), "阶段补给批次", "processing missing basic parts detail points to stage supply")
	processing_character.inventory.add_item("item.crystal_ore", 3)
	var started := processing.process_recipe("recipe.process_crystal_ore", processing_character, processing_world)
	_expect_equal(bool(started.get("success", false)), true, "processing starts before in-progress failure")
	var in_progress := processing.process_recipe("recipe.process_crystal_ore", processing_character, processing_world)
	_expect_failure_feedback(in_progress, "设备加工中", "processing in progress feedback")
	var build_system := BuildSystem.new(data_registry)
	var build_world := WorldState.create_default()
	var build_character := CharacterState.create_default()
	var blocked_build := build_system.build_structure(
		"map_object_instance.pollution_filter_build_site",
		"building.pollution_filter",
		build_character,
		build_world
	)
	_expect_failure_feedback(blocked_build, "建造前置不足", "build prerequisite feedback")
	var gather_system := GatherSystem.new(data_registry)
	var blocked_sample := gather_system.interact_with_object(
		"map_object_instance.anomaly_crystal",
		"map_object.anomaly_crystal",
		"sample",
		CharacterState.create_default(),
		WorldState.create_default()
	)
	_expect_failure_feedback(blocked_sample, "交互前置不足", "anomaly sample quest gate feedback")
	var blocked_residue := gather_system.interact_with_object(
		"map_object_instance.anomaly_residue_north",
		"map_object.anomaly_residue_patch",
		"gather",
		CharacterState.create_default(),
		WorldState.create_default()
	)
	_expect_failure_feedback(blocked_residue, "交互前置不足", "anomaly residue quest gate feedback")
	var rich_vein_character := CharacterState.create_default()
	var rich_vein_result := gather_system.interact_with_object(
		"map_object_instance.rich_crystal_vein_north",
		"map_object.rich_crystal_vein",
		"gather",
		rich_vein_character,
		WorldState.create_default()
	)
	_expect_equal(bool(rich_vein_result.get("success", false)), true, "rich crystal vein can be gathered as optional supply")
	_expect_equal(int(rich_vein_character.inventory.items.get("item.crystal_ore", 0)), 6, "rich crystal vein grants emergency crystal ore")
func _check_device_panel_formatting() -> void:
	var device_panel_presenter := HudDevicePanelPresenter.new()
	var processing := ProcessingSystem.new(data_registry)
	var formatter := InteractionPromptFormatter.new(data_registry, processing, BuildSystem.new(data_registry))
	var device_world := WorldState.create_default()
	var device_character := CharacterState.create_default()
	var reactor := PrototypeInteractable.new()
	reactor.definition_id = "building.basic_reactor"
	reactor.interaction_type = "process_recipe"
	reactor.recipe_id = "recipe.process_crystal_ore"
	reactor.set_recipe_cycle([
		"recipe.process_crystal_ore",
		"recipe.reactor_calibrator",
		"recipe.analyze_anomaly_sample",
		"recipe.make_filter_media",
		"recipe.basic_filter_module",
		"recipe.foundation_t1",
		"recipe.repair_gel"
	])
	device_world.quest_state.unlock_effect("recipe.process_crystal_ore")
	device_character.inventory.add_item("item.crystal_ore", 3)
	var texts := device_panel_presenter.format_device_panel_texts(
		data_registry,
		processing,
		reactor,
		device_character,
		device_world
	)
	_expect_text_contains(String(texts.get("title", "")), "基础反应器", "device panel title")
	_expect_text_contains(String(texts.get("status", "")), "当前配方：处理晶体矿物", "device panel current recipe")
	_expect_text_contains(String(texts.get("recipes", "")), "> 1. 处理晶体矿物：可加工", "device panel recipe list")
	_expect_text_contains(String(texts.get("operations", "")), "E 启动当前配方", "device panel process operation")
	_expect_text_contains(String(texts.get("operations", "")), "R 切换配方", "device panel cycle operation")
	_expect_text_contains(String(texts.get("operations", "")), "Q 关闭面板", "device panel close operation")
	var prompt_text := formatter.format_processing_prompt(reactor, device_character, device_world)
	_expect_text_contains(prompt_text, "设备：基础反应器", "processing prompt shows device name")
	_expect_text_contains(prompt_text, "Q 详情", "processing prompt keeps device detail shortcut")
	if prompt_text.split("\n").size() > 5:
		failures.append("processing prompt should stay compact, got %d lines: %s" % [prompt_text.split("\n").size(), prompt_text])
	if prompt_text.find("上次结果") >= 0:
		failures.append("processing prompt should not duplicate last completion details: %s" % prompt_text)
	var recommended_world := WorldState.create_default()
	var recommended_character := CharacterState.create_default()
	recommended_world.quest_state.active_quest_ids = ["quest.analyze_anomaly_sample"]
	recommended_world.quest_state.unlock_effect("recipe.analyze_anomaly_sample")
	recommended_world.quest_state.set_objective_progress(
		"quest.analyze_anomaly_sample",
		"gather_item",
		"item.anomaly_residue",
		2
	)
	var recommended_texts := device_panel_presenter.format_device_panel_texts(
		data_registry,
		processing,
		reactor,
		recommended_character,
		recommended_world
	)
	_expect_text_contains(
		String(recommended_texts.get("status", "")),
		"推荐：当前目标建议使用 分析异常样本",
		"device panel recommended recipe status"
	)
	_expect_text_contains(
		String(recommended_texts.get("recipes", "")),
		"分析异常样本（当前目标）",
		"device panel recommended recipe marker"
	)
	var missing_parts_world := WorldState.create_default()
	var missing_parts_character := CharacterState.create_default()
	var missing_parts_reactor := PrototypeInteractable.new()
	missing_parts_world.quest_state.unlock_effect("recipe.relay_tuning_lens")
	missing_parts_character.inventory.add_item("item.phase_lens_blank", 1)
	missing_parts_character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	missing_parts_character.inventory.items["item.basic_parts"] = 0
	missing_parts_reactor.definition_id = "building.basic_reactor"
	missing_parts_reactor.interaction_type = "process_recipe"
	missing_parts_reactor.recipe_id = "recipe.relay_tuning_lens"
	missing_parts_reactor.set_recipe_cycle(["recipe.relay_tuning_lens"])
	var missing_parts_texts := device_panel_presenter.format_device_panel_texts(
		data_registry,
		processing,
		missing_parts_reactor,
		missing_parts_character,
		missing_parts_world
	)
	_expect_text_contains(String(missing_parts_texts.get("status", "")), "前哨核心回收", "device panel basic parts supply points to outpost")
	_expect_text_contains(String(missing_parts_texts.get("status", "")), "阶段补给批次", "device panel basic parts supply points to stage supply")
	_expect_text_contains(String(missing_parts_texts.get("status", "")), "富晶残脉", "device panel basic parts supply points to rich vein")
	_expect_text_contains(String(missing_parts_texts.get("recipes", "")), "缺 基础零件 x2", "device panel basic parts missing input")
	VerticalSliceRegressionChecks.new(self).check_task_recipe_selection(reactor, processing)
	var filter := PrototypeInteractable.new()
	filter.definition_id = "building.pollution_filter"
	filter.interaction_type = "process_recipe"
	filter.recipe_id = "recipe.cleanse_residue"
	filter.set_recipe_cycle(["recipe.cleanse_residue"])
	var filter_world := WorldState.create_default()
	var filter_character := CharacterState.create_default()
	filter_world.quest_state.unlock_effect("recipe.cleanse_residue")
	filter_world.add_base_structure(
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.pollution_edge",
		"map_object_instance.pollution_filter_build_site"
	)
	var filter_texts := device_panel_presenter.format_device_panel_texts(
		data_registry,
		processing,
		filter,
		filter_character,
		filter_world
	)
	_expect_text_contains(String(filter_texts.get("title", "")), "污染过滤器", "filter device panel title")
	_expect_text_contains(String(filter_texts.get("recipes", "")), "缺 污染沉积物 x2", "filter device panel missing input")
	_expect_text_contains(String(filter_texts.get("operations", "")), "E 尝试当前配方", "filter device panel blocked operation")
	reactor.free()
	missing_parts_reactor.free()
	filter.free()
func _check_manual_recipe_cycle_keeps_player_choice() -> void:
	var game_root = GameRootScript.new()
	var recipe_world := WorldState.create_default()
	var recipe_character := CharacterState.create_default()
	var processing := ProcessingSystem.new(data_registry)
	var reactor := PrototypeInteractable.new()
	reactor.definition_id = "building.basic_reactor"
	reactor.interaction_type = "process_recipe"
	reactor.recipe_id = "recipe.process_crystal_ore"
	reactor.set_recipe_cycle([
		"recipe.process_crystal_ore",
		"recipe.analyze_anomaly_sample"
	])
	recipe_world.quest_state.active_quest_ids = ["quest.analyze_anomaly_sample"]
	recipe_world.quest_state.set_objective_progress(
		"quest.analyze_anomaly_sample",
		"gather_item",
		"item.anomaly_residue",
		2
	)
	game_root.processing_system = processing
	game_root.world_state = recipe_world
	game_root.character_state = recipe_character
	_expect_equal(
		game_root._maybe_select_recommended_recipe(reactor, false),
		"",
		"manual recipe cycle should not auto select recommendation"
	)
	_expect_equal(
		reactor.get_current_recipe_id(),
		"recipe.process_crystal_ore",
		"manual recipe cycle keeps current recipe after prompt refresh"
	)
	_expect_equal(
		game_root._maybe_select_recommended_recipe(reactor, true),
		"recipe.analyze_anomaly_sample",
		"device approach can still auto select recommendation"
	)
	_expect_equal(
		reactor.get_current_recipe_id(),
		"recipe.analyze_anomaly_sample",
		"device approach changes to recommended recipe"
	)
	reactor.free()
	game_root.free()
func _complete_active_quest(quest_id: String, progress_refs: Array) -> void:
	if not world_state.quest_state.has_active_quest(quest_id):
		failures.append("%s should be active before completion" % quest_id)
		return
	var updates: Array[Dictionary] = []
	for progress_ref in progress_refs:
		if not progress_ref is Dictionary:
			continue
		updates.append({
			"mode": "set",
			"quest_id": quest_id,
			"objective_type": String(progress_ref.get("type", "")),
			"target_id": String(progress_ref.get("target_id", "")),
			"amount": float(progress_ref.get("amount", 1.0))
		})
	var runtime := QuestRuntime.new(data_registry)
	runtime.apply_objective_updates(world_state, character_state, updates)
	if not world_state.quest_state.has_completed_quest(quest_id):
		failures.append("%s should complete through QuestRuntime" % quest_id)
func _check_processing_runtime() -> void:
	var processing := ProcessingSystem.new(data_registry)
	var processing_world := WorldState.create_default()
	var processing_character := CharacterState.create_default()
	processing_world.quest_state.unlock_effect("recipe.process_crystal_ore")
	processing_character.inventory.add_item("item.crystal_ore", 3)
	var start_result := processing.process_recipe("recipe.process_crystal_ore", processing_character, processing_world)
	_expect_equal(bool(start_result.get("success", false)), true, "processing should start")
	_expect_equal(int(processing_character.inventory.items.get("item.crystal_ore", 0)), 0, "processing consumes inputs on start")
	_expect_equal(int(processing_character.inventory.items.get("item.basic_parts", 0)), 4, "processing should not grant outputs on start")
	var reactor: Dictionary = processing_world.base_structures.get("structure.basic_reactor", {})
	_expect_equal(String(reactor.get("status", "")), "in_progress", "reactor status after start")
	_expect_equal(String(reactor.get("active_recipe_id", "")), "recipe.process_crystal_ore", "reactor active recipe")
	var partial_results := processing.advance_processing(3.0, processing_character, processing_world)
	_expect_equal(partial_results.size(), 0, "processing should not complete early")
	reactor = processing_world.base_structures.get("structure.basic_reactor", {})
	_expect_equal(float(reactor.get("progress_seconds", 0.0)), 3.0, "reactor partial progress")
	var status := processing.get_recipe_status("recipe.process_crystal_ore", processing_character, processing_world)
	if String(status.get("message", "")).find("加工中") < 0:
		failures.append("processing status should show in progress, got %s" % var_to_str(status))
	var completed_results := processing.advance_processing(10.0, processing_character, processing_world)
	_expect_equal(completed_results.size(), 1, "processing should complete after duration")
	if not completed_results.is_empty():
		_expect_text_contains(
			String(completed_results[0].get("message", "")),
			"产物已放入背包：基础零件 x4",
			"processing completion log destination"
		)
		_expect_text_contains(
			String(completed_results[0].get("message", "")),
			"下一步：",
			"processing completion log next step"
		)
	_expect_equal(int(processing_character.inventory.items.get("item.basic_parts", 0)), 8, "processing grants outputs on completion")
	reactor = processing_world.base_structures.get("structure.basic_reactor", {})
	_expect_equal(String(reactor.get("status", "")), "completed", "reactor status after completion")
	_expect_equal(String(reactor.get("active_recipe_id", "")), "", "reactor clears active recipe after completion")
	_expect_equal(String(reactor.get("last_recipe_id", "")), "recipe.process_crystal_ore", "reactor last recipe after completion")
	_expect_equal(int(reactor.get("completed_runs", 0)), 1, "reactor completed runs")
	var completed_status := processing.get_recipe_status("recipe.process_crystal_ore", processing_character, processing_world)
	_expect_text_contains(
		String(completed_status.get("last_completion", "")),
		"刚完成：处理晶体矿物",
		"processing panel last completion"
	)
	_expect_text_contains(
		String(completed_status.get("last_destination", "")),
		"产物已放入背包：基础零件 x4",
		"processing panel destination"
	)
	_expect_text_contains(
		String(completed_status.get("last_next_step", "")),
		"按 R 切换",
		"processing panel next step"
	)
	var filter_world := WorldState.create_default()
	var filter_character := CharacterState.create_default()
	filter_world.quest_state.unlock_effect("recipe.cleanse_residue")
	filter_world.add_base_structure(
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.pollution_edge",
		"map_object_instance.pollution_filter_build_site"
	)
	filter_character.inventory.add_item("item.polluted_residue", 2)
	filter_character.inventory.add_fluid("fluid.basic_solvent", 1.0)
	var filter_start := processing.process_recipe("recipe.cleanse_residue", filter_character, filter_world)
	_expect_equal(bool(filter_start.get("success", false)), true, "pollution filter should start")
	_expect_equal(filter_world.base_structures.has("structure.pollution_filter"), false, "processing should reuse built pollution filter structure")
	var filter_completed := processing.advance_processing(20.0, filter_character, filter_world)
	_expect_equal(filter_completed.size(), 1, "pollution filter should complete")
	if not filter_completed.is_empty():
		_expect_text_contains(
			String(filter_completed[0].get("message", "")),
			"产物已放入背包：抗污染药剂 I x1",
			"pollution filter completion log output destination"
		)
		_expect_text_contains(
			String(filter_completed[0].get("message", "")),
			"副产已放入背包：污染浆液 x1",
			"pollution filter completion log byproduct destination"
		)
		_expect_text_contains(
			String(filter_completed[0].get("message", "")),
			"继续采集沉积物并清理受扰敌人",
			"pollution filter completion log next step"
		)
	_expect_equal(int(filter_character.inventory.items.get("item.resistance_vial_t1", 0)), 1, "pollution filter grants vial")
	_expect_equal(float(filter_character.inventory.fluids.get("fluid.polluted_slurry", 0.0)), 1.0, "pollution filter grants byproduct")
	var filter_status := processing.get_recipe_status("recipe.cleanse_residue", filter_character, filter_world)
	_expect_text_contains(
		String(filter_status.get("last_completion", "")),
		"刚完成：处理污染沉积物",
		"pollution filter panel last completion"
	)
	_expect_text_contains(
		String(filter_status.get("last_destination", "")),
		"副产已放入背包：污染浆液 x1",
		"pollution filter panel byproduct destination"
	)
	_expect_text_contains(
		String(filter_status.get("last_next_step", "")),
		"抗污染药剂",
		"pollution filter panel next step"
	)
func _check_evacuation_feedback() -> void:
	var map := VerticalSliceMap.new()
	map.player = PlayerController.new()
	var evacuation_world := WorldState.create_default()
	var evacuation_character := CharacterState.create_default()
	evacuation_character.health = 0.0
	evacuation_character.protection = 80.0
	evacuation_character.current_region_id = "region.pollution_edge"
	evacuation_world.current_region_id = "region.pollution_edge"
	var feedback := map._evacuate_if_needed(evacuation_character, evacuation_world, "combat")
	_expect_equal(String(feedback.get("title", "")), "撤离前哨", "evacuation feedback title")
	_expect_equal(String(feedback.get("reason_text", "")), "生命耗尽", "evacuation reason")
	_expect_equal(evacuation_world.current_region_id, "region.outpost_platform", "evacuation world region")
	_expect_equal(evacuation_character.current_region_id, "region.outpost_platform", "evacuation character region")
	_expect_equal(evacuation_character.health, 60.0, "evacuation health recovery")
	if String(feedback.get("retry_text", "")).find("修复凝胶") < 0:
		failures.append("evacuation retry text should mention repair gel, got %s" % var_to_str(feedback))
	var presenter := HudFeedbackPresenter.new()
	var panel_texts := presenter.format_evacuation_panel_texts(feedback)
	_expect_equal(String(panel_texts.get("title", "")), "撤离结果：生命耗尽", "evacuation panel title")
	_expect_text_contains(String(panel_texts.get("detail", "")), "原因：生命耗尽", "evacuation panel reason")
	_expect_text_contains(String(panel_texts.get("detail", "")), "恢复：已撤回前哨", "evacuation panel recovery")
	_expect_text_contains(String(panel_texts.get("detail", "")), "再尝试前：按 1 使用修复凝胶", "evacuation panel retry")
	map.player.free()
	map.free()
func _expect_active_quest(quest_id: String, label: String) -> void:
	_expect_array_has(world_state.quest_state.active_quest_ids, quest_id, label)
func _expect_equal(actual, expected, label: String) -> void:
	if actual != expected:
		failures.append("%s expected %s, got %s" % [label, var_to_str(expected), var_to_str(actual)])
func _expect_array_has(values: Array, expected_value: String, label: String) -> void:
	if not values.has(expected_value):
		failures.append("%s should contain %s, got %s" % [label, expected_value, var_to_str(values)])
func _expect_array_missing(values: Array, unexpected_value: String, label: String) -> void:
	if values.has(unexpected_value):
		failures.append("%s should not contain %s, got %s" % [label, unexpected_value, var_to_str(values)])
func _expect_hint_contains(
	presenter: HudHintPresenter,
	hint_world: WorldState,
	hint_character: CharacterState,
	quest_id: String,
	expected_text: String,
	label: String
) -> void:
	var hint := presenter.format_onboarding_hint(hint_world, hint_character, quest_id)
	if hint.find(expected_text) < 0:
		failures.append("%s should contain %s, got %s" % [label, expected_text, hint])
func _expect_text_contains(text: String, expected_text: String, label: String) -> void:
	if text.find(expected_text) < 0:
		failures.append("%s should contain %s, got %s" % [label, expected_text, text])
func _expect_text_missing(text: String, unexpected_text: String, label: String) -> void:
	if text.find(unexpected_text) >= 0:
		failures.append("%s should not contain %s, got %s" % [label, unexpected_text, text])
func _expect_feedback_contains(result: Dictionary, expected_text: String, label: String) -> void:
	var feedback = result.get("supply_feedback", {})
	if not feedback is Dictionary:
		failures.append("%s should include supply feedback, got %s" % [label, var_to_str(result)])
		return
	var text := "%s %s" % [
		String(feedback.get("title", "")),
		String(feedback.get("detail", ""))
	]
	_expect_text_contains(text, expected_text, label)
func _create_visual_check_interactable(
	parent: Node,
	instance_id: String,
	definition_id: String,
	interaction_type: String,
	display_name: String
) -> PrototypeInteractable:
	var interactable := PrototypeInteractable.new()
	var marker := ColorRect.new()
	marker.name = "Marker"
	marker.offset_left = -16.0
	marker.offset_top = -16.0
	marker.offset_right = 16.0
	marker.offset_bottom = 16.0
	marker.color = PrototypeInteractable.DEFAULT_MARKER_COLOR
	interactable.add_child(marker)
	interactable.marker = marker
	var label := Label.new()
	label.name = "Label"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interactable.add_child(label)
	interactable.label = label
	parent.add_child(interactable)
	interactable.instance_id = instance_id
	interactable.definition_id = definition_id
	interactable.interaction_type = interaction_type
	interactable.setup(display_name)
	return interactable
func _create_visual_check_enemy(
	definition_id: String,
	display_name: String,
	max_health: float,
	category: String
) -> PrototypeEnemy:
	var enemy := PrototypeEnemy.new()
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	collision_shape.shape = CircleShape2D.new()
	enemy.add_child(collision_shape)
	enemy.collision_shape = collision_shape
	var sprite := ColorRect.new()
	sprite.name = "Sprite"
	sprite.color = Color(0.8, 0.313726, 0.215686, 1)
	enemy.add_child(sprite)
	enemy.sprite = sprite
	var label := Label.new()
	label.name = "Label"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy.add_child(label)
	enemy.label = label
	enemy.definition_id = definition_id
	enemy.setup(display_name, max_health, category)
	return enemy
func _expect_failure_feedback(result: Dictionary, expected_title: String, label: String) -> void:
	_expect_equal(bool(result.get("success", true)), false, "%s success state" % label)
	var feedback = result.get("failure_feedback", {})
	if not feedback is Dictionary:
		failures.append("%s should include failure feedback, got %s" % [label, var_to_str(result)])
		return
	_expect_equal(String(feedback.get("title", "")), expected_title, label)
	if String(feedback.get("detail", "")).strip_edges().is_empty():
		failures.append("%s should include next-step detail, got %s" % [label, var_to_str(feedback)])
func _cleanup() -> void:
	data_registry.free()
