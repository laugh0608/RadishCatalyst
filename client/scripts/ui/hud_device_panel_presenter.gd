extends RefCounted
class_name HudDevicePanelPresenter


func format_device_panel_texts(
	data_registry: DataRegistry,
	processing_system: ProcessingSystem,
	interactable: PrototypeInteractable,
	character_state: CharacterState,
	world_state: WorldState
) -> Dictionary:
	if interactable == null or interactable.interaction_type != "process_recipe":
		return {}

	var current_recipe_id := interactable.get_current_recipe_id()
	var status := processing_system.get_recipe_status(current_recipe_id, character_state, world_state)
	var recommended_recipe_id := processing_system.get_recommended_recipe_id(interactable, character_state, world_state)
	return {
		"title": "设备面板：%s" % _get_display_name(data_registry, interactable.definition_id),
		"status": _format_device_status(data_registry, current_recipe_id, status, recommended_recipe_id),
		"recipes": _format_device_recipe_list(
			data_registry,
			processing_system,
			interactable,
			character_state,
			world_state,
			recommended_recipe_id
		),
		"operations": _format_device_operations(interactable, status)
	}


func _format_device_status(
	data_registry: DataRegistry,
	recipe_id: String,
	status: Dictionary,
	recommended_recipe_id: String
) -> String:
	var parts: Array[String] = [
		"当前配方：%s" % _get_display_name(data_registry, recipe_id),
		"状态：%s" % String(status.get("message", "")),
		"输入：%s" % String(status.get("inputs", "无")),
		"产出：%s" % String(status.get("outputs", "无"))
	]
	if not recommended_recipe_id.is_empty():
		parts.append(_format_recommended_recipe_status(data_registry, recipe_id, recommended_recipe_id))
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
	return "\n".join(parts)


func _format_device_recipe_list(
	data_registry: DataRegistry,
	processing_system: ProcessingSystem,
	interactable: PrototypeInteractable,
	character_state: CharacterState,
	world_state: WorldState,
	recommended_recipe_id: String
) -> String:
	var recipe_ids := interactable.recipe_ids.duplicate()
	if recipe_ids.is_empty() and not interactable.recipe_id.is_empty():
		recipe_ids.append(interactable.recipe_id)
	if recipe_ids.is_empty():
		return "配方列表：无"

	var rows: Array[String] = ["配方列表："]
	var current_recipe_id := interactable.get_current_recipe_id()
	for recipe_index in range(recipe_ids.size()):
		var recipe_id := String(recipe_ids[recipe_index])
		var status := processing_system.get_recipe_status(recipe_id, character_state, world_state)
		var marker := "  "
		if recipe_id == current_recipe_id:
			marker = "> "
		var recommendation_tag := ""
		if recipe_id == recommended_recipe_id:
			recommendation_tag = "（当前目标）"
		rows.append("%s%d. %s%s：%s" % [
			marker,
			recipe_index + 1,
			_get_display_name(data_registry, recipe_id),
			recommendation_tag,
			_format_device_recipe_state(status)
		])
	return "\n".join(rows)


func _format_device_recipe_state(status: Dictionary) -> String:
	if bool(status.get("can_process", false)):
		return "可加工"
	var missing_inputs: Array = status.get("missing_inputs", [])
	if not missing_inputs.is_empty():
		return "缺 %s" % "，".join(missing_inputs)
	return String(status.get("message", "不可加工")).trim_suffix("。")


func _format_device_operations(interactable: PrototypeInteractable, status: Dictionary) -> String:
	var operations: Array[String] = []
	if bool(status.get("can_process", false)):
		operations.append("E 启动当前配方")
	else:
		operations.append("E 尝试当前配方")
	if interactable.get_recipe_count() > 1:
		operations.append("R 切换配方")
	operations.append("Q 关闭面板")
	return "操作：%s" % "；".join(operations)


func _format_recommended_recipe_status(data_registry: DataRegistry, recipe_id: String, recommended_recipe_id: String) -> String:
	var recommended_name := _get_display_name(data_registry, recommended_recipe_id)
	if recipe_id == recommended_recipe_id:
		return "推荐：当前配方匹配当前目标。"
	return "推荐：当前目标建议使用 %s；按 R 切换到标记为“当前目标”的配方。" % recommended_name


func _get_display_name(data_registry: DataRegistry, definition_id: String) -> String:
	if definition_id.is_empty():
		return ""
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id
	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))
