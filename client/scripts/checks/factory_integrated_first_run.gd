extends SceneTree

const Boot := preload("res://scenes/boot/Boot.tscn")
const Route := preload("res://scripts/checks/factory_integrated_first_route.gd")
const Driver := preload("res://scripts/checks/factory_window_driver.gd")
const Store := preload("res://scripts/factory/save/store.gd")
const Codec := Store.Codec
const NAME := "整合工厂联合首程"

var evidence := ""
var boot: Node
var driver := Driver.new()
var windowed := false


func _init() -> void:
	call_deferred("run")


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--batch="):
			var name := arg.trim_prefix("--batch=")
			if name.is_valid_filename() and ".." not in name:
				evidence = SliceCheckPaths.check_run("factory-integrated-first-run-v1", false).path_join(name)
	if evidence.is_empty() or not DirAccess.dir_exists_absolute(evidence):
		push_error("Requires an isolated first-run batch.")
		quit(2)
		return
	windowed = DisplayServer.get_name() != "headless"
	driver.capture_screenshots = windowed
	driver.shot_root = evidence
	root.add_child(driver)
	if windowed:
		root.mode = Window.MODE_WINDOWED
		root.size = Vector2i(1440, 900).min(DisplayServer.screen_get_usable_rect().size - Vector2i(32, 48))
		root.move_to_center()
	boot = Boot.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(evidence.path_join("slice"))
	boot.factory_save_root = evidence.path_join("factory")
	root.add_child(boot)
	await driver.settle(15)
	var reading := "--read" in OS.get_cmdline_user_args()
	if windowed and not root.has_focus():
		driver.expect(false, "window focused at startup")
		_finish("read" if reading else "write")
		return
	var start := boot.startup_menu.find_child("FactoryButton", true, false) as Button
	await _click(start)
	if reading:
		await _read()
		_finish("read")
	else:
		await _first_run()
		_finish("write")


func _click(button: Button) -> void:
	if windowed:
		await driver.click(button)
	else:
		driver.expect(not button.disabled, "button available: " + button.text)
		button.pressed.emit()
		await driver.settle()


