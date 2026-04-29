extends CanvasLayer
class_name PrototypeHud

@onready var status_label: Label = $PanelBackground/StatusLabel
@onready var prompt_label: Label = $PanelBackground/PromptLabel
@onready var log_label: Label = $PanelBackground/LogLabel


func update_status(data_registry: DataRegistry, world_state: WorldState, character_state: CharacterState) -> void:
	var active_quest_id := ""
	if not world_state.quest_state.active_quest_ids.is_empty():
		active_quest_id = world_state.quest_state.active_quest_ids[0]

	status_label.text = "\n".join([
		"RadishCatalyst Prototype",
		"区域：%s" % _get_display_name(data_registry, world_state.current_region_id),
		"目标：%s" % _format_goal_name(data_registry, world_state, active_quest_id),
		"进度：%s" % _format_active_quest_progress(data_registry, world_state, active_quest_id),
		"方向：%s" % _format_direction_hint(world_state, character_state, active_quest_id),
		"生命：%.0f / %.0f" % [character_state.health, character_state.max_health],
		"防护：%.0f / %.0f" % [character_state.protection, character_state.max_protection],
		"模块：%s（污染消耗 x%.2f）" % [
			_get_equipped_module_name(data_registry, character_state),
			character_state.get_pollution_drain_multiplier(data_registry)
		],
		"快捷栏：%s" % _format_quick_slots(data_registry, character_state),
		"背包：%s" % _format_inventory(data_registry, character_state.inventory)
	])


func show_prompt(text: String) -> void:
	prompt_label.text = text


func clear_prompt() -> void:
	prompt_label.text = ""


func append_log(text: String) -> void:
	log_label.text = text


func _get_display_name(data_registry: DataRegistry, definition_id: String) -> String:
	if definition_id.is_empty():
		return ""
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id
	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))


func _format_goal_name(data_registry: DataRegistry, world_state: WorldState, quest_id: String) -> String:
	if not quest_id.is_empty():
		return _get_display_name(data_registry, quest_id)
	if _is_slice_complete(world_state):
		return "第一切片已完成"
	return "无"


func _format_inventory(data_registry: DataRegistry, inventory: InventoryState) -> String:
	if inventory.items.is_empty() and inventory.fluids.is_empty():
		return "空"

	var parts: Array[String] = []
	for item_id in inventory.items:
		parts.append("%s x%s" % [_get_display_name(data_registry, item_id), inventory.items[item_id]])
	for fluid_id in inventory.fluids:
		parts.append("%s x%s" % [_get_display_name(data_registry, fluid_id), inventory.fluids[fluid_id]])
	return ", ".join(parts)


func _get_equipped_module_name(data_registry: DataRegistry, character_state: CharacterState) -> String:
	var module_id := String(character_state.equipment.get("suit_module", ""))
	if module_id.is_empty():
		return "未启用"
	return _get_display_name(data_registry, module_id)


func _format_quick_slots(data_registry: DataRegistry, character_state: CharacterState) -> String:
	var parts: Array[String] = []
	for slot_index in range(character_state.quick_slots.size()):
		var item_id := character_state.quick_slots[slot_index]
		if item_id.is_empty():
			parts.append("%d 空" % (slot_index + 1))
			continue

		parts.append("%d %s x%s" % [
			slot_index + 1,
			_get_display_name(data_registry, item_id),
			int(character_state.inventory.items.get(item_id, 0))
		])
	if parts.is_empty():
		return "无"
	return "；".join(parts)


func _format_active_quest_progress(data_registry: DataRegistry, world_state: WorldState, quest_id: String) -> String:
	if quest_id.is_empty():
		if _is_slice_complete(world_state):
			return "更深区域信号已确认"
		return "无"

	var quest := data_registry.get_definition(quest_id)
	if quest.is_empty():
		return "无"

	var parts: Array[String] = []
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
		parts.append("%s%s %s/%s" % [
			_get_objective_verb(objective_type),
			_get_display_name(data_registry, target_id),
			_format_amount(current_amount),
			_format_amount(required_amount)
		])

	if parts.is_empty():
		return "无"
	return "；".join(parts)


func _format_direction_hint(world_state: WorldState, character_state: CharacterState, quest_id: String) -> String:
	if quest_id.is_empty():
		if _is_slice_complete(world_state):
			return "第一切片原型已收束；返回基地整理补给，后续区域待开放。"
		return "按当前目标推进。"

	match quest_id:
		"quest.restore_outpost":
			return "检查左侧前哨核心，解锁晶体矿脉导航。"
		"quest.scout_crystal_field":
			return "向东进入蓝色晶体矿脉区，采集晶体矿物。"
		"quest.bring_back_sample":
			if world_state.quest_state.get_objective_progress(quest_id, "sample_object", "map_object.anomaly_crystal") <= 0.0:
				return "向东南采样异常晶体；采样后返回基地平台。"
			return "向西返回基地平台，完成样本回收。"
		"quest.make_filter_module":
			return "回基地使用基础反应器，组装基础过滤模块。"
		"quest.expand_treatment_point":
			return "前往污染边界北缘，清理地块、铺设地基并建造过滤器。"
		"quest.enter_pollution_edge":
			if not world_state.unlocked_region_ids.has("region.pollution_edge"):
				return "按 F 启用过滤模块，再向东进入黄色污染边界。"
			if character_state.protection < character_state.max_protection * 0.5:
				return "防护偏低，先用 2 补充或回基地再深入污染边界。"
			return "向东南进入黄色污染边界，采集沉积物并处理药剂。"
		"quest.defeat_elite_node":
			return "污染深处仍有精英节点，携带补给后继续向东推进。"
		"quest.unlock_ruin_signal":
			return "向污染边界东侧检查封锁遗迹入口；此处仅确认后续信号。"
		_:
			return "按当前目标推进。"


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
		"defeat_enemy":
			return "击败 "
		"inspect":
			return "检查 "
		_:
			return ""


func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount


func _is_slice_complete(world_state: WorldState) -> bool:
	return world_state.quest_state.unlocked_effects.has("slice_01_complete")
