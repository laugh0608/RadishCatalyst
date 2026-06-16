extends RefCounted
class_name FunctionalTransitionRouteSupportFormatter

const REGION_IDS := [
	"region.ruin_outer_ring",
	"region.deep_ruin_threshold",
	"region.inner_phase_well",
	"region.phase_well_sink",
	"region.phase_well_chamber",
	"region.phase_well_loom",
	"region.phase_well_frame",
	"region.phase_well_tether"
]

const REGION_INFO := {
	"region.ruin_outer_ring": {
		"title": "封锁遗迹机制展示线",
		"role": "稳相信标、外圈中继和回波匣把遗迹门槛读成第一次短副本回访",
		"danger": "污染残留、相位守卫和抖动雾幕会检验出发整备",
		"return_reason": "继电残片、污染沉积和回波匣要回基地解析成稳相信标与裂相坐标",
		"object_reason": "这里展示遗迹门槛、外圈信号和回基地解析价值"
	},
	"region.deep_ruin_threshold": {
		"title": "裂相脊前线回传线",
		"role": "裂相入口、锁扣、阵列和前线回传锚点把深段风险接回基地",
		"danger": "裂相守卫、追袭体和偏振读数会压迫防护与回投节奏",
		"return_reason": "裂相样块、导管和读数矩阵要回基地整理成回传锚点与后续坐标",
		"object_reason": "这里展示前线回传、裂隙收益和回基地整理价值"
	},
	"region.inner_phase_well": {
		"title": "回声台地异常读数线",
		"role": "回声定位器、泄压阀和台地探点把异常读数转成后续路线",
		"danger": "回声压力、故障残渣和泄压读数会抬高采集与勘验风险",
		"return_reason": "回声芯样本和稳定碎屑要回基地解析成盐壳浅滩入口",
		"object_reason": "这里展示异常读数、相位样本和测绘入口"
	},
	"region.phase_well_sink": {
		"title": "盐壳浅滩污染沉积连接线",
		"role": "盐壳硬壳和裂口把污染化学沉积接到后段异常路线",
		"danger": "盐壳余烬和硬壳会让防护压力高于普通过渡段",
		"return_reason": "盐壳余烬和碎晶心核要回基地稳定化，继续打开碎晶沟谷",
		"object_reason": "这里连接污染沉积地貌和后续碎晶路线"
	},
	"region.phase_well_chamber": {
		"title": "碎晶沟谷资源耦合线",
		"role": "碎晶分流读数和沟谷断面把高价值晶体接到异常推进",
		"danger": "碎晶脉冲和分流读数会诱发更强现场反击",
		"return_reason": "心棘残片和风蚀张力核要回基地处理，继续打开风蚀管廊",
		"object_reason": "这里展示晶体资源和异常能量耦合后的路线收益"
	},
	"region.phase_well_loom": {
		"title": "风蚀管廊旧设施连接线",
		"role": "张力绕轮和管廊断面把旧前哨事故线索接到稳定工程",
		"danger": "风蚀张力和远古管廊会压住回收线",
		"return_reason": "纬束残团和锁相织构核要回基地解析，继续打开锁相框架",
		"object_reason": "这里连接旧前哨设施、远古结构和后续稳定工程"
	},
	"region.phase_well_frame": {
		"title": "锁相框架终点前压强线",
		"role": "侧路障和框架断面说明旧系统试图压住异常相位",
		"danger": "锁相织线和侧路障会抬高终点前压强",
		"return_reason": "边缕残条和锚定结核要回基地整理，继续打开锚定桥",
		"object_reason": "这里展示锁相结构、侧路清理和终点前压力抬升"
	},
	"region.phase_well_tether": {
		"title": "锚定桥稳定工程接入线",
		"role": "锚定桥断面、结点和锚场回稳窗把前线结果接回核心稳定工程",
		"danger": "锚索拉结、压力钉和稳场守脉体会检验最后整备",
		"return_reason": "稳场锚核、锚索残股和稳窗余响片要回基地归档，支撑核心稳定站",
		"object_reason": "这里展示稳定窗口、前线行动结果和核心站前置价值"
	}
}

const DEFINITION_REGION_IDS := {
	"map_object.ruin_gate": "region.ruin_outer_ring",
	"map_object.relay_shard_cache": "region.ruin_outer_ring",
	"map_object.outer_ring_barrier": "region.ruin_outer_ring",
	"map_object.outer_ring_console": "region.ruin_outer_ring",
	"map_object.signal_echo_cache": "region.ruin_outer_ring",
	"map_object.deep_ruin_door": "region.deep_ruin_threshold",
	"map_object.deep_ruin_latch": "region.deep_ruin_threshold",
	"map_object.deep_signal_array": "region.deep_ruin_threshold",
	"map_object.phase_return_anchor": "region.deep_ruin_threshold",
	"map_object.phase_splinter_resonance_node": "region.deep_ruin_threshold",
	"map_object.phase_fault_spire": "region.deep_ruin_threshold",
	"map_object.phase_well_lock": "region.deep_ruin_threshold",
	"map_object.inner_phase_well": "region.inner_phase_well",
	"map_object.well_flux_cluster": "region.inner_phase_well",
	"map_object.well_flux_pressure_vent": "region.inner_phase_well",
	"map_object.phase_well_sink": "region.phase_well_sink",
	"map_object.well_ash_cluster": "region.phase_well_sink",
	"map_object.well_ash_crust_blocker": "region.phase_well_sink",
	"map_object.phase_well_chamber": "region.phase_well_chamber",
	"map_object.phase_well_chamber_shunt_node": "region.phase_well_chamber",
	"map_object.heart_spine_cluster": "region.phase_well_chamber",
	"map_object.phase_well_loom": "region.phase_well_loom",
	"map_object.phase_well_loom_tension_spool": "region.phase_well_loom",
	"map_object.weft_bundle_cluster": "region.phase_well_loom",
	"map_object.phase_well_frame": "region.phase_well_frame",
	"map_object.phase_well_frame_route_blocker": "region.phase_well_frame",
	"map_object.selvedge_strip_cluster": "region.phase_well_frame",
	"map_object.phase_well_tether": "region.phase_well_tether",
	"map_object.phase_well_tether_knot_node": "region.phase_well_tether",
	"map_object.tether_fiber_cluster": "region.phase_well_tether",
	"map_object.phase_well_anchor_field": "region.phase_well_tether",
	"map_object.phase_well_anchor_pressure_pin": "region.phase_well_tether"
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
		"路线支撑：%s" % _get_info_text(region_id, "title"),
		"当前危险：%s；回基地理由：%s" % [
			_get_info_text(region_id, "danger"),
			_get_info_text(region_id, "return_reason")
		]
	]


static func format_map_route_hint(region_id: String) -> String:
	if not REGION_IDS.has(region_id):
		return ""
	return "路线：%s；职责：%s；当前危险：%s；回基地：%s" % [
		_get_info_text(region_id, "title"),
		_get_info_text(region_id, "role"),
		_get_info_text(region_id, "danger"),
		_get_info_text(region_id, "return_reason")
	]


static func format_object_route_line(definition_id: String, fallback_region_id: String = "") -> String:
	var region_id := get_region_id_for_definition(definition_id)
	if region_id.is_empty() and REGION_IDS.has(fallback_region_id):
		region_id = fallback_region_id
	if region_id.is_empty():
		return ""
	return "路线支撑：%s；%s；回基地：%s" % [
		_get_info_text(region_id, "title"),
		_get_info_text(region_id, "object_reason"),
		_get_info_text(region_id, "return_reason")
	]


static func get_region_id_for_definition(definition_id: String) -> String:
	if DEFINITION_REGION_IDS.has(definition_id):
		return String(DEFINITION_REGION_IDS[definition_id])
	return ""


static func _get_info_text(region_id: String, key: String) -> String:
	var info: Dictionary = REGION_INFO.get(region_id, {})
	return String(info.get(key, ""))