func _first_run() -> void:
	var menu: Control = boot.factory_menu
	driver.expect(menu != null, "open Boot factory menu")
	if menu == null:
		return
	var supplies: Array[String] = []
	for i in menu.world_type.item_count:
		supplies.append(menu.world_type.get_item_metadata(i))
	driver.expect(supplies == [Codec.Rules.NORMAL_SUPPLY, Codec.V2.Config.ADMISSION_SUPPLY_ID,
		Codec.V6.Expansion.SUPPLY_ID, Codec.V7.Energy.SUPPLY_ID, Route.Model.Integrated.SUPPLY_ID],
		"normal menu preserves the existing choices and adds integrated creation")
	driver.expect(menu.world_type.get_selected_metadata() == Codec.Rules.NORMAL_SUPPLY, "the existing default remains selected")
	var index := supplies.find(Route.Model.Integrated.SUPPLY_ID)
	if index < 0:
		return
	menu.world_type.select(index)
	menu.title_input.text = NAME
	await driver.shot("00-create-integrated")
	# Capture the schema 9 start before the first process frame advances the model.
	if windowed:
		await _click(menu.create_button)
	else:
		menu.create_button.pressed.emit()
	var world: Control = boot.factory_world
	driver.expect(world != null and world.initialized, "Boot creates a schema 9 world")
	if world == null or not world.initialized:
		return
	driver.world = world
	world._set_paused(true)
	var model: RefCounted = world.model
	driver.expect(model.core.level == 1 and model.core.items.is_empty() and model.bag.is_empty() and model.entities.size() == 1, "empty first run with one core")
	await driver.shot("01-empty-world")
	if windowed:
		var spawn := Vector2(model.actor.x, model.actor.z)
		await driver.click(world.hud.buttons.guide_action)
		driver.expect(world.view.inspection_target == Vector3(-27.0, 0.25, -11.0), "first objective locates the offscreen iron site")
		driver.expect(Vector2(model.actor.x, model.actor.z) == spawn, "locating the ore leaves the actor at spawn")
		await driver.shot("01a-iron-located")
		world.view.inspection_target = null
	var layout: Variant = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("layout.json")))
	driver.expect(layout is Dictionary and layout.get("layout") == "S1-P", "validated four-sided layout loaded")
	if not layout is Dictionary:
		return
	var journey := Route.new(model, layout)
	journey.bootstrap()
	await driver.shot("02-tier-ii-from-stock")
	journey.energy_line()
	await driver.shot("03-four-outputs-live")
	if windowed:
		if not root.has_focus():
			driver.expect(false, "window retains focus for generator input")
			world._request_exit("return")
			return
		journey.walk_near(journey.devices.G)
		await driver.settle()
		var gen_cell := Vector2i(journey.devices.G.x, journey.devices.G.z + 1)
		await driver.world_click(gen_cell, 1.5)
		driver.expect(world.discovery_panel.visible and world.discovery_panel.selected == journey.devices.G.id, "world pick opens the naturally supplied G")
		if world.discovery_panel.visible:
			await driver.click(world.discovery_panel.buttons.device_toggle)
			driver.expect(journey.devices.G.enabled, "enable from generator panel")
			await driver.click(world.discovery_panel.buttons.pause)
			await create_timer(0.3).timeout
			driver.expect(journey.devices.G.burn_remaining_ticks > 0, "normal window clock burns real fuel")
			await driver.shot("04-generator-burns")
			await driver.click(world.discovery_panel.buttons.pause)
			driver.expect(world.ui.paused, "pause the window clock before the fixed-step sample")
			world.discovery_panel.close_panel()
	var continuous := journey.steady()
	await driver.shot("05-continuous-production")
	journey.alternatives_and_passages()
	driver.expect(model.researched.size() == 7 and model.completed_by_recipe.slag_sintering > 0, "same world finishes seven nodes and material reuse")
	driver.expect(model.discovery.passages.inner and model.completed_by_recipe.rich_catalyst > 0, "rich ore production is earned through the real gates")
	model.advance(7.35)
	var id: String = world.store.world_id
	var generator: int = journey.devices.G.id
	var current := _result(model, generator)
	await driver.shot("06-full-research-and-stock")
	if windowed and not root.has_focus():
		driver.expect(false, "window retains focus for save and return")
		world._request_exit("return")
		return
	await _click(world.hud.buttons["return"])
	driver.expect(boot.factory_world == null, "save and return releases the write session")
	if boot.factory_world != null:
		return
	var store := Store.new(boot.factory_save_root)
	var candidate := store.find_candidate(id)
	driver.expect(candidate.ok and candidate.document.save_schema_version == 9, "read published schema 9 save")
	if not candidate.ok:
		return
	var sequence: int = candidate.document.sequence
	model.advance(30.0, 600)
	_write("expected.json", {"id": id, "generator": generator, "before": candidate.document,
		"after": Codec.snapshot(model, id, NAME, sequence)})
	_write("first-run.json", {"layout": "S1-P", "milestones": journey.milestones, "walked_grid_units": journey.distance,
		"manual_transfer_commands": journey.carried, "continuous": continuous, "saved": current,
		"timing": "fixed-step simulation and collision-aware walks; not player elapsed time"})
	print("First run continuous: " + JSON.stringify(continuous))


