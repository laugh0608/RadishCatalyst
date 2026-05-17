extends RefCounted
class_name DevelopmentBaselineBuilder

const BASELINE_OUTPOST_POSITION := Vector2(-250, -48)
const BASELINE_OUTER_RING_POSITION := Vector2(604, -44)
const BASELINE_DEEP_THRESHOLD_POSITION := Vector2(738, 10)
const BASELINE_PHASE_RELAY_PAD_POSITION := Vector2(-188, 48)
const BASELINE_ANCHOR_FIELD_POSITION := Vector2(3192, 18)
const BASELINE_FRONTLINE_ACTION_CONSOLE_POSITION := Vector2(-92, 48)

const QUEST_PROGRESS_ORDER: Array[String] = [
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
	"quest.inspect_phase_well_sink",
	"quest.analyze_phase_well_heart",
	"quest.collect_heart_spine",
	"quest.refine_heart_spine",
	"quest.inspect_phase_well_chamber",
	"quest.analyze_phase_well_spindle",
	"quest.collect_weft_bundle",
	"quest.refine_weft_bundle",
	"quest.inspect_phase_well_loom",
	"quest.analyze_phase_well_weave_core",
	"quest.collect_selvedge_strip",
	"quest.refine_selvedge_strip",
	"quest.inspect_phase_well_frame",
	"quest.analyze_phase_well_knot_core",
	"quest.collect_tether_fiber",
	"quest.refine_tether_fiber",
	"quest.inspect_phase_well_tether",
	"quest.analyze_phase_well_anchor_core",
	"quest.refine_anchor_core_dust",
	"quest.stabilize_phase_well_anchor_field",
	"quest.analyze_phase_well_echo_shard",
	"quest.calibrate_phase_well_stability_window",
	"quest.plan_stability_frontline_action",
	"quest.survey_stability_echo_probe",
	"quest.analyze_stability_echo_sample",
	"quest.confirm_supply_frontline_action",
	"quest.inspect_supply_return_marker",
	"quest.analyze_supply_return_trace",
	"quest.confirm_route_frontline_action",
	"quest.inspect_route_signal_marker",
	"quest.analyze_route_signal_trace",
	"quest.choose_phase_survey_action",
	"quest.inspect_phase_survey_nodes",
	"quest.analyze_phase_survey_trace"
]

var data_registry: DataRegistry
var progress_rules: QuestProgressRules
var completion_rules: QuestCompletionRules
var completion_applier: QuestCompletionApplier


func _init(registry: DataRegistry) -> void:
	data_registry = registry
	progress_rules = QuestProgressRules.new(data_registry)
	completion_rules = QuestCompletionRules.new(data_registry, progress_rules)
	completion_applier = QuestCompletionApplier.new(data_registry)


func get_baseline_definitions() -> Array[Dictionary]:
	return DevelopmentBaselineCatalog.get_baseline_definitions()


func create_baseline_state(baseline_id: String) -> Dictionary:
	var definition := DevelopmentBaselineCatalog.get_definition(baseline_id)
	if definition.is_empty():
		return _failure("未找到开发基线：%s。" % baseline_id)

	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	var completed_through := String(definition.get("completed_through", ""))
	if not completed_through.is_empty():
		var progression_result := _complete_progress_until(world_state, character_state, completed_through)
		if not bool(progression_result.get("success", false)):
			return progression_result

	_apply_baseline_pose_and_inventory(String(definition.get("id", "")), world_state, character_state)
	return {
		"success": true,
		"message": _format_loaded_message(definition),
		"baseline_definition": definition,
		"world_state": world_state,
		"character_state": character_state
	}


func _complete_progress_until(
	world_state: WorldState,
	character_state: CharacterState,
	completed_through: String
) -> Dictionary:
	var found_target := completed_through.is_empty()
	for quest_id in QUEST_PROGRESS_ORDER:
		var completion_result := _complete_quest(world_state, character_state, quest_id)
		if not bool(completion_result.get("success", false)):
			return completion_result
		if quest_id == completed_through:
			found_target = true
			break

	if not found_target:
		return _failure("开发基线引用了未知阶段终点：%s。" % completed_through)
	return _success("开发基线阶段已生成。")


func _complete_quest(world_state: WorldState, character_state: CharacterState, quest_id: String) -> Dictionary:
	if not world_state.quest_state.has_active_quest(quest_id):
		return _failure("开发基线生成失败：任务未激活：%s。" % quest_id)

	var quest := data_registry.get_definition(quest_id)
	if quest.is_empty():
		return _failure("开发基线生成失败：缺少任务定义：%s。" % quest_id)

	for objective in quest.get("objectives", []):
		if not objective is Dictionary:
			continue
		progress_rules.set_active_objective_progress(
			world_state.quest_state,
			quest_id,
			String(objective.get("type", "")),
			String(objective.get("target_id", "")),
			float(objective.get("amount", 1.0))
		)

	var completion_result := completion_rules.try_complete_quest(world_state.quest_state, quest_id)
	if not bool(completion_result.get("completed", false)):
		return _failure("开发基线生成失败：任务未能完成：%s。" % quest_id)

	completion_applier.apply_completion(world_state, character_state, completion_result)
	_apply_completed_quest_runtime_state(world_state, quest_id)
	return _success("任务阶段已推进。")


