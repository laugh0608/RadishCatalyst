class_name SlicePlacementPointerInput
extends RefCounted

## Keeps pointer targeting and floor-drag state outside SliceWorld. It never
## validates or places a building; callers remain authoritative for both.

var screen_position := Vector2.ZERO
var pointer_target_active := false
var floor_drag_active := false

var _last_drag_origin := Vector2i(-1, -1)


func begin() -> void:
	screen_position = Vector2.ZERO
	pointer_target_active = false
	floor_drag_active = false
	_last_drag_origin = Vector2i(-1, -1)


func cancel() -> void:
	floor_drag_active = false
	_last_drag_origin = Vector2i(-1, -1)


func track_event(event: InputEvent) -> bool:
	if event is InputEventMouseMotion:
		screen_position = (event as InputEventMouseMotion).position
		pointer_target_active = true
		return true
	if event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		if button_event.button_index != MOUSE_BUTTON_LEFT:
			return false
		screen_position = button_event.position
		pointer_target_active = true
		if not button_event.pressed:
			cancel()
		return true
	return false


func should_confirm(
	event: InputEvent,
	origin_cell: Vector2i,
	is_floor: bool,
	ui_blocked: bool
) -> bool:
	if ui_blocked:
		return false
	if event is InputEventMouseButton:
		var button_event := event as InputEventMouseButton
		if (
			button_event.button_index != MOUSE_BUTTON_LEFT
			or not button_event.pressed
		):
			return false
		floor_drag_active = is_floor
		_last_drag_origin = origin_cell
		return true
	if (
		event is InputEventMouseMotion
		and floor_drag_active
		and is_floor
		and origin_cell != _last_drag_origin
	):
		_last_drag_origin = origin_cell
		return true
	return false


func release_if_button_up() -> void:
	if (
		floor_drag_active
		and not Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
	):
		cancel()
