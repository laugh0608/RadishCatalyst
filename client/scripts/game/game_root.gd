extends Node2D

var data_registry: DataRegistry
var world_state: WorldState
var character_state: CharacterState
var save_service := SaveService.new()
var development_baseline_builder: DevelopmentBaselineBuilder
var processing_system: ProcessingSystem
var build_system: BuildSystem
var quest_runtime: QuestRuntime
var interaction_prompt_formatter: InteractionPromptFormatter
var hud_feedback_presenter: HudFeedbackPresenter
var hud_log_presenter: HudLogPresenter

@onready var world_camera: Camera2D = $WorldCamera
@onready var vertical_slice_map: VerticalSliceMap = $VerticalSliceMap
@onready var hud: PrototypeHud = $PrototypeHud


func _ready() -> void:
	if data_registry == null:
		push_error("GameRoot requires DataRegistry before _ready().")
		return

	world_state = WorldState.create_default()
	character_state = CharacterState.create_default()
	save_service.setup(data_registry)
	development_baseline_builder = DevelopmentBaselineBuilder.new(data_registry)
	processing_system = ProcessingSystem.new(data_registry)
	build_system = BuildSystem.new(data_registry)
	quest_runtime = QuestRuntime.new(data_registry)
	interaction_prompt_formatter = InteractionPromptFormatter.new(data_registry, processing_system, build_system)
	hud_feedback_presenter = HudFeedbackPresenter.new()
	hud_log_presenter = HudLogPresenter.new(data_registry)
	vertical_slice_map.setup(data_registry)
	hud.configure_map_presenter(data_registry, vertical_slice_map)
	vertical_slice_map.sync_enemy_states(world_state)
	vertical_slice_map.refresh_world_interactables(world_state)
	vertical_slice_map.player.interaction_requested.connect(_on_player_interaction_requested)
	vertical_slice_map.player.attack_requested.connect(_on_player_attack_requested)
	vertical_slice_map.player.recipe_cycle_requested.connect(_on_player_recipe_cycle_requested)
	vertical_slice_map.player.device_panel_toggle_requested.connect(_on_player_device_panel_toggle_requested)
	vertical_slice_map.player.module_toggle_requested.connect(_on_player_module_toggle_requested)
	vertical_slice_map.player.quick_slot_requested.connect(_on_player_quick_slot_requested)
	vertical_slice_map.player.save_requested.connect(_on_player_save_requested)
	vertical_slice_map.player.load_requested.connect(_on_player_load_requested)
	hud.save_slot_requested.connect(_on_hud_save_slot_requested)
	hud.load_slot_requested.connect(_on_hud_load_slot_requested)
	hud.delete_slot_requested.connect(_on_hud_delete_slot_requested)
	hud.new_game_requested.connect(_on_hud_new_game_requested)
	hud.quick_slot_binding_requested.connect(_on_hud_quick_slot_binding_requested)
	hud.development_baseline_requested.connect(_on_hud_development_baseline_requested)
	hud.gm_resource_adjust_requested.connect(_on_hud_gm_resource_adjust_requested)
	hud.gm_vitals_refill_requested.connect(_on_hud_gm_vitals_refill_requested)
	vertical_slice_map.interaction_available.connect(_on_interaction_available)
	vertical_slice_map.interaction_cleared.connect(_on_interaction_cleared)
	vertical_slice_map.region_changed.connect(_on_region_changed)
	vertical_slice_map.region_gate_blocked.connect(_on_region_gate_blocked)
	_configure_world_camera()
	_sync_world_camera()

	hud.append_log(hud_log_presenter.format_startup_log())
	hud.update_development_baselines(development_baseline_builder.get_baseline_definitions())
	_refresh_save_slot_summaries()
	_update_hud()


func _process(delta: float) -> void:
	if world_state == null or character_state == null:
		return
	_apply_processing_progress(delta)
	_reconcile_active_quest_state()
	vertical_slice_map.refresh_enemy_spawns(world_state)
	vertical_slice_map.update_current_interactable()
	vertical_slice_map.update_region_presence(world_state, character_state)
	character_state.position = vertical_slice_map.get_player_position()
	_sync_world_camera()
	_refresh_current_context_prompt()
	_update_hud()


func _on_player_interaction_requested() -> void:
	var context := _get_current_interaction_context()
	var result := vertical_slice_map.try_interact(character_state, world_state)
	var log_messages: Array[String] = [hud_log_presenter.format_result_log(result)]
	if bool(result.get("success", false)) and _should_advance_interaction(context, result):
		_append_quest_runtime_result(log_messages, quest_runtime.advance_for_interaction(world_state, character_state, context, result))
	hud_feedback_presenter.show_evacuation_feedback(result, hud)
	hud_feedback_presenter.show_supply_feedback(result, hud)
	vertical_slice_map.refresh_world_interactables(world_state)
	if vertical_slice_map.current_interactable != null:
		_on_interaction_available(vertical_slice_map.current_interactable)
	hud.append_log(hud_log_presenter.join_messages(log_messages))
	_update_hud()


func _on_player_attack_requested() -> void:
	var result := vertical_slice_map.try_attack(character_state, world_state)
	var log_messages: Array[String] = [hud_log_presenter.format_result_log(result)]
	if bool(result.get("success", false)) and bool(result.get("enemy_defeated", false)):
		_append_quest_runtime_result(
			log_messages,
			quest_runtime.advance_for_defeated_enemy(world_state, character_state, String(result.get("enemy_definition_id", "")))
		)
	hud_feedback_presenter.show_evacuation_feedback(result, hud)
	hud.append_log(hud_log_presenter.join_messages(log_messages))
	_update_hud()


func _on_player_recipe_cycle_requested() -> void:
	var result := vertical_slice_map.try_cycle_recipe(world_state)
	if bool(result.get("success", false)) and vertical_slice_map.current_interactable != null and vertical_slice_map.current_interactable.interaction_type == "process_recipe":
		hud.append_log(interaction_prompt_formatter.format_processing_log(
			vertical_slice_map.current_interactable.get_current_recipe_id(),
			character_state,
			world_state
		))
		_on_interaction_available(vertical_slice_map.current_interactable, false)
	else:
		hud.append_log(hud_log_presenter.format_result_log(result))
		if bool(result.get("success", false)) and vertical_slice_map.current_interactable != null:
			_on_interaction_available(vertical_slice_map.current_interactable, false)
	_update_hud()


func _on_player_device_panel_toggle_requested() -> void:
	var interactable := vertical_slice_map.current_interactable
	if hud.is_device_panel_visible():
		hud.hide_device_panel()
		return
	if interactable == null or interactable.interaction_type != "process_recipe":
		hud.append_log(hud_log_presenter.format_no_device_panel_target_log())
		_update_hud()
		return

	hud.show_device_panel(data_registry, processing_system, interactable, character_state, world_state)
	hud.append_log(hud_log_presenter.format_device_panel_opened_log(interactable.definition_id))
	_update_hud()


func _on_player_module_toggle_requested() -> void:
	var module_id := "equipment.filter_module_t1"
	if String(character_state.equipment.get("suit_module", "")) == module_id:
		hud.append_log(hud_log_presenter.format_filter_module_already_enabled_log(_mark_pollution_edge_ready()))
		_update_hud()
		return
	if not character_state.equip_suit_module(module_id):
		hud.append_log(hud_log_presenter.format_filter_module_missing_log())
		_update_hud()
		return

	hud.append_log(hud_log_presenter.format_filter_module_enabled_log(_mark_pollution_edge_ready()))
	_update_hud()


func _on_player_quick_slot_requested(slot_index: int) -> void:
	var result := character_state.use_quick_slot(slot_index, data_registry)
	hud.append_log(String(result.get("message", "")))
	hud_feedback_presenter.show_supply_feedback(result, hud)
	_update_hud()


func _on_player_save_requested() -> void:
	_save_to_slot(SaveService.DEFAULT_SLOT_ID)


func _on_player_load_requested() -> void:
	_load_from_slot(SaveService.DEFAULT_SLOT_ID)


func _on_hud_save_slot_requested(slot_id: String) -> void:
	_save_to_slot(slot_id)


func _on_hud_load_slot_requested(slot_id: String) -> void:
	_load_from_slot(slot_id)


func _on_hud_delete_slot_requested(slot_id: String) -> void:
	var result := save_service.delete_game_for_slot(slot_id)
	hud.append_log(hud_log_presenter.format_slot_result_log(slot_id, result))
	_refresh_save_slot_summaries()
	_update_hud()