func _apply_completed_quest_runtime_state(world_state: WorldState, quest_id: String) -> void:
	match quest_id:
		"quest.calibrate_reactor":
			_mark_objects_gathered(world_state, [
				"map_object_instance.field_wreckage_north",
				"map_object_instance.field_wreckage_east"
			], "map_object.field_wreckage", "region.crystal_vein_field")
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.reactor_calibrator")
		"quest.bring_back_sample":
			_mark_object_sampled(world_state, "map_object_instance.anomaly_crystal", "map_object.anomaly_crystal", "region.crystal_vein_field")
		"quest.analyze_anomaly_sample":
			_mark_objects_gathered(world_state, [
				"map_object_instance.anomaly_residue_north",
				"map_object_instance.anomaly_residue_east"
			], "map_object.anomaly_residue_patch", "region.crystal_vein_field")
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.analyze_anomaly_sample")
		"quest.make_filter_module":
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.basic_filter_module")
		"quest.prepare_treatment_supplies":
			_mark_enemy_defeated(world_state, "enemy_instance.treatment_skitter", "enemy.treatment_skitter", "region.crystal_vein_field")
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.repair_gel")
		"quest.expand_treatment_point":
			_mark_objects_cleared(world_state, [
				"map_object_instance.rough_ground_north",
				"map_object_instance.rough_ground_south"
			], "map_object.rough_ground", "region.pollution_edge")
			_mark_structure_built(
				world_state,
				"structure.foundation_site_north",
				"building.foundation_t1",
				"region.pollution_edge",
				"map_object_instance.foundation_site_north"
			)
			_mark_structure_built(
				world_state,
				"structure.foundation_site_south",
				"building.foundation_t1",
				"region.pollution_edge",
				"map_object_instance.foundation_site_south"
			)
			_mark_structure_built(
				world_state,
				"structure.pollution_filter_build_site",
				"building.pollution_filter",
				"region.pollution_edge",
				"map_object_instance.pollution_filter_build_site"
			)
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.foundation_t1")
		"quest.enter_pollution_edge":
			_mark_object_gathered(world_state, "map_object_instance.pollution_residue", "map_object.pollution_residue_patch", "region.pollution_edge")
			_mark_enemy_defeated(world_state, "enemy_instance.polluted_skitter", "enemy.polluted_skitter", "region.pollution_edge")
			_mark_structure_completed(world_state, "structure.pollution_filter_build_site", "recipe.cleanse_residue")
		"quest.defeat_elite_node":
			_mark_enemy_defeated(world_state, "enemy_instance.elite_residue_node", "enemy.elite_residue_node", "region.pollution_edge")
		"quest.scout_ruin_outer_ring":
			_mark_objects_gathered(world_state, [
				"map_object_instance.relay_shard_cache_north",
				"map_object_instance.relay_shard_cache_south"
			], "map_object.relay_shard_cache", "region.ruin_outer_ring")
		"quest.assemble_phase_anchor":
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.phase_anchor")
		"quest.salvage_signal_echo":
			_mark_enemy_defeated(world_state, "enemy_instance.ruin_phase_guard", "enemy.ruin_phase_guard", "region.ruin_outer_ring")
		"quest.analyze_deep_signal":
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.deep_signal_analysis")
		"quest.harvest_phase_filament":
			_mark_enemy_defeated(world_state, "enemy_instance.deep_ruin_sentinel", "enemy.deep_ruin_sentinel", "region.deep_ruin_threshold")
			_mark_objects_gathered(world_state, [
				"map_object_instance.phase_filament_cluster_north",
				"map_object_instance.phase_filament_cluster_south"
			], "map_object.phase_filament_cluster", "region.deep_ruin_threshold")
		"quest.refine_phase_filament":
			_mark_structure_completed(world_state, "structure.pollution_filter_build_site", "recipe.phase_filament_refining")
		"quest.assemble_deep_override":
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.deep_override_key")
		"quest.analyze_deep_core":
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.deep_core_imprint")
		"quest.activate_deep_array":
			_mark_enemy_defeated(world_state, "enemy_instance.deep_ruin_stalker", "enemy.deep_ruin_stalker", "region.deep_ruin_threshold")
			_mark_objects_gathered(world_state, [
				"map_object_instance.phase_conduit_cluster_north",
				"map_object_instance.phase_conduit_cluster_south"
			], "map_object.phase_conduit_cluster", "region.deep_ruin_threshold")
		"quest.assemble_deep_signal_matrix":
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.deep_signal_matrix")
		"quest.deploy_phase_relay_anchor":
			world_state.set_active_phase_relay_anchor("map_object_instance.phase_return_anchor")
		"quest.trace_phase_splinters":
			_mark_enemy_defeated(world_state, "enemy_instance.deep_fault_hunter", "enemy.deep_fault_hunter", "region.deep_ruin_threshold")
			_mark_object_sampled(world_state, "map_object_instance.phase_splinter_resonance_west", "map_object.phase_splinter_resonance_node", "region.deep_ruin_threshold")
			_mark_object_sampled(world_state, "map_object_instance.phase_splinter_resonance_east", "map_object.phase_splinter_resonance_node", "region.deep_ruin_threshold")
			_mark_objects_gathered(world_state, [
				"map_object_instance.phase_splinter_cluster_north",
				"map_object_instance.phase_splinter_cluster_south"
			], "map_object.phase_splinter_cluster", "region.deep_ruin_threshold")
		"quest.refine_phase_splinters":
			_mark_structure_completed(world_state, "structure.pollution_filter_build_site", "recipe.phase_splinter_refining")
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.relay_tuning_lens")
		"quest.analyze_inner_fault_trace":
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.inner_fault_analysis")
		"quest.collect_fault_residue":
			_mark_enemy_defeated(world_state, "enemy_instance.inner_fault_stalker", "enemy.inner_fault_stalker", "region.deep_ruin_threshold")
			_mark_object_sampled(world_state, "map_object_instance.fault_residue_pulse_west", "map_object.fault_residue_pulse_node", "region.deep_ruin_threshold")
			_mark_object_sampled(world_state, "map_object_instance.fault_residue_pulse_east", "map_object.fault_residue_pulse_node", "region.deep_ruin_threshold")
			_mark_objects_gathered(world_state, [
				"map_object_instance.fault_residue_cluster_north",
				"map_object_instance.fault_residue_cluster_south"
			], "map_object.fault_residue_cluster", "region.deep_ruin_threshold")
		"quest.refine_fault_residue":
			_mark_structure_completed(world_state, "structure.pollution_filter_build_site", "recipe.fault_residue_stabilization")
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.phase_well_key")
		"quest.analyze_phase_well_locator":
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.phase_well_locator_analysis")
		"quest.collect_well_flux":
			_mark_enemy_defeated(world_state, "enemy_instance.phase_well_sentry", "enemy.phase_well_sentry", "region.inner_phase_well")
			_mark_object_sampled(world_state, "map_object_instance.well_flux_pressure_vent_west", "map_object.well_flux_pressure_vent", "region.inner_phase_well")
			_mark_object_sampled(world_state, "map_object_instance.well_flux_pressure_vent_east", "map_object.well_flux_pressure_vent", "region.inner_phase_well")
			_mark_objects_gathered(world_state, [
				"map_object_instance.well_flux_cluster_north",
				"map_object_instance.well_flux_cluster_south"
			], "map_object.well_flux_cluster", "region.inner_phase_well")
		"quest.refine_well_flux":
			_mark_structure_completed(world_state, "structure.pollution_filter_build_site", "recipe.well_flux_stabilization")
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.phase_well_probe")
		"quest.analyze_phase_well_core":
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.phase_well_core_analysis")
		"quest.collect_well_ash":
			_mark_enemy_defeated(world_state, "enemy_instance.phase_well_lurker", "enemy.phase_well_lurker", "region.phase_well_sink")
			_mark_objects_cleared(world_state, [
				"map_object_instance.well_ash_crust_north",
				"map_object_instance.well_ash_crust_south"
			], "map_object.well_ash_crust_blocker", "region.phase_well_sink")
			_mark_objects_gathered(world_state, [
				"map_object_instance.well_ash_cluster_north",
				"map_object_instance.well_ash_cluster_south"
			], "map_object.well_ash_cluster", "region.phase_well_sink")
		"quest.refine_well_ash":
			_mark_structure_completed(world_state, "structure.pollution_filter_build_site", "recipe.well_ash_stabilization")
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.phase_well_pike")
		"quest.analyze_phase_well_heart":
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.phase_well_heart_analysis")
		"quest.collect_heart_spine":
			_mark_enemy_defeated(world_state, "enemy_instance.phase_well_reaver", "enemy.phase_well_reaver", "region.phase_well_chamber")
			_mark_objects_gathered(world_state, [
				"map_object_instance.heart_spine_cluster_north",
				"map_object_instance.heart_spine_cluster_south"
			], "map_object.heart_spine_cluster", "region.phase_well_chamber")
		"quest.refine_heart_spine":
			_mark_structure_completed(world_state, "structure.pollution_filter_build_site", "recipe.heart_spine_stabilization")
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.phase_well_shunt")
		"quest.analyze_phase_well_spindle":
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.phase_well_spindle_analysis")
		"quest.collect_weft_bundle":
			_mark_enemy_defeated(world_state, "enemy_instance.phase_well_tangler", "enemy.phase_well_tangler", "region.phase_well_loom")
			_mark_objects_gathered(world_state, [
				"map_object_instance.weft_bundle_cluster_north",
				"map_object_instance.weft_bundle_cluster_south"
			], "map_object.weft_bundle_cluster", "region.phase_well_loom")
		"quest.refine_weft_bundle":
			_mark_structure_completed(world_state, "structure.pollution_filter_build_site", "recipe.weft_bundle_stabilization")
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.phase_well_shuttle")
		"quest.analyze_phase_well_weave_core":
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.phase_well_weave_core_analysis")
		"quest.collect_selvedge_strip":
			_mark_enemy_defeated(world_state, "enemy_instance.phase_well_raker", "enemy.phase_well_raker", "region.phase_well_frame")
			_mark_objects_gathered(world_state, [
				"map_object_instance.selvedge_strip_cluster_north",
				"map_object_instance.selvedge_strip_cluster_south"
			], "map_object.selvedge_strip_cluster", "region.phase_well_frame")
		"quest.refine_selvedge_strip":
			_mark_structure_completed(world_state, "structure.pollution_filter_build_site", "recipe.selvedge_strip_stabilization")
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.phase_well_frame_key")
		"quest.analyze_phase_well_knot_core":
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.phase_well_knot_core_analysis")
		"quest.collect_tether_fiber":
			_mark_enemy_defeated(world_state, "enemy_instance.phase_well_binder", "enemy.phase_well_binder", "region.phase_well_tether")
			_mark_objects_gathered(world_state, [
				"map_object_instance.tether_fiber_cluster_north",
				"map_object_instance.tether_fiber_cluster_south"
			], "map_object.tether_fiber_cluster", "region.phase_well_tether")
		"quest.refine_tether_fiber":
			_mark_structure_completed(world_state, "structure.pollution_filter_build_site", "recipe.tether_fiber_stabilization")
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.phase_well_tether_spike")
		"quest.analyze_phase_well_anchor_core":
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.phase_well_anchor_core_analysis")
		"quest.refine_anchor_core_dust":
			_mark_structure_completed(world_state, "structure.pollution_filter_build_site", "recipe.anchor_core_dust_stabilization")
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.phase_well_anchor_stake")
		"quest.stabilize_phase_well_anchor_field":
			var anchor_field_state := world_state.ensure_map_object(
				"map_object_instance.phase_well_anchor_field",
				"map_object.phase_well_anchor_field",
				"region.phase_well_tether"
			)
			anchor_field_state["anchor_field_deployed"] = true
			anchor_field_state["anchor_field_pressure_active"] = false
			anchor_field_state["anchor_field_pressure_cleared"] = true
			anchor_field_state["anchor_field_stabilized"] = true
			_mark_enemy_defeated(world_state, "enemy_instance.phase_well_warden", "enemy.phase_well_warden", "region.phase_well_tether")
		"quest.analyze_phase_well_echo_shard":
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.phase_well_echo_shard_analysis")
		"quest.calibrate_phase_well_stability_window":
			for node in [
				{
					"instance_id": "map_object_instance.phase_well_stability_node_west",
					"definition_id": "map_object.phase_well_stability_node_west"
				},
				{
					"instance_id": "map_object_instance.phase_well_stability_node_core",
					"definition_id": "map_object.phase_well_stability_node_core"
				},
				{
					"instance_id": "map_object_instance.phase_well_stability_node_east",
					"definition_id": "map_object.phase_well_stability_node_east"
				}
			]:
				var node_state := world_state.ensure_map_object(
					String(node.get("instance_id", "")),
					String(node.get("definition_id", "")),
					"region.phase_well_tether"
				)
				node_state["stability_node_calibrated"] = true
		"quest.plan_stability_frontline_action":
			_mark_object_sampled(
				world_state,
				"map_object_instance.frontline_action_console",
				"map_object.frontline_action_console",
				"region.outpost_platform"
			)
		"quest.survey_stability_echo_probe":
			_mark_object_sampled(
				world_state,
				"map_object_instance.stability_echo_probe",
				"map_object.stability_echo_probe",
				"region.phase_well_tether"
			)
		"quest.analyze_stability_echo_sample":
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.stability_echo_report")
		"quest.confirm_supply_frontline_action":
			_mark_object_sampled(
				world_state,
				"map_object_instance.frontline_supply_console",
				"map_object.frontline_supply_console",
				"region.outpost_platform"
			)
		"quest.inspect_supply_return_marker":
			_mark_object_sampled(
				world_state,
				"map_object_instance.supply_return_marker",
				"map_object.supply_return_marker",
				"region.phase_well_tether"
			)
		"quest.analyze_supply_return_trace":
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.short_action_feedback")
		"quest.confirm_route_frontline_action":
			_mark_object_sampled(
				world_state,
				"map_object_instance.frontline_route_console",
				"map_object.frontline_route_console",
				"region.outpost_platform"
			)
		"quest.inspect_route_signal_marker":
			_mark_object_sampled(
				world_state,
				"map_object_instance.route_signal_marker",
				"map_object.route_signal_marker",
				"region.phase_well_tether"
			)
		"quest.analyze_route_signal_trace":
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.route_action_feedback")
		"quest.choose_steady_supply_action":
			_mark_object_sampled(
				world_state,
				"map_object_instance.base_supply_choice_console",
				"map_object.base_supply_choice_console",
				"region.outpost_platform"
			)
		"quest.choose_phase_survey_action":
			_mark_object_sampled(
				world_state,
				"map_object_instance.base_survey_choice_console",
				"map_object.base_survey_choice_console",
				"region.outpost_platform"
			)
		"quest.inspect_steady_supply_drop":
			_mark_object_sampled(
				world_state,
				"map_object_instance.steady_supply_drop_marker",
				"map_object.steady_supply_drop_marker",
				"region.phase_well_tether"
			)
		"quest.analyze_steady_supply_trace":
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.steady_supply_feedback")
		"quest.inspect_phase_survey_nodes":
			for node in [
				{
					"instance_id": "map_object_instance.phase_survey_node_west",
					"definition_id": "map_object.phase_survey_node_west"
				},
				{
					"instance_id": "map_object_instance.phase_survey_node_east",
					"definition_id": "map_object.phase_survey_node_east"
				}
			]:
				_mark_object_sampled(
					world_state,
					String(node.get("instance_id", "")),
					String(node.get("definition_id", "")),
					"region.phase_well_tether"
				)
		"quest.analyze_phase_survey_trace":
			_mark_structure_completed(world_state, "structure.basic_reactor", "recipe.phase_survey_feedback")


func _apply_baseline_pose_and_inventory(
	baseline_id: String,
	world_state: WorldState,
	character_state: CharacterState
) -> void:
	character_state.health = character_state.max_health
	character_state.protection = character_state.max_protection
	character_state.quick_slots = ["item.repair_gel", "item.resistance_vial_t1"]
	match baseline_id:
		"baseline.s0_new_game":
			_set_runtime_position(world_state, character_state, "region.outpost_platform", BASELINE_OUTPOST_POSITION)
			character_state.equipment["suit_module"] = ""
			character_state.inventory = _make_inventory(
				{"item.basic_parts": 4, "item.repair_gel": 1},
				{},
				{"fluid.basic_solvent": 3.0}
			)
		"baseline.s1_treatment_ready":
			_set_runtime_position(world_state, character_state, "region.outpost_platform", BASELINE_OUTPOST_POSITION)
			character_state.equipment["suit_module"] = ""
			character_state.inventory = _make_inventory(
				{"item.basic_parts": 4, "item.repair_gel": 2},
				{"equipment.filter_module_t1": 1},
				{"fluid.basic_solvent": 3.0}
			)
		"baseline.s2_outer_ring_secured":
			_set_runtime_position(world_state, character_state, "region.ruin_outer_ring", BASELINE_OUTER_RING_POSITION)
			character_state.equipment["suit_module"] = "equipment.filter_module_t1"
			character_state.inventory = _make_inventory(
				{"item.basic_parts": 4, "item.repair_gel": 2, "item.resistance_vial_t1": 1},
				{},
				{"fluid.basic_solvent": 2.0}
			)
		"baseline.s3_deep_entrance_open":
			_set_runtime_position(world_state, character_state, "region.deep_ruin_threshold", BASELINE_DEEP_THRESHOLD_POSITION)
			character_state.equipment["suit_module"] = "equipment.filter_module_t1"
			character_state.inventory = _make_inventory(
				{"item.basic_parts": 4, "item.repair_gel": 2, "item.resistance_vial_t1": 1},
				{},
				{"fluid.basic_solvent": 2.0}
			)
			progress_rules.set_active_objective_progress(
				world_state.quest_state,
				"quest.harvest_phase_filament",
				"visit_region",
				"region.deep_ruin_threshold",
				1.0
			)
		"baseline.s4_deep_cache_open":
			_set_runtime_position(world_state, character_state, "region.outpost_platform", BASELINE_OUTPOST_POSITION)
			character_state.equipment["suit_module"] = "equipment.filter_module_t1"
			character_state.inventory = _make_inventory(
				{
					"item.basic_parts": 4,
					"item.deep_ruin_core": 1,
					"item.repair_gel": 1,
					"item.resistance_vial_t1": 1
				},
				{},
				{"fluid.basic_solvent": 2.0, "fluid.polluted_slurry": 1.0}
			)
		"baseline.s5_phase_relay_online":
			_set_runtime_position(world_state, character_state, "region.outpost_platform", BASELINE_PHASE_RELAY_PAD_POSITION)
			character_state.equipment["suit_module"] = "equipment.filter_module_t1"
			character_state.inventory = _make_inventory(
				{"item.basic_parts": 2, "item.repair_gel": 1, "item.resistance_vial_t1": 1},
				{},
				{"fluid.basic_solvent": 2.0}
			)
		"baseline.s6_inner_fault_trace_ready":
			_set_runtime_position(world_state, character_state, "region.outpost_platform", BASELINE_PHASE_RELAY_PAD_POSITION)
			character_state.equipment["suit_module"] = "equipment.filter_module_t1"
			character_state.inventory = _make_inventory(
				{"item.basic_parts": 4, "item.repair_gel": 1, "item.resistance_vial_t1": 1},
				{},
				{"fluid.basic_solvent": 2.0}
			)
		"baseline.s7_phase_well_locator_ready":
			_set_runtime_position(world_state, character_state, "region.outpost_platform", BASELINE_PHASE_RELAY_PAD_POSITION)
			character_state.equipment["suit_module"] = "equipment.filter_module_t1"
			character_state.inventory = _make_inventory(
				{"item.basic_parts": 4, "item.phase_well_locator": 1, "item.repair_gel": 1, "item.resistance_vial_t1": 1},
				{},
				{"fluid.basic_solvent": 2.0}
			)
		"baseline.s8_phase_well_core_ready":
			_set_runtime_position(world_state, character_state, "region.outpost_platform", BASELINE_PHASE_RELAY_PAD_POSITION)
			character_state.equipment["suit_module"] = "equipment.filter_module_t1"
			character_state.inventory = _make_inventory(
				{"item.basic_parts": 4, "item.phase_well_core": 1, "item.repair_gel": 1, "item.resistance_vial_t1": 1},
				{},
				{"fluid.basic_solvent": 2.0}
			)
		"baseline.s9_phase_well_heart_ready":
			_set_runtime_position(world_state, character_state, "region.outpost_platform", BASELINE_PHASE_RELAY_PAD_POSITION)
			character_state.equipment["suit_module"] = "equipment.filter_module_t1"
			character_state.inventory = _make_inventory(
				{"item.basic_parts": 4, "item.phase_well_heart": 1, "item.repair_gel": 1, "item.resistance_vial_t1": 1},
				{},
				{"fluid.basic_solvent": 2.0}
			)
		"baseline.s10_phase_well_spindle_ready":
			_set_runtime_position(world_state, character_state, "region.outpost_platform", BASELINE_PHASE_RELAY_PAD_POSITION)
			world_state.set_active_phase_relay_anchor("map_object_instance.phase_return_anchor_chamber")
			character_state.equipment["suit_module"] = "equipment.filter_module_t1"
			character_state.inventory = _make_inventory(
				{"item.basic_parts": 4, "item.phase_well_spindle": 1, "item.repair_gel": 1, "item.resistance_vial_t1": 1},
				{},
				{"fluid.basic_solvent": 2.0}
			)
		"baseline.s11_phase_well_weave_core_ready":
			_set_runtime_position(world_state, character_state, "region.outpost_platform", BASELINE_PHASE_RELAY_PAD_POSITION)
			world_state.set_active_phase_relay_anchor("map_object_instance.phase_return_anchor_chamber")
			character_state.equipment["suit_module"] = "equipment.filter_module_t1"
			character_state.inventory = _make_inventory(
				{"item.basic_parts": 4, "item.phase_well_weave_core": 1, "item.repair_gel": 1, "item.resistance_vial_t1": 1},
				{},
				{"fluid.basic_solvent": 2.0}
			)
		"baseline.s12_phase_well_knot_core_ready":
			_set_runtime_position(world_state, character_state, "region.outpost_platform", BASELINE_PHASE_RELAY_PAD_POSITION)
			world_state.set_active_phase_relay_anchor("map_object_instance.phase_return_anchor_chamber")
			character_state.equipment["suit_module"] = "equipment.filter_module_t1"
			character_state.inventory = _make_inventory(
				{"item.basic_parts": 4, "item.phase_well_knot_core": 1, "item.repair_gel": 1, "item.resistance_vial_t1": 1},
				{},
				{"fluid.basic_solvent": 2.0}
			)
		"baseline.s13_phase_well_anchor_core_ready":
			_set_runtime_position(world_state, character_state, "region.outpost_platform", BASELINE_PHASE_RELAY_PAD_POSITION)
			world_state.set_active_phase_relay_anchor("map_object_instance.phase_return_anchor_chamber")
			character_state.equipment["suit_module"] = "equipment.filter_module_t1"
			character_state.inventory = _make_inventory(
				{"item.basic_parts": 4, "item.phase_well_anchor_core": 1, "item.repair_gel": 1, "item.resistance_vial_t1": 1},
				{},
				{"fluid.basic_solvent": 2.0}
			)
		"baseline.s14_phase_well_anchor_field_stabilized":
			_set_runtime_position(world_state, character_state, "region.phase_well_tether", BASELINE_ANCHOR_FIELD_POSITION)
			world_state.add_deployed_phase_relay_anchor("map_object_instance.phase_return_anchor_chamber")
			world_state.set_active_phase_relay_anchor("map_object_instance.phase_return_anchor_tether")
			character_state.equipment["suit_module"] = "equipment.filter_module_t1"
			character_state.inventory = _make_inventory(
				{"item.basic_parts": 4, "item.phase_well_echo_shard": 1, "item.repair_gel": 1, "item.resistance_vial_t1": 1},
				{},
				{"fluid.basic_solvent": 2.0}
			)
		"baseline.s15_phase_well_stability_readout_ready":
			_set_runtime_position(world_state, character_state, "region.phase_well_tether", BASELINE_ANCHOR_FIELD_POSITION)
			world_state.add_deployed_phase_relay_anchor("map_object_instance.phase_return_anchor_chamber")
			world_state.set_active_phase_relay_anchor("map_object_instance.phase_return_anchor_tether")
			character_state.equipment["suit_module"] = "equipment.filter_module_t1"
			character_state.inventory = _make_inventory(
				{"item.basic_parts": 4, "item.phase_well_stability_readout": 1, "item.repair_gel": 1, "item.resistance_vial_t1": 1},
				{},
				{"fluid.basic_solvent": 2.0}
			)
		"baseline.s16_phase_well_stability_window_calibrated":
			_set_runtime_position(world_state, character_state, "region.phase_well_tether", BASELINE_ANCHOR_FIELD_POSITION)
			world_state.add_deployed_phase_relay_anchor("map_object_instance.phase_return_anchor_chamber")
			world_state.set_active_phase_relay_anchor("map_object_instance.phase_return_anchor_tether")
			character_state.equipment["suit_module"] = "equipment.filter_module_t1"
			character_state.inventory = _make_inventory(
				{"item.basic_parts": 4, "item.phase_well_stability_readout": 1, "item.repair_gel": 1, "item.resistance_vial_t1": 1},
				{},
				{"fluid.basic_solvent": 2.0}
			)
		"baseline.s17_frontline_action_report_ready":
			_set_runtime_position(world_state, character_state, "region.outpost_platform", BASELINE_FRONTLINE_ACTION_CONSOLE_POSITION)
			world_state.add_deployed_phase_relay_anchor("map_object_instance.phase_return_anchor_chamber")
			world_state.set_active_phase_relay_anchor("map_object_instance.phase_return_anchor_tether")
			character_state.equipment["suit_module"] = "equipment.filter_module_t1"
			character_state.inventory = _make_inventory(
				{"item.basic_parts": 8, "item.frontline_action_report": 1, "item.repair_gel": 2, "item.resistance_vial_t1": 2},
				{},
				{"fluid.basic_solvent": 2.0}
			)
		"baseline.s18_short_action_feedback_ready":
			_set_runtime_position(world_state, character_state, "region.outpost_platform", BASELINE_FRONTLINE_ACTION_CONSOLE_POSITION)
			world_state.add_deployed_phase_relay_anchor("map_object_instance.phase_return_anchor_chamber")
			world_state.set_active_phase_relay_anchor("map_object_instance.phase_return_anchor_tether")
			character_state.equipment["suit_module"] = "equipment.filter_module_t1"
			character_state.inventory = _make_inventory(
				{
					"item.basic_parts": 12,
					"item.frontline_action_report": 1,
					"item.short_action_feedback": 1,
					"item.repair_gel": 3,
					"item.resistance_vial_t1": 3
				},
				{},
				{"fluid.basic_solvent": 2.0}
			)
		"baseline.s19_route_action_feedback_ready":
			_set_runtime_position(world_state, character_state, "region.outpost_platform", BASELINE_FRONTLINE_ACTION_CONSOLE_POSITION)
			world_state.add_deployed_phase_relay_anchor("map_object_instance.phase_return_anchor_chamber")
			world_state.set_active_phase_relay_anchor("map_object_instance.phase_return_anchor_tether")
			character_state.equipment["suit_module"] = "equipment.filter_module_t1"
			character_state.inventory = _make_inventory(
				{
					"item.basic_parts": 14,
					"item.frontline_action_report": 1,
					"item.short_action_feedback": 1,
					"item.route_action_feedback": 1,
					"item.repair_gel": 4,
					"item.resistance_vial_t1": 4
				},
				{},
				{"fluid.basic_solvent": 2.0}
			)
		"baseline.s20_phase_survey_feedback_ready":
			_set_runtime_position(world_state, character_state, "region.outpost_platform", BASELINE_FRONTLINE_ACTION_CONSOLE_POSITION)
			world_state.add_deployed_phase_relay_anchor("map_object_instance.phase_return_anchor_chamber")
			world_state.set_active_phase_relay_anchor("map_object_instance.phase_return_anchor_tether")
			character_state.equipment["suit_module"] = "equipment.filter_module_t1"
			character_state.inventory = _make_inventory(
				{
					"item.basic_parts": 16,
					"item.frontline_action_report": 1,
					"item.short_action_feedback": 1,
					"item.route_action_feedback": 1,
					"item.phase_survey_feedback": 1,
					"item.repair_gel": 4,
					"item.resistance_vial_t1": 5
				},
				{},
				{"fluid.basic_solvent": 2.0}
			)


