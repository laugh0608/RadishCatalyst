extends RefCounted
class_name BuildSystem

var data_registry: DataRegistry


func _init(registry: DataRegistry) -> void:
	data_registry = registry


func build_structure(
	site_instance_id: String,
	building_id: String,
	character_state: CharacterState,
	world_state: WorldState,
	prerequisite_instance_id: String = ""
) -> Dictionary:
	var building := data_registry.get_definition(building_id)
	if building.is_empty():
		return _failure("未知建筑：%s。" % building_id, "建造未完成", "检查建造点配置或切换到已知建筑。")

	var site_state := world_state.ensure_map_object(site_instance_id, building_id, character_state.current_region_id)
	if bool(site_state.get("is_built", false)):
		return _failure("该建造点已完成。", "建造未执行", _get_built_hint(building_id, world_state))

	var requirement_error := _get_requirement_error(building_id, prerequisite_instance_id, world_state)
	if not requirement_error.is_empty():
		var requirement_feedback := DemoActionBlockerRecoveryFormatter.format_build_prerequisite_failure(
			_get_display_name(building_id),
			requirement_error,
			_get_requirement_gap(building_id, world_state),
			_get_requirement_hint(building_id, world_state)
		)
		return _failure_from_feedback(requirement_error, requirement_feedback)

	var missing_costs := _get_missing_costs(building, character_state.inventory)
	if not missing_costs.is_empty():
		var missing_feedback := DemoActionBlockerRecoveryFormatter.format_build_material_failure(
			_get_display_name(building_id),
			missing_costs,
			_get_cost_hint(building_id)
		)
		return _failure_from_feedback("缺少建造材料：%s。" % ", ".join(missing_costs), missing_feedback)

	_consume_refs(building.get("build_cost", []), character_state.inventory)
	world_state.set_map_object_flag(site_instance_id, "is_built", true)
	world_state.map_objects[site_instance_id]["built_definition_id"] = building_id
	world_state.add_base_structure(
		_get_structure_id(site_instance_id),
		building_id,
		character_state.current_region_id,
		site_instance_id
	)

	var followup := _get_build_followup(building_id, world_state)
	var module_task := DemoIndustrialModuleTaskRhythmFormatter.format_build_result_line(
		building_id,
		world_state,
		character_state
	)
	return _success(
		"建造完成：%s。%s" % [_get_display_name(building_id), followup],
		building_id,
		followup,
		module_task
	)


func get_build_status(
	site_instance_id: String,
	building_id: String,
	character_state: CharacterState,
	world_state: WorldState,
	prerequisite_instance_id: String = ""
) -> Dictionary:
	var building := data_registry.get_definition(building_id)
	if building.is_empty():
		return {
			"can_build": false,
			"costs": "无",
			"message": "未知建筑：%s。" % building_id,
			"next_step": "检查建造点配置或切换到已知建筑。"
		}

	var site_state := world_state.get_map_object(site_instance_id)
	if bool(site_state.get("is_built", false)):
		return {
			"can_build": false,
			"costs": _format_refs(building.get("build_cost", [])),
			"message": "已建成。",
			"foundation_status": _format_foundation_status(building_id, world_state),
			"next_step": _get_built_hint(building_id, world_state)
		}

	var requirement_error := _get_requirement_error(building_id, prerequisite_instance_id, world_state)
	if not requirement_error.is_empty():
		return {
			"can_build": false,
			"costs": _format_refs(building.get("build_cost", [])),
			"message": requirement_error,
			"foundation_status": _format_foundation_status(building_id, world_state),
			"next_step": _get_requirement_hint(building_id, world_state)
		}

	var missing_costs := _get_missing_costs(building, character_state.inventory)
	if not missing_costs.is_empty():
		return {
			"can_build": false,
			"costs": _format_refs(building.get("build_cost", [])),
			"message": "缺少建造材料：%s。" % ", ".join(missing_costs),
			"missing_costs": missing_costs,
			"foundation_status": _format_foundation_status(building_id, world_state),
			"next_step": _get_cost_hint(building_id)
		}

	return {
		"can_build": true,
		"costs": _format_refs(building.get("build_cost", [])),
		"message": "可建造。",
		"foundation_status": _format_foundation_status(building_id, world_state),
		"next_step": _get_ready_build_hint(building_id, world_state)
	}


func _get_requirement_error(building_id: String, prerequisite_instance_id: String, world_state: WorldState) -> String:
	if building_id == "building.foundation_t1":
		if prerequisite_instance_id.is_empty():
			return ""

		var prerequisite_state := world_state.get_map_object(prerequisite_instance_id)
		if prerequisite_state.is_empty() or not bool(prerequisite_state.get("is_cleared", false)):
			return "地面仍然粗糙，先清理或平整地块。"
		return ""

	if building_id == "building.pollution_filter":
		if world_state.count_base_structures("building.foundation_t1") < 2:
			return "污染过滤器需要先铺设 2 块基础地基。"
		return ""

	if building_id == "building.slurry_buffer_tank":
		if not world_state.has_base_structure_definition("building.pollution_filter"):
			return "污染浆液缓冲罐需要先建成污染过滤器。"
		if not _has_first_resistance_vial_processed(world_state):
			return "污染浆液缓冲罐需要先让污染过滤器跑通首支抗污染药剂。"
		return ""
	if building_id == "building.crystal_collector_t1":
		if not world_state.quest_state.has_completed_quest("quest.restore_outpost"):
			return "基础晶体采集器需要先恢复前哨核心。"
		return ""

	return ""


