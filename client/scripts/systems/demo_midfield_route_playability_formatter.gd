extends RefCounted
class_name DemoMidfieldRoutePlayabilityFormatter

const REGION_IDS := [
	"region.inner_phase_well",
	"region.phase_well_sink",
	"region.phase_well_chamber"
]

const REGION_INFO := {
	"region.inner_phase_well": {
		"title": "回声台地中段路径",
		"entrance": "从裂相锁位向东进入回声台地入口，先处理回声泄压阀。",
		"boundary": "两处泄压阀把台地入口和芯样本探点分开，卸压后再回收碎屑。",
		"hazard": "回声哨戒体压在台地中线，回声压力沿上下两处泄压点外溢。",
		"resource": "回声碎屑在南北两侧，服务回声探针和后续样本解析。",
		"facility": "回声台地探点在东侧，读取后把回声芯样本带回基地。",
		"return": "回基地稳定回声碎屑并解析回声芯样本，打开盐壳浅滩。",
		"next": "完成回声解析后，向东进入盐壳浅滩。"
	},
	"region.phase_well_sink": {
		"title": "盐壳浅滩中段路径",
		"entrance": "从回声样本指向的浅滩裂口进入，先清掉盐壳硬壳。",
		"boundary": "两处盐壳硬壳压住余烬回收线，清开后才能进入裂口。",
		"hazard": "盐壳潜伏体守在浅滩中线，盐壳沉积把路线切成上下两条边。",
		"resource": "盐壳余烬在硬壳后方，服务盐壳穿钉和碎晶心核解析。",
		"facility": "盐壳裂口在东侧，凿开后把碎晶心核带回基地。",
		"return": "回基地稳定盐壳余烬并解析碎晶心核，打开碎晶沟谷。",
		"next": "完成盐壳解析后，向东进入碎晶沟谷。"
	},
	"region.phase_well_chamber": {
		"title": "碎晶沟谷中段路径",
		"entrance": "从碎晶心核指向的沟谷入口进入，先写入碎晶分流读数。",
		"boundary": "两处分流读数把高脉冲沟谷降下来，读完后心棘残片才稳定。",
		"hazard": "碎晶撕裂体压在沟谷中线，分流点把入口和断面隔开。",
		"resource": "心棘残片在南北两侧，服务碎晶分流栓和风蚀张力核解析。",
		"facility": "碎晶沟谷断面在东侧，勘验后把风蚀张力核带回基地。",
		"return": "回基地稳定心棘残片并解析风蚀张力核，接向风蚀管廊。",
		"next": "完成碎晶解析后，向东进入风蚀管廊。"
	}
}

const OBJECT_ROUTE_INFO := {
	"map_object.well_flux_pressure_vent": {
		"region_id": "region.inner_phase_well",
		"role": "入口边界",
		"placement": "两处泄压阀压住台地入口，处理后回声碎屑回收线稳定。"
	},
	"map_object.well_flux_cluster": {
		"region_id": "region.inner_phase_well",
		"role": "资源",
		"placement": "南北两侧回声碎屑迫使玩家离开中线确认台地宽度。"
	},
	"map_object.inner_phase_well": {
		"region_id": "region.inner_phase_well",
		"role": "设施",
		"placement": "东侧探点把回声芯样本送回基地解析，接到盐壳浅滩。"
	},
	"map_object.well_ash_crust_blocker": {
		"region_id": "region.phase_well_sink",
		"role": "入口边界",
		"placement": "盐壳硬壳压住浅滩上下边，清开后余烬回收线打开。"
	},
	"map_object.well_ash_cluster": {
		"region_id": "region.phase_well_sink",
		"role": "资源",
		"placement": "硬壳后方盐壳余烬服务基地稳定和盐壳穿钉整备。"
	},
	"map_object.phase_well_sink": {
		"region_id": "region.phase_well_sink",
		"role": "设施",
		"placement": "东侧裂口把碎晶心核带回基地解析，接到碎晶沟谷。"
	},
	"map_object.phase_return_anchor": {
		"region_id": "region.phase_well_chamber",
		"role": "返回设施",
		"placement": "沟谷前侧回传锚点让中段路线能回基地整备后再进。"
	},
	"map_object.phase_well_chamber_shunt_node": {
		"region_id": "region.phase_well_chamber",
		"role": "入口边界",
		"placement": "两处分流读数降低沟谷脉冲，让心棘残片露出。"
	},
	"map_object.heart_spine_cluster": {
		"region_id": "region.phase_well_chamber",
		"role": "资源",
		"placement": "南北两侧心棘残片服务碎晶分流栓和后续风蚀解析。"
	},
	"map_object.phase_well_chamber": {
		"region_id": "region.phase_well_chamber",
		"role": "设施",
		"placement": "东侧断面带回风蚀张力核，把路线接向风蚀管廊。"
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
		"中段路径：%s；入口：%s；边界：%s" % [
			_get_region_text(region_id, "title"),
			_get_region_text(region_id, "entrance"),
			_get_region_text(region_id, "boundary")
		],
		"路径落点：危险：%s；资源：%s；设施：%s；回基地：%s" % [
			_get_region_text(region_id, "hazard"),
			_get_region_text(region_id, "resource"),
			_get_region_text(region_id, "facility"),
			_get_region_text(region_id, "return")
		]
	]


static func format_map_route_hint(region_id: String) -> String:
	if not REGION_IDS.has(region_id):
		return ""
	return "中段路径：%s；入口：%s；边界：%s；落点：%s / %s / %s；回基地：%s" % [
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
	return "中段路径：%s；对象落点：%s；状态：%s；%s；去向：%s" % [
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
	return "中段路径：%s；对象落点：%s；%s；回基地：%s" % [
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
	return "中段路径：%s已处理；下一段：%s；回基地：%s" % [
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
		"role": "区域对象",
		"placement": "当前对象服务中段路线入口、资源、设施或回基地处理判断。"
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
