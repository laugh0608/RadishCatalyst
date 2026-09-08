extends SceneTree

const Boot := preload("res://scenes/boot/Boot.tscn")
const Codec := preload("res://scripts/factory/save/codec.gd")
const Driver := preload("res://scripts/checks/factory_window_driver.gd")
const Fixture := preload("res://scripts/checks/factory_load_fixture.gd")
var boot: Node
var world: Control
var driver: Node
var run_root := ""
var phases: Array[Dictionary] = []
var duration := 12.0
var active_fixture := false
var last_progress_second := -1


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var base := SliceCheckPaths.check_run("factory-foundation-v1", false)
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base.path_join("scale-full-state.json")))
	var run_id := "performance-%d-%d" % [Time.get_unix_time_from_system(), OS.get_process_id()]
	run_root = base.path_join(run_id)
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--phase-seconds="):
			duration = float(arg.trim_prefix("--phase-seconds="))
		if arg == "--active":
			active_fixture = true
	if active_fixture:
		var fixture := Fixture.build()
		assert(fixture.ok)
		source = Codec.snapshot(fixture.model, source.world_id, "首档持续生产", 1)
	var world_root := run_root.path_join("factory").path_join(source.world_id)
	DirAccess.make_dir_recursive_absolute(world_root)
	var file := FileAccess.open(world_root.path_join("autosave.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(source, "", true, true))
	file.close()
	driver = Driver.new()
	driver.shot_root = SliceCheckPaths.repository_root().path_join("assets/art-intake/2026-09-08-factory-foundation-preview").path_join(run_id)
	DirAccess.make_dir_recursive_absolute(driver.shot_root)
	root.add_child(driver)
	boot = Boot.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(run_root.path_join("slice"))
	boot.factory_save_root = run_root.path_join("factory")
	root.add_child(boot)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1920, 1080)
	await driver.settle(15)
	boot.startup_menu.factory_requested.emit()
	boot.factory_menu.list.select(0)
	boot.factory_menu.list.item_selected.emit(0)
	var load_begin := Time.get_ticks_usec()
	boot.factory_menu.continue_button.pressed.emit()
	await driver.settle(30)
	world = boot.factory_world
	driver.world = world
	driver.expect(world != null and world.initialized, "full state from formal Boot")
	if world == null:
		finish()
		return
	var load_ms := (Time.get_ticks_usec() - load_begin) / 1000.0
	print("Factory full-world Boot load and settle: %.3f ms" % load_ms)
	world.ui.mission = false
	world.ui.build = false
	world._refresh()
	await _phase("1080-local", false, 1.0)
	await _phase("1080-wide", false, 0.45)
	await _phase("max-local", true, 1.0)
	await _phase("max-wide", true, 0.45)
	world._request_exit("return")
	await driver.settle()
	finish()


func _phase(label: String, maximized: bool, zoom: float) -> void:
	root.mode = Window.MODE_MAXIMIZED if maximized else Window.MODE_WINDOWED
	if not maximized:
		root.size = Vector2i(1920, 1080)
	world.view.zoom = zoom
	world.view.sync_camera()
	await driver.settle(30)
	await driver.shot(label)
	await driver.settle(30) # Exclude screenshot readback and resize warm-up.
	world.frame_samples.clear()
	world.simulation_samples.clear()
	world.model.step_samples.clear()
	world.sample_enabled = true
	world.model.measure_steps = true
	var started := Time.get_ticks_usec()
	var previous := started
	var active := 0.0
	var focus_lost := 0.0
	var max_backlog := 0.0
	var draw_calls: Array[float] = []
	var delivered_before: int = world.model.delivered
	var started_simulation: float = world.model.time
	last_progress_second = -1
	while active < duration:
		await process_frame
		var now := Time.get_ticks_usec()
		var delta := (now - previous) / 1000000.0
		previous = now
		if world.focused and root.has_focus():
			active += delta
		else:
			focus_lost += delta
			driver.expect(false, "用户切换窗口，持续验证已中断；不请求焦点。")
			finish()
			return
		max_backlog = maxf(max_backlog, world.model.remainder)
		draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		var minute := int(active) / 60
		if minute != last_progress_second:
			last_progress_second = minute
			print("Factory sustained progress: %s %.0f/%.0f active seconds; delivered=%d backlog=%.4f" % [label, active, duration, world.model.delivered, world.model.remainder])
		if (now - started) / 1000000.0 > duration + 120:
			driver.expect(false, "foreground timeout " + label)
			break
	world.sample_enabled = false
	world.model.measure_steps = false
	var save_begin := Time.get_ticks_usec()
	var saved: bool = world._save_now()
	var save_ms := (Time.get_ticks_usec() - save_begin) / 1000.0
	var stats := {"label": label, "active_seconds": active, "focus_lost_seconds": focus_lost,
		"simulation_seconds": world.model.time - started_simulation,
		"delivered_during_phase": world.model.delivered - delivered_before,
		"frame_ms": summary(world.frame_samples), "step_ms": summary(world.model.step_samples),
		"draw_calls": summary(draw_calls), "max_backlog_seconds": max_backlog, "save_ms": save_ms,
		"window_pixels": [root.size.x, root.size.y], "world_pixels": [world.hud.subviewport.size.x, world.hud.subviewport.size.y],
		"static_memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
		"video_memory_bytes": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)}
	phases.append(stats)
	driver.expect(saved, "save full load " + label)
	driver.expect(stats.frame_ms.p95 <= 16.7, "frame p95 budget " + label)
	driver.expect(stats.step_ms.p95 <= 10, "step p95 budget " + label)
	driver.expect(max_backlog < 0.5, "no sustained simulation backlog " + label)
	if active_fixture:
		driver.expect(stats.delivered_during_phase > 0, "actual sustained production " + label)
	print("Factory performance phase: ", JSON.stringify(stats))


func summary(values: Array[float]) -> Dictionary:
	if values.is_empty():
		return {"count": 0}
	var sorted := values.duplicate()
	sorted.sort()
	return {"count": sorted.size(), "p50": sorted[int((sorted.size() - 1) * 0.5)],
		"p95": sorted[int((sorted.size() - 1) * 0.95)], "p99": sorted[int((sorted.size() - 1) * 0.99)], "max": sorted.back()}


func finish() -> void:
	var file := FileAccess.open(run_root.path_join("result.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"phases": phases, "failures": driver.failures, "engine": Engine.get_version_info(),
		"renderer": RenderingServer.get_current_rendering_method(), "adapter": RenderingServer.get_video_adapter_name(),
		"cpu": OS.get_processor_name(), "memory": OS.get_memory_info(),
		"scope": "Active production fixture" if active_fixture else "Full backpressure fixture",
		"sampling": "Actual foreground wall time; all frame intervals retained including autosave stalls; GPU time unavailable"}, "\t"))
	file.close()
	print("Factory performance result: " + run_root)
	quit(0 if driver.failures.is_empty() else 1)
