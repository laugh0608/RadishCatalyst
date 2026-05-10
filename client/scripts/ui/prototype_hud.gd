extends CanvasLayer
class_name PrototypeHud

const SAVE_SLOT_IDS: Array[String] = ["slot_01", "slot_02", "slot_03"]
const QUICK_SLOT_BIND_CANDIDATES: Array[String] = ["item.repair_gel", "item.resistance_vial_t1", ""]
const GM_RESOURCE_CANDIDATES: Array[String] = [
	"item.repair_gel",
	"item.resistance_vial_t1",
	"item.basic_parts",
	"fluid.basic_solvent",
	"fluid.polluted_slurry",
	"item.phase_anchor",
	"item.deep_ruin_coordinates",
	"item.deep_override_key",
	"item.deep_route_imprint",
	"item.deep_signal_matrix",
	"item.phase_lens_blank",
	"item.relay_tuning_lens",
	"item.phase_well_locator",
	"item.phase_well_route",
	"item.well_flux_shard",
	"item.phase_well_stabilizer",
	"item.phase_well_probe",
	"item.phase_well_core"
]
const SUPPLY_FEEDBACK_SECONDS := 4.0
const QUEST_COMPLETION_FEEDBACK_SECONDS := 7.0
const LOG_FEEDBACK_SECONDS := 6.0

var last_quick_slots: Array[String] = []
var supply_feedback_remaining_seconds := 0.0
var quest_completion_feedback_remaining_seconds := 0.0
var log_feedback_remaining_seconds := 0.0
var debug_panels_visible := false
var last_viewport_size := Vector2.ZERO
var device_panel_presenter := HudDevicePanelPresenter.new()
var debug_panel_presenter := HudDebugPanelPresenter.new()
var feedback_presenter := HudFeedbackPresenter.new()
var map_presenter := HudMapPresenter.new()
var status_presenter := HudStatusPresenter.new()
var hint_presenter := HudHintPresenter.new()
var development_baseline_presenter := HudDevelopmentBaselinePresenter.new()
var context_prompt_text := ""
var runtime_hint_text := ""
var development_baseline_definitions: Array[Dictionary] = []
var selected_development_baseline_index := 0
var selected_gm_resource_index := 0
var last_debug_data_registry: DataRegistry
var last_debug_character_state: CharacterState

@onready var save_panel: ColorRect = $SavePanel
@onready var completion_panel: ColorRect = $CompletionPanel
@onready var quick_slot_panel: ColorRect = $QuickSlotPanel
@onready var status_panel: ColorRect = $StatusPanel
@onready var vitals_panel: ColorRect = $VitalsPanel
@onready var map_panel: ColorRect = $MapPanel
@onready var prompt_panel: ColorRect = $PromptPanel
@onready var device_panel: ColorRect = $DevicePanel
@onready var log_panel: ColorRect = $LogPanel
@onready var status_label: Label = $StatusPanel/StatusLabel
@onready var vitals_label: Label = $VitalsPanel/VitalsLabel
@onready var prompt_label: Label = $PromptPanel/PromptLabel
@onready var log_label: Label = $LogPanel/LogLabel
@onready var map_marker_rects: Array[ColorRect] = [
	$MapPanel/OutpostMarker,
	$MapPanel/CrystalMarker,
	$MapPanel/PollutionMarker,
	$MapPanel/RuinMarker,
	$MapPanel/DeepMarker,
	$MapPanel/InnerPhaseWellMarker
]
@onready var map_marker_labels: Array[Label] = [
	$MapPanel/OutpostLabel,
	$MapPanel/CrystalLabel,
	$MapPanel/PollutionLabel,
	$MapPanel/RuinLabel,
	$MapPanel/DeepLabel,
	$MapPanel/InnerPhaseWellLabel
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
@onready var gm_resource_label: Label = $QuickSlotPanel/GmResourceLabel
@onready var gm_vitals_label: Label = $QuickSlotPanel/GmVitalsLabel
@onready var gm_previous_button: Button = $QuickSlotPanel/GmPreviousButton
@onready var gm_subtract_button: Button = $QuickSlotPanel/GmSubtractButton
@onready var gm_add_button: Button = $QuickSlotPanel/GmAddButton
@onready var gm_next_button: Button = $QuickSlotPanel/GmNextButton
@onready var gm_refill_button: Button = $QuickSlotPanel/GmRefillButton
@onready var evacuation_panel: ColorRect = $EvacuationPanel
@onready var evacuation_title_label: Label = $EvacuationPanel/EvacuationTitleLabel
@onready var evacuation_detail_label: Label = $EvacuationPanel/EvacuationDetailLabel
@onready var evacuation_close_button: Button = $EvacuationPanel/EvacuationCloseButton
@onready var supply_feedback_panel: ColorRect = $SupplyFeedbackPanel
@onready var supply_feedback_title_label: Label = $SupplyFeedbackPanel/SupplyFeedbackTitleLabel
@onready var supply_feedback_detail_label: Label = $SupplyFeedbackPanel/SupplyFeedbackDetailLabel
@onready var new_game_button: Button = $SavePanel/NewGameButton
@onready var baseline_label: Label = $SavePanel/BaselineLabel
@onready var baseline_previous_button: Button = $SavePanel/BaselinePreviousButton
@onready var baseline_load_button: Button = $SavePanel/BaselineLoadButton
@onready var baseline_next_button: Button = $SavePanel/BaselineNextButton
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
signal development_baseline_requested(baseline_id: String)
signal gm_resource_adjust_requested(definition_id: String, delta: float)
signal gm_vitals_refill_requested


func _ready() -> void:
	_ensure_runtime_nodes()
	new_game_button.pressed.connect(_on_new_game_pressed)
	baseline_previous_button.pressed.connect(_on_baseline_previous_pressed)
	baseline_load_button.pressed.connect(_on_baseline_load_pressed)
	baseline_next_button.pressed.connect(_on_baseline_next_pressed)
	for index in range(SAVE_SLOT_IDS.size()):
		save_slot_buttons[index].pressed.connect(_on_save_slot_pressed.bind(index))
		load_slot_buttons[index].pressed.connect(_on_load_slot_pressed.bind(index))
		delete_slot_buttons[index].pressed.connect(_on_delete_slot_pressed.bind(index))
	for index in range(quick_slot_binding_buttons.size()):
		quick_slot_binding_buttons[index].pressed.connect(_on_quick_slot_binding_pressed.bind(index))
	gm_previous_button.pressed.connect(_on_gm_previous_pressed)
	gm_subtract_button.pressed.connect(_on_gm_subtract_pressed)
	gm_add_button.pressed.connect(_on_gm_add_pressed)
	gm_next_button.pressed.connect(_on_gm_next_pressed)
	gm_refill_button.pressed.connect(_on_gm_refill_pressed)
	evacuation_close_button.pressed.connect(_on_evacuation_close_pressed)
	device_close_button.pressed.connect(hide_device_panel)
	_layout_runtime_panels(true)
	_set_debug_panels_visible(false)


func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	if event.pressed and not event.echo and event.keycode == KEY_TAB:
		_set_debug_panels_visible(not debug_panels_visible)
		get_viewport().set_input_as_handled()


func _process(delta: float) -> void:
	_layout_runtime_panels()
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
	last_debug_data_registry = data_registry
	last_debug_character_state = character_state
	var active_quest_id := _get_active_quest_id(world_state)
	if status_label != null:
		status_label.text = status_presenter.format_objective_text(data_registry, world_state)
	if vitals_label != null:
		vitals_label.text = status_presenter.format_vitals_text(data_registry, world_state, character_state)
	_update_runtime_hint(world_state, character_state, active_quest_id)
	_update_map_panel(world_state, active_quest_id)
	last_quick_slots = debug_panel_presenter.update_quick_slot_binding_panel(
		data_registry,
		character_state,
		quick_slot_binding_labels
	)
	_refresh_gm_panel()


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

func update_development_baselines(definitions: Array[Dictionary]) -> void:
	development_baseline_definitions.clear()
	for definition in definitions:
		var baseline_definition: Dictionary = definition
		development_baseline_definitions.append(baseline_definition.duplicate(true))
	if development_baseline_definitions.is_empty():
		selected_development_baseline_index = 0
	else:
		selected_development_baseline_index = clampi(
			selected_development_baseline_index,
			0,
			development_baseline_definitions.size() - 1
		)
	_refresh_development_baseline_panel()


func _on_save_slot_pressed(slot_index: int) -> void:
	save_slot_requested.emit(SAVE_SLOT_IDS[slot_index])


func _on_load_slot_pressed(slot_index: int) -> void:
	load_slot_requested.emit(SAVE_SLOT_IDS[slot_index])


func _on_delete_slot_pressed(slot_index: int) -> void:
	delete_slot_requested.emit(SAVE_SLOT_IDS[slot_index])


func _on_new_game_pressed() -> void:
	new_game_requested.emit()


func _on_baseline_previous_pressed() -> void:
	if development_baseline_definitions.is_empty():
		return
	selected_development_baseline_index = posmod(
		selected_development_baseline_index - 1,
		development_baseline_definitions.size()
	)
	_refresh_development_baseline_panel()


func _on_baseline_load_pressed() -> void:
	var definition := _get_selected_development_baseline()
	if definition.is_empty():
		return
	development_baseline_requested.emit(String(definition.get("id", "")))

func _on_baseline_next_pressed() -> void:
	if development_baseline_definitions.is_empty():
		return
	selected_development_baseline_index = posmod(
		selected_development_baseline_index + 1,
		development_baseline_definitions.size()
	)
	_refresh_development_baseline_panel()


func _on_quick_slot_binding_pressed(slot_index: int) -> void:
	var current_item_id := ""
	if slot_index < last_quick_slots.size():
		current_item_id = last_quick_slots[slot_index]
	var next_item_id := debug_panel_presenter.get_next_quick_slot_candidate(
		current_item_id,
		QUICK_SLOT_BIND_CANDIDATES
	)
	quick_slot_binding_requested.emit(slot_index, next_item_id)


func _on_gm_previous_pressed() -> void:
	if GM_RESOURCE_CANDIDATES.is_empty():
		return
	selected_gm_resource_index = posmod(selected_gm_resource_index - 1, GM_RESOURCE_CANDIDATES.size())
	_refresh_gm_panel()


func _on_gm_subtract_pressed() -> void:
	var definition_id := _get_selected_gm_resource_id()
	if definition_id.is_empty():
		return
	gm_resource_adjust_requested.emit(definition_id, -1.0)


func _on_gm_add_pressed() -> void:
	var definition_id := _get_selected_gm_resource_id()
	if definition_id.is_empty():
		return
	gm_resource_adjust_requested.emit(definition_id, 1.0)


func _on_gm_next_pressed() -> void:
	if GM_RESOURCE_CANDIDATES.is_empty():
		return
	selected_gm_resource_index = posmod(selected_gm_resource_index + 1, GM_RESOURCE_CANDIDATES.size())
	_refresh_gm_panel()


func _on_gm_refill_pressed() -> void:
	gm_vitals_refill_requested.emit()


func _on_evacuation_close_pressed() -> void:
	evacuation_panel.visible = false


func _set_debug_panels_visible(should_show: bool) -> void:
	_ensure_runtime_nodes()
	debug_panels_visible = should_show
	save_panel.visible = should_show
	quick_slot_panel.visible = should_show
	if vitals_panel != null:
		vitals_panel.visible = not should_show
	_layout_runtime_panels(true)


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


func _refresh_development_baseline_panel() -> void:
	_ensure_runtime_nodes()
	var definition := _get_selected_development_baseline()
	if baseline_label != null:
		baseline_label.text = development_baseline_presenter.format_selected_baseline(
			definition,
			selected_development_baseline_index,
			maxi(development_baseline_definitions.size(), 1)
		)
	var has_definitions := not development_baseline_definitions.is_empty()
	if baseline_previous_button != null:
		baseline_previous_button.disabled = not has_definitions
	if baseline_load_button != null:
		baseline_load_button.disabled = not has_definitions
	if baseline_next_button != null:
		baseline_next_button.disabled = not has_definitions

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
	if status_panel == null:
		status_panel = get_node_or_null("StatusPanel")
	if vitals_panel == null:
		vitals_panel = get_node_or_null("VitalsPanel")
	if map_panel == null:
		map_panel = get_node_or_null("MapPanel")
	if prompt_panel == null:
		prompt_panel = get_node_or_null("PromptPanel")
	if device_panel == null:
		device_panel = get_node_or_null("DevicePanel")
	if log_panel == null:
		log_panel = get_node_or_null("LogPanel")
	if status_label == null:
		status_label = get_node_or_null("StatusPanel/StatusLabel")
	if vitals_label == null:
		vitals_label = get_node_or_null("VitalsPanel/VitalsLabel")
	if prompt_label == null:
		prompt_label = get_node_or_null("PromptPanel/PromptLabel")
	if log_label == null:
		log_label = get_node_or_null("LogPanel/LogLabel")
	if map_marker_rects.is_empty() or map_marker_rects[0] == null:
		map_marker_rects = [
			get_node_or_null("MapPanel/OutpostMarker"),
			get_node_or_null("MapPanel/CrystalMarker"),
			get_node_or_null("MapPanel/PollutionMarker"),
			get_node_or_null("MapPanel/RuinMarker"),
			get_node_or_null("MapPanel/DeepMarker"),
			get_node_or_null("MapPanel/InnerPhaseWellMarker")
		]
	if map_marker_labels.is_empty() or map_marker_labels[0] == null:
		map_marker_labels = [
			get_node_or_null("MapPanel/OutpostLabel"),
			get_node_or_null("MapPanel/CrystalLabel"),
			get_node_or_null("MapPanel/PollutionLabel"),
			get_node_or_null("MapPanel/RuinLabel"),
			get_node_or_null("MapPanel/DeepLabel"),
			get_node_or_null("MapPanel/InnerPhaseWellLabel")
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
	if gm_resource_label == null:
		gm_resource_label = get_node_or_null("QuickSlotPanel/GmResourceLabel")
	if gm_vitals_label == null:
		gm_vitals_label = get_node_or_null("QuickSlotPanel/GmVitalsLabel")
	if gm_previous_button == null:
		gm_previous_button = get_node_or_null("QuickSlotPanel/GmPreviousButton")
	if gm_subtract_button == null:
		gm_subtract_button = get_node_or_null("QuickSlotPanel/GmSubtractButton")
	if gm_add_button == null:
		gm_add_button = get_node_or_null("QuickSlotPanel/GmAddButton")
	if gm_next_button == null:
		gm_next_button = get_node_or_null("QuickSlotPanel/GmNextButton")
	if gm_refill_button == null:
		gm_refill_button = get_node_or_null("QuickSlotPanel/GmRefillButton")
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
	if baseline_label == null:
		baseline_label = get_node_or_null("SavePanel/BaselineLabel")
	if baseline_previous_button == null:
		baseline_previous_button = get_node_or_null("SavePanel/BaselinePreviousButton")
	if baseline_load_button == null:
		baseline_load_button = get_node_or_null("SavePanel/BaselineLoadButton")
	if baseline_next_button == null:
		baseline_next_button = get_node_or_null("SavePanel/BaselineNextButton")
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


func _layout_runtime_panels(force: bool = false) -> void:
	_ensure_runtime_nodes()
	var viewport_size := get_viewport().get_visible_rect().size
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	if not force and viewport_size == last_viewport_size:
		return

	last_viewport_size = viewport_size
	var margin := 20.0
	var gap := 16.0
	var map_width := 372.0
	var map_height := 176.0
	var objective_width := clampf(viewport_size.x * 0.28, 400.0, 520.0)
	var objective_height := 180.0
	var vitals_width := clampf(viewport_size.x * 0.24, 360.0, 440.0)
	var vitals_height := 168.0
	var prompt_width := clampf(viewport_size.x * 0.40, 680.0, 820.0)
	var prompt_height := 192.0
	var log_width := prompt_width
	var log_height := 96.0
	var device_width := clampf(viewport_size.x * 0.34, 520.0, 640.0)
	var device_height := clampf(viewport_size.y * 0.52, 620.0, 760.0)
	var feedback_width := clampf(viewport_size.x * 0.24, 460.0, 560.0)
	var feedback_height := 220.0
	var save_width := 544.0
	var save_height := 454.0
	var quick_width := 368.0
	var quick_height := 322.0
	var save_position := Vector2(viewport_size.x - margin - save_width, margin)
	var quick_slot_position := Vector2(
		viewport_size.x - margin - quick_width,
		save_position.y + save_height + gap
	)
	var vitals_x := viewport_size.x - margin - vitals_width
	if debug_panels_visible:
		var shifted_vitals_x := save_position.x - gap - vitals_width
		vitals_x = maxf(margin + objective_width + gap, shifted_vitals_x)

	_set_control_rect(map_panel, Vector2(margin, margin), Vector2(map_width, map_height))
	_set_control_rect(status_panel, Vector2(margin, map_panel.position.y + map_panel.size.y + gap), Vector2(objective_width, objective_height))
	if vitals_panel != null:
		if not debug_panels_visible:
			vitals_panel.visible = true
		_set_control_rect(vitals_panel, Vector2(vitals_x, margin), Vector2(vitals_width, vitals_height))

	var prompt_y := viewport_size.y - margin - prompt_height
	var log_y := prompt_y - gap - log_height
	_set_control_rect(prompt_panel, Vector2(margin, prompt_y), Vector2(prompt_width, prompt_height))
	_set_control_rect(log_panel, Vector2(margin, log_y), Vector2(log_width, log_height))

	var device_y := (viewport_size.y - device_height) * 0.5
	if debug_panels_visible:
		device_y = minf(
			viewport_size.y - margin - device_height,
			maxf(device_y, quick_slot_position.y + quick_height + gap)
		)
	var device_x := viewport_size.x - margin - device_width
	_set_control_rect(device_panel, Vector2(device_x, device_y), Vector2(device_width, device_height))
	_set_control_rect(
		completion_panel,
		Vector2((viewport_size.x - feedback_width) * 0.5, viewport_size.y - margin - feedback_height - 72.0),
		Vector2(feedback_width, feedback_height)
	)
	var side_feedback_x := viewport_size.x - margin - feedback_width
	if device_x - gap - feedback_width >= margin:
		side_feedback_x = device_x - gap - feedback_width
	_set_control_rect(
		evacuation_panel,
		Vector2(side_feedback_x, (viewport_size.y - 280.0) * 0.5),
		Vector2(feedback_width, 280.0)
	)
	_set_control_rect(
		supply_feedback_panel,
		Vector2(side_feedback_x, evacuation_panel.position.y + evacuation_panel.size.y + gap),
		Vector2(feedback_width, 118.0)
	)
	_set_control_rect(save_panel, save_position, Vector2(save_width, save_height))
	_set_control_rect(quick_slot_panel, quick_slot_position, Vector2(quick_width, quick_height))

	_layout_full_label(status_label, status_panel, 18.0, 18.0)
	_layout_full_label(vitals_label, vitals_panel, 18.0, 18.0)
	_layout_full_label(prompt_label, prompt_panel, 18.0, 18.0)
	_layout_full_label(log_label, log_panel, 18.0, 18.0)
	_layout_full_label(completion_title_label, completion_panel, 22.0, 16.0, 32.0)
	_layout_full_label(completion_detail_label, completion_panel, 22.0, 62.0)
	_layout_device_panel_labels()


func _set_control_rect(control: Control, position: Vector2, size: Vector2) -> void:
	if control == null:
		return
	control.position = position
	control.size = size


func _layout_full_label(label: Label, panel: Control, left: float, top: float, forced_height: float = -1.0) -> void:
	if label == null or panel == null:
		return
	label.position = Vector2(left, top)
	label.size.x = maxf(0.0, panel.size.x - left * 2.0)
	label.size.y = forced_height if forced_height > 0.0 else maxf(0.0, panel.size.y - top * 2.0)


func _layout_device_panel_labels() -> void:
	if device_panel == null:
		return
	if device_title_label != null:
		device_title_label.position = Vector2(22.0, 18.0)
		device_title_label.size = Vector2(device_panel.size.x - 134.0, 32.0)
	if device_close_button != null:
		device_close_button.position = Vector2(device_panel.size.x - 104.0, 18.0)
		device_close_button.size = Vector2(82.0, 32.0)
	if device_status_label != null:
		device_status_label.position = Vector2(22.0, 66.0)
		device_status_label.size = Vector2(device_panel.size.x - 44.0, 244.0)
	if device_recipe_label != null:
		device_recipe_label.position = Vector2(22.0, 322.0)
		device_recipe_label.size = Vector2(device_panel.size.x - 44.0, 240.0)
	if device_operation_label != null:
		device_operation_label.position = Vector2(22.0, device_panel.size.y - 78.0)
		device_operation_label.size = Vector2(device_panel.size.x - 44.0, 42.0)


func _get_selected_development_baseline() -> Dictionary:
	if development_baseline_definitions.is_empty():
		return {}
	return development_baseline_definitions[selected_development_baseline_index]


func _get_selected_gm_resource_id() -> String:
	if GM_RESOURCE_CANDIDATES.is_empty():
		return ""
	selected_gm_resource_index = clampi(selected_gm_resource_index, 0, GM_RESOURCE_CANDIDATES.size() - 1)
	return GM_RESOURCE_CANDIDATES[selected_gm_resource_index]


func _refresh_gm_panel() -> void:
	_ensure_runtime_nodes()
	var has_context := last_debug_data_registry != null and last_debug_character_state != null
	var definition_id := _get_selected_gm_resource_id()
	if gm_resource_label != null:
		if has_context:
			gm_resource_label.text = debug_panel_presenter.format_gm_resource_text(
				last_debug_data_registry,
				last_debug_character_state,
				definition_id
			)
		else:
			gm_resource_label.text = "GM 资源读取中..."
	if gm_vitals_label != null:
		if has_context:
			gm_vitals_label.text = debug_panel_presenter.format_gm_vitals_text(last_debug_character_state)
		else:
			gm_vitals_label.text = ""

	var has_gm_candidates := not definition_id.is_empty()
	if gm_previous_button != null:
		gm_previous_button.disabled = not has_gm_candidates
	if gm_subtract_button != null:
		gm_subtract_button.disabled = not has_gm_candidates
	if gm_add_button != null:
		gm_add_button.disabled = not has_gm_candidates
	if gm_next_button != null:
		gm_next_button.disabled = not has_gm_candidates
	if gm_refill_button != null:
		gm_refill_button.disabled = not has_context
