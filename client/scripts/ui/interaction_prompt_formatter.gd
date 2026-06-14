extends RefCounted
class_name InteractionPromptFormatter

var data_registry: DataRegistry
var processing_system: ProcessingSystem
var build_system: BuildSystem

const FIELD_READING_PROMPTS := {
	"map_object.phase_splinter_resonance_node": {
		"quest_id": "quest.trace_phase_splinters",
		"objective_type": "inspect",
		"target_id": "map_object.phase_splinter_resonance_node",
		"required": 2.0,
		"title": "裂相共振读数",
		"effect": "两点读数写完后，裂相碎屑回收线才会稳定。"
	},
	"map_object.fault_residue_pulse_node": {
		"quest_id": "quest.collect_fault_residue",
		"objective_type": "inspect",
		"target_id": "map_object.fault_residue_pulse_node",
		"required": 2.0,
		"title": "故障脉冲读数",
		"effect": "两处脉冲读完后，故障残渣回收线才会显形。"
	},
	"map_object.well_flux_pressure_vent": {
		"quest_id": "quest.collect_well_flux",
		"objective_type": "inspect",
		"target_id": "map_object.well_flux_pressure_vent",
		"required": 2.0,
		"title": "回声泄压阀",
		"effect": "两处泄压完成后，回声碎屑回收线才会稳定。"
	},
	"map_object.phase_well_chamber_shunt_node": {
		"quest_id": "quest.collect_heart_spine",
		"objective_type": "inspect",
		"target_id": "map_object.phase_well_chamber_shunt_node",
		"required": 2.0,
		"title": "碎晶分流读数",
		"effect": "两处分流写完后，心棘残片才会从脉冲里露出。"
	},
	"map_object.phase_well_loom_tension_spool": {
		"quest_id": "quest.collect_weft_bundle",
		"objective_type": "inspect",
		"target_id": "map_object.phase_well_loom_tension_spool",
		"required": 2.0,
		"title": "风蚀张力绕轮",
		"effect": "两处张力确认后，纬束残团回收线才会稳定。"
	},
	"map_object.phase_well_tether_knot_node": {
		"quest_id": "quest.collect_tether_fiber",
		"objective_type": "inspect",
		"target_id": "map_object.phase_well_tether_knot_node",
		"required": 2.0,
		"title": "锚定桥结点",
		"effect": "两端结点确认后，锚索残股才会从桥体边缘松开。"
	}
}

const FRONTLINE_ACTION_TARGET_PROMPTS := {
	"map_object.stability_echo_probe": {
		"quest_id": "quest.survey_stability_echo_probe",
		"objective_type": "inspect",
		"target_ids": ["map_object.stability_echo_probe"],
		"title": "稳窗回波探点",
		"status": "未读取，本趟稳窗回访只要求确认这一处探点。",
		"effect": "读取后回基地使用基础反应器解析前线行动回报。",
		"action": "按 E 读取稳窗回波样本"
	},
	"map_object.supply_return_marker": {
		"quest_id": "quest.inspect_supply_return_marker",
		"objective_type": "inspect",
		"target_ids": ["map_object.supply_return_marker"],
		"title": "补给回执标记",
		"status": "未读取，本趟补给短行动只要求确认这一处回执标记。",
		"effect": "读取后回基地使用基础反应器解析短行动反馈。",
		"action": "按 E 读取补给回执"
	},
	"map_object.route_signal_marker": {
		"quest_id": "quest.inspect_route_signal_marker",
		"objective_type": "inspect",
		"target_ids": ["map_object.route_signal_marker"],
		"title": "巡线信标",
		"status": "未读取，本趟巡线短行动只要求确认这一处巡线信标。",
		"effect": "读取后回基地使用基础反应器解析巡线反馈。",
		"action": "按 E 读取巡线信标"
	},
	"map_object.steady_supply_drop_marker": {
		"quest_id": "quest.inspect_steady_supply_drop",
		"objective_type": "inspect",
		"target_ids": ["map_object.steady_supply_drop_marker"],
		"title": "稳场补给投放点",
		"status": "未读取，补给回执还没有带回基地。",
		"effect": "读取后回基地使用基础反应器解析稳场补给反馈。",
		"action": "按 E 读取补给回执"
	},
	"map_object.phase_survey_node_west": {
		"quest_id": "quest.inspect_phase_survey_nodes",
		"objective_type": "inspect",
		"target_ids": ["map_object.phase_survey_node_west", "map_object.phase_survey_node_east"],
		"title": "西侧相位测绘点",
		"status": "未写入，测绘记录需要西侧和东侧两处读数。",
		"effect": "两处读数完成后回基地解析相位测绘反馈，换取路线提示。",
		"action": "按 E 写入测绘读数"
	},
	"map_object.phase_survey_node_east": {
		"quest_id": "quest.inspect_phase_survey_nodes",
		"objective_type": "inspect",
		"target_ids": ["map_object.phase_survey_node_west", "map_object.phase_survey_node_east"],
		"title": "东侧相位测绘点",
		"status": "未写入，测绘记录需要西侧和东侧两处读数。",
		"effect": "两处读数完成后回基地解析相位测绘反馈，换取路线提示。",
		"action": "按 E 写入测绘读数"
	},
	"map_object.pressure_clearance_node": {
		"quest_id": "quest.clear_pressure_frontline_hazard",
		"objective_type": "clear",
		"target_ids": ["map_object.pressure_clearance_node"],
		"title": "前线压力扰点",
		"status": "未清理，高压扰动仍压着锚定桥前线；清障扰动守卫也需要先击退。",
		"effect": "击退守卫并清除扰点后回基地使用基础反应器解析压力清障反馈，换取防护整备。",
		"action": "按 E 清理压力扰点",
		"requires_tool": true
	}
}


func _init(registry: DataRegistry, processing: ProcessingSystem, builder: BuildSystem) -> void:
	data_registry = registry
	processing_system = processing
	build_system = builder


func format_general_interaction_prompt(
	interactable: PrototypeInteractable,
	character_state: CharacterState,
	world_state: WorldState
) -> String:
	var title := _get_display_name(interactable.definition_id)
	var definition := data_registry.get_definition(interactable.definition_id)
	var object_state := world_state.get_map_object(interactable.instance_id)
	var parts: Array[String] = ["对象：%s" % title]
	parts.append("用途：%s" % _get_general_interaction_purpose(interactable, definition))
	var reward_line := _format_interaction_reward_line(interactable, definition)
	if not reward_line.is_empty():
		parts.append(reward_line)
	parts.append("状态：%s" % _get_general_interaction_status(interactable, object_state, character_state, world_state))
	var next_step_line := _get_general_interaction_next_step(interactable, object_state, character_state, world_state)
	if not next_step_line.is_empty():
		parts.append("下一步：%s" % next_step_line)
	var action_line := _get_general_interaction_action(interactable, object_state, character_state, world_state)
	if not action_line.is_empty():
		parts.append("操作：%s" % action_line)
	return "\n".join(parts)


func format_outfitting_station_prompt(character_state: CharacterState, world_state: WorldState) -> String:
	if not world_state.has_base_structure_definition("building.field_outfitting_station"):
		return "设施：%s\n用途：把基地制造出的模块装入防护服，让外勤承压差异从 HUD 提示变成可操作整备。\n状态：未建成。\n下一步：先完成基地平台的出发整备台建造点。" % _get_display_name("building.field_outfitting_station")

	var parts: Array[String] = [DepartureReadinessFormatter.format_outfitting_station_prompt(world_state, character_state)]
	if FieldOutfittingRuntime.has_filter_module_equipped(character_state):
		var drain_mult := (
			character_state.get_pollution_drain_multiplier(data_registry)
			* FieldOutfittingRuntime.get_pollution_drain_multiplier(character_state, world_state)
		)
		var counter_mult := (
			character_state.get_pollution_counter_damage_multiplier(data_registry)
			* FieldOutfittingRuntime.get_pollution_counter_damage_multiplier(character_state, world_state)
		)
		parts.append("防护服：污染消耗 x%.2f；污染反击 x%.2f。" % [drain_mult, counter_mult])
		if (
			FieldOutfittingRuntime.is_core_archive_maintenance_available(character_state, world_state)
			and not FieldOutfittingRuntime.is_core_archive_maintained(world_state)
		):
			parts.append("核心归档：可把核心稳定数据接入基础过滤模块维护。")
			parts.append("操作：E 接入核心归档维护")
			return "\n".join(parts)
		if FieldOutfittingRuntime.is_core_archive_maintained(world_state):
			parts.append("核心归档：维护已接入，污染采集和污染反击承压继续下降。")
		if FieldOutfittingRuntime.should_confirm_logistics_maintenance(character_state, world_state):
			parts.append("后勤维护：补料已加工成基础零件，待出发整备台确认。")
			parts.append("操作：E 确认后勤维护")
			return "\n".join(parts)
		if FieldOutfittingRuntime.is_module_calibrated(world_state):
			parts.append("维护：晶体校准已写入，污染采集和污染反击承压继续下降。")
			parts.append("操作：E 检查整备状态")
			return "\n".join(parts)
		if FieldOutfittingRuntime.has_calibration_materials(character_state):
			parts.append("维护：可消耗晶体矿 x%d / 残骸废件 x%d 校准过滤模块。" % [
				FieldOutfittingRuntime.MODULE_CALIBRATION_CRYSTAL_COST,
				FieldOutfittingRuntime.MODULE_CALIBRATION_SCRAP_COST
			])
			parts.append("操作：E 校准基础过滤模块")
			return "\n".join(parts)
		parts.append("下一步：回晶体侧路补晶体矿和残骸废件，再回整备台维护校准。")
		parts.append("操作：E 查看缺料")
		return "\n".join(parts)

	if character_state.inventory.has_ref(FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID, 1):
		parts.append("操作：E 装配基础过滤模块")
		return "\n".join(parts)

	parts.append("下一步：用基础反应器组装基础过滤模块，再回整备台装入防护服。")
	parts.append("操作：E 查看缺料")
	return "\n".join(parts)


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
	var next_step := String(status.get("next_step", ""))
	if not next_step.is_empty():
		parts.append("下一步：%s" % next_step)
	if bool(status.get("can_build", false)):
		parts.append("操作：按 E 建造")
	return "\n".join(parts)


func format_clear_prompt(
	interactable: PrototypeInteractable,
	character_state: CharacterState,
	world_state: WorldState
) -> String:
	var object_state := world_state.get_map_object(interactable.instance_id)
	if interactable.definition_id == "map_object.well_ash_crust_blocker":
		if bool(object_state.get("is_cleared", false)):
			return "盐壳硬壳：已清理，盐壳余烬回收线保持打开。"
		var ash_tool_status := _get_interaction_tool_status(interactable.definition_id, character_state)
		var ash_parts: Array[String] = [
			"清障：%s" % _get_display_name(interactable.definition_id),
			"状态：未清理，盐壳余烬被余烬壳压住。",
			"后续：清掉两处余烬壳，再处理盐壳潜伏体和盐壳余烬。",
			"工具：%s" % ash_tool_status
		]
		if ash_tool_status == "可清理":
			ash_parts.append("按 E 清理余烬壳")
		return "\n".join(ash_parts)
	if interactable.definition_id == "map_object.phase_well_frame_route_blocker":
		if bool(object_state.get("is_cleared", false)):
			return "锁相框架侧路障：已清理，边缕残条回收线保持打开。"
		var frame_tool_status := _get_interaction_tool_status(interactable.definition_id, character_state)
		var frame_parts: Array[String] = [
			"侧路：%s" % _get_display_name(interactable.definition_id),
			"状态：未清理，边缕残条回收线不稳定。",
			"后续：任选一条侧路清理，再回收两处边缕残条。",
			"工具：%s" % frame_tool_status
		]
		if frame_tool_status == "可清理":
			frame_parts.append("按 E 清理侧路")
		return "\n".join(frame_parts)
	if interactable.definition_id == "map_object.phase_well_anchor_pressure_pin":
		if bool(object_state.get("is_cleared", false)):
			return "锚场压力钉：已清理，回稳压制正在转向稳场守脉体。"
		var pin_tool_status := _get_interaction_tool_status(interactable.definition_id, character_state)
		var pin_parts: Array[String] = [
			"压力钉：%s" % _get_display_name(interactable.definition_id),
			"状态：未清理，稳场守脉体还没有完全暴露。",
			"后续：清掉两处压力钉，再压制稳场守脉体。",
			"工具：%s" % pin_tool_status
		]
		if pin_tool_status == "可清理":
			pin_parts.append("按 E 清理压力钉")
		return "\n".join(pin_parts)
	if interactable.definition_id == "map_object.pressure_clearance_node":
		return format_frontline_action_target_prompt(interactable, character_state, world_state)
	if bool(object_state.get("is_cleared", false)):
		return "地块：%s\n状态：已清理，可用于铺设基础地基。" % _get_display_name(interactable.definition_id)

	var tool_status := _get_interaction_tool_status(interactable.definition_id, character_state)
	var parts: Array[String] = [
		"地块：%s" % _get_display_name(interactable.definition_id),
		"状态：未清理，阻挡建造。",
		"下一步：清理后可铺设基础地基。",
		"工具：%s" % tool_status
	]
	if tool_status == "可清理":
		parts.append("操作：按 E 清理地块")
	return "\n".join(parts)


