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
			"destination_text": _format_completion_destination(recipe),
			"next_step_text": _get_completion_next_step(recipe_id),
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
	var required_structure: Dictionary = {}
	if not structure_id.is_empty():
		required_structure = world_state.base_structures.get(structure_id, {})

	var active_structure := _get_active_structure_for_building(String(recipe.get("required_building_id", "")), world_state)
	if not active_structure.is_empty():
		return _recipe_status(recipe, false, _format_in_progress_message(active_structure), missing_inputs, active_structure, required_structure)

	if not lock_message.is_empty():
		return _recipe_status(recipe, false, lock_message, missing_inputs, {}, required_structure)
	if not missing_structure.is_empty():
		return _recipe_status(recipe, false, missing_structure, missing_inputs, {}, required_structure)
	if not missing_inputs.is_empty():
		return _recipe_status(recipe, false, "缺少原料：%s。" % ", ".join(missing_inputs), missing_inputs, {}, required_structure)

	return _recipe_status(recipe, true, "可加工。", [], {}, required_structure)


func get_recommended_recipe_id(
	interactable: PrototypeInteractable,
	character_state: CharacterState,
	world_state: WorldState
) -> String:
	if interactable == null or interactable.interaction_type != "process_recipe":
		return ""

	var active_quest_id := ""
	if not world_state.quest_state.active_quest_ids.is_empty():
		active_quest_id = String(world_state.quest_state.active_quest_ids[0])
	match active_quest_id:
		"quest.scout_crystal_field":
			return _select_if_available(interactable, "recipe.process_crystal_ore")
		"quest.calibrate_reactor":
			if world_state.quest_state.get_objective_progress(active_quest_id, "gather_item", "item.salvage_scrap") >= 4.0:
				return _select_if_available(interactable, "recipe.reactor_calibrator")
			return ""
		"quest.analyze_anomaly_sample":
			if world_state.quest_state.get_objective_progress(active_quest_id, "gather_item", "item.anomaly_residue") >= 2.0:
				return _select_if_available(interactable, "recipe.analyze_anomaly_sample")
			return ""
		"quest.make_filter_module":
			if not character_state.inventory.has_ref("item.filter_media", 1):
				return _select_if_available(interactable, "recipe.make_filter_media")
			return _select_if_available(interactable, "recipe.basic_filter_module")
		"quest.prepare_treatment_supplies":
			if world_state.quest_state.get_objective_progress(active_quest_id, "craft_item", "item.repair_gel") < 1.0:
				return _select_if_available(interactable, "recipe.repair_gel")
			return ""
		"quest.expand_treatment_point":
			var pending_foundations := maxi(0, 2 - world_state.count_base_structures("building.foundation_t1"))
			if _get_inventory_ref_amount("item.foundation_material", character_state.inventory) < pending_foundations:
				return _select_if_available(interactable, "recipe.foundation_t1")
			if world_state.has_base_structure_definition("building.pollution_filter"):
				return ""
			if _get_build_cost_shortage("building.pollution_filter", "item.filter_media", character_state.inventory) > 0.0:
				return _select_if_available(interactable, "recipe.make_filter_media")
			if _get_build_cost_shortage("building.pollution_filter", "item.basic_parts", character_state.inventory) > 0.0:
				return _select_if_available(interactable, "recipe.process_crystal_ore")
			return ""
		"quest.enter_pollution_edge":
			return _select_if_available(interactable, "recipe.cleanse_residue")
		"quest.assemble_phase_anchor":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_anchor")
		"quest.analyze_deep_signal":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.deep_signal_analysis")
		"quest.refine_phase_filament":
			return _select_if_available(interactable, "recipe.phase_filament_refining")
		"quest.assemble_deep_override":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.deep_override_key")
		"quest.analyze_deep_core":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.deep_core_imprint")
		"quest.assemble_deep_signal_matrix":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.deep_signal_matrix")
		"quest.refine_phase_splinters":
			return _select_if_available(interactable, "recipe.phase_splinter_refining")
		"quest.tune_relay_lens":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.relay_tuning_lens")
		"quest.analyze_inner_fault_trace":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.inner_fault_analysis")
		"quest.refine_fault_residue":
			return _select_if_available(interactable, "recipe.fault_residue_stabilization")
		"quest.assemble_phase_well_key":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_key")
		"quest.analyze_phase_well_locator":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_locator_analysis")
		"quest.refine_well_flux":
			return _select_if_available(interactable, "recipe.well_flux_stabilization")
		"quest.assemble_phase_well_probe":
			return _select_recipe_with_basic_parts_fallback(interactable, character_state.inventory, "recipe.phase_well_probe")
		_:
			return ""


