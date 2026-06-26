extends RefCounted
class_name ProcessingInteractionPromptFormatter

var data_registry: DataRegistry
var processing_system: ProcessingSystem


func _init(registry: DataRegistry, processing: ProcessingSystem) -> void:
	data_registry = registry
	processing_system = processing


func format_processing_prompt(
	interactable: PrototypeInteractable,
	character_state: CharacterState,
	world_state: WorldState
) -> String:
	var recipe_id := interactable.get_current_recipe_id()
	var status := processing_system.get_recipe_status(recipe_id, character_state, world_state)
	var displayed_recipe_id := String(status.get("recipe_id", recipe_id))
	var parts: Array[String] = ["设备：%s" % _get_display_name(interactable.definition_id)]
	var recipe_line := "配方：%s" % _get_display_name(displayed_recipe_id)
	if interactable.get_recipe_count() > 1:
		recipe_line = "%s（%d/%d）" % [
			recipe_line,
			_get_recipe_position(interactable, displayed_recipe_id),
			interactable.get_recipe_count()
		]
	parts.append(recipe_line)
	if (
		interactable.definition_id == "building.basic_reactor"
		and FieldOutfittingRuntime.has_crystal_logistics_return_materials(world_state)
		and not FieldOutfittingRuntime.is_logistics_maintenance_confirmed(world_state)
	):
		parts.append(DepartureReadinessFormatter.format_crystal_logistics_return_line(world_state, character_state))

	var io_line := "%s -> %s" % [
		String(status.get("inputs", "无")),
		String(status.get("outputs", "无"))
	]
	var byproducts := String(status.get("byproducts", ""))
	if not byproducts.is_empty():
		io_line = "%s；副产 %s" % [io_line, byproducts]
	var industrial_chain_line := IndustrialTechSpineFormatter.format_processing_prompt_line(
		interactable.definition_id,
		displayed_recipe_id,
		world_state,
		character_state
	)
	if not industrial_chain_line.is_empty():
		io_line = "%s；%s" % [io_line, industrial_chain_line]
	var field_task_line := DemoFieldTaskDifferentiationFormatter.format_processing_prompt_line(
		interactable.definition_id,
		displayed_recipe_id,
		world_state,
		character_state
	)
	if not field_task_line.is_empty():
		io_line = "%s；%s" % [io_line, field_task_line]
	var base_reentry_line := DemoRouteReturnAndBaseReentryFormatter.format_device_status_line(
		interactable.definition_id,
		displayed_recipe_id,
		world_state,
		character_state
	)
	if not base_reentry_line.is_empty():
		io_line = "%s；%s" % [io_line, base_reentry_line]
	var operation_line := DemoDevicePanelOperationFormatter.format_processing_prompt_line(
		interactable.definition_id,
		displayed_recipe_id,
		status,
		world_state,
		character_state
	)
	if not operation_line.is_empty():
		io_line = "%s；%s" % [io_line, operation_line]
	var module_task_line := DemoIndustrialModuleTaskRhythmFormatter.format_processing_prompt_line(
		interactable.definition_id,
		displayed_recipe_id,
		world_state,
		character_state
	)
	if not module_task_line.is_empty():
		io_line = "%s；%s" % [io_line, module_task_line]
	parts.append(io_line)

	var status_line := "状态：%s" % String(status.get("message", ""))
	var progress := String(status.get("progress", ""))
	if not progress.is_empty():
		status_line = "%s；进度：%s %s" % [
			status_line,
			_format_progress_bar(float(status.get("progress_ratio", 0.0))),
			progress
		]
		var processing_next_step := String(status.get("next_step", ""))
		if not processing_next_step.is_empty():
			status_line = "%s；下一步：%s" % [status_line, processing_next_step]
	elif bool(status.get("can_process", false)):
		status_line = "%s；%s 秒" % [status_line, String(status.get("duration", "0"))]
	else:
		var next_step := _get_processing_next_step(status)
		if not next_step.is_empty():
			status_line = "%s；下一步：%s" % [status_line, next_step]
	parts.append(status_line)

	var action_parts: Array[String] = ["Q 详情"]
	if interactable.get_recipe_count() > 1:
		action_parts.append("R 切换")
	if bool(status.get("can_process", false)):
		action_parts.append("E 启动加工")
	parts.append("操作：%s" % "；".join(action_parts))
	return "\n".join(parts)


func format_processing_log(recipe_id: String, character_state: CharacterState, world_state: WorldState) -> String:
	var status := processing_system.get_recipe_status(recipe_id, character_state, world_state)
	var displayed_recipe_id := String(status.get("recipe_id", recipe_id))
	var parts: Array[String] = [
		"%s：%s" % [_get_display_name(displayed_recipe_id), String(status.get("message", ""))],
		"输入：%s" % String(status.get("inputs", "无")),
		"产出：%s" % String(status.get("outputs", "无")),
		"耗时：%s 秒" % String(status.get("duration", "0"))
	]
	var next_step := String(status.get("next_step", ""))
	if not next_step.is_empty():
		parts.append("下一步：%s" % next_step)
	var industrial_chain_line := IndustrialTechSpineFormatter.format_processing_log_line(
		displayed_recipe_id,
		world_state,
		character_state
	)
	if not industrial_chain_line.is_empty():
		parts.append(industrial_chain_line)
	var field_task_line := DemoFieldTaskDifferentiationFormatter.format_processing_log_line(
		displayed_recipe_id,
		world_state,
		character_state
	)
	if not field_task_line.is_empty():
		parts.append(field_task_line)
	var operation_line := DemoDevicePanelOperationFormatter.format_processing_log_line(
		displayed_recipe_id,
		status,
		world_state,
		character_state
	)
	if not operation_line.is_empty():
		parts.append(operation_line)
	var module_task_line := DemoIndustrialModuleTaskRhythmFormatter.format_processing_log_line(
		displayed_recipe_id,
		world_state,
		character_state
	)
	if not module_task_line.is_empty():
		parts.append(module_task_line)
	return "；".join(parts)


func _get_recipe_position(interactable: PrototypeInteractable, recipe_id: String) -> int:
	if interactable.recipe_ids.is_empty():
		return interactable.get_recipe_position()
	var index := interactable.recipe_ids.find(recipe_id)
	if index < 0:
		return interactable.get_recipe_position()
	return index + 1


func _get_processing_next_step(status: Dictionary) -> String:
	var supply_hint := String(status.get("supply_hint", ""))
	if not supply_hint.is_empty():
		return supply_hint

	var message := String(status.get("message", ""))
	if not Array(status.get("missing_inputs", [])).is_empty():
		return "先采集或回收缺少的原料，再回到设备启动加工。"
	if message.begins_with("需要先建造："):
		return "先完成对应建造点，再回到设备启动加工。"
	if message.find("未解锁") >= 0:
		return "先完成当前任务目标，解锁该配方后再启动加工。"
	if message.find("加工中") >= 0:
		return "等待设备完成；靠近设备查看进度，按 Q 打开设备面板。"
	return ""


func _format_progress_bar(ratio: float) -> String:
	var segment_count := 10
	var filled_count := mini(segment_count, maxi(0, int(floor(clampf(ratio, 0.0, 1.0) * float(segment_count)))))
	if ratio > 0.0 and filled_count == 0:
		filled_count = 1
	return "[%s%s]" % [
		_repeat_text("#", filled_count),
		_repeat_text("-", segment_count - filled_count)
	]


func _repeat_text(text: String, count: int) -> String:
	var parts: Array[String] = []
	for _index in range(maxi(0, count)):
		parts.append(text)
	return "".join(parts)


func _get_display_name(definition_id: String) -> String:
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id
	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))
