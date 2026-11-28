extends SceneTree

const Boot := preload("res://scenes/boot/Boot.tscn")
const Route := preload("res://scripts/checks/factory_integrated_first_route.gd")
const Driver := preload("res://scripts/checks/factory_window_driver.gd")
const Store := preload("res://scripts/factory/save/store.gd")
const Codec := Store.Codec
const NAME := "整合工厂联合首程"
const LIVE_SECONDS := 35.0

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
	_check_r2_core(world, "normal creation")
	await driver.shot("01-empty-world")
	if windowed:
		var spawn := Vector2(model.actor.x, model.actor.z)
		await driver.click(world.hud.buttons.guide_action)
		driver.expect(world.view.inspection_target == null and world.hud.waypoint_panel.visible and world.hud.waypoint_map.target == Vector2(-27.0, -11.0),
			"first objective pins the offscreen iron site while keeping the camera on the actor")
		driver.expect(Vector2(model.actor.x, model.actor.z) == spawn, "locating the ore leaves the actor at spawn")
		await driver.shot("01a-iron-located")
		await driver.click(world.hud.buttons.clear_waypoint)
	var layout: Variant = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("layout.json")))
	driver.expect(layout is Dictionary and layout.get("layout") == "S1-P", "validated four-sided layout loaded")
	if not layout is Dictionary:
		return
	var journey := Route.new(model, layout)
	if windowed:
		journey.prepare_core_upgrade()
		journey.walk_to(Vector2(-8, 20.5))
		if not await _upgrade_at_core(world):
			return
		journey.finish_bootstrap()
	else:
		journey.bootstrap()
	await driver.settle()
	_check_r2_core(world, "tier II upgrade")
	await driver.shot("02-tier-ii-from-stock")
	journey.energy_line()
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
	journey.walk_to(Vector2(-8, 20.5))
	var traffic := journey.observe_core_outputs()
	driver.expect(traffic.size() == 4 and model.material_balance().balanced,
		"all four core outputs carry their configured item on real belts")
	await driver.shot("03-four-outputs-live")
	if windowed:
		await _inspect_minimum_window(world)
	await driver.shot("05-continuous-production")
	if "--live" in OS.get_cmdline_user_args() and not await _sample_live_production(world, journey.devices.G.id):
		return
	if windowed:
		journey.walk_near(journey.devices.R)
		await _check_reactor_panel(world, journey.devices.R, false)
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
		"manual_transfer_commands": journey.carried, "continuous": continuous, "core_output_traffic": traffic, "saved": current,
		"timing": "fixed-step simulation and collision-aware walks; not player elapsed time"})
	print("First run continuous: " + JSON.stringify(continuous))
	journey.check_split_furnace_ports()
	journey.check_rich_return_outlet()
	journey.check_pack_input_recovery()


