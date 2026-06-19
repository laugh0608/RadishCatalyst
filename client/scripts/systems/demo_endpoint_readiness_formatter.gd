extends RefCounted
class_name DemoEndpointReadinessFormatter

const ENTRY_QUEST_ID := "quest.enter_demo_stabilization_core"
const BUFFER_QUEST_ID := "quest.prepare_demo_stabilization_buffer"
const GUARD_QUEST_ID := "quest.defeat_demo_stabilization_guard"
const WRITE_QUEST_ID := "quest.write_demo_stabilization_core"
const STABILITY_WINDOW_QUEST_ID := "quest.calibrate_phase_well_stability_window"
const CORE_REGION_ID := "region.demo_stabilization_core"
const CORE_DEVICE_ID := "map_object.demo_stabilization_core"


static func is_endpoint_readiness_context(world_state: WorldState) -> bool:
	if world_state == null or DemoMainlineCompletionFormatter.is_demo_complete(world_state):
		return false
	if world_state.current_region_id == CORE_REGION_ID:
		return true
	if _has_any_endpoint_quest(world_state):
		return true
	return world_state.quest_state.has_completed_quest(STABILITY_WINDOW_QUEST_ID)


static func format_hud_summary(world_state: WorldState, character_state: CharacterState) -> Array[String]:
	if not is_endpoint_readiness_context(world_state):
		return []
	return [
		"终点前准备：%s" % "；".join(format_readiness_parts(world_state, character_state)),
		"终点下一步：%s" % format_next_step(world_state, character_state)
	]


