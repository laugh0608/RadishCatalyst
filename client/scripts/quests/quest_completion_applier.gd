extends RefCounted
class_name QuestCompletionApplier

var data_registry: DataRegistry


func _init(registry: DataRegistry) -> void:
	data_registry = registry


func apply_completion(world_state: WorldState, character_state: CharacterState, completion_result: Dictionary) -> Dictionary:
	if not bool(completion_result.get("completed", false)):
		return {}

	var quest_id := String(completion_result.get("quest_id", ""))
	var reward_refs: Array = completion_result.get("rewards", [])
	var reward_messages := _grant_refs(character_state, reward_refs)
	var unlock_effects: Array = completion_result.get("unlock_effects", [])
	for effect_id in unlock_effects:
		_apply_world_unlock_effect(world_state, String(effect_id))

	var next_quest_ids: Array = completion_result.get("next_quest_ids", [])
	var next_quest_names := _format_next_quest_names(next_quest_ids)
	var unlock_messages := _format_unlock_effects(unlock_effects)
	var note_text := _format_completion_note(quest_id)
	var title := "任务完成：%s" % _get_display_name(quest_id)
	var reward_text := "奖励：无直接物资"
	if not reward_messages.is_empty():
		reward_text = "奖励：%s" % ", ".join(reward_messages)

	var unlock_text := ""
	if not unlock_messages.is_empty():
		unlock_text = "解锁：%s" % ", ".join(unlock_messages)

	var next_goal_text := ""
	if not next_quest_names.is_empty():
		next_goal_text = "新目标：%s" % ", ".join(next_quest_names)

	return {
		"quest_id": quest_id,
		"title": title,
		"reward_text": reward_text,
		"unlock_text": unlock_text,
		"note_text": note_text,
		"next_goal_text": next_goal_text,
		"log_message": _format_log_message(title, reward_text, unlock_text, note_text, next_goal_text)
	}


func _grant_refs(character_state: CharacterState, refs: Array) -> Array[String]:
	var reward_messages: Array[String] = []
	for ref in refs:
		if not ref is Dictionary:
			continue

		var definition_id := String(ref.get("id", ""))
		var amount := float(ref.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0:
			continue

		character_state.inventory.add_ref(definition_id, amount)
		reward_messages.append("%s x%s" % [_get_display_name(definition_id), _format_amount(amount)])
	return reward_messages


func _apply_world_unlock_effect(world_state: WorldState, effect_id: String) -> void:
	if effect_id.begins_with("region."):
		world_state.unlock_region(effect_id)


func _format_next_quest_names(next_quest_ids: Array) -> Array[String]:
	var next_quest_names: Array[String] = []
	for next_quest_id in next_quest_ids:
		next_quest_names.append(_get_display_name(String(next_quest_id)))
	return next_quest_names


func _format_unlock_effects(unlock_effects: Array) -> Array[String]:
	var unlock_messages: Array[String] = []
	for effect_id in unlock_effects:
		var id := String(effect_id)
		if id.begins_with("quest."):
			continue
		if id == "slice_01_complete":
			unlock_messages.append("第一切片完成标记")
			continue
		if id.begins_with("region.") or id.begins_with("recipe.") or id.begins_with("building.") or id.begins_with("equipment.") or id.begins_with("item."):
			unlock_messages.append(_get_display_name(id))
			continue
		unlock_messages.append(id)
	return unlock_messages


func _format_completion_note(quest_id: String) -> String:
	match quest_id:
		"quest.enter_pollution_edge":
			return "污染深处 / 遗迹入口信号已标记"
		"quest.unlock_ruin_signal":
			return "切片结尾：更深区域信号已确认，后续内容待开放"
		_:
			return ""


func _format_log_message(
	title: String,
	reward_text: String,
	unlock_text: String,
	note_text: String,
	next_goal_text: String
) -> String:
	var parts: Array[String] = [title + "。", reward_text + "。"]
	if not unlock_text.is_empty():
		parts.append(unlock_text + "。")
	if not note_text.is_empty():
		parts.append(note_text + "。")
	if not next_goal_text.is_empty():
		parts.append(next_goal_text + "。")
	return " ".join(parts)


func _get_display_name(definition_id: String) -> String:
	if definition_id.is_empty():
		return ""

	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id

	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))


func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount
