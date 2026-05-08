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

	var io_line := "输入：%s；产出：%s" % [
		String(status.get("inputs", "无")),
		String(status.get("outputs", "无"))
	]
	var byproducts := String(status.get("byproducts", ""))
	if not byproducts.is_empty():
		io_line = "%s；副产：%s" % [io_line, byproducts]
	parts.append(io_line)

	var status_line := "状态：%s" % String(status.get("message", ""))
	var progress := String(status.get("progress", ""))
	if not progress.is_empty():
		status_line = "%s；进度 %s" % [status_line, progress]
	else:
		status_line = "%s；耗时 %s 秒" % [status_line, String(status.get("duration", "0"))]
	parts.append(status_line)

	var action_parts: Array[String] = ["Q 查看详情"]
	if interactable.get_recipe_count() > 1:
		action_parts.append("R 切换")
	if bool(status.get("can_process", false)):
		action_parts.append("E 启动加工")
	parts.append("操作：%s" % "；".join(action_parts))

	var last_completion := String(status.get("last_completion", ""))
	if not last_completion.is_empty():
		var result_line := "上次结果：%s" % last_completion
		var last_destination := String(status.get("last_destination", ""))
		if not last_destination.is_empty():
			result_line = "%s；入库：%s" % [result_line, last_destination]
		parts.append(result_line)
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
