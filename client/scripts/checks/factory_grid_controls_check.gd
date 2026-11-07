extends SceneTree

const Boot := preload("res://scenes/boot/Boot.tscn")
const Driver := preload("res://scripts/checks/factory_window_driver.gd")
const Route := preload("res://scripts/checks/factory_integrated_first_route.gd")
const Store := preload("res://scripts/factory/save/store.gd")
const Compare := preload("res://scripts/checks/factory_expansion_compare.gd")
const Codec := Store.Codec
const Controls := Codec.V11.Controls
const StoragePath := preload("res://scripts/checks/factory_grid_storage_path.gd")
const NAME := "核心 III 升级与存读"

var driver := Driver.new()
var boot: Node
var evidence := ""
var windowed := false
var storage := false


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var args := OS.get_cmdline_user_args()
	var playing := "--play" in args
	storage = "--storage" in args
	for arg in args:
		if arg.begins_with("--batch="):
			var batch := arg.trim_prefix("--batch=")
			if batch.is_valid_filename() and ".." not in batch:
				var parent := SliceCheckPaths.review_worlds("factory-grid-controls-v1") if playing else SliceCheckPaths.check_run("factory-grid-controls-v1", false)
				evidence = parent.path_join(batch)
	if evidence.is_empty() or not DirAccess.dir_exists_absolute(evidence):
		push_error("Requires an isolated grid controls batch.")
		quit(2)
		return
	boot = Boot.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(evidence.path_join("slice"))
	boot.factory_save_root = evidence.path_join("factory")
	boot.factory_controls_context = true
	root.add_child(boot)
	if playing:
		return
	windowed = DisplayServer.get_name() != "headless"
	driver.capture_screenshots = windowed
	driver.shot_root = evidence
	root.add_child(driver)
	if windowed:
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1440, 900).min(DisplayServer.screen_get_usable_rect().size - Vector2i(32, 48))
		root.move_to_center()
	await driver.settle(15)
	if windowed and not root.has_focus():
		driver.expect(false, "window focused at startup")
	else:
		await _click(boot.startup_menu.find_child("FactoryButton", true, false))
		if "--read" in args:
			await _read()
		else:
			await _write()
	print("Factory grid controls: %d checks, %d failures" % [driver.assertions, driver.failures.size()])
	quit(0 if driver.failures.is_empty() else 1)


func _click(button: Button) -> void:
	if windowed:
		await driver.click(button)
	else:
		driver.expect(not button.disabled, "button available: " + button.text)
		button.pressed.emit()
		await driver.settle()


