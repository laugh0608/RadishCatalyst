extends Node2D

var data_registry: DataRegistry
var world_state: WorldState
var character_state: CharacterState
var save_service := SaveService.new()
var processing_system: ProcessingSystem
var quest_event_rules: QuestEventRules
var quest_progress_rules: QuestProgressRules
var quest_completion_rules: QuestCompletionRules

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
	quest_event_rules = QuestEventRules.new(data_registry)
	quest_progress_rules = QuestProgressRules.new(data_registry)
	quest_completion_rules = QuestCompletionRules.new(data_registry, quest_progress_rules)
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
	vertical_slice_map.interaction_available.connect(_on_interaction_available)
	vertical_slice_map.interaction_cleared.connect(_on_interaction_cleared)
	vertical_slice_map.region_changed.connect(_on_region_changed)
	vertical_slice_map.region_gate_blocked.connect(_on_region_gate_blocked)

	hud.append_log("前哨原型已启动。WASD 移动，E 交互，J 攻击，R 切换设备配方，F 启用过滤模块，1/2 使用快捷栏；左侧面板可保存 / 读取 3 个原型槽位，K / L 仍操作默认槽位。先检查前哨核心。")
	_refresh_save_slot_summaries()
	_update_hud()


func _process(_delta: float) -> void:
	if world_state == null or character_state == null:
		return
	vertical_slice_map.update_current_interactable()
	vertical_slice_map.update_region_presence(world_state, character_state)
	character_state.position = vertical_slice_map.get_player_position()
	_update_hud()


func _on_player_interaction_requested() -> void:
	var context := _get_current_interaction_context()
	var result := vertical_slice_map.try_interact(character_state, world_state)
	var log_messages: Array[String] = [String(result.get("message", ""))]
	if bool(result.get("success", false)):
		log_messages.append_array(_advance_quest_for_interaction(context, result))
	vertical_slice_map.refresh_world_interactables(world_state)
	if vertical_slice_map.current_interactable != null:
		_on_interaction_available(vertical_slice_map.current_interactable)
	hud.append_log(_join_log_messages(log_messages))
	_update_hud()


func _on_player_attack_requested() -> void:
	var result := vertical_slice_map.try_attack(character_state, world_state)
	var log_messages: Array[String] = [String(result.get("message", ""))]
	if bool(result.get("success", false)) and bool(result.get("enemy_defeated", false)):
		log_messages.append_array(_advance_quest_for_defeated_enemy(String(result.get("enemy_definition_id", ""))))
	hud.append_log(_join_log_messages(log_messages))
	_update_hud()


func _on_player_recipe_cycle_requested() -> void:
	var result := vertical_slice_map.try_cycle_recipe()
	if bool(result.get("success", false)) and vertical_slice_map.current_interactable != null:
		hud.append_log(_format_processing_log(vertical_slice_map.current_interactable.get_current_recipe_id()))
		_on_interaction_available(vertical_slice_map.current_interactable)
	else:
		hud.append_log(String(result.get("message", "")))
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
	_update_hud()


func _on_player_save_requested() -> void:
	_save_to_slot(SaveService.DEFAULT_SLOT_ID)


func _on_player_load_requested() -> void:
	_load_from_slot(SaveService.DEFAULT_SLOT_ID)


func _on_hud_save_slot_requested(slot_id: String) -> void:
	_save_to_slot(slot_id)


func _on_hud_load_slot_requested(slot_id: String) -> void:
	_load_from_slot(slot_id)


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
		hud.show_prompt("按 E 建造：%s" % _get_display_name(interactable.definition_id))
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
	log_messages.append_array(_advance_quest_for_region(region_id))
	hud.append_log(_join_log_messages(log_messages))
	_update_hud()


func _on_region_gate_blocked(message: String) -> void:
	hud.append_log(message)
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
	var parts: Array[String] = ["按 E 加工：%s" % _get_display_name(recipe_id)]
	if interactable.get_recipe_count() > 1:
		parts[0] = "%s；按 R 切换配方（%d/%d）" % [
			parts[0],
			interactable.get_recipe_position(),
			interactable.get_recipe_count()
		]

	parts.append("输入：%s" % String(status.get("inputs", "无")))
	parts.append("产出：%s" % String(status.get("outputs", "无")))
	var byproducts := String(status.get("byproducts", ""))
	if not byproducts.is_empty():
		parts.append("副产：%s" % byproducts)
	parts.append("状态：%s" % String(status.get("message", "")))
	return "\n".join(parts)


func _format_processing_log(recipe_id: String) -> String:
	var status := processing_system.get_recipe_status(recipe_id, character_state, world_state)
	return "%s：%s 输入：%s；产出：%s。" % [
		_get_display_name(recipe_id),
		String(status.get("message", "")),
		String(status.get("inputs", "无")),
		String(status.get("outputs", "无"))
	]


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


func _get_current_interaction_context() -> Dictionary:
	var interactable := vertical_slice_map.current_interactable
	if interactable == null:
		return {}

	return {
		"definition_id": interactable.definition_id,
		"interaction_type": interactable.interaction_type,
		"recipe_id": interactable.get_current_recipe_id()
	}


