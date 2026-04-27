extends Area2D
class_name PrototypeInteractable

@export var definition_id: String = ""
@export var interaction_type: String = "inspect"
@export var reward_id: String = ""
@export var reward_amount: int = 0
@export var single_use: bool = true

var consumed: bool = false

@onready var label: Label = $Label


func setup(display_name: String) -> void:
	label.text = display_name


func can_interact() -> bool:
	return not consumed


func apply_interaction(character_state: CharacterState, world_state: WorldState) -> Dictionary:
	if not can_interact():
		return {
			"success": false,
			"message": "目标已处理。"
		}

	if reward_id.begins_with("item."):
		character_state.inventory.add_item(reward_id, reward_amount)
	elif reward_id.begins_with("fluid."):
		character_state.inventory.add_fluid(reward_id, reward_amount)

	if interaction_type == "outpost_core":
		world_state.quest_state.complete_quest("quest.restore_outpost")
		world_state.quest_state.activate_quest("quest.scout_crystal_field")
		world_state.unlock_region("region.crystal_vein_field")

	if single_use:
		consumed = true
		visible = false
		monitoring = false

	return {
		"success": true,
		"message": _build_message()
	}


func _build_message() -> String:
	if reward_id.is_empty() or reward_amount <= 0:
		return "交互完成。"
	return "获得 %s x%d" % [reward_id, reward_amount]
