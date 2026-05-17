extends RefCounted
class_name QuestCompletionApplier

var data_registry: DataRegistry


func _init(registry: DataRegistry) -> void:
	data_registry = registry


func apply_completion(world_state: WorldState, character_state: CharacterState, completion_result: Dictionary) -> Dictionary:
	if not bool(completion_result.get("completed", false)):
		return {}

	var quest_id := String(completion_result.get("quest_id", ""))
	var reward_refs: Array = completion_result.get("rewards", [])
	var reward_messages := _grant_refs(character_state, reward_refs)
	var unlock_effects: Array = completion_result.get("unlock_effects", [])
	for effect_id in unlock_effects:
		_apply_world_unlock_effect(world_state, String(effect_id))
	var progression_sync := CharacterProgressionStats.sync_character_state(
		character_state,
		world_state.quest_state,
		"gain"
	)
	if bool(progression_sync.get("changed", false)):
		var progression_reward_message := CharacterProgressionStats.format_reward_message(progression_sync)
		if not progression_reward_message.is_empty():
			reward_messages.append(progression_reward_message)

	var next_quest_ids: Array = completion_result.get("next_quest_ids", [])
	var next_quest_names := _format_next_quest_names(next_quest_ids)
	var unlock_messages := _format_unlock_effects(unlock_effects)
	var note_text := _format_completion_note(quest_id)
	var quest_name := _get_display_name(quest_id)
	var title := "任务完成：%s" % quest_name
	var panel_title := "任务完成"
	if quest_id == "quest.secure_outer_ring_signal":
		panel_title = "切片完成"
	var completed_text := "完成：%s" % quest_name
	var reward_text := "奖励：无直接物资"
	if not reward_messages.is_empty():
		reward_text = "奖励：%s" % ", ".join(reward_messages)

	var unlock_text := ""
	if not unlock_messages.is_empty():
		unlock_text = "解锁：%s" % ", ".join(unlock_messages)

	var next_goal_text := ""
	if not next_quest_names.is_empty():
		next_goal_text = "新目标：%s" % ", ".join(next_quest_names)

	return {
		"quest_id": quest_id,
		"title": title,
		"panel_title": panel_title,
		"completed_text": completed_text,
		"reward_text": reward_text,
		"unlock_text": unlock_text,
		"note_text": note_text,
		"next_goal_text": next_goal_text,
		"log_message": _format_log_message(title, reward_text, unlock_text, note_text, next_goal_text)
	}


