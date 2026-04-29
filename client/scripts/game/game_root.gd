extends Node2D

var data_registry: DataRegistry
var world_state: WorldState
var character_state: CharacterState

@onready var vertical_slice_map: VerticalSliceMap = $VerticalSliceMap
@onready var hud: PrototypeHud = $PrototypeHud


func _ready() -> void:
	if data_registry == null:
		push_error("GameRoot requires DataRegistry before _ready().")
		return

	world_state = WorldState.create_default()
	character_state = CharacterState.create_default()
	vertical_slice_map.setup(data_registry)
	vertical_slice_map.sync_enemy_states(world_state)
	vertical_slice_map.refresh_world_interactables(world_state)
	vertical_slice_map.player.interaction_requested.connect(_on_player_interaction_requested)
	vertical_slice_map.player.attack_requested.connect(_on_player_attack_requested)
	vertical_slice_map.player.recipe_cycle_requested.connect(_on_player_recipe_cycle_requested)
	vertical_slice_map.player.module_toggle_requested.connect(_on_player_module_toggle_requested)
	vertical_slice_map.interaction_available.connect(_on_interaction_available)
	vertical_slice_map.interaction_cleared.connect(_on_interaction_cleared)

	hud.append_log("前哨原型已启动。WASD 移动，E 交互，J 攻击，R 切换设备配方，F 启用过滤模块。")
	_update_hud()


func _on_player_interaction_requested() -> void:
	var context := _get_current_interaction_context()
	var result := vertical_slice_map.try_interact(character_state, world_state)
	if bool(result.get("success", false)):
		_advance_quest_for_interaction(context, result)
	vertical_slice_map.refresh_world_interactables(world_state)
	hud.append_log(String(result.get("message", "")))
	_update_hud()


func _on_player_attack_requested() -> void:
	var result := vertical_slice_map.try_attack(character_state, world_state)
	if bool(result.get("success", false)) and bool(result.get("enemy_defeated", false)):
		_advance_quest_for_defeated_enemy(String(result.get("enemy_definition_id", "")))
	hud.append_log(String(result.get("message", "")))
	_update_hud()


func _on_player_recipe_cycle_requested() -> void:
	var result := vertical_slice_map.try_cycle_recipe()
	hud.append_log(String(result.get("message", "")))
	if bool(result.get("success", false)) and vertical_slice_map.current_interactable != null:
		_on_interaction_available(vertical_slice_map.current_interactable)
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


func _on_interaction_available(interactable: PrototypeInteractable) -> void:
	if interactable.interaction_type == "process_recipe":
		hud.show_prompt(_format_processing_prompt(interactable))
		return
	if interactable.interaction_type == "build":
		hud.show_prompt("按 E 建造：%s" % _get_display_name(interactable.definition_id))
		return

	hud.show_prompt("按 E 交互：%s" % _get_display_name(interactable.definition_id))


func _on_interaction_cleared(_interactable: PrototypeInteractable) -> void:
	hud.clear_prompt()


func _update_hud() -> void:
	hud.update_status(data_registry, world_state, character_state)


func _get_display_name(definition_id: String) -> String:
	if definition_id.is_empty():
		return ""

	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id

	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))


func _format_processing_prompt(interactable: PrototypeInteractable) -> String:
	if interactable.get_recipe_count() <= 1:
		return "按 E 加工：%s" % _get_display_name(interactable.get_current_recipe_id())

	return "按 E 加工：%s；按 R 切换配方（%d/%d）" % [
		_get_display_name(interactable.get_current_recipe_id()),
		interactable.get_recipe_position(),
		interactable.get_recipe_count()
	]


func _get_current_interaction_context() -> Dictionary:
	var interactable := vertical_slice_map.current_interactable
	if interactable == null:
		return {}

	return {
		"definition_id": interactable.definition_id,
		"interaction_type": interactable.interaction_type,
		"recipe_id": interactable.get_current_recipe_id()
	}


func _advance_quest_for_interaction(context: Dictionary, result: Dictionary) -> void:
	var definition_id := String(context.get("definition_id", ""))
	var interaction_type := String(context.get("interaction_type", ""))
	var recipe_id := String(context.get("recipe_id", ""))

	if interaction_type == "outpost_core":
		world_state.quest_state.set_objective_progress("quest.restore_outpost", "interact", "building.outpost_core", 1)
		return
	if interaction_type == "gather" and definition_id == "map_object.crystal_cluster":
		_add_drop_objective_progress("quest.scout_crystal_field", "gather_item", "item.crystal_ore", definition_id)
		world_state.quest_state.set_objective_progress("quest.scout_crystal_field", "visit_region", "region.crystal_vein_field", 1)
		_try_complete_quest("quest.scout_crystal_field")
		return
	if interaction_type == "sample" and definition_id == "map_object.anomaly_crystal":
		world_state.quest_state.set_objective_progress("quest.bring_back_sample", "sample_object", "map_object.anomaly_crystal", 1)
		world_state.quest_state.set_objective_progress("quest.bring_back_sample", "return_region", "region.outpost_platform", 1)
		_try_complete_quest("quest.bring_back_sample")
		return
	if interaction_type == "gather" and definition_id == "map_object.pollution_residue_patch":
		world_state.quest_state.set_objective_progress("quest.enter_pollution_edge", "visit_region", "region.pollution_edge", 1)
		_add_drop_objective_progress("quest.enter_pollution_edge", "gather_item", "item.polluted_residue", definition_id)
		_try_complete_quest("quest.enter_pollution_edge")
		return
	if interaction_type == "process_recipe":
		_advance_quest_for_recipe(recipe_id)
		return
	if interaction_type == "build":
		_advance_quest_for_build(String(result.get("built_definition_id", definition_id)))


