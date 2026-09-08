extends Node

var world: Control
var failures: Array[String] = []
var assertions := 0
var shot_root := ""


func expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
		push_error(label)


func settle(frames := 5) -> void:
	for i in frames:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw


func click(button: Button) -> void:
	expect(button.is_visible_in_tree() and not button.disabled, "button: " + button.text)
	var at := button.get_global_rect().get_center()
	await motion(at)
	await mouse(at, true)
	await mouse(at, false)
	await settle()


func motion(at: Vector2, held := false) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	get_viewport().push_input(event, true)
	await get_tree().process_frame


func mouse(at: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.pressed = pressed
	get_viewport().push_input(event, true)
	await get_tree().process_frame


func key(code: int, held: Variant = null) -> void:
	for pressed in ([true, false] if held == null else [held]):
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		get_viewport().push_input(event, true)
		await get_tree().process_frame
	await settle()


func cell_screen(cell: Vector2i, height := 0.0) -> Vector2:
	return world.hud.viewport_to_screen(world.view.project(Vector3(cell.x + 0.5, height, cell.y + 0.5)))


func world_click(cell: Vector2i, height := 0.0) -> void:
	var at := cell_screen(cell, height)
	expect(world.hud.world_point(at) != null, "world target unobstructed: " + str(cell))
	await motion(at)
	await mouse(at, true)
	await mouse(at, false)
	await settle()


func drag(cells: Array) -> void:
	await motion(cell_screen(cells[0]))
	await mouse(cell_screen(cells[0]), true)
	for cell in cells.slice(1):
		await motion(cell_screen(cell), true)
	await mouse(cell_screen(cells.back()), false)
	await settle()


func shot(name: String) -> void:
	await settle()
	var picture := get_viewport().get_texture().get_image()
	expect(picture.save_png(shot_root.path_join(name + ".png")) == OK, "screenshot " + name)
	print("Factory screenshot: " + name)
