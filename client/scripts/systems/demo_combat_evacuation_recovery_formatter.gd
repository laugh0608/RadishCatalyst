extends RefCounted
class_name DemoCombatEvacuationRecoveryFormatter

const OUTPOST_REGION_ID := "region.outpost_platform"
const CORE_REGION_ID := "region.demo_stabilization_core"

const REGION_LABELS := {
	"region.outpost_platform": "前哨平台",
	"region.crystal_vein_field": "晶体矿脉",
	"region.pollution_edge": "污染边界",
	"region.ruin_outer_ring": "遗迹外圈",
	"region.deep_ruin_threshold": "裂相脊",
	"region.inner_phase_well": "回声台地",
	"region.phase_well_sink": "盐壳浅滩",
	"region.phase_well_chamber": "碎晶沟谷",
	"region.phase_well_loom": "风蚀管廊",
	"region.phase_well_frame": "锁相框架",
	"region.phase_well_tether": "锚定桥",
	"region.demo_stabilization_core": "核心稳定站"
}

const QUEST_ROUTE_LABELS := {
	"quest.enter_pollution_edge": "污染边界排压",
	"quest.unlock_ruin_signal": "封锁遗迹入口",
	"quest.salvage_signal_echo": "遗迹外圈回波匣",
	"quest.enter_deep_ruin_threshold": "裂相脊入口",
	"quest.activate_deep_array": "裂相阵列",
	"quest.reenter_phase_frontline": "前线回投路线",
	"quest.enter_demo_stabilization_core": "核心稳定站入口",
	"quest.prepare_demo_stabilization_buffer": "核心写入缓冲",
	"quest.defeat_demo_stabilization_guard": "核心守卫战",
	"quest.write_demo_stabilization_core": "核心稳定写入"
}

const RECOVERY_CONTEXT_QUEST_IDS := [
	"quest.enter_pollution_edge",
	"quest.unlock_ruin_signal",
	"quest.salvage_signal_echo",
	"quest.enter_deep_ruin_threshold",
	"quest.activate_deep_array",
	"quest.reenter_phase_frontline",
	"quest.enter_demo_stabilization_core",
	"quest.prepare_demo_stabilization_buffer",
	"quest.defeat_demo_stabilization_guard",
	"quest.write_demo_stabilization_core"
]


static func build_feedback(
	character_state: CharacterState,
	world_state: WorldState,
	reason: String,
	origin_region_id: String,
	health_depleted: bool,
	protection_depleted: bool
) -> Dictionary:
	var reason_text := format_depletion_reason(health_depleted, protection_depleted)
	var recovery_text := "已撤回前哨；生命恢复到 %s，防护恢复到 %s" % [
		_format_amount(character_state.health),
		_format_amount(character_state.protection)
	]
	var retry_text := format_retry_hint(reason, health_depleted, protection_depleted)
	var retained_text := format_retained_progress(world_state, origin_region_id)
	var recovery_action_text := format_recovery_action(character_state, health_depleted, protection_depleted)
	var next_target_text := format_next_target(world_state, origin_region_id)
	return {
		"title": "撤离前哨",
		"reason_text": reason_text,
		"origin_region_id": origin_region_id,
		"origin_text": "撤离来源：%s" % _format_region_label(origin_region_id),
		"recovery_text": recovery_text,
		"retained_progress_text": retained_text,
		"recovery_action_text": recovery_action_text,
		"next_target_text": next_target_text,
		"retry_text": retry_text,
		"log_message": " %s，%s。保留进度：%s；恢复动作：%s；继续目标：%s。%s" % [
			reason_text,
			recovery_text,
			retained_text,
			recovery_action_text,
			next_target_text,
			retry_text
		]
	}


static func format_panel_detail_lines(feedback: Dictionary) -> Array[String]:
	if feedback.is_empty():
		return []
	var details: Array[String] = []
	_append_detail(details, "原因：%s" % String(feedback.get("reason_text", "状态过低")))
	_append_detail(details, String(feedback.get("origin_text", "")))
	_append_detail(details, "恢复：%s" % String(feedback.get("recovery_text", "已撤回前哨。")))
	_append_detail(details, "保留进度：%s" % String(feedback.get("retained_progress_text", "")))
	_append_detail(details, "恢复动作：%s" % String(feedback.get("recovery_action_text", "")))
	_append_detail(details, "继续目标：%s" % String(feedback.get("next_target_text", "")))
	_append_detail(details, _format_retry_detail(String(feedback.get("retry_text", "再尝试前：补充快捷栏物品。"))))
	return details