func _format_completion_message(recipe: Dictionary) -> String:
	var recipe_id := String(recipe.get("id", ""))
	var parts: Array[String] = ["加工完成：%s。" % _get_display_name(recipe_id)]
	var destination := _format_completion_destination(recipe)
	if not destination.is_empty():
		parts.append(destination)
	var next_step := _get_completion_next_step(recipe_id)
	if not next_step.is_empty():
		parts.append("下一步：%s" % next_step)
	return " ".join(parts)


func _format_completion_destination(recipe: Dictionary) -> String:
	var parts: Array[String] = []
	var outputs := _format_refs(recipe.get("outputs", []), "")
	if not outputs.is_empty():
		parts.append("产物已放入背包：%s。" % outputs)
	var byproducts := _format_refs(recipe.get("byproducts", []), "")
	if not byproducts.is_empty():
		parts.append("副产已放入背包：%s。" % byproducts)
	if parts.is_empty():
		return "本次无新增产物。"
	return " ".join(parts)


func _format_last_completion_status(structure: Dictionary) -> String:
	var last_recipe_id := String(structure.get("last_recipe_id", ""))
	if last_recipe_id.is_empty():
		return ""
	var completed_runs := int(structure.get("completed_runs", 0))
	if completed_runs > 0:
		return "刚完成：%s（累计 %d 次）。" % [_get_display_name(last_recipe_id), completed_runs]
	return "刚完成：%s。" % _get_display_name(last_recipe_id)


func _get_completion_next_step(recipe_id: String) -> String:
	match recipe_id:
		"recipe.process_crystal_ore":
			return "基础零件已补足；若当前任务还差更高阶配方，设备会自动切回对应配方，也可按 R 切换。"
		"recipe.reactor_calibrator":
			return "反应器采样通道已校准；前往异常晶体采样并回收周边残留物。"
		"recipe.analyze_anomaly_sample":
			return "样本过滤参数已确认；切换到过滤介质和基础过滤模块配方。"
		"recipe.make_filter_media":
			return "切换到基础过滤模块配方，把过滤介质和基础零件组装成远征模块。"
		"recipe.basic_filter_module":
			return "按 F 启用基础过滤模块，再准备污染处理点的地基。"
		"recipe.foundation_t1":
			return "前往污染边界北缘清理地块并铺设基础地基。"
		"recipe.cleanse_residue":
			return "把抗污染药剂留在快捷栏，继续采集沉积物并清理受扰敌人。"
		"recipe.repair_gel":
			return "把修复凝胶留在快捷栏，生命偏低时按 1 使用。"
		"recipe.phase_anchor":
			return "带着稳相信标返回遗迹外圈，在抖动雾幕前部署后再继续深入。"
		"recipe.deep_signal_analysis":
			return "带着更深遗迹坐标返回遗迹外圈最东侧，写入深段入口门禁。"
		"recipe.phase_filament_refining":
			return "把谐振滤芯、副产污染浆液和基础零件送到基础反应器，组装深段覆写栓。"
		"recipe.deep_override_key":
			return "带着深段覆写栓返回深段入口，覆写锁扣并取出样块。"
		"recipe.deep_core_imprint":
			return "带着深段路由印片返回深段阵列台，点亮第二轮导管回收线。"
		"recipe.deep_signal_matrix":
			return "深段第二轮读数已整理完成；返回深段固定点部署前线回传锚点，并准备从回投台重返前线。"
		"recipe.phase_splinter_refining":
			return "透镜胚片和副产污染浆液已筛出；把它们带回基地反应器，调准成中继调谐镜。"
		"recipe.relay_tuning_lens":
			return "带着中继调谐镜返回更东侧裂相尖塔，逼出第一份内层故障轨迹。"
		"recipe.inner_fault_analysis":
			return "相位井坐标印片已整理完成；返回裂相尖塔更东侧，击退潜猎体并回收故障残渣。"
		"recipe.fault_residue_stabilization":
			return "稳定故障芯和副产污染浆液已筛出；把它们带回基地反应器，组装相位井钥。"
		"recipe.phase_well_key":
			return "带着相位井钥返回更东侧相位井锁，钉住锁位并带回第一份定位器。"
		"recipe.phase_well_locator_analysis":
			return "相位井路由片已整理完成；继续向东进入新暴露的内层相位井边缘，击退哨戒体并回收井涌碎屑。"
		"recipe.well_flux_stabilization":
			return "稳流芯和副产污染浆液已筛出；把它们带回基地反应器，组装相位井探针。"
		"recipe.phase_well_probe":
			return "带着相位井探针返回更东侧内层相位井，读取第一份井芯样本。"
		_:
			return "查看当前任务目标，选择下一次加工或外出行动。"


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