func _read() -> void:
	var expected: Variant = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("expected.json")))
	driver.expect(expected is Dictionary, "cross-process manifest available")
	if not expected is Dictionary:
		return
	var menu: Control = boot.factory_menu
	driver.expect(menu != null and menu.worlds.size() == 1 and menu.worlds[0].id == expected.id, "Boot lists exactly the saved world")
	if menu == null or menu.worlds.size() != 1:
		return
	menu.list.select(0)
	menu.list.item_selected.emit(0)
	driver.expect(menu.worlds[0].schema == Codec.V9.VERSION and menu.upgrade_button.disabled,
		"normal menu offers continue without an upgrade for schema 9")
	await driver.shot("00-continue-integrated")
	# Pause as soon as Boot opens the world, before a frame can advance the saved clock.
	menu.world_ready.connect(func(_store, _model, _candidate):
		if boot.factory_world != null:
			boot.factory_world._set_paused(true), CONNECT_ONE_SHOT)
	await _click(menu.continue_button)
	var world: Control = boot.factory_world
	driver.expect(world != null and world.initialized, "Boot reconstructs saved world in a separate process")
	if world == null or not world.initialized:
		return
	driver.world = world
	var model: RefCounted = world.model
	var sequence: int = world.store.sequence
	# The menu callback samples the few active microseconds before it pauses Boot.
	var startup_seconds: float = world.production_clock.active_usec / 1000000.0
	var first := _result(model, int(expected.generator))
	var restored := Codec.snapshot(model, expected.id, NAME, sequence)
	restored.state.remainder_s -= startup_seconds
	driver.expect(_matches(restored, expected.before),
		"first frame matches the full saved snapshot")
	driver.expect(world.hud.mission.text.begins_with("富集矿道已开放") and "定位铁矿" not in world.hud.notice.text,
		"restored guidance reflects the opened passage")
	await driver.shot("07-restored-world")
	model.advance(30.0, 600)
	var continued := _result(model, int(expected.generator))
	var after := Codec.snapshot(model, expected.id, NAME, sequence)
	after.state.remainder_s -= startup_seconds
	driver.expect(_matches(after, expected.after),
		"30-second resumed snapshot matches uninterrupted simulation")
	driver.expect(model.material_balance().balanced, "continued world conserves materials")
	_write("restore-result.json", {"first": first, "continued": continued, "startup_active_seconds": startup_seconds,
		"failures": driver.failures})
	await _click(world.hud.buttons["return"])


func _result(model: RefCounted, generator: int) -> Dictionary:
	var g: Dictionary = model.by_id(generator)
	return {"tick": model.statistics.ticks, "core": model.core.items.duplicate(), "researched": model.researched.size(),
		"level": model.core.level, "packs": model.completed_by_recipe.construction_assembly,
		"cells": model.completed_by_recipe.cell_assembly, "plates": model.completed_by_recipe.direct_refining,
		"fuel": g.fuel.duplicate(), "remaining": g.burn_remaining_ticks, "enabled": g.enabled,
		"activations": model.statistics.totals.cells_activated,
		"released_micro_kj": roundi(model.statistics.totals.fuel_released_kj * 1000000.0),
		"spill_micro_kj": roundi(model.statistics.totals.spill_kj * 1000000.0), "passages": model.discovery.passages.duplicate(),
		"rich_batches": model.completed_by_recipe.rich_catalyst, "slag_reuse_batches": model.completed_by_recipe.slag_sintering}


func _matches(actual: Variant, expected: Variant) -> bool:
	if actual is Dictionary:
		if not expected is Dictionary or actual.size() != expected.size():
			return false
		for key in actual:
			if not expected.has(key) or not _matches(actual[key], expected[key]):
				return false
		return true
	if actual is Array:
		if not expected is Array or actual.size() != expected.size():
			return false
		for i in actual.size():
			if not _matches(actual[i], expected[i]):
				return false
		return true
	# Match C's JSON float tolerance while retaining exact integer comparisons.
	if actual is float and (expected is float or expected is int):
		return absf(actual - expected) <= 1e-10 + 1e-12 * maxf(absf(actual), absf(expected))
	return actual == expected


func _write(name: String, value: Variant) -> void:
	var file := FileAccess.open(evidence.path_join(name), FileAccess.WRITE)
	if file == null:
		driver.expect(false, "write evidence " + name)
		return
	file.store_string(JSON.stringify(value, "\t", true, true))
	file.close()


func _finish(phase: String) -> void:
	_write(phase + "-result.json", {"assertions": driver.assertions, "failures": driver.failures, "window": windowed})
	print("Factory integrated first run %s: %d checks, %d failures" % [phase, driver.assertions, driver.failures.size()])
	quit(0 if driver.failures.is_empty() else 1)
