extends RefCounted
class_name HudObjectiveCompactFormatter

const MAX_LINES := 5
const PROGRESS_LINE_LIMIT := 2
const PROGRESS_MAX_LENGTH := 42
const NEXT_STEP_MAX_LENGTH := 44

var objective_source_resolver: QuestObjectiveSourceResolver
var objective_source_registry: DataRegistry


func format_lines(
	data_registry: DataRegistry,
	world_state: WorldState,
	character_state: CharacterState,
	quest_id: String,
	goal_name: String,
	fallback_progress: String
) -> Array[String]:
	_ensure_objective_source_resolver(data_registry)
	var lines: Array[String] = ["目标：%s" % goal_name]
	var progress_lines := _format_compact_active_quest_progress_lines(
		data_registry,
		world_state,
		quest_id,
		fallback_progress
	)
	if progress_lines.is_empty():
		lines.append("进度：无")
	else:
		for index in range(progress_lines.size()):
			var prefix := "进度：" if index == 0 else "  "
			lines.append("%s%s" % [prefix, progress_lines[index]])
	var next_step_line := _format_active_quest_next_step_line(
		data_registry,
		world_state,
		character_state,
		quest_id
	)
	if not next_step_line.is_empty():
		lines.append(next_step_line)
	return lines


func _format_compact_active_quest_progress_lines(
	data_registry: DataRegistry,
	world_state: WorldState,
	quest_id: String,
	fallback_progress: String
) -> Array[String]:
	var quest := data_registry.get_definition(quest_id)
	if quest.is_empty():
		if fallback_progress == "无":
			return []
		return [_shorten_visible_text(fallback_progress, PROGRESS_MAX_LENGTH)]

	var objective_lines: Array[String] = []
	var completion_flags: Array[bool] = []
	for objective in quest.get("objectives", []):
		if not objective is Dictionary:
			continue

		var objective_type := String(objective.get("type", ""))
		var target_id := String(objective.get("target_id", ""))
		var required_amount := float(objective.get("amount", 1.0))
		var current_amount := minf(
			world_state.quest_state.get_objective_progress(quest_id, objective_type, target_id),
			required_amount
		)
		objective_lines.append(_shorten_visible_text("%s%s %s/%s" % [
			_get_objective_verb(objective_type),
			_format_objective_target_name(data_registry, quest_id, objective_type, target_id, true),
			_format_amount(current_amount),
			_format_amount(required_amount)
		], PROGRESS_MAX_LENGTH))
		completion_flags.append(current_amount >= required_amount)

	if objective_lines.is_empty():
		return []

	var first_incomplete_index := -1
	for index in range(completion_flags.size()):
		if not completion_flags[index]:
			first_incomplete_index = index
			break

	var start_index := maxi(0, objective_lines.size() - PROGRESS_LINE_LIMIT)
	if first_incomplete_index >= 0:
		start_index = maxi(0, first_incomplete_index - (PROGRESS_LINE_LIMIT - 1))
		start_index = mini(start_index, maxi(0, objective_lines.size() - PROGRESS_LINE_LIMIT))

	var selected_lines: Array[String] = []
	var end_index := mini(objective_lines.size(), start_index + PROGRESS_LINE_LIMIT)
	for index in range(start_index, end_index):
		selected_lines.append(objective_lines[index])
	return selected_lines


func _format_active_quest_next_step_line(
	data_registry: DataRegistry,
	world_state: WorldState,
	character_state: CharacterState,
	quest_id: String
) -> String:
	if quest_id.is_empty():
		return ""
	if quest_id == "quest.enter_pollution_edge" and _has_pollution_vial_objective_ready(world_state):
		return "下一步：带药剂回污染边界，清理敌人/压力点"

	var quest := data_registry.get_definition(quest_id)
	if quest.is_empty():
		return ""
	for objective in quest.get("objectives", []):
		if not objective is Dictionary:
			continue
		var objective_type := String(objective.get("type", ""))
		var target_id := String(objective.get("target_id", ""))
		var required_amount := float(objective.get("amount", 1.0))
		if world_state.quest_state.get_objective_progress(quest_id, objective_type, target_id) >= required_amount:
			continue
		var next_step := _format_objective_next_step(
			data_registry,
			character_state,
			quest_id,
			objective_type,
			target_id
		)
		if next_step.is_empty():
			return ""
		return _shorten_visible_text("下一步：%s" % next_step, NEXT_STEP_MAX_LENGTH)
	return "下一步：当前目标已达成，继续查看新目标"


func _format_objective_next_step(
	data_registry: DataRegistry,
	character_state: CharacterState,
	quest_id: String,
	objective_type: String,
	target_id: String
) -> String:
	var target_name := _get_display_name(data_registry, target_id)
	match objective_type:
		"interact":
			return "与%s交互" % target_name
		"visit_region":
			return "前往%s" % target_name
		"return_region":
			return "返回%s" % target_name
		"gather_item":
			var source_hint := _get_objective_source_hint(quest_id, objective_type, target_id)
			if not source_hint.is_empty():
				return "到%s收集%s" % [_compact_source_hint(source_hint), target_name]
			return "收集%s" % target_name
		"sample_object":
			return "采样%s" % target_name
		"craft_item":
			return _format_craft_next_step(data_registry, character_state, target_id)
		"build":
			return _format_build_next_step(data_registry, character_state, target_id)
		"clear":
			return "清理%s" % target_name
		"defeat_enemy":
			return "击败%s" % target_name
		"inspect":
			return "检查%s" % target_name
		_:
			return target_name


func _format_craft_next_step(
	data_registry: DataRegistry,
	character_state: CharacterState,
	target_id: String
) -> String:
	var recipe := _find_recipe_for_output(data_registry, target_id)
	var target_name := _get_display_name(data_registry, target_id)
	if recipe.is_empty():
		return "制造%s" % target_name

	var recipe_name := _get_display_name(data_registry, String(recipe.get("id", "")))
	if recipe_name.is_empty():
		recipe_name = target_name
	var building_name := _get_display_name(data_registry, String(recipe.get("required_building_id", "")))
	var action_text := "执行%s" % recipe_name
	if not building_name.is_empty():
		action_text = "在%s%s" % [building_name, action_text]

	if character_state != null:
		var missing_inputs := _format_missing_recipe_inputs(data_registry, recipe, character_state.inventory)
		if not missing_inputs.is_empty():
			if not building_name.is_empty():
				return "补齐%s后在%s执行%s" % [missing_inputs, building_name, recipe_name]
			return "补齐%s后%s" % [missing_inputs, action_text]
	return action_text


func _format_build_next_step(
	data_registry: DataRegistry,
	character_state: CharacterState,
	building_id: String
) -> String:
	var building_name := _get_display_name(data_registry, building_id)
	var building := data_registry.get_definition(building_id)
	if character_state != null and not building.is_empty():
		var missing_costs := _format_missing_refs(data_registry, building.get("build_cost", []), character_state.inventory)
		if not missing_costs.is_empty():
			return "补齐%s后建造%s" % [missing_costs, building_name]
	return "建造%s" % building_name


func _get_objective_verb(objective_type: String) -> String:
	match objective_type:
		"interact":
			return "交互 "
		"visit_region":
			return "进入 "
		"return_region":
			return "返回 "
		"gather_item":
			return "收集 "
		"sample_object":
			return "采样 "
		"craft_item":
			return "制造 "
		"build":
			return "建造 "
		"clear":
			return "清理 "
		"defeat_enemy":
			return "击败 "
		"inspect":
			return "检查 "
		_:
			return ""


func _format_objective_target_name(
	data_registry: DataRegistry,
	quest_id: String,
	objective_type: String,
	target_id: String,
	compact: bool = false
) -> String:
	var target_name := _get_display_name(data_registry, target_id)
	var source_hint := _get_objective_source_hint(quest_id, objective_type, target_id)
	if source_hint.is_empty():
		return target_name
	if compact:
		source_hint = _compact_source_hint(source_hint)
	return "%s（%s）" % [target_name, source_hint]


