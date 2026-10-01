extends Node

## Bounded window review. Fixture positioning is explicit; movement uses input actions.
var failures: Array[String] = []
var assertions := 0
var shot_root := ""
var record_root := ""
var movements: Array[Dictionary] = []


func run(world: Node3D) -> void:
	get_tree().create_timer(55.0).timeout.connect(func():
		push_error("3D comparison verification exceeded 55 seconds")
		get_tree().quit(1)
	)
	var repo := ProjectSettings.globalize_path("res://").path_join("../../..").simplify_path()
	var run_id := "run-%d-%d" % [Time.get_unix_time_from_system(), OS.get_process_id()]
	shot_root = repo.path_join("assets/art-intake/2026-09-06-topdown-3d-preview").path_join(run_id)
	record_root = repo.path_join("tools/runtime-intake/check-runs/topdown-3d").path_join(run_id)
	_expect(DirAccess.make_dir_recursive_absolute(shot_root) == OK, "screenshot directory created")
	_expect(DirAccess.make_dir_recursive_absolute(record_root) == OK, "isolated record directory created")
	for i in 30:
		await get_tree().process_frame
	await _settle()
	_expect(get_tree().current_scene == world, "project main scene is the real independent entry")
	_expect(world.player is CharacterBody3D, "movable character uses 3D physics")
	_expect(world.camera.projection == Camera3D.PROJECTION_ORTHOGONAL, "oblique orthographic camera")
	_expect(world.specimen.glass_parts.size() == 5, "five actual mesh spans")
	_expect(world.specimen.glass_parts[0].mesh is ArrayMesh, "tube has authored 3D surface geometry")
	_expect(world.player.is_on_floor(), "character stands on the physical slab")
	await _shot("01-overview")
	await _click(world.buttons["filled"])
	_expect(not world.filled, "mouse button switches to empty pipe")
	await _shot("02-empty-glass")
	await _click(world.buttons["glass"])
	_expect(not world.glass_enabled, "mouse button switches to opaque wall")
	await _shot("03-opaque-pipe")
	await _click(world.buttons["glass"])
	await _click(world.buttons["filled"])
	await _click(world.buttons["shadows"])
	_expect(not world.sun.shadow_enabled, "shadow toggle reaches the real light")
	await _shot("04-shadows-off")
	await _click(world.buttons["shadows"])
	await _click(world.buttons["light"])
	await _shot("05-alternate-light")
	await _click(world.buttons["light"])
	# Behind the reactor, then walk into it to test collision, and around its left edge.
	world.player.position = Vector3(-3.15, 0.02, -2.5)
	world.player.velocity = Vector3.ZERO
	await _settle()
	await _shot("06-character-behind")
	await _walk(world, Vector3(0, 0, 1), 55)
	_expect(world.player.position.z < -2.25, "reactor collision blocks forward movement")
	await _walk(world, Vector3(-1, 0, 0), 58)
	_expect(world.player.position.x < -5.0, "input movement reaches side of reactor")
	await _walk(world, Vector3(0, 0, 1), 95)
	_expect(world.player.position.z > 1.4, "input movement passes reactor edge to the front")
	await _walk(world, Vector3(1, 0, 0), 50)
	await _shot("07-character-front")
	# Behind the glass, away from collars and supports; compare against an opaque wall.
	world.player.position = Vector3(1.95, 0.02, -1.25)
	world.player.velocity = Vector3.ZERO
	world.specimen.set_filled(false)
	world.filled = false
	world._refresh_status()
	await _settle()
	await _shot("08-character-through-glass")
	await _click(world.buttons["glass"])
	await _shot("09-character-opaque-occlusion")
	await _click(world.buttons["glass"])
	await _walk(world, Vector3(0, 0, 1), 64)
	_expect(world.player.position.z > 1.2, "character walks beneath clear span to foreground")
	await _shot("10-character-pipe-front")
	await _click(world.buttons["filled"])
	world.yaw = -18.0
	world._update_camera()
	await _shot("11-alternate-camera")
	world.yaw = 22.0
	world._update_camera()
	await _click(world.buttons["zoom"])
	await _shot("12-wide-scale")
	var file := FileAccess.open(record_root.path_join("result.json"), FileAccess.WRITE)
	_expect(file != null, "result record opens")
	var record := {"assertions": assertions, "failures": failures, "screenshots": shot_root,
		"user_data_dir": OS.get_user_data_dir(), "engine": Engine.get_version_info(), "renderer": RenderingServer.get_current_rendering_method(),
		"video_adapter": RenderingServer.get_video_adapter_name(), "movement": movements,
		"scope": "Independent Main scene; fixture positions plus input-driven walks; no gameplay saves"}
	if file:
		file.store_string(JSON.stringify(record, "\t") + "\n")
		file.close()
	print("3D comparison: %d assertions, %d failures. Screenshots: %s" % [assertions, failures.size(), shot_root])
	for failure in failures:
		push_error(failure)
	get_tree().quit(0 if failures.is_empty() else 1)


func _walk(world: Node3D, direction: Vector3, frames: int) -> void:
	var start: Vector3 = world.player.position
	var right: Vector3 = world.camera.global_basis.x
	var forward: Vector3 = world.camera.global_basis.z
	right.y = 0
	forward.y = 0
	var axis := Vector2(direction.dot(right.normalized()), direction.dot(forward.normalized()))
	Input.action_press("right" if axis.x > 0 else "left", absf(axis.x))
	Input.action_press("down" if axis.y > 0 else "up", absf(axis.y))
	for i in frames:
		await get_tree().physics_frame
	for action in ["left", "right", "up", "down"]:
		Input.action_release(action)
	await _settle()
	movements.append({"start": str(start), "end": str(world.player.position), "direction": str(direction), "physics_frames": frames})


func _click(button: Button) -> void:
	var at := button.get_global_rect().get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = at
	get_viewport().push_input(motion, true)
	await get_tree().process_frame
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = at
		event.pressed = pressed
		get_viewport().push_input(event, true)
		await get_tree().process_frame
	await _settle()


func _settle() -> void:
	for i in 5:
		await get_tree().physics_frame
	await RenderingServer.frame_post_draw


func _shot(name: String) -> void:
	await _settle()
	var screenshot := get_viewport().get_texture().get_image()
	_expect(screenshot.save_png(shot_root.path_join(name + ".png")) == OK, "saved " + name)


func _expect(condition: bool, message: String) -> void:
	assertions += 1
	if not condition:
		failures.append(message)
