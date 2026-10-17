extends "res://scripts/checks/factory_performance_check.gd"

const Layout := preload("res://scripts/checks/factory_engineering_layout.gd")
const Compare := preload("res://scripts/checks/factory_discovery_check.gd")
var mode := ""
var prepared := {}
var interrupt_at := "before"
var verification := []
var camera_route := {}


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): run_root = arg.trim_prefix("--evidence=")
		if arg.begins_with("--mode="): mode = arg.trim_prefix("--mode=")
		if arg.begins_with("--interrupt-at="): interrupt_at = arg.trim_prefix("--interrupt-at=")
	if run_root.is_empty(): quit(2); return
	driver = Driver.new()
	root.add_child(driver)
	auto_accept_quit = false
	duration = 12
	active_fixture = true
	if mode == "boot-restore":
		var checkpoints: Array = read_json("checkpoints.json")
		for row in checkpoints:
			prepared = read_json("checkpoints/" + row.source)
			if not await load_world(row.source.trim_suffix(".json")): break
			world.model.advance(1, 20)
			var expected: Dictionary = read_json("checkpoints/" + row.continuation)
			driver.expect(Compare.equivalent(expected, snapshot()), "Boot exact 20-step continuation " + row.source)
			driver.expect(world._save_now(), "Boot formal save checkpoint " + row.source)
			var saved := Codec.snapshot(world.model, world.store.world_id, world.store.world_name, world.store.sequence)
			var published: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(world.store.root.path_join(world.store.world_id).path_join("autosave.json")))
			driver.expect(Compare.equivalent(saved, published), "actual published save matches model " + row.source)
			verification.append({"checkpoint": row.source, "sequence": world.store.sequence,
				"ticks": world.model.statistics.ticks, "entities": world.model.entities.size()})
			await close_world()
		finish()
		return
	prepared = read_json("source.json")
	if mode == "short-window":
		driver.shot_root = SliceCheckPaths.repository_root().path_join("assets/art-intake/" + Time.get_date_string_from_system() + "-factory-engineering-preview").path_join(run_root.get_file())
		DirAccess.make_dir_recursive_absolute(driver.shot_root)
		var gate := preload("res://scripts/checks/factory_diagnostic_gate.gd")
		if not await gate.wait_for_start(self, "异星催化 · D4-S0 工程规模短窗", "工程规模验证：100 台生产/仓储、1,000 段带。\n窗口/最大化 × 局部/拉远，每档 12 秒；不是 30 分钟验收。\n点击开始后保持前台；失焦或关闭停止全部后续档位。", "开始工程规模短窗"):
			_interrupt("start_not_confirmed")
			finish()
			return
	else:
		interruption_check = true
		Engine.max_fps = 60
	root.focus_exited.connect(_interrupt.bind("focus_lost"))
	root.close_requested.connect(_interrupt.bind("window_closed"))
	if not await load_world("continuous"):
		finish()
		return
	if mode == "interrupt":
		await verify_interruption()
		finish()
		return
	camera_route = Layout.walk(world.model, Vector2(-4.5, 1.5))
	driver.expect(camera_route.ok, "actual collision movement to central camera position")
	world._refresh()
	world._set_paused(false)
	for spec in [["1080-local", false, 1.0], ["1080-wide", false, 0.45], ["max-local", true, 1.0], ["max-wide", true, 0.45]]:
		if not await _phase(spec[0], spec[1], spec[2]):
			finish()
			return
	await close_world()
	finish()


func read_json(path: String) -> Variant:
	return JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join(path)))


func write_json(path: String, value: Variant) -> void:
	var file := FileAccess.open(run_root.path_join(path), FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "\t", false, true))
	file.close()


func snapshot() -> Dictionary:
	return Codec.snapshot(world.model, prepared.world_id, prepared.name, int(prepared.sequence))


