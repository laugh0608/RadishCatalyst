extends Node2D

var data_registry: DataRegistry
var world_state: WorldState
var character_state: CharacterState
var save_service := SaveService.new()
var processing_system: ProcessingSystem
var build_system: BuildSystem
var quest_runtime: QuestRuntime
var interaction_prompt_formatter: InteractionPromptFormatter
var hud_feedback_presenter: HudFeedbackPresenter

@onready var vertical_slice_map: VerticalSliceMap = $VerticalSliceMap
@onready var hud: PrototypeHud = $PrototypeHud


func _ready() -> void:
	if data_registry == null:
		push_error("GameRoot requires DataRegistry before _ready().")
		return

	world_state = WorldState.create_default()
	character_state = CharacterState.create_default()
	save_service.setup(data_registry)
	processing_system = ProcessingSystem.new(data_registry)
	build_system = BuildSystem.new(data_registry)
	quest_runtime = QuestRuntime.new(data_registry)
	interaction_prompt_formatter = InteractionPromptFormatter.new(data_registry, processing_system, build_system)
	hud_feedback_presenter = HudFeedbackPresenter.new()
	vertical_slice_map.setup(data_registry)
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
	vertical_slice_map.interaction_available.connect(_on_interaction_available)
	vertical_slice_map.interaction_cleared.connect(_on_interaction_cleared)
	vertical_slice_map.region_changed.connect(_on_region_changed)
	vertical_slice_map.region_gate_blocked.connect(_on_region_gate_blocked)

	hud.append_log("前哨原型已启动。WASD 移动，E 交互，J 攻击，R 切换设备配方，Q 打开或关闭设备面板，F 启用过滤模块，1/2 使用快捷栏；K / L 操作默认槽位，Tab 显示或隐藏存档 / 快捷栏调试面板。先检查前哨核心。")
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
	_refresh_current_context_prompt()
	_update_hud()


func _on_player_interaction_requested() -> void:
	var context := _get_current_interaction_context()
	var result := vertical_slice_map.try_interact(character_state, world_state)
	var log_messages: Array[String] = [_format_result_log(result)]
	if bool(result.get("success", false)) and _should_advance_interaction(context, result):
		_append_quest_runtime_result(log_messages, quest_runtime.advance_for_interaction(world_state, character_state, context, result))
	hud_feedback_presenter.show_evacuation_feedback(result, hud)
	vertical_slice_map.refresh_world_interactables(world_state)
	if vertical_slice_map.current_interactable != null:
		_on_interaction_available(vertical_slice_map.current_interactable)
	hud.append_log(_join_log_messages(log_messages))
	_update_hud()


func _on_player_attack_requested() -> void:
	var result := vertical_slice_map.try_attack(character_state, world_state)
	var log_messages: Array[String] = [_format_result_log(result)]
	if bool(result.get("success", false)) and bool(result.get("enemy_defeated", false)):
		_append_quest_runtime_result(
			log_messages,
			quest_runtime.advance_for_defeated_enemy(world_state, character_state, String(result.get("enemy_definition_id", "")))
		)
	hud_feedback_presenter.show_evacuation_feedback(result, hud)
	hud.append_log(_join_log_messages(log_messages))
	_update_hud()


func _on_player_recipe_cycle_requested() -> void:
	var result := vertical_slice_map.try_cycle_recipe()
	if bool(result.get("success", false)) and vertical_slice_map.current_interactable != null:
		hud.append_log(interaction_prompt_formatter.format_processing_log(
			vertical_slice_map.current_interactable.get_current_recipe_id(),
			character_state,
			world_state
		))
		_on_interaction_available(vertical_slice_map.current_interactable, false)
	else:
		hud.append_log(_format_result_log(result))
	_update_hud()


func _on_player_device_panel_toggle_requested() -> void:
	var interactable := vertical_slice_map.current_interactable
	if hud.is_device_panel_visible():
		hud.hide_device_panel()
		return
	if interactable == null or interactable.interaction_type != "process_recipe":
		hud.append_log("附近没有可查看的加工设备；靠近基础反应器或污染过滤器后按 Q。")
		_update_hud()
		return

	hud.show_device_panel(data_registry, processing_system, interactable, character_state, world_state)
	hud.append_log("已打开设备面板：%s。" % _get_display_name(interactable.definition_id))
	_update_hud()


func _on_player_module_toggle_requested() -> void:
	var module_id := "equipment.filter_module_t1"
	if String(character_state.equipment.get("suit_module", "")) == module_id:
		if _mark_pollution_edge_ready():
			hud.append_log("基础过滤模块已启用，污染边界区已标记。")
		else:
			hud.append_log("基础过滤模块已启用。")
		_update_hud()
		return
	if not character_state.equip_suit_module(module_id):
		hud.append_log("背包中没有基础过滤模块，无法启用。")
		_update_hud()
		return

	if _mark_pollution_edge_ready():
		hud.append_log("已启用基础过滤模块，污染边界区已标记，污染防护消耗降低。")
	else:
		hud.append_log("已启用基础过滤模块。还需要先扩建污染处理点，才能稳定推进污染边界。")
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
	hud.append_log("%s：%s" % [_format_slot_name(slot_id), String(result.get("message", ""))])
	_refresh_save_slot_summaries()
	_update_hud()


func _on_hud_new_game_requested() -> void:
	_start_new_game()


