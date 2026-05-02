extends Node2D

var data_registry: DataRegistry
var world_state: WorldState
var character_state: CharacterState
var save_service := SaveService.new()
var processing_system: ProcessingSystem
var build_system: BuildSystem
var quest_runtime: QuestRuntime

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
	vertical_slice_map.setup(data_registry)
	vertical_slice_map.sync_enemy_states(world_state)
	vertical_slice_map.refresh_world_interactables(world_state)
	vertical_slice_map.player.interaction_requested.connect(_on_player_interaction_requested)
	vertical_slice_map.player.attack_requested.connect(_on_player_attack_requested)
	vertical_slice_map.player.recipe_cycle_requested.connect(_on_player_recipe_cycle_requested)
	vertical_slice_map.player.module_toggle_requested.connect(_on_player_module_toggle_requested)
	vertical_slice_map.player.quick_slot_requested.connect(_on_player_quick_slot_requested)
	vertical_slice_map.player.save_requested.connect(_on_player_save_requested)
	vertical_slice_map.player.load_requested.connect(_on_player_load_requested)
	hud.save_slot_requested.connect(_on_hud_save_slot_requested)
	hud.load_slot_requested.connect(_on_hud_load_slot_requested)
	hud.quick_slot_binding_requested.connect(_on_hud_quick_slot_binding_requested)
	vertical_slice_map.interaction_available.connect(_on_interaction_available)
	vertical_slice_map.interaction_cleared.connect(_on_interaction_cleared)
	vertical_slice_map.region_changed.connect(_on_region_changed)
	vertical_slice_map.region_gate_blocked.connect(_on_region_gate_blocked)

	hud.append_log("前哨原型已启动。WASD 移动，E 交互，J 攻击，R 切换设备配方，F 启用过滤模块，1/2 使用快捷栏；左侧面板可保存 / 读取 3 个原型槽位，K / L 仍操作默认槽位。先检查前哨核心。")
	_refresh_save_slot_summaries()
	_update_hud()


func _process(delta: float) -> void:
	if world_state == null or character_state == null:
		return
	_apply_processing_progress(delta)
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
	_show_evacuation_feedback(result)
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
	_show_evacuation_feedback(result)
	hud.append_log(_join_log_messages(log_messages))
	_update_hud()


func _on_player_recipe_cycle_requested() -> void:
	var result := vertical_slice_map.try_cycle_recipe()
	if bool(result.get("success", false)) and vertical_slice_map.current_interactable != null:
		hud.append_log(_format_processing_log(vertical_slice_map.current_interactable.get_current_recipe_id()))
		_on_interaction_available(vertical_slice_map.current_interactable)
	else:
		hud.append_log(_format_result_log(result))
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
	_show_supply_feedback(result)
	_update_hud()


func _on_player_save_requested() -> void:
	_save_to_slot(SaveService.DEFAULT_SLOT_ID)


func _on_player_load_requested() -> void:
	_load_from_slot(SaveService.DEFAULT_SLOT_ID)


func _on_hud_save_slot_requested(slot_id: String) -> void:
	_save_to_slot(slot_id)


func _on_hud_load_slot_requested(slot_id: String) -> void:
	_load_from_slot(slot_id)


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


func _on_interaction_available(interactable: PrototypeInteractable) -> void:
	if interactable.definition_id == "map_object.ruin_gate":
		hud.show_prompt(_format_ruin_gate_prompt())
		return
	if interactable.interaction_type == "process_recipe":
		hud.show_prompt(_format_processing_prompt(interactable))
		return
	if interactable.interaction_type == "build":
		hud.show_prompt(_format_build_prompt(interactable))
		return
	if interactable.interaction_type == "clear":
		hud.show_prompt(_format_clear_prompt(interactable))
		return

	hud.show_prompt("按 E 交互：%s" % _get_display_name(interactable.definition_id))


func _on_interaction_cleared(_interactable: PrototypeInteractable) -> void:
	hud.clear_prompt()


