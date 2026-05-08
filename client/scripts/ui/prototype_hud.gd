extends CanvasLayer
class_name PrototypeHud

const SAVE_SLOT_IDS: Array[String] = ["slot_01", "slot_02", "slot_03"]
const QUICK_SLOT_BIND_CANDIDATES: Array[String] = ["item.repair_gel", "item.resistance_vial_t1", ""]
const SUPPLY_FEEDBACK_SECONDS := 4.0
const QUEST_COMPLETION_FEEDBACK_SECONDS := 7.0
const LOG_FEEDBACK_SECONDS := 6.0
var last_quick_slots: Array[String] = []
var supply_feedback_remaining_seconds := 0.0
var quest_completion_feedback_remaining_seconds := 0.0
var log_feedback_remaining_seconds := 0.0
var debug_panels_visible := false
var device_panel_presenter := HudDevicePanelPresenter.new()
var debug_panel_presenter := HudDebugPanelPresenter.new()
var feedback_presenter := HudFeedbackPresenter.new()
var map_presenter := HudMapPresenter.new()
var status_presenter := HudStatusPresenter.new()
var hint_presenter := HudHintPresenter.new()
var context_prompt_text := ""
var runtime_hint_text := ""

@onready var save_panel: ColorRect = $SavePanel
@onready var completion_panel: ColorRect = $CompletionPanel
@onready var quick_slot_panel: ColorRect = $QuickSlotPanel
@onready var device_panel: ColorRect = $DevicePanel
@onready var log_panel: ColorRect = $LogPanel
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
	_ensure_runtime_nodes()
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
	hint_presenter.configure(data_registry, map)


func _update_timed_panel_visibility(delta: float) -> void:
	supply_feedback_remaining_seconds = maxf(0.0, supply_feedback_remaining_seconds - delta)
	if supply_feedback_remaining_seconds <= 0.0:
		supply_feedback_panel.visible = false
	quest_completion_feedback_remaining_seconds = maxf(0.0, quest_completion_feedback_remaining_seconds - delta)
	if quest_completion_feedback_remaining_seconds <= 0.0:
		completion_panel.visible = false
	log_feedback_remaining_seconds = maxf(0.0, log_feedback_remaining_seconds - delta)
	if log_feedback_remaining_seconds <= 0.0 and log_panel != null:
		log_panel.visible = false


func update_status(data_registry: DataRegistry, world_state: WorldState, character_state: CharacterState) -> void:
	_ensure_runtime_nodes()
	var active_quest_id := _get_active_quest_id(world_state)
	if status_label != null:
		status_label.text = status_presenter.format_status_text(data_registry, world_state, character_state)
	_update_runtime_hint(world_state, character_state, active_quest_id)
	_update_map_panel(world_state, active_quest_id)
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
	_ensure_runtime_nodes()
	context_prompt_text = text
	_refresh_prompt_label()


func clear_prompt() -> void:
	_ensure_runtime_nodes()
	context_prompt_text = ""
	_refresh_prompt_label()


func append_log(text: String) -> void:
	_ensure_runtime_nodes()
	if log_label != null:
		log_label.text = text
	if log_panel != null:
		log_panel.visible = not text.strip_edges().is_empty()
	log_feedback_remaining_seconds = LOG_FEEDBACK_SECONDS if not text.strip_edges().is_empty() else 0.0


func clear_runtime_feedback() -> void:
	context_prompt_text = ""
	runtime_hint_text = ""
	_refresh_prompt_label()
	hide_device_panel()
	completion_panel.visible = false
	evacuation_panel.visible = false
	supply_feedback_panel.visible = false
	quest_completion_feedback_remaining_seconds = 0.0
	supply_feedback_remaining_seconds = 0.0


func show_quest_completion(feedback: Dictionary) -> void:
	_ensure_runtime_nodes()
	if feedback.is_empty():
		return

	var texts := feedback_presenter.format_quest_completion_panel_texts(feedback)
	completion_title_label.text = String(texts.get("title", "任务完成"))
	completion_detail_label.text = String(texts.get("detail", ""))
	completion_panel.visible = true
	quest_completion_feedback_remaining_seconds = QUEST_COMPLETION_FEEDBACK_SECONDS


func show_evacuation_feedback(feedback: Dictionary) -> void:
	_ensure_runtime_nodes()
	if feedback.is_empty():
		return

	var texts := feedback_presenter.format_evacuation_panel_texts(feedback)
	evacuation_title_label.text = String(texts.get("title", "撤离结果"))
	evacuation_detail_label.text = String(texts.get("detail", ""))
	evacuation_panel.visible = true


func show_supply_feedback(feedback: Dictionary) -> void:
	_ensure_runtime_nodes()
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
	_ensure_runtime_nodes()
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
	_ensure_runtime_nodes()
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
	_ensure_runtime_nodes()
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
	_ensure_runtime_nodes()
	var marker_view_data := map_presenter.get_marker_view_data(world_state, quest_id)
	for index in range(mini(marker_view_data.size(), map_marker_rects.size())):
		if map_marker_rects[index] == null or map_marker_labels[index] == null:
			continue
		var marker_view := marker_view_data[index]
		map_marker_rects[index].color = marker_view.get("color", Color.WHITE)
		map_marker_labels[index].text = String(marker_view.get("label", ""))


func _update_runtime_hint(world_state: WorldState, character_state: CharacterState, quest_id: String) -> void:
	runtime_hint_text = hint_presenter.format_runtime_hint(world_state, character_state, quest_id)
	_refresh_prompt_label()


func _refresh_prompt_label() -> void:
	_ensure_runtime_nodes()
	if prompt_label == null:
		return
	if not context_prompt_text.strip_edges().is_empty():
		prompt_label.text = context_prompt_text
		return
	prompt_label.text = runtime_hint_text


func _ensure_runtime_nodes() -> void:
	if save_panel == null:
		save_panel = get_node_or_null("SavePanel")
	if completion_panel == null:
		completion_panel = get_node_or_null("CompletionPanel")
	if quick_slot_panel == null:
		quick_slot_panel = get_node_or_null("QuickSlotPanel")
	if device_panel == null:
		device_panel = get_node_or_null("DevicePanel")
	if log_panel == null:
		log_panel = get_node_or_null("LogPanel")
	if status_label == null:
		status_label = get_node_or_null("StatusPanel/StatusLabel")
	if prompt_label == null:
		prompt_label = get_node_or_null("PromptPanel/PromptLabel")
	if log_label == null:
		log_label = get_node_or_null("LogPanel/LogLabel")
	if map_marker_rects.is_empty() or map_marker_rects[0] == null:
		map_marker_rects = [
			get_node_or_null("MapPanel/OutpostMarker"),
			get_node_or_null("MapPanel/CrystalMarker"),
			get_node_or_null("MapPanel/PollutionMarker"),
			get_node_or_null("MapPanel/RuinMarker")
		]
	if map_marker_labels.is_empty() or map_marker_labels[0] == null:
		map_marker_labels = [
			get_node_or_null("MapPanel/OutpostLabel"),
			get_node_or_null("MapPanel/CrystalLabel"),
			get_node_or_null("MapPanel/PollutionLabel"),
			get_node_or_null("MapPanel/RuinLabel")
		]
	if device_title_label == null:
		device_title_label = get_node_or_null("DevicePanel/DeviceTitleLabel")
	if device_status_label == null:
		device_status_label = get_node_or_null("DevicePanel/DeviceStatusLabel")
	if device_recipe_label == null:
		device_recipe_label = get_node_or_null("DevicePanel/DeviceRecipeLabel")
	if device_operation_label == null:
		device_operation_label = get_node_or_null("DevicePanel/DeviceOperationLabel")
	if device_close_button == null:
		device_close_button = get_node_or_null("DevicePanel/DeviceCloseButton")
	if completion_title_label == null:
		completion_title_label = get_node_or_null("CompletionPanel/CompletionTitleLabel")
	if completion_detail_label == null:
		completion_detail_label = get_node_or_null("CompletionPanel/CompletionDetailLabel")
	if quick_slot_binding_labels.is_empty() or quick_slot_binding_labels[0] == null:
		quick_slot_binding_labels = [
			get_node_or_null("QuickSlotPanel/Slot01BindingLabel"),
			get_node_or_null("QuickSlotPanel/Slot02BindingLabel")
		]
	if quick_slot_binding_buttons.is_empty() or quick_slot_binding_buttons[0] == null:
		quick_slot_binding_buttons = [
			get_node_or_null("QuickSlotPanel/Slot01BindingButton"),
			get_node_or_null("QuickSlotPanel/Slot02BindingButton")
		]
	if evacuation_panel == null:
		evacuation_panel = get_node_or_null("EvacuationPanel")
	if evacuation_title_label == null:
		evacuation_title_label = get_node_or_null("EvacuationPanel/EvacuationTitleLabel")
	if evacuation_detail_label == null:
		evacuation_detail_label = get_node_or_null("EvacuationPanel/EvacuationDetailLabel")
	if evacuation_close_button == null:
		evacuation_close_button = get_node_or_null("EvacuationPanel/EvacuationCloseButton")
	if supply_feedback_panel == null:
		supply_feedback_panel = get_node_or_null("SupplyFeedbackPanel")
	if supply_feedback_title_label == null:
		supply_feedback_title_label = get_node_or_null("SupplyFeedbackPanel/SupplyFeedbackTitleLabel")
	if supply_feedback_detail_label == null:
		supply_feedback_detail_label = get_node_or_null("SupplyFeedbackPanel/SupplyFeedbackDetailLabel")
	if new_game_button == null:
		new_game_button = get_node_or_null("SavePanel/NewGameButton")
	if save_slot_labels.is_empty() or save_slot_labels[0] == null:
		save_slot_labels = [
			get_node_or_null("SavePanel/Slot01Label"),
			get_node_or_null("SavePanel/Slot02Label"),
			get_node_or_null("SavePanel/Slot03Label")
		]
	if save_slot_buttons.is_empty() or save_slot_buttons[0] == null:
		save_slot_buttons = [
			get_node_or_null("SavePanel/Slot01SaveButton"),
			get_node_or_null("SavePanel/Slot02SaveButton"),
			get_node_or_null("SavePanel/Slot03SaveButton")
		]
	if load_slot_buttons.is_empty() or load_slot_buttons[0] == null:
		load_slot_buttons = [
			get_node_or_null("SavePanel/Slot01LoadButton"),
			get_node_or_null("SavePanel/Slot02LoadButton"),
			get_node_or_null("SavePanel/Slot03LoadButton")
		]
	if delete_slot_buttons.is_empty() or delete_slot_buttons[0] == null:
		delete_slot_buttons = [
			get_node_or_null("SavePanel/Slot01DeleteButton"),
			get_node_or_null("SavePanel/Slot02DeleteButton"),
			get_node_or_null("SavePanel/Slot03DeleteButton")
		]