func load_world(label: String) -> bool:
	var isolated := run_root.path_join(label)
	var world_root := isolated.path_join("factory").path_join(prepared.world_id)
	DirAccess.make_dir_recursive_absolute(world_root)
	write_json(label + "/factory/" + prepared.world_id + "/autosave.json", prepared)
	boot = Boot.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(isolated.path_join("slice"))
	boot.factory_save_root = isolated.path_join("factory")
	boot.factory_engineering_context = true
	root.add_child(boot)
	await _settle(10)
	if interrupted: return false
	boot.startup_menu.factory_requested.emit()
	boot.factory_menu.list.select(0)
	boot.factory_menu.list.item_selected.emit(0)
	var began := Time.get_ticks_usec()
	boot.factory_menu.continue_button.pressed.emit()
	world = boot.factory_world
	driver.world = world
	driver.expect(world != null and world.initialized, "formal isolated Boot engineering world " + label)
	if world == null: return false
	# Freeze before yielding a single process frame; the complete first state is compared.
	world.ui.paused = true
	world.production_clock.start(Time.get_ticks_usec(), false)
	driver.expect(Compare.equivalent(prepared, snapshot()), "exact complete first restored frame " + label)
	load_metrics[label] = {"boot_load_ms": (Time.get_ticks_usec() - began) / 1000.0, "sequence": world.store.sequence}
	world.ui.mission = false
	world.ui.build = false
	world._refresh()
	return driver.failures.is_empty() and not interrupted


func close_world() -> void:
	world._set_paused(true)
	world._request_exit("return")
	driver.expect(boot.factory_world == null, "world saved and released")
	await _settle()
	boot.queue_free()
	await _settle()


func verify_interruption() -> void:
	if interrupt_at == "before": root.focus_exited.emit()
	else:
		root.focus_entered.emit()
		world._set_paused(false)
		interrupt_during_sample = true
	var completed := await _phase("interruption", false, 1.0)
	driver.expect(not completed and interrupted and phases.is_empty(), "interruption never completes a phase")
	driver.expect(not world.sample_enabled and not world.model.measure_steps, "interruption disables all sampling")
	driver.expect(attempted_phases == ([] if interrupt_at == "before" else ["interruption"]), "interruption at expected boundary")
	var attempted := attempted_phases.duplicate()
	driver.expect(not await _phase("must-not-run", false, 1.0) and attempted_phases == attempted, "no later phase after interruption")


func _inject_interruption() -> void:
	await process_frame
	await process_frame
	var began := Time.get_ticks_usec()
	while world.model.step_samples.is_empty() and Time.get_ticks_usec() - began < 2000000: await process_frame
	driver.expect(not world.model.step_samples.is_empty(), "actual step before injected interruption")
	driver.expect(world._save_now(), "actual save before injected interruption")
	if interrupt_at == "close": root.close_requested.emit()
	else: root.focus_exited.emit()


func _delivery_count() -> int:
	var total := 0
	for amount in world.model.statistics.totals.delivered.values(): total += int(amount)
	return total


func finish() -> void:
	if finished: return
	super.finish()
	var report: Dictionary = read_json("result.json")
	report.mode = mode
	report.scope = "D4-S0 engineering 100 production/storage, 1000 belts; 12-second screening only; NOT S1 sustained acceptance"
	report.sustained_acceptance = false
	report.short_screening_passed = mode == "short-window" and phases.size() == 4 and not interrupted and driver.failures.is_empty()
	report.verification = verification
	report.camera_route = camera_route
	report.interrupt_at = interrupt_at if mode == "interrupt" else ""
	if mode == "boot-restore": report.sampling = "Headless formal Boot first-frame and explicit 20-step continuation; no performance samples"
	if mode == "interrupt": report.sampling = "Headless synthetic interruption with real clock step/save; no performance claim"
	write_json("result.json", report)
	if is_instance_valid(world):
		world.ui.paused = true
		world.production_clock.start(Time.get_ticks_usec(), false)
		world.store.release()
