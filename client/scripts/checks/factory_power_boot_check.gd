extends SceneTree

const Boot := preload("res://scenes/boot/Boot.tscn")
const Driver := preload("res://scripts/checks/factory_window_driver.gd")
const Codec := preload("res://scripts/factory/save/codec.gd")
var boot: Node
var world: Control
var driver: Node
var run_root := ""
var read_mode := false
var dialog_only := false
var expand_load := false
var observations: Array = []


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var batch := ""
	for arg in OS.get_cmdline_user_args():
		if arg == "--expand":
			expand_load = true
		if arg == "--dialogs":
			dialog_only = true
			read_mode = true
		if arg == "--read":
			read_mode = true
		if arg.begins_with("--batch="):
			batch = arg.trim_prefix("--batch=")
	assert(batch.is_valid_filename() and not ".." in batch)
	var repo := SliceCheckPaths.repository_root()
	run_root = repo.path_join("tools/runtime-intake/check-runs/factory-power-v1").path_join(batch)
	driver = Driver.new()
	driver.shot_root = repo.path_join("assets/art-intake/2026-09-25-factory-power-preview").path_join(batch)
	DirAccess.make_dir_recursive_absolute(driver.shot_root)
	DirAccess.make_dir_recursive_absolute(run_root)
	root.add_child(driver)
	create_timer(150).timeout.connect(func(): driver.expect(false, "power Boot timeout"); finish())
	boot = Boot.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(run_root.path_join("slice"))
	boot.factory_save_root = run_root.path_join("factory")
	root.add_child(boot)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1440, 900)
	await driver.settle(30)
	await driver.click(boot.startup_menu.get_node("ContentRoot/MenuButtons/FactoryButton"))
	if read_mode:
		boot.factory_menu.list.select(0)
		boot.factory_menu.list.item_selected.emit(0)
		boot.factory_menu.continue_button.pressed.emit()
		world = boot.factory_world
		if world != null:
			world.ui.paused = true # Compare before the first process step.
	else:
		boot.factory_menu.world_type.select(1)
		boot.factory_menu.title_input.text = "电力首线隔离复核"
		await driver.click(boot.factory_menu.create_button)
		world = boot.factory_world
	driver.world = world
	driver.expect(world != null and world.initialized, "formal Boot new/load")
	if world == null:
		finish()
		return
	if dialog_only:
		world.view.zoom = 0.72
		await driver.settle(15)
		world.view.sync_camera()
		await branch_path(16, [17, 18])
		await driver.click(world.hud.buttons.return)
	elif read_mode:
		await read_path()
	else:
		await write_path()
	finish()


func place(type: String, x: int, z: int) -> void:
	await driver.click(world.hud.buttons[type])
	world.hud.cell_x.value = x
	world.hud.cell_z.value = z
	await driver.settle()
	await driver.click(world.hud.buttons.place)
	driver.expect(world.model.entity_at(Vector2i(x, z)).get("type") == type, "precision UI placement " + type)


func select(id: int) -> void:
	if dialog_only:
		world.ui.selected = id # Targeted modal test; world mouse selection covered by write/read paths.
		world._refresh()
		await driver.settle()
		return
	var e: Dictionary = world.model.by_id(id)
	await driver.world_click(Vector2i(e.x, e.z), 0.4)
	driver.expect(world.ui.selected == id, "mouse selection #%d" % id)


func connect_nodes(a: int, b: int) -> void:
	await select(a)
	if not driver.failures.is_empty():
		return
	await driver.click(world.hud.buttons.power_connect)
	var target: Dictionary = world.model.by_id(b)
	driver.expect(not target.is_empty(), "connection target exists")
	if target.is_empty():
		return
	await driver.world_click(Vector2i(target.x, target.z), 0.4)
	await driver.key(KEY_ESCAPE)
	driver.expect([mini(a, b), maxi(a, b)] in world.model.power_links or target.get("power_node_id", 0) == a, "UI connection %d -> %d" % [a, b])


func active(seconds: float) -> bool:
	var target: float = world.model.time + seconds
	var started := Time.get_ticks_usec()
	while world.model.time < target:
		await process_frame
		if not root.has_focus():
			driver.expect(false, "focus lost: stop window validation")
			return false
	observations.append({"active_seconds": seconds, "wall_seconds": (Time.get_ticks_usec() - started) / 1000000.0, "time": world.model.time, "generated": world.model.generated, "completed": world.model.completed, "delivered": world.model.delivered, "used_kj": world.model.statistics.totals.used_kj})
	return true


