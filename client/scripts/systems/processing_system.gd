extends RefCounted
class_name ProcessingSystem

var data_registry: DataRegistry


func _init(registry: DataRegistry) -> void:
	data_registry = registry


func process_recipe(recipe_id: String, character_state: CharacterState, world_state: WorldState) -> Dictionary:
	var recipe := data_registry.get_definition(recipe_id)
	if recipe.is_empty():
		return _failure("未知配方：%s" % recipe_id)

	var missing_inputs := _get_missing_inputs(recipe, character_state.inventory)
	if not missing_inputs.is_empty():
		return _failure("缺少原料：%s。" % ", ".join(missing_inputs))

	_consume_refs(recipe.get("inputs", []), character_state.inventory)
	_grant_refs(recipe.get("outputs", []), character_state.inventory)
	_grant_refs(recipe.get("byproducts", []), character_state.inventory)
	_record_structure_run(recipe, world_state)

	return _success("加工完成：%s -> %s。" % [
		_get_display_name(recipe_id),
		_format_refs(recipe.get("outputs", []))
	])


func _get_missing_inputs(recipe: Dictionary, inventory: InventoryState) -> Array[String]:
	var missing_inputs: Array[String] = []
	for input_ref in recipe.get("inputs", []):
		if not input_ref is Dictionary:
			continue

		var definition_id := String(input_ref.get("id", ""))
		var amount := float(input_ref.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0:
			continue
		if not inventory.has_ref(definition_id, amount):
			missing_inputs.append("%s x%s" % [_get_display_name(definition_id), _format_amount(amount)])

	return missing_inputs


func _consume_refs(refs: Array, inventory: InventoryState) -> void:
	for ref in refs:
		if not ref is Dictionary:
			continue

		var definition_id := String(ref.get("id", ""))
		var amount := float(ref.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0:
			continue

		inventory.consume_ref(definition_id, amount)


func _grant_refs(refs: Array, inventory: InventoryState) -> void:
	for ref in refs:
		if not ref is Dictionary:
			continue

		var definition_id := String(ref.get("id", ""))
		var amount := float(ref.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0:
			continue

		inventory.add_ref(definition_id, amount)


func _record_structure_run(recipe: Dictionary, world_state: WorldState) -> void:
	var building_id := String(recipe.get("required_building_id", ""))
	if building_id.is_empty():
		return

	var structure_id := "structure.%s" % building_id.get_slice(".", 1)
	world_state.ensure_base_structure(structure_id, building_id, "region.outpost_platform")
	world_state.set_base_structure_status(structure_id, "completed", String(recipe.get("id", "")))


func _format_refs(refs: Array) -> String:
	var parts: Array[String] = []
	for ref in refs:
		if not ref is Dictionary:
			continue

		var definition_id := String(ref.get("id", ""))
		var amount := float(ref.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0:
			continue

		parts.append("%s x%s" % [_get_display_name(definition_id), _format_amount(amount)])

	if parts.is_empty():
		return "无产物"
	return ", ".join(parts)


func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount


func _get_display_name(definition_id: String) -> String:
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id
	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))


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
