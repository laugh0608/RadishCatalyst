extends "res://scripts/factory/discovery_model.gd"

const Logistics := preload("res://scripts/factory/logistics.gd")
var ordered_entities: Array[Dictionary] = []
var order_revision := -1


func _init() -> void:
	super(true)
	automatic_power = true
	supply_id = DiscoveryRules.ROUTING_SUPPLY_ID
	kits = DiscoveryRules.routing_supply()


func placement_replacement(type: String, cell: Vector2i) -> Dictionary:
	if type not in ["splitter", "merger", "admission_gate"] or not kits.has(type):
		return {}
	var target := entity_at(cell)
	return target if target.get("type", "") == "belt" else {}


func placement(type: String, cell: Vector2i, player: Variant = null) -> Dictionary:
	var valid := super.placement(type, cell, player)
	if not valid.ok:
		return valid
	var belt := placement_replacement(type, cell)
	if not belt.is_empty() and Items.count(bag) + Items.count(Items.contents(belt)) > 200:
		return failure("背包放不下带上物料，不能替换；原带保持不变")
	return valid


func _place_entity(type: String, cell: Vector2i, dir: int) -> Dictionary:
	var belt := placement_replacement(type, cell)
	var recovered := {}
	if not belt.is_empty():
		recovered = Items.contents(belt)
		Items.merge(bag, recovered)
		kits.belt += 1
		entities.erase(belt)
		instances.erase(belt.id)
		input_sides.erase(belt.id)
		occupancy.erase(cell)
	var result := super._place_entity(type, cell, dir)
	if not belt.is_empty():
		result.merge({"replaced_belt": belt.id, "recovered_items": recovered})
	return result


func place(type: String, cell: Vector2i, dir := -1, player: Variant = null) -> Dictionary:
	dir = placement_direction(type, cell, dir)
	var result := super.place(type, cell, dir, player)
	if result.ok and type in ["splitter", "merger"]:
		var e: Dictionary = result.entity
		e.dir = dir
		e.merge({"cargo": "", "progress": 0.0, "entry": -DIRS[dir], "batch": 0})
		e["output_cursor" if type == "splitter" else "input_cursor"] = 0
		_refresh_neighbors(e)
	return result


func rotate(id: int) -> Dictionary:
	var e := by_id(id)
	if e.get("type", "") not in ["splitter", "merger"]:
		return super.rotate(id)
	if not e.cargo.is_empty():
		return failure("附件中有货物；请等待排空或回收后重新放置")
	e.dir = (e.dir + 1) % 4
	e.entry = -DIRS[e.dir]
	e["output_cursor" if e.type == "splitter" else "input_cursor"] = 0
	_refresh_neighbors(e)
	revision += 1
	return success()


func _logistics(dt: float) -> void:
	Logistics.step(self, dt)


func _find_belt_inputs(b: Dictionary) -> Array[int]:
	var inputs: Array[int] = []
	for p in Logistics.ports(self, b, "input"):
		var source := entity_at(Vector2i(p.x + p.dx, p.z + p.dz))
		if source.is_empty():
			continue
		for output in Logistics.ports(self, source, "output"):
			if not Logistics.receiving_port(self, b, output).is_empty():
				inputs.append(DIRS.find(Vector2i(p.dx, p.dz)))
	return inputs


func feedback(e: Dictionary) -> Dictionary:
	return Logistics.feedback(self, e) if Logistics.transport(e) else super.feedback(e)


func belt_blocked(e: Dictionary) -> bool:
	return Logistics.feedback(self, e).kind == "blocked"


func _production_entities() -> Array[Dictionary]:
	if order_revision != revision:
		ordered_entities = entities.duplicate()
		ordered_entities.sort_custom(func(a, b): return a.id < b.id)
		order_revision = revision
	return ordered_entities
