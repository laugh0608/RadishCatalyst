extends RefCounted
class_name QuestObjectiveSourceResolver

const MAP_OBJECT_SOURCE_PRIORITY := 0
const ENEMY_SOURCE_PRIORITY := 5
const RECIPE_SOURCE_PRIORITY := 10
const QUEST_REWARD_SOURCE_PRIORITY := 20

var data_registry: DataRegistry
var source_hint_candidates: Dictionary = {}


func _init(registry: DataRegistry) -> void:
	data_registry = registry
	_rebuild_source_index()


func resolve_source_hint(objective_type: String, target_id: String) -> String:
	var key := _get_objective_key(objective_type, target_id)
	var candidates: Array = source_hint_candidates.get(key, [])
	if candidates.is_empty():
		return ""

	var best_label := ""
	var best_priority := 1_000_000
	for candidate_entry in candidates:
		if not candidate_entry is Dictionary:
			continue
		var candidate: Dictionary = candidate_entry
		var label := String(candidate.get("label", ""))
		if label.is_empty():
			continue
		var priority := int(candidate.get("priority", QUEST_REWARD_SOURCE_PRIORITY))
		if priority >= best_priority:
			continue
		best_priority = priority
		best_label = label
	return best_label


func _rebuild_source_index() -> void:
	source_hint_candidates.clear()
	if data_registry == null:
		return

	for map_object in data_registry.get_table("map_objects"):
		if not map_object is Dictionary:
			continue
		var map_object_id := String(map_object.get("id", ""))
		var map_object_label := _get_display_name(map_object_id)
		for drop in map_object.get("drops", []):
			if not drop is Dictionary:
				continue
			_add_source_hint_candidate(
				"gather_item",
				String(drop.get("id", "")),
				map_object_label,
				MAP_OBJECT_SOURCE_PRIORITY
			)
		for sample_result_id in map_object.get("sample_result_refs", []):
			_add_source_hint_candidate(
				"gather_item",
				String(sample_result_id),
				map_object_label,
				MAP_OBJECT_SOURCE_PRIORITY
			)

	for enemy in data_registry.get_table("enemies"):
		if not enemy is Dictionary:
			continue
		var enemy_id := String(enemy.get("id", ""))
		var enemy_label := _get_display_name(enemy_id)
		for drop in enemy.get("drops", []):
			if not drop is Dictionary:
				continue
			_add_source_hint_candidate(
				"gather_item",
				String(drop.get("id", "")),
				enemy_label,
				ENEMY_SOURCE_PRIORITY
			)

	for recipe in data_registry.get_table("recipes"):
		if not recipe is Dictionary:
			continue
		var required_building_id := String(recipe.get("required_building_id", ""))
		var source_label := _get_display_name(required_building_id)
		for output in recipe.get("outputs", []):
			if not output is Dictionary:
				continue
			var output_id := String(output.get("id", ""))
			_add_source_hint_candidate(
				"craft_item",
				output_id,
				source_label,
				RECIPE_SOURCE_PRIORITY
			)
			_add_source_hint_candidate(
				"gather_item",
				output_id,
				source_label,
				RECIPE_SOURCE_PRIORITY
			)
		for byproduct in recipe.get("byproducts", []):
			if not byproduct is Dictionary:
				continue
			var byproduct_id := String(byproduct.get("id", ""))
			_add_source_hint_candidate(
				"craft_item",
				byproduct_id,
				source_label,
				RECIPE_SOURCE_PRIORITY
			)
			_add_source_hint_candidate(
				"gather_item",
				byproduct_id,
				source_label,
				RECIPE_SOURCE_PRIORITY
			)

	for quest in data_registry.get_table("quests"):
		if not quest is Dictionary:
			continue
		var quest_id := String(quest.get("id", ""))
		var quest_label := _get_display_name(quest_id)
		for reward in quest.get("rewards", []):
			if not reward is Dictionary:
				continue
			_add_source_hint_candidate(
				"gather_item",
				String(reward.get("id", "")),
				quest_label,
				QUEST_REWARD_SOURCE_PRIORITY
			)


func _add_source_hint_candidate(objective_type: String, target_id: String, label: String, priority: int) -> void:
	if objective_type.is_empty() or target_id.is_empty() or label.is_empty():
		return

	var key := _get_objective_key(objective_type, target_id)
	if not source_hint_candidates.has(key):
		source_hint_candidates[key] = []

	var candidates: Array = source_hint_candidates[key]
	for index in range(candidates.size()):
		var existing_candidate_entry = candidates[index]
		if not existing_candidate_entry is Dictionary:
			continue
		var existing_candidate: Dictionary = existing_candidate_entry
		if String(existing_candidate.get("label", "")) != label:
			continue
		if int(existing_candidate.get("priority", priority)) <= priority:
			return
		candidates[index] = {
			"label": label,
			"priority": priority
		}
		source_hint_candidates[key] = candidates
		return

	candidates.append({
		"label": label,
		"priority": priority
	})
	source_hint_candidates[key] = candidates


func _get_display_name(definition_id: String) -> String:
	if definition_id.is_empty() or data_registry == null:
		return ""
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id
	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))


func _get_objective_key(objective_type: String, target_id: String) -> String:
	return "%s|%s" % [objective_type, target_id]
