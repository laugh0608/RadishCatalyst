extends SceneTree

const Boot := preload("res://scenes/boot/Boot.tscn")
const Driver := preload("res://scripts/checks/factory_window_driver.gd")
const Codec := preload("res://scripts/factory/save/codec.gd")
var boot: Node
var driver: Node
var run_root := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var repo := SliceCheckPaths.repository_root()
	var run_id := "boot-%d-%d" % [Time.get_unix_time_from_system(), OS.get_process_id()]
	run_root = repo.path_join("tools/runtime-intake/check-runs/factory-foundation-v1").path_join(run_id)
	driver = Driver.new()
	driver.shot_root = repo.path_join("assets/art-intake/2026-09-08-factory-foundation-preview").path_join(run_id)
	DirAccess.make_dir_recursive_absolute(driver.shot_root)
	root.add_child(driver)
	create_timer(120).timeout.connect(func(): driver.expect(false, "Boot review timeout"); finish())
	boot = Boot.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(run_root.path_join("slice"))
	boot.factory_save_root = run_root.path_join("factory")
	root.add_child(boot)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1440, 900)
	await driver.settle(30)
	driver.expect(boot.startup_menu != null, "official Boot startup")
	await driver.shot("01-boot-menu")
	await driver.click(boot.startup_menu.get_node("ContentRoot/MenuButtons/FactoryButton"))
	driver.expect(boot.factory_menu != null, "factory list from startup button")
	boot.factory_menu.title_input.text = "正式入口检查"
	await driver.click(boot.factory_menu.create_button)
	driver.world = boot.factory_world
	if driver.world == null:
		driver.expect(false, "created factory scene")
		finish()
		return
	await driver.settle(20)
	var world: Control = driver.world
	driver.expect(world.initialized, "candidate model/view ready")
	driver.expect(world.model.entities.is_empty(), "empty normal new world")
	driver.expect(FileAccess.file_exists(world.store.path("autosave.json")), "initial save before entry")
	await driver.shot("02-new-factory")
	for spec in [["collector", -8, -1], ["reactor", -1, -2], ["storage", 6, -1]]:
		await driver.click(world.hud.buttons[spec[0]])
		await driver.world_click(Vector2i(spec[1], spec[2]))
		driver.expect(world.model.entity_at(Vector2i(spec[1], spec[2])).get("type") == spec[0], "mouse places " + spec[0])
	if not driver.failures.is_empty():
		await driver.shot("failure-placement")
		finish()
		return
	await driver.click(world.hud.buttons.belt)
	await driver.drag([Vector2i(-6, 0), Vector2i(-2, 0)])
	await driver.drag([Vector2i(2, 0), Vector2i(2, 2), Vector2i(4, 2), Vector2i(4, 0), Vector2i(5, 0)])
	driver.expect(world.model.kits.belt == 243, "13 real belts from mouse drags")
	await driver.key(KEY_ESCAPE)
	await driver.shot("03-first-line")
	await driver.click(world.hud.buttons.pause)
	var document: Dictionary = Codec.snapshot(world.model, world.store.world_id, world.store.world_name, 1)
	var id: String = world.store.world_id
	await driver.click(world.hud.buttons.return)
	driver.expect(boot.factory_world == null and boot.factory_menu.visible, "saved return to factory list")
	driver.expect(not DirAccess.dir_exists_absolute(run_root.path_join("factory").path_join(id).path_join("session.lock")), "return releases world")
	boot.factory_menu.list.select(0)
	boot.factory_menu.list.item_selected.emit(0)
	await driver.click(boot.factory_menu.continue_button)
	driver.world = boot.factory_world
	await driver.settle()
	world = driver.world
	driver.expect(world != null and world.initialized, "continue reconstructs official factory")
	if world != null:
		driver.expect(world.model.entities.size() == document.state.entities.size(), "continue restores placed structures")
		driver.expect(world.model.kits == document.state.kits, "continue restores kits")
		await driver.shot("04-continued-factory")
		world._request_exit("return")
		await driver.settle()
	boot.factory_menu.back_requested.emit()
	await driver.settle()
	driver.expect(boot.startup_menu != null, "old startup menu remains reachable")
	boot.startup_menu.new_game_button.pressed.emit()
	boot.startup_menu.world_name_input.text = "旧二维回归"
	boot.startup_menu.create_world_button.pressed.emit()
	await driver.settle(30)
	driver.expect(boot.slice_world != null, "old 2D new world path")
	await driver.shot("05-retained-2d-world")
	finish()


func finish() -> void:
	DirAccess.make_dir_recursive_absolute(run_root)
	var file := FileAccess.open(run_root.path_join("result.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"assertions": driver.assertions, "failures": driver.failures, "screenshots": driver.shot_root}, "\t"))
	file.close()
	print("Factory Boot checks: %d assertions, %d failures; %s" % [driver.assertions, driver.failures.size(), run_root])
	quit(0 if driver.failures.is_empty() else 1)
