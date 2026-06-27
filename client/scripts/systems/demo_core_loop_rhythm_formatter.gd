extends RefCounted
class_name DemoCoreLoopRhythmFormatter

const STAGE_OUTPOST_START := "outpost_start"
const STAGE_FIELD_INPUT := "field_input"
const STAGE_BASE_PROCESSING := "base_processing"
const STAGE_OUTFITTING := "outfitting"
const STAGE_POLLUTION_PRESSURE := "pollution_pressure"
const STAGE_CORE_WRITE := "core_write"
const STAGE_COMPLETE := "complete"

const OUTPOST_REGION_ID := "region.outpost_platform"
const CRYSTAL_REGION_ID := "region.crystal_vein_field"
const POLLUTION_REGION_ID := "region.pollution_edge"
const CORE_REGION_ID := "region.demo_stabilization_core"

const CORE_LOOP_RECIPE_IDS: Array[String] = [
	"recipe.process_crystal_ore",
	"recipe.repair_gel",
	"recipe.basic_filter_module",
	"recipe.cleanse_residue",
	"recipe.core_stabilization_buffer"
]


static func format_hud_summary(world_state: WorldState, character_state: CharacterState) -> Array[String]:
	if not _should_show_summary(world_state, character_state):
		return []
	var stage_id := get_stage_id(world_state, character_state)
	return [
		"核心循环：%s；下一步：%s" % [
			format_stage_label(stage_id),
			format_next_step(stage_id, world_state, character_state)
		]
	]


