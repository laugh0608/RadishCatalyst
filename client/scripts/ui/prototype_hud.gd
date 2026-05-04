extends CanvasLayer
class_name PrototypeHud

const SAVE_SLOT_IDS: Array[String] = ["slot_01", "slot_02", "slot_03"]
const QUICK_SLOT_BIND_CANDIDATES: Array[String] = ["item.repair_gel", "item.resistance_vial_t1", ""]
const SUPPLY_FEEDBACK_SECONDS := 4.0
const MAP_MARKER_CURRENT_COLOR := Color(0.18, 0.86, 0.93, 1.0)
const MAP_MARKER_TARGET_COLOR := Color(1.0, 0.78, 0.28, 1.0)
const MAP_MARKER_UNLOCKED_COLOR := Color(0.55, 0.72, 0.66, 1.0)
const MAP_MARKER_LOCKED_COLOR := Color(0.28, 0.32, 0.32, 1.0)

var last_quick_slots: Array[String] = []
var supply_feedback_remaining_seconds := 0.0
var debug_panels_visible := false

@onready var save_panel: ColorRect = $SavePanel
@onready var completion_panel: ColorRect = $CompletionPanel
@onready var quick_slot_panel: ColorRect = $QuickSlotPanel
@onready var device_panel: ColorRect = $DevicePanel
@onready var status_label: Label = $StatusPanel/StatusLabel
@onready var prompt_label: Label = $PromptPanel/PromptLabel
@onready var log_label: Label = $LogPanel/LogLabel
@onready var map_marker_rects: Array[ColorRect] = [
	$MapPanel/OutpostMarker,
	$MapPanel/CrystalMarker,
	$MapPanel/PollutionMarker,
	$MapPanel/RuinMarker
]
@onready var map_marker_labels: Array[Label] = [
	$MapPanel/OutpostLabel,
	$MapPanel/CrystalLabel,
	$MapPanel/PollutionLabel,
	$MapPanel/RuinLabel
]
@onready var device_title_label: Label = $DevicePanel/DeviceTitleLabel
@onready var device_status_label: Label = $DevicePanel/DeviceStatusLabel
@onready var device_recipe_label: Label = $DevicePanel/DeviceRecipeLabel
@onready var device_operation_label: Label = $DevicePanel/DeviceOperationLabel
@onready var device_close_button: Button = $DevicePanel/DeviceCloseButton
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
@onready var evacuation_panel: ColorRect = $EvacuationPanel
@onready var evacuation_title_label: Label = $EvacuationPanel/EvacuationTitleLabel
@onready var evacuation_detail_label: Label = $EvacuationPanel/EvacuationDetailLabel
@onready var evacuation_close_button: Button = $EvacuationPanel/EvacuationCloseButton
@onready var supply_feedback_panel: ColorRect = $SupplyFeedbackPanel
@onready var supply_feedback_title_label: Label = $SupplyFeedbackPanel/SupplyFeedbackTitleLabel
@onready var supply_feedback_detail_label: Label = $SupplyFeedbackPanel/SupplyFeedbackDetailLabel
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
@onready var delete_slot_buttons: Array[Button] = [
	$SavePanel/Slot01DeleteButton,
	$SavePanel/Slot02DeleteButton,
	$SavePanel/Slot03DeleteButton
]

signal save_slot_requested(slot_id: String)
signal load_slot_requested(slot_id: String)
signal delete_slot_requested(slot_id: String)
signal quick_slot_binding_requested(slot_index: int, item_id: String)


func _ready() -> void:
	for index in range(SAVE_SLOT_IDS.size()):
		save_slot_buttons[index].pressed.connect(_on_save_slot_pressed.bind(index))
		load_slot_buttons[index].pressed.connect(_on_load_slot_pressed.bind(index))
		delete_slot_buttons[index].pressed.connect(_on_delete_slot_pressed.bind(index))
	for index in range(quick_slot_binding_buttons.size()):
		quick_slot_binding_buttons[index].pressed.connect(_on_quick_slot_binding_pressed.bind(index))
	evacuation_close_button.pressed.connect(_on_evacuation_close_pressed)
	device_close_button.pressed.connect(hide_device_panel)
	_set_debug_panels_visible(false)


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if event.pressed and not event.echo and event.keycode == KEY_TAB:
		_set_debug_panels_visible(not debug_panels_visible)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	if supply_feedback_remaining_seconds <= 0.0:
		return

	supply_feedback_remaining_seconds = maxf(0.0, supply_feedback_remaining_seconds - delta)
	if supply_feedback_remaining_seconds <= 0.0:
		supply_feedback_panel.visible = false


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
		"提示：%s" % _format_onboarding_hint(world_state, character_state, active_quest_id),
		"坐标：x %.1f，y %.1f" % [character_state.position.x, character_state.position.y],
		"生命：%.0f / %.0f" % [character_state.health, character_state.max_health],
		"防护：%.0f / %.0f" % [character_state.protection, character_state.max_protection],
		"污染：%s" % _format_pollution_status(data_registry, world_state, character_state),
		"模块：%s（污染消耗 x%.2f）" % [
			_get_equipped_module_name(data_registry, character_state),
			character_state.get_pollution_drain_multiplier(data_registry)
		],
		"快捷栏：%s" % _format_quick_slots(data_registry, character_state),
		"背包：%s" % _format_inventory(data_registry, character_state.inventory)
	])
	_update_map_panel(world_state, active_quest_id)
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

	completion_title_label.text = _format_quest_completion_panel_title(feedback)
	completion_detail_label.text = _format_quest_completion_details(feedback)


func show_evacuation_feedback(feedback: Dictionary) -> void:
	if feedback.is_empty():
		return

	evacuation_title_label.text = String(feedback.get("title", "撤离前哨"))
	var details: Array[String] = []
	_append_detail(details, "原因：%s" % String(feedback.get("reason_text", "")))
	_append_detail(details, String(feedback.get("recovery_text", "")))
	_append_detail(details, String(feedback.get("retry_text", "")))
	evacuation_detail_label.text = "\n".join(details)
	evacuation_panel.visible = true


func show_supply_feedback(feedback: Dictionary) -> void:
	if feedback.is_empty():
		return

	supply_feedback_title_label.text = String(feedback.get("title", "补给反馈"))
	supply_feedback_detail_label.text = String(feedback.get("detail", ""))
	supply_feedback_panel.visible = true
	supply_feedback_remaining_seconds = SUPPLY_FEEDBACK_SECONDS


func show_device_panel(
	data_registry: DataRegistry,
	processing_system: ProcessingSystem,
	interactable: PrototypeInteractable,
	character_state: CharacterState,
	world_state: WorldState
) -> void:
	if interactable == null or interactable.interaction_type != "process_recipe":
		hide_device_panel()
		return

	var texts := format_device_panel_texts(
		data_registry,
		processing_system,
		interactable,
		character_state,
		world_state
	)
	device_title_label.text = String(texts.get("title", "设备面板"))
	device_status_label.text = String(texts.get("status", ""))
	device_recipe_label.text = String(texts.get("recipes", ""))
	device_operation_label.text = String(texts.get("operations", ""))
	device_panel.visible = true


func refresh_device_panel(
	data_registry: DataRegistry,
	processing_system: ProcessingSystem,
	interactable: PrototypeInteractable,
	character_state: CharacterState,
	world_state: WorldState
) -> void:
	if not device_panel.visible:
		return
	show_device_panel(data_registry, processing_system, interactable, character_state, world_state)


func hide_device_panel() -> void:
	device_panel.visible = false


func is_device_panel_visible() -> bool:
	return device_panel.visible


func format_device_panel_texts(
	data_registry: DataRegistry,
	processing_system: ProcessingSystem,
	interactable: PrototypeInteractable,
	character_state: CharacterState,
	world_state: WorldState
) -> Dictionary:
	if interactable == null or interactable.interaction_type != "process_recipe":
		return {}

	var current_recipe_id := interactable.get_current_recipe_id()
	var status := processing_system.get_recipe_status(current_recipe_id, character_state, world_state)
	return {
		"title": "设备面板：%s" % _get_display_name(data_registry, interactable.definition_id),
		"status": _format_device_status(data_registry, current_recipe_id, status),
		"recipes": _format_device_recipe_list(data_registry, processing_system, interactable, character_state, world_state),
		"operations": _format_device_operations(interactable, status)
	}


func update_save_slot_summaries(summaries: Array[Dictionary]) -> void:
	for index in range(save_slot_labels.size()):
		if index >= summaries.size():
			continue

		var summary := summaries[index]
		var label_text := "%s：%s\n%s" % [
			String(summary.get("display_name", SAVE_SLOT_IDS[index])),
			String(summary.get("status", "未知")),
			_format_save_slot_details(summary)
		]
		save_slot_labels[index].text = label_text
		load_slot_buttons[index].disabled = not bool(summary.get("has_loadable_save", false))


func _on_save_slot_pressed(slot_index: int) -> void:
	save_slot_requested.emit(SAVE_SLOT_IDS[slot_index])


func _on_load_slot_pressed(slot_index: int) -> void:
	load_slot_requested.emit(SAVE_SLOT_IDS[slot_index])


func _on_delete_slot_pressed(slot_index: int) -> void:
	delete_slot_requested.emit(SAVE_SLOT_IDS[slot_index])


func _on_quick_slot_binding_pressed(slot_index: int) -> void:
	var current_item_id := ""
	if slot_index < last_quick_slots.size():
		current_item_id = last_quick_slots[slot_index]
	var next_item_id := _get_next_quick_slot_candidate(current_item_id)
	quick_slot_binding_requested.emit(slot_index, next_item_id)


func _on_evacuation_close_pressed() -> void:
	evacuation_panel.visible = false


func _format_device_status(data_registry: DataRegistry, recipe_id: String, status: Dictionary) -> String:
	var parts: Array[String] = [
		"当前配方：%s" % _get_display_name(data_registry, recipe_id),
		"状态：%s" % String(status.get("message", "")),
		"输入：%s" % String(status.get("inputs", "无")),
		"产出：%s" % String(status.get("outputs", "无"))
	]
	var byproducts := String(status.get("byproducts", ""))
	if not byproducts.is_empty():
		parts.append("副产：%s" % byproducts)
	parts.append("耗时：%s 秒" % String(status.get("duration", "0")))
	var progress := String(status.get("progress", ""))
	if not progress.is_empty():
		parts.append("进度：%s" % progress)
	var last_completion := String(status.get("last_completion", ""))
	if not last_completion.is_empty():
		parts.append(last_completion)
	var last_destination := String(status.get("last_destination", ""))
	if not last_destination.is_empty():
		parts.append("入库：%s" % last_destination)
	var last_next_step := String(status.get("last_next_step", ""))
	if not last_next_step.is_empty():
		parts.append("下一步：%s" % last_next_step)
	return "\n".join(parts)


func _format_device_recipe_list(
	data_registry: DataRegistry,
	processing_system: ProcessingSystem,
	interactable: PrototypeInteractable,
	character_state: CharacterState,
	world_state: WorldState
) -> String:
	var recipe_ids := interactable.recipe_ids.duplicate()
	if recipe_ids.is_empty() and not interactable.recipe_id.is_empty():
		recipe_ids.append(interactable.recipe_id)
	if recipe_ids.is_empty():
		return "配方列表：无"

	var rows: Array[String] = ["配方列表："]
	var current_recipe_id := interactable.get_current_recipe_id()
	for recipe_index in range(recipe_ids.size()):
		var recipe_id := String(recipe_ids[recipe_index])
		var status := processing_system.get_recipe_status(recipe_id, character_state, world_state)
		var marker := "  "
		if recipe_id == current_recipe_id:
			marker = "> "
		rows.append("%s%d. %s：%s" % [
			marker,
			recipe_index + 1,
			_get_display_name(data_registry, recipe_id),
			_format_device_recipe_state(status)
		])
	return "\n".join(rows)


func _format_device_recipe_state(status: Dictionary) -> String:
	if bool(status.get("can_process", false)):
		return "可加工"
	var missing_inputs: Array = status.get("missing_inputs", [])
	if not missing_inputs.is_empty():
		return "缺 %s" % "，".join(missing_inputs)
	return String(status.get("message", "不可加工")).trim_suffix("。")


func _format_device_operations(interactable: PrototypeInteractable, status: Dictionary) -> String:
	var operations: Array[String] = []
	if bool(status.get("can_process", false)):
		operations.append("E 启动当前配方")
	else:
		operations.append("E 尝试当前配方")
	if interactable.get_recipe_count() > 1:
		operations.append("R 切换配方")
	operations.append("Q 关闭面板")
	return "操作：%s" % "；".join(operations)


func _set_debug_panels_visible(is_visible: bool) -> void:
	debug_panels_visible = is_visible
	save_panel.visible = is_visible
	completion_panel.visible = is_visible
	quick_slot_panel.visible = is_visible


func _format_save_slot_details(summary: Dictionary) -> String:
	var status := String(summary.get("status", ""))
	var details := String(summary.get("details", ""))
	if status == "存档不可读取":
		return "存档损坏或内容已过期；可覆盖保存。"
	if bool(summary.get("has_loadable_save", false)):
		return _format_loadable_slot_details(details)
	if details.length() > 28:
		return "%s..." % details.substr(0, 28)
	return details


func _format_loadable_slot_details(details: String) -> String:
	var parts := details.split("；", false)
	var saved_at := ""
	var region := ""
	for part in parts:
		var text := String(part)
		if text.begins_with("最近保存："):
			saved_at = text.trim_prefix("最近保存：")
		if text.begins_with("区域："):
			region = text.trim_prefix("区域：")
	if saved_at.length() >= 16:
		saved_at = "%s %s" % [saved_at.substr(5, 5), saved_at.substr(11, 5)]
	if not saved_at.is_empty() and not region.is_empty():
		return "最近：%s；区域：%s" % [saved_at, region]
	if not saved_at.is_empty():
		return "最近：%s" % saved_at
	if details.length() > 28:
		return "%s..." % details.substr(0, 28)
	return details


func _append_detail(details: Array[String], text: String) -> void:
	if text.strip_edges().is_empty():
		return
	details.append(text)


func _format_quest_completion_panel_title(feedback: Dictionary) -> String:
	var panel_title := String(feedback.get("panel_title", ""))
	if not panel_title.strip_edges().is_empty():
		return panel_title
	var title := String(feedback.get("title", "任务完成"))
	if title.find("切片结尾") >= 0:
		return "切片完成"
	return "任务完成"


func _format_quest_completion_details(feedback: Dictionary) -> String:
	var details: Array[String] = []
	var completed_text := String(feedback.get("completed_text", ""))
	if completed_text.strip_edges().is_empty():
		completed_text = _format_completed_text_from_title(String(feedback.get("title", "")))
	_append_detail(details, completed_text)
	_append_detail(details, String(feedback.get("reward_text", "")))
	_append_detail(details, String(feedback.get("unlock_text", "")))
	_append_detail(details, _format_note_detail(String(feedback.get("note_text", ""))))
	_append_detail(details, String(feedback.get("next_goal_text", "")))
	if details.is_empty():
		return "暂无任务完成反馈"
	return "\n".join(details)


func _format_completed_text_from_title(title: String) -> String:
	if title.begins_with("任务完成："):
		return "完成：%s" % title.trim_prefix("任务完成：")
	if title.strip_edges().is_empty():
		return ""
	return "完成：%s" % title


func _format_note_detail(note_text: String) -> String:
	if note_text.strip_edges().is_empty() or note_text.begins_with("提示："):
		return note_text
	return "提示：%s" % note_text


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
		var amount := int(inventory.items[item_id])
		if amount <= 0:
			continue
		parts.append("%s x%s" % [_get_display_name(data_registry, item_id), amount])
	for fluid_id in inventory.fluids:
		var amount := float(inventory.fluids[fluid_id])
		if amount <= 0.0:
			continue
		parts.append("%s x%s" % [_get_display_name(data_registry, fluid_id), _format_amount(amount)])
	if parts.is_empty():
		return "空"
	if parts.size() <= 7:
		return "；".join(parts)
	return "%s；另 %d 类" % ["；".join(parts.slice(0, 7)), parts.size() - 7]


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


func _format_region_markers(world_state: WorldState, quest_id: String) -> String:
	var target_region_id := _get_quest_target_region_id(world_state, quest_id)
	var parts: Array[String] = []
	for marker in _get_region_marker_data():
		var region_id := String(marker.get("region_id", ""))
		var marker_parts: Array[String] = []
		if world_state.current_region_id == region_id:
			marker_parts.append("当前位置")
		else:
			marker_parts.append(String(marker.get("direction", "")))

		if target_region_id == region_id:
			marker_parts.append("目标")
		elif world_state.unlocked_region_ids.has(region_id):
			marker_parts.append("已解锁")
		else:
			marker_parts.append("未解锁")

		parts.append("%s：%s" % [
			String(marker.get("label", region_id)),
			"，".join(marker_parts)
		])
	return "；".join(parts)


func format_map_marker_labels(world_state: WorldState, quest_id: String) -> Array[String]:
	var labels: Array[String] = []
	var target_region_id := _get_quest_target_region_id(world_state, quest_id)
	for marker in _get_region_marker_data():
		labels.append(_format_map_marker_label(marker, world_state, target_region_id))
	return labels


func _update_map_panel(world_state: WorldState, quest_id: String) -> void:
	var target_region_id := _get_quest_target_region_id(world_state, quest_id)
	var markers := _get_region_marker_data()
	for index in range(mini(markers.size(), map_marker_rects.size())):
		var marker := markers[index]
		var region_id := String(marker.get("region_id", ""))
		map_marker_rects[index].color = _get_map_marker_color(region_id, world_state, target_region_id)
		map_marker_labels[index].text = _format_map_marker_label(marker, world_state, target_region_id)


func _get_region_marker_data() -> Array[Dictionary]:
	return [
		{
			"region_id": "region.outpost_platform",
			"label": "基地",
			"direction": "西侧"
		},
		{
			"region_id": "region.crystal_vein_field",
			"label": "晶体",
			"direction": "东侧"
		},
		{
			"region_id": "region.pollution_edge",
			"label": "污染",
			"direction": "东南"
		},
		{
			"region_id": "region.locked_ruin_gate",
			"label": "遗迹",
			"direction": "东端"
		}
	]


func _format_map_marker_label(marker: Dictionary, world_state: WorldState, target_region_id: String) -> String:
	var region_id := String(marker.get("region_id", ""))
	var rows: Array[String] = [String(marker.get("label", region_id))]
	if world_state.current_region_id == region_id:
		rows.append("当前")
	if target_region_id == region_id:
		rows.append("目标")
	elif world_state.unlocked_region_ids.has(region_id):
		rows.append("已解锁")
	else:
		rows.append("未解锁")
	return "\n".join(rows)


func _get_map_marker_color(region_id: String, world_state: WorldState, target_region_id: String) -> Color:
	if world_state.current_region_id == region_id:
		return MAP_MARKER_CURRENT_COLOR
	if target_region_id == region_id:
		return MAP_MARKER_TARGET_COLOR
	if world_state.unlocked_region_ids.has(region_id):
		return MAP_MARKER_UNLOCKED_COLOR
	return MAP_MARKER_LOCKED_COLOR


func _get_quest_target_region_id(world_state: WorldState, quest_id: String) -> String:
	match quest_id:
		"quest.restore_outpost":
			return "region.outpost_platform"
		"quest.scout_crystal_field":
			return "region.crystal_vein_field"
		"quest.bring_back_sample":
			if world_state.quest_state.get_objective_progress(quest_id, "sample_object", "map_object.anomaly_crystal") <= 0.0:
				return "region.crystal_vein_field"
			return "region.outpost_platform"
		"quest.make_filter_module":
			return "region.outpost_platform"
		"quest.expand_treatment_point", "quest.enter_pollution_edge", "quest.defeat_elite_node":
			return "region.pollution_edge"
		"quest.unlock_ruin_signal":
			return "region.locked_ruin_gate"
		_:
			return ""


func _format_onboarding_hint(world_state: WorldState, character_state: CharacterState, quest_id: String) -> String:
	if quest_id.is_empty():
		if _is_slice_complete(world_state):
			return "更深区域信号已确认，整理补给后等待后续内容。"
		return "查看当前目标和附近交互提示，按顺序推进。"

	match quest_id:
		"quest.restore_outpost":
			return "先恢复前哨核心；基地设备会告诉你缺什么资源。"
		"quest.scout_crystal_field":
			if world_state.current_region_id != "region.crystal_vein_field":
				return "晶体矿物是第一批加工输入，先去蓝色晶体区。"
			return "采集晶体簇；遇到掠行体时先用基础攻击处理威胁。"
		"quest.bring_back_sample":
			if world_state.quest_state.get_objective_progress(quest_id, "sample_object", "map_object.anomaly_crystal") <= 0.0:
				return "采样异常晶体；样本会解锁过滤介质配方。"
			return "带样本回基地，分析结果会打开制造过滤模块的链路。"
		"quest.make_filter_module":
			return "基础反应器负责制造远征产物；先补齐配方输入，再等待加工完成。"
		"quest.expand_treatment_point":
			if world_state.count_base_structures("building.foundation_t1") < 2:
				return "污染过滤器不能直接落地，先清理地块并铺设 2 块地基。"
			return "地基已满足要求，建造污染过滤器来处理沉积物。"
		"quest.enter_pollution_edge":
			if String(character_state.equipment.get("suit_module", "")).is_empty():
				return "启用基础过滤模块后再深入污染区，防护消耗会降低。"
			if character_state.protection < character_state.max_protection * 0.5:
				return "防护偏低，先使用抗污染药剂或回基地补给。"
			return "收集污染沉积物，用过滤器处理药剂，再清理受扰敌人。"
		"quest.unlock_ruin_signal":
			return "检查封锁遗迹入口即可结束本切片，不会进入新区域。"
		_:
			return "按当前目标推进；失败时查看日志和撤离反馈。"


func _format_pollution_status(data_registry: DataRegistry, world_state: WorldState, character_state: CharacterState) -> String:
	var region_id := world_state.current_region_id
	var pollution_level := float(world_state.pollution_levels.get(region_id, 0.0))
	if pollution_level <= 0.0:
		return "当前区域稳定，无持续污染压力。"

	var parts: Array[String] = [
		"%s 污染 %.0f%%" % [
			_get_display_name(data_registry, region_id),
			pollution_level * 100.0
		]
	]
	var module_id := String(character_state.equipment.get("suit_module", ""))
	if module_id.is_empty():
		parts.append("未启用过滤模块")
	else:
		parts.append("%s 生效，消耗 x%.2f" % [
			_get_display_name(data_registry, module_id),
			character_state.get_pollution_drain_multiplier(data_registry)
		])

	if character_state.protection < character_state.max_protection * 0.35:
		parts.append("防护危险，先用抗污染药剂或撤回基地")
	elif character_state.protection < character_state.max_protection * 0.5:
		parts.append("防护偏低，建议先补给")
	else:
		parts.append("防护可继续尝试")
	return "；".join(parts)


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
