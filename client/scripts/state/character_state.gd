extends RefCounted
class_name CharacterState

var stable_id: String = "character.player"
var display_name: String = "前哨工程战斗员"
var health: float = 100.0
var max_health: float = 100.0
var protection: float = 100.0
var max_protection: float = 100.0
var current_region_id: String = "region.outpost_platform"
var equipment: Dictionary = {
	"tool": "equipment.basic_tool",
	"suit": "equipment.basic_suit",
	"suit_module": ""
}
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


func to_dict() -> Dictionary:
	return {
		"stable_id": stable_id,
		"display_name": display_name,
		"health": health,
		"max_health": max_health,
		"protection": protection,
		"max_protection": max_protection,
		"current_region_id": current_region_id,
		"equipment": equipment.duplicate(true),
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
	state.equipment = data.get("equipment", state.equipment).duplicate(true)
	state.inventory = InventoryState.from_dict(data.get("inventory", {}))
	return state
