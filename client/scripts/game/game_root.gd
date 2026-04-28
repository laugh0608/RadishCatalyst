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
	vertical_slice_map.player.interaction_requested.connect(_on_player_interaction_requested)
	vertical_slice_map.player.attack_requested.connect(_on_player_attack_requested)
	vertical_slice_map.player.recipe_cycle_requested.connect(_on_player_recipe_cycle_requested)
	vertical_slice_map.player.module_toggle_requested.connect(_on_player_module_toggle_requested)
	vertical_slice_map.interaction_available.connect(_on_interaction_available)
	vertical_slice_map.interaction_cleared.connect(_on_interaction_cleared)

	hud.append_log("前哨原型已启动。WASD 移动，E 交互，J 攻击，R 切换设备配方，F 启用过滤模块。")
	_update_hud()


func _on_player_interaction_requested() -> void:
	var result := vertical_slice_map.try_interact(character_state, world_state)
	hud.append_log(String(result.get("message", "")))
	_update_hud()


func _on_player_attack_requested() -> void:
	var result := vertical_slice_map.try_attack(character_state, world_state)
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
		hud.append_log("基础过滤模块已启用。")
		_update_hud()
		return
	if not character_state.equip_suit_module(module_id):
		hud.append_log("背包中没有基础过滤模块，无法启用。")
		_update_hud()
		return

	world_state.unlock_region("region.pollution_edge")
	hud.append_log("已启用基础过滤模块，污染边界区已标记，污染防护消耗降低。")
	_update_hud()


func _on_interaction_available(interactable: PrototypeInteractable) -> void:
	if interactable.interaction_type == "process_recipe":
		hud.show_prompt(_format_processing_prompt(interactable))
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
