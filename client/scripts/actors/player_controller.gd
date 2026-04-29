extends CharacterBody2D
class_name PlayerController

@export var move_speed: float = 180.0

signal interaction_requested
signal attack_requested
signal recipe_cycle_requested
signal module_toggle_requested
signal quick_slot_requested(slot_index: int)
signal save_requested
signal load_requested


func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector == Vector2.ZERO:
		input_vector = _get_keyboard_fallback_vector()

	velocity = input_vector * move_speed
	move_and_slide()

	if Input.is_action_just_pressed("interact"):
		interaction_requested.emit()
	if Input.is_action_just_pressed("attack"):
		attack_requested.emit()
	if Input.is_action_just_pressed("cycle_recipe"):
		recipe_cycle_requested.emit()
	if Input.is_action_just_pressed("toggle_module"):
		module_toggle_requested.emit()
	if Input.is_action_just_pressed("use_quick_slot_1"):
		quick_slot_requested.emit(0)
	if Input.is_action_just_pressed("use_quick_slot_2"):
		quick_slot_requested.emit(1)
	if Input.is_action_just_pressed("save_game"):
		save_requested.emit()
	if Input.is_action_just_pressed("load_game"):
		load_requested.emit()


func _get_keyboard_fallback_vector() -> Vector2:
	var x_axis := 0.0
	var y_axis := 0.0

	if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
		x_axis -= 1.0
	if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
		x_axis += 1.0
	if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
		y_axis -= 1.0
	if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
		y_axis += 1.0

	return Vector2(x_axis, y_axis).normalized()
