extends RefCounted
class_name QuestEventRules

var data_registry: DataRegistry


func _init(registry: DataRegistry) -> void:
	data_registry = registry


func get_interaction_objective_updates(context: Dictionary, result: Dictionary, quest_state: QuestState) -> Array[Dictionary]:
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
	if interaction_type == "gather" and definition_id == "map_object.pollution_residue_patch":
		var updates: Array[Dictionary] = [
			_set_update("quest.enter_pollution_edge", "visit_region", "region.pollution_edge", 1)
		]
		updates.append_array(_get_drop_objective_updates("quest.enter_pollution_edge", "gather_item", "item.polluted_residue", definition_id))
		return updates
	if interaction_type == "inspect" and definition_id == "map_object.ruin_gate":
		return [_set_update("quest.unlock_ruin_signal", "inspect", "map_object.ruin_gate", 1)]
	if interaction_type == "process_recipe":
		return get_recipe_objective_updates(recipe_id)
	if interaction_type == "build":
		return get_build_objective_updates(String(result.get("built_definition_id", definition_id)))
	return []


func get_region_objective_updates(region_id: String, quest_state: QuestState) -> Array[Dictionary]:
	if region_id == "region.crystal_vein_field":
		return [_set_update("quest.scout_crystal_field", "visit_region", region_id, 1)]
	if (
		region_id == "region.outpost_platform"
		and quest_state.get_objective_progress("quest.bring_back_sample", "sample_object", "map_object.anomaly_crystal") > 0.0
	):
		return [_set_update("quest.bring_back_sample", "return_region", region_id, 1)]
	if region_id == "region.pollution_edge":
		return [_set_update("quest.enter_pollution_edge", "visit_region", region_id, 1)]
	return []


func get_recipe_objective_updates(recipe_id: String) -> Array[Dictionary]:
	match recipe_id:
		"recipe.reactor_calibrator":
			return [_set_update("quest.calibrate_reactor", "craft_item", "item.reactor_calibrator", 1)]
		"recipe.basic_filter_module":
			return [_set_update("quest.make_filter_module", "craft_item", "equipment.filter_module_t1", 1)]
		"recipe.cleanse_residue":
			return [_set_update("quest.enter_pollution_edge", "craft_item", "item.resistance_vial_t1", 1)]
		_:
			return []


func get_build_objective_updates(building_id: String) -> Array[Dictionary]:
	if building_id == "building.foundation_t1":
		return [_add_update("quest.expand_treatment_point", "build", building_id, 1)]
	if building_id == "building.pollution_filter":
		return [_set_update("quest.expand_treatment_point", "build", building_id, 1)]
	return []


func get_defeated_enemy_objective_updates(enemy_definition_id: String) -> Array[Dictionary]:
	if enemy_definition_id == "enemy.polluted_skitter":
		return [_set_update("quest.enter_pollution_edge", "defeat_enemy", enemy_definition_id, 1)]
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
