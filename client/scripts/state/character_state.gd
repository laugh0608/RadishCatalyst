extends RefCounted
class_name CharacterState

const REPAIR_GEL_HEAL_AMOUNT := 35.0
const RESISTANCE_VIAL_PROTECTION_AMOUNT := 30.0

var stable_id: String = "character.player"
var display_name: String = "前哨工程战斗员"
var health: float = 100.0
var max_health: float = 100.0
var protection: float = 100.0
var max_protection: float = 100.0
var current_region_id: String = "region.outpost_platform"
var position: Vector2 = Vector2(-250, -48)
var equipment: Dictionary = {
	"tool": "equipment.basic_tool",
	"suit": "equipment.basic_suit",
	"suit_module": ""
}
var quick_slots: Array[String] = ["item.repair_gel", "item.resistance_vial_t1"]
var inventory: InventoryState = InventoryState.create_starting_inventory()


static func create_default() -> CharacterState:
	return CharacterState.new()


func equip_suit_module(module_id: String) -> bool:
	if module_id.is_empty() or not inventory.has_ref(module_id, 1):
		return false

	equipment["suit_module"] = module_id
	return true


func get_pollution_drain_multiplier(data_registry: DataRegistry) -> float:
	var multiplier := 1.0
	for equipment_id in [equipment.get("suit", ""), equipment.get("suit_module", "")]:
		var definition := data_registry.get_definition(String(equipment_id))
		if definition.is_empty():
			continue

		var stat_modifiers: Dictionary = definition.get("stat_modifiers", {})
		multiplier *= float(stat_modifiers.get("pollution_drain_mult", 1.0))
	return multiplier


func apply_health_damage(amount: float) -> float:
	var actual_amount := maxf(0.0, amount)
	health = maxf(0.0, health - actual_amount)
	return actual_amount


func apply_protection_damage(amount: float) -> float:
	var actual_amount := maxf(0.0, amount)
	protection = maxf(0.0, protection - actual_amount)
	return actual_amount


func use_quick_slot(slot_index: int, data_registry: DataRegistry) -> Dictionary:
	if slot_index < 0 or slot_index >= quick_slots.size():
		return _failure("该快捷栏槽位不存在。")

	var item_id := quick_slots[slot_index]
	if item_id.is_empty():
		return _failure("快捷栏 %d 未绑定物品。" % (slot_index + 1))
	if not inventory.has_ref(item_id, 1):
		return _failure("没有%s。" % _get_display_name(item_id, data_registry))

	match item_id:
		"item.repair_gel":
			return _use_repair_gel(item_id, data_registry)
		"item.resistance_vial_t1":
			return _use_resistance_vial(item_id, data_registry)
		_:
			return _failure("%s 暂未接入使用效果。" % _get_display_name(item_id, data_registry))


func bind_quick_slot(slot_index: int, item_id: String, data_registry: DataRegistry) -> Dictionary:
	if slot_index < 0 or slot_index >= quick_slots.size():
		return _failure("该快捷栏槽位不存在。")
	if item_id.is_empty():
		quick_slots[slot_index] = ""
		return _success("快捷栏 %d 已清空。" % (slot_index + 1))

	if not _is_supported_quick_slot_item(item_id):
		return _failure("%s 暂不能绑定到快捷栏。" % _get_display_name(item_id, data_registry))
	if data_registry.get_definition(item_id).is_empty():
		return _failure("未知快捷栏物品：%s。" % item_id)

	quick_slots[slot_index] = item_id
	return _success("快捷栏 %d 已绑定：%s。" % [
		slot_index + 1,
		_get_display_name(item_id, data_registry)
	])


func _use_repair_gel(item_id: String, data_registry: DataRegistry) -> Dictionary:
	if health >= max_health:
		return _failure("生命已满。")

	var before := health
	inventory.consume_ref(item_id, 1)
	health = minf(max_health, health + REPAIR_GEL_HEAL_AMOUNT)
	return _success("使用%s，生命 +%s。" % [
		_get_display_name(item_id, data_registry),
		_format_amount(health - before)
	])


func _use_resistance_vial(item_id: String, data_registry: DataRegistry) -> Dictionary:
	if protection >= max_protection:
		return _failure("防护已满。")

	var before := protection
	inventory.consume_ref(item_id, 1)
	protection = minf(max_protection, protection + RESISTANCE_VIAL_PROTECTION_AMOUNT)
	return _success("使用%s，防护 +%s。" % [
		_get_display_name(item_id, data_registry),
		_format_amount(protection - before)
	])


func _is_supported_quick_slot_item(item_id: String) -> bool:
	return item_id == "item.repair_gel" or item_id == "item.resistance_vial_t1"


func to_dict() -> Dictionary:
	return {
		"stable_id": stable_id,
		"display_name": display_name,
		"health": health,
		"max_health": max_health,
		"protection": protection,
		"max_protection": max_protection,
		"current_region_id": current_region_id,
		"position": {"x": position.x, "y": position.y},
		"equipment": equipment.duplicate(true),
		"quick_slots": quick_slots.duplicate(true),
		"inventory": inventory.to_dict()
	}


static func from_dict(data: Dictionary) -> CharacterState:
	var state := CharacterState.new()
	state.stable_id = String(data.get("stable_id", "character.player"))
	state.display_name = String(data.get("display_name", "前哨工程战斗员"))
	state.health = float(data.get("health", 100.0))
	state.max_health = float(data.get("max_health", 100.0))
	state.protection = float(data.get("protection", 100.0))
	state.max_protection = float(data.get("max_protection", 100.0))
	state.current_region_id = String(data.get("current_region_id", "region.outpost_platform"))
	var position_data = data.get("position", {"x": -250.0, "y": -48.0})
	if position_data is Dictionary:
		state.position = Vector2(
			float(position_data.get("x", -250.0)),
			float(position_data.get("y", -48.0))
		)
	var equipment_data = data.get("equipment", state.equipment)
	if equipment_data is Dictionary:
		state.equipment = equipment_data.duplicate(true)
	var quick_slots_data = data.get("quick_slots", state.quick_slots)
	if quick_slots_data is Array:
		state.quick_slots.assign(quick_slots_data)
	var inventory_data = data.get("inventory", null)
	if inventory_data is Dictionary:
		state.inventory = InventoryState.from_dict(inventory_data)
	return state


func _get_display_name(definition_id: String, data_registry: DataRegistry) -> String:
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id
	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))


func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount


func _success(message: String) -> Dictionary:
	return {
		"success": true,
		"message": message
	}


func _failure(message: String) -> Dictionary:
	return {
		"success": false,
		"message": message
	}
