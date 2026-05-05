extends CanvasLayer
class_name PrototypeHud

const SAVE_SLOT_IDS: Array[String] = ["slot_01", "slot_02", "slot_03"]
const QUICK_SLOT_BIND_CANDIDATES: Array[String] = ["item.repair_gel", "item.resistance_vial_t1", ""]
const SUPPLY_FEEDBACK_SECONDS := 4.0
const QUEST_COMPLETION_FEEDBACK_SECONDS := 7.0
const MAP_MARKER_CURRENT_COLOR := Color(0.18, 0.86, 0.93, 1.0)
const MAP_MARKER_TARGET_COLOR := Color(1.0, 0.78, 0.28, 1.0)
const MAP_MARKER_UNLOCKED_COLOR := Color(0.55, 0.72, 0.66, 1.0)
const MAP_MARKER_LOCKED_COLOR := Color(0.28, 0.32, 0.32, 1.0)
var last_quick_slots: Array[String] = []
var supply_feedback_remaining_seconds := 0.0
var quest_completion_feedback_remaining_seconds := 0.0
var debug_panels_visible := false
var device_panel_presenter := HudDevicePanelPresenter.new()
var debug_panel_presenter := HudDebugPanelPresenter.new()
var feedback_presenter := HudFeedbackPresenter.new()
var status_presenter := HudStatusPresenter.new()

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
@onready var new_game_button: Button = $SavePanel/NewGameButton
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
signal new_game_requested
signal quick_slot_binding_requested(slot_index: int, item_id: String)


func _ready() -> void:
	new_game_button.pressed.connect(_on_new_game_pressed)
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
	_update_timed_panel_visibility(delta)


func _update_timed_panel_visibility(delta: float) -> void:
	supply_feedback_remaining_seconds = maxf(0.0, supply_feedback_remaining_seconds - delta)
	if supply_feedback_remaining_seconds <= 0.0:
		supply_feedback_panel.visible = false
	quest_completion_feedback_remaining_seconds = maxf(0.0, quest_completion_feedback_remaining_seconds - delta)
	if quest_completion_feedback_remaining_seconds <= 0.0:
		completion_panel.visible = false


func update_status(data_registry: DataRegistry, world_state: WorldState, character_state: CharacterState) -> void:
	status_label.text = status_presenter.format_status_text(data_registry, world_state, character_state)
	_update_map_panel(world_state, _get_active_quest_id(world_state))
	last_quick_slots = debug_panel_presenter.update_quick_slot_binding_panel(
		data_registry,
		character_state,
		quick_slot_binding_labels
	)


func _get_active_quest_id(world_state: WorldState) -> String:
	var active_quest_id := ""
	if not world_state.quest_state.active_quest_ids.is_empty():
		active_quest_id = world_state.quest_state.active_quest_ids[0]
	return active_quest_id


func show_prompt(text: String) -> void:
	prompt_label.text = text


func clear_prompt() -> void:
	prompt_label.text = ""


func append_log(text: String) -> void:
	log_label.text = text


func clear_runtime_feedback() -> void:
	clear_prompt()
	hide_device_panel()
	completion_panel.visible = false
	evacuation_panel.visible = false
	supply_feedback_panel.visible = false
	quest_completion_feedback_remaining_seconds = 0.0
	supply_feedback_remaining_seconds = 0.0


func show_quest_completion(feedback: Dictionary) -> void:
	if feedback.is_empty():
		return

	var texts := feedback_presenter.format_quest_completion_panel_texts(feedback)
	completion_title_label.text = String(texts.get("title", "任务完成"))
	completion_detail_label.text = String(texts.get("detail", ""))
	completion_panel.visible = true
	quest_completion_feedback_remaining_seconds = QUEST_COMPLETION_FEEDBACK_SECONDS


func show_evacuation_feedback(feedback: Dictionary) -> void:
	if feedback.is_empty():
		return

	var texts := format_evacuation_panel_texts(feedback)
	evacuation_title_label.text = String(texts.get("title", "撤离结果"))
	evacuation_detail_label.text = String(texts.get("detail", ""))
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

	var texts := device_panel_presenter.format_device_panel_texts(
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


func update_save_slot_summaries(summaries: Array[Dictionary]) -> void:
	debug_panel_presenter.update_save_slot_summaries(
		summaries,
		save_slot_labels,
		load_slot_buttons,
		SAVE_SLOT_IDS
	)


func _on_save_slot_pressed(slot_index: int) -> void:
	save_slot_requested.emit(SAVE_SLOT_IDS[slot_index])


func _on_load_slot_pressed(slot_index: int) -> void:
	load_slot_requested.emit(SAVE_SLOT_IDS[slot_index])


func _on_delete_slot_pressed(slot_index: int) -> void:
	delete_slot_requested.emit(SAVE_SLOT_IDS[slot_index])


func _on_new_game_pressed() -> void:
	new_game_requested.emit()


func _on_quick_slot_binding_pressed(slot_index: int) -> void:
	var current_item_id := ""
	if slot_index < last_quick_slots.size():
		current_item_id = last_quick_slots[slot_index]
	var next_item_id := debug_panel_presenter.get_next_quick_slot_candidate(
		current_item_id,
		QUICK_SLOT_BIND_CANDIDATES
	)
	quick_slot_binding_requested.emit(slot_index, next_item_id)


func _on_evacuation_close_pressed() -> void:
	evacuation_panel.visible = false


func format_evacuation_panel_texts(feedback: Dictionary) -> Dictionary:
	var reason_text := String(feedback.get("reason_text", "状态过低"))
	var recovery_text := String(feedback.get("recovery_text", "已撤回前哨。"))
	var retry_text := String(feedback.get("retry_text", "再尝试前：补充快捷栏物品。"))
	var details: Array[String] = []
	_append_detail(details, "原因：%s" % reason_text)
	_append_detail(details, "恢复：%s" % recovery_text)
	_append_detail(details, _format_retry_detail(retry_text))
	return {
		"title": "撤离结果：%s" % reason_text,
		"detail": "\n".join(details)
	}


func _format_retry_detail(retry_text: String) -> String:
	if retry_text.strip_edges().is_empty():
		return ""
	if retry_text.begins_with("再尝试前："):
		return retry_text
	return "再尝试前：%s" % retry_text


func _set_debug_panels_visible(should_show: bool) -> void:
	debug_panels_visible = should_show
	save_panel.visible = should_show
	quick_slot_panel.visible = should_show


func _append_detail(details: Array[String], text: String) -> void:
	if text.strip_edges().is_empty():
		return
	details.append(text)


func _get_display_name(data_registry: DataRegistry, definition_id: String) -> String:
	if definition_id.is_empty():
		return ""
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id
	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))


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
		"quest.calibrate_reactor":
			if world_state.quest_state.get_objective_progress(quest_id, "gather_item", "item.salvage_scrap") < 4.0:
				return "在晶体矿脉区回收外勤残骸，凑齐导电废件后回基地。"
			return "回基地使用基础反应器，组装反应器校准件。"
		"quest.bring_back_sample":
			if world_state.quest_state.get_objective_progress(quest_id, "sample_object", "map_object.anomaly_crystal") <= 0.0:
				return "向东南采样异常晶体；采样后返回基地平台。"
			return "向西返回基地平台，完成样本回收。"
		"quest.analyze_anomaly_sample":
			if world_state.quest_state.get_objective_progress(quest_id, "gather_item", "item.anomaly_residue") < 2.0:
				return "回到异常晶体周边，回收两处异常残留点。"
			return "回基地使用基础反应器，分析异常样本。"
		"quest.make_filter_module":
			return "回基地使用基础反应器，组装基础过滤模块。"
		"quest.prepare_treatment_supplies":
			if world_state.quest_state.get_objective_progress(quest_id, "craft_item", "item.repair_gel") <= 0.0:
				return "回基地用基础反应器调制修复凝胶，给处理点施工做准备。"
			return "前往处理点北缘，清理徘徊的原生掠行体。"
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
		"quest.calibrate_reactor":
			if world_state.quest_state.get_objective_progress(quest_id, "gather_item", "item.salvage_scrap") < 4.0:
				return "region.crystal_vein_field"
			return "region.outpost_platform"
		"quest.bring_back_sample":
			if world_state.quest_state.get_objective_progress(quest_id, "sample_object", "map_object.anomaly_crystal") <= 0.0:
				return "region.crystal_vein_field"
			return "region.outpost_platform"
		"quest.analyze_anomaly_sample":
			if world_state.quest_state.get_objective_progress(quest_id, "gather_item", "item.anomaly_residue") < 2.0:
				return "region.crystal_vein_field"
			return "region.outpost_platform"
		"quest.make_filter_module":
			return "region.outpost_platform"
		"quest.prepare_treatment_supplies":
			if world_state.quest_state.get_objective_progress(quest_id, "craft_item", "item.repair_gel") <= 0.0:
				return "region.outpost_platform"
			return "region.crystal_vein_field"
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
		"quest.calibrate_reactor":
			if world_state.quest_state.get_objective_progress(quest_id, "gather_item", "item.salvage_scrap") < 4.0:
				return "外勤残骸提供导电废件；回收两处残骸后回基地加工校准件。"
			return "靠近基础反应器，切换到反应器校准件配方并等待加工完成。"
		"quest.bring_back_sample":
			if world_state.quest_state.get_objective_progress(quest_id, "sample_object", "map_object.anomaly_crystal") <= 0.0:
				return "采样异常晶体；样本需要带回基地确认。"
			return "带样本回基地，下一步会去周边回收残留物做分析。"
		"quest.analyze_anomaly_sample":
			if world_state.quest_state.get_objective_progress(quest_id, "gather_item", "item.anomaly_residue") < 2.0:
				return "异常残留物用于校验样本，回收两处后再回基地加工分析。"
			return "靠近基础反应器，切换到异常样本分析配方并等待完成。"
		"quest.make_filter_module":
			return "基础反应器负责制造远征产物；先补齐配方输入，再等待加工完成。"
		"quest.prepare_treatment_supplies":
			if world_state.quest_state.get_objective_progress(quest_id, "craft_item", "item.repair_gel") <= 0.0:
				return "先调制 1 份修复凝胶；后续处理点施工会经过敌人巡游区。"
			return "带上修复凝胶，清理处理点北缘的原生掠行体。"
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


func _is_slice_complete(world_state: WorldState) -> bool:
	return world_state.quest_state.unlocked_effects.has("slice_01_complete")
