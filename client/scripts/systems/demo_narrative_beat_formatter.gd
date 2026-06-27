extends RefCounted
class_name DemoNarrativeBeatFormatter

const OUTPOST_REGION_ID := "region.outpost_platform"
const CRYSTAL_REGION_ID := "region.crystal_vein_field"
const POLLUTION_REGION_ID := "region.pollution_edge"
const CORE_REGION_ID := "region.demo_stabilization_core"

const FIELD_INPUT_QUEST_IDS: Array[String] = [
	"quest.scout_crystal_field"
]
const BASE_RECOVERY_QUEST_IDS: Array[String] = [
	"quest.calibrate_reactor"
]
const ANOMALY_QUEST_IDS: Array[String] = [
	"quest.bring_back_sample",
	"quest.analyze_anomaly_sample",
	"quest.make_filter_module"
]
const TREATMENT_QUEST_IDS: Array[String] = [
	"quest.prepare_treatment_supplies",
	"quest.expand_treatment_point"
]
const POLLUTION_QUEST_IDS: Array[String] = [
	"quest.enter_pollution_edge",
	"quest.defeat_elite_node",
	"quest.unlock_ruin_signal"
]
const CORE_QUEST_IDS: Array[String] = [
	"quest.enter_demo_stabilization_core",
	"quest.prepare_demo_stabilization_buffer",
	"quest.defeat_demo_stabilization_guard",
	"quest.write_demo_stabilization_core"
]


static func format_hud_summary(world_state: WorldState, character_state: CharacterState) -> Array[String]:
	var beat := format_current_beat(world_state, character_state)
	if beat.is_empty():
		return []
	return ["现场记录：%s" % beat]


static func format_current_beat(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state == null:
		return ""
	if DemoMainlineCompletionFormatter.is_demo_complete(world_state):
		return format_completion_hook_line()
	if not world_state.quest_state.has_completed_quest("quest.restore_outpost"):
		if not world_state.quest_state.has_active_quest("quest.restore_outpost"):
			return ""
		return "前哨核心低功率，反应器和储运线待重启"
	if _has_core_context(world_state, character_state):
		return "核心稳定站是旧稳定工程节点；写入会让前哨接回稳定窗口"
	if _has_pollution_to_core_handoff_context(world_state, character_state):
		return "污染短战斗留下沉积、药剂和浆液；基地整备会把结果送进核心稳定站"
	if _has_pollution_context(world_state, character_state):
		return "污染沉积和受扰生态确认事故正在外部扩散"
	if _has_any_active_quest(world_state, TREATMENT_QUEST_IDS):
		return "处理点把清障、地基和过滤器接回基地恢复线"
	if _has_any_active_quest(world_state, ANOMALY_QUEST_IDS):
		return "异常样本给出过滤参数；污染边界不只是路障"
	if _has_base_recovery_context(world_state, character_state):
		return "第一批晶体和废件正在恢复基础反应器"
	if _has_field_input_context(world_state, character_state):
		return "晶体矿脉是基础工艺输入；带回基地才能使用"
	return ""


static func format_completion_hook_line() -> String:
	return "前哨打开一个稳定窗口；异常源头仍未解释"


static func _has_field_input_context(world_state: WorldState, character_state: CharacterState) -> bool:
	return (
		world_state.current_region_id == CRYSTAL_REGION_ID
		or _has_any_active_quest(world_state, FIELD_INPUT_QUEST_IDS)
		or _has_inventory_ref(character_state, "item.crystal_ore", 1)
	)


static func _has_base_recovery_context(world_state: WorldState, character_state: CharacterState) -> bool:
	return (
		_has_any_active_quest(world_state, BASE_RECOVERY_QUEST_IDS)
		or _has_active_recipe(world_state, "recipe.process_crystal_ore")
		or _has_active_recipe(world_state, "recipe.reactor_calibrator")
		or _has_inventory_ref(character_state, "item.salvage_scrap", 1)
		or _has_inventory_ref(character_state, "item.reactor_calibrator", 1)
	)


static func _has_pollution_context(world_state: WorldState, character_state: CharacterState) -> bool:
	return (
		world_state.current_region_id == POLLUTION_REGION_ID
		or _has_any_active_quest(world_state, POLLUTION_QUEST_IDS)
		or _has_active_recipe(world_state, "recipe.cleanse_residue")
		or _has_inventory_ref(character_state, "item.polluted_residue", 1)
		or _has_inventory_ref(character_state, "item.resistance_vial_t1", 1)
	)


static func _has_core_context(world_state: WorldState, character_state: CharacterState) -> bool:
	return (
		world_state.current_region_id == CORE_REGION_ID
		or _has_any_active_quest(world_state, CORE_QUEST_IDS)
		or _has_active_recipe(world_state, "recipe.core_stabilization_buffer")
		or _has_inventory_ref(character_state, "item.core_stabilization_buffer", 1)
		or _has_inventory_ref(character_state, "item.core_write_charge", 1)
	)


static func _has_pollution_to_core_handoff_context(world_state: WorldState, character_state: CharacterState) -> bool:
	if not world_state.quest_state.has_completed_quest("quest.enter_pollution_edge"):
		return false
	if world_state.quest_state.has_completed_quest("quest.enter_demo_stabilization_core"):
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


static func _has_any_active_quest(world_state: WorldState, quest_ids: Array[String]) -> bool:
	for quest_id in quest_ids:
		if world_state.quest_state.has_active_quest(quest_id):
			return true
	return false


static func _has_active_recipe(world_state: WorldState, recipe_id: String) -> bool:
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
