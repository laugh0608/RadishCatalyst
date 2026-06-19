extends RefCounted
class_name DemoResourceChainStateFormatter

const CRYSTAL_ORE_ID := "item.crystal_ore"
const BASIC_PARTS_ID := "item.basic_parts"
const FILTER_MEDIA_ID := "item.filter_media"
const POLLUTED_RESIDUE_ID := "item.polluted_residue"
const POLLUTED_SLURRY_ID := "fluid.polluted_slurry"
const RESISTANCE_VIAL_ID := "item.resistance_vial_t1"
const REPAIR_GEL_ID := "item.repair_gel"
const CORE_BUFFER_ID := "item.core_stabilization_buffer"
const BASIC_REACTOR_ID := "building.basic_reactor"
const POLLUTION_FILTER_ID := "building.pollution_filter"

const CORE_RESOURCE_IDS: Array[String] = [
	CRYSTAL_ORE_ID,
	BASIC_PARTS_ID,
	FILTER_MEDIA_ID,
	POLLUTED_RESIDUE_ID,
	POLLUTED_SLURRY_ID,
	RESISTANCE_VIAL_ID,
	REPAIR_GEL_ID,
	CORE_BUFFER_ID
]

const CORE_RESOURCE_LABELS := {
	"item.crystal_ore": "晶体矿物",
	"item.basic_parts": "基础零件",
	"item.filter_media": "过滤介质",
	"item.polluted_residue": "污染沉积物",
	"fluid.polluted_slurry": "污染浆液",
	"item.resistance_vial_t1": "抗污染药剂",
	"item.repair_gel": "修复凝胶",
	"item.core_stabilization_buffer": "核心稳压缓冲包"
}


static func get_core_resource_ids() -> Array[String]:
	return CORE_RESOURCE_IDS.duplicate()


static func format_hud_summary(world_state: WorldState, character_state: CharacterState) -> Array[String]:
	if world_state == null or character_state == null:
		return []
	if world_state.current_region_id != "region.outpost_platform":
		return []
	if not _should_show_summary(world_state, character_state):
		return []

	return [
		"资源链状态：%s" % format_chain_state_line(world_state, character_state),
		"资源快照：%s" % format_core_resource_snapshot(character_state.inventory)
	]


static func format_chain_state_line(world_state: WorldState, character_state: CharacterState) -> String:
	if world_state == null or character_state == null:
		return ""
	var inventory := character_state.inventory
	if inventory.has_ref(CORE_BUFFER_ID, 1):
		return "核心整备完成：核心稳压缓冲包已在背包，带回核心稳定站挑战阶段守卫。"
	if _has_core_buffer_inputs(inventory):
		return "核心缓冲包原料齐备：到基础反应器启动核心稳压缓冲包。"
	if inventory.has_ref(POLLUTED_RESIDUE_ID, 2):
		return "污染处理待加工：污染沉积物可进污染过滤器，产出抗污染药剂 + 污染浆液。"
	if inventory.has_ref(POLLUTED_SLURRY_ID, 1):
		if world_state.quest_state.has_active_quest("quest.prepare_demo_stabilization_buffer"):
			return "污染浆液已就绪：优先留给核心稳压缓冲包，多余浆液再回收基础零件。"
		return "副产待分流：污染浆液可回收成基础零件，也可保留给遗迹 / 核心组装。"
	if _has_filter_module_inputs(inventory) and not FieldOutfittingRuntime.has_filter_module_equipped(character_state):
		return "过滤模块原料齐备：基础零件 + 过滤介质可组装基础过滤模块，再到出发整备台装入。"
	if FieldOutfittingRuntime.has_filter_module_equipped(character_state):
		return "外勤整备链已接入：基础过滤模块、药剂和修复凝胶支撑下一趟承压。"
	if inventory.has_ref(CRYSTAL_ORE_ID, 3):
		return "固体加工待启动：晶体矿物可进基础反应器转成基础零件。"
	if _has_any_core_resource(inventory) or _has_resource_chain_quest(world_state):
		return "资源链待补料：采集晶体矿物或污染沉积物后，回基地接入基础反应器 / 污染过滤器。"
	return ""


static func format_core_resource_snapshot(inventory: InventoryState) -> String:
	if inventory == null:
		return "暂无核心链资源"
	var parts: Array[String] = []
	for resource_id in CORE_RESOURCE_IDS:
		var amount := _get_ref_amount(inventory, resource_id)
		if amount <= 0.0:
			continue
		parts.append("%s x%s" % [_get_resource_label(resource_id), _format_amount(amount)])
	if parts.is_empty():
		return "暂无核心链资源"
	return "，".join(parts)


