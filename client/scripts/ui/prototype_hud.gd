extends CanvasLayer
class_name PrototypeHud

const SAVE_SLOT_IDS: Array[String] = ["slot_01", "slot_02", "slot_03"]
const QUICK_SLOT_BIND_CANDIDATES: Array[String] = ["item.repair_gel", "item.resistance_vial_t1", ""]
const SUPPLY_FEEDBACK_SECONDS := 4.0
const QUEST_COMPLETION_FEEDBACK_SECONDS := 7.0
var last_quick_slots: Array[String] = []
var supply_feedback_remaining_seconds := 0.0
var quest_completion_feedback_remaining_seconds := 0.0
var debug_panels_visible := false
var device_panel_presenter := HudDevicePanelPresenter.new()
var debug_panel_presenter := HudDebugPanelPresenter.new()
var feedback_presenter := HudFeedbackPresenter.new()
var map_presenter := HudMapPresenter.new()
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


func configure_map_presenter(data_registry: DataRegistry, map: VerticalSliceMap) -> void:
	map_presenter.configure(data_registry, map)


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

	var texts := feedback_presenter.format_evacuation_panel_texts(feedback)
	evacuation_title_label.text = String(texts.get("title", "撤离结果"))
	evacuation_detail_label.text = String(texts.get("detail", ""))
	evacuation_panel.visible = true


func show_supply_feedback(feedback: Dictionary) -> void:
	if feedback.is_empty():
		return

	var texts := feedback_presenter.format_supply_feedback_panel_texts(feedback)
	supply_feedback_title_label.text = String(texts.get("title", "补给反馈"))
	supply_feedback_detail_label.text = String(texts.get("detail", ""))
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


func _update_map_panel(world_state: WorldState, quest_id: String) -> void:
	var marker_view_data := map_presenter.get_marker_view_data(world_state, quest_id)
	for index in range(mini(marker_view_data.size(), map_marker_rects.size())):
		var marker_view := marker_view_data[index]
		map_marker_rects[index].color = marker_view.get("color", Color.WHITE)
		map_marker_labels[index].text = String(marker_view.get("label", ""))
