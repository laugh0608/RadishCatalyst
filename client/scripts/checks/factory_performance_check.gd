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
var interrupted := false
var finished := false
var interruption_check := false
var attempted_phases: Array[String] = []
var interrupt_during_sample := false
var load_metrics := {}
var raw_frames: Array[Dictionary] = []
var current_label := ""
var interruption_reason := ""
var sampling_context := {}


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
		if arg == "--check-interruption":
			interruption_check = true
		if arg == "--interrupt-during-sample":
			interrupt_during_sample = true
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
	driver.shot_root = SliceCheckPaths.repository_root().path_join("assets/art-intake/" + Time.get_date_string_from_system() + "-factory-foundation-preview").path_join(run_id)
	DirAccess.make_dir_recursive_absolute(driver.shot_root)
	root.add_child(driver)
	root.focus_exited.connect(_interrupt.bind("focus_lost"))
	root.close_requested.connect(_interrupt.bind("window_closed"))
	boot = Boot.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(run_root.path_join("slice"))
	boot.factory_save_root = run_root.path_join("factory")
	root.add_child(boot)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1920, 1080)
	await _settle(15)
	if interrupted:
		finish()
		return
	boot.startup_menu.factory_requested.emit()
	boot.factory_menu.list.select(0)
	boot.factory_menu.list.item_selected.emit(0)
	var load_begin := Time.get_ticks_usec()
	boot.factory_menu.continue_button.pressed.emit()
	load_metrics.boot_load_ms = (Time.get_ticks_usec() - load_begin) / 1000.0
	await _settle(30)
	if interrupted:
		finish()
		return
	world = boot.factory_world
	driver.world = world
	driver.expect(world != null and world.initialized, "full state from formal Boot")
	if world == null:
		finish()
		return
	var load_ms := (Time.get_ticks_usec() - load_begin) / 1000.0
	load_metrics.load_and_settle_ms = load_ms
	print("Factory full-world Boot load and settle: %.3f ms" % load_ms)
	world.ui.mission = false
	world.ui.build = false
	world._refresh()
	if interruption_check:
		root.focus_entered.emit()
		if not interrupt_during_sample:
			_inject_interruption()
	for spec in [["1080-local", false, 1.0], ["1080-wide", false, 0.45], ["max-local", true, 1.0], ["max-wide", true, 0.45]]:
		if not await _phase(spec[0], spec[1], spec[2]):
			if interruption_check:
				driver.expect(interrupted and attempted_phases == ["1080-local"], "interruption prevents every later phase")
				driver.expect(phases.is_empty() and not world.sample_enabled and not world.model.measure_steps, "no completed samples or trailing phase save after interruption")
			finish()
			return
	world._request_exit("return")
	await _settle()
	finish()


