extends RefCounted
class_name ProcessingSystem

var data_registry: DataRegistry


func _init(registry: DataRegistry) -> void:
	data_registry = registry


func process_recipe(recipe_id: String, character_state: CharacterState, world_state: WorldState) -> Dictionary:
	var recipe := data_registry.get_definition(recipe_id)
	if recipe.is_empty():
		return _failure("未知配方：%s。" % recipe_id, "加工未完成", "切换到已知配方，或检查静态数据定义。")

	var lock_message := _get_recipe_lock_message(recipe, world_state)
	if not lock_message.is_empty():
		return _failure(lock_message, "配方未解锁", "先完成当前任务目标，解锁该配方后再启动加工。")

	var structure_id := _get_required_structure_id(recipe, world_state)
	if structure_id.is_empty():
		return _failure(
			"需要先建造：%s。" % _get_display_name(String(recipe.get("required_building_id", ""))),
			"设备未就绪",
			"先完成建造点或处理点扩建，再回到设备启动加工。"
		)
	var structure: Dictionary = world_state.base_structures.get(structure_id, {})
	if String(structure.get("status", "idle")) == "in_progress":
		return _failure(_format_in_progress_message(structure), "设备加工中", "等待进度完成；靠近设备可查看当前进度。")

	var missing_inputs := _get_missing_inputs(recipe, character_state.inventory)
	if not missing_inputs.is_empty():
		return _failure("缺少原料：%s。" % ", ".join(missing_inputs), "原料不足", "先采集资源或切换到输入已满足的配方。")

	_consume_refs(recipe.get("inputs", []), character_state.inventory)
	world_state.set_base_structure_status(structure_id, "in_progress", recipe_id)

	return {
		"success": true,
		"processing_started": true,
		"recipe_id": recipe_id,
		"structure_id": structure_id,
		"message": "已启动加工：%s；预计 %s 秒完成。" % [
			_get_display_name(recipe_id),
			_format_amount(_get_recipe_duration(recipe))
		]
	}


func advance_processing(delta_seconds: float, character_state: CharacterState, world_state: WorldState) -> Array[Dictionary]:
	var completed_results: Array[Dictionary] = []
	if delta_seconds <= 0.0:
		return completed_results

	for structure_id in world_state.base_structures:
		var structure = world_state.base_structures[structure_id]
		if not structure is Dictionary:
			continue
		if String(structure.get("status", "idle")) != "in_progress":
			continue

		var recipe_id := String(structure.get("active_recipe_id", ""))
		var recipe := data_registry.get_definition(recipe_id)
		if recipe.is_empty():
			continue

		var duration := _get_recipe_duration(recipe)
		var progress_seconds := minf(float(structure.get("progress_seconds", 0.0)) + delta_seconds, duration)
		world_state.set_base_structure_progress(String(structure_id), progress_seconds)
		if progress_seconds < duration:
			continue

		_grant_refs(recipe.get("outputs", []), character_state.inventory)
		_grant_refs(recipe.get("byproducts", []), character_state.inventory)
		world_state.set_base_structure_status(String(structure_id), "completed", recipe_id)
		completed_results.append({
			"success": true,
			"completed_recipe_id": recipe_id,
			"structure_id": String(structure_id),
			"message": _format_completion_message(recipe)
		})

	return completed_results


func get_recipe_status(recipe_id: String, character_state: CharacterState, world_state: WorldState) -> Dictionary:
	var recipe := data_registry.get_definition(recipe_id)
	if recipe.is_empty():
		return {
			"can_process": false,
			"message": "未知配方：%s" % recipe_id,
			"inputs": "无",
			"outputs": "无",
			"byproducts": "",
			"duration": "0",
			"progress": "",
			"progress_ratio": 0.0
		}

	var missing_inputs := _get_missing_inputs(recipe, character_state.inventory)
	var lock_message := _get_recipe_lock_message(recipe, world_state)
	var structure_id := _get_required_structure_id(recipe, world_state)
	var missing_structure := ""
	if structure_id.is_empty():
		missing_structure = "需要先建造：%s。" % _get_display_name(String(recipe.get("required_building_id", "")))

	var active_structure := _get_active_structure_for_building(String(recipe.get("required_building_id", "")), world_state)
	if not active_structure.is_empty():
		return _recipe_status(recipe, false, _format_in_progress_message(active_structure), missing_inputs, active_structure)

	if not lock_message.is_empty():
		return _recipe_status(recipe, false, lock_message, missing_inputs)
	if not missing_structure.is_empty():
		return _recipe_status(recipe, false, missing_structure, missing_inputs)
	if not missing_inputs.is_empty():
		return _recipe_status(recipe, false, "缺少原料：%s。" % ", ".join(missing_inputs), missing_inputs)

	return _recipe_status(recipe, true, "可加工。", [])


func _format_completion_message(recipe: Dictionary) -> String:
	var parts: Array[String] = [
		"加工完成：%s -> %s" % [
			_get_display_name(String(recipe.get("id", ""))),
			_format_refs(recipe.get("outputs", []), "无产物")
		]
	]
	var byproducts := _format_refs(recipe.get("byproducts", []), "")
	if not byproducts.is_empty():
		parts.append("副产：%s" % byproducts)
	return "%s。" % "；".join(parts)


func _format_in_progress_message(structure: Dictionary) -> String:
	var active_recipe_id := String(structure.get("active_recipe_id", ""))
	var recipe := data_registry.get_definition(active_recipe_id)
	var duration := _get_recipe_duration(recipe)
	var progress_seconds := float(structure.get("progress_seconds", 0.0))
	return "加工中：%s（%s / %s 秒）。" % [
		_get_display_name(active_recipe_id),
		_format_amount(progress_seconds),
		_format_amount(duration)
	]


func _get_missing_inputs(recipe: Dictionary, inventory: InventoryState) -> Array[String]:
	var missing_inputs: Array[String] = []
	for input_ref in recipe.get("inputs", []):
		if not input_ref is Dictionary:
			continue

		var definition_id := String(input_ref.get("id", ""))
		var amount := float(input_ref.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0:
			continue
		var current_amount := _get_inventory_ref_amount(definition_id, inventory)
		if current_amount < amount:
			missing_inputs.append("%s x%s" % [_get_display_name(definition_id), _format_amount(amount - current_amount)])

	return missing_inputs


func _get_required_structure_id(recipe: Dictionary, world_state: WorldState) -> String:
	var building_id := String(recipe.get("required_building_id", ""))
	if building_id.is_empty():
		return ""
	return world_state.get_base_structure_id_for_definition(building_id)


func _get_active_structure_for_building(building_id: String, world_state: WorldState) -> Dictionary:
	if building_id.is_empty():
		return {}

	for structure in world_state.base_structures.values():
		if not structure is Dictionary:
			continue
		if String(structure.get("definition_id", "")) != building_id:
			continue
		if String(structure.get("status", "idle")) == "in_progress":
			return structure
	return {}


func _consume_refs(refs: Array, inventory: InventoryState) -> void:
	for ref in refs:
		if not ref is Dictionary:
			continue

		var definition_id := String(ref.get("id", ""))
		var amount := float(ref.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0:
			continue

		inventory.consume_ref(definition_id, amount)


func _grant_refs(refs: Array, inventory: InventoryState) -> void:
	for ref in refs:
		if not ref is Dictionary:
			continue

		var definition_id := String(ref.get("id", ""))
		var amount := float(ref.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0:
			continue

		inventory.add_ref(definition_id, amount)


func _format_refs(refs: Array, empty_text: String = "无") -> String:
	var parts: Array[String] = []
	for ref in refs:
		if not ref is Dictionary:
			continue

		var definition_id := String(ref.get("id", ""))
		var amount := float(ref.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0:
			continue

		parts.append("%s x%s" % [_get_display_name(definition_id), _format_amount(amount)])

	if parts.is_empty():
		return empty_text
	return ", ".join(parts)


func _recipe_status(
	recipe: Dictionary,
	can_process: bool,
	message: String,
	missing_inputs: Array[String],
	active_structure: Dictionary = {}
) -> Dictionary:
	var active_recipe_id := String(active_structure.get("active_recipe_id", ""))
	var active_recipe := data_registry.get_definition(active_recipe_id)
	var duration := _get_recipe_duration(recipe)
	if not active_recipe.is_empty():
		duration = _get_recipe_duration(active_recipe)
	var progress := ""
	var progress_ratio := 0.0
	if not active_structure.is_empty():
		var progress_seconds := float(active_structure.get("progress_seconds", 0.0))
		progress = "%s / %s 秒" % [_format_amount(progress_seconds), _format_amount(duration)]
		if duration > 0.0:
			progress_ratio = clampf(progress_seconds / duration, 0.0, 1.0)

	return {
		"can_process": can_process,
		"message": message,
		"inputs": _format_refs(recipe.get("inputs", [])),
		"outputs": _format_refs(recipe.get("outputs", [])),
		"byproducts": _format_refs(recipe.get("byproducts", []), ""),
		"missing_inputs": missing_inputs,
		"duration": _format_amount(duration),
		"progress": progress,
		"progress_ratio": progress_ratio
	}


func _get_recipe_lock_message(recipe: Dictionary, world_state: WorldState) -> String:
	var recipe_id := String(recipe.get("id", ""))
	var unlock_conditions = recipe.get("unlock_conditions", [])
	if not (unlock_conditions is Array) or unlock_conditions.is_empty():
		return ""
	if world_state.quest_state.unlocked_effects.has(recipe_id):
		return ""
	return "配方尚未解锁：%s。" % _format_unlock_conditions(unlock_conditions)


func _format_unlock_conditions(unlock_conditions: Array) -> String:
	var parts: Array[String] = []
	for unlock_condition in unlock_conditions:
		parts.append(_get_display_name(String(unlock_condition)))
	if parts.is_empty():
		return "继续推进当前目标"
	return ", ".join(parts)


func _get_recipe_duration(recipe: Dictionary) -> float:
	return maxf(0.1, float(recipe.get("duration", 0.1)))


func _get_inventory_ref_amount(definition_id: String, inventory: InventoryState) -> float:
	if definition_id.begins_with("fluid."):
		return float(inventory.fluids.get(definition_id, 0.0))
	return float(inventory.items.get(definition_id, 0))


func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount


func _get_display_name(definition_id: String) -> String:
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id
	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))


func _success(message: String) -> Dictionary:
	return {
		"success": true,
		"message": message
	}


func _failure(message: String, title: String = "加工未完成", detail: String = "") -> Dictionary:
	return {
		"success": false,
		"message": message,
		"failure_feedback": {
			"title": title,
			"detail": detail
		}
	}