func _grant_refs(character_state: CharacterState, refs: Array) -> Array[String]:
	var reward_messages: Array[String] = []
	for ref in refs:
		if not ref is Dictionary:
			continue

		var definition_id := String(ref.get("id", ""))
		var amount := float(ref.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0:
			continue

		character_state.inventory.add_ref(definition_id, amount)
		reward_messages.append("%s x%s" % [_get_display_name(definition_id), _format_amount(amount)])
	return reward_messages


func _apply_world_unlock_effect(world_state: WorldState, effect_id: String) -> void:
	if effect_id.begins_with("region."):
		world_state.unlock_region(effect_id)


func _format_next_quest_names(next_quest_ids: Array) -> Array[String]:
	var next_quest_names: Array[String] = []
	for next_quest_id in next_quest_ids:
		next_quest_names.append(_get_display_name(String(next_quest_id)))
	return next_quest_names


func _format_unlock_effects(unlock_effects: Array) -> Array[String]:
	var unlock_messages: Array[String] = []
	for effect_id in unlock_effects:
		var id := String(effect_id)
		if id.begins_with("quest."):
			continue
		if id == "slice_01_complete":
			unlock_messages.append("第一切片完成标记")
			continue
		if id.begins_with("region.") or id.begins_with("recipe.") or id.begins_with("building.") or id.begins_with("equipment.") or id.begins_with("item."):
			unlock_messages.append(_get_display_name(id))
			continue
		unlock_messages.append(id)
	return unlock_messages


func _format_completion_note(quest_id: String) -> String:
	match quest_id:
		"quest.enter_pollution_edge":
			return "污染深处出现稳定源点反应"
		"quest.defeat_elite_node":
			return "污染源点已压制，封锁遗迹入口信号可确认"
		"quest.unlock_ruin_signal":
			return "遗迹外圈通路已恢复，可进入外圈回收继电残片"
		"quest.stabilize_outer_ring_barrier":
			return "稳相信标已部署，外圈深段通路已稳定"
		"quest.secure_outer_ring_signal":
			return "遗迹外圈主闭环已完成；深段回波匣已暴露，可继续回收"
		"quest.salvage_signal_echo":
			return "深段回波已带回；回基地解析后可整理出更深遗迹坐标"
		"quest.analyze_deep_signal":
			return "更深遗迹坐标已解析，可返回外圈最东侧写入深段入口门禁"
		"quest.unlock_deep_ruin_entrance":
			return "深段入口已打开，可进入更深区域回收相位纤丝"
		"quest.harvest_phase_filament":
			return "相位纤丝已带回；回基地用污染过滤器精炼谐振滤芯"
		"quest.refine_phase_filament":
			return "谐振滤芯和污染浆液已就绪；回基础反应器组装深段覆写栓"
		"quest.assemble_deep_override":
			return "深段覆写栓已完成，可返回深段入口覆写锁扣"
		"quest.unlock_deep_ruin_cache":
			return "深段样块已回收；回基地解析后可继续点亮深段阵列"
		"quest.analyze_deep_core":
			return "深段路由印片已整理；返回深段阵列台可打开第二轮回收线"
		"quest.activate_deep_array":
			return "深段阵列已点亮；相位导管已带回，可回基地整理新的读数矩阵"
		"quest.assemble_deep_signal_matrix":
			return "深段读数矩阵已整理完成；返回深段固定点部署前线回传锚点"
		"quest.deploy_phase_relay_anchor":
			return "前线回传锚点已部署；先在基地真正用一次相位回投台，再继续追踪更东侧裂相脊"
		"quest.reenter_phase_frontline":
			return "基地回投已接入正式主线；更东侧裂相碎屑和新的深段猎手已暴露"
		"quest.trace_phase_splinters":
			return "裂相碎屑已带回；回基地完成中继调谐镜远征整备"
		"quest.refine_phase_splinters":
			return "中继调谐镜已整备完成；返回更东侧裂相尖塔，逼出第一份内层故障轨迹"
		"quest.inspect_phase_fault_spire":
			return "内层故障轨迹已带回；回传后的更深风险和收益已真正落到下一轮推进线索"
		"quest.refine_well_flux":
			return "相位井探针已整备完成；返回更东侧内层相位井，读取第一份井芯样本"
		"quest.refine_well_ash":
			return "井底穿钉已整备完成；返回更东侧井底裂口，凿开后带回第一份相位井心核"
		"quest.refine_heart_spine":
			return "井心分流栓已整备完成；返回更东侧井心室断面，勘验后带回第一份相位井纺核"
		"quest.refine_weft_bundle":
			return "井纺梭栓已整备完成；返回更东侧井纺室断面，勘验后带回第一份相位井织核"
		"quest.refine_selvedge_strip":
			return "井纹架键栓已整备完成；返回更东侧井纹架断面，勘验后带回第一份相位井结核"
		"quest.refine_tether_fiber":
			return "井系定桩已整备完成；返回更东侧井系桥断面，勘验后带回第一份相位井锚核"
		"quest.inspect_phase_well_tether":
			return "相位井锚核已带回；回基地解析后可把井系桥东侧改成新的短守场目标"
		"quest.analyze_phase_well_anchor_core":
			return "归谱片和锚核落尘已整理完成；回基地完成井系校锚桩整备"
		"quest.refine_anchor_core_dust":
			return "井系校锚桩已整备完成；返回井系桥东侧部署，先清压力钉再顶住一轮回稳压制"
		"quest.assemble_phase_well_anchor_stake":
			return "井系校锚桩已完成；返回井系桥东侧部署，先清压力钉再顶住一轮回稳压制"
		"quest.stabilize_phase_well_anchor_field":
			return "井系桥东侧稳定窗口已生成；相位井余响片已带回基地"
		"quest.analyze_phase_well_echo_shard":
			return "稳窗读数已解析；返回井系桥东侧按现场相位序校准三处稳窗节点"
		"quest.calibrate_phase_well_stability_window":
			return "稳窗校准完成；回基地在前线行动台确认下一趟外出行动"
		"quest.plan_stability_frontline_action":
			return "前线行动已确认；从相位回投台返回井系桥东侧，读取稳窗回波探点"
		"quest.survey_stability_echo_probe":
			return "稳窗回波样本已带回；回基地用基础反应器解析前线行动回报"
		"quest.analyze_stability_echo_sample":
			return "前线行动回报已归档；基地已把回报整理成下一趟短行动补给"
		"quest.confirm_supply_frontline_action":
			return "补给短行动已确认；从相位回投台返回井系桥前线，读取补给回执标记"
		"quest.inspect_supply_return_marker":
			return "补给回执读数已带回；回基地用基础反应器解析短行动反馈"
		"quest.analyze_supply_return_trace":
			return "短行动反馈已归档；基地已把反馈整理成下一趟巡线短行动"
		"quest.confirm_route_frontline_action":
			return "巡线短行动已确认；从相位回投台返回井系桥前线，读取巡线信标"
		"quest.inspect_route_signal_marker":
			return "巡线信标读数已带回；回基地用基础反应器解析巡线反馈"
		"quest.analyze_route_signal_trace":
			return "巡线反馈已归档；第三条轻量前线行动闭环已经收束"
		_:
			return ""


func _format_log_message(
	title: String,
	reward_text: String,
	unlock_text: String,
	note_text: String,
	next_goal_text: String
) -> String:
	var parts: Array[String] = [title + "。", reward_text + "。"]
	if not unlock_text.is_empty():
		parts.append(unlock_text + "。")
	if not note_text.is_empty():
		parts.append(note_text + "。")
	if not next_goal_text.is_empty():
		parts.append(next_goal_text + "。")
	return " ".join(parts)


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
