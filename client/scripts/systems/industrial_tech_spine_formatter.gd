extends RefCounted
class_name IndustrialTechSpineFormatter

const BASIC_REACTOR_ID := "building.basic_reactor"
const POLLUTION_FILTER_ID := "building.pollution_filter"
const FIELD_OUTFITTING_STATION_ID := "building.field_outfitting_station"
const BASIC_PARTS_ID := "item.basic_parts"
const POLLUTED_RESIDUE_ID := "item.polluted_residue"
const RESISTANCE_VIAL_ID := "item.resistance_vial_t1"
const FILTER_MEDIA_ID := "item.filter_media"
const REPAIR_GEL_ID := "item.repair_gel"
const CORE_BUFFER_ID := "item.core_stabilization_buffer"
const POLLUTED_SLURRY_ID := "fluid.polluted_slurry"


static func format_hud_summary(world_state: WorldState, character_state: CharacterState) -> Array[String]:
	if world_state == null or character_state == null:
		return []
	if world_state.current_region_id != "region.outpost_platform":
		return []
	if not _should_show_hud_summary(world_state, character_state):
		return []

	var material_line := _format_current_material_chain(world_state, character_state)
	var sortie_line := _format_next_sortie_chain(world_state, character_state)
	if material_line.is_empty() and sortie_line.is_empty():
		return []

	var lines: Array[String] = []
	if not material_line.is_empty():
		lines.append("工艺主干：%s" % material_line)
	if not sortie_line.is_empty():
		lines.append("外勤收益：%s" % sortie_line)
	return lines


static func format_device_status_line(
	building_id: String,
	recipe_id: String,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	var recipe_hint := format_recipe_chain_hint(recipe_id, world_state, character_state)
	if not recipe_hint.is_empty():
		return "工艺主干：%s" % recipe_hint
	var building_hint := format_building_chain_hint(building_id, world_state, character_state)
	if building_hint.is_empty():
		return ""
	return "工艺主干：%s" % building_hint


static func format_processing_prompt_line(
	building_id: String,
	recipe_id: String,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	var recipe_hint := format_recipe_chain_hint(recipe_id, world_state, character_state)
	if not recipe_hint.is_empty():
		return "主干：%s" % recipe_hint
	var building_hint := format_building_chain_hint(building_id, world_state, character_state)
	if building_hint.is_empty():
		return ""
	return "主干：%s" % building_hint


static func format_outfitting_station_prompt_line(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if world_state == null or character_state == null:
		return ""
	if not FieldOutfittingRuntime.has_station_built(world_state):
		return "主干：基础零件 + 残骸废件会建出发整备台；整备台把过滤模块和补给变成下一趟外勤收益。"
	if not FieldOutfittingRuntime.has_filter_module_equipped(character_state):
		if character_state.inventory.has_ref(FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID, 1):
			return "主干：基础过滤模块已在背包；在整备台装入防护服后，污染采集和反击承压会下降。"
		return "主干：先用基础反应器组装基础过滤模块，再在整备台装入防护服。"
	if FieldOutfittingRuntime.has_active_logistics_maintenance(character_state, world_state):
		return "主干：整备台已接入基础过滤模块和后勤维护；污染过滤器补药剂，维护状态服务下一趟污染 / 遗迹 / 核心站承压。"
	if FieldOutfittingRuntime.has_active_core_archive_maintenance(character_state, world_state):
		return "主干：整备台已接入基础过滤模块和核心归档维护；药剂与模块一起支撑核心站复测。"
	if FieldOutfittingRuntime.has_active_module_calibration(character_state, world_state):
		return "主干：整备台已校准基础过滤模块；下一趟污染采集、污染反击和遗迹外圈反击会读取校准收益。"
	return "主干：整备台已装入基础过滤模块；过滤器补药剂，模块负责把基地加工收益带进外勤。"


static func format_processing_log_line(
	recipe_id: String,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	var chain_hint := format_recipe_chain_hint(recipe_id, world_state, character_state)
	if chain_hint.is_empty():
		return ""
	return "工艺：%s" % chain_hint


static func format_result_feedback_line(
	recipe_id: String,
	world_state: WorldState,
	character_state: CharacterState = null
) -> String:
	match recipe_id:
		"recipe.cleanse_residue":
			if world_state != null:
				if world_state.quest_state.has_active_quest("quest.prepare_demo_stabilization_buffer"):
					return "药剂支撑核心站排压，污染浆液留给核心稳压缓冲包。"
				if world_state.quest_state.has_active_quest("quest.salvage_signal_echo"):
					return "药剂支撑遗迹外圈承压，污染浆液留给深段回波解析。"
				if world_state.quest_state.has_active_quest("quest.assemble_phase_anchor"):
					return "药剂支撑遗迹外圈承压，污染浆液进入稳相信标组装。"
		"recipe.basic_filter_module":
			return "基础过滤模块到出发整备台装入防护服，服务下一趟污染承压。"
		"recipe.core_stabilization_buffer":
			return "核心稳压缓冲包服务守卫第一段回写压力。"
		"recipe.reclaim_basic_parts":
			return "污染副产回收成基础零件，支撑整备台维护和补给。"
	return ""


static func format_building_chain_hint(
	building_id: String,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	match building_id:
		BASIC_REACTOR_ID:
			return "基础反应器把晶体矿物 / 污染浆液转成基础零件，再继续支撑过滤模块、修复凝胶和核心稳压缓冲包。"
		POLLUTION_FILTER_ID:
			return "污染过滤器把污染沉积物转成抗污染药剂 + 污染浆液；药剂进外勤补给，浆液回反应器或后续组装。"
		FIELD_OUTFITTING_STATION_ID:
			return format_outfitting_station_prompt_line(world_state, character_state).trim_prefix("主干：")
		_:
			return ""


static func format_recipe_chain_hint(
	recipe_id: String,
	world_state: WorldState,
	_character_state: CharacterState = null
) -> String:
	match recipe_id:
		"recipe.process_crystal_ore":
			return "晶体矿物 -> 基础零件；基础零件继续进入过滤模块、修复凝胶、污染浆液回收或核心稳压缓冲包。"
		"recipe.reclaim_basic_parts":
			return "污染浆液 -> 基础零件；污染副产被回收后可补过滤模块、整备台维护和下一趟外勤补给。"
		"recipe.make_filter_media":
			return "基础零件 + 基础溶剂 -> 过滤介质；过滤介质继续进入基础过滤模块或污染过滤器建设。"
		"recipe.basic_filter_module":
			return "基础零件 + 过滤介质 -> 基础过滤模块；到出发整备台装入防护服后服务污染采集和反击承压。"
		"recipe.cleanse_residue":
			return _format_pollution_filter_recipe_hint(world_state)
		"recipe.repair_gel":
			return "基础零件 + 基础溶剂 -> 修复凝胶；出发前补给，支撑下一段清障战斗。"
		"recipe.core_stabilization_buffer":
			return "修复凝胶 + 抗污染药剂 + 污染浆液 + 基础零件 -> 核心稳压缓冲包；服务核心站守卫第一段回写压力。"
		"recipe.phase_anchor":
			return "继电残片 + 污染浆液 + 基础零件 -> 稳相信标；服务遗迹外圈雾幕稳定。"
		"recipe.phase_filament_refining":
			return "污染过滤器剥离相位纤丝，产出谐振滤芯并留下污染浆液；二者都会回到反应器组装裂相覆写栓。"
		"recipe.deep_override_key":
			return "谐振滤芯 + 污染浆液 + 基础零件 -> 裂相覆写栓；服务裂相脊入口开路。"
		_:
			return ""


static func _format_pollution_filter_recipe_hint(world_state: WorldState) -> String:
	if world_state != null:
		if world_state.quest_state.has_active_quest("quest.salvage_signal_echo"):
			return "污染沉积物 -> 抗污染药剂 + 污染浆液；药剂支撑遗迹外圈承压，浆液要留给深段回波解析。"
		if world_state.quest_state.has_active_quest("quest.prepare_demo_stabilization_buffer"):
			return "污染沉积物 -> 抗污染药剂 + 污染浆液；药剂支撑核心站排压，污染浆液要留给核心稳压缓冲包。"
		if world_state.quest_state.has_active_quest("quest.assemble_phase_anchor"):
			return "污染沉积物 -> 抗污染药剂 + 污染浆液；药剂支撑遗迹外圈承压，浆液进入稳相信标组装。"
	return "污染沉积物 -> 抗污染药剂 + 污染浆液；药剂进快捷栏，浆液可回基础反应器回收成基础零件或留作后续组装输入。"


static func _should_show_hud_summary(world_state: WorldState, character_state: CharacterState) -> bool:
	if _has_current_spine_materials(character_state):
		return true
	if _has_active_spine_quest(world_state):
		return true
	return false


static func _has_current_spine_materials(character_state: CharacterState) -> bool:
	return (
		character_state.inventory.has_ref(POLLUTED_RESIDUE_ID, 1)
		or character_state.inventory.has_ref(POLLUTED_SLURRY_ID, 1)
		or character_state.inventory.has_ref(FILTER_MEDIA_ID, 1)
		or character_state.inventory.has_ref(RESISTANCE_VIAL_ID, 1)
		or character_state.inventory.has_ref(CORE_BUFFER_ID, 1)
	)


static func _has_active_spine_quest(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	for quest_id in [
		"quest.make_filter_module",
		"quest.enter_pollution_edge",
		"quest.assemble_phase_anchor",
		"quest.salvage_signal_echo",
		"quest.prepare_demo_stabilization_buffer"
	]:
		if world_state.quest_state.has_active_quest(quest_id):
			return true
	return false


static func _format_current_material_chain(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if character_state.inventory.has_ref(POLLUTED_RESIDUE_ID, 2):
		return "污染沉积物可回污染过滤器转成抗污染药剂 + 污染浆液。"
	if character_state.inventory.has_ref(POLLUTED_SLURRY_ID, 1):
		if world_state.quest_state.has_active_quest("quest.prepare_demo_stabilization_buffer"):
			return "污染浆液先留给核心稳压缓冲包；多余浆液再回基础反应器回收基础零件。"
		return "污染浆液可回基础反应器回收基础零件，也可作为遗迹 / 核心整备输入。"
	if (
		character_state.inventory.has_ref(BASIC_PARTS_ID, 2)
		and character_state.inventory.has_ref(FILTER_MEDIA_ID, 1)
		and not FieldOutfittingRuntime.has_filter_module_equipped(character_state)
	):
		return "基础零件 + 过滤介质可组装基础过滤模块，随后到出发整备台装入防护服。"
	if FieldOutfittingRuntime.has_filter_module_equipped(character_state):
		return "基础过滤模块、抗污染药剂和整备台维护共同支撑下一趟外勤承压。"
	if world_state.has_base_structure_definition(POLLUTION_FILTER_ID):
		return "污染过滤器负责药剂和污染浆液；基础反应器负责基础零件和外勤整备件。"
	return "基础反应器把晶体矿物转基础零件，再接过滤模块、修复凝胶和整备台。"


static func _format_next_sortie_chain(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	var target_vial := DepartureSupplyRuntime.get_resistance_vial_target(world_state)
	var current_vial := DepartureSupplyRuntime.get_resistance_vial_count(character_state)
	if FieldOutfittingRuntime.has_active_logistics_maintenance(character_state, world_state):
		return "后勤维护已确认；药剂 %d/%d，下一趟污染 / 遗迹 / 核心站会读取模块维护收益。" % [
			current_vial,
			target_vial
		]
	if FieldOutfittingRuntime.has_filter_module_equipped(character_state):
		return "基础过滤模块已装入；药剂 %d/%d，下一趟污染采集和污染 / 遗迹反击承压下降。" % [
			current_vial,
			target_vial
		]
	if character_state.inventory.has_ref(FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID, 1):
		return "基础过滤模块已在背包；到出发整备台装入后再从外勤出发口推进。"
	if current_vial > 0:
		return "抗污染药剂 %d/%d 已备；过滤器产出的药剂支撑下一趟污染排压。" % [
			current_vial,
			target_vial
		]
	return "先把材料加工成模块、药剂或修复凝胶，再从外勤出发口推进。"