func _get_objective_source_hint(quest_id: String, objective_type: String, target_id: String) -> String:
	if objective_source_resolver == null:
		return ""
	if objective_type != "gather_item" and objective_type != "craft_item":
		return ""
	var contextual_source_hint := _get_contextual_objective_source_hint(quest_id, objective_type, target_id)
	if not contextual_source_hint.is_empty():
		return contextual_source_hint
	return objective_source_resolver.resolve_source_hint(objective_type, target_id)


func _get_contextual_objective_source_hint(quest_id: String, objective_type: String, target_id: String) -> String:
	if objective_type != "gather_item" or target_id != "item.polluted_residue":
		return ""
	match quest_id:
		"quest.salvage_signal_echo":
			return "污染回波沉积"
		"quest.prepare_demo_stabilization_buffer":
			return "核心缓冲补料沉积"
		_:
			return ""


func _has_pollution_vial_objective_ready(world_state: WorldState) -> bool:
	return world_state.quest_state.get_objective_progress(
		"quest.enter_pollution_edge",
		"craft_item",
		"item.resistance_vial_t1"
	) >= 1.0


func _find_recipe_for_output(data_registry: DataRegistry, target_id: String) -> Dictionary:
	if target_id.is_empty():
		return {}
	for recipe in data_registry.get_table("recipes"):
		if not recipe is Dictionary:
			continue
		for output_ref in recipe.get("outputs", []):
			if not output_ref is Dictionary:
				continue
			if String(output_ref.get("id", "")) == target_id:
				return recipe
	return {}


func _format_missing_recipe_inputs(data_registry: DataRegistry, recipe: Dictionary, inventory: InventoryState) -> String:
	return _format_missing_refs(data_registry, recipe.get("inputs", []), inventory)


func _format_missing_refs(data_registry: DataRegistry, refs: Array, inventory: InventoryState) -> String:
	var parts: Array[String] = []
	for ref in refs:
		if not ref is Dictionary:
			continue
		var definition_id := String(ref.get("id", ""))
		var required_amount := float(ref.get("amount", 0.0))
		if definition_id.is_empty() or required_amount <= 0.0:
			continue
		var shortage := required_amount - _get_inventory_amount(inventory, definition_id)
		if shortage <= 0.0:
			continue
		parts.append("%s x%s" % [_get_display_name(data_registry, definition_id), _format_amount(shortage)])
	if parts.is_empty():
		return ""
	return "，".join(parts)


func _get_inventory_amount(inventory: InventoryState, definition_id: String) -> float:
	if inventory == null:
		return 0.0
	if definition_id.begins_with("fluid."):
		return float(inventory.fluids.get(definition_id, 0.0))
	if definition_id.begins_with("equipment."):
		return float(inventory.equipment.get(definition_id, 0))
	return float(inventory.items.get(definition_id, 0))


func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount


func _compact_source_hint(source_hint: String) -> String:
	match source_hint:
		"基础反应器":
			return "反应器"
		"污染过滤器":
			return "过滤器"
		"异常残留点":
			return "残留点"
		_:
			return source_hint


func _shorten_visible_text(text: String, max_length: int) -> String:
	if text.length() <= max_length:
		return text
	return "%s..." % text.substr(0, maxi(0, max_length - 3))


func _get_display_name(data_registry: DataRegistry, definition_id: String) -> String:
	if definition_id.is_empty():
		return ""
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id
	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))


func _ensure_objective_source_resolver(data_registry: DataRegistry) -> void:
	if data_registry == null:
		objective_source_resolver = null
		objective_source_registry = null
		return
	if objective_source_resolver != null and objective_source_registry == data_registry:
		return
	objective_source_resolver = QuestObjectiveSourceResolver.new(data_registry)
	objective_source_registry = data_registry