func _advance_quest_for_interaction(context: Dictionary, result: Dictionary) -> Array[String]:
	return _apply_quest_objective_updates(
		quest_event_rules.get_interaction_objective_updates(context, result, world_state.quest_state)
	)


func _advance_quest_for_region(region_id: String) -> Array[String]:
	return _apply_quest_objective_updates(
		quest_event_rules.get_region_objective_updates(region_id, world_state.quest_state)
	)


func _advance_quest_for_defeated_enemy(enemy_definition_id: String) -> Array[String]:
	return _apply_quest_objective_updates(
		quest_event_rules.get_defeated_enemy_objective_updates(enemy_definition_id)
	)


func _mark_pollution_edge_ready() -> bool:
	if not world_state.quest_state.has_active_quest("quest.enter_pollution_edge") and not world_state.quest_state.has_completed_quest("quest.expand_treatment_point"):
		return false

	world_state.unlock_region("region.pollution_edge")
	_apply_quest_objective_updates(quest_event_rules.get_pollution_edge_ready_updates(world_state.quest_state))
	return true


func _apply_quest_objective_updates(updates: Array[Dictionary]) -> Array[String]:
	var completion_messages: Array[String] = []
	var changed_quest_ids: Array[String] = []
	for update in updates:
		var quest_id := String(update.get("quest_id", ""))
		var objective_type := String(update.get("objective_type", ""))
		var target_id := String(update.get("target_id", ""))
		var amount := float(update.get("amount", 0.0))
		if String(update.get("mode", "set")) == "add":
			quest_progress_rules.add_active_objective_progress(world_state.quest_state, quest_id, objective_type, target_id, amount)
		else:
			quest_progress_rules.set_active_objective_progress(world_state.quest_state, quest_id, objective_type, target_id, amount)
		if not changed_quest_ids.has(quest_id):
			changed_quest_ids.append(quest_id)

	for quest_id in changed_quest_ids:
		completion_messages.append_array(_try_complete_quest(quest_id))
	return completion_messages


func _try_complete_quest(quest_id: String) -> Array[String]:
	var completion_result := quest_completion_rules.try_complete_quest(world_state.quest_state, quest_id)
	if not bool(completion_result.get("completed", false)):
		return []

	var reward_messages := _grant_refs(completion_result.get("rewards", []))
	for effect_id in completion_result.get("unlock_effects", []):
		_apply_world_unlock_effect(String(effect_id))
	var next_quest_names: Array[String] = []
	for next_quest_id in completion_result.get("next_quest_ids", []):
		var next_id := String(next_quest_id)
		next_quest_names.append(_get_display_name(next_id))
	return [_format_quest_completion_message(quest_id, reward_messages, completion_result.get("unlock_effects", []), next_quest_names)]


func _grant_refs(refs: Array) -> Array[String]:
	var reward_messages: Array[String] = []
	for ref in refs:
		if not ref is Dictionary:
			continue

		var definition_id := String(ref.get("id", ""))
		var amount := float(ref.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0:
			continue

		character_state.inventory.add_ref(definition_id, amount)
		reward_messages.append("%s x%s" % [_get_display_name(definition_id), _format_amount(amount)])
	return reward_messages


func _apply_world_unlock_effect(effect_id: String) -> void:
	if effect_id.begins_with("region."):
		world_state.unlock_region(effect_id)


func _format_quest_completion_message(
	quest_id: String,
	reward_messages: Array[String],
	unlock_effects: Array,
	next_quest_names: Array[String]
) -> String:
	var parts: Array[String] = ["任务完成：%s。" % _get_display_name(quest_id)]
	if reward_messages.is_empty():
		parts.append("奖励：无直接物资。")
	else:
		parts.append("奖励：%s。" % ", ".join(reward_messages))

	var unlock_messages := _format_unlock_effects(unlock_effects)
	if not unlock_messages.is_empty():
		parts.append("解锁：%s。" % ", ".join(unlock_messages))
	if quest_id == "quest.enter_pollution_edge":
		parts.append("污染深处 / 遗迹入口信号已标记。")
	if quest_id == "quest.unlock_ruin_signal":
		parts.append("切片结尾：更深区域信号已确认，后续内容待开放。")
	if not next_quest_names.is_empty():
		parts.append("新目标：%s。" % ", ".join(next_quest_names))
	return " ".join(parts)


func _format_unlock_effects(unlock_effects: Array) -> Array[String]:
	var unlock_messages: Array[String] = []
	for effect_id in unlock_effects:
		var id := String(effect_id)
		if id.begins_with("quest."):
			continue
		if id == "slice_01_complete":
			unlock_messages.append("第一切片完成标记")
			continue
		if id.begins_with("region.") or id.begins_with("recipe.") or id.begins_with("building.") or id.begins_with("equipment.") or id.begins_with("item."):
			unlock_messages.append(_get_display_name(id))
		else:
			unlock_messages.append(id)
	return unlock_messages


func _join_log_messages(messages: Array[String]) -> String:
	var clean_messages: Array[String] = []
	for message in messages:
		if message.strip_edges().is_empty():
			continue
		clean_messages.append(message)
	return " ".join(clean_messages)


func _format_amount(amount: float) -> String:
	if is_equal_approx(amount, roundf(amount)):
		return str(int(amount))
	return "%.1f" % amount
