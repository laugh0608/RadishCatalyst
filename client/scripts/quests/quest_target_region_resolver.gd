extends RefCounted
class_name QuestTargetRegionResolver

const PRIMARY_SOURCE_PRIORITY := 0
const CRAFT_FALLBACK_PRIORITY := 10

var data_registry: DataRegistry
var objective_region_candidates: Dictionary = {}
var quest_refs_by_region: Dictionary = {}


func _init(registry: DataRegistry) -> void:
	data_registry = registry
	_rebuild_region_quest_refs()


func configure_from_map(map: VerticalSliceMap) -> void:
	objective_region_candidates.clear()
	_rebuild_region_quest_refs()
	if map == null or data_registry == null:
		return

	var interactables_root: Node = map.interactables_root
	if interactables_root == null:
		interactables_root = map.get_node_or_null("Interactables")
	var enemies_root: Node = map.enemies_root
	if enemies_root == null:
		enemies_root = map.get_node_or_null("Enemies")
	if interactables_root == null or enemies_root == null:
		return

	var processor_regions_by_building: Dictionary = {}
	for node in interactables_root.get_children():
		if not node is PrototypeInteractable:
			continue
		var interactable := node as PrototypeInteractable
		var region_id := map._get_region_id_for_position(interactable.position)
		_index_interactable(interactable, region_id, processor_regions_by_building)

	for node in enemies_root.get_children():
		if not node is PrototypeEnemy:
			continue
		var enemy := node as PrototypeEnemy
		var region_id := map._get_region_id_for_position(enemy.position)
		_add_objective_region("defeat_enemy", enemy.definition_id, region_id, PRIMARY_SOURCE_PRIORITY)
		_index_enemy_drop_regions(enemy.definition_id, region_id)

	_index_recipe_regions(processor_regions_by_building)


func resolve_target_region_id(world_state: WorldState, quest_id: String) -> String:
	if data_registry == null or quest_id.is_empty():
		return ""

	var quest := data_registry.get_definition(quest_id)
	if quest.is_empty():
		return ""

	var last_resolved_region_id := ""
	for objective in quest.get("objectives", []):
		if not objective is Dictionary:
			continue
		var objective_region_id := _resolve_objective_region(world_state, quest_id, objective)
		if not objective_region_id.is_empty():
			last_resolved_region_id = objective_region_id
		if not _is_objective_complete(world_state, quest_id, objective):
			return objective_region_id
	return last_resolved_region_id


func _rebuild_region_quest_refs() -> void:
	quest_refs_by_region.clear()
	if data_registry == null:
		return

	for region in data_registry.get_table("regions"):
		if not region is Dictionary:
			continue
		var region_id := String(region.get("id", ""))
		if region_id.is_empty():
			continue
		var quest_refs: Array[String] = []
		for quest_ref in region.get("quest_refs", []):
			var quest_id := String(quest_ref)
			if quest_id.is_empty():
				continue
			quest_refs.append(quest_id)
		quest_refs_by_region[region_id] = quest_refs


func _index_interactable(
	interactable: PrototypeInteractable,
	region_id: String,
	processor_regions_by_building: Dictionary
) -> void:
	match interactable.interaction_type:
		"outpost_core":
			_add_objective_region("interact", interactable.definition_id, region_id, PRIMARY_SOURCE_PRIORITY)
		"sample":
			_add_objective_region("sample_object", interactable.definition_id, region_id, PRIMARY_SOURCE_PRIORITY)
			_index_map_object_drop_regions(interactable.definition_id, region_id)
		"inspect":
			_add_objective_region("inspect", interactable.definition_id, region_id, PRIMARY_SOURCE_PRIORITY)
		"clear":
			_add_objective_region("clear", interactable.definition_id, region_id, PRIMARY_SOURCE_PRIORITY)
		"build":
			_add_objective_region("build", interactable.definition_id, region_id, PRIMARY_SOURCE_PRIORITY)
		"gather":
			_index_map_object_drop_regions(interactable.definition_id, region_id)
		"process_recipe":
			_add_processor_region(processor_regions_by_building, interactable.definition_id, region_id)


func _index_map_object_drop_regions(definition_id: String, region_id: String) -> void:
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return

	for drop in definition.get("drops", []):
		if not drop is Dictionary:
			continue
		_add_objective_region(
			"gather_item",
			String(drop.get("id", "")),
			region_id,
			PRIMARY_SOURCE_PRIORITY
		)

	for sample_result_id in definition.get("sample_result_refs", []):
		_add_objective_region(
			"gather_item",
			String(sample_result_id),
			region_id,
			PRIMARY_SOURCE_PRIORITY
		)


func _index_enemy_drop_regions(definition_id: String, region_id: String) -> void:
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return

	for drop in definition.get("drops", []):
		if not drop is Dictionary:
			continue
		_add_objective_region(
			"gather_item",
			String(drop.get("id", "")),
			region_id,
			PRIMARY_SOURCE_PRIORITY
		)


