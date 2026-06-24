extends RefCounted
class_name DemoMainlineCompletionFormatter

const WRITE_QUEST_ID := "quest.write_demo_stabilization_core"
const CORE_REGION_ID := "region.demo_stabilization_core"
const OUTPOST_REGION_ID := "region.outpost_platform"
const CompletionOutcomeFormatter := preload("res://scripts/systems/demo_completion_outcome_formatter.gd")


static func is_demo_complete(world_state: WorldState) -> bool:
	return world_state != null and world_state.quest_state.has_completed_quest(WRITE_QUEST_ID)


static func format_goal_name(world_state: WorldState) -> String:
	if not is_demo_complete(world_state):
		return ""
	var goal_name := CompletionOutcomeFormatter.format_goal_name(world_state)
	if not goal_name.is_empty():
		return goal_name
	return "首版 Demo 主线已完成"


static func format_progress_line(world_state: WorldState) -> String:
	if not is_demo_complete(world_state):
		return ""
	return CompletionOutcomeFormatter.format_progress_line(world_state)


static func format_hud_summary(world_state: WorldState, _character_state: CharacterState) -> Array[String]:
	if not is_demo_complete(world_state):
		return []
	return CompletionOutcomeFormatter.format_hud_summary(world_state, _character_state)


static func format_map_route_hint(world_state: WorldState) -> String:
	if not is_demo_complete(world_state):
		return ""
	return CompletionOutcomeFormatter.format_map_route_hint(world_state)


static func format_core_object_status(
	world_state: WorldState,
	character_state: CharacterState,
	_object_state: Dictionary
) -> String:
	if not is_demo_complete(world_state):
		return ""
	return "Demo 终点已完成；%s；%s。" % [
		CompletionOutcomeFormatter.format_core_object_status_line(world_state, character_state),
		_format_completion_evidence(
			world_state,
			character_state
		)
	]


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
	return CompletionOutcomeFormatter.format_core_object_next_step(world_state, _character_state)


static func format_outpost_core_prompt_line(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if not is_demo_complete(world_state):
		return ""
	var outcome_line := CompletionOutcomeFormatter.format_outpost_core_prompt_line(
		world_state,
		character_state
	)
	var refit_line := CoreGuardAftermathFormatter.format_next_sortie_supply_state(
		world_state,
		character_state
	)
	if refit_line.is_empty():
		refit_line = "回前哨整理补给和模块整备"
	return "Demo 完成：核心写入已归档；%s，并复测整备收益。%s" % [
		refit_line,
		outcome_line
	]


static func format_completion_note() -> String:
	return "核心稳定站已接管第一条稳定通道；首版 Demo 主线目标已完成，回前哨可整理补给、整备和复测记录；%s" % DemoNarrativeBeatFormatter.format_completion_hook_line()


static func format_completion_note_for_state(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	return CompletionOutcomeFormatter.format_completion_note(world_state, character_state)


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