func write_path() -> void:
	driver.expect(world.model.entities.is_empty() and world.model.generated == 0, "ordinary new world zero injected materials")
	await driver.click(world.hud.buttons.pause)
	# Camera positioning only; construction and wiring go through the real UI.
	world.actor.x = -13
	world.actor.z = 5.7
	world.view.zoom = 0.72
	world.view.sync_camera()
	for spec in [["collector", -20, -1], ["reactor", -13, -2], ["storage", -6, -1], ["power_source", -20, -6], ["power_junction", -13, -5]]:
		await place(spec[0], spec[1], spec[2])
	await driver.click(world.hud.buttons.belt)
	await driver.drag([Vector2i(-18, 0), Vector2i(-14, 0)])
	await driver.drag([Vector2i(-10, 0), Vector2i(-7, 0)])
	await driver.key(KEY_ESCAPE)
	await select(1)
	await driver.shot("01-unwired")
	driver.expect(world.model.feedback(world.model.by_id(1)).power == "未接线", "unwired feedback")
	if not driver.failures.is_empty():
		return
	await connect_nodes(4, 1)
	await connect_nodes(4, 5)
	await connect_nodes(5, 2)
	await select(2)
	await driver.click(world.hud.buttons.pause)
	if not await active(20):
		return
	driver.expect(world.model.completed >= 1, "real-time ordinary production")
	await driver.shot("02-powered-production")
	await select(4)
	await driver.click(world.hud.buttons.power_toggle)
	var energy: float = world.model.statistics.totals.used_kj
	var progress: float = world.model.by_id(2).progress
	var batch: int = world.model.next_batch
	var delivered: int = world.model.delivered
	if not await active(6):
		return
	driver.expect(is_equal_approx(world.model.statistics.totals.used_kj, energy), "blackout no energy")
	driver.expect(is_equal_approx(world.model.by_id(2).progress, progress) and world.model.next_batch == batch, "blackout holds work and batch")
	driver.expect(world.model.delivered > delivered, "passive belts deliver old output while power off")
	await select(2)
	await driver.shot("03-blackout")
	await select(4)
	await driver.click(world.hud.buttons.power_toggle)
	if not await active(2):
		return
	await driver.click(world.hud.buttons.pause)
	var paused: Dictionary = world.model.statistics.snapshot()
	await create_timer(0.3).timeout
	driver.expect(world.model.statistics.snapshot() == paused, "pause freezes energy and history")
	await select(2)
	await driver.shot("04-resumed-half-batch")
	driver.expect(world.model.by_id(2).processing, "save in-flight batch")
	await driver.click(world.hud.buttons.save)
	var expected: Dictionary = Codec.snapshot(world.model, world.store.world_id, world.store.world_name, world.store.sequence)
	write_json("expected.json", expected)
	var clone: RefCounted = Codec.decode(expected, world.store.world_id).model
	clone.advance(20)
	write_json("trajectory.json", Codec.snapshot(clone, world.store.world_id, world.store.world_name, world.store.sequence))
	await driver.click(world.hud.buttons.return)
	driver.expect(boot.factory_world == null, "save return releases session")


func read_path() -> void:
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("expected.json")))
	var restored: Dictionary = Codec.snapshot(world.model, world.store.world_id, world.store.world_name, expected.sequence)
	driver.expect(equivalent(restored, expected), "independent Boot exact snapshot before first frame")
	var clone: RefCounted = Codec.decode(restored, world.store.world_id).model
	clone.advance(20)
	var target: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("trajectory.json")))
	driver.expect(equivalent(Codec.snapshot(clone, world.store.world_id, world.store.world_name, expected.sequence), target), "independent process forward trajectory")
	world.view.zoom = 0.72
	world.ui.selected = 2
	await driver.settle(10)
	await driver.shot("05-cross-process-restored")
	await driver.click(world.hud.buttons.pause)
	if not await active(5):
		return
	driver.expect(world.model.statistics.totals.used_kj > expected.state.statistics.totals.used_kj, "restored world resumes real energy")
	if expand_load:
		await overload_path()
	await driver.click(world.hud.buttons.return)


func write_json(name: String, value: Variant) -> void:
	var file := FileAccess.open(run_root.path_join(name), FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "\t", false, true))
	file.close()


func finish() -> void:
	write_json("read-result.json" if read_mode else "write-result.json", {"assertions": driver.assertions, "failures": driver.failures, "observations": observations, "dialog_only": dialog_only, "input": "synthetic mouse; dialogs use explicit button keyboard focus and synthetic Enter; dialog-only uses direct entity selection; precision SpinBox values; camera actor reposition; read pauses before first frame"})
	print("Power Boot checks: %d assertions, %d failures" % [driver.assertions, driver.failures.size()])
	quit(0 if driver.failures.is_empty() else 1)