func _index_recipe_regions(processor_regions_by_building: Dictionary) -> void:
	for recipe in data_registry.get_table("recipes"):
		if not recipe is Dictionary:
			continue
		var required_building_id := String(recipe.get("required_building_id", ""))
		var processor_regions: Array[String] = []
		for region_entry in processor_regions_by_building.get(required_building_id, []):
			processor_regions.append(String(region_entry))
		if processor_regions.is_empty():
			continue

		for output in recipe.get("outputs", []):
			if not output is Dictionary:
				continue
			var output_id := String(output.get("id", ""))
			for region_id in processor_regions:
				_add_objective_region("craft_item", output_id, region_id, PRIMARY_SOURCE_PRIORITY)
				_add_objective_region("gather_item", output_id, region_id, CRAFT_FALLBACK_PRIORITY)

		for byproduct in recipe.get("byproducts", []):
			if not byproduct is Dictionary:
				continue
			var byproduct_id := String(byproduct.get("id", ""))
			for region_id in processor_regions:
				_add_objective_region("craft_item", byproduct_id, region_id, PRIMARY_SOURCE_PRIORITY)
				_add_objective_region("gather_item", byproduct_id, region_id, CRAFT_FALLBACK_PRIORITY)


func _add_processor_region(processor_regions_by_building: Dictionary, building_id: String, region_id: String) -> void:
	if building_id.is_empty() or region_id.is_empty():
		return
	if not processor_regions_by_building.has(building_id):
		processor_regions_by_building[building_id] = []
	var regions: Array[String] = []
	for region_entry in processor_regions_by_building[building_id]:
		regions.append(String(region_entry))
	if not regions.has(region_id):
		regions.append(region_id)
	processor_regions_by_building[building_id] = regions


func _add_objective_region(objective_type: String, target_id: String, region_id: String, priority: int) -> void:
	if objective_type.is_empty() or target_id.is_empty() or region_id.is_empty():
		return

	var key := _get_objective_key(objective_type, target_id)
	if not objective_region_candidates.has(key):
		objective_region_candidates[key] = []

	var candidates: Array = objective_region_candidates[key]
	for index in range(candidates.size()):
		var candidate: Dictionary = candidates[index]
		if String(candidate.get("region_id", "")) != region_id:
			continue
		if int(candidate.get("priority", priority)) <= priority:
			return
		candidates[index] = {
			"region_id": region_id,
			"priority": priority
		}
		objective_region_candidates[key] = candidates
		return

	candidates.append({
		"region_id": region_id,
		"priority": priority
	})
	objective_region_candidates[key] = candidates


func _resolve_objective_region(world_state: WorldState, quest_id: String, objective: Dictionary) -> String:
	var objective_type := String(objective.get("type", ""))
	var target_id := String(objective.get("target_id", ""))
	if target_id.is_empty():
		return ""

	if objective_type == "visit_region" or objective_type == "return_region":
		return target_id

	var key := _get_objective_key(objective_type, target_id)
	var candidates: Array = objective_region_candidates.get(key, [])
	if candidates.is_empty():
		return ""
	return _pick_best_region_id(world_state, quest_id, candidates)


func _pick_best_region_id(world_state: WorldState, quest_id: String, candidates: Array) -> String:
	var best_region_id := ""
	var best_score := 1_000_000
	for candidate_entry in candidates:
		if not candidate_entry is Dictionary:
			continue
		var candidate: Dictionary = candidate_entry
		var region_id := String(candidate.get("region_id", ""))
		if region_id.is_empty():
			continue
		var score := int(candidate.get("priority", CRAFT_FALLBACK_PRIORITY)) * 100
		if not _region_has_quest_ref(region_id, quest_id):
			score += 10
		if not world_state.unlocked_region_ids.has(region_id):
			score += 2
		if world_state.current_region_id == region_id:
			score -= 1
		if score < best_score:
			best_score = score
			best_region_id = region_id
	return best_region_id


func _region_has_quest_ref(region_id: String, quest_id: String) -> bool:
	var quest_refs: Array[String] = []
	for quest_ref_entry in quest_refs_by_region.get(region_id, []):
		quest_refs.append(String(quest_ref_entry))
	return quest_refs.has(quest_id)


func _is_objective_complete(world_state: WorldState, quest_id: String, objective: Dictionary) -> bool:
	var objective_type := String(objective.get("type", ""))
	var target_id := String(objective.get("target_id", ""))
	var required_amount := float(objective.get("amount", 1.0))
	return world_state.quest_state.get_objective_progress(quest_id, objective_type, target_id) >= required_amount


func _get_objective_key(objective_type: String, target_id: String) -> String:
	return "%s|%s" % [objective_type, target_id]
