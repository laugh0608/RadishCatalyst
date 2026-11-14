extends SceneTree

const Session := preload("res://scripts/prototypes/factory_camera/session.gd")
const Gate := preload("res://scripts/checks/factory_diagnostic_gate.gd")
var demo: Control
var output := ""
var interrupted := false
var failures: Array[String] = []
var checks := 0
var performance: Array[Dictionary] = []


func _init() -> void:
	call_deferred("run")


func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)


func run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.is_empty() or args.size() > 2 or not args[0].is_valid_filename() or "." in args[0] \
			or (args.size() == 2 and args[1] != "--window"):
		push_error("Usage: check-material-study.gd -- <new batch> [--window]")
		quit(2)
		return
	var rendered := args.size() == 2
	var repo := ProjectSettings.globalize_path("res://..").simplify_path()
	output = repo.path_join("tools/runtime-intake/check-runs/factory-material-study-v1/" + args[0])
	var shots := repo.path_join("assets/art-intake/factory-material-study-v1/" + args[0])
	if FileAccess.file_exists(output.path_join("results.json")) or DirAccess.make_dir_recursive_absolute(output) != OK:
		push_error("Use a new writable material-study batch")
		quit(2)
		return
	if rendered and not await Gate.wait_for_start(self, "异星催化 · 材质与场景对照准备页",
			"短时 M0 / M1 对照、操作与帧采样。点击后请保持窗口在前台。", "开始联合复测"):
		quit(2)
		return
	root.mode = Window.MODE_WINDOWED
	root.content_scale_size = Vector2i(1440, 900)
	root.size = Vector2i(1440, 900)
	root.min_size = Vector2i(1100, 720)
	var result := await Session.open(self, output.path_join("isolated"), shots, true, true)
	if result.is_empty():
		quit(1)
		return
	demo = result.demo
	demo.paused = true
	await process_frame
	await verify_modes()
	if rendered and failures.is_empty():
		await frames(4)
		if root.has_focus():
			root.focus_exited.connect(func(): interrupted = true)
			await verify_window()
		else:
			interrupted = true
			expect(false, "Window focus unavailable")
	expect(not DirAccess.dir_exists_absolute(output.path_join("isolated/factory")) and
		not DirAccess.dir_exists_absolute(output.path_join("isolated/slice")), "Both world saves remain absent")
	var file := FileAccess.open(output.path_join("results.json"), FileAccess.WRITE)
	var ok := failures.is_empty() and not interrupted and file != null
	if file != null:
		file.store_string(JSON.stringify({"mode": "window" if rendered else "headless", "checks": checks,
			"failures": failures, "interrupted": interrupted, "captures": demo.captures, "performance": performance}, "\t") + "\n")
	print("MATERIAL_STUDY_CHECKS checks=", checks, " failures=", failures.size(),
		" captures=", demo.captures, " interrupted=", interrupted)
	result.boot.queue_free()
	await process_frame
	quit(0 if ok else 1)


func overrides(parts: Array) -> Array[Material]:
	var result: Array[Material] = []
	for part: MeshInstance3D in parts:
		for i in part.mesh.get_surface_count():
			var material := part.get_surface_override_material(i)
			if material != null: result.append(material)
	return result


func device_parts(id: int) -> Array:
	return demo.view.models[id].focus_parts


func verify_modes() -> void:
	var view: Node3D = demo.view
	var core_parts: Array = view.core.parts
	var original := []
	for part: MeshInstance3D in core_parts:
		original.append(part.mesh.surface_get_material(0))
	var original_camera: Dictionary = view.camera_state()
	expect(view.material_mode == 0 and overrides(core_parts).is_empty(), "M0 starts on imported materials")
	expect(overrides(view.yard_parts).is_empty(), "M0 uses original ground")
	var reactor: int = demo.board.entity_at(Vector2i(5, -1)).id
	var belt: int = demo.board.entity_at(Vector2i(-2, -4)).id
	var belt_parts := device_parts(belt)
	var markers: Array = demo.hud.marker_points.duplicate()
	demo.act("material", 1)
	await process_frame
	expect(overrides(core_parts).size() == 4, "Core shell, structure and both tier modules receive overrides")
	expect(overrides(device_parts(reactor)).size() == 4, "Representative reactor receives four overrides")
	expect(overrides(belt_parts).size() == 2, "Belt shares trim and retains routing markings")
	expect(overrides(view.yard_parts).size() == 3, "Rock overrides three ground surfaces")
	var rock := overrides(view.yard_parts)[0] as StandardMaterial3D
	expect(rock.normal_enabled and rock.normal_texture.get_image().has_mipmaps(), "Rock imports linear normal and mips")
	var equipment := overrides(core_parts)
	expect(view.camera_state() == original_camera and demo.hud.marker_points == markers, "M1 retains camera and port anchors")
	demo.act("material", 2)
	await process_frame
	var work := overrides(view.yard_parts)[0] as StandardMaterial3D
	expect(work != rock and not work.normal_enabled and work.albedo_texture.get_image().has_mipmaps(), "Work surface switches only ground")
	expect(overrides(core_parts) == equipment, "Ground switch shares the same equipment resources")
	demo.act("board", "D")
	await process_frame
	var dense_reactors := 0
	for e in demo.board.entities:
		if e.type == "reactor" and overrides(device_parts(e.id)).size() == 4: dense_reactors += 1
	expect(dense_reactors == 16 and not view.core.visible, "Dense rebuild keeps representative reactor materials")
	demo.act("board", "P")
	await process_frame
	expect(view.core.visible and overrides(core_parts) == equipment, "Returning to P retains M1")
	demo.act("material", 0)
	await process_frame
	expect(overrides(core_parts).is_empty() and overrides(view.yard_parts).is_empty(), "M0 restores core and ground")
	expect(overrides(device_parts(reactor)).is_empty() and overrides(device_parts(belt)).is_empty(), "M0 restores reactor and belt")
	for i in core_parts.size():
		expect(core_parts[i].mesh.surface_get_material(0) == original[i], "Imported core material remains shared and unchanged")


func frames(count: int) -> void:
	for _i in count:
		if interrupted: return
		await process_frame
		await RenderingServer.frame_post_draw


func capture() -> void:
	await frames(4)
	if not interrupted: await demo.capture()


func key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	Input.flush_buffered_events()


func tap(code: Key) -> void:
	key(code, true)
	key(code, false)


func click_at(point: Vector3) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = demo.hud.ui_point(demo.view.project(point))
	demo.world_input(event)


func verify_window() -> void:
	# Fixed P and D pairs; no scene, light or camera changes within a pair.
	await capture()
	demo.act("material", 1)
	await capture()
	demo.act("material", 2)
	await capture()
	demo.act("board", "D")
	demo.act("material", 0)
	await capture()
	demo.act("material", 1)
	await capture()
	if interrupted: return
	var viewport: SubViewport = demo.hud.viewport
	RenderingServer.viewport_set_measure_render_time(viewport.get_viewport_rid(), true)
	for mode in [0, 1, 1, 0]:
		if interrupted: break
		await sample_performance(viewport, mode)
	RenderingServer.viewport_set_measure_render_time(viewport.get_viewport_rid(), false)
	if interrupted: return
	expect(performance.size() == 4 and performance.all(func(group): return group.samples.size() == 60),
		"Four paired foreground samples without capture interference")
	demo.act("material", 2)
	demo.paused = false
	key(KEY_W, true)
	await frames(55)
	key(KEY_W, false)
	demo.paused = true
	if interrupted: return
	expect(demo.board.actor.z >= 7.28 and demo.board.actor.z < 8.0 and demo.input_moves > 0, "Dense W movement stops at collision")
	await capture()
	demo.act("board", "P")
	demo.act("span", 16)
	demo.paused = false
	key(KEY_W, true)
	await frames(55)
	key(KEY_W, false)
	demo.paused = true
	if interrupted: return
	expect(demo.board.actor.z >= 3.29 and demo.board.actor.z < 3.4, "Approaching the core stops at south collision")
	tap(KEY_F)
	await frames(2)
	expect(demo.selected == -2, "F selects the core under M1")
	var south_port: Dictionary = demo.view.core.ports.filter(func(port): return port.id == "OUT_S0")[0]
	click_at(south_port.probe)
	expect(demo.selected_port == "OUT_S0", "South output picking stays aligned")
	await capture()
	tap(KEY_B)
	tap(KEY_R)
	var count: int = demo.board.entities.size()
	click_at(Vector3(-5.5, 0, 4.5))
	await frames(3)
	expect(demo.measuring and demo.cell == Vector2i(-6, 4) and demo.direction == 1
		and demo.view.preview.get_child_count() > 0 and demo.board.entities.size() == count,
		"Build preview cell and rotation align without placing an entity")
	await capture()
	tap(KEY_ESCAPE)
	demo.act("reset", null)
	demo.act("window", Vector2i(1100, 720))
	demo.act("span", 21)
	demo.act("ports", null)
	await capture()
	var state: Dictionary = demo.state()
	expect(root.size == Vector2i(1100, 720) and viewport.size.x == 1100, "Minimum native window and 3D width")
	expect(state.core.ports.size() == 16 and state.core.ports.values().all(func(port): return not port.probe_blocked_by_core),
		"Minimum-window port samples remain unoccluded by core")
	var output_rects: Array[Rect2] = []
	for marker in demo.hud.markers:
		if marker.visible and marker.size.x == 18: output_rects.append(marker.get_rect())
	expect(output_rects.size() == 4, "All four sample output icons shown")
	for i in output_rects.size():
		for j in range(i + 1, output_rects.size()):
			expect(not output_rects[i].intersects(output_rects[j]), "Output markers do not overlap")
	demo.act("core_names", null)
	demo.act("span", 16)
	await capture()
	expect(demo.view.core.names_visible and demo.hud.markers.all(func(marker): return not marker.visible),
		"ID inspection is separate from sample icon display")
	demo.act("ports", null)
	await frames(2)
	expect(not demo.view.core.names_visible and demo.hud.ports_visible, "Marker inspection restores icons without ID overlap")
	expect(demo.captures == 10, "All planned views captured")


func sample_performance(viewport: SubViewport, mode: int) -> void:
	demo.act("material", mode)
	await frames(45)
	var rid := viewport.get_viewport_rid()
	var samples := []
	var stamp := Time.get_ticks_usec()
	for _i in 60:
		await RenderingServer.frame_post_draw
		if interrupted: return
		var next := Time.get_ticks_usec()
		samples.append({"wall_ms": (next - stamp) / 1000.0,
			"render_cpu_ms": RenderingServer.viewport_get_measured_render_time_cpu(rid),
			"render_gpu_ms": RenderingServer.viewport_get_measured_render_time_gpu(rid),
			"draw_calls": viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
			"triangles": viewport.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME)})
		stamp = next
	performance.append({"mode": mode, "board": demo.board.board_id, "viewport": [viewport.size.x, viewport.size.y],
		"warmup_frames": 45, "samples": samples})
