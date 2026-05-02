extends RefCounted
class_name BuildSystem

var data_registry: DataRegistry


func _init(registry: DataRegistry) -> void:
	data_registry = registry


func build_structure(
	site_instance_id: String,
	building_id: String,
	character_state: CharacterState,
	world_state: WorldState,
	prerequisite_instance_id: String = ""
) -> Dictionary:
	var building := data_registry.get_definition(building_id)
	if building.is_empty():
		return _failure("未知建筑：%s" % building_id)

	var site_state := world_state.ensure_map_object(site_instance_id, building_id, character_state.current_region_id)
	if bool(site_state.get("is_built", false)):
		return _failure("该建造点已完成。")

	var requirement_error := _get_requirement_error(building_id, prerequisite_instance_id, world_state)
	if not requirement_error.is_empty():
		return _failure(requirement_error)

	var missing_costs := _get_missing_costs(building, character_state.inventory)
	if not missing_costs.is_empty():
		return _failure("缺少建造材料：%s。" % ", ".join(missing_costs))

	_consume_refs(building.get("build_cost", []), character_state.inventory)
	world_state.set_map_object_flag(site_instance_id, "is_built", true)
	world_state.map_objects[site_instance_id]["built_definition_id"] = building_id
	world_state.add_base_structure(
		_get_structure_id(site_instance_id),
		building_id,
		character_state.current_region_id,
		site_instance_id
	)

	return _success("建造完成：%s。" % _get_display_name(building_id), building_id)


func get_build_status(
	site_instance_id: String,
	building_id: String,
	character_state: CharacterState,
	world_state: WorldState,
	prerequisite_instance_id: String = ""
) -> Dictionary:
	var building := data_registry.get_definition(building_id)
	if building.is_empty():
		return {
			"can_build": false,
			"costs": "无",
			"message": "未知建筑：%s。" % building_id
		}

	var site_state := world_state.get_map_object(site_instance_id)
	if bool(site_state.get("is_built", false)):
		return {
			"can_build": false,
			"costs": _format_refs(building.get("build_cost", [])),
			"message": "已建成。"
		}

	var requirement_error := _get_requirement_error(building_id, prerequisite_instance_id, world_state)
	if not requirement_error.is_empty():
		return {
			"can_build": false,
			"costs": _format_refs(building.get("build_cost", [])),
			"message": requirement_error,
			"foundation_status": _format_foundation_status(building_id, world_state)
		}

	var missing_costs := _get_missing_costs(building, character_state.inventory)
	if not missing_costs.is_empty():
		return {
			"can_build": false,
			"costs": _format_refs(building.get("build_cost", [])),
			"message": "缺少建造材料：%s。" % ", ".join(missing_costs),
			"missing_costs": missing_costs,
			"foundation_status": _format_foundation_status(building_id, world_state)
		}

	return {
		"can_build": true,
		"costs": _format_refs(building.get("build_cost", [])),
		"message": "可建造。",
		"foundation_status": _format_foundation_status(building_id, world_state)
	}


func _get_requirement_error(building_id: String, prerequisite_instance_id: String, world_state: WorldState) -> String:
	if building_id == "building.foundation_t1":
		if prerequisite_instance_id.is_empty():
			return ""

		var prerequisite_state := world_state.get_map_object(prerequisite_instance_id)
		if prerequisite_state.is_empty() or not bool(prerequisite_state.get("is_cleared", false)):
			return "地面仍然粗糙，先清理或平整地块。"
		return ""

	if building_id == "building.pollution_filter":
		if world_state.count_base_structures("building.foundation_t1") < 2:
			return "污染过滤器需要先铺设 2 块基础地基。"
		return ""

	return ""


func _get_missing_costs(building: Dictionary, inventory: InventoryState) -> Array[String]:
	var missing_costs: Array[String] = []
	for cost in building.get("build_cost", []):
		if not cost is Dictionary:
			continue

		var definition_id := String(cost.get("id", ""))
		var amount := float(cost.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0:
			continue
		if not inventory.has_ref(definition_id, amount):
			missing_costs.append("%s x%s" % [_get_display_name(definition_id), _format_amount(amount)])

	return missing_costs


func _format_foundation_status(building_id: String, world_state: WorldState) -> String:
	if building_id != "building.pollution_filter":
		return ""
	return "基础地基：%d / 2" % mini(world_state.count_base_structures("building.foundation_t1"), 2)


func _format_refs(refs: Array, empty_text: String = "无") -> String:
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
		return empty_text
	return ", ".join(parts)


func _consume_refs(refs: Array, inventory: InventoryState) -> void:
	for ref in refs:
		if not ref is Dictionary:
			continue

		var definition_id := String(ref.get("id", ""))
		var amount := float(ref.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0:
			continue

		inventory.consume_ref(definition_id, amount)


func _get_structure_id(site_instance_id: String) -> String:
	return "structure.%s" % site_instance_id.get_slice(".", 1)


func _get_display_name(definition_id: String) -> String:
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id
	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))


func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount


func _success(message: String, building_id: String) -> Dictionary:
	return {
		"success": true,
		"message": message,
		"built_definition_id": building_id
	}


func _failure(message: String) -> Dictionary:
	return {
		"success": false,
		"message": message
	}
