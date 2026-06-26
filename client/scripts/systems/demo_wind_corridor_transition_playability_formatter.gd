extends RefCounted
class_name DemoWindCorridorTransitionPlayabilityFormatter

const REGION_IDS := [
	"region.phase_well_loom"
]

const REGION_INFO := {
	"region.phase_well_loom": {
		"title": "风蚀管廊过渡路径",
		"entrance": "从碎晶沟谷带回风蚀张力核并完成解析后，进入旧管廊入口。",
		"boundary": "两处张力绕轮把入口管线和纬束回收线分开，确认后再进入断面。",
		"hazard": "风蚀纠缠体压在旧管廊中段，张力抖动会把资源线拉回高压状态。",
		"resource": "纬束残团分布在管廊南北两侧，服务风蚀梭栓和锁相织构核解析。",
		"facility": "风蚀管廊断面在东侧，勘验后把锁相织构核带回基地。",
		"return": "回基地稳定纬束残团并解析锁相织构核，打开锁相框架入口。",
		"next": "完成风蚀解析后，向东进入锁相框架；本包只承接入口，不重做框架小循环。"
	}
}

const OBJECT_ROUTE_INFO := {
	"map_object.phase_well_loom_tension_spool": {
		"region_id": "region.phase_well_loom",
		"role": "入口边界",
		"placement": "两处张力绕轮压住旧管廊入口，写入后纬束回收线稳定。"
	},
	"map_object.weft_bundle_cluster": {
		"region_id": "region.phase_well_loom",
		"role": "资源",
		"placement": "南北两侧纬束残团让玩家确认管廊宽度和回收路线。"
	},
	"map_object.phase_well_loom": {
		"region_id": "region.phase_well_loom",
		"role": "设施",
		"placement": "东侧断面把锁相织构核送回基地解析，接到锁相框架。"
	},
	"map_object.phase_well_frame_route_blocker": {
		"region_id": "region.phase_well_loom",
		"role": "锁相入口承接",
		"placement": "风蚀解析后的第一道织线侧路，只确认进入锁相框架的入口。"
	}
}


static func get_region_ids() -> Array:
	return REGION_IDS.duplicate()


static func format_hud_summary(world_state: WorldState, _character_state: CharacterState = null) -> Array[String]:
	if world_state == null:
		return []
	var region_id := String(world_state.current_region_id)
	if not REGION_IDS.has(region_id):
		return []
	return [
		"风蚀过渡：%s；入口：%s；边界：%s" % [
			_get_region_text(region_id, "title"),
			_get_region_text(region_id, "entrance"),
			_get_region_text(region_id, "boundary")
		],
		"过渡落点：危险：%s；资源：%s；设施：%s；回基地：%s" % [
			_get_region_text(region_id, "hazard"),
			_get_region_text(region_id, "resource"),
			_get_region_text(region_id, "facility"),
			_get_region_text(region_id, "return")
		]
	]


static func format_map_route_hint(region_id: String) -> String:
	if not REGION_IDS.has(region_id):
		return ""
	return "风蚀过渡：%s；入口：%s；边界：%s；落点：%s / %s / %s；回基地：%s" % [
		_get_region_text(region_id, "title"),
		_get_region_text(region_id, "entrance"),
		_get_region_text(region_id, "boundary"),
		_get_region_text(region_id, "hazard"),
		_get_region_text(region_id, "resource"),
		_get_region_text(region_id, "facility"),
		_get_region_text(region_id, "return")
	]


static func format_object_route_line(
	definition_id: String,
	object_state: Dictionary,
	fallback_region_id: String = ""
) -> String:
	var info := _get_object_info(definition_id, fallback_region_id)
	if info.is_empty():
		return ""
	var region_id := String(info.get("region_id", ""))
	var processed := _is_object_state_processed(object_state)
	var status := "已处理" if processed else "待处理"
	return "风蚀过渡：%s；对象落点：%s；状态：%s；%s；去向：%s" % [
		_get_region_text(region_id, "title"),
		String(info.get("role", "")),
		status,
		String(info.get("placement", "")),
		_get_region_text(region_id, "next")
	]


static func format_static_object_route_line(definition_id: String, fallback_region_id: String = "") -> String:
	var info := _get_object_info(definition_id, fallback_region_id)
	if info.is_empty():
		return ""
	var region_id := String(info.get("region_id", ""))
	return "风蚀过渡：%s；对象落点：%s；%s；回基地：%s" % [
		_get_region_text(region_id, "title"),
		String(info.get("role", "")),
		String(info.get("placement", "")),
		_get_region_text(region_id, "return")
	]


static func format_result_followup_line(
	definition_id: String,
	_world_state: WorldState = null,
	fallback_region_id: String = ""
) -> String:
	var info := _get_object_info(definition_id, fallback_region_id)
	if info.is_empty():
		return ""
	var region_id := String(info.get("region_id", ""))
	return "风蚀过渡：%s已处理；下一段：%s；回基地：%s" % [
		String(info.get("role", "")),
		_get_region_text(region_id, "next"),
		_get_region_text(region_id, "return")
	]


static func get_region_id_for_definition(definition_id: String, fallback_region_id: String = "") -> String:
	var info: Dictionary = OBJECT_ROUTE_INFO.get(definition_id, {})
	if not info.is_empty():
		return String(info.get("region_id", ""))
	if REGION_IDS.has(fallback_region_id):
		return fallback_region_id
	return ""


static func _get_object_info(definition_id: String, fallback_region_id: String) -> Dictionary:
	var info: Dictionary = OBJECT_ROUTE_INFO.get(definition_id, {})
	if not info.is_empty():
		return info
	if not REGION_IDS.has(fallback_region_id):
		return {}
	return {
		"region_id": fallback_region_id,
		"role": "过渡对象",
		"placement": "当前对象服务风蚀管廊入口、资源、设施或锁相入口承接判断。"
	}


static func _get_region_text(region_id: String, key: String) -> String:
	var info: Dictionary = REGION_INFO.get(region_id, {})
	return String(info.get(key, ""))


static func _is_object_state_processed(object_state: Dictionary) -> bool:
	return (
		bool(object_state.get("is_gathered", false))
		or bool(object_state.get("is_sampled", false))
		or bool(object_state.get("is_cleared", false))
		or bool(object_state.get("is_inspected", false))
	)
