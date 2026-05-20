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
		"title": "井涌泄压阀",
		"effect": "两处泄压完成后，井涌碎屑回收线才会稳定。"
	},
	"map_object.phase_well_chamber_shunt_node": {
		"quest_id": "quest.collect_heart_spine",
		"objective_type": "inspect",
		"target_id": "map_object.phase_well_chamber_shunt_node",
		"required": 2.0,
		"title": "井心分流读数",
		"effect": "两处分流写完后，心棘残片才会从脉冲里露出。"
	},
	"map_object.phase_well_loom_tension_spool": {
		"quest_id": "quest.collect_weft_bundle",
		"objective_type": "inspect",
		"target_id": "map_object.phase_well_loom_tension_spool",
		"required": 2.0,
		"title": "井纺张力绕轮",
		"effect": "两处张力确认后，纬束残团回收线才会稳定。"
	},
	"map_object.phase_well_tether_knot_node": {
		"quest_id": "quest.collect_tether_fiber",
		"objective_type": "inspect",
		"target_id": "map_object.phase_well_tether_knot_node",
		"required": 2.0,
		"title": "井系桥结点",
		"effect": "两端结点确认后，系索残股才会从桥体边缘松开。"
	}
}

const FRONTLINE_ACTION_TARGET_PROMPTS := {
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
		"status": "未清理，高压扰动仍压着井系桥前线。",
		"effect": "清除后回基地使用基础反应器解析压力清障反馈，换取防护整备。",
		"action": "按 E 清理压力扰点",
		"requires_tool": true
	}
}


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
	var parts: Array[String] = ["设备：%s" % _get_display_name(interactable.definition_id)]
	var recipe_line := "配方：%s" % _get_display_name(recipe_id)
	if interactable.get_recipe_count() > 1:
		recipe_line = "%s（%d/%d）" % [
			recipe_line,
			interactable.get_recipe_position(),
			interactable.get_recipe_count()
		]
	parts.append(recipe_line)

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
		status_line = "%s；%s" % [status_line, progress]
	elif bool(status.get("can_process", false)):
		status_line = "%s；%s 秒" % [status_line, String(status.get("duration", "0"))]
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
	if interactable.definition_id == "map_object.well_ash_crust_blocker":
		if bool(object_state.get("is_cleared", false)):
			return "井底余烬壳：已清理，井壁余烬回收线保持打开。"
		var ash_tool_status := _get_interaction_tool_status(interactable.definition_id, character_state)
		var ash_parts: Array[String] = [
			"清障：%s" % _get_display_name(interactable.definition_id),
			"状态：未清理，井壁余烬被余烬壳压住。",
			"后续：清掉两处余烬壳，再处理井底潜伏体和井壁余烬。",
			"工具：%s" % ash_tool_status
		]
		if ash_tool_status == "可清理":
			ash_parts.append("按 E 清理余烬壳")
		return "\n".join(ash_parts)
	if interactable.definition_id == "map_object.phase_well_frame_route_blocker":
		if bool(object_state.get("is_cleared", false)):
			return "井纹架侧路障：已清理，边缕残条回收线保持打开。"
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
			return "锚场压力钉：已清理，回稳压制正在转向井系守脉体。"
		var pin_tool_status := _get_interaction_tool_status(interactable.definition_id, character_state)
		var pin_parts: Array[String] = [
			"压力钉：%s" % _get_display_name(interactable.definition_id),
			"状态：未清理，井系守脉体还没有完全暴露。",
			"后续：清掉两处压力钉，再压制井系守脉体。",
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
		"后续：清理后可铺设基础地基。",
		"工具：%s" % tool_status
	]
	if tool_status == "可清理":
		parts.append("按 E 清理地块")
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


func can_format_frontline_action_target_prompt(definition_id: String) -> bool:
	return FRONTLINE_ACTION_TARGET_PROMPTS.has(definition_id)


func format_frontline_action_target_prompt(
	interactable: PrototypeInteractable,
	character_state: CharacterState,
	world_state: WorldState
) -> String:
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


func format_outpost_core_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if not world_state.quest_state.has_completed_quest("quest.restore_outpost"):
		return "按 E 恢复：前哨核心，重启基础导航。"
	if character_state.are_vitals_full():
		return "前哨核心：整备在线；生命与防护完整，可继续外出或使用相位回投台。"
	return "按 E 整备：前哨核心，恢复生命与防护。"


func format_ruin_gate_prompt(world_state: WorldState) -> String:
	if not world_state.quest_state.has_completed_quest("quest.defeat_elite_node"):
		return "封锁遗迹入口：先压制污染残核，再确认更深区域信号。"
	if world_state.quest_state.has_completed_quest("quest.unlock_ruin_signal"):
		return "遗迹外圈已开放：继续向东进入外圈，回收继电残片。"
	return "按 E 确认：封锁遗迹入口信号，打开遗迹外圈通路。"


func format_outer_ring_barrier_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.stabilize_outer_ring_barrier"):
		return "抖动雾幕：已稳定，可继续向东检查外圈中继台。"
	if not world_state.quest_state.has_completed_quest("quest.assemble_phase_anchor"):
		return "抖动雾幕：先回基地组装稳相信标，再返回部署。"
	if not character_state.inventory.has_ref("item.phase_anchor", 1):
		return "抖动雾幕：缺少稳相信标；回基地用基础反应器把继电残片和污染浆液组装后再来。"
	return "按 E 部署：稳相信标，稳定抖动雾幕。"


func format_outer_ring_console_prompt(world_state: WorldState) -> String:
	if not world_state.quest_state.has_completed_quest("quest.stabilize_outer_ring_barrier"):
		return "外圈中继台：先稳定抖动雾幕，再进入外圈深段。"
	if world_state.quest_state.has_completed_quest("quest.secure_outer_ring_signal"):
		return "外圈中继台：数据已读取，更深遗迹结构坐标已保留。"
	return "按 E 检查：外圈中继台。"


func format_signal_echo_cache_prompt(world_state: WorldState) -> String:
	if not world_state.quest_state.has_completed_quest("quest.secure_outer_ring_signal"):
		return "外圈回波匣：先检查外圈中继台，锁定稳定回波。"
	if world_state.quest_state.has_completed_quest("quest.salvage_signal_echo"):
		return "外圈回波匣：已回收，回基地解析深段回波。"
	return "按 E 回收：外圈回波匣。"


func format_deep_ruin_door_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.unlock_deep_ruin_entrance"):
		return "深段入口门禁：已写入，可继续向东进入深段。"
	if not world_state.quest_state.has_completed_quest("quest.analyze_deep_signal"):
		return "深段入口门禁：先回基地解析深段回波，拿到更深遗迹坐标。"
	if not character_state.inventory.has_ref("item.deep_ruin_coordinates", 1):
		return "深段入口门禁：缺少更深遗迹坐标；回基地确认基础反应器解析结果后再来。"
	return "按 E 写入：更深遗迹坐标，打开深段入口。"


func format_deep_ruin_latch_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.unlock_deep_ruin_cache"):
		return "深段锁扣：已覆写，深段样块已回收。"
	if not world_state.quest_state.has_completed_quest("quest.assemble_deep_override"):
		return "深段锁扣：先回基地精炼相位纤丝并组装深段覆写栓。"
	if not character_state.inventory.has_ref("item.deep_override_key", 1):
		return "深段锁扣：缺少深段覆写栓；回过滤器精炼纤丝，再去反应器组装。"
	return "按 E 覆写：深段锁扣。"


func format_deep_signal_array_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.activate_deep_array"):
		return "深段阵列台：已点亮，第二轮导管回收线已暴露。"
	if not world_state.quest_state.has_completed_quest("quest.analyze_deep_core"):
		return "深段阵列台：先回基地解析深段样块，整理出路由印片。"
	if not character_state.inventory.has_ref("item.deep_route_imprint", 1):
		return "深段阵列台：缺少深段路由印片；回基地确认基础反应器解析结果后再来。"
	return "按 E 写入：深段路由印片，点亮深段阵列台。"


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
		return "裂相尖塔：已校准，第一份内层故障轨迹已带回基地；下一步回基地解析更东侧相位井锁。"
	if not (
		world_state.quest_state.has_completed_quest("quest.refine_phase_splinters")
		or world_state.quest_state.has_completed_quest("quest.tune_relay_lens")
	):
		return "裂相尖塔：先回基地完成中继调谐镜整备，再回来校准内层回波。"
	if not character_state.inventory.has_ref("item.relay_tuning_lens", 1):
		return "裂相尖塔：缺少中继调谐镜；回基地确认基础反应器组装结果后再来。"
	return "按 E 校准：裂相尖塔。"


func format_phase_well_lock_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.unlock_phase_well"):
		return "相位井锁：已钉住，第一份相位井定位器已带回基地；下一步回基地解析定位器。"
	if not (world_state.quest_state.has_completed_quest("quest.refine_fault_residue") or world_state.quest_state.has_completed_quest("quest.assemble_phase_well_key")):
		return "相位井锁：先回基地完成相位井钥整备，再回来钉住锁位。"
	if not character_state.inventory.has_ref("item.phase_well_key", 1):
		return "相位井锁：缺少相位井钥；回基地确认基础反应器组装结果后再来。"
	return "按 E 锁定：相位井锁。"


func format_inner_phase_well_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.inspect_inner_phase_well"):
		return "内层相位井：井芯样本已带回；先回基地解析这份样本，再回来继续推进更东侧井底裂口。"
	if not (world_state.quest_state.has_completed_quest("quest.refine_well_flux") or world_state.quest_state.has_completed_quest("quest.assemble_phase_well_probe")):
		return "内层相位井：先回基地完成相位井探针整备，再回来读取井芯样本。"
	if not character_state.inventory.has_ref("item.phase_well_probe", 1):
		return "内层相位井：缺少相位井探针；回基地确认基础反应器组装结果后再来。"
	return "按 E 勘验：内层相位井。"


