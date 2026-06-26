extends RefCounted
class_name DemoFunctionalSceneGameplayDensityFormatter

const REGION_IDS := [
	"region.phase_well_frame",
	"region.phase_well_tether"
]

const REGION_INFO := {
	"region.phase_well_frame": {
		"title": "锁相框架小循环",
		"return": "回基地稳定边缕残条并组装锁相键栓，再回框架断面析出锚定结核。"
	},
	"region.phase_well_tether": {
		"title": "锚定桥小循环",
		"return": "回基地处理锚索残股并组装锚定桩，把锚场回稳窗接向核心稳定工程。"
	}
}

const REGION_STEPS := {
	"region.phase_well_frame": [
		{
			"definition_id": "map_object.phase_well_frame_route_blocker",
			"label": "清理锁相侧路",
			"pending": "先清开侧路障，让边缕残条回收线露出来。",
			"complete": "侧路已打开，边缕残条回收线露出。",
			"quest_id": "quest.collect_selvedge_strip",
			"objective_type": "clear",
			"objective_target_id": "map_object.phase_well_frame_route_blocker",
			"required": 1.0,
			"required_instances": 1
		},
		{
			"definition_id": "map_object.selvedge_strip_cluster",
			"label": "回收边缕残条",
			"pending": "回收两处边缕残条，让锁相框架整备有真实材料。",
			"complete": "边缕残条已回收，基地可以稳定并组装锁相键栓。",
			"quest_id": "quest.collect_selvedge_strip",
			"objective_type": "gather_item",
			"objective_target_id": "item.selvedge_strip",
			"required": 2.0,
			"required_instances": 2
		},
		{
			"definition_id": "map_object.phase_well_frame",
			"label": "勘验锁相框架断面",
			"pending": "带锁相键栓回到框架断面，确认锚定桥前置收益。",
			"complete": "框架断面已勘验，锚定结核进入基地解析。",
			"quest_id": "quest.inspect_phase_well_frame",
			"objective_type": "inspect",
			"objective_target_id": "map_object.phase_well_frame",
			"required": 1.0,
			"required_instances": 1
		}
	],
	"region.phase_well_tether": [
		{
			"definition_id": "map_object.phase_well_tether_knot_node",
			"label": "确认锚索结点",
			"pending": "先确认两端锚索结点，让锚索残股松开。",
			"complete": "锚索结点已确认，锚索残股回收线打开。",
			"quest_id": "quest.collect_tether_fiber",
			"objective_type": "inspect",
			"objective_target_id": "map_object.phase_well_tether_knot_node",
			"required": 2.0,
			"required_instances": 2
		},
		{
			"definition_id": "map_object.tether_fiber_cluster",
			"label": "回收锚索残股",
			"pending": "回收两处锚索残股，让锚定桥整备有真实材料。",
			"complete": "锚索残股已回收，基地可以稳定并组装锚定桩。",
			"quest_id": "quest.collect_tether_fiber",
			"objective_type": "gather_item",
			"objective_target_id": "item.tether_fiber",
			"required": 2.0,
			"required_instances": 2
		},
		{
			"definition_id": "map_object.phase_well_tether",
			"label": "勘验锚定桥断面",
			"pending": "带锚定桩回到桥体断面，确认锚场回稳前置收益。",
			"complete": "锚定桥断面已勘验，稳场锚核进入基地解析。",
			"quest_id": "quest.inspect_phase_well_tether",
			"objective_type": "inspect",
			"objective_target_id": "map_object.phase_well_tether",
			"required": 1.0,
			"required_instances": 1
		}
	]
}

const DEFINITION_REGION_IDS := {
	"map_object.phase_well_frame_route_blocker": "region.phase_well_frame",
	"map_object.selvedge_strip_cluster": "region.phase_well_frame",
	"map_object.phase_well_frame": "region.phase_well_frame",
	"map_object.phase_well_tether_knot_node": "region.phase_well_tether",
	"map_object.tether_fiber_cluster": "region.phase_well_tether",
	"map_object.phase_well_tether": "region.phase_well_tether"
}

const ACTIVE_QUEST_REGION_IDS := {
	"quest.collect_selvedge_strip": "region.phase_well_frame",
	"quest.refine_selvedge_strip": "region.phase_well_frame",
	"quest.inspect_phase_well_frame": "region.phase_well_frame",
	"quest.collect_tether_fiber": "region.phase_well_tether",
	"quest.refine_tether_fiber": "region.phase_well_tether",
	"quest.inspect_phase_well_tether": "region.phase_well_tether"
}


static func get_region_ids() -> Array:
	return REGION_IDS.duplicate()


static func format_hud_summary(world_state: WorldState, _character_state: CharacterState = null) -> Array[String]:
	if world_state == null:
		return []
	var region_id := String(world_state.current_region_id)
	if not REGION_IDS.has(region_id) or not _has_density_context(world_state, region_id):
		return []
	return [
		"玩法密度：%s；步骤进度：%s" % [_get_region_text(region_id, "title"), _format_region_progress(world_state, region_id)],
		"当前小循环：%s；回基地：%s" % [_get_next_step_text(world_state, region_id), _get_region_text(region_id, "return")]
	]


