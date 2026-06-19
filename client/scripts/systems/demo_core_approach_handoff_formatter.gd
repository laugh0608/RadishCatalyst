extends RefCounted
class_name DemoCoreApproachHandoffFormatter

const REGION_IDS := [
	"region.phase_well_frame",
	"region.phase_well_tether",
	"region.demo_stabilization_core"
]

const REGION_INFO := {
	"region.phase_well_frame": {
		"title": "锁相框架 -> 锚定桥承接",
		"route": "锁相框架把风蚀管廊后的织构压成终点前压强线。",
		"evidence": "侧路障、边缕残条和框架断面说明这里不是独立支线，而是锚定桥前置收益。",
		"return": "回基地稳定边缕残条并解析锚定结核，打开锚定桥。",
		"next": "完成锁相解析后进入锚定桥，继续把稳定工程接向核心稳定站入口。"
	},
	"region.phase_well_tether": {
		"title": "锚定桥 -> 核心稳定站入口",
		"route": "锚定桥把锚索结点、锚场回稳窗和前线行动读数接成核心入口前准备。",
		"evidence": "桥体断面、回传锚点、回稳窗、稳窗校准点和前线读数标记共同指向核心稳定站。",
		"return": "回基地解析稳场锚核、稳窗余响片和前线读数，归档后进入核心稳定站。",
		"next": "稳窗校准和前线读数归档后，向东进入核心稳定站并读取终点压力。"
	},
	"region.demo_stabilization_core": {
		"title": "核心稳定站入口确认",
		"route": "核心稳定站读取锚定桥稳窗和高压窗口归档，转入终点前准备。",
		"evidence": "核心稳定设备、侧边补给、守卫缓存和写入校验片共同证明前线收益已接到终点。",
		"return": "回基地整备核心稳压缓冲包、补给和药剂，再回来处理守卫和核心写入。",
		"next": "按终点前准备处理缓冲包、阶段守卫和核心稳定数据写入。"
	}
}

