extends Area2D
class_name PrototypeInteractable

@export var definition_id: String = ""
@export var interaction_type: String = "inspect"
@export var recipe_id: String = ""
@export var prerequisite_instance_id: String = ""
@export var single_use: bool = true
@export var label_offset := Vector2(-72.0, 20.0)
@export var label_size := Vector2(144.0, 24.0)

var consumed: bool = false
var instance_id: String = ""
var recipe_ids: Array[String] = []
var recipe_index: int = 0

@onready var label: Label = $Label


func setup(display_name: String) -> void:
	label.text = display_name
	label.offset_left = label_offset.x
	label.offset_top = label_offset.y
	label.offset_right = label_offset.x + label_size.x
	label.offset_bottom = label_offset.y + label_size.y


func can_interact() -> bool:
	return not consumed


func set_recipe_cycle(available_recipe_ids: Array[String]) -> void:
	recipe_ids.clear()
	for available_recipe_id in available_recipe_ids:
		recipe_ids.append(available_recipe_id)
	if recipe_ids.is_empty():
		return

	var existing_index := recipe_ids.find(recipe_id)
	recipe_index = maxi(existing_index, 0)
	recipe_id = recipe_ids[recipe_index]


func get_current_recipe_id() -> String:
	if recipe_ids.is_empty():
		return recipe_id

	recipe_index = clampi(recipe_index, 0, recipe_ids.size() - 1)
	recipe_id = recipe_ids[recipe_index]
	return recipe_id


func select_next_recipe() -> String:
	if recipe_ids.is_empty():
		return get_current_recipe_id()

	recipe_index = (recipe_index + 1) % recipe_ids.size()
	recipe_id = recipe_ids[recipe_index]
	return recipe_id


func get_recipe_count() -> int:
	if recipe_ids.is_empty() and not recipe_id.is_empty():
		return 1
	return recipe_ids.size()


func get_recipe_position() -> int:
	if get_recipe_count() <= 0:
		return 0
	return recipe_index + 1


func mark_consumed() -> void:
	if single_use:
		consumed = true
		visible = false
		monitoring = false


func set_interaction_enabled(enabled: bool) -> void:
	visible = enabled
	monitoring = enabled
