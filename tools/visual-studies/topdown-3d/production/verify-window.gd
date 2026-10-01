extends Node

## Real Production entry, mouse/key events and wall-clock production, no state injection.
const Model := preload("res://production/model.gd")
var world: Control
var failures: Array[String] = []
var assertions := 0
var shot_root := ""
var record_root := ""
var observations: Array[Dictionary] = []
var performance := {}
var verification_scope := "Independent Production scene; synthesized mouse/key input; normal production time; no simulation state injection or saved games"


func prepare(app: Control, timeout := 600.0) -> void:
	world = app
	get_window().mode = Window.MODE_WINDOWED
	get_window().size = Vector2i(1440, 900)
	var repo := ProjectSettings.globalize_path("res://").path_join("../../..").simplify_path()
	var run_id := "run-%d-%d" % [Time.get_unix_time_from_system(), OS.get_process_id()]
	record_root = repo.path_join("tools/runtime-intake/check-runs/godot-production-line").path_join(run_id)
	shot_root = repo.path_join("assets/art-intake/2026-09-08-godot-production-line-preview").path_join(run_id)
	DirAccess.make_dir_recursive_absolute(record_root)
	DirAccess.make_dir_recursive_absolute(shot_root)
	get_tree().create_timer(timeout).timeout.connect(func():
		failures.append("Window verification exceeded wall-clock budget")
		_finish()
	)


