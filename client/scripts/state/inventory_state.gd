extends RefCounted
class_name InventoryState

var items: Dictionary = {}
var fluids: Dictionary = {}
var capacity_slots: int = 24


static func create_starting_inventory() -> InventoryState:
	var state := InventoryState.new()
	state.items = {
		"item.basic_parts": 4,
		"item.repair_gel": 1
	}
	state.fluids = {
		"fluid.basic_solvent": 3
	}
	return state


func add_item(definition_id: String, amount: int) -> void:
	items[definition_id] = int(items.get(definition_id, 0)) + amount


func add_fluid(definition_id: String, amount: float) -> void:
	fluids[definition_id] = float(fluids.get(definition_id, 0.0)) + amount


func to_dict() -> Dictionary:
	return {
		"items": items.duplicate(true),
		"fluids": fluids.duplicate(true),
		"capacity_slots": capacity_slots
	}


static func from_dict(data: Dictionary) -> InventoryState:
	var state := InventoryState.new()
	state.items = data.get("items", {}).duplicate(true)
	state.fluids = data.get("fluids", {}).duplicate(true)
	state.capacity_slots = int(data.get("capacity_slots", 24))
	return state