func _sample_live_production(world: Control, generator: int) -> bool:
	if not windowed or not root.has_focus():
		driver.expect(false, "live production needs a focused window")
		return false
	var model: RefCounted = world.model
	var focus_lost := [false]
	var interrupt := func(): focus_lost[0] = true
	root.focus_exited.connect(interrupt)
	var before := _result(model, generator)
	var deficit_before: float = model.statistics.totals.deficit_kj
	world.sample_enabled = true
	world._set_paused(false)
	var start: int = world.production_clock.last_usec
	var draw_calls := []
	while world.production_clock.last_usec - start < LIVE_SECONDS * 1000000.0 and not focus_lost[0] and not world.save_failed:
		await process_frame
		if not root.has_focus():
			focus_lost[0] = true
		if not focus_lost[0]:
			draw_calls.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	var elapsed: float = (world.production_clock.last_usec - start) / 1000000.0
	world.sample_enabled = false
	world._set_paused(true)
	root.focus_exited.disconnect(interrupt)
	var after := _result(model, generator)
	_write("live-production.json", {"focus_lost": focus_lost[0], "seconds": elapsed,
		"renderer": RenderingServer.get_current_rendering_method(), "adapter": RenderingServer.get_video_adapter_name(),
		"window_pixels": [root.size.x, root.size.y], "viewport_pixels": [world.hud.subviewport.size.x, world.hud.subviewport.size.y],
		"zoom": world.view.zoom, "entities": model.entities.size(), "frame_ms": world.frame_samples,
		"simulation_ms": world.simulation_samples, "draw_calls": draw_calls, "autosaves": world.save_samples,
		"before": before, "after": after})
	if focus_lost[0] or world.save_failed:
		driver.expect(false, "continuous live sample interrupted; partial evidence retained")
		return false
	driver.expect(elapsed >= LIVE_SECONDS and not draw_calls.is_empty(), "focused window production sample reaches its duration")
	driver.expect(after.tick > before.tick and after.cells > before.cells and after.plates > before.plates,
		"live production advances and makes both cells and plates")
	var expected_release := roundi((after.tick - before.tick) * Route.STEP * Route.Model.Energy.GENERATOR_KW * 1000000.0)
	driver.expect(after.released_micro_kj - before.released_micro_kj == expected_release
		and is_equal_approx(model.statistics.totals.deficit_kj, deficit_before), "continuous fixed burn and sufficient power throughout sample")
	driver.expect(not world.save_samples.is_empty() and world.save_samples.all(func(sample): return sample.ok),
		"natural autosaves complete during the sample")
	return driver.failures.is_empty()


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
	_check_r2_core(world, "independent continue")
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
	var factory_mission: String = world.hud.mission.text
	await _click(world.hud.buttons.discovery)
	await _click(world.discovery_panel.buttons.mine_location)
	driver.expect(world.ui.waypoint.get("mine", false) and world.hud.buttons.clear_waypoint.text == "返回工厂目标",
		"mine tracking names the way back to the factory objective")
	await _click(world.hud.buttons.clear_waypoint)
	driver.expect(world.ui.waypoint.is_empty() and world.hud.mission.text == factory_mission,
		"leaving mine tracking restores the current factory objective")
	await _click(world.hud.buttons.guide_action)
	driver.expect(world.hud.waypoint_panel.visible and world.hud.buttons.clear_waypoint.text == "关闭定位",
		"ordinary factory waypoints keep their map action after mine tracking")
	await _click(world.hud.buttons.clear_waypoint)
	model.advance(30.0, 600)
	var continued := _result(model, int(expected.generator))
	var after := Codec.snapshot(model, expected.id, NAME, sequence)
	after.state.remainder_s -= startup_seconds
	driver.expect(_matches(after, expected.after),
		"30-second resumed snapshot matches uninterrupted simulation")
	driver.expect(model.material_balance().balanced, "continued world conserves materials")
	if windowed:
		var reactor_index: int = model.entities.find_custom(func(e): return e.get("recipe_id") == "basic_catalyst")
		driver.expect(reactor_index >= 0, "continued world contains the original catalyst reactor")
		if reactor_index >= 0:
			var reactor: Dictionary = model.entities[reactor_index]
			var walk := Route.new(model, {})
			walk.advance_movement = false
			walk.walk_near(reactor)
			await _check_reactor_panel(world, reactor, true)
	_write("restore-result.json", {"first": first, "continued": continued, "startup_active_seconds": startup_seconds,
		"failures": driver.failures})
	await _click(world.hud.buttons["return"])


func _check_reactor_panel(world: Control, reactor: Dictionary, minimum: bool) -> void:
	var original_size := root.size
	if minimum:
		root.size = Vector2i(1100, 720)
		root.move_to_center()
		await driver.settle(12)
		driver.expect(root.size == Vector2i(1100, 720), "continued reactor panel uses the actual minimum window")
	await driver.settle()
	var center: Vector2 = world.model.Grid.center(reactor)
	var projected: Vector2 = world.view.project(Vector3(center.x - 0.25, 2.0, center.y - 0.2))
	var mouse: Vector2 = world.hud.viewport_to_screen(projected)
	driver.expect(world.view.hit(projected) == reactor.id, "world reactor can be picked from its visible geometry")
	await driver.motion(mouse)
	if minimum:
		await driver.mouse(mouse, true)
		await driver.mouse(mouse, false)
		await driver.settle()
	else:
		await driver.key(KEY_F)
	var panel: Control = world.discovery_panel
	var opened: bool = panel.visible and panel.selected == reactor.id
	driver.expect(opened, "reactor opens its panel through the normal input path")
	if opened:
		var visual: Dictionary = world.view.models[reactor.id]
		var placed: Node3D = visual.root.get_child(0)
		var thumbnail: Node3D = panel.device_summary.preview.asset
		var expected: String = world.View.FOUNDATION_REACTOR_PATH
		driver.expect(placed.scene_file_path == expected and thumbnail.scene_file_path == expected,
			"the world and panel thumbnail both instantiate the R2 reactor scene")
		var placed_parts: Array = visual.focus_parts
		var preview_parts := thumbnail.find_children("*", "MeshInstance3D", true, false)
		var shared_surfaces := 0
		var coated := 0
		for i in mini(placed_parts.size(), preview_parts.size()):
			var material := placed_parts[i].get_active_material(0) as StandardMaterial3D
			if placed_parts[i].mesh == preview_parts[i].mesh and material == preview_parts[i].get_active_material(0):
				shared_surfaces += 1
				if material != null and material.albedo_texture != null and material.uv1_triplanar:
					coated += 1
		driver.expect(shared_surfaces == 7 and coated == 4, "world and panel share %d meshes and %d coated surfaces (expected 7 and 4)" % [shared_surfaces, coated])
		await driver.shot("07a-restored-r2-reactor-panel" if minimum else "05a-r2-reactor-panel")
		await driver.click(panel.buttons.close)
	if minimum:
		root.size = original_size
		root.move_to_center()
		await driver.settle(12)


func _check_r2_core(world: Control, stage: String) -> void:
	var graphic: Node3D = world.view.models[world.model.core.id].root
	var tiers := graphic.find_child("TierModules", true, false)
	var level: int = world.model.core.level
	driver.expect(world.view.assets.base_core.resource_path == world.View.FOUNDATION_CORE_PATH
		and tiers.get_node("I").visible == (level == 1) and tiers.get_node("II").visible == (level == 2),
		stage + " loads the formal R2 scene and active tier")
	var coated := 0
	for part: MeshInstance3D in graphic.find_children("*", "MeshInstance3D", true, false):
		var material := part.get_active_material(0) as StandardMaterial3D
		if material != null and material.albedo_texture != null and material.uv1_triplanar:
			coated += 1
	driver.expect(coated == 4, stage + " retains the four approved surface overrides")


func _upgrade_at_core(world: Control) -> bool:
	await driver.settle()
	await driver.motion(driver.cell_screen(Vector2i(-8, 24), 2.5))
	await driver.key(KEY_F)
	var panel: Control = world.core_panel
	driver.expect(panel.visible and world.ui.selected == world.model.core.id, "nearby F opens the formal R2 core")
	if not panel.visible:
		return false
	panel.tabs.current_tab = 3
	await driver.settle()
	var packs: int = world.model.core.items.get("construction_pack", 0)
	await driver.click(panel.upgrade_button)
	var upgraded: bool = world.model.core.level == 2
	driver.expect(upgraded and world.model.core.items.get("construction_pack", 0) == packs - 2,
		"upgrade button consumes two produced packs")
	await driver.click(panel.close_button)
	await driver.key(KEY_ESCAPE)
	return upgraded


func _inspect_minimum_window(world: Control) -> void:
	var original_size := root.size
	root.size = Vector2i(1100, 720)
	root.move_to_center()
	await driver.settle(12)
	driver.expect(root.size == Vector2i(1100, 720), "native window reaches its minimum size")
	await driver.shot("03a-r2-minimum-window")
	await driver.world_click(Vector2i(-8, 24), 2.5)
	var panel: Control = world.core_panel
	driver.expect(panel.visible and world.ui.selected == world.model.core.id, "mouse selection opens the R2 core at minimum size")
	if panel.visible:
		panel.tabs.current_tab = 1
		await driver.shot("03b-r2-minimum-interfaces")
		await driver.click(panel.close_button)
		await driver.key(KEY_ESCAPE)
	root.size = original_size
	root.move_to_center()
	await driver.settle(12)


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
