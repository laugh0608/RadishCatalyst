extends CanvasLayer
class_name PrototypeHud

const SAVE_SLOT_IDS: Array[String] = ["slot_01", "slot_02", "slot_03"]
const QUICK_SLOT_BIND_CANDIDATES: Array[String] = ["item.repair_gel", "item.resistance_vial_t1", ""]

var last_quick_slots: Array[String] = []

@onready var status_label: Label = $StatusPanel/StatusLabel
@onready var prompt_label: Label = $PromptPanel/PromptLabel
@onready var log_label: Label = $LogPanel/LogLabel
@onready var completion_title_label: Label = $CompletionPanel/CompletionTitleLabel
@onready var completion_detail_label: Label = $CompletionPanel/CompletionDetailLabel
@onready var quick_slot_binding_labels: Array[Label] = [
	$QuickSlotPanel/Slot01BindingLabel,
	$QuickSlotPanel/Slot02BindingLabel
]
@onready var quick_slot_binding_buttons: Array[Button] = [
	$QuickSlotPanel/Slot01BindingButton,
	$QuickSlotPanel/Slot02BindingButton
]
@onready var save_slot_labels: Array[Label] = [
	$SavePanel/Slot01Label,
	$SavePanel/Slot02Label,
	$SavePanel/Slot03Label
]
@onready var save_slot_buttons: Array[Button] = [
	$SavePanel/Slot01SaveButton,
	$SavePanel/Slot02SaveButton,
	$SavePanel/Slot03SaveButton
]
@onready var load_slot_buttons: Array[Button] = [
	$SavePanel/Slot01LoadButton,
	$SavePanel/Slot02LoadButton,
	$SavePanel/Slot03LoadButton
]

signal save_slot_requested(slot_id: String)
signal load_slot_requested(slot_id: String)
signal quick_slot_binding_requested(slot_index: int, item_id: String)


func _ready() -> void:
	for index in range(SAVE_SLOT_IDS.size()):
		save_slot_buttons[index].pressed.connect(_on_save_slot_pressed.bind(index))
		load_slot_buttons[index].pressed.connect(_on_load_slot_pressed.bind(index))
	for index in range(quick_slot_binding_buttons.size()):
		quick_slot_binding_buttons[index].pressed.connect(_on_quick_slot_binding_pressed.bind(index))


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
		"坐标：x %.1f，y %.1f" % [character_state.position.x, character_state.position.y],
		"生命：%.0f / %.0f" % [character_state.health, character_state.max_health],
		"防护：%.0f / %.0f" % [character_state.protection, character_state.max_protection],
		"模块：%s（污染消耗 x%.2f）" % [
			_get_equipped_module_name(data_registry, character_state),
			character_state.get_pollution_drain_multiplier(data_registry)
		],
		"快捷栏：%s" % _format_quick_slots(data_registry, character_state),
		"背包：%s" % _format_inventory(data_registry, character_state.inventory)
	])
	_update_quick_slot_binding_panel(data_registry, character_state)


func show_prompt(text: String) -> void:
	prompt_label.text = text


func clear_prompt() -> void:
	prompt_label.text = ""


func append_log(text: String) -> void:
	log_label.text = text


func show_quest_completion(feedback: Dictionary) -> void:
	if feedback.is_empty():
		return

	completion_title_label.text = String(feedback.get("title", "任务完成"))
	var details: Array[String] = []
	_append_detail(details, String(feedback.get("reward_text", "")))
	_append_detail(details, String(feedback.get("unlock_text", "")))
	_append_detail(details, String(feedback.get("note_text", "")))
	_append_detail(details, String(feedback.get("next_goal_text", "")))
	completion_detail_label.text = "\n".join(details)


func update_save_slot_summaries(summaries: Array[Dictionary]) -> void:
	for index in range(save_slot_labels.size()):
		if index >= summaries.size():
			continue

		var summary := summaries[index]
		var label_text := "%s：%s\n%s" % [
			String(summary.get("display_name", SAVE_SLOT_IDS[index])),
			String(summary.get("status", "未知")),
			String(summary.get("details", ""))
		]
		save_slot_labels[index].text = label_text
		load_slot_buttons[index].disabled = not bool(summary.get("has_loadable_save", false))


func _on_save_slot_pressed(slot_index: int) -> void:
	save_slot_requested.emit(SAVE_SLOT_IDS[slot_index])


func _on_load_slot_pressed(slot_index: int) -> void:
	load_slot_requested.emit(SAVE_SLOT_IDS[slot_index])


func _on_quick_slot_binding_pressed(slot_index: int) -> void:
	var current_item_id := ""
	if slot_index < last_quick_slots.size():
		current_item_id = last_quick_slots[slot_index]
	var next_item_id := _get_next_quick_slot_candidate(current_item_id)
	quick_slot_binding_requested.emit(slot_index, next_item_id)


func _append_detail(details: Array[String], text: String) -> void:
	if text.strip_edges().is_empty():
		return
	details.append(text)


func _update_quick_slot_binding_panel(data_registry: DataRegistry, character_state: CharacterState) -> void:
	last_quick_slots = character_state.quick_slots.duplicate()
	for slot_index in range(quick_slot_binding_labels.size()):
		var item_id := ""
		if slot_index < character_state.quick_slots.size():
			item_id = character_state.quick_slots[slot_index]
		quick_slot_binding_labels[slot_index].text = "%d：%s" % [
			slot_index + 1,
			_format_quick_slot_binding(data_registry, character_state, item_id)
		]


func _format_quick_slot_binding(data_registry: DataRegistry, character_state: CharacterState, item_id: String) -> String:
	if item_id.is_empty():
		return "空"
	return "%s x%s" % [
		_get_display_name(data_registry, item_id),
		int(character_state.inventory.items.get(item_id, 0))
	]


func _get_next_quick_slot_candidate(current_item_id: String) -> String:
	var current_index := QUICK_SLOT_BIND_CANDIDATES.find(current_item_id)
	if current_index < 0:
		return QUICK_SLOT_BIND_CANDIDATES[0]
	return QUICK_SLOT_BIND_CANDIDATES[(current_index + 1) % QUICK_SLOT_BIND_CANDIDATES.size()]


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
