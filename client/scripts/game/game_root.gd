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
	vertical_slice_map.player.interaction_requested.connect(_on_player_interaction_requested)
	vertical_slice_map.interaction_available.connect(_on_interaction_available)
	vertical_slice_map.interaction_cleared.connect(_on_interaction_cleared)

	hud.append_log("前哨原型已启动。WASD 移动，E 交互。")
	_update_hud()


func _on_player_interaction_requested() -> void:
	var result := vertical_slice_map.try_interact(character_state, world_state)
	hud.append_log(String(result.get("message", "")))
	_update_hud()


func _on_interaction_available(interactable: PrototypeInteractable) -> void:
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
