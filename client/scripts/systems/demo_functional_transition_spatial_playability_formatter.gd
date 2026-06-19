extends RefCounted
class_name DemoFunctionalTransitionSpatialPlayabilityFormatter

const REGION_IDS := [
	"region.ruin_outer_ring",
	"region.deep_ruin_threshold"
]

const REGION_INFO := {
	"region.ruin_outer_ring": {
		"title": "封锁遗迹可达空间",
		"entrance": "遗迹门从污染边界东侧进入，门后先读雾幕边界。",
		"boundary": "抖动雾幕把入口段和外圈深段分开，稳定后才能进入回波匣侧。",
		"hazard": "相位守卫压在回波匣前，污染回波沉积留在下侧口袋。",
		"resource": "继电残片分布在南北两侧，污染回波沉积服务药剂和浆液处理。",
		"facility": "外圈中继台位于深段上侧，回波匣位于返回基地前的目标点。",
		"return": "回基地处理继电残片、污染沉积和回波匣，整理裂相坐标。",
		"next": "向东写入裂相坐标，进入裂相脊入口门禁。"
	},
	"region.deep_ruin_threshold": {
		"title": "裂相脊可达空间",
		"entrance": "裂相门禁从封锁遗迹东侧进入，门后先读锁扣和相位纤丝。",
		"boundary": "裂相锁扣把入口资源段和阵列深段分开，覆写后才进入阵列台。",
		"hazard": "裂相守卫压在入口中线，追袭体守住阵列台和导管回收线。",
		"resource": "相位纤丝在入口南北两侧，导管和读数点沿阵列深段展开。",
		"facility": "裂相阵列台在上侧，前线回传锚点在下侧，形成回基地路线。",
		"return": "回基地精炼纤丝、解析裂相样块和导管读数，整理回传锚点。",
		"next": "通过回传锚点回基地，再从回投台重返更东侧路线。"
	}
}

const OBJECT_SPATIAL_INFO := {
	"map_object.ruin_gate": {
		"region_id": "region.ruin_outer_ring",
		"role": "入口",
		"placement": "污染边界东侧入口，确认后把玩家送入封锁遗迹。"
	},
	"map_object.relay_shard_cache": {
		"region_id": "region.ruin_outer_ring",
		"role": "资源",
		"placement": "南北两侧残片点，迫使玩家离开中线确认可走边界。"
	},
	"map_object.outer_ring_barrier": {
		"region_id": "region.ruin_outer_ring",
		"role": "边界",
		"placement": "入口段中线阻挡，稳定后打开外圈深段。"
	},
	"map_object.outer_ring_console": {
		"region_id": "region.ruin_outer_ring",
		"role": "设施",
		"placement": "深段上侧中继台，读取后让回波匣成为可回收目标。"
	},
	"map_object.signal_echo_cache": {
		"region_id": "region.ruin_outer_ring",
		"role": "回收目标",
		"placement": "深段下侧回波匣，和守卫、沉积物组成回基地处理点。"
	},
	"map_object.pollution_residue_patch": {
		"region_id": "region.ruin_outer_ring",
		"role": "危险资源",
		"placement": "回波匣旁下侧沉积口袋，战斗后回收并带回过滤器处理。"
	},
	"map_object.deep_ruin_door": {
		"region_id": "region.deep_ruin_threshold",
		"role": "入口",
		"placement": "封锁遗迹东侧门禁，写入裂相坐标后打开裂相脊。"
	},
	"map_object.phase_filament_cluster": {
		"region_id": "region.deep_ruin_threshold",
		"role": "资源",
		"placement": "入口南北两侧纤丝点，服务裂相锁扣覆写准备。"
	},
	"map_object.deep_ruin_latch": {
		"region_id": "region.deep_ruin_threshold",
		"role": "边界",
		"placement": "入口段中线锁扣，覆写后进入阵列深段。"
	},
	"map_object.deep_signal_array": {
		"region_id": "region.deep_ruin_threshold",
		"role": "设施",
		"placement": "阵列深段上侧，点亮后打开导管回收线。"
	},
	"map_object.phase_conduit_cluster": {
		"region_id": "region.deep_ruin_threshold",
		"role": "资源",
		"placement": "阵列后侧导管点，回基地整理成深段读数矩阵。"
	},
	"map_object.phase_return_anchor": {
		"region_id": "region.deep_ruin_threshold",
		"role": "返回设施",
		"placement": "阵列下侧回传锚点，把深段结果接回基地相位回投台。"
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
		"可达空间：%s；入口：%s；边界：%s" % [
			_get_region_text(region_id, "title"),
			_get_region_text(region_id, "entrance"),
			_get_region_text(region_id, "boundary")
		],
		"场地落点：危险：%s；资源：%s；设施：%s；回基地：%s" % [
			_get_region_text(region_id, "hazard"),
			_get_region_text(region_id, "resource"),
			_get_region_text(region_id, "facility"),
			_get_region_text(region_id, "return")
		]
	]


static func format_map_route_hint(region_id: String) -> String:
	if not REGION_IDS.has(region_id):
		return ""
	return "可达空间：%s；入口：%s；边界：%s；落点：%s / %s / %s；回基地：%s" % [
		_get_region_text(region_id, "title"),
		_get_region_text(region_id, "entrance"),
		_get_region_text(region_id, "boundary"),
		_get_region_text(region_id, "hazard"),
		_get_region_text(region_id, "resource"),
		_get_region_text(region_id, "facility"),
		_get_region_text(region_id, "return")
	]


static func format_static_object_spatial_line(definition_id: String, fallback_region_id: String = "") -> String:
	var info := _get_object_info(definition_id, fallback_region_id)
	if info.is_empty():
		return ""
	var region_id := String(info.get("region_id", ""))
	return "可达空间：%s；对象落点：%s；%s；去向：%s" % [
		_get_region_text(region_id, "title"),
		String(info.get("role", "")),
		String(info.get("placement", "")),
		_get_region_text(region_id, "next")
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
	return "可达空间：%s已处理；下一段：%s；回基地：%s" % [
		String(info.get("role", "")),
		_get_region_text(region_id, "next"),
		_get_region_text(region_id, "return")
	]


static func get_region_id_for_definition(definition_id: String, fallback_region_id: String = "") -> String:
	var info: Dictionary = OBJECT_SPATIAL_INFO.get(definition_id, {})
	if not info.is_empty():
		return String(info.get("region_id", ""))
	if REGION_IDS.has(fallback_region_id):
		return fallback_region_id
	return ""


static func _get_object_info(definition_id: String, fallback_region_id: String) -> Dictionary:
	var info: Dictionary = OBJECT_SPATIAL_INFO.get(definition_id, {})
	if not info.is_empty():
		return info
	if not REGION_IDS.has(fallback_region_id):
		return {}
	return {
		"region_id": fallback_region_id,
		"role": "区域对象",
		"placement": "当前对象服务本区域入口、边界或回基地处理判断。"
	}


static func _get_region_text(region_id: String, key: String) -> String:
	var info: Dictionary = REGION_INFO.get(region_id, {})
	return String(info.get(key, ""))