func _advance_quest_for_recipe(recipe_id: String) -> void:
	match recipe_id:
		"recipe.basic_filter_module":
			world_state.quest_state.set_objective_progress("quest.make_filter_module", "craft_item", "equipment.filter_module_t1", 1)
			_try_complete_quest("quest.make_filter_module")
		"recipe.cleanse_residue":
			world_state.quest_state.set_objective_progress("quest.enter_pollution_edge", "craft_item", "item.resistance_vial_t1", 1)
			_try_complete_quest("quest.enter_pollution_edge")
		_:
			pass


func _advance_quest_for_build(building_id: String) -> void:
	if building_id == "building.foundation_t1":
		world_state.quest_state.add_objective_progress("quest.expand_treatment_point", "build", building_id, 1)
		_try_complete_quest("quest.expand_treatment_point")
		return
	if building_id == "building.pollution_filter":
		world_state.quest_state.set_objective_progress("quest.expand_treatment_point", "build", building_id, 1)
		_try_complete_quest("quest.expand_treatment_point")


func _advance_quest_for_defeated_enemy(enemy_definition_id: String) -> void:
	if enemy_definition_id == "enemy.polluted_skitter":
		world_state.quest_state.set_objective_progress("quest.enter_pollution_edge", "defeat_enemy", enemy_definition_id, 1)
		_try_complete_quest("quest.enter_pollution_edge")


func _mark_pollution_edge_ready() -> bool:
	if not world_state.quest_state.has_active_quest("quest.enter_pollution_edge") and not world_state.quest_state.has_completed_quest("quest.expand_treatment_point"):
		return false

	world_state.unlock_region("region.pollution_edge")
	if world_state.quest_state.has_active_quest("quest.enter_pollution_edge"):
		world_state.quest_state.set_objective_progress("quest.enter_pollution_edge", "visit_region", "region.pollution_edge", 1)
		_try_complete_quest("quest.enter_pollution_edge")
	return true


func _add_drop_objective_progress(quest_id: String, objective_type: String, target_id: String, source_definition_id: String) -> void:
	var source_definition := data_registry.get_definition(source_definition_id)
	for drop in source_definition.get("drops", []):
		if not drop is Dictionary:
			continue
		if String(drop.get("id", "")) != target_id:
			continue

		world_state.quest_state.add_objective_progress(
			quest_id,
			objective_type,
			target_id,
			float(drop.get("amount", 0.0))
		)
		return


func _try_complete_quest(quest_id: String) -> void:
	if not world_state.quest_state.has_active_quest(quest_id):
		return
	if not _are_quest_objectives_complete(quest_id):
		return

	var quest := data_registry.get_definition(quest_id)
	world_state.quest_state.complete_quest(quest_id)
	_grant_refs(quest.get("rewards", []))
	for effect_id in quest.get("unlock_effects", []):
		_apply_quest_unlock(String(effect_id))
	for next_quest_id in quest.get("next_quest_ids", []):
		world_state.quest_state.activate_quest(String(next_quest_id))


func _are_quest_objectives_complete(quest_id: String) -> bool:
	var quest := data_registry.get_definition(quest_id)
	for objective in quest.get("objectives", []):
		if not objective is Dictionary:
			continue

		var objective_type := String(objective.get("type", ""))
		var target_id := String(objective.get("target_id", ""))
		var required_amount := float(objective.get("amount", 1.0))
		var current_amount := world_state.quest_state.get_objective_progress(quest_id, objective_type, target_id)
		if current_amount < required_amount:
			return false

	return true


func _grant_refs(refs: Array) -> void:
	for ref in refs:
		if not ref is Dictionary:
			continue

		var definition_id := String(ref.get("id", ""))
		var amount := float(ref.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0:
			continue

		character_state.inventory.add_ref(definition_id, amount)


func _apply_quest_unlock(effect_id: String) -> void:
	if effect_id.begins_with("region."):
		world_state.unlock_region(effect_id)
	world_state.quest_state.unlock_effect(effect_id)
