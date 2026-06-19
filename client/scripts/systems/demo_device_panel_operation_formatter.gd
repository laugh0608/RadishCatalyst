extends RefCounted
class_name DemoDevicePanelOperationFormatter

const OUTPOST_CORE_ID := "building.outpost_core"
const BASIC_REACTOR_ID := "building.basic_reactor"
const POLLUTION_FILTER_ID := "building.pollution_filter"
const FIELD_OUTFITTING_STATION_ID := "building.field_outfitting_station"
const CORE_BUFFER_ID := "item.core_stabilization_buffer"

const COVERED_BUILDING_IDS: Array[String] = [
	OUTPOST_CORE_ID,
	BASIC_REACTOR_ID,
	POLLUTION_FILTER_ID,
	FIELD_OUTFITTING_STATION_ID
]

const PRIMARY_RECIPE_IDS: Array[String] = [
	"recipe.process_crystal_ore",
	"recipe.reclaim_basic_parts",
	"recipe.cleanse_residue",
	"recipe.repair_gel",
	"recipe.core_stabilization_buffer"
]


static func get_covered_building_ids() -> Array[String]:
	return COVERED_BUILDING_IDS.duplicate()


static func get_primary_recipe_ids() -> Array[String]:
	return PRIMARY_RECIPE_IDS.duplicate()


static func format_device_status_line(
	building_id: String,
	recipe_id: String,
	status: Dictionary,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	var operation_text := _format_operation_for_recipe(recipe_id, world_state, character_state)
	if operation_text.is_empty():
		operation_text = _format_operation_for_building(building_id, world_state, character_state)
	var missing_text := _format_missing_material_line(recipe_id, status)
	if operation_text.is_empty():
		return missing_text
	if missing_text.is_empty():
		return "操作读法：%s" % operation_text
	return "操作读法：%s；%s" % [operation_text, missing_text]


static func format_processing_prompt_line(
	building_id: String,
	recipe_id: String,
	status: Dictionary,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	return format_device_status_line(building_id, recipe_id, status, world_state, character_state)


static func format_processing_log_line(
	recipe_id: String,
	status: Dictionary,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	var operation_text := _format_operation_for_recipe(recipe_id, world_state, character_state)
	var missing_text := _format_missing_material_line(recipe_id, status)
	if operation_text.is_empty():
		return missing_text
	if missing_text.is_empty():
		return "设备操作：%s" % operation_text
	return "设备操作：%s；%s" % [operation_text, missing_text]


static func format_result_feedback_line(recipe_id: String, world_state: WorldState = null) -> String:
	match recipe_id:
		"recipe.core_stabilization_buffer":
			return "设备操作：核心稳压缓冲包完成后回核心稳定站按入口确认、侧边补给、阶段守卫、回写缓存继续。"
	return ""


static func format_outpost_core_panel_line(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if world_state == null or character_state == null:
		return ""
	if character_state.inventory.has_ref(CORE_BUFFER_ID, 1):
		return "设备操作：前哨核心补满生命、防护和抗污染药剂后，从外勤出发口回核心稳定站推进阶段守卫。"
	if world_state.quest_state.has_active_quest("quest.prepare_demo_stabilization_buffer"):
		return "设备操作：前哨核心先补生命、防护和药剂；缺缓冲包时回污染过滤器与基础反应器补齐。"
	if world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core"):
		return "设备操作：前哨核心负责终点后补给结算；后续按当前任务和地图目标继续，不新增终局面板。"
	return "设备操作：前哨核心负责出发前补生命、防护和快捷药剂；当前目标决定下一趟外勤路线。"


static func format_outfitting_station_panel_line(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if world_state == null or character_state == null:
		return ""
	if not world_state.has_base_structure_definition(FIELD_OUTFITTING_STATION_ID):
		return "设备操作：出发整备台未建成；先完成建造点，再把基础过滤模块装入防护服。"
	if (
		not FieldOutfittingRuntime.has_filter_module_equipped(character_state)
		and character_state.inventory.has_ref(FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID, 1)
	):
		return "设备操作：出发整备台现在应装配基础过滤模块；装配后回前哨核心补给再出发。"
	if FieldOutfittingRuntime.should_confirm_logistics_maintenance(character_state, world_state):
		return "设备操作：出发整备台确认后勤维护；确认后回前哨核心补给并从外勤出发口复测。"
	if FieldOutfittingRuntime.is_core_archive_maintenance_available(character_state, world_state):
		return "设备操作：出发整备台可接入核心归档维护；维护后污染采集和反击承压下降。"
	return "设备操作：出发整备台读取过滤模块、维护和校准状态；确认后回前哨核心补给再出发。"


static func _format_operation_for_building(
	building_id: String,
	_world_state: WorldState,
	_character_state: CharacterState
) -> String:
	match building_id:
		BASIC_REACTOR_ID:
			return "基础反应器承接晶体加工、副产回收、补给制造和核心缓冲包组装。"
		POLLUTION_FILTER_ID:
			return "污染过滤器承接沉积物处理，产出抗污染药剂并留下可分流污染浆液。"
	return ""


static func _format_operation_for_recipe(
	recipe_id: String,
	world_state: WorldState,
	_character_state: CharacterState
) -> String:
	match recipe_id:
		"recipe.process_crystal_ore":
			return "基础反应器把晶体矿物转成基础零件，后续接过滤模块、修复凝胶或核心稳压缓冲包。"
		"recipe.reclaim_basic_parts":
			return "基础反应器把污染浆液回收成基础零件；当前核心目标缺浆液时不要先回收。"
		"recipe.cleanse_residue":
			if world_state != null and world_state.quest_state.has_active_quest("quest.prepare_demo_stabilization_buffer"):
				return "污染过滤器把沉积物转成抗污染药剂和污染浆液；完成后回基础反应器整备核心稳压缓冲包。"
			return "污染过滤器把沉积物转成抗污染药剂并留下污染浆液；药剂回前线承压，浆液回基础反应器或后续组装。"
		"recipe.repair_gel":
			return "基础反应器把基础零件和溶剂调成修复凝胶；凝胶用于下一段战斗前的快捷补给。"
		"recipe.core_stabilization_buffer":
			return "基础反应器把修复凝胶、抗污染药剂、污染浆液和基础零件压成核心稳压缓冲包；完成后回核心稳定站。"
	return ""


static func _format_missing_material_line(recipe_id: String, status: Dictionary) -> String:
	var missing_inputs: Array = status.get("missing_inputs", [])
	if missing_inputs.is_empty():
		return ""
	var missing_text := _join_strings(missing_inputs)
	var supply_hint := String(status.get("supply_hint", "")).strip_edges().trim_suffix("。")
	if supply_hint.is_empty():
		return "缺料读法：缺 %s；先补齐原料，再回当前设备启动。" % missing_text
	if recipe_id == "recipe.core_stabilization_buffer":
		return "缺料读法：缺 %s；按缺料去向补齐后，再回基础反应器启动核心稳压缓冲包；%s。" % [
			missing_text,
			supply_hint
		]
	return "缺料读法：缺 %s；%s。" % [missing_text, supply_hint]


static func _join_strings(values: Array) -> String:
	var parts: Array[String] = []
	for value in values:
		var text := String(value).strip_edges()
		if not text.is_empty():
			parts.append(text)
	return "，".join(parts)
