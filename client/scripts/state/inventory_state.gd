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


func has_ref(definition_id: String, amount: float) -> bool:
	if definition_id.begins_with("fluid."):
		return float(fluids.get(definition_id, 0.0)) >= amount
	return int(items.get(definition_id, 0)) >= int(amount)


func consume_ref(definition_id: String, amount: float) -> void:
	if definition_id.begins_with("fluid."):
		fluids[definition_id] = maxf(0.0, float(fluids.get(definition_id, 0.0)) - amount)
		return

	items[definition_id] = maxi(0, int(items.get(definition_id, 0)) - int(amount))


func add_ref(definition_id: String, amount: float) -> void:
	if definition_id.begins_with("fluid."):
		add_fluid(definition_id, amount)
		return

	add_item(definition_id, int(amount))


func to_dict() -> Dictionary:
	return {
		"items": items.duplicate(true),
		"fluids": fluids.duplicate(true),
		"capacity_slots": capacity_slots
	}


static func from_dict(data: Dictionary) -> InventoryState:
	var state := InventoryState.new()
	var items_data = data.get("items", {})
	if items_data is Dictionary:
		state.items = items_data.duplicate(true)
	var fluids_data = data.get("fluids", {})
	if fluids_data is Dictionary:
		state.fluids = fluids_data.duplicate(true)
	state.capacity_slots = int(data.get("capacity_slots", 24))
	return state
