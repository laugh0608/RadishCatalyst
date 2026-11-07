extends SceneTree

const Boot := preload("res://scenes/boot/Boot.tscn")
const Journey := preload("res://scripts/checks/factory_fixed_burn_journey.gd")
const Driver := preload("res://scripts/checks/factory_window_driver.gd")
const Codec := preload("res://scripts/factory/save/codec.gd")

var driver := Driver.new()
var boot: Node
var evidence := ""


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var play := "--play" in OS.get_cmdline_user_args()
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--batch="):
			var name := arg.trim_prefix("--batch=")
			if name.is_valid_filename() and ".." not in name:
				var topic := SliceCheckPaths.review_worlds("factory-integrated-c-v1") if play else SliceCheckPaths.check_run("factory-integrated-c-v1", false)
				evidence = topic.path_join(name)
	if evidence.is_empty() or not DirAccess.dir_exists_absolute(evidence) or DisplayServer.get_name() == "headless":
		push_error("Requires an isolated visible Boot batch.")
		quit(2)
		return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1440, 900).min(DisplayServer.screen_get_usable_rect().size - Vector2i(32, 48))
	root.move_to_center()
	driver.shot_root = evidence
	root.add_child(driver)
	boot = Boot.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(evidence.path_join("slice"))
	boot.factory_save_root = evidence.path_join("factory")
	boot.factory_integrated_context = true
	root.add_child(boot)
	await driver.settle(15)
	if play:
		return
	if not root.has_focus():
		driver.expect(false, "window focused before starting input")
		_finish()
		return
	await _review()
	_finish()


func _review() -> void:
	var button := boot.startup_menu.find_child("FactoryButton", true, false) as Button
	await driver.click(button)
	var menu: Control = boot.factory_menu
	if menu == null:
		driver.expect(false, "Boot opened the factory catalog")
		return
	var choices: OptionButton = menu.world_type
	var index := -1
	for i in choices.item_count:
		if choices.get_item_metadata(i) == Journey.Model.Integrated.SUPPLY_ID:
			index = i
	driver.expect(index >= 0, "isolated catalog offers the integrated world")
	if index < 0: return
	choices.select(index)
	menu.title_input.text = "固定燃烧窗口复核"
	await driver.click(menu.create_button)
	var world: Control = boot.factory_world
	driver.expect(world != null and world.initialized, "new schema 9 opened through Boot catalog")
	if world == null or not world.initialized: return
	driver.world = world
	var model: RefCounted = world.model
	driver.expect(model.entities.size() == 1 and model.core.items.is_empty(), "new world starts with only the core and zero material")
	await driver.click(world.hud.buttons.pause)
	var journey := Journey.new()
	journey.model = model
	journey.prepare_fuel_and_kit()
	model.actor.x = Journey.G_CELL.x + 1.0
	model.actor.z = Journey.G_CELL.y - 0.7
	await driver.settle(12)
	if not root.has_focus():
		driver.expect(false, "window retained focus for placement")
		_close_world()
		return
	await driver.click(world.hud.buttons.cell_generator)
	await driver.world_click(Journey.G_CELL)
	var g: Dictionary = model.entity_at(Journey.G_CELL)
	driver.expect(g.get("type") == "cell_generator" and not g.get("enabled", true), "build tool places a stopped generator")
	if g.get("type") != "cell_generator":
		_close_world()
		return
	journey.generator = g
	journey.connect_generator()
	model.actor.x = g.x + 1.0
	model.actor.z = g.z - 0.7
	await driver.settle()
	if not root.has_focus():
		driver.expect(false, "window retained focus for generator interaction")
		_close_world()
		return
	await driver.world_click(Journey.G_CELL + Vector2i(0, 1), 1.5)
	var panel: Control = world.discovery_panel
	driver.expect(panel.visible and panel.selected == g.id, "world picker opens the generator")
	if not panel.visible or panel.selected != g.id:
		_close_world()
		return
	await driver.shot("01-generator-off")
	await driver.click(panel.buttons.device_toggle)
	driver.expect(g.enabled and g.fuel.industrial_cell == 2, "toggle enables while world paused without consuming")
	await driver.click(panel.buttons.pause)
	await create_timer(0.32).timeout
	driver.expect(g.burn_remaining_ticks in range(1, 1200) and model.statistics.totals.spill_kj > 0, "normal window clock burns and records spill")
	await driver.shot("02-fixed-burn")
	await driver.click(panel.buttons.device_toggle)
	var ticks: int = g.burn_remaining_ticks
	await create_timer(0.18).timeout
	driver.expect(g.burn_remaining_ticks == ticks and not g.enabled, "manual stop preserves fuel while factory runs")
	panel.close_panel()
	await driver.click(world.hud.buttons.pause)
	await driver.click(world.hud.buttons.statistics)
	var stats_panel: Control = world.statistics_panel
	stats_panel.page.select(1)
	stats_panel.page.item_selected.emit(1)
	await driver.settle()
	driver.expect("累计激活" in stats_panel.power_summary.text and "弃能" in stats_panel.power_summary.text, "statistics shows spill separately")
	await driver.shot("03-energy-ledger")
	stats_panel.hide()
	var id: String = world.store.world_id
	var gen_id: int = g.id
	await driver.click(world.hud.buttons["return"])
	driver.expect(boot.factory_world == null and menu.visible, "save and return releases the world")
	if boot.factory_world != null: return
	driver.expect(menu.worlds.size() == 1 and menu.worlds[0].schema == Codec.V9.VERSION, "catalog recognizes schema 9 save")
	menu.list.select(0)
	menu.list.item_selected.emit(0)
	await driver.click(menu.continue_button)
	world = boot.factory_world
	driver.expect(world != null and world.initialized, "continue rebuilds the integrated world")
	if world == null or not world.initialized: return
	driver.world = world
	var restored: Dictionary = world.model.by_id(gen_id)
	driver.expect(world.store.world_id == id and world.model.core.level == 2 and restored.burn_remaining_ticks == ticks and not restored.enabled, "reload preserves core tier, research and stopped burn remainder")
	driver.expect(world.model.researched.has(Journey.P.CELLS) and world.model.material_balance().balanced, "reload retains research and complete material ledger")
	await driver.world_click(Journey.G_CELL + Vector2i(0, 1), 1.5)
	driver.expect(world.discovery_panel.selected == gen_id, "reconstructed generator remains interactable")
	await driver.shot("04-restored-generator")
	_close_world()
	await driver.settle()


func _close_world() -> void:
	var world: Control = boot.factory_world
	if world == null:
		return
	world.discovery_panel.close_panel()
	world._request_exit("return")


func _finish() -> void:
	var file := FileAccess.open(evidence.path_join("window-result.json"), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"assertions": driver.assertions, "failures": driver.failures,
			"fixture": "natural production via commands in created world; window-clock burn, input and catalog reload"}, "\t"))
		file.close()
	print("Factory integrated C window: %d checks, %d failures" % [driver.assertions, driver.failures.size()])
	quit(0 if driver.failures.is_empty() else 1)