static func format_object_density_line(
	definition_id: String,
	object_state: Dictionary,
	fallback_region_id: String = ""
) -> String:
	var step := _get_step_for_definition(definition_id, fallback_region_id)
	if step.is_empty():
		return ""
	var region_id := String(step.get("region_id", _get_region_id_for_definition(definition_id, fallback_region_id)))
	var processed := _is_object_state_processed(object_state)
	var status := "已处理" if processed else "待处理"
	var step_text := String(step.get("complete", "")) if processed else String(step.get("pending", ""))
	return "玩法密度：%s；步骤：%s；状态：%s；%s" % [
		_get_region_text(region_id, "title"),
		String(step.get("label", "")),
		status,
		step_text
	]


static func format_static_object_density_line(definition_id: String, fallback_region_id: String = "") -> String:
	var step := _get_step_for_definition(definition_id, fallback_region_id)
	if step.is_empty():
		return ""
	var region_id := String(step.get("region_id", _get_region_id_for_definition(definition_id, fallback_region_id)))
	return "玩法密度：%s；步骤：%s；%s" % [
		_get_region_text(region_id, "title"),
		String(step.get("label", "")),
		String(step.get("pending", ""))
	]


static func format_result_followup_line(
	definition_id: String,
	world_state: WorldState = null,
	fallback_region_id: String = ""
) -> String:
	var step := _get_step_for_definition(definition_id, fallback_region_id)
	if step.is_empty():
		return ""
	var region_id := String(step.get("region_id", _get_region_id_for_definition(definition_id, fallback_region_id)))
	var done_text := "已完成" if _is_step_complete(world_state, step) else "已推进"
	return "玩法密度：%s%s；下一步：%s；回基地：%s" % [
		String(step.get("label", "")),
		done_text,
		_get_next_step_after_definition(world_state, region_id, definition_id),
		_get_region_text(region_id, "return")
	]


static func _format_region_progress(world_state: WorldState, region_id: String) -> String:
	var completed := 0
	var steps: Array = REGION_STEPS.get(region_id, [])
	for step in steps:
		if _is_step_complete(world_state, step):
			completed += 1
	return "%d/%d" % [completed, steps.size()]


static func _has_density_context(world_state: WorldState, region_id: String) -> bool:
	for quest_id in world_state.quest_state.active_quest_ids:
		if String(ACTIVE_QUEST_REGION_IDS.get(String(quest_id), "")) == region_id:
			return true
	for object_state in world_state.map_objects.values():
		if not object_state is Dictionary:
			continue
		if _get_region_id_for_definition(String(object_state.get("definition_id", "")), "") == region_id:
			return true
	return false


static func _get_next_step_text(world_state: WorldState, region_id: String) -> String:
	for step in REGION_STEPS.get(region_id, []):
		if not _is_step_complete(world_state, step):
			return String(step.get("pending", ""))
	return "本区域小循环已处理，回基地整理产物并接入下一段路线。"


static func _get_next_step_after_definition(world_state: WorldState, region_id: String, definition_id: String) -> String:
	var seen_definition := false
	for step in REGION_STEPS.get(region_id, []):
		if String(step.get("definition_id", "")) == definition_id:
			if not _is_step_complete(world_state, step):
				return String(step.get("pending", ""))
			seen_definition = true
			continue
		if seen_definition and not _is_step_complete(world_state, step):
			return String(step.get("pending", ""))
	return "本区域小循环已处理，回基地整理产物并接入下一段路线。"


static func _is_step_complete(world_state: WorldState, step: Dictionary) -> bool:
	if world_state == null:
		return false
	var quest_id := String(step.get("quest_id", ""))
	if not quest_id.is_empty() and world_state.quest_state.has_completed_quest(quest_id):
		return true
	var objective_type := String(step.get("objective_type", ""))
	var objective_target_id := String(step.get("objective_target_id", ""))
	var required := float(step.get("required", 1.0))
	if not quest_id.is_empty() and not objective_type.is_empty() and not objective_target_id.is_empty():
		if world_state.quest_state.get_objective_progress(quest_id, objective_type, objective_target_id) >= required:
			return true
	var required_instances := int(step.get("required_instances", 1))
	return _count_processed_objects(world_state, String(step.get("definition_id", ""))) >= required_instances


static func _count_processed_objects(world_state: WorldState, definition_id: String) -> int:
	var processed_count := 0
	for object_state in world_state.map_objects.values():
		if not object_state is Dictionary:
			continue
		if String(object_state.get("definition_id", "")) == definition_id and _is_object_state_processed(object_state):
			processed_count += 1
	return processed_count


static func _is_object_state_processed(object_state: Dictionary) -> bool:
	return (
		bool(object_state.get("is_gathered", false))
		or bool(object_state.get("is_sampled", false))
		or bool(object_state.get("is_cleared", false))
	)


static func _get_step_for_definition(definition_id: String, fallback_region_id: String) -> Dictionary:
	var region_id := _get_region_id_for_definition(definition_id, fallback_region_id)
	for step in REGION_STEPS.get(region_id, []):
		if String(step.get("definition_id", "")) == definition_id:
			var step_copy: Dictionary = step.duplicate()
			step_copy["region_id"] = region_id
			return step_copy
	return {}


static func _get_region_id_for_definition(definition_id: String, fallback_region_id: String) -> String:
	if DEFINITION_REGION_IDS.has(definition_id):
		return String(DEFINITION_REGION_IDS[definition_id])
	if REGION_IDS.has(fallback_region_id):
		return fallback_region_id
	return ""


static func _get_region_text(region_id: String, key: String) -> String:
	var info: Dictionary = REGION_INFO.get(region_id, {})
	return String(info.get(key, ""))