func format_phase_well_sink_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.inspect_phase_well_sink"):
		return "井底裂口：已凿开，第一份相位井心核已带回基地；下一步回基地解析并继续推进井心室断面。"
	if not _has_completed_any(world_state, ["quest.refine_well_ash", "quest.assemble_phase_well_pike"]):
		return "井底裂口：先回基地完成井底整备，把井底穿钉带回来凿开更东侧裂口。"
	if not character_state.inventory.has_ref("item.phase_well_pike", 1):
		return "井底裂口：缺少井底穿钉；回基地确认基础反应器组装结果后再来。"
	return "按 E 凿开：井底裂口。"


func format_phase_well_chamber_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.inspect_phase_well_chamber"):
		return "井心室断面：已勘验，第一份相位井纺核已带回基地；下一步回基地解析并继续推进井纺室断面。"
	if not _has_completed_any(world_state, ["quest.refine_heart_spine", "quest.assemble_phase_well_shunt"]):
		return "井心室断面：先回基地完成井心整备，把井心分流栓带回来勘验更东侧断面。"
	if not character_state.inventory.has_ref("item.phase_well_shunt", 1):
		return "井心室断面：缺少井心分流栓；回基地确认基础反应器组装结果后再来。"
	return "按 E 勘验：井心室断面。"


func format_phase_well_loom_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.inspect_phase_well_loom"):
		return "井纺室断面：已勘验，第一份相位井织核已带回基地；下一步回基地解析并继续推进井纹架断面。"
	if not _has_completed_any(world_state, ["quest.refine_weft_bundle", "quest.assemble_phase_well_shuttle"]):
		return "井纺室断面：先回基地完成井纺整备，把井纺梭栓带回来勘验更东侧断面。"
	if not character_state.inventory.has_ref("item.phase_well_shuttle", 1):
		return "井纺室断面：缺少井纺梭栓；回基地确认基础反应器组装结果后再来。"
	return "按 E 勘验：井纺室断面。"


func format_phase_well_frame_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.inspect_phase_well_frame"):
		return "井纹架断面：已勘验，第一份相位井结核已带回基地；下一步回基地解析并继续推进井系桥断面。"
	if not _has_completed_any(world_state, ["quest.refine_selvedge_strip", "quest.assemble_phase_well_frame_key"]):
		return "井纹架断面：先回基地完成井纹架整备，把井纹架键栓带回来勘验更东侧断面。"
	if not character_state.inventory.has_ref("item.phase_well_frame_key", 1):
		return "井纹架断面：缺少井纹架键栓；回基地确认基础反应器组装结果后再来。"
	return "按 E 勘验：井纹架断面。"


func format_phase_well_tether_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.inspect_phase_well_tether"):
		return "井系桥断面：已勘验，第一份相位井锚核已带回基地；下一步回基地完成锚场整备。"
	if not _has_completed_any(world_state, ["quest.refine_tether_fiber", "quest.assemble_phase_well_tether_spike"]):
		return "井系桥断面：先回基地完成井系整备，把井系定桩带回来勘验更东侧断面。"
	if not character_state.inventory.has_ref("item.phase_well_tether_spike", 1):
		return "井系桥断面：缺少井系定桩；回基地确认基础反应器组装结果后再来。"
	return "按 E 勘验：井系桥断面。"


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
			return "按 E 回充：稳窗读数已校准，锚场回稳窗可在前线恢复生命与防护。"
		return "锚场回稳窗：局部稳定窗口已维持；回基地解析相位井余响片后，可把这里校准成前线回稳点。"
	if not _has_completed_any(world_state, ["quest.refine_anchor_core_dust", "quest.assemble_phase_well_anchor_stake"]):
		return "锚场回稳窗：先回基地完成锚场整备，把井系校锚桩带回来部署。"
	if not deployed:
		if not character_state.inventory.has_ref("item.phase_well_anchor_stake", 1):
			return "锚场回稳窗：缺少井系校锚桩；回基地确认基础反应器组装结果后再来。"
		return "按 E 部署：锚场回稳窗。"
	if not pressure_cleared:
		if not _has_anchor_field_pressure_pins_cleared(world_state):
			return "锚场回稳窗：回稳中；先清掉两处压力钉，再压制井系守脉体。校锚桩会保留在现场，失败后可直接重试。"
		return "锚场回稳窗：回稳中；先清掉井系守脉体，再回来收束稳定窗口。校锚桩会保留在现场，失败后可直接重试。"
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
			return "井心室前线"
		"map_object_instance.phase_return_anchor_tether":
			return "井系桥前线"
		_:
			return "当前落点"
