extends RefCounted
class_name SceneArtFoundationFormatter

const CORE_REGION_IDS := [
	"region.outpost_platform",
	"region.crystal_vein_field",
	"region.pollution_edge",
	"region.demo_stabilization_core"
]

const BASE_DEFINITION_IDS := [
	"building.outpost_core",
	"building.basic_reactor",
	"building.field_outfitting_station",
	"building.basic_storage",
	"building.slurry_buffer_tank",
	"map_object.outpost_departure_gate",
	"map_object.outpost_logistics_route_sign"
]
const CRYSTAL_DEFINITION_IDS := [
	"map_object.crystal_cluster",
	"map_object.rich_crystal_vein",
	"map_object.field_wreckage",
	"map_object.anomaly_crystal",
	"map_object.anomaly_residue_patch"
]
const POLLUTION_DEFINITION_IDS := [
	"map_object.pollution_residue_patch",
	"map_object.rough_ground",
	"building.foundation_t1",
	"building.pollution_filter"
]
const CORE_DEFINITION_IDS := [
	"map_object.demo_stabilization_core",
	"map_object.demo_stabilization_recovery_cache",
	"map_object.demo_stabilization_guard_cache",
	"map_object.demo_stabilization_retest_readout_cache",
	"map_object.demo_stabilization_logistics_retest_residue"
]


static func format_hud_summary(world_state: WorldState, _character_state: CharacterState = null) -> Array[String]:
	if world_state == null:
		return []
	var region_id := String(world_state.current_region_id)
	if region_id == "region.outpost_platform" or not CORE_REGION_IDS.has(region_id):
		return []
	return [
		"场景识别：%s" % _get_region_title(region_id),
		"回基地理由：%s" % _get_region_return_reason(region_id)
	]


static func format_map_route_hint(region_id: String) -> String:
	if not CORE_REGION_IDS.has(region_id):
		return ""
	return "场景：%s；%s；回基地：%s" % [
		_get_region_title(region_id),
		_get_region_visual_read(region_id),
		_get_region_return_reason(region_id)
	]


static func format_object_scene_line(definition_id: String, fallback_region_id: String = "") -> String:
	var region_id := get_region_id_for_definition(definition_id)
	if region_id.is_empty() and CORE_REGION_IDS.has(fallback_region_id):
		region_id = fallback_region_id
	if region_id.is_empty():
		return ""
	return "场景：%s；%s" % [_get_region_title(region_id), _get_region_object_reason(region_id)]


static func get_region_id_for_definition(definition_id: String) -> String:
	if BASE_DEFINITION_IDS.has(definition_id):
		return "region.outpost_platform"
	if CRYSTAL_DEFINITION_IDS.has(definition_id):
		return "region.crystal_vein_field"
	if POLLUTION_DEFINITION_IDS.has(definition_id):
		return "region.pollution_edge"
	if CORE_DEFINITION_IDS.has(definition_id):
		return "region.demo_stabilization_core"
	return ""


static func _get_region_title(region_id: String) -> String:
	match region_id:
		"region.outpost_platform":
			return "基地整备回路"
		"region.crystal_vein_field":
			return "晶体矿脉资源线"
		"region.pollution_edge":
			return "污染边界过滤线"
		"region.demo_stabilization_core":
			return "核心稳定站终点"
		_:
			return ""


static func _get_region_visual_read(region_id: String) -> String:
	match region_id:
		"region.outpost_platform":
			return "青色设备垫把前哨核心、基础反应器、出发整备台和出发口串成整备路线"
		"region.crystal_vein_field":
			return "蓝色矿脉带和下方残骸口袋区分主采集线与侧路回收"
		"region.pollution_edge":
			return "黄绿施工带在上方，深色危险沉积带在下方，边界线提示承压变化"
		"region.demo_stabilization_core":
			return "青绿核心垫、橙色守卫压力区和回写线指向 Demo 终点"
		_:
			return ""


static func _get_region_return_reason(region_id: String) -> String:
	match region_id:
		"region.outpost_platform":
			return "外勤材料在这里转成加工、补给和下一趟出发整备。"
		"region.crystal_vein_field":
			return "晶体矿物和残骸废件要回基础反应器变成基础零件、模块和维护材料。"
		"region.pollution_edge":
			return "污染沉积物要回过滤器转成抗污染药剂和污染浆液，支撑后续外勤。"
		"region.demo_stabilization_core":
			return "守卫缓存、补给和稳定写入会回指前哨核心、整备台和核心站复测。"
		_:
			return ""


static func _get_region_object_reason(region_id: String) -> String:
	match region_id:
		"region.outpost_platform":
			return "这里把回收材料接到加工、补给和出发整备。"
		"region.crystal_vein_field":
			return "这里提供基础矿物、残骸和异常样本，带回基地才会变成外勤收益。"
		"region.pollution_edge":
			return "这里同时给出危险沉积和过滤回基地理由。"
		"region.demo_stabilization_core":
			return "这里验证补给、守卫压力和稳定写入，是首版 Demo 终点。"
		_:
			return ""