static func format_hud_summary(world_state: WorldState, character_state: CharacterState) -> Array[String]:
	if not _is_outpost_recovery_context(world_state, character_state):
		return []
	return [
		"撤离恢复：生命 %s / %s，防护 %s / %s；%s" % [
			_format_amount(character_state.health),
			_format_amount(character_state.max_health),
			_format_amount(character_state.protection),
			_format_amount(character_state.max_protection),
			format_recovery_action(character_state, false, false)
		],
		"恢复下一步：保留进度：%s；继续目标：%s" % [
			format_retained_progress(world_state),
			format_next_target(world_state)
		]
	]


static func format_map_route_hint(
	world_state: WorldState,
	quest_id: String,
	character_state: CharacterState = null
) -> String:
	if not _is_outpost_recovery_context(world_state, character_state):
		return ""
	var target_text := format_next_target(world_state, "", quest_id)
	return "撤离恢复 · %s · 保留进度：%s · 继续目标：%s" % [
		format_recovery_action(character_state, false, false),
		format_retained_progress(world_state),
		target_text
	]


static func format_outpost_core_recovery_line(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if not _is_outpost_recovery_context(world_state, character_state):
		return ""
	return "撤离恢复：%s；保留进度：%s；继续目标：%s" % [
		format_recovery_action(character_state, false, false),
		format_retained_progress(world_state),
		format_next_target(world_state)
	]


static func format_departure_gate_status_line(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if not _is_outpost_recovery_context(world_state, character_state):
		return ""
	return "撤离恢复未完成：生命 / 防护 %s / %s；先完成前哨恢复再出发" % [
		_format_amount(character_state.health),
		_format_amount(character_state.protection)
	]


static func format_departure_gate_next_step(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if not _is_outpost_recovery_context(world_state, character_state):
		return ""
	return "%s；随后%s" % [
		format_recovery_action(character_state, false, false),
		format_next_target(world_state)
	]


static func format_outfitting_station_recovery_line(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if not _is_outpost_recovery_context(world_state, character_state):
		return ""
	return "撤离恢复：若本趟承压来自防护或核心站，确认模块 / 整备状态后再回出发口继续。"


static func format_depletion_reason(health_depleted: bool, protection_depleted: bool) -> String:
	if health_depleted and protection_depleted:
		return "生命和防护耗尽"
	if health_depleted:
		return "生命耗尽"
	if protection_depleted:
		return "防护耗尽"
	return "状态过低"


static func format_retry_hint(reason: String, health_depleted: bool, protection_depleted: bool) -> String:
	if health_depleted and protection_depleted:
		return "再尝试前：按 E 整备前哨核心回满生命与防护；按 1 补修复凝胶，按 2 补抗污染药剂。"
	if health_depleted:
		return "再尝试前：按 1 使用修复凝胶，或在前哨核心恢复生命；回基地用基础反应器调制补给。"
	if protection_depleted:
		return "再尝试前：启用过滤模块，按 2 使用抗污染药剂，或回基地处理污染沉积物补充药剂。"
	if reason == "pollution":
		return "再尝试前：检查防护、过滤模块和抗污染药剂。"
	return "再尝试前：补充快捷栏物品。"


static func format_recovery_action(
	character_state: CharacterState,
	health_depleted: bool = false,
	protection_depleted: bool = false
) -> String:
	if character_state == null:
		return "回前哨核心确认生命、防护和快捷栏补给"
	var needs_health := health_depleted or character_state.health < character_state.max_health
	var needs_protection := protection_depleted or character_state.protection < character_state.max_protection
	if needs_health and needs_protection:
		return "在前哨核心回满生命 / 防护，并补修复凝胶和抗污染药剂"
	if needs_health:
		return "在前哨核心回满生命，并补修复凝胶"
	if needs_protection:
		return "在前哨核心回满防护，检查过滤模块并补抗污染药剂"
	return "确认出发整备与快捷栏后返回当前外勤目标"


static func format_retained_progress(world_state: WorldState, origin_region_id: String = "") -> String:
	if world_state == null:
		return "当前任务、敌人和对象状态保留"
	if DemoMainlineCompletionFormatter.is_demo_complete(world_state):
		return "Demo 写入、守卫记录、前哨收益和复测状态保留"
	if _has_demo_guard_evidence(world_state):
		return "核心守卫状态、守卫缓存和写入准备保留"
	if origin_region_id == "region.pollution_edge" or _has_active_quest(world_state, "quest.enter_pollution_edge"):
		return "污染采集、过滤处理、已清理敌人与当前任务进度保留"
	if origin_region_id == "region.ruin_outer_ring":
		return "遗迹外圈回波、门前压力和已处理对象状态保留"
	if _is_deep_region(origin_region_id):
		return "深段锚点、已击败敌人、读数对象和当前任务进度保留"
	if not world_state.quest_state.active_quest_ids.is_empty():
		return "当前任务进度、敌人状态和已交互对象保留"
	return "世界位置外的任务、敌人、对象和库存状态保留"


static func format_next_target(
	world_state: WorldState,
	origin_region_id: String = "",
	quest_id: String = ""
) -> String:
	if world_state == null:
		return "恢复后按当前目标继续"
	if DemoMainlineCompletionFormatter.is_demo_complete(world_state):
		return "回前哨核心整理 Demo 成果；不新增必需后续任务"
	var active_quest_id := quest_id
	if active_quest_id.is_empty() and not world_state.quest_state.active_quest_ids.is_empty():
		active_quest_id = String(world_state.quest_state.active_quest_ids[0])
	if not active_quest_id.is_empty():
		return "从地图回到%s继续%s" % [
			_format_target_region_for_quest(active_quest_id, origin_region_id),
			_format_quest_route_label(active_quest_id)
		]
	if not origin_region_id.is_empty() and origin_region_id != OUTPOST_REGION_ID:
		return "从地图回到%s继续当前外勤目标" % _format_region_label(origin_region_id)
	return "完成前哨恢复后按地图目标继续外勤"


static func _is_outpost_recovery_context(world_state: WorldState, character_state: CharacterState) -> bool:
	if world_state == null or character_state == null:
		return false
	if world_state.current_region_id != OUTPOST_REGION_ID:
		return false
	if DemoMainlineCompletionFormatter.is_demo_complete(world_state):
		return false
	if not _has_recovery_context_quest(world_state):
		return false
	return not character_state.are_vitals_full()


static func _format_target_region_for_quest(quest_id: String, origin_region_id: String) -> String:
	if not origin_region_id.is_empty() and origin_region_id != OUTPOST_REGION_ID:
		return _format_region_label(origin_region_id)
	match quest_id:
		"quest.enter_pollution_edge":
			return "污染边界"
		"quest.unlock_ruin_signal", "quest.salvage_signal_echo":
			return "遗迹外圈"
		"quest.enter_deep_ruin_threshold", "quest.activate_deep_array", "quest.reenter_phase_frontline":
			return "深段路线"
		"quest.enter_demo_stabilization_core", "quest.prepare_demo_stabilization_buffer", "quest.defeat_demo_stabilization_guard", "quest.write_demo_stabilization_core":
			return "核心稳定站"
		_:
			return "当前目标区域"


static func _format_quest_route_label(quest_id: String) -> String:
	if QUEST_ROUTE_LABELS.has(quest_id):
		return String(QUEST_ROUTE_LABELS[quest_id])
	return "当前任务"


static func _format_region_label(region_id: String) -> String:
	if REGION_LABELS.has(region_id):
		return String(REGION_LABELS[region_id])
	if region_id.is_empty():
		return "当前区域"
	return region_id


static func _is_deep_region(region_id: String) -> bool:
	return [
		"region.deep_ruin_threshold",
		"region.inner_phase_well",
		"region.phase_well_sink",
		"region.phase_well_chamber",
		"region.phase_well_loom",
		"region.phase_well_frame",
		"region.phase_well_tether"
	].has(region_id)


static func _has_active_quest(world_state: WorldState, quest_id: String) -> bool:
	if world_state == null:
		return false
	return world_state.quest_state.has_active_quest(quest_id)


static func _has_recovery_context_quest(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	for quest_id in world_state.quest_state.active_quest_ids:
		if RECOVERY_CONTEXT_QUEST_IDS.has(String(quest_id)):
			return true
	return _has_demo_guard_evidence(world_state)


static func _has_demo_guard_evidence(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	var guard := world_state.get_enemy("enemy_instance.demo_stabilization_guard")
	if bool(guard.get("is_defeated", false)) or bool(guard.get("core_buffer_used", false)):
		return true
	var guard_cache := world_state.get_map_object("map_object_instance.demo_stabilization_guard_cache")
	if bool(guard_cache.get("is_gathered", false)):
		return true
	return world_state.quest_state.has_completed_quest("quest.defeat_demo_stabilization_guard")


static func _format_retry_detail(retry_text: String) -> String:
	if retry_text.strip_edges().is_empty():
		return ""
	if retry_text.begins_with("再尝试前："):
		return retry_text
	return "再尝试前：%s" % retry_text


static func _append_detail(details: Array[String], text: String) -> void:
	if text.strip_edges().is_empty():
		return
	details.append(text)


static func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount
