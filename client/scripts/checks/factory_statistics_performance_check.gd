extends "res://scripts/checks/factory_performance_check.gd"

# Reuse the established foreground sampler and budgets without changing its scale fixture.
var source_path := ""
var source_sha256 := ""
var prepared := {}
var fixture_counts := {}
var prepare_only := false


func _run() -> void:
	var batch := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--batch="):
			batch = arg.trim_prefix("--batch=")
		if arg.begins_with("--source="):
			source_path = arg.trim_prefix("--source=")
		prepare_only = prepare_only or arg == "--prepare-only"
	assert(batch.is_valid_filename() and not ".." in batch)
	run_root = SliceCheckPaths.repository_root().path_join("tools/runtime-intake/check-runs/factory-statistics-v1").path_join(batch)
	DirAccess.make_dir_recursive_absolute(run_root)
	driver = Driver.new()
	root.add_child(driver)
	duration = 45.0
	active_fixture = true
	if not FileAccess.file_exists(source_path):
		driver.expect(false, "explicit source snapshot exists")
		finish()
		return
	source_sha256 = FileAccess.get_sha256(source_path)
	var source: Variant = JSON.parse_string(FileAccess.get_file_as_string(source_path))
	if not source is Dictionary or source.get("save_schema_version") != 2:
		driver.expect(false, "source is a schema 2 snapshot")
		finish()
		return
	var decoded := Codec.decode(source, source.world_id)
	driver.expect(decoded.ok, "source passes unchanged save contract")
	if not decoded.ok:
		finish()
		return
	var model: RefCounted = decoded.model
	# Preparation only: real model steps fill all 600 history buckets before foreground sampling.
	model.advance(600.0, 12000)
	model.statistics_ui.window_seconds = 600
	prepared = Codec.snapshot(model, source.world_id, "D4 普通供给统计对照", 1)
	driver.expect(Codec.decode(prepared, source.world_id).ok, "prepared full history passes save contract")
	driver.expect(model.statistics.buckets.size() == 600, "full 600 second history retained")
	for e in model.entities:
		fixture_counts[e.type] = fixture_counts.get(e.type, 0) + 1
	write_json("prepared.json", prepared)
	if prepare_only or not driver.failures.is_empty():
		finish()
		return
	driver.shot_root = SliceCheckPaths.repository_root().path_join("assets/art-intake/" + Time.get_date_string_from_system() + "-factory-statistics-preview").path_join(batch)
	DirAccess.make_dir_recursive_absolute(driver.shot_root)
	var gate := preload("res://scripts/checks/factory_diagnostic_gate.gd")
	if not await gate.wait_for_start(self, "异星催化 · D4 统计对照准备", "普通供给同状态对照：关闭统计 / 物料 / 电力各 45 秒。\n点击开始后请保持前台；失焦或关闭即终止，不自动重开。"):
		_interrupt("start_not_confirmed")
		finish()
		return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1920, 1080)
	root.focus_exited.connect(_interrupt.bind("focus_lost"))
	root.close_requested.connect(_interrupt.bind("window_closed"))
	for label in ["closed", "materials", "power"]:
		if not await load_phase(label):
			finish()
			return
		if not await _phase(label, false, 1.0):
			finish()
			return
		world._request_exit("return")
		await _settle()
		boot.queue_free()
		await _settle()
	finish()


func load_phase(label: String) -> bool:
	var isolated := run_root.path_join(label)
	var world_root := isolated.path_join("factory").path_join(prepared.world_id)
	DirAccess.make_dir_recursive_absolute(world_root)
	var file := FileAccess.open(world_root.path_join("autosave.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(prepared, "", true, true))
	file.close()
	boot = Boot.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(isolated.path_join("slice"))
	boot.factory_save_root = isolated.path_join("factory")
	root.add_child(boot)
	await _settle(20)
	if interrupted:
		return false
	boot.startup_menu.factory_requested.emit()
	boot.factory_menu.list.select(0)
	boot.factory_menu.list.item_selected.emit(0)
	var began := Time.get_ticks_usec()
	boot.factory_menu.continue_button.pressed.emit()
	load_metrics[label] = {"boot_load_ms": (Time.get_ticks_usec() - began) / 1000.0}
	world = boot.factory_world
	driver.world = world
	driver.expect(world != null and world.initialized, "formal Boot restores paired state " + label)
	if world == null:
		return false
	world.ui.mission = false
	world.ui.build = false
	world._refresh()
	if label != "closed":
		world._action("statistics", null)
		world.statistics_panel.page.select(0 if label == "materials" else 1)
		world.statistics_panel.selected_item = "catalyst"
		world.statistics_panel.refresh()
	driver.expect(world.statistics_panel.visible == (label != "closed"), "expected overlay state " + label)
	return not interrupted and driver.failures.is_empty()


func _delivery_count() -> int:
	var count := 0
	for amount in world.model.statistics.totals.delivered.values():
		count += int(amount)
	return count


func write_json(name: String, data: Variant) -> void:
	var file := FileAccess.open(run_root.path_join(name), FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t", false, true))


func finish() -> void:
	if finished:
		return
	# The inherited sampler preserves all raw samples, saves and interruptions.
	super.finish()
	var report: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("result.json")))
	report.scope = "Schema 2 ordinary supply; paired identical starting snapshot; NOT 100 machines / 1000 belts or sustained acceptance"
	report.source = {"path": source_path, "sha256": source_sha256}
	report.fixture_counts = fixture_counts
	report.preparation = "600 simulated seconds before sampling; all 600 history buckets retained; foreground phases run at real time"
	report.prepare_only = prepare_only
	report.phase_seconds = duration
	report.delivery_metric = "All materials actually delivered into storage; schema 2 authoritative statistics.totals.delivered"
	report.input = "Formal Boot menu signals; statistics action and page selection; camera fixed; no manual playtest claim"
	write_json("result.json", report)
