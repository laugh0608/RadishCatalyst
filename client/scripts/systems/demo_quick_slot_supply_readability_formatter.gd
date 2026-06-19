extends RefCounted
class_name DemoQuickSlotSupplyReadabilityFormatter

const REPAIR_GEL_ID := "item.repair_gel"
const RESISTANCE_VIAL_ID := "item.resistance_vial_t1"
const LOW_VITAL_RATIO := 0.75


static func format_quick_slot_summary(
	data_registry: DataRegistry,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	var parts: Array[String] = []
	for slot_index in range(character_state.quick_slots.size()):
		parts.append(_format_slot(data_registry, world_state, character_state, slot_index))
	if parts.is_empty():
		return "无"
	return "；".join(parts)


static func _format_slot(
	data_registry: DataRegistry,
	world_state: WorldState,
	character_state: CharacterState,
	slot_index: int
) -> String:
	var item_id := character_state.quick_slots[slot_index]
	if item_id.is_empty():
		return "%d 空" % (slot_index + 1)
	var count := int(character_state.inventory.items.get(item_id, 0))
	return "%d %sx%d/%s" % [
		slot_index + 1,
		_get_display_name(data_registry, item_id),
		count,
		_format_item_state(item_id, count, world_state, character_state)
	]


static func _format_item_state(
	item_id: String,
	count: int,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	match item_id:
		REPAIR_GEL_ID:
			return _format_repair_gel_state(count, character_state)
		RESISTANCE_VIAL_ID:
			return _format_resistance_vial_state(count, world_state, character_state)
		_:
			if count <= 0:
				return "缺"
			return "可用"


static func _format_repair_gel_state(count: int, character_state: CharacterState) -> String:
	if count <= 0:
		return "缺:反应器"
	var health_ratio := _safe_ratio(character_state.health, character_state.max_health)
	if health_ratio >= 1.0:
		return "满"
	if health_ratio <= LOW_VITAL_RATIO:
		return "生命低可用"
	return "可用"


static func _format_resistance_vial_state(
	count: int,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if count <= 0:
		return "缺:过滤器"
	var protection_ratio := _safe_ratio(character_state.protection, character_state.max_protection)
	if protection_ratio >= 1.0:
		return "满"
	if protection_ratio <= LOW_VITAL_RATIO:
		return "防护低可用"
	if _is_pollution_pressure_region(world_state):
		return "污染可用"
	return "进污染前可用"


static func _is_pollution_pressure_region(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return String(world_state.current_region_id) in [
		"region.pollution_edge",
		"region.demo_stabilization_core"
	]


static func _safe_ratio(value: float, maximum: float) -> float:
	if maximum <= 0.0:
		return 1.0
	return value / maximum


static func _get_display_name(data_registry: DataRegistry, definition_id: String) -> String:
	if definition_id.is_empty():
		return ""
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id
	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))
