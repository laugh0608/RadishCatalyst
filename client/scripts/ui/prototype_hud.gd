extends CanvasLayer
class_name PrototypeHud

@onready var status_label: Label = $PanelBackground/StatusLabel
@onready var prompt_label: Label = $PanelBackground/PromptLabel
@onready var log_label: Label = $PanelBackground/LogLabel


func update_status(data_registry: DataRegistry, world_state: WorldState, character_state: CharacterState) -> void:
	var active_quest_id := ""
	if not world_state.quest_state.active_quest_ids.is_empty():
		active_quest_id = world_state.quest_state.active_quest_ids[0]

	status_label.text = "\n".join([
		"RadishCatalyst Prototype",
		"区域：%s" % _get_display_name(data_registry, world_state.current_region_id),
		"目标：%s" % _get_display_name(data_registry, active_quest_id),
		"生命：%.0f / %.0f" % [character_state.health, character_state.max_health],
		"防护：%.0f / %.0f" % [character_state.protection, character_state.max_protection],
		"模块：%s（污染消耗 x%.2f）" % [
			_get_equipped_module_name(data_registry, character_state),
			character_state.get_pollution_drain_multiplier(data_registry)
		],
		"背包：%s" % _format_inventory(data_registry, character_state.inventory)
	])


func show_prompt(text: String) -> void:
	prompt_label.text = text


func clear_prompt() -> void:
	prompt_label.text = ""


func append_log(text: String) -> void:
	log_label.text = text


func _get_display_name(data_registry: DataRegistry, definition_id: String) -> String:
	if definition_id.is_empty():
		return ""
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id
	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))


func _format_inventory(data_registry: DataRegistry, inventory: InventoryState) -> String:
	if inventory.items.is_empty() and inventory.fluids.is_empty():
		return "空"

	var parts: Array[String] = []
	for item_id in inventory.items:
		parts.append("%s x%s" % [_get_display_name(data_registry, item_id), inventory.items[item_id]])
	for fluid_id in inventory.fluids:
		parts.append("%s x%s" % [_get_display_name(data_registry, fluid_id), inventory.fluids[fluid_id]])
	return ", ".join(parts)


func _get_equipped_module_name(data_registry: DataRegistry, character_state: CharacterState) -> String:
	var module_id := String(character_state.equipment.get("suit_module", ""))
	if module_id.is_empty():
		return "未启用"
	return _get_display_name(data_registry, module_id)
