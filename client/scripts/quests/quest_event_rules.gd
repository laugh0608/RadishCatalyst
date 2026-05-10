extends RefCounted
class_name QuestEventRules

var data_registry: DataRegistry


func _init(registry: DataRegistry) -> void:
	data_registry = registry


func get_interaction_objective_updates(context: Dictionary, result: Dictionary, _quest_state: QuestState) -> Array[Dictionary]:
	var definition_id := String(context.get("definition_id", ""))
	var interaction_type := String(context.get("interaction_type", ""))
	var recipe_id := String(context.get("recipe_id", ""))

	if interaction_type == "outpost_core":
		return [_set_update("quest.restore_outpost", "interact", "building.outpost_core", 1)]
	if interaction_type == "gather" and definition_id == "map_object.crystal_cluster":
		var updates: Array[Dictionary] = [
			_set_update("quest.scout_crystal_field", "visit_region", "region.crystal_vein_field", 1)
		]
		updates.append_array(_get_drop_objective_updates("quest.scout_crystal_field", "gather_item", "item.crystal_ore", definition_id))
		return updates
	if interaction_type == "gather" and definition_id == "map_object.field_wreckage":
		return _get_drop_objective_updates("quest.calibrate_reactor", "gather_item", "item.salvage_scrap", definition_id)
	if interaction_type == "sample" and definition_id == "map_object.anomaly_crystal":
		return [_set_update("quest.bring_back_sample", "sample_object", "map_object.anomaly_crystal", 1)]
	if interaction_type == "gather" and definition_id == "map_object.anomaly_residue_patch":
		return _get_drop_objective_updates("quest.analyze_anomaly_sample", "gather_item", "item.anomaly_residue", definition_id)
	if interaction_type == "gather" and definition_id == "map_object.pollution_residue_patch":
		var updates: Array[Dictionary] = [
			_set_update("quest.enter_pollution_edge", "visit_region", "region.pollution_edge", 1)
		]
		updates.append_array(_get_drop_objective_updates("quest.enter_pollution_edge", "gather_item", "item.polluted_residue", definition_id))
		return updates
	if interaction_type == "inspect" and definition_id == "map_object.ruin_gate":
		return [_set_update("quest.unlock_ruin_signal", "inspect", "map_object.ruin_gate", 1)]
	if interaction_type == "gather" and definition_id == "map_object.relay_shard_cache":
		var updates: Array[Dictionary] = [
			_set_update("quest.scout_ruin_outer_ring", "visit_region", "region.ruin_outer_ring", 1)
		]
		updates.append_array(_get_drop_objective_updates("quest.scout_ruin_outer_ring", "gather_item", "item.relay_shard", definition_id))
		return updates
	if interaction_type == "inspect" and definition_id == "map_object.outer_ring_barrier":
		return [_set_update("quest.stabilize_outer_ring_barrier", "inspect", "map_object.outer_ring_barrier", 1)]
	if interaction_type == "inspect" and definition_id == "map_object.outer_ring_console":
		return [_set_update("quest.secure_outer_ring_signal", "inspect", "map_object.outer_ring_console", 1)]
	if interaction_type == "inspect" and definition_id == "map_object.signal_echo_cache":
		return [_set_update("quest.salvage_signal_echo", "inspect", "map_object.signal_echo_cache", 1)]
	if interaction_type == "inspect" and definition_id == "map_object.deep_ruin_door":
		return [_set_update("quest.unlock_deep_ruin_entrance", "inspect", "map_object.deep_ruin_door", 1)]
	if interaction_type == "gather" and definition_id == "map_object.phase_filament_cluster":
		var updates: Array[Dictionary] = [
			_set_update("quest.harvest_phase_filament", "visit_region", "region.deep_ruin_threshold", 1)
		]
		updates.append_array(_get_drop_objective_updates("quest.harvest_phase_filament", "gather_item", "item.phase_filament", definition_id))
		return updates
	if interaction_type == "inspect" and definition_id == "map_object.deep_ruin_latch":
		return [_set_update("quest.unlock_deep_ruin_cache", "inspect", "map_object.deep_ruin_latch", 1)]
	if interaction_type == "inspect" and definition_id == "map_object.deep_signal_array":
		return [_set_update("quest.activate_deep_array", "inspect", "map_object.deep_signal_array", 1)]
	if interaction_type == "inspect" and definition_id == "map_object.phase_return_anchor":
		return [_set_update("quest.deploy_phase_relay_anchor", "inspect", "map_object.phase_return_anchor", 1)]
	if interaction_type == "inspect" and definition_id == "map_object.phase_relay_pad":
		return [_set_update("quest.reenter_phase_frontline", "inspect", "map_object.phase_relay_pad", 1)]
	if interaction_type == "gather" and definition_id == "map_object.phase_conduit_cluster":
		return _get_drop_objective_updates("quest.activate_deep_array", "gather_item", "item.phase_conduit", definition_id)
	if interaction_type == "gather" and definition_id == "map_object.phase_splinter_cluster":
		var updates: Array[Dictionary] = [
			_set_update("quest.trace_phase_splinters", "visit_region", "region.deep_ruin_threshold", 1)
		]
		updates.append_array(_get_drop_objective_updates("quest.trace_phase_splinters", "gather_item", "item.phase_splinter", definition_id))
		return updates
	if interaction_type == "inspect" and definition_id == "map_object.phase_fault_spire":
		return [_set_update("quest.inspect_phase_fault_spire", "inspect", "map_object.phase_fault_spire", 1)]
	if interaction_type == "gather" and definition_id == "map_object.fault_residue_cluster":
		var updates: Array[Dictionary] = [
			_set_update("quest.collect_fault_residue", "visit_region", "region.deep_ruin_threshold", 1)
		]
		updates.append_array(_get_drop_objective_updates("quest.collect_fault_residue", "gather_item", "item.fault_residue", definition_id))
		return updates
	if interaction_type == "inspect" and definition_id == "map_object.phase_well_lock":
		return [_set_update("quest.unlock_phase_well", "inspect", "map_object.phase_well_lock", 1)]
	if interaction_type == "gather" and definition_id == "map_object.well_flux_cluster":
		var updates: Array[Dictionary] = [
			_set_update("quest.collect_well_flux", "visit_region", "region.inner_phase_well", 1)
		]
		updates.append_array(_get_drop_objective_updates("quest.collect_well_flux", "gather_item", "item.well_flux_shard", definition_id))
		return updates
	if interaction_type == "inspect" and definition_id == "map_object.inner_phase_well":
		return [_set_update("quest.inspect_inner_phase_well", "inspect", "map_object.inner_phase_well", 1)]
	if interaction_type == "gather" and definition_id == "map_object.well_ash_cluster":
		var sink_updates: Array[Dictionary] = [
			_set_update("quest.collect_well_ash", "visit_region", "region.phase_well_sink", 1)
		]
		sink_updates.append_array(_get_drop_objective_updates("quest.collect_well_ash", "gather_item", "item.well_ash", definition_id))
		return sink_updates
	if interaction_type == "inspect" and definition_id == "map_object.phase_well_sink":
		return [_set_update("quest.inspect_phase_well_sink", "inspect", "map_object.phase_well_sink", 1)]
	if interaction_type == "process_recipe":
		return get_recipe_objective_updates(recipe_id)
	if interaction_type == "build":
		return get_build_objective_updates(String(result.get("built_definition_id", definition_id)))
	return []