func _on_hud_quick_slot_binding_requested(slot_index: int, item_id: String) -> void:
	var result := character_state.bind_quick_slot(slot_index, item_id, data_registry)
	hud.append_log(String(result.get("message", "")))
	_update_hud()


func _save_to_slot(slot_id: String) -> void:
	character_state.position = vertical_slice_map.get_player_position()
	var result := save_service.save_game_for_slot(slot_id, world_state, character_state)
	hud.append_log("%s：%s" % [_format_slot_name(slot_id), String(result.get("message", ""))])
	_refresh_save_slot_summaries()
	_update_hud()


func _load_from_slot(slot_id: String) -> void:
	var result := save_service.load_game_for_slot(slot_id)
	if not bool(result.get("success", false)):
		hud.append_log("%s：%s" % [_format_slot_name(slot_id), String(result.get("message", ""))])
		_refresh_save_slot_summaries()
		_update_hud()
		return

	world_state = result.get("world_state", WorldState.create_default())
	character_state = result.get("character_state", CharacterState.create_default())
	vertical_slice_map.apply_runtime_state(world_state, character_state)
	hud.append_log("%s：%s" % [_format_slot_name(slot_id), String(result.get("message", ""))])
	_refresh_save_slot_summaries()
	_update_hud()


func _start_new_game() -> void:
	var new_state := create_new_game_state()
	world_state = new_state.get("world_state", WorldState.create_default())
	character_state = new_state.get("character_state", CharacterState.create_default())
	vertical_slice_map.apply_runtime_state(world_state, character_state)
	hud.clear_runtime_feedback()
	hud.append_log("已从头开始新原型进度；当前进度尚未保存。")
	_refresh_save_slot_summaries()
	_update_hud()


func create_new_game_state() -> Dictionary:
	return {
		"world_state": WorldState.create_default(),
		"character_state": CharacterState.create_default()
	}


func _on_interaction_available(interactable: PrototypeInteractable, should_auto_select_recipe: bool = true) -> void:
	if interactable.definition_id == "map_object.ruin_gate":
		hud.show_prompt(interaction_prompt_formatter.format_ruin_gate_prompt(world_state))
		return
	if interactable.interaction_type == "process_recipe":
		var auto_selected_recipe := _maybe_select_recommended_recipe(interactable, should_auto_select_recipe)
		hud.show_prompt(interaction_prompt_formatter.format_processing_prompt(interactable, character_state, world_state))
		hud.refresh_device_panel(data_registry, processing_system, interactable, character_state, world_state)
		if not auto_selected_recipe.is_empty():
			hud.append_log("已为当前目标选中配方：%s。" % _get_display_name(auto_selected_recipe))
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
	var log_messages: Array[String] = ["已进入：%s。" % _get_display_name(region_id)]
	if region_id == "region.pollution_edge":
		var warning := interaction_prompt_formatter.format_pollution_entry_warning(character_state)
		if not warning.is_empty():
			log_messages.append(warning)
	_append_quest_runtime_result(log_messages, quest_runtime.advance_for_region(world_state, character_state, region_id))
	hud.append_log(_join_log_messages(log_messages))
	_update_hud()


func _on_region_gate_blocked(message: String) -> void:
	if message.find("污染边界") >= 0:
		hud.append_log(interaction_prompt_formatter.format_region_gate_blocked_log(
			message,
			interaction_prompt_formatter.format_pollution_gate_hint(world_state, character_state)
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


func _format_slot_name(slot_id: String) -> String:
	if slot_id.begins_with("slot_"):
		var suffix := slot_id.trim_prefix("slot_")
		if suffix.is_valid_int():
			return "槽位 %02d" % int(suffix)
	return slot_id


func _get_display_name(definition_id: String) -> String:
	if definition_id.is_empty():
		return ""

	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id

	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))


func _format_result_log(result: Dictionary) -> String:
	if bool(result.get("success", false)):
		return String(result.get("message", ""))
	return _format_failure_result_log(result)


func _format_failure_result_log(result: Dictionary) -> String:
	var message := String(result.get("message", "操作未完成。"))
	var feedback = result.get("failure_feedback", {})
	if not feedback is Dictionary or feedback.is_empty():
		return message

	var title := String(feedback.get("title", "操作未完成"))
	var detail := String(feedback.get("detail", ""))
	if detail.strip_edges().is_empty():
		return "%s：%s" % [title, message]
	return "%s：%s 下一步：%s" % [title, message, detail]


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
		hud.append_log(_join_log_messages(log_messages))


func _reconcile_active_quest_state() -> void:
	var result := quest_runtime.reconcile_active_objectives(world_state, character_state)
	if not bool(result.get("accepted", false)):
		return
	var log_messages: Array[String] = []
	_append_quest_runtime_result(log_messages, result)
	if log_messages.is_empty():
		return
	hud.append_log(_join_log_messages(log_messages))


func _refresh_current_context_prompt() -> void:
	var interactable := vertical_slice_map.current_interactable
	if interactable == null:
		return
	if interactable.interaction_type == "process_recipe":
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


func _join_log_messages(messages: Array[String]) -> String:
	var clean_messages: Array[String] = []
	for message in messages:
		if message.strip_edges().is_empty():
			continue
		clean_messages.append(message)
	return " ".join(clean_messages)
