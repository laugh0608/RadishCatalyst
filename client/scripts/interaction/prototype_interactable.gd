extends Area2D
class_name PrototypeInteractable

@export var definition_id: String = ""
@export var interaction_type: String = "inspect"
@export var single_use: bool = true

var consumed: bool = false
var instance_id: String = ""

@onready var label: Label = $Label


func setup(display_name: String) -> void:
	label.text = display_name


func can_interact() -> bool:
	return not consumed


func mark_consumed() -> void:
	if single_use:
		consumed = true
		visible = false
		monitoring = false