func get_region_objective_updates(region_id: String, _quest_state: QuestState) -> Array[Dictionary]:
	if region_id == "region.crystal_vein_field":
		return [_set_update("quest.scout_crystal_field", "visit_region", region_id, 1)]
	if region_id == "region.pollution_edge":
		return [_set_update("quest.enter_pollution_edge", "visit_region", region_id, 1)]
	if region_id == "region.ruin_outer_ring":
		return [_set_update("quest.scout_ruin_outer_ring", "visit_region", region_id, 1)]
	if region_id == "region.deep_ruin_threshold":
		return [
			_set_update("quest.harvest_phase_filament", "visit_region", region_id, 1),
			_set_update("quest.trace_phase_splinters", "visit_region", region_id, 1),
			_set_update("quest.collect_fault_residue", "visit_region", region_id, 1)
		]
	if region_id == "region.inner_phase_well":
		return [
			_set_update("quest.collect_well_flux", "visit_region", region_id, 1)
		]
	if region_id == "region.phase_well_sink":
		return [
			_set_update("quest.collect_well_ash", "visit_region", region_id, 1)
		]
	return []


func get_recipe_objective_updates(recipe_id: String) -> Array[Dictionary]:
	match recipe_id:
		"recipe.reactor_calibrator":
			return [_set_update("quest.calibrate_reactor", "craft_item", "item.reactor_calibrator", 1)]
		"recipe.analyze_anomaly_sample":
			return [_set_update("quest.analyze_anomaly_sample", "craft_item", "item.sample_analysis", 1)]
		"recipe.repair_gel":
			return [_set_update("quest.prepare_treatment_supplies", "craft_item", "item.repair_gel", 1)]
		"recipe.basic_filter_module":
			return [_set_update("quest.make_filter_module", "craft_item", "equipment.filter_module_t1", 1)]
		"recipe.cleanse_residue":
			return [_set_update("quest.enter_pollution_edge", "craft_item", "item.resistance_vial_t1", 1)]
		"recipe.phase_anchor":
			return [_set_update("quest.assemble_phase_anchor", "craft_item", "item.phase_anchor", 1)]
		"recipe.deep_signal_analysis":
			return [_set_update("quest.analyze_deep_signal", "craft_item", "item.deep_ruin_coordinates", 1)]
		"recipe.phase_filament_refining":
			return [_set_update("quest.refine_phase_filament", "craft_item", "item.resonance_filter", 1)]
		"recipe.deep_override_key":
			return [_set_update("quest.assemble_deep_override", "craft_item", "item.deep_override_key", 1)]
		"recipe.deep_core_imprint":
			return [_set_update("quest.analyze_deep_core", "craft_item", "item.deep_route_imprint", 1)]
		"recipe.deep_signal_matrix":
			return [_set_update("quest.assemble_deep_signal_matrix", "craft_item", "item.deep_signal_matrix", 1)]
		"recipe.phase_splinter_refining":
			return [_set_update("quest.refine_phase_splinters", "craft_item", "item.phase_lens_blank", 1)]
		"recipe.relay_tuning_lens":
			return [_set_update("quest.tune_relay_lens", "craft_item", "item.relay_tuning_lens", 1)]
		"recipe.inner_fault_analysis":
			return [_set_update("quest.analyze_inner_fault_trace", "craft_item", "item.phase_well_coordinate", 1)]
		"recipe.fault_residue_stabilization":
			return [_set_update("quest.refine_fault_residue", "craft_item", "item.stabilized_fault_core", 1)]
		"recipe.phase_well_key":
			return [_set_update("quest.assemble_phase_well_key", "craft_item", "item.phase_well_key", 1)]
		"recipe.phase_well_locator_analysis":
			return [_set_update("quest.analyze_phase_well_locator", "craft_item", "item.phase_well_route", 1)]
		"recipe.well_flux_stabilization":
			return [_set_update("quest.refine_well_flux", "craft_item", "item.phase_well_stabilizer", 1)]
		"recipe.phase_well_probe":
			return [_set_update("quest.assemble_phase_well_probe", "craft_item", "item.phase_well_probe", 1)]
		"recipe.phase_well_core_analysis":
			return [_set_update("quest.analyze_phase_well_core", "craft_item", "item.phase_well_spectrum", 1)]
		"recipe.well_ash_stabilization":
			return [_set_update("quest.refine_well_ash", "craft_item", "item.phase_well_lattice", 1)]
		"recipe.phase_well_pike":
			return [_set_update("quest.assemble_phase_well_pike", "craft_item", "item.phase_well_pike", 1)]
		_:
			return []


