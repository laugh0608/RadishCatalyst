extends CharacterBody2D
class_name PlayerController

@export var move_speed: float = 180.0

signal interaction_requested


func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = input_vector * move_speed
	move_and_slide()

	if Input.is_action_just_pressed("interact"):
		interaction_requested.emit()
