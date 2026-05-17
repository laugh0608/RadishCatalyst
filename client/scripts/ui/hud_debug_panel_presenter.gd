extends RefCounted
class_name HudDebugPanelPresenter


func update_save_slot_summaries(
	summaries: Array[Dictionary],
	save_slot_labels: Array[Label],
	load_slot_buttons: Array[Button],
	save_slot_ids: Array[String]
) -> void:
	for index in range(save_slot_labels.size()):
		if index >= summaries.size():
			continue

		var summary := summaries[index]
		var slot_id := save_slot_ids[index]
		var label_text := "%s：%s\n%s" % [
			String(summary.get("display_name", slot_id)),
			String(summary.get("status", "未知")),
			_format_save_slot_details(summary)
		]
		save_slot_labels[index].text = label_text
		load_slot_buttons[index].disabled = not bool(summary.get("has_loadable_save", false))


func update_quick_slot_binding_panel(
	data_registry: DataRegistry,
	character_state: CharacterState,
	quick_slot_binding_labels: Array[Label]
) -> Array[String]:
	var quick_slots := character_state.quick_slots.duplicate()
	for slot_index in range(quick_slot_binding_labels.size()):
		var item_id := ""
		if slot_index < character_state.quick_slots.size():
			item_id = character_state.quick_slots[slot_index]
		quick_slot_binding_labels[slot_index].text = "%d：%s" % [
			slot_index + 1,
			_format_quick_slot_binding(data_registry, character_state, item_id)
		]
	return quick_slots


func get_next_quick_slot_candidate(current_item_id: String, candidates: Array[String]) -> String:
	return get_next_candidate(current_item_id, candidates)


func get_next_candidate(current_item_id: String, candidates: Array[String]) -> String:
	if candidates.is_empty():
		return ""
	var current_index := candidates.find(current_item_id)
	if current_index < 0:
		return candidates[0]
	return candidates[(current_index + 1) % candidates.size()]


func get_previous_candidate(current_item_id: String, candidates: Array[String]) -> String:
	if candidates.is_empty():
		return ""
	var current_index := candidates.find(current_item_id)
	if current_index < 0:
		return candidates[0]
	return candidates[posmod(current_index - 1, candidates.size())]


func format_gm_resource_text(
	data_registry: DataRegistry,
	character_state: CharacterState,
	definition_id: String
) -> String:
	if definition_id.is_empty():
		return "资源：未选择"
	return "资源：%s\nID：%s\n当前：%s" % [
		_get_display_name(data_registry, definition_id),
		definition_id,
		_format_inventory_amount(character_state, definition_id)
	]


func format_gm_vitals_text(character_state: CharacterState) -> String:
	return "状态：生命 %s / %s；防护 %s / %s" % [
		_format_amount(character_state.health),
		_format_amount(character_state.max_health),
		_format_amount(character_state.protection),
		_format_amount(character_state.max_protection)
	]


func _format_save_slot_details(summary: Dictionary) -> String:
	var status := String(summary.get("status", ""))
	var details := String(summary.get("details", ""))
	if status == "存档不可读取":
		return "存档损坏或内容已过期；可覆盖保存。"
	if bool(summary.get("has_loadable_save", false)):
		return _format_loadable_slot_details(details)
	if details.length() > 28:
		return "%s..." % details.substr(0, 28)
	return details


func _format_loadable_slot_details(details: String) -> String:
	var parts := details.split("；", false)
	var saved_at := ""
	var region := ""
	for part in parts:
		var text := String(part)
		if text.begins_with("最近保存："):
			saved_at = text.trim_prefix("最近保存：")
		if text.begins_with("区域："):
			region = text.trim_prefix("区域：")
	if saved_at.length() >= 16:
		saved_at = "%s %s" % [saved_at.substr(5, 5), saved_at.substr(11, 5)]
	if not saved_at.is_empty() and not region.is_empty():
		return "最近：%s；区域：%s" % [saved_at, region]
	if not saved_at.is_empty():
		return "最近：%s" % saved_at
	if details.length() > 28:
		return "%s..." % details.substr(0, 28)
	return details


func _format_quick_slot_binding(data_registry: DataRegistry, character_state: CharacterState, item_id: String) -> String:
	if item_id.is_empty():
		return "空"
	return "%s x%s" % [
		_get_display_name(data_registry, item_id),
		int(character_state.inventory.items.get(item_id, 0))
	]


func _format_inventory_amount(character_state: CharacterState, definition_id: String) -> String:
	if definition_id.begins_with("fluid."):
		return "x%s" % _format_amount(float(character_state.inventory.fluids.get(definition_id, 0.0)))
	if definition_id.begins_with("equipment."):
		return "x%d" % int(character_state.inventory.equipment.get(definition_id, 0))
	return "x%d" % int(character_state.inventory.items.get(definition_id, 0))


func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount


func _get_display_name(data_registry: DataRegistry, definition_id: String) -> String:
	if definition_id.is_empty():
		return ""
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id
	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))