func get_build_objective_updates(building_id: String) -> Array[Dictionary]:
	if building_id == "building.foundation_t1":
		return [_add_update("quest.expand_treatment_point", "build", building_id, 1)]
	if building_id == "building.pollution_filter":
		return [_set_update("quest.expand_treatment_point", "build", building_id, 1)]
	return []


func get_defeated_enemy_objective_updates(enemy_definition_id: String) -> Array[Dictionary]:
	if enemy_definition_id == "enemy.treatment_skitter":
		return [_set_update("quest.prepare_treatment_supplies", "defeat_enemy", enemy_definition_id, 1)]
	if enemy_definition_id == "enemy.polluted_skitter":
		return [_set_update("quest.enter_pollution_edge", "defeat_enemy", enemy_definition_id, 1)]
	if enemy_definition_id == "enemy.elite_residue_node":
		return [_set_update("quest.defeat_elite_node", "defeat_enemy", enemy_definition_id, 1)]
	if enemy_definition_id == "enemy.ruin_phase_guard":
		return [_set_update("quest.salvage_signal_echo", "defeat_enemy", enemy_definition_id, 1)]
	if enemy_definition_id == "enemy.deep_ruin_sentinel":
		return [_set_update("quest.harvest_phase_filament", "defeat_enemy", enemy_definition_id, 1)]
	if enemy_definition_id == "enemy.deep_ruin_stalker":
		return [_set_update("quest.activate_deep_array", "defeat_enemy", enemy_definition_id, 1)]
	if enemy_definition_id == "enemy.deep_fault_hunter":
		return [_set_update("quest.trace_phase_splinters", "defeat_enemy", enemy_definition_id, 1)]
	if enemy_definition_id == "enemy.inner_fault_stalker":
		return [_set_update("quest.collect_fault_residue", "defeat_enemy", enemy_definition_id, 1)]
	if enemy_definition_id == "enemy.phase_well_sentry":
		return [_set_update("quest.collect_well_flux", "defeat_enemy", enemy_definition_id, 1)]
	if enemy_definition_id == "enemy.phase_well_lurker":
		return [_set_update("quest.collect_well_ash", "defeat_enemy", enemy_definition_id, 1)]
	return []