func _on_region_changed(region_id: String) -> void:
	var log_messages: Array[String] = ["已进入：%s。" % _get_display_name(region_id)]
	if region_id == "region.pollution_edge":
		var warning := _get_pollution_entry_warning()
		if not warning.is_empty():
			log_messages.append(warning)
	_append_quest_runtime_result(log_messages, quest_runtime.advance_for_region(world_state, character_state, region_id))
	hud.append_log(_join_log_messages(log_messages))
	_update_hud()


func _on_region_gate_blocked(message: String) -> void:
	if message.find("污染边界") >= 0:
		hud.append_log(_format_region_gate_blocked_log(message, _get_pollution_gate_hint()))
	else:
		hud.append_log(_format_region_gate_blocked_log(message, "需要：先检查前哨核心。"))
	_update_hud()


func _update_hud() -> void:
	hud.update_status(data_registry, world_state, character_state)


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


func _format_processing_prompt(interactable: PrototypeInteractable) -> String:
	var recipe_id := interactable.get_current_recipe_id()
	var status := processing_system.get_recipe_status(recipe_id, character_state, world_state)
	var parts: Array[String] = [
		"设备：%s" % _get_display_name(interactable.definition_id),
		"配方：%s" % _get_display_name(recipe_id)
	]
	if interactable.get_recipe_count() > 1:
		parts[1] = "%s；R 切换（%d/%d）" % [
			parts[1],
			interactable.get_recipe_position(),
			interactable.get_recipe_count()
		]

	parts.append("输入：%s" % String(status.get("inputs", "无")))
	parts.append("产出：%s" % String(status.get("outputs", "无")))
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
	parts.append("状态：%s" % String(status.get("message", "")))
	if bool(status.get("can_process", false)):
		parts.append("按 E 启动加工")
	return "\n".join(parts)


func _format_processing_log(recipe_id: String) -> String:
	var status := processing_system.get_recipe_status(recipe_id, character_state, world_state)
	return "%s：%s 输入：%s；产出：%s；耗时：%s 秒。" % [
		_get_display_name(recipe_id),
		String(status.get("message", "")),
		String(status.get("inputs", "无")),
		String(status.get("outputs", "无")),
		String(status.get("duration", "0"))
	]


func _format_build_prompt(interactable: PrototypeInteractable) -> String:
	var status := build_system.get_build_status(
		interactable.instance_id,
		interactable.definition_id,
		character_state,
		world_state,
		interactable.prerequisite_instance_id
	)
	var parts: Array[String] = [
		"建造点：%s" % _get_display_name(interactable.definition_id),
		"材料：%s" % String(status.get("costs", "无"))
	]
	var foundation_status := String(status.get("foundation_status", ""))
	if not foundation_status.is_empty():
		parts.append(foundation_status)
	parts.append("状态：%s" % String(status.get("message", "")))
	if bool(status.get("can_build", false)):
		parts.append("按 E 建造")
	return "\n".join(parts)


func _format_clear_prompt(interactable: PrototypeInteractable) -> String:
	var object_state := world_state.get_map_object(interactable.instance_id)
	if bool(object_state.get("is_cleared", false)):
		return "地块：%s\n状态：已清理，可用于铺设基础地基。" % _get_display_name(interactable.definition_id)

	var tool_status := _get_interaction_tool_status(interactable.definition_id)
	var parts: Array[String] = [
		"地块：%s" % _get_display_name(interactable.definition_id),
		"状态：未清理，阻挡建造。",
		"后续：清理后可铺设基础地基。",
		"工具：%s" % tool_status
	]
	if tool_status == "可清理":
		parts.append("按 E 清理地块")
	return "\n".join(parts)


func _format_ruin_gate_prompt() -> String:
	if not world_state.quest_state.has_completed_quest("quest.enter_pollution_edge"):
		return "封锁遗迹入口：先治理污染边界，再确认更深区域信号。"
	if world_state.quest_state.has_completed_quest("quest.unlock_ruin_signal"):
		return "切片结尾：更深区域信号已确认，后续内容待开放。"
	return "按 E 确认：封锁遗迹入口信号。"


