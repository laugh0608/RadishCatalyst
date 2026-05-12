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
	if world_state.quest_state.has_active_quest("quest.reenter_phase_frontline"):
		return "按 E 回投：相位回投台，返回当前锚点 %s 并继续追踪更东侧裂相碎屑%s。" % [active_anchor_label, cycle_hint]
	return "按 E 回投：相位回投台，返回当前前线回传锚点 %s%s。" % [active_anchor_label, cycle_hint]


func format_phase_fault_spire_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.inspect_phase_fault_spire"):
		return "裂相尖塔：已校准，第一份内层故障轨迹已带回基地；下一步回基地解析更东侧相位井锁。"
	if not world_state.quest_state.has_completed_quest("quest.tune_relay_lens"):
		return "裂相尖塔：先回基地用基础反应器调准中继调谐镜，再回来校准内层回波。"
	if not character_state.inventory.has_ref("item.relay_tuning_lens", 1):
		return "裂相尖塔：缺少中继调谐镜；回基地确认基础反应器组装结果后再来。"
	return "按 E 校准：裂相尖塔。"


func format_phase_well_lock_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.unlock_phase_well"):
		return "相位井锁：已钉住，第一份相位井定位器已带回基地；下一步回基地解析定位器。"
	if not world_state.quest_state.has_completed_quest("quest.assemble_phase_well_key"):
		return "相位井锁：先回基地用基础反应器组装相位井钥，再回来钉住锁位。"
	if not character_state.inventory.has_ref("item.phase_well_key", 1):
		return "相位井锁：缺少相位井钥；回基地确认基础反应器组装结果后再来。"
	return "按 E 锁定：相位井锁。"


func format_inner_phase_well_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.inspect_inner_phase_well"):
		return "内层相位井：井芯样本已带回；先回基地解析这份样本，再回来继续推进更东侧井底裂口。"
	if not world_state.quest_state.has_completed_quest("quest.assemble_phase_well_probe"):
		return "内层相位井：先回基地组装相位井探针，再回来读取井芯样本。"
	if not character_state.inventory.has_ref("item.phase_well_probe", 1):
		return "内层相位井：缺少相位井探针；回基地确认基础反应器组装结果后再来。"
	return "按 E 勘验：内层相位井。"


func format_phase_well_sink_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.inspect_phase_well_sink"):
		return "井底裂口：已凿开，第一份相位井心核已带回基地；下一步回基地解析并继续推进井心室断面。"
	if not world_state.quest_state.has_completed_quest("quest.assemble_phase_well_pike"):
		return "井底裂口：先回基地用基础反应器组装井底穿钉，再回来凿开更东侧裂口。"
	if not character_state.inventory.has_ref("item.phase_well_pike", 1):
		return "井底裂口：缺少井底穿钉；回基地确认基础反应器组装结果后再来。"
	return "按 E 凿开：井底裂口。"


func format_phase_well_chamber_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.inspect_phase_well_chamber"):
		return "井心室断面：已勘验，第一份相位井纺核已带回基地；下一步回基地解析并继续推进井纺室断面。"
	if not world_state.quest_state.has_completed_quest("quest.assemble_phase_well_shunt"):
		return "井心室断面：先回基地用基础反应器组装井心分流栓，再回来勘验更东侧断面。"
	if not character_state.inventory.has_ref("item.phase_well_shunt", 1):
		return "井心室断面：缺少井心分流栓；回基地确认基础反应器组装结果后再来。"
	return "按 E 勘验：井心室断面。"


func format_phase_well_loom_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.inspect_phase_well_loom"):
		return "井纺室断面：已勘验，第一份相位井织核已带回基地；下一步回基地解析并继续推进井纹架断面。"
	if not world_state.quest_state.has_completed_quest("quest.assemble_phase_well_shuttle"):
		return "井纺室断面：先回基地用基础反应器组装井纺梭栓，再回来勘验更东侧断面。"
	if not character_state.inventory.has_ref("item.phase_well_shuttle", 1):
		return "井纺室断面：缺少井纺梭栓；回基地确认基础反应器组装结果后再来。"
	return "按 E 勘验：井纺室断面。"


func format_phase_well_frame_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.inspect_phase_well_frame"):
		return "井纹架断面：已勘验，第一份相位井结核已带回基地；下一步回基地解析并继续推进井系桥断面。"
	if not world_state.quest_state.has_completed_quest("quest.assemble_phase_well_frame_key"):
		return "井纹架断面：先回基地用基础反应器组装井纹架键栓，再回来勘验更东侧断面。"
	if not character_state.inventory.has_ref("item.phase_well_frame_key", 1):
		return "井纹架断面：缺少井纹架键栓；回基地确认基础反应器组装结果后再来。"
	return "按 E 勘验：井纹架断面。"


func format_phase_well_tether_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state.quest_state.has_completed_quest("quest.inspect_phase_well_tether"):
		return "井系桥断面：已勘验，第一份相位井锚核已带回基地；下一步回基地解析锚核并组装井系校锚桩。"
	if not world_state.quest_state.has_completed_quest("quest.assemble_phase_well_tether_spike"):
		return "井系桥断面：先回基地用基础反应器组装井系定桩，再回来勘验更东侧断面。"
	if not character_state.inventory.has_ref("item.phase_well_tether_spike", 1):
		return "井系桥断面：缺少井系定桩；回基地确认基础反应器组装结果后再来。"
	return "按 E 勘验：井系桥断面。"


func format_phase_well_anchor_field_prompt(world_state: WorldState, character_state: CharacterState) -> String:
	var object_state := world_state.get_map_object("map_object_instance.phase_well_anchor_field")
	var deployed := bool(object_state.get("anchor_field_deployed", false))
	var pressure_cleared := bool(object_state.get("anchor_field_pressure_cleared", false))
	var stabilized := bool(object_state.get("anchor_field_stabilized", false)) or world_state.quest_state.has_completed_quest("quest.stabilize_phase_well_anchor_field")
	if stabilized:
		return "锚场回稳窗：已稳定，井系桥东侧的局部稳定窗口仍在维持；相位井余响片已带回基地。"
	if not world_state.quest_state.has_completed_quest("quest.assemble_phase_well_anchor_stake"):
		return "锚场回稳窗：先回基地解析相位井锚核、稳定锚核落尘，再组装井系校锚桩回来部署。"
	if not deployed:
		if not character_state.inventory.has_ref("item.phase_well_anchor_stake", 1):
			return "锚场回稳窗：缺少井系校锚桩；回基地确认基础反应器组装结果后再来。"
		return "按 E 部署：锚场回稳窗。"
	if not pressure_cleared:
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


func _get_display_name(definition_id: String) -> String:
	if definition_id.is_empty():
		return ""

	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id

	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))


func _format_phase_relay_anchor_label(anchor_instance_id: String) -> String:
	match anchor_instance_id:
		"map_object_instance.phase_return_anchor":
			return "深段固定点"
		"map_object_instance.phase_return_anchor_chamber":
			return "井心室前线"
		_:
			return "当前落点"
