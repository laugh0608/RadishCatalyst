extends RefCounted
class_name NonCoreSceneIdentityFormatter

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
		"title": "封锁遗迹旧设施区",
		"visual": "断裂铜绿条带、雾幕门和中继台把这里读成旧设施短副本入口",
		"object_reason": "旧设施、信号封锁和回波容器说明这里不是普通荒野"
	},
	"region.deep_ruin_threshold": {
		"title": "裂相脊撕裂地貌",
		"visual": "长裂隙、前线锚点和阵列台把地表撕裂感拉成一条回传路线",
		"object_reason": "裂相门禁、锁扣和回传锚点说明这里承载前线回传"
	},
	"region.inner_phase_well": {
		"title": "回声台地观测残响",
		"visual": "台地探点、泄压阀和回声读数把这里读成异常观测残留区",
		"object_reason": "回声探点与读数阀说明这里提供异常样本和测绘入口"
	},
	"region.phase_well_sink": {
		"title": "盐壳浅滩化学沉积",
		"visual": "浅黄盐壳、硬壳阻挡和余烬团把污染沉积地貌读清楚",
		"object_reason": "盐壳硬壳和裂口说明这里是污染化学沉积过渡段"
	},
	"region.phase_well_chamber": {
		"title": "碎晶沟谷晶体耦合",
		"visual": "碎晶蓝紫带和分流读数点把高价值晶体与异常能量绑定",
		"object_reason": "碎晶分流和沟谷断面说明资源密度与异常脉冲一起抬升"
	},
	"region.phase_well_loom": {
		"title": "风蚀管廊旧通道",
		"visual": "风蚀灰带、张力绕轮和管廊断面暴露旧前哨与远古结构",
		"object_reason": "张力绕轮和管廊断面说明这里连接旧设施与稳定工程"
	},
	"region.phase_well_frame": {
		"title": "锁相框架压相设施",
		"visual": "框架绿线、侧路障和断面结构表现旧系统压住异常相位",
		"object_reason": "锁相侧路和框架断面说明这里是终点前压强设施"
	},
	"region.phase_well_tether": {
		"title": "锚定桥稳定接入区",
		"visual": "桥体青绿带、锚索结点和回稳窗把前线结果接向核心工程",
		"object_reason": "锚定桥结点、压力钉和回稳窗说明这里接入核心稳定站"
	}
}


static func get_region_ids() -> Array:
	return REGION_IDS.duplicate()


static func format_map_route_hint(region_id: String) -> String:
	if not REGION_IDS.has(region_id):
		return ""
	return "场景：%s；%s" % [
		_get_info_text(region_id, "title"),
		_get_info_text(region_id, "visual")
	]


static func format_object_scene_line(definition_id: String, fallback_region_id: String = "") -> String:
	var region_id := get_region_id_for_definition(definition_id)
	if region_id.is_empty() and REGION_IDS.has(fallback_region_id):
		region_id = fallback_region_id
	if region_id.is_empty():
		return ""
	return "场景：%s；%s" % [
		_get_info_text(region_id, "title"),
		_get_info_text(region_id, "object_reason")
	]


static func get_region_id_for_definition(definition_id: String) -> String:
	return FunctionalTransitionRouteSupportFormatter.get_region_id_for_definition(definition_id)


static func _get_info_text(region_id: String, key: String) -> String:
	var info: Dictionary = REGION_INFO.get(region_id, {})
	return String(info.get(key, ""))
