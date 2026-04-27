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
