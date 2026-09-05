class_name SliceWorldInputRouter
extends RefCounted

## Routes world-level cancel, placement pointer and rotation input. Individual
## panels and the player keep ownership of their focused controls.

var _world_ref: WeakRef


func setup(world: SliceWorld) -> void:
	_world_ref = weakref(world)


func handle(event: InputEvent) -> void:
	var world := _world_ref.get_ref() as SliceWorld
	if world == null:
		return
	if event.is_action_pressed("ui_cancel"):
		_handle_cancel(world)
		world.get_viewport().set_input_as_handled()
		return
	if not world.is_placement_active():
		if _handle_building_selection(
			world, event, _pointer_over_blocking_ui(world)
		):
			world.get_viewport().set_input_as_handled()
		return
	if event is InputEventMouseMotion or event is InputEventMouseButton:
		if handle_placement_pointer(event):
			world.get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("rotate_building"):
		world.rotate_building_placement()
		world.get_viewport().set_input_as_handled()


func _handle_cancel(world: SliceWorld) -> void:
	if world.is_placement_active():
		world.cancel_building_placement()
	elif world._craft_panel != null and world._craft_panel.is_open():
		world._craft_panel.close()
	elif world.is_core_storage_open():
		world.close_core_storage()
	elif world.is_core_charge_confirmation_open():
		world.close_core_charge_confirmation()
	elif world.is_building_actions_open():
		world.close_building_actions()
	elif world.is_build_mode_active():
		world.exit_build_mode()
	elif world.pause_menu != null:
		world.combat_controller.require_fresh_attack_press()
		world.pause_menu.open()


func handle_placement_pointer(
	event: InputEvent,
	ui_blocked := false
) -> bool:
	var world := _world_ref.get_ref() as SliceWorld
	if world == null or not world.is_placement_active():
		return false
	var pointer := world._placement_pointer
	if not pointer.track_event(event):
		return false
	world._refresh_placement_target()
	var placement := world._placement
	if pointer.should_confirm(
		event,
		placement.target_origin,
		placement.definition.is_floor,
		ui_blocked or _pointer_over_blocking_ui(world)
	):
		world.try_place_building()
	return true


func _pointer_over_blocking_ui(world: SliceWorld) -> bool:
	var hovered := world.get_viewport().gui_get_hovered_control()
	return hovered != null and hovered.mouse_filter != Control.MOUSE_FILTER_IGNORE


func _handle_building_selection(
	world: SliceWorld,
	event: InputEvent,
	ui_blocked := false
) -> bool:
	if (
		not world.is_build_mode_active()
		or world.is_placement_active()
		or ui_blocked
	):
		return false
	var click := event as InputEventMouseButton
	if (
		click == null
		or click.button_index != MOUSE_BUTTON_LEFT
		or not click.pressed
	):
		return false
	var canvas_transform := world.get_viewport().get_canvas_transform()
	var world_position := canvas_transform.affine_inverse() * click.position
	var instance := _visible_instance_at(world, world_position)
	if instance == null:
		instance = _occupied_instance_at(world, world_position)
	if instance == null:
		return false
	world.open_building_actions(instance)
	return world.is_building_actions_open()


func _visible_instance_at(
	world: SliceWorld,
	world_position: Vector2
) -> SliceBuildingInstance:
	var best: SliceBuildingInstance
	var best_sort_y := -INF
	for instance in world._building_instances:
		if not _is_selectable(instance, world):
			continue
		var sprite := instance.get_node_or_null("Sprite") as Sprite2D
		if (
			sprite == null
			or not sprite.visible
			or sprite.texture == null
			or not sprite.is_pixel_opaque(sprite.to_local(world_position))
		):
			continue
		var sort_y := instance.global_position.y
		if best == null or sort_y >= best_sort_y:
			best = instance
			best_sort_y = sort_y
	return best


func _occupied_instance_at(
	world: SliceWorld,
	world_position: Vector2
) -> SliceBuildingInstance:
	var cell := Vector2i(
		floor(world_position.x / SliceWorld.TILE_SIZE),
		floor(world_position.y / SliceWorld.TILE_SIZE)
	)
	var instance_id := world._occupancy.blocking_instance_at(cell)
	if instance_id.is_empty():
		instance_id = world._occupancy.floor_instance_at(cell)
	for instance in world._building_instances:
		if instance.instance_id == instance_id and _is_selectable(instance, world):
			return instance
	return null


func _is_selectable(
	instance: SliceBuildingInstance,
	world: SliceWorld
) -> bool:
	return (
		instance != null
		and instance.visible
		and instance != world._adjustment_instance
		and instance.definition != null
	)
