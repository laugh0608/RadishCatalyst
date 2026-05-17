extends RefCounted
class_name InventoryState

var items: Dictionary = {}
var equipment: Dictionary = {}
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
	if definition_id.begins_with("equipment."):
		add_equipment(definition_id, amount)
		return
	items[definition_id] = int(items.get(definition_id, 0)) + amount


func add_equipment(definition_id: String, amount: int) -> void:
	equipment[definition_id] = int(equipment.get(definition_id, 0)) + amount


func add_fluid(definition_id: String, amount: float) -> void:
	fluids[definition_id] = float(fluids.get(definition_id, 0.0)) + amount


func has_ref(definition_id: String, amount: float) -> bool:
	if definition_id.begins_with("fluid."):
		return float(fluids.get(definition_id, 0.0)) >= amount
	if definition_id.begins_with("equipment."):
		_migrate_legacy_equipment_refs()
		return int(equipment.get(definition_id, 0)) >= int(amount)
	return int(items.get(definition_id, 0)) >= int(amount)


func consume_ref(definition_id: String, amount: float) -> void:
	if definition_id.begins_with("fluid."):
		fluids[definition_id] = maxf(0.0, float(fluids.get(definition_id, 0.0)) - amount)
		return
	if definition_id.begins_with("equipment."):
		_migrate_legacy_equipment_refs()
		equipment[definition_id] = maxi(0, int(equipment.get(definition_id, 0)) - int(amount))
		if int(equipment.get(definition_id, 0)) <= 0:
			equipment.erase(definition_id)
		return

	items[definition_id] = maxi(0, int(items.get(definition_id, 0)) - int(amount))
	if int(items.get(definition_id, 0)) <= 0:
		items.erase(definition_id)


func add_ref(definition_id: String, amount: float) -> void:
	if definition_id.begins_with("fluid."):
		add_fluid(definition_id, amount)
		return
	if definition_id.begins_with("equipment."):
		add_equipment(definition_id, int(amount))
		return

	add_item(definition_id, int(amount))


func to_dict() -> Dictionary:
	_migrate_legacy_equipment_refs()
	return {
		"items": items.duplicate(true),
		"equipment": equipment.duplicate(true),
		"fluids": fluids.duplicate(true),
		"capacity_slots": capacity_slots
	}


static func from_dict(data: Dictionary) -> InventoryState:
	var state := InventoryState.new()
	var items_data = data.get("items", {})
	if items_data is Dictionary:
		state.items = items_data.duplicate(true)
	var equipment_data = data.get("equipment", {})
	if equipment_data is Dictionary:
		state.equipment = equipment_data.duplicate(true)
	var fluids_data = data.get("fluids", {})
	if fluids_data is Dictionary:
		state.fluids = fluids_data.duplicate(true)
	state.capacity_slots = int(data.get("capacity_slots", 24))
	state._migrate_legacy_equipment_refs()
	return state


func _migrate_legacy_equipment_refs() -> void:
	var legacy_ids: Array[String] = []
	for item_id in items.keys():
		var definition_id := String(item_id)
		if not definition_id.begins_with("equipment."):
			continue
		add_equipment(definition_id, int(items.get(definition_id, 0)))
		legacy_ids.append(definition_id)

	for definition_id in legacy_ids:
		items.erase(definition_id)