static func format_outpost_core_prompt_line(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if not is_endpoint_readiness_context(world_state):
		return ""
	return "终点前总览：%s；下一步：%s" % [
		"；".join(format_readiness_parts(world_state, character_state)),
		format_next_step(world_state, character_state)
	]


static func format_departure_gate_status_line(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if not is_endpoint_readiness_context(world_state):
		return ""
	return "终点前准备：%s" % "；".join(format_readiness_parts(world_state, character_state))


static func format_departure_gate_next_step(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if not is_endpoint_readiness_context(world_state):
		return ""
	return format_next_step(world_state, character_state)


static func format_core_object_status_line(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if not is_endpoint_readiness_context(world_state):
		return ""
	return "终点总览：%s" % "；".join(format_readiness_parts(world_state, character_state))


static func format_core_object_next_step(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if not is_endpoint_readiness_context(world_state):
		return ""
	return format_next_step(world_state, character_state)


static func format_readiness_parts(
	world_state: WorldState,
	character_state: CharacterState
) -> Array[String]:
	var parts: Array[String] = [
		_format_mainline_state(world_state),
		_format_supply_state(world_state, character_state),
		_format_outfitting_state(world_state, character_state),
		_format_core_pressure_state(world_state, character_state)
	]
	return parts


static func format_next_step(world_state: WorldState, character_state: CharacterState) -> String:
	if DemoMainlineCompletionFormatter.is_demo_complete(world_state):
		return ""
	if not world_state.quest_state.has_completed_quest(ENTRY_QUEST_ID):
		return "从锚定桥进入核心稳定站，先读取侧边补给、守卫和核心设备"
	if not world_state.quest_state.has_completed_quest(BUFFER_QUEST_ID):
		if character_state.inventory.has_ref("item.core_stabilization_buffer", 1):
			return "带核心稳压缓冲包回核心稳定站，准备挑战核心阶段守卫"
		return "回污染边界补沉积物并回基地整备核心稳压缓冲包"
	if not world_state.quest_state.has_completed_quest(GUARD_QUEST_ID):
		if not character_state.are_vitals_full():
			return "先回前哨核心恢复生命 / 防护，再带缓冲包挑战核心阶段守卫"
		return "带核心稳压缓冲包进入核心稳定站，先取侧边补给并处理核心阶段守卫"
	if not CoreStabilizationPressureFormatter.has_guard_cache(world_state):
		return "回收守卫回写缓存，取得核心写入校验片和补给"
	if not character_state.inventory.has_ref("item.core_write_charge", 1):
		return "确认核心写入校验片在身，再靠近核心稳定设备写入"
	if not character_state.are_vitals_full():
		return "先回前哨核心恢复生命 / 防护，再写入核心稳定设备"
	if DepartureSupplyRuntime.get_resistance_vial_count(character_state) < DepartureSupplyRuntime.get_resistance_vial_target(world_state):
		return "先回前哨核心补抗污染药剂，再写入核心稳定设备"
	return "在核心稳定设备写入核心稳定数据"


static func _format_mainline_state(world_state: WorldState) -> String:
	if world_state.quest_state.has_active_quest(WRITE_QUEST_ID):
		return "主线：核心设备待写入"
	if world_state.quest_state.has_completed_quest(GUARD_QUEST_ID):
		return "主线：守卫已清，待回收缓存"
	if world_state.quest_state.has_active_quest(GUARD_QUEST_ID):
		return "主线：核心阶段守卫待处理"
	if world_state.quest_state.has_completed_quest(BUFFER_QUEST_ID):
		return "主线：缓冲包已整备"
	if world_state.quest_state.has_active_quest(BUFFER_QUEST_ID):
		return "主线：核心稳压缓冲包整备中"
	if world_state.quest_state.has_active_quest(ENTRY_QUEST_ID):
		return "主线：核心站入口待进入"
	return "主线：锚定桥稳窗已校准"


static func _format_supply_state(world_state: WorldState, character_state: CharacterState) -> String:
	var parts: Array[String] = []
	parts.append("生命 / 防护已满" if character_state.are_vitals_full() else "生命 / 防护待恢复")
	parts.append("修复凝胶已备" if character_state.inventory.has_ref("item.repair_gel", 1) else "修复凝胶待补")
	var vial_count := DepartureSupplyRuntime.get_resistance_vial_count(character_state)
	var vial_target := DepartureSupplyRuntime.get_resistance_vial_target(world_state)
	if vial_count >= vial_target:
		parts.append("抗污染药剂 %d/%d已备" % [vial_count, vial_target])
	elif vial_count > 0:
		parts.append("抗污染药剂 %d/%d，建议补满" % [vial_count, vial_target])
	else:
		parts.append("抗污染药剂待补")
	return "补给：%s" % " / ".join(parts)


static func _format_outfitting_state(world_state: WorldState, character_state: CharacterState) -> String:
	var parts: Array[String] = []
	if FieldOutfittingRuntime.has_filter_module_equipped(character_state):
		parts.append("过滤模块已装")
	elif world_state.has_base_structure_definition("building.field_outfitting_station"):
		parts.append("过滤模块待确认")
	else:
		parts.append("出发整备台待建")
	if FieldOutfittingRuntime.has_active_module_calibration(character_state, world_state):
		parts.append("模块校准已接入")
	if FieldOutfittingRuntime.has_active_field_loop_payoff(character_state, world_state):
		parts.append("外勤收益整备已接入")
	var protective_state := FieldOutfittingRuntime.format_protective_response_compact_state(
		world_state,
		character_state
	)
	if not protective_state.is_empty():
		parts.append(protective_state)
	var tool_state := FieldOutfittingRuntime.format_tool_strike_calibration_compact_state(
		world_state,
		character_state
	)
	if not tool_state.is_empty():
		parts.append(tool_state)
	return "整备：%s" % " / ".join(parts)


static func _format_core_pressure_state(world_state: WorldState, character_state: CharacterState) -> String:
	return "终点准备 %d/4：%s" % [
		CoreStabilizationPressureFormatter.get_ready_count(world_state, character_state),
		CoreStabilizationPressureFormatter.format_ready_parts(world_state, character_state)
	]


static func _has_any_endpoint_quest(world_state: WorldState) -> bool:
	for quest_id in [ENTRY_QUEST_ID, BUFFER_QUEST_ID, GUARD_QUEST_ID, WRITE_QUEST_ID]:
		if world_state.quest_state.has_active_quest(quest_id) or world_state.quest_state.has_completed_quest(quest_id):
			return true
	return false