func overload_path() -> void:
	await driver.click(world.hud.buttons.pause)
	await select(1)
	await driver.click(world.hud.buttons.salvage)
	driver.expect(world.model.bag.crystal >= 4, "harvested material recovered, no injected inputs")
	await place("collector", -20, -1)
	if not driver.failures.is_empty():
		return
	var collector: int = world.ui.selected
	await connect_nodes(4, collector)
	await place("power_junction", -14, 1)
	var junction: int = world.ui.selected
	await connect_nodes(5, junction)
	var reactors: Array[int] = []
	for cell in [Vector2i(-17, 3), Vector2i(-11, 3)]:
		await place("reactor", cell.x, cell.y)
		var id: int = world.ui.selected
		reactors.append(id)
		await driver.click(world.hud.buttons.deposit)
		driver.expect(world.model.by_id(id).input == 2, "real recovered crystals feed load")
		await connect_nodes(junction, id)
	await driver.click(world.hud.buttons.pause)
	if not await active(1):
		return
	driver.expect(world.model.power_state().request_kw > 120 and world.model.power_state().deficit_kw > 0, "live demand exceeds source")
	for id in reactors:
		driver.expect(world.model.by_id(id).progress > 0 and world.model.by_id(id).progress < 1.2, "actual reduced progress")
	await select(reactors[0])
	await driver.shot("06-proportional-shortfall")
	await driver.click(world.hud.buttons.pause)
	await place("power_source", -12, -9)
	var source: int = world.ui.selected
	driver.expect(world.model.power_state().deficit_kw > 0, "isolated second source still leaves deficit")
	await connect_nodes(5, source)
	await driver.click(world.hud.buttons.pause)
	if not await active(1):
		return
	driver.expect(world.model.power_state().deficit_kw == 0, "second source restores full network")
	await select(reactors[0])
	await driver.shot("07-capacity-restored")
	await driver.click(world.hud.buttons.pause)
	await branch_path(junction, reactors)


func branch_path(junction: int, reactors: Array) -> void:
	await select(junction)
	await driver.click(world.hud.buttons.salvage)
	driver.expect(world.power_dialog.visible, "connected node removal explicit dialog")
	await dialog_shot("10-node-removal-confirmation")
	await dialog_click(world.power_dialog.get_cancel_button())
	driver.expect(not world.model.by_id(junction).is_empty(), "cancel removal leaves node")
	await driver.click(world.hud.buttons.power_disconnect)
	driver.expect(world.power_choices.item_count > 0, "disconnect dialog populated")
	if world.power_choices.item_count == 0:
		return
	await dialog_shot("09-disconnect-choice")
	world.power_choices.select(0) # Upstream link is listed before consumer links.
	await dialog_click(world.power_dialog.get_ok_button())
	var progress: float = world.model.by_id(reactors[0]).progress
	await driver.click(world.hud.buttons.pause)
	if not await active(1):
		return
	driver.expect(is_equal_approx(world.model.by_id(reactors[0]).progress, progress), "disconnected branch stops")
	driver.expect(world.model.power_state().devices[2].fraction == 1, "main branch remains powered")
	await select(reactors[0])
	await driver.shot("08-branch-disconnected")
	await driver.click(world.hud.buttons.pause)
	await connect_nodes(5, junction)
	await select(junction)
	await driver.click(world.hud.buttons.salvage)
	await dialog_click(world.power_dialog.get_ok_button())
	driver.expect(world.model.by_id(junction).is_empty(), "confirmed node removal")
	for id in reactors:
		driver.expect(world.model.by_id(id).power_node_id == 0, "removed node clears consumers")
	driver.expect(Codec.decode(Codec.snapshot(world.model, world.store.world_id, world.store.world_name, 1), world.store.world_id).ok, "edited network and history save valid")


func dialog_click(button: Button) -> void:
	# Native mouse hover belongs to the OS window manager. Use explicit keyboard
	# focus and normal Enter input; do not mistake push_input for an OS cursor move.
	button.grab_focus()
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = KEY_ENTER
		event.keycode = KEY_ENTER
		event.pressed = pressed
		button.get_window().push_input(event, true)
		await process_frame
	await driver.settle()
	driver.expect(not world.power_dialog.visible, "keyboard dialog input closes confirmation")


func dialog_shot(name: String) -> void:
	await driver.settle()
	var picture: Image = world.power_dialog.get_texture().get_image()
	driver.expect(picture.save_png(driver.shot_root.path_join(name + ".png")) == OK, "native dialog screenshot " + name)


func equivalent(a: Variant, b: Variant, path := "state") -> bool:
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size():
			return false
		for key in a:
			if not b.has(key) or not equivalent(a[key], b[key], path + "." + key):
				return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size():
			return false
		for i in a.size():
			if not equivalent(a[i], b[i], path + "[%d]" % i):
				return false
		return true
	if (a is int or a is float) and (b is int or b is float):
		if a == floor(a) and b == floor(b):
			return a == b
		if absf(a - b) <= 1e-12:
			return true
	if a != b:
		print("snapshot mismatch ", path, ": ", a, " / ", b)
	return a == b
