extends RefCounted
class_name FunctionalSceneGameplayFormatter

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
		"title": "封锁遗迹现场玩法",
		"active": "先回收继电残片，稳定雾幕，再把回波匣带回基地解析。",
		"return": "回基地把继电残片、污染沉积和回波匣整理成信标与裂相坐标。"
	},
	"region.deep_ruin_threshold": {
		"title": "裂相脊现场玩法",
		"active": "读出共振点、部署前线回传锚点，并把尖塔轨迹带回基地。",
		"return": "回基地整理裂相样块、导管和读数矩阵，打开后续回投路线。"
	},
	"region.inner_phase_well": {
		"title": "回声台地现场玩法",
		"active": "先处理泄压阀，再读取台地探点，把回声芯样本带回基地。",
		"return": "回基地解析回声样本和稳定碎屑，继续打开盐壳浅滩。"
	},
	"region.phase_well_sink": {
		"title": "盐壳浅滩现场玩法",
		"active": "清开盐壳硬壳，再凿开裂口取回碎晶心核。",
		"return": "回基地稳定盐壳余烬和碎晶心核，继续推进碎晶沟谷。"
	},
	"region.phase_well_chamber": {
		"title": "碎晶沟谷现场玩法",
		"active": "写入分流读数，稳定心棘残片，再勘验碎晶沟谷断面。",
		"return": "回基地解析心棘残片和风蚀张力核，继续推进风蚀管廊。"
	},
	"region.phase_well_loom": {
		"title": "风蚀管廊现场玩法",
		"active": "检查张力绕轮，稳定纬束残团，再勘验管廊断面。",
		"return": "回基地解析纬束残团和锁相织构核，继续推进锁相框架。"
	},
	"region.phase_well_frame": {
		"title": "锁相框架现场玩法",
		"active": "清理锁相侧路，回收边缕残条，再勘验框架断面。",
		"return": "回基地解析边缕残条和锚定结核，继续推进锚定桥。"
	},
	"region.phase_well_tether": {
		"title": "锚定桥现场玩法",
		"active": "检查桥结点、清理压力钉，并把锚场回稳窗接向核心稳定工程。",
		"return": "回基地归档锚索残股、稳场锚核和稳窗读数，支撑核心稳定站。"
	}
}

const REGION_OBJECT_IDS := {
	"region.ruin_outer_ring": ["map_object.relay_shard_cache", "map_object.outer_ring_barrier", "map_object.signal_echo_cache"],
	"region.deep_ruin_threshold": ["map_object.phase_splinter_resonance_node", "map_object.phase_return_anchor", "map_object.phase_fault_spire"],
	"region.inner_phase_well": ["map_object.well_flux_pressure_vent", "map_object.inner_phase_well"],
	"region.phase_well_sink": ["map_object.well_ash_crust_blocker", "map_object.phase_well_sink"],
	"region.phase_well_chamber": ["map_object.phase_well_chamber_shunt_node", "map_object.phase_well_chamber"],
	"region.phase_well_loom": ["map_object.phase_well_loom_tension_spool", "map_object.phase_well_loom"],
	"region.phase_well_frame": ["map_object.phase_well_frame_route_blocker", "map_object.phase_well_frame"],
	"region.phase_well_tether": ["map_object.phase_well_tether_knot_node", "map_object.phase_well_tether", "map_object.phase_well_anchor_pressure_pin", "map_object.phase_well_anchor_field"]
}

