extends RefCounted
class_name GatherSystem

var data_registry: DataRegistry


func _init(registry: DataRegistry) -> void:
	data_registry = registry


func interact_with_object(
	instance_id: String,
	definition_id: String,
	interaction_type: String,
	character_state: CharacterState,
	world_state: WorldState
) -> Dictionary:
	if interaction_type == "outpost_core":
		return _interact_with_outpost_core(character_state, world_state)

	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return _failure("未知交互对象：%s" % definition_id)

	var object_state := world_state.ensure_map_object(instance_id, definition_id, character_state.current_region_id)
	if _is_already_processed(object_state, interaction_type):
		return _failure("目标已处理。")

	if not _supports_interaction(definition, interaction_type):
		return _failure("当前目标不支持该交互。")

	match interaction_type:
		"gather":
			return _gather(instance_id, definition, character_state, world_state)
		"sample":
			return _sample(instance_id, definition, character_state, world_state)
		"clear":
			world_state.set_map_object_flag(instance_id, "is_cleared", true)
			return _success("地块已清理。")
		_:
			return _success("交互完成。")


func _interact_with_outpost_core(_character_state: CharacterState, world_state: WorldState) -> Dictionary:
	world_state.quest_state.complete_quest("quest.restore_outpost")
	world_state.quest_state.activate_quest("quest.scout_crystal_field")
	world_state.unlock_region("region.crystal_vein_field")
	return _success("前哨核心已恢复，晶体矿脉区已标记。")


func _gather(instance_id: String, definition: Dictionary, character_state: CharacterState, world_state: WorldState) -> Dictionary:
	var rewards := _grant_refs(definition.get("drops", []), character_state)
	world_state.set_map_object_flag(instance_id, "is_gathered", true)

	if rewards.is_empty():
		return _success("采集完成。")
	return _success("采集完成：%s" % ", ".join(rewards))


func _sample(instance_id: String, definition: Dictionary, character_state: CharacterState, world_state: WorldState) -> Dictionary:
	var sample_refs: Array = definition.get("sample_result_refs", [])
	var rewards: Array[String] = []
	for sample_id in sample_refs:
		character_state.inventory.add_item(String(sample_id), 1)
		rewards.append("%s x1" % sample_id)

	world_state.set_map_object_flag(instance_id, "is_sampled", true)
	if rewards.is_empty():
		return _success("采样完成。")
	return _success("采样完成：%s" % ", ".join(rewards))


func _grant_refs(refs: Array, character_state: CharacterState) -> Array[String]:
	var rewards: Array[String] = []
	for ref in refs:
		if not ref is Dictionary:
			continue

		var reward_id := String(ref.get("id", ""))
		var amount := int(ref.get("amount", 0))
		if reward_id.is_empty() or amount <= 0:
			continue

		if reward_id.begins_with("item."):
			character_state.inventory.add_item(reward_id, amount)
		elif reward_id.begins_with("fluid."):
			character_state.inventory.add_fluid(reward_id, amount)
		else:
			continue

		rewards.append("%s x%d" % [reward_id, amount])
	return rewards


func _supports_interaction(definition: Dictionary, interaction_type: String) -> bool:
	var interaction_types: Array = definition.get("interaction_types", [])
	return interaction_types.has(interaction_type)


func _is_already_processed(object_state: Dictionary, interaction_type: String) -> bool:
	match interaction_type:
		"gather":
			return bool(object_state.get("is_gathered", false))
		"sample":
			return bool(object_state.get("is_sampled", false))
		"clear":
			return bool(object_state.get("is_cleared", false))
		_:
			return false


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
