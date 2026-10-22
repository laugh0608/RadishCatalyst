extends "res://scripts/factory/admission_model.gd"

const Expansion := preload("res://data/factory/expansion_rules.gd")
const MAX_COUNTER := 9007199254740991
var extracted_by_item := {"crystal": 0, "rich_crystal": 0, "iron_ore": 0, "carbon_ore": 0}
var completed_by_recipe := {}
var assembly_counts := {}
var batch_recipes := {}
var first_expansion_placed := false


func _init() -> void:
	super()
	supply_id = Expansion.SUPPLY_ID
	map_id = Expansion.MAP_ID
	kits = Expansion.SUPPLY.duplicate()
	recipes.merge(Expansion.RECIPES)
	item_ids.append_array(Expansion.NAMES.keys())
	process_types.append_array(Expansion.PROCESSORS)
	input_batches = 2
	admission_items = item_ids.filter(func(item): return item != "crust_sample")
	for recipe_id in recipes:
		completed_by_recipe[recipe_id] = 0
	for type in Expansion.ASSEMBLY_COST:
		assembly_counts[type] = 0


func place(type: String, cell: Vector2i, dir := -1, player: Variant = null) -> Dictionary:
	var result := super.place(type, cell, dir, player)
	if not result.ok: return result
	if type in Expansion.PROCESSORS:
		result.entity.merge({"recipe_id": Expansion.DEFAULTS[type], "input": {}, "output": {}, "invested": {}, "processing": false, "progress": 0.0, "active_batch": 0, "output_batch": 0, "output_cursor": 0})
	if type == "refinery" and assembly_counts.refinery > 0 and entities.filter(func(e): return e.type == "refinery").size() >= 2:
		first_expansion_placed = true
	return result


func recipe_available(id: String) -> bool:
	return Expansion.RECIPES.has(id) or super.recipe_available(id)


func collector_cycle(e: Dictionary) -> float:
	return Expansion.cycle(e.mineral)


func _collected(item: String) -> void:
	extracted_by_item[item] += 1


func _batch_started(e: Dictionary) -> void:
	batch_recipes[str(e.active_batch)] = e.recipe_id


func _batch_completed(e: Dictionary) -> void:
	completed_by_recipe[e.recipe_id] += 1


func _step(dt: float) -> void:
	super._step(dt)
	prune_batches()


func prune_batches() -> void:
	var references := {}
	for e in entities:
		for key in ["active_batch", "output_batch", "batch"]:
			if e.get(key, 0) > 0:
				references[str(e[key])] = true
	for key in batch_recipes.keys():
		if not references.has(key): batch_recipes.erase(key)


func transfer(id: int, item: String, putting: bool, all_items: bool) -> Dictionary:
	var result := super.transfer(id, item, putting, all_items)
	if result.ok: prune_batches()
	return result


func cancel_batch(id: int) -> Dictionary:
	var result := super.cancel_batch(id)
	if result.ok: prune_batches()
	return result


func salvage(id: int, confirmed := false) -> Dictionary:
	if not near_entity(by_id(id)): return failure("请走到设备两格内回收")
	var result := super.salvage(id, confirmed)
	if result.ok: prune_batches()
	return result


func _output_item_at(e: Dictionary, output_port: Dictionary) -> String:
	if e.get("type", "") != "refinery": return super._output_item_at(e, output_port)
	for item in e.output:
		if (item == "mineral_slag") == (output_port.index == 1): return item
	return ""


func owned_count() -> int:
	return entities.size() + Items.count(kits)


func assemble(type: String) -> Dictionary:
	if not Expansion.ASSEMBLY_COST.has(type): return failure("此构件不能装配")
	var cost: int = Expansion.ASSEMBLY_COST[type]
	var quantity := Expansion.yield_for(type)
	if bag.get("construction_pack", 0) < cost: return failure("背包需要 %d 个构件包" % cost)
	if owned_count() > Expansion.MAX_OWNED - quantity: return failure("总拥有量上限 326，整批还需 %d 个空位" % quantity)
	if assembly_counts[type] >= MAX_COUNTER: return failure("装配计数已达上限")
	Items.add(bag, "construction_pack", -cost)
	kits[type] += quantity
	assembly_counts[type] += 1
	statistics.event("consumed", "construction_pack", cost)
	revision += 1
	return success({"type": type, "quantity": quantity, "cost": cost})


func material_balance() -> Dictionary:
	var held := bag.duplicate()
	for e in entities: Items.merge(held, Items.contents(e))
	var expected := extracted_by_item.duplicate()
	if discovery.sample_taken: expected.crust_sample = 1
	for recipe_id in recipes:
		var n: int = completed_by_recipe[recipe_id]
		for item in recipes[recipe_id].output:
			expected[item] = expected.get(item, 0) + n * recipes[recipe_id].output[item]
		for item in recipes[recipe_id].input:
			expected[item] = expected.get(item, 0) - n * recipes[recipe_id].input[item]
	for type in assembly_counts:
		expected.construction_pack = expected.get("construction_pack", 0) - assembly_counts[type] * Expansion.ASSEMBLY_COST[type]
	for passage in discovery.passages:
		if discovery.passages[passage]:
			expected.crust_solvent = expected.get("crust_solvent", 0) - DiscoveryRules.PASSAGES[passage].cost
	var balanced := true
	for item in item_ids:
		if held.get(item, 0) != expected.get(item, 0): balanced = false
	return {"held": held, "expected": expected, "balanced": balanced, "generated": generated}