const OBJECT_STAGE_INFO := {
	"map_object.relay_shard_cache": {
		"region_id": "region.ruin_outer_ring",
		"title": "继电残片回收",
		"pending": "回收继电残片，给稳相信标提供第一份现场材料。",
		"complete": "继电残片已回收，遗迹门槛从路障转成可回基地整备。"
	},
	"map_object.outer_ring_barrier": {
		"region_id": "region.ruin_outer_ring",
		"title": "抖动雾幕稳定",
		"pending": "部署稳相信标，把外圈深段入口稳定下来。",
		"complete": "抖动雾幕已稳定，外圈深段可以继续检查中继台。"
	},
	"map_object.signal_echo_cache": {
		"region_id": "region.ruin_outer_ring",
		"title": "回波匣回收",
		"pending": "压下相位守卫和污染回波沉积，再回收回波匣。",
		"complete": "回波匣已回收，裂相坐标进入基地解析阶段。"
	},
	"map_object.phase_splinter_resonance_node": {
		"region_id": "region.deep_ruin_threshold",
		"title": "裂相共振读数",
		"pending": "写入两处共振点，稳定裂相碎屑回收线。",
		"complete": "共振读数已写入，碎屑回收从风险点转成可整理目标。"
	},
	"map_object.phase_return_anchor": {
		"region_id": "region.deep_ruin_threshold",
		"title": "前线回传锚点",
		"pending": "部署或校准回传锚点，把深段风险接回基地回投台。",
		"complete": "前线锚点已部署，深段路线可以通过基地回投复用。"
	},
	"map_object.phase_fault_spire": {
		"region_id": "region.deep_ruin_threshold",
		"title": "裂相尖塔校准",
		"pending": "用中继调谐镜校准尖塔，逼出内层故障轨迹。",
		"complete": "尖塔轨迹已带回，后续锁位路线进入基地解析。"
	},
	"map_object.well_flux_pressure_vent": {
		"region_id": "region.inner_phase_well",
		"title": "回声泄压",
		"pending": "处理两处泄压阀，让回声碎屑回收线稳定。",
		"complete": "回声压力已卸掉，台地样本可以继续回基地解析。"
	},
	"map_object.inner_phase_well": {
		"region_id": "region.inner_phase_well",
		"title": "回声探点勘验",
		"pending": "带回声探针读取芯样本，确认后续盐壳路线。",
		"complete": "回声芯样本已带回，盐壳浅滩入口进入解析阶段。"
	},
	"map_object.well_ash_crust_blocker": {
		"region_id": "region.phase_well_sink",
		"title": "盐壳硬壳清理",
		"pending": "清开硬壳，把余烬回收线从阻挡状态拉出来。",
		"complete": "盐壳硬壳已清开，余烬回收线可继续处理。"
	},
	"map_object.phase_well_sink": {
		"region_id": "region.phase_well_sink",
		"title": "盐壳裂口凿开",
		"pending": "带盐壳穿钉凿开裂口，取出碎晶心核。",
		"complete": "碎晶心核已带回，碎晶沟谷进入基地解析阶段。"
	},
	"map_object.phase_well_chamber_shunt_node": {
		"region_id": "region.phase_well_chamber",
		"title": "碎晶分流读数",
		"pending": "写入两处分流读数，让心棘残片从脉冲里露出。",
		"complete": "分流读数已写入，碎晶回收线稳定。"
	},
	"map_object.phase_well_chamber": {
		"region_id": "region.phase_well_chamber",
		"title": "碎晶沟谷断面勘验",
		"pending": "带碎晶分流栓勘验断面，取出风蚀张力核。",
		"complete": "风蚀张力核已带回，风蚀管廊进入解析阶段。"
	},
	"map_object.phase_well_loom_tension_spool": {
		"region_id": "region.phase_well_loom",
		"title": "风蚀张力确认",
		"pending": "检查两处张力绕轮，让纬束残团回收线稳定。",
		"complete": "张力绕轮已确认，管廊回收线稳定。"
	},
	"map_object.phase_well_loom": {
		"region_id": "region.phase_well_loom",
		"title": "风蚀管廊断面勘验",
		"pending": "带风蚀梭栓勘验断面，取出锁相织构核。",
		"complete": "锁相织构核已带回，锁相框架进入解析阶段。"
	},
	"map_object.phase_well_frame_route_blocker": {
		"region_id": "region.phase_well_frame",
		"title": "锁相侧路清理",
		"pending": "清开一条侧路，让边缕残条回收线打开。",
		"complete": "锁相侧路已清开，终点前压强转成可处理回收线。"
	},
	"map_object.phase_well_frame": {
		"region_id": "region.phase_well_frame",
		"title": "锁相框架断面勘验",
		"pending": "带锁相键栓勘验断面，取出锚定结核。",
		"complete": "锚定结核已带回，锚定桥进入解析阶段。"
	},
	"map_object.phase_well_tether_knot_node": {
		"region_id": "region.phase_well_tether",
		"title": "锚定桥结点确认",
		"pending": "检查两端桥结点，让锚索残股松开。",
		"complete": "桥结点已确认，锚索残股回收线打开。"
	},
	"map_object.phase_well_tether": {
		"region_id": "region.phase_well_tether",
		"title": "锚定桥断面勘验",
		"pending": "带锚定桩勘验桥体断面，取出稳场锚核。",
		"complete": "稳场锚核已带回，锚场整备进入基地解析。"
	},
	"map_object.phase_well_anchor_pressure_pin": {
		"region_id": "region.phase_well_tether",
		"title": "锚场压力钉清理",
		"pending": "清掉压力钉，让稳场守脉体完全暴露。",
		"complete": "压力钉已清理，锚场回稳窗进入压制收束。"
	},
	"map_object.phase_well_anchor_field": {
		"region_id": "region.phase_well_tether",
		"title": "锚场回稳窗收束",
		"pending": "部署校锚桩并收束回稳窗，把前线结果接向核心稳定站。",
		"complete": "回稳窗已维持，稳窗读数可以回基地归档。"
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
	if not _has_region_object_state(world_state, region_id):
		return []
	var progress := _format_region_progress(world_state, region_id)
	var next_step := _get_next_region_step(world_state, region_id)
	return [
		"现场玩法：%s；现场进度：%s" % [_get_region_text(region_id, "title"), progress],
		"当前处理：%s；回基地：%s" % [next_step, _get_region_text(region_id, "return")]
	]


static func format_object_gameplay_line(
	definition_id: String,
	object_state: Dictionary,
	fallback_region_id: String = ""
) -> String:
	var info := _get_object_info(definition_id, fallback_region_id)
	if info.is_empty():
		return ""
	var processed := _is_object_state_processed(object_state)
	var status := "已处理" if processed else "待处理"
	var stage_text := String(info.get("complete", "")) if processed else String(info.get("pending", ""))
	return "现场玩法：%s；状态：%s；%s；回基地：%s" % [
		String(info.get("title", "")),
		status,
		stage_text,
		_get_region_text(String(info.get("region_id", "")), "return")
	]


static func format_static_object_gameplay_line(definition_id: String, fallback_region_id: String = "") -> String:
	var info := _get_object_info(definition_id, fallback_region_id)
	if info.is_empty():
		return ""
	return "现场玩法：%s；%s；回基地：%s" % [
		String(info.get("title", "")),
		String(info.get("pending", "")),
		_get_region_text(String(info.get("region_id", "")), "return")
	]


static func format_result_followup_line(
	definition_id: String,
	_world_state: WorldState = null,
	fallback_region_id: String = ""
) -> String:
	var info := _get_object_info(definition_id, fallback_region_id)
	if info.is_empty():
		return ""
	return "现场阶段：%s已完成；%s；回基地：%s" % [
		String(info.get("title", "")),
		String(info.get("complete", "")),
		_get_region_text(String(info.get("region_id", "")), "return")
	]


static func get_region_id_for_definition(definition_id: String) -> String:
	var info: Dictionary = OBJECT_STAGE_INFO.get(definition_id, {})
	return String(info.get("region_id", ""))


static func _format_region_progress(world_state: WorldState, region_id: String) -> String:
	var object_ids: Array = REGION_OBJECT_IDS.get(region_id, [])
	var completed := 0
	for definition_id in object_ids:
		if _is_definition_processed(world_state, String(definition_id)):
			completed += 1
	return "%d/%d" % [completed, object_ids.size()]


static func _has_region_object_state(world_state: WorldState, region_id: String) -> bool:
	if world_state == null:
		return false
	var object_ids: Array = REGION_OBJECT_IDS.get(region_id, [])
	for object_state in world_state.map_objects.values():
		if not object_state is Dictionary:
			continue
		if object_ids.has(String(object_state.get("definition_id", ""))):
			return true
	return false


static func _get_next_region_step(world_state: WorldState, region_id: String) -> String:
	var object_ids: Array = REGION_OBJECT_IDS.get(region_id, [])
	for definition_id in object_ids:
		var object_id := String(definition_id)
		if not _is_definition_processed(world_state, object_id):
			var info: Dictionary = OBJECT_STAGE_INFO.get(object_id, {})
			return String(info.get("pending", _get_region_text(region_id, "active")))
	return "本区域代表性现场对象已处理，下一步回基地整理产物并接入后续路线。"


static func _is_definition_processed(world_state: WorldState, definition_id: String) -> bool:
	if world_state == null:
		return false
	for object_state in world_state.map_objects.values():
		if not object_state is Dictionary:
			continue
		if String(object_state.get("definition_id", "")) != definition_id:
			continue
		if _is_object_state_processed(object_state):
			return true
	return false


static func _is_object_state_processed(object_state: Dictionary) -> bool:
	return (
		bool(object_state.get("is_gathered", false))
		or bool(object_state.get("is_sampled", false))
		or bool(object_state.get("is_cleared", false))
		or bool(object_state.get("anchor_field_stabilized", false))
	)


static func _get_object_info(definition_id: String, fallback_region_id: String) -> Dictionary:
	var info: Dictionary = OBJECT_STAGE_INFO.get(definition_id, {})
	if not info.is_empty():
		return info
	if not REGION_IDS.has(fallback_region_id):
		return {}
	return {
		"region_id": fallback_region_id,
		"title": _get_region_text(fallback_region_id, "title"),
		"pending": _get_region_text(fallback_region_id, "active"),
		"complete": "区域代表性交互已处理"
	}


static func _get_region_text(region_id: String, key: String) -> String:
	var info: Dictionary = REGION_INFO.get(region_id, {})
	return String(info.get(key, ""))
