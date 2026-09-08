extends SceneTree

const Boot := preload("res://scenes/boot/Boot.tscn")
const Driver := preload("res://scripts/checks/factory_window_driver.gd")
const Codec := preload("res://scripts/factory/save/codec.gd")
var boot: Node
var world: Control
var driver: Node
var run_root := ""
var read_mode := false
var observations: Array[Dictionary] = []


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var batch := ""
	for arg in OS.get_cmdline_user_args():
		if arg == "--read":
			read_mode = true
		if arg.begins_with("--batch="):
			batch = arg.trim_prefix("--batch=")
	assert(batch.is_valid_filename() and not ".." in batch)
	run_root = SliceCheckPaths.check_run("factory-foundation-v1", false).path_join(batch)
	driver = Driver.new()
	driver.shot_root = SliceCheckPaths.repository_root().path_join("assets/art-intake/2026-09-08-factory-foundation-preview").path_join(batch)
	DirAccess.make_dir_recursive_absolute(driver.shot_root)
	root.add_child(driver)
	create_timer(300).timeout.connect(func(): driver.expect(false, "operation window timeout"); finish())
	boot = Boot.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(run_root.path_join("slice"))
	boot.factory_save_root = run_root.path_join("factory")
	root.add_child(boot)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1440, 900)
	await driver.settle(20)
	await driver.click(boot.startup_menu.get_node("ContentRoot/MenuButtons/FactoryButton"))
	if read_mode:
		boot.factory_menu.list.select(0)
		boot.factory_menu.list.item_selected.emit(0)
		# Pause synchronously after Boot reconstructs, before the first process step.
		boot.factory_menu.continue_button.pressed.emit()
		world = boot.factory_world
		if world == null:
			driver.expect(false, "cross-process Boot load")
			finish()
			return
		world.ui.paused = true
	else:
		boot.factory_menu.title_input.text = "双产线正式复测"
		await driver.click(boot.factory_menu.create_button)
		world = boot.factory_world
	driver.world = world
	driver.expect(world != null and world.initialized, "formal world ready")
	if world == null:
		finish()
		return
	if read_mode:
		await _read_path()
	else:
		await _build_path()
	finish()


func _build_line(offset: Vector2i) -> void:
	for spec in [["collector", Vector2i(-8, -1)], ["reactor", Vector2i(-1, -2)], ["storage", Vector2i(6, -1)]]:
		await driver.click(world.hud.buttons[spec[0]])
		await driver.world_click(spec[1] + offset)
		driver.expect(world.model.entity_at(spec[1] + offset).get("type") == spec[0], "build " + spec[0] + str(offset))
	await driver.click(world.hud.buttons.belt)
	await driver.drag([Vector2i(-6, 0) + offset, Vector2i(-2, 0) + offset])
	await driver.drag([Vector2i(2, 0) + offset, Vector2i(2, 2) + offset, Vector2i(4, 2) + offset,
		Vector2i(4, 0) + offset, Vector2i(5, 0) + offset])
	await driver.key(KEY_ESCAPE)


func _build_path() -> void:
	await _build_line(Vector2i.ZERO)
	if not driver.failures.is_empty():
		await driver.shot("failure-first-line")
		return
	await driver.click(world.hud.buttons.belt)
	await driver.motion(driver.cell_screen(Vector2i(-6, 4)))
	await driver.mouse(driver.cell_screen(Vector2i(-6, 4)), true)
	await driver.motion(driver.cell_screen(Vector2i(-3, 4)), true)
	var kits: int = world.model.kits.belt
	await driver.key(KEY_ESCAPE)
	await driver.mouse(driver.cell_screen(Vector2i(-3, 4)), false)
	driver.expect(world.model.kits.belt == kits and world.ui.stroke.is_empty(), "cancel stroke leaves supply unchanged")
	await driver.key(KEY_ESCAPE)
	var before := Vector2(world.actor.x, world.actor.z)
	await driver.key(KEY_S, true)
	var movement_begin := Time.get_ticks_msec()
	while world.actor.z < 16 and Time.get_ticks_msec() - movement_begin < 15000:
		await process_frame
	await driver.key(KEY_S, false)
	driver.expect(world.actor.z >= 16 and Vector2(world.actor.x, world.actor.z).distance_to(before) > 10, "actual key movement to second ore row")
	driver.expect(absf(world.view.target.z - (world.actor.z - 4)) < 0.1, "camera follows expansion movement")
	await _build_line(Vector2i(0, 12))
	if not driver.failures.is_empty():
		await driver.shot("failure-second-line")
		return
	driver.expect(world.model.entities.size() == 32 and world.model.kits.belt == 230, "two independently constructed curved lines")
	await driver.shot("01-two-built-lines")
	await _until(func(): return world.model.entity_at(Vector2i(6, -1)).catalyst > 0 and world.model.entity_at(Vector2i(6, 11)).catalyst > 0, 55, "both real lines deliver")
	await _until(func(): return world.model.entity_at(Vector2i(-1, 10)).processing and world.model.entity_at(Vector2i(2, 14)).cargo == "catalyst", 25, "processing batch plus curved in-flight cargo")
	await driver.click(world.hud.buttons.pause)
	await driver.world_click(Vector2i(2, 14), 0.29)
	driver.expect(world.model.by_id(world.ui.selected).get("x") == 2, "select curved loaded belt")
	await driver.shot("02-second-line-production")
	await driver.click(world.hud.buttons.close_inspector)
	await driver.world_click(Vector2i(-4, 12), 0.29)
	await driver.click(world.hud.buttons.salvage)
	driver.expect(world.model.entity_at(Vector2i(-4, 12)).is_empty(), "salvage exact second-line input")
	driver.expect(world.model.bag.crystal > 0, "salvage recovers carried material")
	var document: Dictionary = Codec.snapshot(world.model, world.store.world_id, world.store.world_name, 1)
	var file := FileAccess.open(run_root.path_join("before-exit.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(document, "", true, true))
	file.close()
	observations.append({"label": "before_exit", "time": world.model.time, "balance": world.model.material_balance()})
	await driver.click(world.hud.buttons.return)
	driver.expect(boot.factory_world == null, "save and leave before ending process")


func _read_path() -> void:
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("before-exit.json")))
	var actual: Dictionary = Codec.snapshot(world.model, world.store.world_id, world.store.world_name, 1)
	driver.expect(_equal(expected, actual), "Boot cross-process counts, progress, cargo, actor and clock restored")
	await driver.shot("03-cross-process-restored")
	var baseline := FileAccess.get_sha256(world.store.path("autosave.json"))
	world.store.fault = func(stage): return stage == "publish"
	await driver.click(world.hud.buttons.return)
	driver.expect(world.failure_dialog.visible and boot.factory_world == world, "failed save return retains paused world")
	driver.expect(FileAccess.get_sha256(world.store.path("autosave.json")) == baseline, "failed exit preserves main")
	world.failure_dialog.get_cancel_button().pressed.emit()
	await driver.settle()
	driver.expect(not world.failure_dialog.visible and world.exit_intent.is_empty(), "cancel failed exit remains in world")
	world.store.fault = Callable()
	await driver.click(world.hud.buttons.save)
	driver.expect(not world.save_failed, "explicit retry succeeds")
	await driver.click(world.hud.buttons.belt)
	await driver.world_click(Vector2i(-4, 12))
	await driver.key(KEY_ESCAPE)
	await driver.click(world.hud.buttons.pause)
	var previous: int = world.model.entity_at(Vector2i(6, 11)).catalyst
	await _until(func(): return world.model.entity_at(Vector2i(6, 11)).catalyst > previous, 35, "same repaired line delivers after process restart")
	await driver.click(world.hud.buttons.pause)
	root.mode = Window.MODE_MAXIMIZED
	await driver.settle(20)
	await driver.click(world.hud.buttons.camera_left)
	await driver.world_click(Vector2i(-1, 10), 1.0)
	driver.expect(world.model.by_id(world.ui.selected).get("type") == "reactor", "maximized rotated ray selects reactor")
	driver.expect(world.hud.subviewport.get_texture().get_image().get_size() == world.hud.subviewport.size, "native maximum world framebuffer")
	await driver.shot("04-maximized-recovered-line")
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1440, 900)
	await driver.settle(20)
	await driver.click(world.hud.buttons.close_inspector)
	await driver.shot("05-restored-window")
	await driver.click(world.hud.buttons.return)
	driver.expect(boot.factory_world == null, "final saved return")


func _until(condition: Callable, seconds: float, label: String) -> void:
	var started: float = world.model.time
	var wall_start := Time.get_ticks_msec()
	while not condition.call() and world.model.time - started < seconds and Time.get_ticks_msec() - wall_start < 120000:
		await process_frame
	driver.expect(condition.call(), label)


func _equal(a: Variant, b: Variant) -> bool:
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size():
			return false
		for key in a:
			if not b.has(key) or not _equal(a[key], b[key]):
				return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size():
			return false
		for i in a.size():
			if not _equal(a[i], b[i]):
				return false
		return true
	if a is float and b is float:
		return absf(a - b) <= 1e-12
	return a == b


func finish() -> void:
	var file := FileAccess.open(run_root.path_join("operation-%s.json" % ("read" if read_mode else "write")), FileAccess.WRITE)
	file.store_string(JSON.stringify({"assertions": driver.assertions, "failures": driver.failures, "observations": observations,
		"scope": "Formal Boot; synthesized mouse/key events and real production time; save dialogs use visible button signals; isolated old/new roots"}, "\t"))
	file.close()
	print("Factory operation %s: %d assertions, %d failures; %s" % ["read" if read_mode else "write", driver.assertions, driver.failures.size(), run_root])
	quit(0 if driver.failures.is_empty() else 1)
