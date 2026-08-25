class_name SliceCraftingPlan
extends RefCounted

## Pure manufacturing diagnostics. The plan reads recipes and an immutable
## inventory snapshot, but never crafts intermediates or mutates player state.

const MAX_DIAGNOSTIC_BATCHES := 999


static func analyze(
	recipe: Dictionary,
	inventory: Inventory,
	core_inventory: Inventory = null
) -> Dictionary:
	if recipe.is_empty() or inventory == null:
		return {}
	var raw_cost := _expanded_base_cost(recipe)
	return {
		"direct_cost": (recipe["cost"] as Dictionary).duplicate(),
		"raw_cost": raw_cost,
		"current_craftable": _direct_craftable_count(
			recipe, inventory, core_inventory
		),
		"dependency_supported": _dependency_supported_count(
			recipe, inventory, core_inventory
		),
		"support_floor_maximum": _support_floor_maximum(recipe),
	}


static func summary_text(plan: Dictionary) -> String:
	if plan.is_empty():
		return ""
	var summary := "当前可制作 ×%d · 完整依赖可支撑 ×%d" % [
		int(plan["current_craftable"]),
		int(plan["dependency_supported"]),
	]
	var raw_cost: Dictionary = plan["raw_cost"]
	if not raw_cost.is_empty():
		summary += "\n基础折算 %s" % SliceRecipes.cost_text(raw_cost)
	var floor_maximum := int(plan["support_floor_maximum"])
	if floor_maximum > 0:
		summary += " · 补板最多 %d 格" % floor_maximum
	return summary


static func _direct_craftable_count(
	recipe: Dictionary,
	inventory: Inventory,
	core_inventory: Inventory
) -> int:
	var maximum := MAX_DIAGNOSTIC_BATCHES
	for raw_item_id in recipe["cost"]:
		var item_id := String(raw_item_id)
		var cost := int(recipe["cost"][raw_item_id])
		maximum = mini(
			maximum,
			floori(float(inventory.count(item_id)) / float(cost))
		)
	return _apply_output_limits(recipe, inventory, core_inventory, maximum)


static func _dependency_supported_count(
	recipe: Dictionary,
	inventory: Inventory,
	core_inventory: Inventory
) -> int:
	var working := inventory.contents_view()
	var crafted := 0
	while crafted < MAX_DIAGNOSTIC_BATCHES:
		var candidate := working.duplicate()
		if not _consume_recipe_cost(recipe, candidate, []):
			break
		var output_id := String(recipe["output"])
		candidate[output_id] = (
			int(candidate.get(output_id, 0))
			+ int(recipe.get("output_count", 1))
		)
		if not inventory.profile().accepts(candidate):
			break
		working = candidate
		crafted += 1
		if _apply_output_limits(
			recipe, inventory, core_inventory, crafted + 1
		) <= crafted:
			break
	return crafted


static func _consume_recipe_cost(
	recipe: Dictionary,
	working: Dictionary,
	stack: Array[String]
) -> bool:
	for raw_item_id in recipe["cost"]:
		if not _consume_item(
			String(raw_item_id),
			int(recipe["cost"][raw_item_id]),
			working,
			stack
		):
			return false
	return true


static func _consume_item(
	item_id: String,
	amount: int,
	working: Dictionary,
	stack: Array[String]
) -> bool:
	var available := int(working.get(item_id, 0))
	var used := mini(available, amount)
	_set_working_count(working, item_id, available - used)
	var missing := amount - used
	if missing <= 0:
		return true
	if stack.has(item_id):
		return false
	var source := _recipe_for_output(item_id)
	if source.is_empty():
		return false
	var output_count := int(source.get("output_count", 1))
	var batches := ceili(float(missing) / float(output_count))
	var next_stack := stack.duplicate()
	next_stack.append(item_id)
	for _index in range(batches):
		if not _consume_recipe_cost(source, working, next_stack):
			return false
	var produced := batches * output_count
	_set_working_count(working, item_id, produced - missing)
	return true


static func _expanded_base_cost(recipe: Dictionary) -> Dictionary:
	var result := {}
	for raw_item_id in recipe["cost"]:
		_expand_item(
			String(raw_item_id),
			int(recipe["cost"][raw_item_id]),
			result,
			[]
		)
	return result


static func _expand_item(
	item_id: String,
	amount: int,
	result: Dictionary,
	stack: Array[String]
) -> void:
	var source := _recipe_for_output(item_id)
	if source.is_empty() or stack.has(item_id):
		result[item_id] = int(result.get(item_id, 0)) + amount
		return
	var output_count := int(source.get("output_count", 1))
	var batches := ceili(float(amount) / float(output_count))
	var next_stack := stack.duplicate()
	next_stack.append(item_id)
	for raw_cost_id in source["cost"]:
		_expand_item(
			String(raw_cost_id),
			int(source["cost"][raw_cost_id]) * batches,
			result,
			next_stack
		)


static func _recipe_for_output(item_id: String) -> Dictionary:
	for candidate in SliceRecipes.RECIPES:
		if String(candidate["output"]) == item_id:
			return candidate
	return {}


static func _apply_output_limits(
	recipe: Dictionary,
	inventory: Inventory,
	core_inventory: Inventory,
	maximum: int
) -> int:
	var output_id := String(recipe["output"])
	var output_count := int(recipe.get("output_count", 1))
	maximum = mini(
		maximum,
		floori(float(inventory.free_space_for(output_id)) / float(output_count))
	)
	var unique_limit := int(recipe.get("unique_total_limit", 0))
	if unique_limit <= 0:
		return maximum
	var existing := inventory.count(output_id)
	if core_inventory != null:
		existing += core_inventory.count(output_id)
	return mini(
		maximum,
		floori(float(maxi(0, unique_limit - existing)) / float(output_count))
	)


static func _support_floor_maximum(recipe: Dictionary) -> int:
	if String(recipe.get("kind", "")) != "building":
		return 0
	var definition := SliceBuildingCatalog.find(
		String(recipe.get("building_id", ""))
	)
	if (
		definition == null
		or definition.is_floor
		or definition.surface_rule
		!= SliceBuildingDefinition.SURFACE_INDUSTRIAL_FLOOR
	):
		return 0
	return definition.footprint.x * definition.footprint.y


static func _set_working_count(
	working: Dictionary,
	item_id: String,
	amount: int
) -> void:
	if amount > 0:
		working[item_id] = amount
	else:
		working.erase(item_id)
