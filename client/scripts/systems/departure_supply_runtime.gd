extends RefCounted
class_name DepartureSupplyRuntime

const BASIC_STORAGE_ID := "building.basic_storage"
const POLLUTION_FILTER_ID := "building.pollution_filter"
const SLURRY_BUFFER_TANK_ID := "building.slurry_buffer_tank"
const REPAIR_GEL_ID := "item.repair_gel"
const RESISTANCE_VIAL_ID := "item.resistance_vial_t1"
const BASIC_STORAGE_REPAIR_GEL_TARGET := 1
const BASIC_RESISTANCE_VIAL_TARGET := 1
const SLURRY_BUFFER_RESISTANCE_VIAL_TARGET := 2


static func get_resistance_vial_target(world_state: WorldState) -> int:
	if world_state != null and world_state.has_base_structure_definition(SLURRY_BUFFER_TANK_ID):
		return SLURRY_BUFFER_RESISTANCE_VIAL_TARGET
	return BASIC_RESISTANCE_VIAL_TARGET


static func get_resistance_vial_count(character_state: CharacterState) -> int:
	if character_state == null:
		return 0
	return int(character_state.inventory.items.get(RESISTANCE_VIAL_ID, 0))


static func get_missing_resistance_vial_count(
	world_state: WorldState,
	character_state: CharacterState
) -> int:
	return maxi(0, get_resistance_vial_target(world_state) - get_resistance_vial_count(character_state))


static func is_resistance_vial_supply_available(world_state: WorldState) -> bool:
	return (
		world_state != null
		and world_state.has_base_structure_definition(POLLUTION_FILTER_ID)
		and (
			world_state.quest_state.has_completed_quest("quest.enter_pollution_edge")
			or world_state.quest_state.get_objective_progress(
				"quest.enter_pollution_edge",
				"craft_item",
				RESISTANCE_VIAL_ID
			) >= 1.0
		)
	)


static func can_outpost_restock_resistance_vial(
	world_state: WorldState,
	character_state: CharacterState = null
) -> bool:
	if world_state == null or not world_state.has_base_structure_definition(BASIC_STORAGE_ID):
		return false
	if not is_resistance_vial_supply_available(world_state):
		return false
	if character_state == null:
		return true
	return get_resistance_vial_count(character_state) < get_resistance_vial_target(world_state)


static func consume_resistance_vial(
	character_state: CharacterState,
	world_state: WorldState
) -> Dictionary:
	var target := get_resistance_vial_target(world_state)
	var before := get_resistance_vial_count(character_state)
	var spend := {
		"consumed": false,
		"before": before,
		"after": before,
		"target": target,
		"can_outpost_restock": can_outpost_restock_resistance_vial(world_state)
	}
	if character_state == null or before <= 0:
		return spend
	character_state.inventory.consume_ref(RESISTANCE_VIAL_ID, 1)
	spend["consumed"] = true
	spend["after"] = get_resistance_vial_count(character_state)
	spend["can_outpost_restock"] = can_outpost_restock_resistance_vial(world_state, character_state)
	return spend


static func format_resistance_vial_count(world_state: WorldState, character_state: CharacterState) -> String:
	var target := get_resistance_vial_target(world_state)
	var current := get_resistance_vial_count(character_state)
	return "%d/%d" % [current, target]


static func format_ready_resistance_vial_name(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	var current := get_resistance_vial_count(character_state)
	var target := get_resistance_vial_target(world_state)
	if current <= 0:
		return ""
	if target > BASIC_RESISTANCE_VIAL_TARGET:
		if current >= target:
			return "抗污染药剂 x%d" % current
		return "抗污染药剂 %d/%d" % [current, target]
	return "抗污染药剂"


static func format_restock_resistance_vial_name(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	var target := get_resistance_vial_target(world_state)
	var current := get_resistance_vial_count(character_state)
	if target > BASIC_RESISTANCE_VIAL_TARGET:
		if current > 0:
			return "抗污染药剂到 %d（当前 %d/%d）" % [target, current, target]
		return "抗污染药剂到 %d" % target
	return "抗污染药剂"


static func format_resistance_vial_restock_hint(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	var target := get_resistance_vial_target(world_state)
	var current := get_resistance_vial_count(character_state)
	if current >= target:
		return ""
	if can_outpost_restock_resistance_vial(world_state, character_state):
		if target > BASIC_RESISTANCE_VIAL_TARGET:
			return "回前哨核心可补回 %d/%d" % [target, target]
		return "回前哨核心可补抗污染药剂"
	if is_resistance_vial_supply_available(world_state):
		return "回过滤器处理污染沉积物可补抗污染药剂"
	return "先跑通污染过滤器的首支抗污染药剂"


static func format_resistance_vial_pressure_spend(
	vial_spend: Dictionary,
	pressure_label: String
) -> String:
	if not bool(vial_spend.get("consumed", false)):
		return "没有抗污染药剂参与%s排压" % pressure_label

	var before := int(vial_spend.get("before", 0))
	var after := int(vial_spend.get("after", 0))
	var target := int(vial_spend.get("target", BASIC_RESISTANCE_VIAL_TARGET))
	var spend_prefix := "抗污染药剂"
	if target > BASIC_RESISTANCE_VIAL_TARGET:
		var spend_index := mini(maxi(target - after, 1), target)
		spend_prefix = "第 %d 份抗污染药剂" % spend_index

	var text := "%s已自动接入%s排压，药剂 %d/%d -> %d/%d" % [
		spend_prefix,
		pressure_label,
		before,
		target,
		after,
		target
	]
	if bool(vial_spend.get("can_outpost_restock", false)) and after < target:
		text = "%s；回前哨核心可补回 %d/%d" % [text, target, target]
	return text


static func format_resistance_vial_shortage_for_pressure(
	world_state: WorldState,
	character_state: CharacterState,
	pressure_label: String
) -> String:
	var target := get_resistance_vial_target(world_state)
	var current := get_resistance_vial_count(character_state)
	var restock_hint := format_resistance_vial_restock_hint(world_state, character_state)
	if restock_hint.is_empty():
		if target > BASIC_RESISTANCE_VIAL_TARGET:
			return "抗污染药剂未重复参与%s排压，当前药剂 %d/%d" % [
				pressure_label,
				current,
				target
			]
		return "抗污染药剂未重复参与%s排压" % pressure_label
	if target > BASIC_RESISTANCE_VIAL_TARGET:
		return "没有抗污染药剂参与%s排压，当前药剂 %d/%d；%s" % [
			pressure_label,
			current,
			target,
			restock_hint
		]
	return "没有抗污染药剂参与%s排压；%s" % [
		pressure_label,
		restock_hint
	]