func _on_hud_new_game_requested() -> void:
	_start_new_game()


func _on_hud_quick_slot_binding_requested(slot_index: int, item_id: String) -> void:
	var result := character_state.bind_quick_slot(slot_index, item_id, data_registry)
	hud.append_log(String(result.get("message", "")))
	_update_hud()


func _on_hud_development_baseline_requested(baseline_id: String) -> void:
	var result := create_development_baseline_state(baseline_id)
	if not bool(result.get("success", false)):
		hud.append_log(hud_log_presenter.format_result_log(result))
		_update_hud()
		return

	world_state = result.get("world_state", WorldState.create_default())
	character_state = result.get("character_state", CharacterState.create_default())
	vertical_slice_map.apply_runtime_state(world_state, character_state)
	_sync_world_camera()
	hud.clear_runtime_feedback()
	hud.append_log(hud_log_presenter.format_result_log(result))
	_refresh_save_slot_summaries()
	_update_hud()


func _on_hud_gm_resource_adjust_requested(definition_id: String, delta: float) -> void:
	var result := _apply_gm_resource_delta(definition_id, delta)
	hud.append_log(String(result.get("message", "")))
	_update_hud()


func _on_hud_gm_vitals_refill_requested() -> void:
	var result := _apply_gm_vitals_refill()
	hud.append_log(String(result.get("message", "")))
	_update_hud()


func _save_to_slot(slot_id: String) -> void:
	character_state.position = vertical_slice_map.get_player_position()
	var result := save_service.save_game_for_slot(slot_id, world_state, character_state)
	hud.append_log(hud_log_presenter.format_slot_result_log(slot_id, result))
	_refresh_save_slot_summaries()
	_update_hud()


func _load_from_slot(slot_id: String) -> void:
	var result := save_service.load_game_for_slot(slot_id)
	if not bool(result.get("success", false)):
		hud.append_log(hud_log_presenter.format_slot_result_log(slot_id, result))
		_refresh_save_slot_summaries()
		_update_hud()
		return

	world_state = result.get("world_state", WorldState.create_default())
	character_state = result.get("character_state", CharacterState.create_default())
	vertical_slice_map.apply_runtime_state(world_state, character_state)
	_sync_world_camera()
	hud.append_log(hud_log_presenter.format_slot_result_log(slot_id, result))
	_refresh_save_slot_summaries()
	_update_hud()


func _start_new_game() -> void:
	var new_state := create_new_game_state()
	world_state = new_state.get("world_state", WorldState.create_default())
	character_state = new_state.get("character_state", CharacterState.create_default())
	vertical_slice_map.apply_runtime_state(world_state, character_state)
	_sync_world_camera()
	hud.clear_runtime_feedback()
	hud.append_log(hud_log_presenter.format_new_game_log())
	_refresh_save_slot_summaries()
	_update_hud()


func create_new_game_state() -> Dictionary:
	return {
		"world_state": WorldState.create_default(),
		"character_state": CharacterState.create_default()
	}


func create_development_baseline_state(baseline_id: String) -> Dictionary:
	if development_baseline_builder == null:
		return {
			"success": false,
			"message": "开发基线生成器尚未初始化。"
		}
	return development_baseline_builder.create_baseline_state(baseline_id)


func _on_interaction_available(interactable: PrototypeInteractable, should_auto_select_recipe: bool = true) -> void:
	if interactable.interaction_type == "outpost_core":
		hud.show_prompt(interaction_prompt_formatter.format_outpost_core_prompt(world_state, character_state))
		return
	if interactable.definition_id == "map_object.ruin_gate":
		hud.show_prompt(interaction_prompt_formatter.format_ruin_gate_prompt(world_state))
		return
	if interactable.definition_id == "map_object.outer_ring_barrier":
		hud.show_prompt(interaction_prompt_formatter.format_outer_ring_barrier_prompt(world_state, character_state))
		return
	if interactable.definition_id == "map_object.outer_ring_console":
		hud.show_prompt(interaction_prompt_formatter.format_outer_ring_console_prompt(world_state))
		return
	if interactable.definition_id == "map_object.signal_echo_cache":
		hud.show_prompt(interaction_prompt_formatter.format_signal_echo_cache_prompt(world_state))
		return
	if interactable.definition_id == "map_object.deep_ruin_door":
		hud.show_prompt(interaction_prompt_formatter.format_deep_ruin_door_prompt(world_state, character_state))
		return
	if interactable.definition_id == "map_object.deep_ruin_latch":
		hud.show_prompt(interaction_prompt_formatter.format_deep_ruin_latch_prompt(world_state, character_state))
		return
	if interactable.definition_id == "map_object.deep_signal_array":
		hud.show_prompt(interaction_prompt_formatter.format_deep_signal_array_prompt(world_state, character_state))
		return
	if interactable.definition_id == "map_object.phase_return_anchor":
		hud.show_prompt(interaction_prompt_formatter.format_phase_return_anchor_prompt(
			world_state,
			character_state,
			interactable.instance_id
		))
		return
	if interactable.definition_id == "map_object.phase_relay_pad":
		hud.show_prompt(interaction_prompt_formatter.format_phase_relay_pad_prompt(world_state))
		return
	if interactable.definition_id == "map_object.phase_fault_spire":
		hud.show_prompt(interaction_prompt_formatter.format_phase_fault_spire_prompt(world_state, character_state))
		return
	if interactable.definition_id == "map_object.phase_well_lock":
		hud.show_prompt(interaction_prompt_formatter.format_phase_well_lock_prompt(world_state, character_state))
		return
	if interactable.definition_id == "map_object.inner_phase_well":
		hud.show_prompt(interaction_prompt_formatter.format_inner_phase_well_prompt(world_state, character_state))
		return
	if interactable.definition_id == "map_object.phase_well_sink":
		hud.show_prompt(interaction_prompt_formatter.format_phase_well_sink_prompt(world_state, character_state))
		return
	if interactable.definition_id == "map_object.phase_well_chamber":
		hud.show_prompt(interaction_prompt_formatter.format_phase_well_chamber_prompt(world_state, character_state))
		return
	if interactable.definition_id == "map_object.phase_well_loom":
		hud.show_prompt(interaction_prompt_formatter.format_phase_well_loom_prompt(world_state, character_state))
		return
	if interactable.definition_id == "map_object.phase_well_frame":
		hud.show_prompt(interaction_prompt_formatter.format_phase_well_frame_prompt(world_state, character_state))
		return
	if interactable.definition_id == "map_object.phase_well_tether":
		hud.show_prompt(interaction_prompt_formatter.format_phase_well_tether_prompt(world_state, character_state))
		return
	if interactable.interaction_type == "process_recipe":
		var auto_selected_recipe := _maybe_select_recommended_recipe(interactable, should_auto_select_recipe)
		hud.show_prompt(interaction_prompt_formatter.format_processing_prompt(interactable, character_state, world_state))
		hud.refresh_device_panel(data_registry, processing_system, interactable, character_state, world_state)
		if not auto_selected_recipe.is_empty():
			hud.append_log(hud_log_presenter.format_recommended_recipe_selected_log(auto_selected_recipe))
		return
	if interactable.interaction_type == "build":
		hud.show_prompt(interaction_prompt_formatter.format_build_prompt(interactable, character_state, world_state))
		return
	if interactable.interaction_type == "clear":
		hud.show_prompt(interaction_prompt_formatter.format_clear_prompt(interactable, character_state, world_state))
		return

	hud.show_prompt("按 E 交互：%s" % _get_display_name(interactable.definition_id))


func _on_interaction_cleared(_interactable: PrototypeInteractable) -> void:
	hud.clear_prompt()
	hud.hide_device_panel()


func _on_region_changed(region_id: String) -> void:
	var log_messages: Array[String] = [hud_log_presenter.format_region_entered_log(region_id)]
	if region_id == "region.pollution_edge":
		var warning := interaction_prompt_formatter.format_pollution_entry_warning(character_state)
		if not warning.is_empty():
			log_messages.append(warning)
	_append_quest_runtime_result(log_messages, quest_runtime.advance_for_region(world_state, character_state, region_id))
	hud.append_log(hud_log_presenter.join_messages(log_messages))
	_update_hud()


func _on_region_gate_blocked(message: String) -> void:
	if message.find("污染边界") >= 0:
		hud.append_log(interaction_prompt_formatter.format_region_gate_blocked_log(
			message,
			interaction_prompt_formatter.format_pollution_gate_hint(world_state, character_state)
		))
	elif message.find("抖动雾幕") >= 0:
		hud.append_log(interaction_prompt_formatter.format_region_gate_blocked_log(
			message,
			"需要：回基地用基础反应器组装稳相信标。"
		))
	elif message.find("深段入口") >= 0:
		hud.append_log(interaction_prompt_formatter.format_region_gate_blocked_log(
			message,
			"需要：回基地解析深段回波，带着更深遗迹坐标回来写入门禁。"
		))
	elif message.find("内层相位井") >= 0:
		hud.append_log(interaction_prompt_formatter.format_region_gate_blocked_log(
			message,
			"需要：先回基地解析定位器，确认更东侧内层相位井路由。"
		))
	elif message.find("井底裂口") >= 0:
		hud.append_log(interaction_prompt_formatter.format_region_gate_blocked_log(
			message,
			"需要：先回基地解析井芯样本，再组装井底穿钉回来凿开裂口。"
		))
	elif message.find("井心室") >= 0:
		hud.append_log(interaction_prompt_formatter.format_region_gate_blocked_log(
			message,
			"需要：先回基地解析相位井心核，再组装井心分流栓回来勘验断面。"
		))
	elif message.find("井纺室") >= 0:
		hud.append_log(interaction_prompt_formatter.format_region_gate_blocked_log(
			message,
			"需要：先回基地解析相位井纺核，再组装井纺梭栓回来勘验断面。"
		))
	elif message.find("井纹架") >= 0:
		hud.append_log(interaction_prompt_formatter.format_region_gate_blocked_log(
			message,
			"需要：先回基地解析相位井织核，再组装井纹架键栓回来勘验断面。"
		))
	elif message.find("井系桥") >= 0:
		hud.append_log(interaction_prompt_formatter.format_region_gate_blocked_log(
			message,
			"需要：先回基地解析相位井结核，再组装井系定桩回来勘验断面。"
		))
	elif message.find("遗迹外圈") >= 0:
		hud.append_log(interaction_prompt_formatter.format_region_gate_blocked_log(
			message,
			"需要：先检查封锁遗迹入口，确认外圈通路。"
		))
	else:
		hud.append_log(interaction_prompt_formatter.format_region_gate_blocked_log(message, "需要：先检查前哨核心。"))
	_update_hud()


func _update_hud() -> void:
	hud.update_status(data_registry, world_state, character_state)
	hud.refresh_device_panel(
		data_registry,
		processing_system,
		vertical_slice_map.current_interactable,
		character_state,
		world_state
	)


func _refresh_save_slot_summaries() -> void:
	hud.update_save_slot_summaries(save_service.get_save_slot_summaries(PrototypeHud.SAVE_SLOT_IDS))


func _configure_world_camera() -> void:
	if world_camera == null:
		return
	world_camera.make_current()
	var bounds := vertical_slice_map.get_camera_bounds_rect_global()
	world_camera.limit_left = int(floor(bounds.position.x))
	world_camera.limit_top = int(floor(bounds.position.y))
	world_camera.limit_right = int(ceil(bounds.position.x + bounds.size.x))
	world_camera.limit_bottom = int(ceil(bounds.position.y + bounds.size.y))


func _sync_world_camera() -> void:
	if world_camera == null:
		return
	world_camera.position = vertical_slice_map.get_camera_focus_global_position()


func _get_display_name(definition_id: String) -> String:
	if definition_id.is_empty():
		return ""

	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id

	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))


func _get_current_interaction_context() -> Dictionary:
	var interactable := vertical_slice_map.current_interactable
	if interactable == null:
		return {}

	return {
		"definition_id": interactable.definition_id,
		"interaction_type": interactable.interaction_type,
		"recipe_id": interactable.get_current_recipe_id()
	}


func _apply_processing_progress(delta: float) -> void:
	var completed_results := processing_system.advance_processing(delta, character_state, world_state)
	for result in completed_results:
		var recipe_id := String(result.get("completed_recipe_id", ""))
		var log_messages: Array[String] = [String(result.get("message", ""))]
		_append_quest_runtime_result(
			log_messages,
			quest_runtime.advance_for_interaction(
				world_state,
				character_state,
				{
					"definition_id": String(data_registry.get_definition(recipe_id).get("required_building_id", "")),
					"interaction_type": "process_recipe",
					"recipe_id": recipe_id
				},
				result
			)
		)
		hud.append_log(hud_log_presenter.join_messages(log_messages))


func _reconcile_active_quest_state() -> void:
	var result := quest_runtime.reconcile_active_objectives(world_state, character_state)
	if not bool(result.get("accepted", false)):
		return
	var log_messages: Array[String] = []
	_append_quest_runtime_result(log_messages, result)
	if log_messages.is_empty():
		return
	hud.append_log(hud_log_presenter.join_messages(log_messages))


func _refresh_current_context_prompt() -> void:
	var interactable := vertical_slice_map.current_interactable
	if interactable == null:
		return
	if interactable.interaction_type == "outpost_core":
		hud.show_prompt(interaction_prompt_formatter.format_outpost_core_prompt(world_state, character_state))
		return
	if interactable.definition_id == "map_object.ruin_gate":
		hud.show_prompt(interaction_prompt_formatter.format_ruin_gate_prompt(world_state))
		return
	if interactable.definition_id == "map_object.outer_ring_barrier":
		hud.show_prompt(interaction_prompt_formatter.format_outer_ring_barrier_prompt(world_state, character_state))
		return
	if interactable.definition_id == "map_object.outer_ring_console":
		hud.show_prompt(interaction_prompt_formatter.format_outer_ring_console_prompt(world_state))
		return
	if interactable.definition_id == "map_object.signal_echo_cache":
		hud.show_prompt(interaction_prompt_formatter.format_signal_echo_cache_prompt(world_state))
		return
	if interactable.definition_id == "map_object.deep_ruin_door":
		hud.show_prompt(interaction_prompt_formatter.format_deep_ruin_door_prompt(world_state, character_state))
		return
	if interactable.definition_id == "map_object.deep_ruin_latch":
		hud.show_prompt(interaction_prompt_formatter.format_deep_ruin_latch_prompt(world_state, character_state))
		return
	if interactable.definition_id == "map_object.deep_signal_array":
		hud.show_prompt(interaction_prompt_formatter.format_deep_signal_array_prompt(world_state, character_state))
		return
	if interactable.definition_id == "map_object.phase_return_anchor":
		hud.show_prompt(interaction_prompt_formatter.format_phase_return_anchor_prompt(
			world_state,
			character_state,
			interactable.instance_id
		))
		return
	if interactable.definition_id == "map_object.phase_relay_pad":
		hud.show_prompt(interaction_prompt_formatter.format_phase_relay_pad_prompt(world_state))
		return
	if interactable.definition_id == "map_object.phase_fault_spire":
		hud.show_prompt(interaction_prompt_formatter.format_phase_fault_spire_prompt(world_state, character_state))
		return
	if interactable.definition_id == "map_object.phase_well_lock":
		hud.show_prompt(interaction_prompt_formatter.format_phase_well_lock_prompt(world_state, character_state))
		return
	if interactable.definition_id == "map_object.inner_phase_well":
		hud.show_prompt(interaction_prompt_formatter.format_inner_phase_well_prompt(world_state, character_state))
		return
	if interactable.definition_id == "map_object.phase_well_sink":
		hud.show_prompt(interaction_prompt_formatter.format_phase_well_sink_prompt(world_state, character_state))
		return
	if interactable.definition_id == "map_object.phase_well_chamber":
		hud.show_prompt(interaction_prompt_formatter.format_phase_well_chamber_prompt(world_state, character_state))
		return
	if interactable.definition_id == "map_object.phase_well_loom":
		hud.show_prompt(interaction_prompt_formatter.format_phase_well_loom_prompt(world_state, character_state))
		return
	if interactable.definition_id == "map_object.phase_well_frame":
		hud.show_prompt(interaction_prompt_formatter.format_phase_well_frame_prompt(world_state, character_state))
		return
	if interactable.definition_id == "map_object.phase_well_tether":
		hud.show_prompt(interaction_prompt_formatter.format_phase_well_tether_prompt(world_state, character_state))
		return
	if interactable.interaction_type == "process_recipe":
		_maybe_select_followup_recipe(interactable)
		hud.show_prompt(interaction_prompt_formatter.format_processing_prompt(interactable, character_state, world_state))
		hud.refresh_device_panel(data_registry, processing_system, interactable, character_state, world_state)
	if interactable.interaction_type == "build":
		hud.show_prompt(interaction_prompt_formatter.format_build_prompt(interactable, character_state, world_state))
	if interactable.interaction_type == "clear":
		hud.show_prompt(interaction_prompt_formatter.format_clear_prompt(interactable, character_state, world_state))