func _write() -> void:
	var menu: Control = boot.factory_menu
	var supply := Codec.V12.Buffer.SUPPLY_ID if storage else Controls.SUPPLY_ID
	var version := Codec.V12.VERSION if storage else Codec.V11.VERSION
	var pin := Codec.V12.PIN if storage else Codec.V11.PIN
	var index := -1
	for i in menu.world_type.item_count:
		if menu.world_type.get_item_metadata(i) == supply:
			index = i
	driver.expect(index >= 0 and not Store.new(Store.DEFAULT_ROOT, false, false, true).allow_controls,
		"schema 11 creation is debug-isolated")
	if index < 0:
		return
	var ordinary := Store.new(boot.factory_save_root, false, true)
	driver.expect(not ordinary.create(NAME, supply, true).ok, "D1 context alone cannot create D2")
	menu.world_type.select(index)
	menu.title_input.text = NAME
	await driver.shot("01-create")
	await _click(menu.create_button)
	var world: Control = boot.factory_world
	driver.expect(world != null and world.initialized, "Boot creates schema 11")
	if world == null or not world.initialized:
		return
	world._set_paused(true)
	driver.world = world
	var model: RefCounted = world.model
	var id: String = world.store.world_id
	var initial := Codec.snapshot(model, id, NAME, world.store.sequence)
	driver.expect(initial.save_schema_version == version and initial.definitions_sha256 == pin and model.single_inlet_belts
		and model.core.level == 1 and model.core.items.is_empty() and model.entities.size() == 1, "empty D2 starts in core I with its own digest and D1 routing")
	driver.expect(not ordinary.find_candidate(id).ok, "D1 context cannot continue D2")
	var layout: Variant = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("layout.json")))
	if not layout is Dictionary:
		driver.expect(false, "S1-P layout is present")
		return
	var journey := Route.new(model, layout)
	journey.bootstrap()
	var before := Codec.snapshot(model, id, NAME, world.store.sequence)
	journey.walk_near(model.core)
	var blocked: Dictionary = model.upgrade_core()
	driver.expect(not blocked.ok and "矿渣回用" in blocked.reason and model.core_upgrades[3].requires == [Route.P.CELLS, Route.P.REUSE],
		"III is blocked until both studies are complete")
	driver.expect(model.core.level == 2 and model.core.items == before.state.core.items, "failed upgrade consumes nothing")
	journey.energy_line()
	journey.steady()
	journey.alternatives_and_passages()
	var g: Dictionary = journey.devices.G
	journey.wait_for(func(): return journey.devices.T.items.get("construction_pack", 0) >= 4, 180, "natural III construction packs")
	journey._packs_to_core(4)
	driver.expect(not model.upgrade_core().ok and model.missing_stock(Controls.III_COST).has(Route.CELL), "missing core fuel blocks III")
	journey.walk_near(g)
	journey.wait_for(func(): return g.fuel.get(Route.CELL, 0) >= 3, 180, "natural III cells with reserve")
	journey.stock(g, Route.CELL, 2, false)
	journey.walk_near(model.core)
	journey.stock(model.core, Route.CELL, 2, true)
	driver.expect(not model.researched.has(model.Frontier.RESEARCH) and model.upgrade_status().ok,
		"ordinary mines and continuous fuel qualify without X2")
	var stock: Dictionary = model.core.items.duplicate()
	var ports: Dictionary = model.core.outputs.duplicate(true)
	var studies: Dictionary = model.researched.duplicate()
	var totals: Dictionary = model.statistics.totals.consumed.duplicate()
	var burn: int = g.burn_remaining_ticks
	var core_id: int = model.core.id
	await driver.settle()
	if windowed:
		await driver.world_click(Vector2i(model.core.x + 3, model.core.z + 3), 1.5)
	else:
		world._open_device(core_id)
	var panel: Control = world.core_panel
	driver.expect(panel.visible, "open the core panel")
	if not panel.visible:
		return
	panel.tabs.current_tab = 3
	await driver.settle()
	driver.expect(panel.upgrade_button.text == "升至核心 III" and not panel.upgrade_button.disabled, "level tab exposes III")
	await driver.shot("02-upgrade-ready")
	await _click(panel.upgrade_button)
	driver.expect(model.core.level == 3 and panel.title.text.ends_with("III") and not panel.upgrade_button.visible, "upgrade via panel replaces level and retires button")
	for item in Controls.III_COST:
		var cost: int = Controls.III_COST[item]
		driver.expect(model.core.items.get(item, 0) == stock.get(item, 0) - cost and model.statistics.totals.consumed[item] == totals.get(item, 0) + cost,
			"debit inventory and record consumption: " + item)
	driver.expect(not model.upgrade_core().ok and model.material_balance().balanced, "duplicate upgrade rejected with balanced ledger")
	driver.expect(model.core.id == core_id and model.core.outputs == ports and model.researched == studies
		and g.burn_remaining_ticks == burn and model.power_state().available_kw == 480.0,
		"upgrade preserves identity, research, ports and 360 + 120 kW")
	await _click(panel.close_button)
	_expect_visual(world)
	await driver.shot("03-core-iii")
	if storage:
		await StoragePath.new(self, journey).exercise()
	await _click(world.hud.buttons["return"])
	driver.expect(boot.factory_world == null, "save and return releases the world: " + world.failure_dialog.dialog_text if boot.factory_world != null else "save and return releases the world")
	if boot.factory_world != null:
		return
	var store := Store.new(boot.factory_save_root, false, false, true)
	var candidate := store.find_candidate(id)
	driver.expect(candidate.ok and candidate.document.state.core.level == 3, "published III passes strict decode")
	if not candidate.ok:
		return
	_bad_saves(candidate.document, initial, id)
	if storage:
		StoragePath.new(self, journey).validate_saved(candidate.document, id)
	model.advance(30.0, 600)
	var after := Codec.snapshot(model, id, NAME, candidate.document.sequence)
	var file := FileAccess.open(evidence.path_join("expected.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"id": id, "before": candidate.document, "after": after}, "", true, true))


func _expect_visual(world: Control) -> void:
	var core: Node3D = world.view.models[world.model.core.id].root
	var tiers := core.find_child("TierModules", true, false)
	driver.expect(tiers.get_node("III").visible and not tiers.get_node("I").visible and not tiers.get_node("II").visible
		and "核心 III" in world.hud.totals.text, "III is visible in the world and HUD")


func _bad_saves(document: Dictionary, initial: Dictionary, id: String) -> void:
	var invalid := document.duplicate(true)
	invalid.definitions_sha256 = Codec.V10.SINGLE_INLET_PIN
	driver.expect(not Codec.decode(invalid, id).ok, "D1 digest is rejected for D2")
	invalid = initial.duplicate(true)
	invalid.state.core.level = 3
	driver.expect(not Codec.decode(invalid, id).ok, "forged III without research is rejected")
	invalid = document.duplicate(true)
	invalid.state.core.items.industrial_cell = invalid.state.core.items.get("industrial_cell", 0) + 2
	driver.expect(not Codec.decode(invalid, id).ok, "forged refund is rejected by the ledger")
	var d1 := Codec.V10.snapshot(Codec.V10.FrontierModel.new(true), id, NAME, 1)
	var old := Codec.decode(d1, id)
	driver.expect(old.ok and not old.model.core_upgrades.has(3), "schema 10 still reads with two tiers")
	d1.state.core.level = 3
	driver.expect(not Codec.decode(d1, id).ok, "schema 10 cannot load III")
	var bad_root := evidence.path_join("cross-identity")
	var folder := bad_root.path_join(id)
	d1.state.core.level = 1
	invalid = document.duplicate(true)
	invalid.state.core.level = 4
	DirAccess.make_dir_recursive_absolute(folder.path_join("backups"))
	for row in [["autosave.json", invalid], ["backups/autosave.bak.1.json", d1]]:
		var file := FileAccess.open(folder.path_join(row[0]), FileAccess.WRITE)
		file.store_string(JSON.stringify(row[1]))
	driver.expect(not Store.new(bad_root, false, true, true).find_candidate(id).ok, "D2 refuses to recover from a D1 backup")


func _read() -> void:
	var expected: Variant = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("expected.json")))
	var menu: Control = boot.factory_menu
	driver.expect(expected is Dictionary and menu.worlds.size() == 1 and menu.worlds[0].schema == (Codec.V12.VERSION if storage else Codec.V11.VERSION), "isolated menu lists the expected checkpoint")
	if not expected is Dictionary or menu.worlds.size() != 1:
		return
	menu.list.select(0)
	menu.list.item_selected.emit(0)
	menu.world_ready.connect(func(_store, _model, _candidate):
		if boot.factory_world != null:
			boot.factory_world._set_paused(true), CONNECT_ONE_SHOT)
	await _click(menu.continue_button)
	var world: Control = boot.factory_world
	driver.expect(world != null and world.initialized, "independent Boot continues III")
	if world == null or not world.initialized:
		return
	driver.world = world
	_expect_visual(world)
	var model: RefCounted = world.model
	if storage:
		driver.expect(model.stored_joules() > 0 and model.power_state().discharge_j == 3000, "loaded E2 resumes with a real discharge request")
	var startup: float = world.production_clock.active_usec / 1000000.0
	var before := Codec.snapshot(model, expected.id, NAME, world.store.sequence)
	before.state.remainder_s -= startup
	driver.expect(Compare.equivalent(before, expected.before), "complete saved snapshot is restored")
	await driver.shot("04-restored-iii")
	model.advance(30.0, 600)
	var after := Codec.snapshot(model, expected.id, NAME, world.store.sequence)
	after.state.remainder_s -= startup
	driver.expect(Compare.equivalent(after, expected.after) and model.material_balance().balanced, "30-second resumed trajectory and material ledger match")
	await _click(world.hud.buttons["return"])
	driver.expect(boot.factory_world == null, "restored world saves and releases the session")
	var result := FileAccess.open(evidence.path_join("restore.json"), FileAccess.WRITE)
	result.store_string(JSON.stringify({"checks": driver.assertions, "failures": driver.failures}))