static func get_stage_id(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state == null:
		return ""
	if DemoMainlineCompletionFormatter.is_demo_complete(world_state):
		return STAGE_COMPLETE
	if not world_state.quest_state.has_completed_quest("quest.restore_outpost"):
		return STAGE_OUTPOST_START
	if _has_core_write_context(world_state, character_state):
		return STAGE_CORE_WRITE
	if _has_pollution_to_core_handoff_context(world_state, character_state):
		return STAGE_CORE_WRITE
	if _has_pollution_pressure_context(world_state, character_state):
		return STAGE_POLLUTION_PRESSURE
	if _has_outfitting_quest_context(world_state):
		return STAGE_OUTFITTING
	if _has_base_processing_context(world_state, character_state):
		return STAGE_BASE_PROCESSING
	if _has_field_input_context(world_state, character_state):
		return STAGE_FIELD_INPUT
	if _has_outfitting_context(world_state, character_state):
		return STAGE_OUTFITTING
	return STAGE_FIELD_INPUT


static func format_stage_label(stage_id: String) -> String:
	match stage_id:
		STAGE_OUTPOST_START:
			return "起点前哨恢复"
		STAGE_FIELD_INPUT:
			return "外勤输入"
		STAGE_BASE_PROCESSING:
			return "基地加工"
		STAGE_OUTFITTING:
			return "整备收益"
		STAGE_POLLUTION_PRESSURE:
			return "污染承压"
		STAGE_CORE_WRITE:
			return "核心写入"
		STAGE_COMPLETE:
			return "前哨成果归档"
		_:
			return "等待当前目标"


static func format_next_step(
	stage_id: String,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	match stage_id:
		STAGE_OUTPOST_START:
			return "检查前哨核心，让反应器和晶体路线接入"
		STAGE_FIELD_INPUT:
			return "采集晶体或残骸，带回基地作为反应器输入"
		STAGE_BASE_PROCESSING:
			if _has_active_recipe(world_state, "recipe.process_crystal_ore"):
				return "等待基础反应器把晶体转成基础零件"
			return "把晶体送入基础反应器，转成基础零件"
		STAGE_OUTFITTING:
			if _has_inventory_ref(character_state, "equipment.filter_module_t1", 1):
				return "到出发整备台把过滤模块装入防护服"
			if _has_inventory_ref(character_state, "item.repair_gel", 1):
				return "带修复凝胶和基础零件准备处理点清障"
			return "把基础零件转成修复凝胶、模块或整备台收益"
		STAGE_POLLUTION_PRESSURE:
			if _has_inventory_ref(character_state, "item.polluted_residue", 2):
				return "回污染过滤器处理沉积物，药剂进补给，浆液回基地"
			if _has_inventory_ref(character_state, "item.resistance_vial_t1", 1):
				return "带药剂和过滤模块顶住污染边界短战斗"
			return "用过滤模块、药剂和修复凝胶顶住污染边界"
		STAGE_CORE_WRITE:
			if _has_pollution_to_core_handoff_context(world_state, character_state) and not _has_any_core_quest_context(world_state):
				return "短挑战结果已回收，回基地把药剂、浆液和修复凝胶整成核心稳压准备"
			if world_state != null and world_state.quest_state.has_active_quest("quest.enter_demo_stabilization_core"):
				return "从出发路线进入核心稳定站，确认入口和终点压力"
			if world_state != null and world_state.quest_state.has_active_quest("quest.prepare_demo_stabilization_buffer"):
				return "把药剂、浆液、修复凝胶和零件整成稳压缓冲包"
			if _has_inventory_ref(character_state, "item.core_stabilization_buffer", 1):
				return "带稳压缓冲包回核心稳定站处理守卫"
			if world_state != null and world_state.quest_state.has_active_quest("quest.write_demo_stabilization_core"):
				return "回收校验片并写入核心稳定设备"
			return "带终点补给完成守卫、回写缓存和核心写入"
		STAGE_COMPLETE:
			return "回前哨整理核心写入成果"
		_:
			return "查看当前目标并处理最近的可操作对象"


static func format_result_feedback_line(
	recipe_id: String,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	match recipe_id:
		"recipe.process_crystal_ore":
			return "循环接力：基地加工完成，基础零件转向储存、整备和后续核心整备。"
		"recipe.repair_gel":
			return "循环接力：整备收益已入包，修复凝胶支撑清障和承压。"
		"recipe.basic_filter_module":
			return "循环接力：过滤模块可装入防护服，下一段污染压力更稳。"
		"recipe.cleanse_residue":
			return "循环接力：污染承压收益已入包，药剂进补给，浆液回基地。"
		"recipe.core_stabilization_buffer":
			return "循环接力：核心写入准备就绪，缓冲包带回核心稳定站。"
		_:
			var stage_id := get_stage_id(world_state, character_state)
			if stage_id.is_empty():
				return ""
			return "循环接力：%s；下一步：%s。" % [
				format_stage_label(stage_id),
				format_next_step(stage_id, world_state, character_state)
			]


static func should_show_result_line(recipe_id: String) -> bool:
	return CORE_LOOP_RECIPE_IDS.has(recipe_id)


static func _should_show_summary(world_state: WorldState, character_state: CharacterState) -> bool:
	if world_state == null or character_state == null:
		return false
	if DemoMainlineCompletionFormatter.is_demo_complete(world_state):
		return false
	if _is_treatment_supply_field_cleanup_state(world_state):
		return false
	if not world_state.quest_state.has_completed_quest("quest.restore_outpost"):
		return world_state.current_region_id == OUTPOST_REGION_ID
	if _has_any_active_quest(world_state, [
		"quest.scout_crystal_field",
		"quest.calibrate_reactor",
		"quest.make_filter_module",
		"quest.prepare_treatment_supplies",
		"quest.expand_treatment_point",
		"quest.enter_pollution_edge",
		"quest.enter_demo_stabilization_core",
		"quest.prepare_demo_stabilization_buffer",
		"quest.defeat_demo_stabilization_guard",
		"quest.write_demo_stabilization_core"
	]):
		return true
	return (
		_has_inventory_ref(character_state, "item.crystal_ore", 1)
		or _has_inventory_ref(character_state, "item.polluted_residue", 1)
		or _has_inventory_ref(character_state, "fluid.polluted_slurry", 1)
		or _has_inventory_ref(character_state, "item.core_stabilization_buffer", 1)
		or _has_inventory_ref(character_state, "item.core_write_charge", 1)
		or _has_pollution_to_core_handoff_context(world_state, character_state)
	)


static func _is_treatment_supply_field_cleanup_state(world_state: WorldState) -> bool:
	return (
		world_state.quest_state.has_active_quest("quest.prepare_treatment_supplies")
		and world_state.quest_state.get_objective_progress(
			"quest.prepare_treatment_supplies",
			"craft_item",
			"item.repair_gel"
		) >= 1.0
		and not _has_active_recipe(world_state, "recipe.repair_gel")
	)


static func _has_field_input_context(world_state: WorldState, character_state: CharacterState) -> bool:
	if world_state == null:
		return false
	if world_state.current_region_id == CRYSTAL_REGION_ID:
		return true
	return (
		world_state.quest_state.has_active_quest("quest.scout_crystal_field")
		and not _has_inventory_ref(character_state, "item.crystal_ore", 3)
	)


static func _has_base_processing_context(world_state: WorldState, character_state: CharacterState) -> bool:
	if world_state == null:
		return false
	return (
		_has_active_recipe(world_state, "recipe.process_crystal_ore")
		or _has_active_recipe(world_state, "recipe.reactor_calibrator")
		or _has_inventory_ref(character_state, "item.crystal_ore", 3)
		or world_state.quest_state.has_active_quest("quest.calibrate_reactor")
	)


static func _has_outfitting_context(world_state: WorldState, character_state: CharacterState) -> bool:
	if world_state == null:
		return false
	if _has_outfitting_quest_context(world_state):
		return true
	return (
		_has_active_recipe(world_state, "recipe.repair_gel")
		or _has_active_recipe(world_state, "recipe.basic_filter_module")
		or _has_inventory_ref(character_state, "item.repair_gel", 1)
		or _has_inventory_ref(character_state, "equipment.filter_module_t1", 1)
		or FieldOutfittingRuntime.has_station_built(world_state)
	)


static func _has_outfitting_quest_context(world_state: WorldState) -> bool:
	return _has_any_active_quest(world_state, [
		"quest.make_filter_module",
		"quest.prepare_treatment_supplies",
		"quest.expand_treatment_point"
	])


static func _has_pollution_pressure_context(world_state: WorldState, character_state: CharacterState) -> bool:
	if world_state == null:
		return false
	if world_state.current_region_id == POLLUTION_REGION_ID:
		return true
	if world_state.quest_state.has_active_quest("quest.enter_pollution_edge"):
		return true
	return (
		_has_active_recipe(world_state, "recipe.cleanse_residue")
		or _has_inventory_ref(character_state, "item.polluted_residue", 1)
		or _has_inventory_ref(character_state, "item.resistance_vial_t1", 1)
		or _has_inventory_ref(character_state, "fluid.polluted_slurry", 1)
	)


static func _has_core_write_context(world_state: WorldState, character_state: CharacterState) -> bool:
	if world_state == null:
		return false
	if world_state.current_region_id == CORE_REGION_ID:
		return true
	if _has_any_active_quest(world_state, [
		"quest.enter_demo_stabilization_core",
		"quest.prepare_demo_stabilization_buffer",
		"quest.defeat_demo_stabilization_guard",
		"quest.write_demo_stabilization_core"
	]):
		return true
	return (
		_has_active_recipe(world_state, "recipe.core_stabilization_buffer")
		or _has_inventory_ref(character_state, "item.core_stabilization_buffer", 1)
		or _has_inventory_ref(character_state, "item.core_write_charge", 1)
	)


static func _has_pollution_to_core_handoff_context(world_state: WorldState, character_state: CharacterState) -> bool:
	if world_state == null or character_state == null:
		return false
	if world_state.quest_state.has_completed_quest("quest.enter_demo_stabilization_core"):
		return false
	if world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core"):
		return false
	if not world_state.quest_state.has_completed_quest("quest.enter_pollution_edge"):
		return false
	if not (
		_has_inventory_ref(character_state, "fluid.polluted_slurry", 1)
		or _has_inventory_ref(character_state, "item.resistance_vial_t1", 1)
		or _has_inventory_ref(character_state, "item.polluted_residue", 1)
	):
		return false
	if world_state.current_region_id == POLLUTION_REGION_ID or character_state.current_region_id == POLLUTION_REGION_ID:
		return true
	return (
		world_state.unlocked_region_ids.has(CORE_REGION_ID)
		or world_state.quest_state.unlocked_effects.has("recipe.core_stabilization_buffer")
		or _has_active_recipe(world_state, "recipe.core_stabilization_buffer")
		or _has_inventory_ref(character_state, "item.core_stabilization_buffer", 1)
		or _has_inventory_ref(character_state, "item.core_write_charge", 1)
	)


static func _has_any_core_quest_context(world_state: WorldState) -> bool:
	return _has_any_active_quest(world_state, [
		"quest.enter_demo_stabilization_core",
		"quest.prepare_demo_stabilization_buffer",
		"quest.defeat_demo_stabilization_guard",
		"quest.write_demo_stabilization_core"
	])


static func _has_any_active_quest(world_state: WorldState, quest_ids: Array) -> bool:
	for quest_id in quest_ids:
		if world_state.quest_state.has_active_quest(String(quest_id)):
			return true
	return false


static func _has_active_recipe(world_state: WorldState, recipe_id: String) -> bool:
	if world_state == null:
		return false
	for structure in world_state.base_structures.values():
		if not structure is Dictionary:
			continue
		if String(structure.get("status", "")) != "in_progress":
			continue
		if String(structure.get("active_recipe_id", "")) == recipe_id:
			return true
	return false


static func _has_inventory_ref(character_state: CharacterState, definition_id: String, amount: float) -> bool:
	return character_state != null and character_state.inventory.has_ref(definition_id, amount)
