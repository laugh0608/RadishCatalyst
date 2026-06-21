extends CharacterBody2D
class_name PlayerController

const BODY_COLOR := Color(0.18, 0.86, 0.93, 1.0)
const BODY_OUTLINE_COLOR := Color(0.93, 0.98, 1.0, 1.0)
const DIRECTION_COLOR := Color(1.0, 0.9, 0.36, 1.0)
const SUIT_DARK := Color(0.05, 0.12, 0.13, 0.92)
const SUIT_PANEL := Color(0.32, 0.72, 0.76, 0.9)
const PACK_COLOR := Color(0.12, 0.24, 0.22, 0.92)
const TOOL_COLOR := Color(0.96, 0.76, 0.32, 0.95)
const PLAYER_VISUAL_PART_IDS := [
	"suit.torso",
	"suit.helmet",
	"suit.backpack",
	"suit.boots",
	"tool.forward_arm",
	"direction.work_light"
]

@export var move_speed: float = 180.0

var facing_direction := Vector2.RIGHT
var block_positive_x_until_release := false

signal interaction_requested
signal attack_requested
signal tactical_scan_requested
signal recipe_cycle_requested
signal device_panel_toggle_requested
signal module_toggle_requested
signal quick_slot_requested(slot_index: int)
signal save_requested
signal load_requested


func _ready() -> void:
	z_index = 80
	queue_redraw()


func _physics_process(_delta: float) -> void:
	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input_vector == Vector2.ZERO:
		input_vector = _get_keyboard_fallback_vector()
	else:
		facing_direction = input_vector.normalized()
	if block_positive_x_until_release:
		if input_vector.x <= 0.0:
			block_positive_x_until_release = false
		else:
			input_vector.x = 0.0

	velocity = input_vector * move_speed
	move_and_slide()
	if input_vector != Vector2.ZERO:
		facing_direction = input_vector.normalized()
		queue_redraw()

	if Input.is_action_just_pressed("interact"):
		interaction_requested.emit()
	if Input.is_action_just_pressed("attack"):
		attack_requested.emit()
	if Input.is_action_just_pressed("tactical_scan"):
		tactical_scan_requested.emit()
	if Input.is_action_just_pressed("toggle_device_panel"):
		device_panel_toggle_requested.emit()
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


func _draw() -> void:
	var forward := _safe_facing_direction()
	var side := forward.orthogonal()
	draw_circle(Vector2.ZERO, 18.0, Color(0.02, 0.05, 0.05, 0.38))
	_draw_oriented_rect(-forward * 4.0, forward, 13.0, 9.0, BODY_OUTLINE_COLOR)
	_draw_oriented_rect(-forward * 4.0, forward, 10.5, 6.8, BODY_COLOR)
	_draw_oriented_rect(-forward * 12.0, forward, 6.5, 8.0, PACK_COLOR)
	draw_circle(forward * 9.0, 8.0, BODY_OUTLINE_COLOR)
	draw_circle(forward * 9.0, 5.6, SUIT_DARK)
	draw_line(forward * 3.0 + side * 8.0, forward * 19.0 + side * 8.0, TOOL_COLOR, 4.0, true)
	draw_line(forward * 18.0 + side * 8.0, forward * 25.0 + side * 8.0, DIRECTION_COLOR, 2.0, true)
	draw_line(-forward * 15.0 + side * 5.0, -forward * 22.0 + side * 8.0, SUIT_PANEL, 3.0, true)
	draw_line(-forward * 15.0 - side * 5.0, -forward * 22.0 - side * 8.0, SUIT_PANEL, 3.0, true)
	draw_arc(Vector2.ZERO, 24.0, 0.0, TAU, 32, Color(0.82, 0.96, 0.96, 0.62), 1.5, true)


func stop_positive_x_until_release() -> void:
	block_positive_x_until_release = true
	velocity.x = 0.0


func clear_positive_x_block() -> void:
	block_positive_x_until_release = false


func clamp_to_play_bounds(minimum: Vector2, maximum: Vector2) -> void:
	var clamped_position := Vector2(
		clampf(position.x, minimum.x, maximum.x),
		clampf(position.y, minimum.y, maximum.y)
	)
	if clamped_position.x != position.x:
		velocity.x = 0.0
	if clamped_position.y != position.y:
		velocity.y = 0.0
	position = clamped_position


func get_visual_part_count() -> int:
	return PLAYER_VISUAL_PART_IDS.size()


func has_visual_part(part_id: String) -> bool:
	return PLAYER_VISUAL_PART_IDS.has(part_id)


func get_facing_direction() -> Vector2:
	return _safe_facing_direction()


func _draw_oriented_rect(center: Vector2, forward: Vector2, half_length: float, half_width: float, color: Color) -> void:
	var side := forward.orthogonal()
	var points := PackedVector2Array([
		center + forward * half_length + side * half_width,
		center + forward * half_length - side * half_width,
		center - forward * half_length - side * half_width,
		center - forward * half_length + side * half_width
	])
	draw_colored_polygon(points, color)


func _safe_facing_direction() -> Vector2:
	if facing_direction.length_squared() <= 0.001:
		return Vector2.RIGHT
	return facing_direction.normalized()


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
