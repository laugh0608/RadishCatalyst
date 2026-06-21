extends RefCounted
class_name DemoIndustrialModuleTaskRhythmFormatter

const OUTPOST_CORE_ID := "building.outpost_core"
const BASIC_REACTOR_ID := "building.basic_reactor"
const POLLUTION_FILTER_ID := "building.pollution_filter"
const BASIC_STORAGE_ID := "building.basic_storage"
const CRYSTAL_COLLECTOR_ID := "building.crystal_collector_t1"
const FIELD_OUTFITTING_STATION_ID := "building.field_outfitting_station"
const BASIC_FILTER_MODULE_ID := "equipment.filter_module_t1"

const STAGE_STORAGE_BOOTSTRAP := "stage.storage_bootstrap"
const STAGE_OUTFITTING_BOOTSTRAP := "stage.outfitting_bootstrap"
const STAGE_MODULE_MATERIALS := "stage.module_materials"
const STAGE_MODULE_ASSEMBLY := "stage.module_assembly"
const STAGE_MODULE_OUTFITTING := "stage.module_outfitting"
const STAGE_POLLUTION_FILTER_BUILD := "stage.pollution_filter_build"
const STAGE_POLLUTION_PROCESSING := "stage.pollution_processing"
const STAGE_CORE_BUFFER_PREP := "stage.core_buffer_prep"
const STAGE_SORTIE_READY := "stage.sortie_ready"

const CORE_MODULE_IDS: Array[String] = [
	OUTPOST_CORE_ID,
	BASIC_REACTOR_ID,
	POLLUTION_FILTER_ID,
	BASIC_STORAGE_ID,
	FIELD_OUTFITTING_STATION_ID
]

const REQUIRED_STAGE_IDS: Array[String] = [
	STAGE_STORAGE_BOOTSTRAP,
	STAGE_OUTFITTING_BOOTSTRAP,
	STAGE_MODULE_MATERIALS,
	STAGE_MODULE_ASSEMBLY,
	STAGE_MODULE_OUTFITTING,
	STAGE_POLLUTION_FILTER_BUILD,
	STAGE_POLLUTION_PROCESSING,
	STAGE_CORE_BUFFER_PREP,
	STAGE_SORTIE_READY
]


static func get_core_module_ids() -> Array[String]:
	return CORE_MODULE_IDS.duplicate()


static func get_required_stage_ids() -> Array[String]:
	return REQUIRED_STAGE_IDS.duplicate()


static func format_hud_summary(world_state: WorldState, character_state: CharacterState) -> Array[String]:
	if not _should_show_hud_summary(world_state, character_state):
		return []
	var stage_line := format_current_stage_line(world_state, character_state)
	var next_action := format_next_player_action(world_state, character_state)
	if stage_line.is_empty():
		return []
	if next_action.is_empty():
		return [stage_line]
	return [stage_line, "任务节奏：%s" % next_action]


static func format_current_stage_line(world_state: WorldState, character_state: CharacterState) -> String:
	var stage_id := get_current_stage_id(world_state, character_state)
	match stage_id:
		STAGE_STORAGE_BOOTSTRAP:
			return "模块职责：前哨核心负责恢复与出发；基础储存箱还未接入补给。"
		STAGE_OUTFITTING_BOOTSTRAP:
			return "模块职责：储存箱已接入补给；出发整备台还未接入模块装配。"
		STAGE_MODULE_MATERIALS:
			return "模块职责：基础反应器正在承接晶体 / 样本材料，目标是做出过滤模块原料。"
		STAGE_MODULE_ASSEMBLY:
			return "模块职责：基础反应器负责把滤材和基础零件组装成基础过滤模块。"
		STAGE_MODULE_OUTFITTING:
			return "模块职责：出发整备台负责把基础过滤模块装入防护服。"
		STAGE_POLLUTION_FILTER_BUILD:
			return "模块职责：污染过滤器建造未完成，污染沉积物还不能稳定转成药剂。"
		STAGE_POLLUTION_PROCESSING:
			return "模块职责：污染过滤器负责药剂与污染浆液；储存箱负责把补给带回前哨核心。"
		STAGE_CORE_BUFFER_PREP:
			return "模块职责：基础反应器负责核心稳压缓冲包，污染过滤器与储存箱负责前置补给。"
		STAGE_SORTIE_READY:
			return "模块职责：前哨核心补生命 / 防护 / 补给；整备台和反应器服务下一趟外勤。"
		_:
			return ""


static func format_next_player_action(world_state: WorldState, character_state: CharacterState) -> String:
	var stage_id := get_current_stage_id(world_state, character_state)
	match stage_id:
		STAGE_STORAGE_BOOTSTRAP:
			return "先在基地平台建基础储存箱，让修复凝胶能随前哨核心补回。"
		STAGE_OUTFITTING_BOOTSTRAP:
			return "建出发整备台；后续模块不是留在背包里，而是装进防护服。"
		STAGE_MODULE_MATERIALS:
			return "采集晶体 / 样本后回基础反应器处理滤材和基础零件。"
		STAGE_MODULE_ASSEMBLY:
			return "在基础反应器启动组装基础过滤模块，再回整备台装配。"
		STAGE_MODULE_OUTFITTING:
			return "靠近出发整备台按 E 装入基础过滤模块。"
		STAGE_POLLUTION_FILTER_BUILD:
			return "清理处理点、铺设地基并建污染过滤器。"
		STAGE_POLLUTION_PROCESSING:
			return "把污染沉积物和基础溶剂带回过滤器，药剂进补给，浆液留给后续核心准备。"
		STAGE_CORE_BUFFER_PREP:
			return "补齐修复凝胶、抗污染药剂、污染浆液和基础零件后启动核心稳压缓冲包。"
		STAGE_SORTIE_READY:
			return "回前哨核心补满生命 / 防护 / 补给，再从外勤出发口推进下一段。"
		_:
			return ""


static func get_current_stage_id(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state == null:
		return ""
	if not world_state.has_base_structure_definition(BASIC_STORAGE_ID):
		return STAGE_STORAGE_BOOTSTRAP
	if not world_state.has_base_structure_definition(FIELD_OUTFITTING_STATION_ID):
		return STAGE_OUTFITTING_BOOTSTRAP
	if not _has_filter_module_available(character_state):
		if _has_filter_module_inputs(character_state):
			return STAGE_MODULE_ASSEMBLY
		return STAGE_MODULE_MATERIALS
	if not FieldOutfittingRuntime.has_filter_module_equipped(character_state):
		return STAGE_MODULE_OUTFITTING
	if not world_state.has_base_structure_definition(POLLUTION_FILTER_ID):
		return STAGE_POLLUTION_FILTER_BUILD
	if _should_prepare_core_buffer(world_state, character_state):
		return STAGE_CORE_BUFFER_PREP
	if not _has_first_resistance_vial_processed(world_state):
		return STAGE_POLLUTION_PROCESSING
	return STAGE_SORTIE_READY


static func format_device_status_line(
	building_id: String,
	recipe_id: String,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	var building_role := _trim_sentence_end(_format_building_role(building_id, world_state, character_state))
	var recipe_task := _trim_sentence_end(format_recipe_task_hint(recipe_id, world_state, character_state))
	if building_role.is_empty():
		if recipe_task.is_empty():
			return ""
		return "任务节奏：%s" % recipe_task
	if recipe_task.is_empty():
		return "任务节奏：%s" % building_role
	return "任务节奏：%s；%s" % [building_role, recipe_task]


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
	var task_hint := format_recipe_task_hint(recipe_id, world_state, character_state)
	if task_hint.is_empty():
		return ""
	return "任务节奏：%s" % task_hint


static func format_result_feedback_line(
	recipe_id: String,
	world_state: WorldState,
	character_state: CharacterState = null
) -> String:
	return format_recipe_task_hint(recipe_id, world_state, character_state)


static func format_recipe_task_hint(
	recipe_id: String,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	match recipe_id:
		"recipe.process_crystal_ore":
			return "基础零件优先补储存箱、整备台、过滤模块和核心缓冲包缺口。"
		"recipe.reclaim_basic_parts":
			return "副产回收回到基础零件池，优先补建造或核心缓冲包。"
		"recipe.make_filter_media":
			return "滤材下一步进入基础过滤模块或污染过滤器建造。"
		"recipe.basic_filter_module":
			if character_state != null and character_state.inventory.has_ref(BASIC_FILTER_MODULE_ID, 1):
				return "基础过滤模块已在背包，下一步去出发整备台装入防护服。"
			return "完成后带到出发整备台装配，不作为普通背包物品长期停留。"
		"recipe.repair_gel":
			return "修复凝胶进入储存箱 / 前哨核心补给，服务下一趟外勤承压。"
		"recipe.foundation_t1":
			return "地基服务污染过滤器建造，2 块后处理点才能上线。"
		"recipe.cleanse_residue":
			return "药剂进快捷补给，污染浆液留给核心缓冲包或后续副产回收。"
		"recipe.core_stabilization_buffer":
			return "核心稳压缓冲包完成后回核心稳定站，进入守卫和写入准备。"
		_:
			return ""


static func format_build_prompt_line(
	building_id: String,
	status: Dictionary,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	var hint := format_build_task_hint(building_id, world_state, character_state)
	if hint.is_empty():
		return ""
	if bool(status.get("can_build", false)):
		return "任务节奏：%s；当前材料可直接建造。" % hint
	return "任务节奏：%s" % hint


static func format_build_task_hint(
	building_id: String,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	match building_id:
		BASIC_STORAGE_ID:
			return "基础储存箱接入前哨核心补修复凝胶，是每趟外勤回基地后的补给落点。"
		CRYSTAL_COLLECTOR_ID:
			return "基础晶体采集器把重复采矿交给矿面设备，玩家转为收料并回基地入料。"
		FIELD_OUTFITTING_STATION_ID:
			return "出发整备台把基地制造出的模块装进防护服，让污染承压差异进入下一趟外勤。"
		POLLUTION_FILTER_ID:
			return "污染过滤器把污染沉积物转成抗污染药剂和污染浆液，连接污染推进与核心准备。"
		"building.foundation_t1":
			return "基础地基服务污染过滤器上线，两块地基后处理点才从清障进入加工。"
		_:
			return ""


static func format_build_result_line(
	building_id: String,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	match building_id:
		BASIC_STORAGE_ID:
			return "储存箱已成为补给落点；回前哨核心时修复凝胶会按储存箱目标补回。"
		CRYSTAL_COLLECTOR_ID:
			return "采集器已成为晶体矿面的稳定出料点；下一步收取托盘并回基础反应器入料。"
		FIELD_OUTFITTING_STATION_ID:
			return "整备台已成为模块装配点；过滤模块完成后在这里装入防护服。"
		POLLUTION_FILTER_ID:
			return "污染过滤器已成为处理点设备；污染沉积物现在能转成药剂和污染浆液。"
		"building.foundation_t1":
			if world_state != null and world_state.count_base_structures("building.foundation_t1") >= 2:
				return "两块基础地基已就绪；下一步建污染过滤器接通污染处理。"
			return "基础地基已写入处理点；继续补齐两块地基后建污染过滤器。"
		_:
			return ""


static func format_outpost_core_prompt_line(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state == null:
		return ""
	var next_action := format_next_player_action(world_state, character_state)
	if next_action.is_empty():
		return ""
	return "任务节奏：前哨核心是补生命 / 防护 / 补给的回合落点；%s" % next_action


static func format_outfitting_station_prompt_line(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state == null:
		return ""
	if not world_state.has_base_structure_definition(FIELD_OUTFITTING_STATION_ID):
		return "任务节奏：整备台未上线，模块还不能变成外勤承压差异。"
	if FieldOutfittingRuntime.has_filter_module_equipped(character_state):
		return "任务节奏：基础过滤模块已装入防护服；回前哨核心补给后再出发。"
	if character_state != null and character_state.inventory.has_ref(BASIC_FILTER_MODULE_ID, 1):
		return "任务节奏：背包已有基础过滤模块，当前整备台负责把它装入防护服。"
	return "任务节奏：先用基础反应器组装基础过滤模块，再回整备台装配。"


static func _format_building_role(
	building_id: String,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	match building_id:
		OUTPOST_CORE_ID:
			return "前哨核心补生命 / 防护 / 补给，并把储存箱产出的补给带入下一趟外勤。"
		BASIC_REACTOR_ID:
			return "基础反应器把外勤材料转成基础零件、滤材、修复凝胶、模块和核心缓冲包。"
		POLLUTION_FILTER_ID:
			return "污染过滤器把污染沉积物转成药剂和污染浆液，药剂回补给，浆液回核心准备。"
		BASIC_STORAGE_ID:
			return "基础储存箱承接修复凝胶和药剂补给，让前哨核心可稳定补回。"
		CRYSTAL_COLLECTOR_ID:
			return "基础晶体采集器把晶体矿面变成设备出料点，输出托盘回到基础反应器。"
		FIELD_OUTFITTING_STATION_ID:
			return "出发整备台把模块装进防护服，让设备产出变成外勤承压差异。"
		_:
			return ""


static func _trim_sentence_end(text: String) -> String:
	return text.strip_edges().trim_suffix("。")


static func _should_show_hud_summary(world_state: WorldState, character_state: CharacterState) -> bool:
	if world_state == null or character_state == null:
		return false
	if not world_state.quest_state.has_completed_quest("quest.restore_outpost"):
		return false
	if _has_any_industrial_task_quest(world_state):
		return true
	if world_state.current_region_id != "region.outpost_platform":
		return false
	return (
		world_state.has_base_structure_definition(BASIC_STORAGE_ID)
		or world_state.has_base_structure_definition(FIELD_OUTFITTING_STATION_ID)
		or world_state.has_base_structure_definition(POLLUTION_FILTER_ID)
		or _has_filter_module_available(character_state)
	)


static func _has_any_industrial_task_quest(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	for quest_id in [
		"quest.make_filter_module",
		"quest.expand_treatment_point",
		"quest.enter_pollution_edge",
		"quest.prepare_demo_stabilization_buffer"
	]:
		if world_state.quest_state.has_active_quest(quest_id):
			return true
	return false


static func _has_filter_module_available(character_state: CharacterState) -> bool:
	if FieldOutfittingRuntime.has_filter_module_equipped(character_state):
		return true
	if character_state == null:
		return false
	return character_state.inventory.has_ref(BASIC_FILTER_MODULE_ID, 1)


static func _has_filter_module_inputs(character_state: CharacterState) -> bool:
	if character_state == null:
		return false
	return (
		character_state.inventory.has_ref("item.filter_media", 1)
		and character_state.inventory.has_ref("item.basic_parts", 2)
	)


static func _has_first_resistance_vial_processed(world_state: WorldState) -> bool:
	return (
		world_state != null
		and (
			world_state.quest_state.has_completed_quest("quest.enter_pollution_edge")
			or world_state.quest_state.get_objective_progress(
				"quest.enter_pollution_edge",
				"craft_item",
				"item.resistance_vial_t1"
			) >= 1.0
		)
	)


static func _should_prepare_core_buffer(
	world_state: WorldState,
	character_state: CharacterState
) -> bool:
	if world_state == null or character_state == null:
		return false
	if world_state.quest_state.has_active_quest("quest.prepare_demo_stabilization_buffer"):
		return true
	return (
		character_state.inventory.has_ref("item.repair_gel", 1)
		and character_state.inventory.has_ref("item.resistance_vial_t1", 1)
		and character_state.inventory.has_ref("fluid.polluted_slurry", 1.0)
		and character_state.inventory.has_ref("item.basic_parts", 2)
	)
