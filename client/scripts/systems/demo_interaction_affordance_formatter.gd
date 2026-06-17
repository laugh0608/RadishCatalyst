extends RefCounted
class_name DemoInteractionAffordanceFormatter

const SIGNAL_ECHO_CACHE_INSTANCE_ID := "map_object_instance.signal_echo_cache"
const DEMO_GUARD_CACHE_INSTANCE_ID := "map_object_instance.demo_stabilization_guard_cache"
const DEMO_CORE_INSTANCE_ID := "map_object_instance.demo_stabilization_core"


static func format_general_affordance_line(
	interactable: PrototypeInteractable,
	object_state: Dictionary,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if interactable == null:
		return ""
	return format_definition_affordance_line(
		interactable.definition_id,
		interactable.interaction_type,
		interactable.instance_id,
		object_state,
		world_state,
		character_state
	)


static func format_definition_affordance_line(
	definition_id: String,
	interaction_type: String,
	instance_id: String,
	object_state: Dictionary,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	var state_text := _format_definition_state(
		definition_id,
		interaction_type,
		instance_id,
		object_state,
		world_state,
		character_state
	)
	if state_text.is_empty():
		return ""
	return "可辨识：%s" % state_text


static func format_build_affordance_line(status: Dictionary) -> String:
	var message := String(status.get("message", ""))
	if bool(status.get("can_build", false)):
		return "可辨识：可建造；材料、下一步和操作行应同时出现。"
	if message.contains("已建成"):
		return "可辨识：已处理；建造点应显示已建成并保留已上线 / 已接入视觉。"
	if message.contains("缺少建造材料"):
		return "可辨识：缺条件；材料缺口和下一步补料方向已列出。"
	if not message.is_empty():
		return "可辨识：缺条件；前置条件和下一步目标已列出。"
	return ""


static func format_clear_affordance_line(
	object_state: Dictionary,
	tool_status: String
) -> String:
	if bool(object_state.get("is_cleared", false)):
		return "可辨识：已处理；场景标签应显示已清理。"
	if tool_status.begins_with("缺少能力"):
		return "可辨识：缺条件；%s。" % tool_status
	return "可辨识：可处理；清障对象仍阻挡路线或建造。"


static func format_outpost_core_affordance_line(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if world_state == null:
		return ""
	if not world_state.quest_state.has_completed_quest("quest.restore_outpost"):
		return "可辨识：可交互；前哨核心仍处于待恢复状态。"
	if DemoMainlineCompletionFormatter.is_demo_complete(world_state):
		return "可辨识：已处理；前哨核心保留 Demo 成果整理和补给恢复入口。"
	if not DemoCombatEvacuationRecoveryFormatter.format_outpost_core_recovery_line(world_state, character_state).is_empty():
		return "可辨识：缺整备条件；生命 / 防护或补给未恢复前，出发口会继续指向前哨核心。"
	return "可辨识：可整备；核心提示、HUD 和地图应共同指向当前外勤目标。"


static func format_outfitting_station_affordance_line(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if world_state == null:
		return ""
	if not world_state.has_base_structure_definition("building.field_outfitting_station"):
		return "可辨识：缺条件；出发整备台未建成，先回建造点。"
	if FieldOutfittingRuntime.is_module_calibrated(world_state):
		return "可辨识：已处理；焦点标签应显示已校准，仍保留整备检查入口。"
	if FieldOutfittingRuntime.has_filter_module_equipped(character_state):
		return "可辨识：可整备；模块已装配，提示应区分维护缺料或可校准。"
	if character_state != null and character_state.inventory.has_ref(FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID, 1):
		return "可辨识：可交互；可装配基础过滤模块。"
	return "可辨识：缺条件；先用基础反应器组装基础过滤模块。"


static func _format_definition_state(
	definition_id: String,
	interaction_type: String,
	instance_id: String,
	object_state: Dictionary,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if _is_processed(definition_id, interaction_type, object_state, world_state):
		return "已处理；焦点标签保留已采集 / 已回收 / 已清理读法，操作行不再提示重复处理。"
	var blocker := _get_blocking_enemy_label(definition_id, instance_id, world_state)
	if not blocker.is_empty():
		return "危险仍在；%s 仍压制该目标，先处理战斗对象。" % blocker
	var missing_condition := _get_missing_condition_label(
		definition_id,
		instance_id,
		world_state,
		character_state
	)
	if not missing_condition.is_empty():
		return "缺条件；%s。" % missing_condition
	match interaction_type:
		"gather":
			return "可处理；靠近后应能读到可采集和回基地处理方向。"
		"sample":
			return "可处理；靠近后应能读到可采样和后续解析方向。"
		"inspect":
			return "可交互；靠近后应能读到检查目标、状态和下一步。"
		_:
			return "可交互；提示、焦点标签和地图目标不应互相冲突。"


static func _is_processed(
	definition_id: String,
	interaction_type: String,
	object_state: Dictionary,
	world_state: WorldState
) -> bool:
	if bool(object_state.get("is_gathered", false)):
		return true
	if bool(object_state.get("is_sampled", false)):
		return true
	if bool(object_state.get("is_cleared", false)):
		return true
	if bool(object_state.get("is_built", false)):
		return true
	if world_state == null:
		return false
	if definition_id == "map_object.signal_echo_cache":
		return world_state.quest_state.has_completed_quest("quest.salvage_signal_echo")
	if definition_id == "map_object.deep_signal_array":
		return world_state.quest_state.has_completed_quest("quest.activate_deep_array")
	if definition_id == "map_object.demo_stabilization_core":
		return world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core")
	return false


static func _get_blocking_enemy_label(
	definition_id: String,
	instance_id: String,
	world_state: WorldState
) -> String:
	if world_state == null:
		return ""
	if definition_id == "map_object.signal_echo_cache":
		if (
			world_state.quest_state.has_active_quest("quest.salvage_signal_echo")
			and not bool(world_state.get_enemy("enemy_instance.ruin_phase_guard").get("is_defeated", false))
		):
			return "相位守卫"
	if definition_id == "map_object.demo_stabilization_guard_cache":
		if not bool(world_state.get_enemy("enemy_instance.demo_stabilization_guard").get("is_defeated", false)):
			return "核心阶段守卫"
	if definition_id == "map_object.demo_stabilization_core":
		if (
			not world_state.quest_state.has_active_quest("quest.write_demo_stabilization_core")
			and not bool(world_state.get_enemy("enemy_instance.demo_stabilization_guard").get("is_defeated", false))
		):
			return "核心阶段守卫"
	return ""


static func _get_missing_condition_label(
	definition_id: String,
	instance_id: String,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if world_state == null:
		return ""
	if definition_id == "map_object.outpost_departure_gate":
		if not world_state.quest_state.has_completed_quest("quest.restore_outpost"):
			return "先恢复前哨核心"
		if not DemoCombatEvacuationRecoveryFormatter.format_departure_gate_status_line(world_state, character_state).is_empty():
			return "前哨恢复未完成，先回核心恢复生命 / 防护和补给"
	if definition_id == "map_object.signal_echo_cache":
		if not world_state.quest_state.has_completed_quest("quest.secure_outer_ring_signal"):
			return "先检查外圈中继台，锁定稳定回波"
		if (
			world_state.quest_state.has_active_quest("quest.salvage_signal_echo")
			and world_state.quest_state.get_objective_progress("quest.salvage_signal_echo", "gather_item", "item.polluted_residue") < 2.0
		):
			return "先回收守卫后暴露的污染回波沉积"
	if definition_id == "map_object.deep_signal_array":
		if not world_state.quest_state.has_completed_quest("quest.analyze_deep_core"):
			return "先回基地解析裂相样块"
		if character_state != null and not character_state.inventory.has_ref("item.deep_route_imprint", 1):
			return "缺少裂相路由印片"
	if definition_id == "map_object.demo_stabilization_core":
		if not world_state.quest_state.has_active_quest("quest.write_demo_stabilization_core"):
			return "写入任务或守卫缓存尚未归档到核心设备"
		if world_state.quest_state.get_objective_progress("quest.write_demo_stabilization_core", "gather_item", "item.core_write_charge") < 1.0:
			return "缺核心写入校验片，先回收守卫回写缓存"
	return ""