func _get_requirement_hint(building_id: String, world_state: WorldState) -> String:
	match building_id:
		"building.foundation_t1":
			return "先清理粗糙地块，再铺设基础地基。"
		"building.pollution_filter":
			var foundation_count := mini(world_state.count_base_structures("building.foundation_t1"), 2)
			if foundation_count <= 0:
				return "先清理两处粗糙地块，并铺设 2 块基础地基。"
			return "还差 1 块基础地基；清理另一处粗糙地块并铺设。"
		"building.slurry_buffer_tank":
			if not world_state.has_base_structure_definition("building.pollution_filter"):
				return "先在处理点建成污染过滤器，再回收沉积物处理出污染浆液。"
			return "先用污染过滤器处理沉积物，产出首支抗污染药剂和污染浆液。"
		"building.crystal_collector_t1":
			return "先恢复前哨核心，再用手持工具采第一口晶体 / 残骸，补齐采集器材料。"
		_:
			return "先完成该建筑的前置条件。"


func _get_requirement_gap(building_id: String, world_state: WorldState) -> String:
	match building_id:
		"building.foundation_t1":
			return "清障状态仍未写入该地块，建造点还不能铺设。"
		"building.pollution_filter":
			return "基础地基：%d / 2。" % mini(world_state.count_base_structures("building.foundation_t1"), 2)
		"building.slurry_buffer_tank":
			if not world_state.has_base_structure_definition("building.pollution_filter"):
				return "污染过滤器尚未建成。"
			return "首支抗污染药剂尚未通过污染过滤器产出。"
		"building.crystal_collector_t1":
			return "前哨核心尚未恢复，晶体采集器不能抢在首屏核心恢复前出现。"
		_:
			return "该建筑的前置条件尚未满足。"


func _get_cost_hint(building_id: String) -> String:
	match building_id:
		"building.basic_storage":
			return "回晶体区采集晶体矿物，用基础反应器加工基础零件后再建储存箱。"
		"building.field_outfitting_station":
			return "回晶体区回收外勤残骸并加工基础零件，再建出发整备台。"
		"building.slurry_buffer_tank":
			return "回污染边界补沉积物，用污染过滤器处理出污染浆液；基础零件不足时回晶体区补晶体加工。"
		"building.crystal_collector_t1":
			return "先手持采晶体 / 回收残骸，回基地加工基础零件后再部署采集器。"
		"building.foundation_t1":
			return "回晶体区采集晶体矿物，并用基础反应器制造基础地基材料。"
		"building.pollution_filter":
			return "回基地用基础反应器补过滤介质和基础零件，再回处理点建造污染过滤器。"
		_:
			return "先补齐该建筑所需材料。"


func _get_ready_build_hint(building_id: String, world_state: WorldState) -> String:
	match building_id:
		"building.basic_storage":
			return "建成后接入前哨核心，外出消耗修复凝胶后回基地可补到 1 份。"
		"building.field_outfitting_station":
			return "建成后可在基地把已制造的基础过滤模块装入防护服。"
		"building.slurry_buffer_tank":
			return "建成后接入前哨核心，出发补给可把抗污染药剂补到 2 份。"
		"building.crystal_collector_t1":
			return "建成后采集器输出托盘会出晶体矿物；收取后回基地入基础反应器。"
		"building.foundation_t1":
			var foundation_count := mini(world_state.count_base_structures("building.foundation_t1"), 2)
			if foundation_count <= 0:
				return "建成后继续铺另一块基础地基，2 块后可建污染过滤器。"
			return "建成后基础地基达到 2 / 2，可继续建污染过滤器。"
		"building.pollution_filter":
			return "建成后可处理污染沉积物，把药剂和污染浆液接入后续外勤。"
	return ""


