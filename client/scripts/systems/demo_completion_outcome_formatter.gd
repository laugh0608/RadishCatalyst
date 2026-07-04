extends RefCounted
class_name DemoCompletionOutcomeFormatter

const WRITE_QUEST_ID := "quest.write_demo_stabilization_core"
const CORE_REGION_ID := "region.demo_stabilization_core"
const OUTPOST_REGION_ID := "region.outpost_platform"


static func is_completion_outcome_context(world_state: WorldState) -> bool:
	return world_state != null and world_state.quest_state.has_completed_quest(WRITE_QUEST_ID)


static func format_goal_name(world_state: WorldState) -> String:
	if not is_completion_outcome_context(world_state):
		return ""
	return "首版 Demo 主线已完成"


static func format_progress_line(world_state: WorldState, character_state: CharacterState = null) -> String:
	if not is_completion_outcome_context(world_state):
		return ""
	var summary := format_outcome_summary(world_state, character_state)
	if world_state.current_region_id == CORE_REGION_ID:
		return "%s；沿外勤路线回前哨整理补给、整备和复测记录" % summary
	if world_state.current_region_id == OUTPOST_REGION_ID:
		return "%s；前哨可整理补给、整备和复测记录" % summary
	return "%s；返回前哨整理核心写入成果" % summary


static func format_hud_summary(world_state: WorldState, character_state: CharacterState) -> Array[String]:
	if not is_completion_outcome_context(world_state):
		return []
	return [
		"Demo 成果：%s" % format_outcome_summary(world_state, character_state),
		"成果整理：%s" % format_outpost_review_line(world_state, character_state),
		"结尾钩子：%s" % DemoNarrativeBeatFormatter.format_completion_hook_line()
	]


static func format_map_route_hint(world_state: WorldState, character_state: CharacterState = null) -> String:
	if not is_completion_outcome_context(world_state):
		return ""
	if world_state.current_region_id == CORE_REGION_ID:
		return "Demo 终点已完成 · %s · 沿外勤路线回前哨整理归档和成果" % format_outcome_summary(
			world_state,
			character_state
		)
	if world_state.current_region_id == OUTPOST_REGION_ID:
		return "Demo 终点已完成 · 前哨已收到核心写入 · %s" % format_outpost_review_line(
			world_state,
			character_state
		)
	return "Demo 终点已完成 · 返回前哨整理核心写入成果"


static func format_core_object_status_line(world_state: WorldState, character_state: CharacterState) -> String:
	if not is_completion_outcome_context(world_state):
		return ""
	return "成果整理：%s；%s" % [
		format_outcome_summary(world_state, character_state),
		format_terminal_evidence_line(world_state, character_state)
	]


static func format_core_object_next_step(world_state: WorldState, character_state: CharacterState) -> String:
	if not is_completion_outcome_context(world_state):
		return ""
	if world_state.current_region_id == CORE_REGION_ID:
		return "沿外勤路线回前哨核心，整理稳定窗口、补给、整备收益和复测读数"
	return "在前哨核心整理稳定窗口、补给、整备收益和复测读数；该完成态不再开启必需后续任务"


static func format_outpost_core_prompt_line(world_state: WorldState, character_state: CharacterState) -> String:
	if not is_completion_outcome_context(world_state):
		return ""
	return "Demo 成果整理：%s；%s" % [
		format_outcome_summary(world_state, character_state),
		format_outpost_review_line(world_state, character_state)
	]


static func format_completion_note(world_state: WorldState, character_state: CharacterState) -> String:
	if not is_completion_outcome_context(world_state):
		return "核心稳定站已接管第一条稳定通道；首版 Demo 主线目标已完成，回前哨可整理补给、整备和复测记录；%s" % DemoNarrativeBeatFormatter.format_completion_hook_line()
	return "%s；首版 Demo 主线目标已完成；回前哨可整理补给、整备和复测记录；%s；%s；不新增必需后续任务。" % [
		format_outcome_summary(world_state, character_state),
		format_outpost_review_line(world_state, character_state),
		DemoNarrativeBeatFormatter.format_completion_hook_line()
	]


static func format_outcome_summary(world_state: WorldState, character_state: CharacterState) -> String:
	var parts: Array[String] = ["核心稳定通道已打开", "前哨稳定窗口已打开"]
	if CoreStabilizationPressureFormatter.has_guard_cache(world_state):
		parts.append("守卫缓存已归档")
	if CoreStabilizationPressureFormatter.has_recovery_cache(world_state):
		parts.append("终点侧边补给已记录")
	if CoreStabilizationPressureFormatter.has_guard_buffer_sync(world_state):
		parts.append("稳压缓冲包参与写入")
	if CoreStabilizationPressureFormatter.has_guard_vial_pressure(world_state):
		parts.append("抗污染药剂参与排压")
	var outfitting := _format_outfitting_outcome(world_state, character_state)
	if not outfitting.is_empty():
		parts.append(outfitting)
	return "；".join(parts)


static func format_terminal_evidence_line(world_state: WorldState, character_state: CharacterState) -> String:
	var parts: Array[String] = []
	parts.append("守卫战记录：%s" % CoreGuardAftermathFormatter.format_battle_spend(world_state))
	if CoreStabilizationPressureFormatter.has_retest_readout(world_state):
		parts.append("复测读数已回收")
	elif CoreStabilizationPressureFormatter.is_retest_readout_available(world_state):
		parts.append("复测读数待回收")
	if character_state != null and not character_state.are_vitals_full():
		parts.append("生命 / 防护可回前哨恢复")
	return "；".join(parts)


static func format_outpost_review_line(world_state: WorldState, character_state: CharacterState) -> String:
	var parts: Array[String] = []
	if character_state != null:
		var supply_line := CoreGuardAftermathFormatter.format_next_sortie_supply_state(
			world_state,
			character_state
		)
		if not supply_line.is_empty():
			parts.append(supply_line)
	var outfitting := _format_outfitting_outcome(world_state, character_state)
	if not outfitting.is_empty():
		parts.append(outfitting)
	if CoreStabilizationPressureFormatter.has_retest_readout(world_state):
		parts.append("核心复测读数可整理为下一趟外勤材料")
	elif CoreStabilizationPressureFormatter.is_retest_readout_available(world_state):
		parts.append("核心复测读数待回收")
	else:
		parts.append("核心设备完成态可复测")
	parts.append("前哨稳定窗口可作为下一趟外勤起点")
	if parts.is_empty():
		return "回前哨整理补给和整备记录"
	return "；".join(parts)


static func _format_outfitting_outcome(world_state: WorldState, character_state: CharacterState) -> String:
	if character_state == null:
		return ""
	var parts: Array[String] = []
	if FieldOutfittingRuntime.has_active_module_calibration(character_state, world_state):
		parts.append("模块校准")
	if FieldOutfittingRuntime.has_active_field_loop_payoff(character_state, world_state):
		parts.append("外勤收益整备")
	if FieldOutfittingRuntime.has_active_core_archive_maintenance(character_state, world_state):
		parts.append("核心归档维护")
	if FieldOutfittingRuntime.has_active_logistics_maintenance(character_state, world_state):
		parts.append("后勤维护")
	if parts.is_empty():
		return ""
	return "整备成果：%s已接入" % " / ".join(parts)