func _select_if_available(interactable: PrototypeInteractable, recipe_id: String) -> String:
	if interactable.has_recipe(recipe_id):
		return recipe_id
	return ""


func _select_recipe_with_basic_parts_fallback(
	interactable: PrototypeInteractable,
	inventory: InventoryState,
	target_recipe_id: String
) -> String:
	if _should_refill_basic_parts_before_recipe(target_recipe_id, inventory):
		var refill_recipe_id := _select_if_available(interactable, "recipe.process_crystal_ore")
		if not refill_recipe_id.is_empty():
			return refill_recipe_id
	return _select_if_available(interactable, target_recipe_id)


func _should_refill_basic_parts_before_recipe(target_recipe_id: String, inventory: InventoryState) -> bool:
	var recipe := data_registry.get_definition(target_recipe_id)
	if recipe.is_empty():
		return false
	if _get_recipe_input_shortage(recipe, "item.basic_parts", inventory) <= 0.0:
		return false
	return _has_required_inputs_except(recipe, inventory, "item.basic_parts")


func _get_recipe_input_shortage(recipe: Dictionary, definition_id: String, inventory: InventoryState) -> float:
	for input_ref in recipe.get("inputs", []):
		if not input_ref is Dictionary:
			continue
		if String(input_ref.get("id", "")) != definition_id:
			continue
		return maxf(0.0, float(input_ref.get("amount", 0.0)) - _get_inventory_ref_amount(definition_id, inventory))
	return 0.0


func _has_required_inputs_except(recipe: Dictionary, inventory: InventoryState, skipped_definition_id: String) -> bool:
	for input_ref in recipe.get("inputs", []):
		if not input_ref is Dictionary:
			continue
		var definition_id := String(input_ref.get("id", ""))
		var amount := float(input_ref.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0 or definition_id == skipped_definition_id:
			continue
		if _get_inventory_ref_amount(definition_id, inventory) < amount:
			return false
	return true


func _get_build_cost_shortage(building_id: String, definition_id: String, inventory: InventoryState) -> float:
	if building_id.is_empty() or definition_id.is_empty():
		return 0.0

	var building := data_registry.get_definition(building_id)
	if building.is_empty():
		return 0.0

	for cost in building.get("build_cost", []):
		if not cost is Dictionary:
			continue
		if String(cost.get("id", "")) != definition_id:
			continue
		return maxf(0.0, float(cost.get("amount", 0.0)) - _get_inventory_ref_amount(definition_id, inventory))
	return 0.0


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
	active_structure: Dictionary = {},
	required_structure: Dictionary = {}
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

	var result := {
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
	if not required_structure.is_empty() and String(required_structure.get("status", "")) == "completed":
		var last_recipe_id := String(required_structure.get("last_recipe_id", ""))
		var last_recipe := data_registry.get_definition(last_recipe_id)
		if not last_recipe.is_empty():
			result["last_completed_recipe_id"] = last_recipe_id
			result["last_completion"] = _format_last_completion_status(required_structure)
			result["last_destination"] = _format_completion_destination(last_recipe)
			result["last_next_step"] = _get_completion_next_step(last_recipe_id)
	return result


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
	if definition_id.begins_with("equipment."):
		return float(inventory.equipment.get(definition_id, 0))
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