func _should_advance_interaction(context: Dictionary, result: Dictionary) -> bool:
	if String(context.get("interaction_type", "")) == "process_recipe":
		return result.has("completed_recipe_id")
	return true


func _mark_pollution_edge_ready() -> bool:
	var result := quest_runtime.advance_pollution_edge_ready(world_state, character_state)
	_show_quest_completion_feedbacks(result)
	return bool(result.get("accepted", false))


func _select_recommended_recipe(interactable: PrototypeInteractable) -> String:
	if interactable == null or interactable.interaction_type != "process_recipe":
		return ""
	var recipe_id := processing_system.get_recommended_recipe_id(interactable, character_state, world_state)
	if recipe_id.is_empty():
		return ""
	if recipe_id == interactable.get_current_recipe_id():
		return ""
	if not interactable.select_recipe(recipe_id):
		return ""
	return recipe_id


func _maybe_select_recommended_recipe(interactable: PrototypeInteractable, should_auto_select_recipe: bool) -> String:
	if not should_auto_select_recipe:
		return ""
	return _select_recommended_recipe(interactable)


func _maybe_select_followup_recipe(interactable: PrototypeInteractable) -> String:
	if interactable == null or interactable.interaction_type != "process_recipe":
		return ""

	var structure_id := world_state.get_base_structure_id_for_definition(interactable.definition_id)
	if structure_id.is_empty():
		return ""

	var structure: Dictionary = world_state.base_structures.get(structure_id, {})
	if String(structure.get("status", "")) != "completed":
		return ""
	if String(structure.get("last_recipe_id", "")) != interactable.get_current_recipe_id():
		return ""
	return _select_recommended_recipe(interactable)


func _append_quest_runtime_result(log_messages: Array[String], result: Dictionary) -> void:
	_show_quest_completion_feedbacks(result)
	for message in result.get("log_messages", []):
		var text := String(message)
		if text.strip_edges().is_empty():
			continue
		log_messages.append(text)


func _show_quest_completion_feedbacks(result: Dictionary) -> void:
	for feedback in result.get("completion_feedbacks", []):
		if not feedback is Dictionary:
			continue
		hud.show_quest_completion(feedback)


func _apply_gm_resource_delta(definition_id: String, delta: float) -> Dictionary:
	if definition_id.is_empty():
		return {
			"success": false,
			"message": "GM：未选择要调整的资源。"
		}
	if data_registry.get_definition(definition_id).is_empty():
		return {
			"success": false,
			"message": "GM：未知资源 %s。" % definition_id
		}
	if is_zero_approx(delta):
		return {
			"success": false,
			"message": "GM：资源数量未变化。"
		}

	if delta > 0.0:
		character_state.inventory.add_ref(definition_id, delta)
	else:
		character_state.inventory.consume_ref(definition_id, absf(delta))
	return {
		"success": true,
		"message": "GM：%s %s%s，当前 %s。" % [
			_get_display_name(definition_id),
			"+" if delta > 0.0 else "-",
			_format_amount(absf(delta)),
			_format_inventory_amount(definition_id)
		]
	}


func _apply_gm_vitals_refill() -> Dictionary:
	var restoration := character_state.restore_vitals_to_full()
	var restored_health := float(restoration.get("restored_health", 0.0))
	var restored_protection := float(restoration.get("restored_protection", 0.0))
	if restored_health <= 0.0 and restored_protection <= 0.0:
		return {
			"success": true,
			"message": "GM：生命与防护已满。"
		}

	var parts: Array[String] = []
	if restored_health > 0.0:
		parts.append("生命 +%s" % _format_amount(restored_health))
	if restored_protection > 0.0:
		parts.append("防护 +%s" % _format_amount(restored_protection))
	return {
		"success": true,
		"message": "GM：%s。" % "，".join(parts)
	}


func _format_inventory_amount(definition_id: String) -> String:
	if definition_id.begins_with("fluid."):
		return _format_amount(float(character_state.inventory.fluids.get(definition_id, 0.0)))
	if definition_id.begins_with("equipment."):
		return str(int(character_state.inventory.equipment.get(definition_id, 0)))
	return str(int(character_state.inventory.items.get(definition_id, 0)))


func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount
