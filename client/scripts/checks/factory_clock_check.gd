extends SceneTree

const Boot := preload("res://scenes/boot/Boot.tscn")
const Clock := preload("res://scripts/factory/active_clock.gd")
const Model := preload("res://scripts/factory/model.gd")
const Codec := preload("res://scripts/factory/save/codec.gd")
var failures: Array[String] = []
var checks := 0
var observations: Array[Dictionary] = []
var world: Control


func _init() -> void:
	call_deferred("_run")


func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)


func _run() -> void:
	var clock := Clock.new()
	var model := Model.new()
	clock.start(1000000, true)
	clock.sample(2174000, true)
	model.advance(clock.consume(), 8)
	expect(absf(model.time + model.remainder - 1.174) < 1e-9, "long frame retained with bounded steps")
	expect(model.time < 0.401 and model.remainder > 0.77, "long frame backlog remains visible")
	clock.sample(2200000, false)
	model.advance(clock.consume(), 0)
	clock.sample(9200000, true)
	expect(clock.consume() == 0, "paused interval excluded")
	clock.sample(9300000, false)
	model.advance(clock.consume(), 0)
	expect(absf(model.time + model.remainder - 1.3) < 1e-9, "sub-frame state transitions preserve active intervals")
	clock.sample(19300000, false)
	expect(clock.consume() == 0, "repeated inactive samples add no production")
	var decoded := Codec.decode(Codec.snapshot(model, "0123456789abcdef0123456789abcdef", "时钟余量", 1), "0123456789abcdef0123456789abcdef")
	expect(decoded.ok, "clock backlog survives codec validation")
	clock.start(90000000, true)
	expect(clock.consume() == 0 and clock.active_usec == 0, "new session has no offline time")

	var run_root := SliceCheckPaths.check_run("factory-foundation-v1", false).path_join("clock-%d-%d" % [Time.get_unix_time_from_system(), OS.get_process_id()])
	DirAccess.make_dir_recursive_absolute(run_root)
	var boot := Boot.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(run_root.path_join("slice"))
	boot.factory_save_root = run_root.path_join("factory")
	root.add_child(boot)
	boot.startup_menu.factory_requested.emit()
	boot.factory_menu.title_input.text = "时钟隔离检查"
	boot.factory_menu.create_button.pressed.emit()
	world = boot.factory_world
	expect(world != null and world.initialized, "clock check enters through formal Boot")
	if world != null:
		# 无窗口中用生命周期信号注入焦点；这不是原生窗口证据。
		root.focus_entered.emit()
		await _frames(4)
		var start := _sample()
		OS.delay_msec(1174)
		await _frames(8)
		var end := _sample()
		var wall: float = (end.usec - start.usec) / 1000000.0
		var model_delta: float = end.accounted - start.accounted
		observations.append({"label": "long_frame", "wall": wall, "model_with_remainder": model_delta,
			"engine_delta": end.engine - start.engine, "error": model_delta - wall})
		expect(absf(model_delta - wall) < 0.00001, "real loop retains stalled wall time")
		expect(world.model.remainder < 0.05, "real loop drains long-frame backlog")
		world._action("pause", null)
		start = _sample()
		OS.delay_msec(180)
		await _frames(3)
		expect(absf(_sample().accounted - start.accounted) < 1e-9, "pause excludes stalled wall time")
		world._action("pause", null)
		root.focus_exited.emit()
		start = _sample()
		OS.delay_msec(180)
		await _frames(3)
		expect(absf(_sample().accounted - start.accounted) < 1e-9, "focus loss excludes time")
		root.focus_entered.emit()
		await _frames(3)
		expect(_sample().accounted - start.accounted < 0.1, "focus return does not catch up inactive time")
		var saved_sequence: int = world.store.sequence
		expect(world.model.place("belt", Vector2i(0, 0)).ok, "dirty command before long frame")
		OS.delay_msec(2050)
		await _frames(8)
		expect(world.store.sequence > saved_sequence, "dirty save uses actual elapsed time across long frame")
		world.store.fault = func(stage):
			if stage == "publish":
				OS.delay_msec(220)
			return false
		start = _sample()
		expect(world._save_now(), "delayed synchronous save succeeds")
		await _frames(4)
		end = _sample()
		wall = (end.usec - start.usec) / 1000000.0
		expect(absf(end.accounted - start.accounted - wall) < 0.00001, "successful active save stall retained")
		observations.append({"label": "save_stall", "wall": wall, "model_with_remainder": end.accounted - start.accounted})
		world.store.fault = func(stage): return stage == "publish"
		world._request_exit("return")
		expect(world.save_failed and world.ui.paused and world.failure_dialog.visible, "failed exit pauses at boundary")
		start = _sample()
		OS.delay_msec(160)
		await _frames(3)
		expect(absf(_sample().accounted - start.accounted) < 1e-9, "failed exit waiting excludes time")
		world.failure_dialog.get_cancel_button().pressed.emit()
		world.store.fault = Callable()
		expect(world._save_now(), "retry save from paused failure")
		expect(world.ui.paused, "save retry does not resume production")
		# 失败弹窗中的重试应完成原退出意图，而不是只隐藏弹窗。
		world.store.fault = func(stage): return stage == "publish"
		world._request_exit("return")
		world.store.fault = Callable()
		world.failure_dialog.get_ok_button().pressed.emit()
		expect(boot.factory_world == null, "dialog retry completes original return and releases world")
		boot.factory_menu.list.select(0)
		boot.factory_menu.list.item_selected.emit(0)
		boot.factory_menu.continue_button.pressed.emit()
		world = boot.factory_world
		expect(world != null and world.initialized, "reenter for discard branch")
		if world != null:
			world._set_paused(true)
			var main_hash := FileAccess.get_sha256(world.store.path("autosave.json"))
			expect(world.model.place("belt", Vector2i(1, 0)).ok, "unsaved command for discard check")
			world.store.fault = func(stage): return stage == "publish"
			world._request_exit("return")
			world.failure_dialog.custom_action.emit("discard")
			expect(world.unsaved_dialog.visible, "discard requires second confirmation")
			world.unsaved_dialog.get_cancel_button().pressed.emit()
			await _frames(2) # AcceptDialog 在 canceled 信号之后延迟 hide。
			expect(not world.unsaved_dialog.visible and boot.factory_world == world, "cancel discard keeps paused world")
			world.failure_dialog.custom_action.emit("discard")
			var main_path: String = world.store.path("autosave.json")
			world.unsaved_dialog.get_ok_button().pressed.emit()
			expect(boot.factory_world == null, "confirmed discard returns without writing")
			expect(FileAccess.get_sha256(main_path) == main_hash, "discard preserves last committed save")
	boot.free()
	var file := FileAccess.open(run_root.path_join("result.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"assertions": checks, "failures": failures, "observations": observations,
		"scope": "Headless Boot; real stalled frames and delayed IO; injected focus signals"}, "\t"))
	file.close()
	print("Factory clock: %d assertions, %d failures; %s" % [checks, failures.size(), run_root])
	for failure in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _sample() -> Dictionary:
	return {"usec": world.production_clock.last_usec, "accounted": world.model.time + world.model.remainder,
		"engine": world.engine_active_seconds}


func _frames(count: int) -> void:
	for i in count:
		await process_frame