const OBJECT_HANDOFF_INFO := {
	"map_object.phase_well_frame_route_blocker": {
		"region_id": "region.phase_well_frame",
		"role": "锁相入口压强",
		"placement": "清开侧路后，边缕残条回收线才从终点前压强里露出来。"
	},
	"map_object.selvedge_strip_cluster": {
		"region_id": "region.phase_well_frame",
		"role": "锁相回收材料",
		"placement": "边缕残条必须回基地稳定成框架肋，继续组装锁相键栓。"
	},
	"map_object.phase_well_frame": {
		"region_id": "region.phase_well_frame",
		"role": "锚定桥前置断面",
		"placement": "框架断面析出锚定结核，把路线从锁相结构交给锚定桥。"
	},
	"map_object.phase_well_tether_knot_node": {
		"region_id": "region.phase_well_tether",
		"role": "锚定桥入口结点",
		"placement": "两端结点确认桥体边界，让锚索残股回收线可读。"
	},
	"map_object.tether_fiber_cluster": {
		"region_id": "region.phase_well_tether",
		"role": "锚索回收材料",
		"placement": "锚索残股回基地稳定成系固肋，支撑锚定桩和锚场回稳。"
	},
	"map_object.phase_well_tether": {
		"region_id": "region.phase_well_tether",
		"role": "锚场前置断面",
		"placement": "桥体断面析出稳场锚核，把下一步交给锚场回稳窗。"
	},
	"map_object.phase_well_anchor_field": {
		"region_id": "region.phase_well_tether",
		"role": "核心入口稳窗",
		"placement": "锚场回稳窗稳定后，前线才具备进入核心稳定站前的恢复和读数承接。"
	},
	"map_object.phase_well_anchor_pressure_pin": {
		"region_id": "region.phase_well_tether",
		"role": "稳窗压力清障",
		"placement": "压力钉清掉后，稳场守脉体暴露，锚场回稳窗才能收束。"
	},
	"map_object.phase_well_stability_node_west": {
		"region_id": "region.phase_well_tether",
		"role": "稳窗校准序列",
		"placement": "西侧稳窗校准点固定核心入口前的第一段相位序。"
	},
	"map_object.phase_well_stability_node_core": {
		"region_id": "region.phase_well_tether",
		"role": "稳窗校准序列",
		"placement": "中央稳窗校准点承接西侧读数，继续锁住核心入口前的稳定窗。"
	},
	"map_object.phase_well_stability_node_east": {
		"region_id": "region.phase_well_tether",
		"role": "稳窗校准序列",
		"placement": "东侧稳窗校准点收口后，核心稳定站入口可被正式指向。"
	},
	"map_object.stability_echo_probe": {
		"region_id": "region.phase_well_tether",
		"role": "前线行动回波",
		"placement": "回波探点把稳窗校准后的短回访收益带回基地解析。"
	},
	"map_object.supply_return_marker": {
		"region_id": "region.phase_well_tether",
		"role": "补给回执标记",
		"placement": "补给回执标记证明终点前补给节奏能支撑下一趟外出。"
	},
	"map_object.route_signal_marker": {
		"region_id": "region.phase_well_tether",
		"role": "巡线信标",
		"placement": "巡线信标确认锚定桥到核心入口的路线稳定性。"
	},
	"map_object.steady_supply_drop_marker": {
		"region_id": "region.phase_well_tether",
		"role": "补给投放支点",
		"placement": "稳场补给投放点验证低风险补给回路，不新增核心入口分支。"
	},
	"map_object.phase_survey_node_west": {
		"region_id": "region.phase_well_tether",
		"role": "相位测绘边界",
		"placement": "西侧测绘点确认核心入口前的低压路线边界。"
	},
	"map_object.phase_survey_node_east": {
		"region_id": "region.phase_well_tether",
		"role": "相位测绘边界",
		"placement": "东侧测绘点把低压路线读数带回基地解析。"
	},
	"map_object.pressure_clearance_node": {
		"region_id": "region.phase_well_tether",
		"role": "前线压力扰点",
		"placement": "压力扰点清除后，核心入口前的高压读法转成可归档回执。"
	},
	"map_object.prepared_frontline_window": {
		"region_id": "region.phase_well_tether",
		"role": "前线行动窗口",
		"placement": "整备异常窗口复用既有前线行动计划，只显示当前承接目标。"
	},
	"map_object.demo_stabilization_core": {
		"region_id": "region.demo_stabilization_core",
		"role": "核心入口设备",
		"placement": "核心稳定设备确认锚定桥和高压窗口收益已进入终点前准备。"
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
		"核心入口承接：%s；路线：%s" % [
			_get_region_text(region_id, "title"),
			_get_region_text(region_id, "route")
		],
		"承接证据：%s；回基地：%s" % [
			_get_region_text(region_id, "evidence"),
			_get_region_text(region_id, "return")
		]
	]


static func format_map_route_hint(region_id: String) -> String:
	if not REGION_IDS.has(region_id):
		return ""
	return "核心入口承接：%s；路线：%s；证据：%s；下一段：%s" % [
		_get_region_text(region_id, "title"),
		_get_region_text(region_id, "route"),
		_get_region_text(region_id, "evidence"),
		_get_region_text(region_id, "next")
	]


static func format_object_handoff_line(
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
	return "核心入口承接：%s；对象落点：%s；状态：%s；%s；下一段：%s" % [
		_get_region_text(region_id, "title"),
		String(info.get("role", "")),
		status,
		String(info.get("placement", "")),
		_get_region_text(region_id, "next")
	]


static func format_static_object_handoff_line(definition_id: String, fallback_region_id: String = "") -> String:
	var info := _get_object_info(definition_id, fallback_region_id)
	if info.is_empty():
		return ""
	var region_id := String(info.get("region_id", ""))
	return "核心入口承接：%s；对象落点：%s；%s；回基地：%s" % [
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
	return "核心入口承接：%s已处理；下一段：%s；回基地：%s" % [
		String(info.get("role", "")),
		_get_region_text(region_id, "next"),
		_get_region_text(region_id, "return")
	]


static func get_region_id_for_definition(definition_id: String, fallback_region_id: String = "") -> String:
	var info := _get_object_info(definition_id, fallback_region_id)
	return String(info.get("region_id", ""))


static func _get_object_info(definition_id: String, fallback_region_id: String) -> Dictionary:
	if definition_id == "map_object.phase_return_anchor":
		if fallback_region_id == "region.phase_well_tether":
			return {
				"region_id": "region.phase_well_tether",
				"role": "回投承接",
				"placement": "锚定桥回传锚点把核心入口前的短回访接回基地相位回投台。"
			}
		return {}
	var info: Dictionary = OBJECT_HANDOFF_INFO.get(definition_id, {})
	if not info.is_empty():
		return info
	if not REGION_IDS.has(fallback_region_id):
		return {}
	return {
		"region_id": fallback_region_id,
		"role": "核心入口承接对象",
		"placement": "当前对象服务锁相框架、锚定桥或核心稳定站入口的承接判断。"
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
		or bool(object_state.get("anchor_field_deployed", false))
		or bool(object_state.get("anchor_field_stabilized", false))
		or bool(object_state.get("stability_node_calibrated", false))
	)