func can_format_base_action_prompt(definition_id: String) -> bool:
	return BaseActionDispatchPlan.is_action_console(definition_id)


func format_base_action_prompt(
	interactable: PrototypeInteractable,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	return BaseActionDispatchPlan.format_console_prompt(
		interactable.definition_id,
		world_state,
		character_state
	)


func can_format_field_reading_prompt(definition_id: String) -> bool:
	return FIELD_READING_PROMPTS.has(definition_id)


func can_format_stability_calibration_prompt(definition_id: String) -> bool:
	return PhaseWellFrontierRuntime.new(data_registry).is_stability_calibration_node(definition_id)


func can_format_frontline_action_target_prompt(definition_id: String) -> bool:
	return FRONTLINE_ACTION_TARGET_PROMPTS.has(definition_id) or BaseActionDispatchPlan.is_frontline_window_object(definition_id)


func format_frontline_action_target_prompt(
	interactable: PrototypeInteractable,
	character_state: CharacterState,
	world_state: WorldState
) -> String:
	if BaseActionDispatchPlan.is_frontline_window_object(interactable.definition_id):
		return BaseActionDispatchPlan.format_frontline_window_prompt(world_state)
	var prompt: Dictionary = FRONTLINE_ACTION_TARGET_PROMPTS.get(interactable.definition_id, {})
	if prompt.is_empty():
		return "按 E 交互：%s" % _get_display_name(interactable.definition_id)

	var title := String(prompt.get("title", _get_display_name(interactable.definition_id)))
	var object_state := world_state.get_map_object(interactable.instance_id)
	var is_cleared := bool(object_state.get("is_cleared", false))
	var quest_id := String(prompt.get("quest_id", ""))
	var objective_type := String(prompt.get("objective_type", "inspect"))
	var target_ids: Array = prompt.get("target_ids", [interactable.definition_id])
	var required := float(target_ids.size())
	var current := 0.0
	for target_id in target_ids:
		current += world_state.quest_state.get_objective_progress(quest_id, objective_type, String(target_id))
	if world_state.quest_state.has_completed_quest(quest_id):
		current = required
	if is_cleared:
		current = required
	var progress := "%s/%s" % [_format_amount(current), _format_amount(required)]
	if current >= required:
		return "%s：已完成；下一步回基地用基础反应器解析反馈，再到前线行动台确认整备槽。" % title

	var parts: Array[String] = [
		"目标：%s" % title,
		"状态：%s 当前进度 %s。" % [String(prompt.get("status", "未完成。")), progress],
		"后续：%s" % String(prompt.get("effect", "完成后回基地解析反馈。"))
	]
	if bool(prompt.get("requires_tool", false)):
		var tool_status := _get_interaction_tool_status(interactable.definition_id, character_state)
		parts.append("工具：%s" % tool_status)
		if tool_status == "可清理":
			parts.append(String(prompt.get("action", "按 E 交互")))
	else:
		parts.append(String(prompt.get("action", "按 E 交互")))
	return "\n".join(parts)


func format_field_reading_prompt(interactable: PrototypeInteractable, world_state: WorldState) -> String:
	var prompt: Dictionary = FIELD_READING_PROMPTS.get(interactable.definition_id, {})
	if prompt.is_empty():
		return "按 E 交互：%s" % _get_display_name(interactable.definition_id)

	var title := String(prompt.get("title", _get_display_name(interactable.definition_id)))
	var object_state := world_state.get_map_object(interactable.instance_id)
	if bool(object_state.get("is_sampled", false)):
		return "%s：已写入；继续检查剩余现场读数点。" % title

	var quest_id := String(prompt.get("quest_id", ""))
	var objective_type := String(prompt.get("objective_type", "inspect"))
	var target_id := String(prompt.get("target_id", interactable.definition_id))
	var required := float(prompt.get("required", 1.0))
	var current := world_state.quest_state.get_objective_progress(quest_id, objective_type, target_id)
	if world_state.quest_state.has_completed_quest(quest_id):
		current = required
	var progress := "%s/%s" % [_format_amount(current), _format_amount(required)]
	var parts: Array[String] = [
		"读数：%s" % title,
		"状态：未写入，当前进度 %s。" % progress,
		"作用：%s" % String(prompt.get("effect", "写入后会推进当前现场目标。")),
		"按 E 写入读数"
	]
	return "\n".join(parts)


func format_stability_calibration_prompt(
	interactable: PrototypeInteractable,
	character_state: CharacterState,
	world_state: WorldState
) -> String:
	var runtime := PhaseWellFrontierRuntime.new(data_registry)
	var title := _get_display_name(interactable.definition_id)
	if runtime.is_stability_node_calibrated(world_state, interactable.instance_id, interactable.definition_id):
		if world_state.quest_state.has_completed_quest("quest.calibrate_phase_well_stability_window"):
			return "%s：已校准；三处稳窗节点已按序写入，回基地在前线行动台确认稳窗回访。" % title
		return "%s：已校准；继续检查剩余稳窗节点。" % title
	if not world_state.quest_state.has_completed_quest("quest.analyze_phase_well_echo_shard"):
		return "%s：缺少稳窗读数；先回基地解析稳窗余响片。" % title
	if not character_state.inventory.has_ref("item.phase_well_stability_readout", 1):
		return "%s：缺少稳窗读数；确认余响片解析产物已放入背包，再返回锚定桥东侧。" % title
	if not runtime.is_stability_calibration_ready(world_state, interactable.definition_id):
		return "%s：相位序未对齐；先按西侧、中央、东侧顺序写入稳窗读数。" % title
	var next_step := "完成后继续按西侧、中央、东侧顺序检查下一处节点。"
	if interactable.definition_id == "map_object.phase_well_stability_node_east":
		next_step = "完成后回基地，在前线行动台确认稳窗回访；本趟只派发稳窗回波探点。"
	return "按 E 校准：%s\n顺序：西侧、中央、东侧。\n后续：%s" % [title, next_step]


func format_outpost_core_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if not world_state.quest_state.has_completed_quest("quest.restore_outpost"):
		return "按 E 恢复：前哨核心，重启基础导航。"
	return DepartureReadinessFormatter.format_outpost_core_prompt(world_state, character_state)


func format_ruin_gate_prompt(world_state: WorldState, character_state: CharacterState = null) -> String:
	if not world_state.quest_state.has_completed_quest("quest.defeat_elite_node"):
		return "封锁遗迹入口：先压制污染残核，再确认更深区域信号。"
	if world_state.quest_state.has_completed_quest("quest.unlock_ruin_signal"):
		return "遗迹外圈已开放：继续向东进入外圈，回收继电残片，并处理外圈前污染脊压力。"
	if _is_gate_pressure_active(world_state):
		return "封锁遗迹入口：门前受扰敌人仍在压制；带药剂回污染边界，清理门前压力点后再确认入口信号。"
	return RuinGateReadinessFormatter.format_ready_prompt(character_state)


func format_outer_ring_barrier_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.stabilize_outer_ring_barrier"):
		return "抖动雾幕：已稳定，可继续向东检查外圈中继台。"
	if not world_state.quest_state.has_completed_quest("quest.assemble_phase_anchor"):
		return "抖动雾幕：先回基地组装稳相信标，再返回部署。"
	if not character_state.inventory.has_ref("item.phase_anchor", 1):
		return "抖动雾幕：缺少稳相信标；回基地把继电残片、污染浆液和基础零件组装后再来。"
	return "按 E 部署：稳相信标，稳定抖动雾幕。"


func format_outer_ring_console_prompt(world_state: WorldState) -> String:
	if not world_state.quest_state.has_completed_quest("quest.stabilize_outer_ring_barrier"):
		return "外圈中继台：先稳定抖动雾幕，再进入外圈深段。"
	if world_state.quest_state.has_completed_quest("quest.secure_outer_ring_signal"):
		return "外圈中继台：数据已读取，裂相结构坐标已保留。"
	return "按 E 检查：外圈中继台。"


func format_signal_echo_cache_prompt(world_state: WorldState) -> String:
	if not world_state.quest_state.has_completed_quest("quest.secure_outer_ring_signal"):
		return "外圈回波匣：先检查外圈中继台，锁定稳定回波。"
	if world_state.quest_state.has_completed_quest("quest.salvage_signal_echo"):
		return "外圈回波匣：已回收，回基地解析深段回波。"
	if world_state.quest_state.has_active_quest("quest.salvage_signal_echo"):
		if not bool(world_state.get_enemy("enemy_instance.ruin_phase_guard").get("is_defeated", false)):
			return "外圈回波匣：相位守卫仍在压制；先清理守卫。"
		if world_state.quest_state.get_objective_progress("quest.salvage_signal_echo", "gather_item", "item.polluted_residue") < 2.0:
			return "外圈回波匣：先回收守卫后暴露的污染回波沉积，再回过滤器处理副产。"
	return "按 E 回收：外圈回波匣。"


func format_deep_ruin_door_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.unlock_deep_ruin_entrance"):
		return "裂相脊入口门禁：已写入，可继续向东进入裂相脊。"
	if not world_state.quest_state.has_completed_quest("quest.analyze_deep_signal"):
		return "裂相脊入口门禁：先回基地解析深段回波，拿到裂相坐标。"
	if not character_state.inventory.has_ref("item.deep_ruin_coordinates", 1):
		return "裂相脊入口门禁：缺少裂相坐标；回基地确认基础反应器解析结果后再来。"
	return "按 E 写入：裂相坐标，打开裂相脊入口。"


func format_deep_ruin_latch_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.unlock_deep_ruin_cache"):
		return "裂相锁扣：已覆写，裂相样块已回收。"
	if not world_state.quest_state.has_completed_quest("quest.assemble_deep_override"):
		return "裂相锁扣：先回基地精炼相位纤丝并组装裂相覆写栓。"
	if not character_state.inventory.has_ref("item.deep_override_key", 1):
		return "裂相锁扣：缺少裂相覆写栓；回过滤器精炼纤丝，再去反应器组装。"
	return "按 E 覆写：裂相锁扣。"


func format_deep_signal_array_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.activate_deep_array"):
		return "裂相阵列台：已点亮，第二轮导管回收线已暴露。"
	if not world_state.quest_state.has_completed_quest("quest.analyze_deep_core"):
		return "裂相阵列台：先回基地解析裂相样块，整理出路由印片。"
	if not character_state.inventory.has_ref("item.deep_route_imprint", 1):
		return "裂相阵列台：缺少裂相路由印片；回基地确认基础反应器解析结果后再来。"
	return "按 E 写入：裂相路由印片，点亮裂相阵列台。"


func format_phase_return_anchor_prompt(
	world_state: WorldState,
	character_state: CharacterState,
	anchor_instance_id: String = ""
) -> String:
	if world_state.quest_state.has_completed_quest("quest.deploy_phase_relay_anchor"):
		var recalibration_hint := ""
		if not anchor_instance_id.is_empty() and world_state.has_deployed_phase_relay_anchor(anchor_instance_id):
			if not world_state.is_active_phase_relay_anchor(anchor_instance_id):
				recalibration_hint = "；回传后会把基地当前落点切回这里"
		if world_state.quest_state.has_active_quest("quest.reenter_phase_frontline"):
			return "按 E 回传：前线回传锚点，返回基地相位回投台，再从回投台重返更东侧裂相脊%s。" % recalibration_hint
		return "按 E 回传：前线回传锚点，快速返回基地相位回投台%s。" % recalibration_hint
	if not world_state.quest_state.has_completed_quest("quest.assemble_deep_signal_matrix"):
		return "前线回传锚点：先回基地整理深段读数矩阵，再返回深段部署。"
	if not character_state.inventory.has_ref("item.deep_signal_matrix", 1):
		return "前线回传锚点：缺少深段读数矩阵；回基地确认基础反应器整理结果后再来。"
	return "按 E 部署：深段读数矩阵，激活前线回传锚点。"


func format_phase_relay_pad_prompt(world_state: WorldState) -> String:
	if not world_state.quest_state.has_completed_quest("quest.deploy_phase_relay_anchor"):
		return "相位回投台：先在深段部署前线回传锚点，再回来回投。"
	if not world_state.has_active_phase_relay_anchor():
		return "相位回投台：前线锚点当前离线；返回深段重新校准后再尝试。"
	var active_anchor_label := _format_phase_relay_anchor_label(world_state.active_phase_relay_anchor_id)
	var cycle_hint := ""
	if world_state.get_deployed_phase_relay_anchor_count() > 1:
		cycle_hint = "；按 R 切换已部署落点"
	var preparation_hint := BaseActionDispatchPlan.format_departure_preparation_prompt(world_state)
	if not preparation_hint.is_empty():
		preparation_hint = "。%s" % preparation_hint
	if world_state.quest_state.has_active_quest("quest.reenter_phase_frontline"):
		return "相位回投台：当前落点 %s%s。按 E 回投并继续追踪更东侧裂相碎屑%s。" % [active_anchor_label, cycle_hint, preparation_hint]
	return "相位回投台：当前落点 %s%s。按 E 回投到该前线回传锚点%s。" % [active_anchor_label, cycle_hint, preparation_hint]


func format_phase_fault_spire_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.inspect_phase_fault_spire"):
		return "裂相尖塔：已校准，第一份内层故障轨迹已带回基地；下一步回基地解析更东侧裂相锁位。"
	if not (
		world_state.quest_state.has_completed_quest("quest.refine_phase_splinters")
		or world_state.quest_state.has_completed_quest("quest.tune_relay_lens")
	):
		return "裂相尖塔：先回基地完成中继调谐镜整备，再回来校准内层回波。"
	if not character_state.inventory.has_ref("item.relay_tuning_lens", 1):
		return "裂相尖塔：缺少中继调谐镜；回基地确认基础反应器组装结果后再来。"
	return "按 E 校准：裂相尖塔，带回内层故障轨迹。"


func format_phase_well_lock_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.unlock_phase_well"):
		return "裂相锁位：已钉住，第一份回声定位器已带回基地；下一步回基地解析定位器。"
	if not (world_state.quest_state.has_completed_quest("quest.refine_fault_residue") or world_state.quest_state.has_completed_quest("quest.assemble_phase_well_key")):
		return "裂相锁位：先回基地完成裂相锁钥整备，再回来钉住锁位。"
	if not character_state.inventory.has_ref("item.phase_well_key", 1):
		return "裂相锁位：缺少裂相锁钥；回基地确认基础反应器组装结果后再来。"
	return "按 E 锁定：裂相锁位，带回回声定位器。"


func format_inner_phase_well_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.inspect_inner_phase_well"):
		return "回声台地：回声芯样本已带回；先回基地解析这份样本，再回来继续推进更东侧盐壳浅滩。"
	if not (world_state.quest_state.has_completed_quest("quest.refine_well_flux") or world_state.quest_state.has_completed_quest("quest.assemble_phase_well_probe")):
		return "回声台地：先回基地完成回声探针整备，再回来读取回声芯样本。"
	if not character_state.inventory.has_ref("item.phase_well_probe", 1):
		return "回声台地：缺少回声探针；回基地确认基础反应器组装结果后再来。"
	return "按 E 勘验：回声台地。"


func format_phase_well_sink_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.inspect_phase_well_sink"):
		return "盐壳浅滩：已凿开，第一份碎晶心核已带回基地；下一步回基地解析并继续推进碎晶沟谷断面。"
	if not _has_completed_any(world_state, ["quest.refine_well_ash", "quest.assemble_phase_well_pike"]):
		return "盐壳浅滩：先回基地完成盐壳整备，把盐壳穿钉带回来凿开更东侧裂口。"
	if not character_state.inventory.has_ref("item.phase_well_pike", 1):
		return "盐壳浅滩：缺少盐壳穿钉；回基地确认基础反应器组装结果后再来。"
	return "按 E 凿开：盐壳浅滩。"


func format_phase_well_chamber_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.inspect_phase_well_chamber"):
		return "碎晶沟谷断面：已勘验，第一份风蚀张力核已带回基地；下一步回基地解析并继续推进风蚀管廊断面。"
	if not _has_completed_any(world_state, ["quest.refine_heart_spine", "quest.assemble_phase_well_shunt"]):
		return "碎晶沟谷断面：先回基地完成碎晶整备，把碎晶分流栓带回来勘验更东侧断面。"
	if not character_state.inventory.has_ref("item.phase_well_shunt", 1):
		return "碎晶沟谷断面：缺少碎晶分流栓；回基地确认基础反应器组装结果后再来。"
	return "按 E 勘验：碎晶沟谷断面。"


func format_phase_well_loom_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.inspect_phase_well_loom"):
		return "风蚀管廊断面：已勘验，第一份锁相织构核已带回基地；下一步回基地解析并继续推进锁相框架断面。"
	if not _has_completed_any(world_state, ["quest.refine_weft_bundle", "quest.assemble_phase_well_shuttle"]):
		return "风蚀管廊断面：先回基地完成风蚀整备，把风蚀梭栓带回来勘验更东侧断面。"
	if not character_state.inventory.has_ref("item.phase_well_shuttle", 1):
		return "风蚀管廊断面：缺少风蚀梭栓；回基地确认基础反应器组装结果后再来。"
	return "按 E 勘验：风蚀管廊断面。"


func format_phase_well_frame_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.inspect_phase_well_frame"):
		return "锁相框架断面：已勘验，第一份锚定结核已带回基地；下一步回基地解析并继续推进锚定桥断面。"
	if not _has_completed_any(world_state, ["quest.refine_selvedge_strip", "quest.assemble_phase_well_frame_key"]):
		return "锁相框架断面：先回基地完成锁相框架整备，把锁相键栓带回来勘验更东侧断面。"
	if not character_state.inventory.has_ref("item.phase_well_frame_key", 1):
		return "锁相框架断面：缺少锁相键栓；回基地确认基础反应器组装结果后再来。"
	return "按 E 勘验：锁相框架断面。"


func format_phase_well_tether_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.inspect_phase_well_tether"):
		return "锚定桥断面：已勘验，第一份稳场锚核已带回基地；下一步回基地完成锚场整备。"
	if not _has_completed_any(world_state, ["quest.refine_tether_fiber", "quest.assemble_phase_well_tether_spike"]):
		return "锚定桥断面：先回基地完成锚定桥整备，把锚定桩带回来勘验更东侧断面。"
	if not character_state.inventory.has_ref("item.phase_well_tether_spike", 1):
		return "锚定桥断面：缺少锚定桩；回基地确认基础反应器组装结果后再来。"
	return "按 E 勘验：锚定桥断面。"


func format_phase_well_anchor_field_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	var object_state := world_state.get_map_object("map_object_instance.phase_well_anchor_field")
	var deployed := bool(object_state.get("anchor_field_deployed", false))
	var pressure_cleared := bool(object_state.get("anchor_field_pressure_cleared", false))
	var stabilized := bool(object_state.get("anchor_field_stabilized", false)) or world_state.quest_state.has_completed_quest("quest.stabilize_phase_well_anchor_field")
	if stabilized:
		if (
			world_state.quest_state.has_completed_quest("quest.analyze_phase_well_echo_shard")
			or character_state.inventory.has_ref("item.phase_well_stability_readout", 1)
		):
			return "按 E 回充：稳窗读数已解析，锚场回稳窗可在前线恢复生命与防护；之后按序校准三处稳窗节点。"
		return "锚场回稳窗：局部稳定窗口已维持；回基地解析稳窗余响片后，可把这里校准成前线回稳点。"
	if not _has_completed_any(world_state, ["quest.refine_anchor_core_dust", "quest.assemble_phase_well_anchor_stake"]):
		return "锚场回稳窗：先回基地完成锚场整备，把稳场校锚桩带回来部署。"
	if not deployed:
		if not character_state.inventory.has_ref("item.phase_well_anchor_stake", 1):
			return "锚场回稳窗：缺少稳场校锚桩；回基地确认基础反应器组装结果后再来。"
		return "按 E 部署：锚场回稳窗。"
	if not pressure_cleared:
		if not _has_anchor_field_pressure_pins_cleared(world_state):
			return "锚场回稳窗：回稳中；先清掉两处压力钉，再压制稳场守脉体。校锚桩会保留在现场，失败后可直接重试。"
		return "锚场回稳窗：回稳中；先清掉稳场守脉体，再回来收束稳定窗口。校锚桩会保留在现场，失败后可直接重试。"
	return "按 E 收束：锚场回稳窗。"


func format_pollution_entry_warning(character_state: CharacterState) -> String:
	var warnings: Array[String] = []
	if character_state.protection < character_state.max_protection * 0.5:
		warnings.append("防护偏低，建议先按 2 使用抗污染药剂或返回基地补给。")
	if String(character_state.equipment.get("suit_module", "")).is_empty():
		warnings.append("未启用过滤模块，按 F 启用后污染消耗会降低。")
	if warnings.is_empty():
		return ""
	return "污染边界警告：%s" % " ".join(warnings)


func format_pollution_gate_hint(world_state: WorldState, character_state: CharacterState) -> String:
	var missing_steps: Array[String] = []
	if not world_state.quest_state.has_completed_quest("quest.expand_treatment_point"):
		missing_steps.append("先完成处理点扩建")
	if String(character_state.equipment.get("suit_module", "")).is_empty():
		missing_steps.append("按 F 启用基础过滤模块")
	if character_state.protection < character_state.max_protection * 0.5:
		missing_steps.append("按 2 使用抗污染药剂或回基地补给")
	if missing_steps.is_empty():
		return "重新靠近边界后会再次检查通行状态。"
	return "需要：%s。" % "；".join(missing_steps)


func format_region_gate_blocked_log(message: String, next_step: String) -> String:
	if next_step.strip_edges().is_empty():
		return "通行受阻：%s" % message
	return "通行受阻：%s 下一步：%s" % [message, next_step]


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


func _get_general_interaction_purpose(interactable: PrototypeInteractable, definition: Dictionary) -> String:
	if interactable.definition_id == "map_object.outpost_departure_gate":
		return "汇总前哨核心补给、出发整备台模块和地图目标，作为外勤前最后检查。"
	if interactable.definition_id == "map_object.outpost_logistics_route_sign":
		return "把前哨核心、储存箱、浆液缓冲罐、出发整备台和外勤出发口读成一条出发准备路线。"
	if interactable.definition_id == "map_object.demo_stabilization_core":
		return "写入归档数据；侧边补给、缓冲回写、药剂和守卫缓存会改变核心设备承压。"
	if interactable.definition_id == CoreStabilizationPressureFormatter.RETEST_READOUT_DEFINITION_ID:
		return "回收核心设备完成态后的复测读数和可用补给，带回基地整理下一趟外勤。"
	if _is_crystal_logistics_return_object(interactable.instance_id):
		return "回收后勤补料材料，支撑基础反应器基础零件加工和出发整备台维护材料。"
	match interactable.interaction_type:
		"gather":
			match String(definition.get("object_type", "")):
				"resource_node":
					return "采集基础资源，带回基地加工或建造。"
				"salvage_node":
					return "回收残骸材料，补足基地制造和施工消耗。"
				"hazard_resource":
					return "回收污染沉积物，用于过滤器处理和污染边界推进。"
				"sample_residue":
					return "回收异常残留，补充样本分析材料。"
				_:
					return "回收可用物资，带回基地继续处理。"
		"sample":
			return "采集异常样本，回基地解析后推进后续目标。"
		"inspect":
			return "检查目标状态，确认当前路线或任务推进条件。"
		_:
			return "与当前目标交互，推进任务或获得反馈。"


func _format_interaction_reward_line(interactable: PrototypeInteractable, definition: Dictionary) -> String:
	if interactable.interaction_type == "gather":
		var drops := _format_refs(definition.get("drops", []))
		if not drops.is_empty():
			return "产物：%s" % drops
	if interactable.interaction_type == "sample":
		var samples := _format_refs(definition.get("sample_result_refs", []))
		if not samples.is_empty():
			return "样本：%s" % samples
	return ""


func _get_general_interaction_status(
	interactable: PrototypeInteractable,
	object_state: Dictionary,
	character_state: CharacterState,
	world_state: WorldState
) -> String:
	if interactable.definition_id == "map_object.demo_stabilization_core":
		return CoreStabilizationPressureFormatter.format_interaction_status(character_state, world_state, object_state)
	if _is_crystal_logistics_return_object(interactable.instance_id):
		return _get_crystal_logistics_return_status(interactable, object_state, world_state)
	if _is_general_interaction_processed(interactable, object_state):
		return _get_processed_interaction_status(interactable, character_state, world_state)
	if interactable.definition_id == CoreStabilizationPressureFormatter.RETEST_READOUT_DEFINITION_ID:
		return CoreStabilizationPressureFormatter.format_completed_cache_status(
			interactable.definition_id,
			world_state,
			character_state
		)
	var tool_status := _get_interaction_tool_status(interactable.definition_id, character_state)
	if tool_status.begins_with("缺少能力"):
		return "%s，先升级或更换工具。" % tool_status
	if interactable.definition_id == "map_object.outpost_departure_gate":
		return DepartureReadinessFormatter.format_departure_gate_status(world_state, character_state)
	if interactable.definition_id == "map_object.outpost_logistics_route_sign":
		return DepartureReadinessFormatter.format_logistics_route_status(world_state, character_state)
	match interactable.interaction_type:
		"gather":
			return "可采集。"
		"sample":
			return "可采样。"
		"inspect":
			return "可检查。"
		_:
			return "可交互。"


func _get_general_interaction_action(
	interactable: PrototypeInteractable,
	object_state: Dictionary,
	character_state: CharacterState,
	world_state: WorldState
) -> String:
	if (
		interactable.definition_id == "map_object.demo_stabilization_core"
		and world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core")
	):
		return "按 E 复测核心稳定设备"
	if _is_general_interaction_processed(interactable, object_state):
		return ""
	var tool_status := _get_interaction_tool_status(interactable.definition_id, character_state)
	if tool_status.begins_with("缺少能力"):
		return ""
	if interactable.definition_id == "map_object.outpost_departure_gate":
		return "按 E 检查出发准备"
	if interactable.definition_id == "map_object.outpost_logistics_route_sign":
		return "按 E 检查后勤路线"
	if interactable.definition_id == "map_object.demo_stabilization_core":
		return "按 E 写入核心稳定数据"
	if interactable.definition_id == CoreStabilizationPressureFormatter.RETEST_READOUT_DEFINITION_ID:
		return "按 E 回收复测读数缓存"
	match interactable.interaction_type:
		"gather":
			return "按 E 采集"
		"sample":
			return "按 E 采样"
		"inspect":
			return "按 E 检查"
		_:
			return "按 E 交互"


func _get_general_interaction_next_step(
	interactable: PrototypeInteractable,
	object_state: Dictionary,
	character_state: CharacterState,
	world_state: WorldState
) -> String:
	if interactable.definition_id == "map_object.outpost_departure_gate":
		return DepartureReadinessFormatter.format_departure_gate_next_step(world_state, character_state)
	if interactable.definition_id == "map_object.outpost_logistics_route_sign":
		return DepartureReadinessFormatter.format_logistics_route_next_step(world_state, character_state)
	if interactable.definition_id == "map_object.demo_stabilization_core":
		return CoreStabilizationPressureFormatter.format_interaction_next_step(character_state, world_state, object_state)
	if interactable.definition_id == CoreStabilizationPressureFormatter.RETEST_READOUT_DEFINITION_ID:
		return CoreStabilizationPressureFormatter.format_retest_readout_next_step(world_state, character_state)
	if _is_crystal_logistics_return_object(interactable.instance_id):
		return _get_crystal_logistics_return_next_step(interactable, object_state, world_state)
	if (
		interactable.definition_id != "map_object.pollution_residue_patch"
		and interactable.definition_id != CoreStabilizationPressureFormatter.LOGISTICS_MAINTENANCE_RETEST_RESIDUE_DEFINITION_ID
	):
		return ""
	var contextual_step := _get_pollution_residue_contextual_next_step(interactable, object_state, world_state)
	if not contextual_step.is_empty():
		return contextual_step
	if _is_general_interaction_processed(interactable, object_state):
		return "把沉积物处理成药剂；带药剂回污染边界后清理受扰敌人和门前压力点。"
	if character_state.inventory.has_ref("item.resistance_vial_t1", 1):
		return "药剂已在身上；采完沉积物后清理受扰敌人和门前压力点。"
	if world_state.has_base_structure_definition("building.pollution_filter"):
		return "采完沉积物先回处理点过滤器做药剂；带药剂回污染边界后清理受扰敌人和门前压力点。"
	return "先完成处理点地基和污染过滤器；过滤器上线后沉积物才能转成抗污染药剂。"


func _get_pollution_residue_contextual_next_step(
	interactable: PrototypeInteractable,
	object_state: Dictionary,
	world_state: WorldState
) -> String:
	var already_gathered := _is_general_interaction_processed(interactable, object_state)
	if interactable.instance_id == "map_object_instance.outer_ring_echo_residue_cache":
		if already_gathered:
			return "污染回波沉积已回收；回处理点过滤器处理成药剂和污染浆液，浆液会进入深段回波解析。"
		return "回收后先回处理点过滤器处理，保留污染浆液，再带回波匣回基地解析裂相坐标。"
	if interactable.instance_id == "map_object_instance.core_buffer_residue_cache":
		if already_gathered:
			return "核心缓冲补料沉积已回收；回处理点过滤器处理成药剂和污染浆液，再回基地整备核心稳压缓冲包。"
		return "回收后回处理点过滤器处理，保留药剂和污染浆液，再回基地整备核心稳压缓冲包。"
	if interactable.instance_id == "map_object_instance.pollution_residue_ridge_cache":
		if already_gathered:
			return "污染脊沉积已回收；回过滤器处理后，药剂支撑外圈承压，浆液可服务稳相信标。"
		return "采完沉积物后回过滤器处理，药剂支撑外圈承压，浆液可服务稳相信标。"
	if interactable.instance_id == "map_object_instance.pollution_residue_vial_reserve_cache":
		if already_gathered:
			return "药剂储备沉积已回收；回过滤器补下一支药剂和污染浆液，多余浆液可回基地反应器回收基础零件。"
		return "回收后回过滤器补下一支药剂和污染浆液，支撑污染边界后续回访。"
	if interactable.instance_id == "map_object_instance.pollution_residue_core_archive_route_cache":
		if already_gathered:
			return "出发路线回访沉积已回收；回过滤器补满双药剂，再从外勤出发口复测核心稳定站。"
		return "回收后回过滤器补满双药剂，验证核心归档维护对下一趟污染承压的收益。"
	if interactable.instance_id == "map_object_instance.pollution_residue_core_archive_return_cache":
		if already_gathered:
			return "归档维护回访沉积已回收；回过滤器处理成药剂和污染浆液，前哨核心补满后再从出发口复测。"
		return "回收后回过滤器处理成药剂和污染浆液，验证核心归档维护反哺下一趟污染承压。"
	if interactable.instance_id == "map_object_instance.pollution_residue_core_archive_pressure_retest_cache":
		if already_gathered:
			return "复测压力沉积已回收；回过滤器处理成药剂和污染浆液，多余浆液可回基础反应器回收基础零件。"
		return "清掉复测压力守卫后回收沉积物；处理后补药剂，并把多余污染浆液转回基地建造和整备收益。"
	if interactable.instance_id == CoreStabilizationPressureFormatter.LOGISTICS_MAINTENANCE_RETEST_RESIDUE_INSTANCE_ID:
		if already_gathered:
			return "后勤维护复测沉积已回收；回过滤器处理成药剂和污染浆液，再回前哨核心补给。"
		return "清掉后勤维护复测守卫后回收沉积物；这次承压会读取整备台后勤维护收益。"
	if world_state.quest_state.has_active_quest("quest.salvage_signal_echo"):
		return "这批沉积物服务深段回波线；处理后保留污染浆液，再回基地解析裂相坐标。"
	if world_state.quest_state.has_active_quest("quest.prepare_demo_stabilization_buffer"):
		return "这批沉积物服务核心缓冲包；处理后保留药剂和污染浆液，再回基地整备缓冲包。"
	return ""


func _is_crystal_logistics_return_object(instance_id: String) -> bool:
	return (
		instance_id == CoreGuardAftermathFormatter.CRYSTAL_LOGISTICS_RETURN_CRYSTAL_INSTANCE_ID
		or instance_id == CoreGuardAftermathFormatter.CRYSTAL_LOGISTICS_RETURN_WRECKAGE_INSTANCE_ID
	)


func _get_crystal_logistics_return_status(
	interactable: PrototypeInteractable,
	object_state: Dictionary,
	world_state: WorldState
) -> String:
	if _is_general_interaction_processed(interactable, object_state):
		if FieldOutfittingRuntime.is_logistics_maintenance_confirmed(world_state):
			return "后勤补料已回收并处理；出发整备台维护已确认。"
		if FieldOutfittingRuntime.is_logistics_material_processed(world_state):
			return "后勤补料已回收并加工成基础零件；出发整备台维护待确认。"
		return "后勤补料已回收；现场保留已回收标记。"
	return "后勤补料可回收；附近守卫仍会压住这条晶体侧路。"


func _get_crystal_logistics_return_next_step(
	interactable: PrototypeInteractable,
	object_state: Dictionary,
	world_state: WorldState
) -> String:
	if _is_general_interaction_processed(interactable, object_state):
		if FieldOutfittingRuntime.is_logistics_maintenance_confirmed(world_state):
			return "后勤补料已处理，整备台维护已确认；回前哨核心补给后准备下一趟外勤。"
		if FieldOutfittingRuntime.is_logistics_material_processed(world_state):
			return "后勤补料已加工成基础零件；回出发整备台确认维护材料。"
		return "后勤补料已回收；回基础反应器加工基础零件，或回出发整备台确认维护材料。"
	var resource_name := "晶体"
	if interactable.instance_id == CoreGuardAftermathFormatter.CRYSTAL_LOGISTICS_RETURN_WRECKAGE_INSTANCE_ID:
		resource_name = "残骸"
	return "清掉后勤补料守卫后回收%s；回基地加工基础零件，或回出发整备台确认维护材料。" % resource_name


func _get_processed_interaction_status(
	interactable: PrototypeInteractable,
	character_state: CharacterState,
	world_state: WorldState
) -> String:
	var core_cache_status := CoreStabilizationPressureFormatter.format_completed_cache_status(
		interactable.definition_id,
		world_state,
		character_state
	)
	if not core_cache_status.is_empty():
		return core_cache_status
	match interactable.interaction_type:
		"gather":
			match interactable.definition_id:
				"map_object.crystal_cluster", "map_object.rich_crystal_vein":
					return "已采集，现场保留已采集标记；继续寻找未变暗的晶体。"
				"map_object.pollution_residue_patch":
					return "已回收，现场保留已回收标记；回过滤器处理沉积物。"
				"map_object.field_wreckage":
					return "已回收，现场保留已回收标记；可回基地制造或继续找未变暗残骸。"
				"map_object.anomaly_residue_patch":
					return "已回收，现场保留已回收标记；继续处理样本分析目标。"
				_:
					return "已回收，现场保留已回收标记。"
		"sample":
			return "已采样，现场保留已采样标记；回基地解析样本。"
		"inspect":
			return "已确认，现场保留完成态标记；继续查看当前目标。"
		_:
			return "已完成，现场保留完成态标记。"


func _is_general_interaction_processed(interactable: PrototypeInteractable, object_state: Dictionary) -> bool:
	match interactable.interaction_type:
		"gather":
			return bool(object_state.get("is_gathered", false))
		"sample":
			return bool(object_state.get("is_sampled", false))
		"inspect":
			return bool(object_state.get("is_sampled", false))
		_:
			return false


func _format_refs(refs: Array) -> String:
	var parts: Array[String] = []
	for ref in refs:
		if ref is Dictionary:
			var definition_id := String(ref.get("id", ""))
			var amount := float(ref.get("amount", 1.0))
			if not definition_id.is_empty() and amount > 0.0:
				parts.append("%s x%s" % [_get_display_name(definition_id), _format_amount(amount)])
		else:
			var definition_id := String(ref)
			if not definition_id.is_empty():
				parts.append("%s x1" % _get_display_name(definition_id))
	return "，".join(parts)


func _has_completed_any(world_state: WorldState, quest_ids: Array[String]) -> bool:
	for quest_id in quest_ids:
		if world_state.quest_state.has_completed_quest(quest_id):
			return true
	return false


func _has_anchor_field_pressure_pins_cleared(world_state: WorldState) -> bool:
	for pressure_pin_instance_id in [
		"map_object_instance.phase_well_anchor_pressure_pin_west",
		"map_object_instance.phase_well_anchor_pressure_pin_east"
	]:
		if not bool(world_state.get_map_object(pressure_pin_instance_id).get("is_cleared", false)):
			return false
	return true


func _is_gate_pressure_active(world_state: WorldState) -> bool:
	var gate_pressure := world_state.get_enemy("enemy_instance.polluted_skitter_gate_pressure")
	if gate_pressure.is_empty():
		return false
	return not bool(gate_pressure.get("is_defeated", false))


func _has_demo_stabilization_recovery_cache(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return (
		bool(world_state.get_map_object("map_object_instance.demo_stabilization_recovery_cache").get("is_gathered", false))
		or bool(world_state.get_map_object("map_object_instance.demo_stabilization_recovery_wreckage").get("is_gathered", false))
	)


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


func _format_phase_relay_anchor_label(anchor_instance_id: String) -> String:
	match anchor_instance_id:
		"map_object_instance.phase_return_anchor":
			return "深段固定点"
		"map_object_instance.phase_return_anchor_chamber":
			return "碎晶沟谷前线"
		"map_object_instance.phase_return_anchor_tether":
			return "锚定桥前线"
		_:
			return "当前落点"