func run(app: Control) -> void:
	prepare(app)
	get_window().grab_focus()
	await _settle(30)
	_expect(get_tree().current_scene == world, "real independent Production entry")
	_expect(world.model.entities.is_empty(), "empty yard and no prebuilt production")
	_expect(is_equal_approx(world.view.yaw, 25) and is_equal_approx(world.view.camera.rotation_degrees.x, -50), "Web 50 degree / 25 degree camera")
	await _shot("01-empty-yard")
	await _click(world.hud.buttons.collector)
	await _world_click(Vector2i(-8, -1))
	_expect(world.model.entity_at(Vector2i(-8, -1)).get("type") == "collector", "mouse places collector on ore")
	await _click(world.hud.buttons.reactor)
	await _world_click(Vector2i(-1, -2))
	_expect(world.model.entity_at(Vector2i(-1, -2)).get("type") == "reactor", "mouse places reactor")
	await _click(world.hud.buttons.storage)
	await _world_click(Vector2i(6, -1))
	_expect(world.model.entity_at(Vector2i(6, -1)).get("type") == "storage", "mouse places terminal storage")
	if not failures.is_empty():
		await _shot("failure-placement")
		_finish()
		return
	await _choose("belt")
	# Input remains enabled while a build preview is active.
	var start := Vector2(world.actor.x, world.actor.z)
	await _key(KEY_D, true)
	await _seconds(0.3)
	await _key(KEY_D, false)
	_expect(Vector2(world.actor.x, world.actor.z).distance_to(start) > 0.4, "keyboard moves engineer during building")
	# Cancelled strokes never spend kits; UI and keyboard cancellation use actual events.
	await _start_drag(Vector2i(-6, 3))
	await _drag_to(Vector2i(-3, 3))
	await _key(KEY_ESCAPE)
	await _mouse_up(_cell_screen(Vector2i(-3, 3)))
	_expect(world.model.kits.belt == 24 and world.ui.stroke.is_empty(), "Esc cancels a preview without kits")
	await _start_drag(Vector2i(-6, 3))
	await _drag_to(Vector2i(-4, 3))
	await _motion(world.hud.buttons.help.get_global_rect().get_center(), true)
	await _mouse_up(world.hud.buttons.help.get_global_rect().get_center())
	_expect(world.model.kits.belt == 24 and not world.pointer, "drag into UI cancels without placement")
	# Fast crossing and backtracking only modify the preview.
	await _start_drag(Vector2i(-6, 0))
	await _drag_to(Vector2i(-2, 0))
	_expect(world.ui.stroke.size() == 5 and world.model.kits.belt == 24, "fast pointer spans fill five cells before commit")
	await _drag_to(Vector2i(-4, 0))
	_expect(world.ui.stroke.size() == 3, "backtracking shortens the preview")
	await _drag_to(Vector2i(-2, 0))
	await _shot("02-input-drag-preview")
	await _mouse_up(_cell_screen(Vector2i(-2, 0)))
	_expect(world.model.kits.belt == 19, "release commits all five input belts")
	await _start_drag(Vector2i(2, 0))
	for cell in [Vector2i(2, 2), Vector2i(4, 2), Vector2i(4, 0), Vector2i(5, 0)]:
		await _drag_to(cell)
	await _shot("03-curved-output-preview")
	await _mouse_up(_cell_screen(Vector2i(5, 0)))
	_expect(world.model.kits.belt == 11, "four-corner output commits eight belts")
	await _key(KEY_ESCAPE)
	await _click(world.hud.buttons.build)
	await _click(world.hud.buttons.zoom_in)
	await _click(world.hud.buttons.zoom_in)
	await _shot("04-running-overview")
	if not failures.is_empty():
		_finish()
		return
	await _until(func(): return world.model.delivered > 0, 45, "first actual catalyst reaches storage")
	_observe("first_delivery")
	world.frame_samples.clear()
	world.simulation_samples.clear()
	world.sample_enabled = true
	await _seconds(8)
	world.sample_enabled = false
	performance = {"frame_interval_ms": _stats(world.frame_samples), "advance_call_ms": _stats(world.simulation_samples),
		"draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),
		"rendered_primitives": Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME),
		"scope": "8 seconds of this three-machine / 13-belt window; no screenshot captures in sample; monotonic wall-clock frame intervals are not GPU timings"}
	await _until(func(): return world.model.entity_at(Vector2i(2, 2)).get("cargo", "") == "catalyst", 15, "catalyst travels through a real curved segment")
	await _click(world.hud.buttons.pause)
	await _world_click(Vector2i(2, 2), 0.29)
	_expect(world.model.by_id(world.ui.selected).get("type") == "belt", "visible belt can be selected")
	await _shot("05-cargo-on-curve")
	await _click(world.hud.buttons.close_inspector)
	await _click(world.hud.buttons.camera_left)
	await _click(world.hud.buttons.camera_left)
	await _shot("06-camera-alternate")
	await _click(world.hud.buttons.camera_right)
	await _click(world.hud.buttons.camera_right)
	await _click(world.hud.buttons.pause)
	await _world_click(Vector2i(-4, 0), 0.29)
	_expect(world.model.by_id(world.ui.selected).get("x") == -4, "ray selects the input belt to dismantle")
	await _click(world.hud.buttons.salvage)
	_expect(world.model.entity_at(Vector2i(-4, 0)).is_empty() and world.model.lesson.cut, "mouse salvage cuts real input connection")
	await _until(func(): return world.model.lesson.starved, 55, "remaining input drains into actual starvation")
	_observe("starved")
	await _world_click(Vector2i(-1, -2), 1.1)
	await _shot("07-input-cut-starved")
	await _choose("belt")
	await _world_click(Vector2i(-4, 0))
	_expect(not world.model.entity_at(Vector2i(-4, 0)).is_empty(), "single-click repairs the missing input")
	await _key(KEY_ESCAPE)
	await _click(world.hud.buttons.build)
	await _until(func(): return world.model.lesson.recovered, 45, "new batch delivery completes recovery")
	_observe("recovered")
	await _shot("08-new-batch-recovered")
	# Output cut verifies backpressure independently of the tutorial milestone.
	await _world_click(Vector2i(2, 1), 0.29)
	await _click(world.hud.buttons.salvage)
	_expect(world.model.entity_at(Vector2i(2, 1)).is_empty(), "output segment dismantles through inspector")
	await _until(func():
		var r: Dictionary = world.model.entity_at(Vector2i(-1, -2))
		return r.output == 1 and not r.processing and r.input == 2
	, 40, "output cut stops new batches with full input and output")
	await _world_click(Vector2i(-1, -2), 1.1)
	await _shot("09-output-backpressure")
	await _choose("belt")
	await _key(KEY_R)
	await _world_click(Vector2i(2, 1))
	await _key(KEY_ESCAPE)
	await _click(world.hud.buttons.build)
	var before: int = world.model.delivered
	await _until(func(): return world.model.delivered > before, 25, "output reconnection resumes actual delivery")
	_observe("output_recovered")
	await _world_click(Vector2i(6, -1), 1.0)
	if world.hud.buttons.deposit.visible and not world.hud.buttons.deposit.disabled:
		await _click(world.hud.buttons.deposit)
	_expect(world.model.bag.crystal + world.model.bag.catalyst == 0, "recovered material deposits through storage UI")
	await _click(world.hud.buttons.close_inspector)
	await _shot("10-final-running")
	var balance: Dictionary = world.model.material_balance()
	_expect(balance.generated == balance.equivalent, "complete input path conserves crystal equivalent")
	_expect(world.model.kits.belt == 11, "all dismantled belts returned to same thirteen-belt topology")
	_finish()


func _cell_screen(cell: Vector2i, height := 0.0) -> Vector2:
	return world.hud.viewport_to_screen(world.view.project(Vector3(cell.x + 0.5, height, cell.y + 0.5)))


func _world_click(cell: Vector2i, height := 0.0) -> void:
	await _settle()
	var at := _cell_screen(cell, height)
	await _motion(at)
	await _mouse_down(at)
	await _mouse_up(at)
	await _settle()


func _choose(type: String) -> void:
	if not world.ui.build:
		await _click(world.hud.buttons.build)
	await _click(world.hud.buttons[type])


func _click(button: Button) -> void:
	await _foreground()
	await _settle()
	_expect(button.is_visible_in_tree() and not button.disabled, "button reachable: " + button.text)
	var at := button.get_global_rect().get_center()
	await _motion(at, false, button.get_viewport())
	await _mouse(at, true, button.get_viewport())
	await _mouse(at, false, button.get_viewport())
	await _settle()


func _start_drag(cell: Vector2i) -> void:
	await _motion(_cell_screen(cell))
	await _mouse_down(_cell_screen(cell))


func _drag_to(cell: Vector2i) -> void:
	await _motion(_cell_screen(cell), true)


func _motion(at: Vector2, held := false, target: Viewport = null) -> void:
	var event := InputEventMouseMotion.new()
	event.position = at
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if held else 0
	(get_viewport() if target == null else target).push_input(event, true)
	await get_tree().process_frame


func _mouse_down(at: Vector2) -> void:
	await _mouse(at, true)


func _mouse_up(at: Vector2) -> void:
	await _mouse(at, false)


func _mouse(at: Vector2, pressed: bool, target: Viewport = null) -> void:
	var event := InputEventMouseButton.new()
	event.position = at
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if pressed else 0
	event.pressed = pressed
	(get_viewport() if target == null else target).push_input(event, true)
	await get_tree().process_frame


func _key(code: int, held: Variant = null) -> void:
	for pressed in ([true, false] if held == null else [held]):
		var event := InputEventKey.new()
		event.physical_keycode = code
		event.keycode = code
		event.pressed = pressed
		get_viewport().push_input(event, true)
		await get_tree().process_frame
	await _settle()


func _settle(frames := 5) -> void:
	await _foreground()
	for i in frames:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw


func _seconds(duration: float) -> void:
	await get_tree().create_timer(duration).timeout


func _foreground() -> void:
	var active_window: Window = world.hud.restart if world.hud.restart.visible else get_window()
	if active_window.has_focus():
		return
	active_window.grab_focus()
	await get_tree().process_frame
	if not active_window.has_focus():
		print("Window review waiting for native foreground focus; production remains paused.")
	while not active_window.has_focus():
		await get_tree().process_frame


func _until(condition: Callable, seconds: float, label: String) -> void:
	await _foreground()
	var started: float = world.model.time
	while not condition.call() and world.model.time - started < seconds:
		if not world.focused:
			await _foreground()
		await get_tree().process_frame
	_expect(condition.call(), label)
	if not condition.call():
		_finish()


func _shot(label: String) -> void:
	await _foreground()
	await _settle()
	await RenderingServer.frame_post_draw
	var screenshot := get_viewport().get_texture().get_image()
	_expect(screenshot.save_png(shot_root.path_join(label + ".png")) == OK, "screenshot: " + label)
	print("Window evidence: " + label)


func _observe(label: String) -> void:
	observations.append({"label": label, "time": world.model.time, "delivered": world.model.delivered,
		"completed": world.model.completed, "entities": world.model.entities.duplicate(true), "lesson": world.model.lesson.duplicate(),
		"balance": world.model.material_balance(), "bag": world.model.bag.duplicate()})


func _stats(values: Array[float]) -> Dictionary:
	if values.is_empty():
		return {"count": 0}
	var sorted := values.duplicate()
	sorted.sort()
	return {"count": sorted.size(), "p50": sorted[int((sorted.size() - 1) * 0.5)],
		"p95": sorted[int((sorted.size() - 1) * 0.95)], "p99": sorted[int((sorted.size() - 1) * 0.99)], "max": sorted.back()}


func _expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
		push_error(label)


func _finish() -> void:
	var file := FileAccess.open(record_root.path_join("result.json"), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({"assertions": assertions, "failures": failures, "screenshots": shot_root,
			"observations": observations, "performance": performance, "engine": Engine.get_version_info(),
			"renderer": RenderingServer.get_current_rendering_method(), "adapter": RenderingServer.get_video_adapter_name(),
			"window": str(get_viewport().get_visible_rect().size), "yaw": world.view.yaw, "zoom": world.view.zoom, "focused": world.focused, "user_data_dir": OS.get_user_data_dir(),
			"scope": verification_scope}, "\t") + "\n")
		file.close()
	print("Godot production window: %d assertions, %d failures. %s" % [assertions, failures.size(), record_root])
	get_tree().quit(0 if failures.is_empty() else 1)