static func format_device_status_line(
	building_id: String,
	recipe_id: String,
	_world_state: WorldState,
	_character_state: CharacterState
) -> String:
	var recipe_line := _format_recipe_chain(recipe_id)
	if not recipe_line.is_empty():
		return "资源链状态：%s" % recipe_line
	match building_id:
		BASIC_REACTOR_ID:
			return "资源链状态：基础反应器承接固体加工、副产回收和核心整备组装。"
		POLLUTION_FILTER_ID:
			return "资源链状态：污染过滤器承接污染处理，产出药剂并留下可分流污染浆液。"
		_:
			return ""


static func format_result_feedback_line(recipe_id: String) -> String:
	match recipe_id:
		"recipe.process_crystal_ore":
			return "固体加工链完成：基础零件已入库，继续过滤模块、修复凝胶或核心稳压缓冲包。"
		"recipe.cleanse_residue":
			return "污染链完成：抗污染药剂进快捷补给，污染浆液进入副产回收或核心稳压缓冲包。"
		"recipe.reclaim_basic_parts":
			return "副产回收完成：污染浆液转基础零件，支撑整备台维护和下一趟补给。"
		"recipe.core_stabilization_buffer":
			return "核心整备链完成：核心稳压缓冲包已可带回核心稳定站。"
		_:
			return ""


static func _format_recipe_chain(recipe_id: String) -> String:
	match recipe_id:
		"recipe.process_crystal_ore":
			return "固体加工链：晶体矿物 -> 基础零件，后续接过滤模块、修复凝胶或核心稳压缓冲包。"
		"recipe.cleanse_residue":
			return "污染处理链：污染沉积物 -> 抗污染药剂 + 污染浆液，药剂进快捷补给，浆液进入副产回收或组装。"
		"recipe.reclaim_basic_parts":
			return "副产回收链：污染浆液 -> 基础零件，避免副产只停在库存数字。"
		"recipe.core_stabilization_buffer":
			return "核心整备链：修复凝胶 + 抗污染药剂 + 污染浆液 + 基础零件 -> 核心稳压缓冲包。"
		"recipe.basic_filter_module":
			return "外勤模块链：基础零件 + 过滤介质 -> 基础过滤模块，再进入出发整备台。"
		"recipe.repair_gel":
			return "外勤补给链：基础零件 + 基础溶剂 -> 修复凝胶，支撑下一段清障战斗。"
		_:
			return ""


static func _should_show_summary(world_state: WorldState, character_state: CharacterState) -> bool:
	var inventory := character_state.inventory
	if (
		inventory.has_ref(CRYSTAL_ORE_ID, 3)
		or inventory.has_ref(POLLUTED_RESIDUE_ID, 2)
		or inventory.has_ref(POLLUTED_SLURRY_ID, 1)
		or inventory.has_ref(CORE_BUFFER_ID, 1)
		or _has_filter_module_inputs(inventory)
		or _has_core_buffer_inputs(inventory)
	):
		return true
	return _has_resource_chain_quest(world_state)


static func _has_resource_chain_quest(world_state: WorldState) -> bool:
	for quest_id in [
		"quest.make_filter_module",
		"quest.enter_pollution_edge",
		"quest.assemble_phase_anchor",
		"quest.prepare_demo_stabilization_buffer"
	]:
		if world_state.quest_state.has_active_quest(quest_id):
			return true
	return false


static func _has_core_buffer_inputs(inventory: InventoryState) -> bool:
	return (
		inventory.has_ref(REPAIR_GEL_ID, 1)
		and inventory.has_ref(RESISTANCE_VIAL_ID, 1)
		and inventory.has_ref(POLLUTED_SLURRY_ID, 1)
		and inventory.has_ref(BASIC_PARTS_ID, 2)
	)


static func _has_filter_module_inputs(inventory: InventoryState) -> bool:
	return inventory.has_ref(BASIC_PARTS_ID, 2) and inventory.has_ref(FILTER_MEDIA_ID, 1)


static func _has_any_core_resource(inventory: InventoryState) -> bool:
	for resource_id in CORE_RESOURCE_IDS:
		if _get_ref_amount(inventory, resource_id) > 0.0:
			return true
	return false


static func _get_ref_amount(inventory: InventoryState, definition_id: String) -> float:
	if definition_id.begins_with("fluid."):
		return float(inventory.fluids.get(definition_id, 0.0))
	if definition_id.begins_with("equipment."):
		return float(inventory.equipment.get(definition_id, 0))
	return float(inventory.items.get(definition_id, 0))


static func _get_resource_label(definition_id: String) -> String:
	return String(CORE_RESOURCE_LABELS.get(definition_id, definition_id))


static func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount
