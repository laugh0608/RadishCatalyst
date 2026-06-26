extends RefCounted
class_name DemoActionFeedbackFormatter


static func format_gather_success_feedback(
	object_name: String,
	definition_id: String,
	instance_id: String,
	rewards: Array[String],
	protection_drain: float,
	world_state: WorldState,
	character_state: CharacterState
) -> Dictionary:
	var status_parts: Array[String] = ["对象状态已写入已采集"]
	if protection_drain > 0.0:
		status_parts.append("防护 -%s" % _format_amount(protection_drain))
	var destination := "现场保留已采集标记。"
	if not rewards.is_empty():
		destination = "获得已放入背包：%s。" % ", ".join(rewards)
	return {
		"title": "采集完成：%s" % object_name,
		"status": "；".join(status_parts),
		"destination": destination,
		"next_step": _get_gather_next_step(definition_id, instance_id, world_state, character_state)
	}


static func format_sample_success_feedback(
	object_name: String,
	definition_id: String,
	rewards: Array[String],
	world_state: WorldState
) -> Dictionary:
	var destination := "现场保留已采样标记。"
	if not rewards.is_empty():
		destination = "样本已放入背包：%s。" % ", ".join(rewards)
	return {
		"title": "采样完成：%s" % object_name,
		"status": "对象状态已写入已采样",
		"destination": destination,
		"next_step": _get_sample_next_step(definition_id, world_state)
	}


static func format_clear_success_feedback(
	object_name: String,
	definition_id: String,
	next_step_override: String = ""
) -> Dictionary:
	return {
		"title": "清障完成：%s" % object_name,
		"status": "对象状态已写入已清理",
		"destination": "现场保留已清理标记。",
		"next_step": next_step_override if not next_step_override.is_empty() else _get_clear_next_step(definition_id)
	}


static func format_core_write_success_feedback(
	pressure_text: String,
	world_state: WorldState,
	character_state: CharacterState
) -> Dictionary:
	return {
		"title": "核心写入完成",
		"status": "核心稳定设备已写入；%s" % _compact_sentence(pressure_text),
		"destination": "核心设备对象状态已写入；Demo 完成成果会进入 HUD、地图和前哨核心。",
		"next_step": _get_core_write_next_step(world_state, character_state)
	}


static func format_enemy_defeat_success_feedback(
	enemy_name: String,
	enemy_definition_id: String,
	drops_message: String,
	followup: String
) -> Dictionary:
	var destination := "敌人状态已写入已击败。"
	if not drops_message.strip_edges().is_empty():
		destination = drops_message.strip_edges().trim_suffix("。")
	return {
		"title": "击败：%s" % enemy_name,
		"status": "敌人状态已写入已击败",
		"destination": destination,
		"next_step": followup if not followup.strip_edges().is_empty() else _get_enemy_next_step(enemy_definition_id)
	}


static func format_outpost_core_success_feedback(
	title: String,
	detail: String,
	next_step: String
) -> Dictionary:
	return {
		"title": title,
		"status": detail,
		"destination": "前哨核心已刷新生命、防护、补给和出发检查读法。",
		"next_step": next_step
	}


static func _get_gather_next_step(
	definition_id: String,
	instance_id: String,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if instance_id == "map_object_instance.demo_stabilization_guard_cache":
		return "守卫回写缓存已入包；回核心稳定设备写入核心稳定数据。"
	if instance_id == CoreStabilizationPressureFormatter.RETEST_READOUT_INSTANCE_ID:
		return "复测读数已带回；沿外勤出发口回前哨核心整理下一趟外勤。"
	if instance_id == "map_object_instance.outer_ring_echo_residue_cache":
		return "回过滤器处理污染回波沉积，再带回波匣回基地解析裂相坐标。"
	if definition_id == "map_object.pollution_residue_patch":
		return "回污染过滤器处理沉积物，补抗污染药剂并保留污染浆液。"
	if definition_id == "map_object.crystal_collector_output":
		return "采集器输出已收取；回基础反应器加工晶体矿，补基础零件或后续设备。"
	if definition_id == "map_object.crystal_cluster" or definition_id == "map_object.rich_crystal_vein":
		return "回基础反应器加工晶体矿，补基础零件或地基材料。"
	if definition_id == "map_object.field_wreckage":
		return "回基础反应器或出发整备台，把残骸废件转成基建 / 维护收益。"
	if world_state != null and not world_state.quest_state.active_quest_ids.is_empty():
		return "按 HUD / 地图当前目标继续：%s。" % String(world_state.quest_state.active_quest_ids[0])
	return "按 HUD / 地图当前目标继续。"


static func _get_sample_next_step(definition_id: String, world_state: WorldState) -> String:
	if definition_id == "map_object.anomaly_crystal":
		return "回基地用基础反应器解析异常样本。"
	if world_state != null and not world_state.quest_state.active_quest_ids.is_empty():
		return "样本已写入；按当前任务继续：%s。" % String(world_state.quest_state.active_quest_ids[0])
	return "样本已写入；按 HUD / 地图当前目标继续。"


static func _get_clear_next_step(definition_id: String) -> String:
	match definition_id:
		"map_object.rough_ground":
			return "清理后可铺设基础地基。"
		"map_object.pressure_clearance_node":
			return "带回压力清障回执，回基地用基础反应器解析防护收益。"
		"map_object.phase_well_anchor_pressure_pin":
			return "继续清掉剩余压力钉，再压制稳场守脉体。"
		"map_object.phase_well_frame_route_blocker":
			return "边缕残条回收线已打开，继续回收侧路材料。"
		"map_object.well_ash_crust_blocker":
			return "盐壳余烬回收线已打开，继续处理浅滩材料。"
	return "清障状态已写入；按 HUD / 地图当前目标继续。"


static func _get_core_write_next_step(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if world_state != null and DemoMainlineCompletionFormatter.is_demo_complete(world_state):
		return "沿外勤出发口回前哨核心整理 Demo 成果。"
	if character_state != null and not character_state.are_vitals_full():
		return "写入后生命 / 防护有消耗；回前哨核心恢复并整理成果。"
	return "核心写入已完成；回前哨核心整理 Demo 成果。"


static func _get_enemy_next_step(enemy_definition_id: String) -> String:
	if enemy_definition_id == "enemy.demo_stabilization_guard":
		return "先回收守卫后的回写缓存，再写入核心稳定设备。"
	if enemy_definition_id == "enemy.ruin_phase_guard":
		return "先回收污染回波沉积，再带回波匣回基地解析。"
	return "敌人已击败；按 HUD / 地图当前目标继续。"


static func _compact_sentence(text: String) -> String:
	var compact := text.strip_edges().trim_prefix("。").trim_prefix("，")
	compact = compact.trim_suffix("。")
	if compact.is_empty():
		return "状态变化已结算"
	return compact


static func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount
