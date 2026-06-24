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
	"item.phase_well_core",
	"item.phase_well_spectrum",
	"item.well_ash",
	"item.phase_well_lattice",
	"item.phase_well_pike",
	"item.phase_well_heart",
	"item.phase_well_pulse_sheet",
	"item.heart_spine",
	"item.phase_well_damper",
	"item.phase_well_shunt",
	"item.phase_well_spindle",
	"item.phase_well_warp_sheet",
	"item.weft_bundle",
	"item.phase_well_tension_rib",
	"item.phase_well_shuttle",
	"item.phase_well_weave_core",
	"item.phase_well_knot_core",
	"item.phase_well_tether_sheet",
	"item.tether_fiber",
	"item.phase_well_tether_rib",
	"item.phase_well_tether_spike",
	"item.phase_well_anchor_core"
]
const SUPPLY_FEEDBACK_SECONDS := 4.0
const COMBAT_FEEDBACK_SECONDS := 5.0
const QUEST_COMPLETION_FEEDBACK_SECONDS := 7.0
const LOG_FEEDBACK_SECONDS := 6.0
const PROMPT_RUNTIME_MAX_CHARACTERS := 34
const LOG_RUNTIME_MAX_CHARACTERS := 44
const RUNTIME_TEXT_ELLIPSIS := "..."

var last_quick_slots: Array[String] = []
var supply_feedback_remaining_seconds := 0.0
var combat_feedback_remaining_seconds := 0.0
var quest_completion_feedback_remaining_seconds := 0.0
var log_feedback_remaining_seconds := 0.0
var last_combat_feedback: Dictionary = {}
var debug_panels_visible := false
var last_viewport_size := Vector2.ZERO
var device_panel_presenter := HudDevicePanelPresenter.new()
var debug_panel_presenter := HudDebugPanelPresenter.new()
var feedback_presenter := HudFeedbackPresenter.new()
var map_presenter := HudMapPresenter.new()
var status_presenter := HudStatusPresenter.new()
var hint_presenter := HudHintPresenter.new()
var action_summary_presenter := HudActionSummaryPresenter.new()
var development_baseline_presenter := HudDevelopmentBaselinePresenter.new()
var context_prompt_text := ""
var runtime_hint_text := ""
var objective_summary_text := ""
var last_log_summary_text := ""
var development_baseline_definitions: Array[Dictionary] = []
var visual_review_checkpoint_definitions: Array[Dictionary] = []
var selected_development_baseline_index := 0
var selected_visual_review_checkpoint_index := 0
var selected_gm_resource_index := 0
var last_debug_data_registry: DataRegistry
var last_debug_character_state: CharacterState

@onready var save_panel: ColorRect = $SavePanel
@onready var completion_panel: ColorRect = $CompletionPanel
@onready var quick_slot_panel: ColorRect = $QuickSlotPanel
@onready var status_panel: ColorRect = $StatusPanel
@onready var vitals_panel: ColorRect = $VitalsPanel
@onready var quick_supply_panel: ColorRect = $QuickSupplyPanel
@onready var action_summary_panel: ColorRect = $ActionSummaryPanel
@onready var combat_panel: ColorRect = $CombatPanel
@onready var map_panel: ColorRect = $MapPanel
@onready var map_title_label: Label = $MapPanel/MapTitleLabel
@onready var map_hint_label: Label = $MapPanel/MapHintLabel
@onready var map_track: ColorRect = $MapPanel/MapTrack
@onready var prompt_panel: ColorRect = $PromptPanel
@onready var device_panel: ColorRect = $DevicePanel
@onready var log_panel: ColorRect = $LogPanel
@onready var status_label: Label = $StatusPanel/StatusLabel
@onready var vitals_label: Label = $VitalsPanel/VitalsLabel
@onready var quick_supply_label: Label = $QuickSupplyPanel/QuickSupplyLabel
@onready var action_summary_label: Label = $ActionSummaryPanel/ActionSummaryLabel
@onready var combat_label: Label = $CombatPanel/CombatLabel
@onready var prompt_label: Label = $PromptPanel/PromptLabel
@onready var log_label: Label = $LogPanel/LogLabel
@onready var map_marker_rects: Array[ColorRect] = [
	$MapPanel/OutpostMarker,
	$MapPanel/CrystalMarker,
	$MapPanel/PollutionMarker,
	$MapPanel/RuinMarker,
	$MapPanel/DeepMarker,
	$MapPanel/InnerPhaseWellMarker,
	$MapPanel/PhaseWellSinkMarker,
	$MapPanel/PhaseWellChamberMarker,
	$MapPanel/PhaseWellLoomMarker,
	$MapPanel/PhaseWellFrameMarker,
	$MapPanel/PhaseWellTetherMarker,
	$MapPanel/DemoStabilizationCoreMarker
]
@onready var map_marker_labels: Array[Label] = [
	$MapPanel/OutpostLabel,
	$MapPanel/CrystalLabel,
	$MapPanel/PollutionLabel,
	$MapPanel/RuinLabel,
	$MapPanel/DeepLabel,
	$MapPanel/InnerPhaseWellLabel,
	$MapPanel/PhaseWellSinkLabel,
	$MapPanel/PhaseWellChamberLabel,
	$MapPanel/PhaseWellLoomLabel,
	$MapPanel/PhaseWellFrameLabel,
	$MapPanel/PhaseWellTetherLabel,
	$MapPanel/DemoStabilizationCoreLabel
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
@onready var baseline_demo_button: Button = $SavePanel/BaselineDemoButton
@onready var baseline_load_button: Button = $SavePanel/BaselineLoadButton
@onready var baseline_next_button: Button = $SavePanel/BaselineNextButton
@onready var visual_checkpoint_label: Label = $SavePanel/VisualCheckpointLabel
@onready var visual_checkpoint_previous_button: Button = $SavePanel/VisualCheckpointPreviousButton
@onready var visual_checkpoint_load_button: Button = $SavePanel/VisualCheckpointLoadButton
@onready var visual_checkpoint_next_button: Button = $SavePanel/VisualCheckpointNextButton
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
signal visual_review_checkpoint_requested(checkpoint_id: String)
signal gm_resource_adjust_requested(definition_id: String, delta: float)
signal gm_vitals_refill_requested


func _ready() -> void:
	_ensure_runtime_nodes()
	_apply_runtime_panel_style()
	new_game_button.pressed.connect(_on_new_game_pressed)
	baseline_previous_button.pressed.connect(_on_baseline_previous_pressed)
	baseline_demo_button.pressed.connect(_on_demo_baseline_pressed)
	baseline_load_button.pressed.connect(_on_baseline_load_pressed)
	baseline_next_button.pressed.connect(_on_baseline_next_pressed)
	visual_checkpoint_previous_button.pressed.connect(_on_visual_checkpoint_previous_pressed)
	visual_checkpoint_load_button.pressed.connect(_on_visual_checkpoint_load_pressed)
	visual_checkpoint_next_button.pressed.connect(_on_visual_checkpoint_next_pressed)
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
	visual_review_checkpoint_definitions = DevelopmentBaselineCatalog.get_visual_review_checkpoint_definitions()
	_select_visual_review_checkpoint_by_id(DevelopmentBaselineCatalog.get_default_visual_review_checkpoint_id())
	_refresh_visual_review_checkpoint_panel()
	_layout_runtime_panels(true)
	_refresh_action_summary_label()
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
	combat_feedback_remaining_seconds = maxf(0.0, combat_feedback_remaining_seconds - delta)
	if combat_feedback_remaining_seconds <= 0.0:
		last_combat_feedback.clear()
	quest_completion_feedback_remaining_seconds = maxf(0.0, quest_completion_feedback_remaining_seconds - delta)
	if quest_completion_feedback_remaining_seconds <= 0.0:
		completion_panel.visible = false
	log_feedback_remaining_seconds = maxf(0.0, log_feedback_remaining_seconds - delta)
	if log_feedback_remaining_seconds <= 0.0 and log_panel != null:
		log_panel.visible = false
		if not last_log_summary_text.is_empty():
			last_log_summary_text = ""
			_refresh_action_summary_label()


func update_status(data_registry: DataRegistry, world_state: WorldState, character_state: CharacterState) -> void:
	_ensure_runtime_nodes()
	last_debug_data_registry = data_registry
	last_debug_character_state = character_state
	var active_quest_id := _get_active_quest_id(world_state)
	var objective_text := status_presenter.format_objective_text(data_registry, world_state, character_state)
	if status_label != null:
		status_label.text = objective_text
	objective_summary_text = objective_text
	if vitals_label != null:
		vitals_label.text = status_presenter.format_runtime_vitals_text(data_registry, world_state, character_state)
	if quick_supply_label != null:
		quick_supply_label.text = status_presenter.format_player_quick_supply_text(data_registry, world_state, character_state)
	_update_runtime_hint(world_state, character_state, active_quest_id)
	_update_map_panel(world_state, active_quest_id, character_state)
	last_quick_slots = debug_panel_presenter.update_quick_slot_binding_panel(
		data_registry,
		character_state,
		quick_slot_binding_labels
	)
	_refresh_gm_panel()


func update_combat_readability(
	data_registry: DataRegistry,
	world_state: WorldState,
	character_state: CharacterState,
	focused_enemy: PrototypeEnemy
) -> void:
	_ensure_runtime_nodes()
	if combat_panel == null or combat_label == null:
		return
	var has_target := focused_enemy != null and focused_enemy.can_be_attacked()
	var has_recent_feedback := not last_combat_feedback.is_empty()
	if not has_target and not has_recent_feedback:
		combat_panel.visible = false
		return
	combat_label.text = DemoCombatReadabilityFormatter.format_panel_text(
		data_registry,
		world_state,
		character_state,
		focused_enemy,
		last_combat_feedback
	)
	combat_panel.visible = true


func _get_active_quest_id(world_state: WorldState) -> String:
	var active_quest_id := ""
	if not world_state.quest_state.active_quest_ids.is_empty():
		active_quest_id = world_state.quest_state.active_quest_ids[0]
	return active_quest_id


func show_prompt(text: String) -> void:
	_ensure_runtime_nodes()
	context_prompt_text = text
	_refresh_prompt_label()
	_refresh_action_summary_label()


func clear_prompt() -> void:
	_ensure_runtime_nodes()
	context_prompt_text = ""
	_refresh_prompt_label()
	_refresh_action_summary_label()


func append_log(text: String) -> void:
	_ensure_runtime_nodes()
	var display_text := _format_bottom_rail_text(text, LOG_RUNTIME_MAX_CHARACTERS)
	last_log_summary_text = display_text
	if log_label != null:
		log_label.text = display_text
		log_label.tooltip_text = text.strip_edges()
	if log_panel != null:
		log_panel.visible = not display_text.is_empty()
	log_feedback_remaining_seconds = LOG_FEEDBACK_SECONDS if not display_text.is_empty() else 0.0
	_refresh_action_summary_label()


func clear_runtime_feedback() -> void:
	context_prompt_text = ""
	runtime_hint_text = ""
	last_log_summary_text = ""
	_refresh_prompt_label()
	_refresh_action_summary_label()
	hide_device_panel()
	completion_panel.visible = false
	evacuation_panel.visible = false
	supply_feedback_panel.visible = false
	combat_panel.visible = false
	quest_completion_feedback_remaining_seconds = 0.0
	supply_feedback_remaining_seconds = 0.0
	combat_feedback_remaining_seconds = 0.0
	last_combat_feedback.clear()


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


func show_combat_feedback(feedback: Dictionary) -> void:
	_ensure_runtime_nodes()
	if feedback.is_empty():
		return

	last_combat_feedback = feedback.duplicate(true)
	combat_feedback_remaining_seconds = COMBAT_FEEDBACK_SECONDS


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
	var selected_baseline_id := _get_selected_development_baseline_id()
	development_baseline_definitions.clear()
	for definition in definitions:
		var baseline_definition: Dictionary = definition
		development_baseline_definitions.append(baseline_definition.duplicate(true))
	if development_baseline_definitions.is_empty():
		selected_development_baseline_index = 0
	else:
		if selected_baseline_id.is_empty():
			selected_baseline_id = DevelopmentBaselineCatalog.get_default_demo_baseline_id()
		_select_development_baseline_by_id(selected_baseline_id)
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


func _on_demo_baseline_pressed() -> void:
	if development_baseline_definitions.is_empty():
		return
	var demo_baseline_ids := DevelopmentBaselineCatalog.get_demo_baseline_ids()
	if demo_baseline_ids.is_empty():
		return
	var current_id := _get_selected_development_baseline_id()
	var current_demo_baseline_index := demo_baseline_ids.find(current_id)
	var next_demo_baseline_id := ""
	if current_demo_baseline_index < 0:
		next_demo_baseline_id = DevelopmentBaselineCatalog.get_default_demo_baseline_id()
	else:
		next_demo_baseline_id = demo_baseline_ids[posmod(current_demo_baseline_index + 1, demo_baseline_ids.size())]
	_select_development_baseline_by_id(next_demo_baseline_id)
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


func _on_visual_checkpoint_previous_pressed() -> void:
	if visual_review_checkpoint_definitions.is_empty():
		return
	selected_visual_review_checkpoint_index = posmod(
		selected_visual_review_checkpoint_index - 1,
		visual_review_checkpoint_definitions.size()
	)
	_refresh_visual_review_checkpoint_panel()


func _on_visual_checkpoint_load_pressed() -> void:
	var definition := _get_selected_visual_review_checkpoint()
	if definition.is_empty():
		return
	visual_review_checkpoint_requested.emit(String(definition.get("id", "")))


func _on_visual_checkpoint_next_pressed() -> void:
	if visual_review_checkpoint_definitions.is_empty():
		return
	selected_visual_review_checkpoint_index = posmod(
		selected_visual_review_checkpoint_index + 1,
		visual_review_checkpoint_definitions.size()
	)
	_refresh_visual_review_checkpoint_panel()


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


func _update_map_panel(world_state: WorldState, quest_id: String, character_state: CharacterState) -> void:
	_ensure_runtime_nodes()
	if map_title_label != null:
		map_title_label.text = map_presenter.format_demo_route_title(world_state, quest_id)
	if map_hint_label != null:
		map_hint_label.text = _format_map_hint_runtime_text(
			map_presenter.format_demo_route_hint(world_state, quest_id, character_state)
		)
	var marker_view_data := map_presenter.get_marker_view_data(world_state, quest_id)
	for index in range(mini(marker_view_data.size(), map_marker_rects.size())):
		if map_marker_rects[index] == null or map_marker_labels[index] == null:
			continue
		var marker_view := marker_view_data[index]
		map_marker_rects[index].color = marker_view.get("color", Color.WHITE)
		map_marker_labels[index].text = _format_map_marker_runtime_label(String(marker_view.get("label", "")))


func _format_map_marker_runtime_label(raw_label: String) -> String:
	var rows := raw_label.split("\n", false)
	if rows.size() <= 1:
		return raw_label
	var status_rows: Array[String] = []
	for index in range(1, rows.size()):
		var row := String(rows[index])
		if row == "当前" or row == "目标" or row == "测绘预告":
			status_rows.append(row)
	if status_rows.is_empty():
		return String(rows[0])
	return "%s\n%s" % [String(rows[0]), " / ".join(status_rows)]


func _format_map_hint_runtime_text(raw_hint: String) -> String:
	var compact_parts: Array[String] = []
	for raw_part in raw_hint.split(" · ", false):
		var part := String(raw_part).strip_edges()
		if part.is_empty():
			continue
		var semicolon_index := part.find("；")
		if semicolon_index >= 0:
			part = part.substr(0, semicolon_index)
		compact_parts.append(part)
		if compact_parts.size() >= 2:
			break
	return " · ".join(compact_parts)


func _update_runtime_hint(world_state: WorldState, character_state: CharacterState, quest_id: String) -> void:
	runtime_hint_text = hint_presenter.format_runtime_hint(world_state, character_state, quest_id)
	_refresh_prompt_label()
	_refresh_action_summary_label()


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
	if baseline_demo_button != null:
		baseline_demo_button.disabled = not _has_available_demo_baselines()
	if baseline_load_button != null:
		baseline_load_button.disabled = not has_definitions
	if baseline_next_button != null:
		baseline_next_button.disabled = not has_definitions


func _refresh_visual_review_checkpoint_panel() -> void:
	_ensure_runtime_nodes()
	var definition := _get_selected_visual_review_checkpoint()
	if visual_checkpoint_label != null:
		visual_checkpoint_label.text = _format_selected_visual_review_checkpoint(definition)
	var has_definitions := not visual_review_checkpoint_definitions.is_empty()
	if visual_checkpoint_previous_button != null:
		visual_checkpoint_previous_button.disabled = not has_definitions
	if visual_checkpoint_load_button != null:
		visual_checkpoint_load_button.disabled = not has_definitions
	if visual_checkpoint_next_button != null:
		visual_checkpoint_next_button.disabled = not has_definitions


func _format_selected_visual_review_checkpoint(definition: Dictionary) -> String:
	if definition.is_empty():
		return "截图定位读取中..."
	return "%d/%d %s\n%s\n观察：%s" % [
		selected_visual_review_checkpoint_index + 1,
		maxi(visual_review_checkpoint_definitions.size(), 1),
		String(definition.get("display_name", "截图定位")),
		String(definition.get("summary", "")),
		String(definition.get("watch", ""))
	]


func _refresh_prompt_label() -> void:
	_ensure_runtime_nodes()
	if prompt_label == null:
		return
	var source_text := context_prompt_text
	if not context_prompt_text.strip_edges().is_empty():
		prompt_label.text = _format_prompt_rail_text(context_prompt_text)
	else:
		source_text = runtime_hint_text
		prompt_label.text = _format_bottom_rail_text(runtime_hint_text, PROMPT_RUNTIME_MAX_CHARACTERS)
	prompt_label.tooltip_text = source_text.strip_edges()


func _refresh_action_summary_label() -> void:
	_ensure_runtime_nodes()
	if action_summary_label == null:
		return
	action_summary_label.text = action_summary_presenter.format_label_text(
		objective_summary_text,
		context_prompt_text,
		runtime_hint_text,
		last_log_summary_text
	)
	action_summary_label.tooltip_text = action_summary_presenter.format_tooltip_text(
		objective_summary_text,
		context_prompt_text,
		runtime_hint_text,
		last_log_summary_text
	)
	if action_summary_panel != null:
		action_summary_panel.visible = true


func _format_prompt_rail_text(text: String) -> String:
	var clean_lines := _get_clean_runtime_lines(text)
	var title := ""
	var status := ""
	var next_step := ""
	var action := ""
	for line in clean_lines:
		if title.is_empty() and (
			line.begins_with("对象：")
				or line.begins_with("设施：")
				or line.begins_with("设备：")
				or line.begins_with("目标：")
				or line.begins_with("敌人：")
		):
			title = line
		elif status.is_empty() and line.begins_with("状态："):
			status = line
		elif next_step.is_empty() and line.begins_with("下一步："):
			next_step = line
		elif action.is_empty() and line.begins_with("操作："):
			action = line

	var parts: Array[String] = []
	if not title.is_empty():
		parts.append(title)
	if not action.is_empty():
		parts.append(action)
	elif not status.is_empty():
		parts.append(status)
	if parts.size() < 2 and not next_step.is_empty():
		parts.append(next_step)
	if parts.is_empty():
		return _format_bottom_rail_text(text, PROMPT_RUNTIME_MAX_CHARACTERS)
	return _shorten_runtime_text("；".join(parts), PROMPT_RUNTIME_MAX_CHARACTERS)


func _format_bottom_rail_text(text: String, max_characters: int) -> String:
	var compact := "；".join(_get_clean_runtime_lines(text))
	compact = compact.replace(" 下一步：", "；下一步：")
	compact = compact.replace(" 状态：", "；状态：")
	compact = compact.replace(" 操作：", "；操作：")
	while compact.find("  ") >= 0:
		compact = compact.replace("  ", " ")
	while compact.find("；；") >= 0:
		compact = compact.replace("；；", "；")
	return _shorten_runtime_text(compact.strip_edges(), max_characters)


func _get_clean_runtime_lines(text: String) -> Array[String]:
	var lines: Array[String] = []
	var normalized := text.replace("\r\n", "\n").replace("\r", "\n")
	for raw_line in normalized.split("\n", false):
		var line := String(raw_line).strip_edges()
		if line.is_empty():
			continue
		lines.append(line)
	return lines


func _shorten_runtime_text(text: String, max_characters: int) -> String:
	if text.length() <= max_characters:
		return text
	var visible_characters := maxi(0, max_characters - RUNTIME_TEXT_ELLIPSIS.length())
	return "%s%s" % [text.substr(0, visible_characters), RUNTIME_TEXT_ELLIPSIS]

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
	if quick_supply_panel == null:
		quick_supply_panel = get_node_or_null("QuickSupplyPanel")
	if action_summary_panel == null:
		action_summary_panel = get_node_or_null("ActionSummaryPanel")
	if combat_panel == null:
		combat_panel = get_node_or_null("CombatPanel")
	if map_panel == null:
		map_panel = get_node_or_null("MapPanel")
	if map_title_label == null:
		map_title_label = get_node_or_null("MapPanel/MapTitleLabel")
	if map_hint_label == null:
		map_hint_label = get_node_or_null("MapPanel/MapHintLabel")
	if map_track == null:
		map_track = get_node_or_null("MapPanel/MapTrack")
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
	if quick_supply_label == null:
		quick_supply_label = get_node_or_null("QuickSupplyPanel/QuickSupplyLabel")
	if action_summary_label == null:
		action_summary_label = get_node_or_null("ActionSummaryPanel/ActionSummaryLabel")
	if combat_label == null:
		combat_label = get_node_or_null("CombatPanel/CombatLabel")
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
			get_node_or_null("MapPanel/InnerPhaseWellMarker"),
			get_node_or_null("MapPanel/PhaseWellSinkMarker"),
			get_node_or_null("MapPanel/PhaseWellChamberMarker"),
			get_node_or_null("MapPanel/PhaseWellLoomMarker"),
			get_node_or_null("MapPanel/PhaseWellFrameMarker"),
			get_node_or_null("MapPanel/PhaseWellTetherMarker"),
			get_node_or_null("MapPanel/DemoStabilizationCoreMarker")
		]
	if map_marker_labels.is_empty() or map_marker_labels[0] == null:
		map_marker_labels = [
			get_node_or_null("MapPanel/OutpostLabel"),
			get_node_or_null("MapPanel/CrystalLabel"),
			get_node_or_null("MapPanel/PollutionLabel"),
			get_node_or_null("MapPanel/RuinLabel"),
			get_node_or_null("MapPanel/DeepLabel"),
			get_node_or_null("MapPanel/InnerPhaseWellLabel"),
			get_node_or_null("MapPanel/PhaseWellSinkLabel"),
			get_node_or_null("MapPanel/PhaseWellChamberLabel"),
			get_node_or_null("MapPanel/PhaseWellLoomLabel"),
			get_node_or_null("MapPanel/PhaseWellFrameLabel"),
			get_node_or_null("MapPanel/PhaseWellTetherLabel"),
			get_node_or_null("MapPanel/DemoStabilizationCoreLabel")
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
	if baseline_demo_button == null:
		baseline_demo_button = get_node_or_null("SavePanel/BaselineDemoButton")
	if baseline_load_button == null:
		baseline_load_button = get_node_or_null("SavePanel/BaselineLoadButton")
	if baseline_next_button == null:
		baseline_next_button = get_node_or_null("SavePanel/BaselineNextButton")
	if visual_checkpoint_label == null:
		visual_checkpoint_label = get_node_or_null("SavePanel/VisualCheckpointLabel")
	if visual_checkpoint_previous_button == null:
		visual_checkpoint_previous_button = get_node_or_null("SavePanel/VisualCheckpointPreviousButton")
	if visual_checkpoint_load_button == null:
		visual_checkpoint_load_button = get_node_or_null("SavePanel/VisualCheckpointLoadButton")
	if visual_checkpoint_next_button == null:
		visual_checkpoint_next_button = get_node_or_null("SavePanel/VisualCheckpointNextButton")
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
	_apply_runtime_panel_style()
	var viewport_size := _get_runtime_viewport_size()
	if viewport_size.x <= 0.0 or viewport_size.y <= 0.0:
		return
	if not force and viewport_size == last_viewport_size:
		return

	last_viewport_size = viewport_size
	var margin := 16.0
	var gap := 10.0
	var objective_width := clampf(viewport_size.x * 0.2, 360.0, 430.0)
	var objective_height := 132.0
	var map_width := objective_width
	var map_height := 104.0
	var vitals_width := clampf(viewport_size.x * 0.18, 340.0, 420.0)
	var vitals_height := 122.0
	var quick_supply_width := vitals_width
	var quick_supply_height := 64.0
	var combat_width := clampf(viewport_size.x * 0.21, 380.0, 500.0)
	var combat_height := 164.0
	var prompt_width := clampf(viewport_size.x * 0.2, 340.0, 420.0)
	var prompt_height := 50.0
	var log_width := clampf(viewport_size.x * 0.2, 360.0, 440.0)
	var log_height := 50.0
	var action_summary_width := clampf(viewport_size.x * 0.32, 560.0, 720.0)
	var action_summary_height := 58.0
	var device_width := clampf(viewport_size.x * 0.34, 520.0, 640.0)
	var device_height := clampf(viewport_size.y * 0.52, 620.0, 760.0)
	var feedback_width := clampf(viewport_size.x * 0.24, 460.0, 560.0)
	var feedback_height := 220.0
	var save_width := 544.0
	var save_height := 584.0
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

	_set_control_rect(status_panel, Vector2(margin, margin), Vector2(objective_width, objective_height))
	_set_control_rect(map_panel, Vector2(margin, status_panel.position.y + status_panel.size.y + gap), Vector2(map_width, map_height))
	if vitals_panel != null:
		if not debug_panels_visible:
			vitals_panel.visible = true
		_set_control_rect(vitals_panel, Vector2(vitals_x, margin), Vector2(vitals_width, vitals_height))
	if quick_supply_panel != null:
		quick_supply_panel.visible = true
		_set_control_rect(
			quick_supply_panel,
			Vector2(vitals_x, margin + vitals_height + gap),
			Vector2(quick_supply_width, quick_supply_height)
		)

	var prompt_x := margin
	var prompt_y := viewport_size.y - margin - prompt_height
	var log_y := viewport_size.y - margin - log_height
	var action_summary_position := Vector2(
		(viewport_size.x - action_summary_width) * 0.5,
		prompt_y - gap - action_summary_height
	)
	_set_control_rect(prompt_panel, Vector2(prompt_x, prompt_y), Vector2(prompt_width, prompt_height))
	_set_control_rect(log_panel, Vector2(prompt_x + prompt_width + gap, log_y), Vector2(log_width, log_height))
	_set_control_rect(
		action_summary_panel,
		action_summary_position,
		Vector2(action_summary_width, action_summary_height)
	)
	if action_summary_panel != null:
		action_summary_panel.visible = true
	var combat_x := viewport_size.x - margin - combat_width
	if debug_panels_visible:
		combat_x = maxf(margin + log_width + gap, save_position.x - gap - combat_width)
	_set_control_rect(
		combat_panel,
		Vector2(combat_x, prompt_y - gap - combat_height),
		Vector2(combat_width, combat_height)
	)

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
		Vector2((viewport_size.x - feedback_width) * 0.5, prompt_y - gap - feedback_height),
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

	_layout_map_panel_contents()
	_layout_full_label(status_label, status_panel, 14.0, 14.0)
	_layout_full_label(vitals_label, vitals_panel, 14.0, 14.0)
	_layout_full_label(quick_supply_label, quick_supply_panel, 14.0, 10.0)
	_layout_full_label(combat_label, combat_panel, 14.0, 12.0)
	_layout_bottom_rail_label(prompt_label, prompt_panel, 14.0, 12.0)
	_layout_bottom_rail_label(log_label, log_panel, 14.0, 12.0)
	_layout_action_summary_label(action_summary_label, action_summary_panel, 16.0, 8.0)
	_layout_full_label(completion_title_label, completion_panel, 22.0, 16.0, 32.0)
	_layout_full_label(completion_detail_label, completion_panel, 22.0, 62.0)
	_layout_device_panel_labels()


func _get_runtime_viewport_size() -> Vector2:
	var viewport := get_viewport()
	if viewport != null:
		return viewport.get_visible_rect().size
	return Vector2(
		float(ProjectSettings.get_setting("display/window/size/viewport_width", 1920)),
		float(ProjectSettings.get_setting("display/window/size/viewport_height", 1080))
	)


func _set_control_rect(control: Control, position: Vector2, size: Vector2) -> void:
	if control == null:
		return
	control.position = position
	control.size = size


func _layout_map_panel_contents() -> void:
	if map_panel == null:
		return
	if map_title_label != null:
		map_title_label.position = Vector2(14.0, 10.0)
		map_title_label.size = Vector2(maxf(0.0, map_panel.size.x - 28.0), 24.0)
	if map_hint_label != null:
		map_hint_label.position = Vector2(14.0, 38.0)
		map_hint_label.size = Vector2(maxf(0.0, map_panel.size.x - 28.0), 30.0)

	var marker_count := mini(map_marker_rects.size(), map_marker_labels.size())
	if marker_count <= 0:
		return

	var marker_top := 76.0
	var marker_size := Vector2(10.0, 12.0)
	var primary_label_top := 88.0
	var secondary_label_top := 88.0
	var label_height := 16.0
	var left_margin := 18.0
	var right_margin := 18.0
	var usable_width := maxf(0.0, map_panel.size.x - left_margin - right_margin - marker_size.x)
	var step := 0.0
	if marker_count > 1:
		step = usable_width / float(marker_count - 1)
	var label_width := clampf(step * 1.7, 64.0, 96.0)
	var first_center_x := left_margin + marker_size.x * 0.5
	var last_center_x := first_center_x

	for index in range(marker_count):
		var marker_rect := map_marker_rects[index]
		var marker_label := map_marker_labels[index]
		if marker_rect == null or marker_label == null:
			continue

		var marker_x := left_margin + step * float(index)
		marker_rect.position = Vector2(marker_x, marker_top)
		marker_rect.size = marker_size

		var marker_center_x := marker_x + marker_size.x * 0.5
		var label_x := clampf(
			marker_center_x - label_width * 0.5,
			4.0,
			maxf(4.0, map_panel.size.x - label_width - 4.0)
		)
		var label_top := primary_label_top if index % 2 == 0 else secondary_label_top
		marker_label.visible = String(marker_label.text).find("\n") >= 0
		marker_label.position = Vector2(label_x, label_top)
		marker_label.size = Vector2(label_width, label_height)
		_prepare_wrapped_label(marker_label)

		if index == 0:
			first_center_x = marker_center_x
		last_center_x = marker_center_x

	if map_track != null:
		map_track.position = Vector2(first_center_x, marker_top + marker_size.y * 0.5 - 3.0)
		map_track.size = Vector2(maxf(0.0, last_center_x - first_center_x), 6.0)


func _apply_runtime_panel_style() -> void:
	var primary_color := Color(0.035, 0.054, 0.059, 0.34)
	var action_color := Color(0.028, 0.045, 0.048, 0.46)
	var floating_color := Color(0.035, 0.054, 0.059, 0.82)
	for panel in [map_panel, status_panel, vitals_panel, quick_supply_panel, combat_panel, prompt_panel, log_panel]:
		if panel != null:
			panel.color = primary_color
	if action_summary_panel != null:
		action_summary_panel.color = action_color
	for panel in [device_panel, completion_panel, evacuation_panel, supply_feedback_panel, save_panel, quick_slot_panel]:
		if panel != null:
			panel.color = floating_color


func _layout_full_label(label: Label, panel: Control, left: float, top: float, forced_height: float = -1.0) -> void:
	if label == null or panel == null:
		return
	label.position = Vector2(left, top)
	label.size.x = maxf(0.0, panel.size.x - left * 2.0)
	label.size.y = forced_height if forced_height > 0.0 else maxf(0.0, panel.size.y - top * 2.0)
	_prepare_wrapped_label(label)


func _layout_bottom_rail_label(label: Label, panel: Control, left: float, top: float) -> void:
	_layout_full_label(label, panel, left, top)
	if label == null:
		return
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.max_lines_visible = 1
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


func _layout_action_summary_label(label: Label, panel: Control, left: float, top: float) -> void:
	_layout_full_label(label, panel, left, top)
	if label == null:
		return
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.max_lines_visible = 2
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


func _prepare_wrapped_label(label: Label) -> void:
	if label == null:
		return
	label.autowrap_mode = TextServer.AUTOWRAP_ARBITRARY
	label.clip_text = true


func _layout_device_panel_labels() -> void:
	if device_panel == null:
		return
	if device_title_label != null:
		device_title_label.position = Vector2(22.0, 18.0)
		device_title_label.size = Vector2(device_panel.size.x - 134.0, 32.0)
		_prepare_wrapped_label(device_title_label)
	if device_close_button != null:
		device_close_button.position = Vector2(device_panel.size.x - 104.0, 18.0)
		device_close_button.size = Vector2(82.0, 32.0)
	if device_status_label != null:
		device_status_label.position = Vector2(22.0, 66.0)
		device_status_label.size = Vector2(device_panel.size.x - 44.0, 244.0)
		_prepare_wrapped_label(device_status_label)
	if device_recipe_label != null:
		device_recipe_label.position = Vector2(22.0, 322.0)
		device_recipe_label.size = Vector2(device_panel.size.x - 44.0, 240.0)
		_prepare_wrapped_label(device_recipe_label)
	if device_operation_label != null:
		device_operation_label.position = Vector2(22.0, device_panel.size.y - 78.0)
		device_operation_label.size = Vector2(device_panel.size.x - 44.0, 42.0)
		_prepare_wrapped_label(device_operation_label)


func _get_selected_development_baseline() -> Dictionary:
	if development_baseline_definitions.is_empty():
		return {}
	return development_baseline_definitions[selected_development_baseline_index]


func _get_selected_visual_review_checkpoint() -> Dictionary:
	if visual_review_checkpoint_definitions.is_empty():
		return {}
	return visual_review_checkpoint_definitions[selected_visual_review_checkpoint_index]


func _get_selected_development_baseline_id() -> String:
	return String(_get_selected_development_baseline().get("id", ""))


func _select_development_baseline_by_id(baseline_id: String) -> void:
	if development_baseline_definitions.is_empty():
		selected_development_baseline_index = 0
		return
	var baseline_index := _find_development_baseline_index(baseline_id)
	if baseline_index >= 0:
		selected_development_baseline_index = baseline_index
		return
	selected_development_baseline_index = clampi(
		selected_development_baseline_index,
		0,
		development_baseline_definitions.size() - 1
	)


func _find_development_baseline_index(baseline_id: String) -> int:
	if baseline_id.is_empty():
		return -1
	for index in range(development_baseline_definitions.size()):
		var definition := development_baseline_definitions[index]
		if String(definition.get("id", "")) == baseline_id:
			return index
	return -1


func _select_visual_review_checkpoint_by_id(checkpoint_id: String) -> void:
	if visual_review_checkpoint_definitions.is_empty():
		selected_visual_review_checkpoint_index = 0
		return
	var checkpoint_index := _find_visual_review_checkpoint_index(checkpoint_id)
	if checkpoint_index >= 0:
		selected_visual_review_checkpoint_index = checkpoint_index
		return
	selected_visual_review_checkpoint_index = clampi(
		selected_visual_review_checkpoint_index,
		0,
		visual_review_checkpoint_definitions.size() - 1
	)


func _find_visual_review_checkpoint_index(checkpoint_id: String) -> int:
	if checkpoint_id.is_empty():
		return -1
	for index in range(visual_review_checkpoint_definitions.size()):
		var definition := visual_review_checkpoint_definitions[index]
		if String(definition.get("id", "")) == checkpoint_id:
			return index
	return -1


func _has_available_demo_baselines() -> bool:
	for baseline_id in DevelopmentBaselineCatalog.get_demo_baseline_ids():
		if _find_development_baseline_index(baseline_id) >= 0:
			return true
	return false


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
