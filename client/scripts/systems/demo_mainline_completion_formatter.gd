extends RefCounted
class_name DemoMainlineCompletionFormatter

const WRITE_QUEST_ID := "quest.write_demo_stabilization_core"
const CORE_REGION_ID := "region.demo_stabilization_core"
const OUTPOST_REGION_ID := "region.outpost_platform"


static func is_demo_complete(world_state: WorldState) -> bool:
	return world_state != null and world_state.quest_state.has_completed_quest(WRITE_QUEST_ID)


static func format_goal_name(world_state: WorldState) -> String:
	if not is_demo_complete(world_state):
		return ""
	return "首版 Demo 主线已完成"


static func format_progress_line(world_state: WorldState) -> String:
	if not is_demo_complete(world_state):
		return ""
	if world_state.current_region_id == CORE_REGION_ID:
		return "核心稳定站已接管第一条稳定通道；回前哨整理补给、整备和复测记录"
	if world_state.current_region_id == OUTPOST_REGION_ID:
		return "核心写入已归档；前哨可整理补给、整备和复测记录"
	return "核心稳定站写入已完成；返回前哨整理本趟外勤收益"


static func format_hud_summary(world_state: WorldState, _character_state: CharacterState) -> Array[String]:
	if not is_demo_complete(world_state):
		return []
	return ["Demo 完成：核心稳定站已接管；回前哨整理补给、整备和复测记录。"]


static func format_map_route_hint(world_state: WorldState) -> String:
	if not is_demo_complete(world_state):
		return ""
	if world_state.current_region_id == CORE_REGION_ID:
		return "Demo 终点已完成 · 核心稳定站已接管；沿外勤路线回前哨整理归档"
	if world_state.current_region_id == OUTPOST_REGION_ID:
		return "Demo 终点已完成 · 前哨已收到核心写入；整理补给、整备和复测记录"
	return "Demo 终点已完成 · 返回前哨整理核心写入和外勤收益"


static func format_core_object_status(
	world_state: WorldState,
	character_state: CharacterState,
	_object_state: Dictionary
) -> String:
	if not is_demo_complete(world_state):
		return ""
	return "Demo 终点已完成；核心稳定站已接管第一条稳定通道；%s。" % _format_completion_evidence(
		world_state,
		character_state
	)


static func format_core_object_action(world_state: WorldState) -> String:
	if not is_demo_complete(world_state):
		return ""
	return "按 E 复测核心完成归档"


static func format_core_object_next_step(
	world_state: WorldState,
	_character_state: CharacterState,
	_object_state: Dictionary
) -> String:
	if not is_demo_complete(world_state):
		return ""
	if world_state.current_region_id == CORE_REGION_ID:
		return "沿外勤路线回前哨核心，整理补给、战后日志和整备复测记录。"
	return "在前哨核心整理补给和整备记录；该完成态不再开启必需后续任务。"


static func format_outpost_core_prompt_line(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if not is_demo_complete(world_state):
		return ""
	var refill_part := "补给已可整理"
	if character_state != null and not character_state.are_vitals_full():
		refill_part = "可在前哨恢复生命 / 防护"
	return "Demo 完成：核心写入已归档；%s，并复测整备收益。" % refill_part


static func format_completion_note() -> String:
	return "核心稳定站已接管第一条稳定通道；首版 Demo 主线目标已完成，回前哨可整理补给、整备和复测记录"


static func _format_completion_evidence(world_state: WorldState, character_state: CharacterState) -> String:
	var parts: Array[String] = []
	if CoreStabilizationPressureFormatter.has_guard_cache(world_state):
		parts.append("守卫缓存已归档")
	if CoreStabilizationPressureFormatter.has_recovery_cache(world_state):
		parts.append("终点前补给已记录")
	if CoreStabilizationPressureFormatter.has_guard_buffer_sync(world_state):
		parts.append("核心稳压缓冲包已参与写入")
	if (
		character_state != null
		and FieldOutfittingRuntime.has_active_core_archive_maintenance(character_state, world_state)
	):
		parts.append("核心归档维护已接入整备")
	if parts.is_empty():
		return "终点写入已归档"
	return "；".join(parts)