func _mark_objects_gathered(
	world_state: WorldState,
	instance_ids: Array[String],
	definition_id: String,
	region_id: String
) -> void:
	for instance_id in instance_ids:
		_mark_object_gathered(world_state, instance_id, definition_id, region_id)


func _mark_objects_cleared(
	world_state: WorldState,
	instance_ids: Array[String],
	definition_id: String,
	region_id: String
) -> void:
	for instance_id in instance_ids:
		_mark_object_cleared(world_state, instance_id, definition_id, region_id)


func _mark_object_gathered(world_state: WorldState, instance_id: String, definition_id: String, region_id: String) -> void:
	var object_state := world_state.ensure_map_object(instance_id, definition_id, region_id)
	object_state["is_gathered"] = true


func _mark_object_sampled(world_state: WorldState, instance_id: String, definition_id: String, region_id: String) -> void:
	var object_state := world_state.ensure_map_object(instance_id, definition_id, region_id)
	object_state["is_sampled"] = true


func _mark_object_cleared(world_state: WorldState, instance_id: String, definition_id: String, region_id: String) -> void:
	var object_state := world_state.ensure_map_object(instance_id, definition_id, region_id)
	object_state["is_cleared"] = true


func _mark_structure_built(
	world_state: WorldState,
	structure_id: String,
	definition_id: String,
	region_id: String,
	site_instance_id: String
) -> void:
	var object_state := world_state.ensure_map_object(site_instance_id, definition_id, region_id)
	object_state["is_built"] = true
	object_state["built_definition_id"] = definition_id
	world_state.add_base_structure(structure_id, definition_id, region_id, site_instance_id)


func _mark_structure_completed(world_state: WorldState, structure_id: String, recipe_id: String) -> void:
	if not world_state.base_structures.has(structure_id):
		return
	world_state.base_structures[structure_id]["status"] = "completed"
	world_state.base_structures[structure_id]["last_recipe_id"] = recipe_id
	world_state.base_structures[structure_id]["completed_runs"] = int(world_state.base_structures[structure_id].get("completed_runs", 0)) + 1
	world_state.base_structures[structure_id].erase("active_recipe_id")
	world_state.base_structures[structure_id].erase("progress_seconds")


func _mark_enemy_defeated(world_state: WorldState, instance_id: String, definition_id: String, region_id: String) -> void:
	var max_health := _get_enemy_max_health(definition_id)
	var enemy_state := world_state.ensure_enemy(instance_id, definition_id, region_id, max_health)
	enemy_state["health"] = 0.0
	enemy_state["max_health"] = max_health
	enemy_state["is_defeated"] = true
	enemy_state["drops_granted"] = true


func _get_enemy_max_health(definition_id: String) -> float:
	var enemy_definition := data_registry.get_definition(definition_id)
	if enemy_definition.is_empty():
		return 1.0
	return float(enemy_definition.get("base_stats", {}).get("max_health", 1.0))


func _make_inventory(items: Dictionary, equipment: Dictionary, fluids: Dictionary) -> InventoryState:
	var inventory := InventoryState.new()
	inventory.items = items.duplicate(true)
	inventory.equipment = equipment.duplicate(true)
	inventory.fluids = fluids.duplicate(true)
	inventory.capacity_slots = 24
	return inventory


func _set_runtime_position(
	world_state: WorldState,
	character_state: CharacterState,
	region_id: String,
	position: Vector2
) -> void:
	world_state.current_region_id = region_id
	character_state.current_region_id = region_id
	character_state.position = position


func _format_loaded_message(definition: Dictionary) -> String:
	return "已载入开发基线 %s：%s 如需长期保留，可直接保存到任一普通槽位。" % [
		String(definition.get("code", "")),
		String(definition.get("summary", ""))
	]


func _success(message: String) -> Dictionary:
	return {
		"success": true,
		"message": message
	}


func _failure(message: String) -> Dictionary:
	return {
		"success": false,
		"message": message
	}
