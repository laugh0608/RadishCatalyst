extends RefCounted
class_name DemoFieldTaskDifferentiationFormatter

const FIELD_TASK_CONFIRMED_FLAG := "field_task_differentiation_confirmed"
const FIELD_OUTFITTING_STATION_ID := "building.field_outfitting_station"
const FIELD_OUTFITTING_STATION_INSTANCE_ID := "map_object_instance.field_outfitting_station"
const BASIC_FILTER_MODULE_ID := "equipment.filter_module_t1"

const CRYSTAL_OBJECT_IDS: Array[String] = [
	"map_object.crystal_cluster",
	"map_object.rich_crystal_vein"
]
const POLLUTION_OBJECT_ID := "map_object.pollution_residue_patch"
const CORE_CACHE_INSTANCE_IDS: Array[String] = [
	"map_object_instance.core_buffer_residue_cache",
	"map_object_instance.demo_stabilization_recovery_cache",
	"map_object_instance.demo_stabilization_guard_cache"
]
const TASK_RECIPE_IDS: Array[String] = [
	"recipe.process_crystal_ore",
	"recipe.cleanse_residue",
	"recipe.reclaim_basic_parts",
	"recipe.core_stabilization_buffer"
]


static func get_task_recipe_ids() -> Array[String]:
	return TASK_RECIPE_IDS.duplicate()


