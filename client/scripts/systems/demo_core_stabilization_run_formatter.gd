extends RefCounted
class_name DemoCoreStabilizationRunFormatter

const ENTRY_QUEST_ID := "quest.enter_demo_stabilization_core"
const BUFFER_QUEST_ID := "quest.prepare_demo_stabilization_buffer"
const GUARD_QUEST_ID := "quest.defeat_demo_stabilization_guard"
const WRITE_QUEST_ID := "quest.write_demo_stabilization_core"
const CORE_REGION_ID := "region.demo_stabilization_core"
const GUARD_INSTANCE_ID := "enemy_instance.demo_stabilization_guard"
const RECOVERY_CACHE_DEFINITION_ID := "map_object.demo_stabilization_recovery_cache"
const GUARD_CACHE_DEFINITION_ID := "map_object.demo_stabilization_guard_cache"
const CORE_DEVICE_DEFINITION_ID := "map_object.demo_stabilization_core"
const RUN_SEQUENCE_TEXT := "入口确认 -> 侧边补给 -> 稳压缓冲包 -> 阶段守卫 -> 回写缓存 -> 核心写入"

const CORE_QUEST_IDS := [
	ENTRY_QUEST_ID,
	BUFFER_QUEST_ID,
	GUARD_QUEST_ID,
	WRITE_QUEST_ID
]

const RUN_OBJECT_INFO := {
	"map_object.demo_stabilization_recovery_cache": {
		"stage": "侧边补给",
		"role": "守卫战前补给缓存",
		"placement": "侧边补给先给修复凝胶和抗污染药剂，随后会被守卫战和核心写入读取。"
	},
	"map_object.demo_stabilization_guard_cache": {
		"stage": "回写缓存",
		"role": "写入校验和战后补回",
		"placement": "守卫回写缓存必须在守卫败退后回收，校验片、基础零件和终点补给会一起入包。"
	},
	"map_object.demo_stabilization_core": {
		"stage": "核心写入",
		"role": "终点写入设备",
		"placement": "核心稳定设备只接受守卫败退、校验片和终点前准备都到位后的写入。"
	}
}


static func is_run_context(world_state: WorldState) -> bool:
	if world_state == null or DemoMainlineCompletionFormatter.is_demo_complete(world_state):
		return false
	if world_state.current_region_id == CORE_REGION_ID:
		return true
	for quest_id in CORE_QUEST_IDS:
		if world_state.quest_state.has_active_quest(quest_id) or world_state.quest_state.has_completed_quest(quest_id):
			return true
	return false


static func get_run_sequence_text() -> String:
	return RUN_SEQUENCE_TEXT


static func get_core_object_definition_ids() -> Array:
	return RUN_OBJECT_INFO.keys()


static func format_hud_summary(world_state: WorldState, character_state: CharacterState) -> Array[String]:
	if not is_run_context(world_state):
		return []
	return [
		"核心站内路径：%s；当前段：%s" % [
			RUN_SEQUENCE_TEXT,
			format_current_stage(world_state, character_state)
		],
		"站内状态：%s；下一步：%s" % [
			format_run_parts(world_state, character_state),
			format_next_step(world_state, character_state)
		]
	]


static func format_map_route_hint(
	world_state: WorldState,
	hint_region_id: String,
	_quest_id: String = "",
	character_state: CharacterState = null
) -> String:
	if hint_region_id != CORE_REGION_ID and not is_run_context(world_state):
		return ""
	if hint_region_id != CORE_REGION_ID and world_state.current_region_id != CORE_REGION_ID:
		return ""
	return "核心站内路径：%s；当前段：%s；下一步：%s" % [
		RUN_SEQUENCE_TEXT,
		format_current_stage(world_state, character_state),
		format_next_step(world_state, character_state)
	]


static func format_object_run_line(
	definition_id: String,
	object_state: Dictionary,
	world_state: WorldState,
	character_state: CharacterState,
	fallback_region_id: String = ""
) -> String:
	if not _should_show_object_line(definition_id, world_state, fallback_region_id):
		return ""
	var info := _get_object_info(definition_id)
	if info.is_empty():
		return ""
	return "核心站内路径：%s；对象职责：%s；状态：%s；%s；下一步：%s" % [
		String(info.get("stage", "")),
		String(info.get("role", "")),
		_format_object_status(definition_id, object_state, world_state, character_state),
		String(info.get("placement", "")),
		format_next_step(world_state, character_state)
	]


static func format_static_object_run_line(definition_id: String, fallback_region_id: String = "") -> String:
	if fallback_region_id != CORE_REGION_ID or not RUN_OBJECT_INFO.has(definition_id):
		return ""
	var info := _get_object_info(definition_id)
	return "核心站内路径：%s；对象职责：%s；%s" % [
		String(info.get("stage", "")),
		String(info.get("role", "")),
		String(info.get("placement", ""))
	]


static func format_result_followup_line(
	definition_id: String,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if definition_id == RECOVERY_CACHE_DEFINITION_ID:
		return "核心站内路径：侧边补给已回收；下一步：带核心稳压缓冲包处理阶段守卫。"
	if definition_id == GUARD_CACHE_DEFINITION_ID:
		return "核心站内路径：守卫回写缓存已回收；下一步：带校验片和补给写入核心稳定设备。"
	if definition_id == CORE_DEVICE_DEFINITION_ID:
		return "核心站内路径：核心写入已完成；下一步：沿外勤出发口回前哨整理 Demo 成果。"
	if not is_run_context(world_state):
		return ""
	return "核心站内路径：当前段 %s；下一步：%s" % [
		format_current_stage(world_state, character_state),
		format_next_step(world_state, character_state)
	]


static func format_guard_defeat_followup(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state == null:
		return ""
	return " 核心站内路径：阶段守卫已击败；下一步：%s" % format_next_step(world_state, character_state)


static func format_current_stage(world_state: WorldState, character_state: CharacterState = null) -> String:
	if world_state == null:
		return "入口确认"
	if not world_state.quest_state.has_completed_quest(ENTRY_QUEST_ID):
		return "入口确认"
	if not world_state.quest_state.has_completed_quest(BUFFER_QUEST_ID):
		return "稳压缓冲包回站" if _has_core_buffer(character_state) else "稳压缓冲包整备"
	if not CoreStabilizationPressureFormatter.has_recovery_cache(world_state):
		return "侧边补给"
	if not _has_guard_defeated(world_state):
		return "阶段守卫"
	if not CoreStabilizationPressureFormatter.has_guard_cache(world_state):
		return "回写缓存"
	return "核心写入"


static func format_run_parts(world_state: WorldState, character_state: CharacterState) -> String:
	var parts: Array[String] = []
	parts.append("入口已确认" if world_state.quest_state.has_completed_quest(ENTRY_QUEST_ID) else "入口待确认")
	parts.append("侧边补给已取" if CoreStabilizationPressureFormatter.has_recovery_cache(world_state) else "侧边补给待取")
	if CoreStabilizationPressureFormatter.has_guard_buffer_sync(world_state):
		parts.append("缓冲包已回写")
	elif _has_core_buffer(character_state):
		parts.append("缓冲包在身")
	else:
		parts.append("缓冲包待整备")
	parts.append("守卫已击败" if _has_guard_defeated(world_state) else "守卫待处理")
	parts.append("回写缓存已取" if CoreStabilizationPressureFormatter.has_guard_cache(world_state) else "回写缓存待回收")
	parts.append("校验片在身" if _has_core_write_charge(world_state, character_state) else "校验片待取得")
	return "；".join(parts)


static func format_next_step(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state == null:
		return "进入核心稳定站并按站内路径确认入口、补给、守卫和写入"
	if not world_state.quest_state.has_completed_quest(ENTRY_QUEST_ID):
		return "从锚定桥进入核心稳定站，确认入口场、侧边补给和核心设备"
	if not world_state.quest_state.has_completed_quest(BUFFER_QUEST_ID):
		if _has_core_buffer(character_state):
			return "带核心稳压缓冲包回核心稳定站，先取侧边补给再挑战守卫"
		return "回污染边界补料并回基地整备核心稳压缓冲包"
	if not CoreStabilizationPressureFormatter.has_recovery_cache(world_state):
		return "先回收核心站侧边补给缓存，再进入守卫场"
	if not _has_guard_defeated(world_state):
		if character_state != null and not character_state.are_vitals_full():
			return "先回前哨核心恢复生命 / 防护，再回来处理核心阶段守卫"
		return "在守卫场处理核心阶段守卫，缓冲包、侧边补给和药剂会降低承压"
	if not CoreStabilizationPressureFormatter.has_guard_cache(world_state):
		return "回收守卫回写缓存，取得核心写入校验片和终点补给"
	if not world_state.quest_state.has_active_quest(WRITE_QUEST_ID):
		return "确认写入任务已归档到核心设备，再带校验片靠近写入平台"
	if not _has_core_write_charge(world_state, character_state):
		return "确认核心写入校验片已从守卫缓存入包，再靠近核心设备"
	if character_state != null and not character_state.are_vitals_full():
		return "先回前哨核心恢复生命 / 防护，再写入核心稳定设备"
	if character_state != null and DepartureSupplyRuntime.get_resistance_vial_count(character_state) < 1:
		return "先回前哨核心或过滤器补抗污染药剂，再写入核心稳定设备"
	return "在核心稳定设备写入核心稳定数据"


static func _should_show_object_line(
	definition_id: String,
	world_state: WorldState,
	fallback_region_id: String
) -> bool:
	if not RUN_OBJECT_INFO.has(definition_id):
		return false
	if fallback_region_id == CORE_REGION_ID:
		return true
	return is_run_context(world_state)


static func _get_object_info(definition_id: String) -> Dictionary:
	return RUN_OBJECT_INFO.get(definition_id, {})


static func _format_object_status(
	definition_id: String,
	object_state: Dictionary,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if definition_id == RECOVERY_CACHE_DEFINITION_ID:
		return "已回收" if bool(object_state.get("is_gathered", false)) else "待回收"
	if definition_id == GUARD_CACHE_DEFINITION_ID:
		if bool(object_state.get("is_gathered", false)):
			return "已回收"
		return "待回收" if _has_guard_defeated(world_state) else "守卫仍在"
	if definition_id == CORE_DEVICE_DEFINITION_ID:
		if _has_core_write_charge(world_state, character_state) and world_state.quest_state.has_active_quest(WRITE_QUEST_ID):
			return "可写入"
		if _has_guard_defeated(world_state):
			return "待校验片"
		return "守卫压制中"
	return "待处理"


static func _has_guard_defeated(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return (
		world_state.quest_state.has_completed_quest(GUARD_QUEST_ID)
		or bool(world_state.get_enemy(GUARD_INSTANCE_ID).get("is_defeated", false))
	)


static func _has_core_buffer(character_state: CharacterState) -> bool:
	return character_state != null and character_state.inventory.has_ref("item.core_stabilization_buffer", 1)


static func _has_core_write_charge(world_state: WorldState, character_state: CharacterState) -> bool:
	if character_state != null and character_state.inventory.has_ref("item.core_write_charge", 1):
		return true
	if world_state == null:
		return false
	return world_state.quest_state.get_objective_progress(WRITE_QUEST_ID, "gather_item", "item.core_write_charge") >= 1.0