func _phase(label: String, maximized: bool, zoom: float) -> bool:
	if interrupted:
		return false
	attempted_phases.append(label)
	current_label = label
	sampling_context = {}
	raw_frames.clear()
	world.frame_samples.clear()
	world.simulation_samples.clear()
	world.model.step_samples.clear()
	world.save_samples.clear()
	root.mode = Window.MODE_MAXIMIZED if maximized else Window.MODE_WINDOWED
	if not maximized:
		root.size = Vector2i(1920, 1080)
	world.view.zoom = zoom
	world.view.sync_camera()
	await _settle(30)
	if interrupted:
		return false
	if not interruption_check:
		await driver.shot(label)
	if interrupted:
		return false
	await _settle(30) # Exclude screenshot readback and resize warm-up.
	if interrupted or (not interruption_check and not root.has_focus()):
		_interrupt()
		return false
	sampling_context = {"window_pixels": [root.size.x, root.size.y],
		"world_pixels": [world.hud.subviewport.size.x, world.hud.subviewport.size.y], "zoom": world.view.zoom}
	world.sample_enabled = true
	world.model.measure_steps = true
	if interruption_check and interrupt_during_sample:
		_inject_interruption()
	# 与应用已完成的帧边界对齐，避免把尚未处理的一帧记作丢时。
	var started: int = world.production_clock.last_usec
	var previous := started
	var active := 0.0
	var focus_lost := 0.0
	var max_backlog := 0.0
	var draw_calls: Array[float] = []
	var delivered_before: int = world.model.delivered
	var started_simulation: float = world.model.time
	var started_remainder: float = world.model.remainder
	var started_engine: float = world.engine_active_seconds
	last_progress_second = -1
	while active < duration:
		await process_frame
		if interrupted:
			return false
		var now: int = world.production_clock.last_usec
		var delta := (now - previous) / 1000000.0
		previous = now
		if world.focused and (interruption_check or root.has_focus()):
			active += delta
		else:
			focus_lost += delta
			_interrupt()
			return false
		max_backlog = maxf(max_backlog, world.model.remainder)
		draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		raw_frames.append({"wall_seconds": active, "frame_ms": delta * 1000,
			"simulation_seconds": world.model.time - started_simulation, "remainder": world.model.remainder,
			"engine_seconds": world.engine_active_seconds - started_engine,
			"draw_calls": draw_calls.back(), "memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC)})
		var minute := int(active) / 60
		if minute != last_progress_second:
			last_progress_second = minute
			print("Factory sustained progress: %s %.0f/%.0f active seconds; delivered=%d backlog=%.4f" % [label, active, duration, world.model.delivered, world.model.remainder])
		if (now - started) / 1000000.0 > duration + 120:
			driver.expect(false, "foreground timeout " + label)
			break
	world.sample_enabled = false
	world.model.measure_steps = false
	var simulation_seconds: float = world.model.time - started_simulation
	var remainder_change: float = world.model.remainder - started_remainder
	var timing_error: float = simulation_seconds + remainder_change - active
	var raw_file := FileAccess.open(run_root.path_join(label + "-samples.json"), FileAccess.WRITE)
	raw_file.store_string(JSON.stringify({"frames": raw_frames, "simulation_ms": world.simulation_samples,
		"step_ms": world.model.step_samples, "autosaves": world.save_samples, "sampling_context": sampling_context}, "", true, true))
	raw_file.close()
	var save_begin := Time.get_ticks_usec()
	var saved: bool = world._save_now()
	var save_ms := (Time.get_ticks_usec() - save_begin) / 1000.0
	var stats := {"label": label, "active_seconds": active, "focus_lost_seconds": focus_lost,
		"simulation_seconds": simulation_seconds, "remainder_change_seconds": remainder_change,
		"timing_error_seconds": timing_error, "engine_seconds": world.engine_active_seconds - started_engine,
		"delivered_during_phase": world.model.delivered - delivered_before,
		"frame_ms": summary(world.frame_samples), "simulation_ms": summary(world.simulation_samples),
		"step_ms": summary(world.model.step_samples),
		"draw_calls": summary(draw_calls), "max_backlog_seconds": max_backlog, "save_ms": save_ms,
		"window_pixels": [root.size.x, root.size.y], "world_pixels": [world.hud.subviewport.size.x, world.hud.subviewport.size.y],
		"static_memory_bytes": Performance.get_monitor(Performance.MEMORY_STATIC),
		"video_memory_bytes": Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)}
	phases.append(stats)
	driver.expect(saved, "save full load " + label)
	driver.expect(absf(timing_error) <= 0.00001, "active wall time equals simulation plus remainder " + label)
	driver.expect(stats.frame_ms.p95 <= 16.7, "frame p95 budget " + label)
	driver.expect(stats.step_ms.p95 <= 10, "step p95 budget " + label)
	driver.expect(max_backlog < 0.5, "no sustained simulation backlog " + label)
	if active_fixture:
		driver.expect(stats.delivered_during_phase > 0, "actual sustained production " + label)
	print("Factory performance phase: ", JSON.stringify(stats))
	return driver.failures.is_empty()


func _interrupt(reason := "focus_unavailable") -> void:
	if interrupted or finished:
		return
	interrupted = true
	interruption_reason = reason
	if is_instance_valid(world):
		world.sample_enabled = false
		world.model.measure_steps = false
	if not interruption_check:
		driver.expect(false, "窗口失焦或关闭，验证已中断；不请求焦点，不继续后续阶段。")


func _settle(frames := 5) -> void:
	for i in frames:
		if interrupted:
			return
		await process_frame


func _inject_interruption() -> void:
	await process_frame
	await process_frame
	if interrupt_during_sample:
		var began := Time.get_ticks_usec()
		while world.model.step_samples.is_empty() and Time.get_ticks_usec() - began < 2000000:
			await process_frame
		driver.expect(not world.model.step_samples.is_empty(), "real simulation step before sampled interruption")
		driver.expect(world._save_now(), "real sampled save before interruption")
	root.focus_exited.emit()


func summary(values: Array[float]) -> Dictionary:
	if values.is_empty():
		return {"count": 0}
	var sorted := values.duplicate()
	sorted.sort()
	return {"count": sorted.size(), "p50": sorted[int((sorted.size() - 1) * 0.5)],
		"p95": sorted[int((sorted.size() - 1) * 0.95)], "p99": sorted[int((sorted.size() - 1) * 0.99)], "max": sorted.back()}


func finish() -> void:
	if finished:
		return
	finished = true
	if interrupted:
		var partial := FileAccess.open(run_root.path_join("interrupted-samples.json"), FileAccess.WRITE)
		partial.store_string(JSON.stringify({"label": current_label, "reason": interruption_reason,
			"frames": raw_frames, "sampling_context": sampling_context,
			"simulation_ms": world.simulation_samples if is_instance_valid(world) else [],
			"step_ms": world.model.step_samples if is_instance_valid(world) else [],
			"autosaves": world.save_samples if is_instance_valid(world) else []}, "", true, true))
		partial.close()
	var file := FileAccess.open(run_root.path_join("result.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"phases": phases, "failures": driver.failures, "engine": Engine.get_version_info(),
		"interrupted": interrupted, "interruption_check": interruption_check, "attempted_phases": attempted_phases,
		"interruption_reason": interruption_reason,
		"assertions": driver.assertions, "load": load_metrics,
		"renderer": RenderingServer.get_current_rendering_method(), "adapter": RenderingServer.get_video_adapter_name(),
		"cpu": OS.get_processor_name(), "memory": OS.get_memory_info(),
		"scope": "Active production fixture" if active_fixture else "Full backpressure fixture",
		"sampling": "Actual foreground wall time; all frame intervals retained including autosave stalls; GPU time unavailable"}, "\t"))
	file.close()
	print("Factory performance result: " + run_root)
	quit(0 if driver.failures.is_empty() else 1)