static func is_confirmed(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return bool(
		world_state.get_map_object(FIELD_OUTFITTING_STATION_INSTANCE_ID).get(
			FIELD_TASK_CONFIRMED_FLAG,
			false
		)
	)


static func can_confirm(world_state: WorldState, character_state: CharacterState) -> bool:
	return (
		_has_station_built(world_state)
		and _has_filter_module_equipped(character_state)
		and not is_confirmed(world_state)
		and _get_ready_lane_count(world_state, character_state) >= 2
	)


static func mark_confirmed(world_state: WorldState) -> void:
	if world_state == null:
		return
	var station_state := world_state.ensure_map_object(
		FIELD_OUTFITTING_STATION_INSTANCE_ID,
		FIELD_OUTFITTING_STATION_ID,
		"region.outpost_platform"
	)
	station_state[FIELD_TASK_CONFIRMED_FLAG] = true


static func format_hud_summary(world_state: WorldState, character_state: CharacterState) -> Array[String]:
	if world_state == null or character_state == null:
		return []
	if world_state.current_region_id != "region.outpost_platform":
		return []
	if is_confirmed(world_state):
		return [
			"任务差异：晶体 / 污染 / 核心准备已登记到整备台",
			"下一趟：按资源类型回对应设备处理，再从出发口推进核心目标"
		]
	var lanes := _format_ready_lane_labels(world_state, character_state)
	if lanes.is_empty():
		return []
	if can_confirm(world_state, character_state):
		return [
			"任务差异待登记：%s" % "；".join(lanes),
			"下一步：出发整备台确认任务差异，再按目标出发"
		]
	return [
		"任务差异：%s" % "；".join(lanes),
		"处理方向：晶体回反应器，污染回过滤器，核心原料回反应器整备"
	]


static func format_object_task_line(
	definition_id: String,
	object_state: Dictionary,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if CRYSTAL_OBJECT_IDS.has(definition_id):
		if bool(object_state.get("is_gathered", false)):
			return "任务差异：晶体已采集；回基础反应器加工基础零件，分流到模块、工具校准或核心缓冲包。"
		return "任务差异：晶体采集不是单纯入库，回基础反应器后转成基础零件。"
	if definition_id == POLLUTION_OBJECT_ID:
		if bool(object_state.get("is_gathered", false)):
			return "任务差异：污染沉积已回收；回污染过滤器拆成抗污染药剂和污染浆液。"
		return "任务差异：污染沉积会带来现场承压，回过滤器后同时补药剂和副产浆液。"
	if definition_id == "map_object.demo_stabilization_core":
		if _has_core_lane_ready(world_state, character_state):
			return "任务差异：核心准备材料已接近齐备；回基础反应器整备核心稳压缓冲包后再写入。"
		return "任务差异：核心写入要读取药剂、浆液、基础零件和守卫缓存，不只看是否到达终点。"
	return ""


static func format_gather_result_line(
	definition_id: String,
	instance_id: String,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if CRYSTAL_OBJECT_IDS.has(definition_id):
		if character_state != null and character_state.inventory.has_ref("item.crystal_ore", 3):
			return "外勤任务差异：晶体矿物已够一炉基础零件，回基础反应器后可分流到过滤模块、工具校准或核心缓冲包。"
		return "外勤任务差异：晶体路线补基础零件，继续采够一炉后回基础反应器。"
	if definition_id == POLLUTION_OBJECT_ID:
		if CORE_CACHE_INSTANCE_IDS.has(instance_id):
			return "外勤任务差异：核心准备污染缓存已回收，回过滤器补药剂和污染浆液，再回反应器整备核心缓冲包。"
		return "外勤任务差异：污染路线会先承压采集，再回过滤器拆成药剂和污染浆液两种收益。"
	return ""


static func format_sample_result_line(definition_id: String) -> String:
	if definition_id == "map_object.anomaly_crystal":
		return "外勤任务差异：异常样本回基础反应器解析后，才会打开过滤模块和污染处理节奏。"
	return ""


static func format_device_status_line(
	building_id: String,
	recipe_id: String,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	var line := format_recipe_task_line(recipe_id, world_state, character_state)
	if not line.is_empty():
		return "任务差异：%s" % line
	match building_id:
		"building.basic_reactor":
			return "任务差异：基础反应器承接晶体加工、副产回收和核心缓冲包整备。"
		"building.pollution_filter":
			return "任务差异：污染过滤器承接高压采集物，把风险转成药剂和污染浆液。"
		_:
			return ""


static func format_processing_prompt_line(
	building_id: String,
	recipe_id: String,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	return format_device_status_line(building_id, recipe_id, world_state, character_state)


static func format_processing_log_line(
	recipe_id: String,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	var line := format_recipe_task_line(recipe_id, world_state, character_state)
	if line.is_empty():
		return ""
	return "任务差异：%s" % line


static func format_recipe_task_line(
	recipe_id: String,
	_world_state: WorldState,
	_character_state: CharacterState
) -> String:
	match recipe_id:
		"recipe.process_crystal_ore":
			return "晶体采集回基地后转基础零件，支撑过滤模块、工具校准和核心缓冲包。"
		"recipe.cleanse_residue":
			return "污染沉积转抗污染药剂和污染浆液，药剂进补给，浆液进核心准备或回收。"
		"recipe.reclaim_basic_parts":
			return "多余污染浆液回收基础零件，补足整备台维护和下一趟出发材料。"
		"recipe.core_stabilization_buffer":
			return "晶体、污染和补给处理结果汇入核心稳压缓冲包，服务终点写入。"
		_:
			return ""


static func format_result_feedback_line(
	recipe_id: String,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	return format_recipe_task_line(recipe_id, world_state, character_state)


static func should_show_result_line(recipe_id: String) -> bool:
	return TASK_RECIPE_IDS.has(recipe_id)


static func format_outfitting_prompt_line(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if is_confirmed(world_state):
		return "任务差异登记：已确认，晶体 / 污染 / 核心准备会按资源类型指向对应设备和下一趟出发收益。"
	if can_confirm(world_state, character_state):
		return "任务差异登记：晶体、污染或核心准备至少两路已有处理结果，可在整备台登记为下一趟外勤任务差异。"
	var lanes := _format_ready_lane_labels(world_state, character_state)
	if lanes.is_empty():
		return ""
	return "任务差异登记：%s；继续补另一类外勤处理结果后再登记。" % "；".join(lanes)


static func format_confirmation_message() -> String:
	return "出发整备台完成任务差异登记：晶体加工、污染过滤和核心准备已按资源类型写入下一趟外勤路线，玩家可以从 HUD、设备面板和对象反馈判断该回哪个设备处理。"


static func format_confirmation_status() -> String:
	return "晶体 / 污染 / 核心准备差异已登记"


static func format_confirmation_next_step() -> String:
	return "回前哨核心补给后，从外勤出发口按当前目标出发；采集晶体回反应器，采集污染回过滤器，核心原料回反应器整备。"


static func _format_ready_lane_labels(
	world_state: WorldState,
	character_state: CharacterState
) -> Array[String]:
	var lanes: Array[String] = []
	if _has_crystal_lane_ready(world_state, character_state):
		lanes.append("晶体->基础零件")
	if _has_pollution_lane_ready(world_state, character_state):
		lanes.append("污染->药剂+浆液")
	if _has_core_lane_ready(world_state, character_state):
		lanes.append("核心准备->缓冲包")
	return lanes


static func _get_ready_lane_count(world_state: WorldState, character_state: CharacterState) -> int:
	return _format_ready_lane_labels(world_state, character_state).size()


static func _has_crystal_lane_ready(world_state: WorldState, character_state: CharacterState) -> bool:
	if character_state != null and character_state.inventory.has_ref("item.crystal_ore", 3):
		return true
	if _has_recent_recipe(world_state, "structure.basic_reactor", "recipe.process_crystal_ore"):
		return true
	if world_state == null:
		return false
	for object_state in world_state.map_objects.values():
		if not object_state is Dictionary:
			continue
		if not bool(object_state.get("is_gathered", false)):
			continue
		if CRYSTAL_OBJECT_IDS.has(String(object_state.get("definition_id", ""))):
			return true
	return false


static func _has_pollution_lane_ready(world_state: WorldState, character_state: CharacterState) -> bool:
	if character_state != null:
		if character_state.inventory.has_ref("item.polluted_residue", 2):
			return true
		if character_state.inventory.has_ref("item.resistance_vial_t1", 1):
			return true
		if character_state.inventory.has_ref("fluid.polluted_slurry", 1):
			return true
	if _has_recent_recipe(world_state, "structure.pollution_filter_build_site", "recipe.cleanse_residue"):
		return true
	if world_state == null:
		return false
	for object_state in world_state.map_objects.values():
		if not object_state is Dictionary:
			continue
		if not bool(object_state.get("is_gathered", false)):
			continue
		if String(object_state.get("definition_id", "")) == POLLUTION_OBJECT_ID:
			return true
	return false


static func _has_core_lane_ready(world_state: WorldState, character_state: CharacterState) -> bool:
	if character_state != null:
		if character_state.inventory.has_ref("item.core_stabilization_buffer", 1):
			return true
		if (
			character_state.inventory.has_ref("item.repair_gel", 1)
			and character_state.inventory.has_ref("item.resistance_vial_t1", 1)
			and character_state.inventory.has_ref("fluid.polluted_slurry", 1)
			and character_state.inventory.has_ref("item.basic_parts", 2)
		):
			return true
	if _has_recent_recipe(world_state, "structure.basic_reactor", "recipe.core_stabilization_buffer"):
		return true
	if world_state == null:
		return false
	for instance_id in CORE_CACHE_INSTANCE_IDS:
		if bool(world_state.get_map_object(instance_id).get("is_gathered", false)):
			return true
	return world_state.quest_state.has_active_quest("quest.prepare_demo_stabilization_buffer")


static func _has_recent_recipe(world_state: WorldState, structure_id: String, recipe_id: String) -> bool:
	if world_state == null:
		return false
	var structure: Dictionary = world_state.base_structures.get(structure_id, {})
	if String(structure.get("last_recipe_id", "")) == recipe_id:
		return true
	for base_structure in world_state.base_structures.values():
		if not base_structure is Dictionary:
			continue
		if String(base_structure.get("last_recipe_id", "")) == recipe_id:
			return true
	return false


static func _has_station_built(world_state: WorldState) -> bool:
	return (
		world_state != null
		and world_state.has_base_structure_definition(FIELD_OUTFITTING_STATION_ID)
	)


static func _has_filter_module_equipped(character_state: CharacterState) -> bool:
	return (
		character_state != null
		and String(character_state.equipment.get("suit_module", "")) == BASIC_FILTER_MODULE_ID
	)