func get_pollution_edge_ready_updates(quest_state: QuestState) -> Array[Dictionary]:
	if not quest_state.has_active_quest("quest.enter_pollution_edge"):
		return []
	return [_set_update("quest.enter_pollution_edge", "visit_region", "region.pollution_edge", 1)]


func _get_drop_objective_updates(quest_id: String, objective_type: String, target_id: String, source_definition_id: String) -> Array[Dictionary]:
	var source_definition := data_registry.get_definition(source_definition_id)
	for drop in source_definition.get("drops", []):
		if not (drop is Dictionary):
			continue
		if String(drop.get("id", "")) != target_id:
			continue
		return [_add_update(quest_id, objective_type, target_id, float(drop.get("amount", 0.0)))]
	return []


func _set_update(quest_id: String, objective_type: String, target_id: String, amount: float) -> Dictionary:
	return _update("set", quest_id, objective_type, target_id, amount)


func _add_update(quest_id: String, objective_type: String, target_id: String, amount: float) -> Dictionary:
	return _update("add", quest_id, objective_type, target_id, amount)


func _update(mode: String, quest_id: String, objective_type: String, target_id: String, amount: float) -> Dictionary:
	return {
		"mode": mode,
		"quest_id": quest_id,
		"objective_type": objective_type,
		"target_id": target_id,
		"amount": amount
	}