func _get_pollution_entry_warning() -> String:
	var warnings: Array[String] = []
	if character_state.protection < character_state.max_protection * 0.5:
		warnings.append("防护偏低，建议先按 2 使用抗污染药剂或返回基地补给。")
	if String(character_state.equipment.get("suit_module", "")).is_empty():
		warnings.append("未启用过滤模块，按 F 启用后污染消耗会降低。")
	if warnings.is_empty():
		return ""
	return "污染边界警告：%s" % " ".join(warnings)


func _get_pollution_gate_hint() -> String:
	var missing_steps: Array[String] = []
	if not world_state.quest_state.has_completed_quest("quest.expand_treatment_point"):
		missing_steps.append("先完成处理点扩建")
	if String(character_state.equipment.get("suit_module", "")).is_empty():
		missing_steps.append("按 F 启用基础过滤模块")
	if character_state.protection < character_state.max_protection * 0.5:
		missing_steps.append("按 2 使用抗污染药剂或回基地补给")
	if missing_steps.is_empty():
		return "重新靠近边界后会再次检查通行状态。"
	return "需要：%s。" % "；".join(missing_steps)


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


func _format_region_gate_blocked_log(message: String, next_step: String) -> String:
	if next_step.strip_edges().is_empty():
		return "通行受阻：%s" % message
	return "通行受阻：%s 下一步：%s" % [message, next_step]


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


func _refresh_current_context_prompt() -> void:
	var interactable := vertical_slice_map.current_interactable
	if interactable == null:
		return
	if interactable.interaction_type == "process_recipe":
		hud.show_prompt(_format_processing_prompt(interactable))
	if interactable.interaction_type == "build":
		hud.show_prompt(_format_build_prompt(interactable))
	if interactable.interaction_type == "clear":
		hud.show_prompt(_format_clear_prompt(interactable))


func _should_advance_interaction(context: Dictionary, result: Dictionary) -> bool:
	if String(context.get("interaction_type", "")) == "process_recipe":
		return result.has("completed_recipe_id")
	return true


func _mark_pollution_edge_ready() -> bool:
	var result := quest_runtime.advance_pollution_edge_ready(world_state, character_state)
	_show_quest_completion_feedbacks(result)
	return bool(result.get("accepted", false))


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


func _show_evacuation_feedback(result: Dictionary) -> void:
	var feedback = result.get("evacuation_feedback", {})
	if feedback is Dictionary and not feedback.is_empty():
		hud.show_evacuation_feedback(feedback)


func _show_supply_feedback(result: Dictionary) -> void:
	var feedback = result.get("supply_feedback", {})
	if feedback is Dictionary and not feedback.is_empty():
		hud.show_supply_feedback(feedback)


func _get_interaction_tool_status(definition_id: String) -> String:
	var definition := data_registry.get_definition(definition_id)
	var required_tool_tags: Array = definition.get("required_tool_tags", [])
	if required_tool_tags.is_empty():
		return "无特殊要求"

	var tool_id := String(character_state.equipment.get("tool", ""))
	var tool_definition := data_registry.get_definition(tool_id)
	var tool_effects: Array = tool_definition.get("effects", [])
	var missing_tags: Array[String] = []
	for required_tool_tag in required_tool_tags:
		var tag := String(required_tool_tag)
		if tool_effects.has("effect.%s" % tag) or tool_effects.has(tag):
			continue
		missing_tags.append(tag)

	if missing_tags.is_empty():
		return "可清理"
	return "缺少能力：%s" % ", ".join(missing_tags)


func _join_log_messages(messages: Array[String]) -> String:
	var clean_messages: Array[String] = []
	for message in messages:
		if message.strip_edges().is_empty():
			continue
		clean_messages.append(message)
	return " ".join(clean_messages)
