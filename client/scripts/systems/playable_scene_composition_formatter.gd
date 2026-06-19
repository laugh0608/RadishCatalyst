extends RefCounted
class_name PlayableSceneCompositionFormatter

const REGION_IDS := [
	"region.outpost_platform",
	"region.crystal_vein_field",
	"region.pollution_edge",
	"region.ruin_outer_ring",
	"region.deep_ruin_threshold",
	"region.inner_phase_well",
	"region.phase_well_sink",
	"region.phase_well_chamber",
	"region.phase_well_loom",
	"region.phase_well_frame",
	"region.phase_well_tether",
	"region.demo_stabilization_core"
]

const REGION_INFO := {
	"region.outpost_platform": {
		"title": "前哨平台构成",
		"main_path": "前哨核心经基础反应器、出发整备台走向东侧出发口",
		"foreground": "前景是核心、储存和整备设备垫",
		"background": "背景保留回投台、短行动台和材料整理区",
		"landmark": "前哨核心 / 出发整备台",
		"object_anchor": "加工、补给和出发落点"
	},
	"region.crystal_vein_field": {
		"title": "晶体矿脉构成",
		"main_path": "蓝色矿脉带沿上侧接向污染入口",
		"foreground": "前景是可采晶簇和高价值矿脉",
		"background": "背景用残骸、异常样本和南侧口袋提示回收线",
		"landmark": "晶簇 / 残骸口袋",
		"object_anchor": "基础资源和残骸回收落点"
	},
	"region.pollution_edge": {
		"title": "污染边界构成",
		"main_path": "中线从晶体入口压到遗迹门前",
		"foreground": "前景是施工带、过滤器基座和粗糙地面",
		"background": "背景以下侧污染沉积和敌压口袋表达承压",
		"landmark": "污染沉积 / 过滤器基座",
		"object_anchor": "污染处理和边界推进落点"
	},
	"region.ruin_outer_ring": {
		"title": "封锁遗迹构成",
		"main_path": "雾幕门、外圈屏障、中继台和回波匣串成短副本推进线",
		"foreground": "前景是旧设施入口和封锁装置",
		"background": "背景把污染回波沉积压在下侧作为回基地材料",
		"landmark": "遗迹门 / 外圈回波匣",
		"object_anchor": "旧设施入口和回波解析落点"
	},
	"region.deep_ruin_threshold": {
		"title": "裂相脊构成",
		"main_path": "门禁、锁扣、阵列台和回传锚点拉成深段回传线",
		"foreground": "前景是裂相门、锁扣和撕裂读数",
		"background": "背景用上下样本、尖塔和故障残渣表现裂相扩散",
		"landmark": "裂相阵列 / 回传锚点",
		"object_anchor": "深段门禁和前线回传落点"
	},
	"region.inner_phase_well": {
		"title": "回声台地构成",
		"main_path": "泄压阀、回声芯和台地探点把路线接向盐壳浅滩",
		"foreground": "前景是泄压阀和回声定位器",
		"background": "背景以回声碎屑和压力读数分层",
		"landmark": "回声芯 / 泄压阀",
		"object_anchor": "异常观测和测绘入口落点"
	},
	"region.phase_well_sink": {
		"title": "盐壳浅滩构成",
		"main_path": "硬壳裂口把污染沉积浅滩接向碎晶沟谷",
		"foreground": "前景是盐壳硬壳和凿开点",
		"background": "背景用余烬团和浅滩色块提示化学沉积",
		"landmark": "盐壳硬壳 / 浅滩裂口",
		"object_anchor": "污染沉积过渡和开路落点"
	},
	"region.phase_well_chamber": {
		"title": "碎晶沟谷构成",
		"main_path": "分流读数点夹住沟谷中线，指向风蚀管廊",
		"foreground": "前景是碎晶分流节点和相位井腔",
		"background": "背景用心棘残片口袋表现高价值资源",
		"landmark": "碎晶分流 / 相位井腔",
		"object_anchor": "晶体耦合和异常推进落点"
	},
	"region.phase_well_loom": {
		"title": "风蚀管廊构成",
		"main_path": "张力绕轮和管廊断面把旧通道接向锁相框架",
		"foreground": "前景是张力绕轮和风蚀断面",
		"background": "背景用纬束残团分布表现旧设施残留",
		"landmark": "张力绕轮 / 管廊断面",
		"object_anchor": "旧通道和稳定工程前置落点"
	},
	"region.phase_well_frame": {
		"title": "锁相框架构成",
		"main_path": "上下侧路障形成压相框，主路从框架缝隙穿向锚定桥",
		"foreground": "前景是锁相框架和侧路障",
		"background": "背景用边缕残条表现终点前压强",
		"landmark": "锁相框架 / 侧路障",
		"object_anchor": "终点前压强和侧路清理落点"
	},
	"region.phase_well_tether": {
		"title": "锚定桥构成",
		"main_path": "桥体中线、锚索结点和锚场回稳窗接入核心稳定站",
		"foreground": "前景是锚索结点、锚定桥断面和锚场",
		"background": "背景放置稳场节点、回执点和压力扰点",
		"landmark": "锚定桥 / 锚场回稳窗",
		"object_anchor": "核心站前稳定接入落点"
	},
	"region.demo_stabilization_core": {
		"title": "核心稳定站构成",
		"main_path": "补给缓存、守卫缓存、复测读数和稳定核心形成 Demo 终点线",
		"foreground": "前景是青绿稳定核心和守卫压力区",
		"background": "背景保留复测读数与后勤回访口袋",
		"landmark": "核心稳定站 / 守卫缓存",
		"object_anchor": "补给、守卫和终点写入落点"
	}
}