func _get_missing_costs(building: Dictionary, inventory: InventoryState) -> Array[String]:
	var missing_costs: Array[String] = []
	for cost in building.get("build_cost", []):
		if not cost is Dictionary:
			continue

		var definition_id := String(cost.get("id", ""))
		var amount := float(cost.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0:
			continue
		if not inventory.has_ref(definition_id, amount):
			missing_costs.append("%s x%s" % [_get_display_name(definition_id), _format_amount(amount)])

	return missing_costs


func _format_foundation_status(building_id: String, world_state: WorldState) -> String:
	if building_id != "building.pollution_filter":
		return ""
	return "基础地基：%d / 2" % mini(world_state.count_base_structures("building.foundation_t1"), 2)


func _get_build_followup(building_id: String, world_state: WorldState) -> String:
	if building_id == "building.basic_storage":
		return "储存箱已接入前哨整备；回前哨核心时会把修复凝胶补到 1 份。"
	if building_id == "building.field_outfitting_station":
		return "整备台已上线；靠近后可把基础过滤模块装入防护服，让污染承压降低。"
	if building_id == "building.slurry_buffer_tank":
		return "污染浆液缓冲罐已接入前哨补给；回前哨核心时抗污染药剂可补到 2 份。"
	if building_id == "building.crystal_collector_t1":
		return "基础晶体采集器已接入矿面；到输出托盘收料，再回基础反应器加工。"
	if building_id == "building.foundation_t1":
		var foundation_count := mini(world_state.count_base_structures("building.foundation_t1"), 2)
		if foundation_count < 2:
			return "继续铺设另一块基础地基；当前基础地基：%d / 2。" % foundation_count
		return "现在可以建造污染过滤器；基础地基：2 / 2。"
	if building_id == "building.pollution_filter":
		return "过滤器已上线；回收污染沉积物后可在这里处理抗污染药剂。"
	return ""


func _get_built_hint(building_id: String, world_state: WorldState) -> String:
	if building_id == "building.basic_storage":
		return "基础储存箱已接入前哨核心；外出消耗修复凝胶后，回前哨核心可补到 1 份。"
	if building_id == "building.field_outfitting_station":
		return "出发整备台已上线；靠近整备台按 E 装配基础过滤模块，或先用基础反应器制造模块。"
	if building_id == "building.slurry_buffer_tank":
		return "污染浆液缓冲罐已接入前哨核心；外出消耗药剂后，回前哨核心可把抗污染药剂补到 2 份。"
	if building_id == "building.crystal_collector_t1":
		return "基础晶体采集器已上线；到矿面输出托盘收取晶体矿物，再回基地入料。"
	if building_id == "building.foundation_t1":
		var foundation_count := mini(world_state.count_base_structures("building.foundation_t1"), 2)
		if foundation_count < 2:
			return "下一个建造点：继续清理并铺设另一块基础地基；2 块后才能建造污染过滤器。"
		return "两块基础地基已就绪；去建造污染过滤器。"
	if building_id == "building.pollution_filter":
		return "污染过滤器已上线；回收污染沉积物后在设备面板处理抗污染药剂。"
	return "前往下一个建造点或查看当前任务目标。"


func _get_build_destination(building_id: String) -> String:
	match building_id:
		"building.basic_storage":
			return "基础储存箱已加入前哨整备补给。"
		"building.field_outfitting_station":
			return "出发整备台已加入基地后勤区。"
		"building.slurry_buffer_tank":
			return "污染浆液缓冲罐已加入前哨药剂补给。"
		"building.crystal_collector_t1":
			return "基础晶体采集器已加入晶体矿面资源端。"
		"building.foundation_t1":
			return "建造结果已写入处理点地基状态。"
		"building.pollution_filter":
			return "污染过滤器已加入处理点设备面板。"
		_:
			return "建造结果已写入基地结构状态。"


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


func _consume_refs(refs: Array, inventory: InventoryState) -> void:
	for ref in refs:
		if not ref is Dictionary:
			continue

		var definition_id := String(ref.get("id", ""))
		var amount := float(ref.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0:
			continue

		inventory.consume_ref(definition_id, amount)


func _has_first_resistance_vial_processed(world_state: WorldState) -> bool:
	return (
		world_state.quest_state.has_completed_quest("quest.enter_pollution_edge")
		or world_state.quest_state.get_objective_progress("quest.enter_pollution_edge", "craft_item", "item.resistance_vial_t1") >= 1.0
	)


func _get_structure_id(site_instance_id: String) -> String:
	return "structure.%s" % site_instance_id.get_slice(".", 1)


func _get_display_name(definition_id: String) -> String:
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id
	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))


func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount


func _success(
	message: String,
	building_id: String,
	next_step: String = "",
	module_task: String = ""
) -> Dictionary:
	var feedback := {
		"title": "建造完成：%s" % _get_display_name(building_id),
		"status": "已建成。",
		"destination": _get_build_destination(building_id),
		"next_step": next_step
	}
	if not module_task.is_empty():
		feedback["module_task"] = module_task
		feedback["show_module_task"] = _should_show_module_task_result_line(building_id)
	return {
		"success": true,
		"message": message,
		"built_definition_id": building_id,
		"success_feedback": feedback
	}


func _failure(message: String, title: String = "建造未完成", detail: String = "") -> Dictionary:
	return {
		"success": false,
		"message": message,
		"failure_feedback": {
			"title": title,
			"detail": detail
		}
	}


func _failure_from_feedback(message: String, feedback: Dictionary) -> Dictionary:
	return {
		"success": false,
		"message": message,
		"failure_feedback": feedback
	}


func _should_show_module_task_result_line(building_id: String) -> bool:
	return [
		"building.basic_storage",
		"building.field_outfitting_station",
		"building.pollution_filter"
	].has(building_id)
