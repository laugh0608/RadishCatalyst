extends RefCounted
class_name GatherSystem

const PROTOTYPE_POLLUTION_PRESSURE_MULT := 15.0

var data_registry: DataRegistry
var processing_system: ProcessingSystem
var build_system: BuildSystem

const FIELD_READING_RESULTS := {
	"map_object.phase_splinter_resonance_node": {
		"quest_id": "quest.trace_phase_splinters",
		"objective_type": "inspect",
		"target_id": "map_object.phase_splinter_resonance_node",
		"required": 2.0,
		"step": "裂相共振读数",
		"partial": "继续检查另一处裂相共振点，再处理猎手和碎屑。",
		"complete": "两点共振已定位，裂相碎屑回收线已经稳定。"
	},
	"map_object.fault_residue_pulse_node": {
		"quest_id": "quest.collect_fault_residue",
		"objective_type": "inspect",
		"target_id": "map_object.fault_residue_pulse_node",
		"required": 2.0,
		"step": "故障脉冲读数",
		"partial": "继续读另一处脉冲，再压制潜猎体。",
		"complete": "两处故障脉冲已读出，故障残渣回收线已经显形。"
	},
	"map_object.well_flux_pressure_vent": {
		"quest_id": "quest.collect_well_flux",
		"objective_type": "inspect",
		"target_id": "map_object.well_flux_pressure_vent",
		"required": 2.0,
		"step": "井涌泄压",
		"partial": "继续处理另一处泄压阀，再压制井口哨戒体。",
		"complete": "两处井涌压力已卸掉，井涌碎屑回收线已经稳定。"
	},
	"map_object.phase_well_chamber_shunt_node": {
		"quest_id": "quest.collect_heart_spine",
		"objective_type": "inspect",
		"target_id": "map_object.phase_well_chamber_shunt_node",
		"required": 2.0,
		"step": "井心分流读数",
		"partial": "继续写入另一处分流读数，心棘残片还没有完全露出。",
		"complete": "两处分流读数已写入，心棘残片从脉冲里露出。"
	},
	"map_object.phase_well_loom_tension_spool": {
		"quest_id": "quest.collect_weft_bundle",
		"objective_type": "inspect",
		"target_id": "map_object.phase_well_loom_tension_spool",
		"required": 2.0,
		"step": "井纺张力绕轮",
		"partial": "继续检查另一处张力绕轮，纬束残团还不稳定。",
		"complete": "两处张力绕轮已确认，纬束残团回收线已经稳定。"
	},
	"map_object.phase_well_tether_knot_node": {
		"quest_id": "quest.collect_tether_fiber",
		"objective_type": "inspect",
		"target_id": "map_object.phase_well_tether_knot_node",
		"required": 2.0,
		"step": "井系桥结点",
		"partial": "继续检查另一端结点，系索残股还没有完全松开。",
		"complete": "两端桥结点已确认，系索残股从桥体边缘松开。"
	}
}


func _init(registry: DataRegistry) -> void:
	data_registry = registry
	processing_system = ProcessingSystem.new(data_registry)
	build_system = BuildSystem.new(data_registry)


func interact_with_object(
	instance_id: String,
	definition_id: String,
	interaction_type: String,
	character_state: CharacterState,
	world_state: WorldState,
	recipe_id: String = ""
) -> Dictionary:
	if interaction_type == "outpost_core":
		return _interact_with_outpost_core(character_state, world_state)
	if interaction_type == "process_recipe":
		return processing_system.process_recipe(recipe_id, character_state, world_state)
	if interaction_type == "build":
		return build_system.build_structure(
			instance_id,
			definition_id,
			character_state,
			world_state,
			recipe_id
		)

	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return _failure("未知交互对象：%s。" % definition_id, "交互未完成", "换一个可交互目标，或检查地图对象定义。")

	if interaction_type == "inspect" and definition_id == BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID:
		var departure_messages := BaseActionDispatchPlan.confirm_departure_preparation(world_state)
		if not departure_messages.is_empty():
			return _success(" ".join(departure_messages))
	if interaction_type == "inspect" and BaseActionDispatchPlan.is_plan_candidate_console_ready(definition_id, world_state):
		var candidate_messages := BaseActionDispatchPlan.select_next_plan_candidate_for_console(definition_id, world_state)
		if not candidate_messages.is_empty():
			return _success(" ".join(candidate_messages))

	var object_state := world_state.ensure_map_object(instance_id, definition_id, character_state.current_region_id)
	if _is_already_processed(object_state, interaction_type):
		return _failure("目标已处理。", "交互未执行", "前往当前目标标记，寻找下一个可交互对象。")
	var quest_gate_error := _get_quest_gate_error(definition_id, interaction_type, world_state)
	if not quest_gate_error.is_empty():
		return _failure(quest_gate_error, "交互前置不足", _get_quest_gate_detail(definition_id, interaction_type))

	if not _supports_interaction(definition, interaction_type):
		return _failure("当前目标不支持该交互。", "交互不可用", "换一个可交互目标，或查看附近提示。")

	var tool_error := _get_tool_requirement_error(definition, character_state)
	if not tool_error.is_empty():
		return _failure(tool_error, "工具能力不足", "检查当前工具能力，或先推进任务解锁合适工具。")

	match interaction_type:
		"gather":
			return _gather(instance_id, definition, character_state, world_state)
		"sample":
			return _sample(instance_id, definition, character_state, world_state)
		"clear":
			world_state.set_map_object_flag(instance_id, "is_cleared", true)
			if definition_id == "map_object.phase_well_anchor_pressure_pin":
				return _success("锚场压力钉已清理：继续清掉剩余压力钉，井系守脉体会完全暴露。")
			if definition_id == "map_object.phase_well_frame_route_blocker":
				return _success("井纹架侧路已清理：边缕残条回收线打开，另一侧路可以保留为未选路线。")
			if definition_id == "map_object.well_ash_crust_blocker":
				return _success("井底余烬壳已清理：井壁余烬回收线打开。")
			if definition_id == "map_object.pressure_clearance_node":
				return _success("前线压力扰点已清除：带回压力清障回执，回基地用基础反应器解析防护收益。")
			return _success("地块已清理。")
		"inspect":
			if _is_persistent_field_reading(definition_id):
				world_state.set_map_object_flag(instance_id, "is_sampled", true)
				return _success(_format_field_reading_result(definition_id, world_state))
			return _success("交互完成。")
		_:
			return _success("交互完成。")


func _interact_with_outpost_core(character_state: CharacterState, world_state: WorldState) -> Dictionary:
	if not world_state.quest_state.has_completed_quest("quest.restore_outpost"):
		return _success("前哨核心已恢复，晶体矿脉区已标记。")

	var restoration := character_state.restore_vitals_to_full()
	var restored_health := float(restoration.get("restored_health", 0.0))
	var restored_protection := float(restoration.get("restored_protection", 0.0))
	if restored_health <= 0.0 and restored_protection <= 0.0:
		return _success("前哨核心已在线：生命与防护完整，可继续外出或使用相位回投台。")

	var detail := _format_outpost_core_refit_detail(
		character_state,
		restored_health,
		restored_protection
	)
	return {
		"success": true,
		"message": "前哨核心整备完成：%s。" % detail,
		"supply_feedback": {
			"title": "前哨整备完成",
			"detail": detail
		}
	}


func _gather(instance_id: String, definition: Dictionary, character_state: CharacterState, world_state: WorldState) -> Dictionary:
	var rewards := _grant_refs(definition.get("drops", []), character_state)
	var protection_drain := _apply_pollution_pressure(definition, character_state)
	world_state.set_map_object_flag(instance_id, "is_gathered", true)

	var result_parts: Array[String] = []
	if rewards.is_empty():
		result_parts.append("采集完成")
	else:
		result_parts.append("采集完成：%s" % ", ".join(rewards))
	if protection_drain > 0.0:
		result_parts.append("污染压力消耗防护 %s%s" % [
			_format_amount(protection_drain),
			_get_pollution_protection_hint(character_state)
		])

	return _success("%s。" % "；".join(result_parts))


func _sample(instance_id: String, definition: Dictionary, character_state: CharacterState, world_state: WorldState) -> Dictionary:
	var sample_refs: Array = definition.get("sample_result_refs", [])
	var rewards: Array[String] = []
	for sample_id in sample_refs:
		var definition_id := String(sample_id)
		if definition_id.is_empty():
			continue
		character_state.inventory.add_ref(definition_id, 1)
		rewards.append("%s x1" % _get_display_name(definition_id))

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
		var amount := float(ref.get("amount", 0.0))
		if reward_id.is_empty() or amount <= 0.0:
			continue

		if not reward_id.begins_with("item.") and not reward_id.begins_with("fluid.") and not reward_id.begins_with("equipment."):
			continue

		character_state.inventory.add_ref(reward_id, amount)
		rewards.append("%s x%s" % [_get_display_name(reward_id), _format_amount(amount)])
	return rewards


func _apply_pollution_pressure(definition: Dictionary, character_state: CharacterState) -> float:
	var pollution_id := String(definition.get("pollution_effect", ""))
	if pollution_id.is_empty():
		return 0.0

	var pollution_definition := data_registry.get_definition(pollution_id)
	var base_drain := 0.0
	for hazard_effect in pollution_definition.get("hazard_effects", []):
		if not hazard_effect is Dictionary:
			continue
		if String(hazard_effect.get("effect", "")) != "protection_drain":
			continue
		base_drain += float(hazard_effect.get("amount", 0.0)) * PROTOTYPE_POLLUTION_PRESSURE_MULT

	if base_drain <= 0.0:
		return 0.0

	var actual_drain := base_drain * character_state.get_pollution_drain_multiplier(data_registry)
	character_state.protection = maxf(0.0, character_state.protection - actual_drain)
	return actual_drain


func _get_pollution_protection_hint(character_state: CharacterState) -> String:
	var module_id := String(character_state.equipment.get("suit_module", ""))
	if module_id.is_empty():
		return "，未启用过滤模块"
	return "，过滤模块已降低消耗"


func _format_outpost_core_refit_detail(
	character_state: CharacterState,
	restored_health: float,
	restored_protection: float
) -> String:
	var parts: Array[String] = []
	if restored_health > 0.0:
		parts.append("生命 +%s，当前 %s / %s" % [
			_format_amount(restored_health),
			_format_amount(character_state.health),
			_format_amount(character_state.max_health)
		])
	if restored_protection > 0.0:
		parts.append("防护 +%s，当前 %s / %s" % [
			_format_amount(restored_protection),
			_format_amount(character_state.protection),
			_format_amount(character_state.max_protection)
		])
	return "；".join(parts)


func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount


func _get_display_name(definition_id: String) -> String:
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id
	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))


func _supports_interaction(definition: Dictionary, interaction_type: String) -> bool:
	var interaction_types: Array = definition.get("interaction_types", [])
	return interaction_types.has(interaction_type)


func _get_tool_requirement_error(definition: Dictionary, character_state: CharacterState) -> String:
	var required_tool_tags: Array = definition.get("required_tool_tags", [])
	if required_tool_tags.is_empty():
		return ""

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
		return ""
	return "当前工具缺少能力：%s。" % ", ".join(missing_tags)


func _get_quest_gate_error(definition_id: String, interaction_type: String, world_state: WorldState) -> String:
	if definition_id != "map_object.anomaly_crystal" or interaction_type != "sample":
		if definition_id != "map_object.anomaly_residue_patch" or interaction_type != "gather":
			return ""
		if world_state.quest_state.has_active_quest("quest.analyze_anomaly_sample"):
			return ""
		if world_state.quest_state.has_completed_quest("quest.analyze_anomaly_sample"):
			return ""
		return "异常残留点尚未纳入分析目标。"
	if world_state.quest_state.has_active_quest("quest.bring_back_sample"):
		return ""
	if world_state.quest_state.has_completed_quest("quest.bring_back_sample"):
		return ""
	return "异常晶体采样通道尚未校准。"


func _get_quest_gate_detail(definition_id: String, interaction_type: String) -> String:
	if definition_id == "map_object.anomaly_crystal" and interaction_type == "sample":
		return "先完成反应器校准件，再按任务目标采样异常晶体。"
	if definition_id == "map_object.anomaly_residue_patch" and interaction_type == "gather":
		return "先带回异常晶体样本，再按分析任务回收周边残留物。"
	return "先完成当前前置目标，再回来处理这个目标。"


func _is_already_processed(object_state: Dictionary, interaction_type: String) -> bool:
	match interaction_type:
		"gather":
			return bool(object_state.get("is_gathered", false))
		"sample":
			return bool(object_state.get("is_sampled", false))
		"inspect":
			return bool(object_state.get("is_sampled", false))
		"clear":
			return bool(object_state.get("is_cleared", false))
		_:
			return false


func _is_persistent_field_reading(definition_id: String) -> bool:
	return (
		definition_id == "map_object.phase_splinter_resonance_node"
		or definition_id == "map_object.fault_residue_pulse_node"
		or definition_id == "map_object.well_flux_pressure_vent"
		or definition_id == "map_object.phase_well_chamber_shunt_node"
		or definition_id == "map_object.phase_well_loom_tension_spool"
		or definition_id == "map_object.phase_well_tether_knot_node"
	)


func _format_field_reading_result(definition_id: String, world_state: WorldState) -> String:
	var result: Dictionary = FIELD_READING_RESULTS.get(definition_id, {})
	if result.is_empty():
		return "现场读数已写入。"
	var quest_id := String(result.get("quest_id", ""))
	var objective_type := String(result.get("objective_type", "inspect"))
	var target_id := String(result.get("target_id", definition_id))
	var required := float(result.get("required", 1.0))
	var current := world_state.quest_state.get_objective_progress(quest_id, objective_type, target_id)
	var next_progress := minf(required, current + 1.0)
	var suffix := String(result.get("partial", "继续检查剩余现场读数点。"))
	if next_progress >= required:
		suffix = String(result.get("complete", "现场读数已全部写入。"))
	return "%s已写入：%s/%s；%s" % [
		String(result.get("step", "现场读数")),
		_format_amount(next_progress),
		_format_amount(required),
		suffix
	]


func _success(message: String) -> Dictionary:
	return {
		"success": true,
		"message": message
	}


func _failure(message: String, title: String = "交互未完成", detail: String = "") -> Dictionary:
	return {
		"success": false,
		"message": message,
		"failure_feedback": {
			"title": title,
			"detail": detail
		}
	}
