extends SceneTree

const Boot := preload("res://scenes/boot/Boot.tscn")
const Driver := preload("res://scripts/checks/factory_window_driver.gd")
const Check := preload("res://scripts/checks/factory_discovery_check.gd")
const Store := preload("res://scripts/factory/save/store.gd")
const Codec := Store.Codec
const CASES := ["sample-ready", "trial-ready", "outer-ready", "rich-half", "inner-ready"]
var boot: Node
var world: Control
var driver: Node
var run_root := ""
var read_mode := false
var manifest := {}
var finished := false


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var batch := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--batch="):
			batch = arg.trim_prefix("--batch=")
		if arg == "--read":
			read_mode = true
	assert(batch.is_valid_filename() and not ".." in batch)
	var repo := SliceCheckPaths.repository_root()
	run_root = repo.path_join("tools/runtime-intake/check-runs/factory-discovery-v1").path_join(batch)
	DirAccess.make_dir_recursive_absolute(run_root)
	driver = Driver.new()
	driver.shot_root = repo.path_join("assets/art-intake/2026-09-25-factory-discovery-preview").path_join(batch)
	DirAccess.make_dir_recursive_absolute(driver.shot_root)
	root.add_child(driver)
	if read_mode:
		manifest = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("manifest.json")))
	else:
		for name in CASES:
			var path := repo.path_join("tools/runtime-intake/check-runs/factory-discovery-v1/d2-b-20260925").path_join(name + ".json")
			var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
			var decoded := Codec.decode(saved, saved.world_id)
			driver.expect(decoded.ok, "natural simulation fixture valid: " + name)
			if not decoded.ok:
				finish()
				return
			var store := Store.new(run_root.path_join("factory"))
			var created := store.create(name, Codec.V2.Config.SUPPLY_ID)
			driver.expect(created.ok and store.save(decoded.model).ok, "isolated fixture published: " + name)
			manifest[name] = {"id": store.world_id, "source": path, "sha256": FileAccess.get_sha256(path)}
			store.release()
		write_json("manifest.json", manifest)
	boot = Boot.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(run_root.path_join("slice"))
	boot.factory_save_root = run_root.path_join("factory")
	root.add_child(boot)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1440, 900)
	create_timer(100).timeout.connect(func(): driver.expect(false, "Boot timeout"); finish())
	await driver.settle(25)
	await driver.click(boot.startup_menu.get_node("ContentRoot/MenuButtons/FactoryButton"))
	for name in CASES:
		await load_case(name)
		if world == null or not driver.failures.is_empty():
			finish()
			return
		if read_mode:
			var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join(name + "-expected.json")))
			var actual := Codec.snapshot(world.model, world.store.world_id, world.store.world_name, expected.sequence)
			driver.expect(Check.equivalent(actual, expected), "independent Boot complete state: " + name)
			var clone: RefCounted = Codec.decode(actual, actual.world_id).model
			clone.advance(20)
			var trajectory: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join(name + "-trajectory.json")))
			driver.expect(Check.equivalent(Codec.snapshot(clone, actual.world_id, actual.name, actual.sequence), trajectory), "independent 400-step trajectory: " + name)
			if name == "inner-ready":
				await driver.shot("09-both-open-restored")
		else:
			match name:
				"sample-ready": await sample_path()
				"trial-ready": await trial()
				"outer-ready": await passage("outer", "04")
				"rich-half": await rich()
				"inner-ready": await passage("inner", "08")
			if not driver.failures.is_empty():
				finish()
				return
			await driver.click(world.hud.buttons.save)
			var saved := Codec.snapshot(world.model, world.store.world_id, world.store.world_name, world.store.sequence)
			write_json(name + "-expected.json", saved)
			var clone: RefCounted = Codec.decode(saved, saved.world_id).model
			clone.advance(20)
			write_json(name + "-trajectory.json", Codec.snapshot(clone, saved.world_id, saved.name, saved.sequence))
		if not driver.failures.is_empty():
			finish()
			return
		await driver.click(world.hud.buttons.return)
		driver.expect(boot.factory_world == null, "save return releases isolated world")
	finish()


func load_case(name: String) -> void:
	var index := -1
	for i in boot.factory_menu.worlds.size():
		if boot.factory_menu.worlds[i].id == manifest[name].id:
			index = i
	driver.expect(index >= 0, "formal menu lists " + name)
	if index < 0:
		return
	boot.factory_menu.list.select(index)
	boot.factory_menu.list.item_selected.emit(index)
	boot.factory_menu.continue_button.pressed.emit()
	world = boot.factory_world
	driver.world = world
	driver.expect(world != null and world.initialized, "formal Boot loads " + name)
	if world == null:
		return
	world.ui.paused = true
	# Freeze before the first frame; startup wall time is not part of the saved fixture.
	world.production_clock.start(Time.get_ticks_usec(), false)
	world.view.zoom = 0.8
	await driver.settle(15)
	driver.expect(root.has_focus(), "foreground before path")


func panel(id := -1) -> void:
	world.ui.selected = id # Targeted command UI, selection covered by foundation checks.
	world._refresh()
	await driver.settle()
	await driver.click(world.hud.buttons.discovery)
	driver.expect(world.discovery_panel.visible, "open real discovery panel")
	await driver.settle(10)
	driver.expect(world.discovery_panel.size.y <= 700 and world.discovery_panel.size.x <= 800, "panel fits ordinary window")
	var rect: Rect2 = world.discovery_panel.get_ok_button().get_global_rect()
	driver.expect(Rect2(Vector2.ZERO, Vector2(world.discovery_panel.size)).encloses(rect), "return button inside visible native viewport")


func press(button: Button) -> void:
	# Native popup input uses explicit Control focus and synthetic Enter.
	driver.expect(button.is_visible_in_tree() and not button.disabled and button.get_window().has_focus(), "native button available and foreground: " + button.text)
	if not driver.failures.is_empty():
		finish()
		return
	button.grab_focus()
	for held in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = KEY_ENTER
		event.keycode = KEY_ENTER
		event.pressed = held
		button.get_window().push_input(event, true)
		await process_frame
	await driver.settle()


func panel_shot(name: String) -> void:
	await driver.settle()
	var picture: Image = world.discovery_panel.get_texture().get_image()
	driver.expect(picture.save_png(driver.shot_root.path_join(name + ".png")) == OK, "native panel screenshot " + name)


func active(seconds: float) -> bool:
	var target: float = world.model.time + seconds
	while world.model.time < target:
		await process_frame
		if not root.has_focus():
			driver.expect(false, "focus lost: validation stopped")
			return false
	return true


func trial() -> void:
	await panel(2)
	await panel_shot("01-trial-conditions")
	await press(world.discovery_panel.buttons.crust_sample_put_one)
	await press(world.discovery_panel.buttons.catalyst_put_all)
	driver.expect(world.model.by_id(2).input == {"crust_sample": 1, "catalyst": 2}, "explicit trial material buttons")
	await press(world.discovery_panel.get_ok_button())
	await driver.click(world.hud.buttons.pause)
	if not await active(10.15):
		return
	await driver.click(world.hud.buttons.pause)
	driver.expect(world.model.discovery.trial_completed and world.model.statistics.totals.consumed.crust_sample == 1, "real-time trial completes once")
	await driver.shot("02-trial-product-on-belt")
	await panel(2)
	driver.expect("crust_solvent" in world.discovery_panel.recipe_ids and "rich_catalyst" in world.discovery_panel.recipe_ids, "new recipes visible after real completion")
	await panel_shot("03-trial-unlocks")
	await press(world.discovery_panel.get_ok_button())


func passage(id: String, prefix: String) -> void:
	await driver.shot(prefix + "-before-opening")
	await panel()
	await panel_shot(prefix + "-opening-command")
	await press(world.discovery_panel.buttons[id])
	driver.expect(world.model.discovery.passages[id], "explicit passage button debits and opens " + id)
	await press(world.discovery_panel.get_ok_button())
	world.actor.target = Vector2(8.5 if id == "outer" else 24.5, 0.5)
	await driver.click(world.hud.buttons.pause)
	if not await active(2.2):
		return
	await driver.click(world.hud.buttons.pause)
	driver.expect(world.actor.x > (8 if id == "outer" else 24), "actual actor collision permits opened crossing")
	await driver.shot(prefix + "-after-crossing")


func rich() -> void:
	world.ui.selected = 16
	world._refresh()
	await driver.shot("06-rich-partial-output")
	await panel(16)
	await panel_shot("06-rich-output-inventory")
	await press(world.discovery_panel.get_ok_button())
	await driver.click(world.hud.buttons.pause)
	if not await active(2.2):
		return
	await driver.click(world.hud.buttons.pause)
	driver.expect(world.model.by_id(16).output.is_empty(), "remaining rich products leave one by one")
	var batch: int = world.model.by_id(18).batch
	for id in [18, 19, 20]:
		driver.expect(world.model.by_id(id).cargo == "catalyst" and world.model.by_id(id).batch == batch, "three separate units retain one batch")
	await driver.shot("07-rich-three-units")


func write_json(name: String, value: Variant) -> void:
	var file := FileAccess.open(run_root.path_join(name), FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "\t", false, true))
	file.close()


func finish() -> void:
	if finished:
		return
	finished = true
	write_json("read-result.json" if read_mode else "write-result.json", {"assertions": driver.assertions, "failures": driver.failures, "input": "Boot menu select signal; root synthetic mouse; native buttons focused with synthetic Enter; selected entity assigned; accelerated natural-production fixtures; actor target assigned for real collision walking"})
	print("Discovery Boot: %d assertions, %d failures" % [driver.assertions, driver.failures.size()])
	quit(0 if driver.failures.is_empty() else 1)


func sample_path() -> void:
	await driver.shot("00-sample-on-ground")
	await panel()
	await press(world.discovery_panel.buttons.survey)
	driver.expect(world.model.discovery.surveyed and not world.model.discovery.sample_taken, "survey is separate from pickup")
	await press(world.discovery_panel.buttons.sample)
	driver.expect(world.model.bag.get("crust_sample", 0) == 1 and world.model.discovery.sample_taken, "explicit pickup obtains unique sample")
	await panel_shot("00-sample-acquired")
	await press(world.discovery_panel.get_ok_button())