const DEFINITION_REGION_IDS := {
	"building.outpost_core": "region.outpost_platform",
	"building.basic_reactor": "region.outpost_platform",
	"building.field_outfitting_station": "region.outpost_platform",
	"building.basic_storage": "region.outpost_platform",
	"building.slurry_buffer_tank": "region.outpost_platform",
	"map_object.outpost_departure_gate": "region.outpost_platform",
	"map_object.outpost_logistics_route_sign": "region.outpost_platform",
	"map_object.phase_relay_pad": "region.outpost_platform",
	"map_object.crystal_cluster": "region.crystal_vein_field",
	"map_object.rich_crystal_vein": "region.crystal_vein_field",
	"map_object.field_wreckage": "region.crystal_vein_field",
	"map_object.anomaly_crystal": "region.crystal_vein_field",
	"map_object.anomaly_residue_patch": "region.crystal_vein_field",
	"map_object.pollution_residue_patch": "region.pollution_edge",
	"map_object.rough_ground": "region.pollution_edge",
	"building.foundation_t1": "region.pollution_edge",
	"building.pollution_filter": "region.pollution_edge",
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
	"map_object.phase_well_anchor_pressure_pin": "region.phase_well_tether",
	"map_object.stability_echo_probe": "region.phase_well_tether",
	"map_object.supply_return_marker": "region.phase_well_tether",
	"map_object.route_signal_marker": "region.phase_well_tether",
	"map_object.pressure_clearance_node": "region.phase_well_tether",
	"map_object.demo_stabilization_core": "region.demo_stabilization_core",
	"map_object.demo_stabilization_recovery_cache": "region.demo_stabilization_core",
	"map_object.demo_stabilization_guard_cache": "region.demo_stabilization_core",
	"map_object.demo_stabilization_retest_readout_cache": "region.demo_stabilization_core",
	"map_object.demo_stabilization_logistics_retest_residue": "region.demo_stabilization_core"
}


static func get_region_ids() -> Array:
	return REGION_IDS.duplicate()


static func format_map_route_hint(region_id: String) -> String:
	if not REGION_IDS.has(region_id):
		return ""
	return "画面构成：%s；主路：%s；关键落点：%s" % [
		_get_info_text(region_id, "title"),
		_get_info_text(region_id, "main_path"),
		_get_info_text(region_id, "landmark")
	]


static func format_object_composition_line(definition_id: String, fallback_region_id: String = "") -> String:
	var region_id := ""
	if REGION_IDS.has(fallback_region_id):
		region_id = fallback_region_id
	if region_id.is_empty():
		region_id = get_region_id_for_definition(definition_id)
	if region_id.is_empty():
		return ""
	return "画面构成：%s；对象落点：%s；画面关系：%s / %s" % [
		_get_info_text(region_id, "title"),
		_get_info_text(region_id, "object_anchor"),
		_get_info_text(region_id, "foreground"),
		_get_info_text(region_id, "background")
	]


static func get_region_id_for_definition(definition_id: String) -> String:
	if DEFINITION_REGION_IDS.has(definition_id):
		return String(DEFINITION_REGION_IDS[definition_id])
	return ""


static func get_region_landmark(region_id: String) -> String:
	return _get_info_text(region_id, "landmark")


static func _get_info_text(region_id: String, key: String) -> String:
	var info: Dictionary = REGION_INFO.get(region_id, {})
	return String(info.get(key, ""))
