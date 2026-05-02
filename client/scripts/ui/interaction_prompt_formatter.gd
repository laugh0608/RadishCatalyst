extends RefCounted
class_name InteractionPromptFormatter

var data_registry: DataRegistry
var processing_system: ProcessingSystem
var build_system: BuildSystem


func _init(registry: DataRegistry, processing: ProcessingSystem, builder: BuildSystem) -> void:
	data_registry = registry
	processing_system = processing
	build_system = builder


func format_processing_prompt(
	interactable: PrototypeInteractable,
	character_state: CharacterState,
	world_state: WorldState
) -> String:
	var recipe_id := interactable.get_current_recipe_id()
	var status := processing_system.get_recipe_status(recipe_id, character_state, world_state)
	var parts: Array[String] = [
		"设备：%s" % _get_display_name(interactable.definition_id),
		"配方：%s" % _get_display_name(recipe_id)
	]
	if interactable.get_recipe_count() > 1:
		parts[1] = "%s；R 切换（%d/%d）" % [
			parts[1],
			interactable.get_recipe_position(),
			interactable.get_recipe_count()
		]

	parts.append("输入：%s" % String(status.get("inputs", "无")))
	parts.append("产出：%s" % String(status.get("outputs", "无")))
	var byproducts := String(status.get("byproducts", ""))
	if not byproducts.is_empty():
		parts.append("副产：%s" % byproducts)
	parts.append("耗时：%s 秒" % String(status.get("duration", "0")))
	var progress := String(status.get("progress", ""))
	if not progress.is_empty():
		parts.append("进度：%s" % progress)
	var last_completion := String(status.get("last_completion", ""))
	if not last_completion.is_empty():
		parts.append(last_completion)
	var last_destination := String(status.get("last_destination", ""))
	if not last_destination.is_empty():
		parts.append("入库：%s" % last_destination)
	var last_next_step := String(status.get("last_next_step", ""))
	if not last_next_step.is_empty():
		parts.append("下一步：%s" % last_next_step)
	parts.append("状态：%s" % String(status.get("message", "")))
	if bool(status.get("can_process", false)):
		parts.append("按 E 启动加工")
	return "\n".join(parts)


func format_processing_log(recipe_id: String, character_state: CharacterState, world_state: WorldState) -> String:
	var status := processing_system.get_recipe_status(recipe_id, character_state, world_state)
	return "%s：%s 输入：%s；产出：%s；耗时：%s 秒。" % [
		_get_display_name(recipe_id),
		String(status.get("message", "")),
		String(status.get("inputs", "无")),
		String(status.get("outputs", "无")),
		String(status.get("duration", "0"))
	]


func format_build_prompt(
	interactable: PrototypeInteractable,
	character_state: CharacterState,
	world_state: WorldState
) -> String:
	var status := build_system.get_build_status(
		interactable.instance_id,
		interactable.definition_id,
		character_state,
		world_state,
		interactable.prerequisite_instance_id
	)
	var parts: Array[String] = [
		"建造点：%s" % _get_display_name(interactable.definition_id),
		"材料：%s" % String(status.get("costs", "无"))
	]
	var foundation_status := String(status.get("foundation_status", ""))
	if not foundation_status.is_empty():
		parts.append(foundation_status)
	parts.append("状态：%s" % String(status.get("message", "")))
	if bool(status.get("can_build", false)):
		parts.append("按 E 建造")
	return "\n".join(parts)


func format_clear_prompt(
	interactable: PrototypeInteractable,
	character_state: CharacterState,
	world_state: WorldState
) -> String:
	var object_state := world_state.get_map_object(interactable.instance_id)
	if bool(object_state.get("is_cleared", false)):
		return "地块：%s\n状态：已清理，可用于铺设基础地基。" % _get_display_name(interactable.definition_id)

	var tool_status := _get_interaction_tool_status(interactable.definition_id, character_state)
	var parts: Array[String] = [
		"地块：%s" % _get_display_name(interactable.definition_id),
		"状态：未清理，阻挡建造。",
		"后续：清理后可铺设基础地基。",
		"工具：%s" % tool_status
	]
	if tool_status == "可清理":
		parts.append("按 E 清理地块")
	return "\n".join(parts)


func _get_interaction_tool_status(definition_id: String, character_state: CharacterState) -> String:
	var definition := data_registry.get_definition(definition_id)
	var required_tool_tags: Array = definition.get("required_tool_tags", [])
	if required_tool_tags.is_empty():
		return "无特殊要求"

	var tool_id := String(character_state.equipment.get("tool", ""))
	var tool_definition := data_registry.get_definition(tool_id)
	var tool_effects: Array = tool_definition.get("effects", [])
	var missing_tags: Array[String] = []
	for required_tool_tag in required_tool_tags:
		var tag := String(required_tool_tag)
		if tool_effects.has("effect.%s" % tag) or tool_effects.has(tag):
			continue
		missing_tags.append(tag)

	if missing_tags.is_empty():
		return "可清理"
	return "缺少能力：%s" % ", ".join(missing_tags)


func _get_display_name(definition_id: String) -> String:
	if definition_id.is_empty():
		return ""

	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id

	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))
