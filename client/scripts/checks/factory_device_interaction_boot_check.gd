extends "res://scripts/checks/factory_statistics_boot_check.gd"

var preview_only := false
var evidence_topic := "factory-device-interaction-v1"
var screenshot_topic := "2026-10-05-factory-device-interaction-preview"

## Reuse the existing focus-aware walking/input and snapshot helpers, with this package's path.
func run() -> void:
	var batch := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--batch="):
			batch = arg.trim_prefix("--batch=")
		read_mode = read_mode or arg == "--read"
		ui_only = ui_only or arg == "--ui-only"
		preview_only = preview_only or arg == "--preview-only"
	assert(batch.is_valid_filename() and not ".." in batch)
	var repo := SliceCheckPaths.repository_root()
	run_root = repo.path_join("tools/runtime-intake/check-runs").path_join(evidence_topic).path_join(batch)
	DirAccess.make_dir_recursive_absolute(run_root)
	driver = Driver.new()
	driver.input_ready = wait_for_focus
	started = Time.get_ticks_usec()
	last_observed_usec = started
	driver.shot_root = repo.path_join("assets/art-intake").path_join(screenshot_topic).path_join(batch)
	DirAccess.make_dir_recursive_absolute(driver.shot_root)
	root.add_child(driver)
	boot = Boot.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(run_root.path_join("slice"))
	boot.factory_save_root = run_root.path_join("factory")
	root.add_child(boot)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1440, 900)
	root.close_requested.connect(func(): driver.expect(false, "window_closed: stopped by user"); finish())
	await driver.settle(30)
	# Use the established keyboard startup path; device/HUD mouse checks remain explicit below.
	await press(boot.startup_menu.get_node("ContentRoot/MenuButtons/FactoryButton"))
	driver.expect(boot.factory_menu != null, "formal factory menu opened by focused Enter")
	if boot.factory_menu == null:
		finish()
		return
	if read_mode:
		var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("expected.json")))
		var index: int = boot.factory_menu.worlds.find_custom(func(entry): return entry.id == saved.world_id)
		driver.expect(index >= 0, "saved world selected by stable ID rather than list order")
		if index < 0:
			finish()
			return
		boot.factory_menu.list.select(index)
		boot.factory_menu.list.item_selected.emit(index)
		boot.factory_menu.continue_button.pressed.emit()
		if boot.factory_world == null:
			driver.expect(false, "read requires a current-version completed write batch")
			finish()
			return
		boot.factory_world.ui.paused = true
		boot.factory_world.production_clock.start(Time.get_ticks_usec(), false)
	else:
		if not preview_only:
			boot.factory_menu.world_type.select(1)
		else:
			driver.expect(boot.factory_menu.world_type.selected == 0, "preview check starts with default foundation world")
		boot.factory_menu.title_input.text = "设备面板与接口 · 正式复核"
		await press(boot.factory_menu.create_button)
	world = boot.factory_world
	driver.world = world
	driver.expect(world != null and world.initialized, "formal factory world initialized")
	if world == null or not world.initialized:
		finish()
		return
	await driver.settle(20)
	if preview_only:
		await _previews()
	elif read_mode:
		await _restore()
	else:
		await _first_line()
	finish()


func _previews() -> void:
	for discovery in [false, true]:
		var kind := "discovery" if discovery else "foundation"
		if discovery:
			boot.factory_menu.world_type.select(1)
			boot.factory_menu.title_input.text = "勘探工厂 · 预览复核"
			await press(boot.factory_menu.create_button)
			world = boot.factory_world
			driver.world = world
			await driver.settle(20)
			await walk(Vector2(-12, 4))
		driver.expect(world.initialized and world.model.has_method("power_state") == discovery, kind + " uses its own authoritative rules")
		await driver.click(world.hud.buttons.pause)
		await driver.click(world.hud.buttons.mission)
		var cells: Dictionary = {"collector": Vector2i(-20, -1), "reactor": Vector2i(-13, -2), "storage": Vector2i(-6, -1)} if discovery else world.model.REFERENCE
		for type in ["collector", "reactor", "storage"]:
			var before := Codec.snapshot(world.model, world.store.world_id, world.store.world_name, world.store.sequence)
			await driver.click(world.hud.buttons[type])
			await driver.motion(driver.cell_screen(cells[type]))
			await driver.settle(10)
			driver.expect(world.ui.cell == cells[type], kind + " mouse moves preview to chosen " + type + " cell")
			driver.expect(world.view.build_model.visible and world.view.build_model.get_child_count() == 1, kind + " shows imported " + type + " before clicking")
			var hints: Array = world.view.port_hints.get_children().filter(func(h): return h.get_meta("entity_id") == -1)
			driver.expect(hints.size() == (2 if type == "reactor" else 1) and world.view.port_hints.visible, kind + " shows " + type + " ports before clicking")
			driver.expect(Check.equivalent(before, Codec.snapshot(world.model, world.store.world_id, world.store.world_name, world.store.sequence)), kind + " preview leaves authoritative state unchanged")
			await driver.shot(kind + "-before-" + type)
			check_failures()
			if finished:
				return
			ids[type] = world.model.next_id
			await driver.world_click(cells[type])
			driver.expect(world.model.by_id(ids[type]).get("type", "") == type, kind + " mouse commits previewed " + type)
		await driver.click(world.hud.buttons.collector)
		await driver.motion(driver.cell_screen(Vector2i(-11, 2) if discovery else Vector2i(-4, 2)))
		await driver.settle()
		driver.expect(not world.model.placement("collector", world.ui.cell).ok and world.view.build_model.visible, kind + " invalid location still shows outline")
		await driver.shot(kind + "-invalid-collector")
		await driver.key(KEY_ESCAPE)
		driver.expect(not world.view.build_model.visible and world.view.port_hints.get_child_count() == 0, kind + " cancel clears transient preview")
		await select_device("storage")
		driver.expect(world.view.port_hints.find_children("*", "Label3D", true, false).is_empty(), kind + " selected device has no floating port text")
		await driver.shot(kind + "-selected-storage")
		await driver.click(world.hud.buttons.zoom_in)
		await driver.click(world.hud.buttons.zoom_in)
		await driver.shot(kind + "-selected-storage-close")
		await driver.click(world.hud.buttons.zoom_out)
		await driver.click(world.hud.buttons.zoom_out)
		await driver.key(KEY_ESCAPE)
		await select_device("collector")
		driver.expect(world.view.port_hints.visible and world.view.port_hints.get_child_count() == 1, kind + " selected collector shows output")
		await driver.click(world.hud.buttons.belt)
		await driver.motion(driver.cell_screen(cells.collector + Vector2i(2, 1)))
		await driver.settle()
		driver.expect(world.view.port_hints.get_children().any(func(h): return h.get_meta("entity_id") == ids.collector), kind + " belt approach retains nearby output guidance")
		await driver.shot(kind + "-belt-approach")
		await driver.key(KEY_ESCAPE)
		if discovery:
			await _power_previews()
			if finished:
				return
		await driver.click(world.hud.buttons.return)
		driver.expect(boot.factory_world == null, kind + " saves and returns cleanly")
		check_failures()
		if finished:
			return


func _power_previews() -> void:
	await driver.click(world.hud.buttons.power_source)
	await driver.motion(driver.cell_screen(Vector2i(-20, -6)))
	await driver.settle(10)
	driver.expect(world.view.power_range.visible, "source placement shows range circles")
	await driver.shot("discovery-before-power-source")
	ids.source = world.model.next_id
	await driver.world_click(Vector2i(-20, -6))
	driver.expect(world.model.by_id(ids.source).get("type", "") == "power_source", "mouse places source")
	await driver.click(world.hud.buttons.power_junction)
	var before := Codec.snapshot(world.model, world.store.world_id, world.store.world_name, world.store.sequence)
	await driver.motion(driver.cell_screen(Vector2i(-17, -3)))
	await driver.settle(10)
	driver.expect(world.ui.cell == Vector2i(-17, -3) and world.view.power_range.visible and world.hud.power_help.visible, "node preview follows mouse with visible range and legend")
	var eligible: Array = world.view.power_range.targets.get_children().map(func(h): return h.get_meta("entity_id"))
	driver.expect(eligible.has(ids.collector) and eligible.has(ids.reactor) and eligible.has(ids.source) and not eligible.has(ids.storage), "live range highlights only reachable powered devices")
	driver.expect(Check.equivalent(before, Codec.snapshot(world.model, world.store.world_id, world.store.world_name, world.store.sequence)), "live power preview does not change authoritative state")
	await driver.shot("discovery-before-power-junction")
	await driver.click(world.hud.buttons.zoom_out)
	await driver.click(world.hud.buttons.zoom_out)
	await driver.shot("discovery-power-range-wide")
	root.size = Vector2i(1100, 720)
	await driver.settle(25)
	driver.expect(world.hud.footer.get_global_rect().encloses(world.hud.power_help.get_global_rect()), "range legend fits minimum window footer")
	await driver.shot("discovery-power-range-minimum")
	root.size = Vector2i(1440, 900)
	await driver.settle(25)
	await driver.motion(driver.cell_screen(Vector2i(-13, -2)))
	await driver.settle(10)
	driver.expect(not world.view.power_range.get_node("ConsumerRange").get_meta("valid") and world.view.power_range.targets.get_child_count() == 0, "occupied placement has red range and no target highlights")
	await driver.shot("discovery-power-range-invalid")
	await driver.key(KEY_ESCAPE)
	driver.expect(not world.view.power_range.visible and not world.hud.power_help.visible, "cancel clears range and legend")
	await driver.click(world.hud.buttons.power_junction)
	await driver.world_click(Vector2i(-17, -3))
	ids.node = world.ui.selected
	driver.expect(world.model.by_id(ids.node).get("type", "") == "power_junction" and world.view.power_range.visible, "placed selected node retains its range")
	driver.expect(world.model.automatic_power and not world.hud.buttons.power_connect.visible and world.model.by_id(ids.reactor).power_node_id != 0, "node placement automatically powers covered devices without wiring controls")
	await driver.shot("discovery-power-range-connected")
	await driver.key(KEY_ESCAPE)
	driver.expect(not world.view.power_range.visible and world.model.power_links.size() == 1, "leaving selection clears guidance while retaining automatic network")
	check_failures()
	if finished:
		return
	await driver.click(world.hud.buttons.pause)
	driver.expect(not world.ui.paused, "resume before walking to shell")
	check_failures()
	if finished:
		return
	await walk(Vector2(-1, 4))
	await driver.shot("discovery-power-range-after-walk")
	await driver.click(world.hud.buttons.pause)
	if not world.ui.paused:
		await driver.shot("failed-pause-near-shell")
		print("Power preview input diagnostic: ", {"hovered": str(root.gui_get_hovered_control()), "actor": world.actor,
			"failure": world.failure_dialog.visible, "unsaved": world.unsaved_dialog.visible, "power": world.power_dialog.visible,
			"discovery": world.discovery_panel.visible, "statistics": world.statistics_panel.visible})
	driver.expect(world.ui.paused, "pause near shell before preview")
	check_failures()
	if finished:
		return
	await driver.click(world.hud.buttons.power_junction)
	check_failures()
	if finished:
		return
	await driver.motion(driver.cell_screen(Vector2i(2, -1)))
	await driver.settle(10)
	driver.expect(world.view.power_range.get_node("ConsumerRange").get_meta("blocked_segments") > 0, "near-shell range shows blocked segments")
	await driver.shot("discovery-power-range-blocked")
	await driver.key(KEY_ESCAPE)


func _first_line() -> void:
	driver.expect(world.model.entities.is_empty() and world.model.bag.is_empty(), "new world has no devices or injected material")
	# Collect the guaranteed sample through the existing native discovery controls.
	await walk(Vector2(2.5, 3.5))
	await driver.click(world.hud.buttons.discovery)
	await native_click(world.discovery_panel.buttons.sample)
	if finished:
		return
	driver.expect(world.model.discovery.sample_taken, "real proximity sample operation remains available")
	await native_click(world.discovery_panel.get_ok_button())
	if ui_only:
		for i in 3:
			await driver.click(world.hud.buttons.discovery)
			await native_click(world.discovery_panel.get_ok_button())
		return
	await walk(Vector2(-12, 4))
	await driver.click(world.hud.buttons.mission)
	# Camera orientation is test preparation; actor movement and production stay natural.
	world.view.yaw = 0
	world.view.sync_camera()
	await driver.click(world.hud.buttons.pause)
	await place("collector", -20, -1, "collector")
	await place("power_source", -20, -6, "source")
	await place("power_junction", -13, -5, "node")
	await driver.click(world.hud.buttons.reactor)
	await driver.motion(driver.cell_screen(Vector2i(-13, -2)))
	await driver.settle()
	driver.expect(world.view.build_model.visible and world.model.entities.size() == 3, "imported preview does not create an entity")
	await driver.shot("01-reactor-before-placement")
	ids.reactor = world.model.next_id
	await driver.world_click(Vector2i(-13, -2))
	driver.expect(world.model.by_id(ids.reactor).get("type", "") == "reactor", "mouse places reactor at preview footprint")
	check_failures()
	await place("storage", -6, -1, "warehouse")
	await driver.click(world.hud.buttons.belt)
	await driver.drag([Vector2i(-18, 0), Vector2i(-17, 0), Vector2i(-16, 0), Vector2i(-15, 0), Vector2i(-14, 0)])
	driver.expect(world.model.entity_at(Vector2i(-14, 0)).get("type", "") == "belt", "real drag reaches displayed input dock")
	await driver.shot("02-drag-input-docks")
	await driver.key(KEY_ESCAPE)
	await select_device("reactor")
	driver.expect("还需" in world.hud.device_summary.production.text and "待机" in world.hud.device_summary.power.text, "live inspector distinguishes missing material from automatic connected power")
	await open_device()
	driver.expect(world.discovery_panel.buttons.crystal_put_one.disabled, "remote operation cannot bypass proximity")
	await native_shot("03-remote-device-actions")
	await native_click(world.discovery_panel.get_ok_button())
	await driver.click(world.hud.buttons.pause)
	await wait_for(func(): return world.model.by_id(ids.reactor).processing, 25, "real first batch begins")
	await driver.shot("04-live-production")
	world.model.set_source_enabled(ids.source, false)
	await active(1, "blackout observation")
	await driver.shot("05-power-off")
	driver.expect("无启用电源" in world.hud.device_summary.power.text, "live panel explains blackout")
	world.model.set_source_enabled(ids.source, true)
	await wait_for(func(): return not world.model.by_id(ids.reactor).output.is_empty(), 20, "first output blocked without belt")
	await driver.settle(15)
	driver.expect("输出尚未清空" in world.hud.device_summary.production.text, "actual backpressure explanation appears")
	await driver.shot("06-output-blocked")
	await walk(Vector2(-12, 2.5))
	await select_device("reactor")
	await open_device()
	var model: RefCounted = world.model
	var frozen: float = model.time
	var actor_at := Vector2(world.actor.x, world.actor.z)
	await create_timer(0.7).timeout
	driver.expect(model.time == frozen and not world._producing(), "operation window pauses production")
	await native_click(world.discovery_panel.buttons.catalyst_take_all)
	driver.expect(model.bag.get("catalyst", 0) == 1 and model.by_id(ids.reactor).output.is_empty(), "native mouse withdraws actual output")
	await native_click(world.discovery_panel.buttons.crystal_take_all)
	driver.expect(model.by_id(ids.reactor).input.is_empty(), "native mouse empties input buffer")
	await native_click(world.discovery_panel.buttons.crystal_put_one)
	driver.expect(model.by_id(ids.reactor).input.get("crystal", 0) == 1, "put one transfers precisely one")
	await native_click(world.discovery_panel.buttons.crystal_put_all)
	driver.expect(model.by_id(ids.reactor).input.get("crystal", 0) == 2, "put all respects recipe input limit")
	await native_shot("07-near-device-actions")
	await native_click(world.discovery_panel.get_ok_button())
	driver.expect(Vector2(world.actor.x, world.actor.z) == actor_at and world.keys.is_empty(), "closing operations does not resume stale movement")
	await active(1.0, "production resumes after operation window")
	await open_device()
	var balance: int = model.material_balance().equivalent
	await native_click(world.discovery_panel.buttons.cancel_batch)
	driver.expect(not model.by_id(ids.reactor).processing and model.material_balance().equivalent == balance, "native cancel returns full invested material")
	await native_click(world.discovery_panel.get_ok_button())
	await driver.click(world.hud.buttons.belt)
	await driver.drag([Vector2i(-10, 0), Vector2i(-9, 0), Vector2i(-8, 0), Vector2i(-7, 0)])
	await driver.key(KEY_ESCAPE)
	await wait_for(func(): return model.by_id(ids.warehouse).items.get("catalyst", 0) >= 1, 25, "repair output by dragging through actual displayed dock")
	await driver.shot("08-repaired-natural-delivery")
	await walk(Vector2(-5, 2.5))
	await select_device("warehouse")
	await open_device()
	await native_click(world.discovery_panel.buttons.catalyst_take_all)
	driver.expect(model.bag.get("catalyst", 0) >= 2, "warehouse exposes real per-material retrieval")
	await native_click(world.discovery_panel.get_ok_button())
	await walk(Vector2(-12, 2.5))
	await select_device("reactor")
	await open_device()
	if model.by_id(ids.reactor).processing:
		await native_click(world.discovery_panel.buttons.cancel_batch)
	for item in ["crystal", "catalyst"]:
		if model.Items.contents(model.by_id(ids.reactor)).get(item, 0) > 0:
			await native_click(world.discovery_panel.buttons[item + "_take_all"])
	world.discovery_panel.recipe.select(world.discovery_panel.recipe_ids.find("solvent_trial"))
	await native_click(world.discovery_panel.buttons.recipe)
	driver.expect(model.by_id(ids.reactor).recipe_id == "solvent_trial", "selected device changes to known trial recipe")
	await native_click(world.discovery_panel.buttons.crust_sample_put_one)
	await native_click(world.discovery_panel.buttons.catalyst_put_all)
	await native_shot("09-trial-device-actions")
	await native_click(world.discovery_panel.get_ok_button())
	await active(2.0, "natural trial half batch")
	await driver.click(world.hud.buttons.pause)
	driver.expect(model.by_id(ids.reactor).processing and model.by_id(ids.reactor).progress > 0, "trial in-process state available for restore")
	await _layout_checks()
	await driver.click(world.hud.buttons.save)
	write_json("expected.json", Codec.snapshot(model, world.store.world_id, world.store.world_name, world.store.sequence))
	write_json("ids.json", ids)
	stage("write-complete", "natural first line, native device actions, output repair and partial trial saved")
	await driver.click(world.hud.buttons.return)
	driver.expect(boot.factory_world == null, "save and return exits cleanly")


func select_device(name: String) -> void:
	var e: Dictionary = world.model.by_id(ids[name])
	var shape: Dictionary = world.model.CATALOG[e.type]
	var point: Vector2 = world.hud.viewport_to_screen(world.view.project(Vector3(e.x + shape.w * 0.5, 1.1, e.z + shape.d * 0.5)))
	driver.expect(world.hud.world_point(point) != null, "selected model is not under HUD")
	await driver.motion(point)
	await driver.mouse(point, true)
	await driver.mouse(point, false)
	await driver.settle()
	driver.expect(world.ui.selected == ids[name], "real model click selects " + name)
	check_failures()


func open_device() -> void:
	world.hud.inspector_scroll.ensure_control_visible(world.hud.buttons.device)
	await driver.settle()
	await driver.click(world.hud.buttons.device)
	driver.expect(world.discovery_panel.visible and world.discovery_panel.device_only, "inspector opens selected-device operations")
	check_failures()


func native_click(button: Button) -> void:
	var window: Window = button.get_window()
	await wait_for_focus(window)
	if button != world.discovery_panel.get_ok_button():
		world.discovery_panel.scroll.ensure_control_visible(button)
	await driver.settle()
	driver.expect(button.is_visible_in_tree() and not button.disabled, "native mouse button available: " + button.text)
	var at := button.get_global_rect().get_center()
	driver.expect(Rect2(Vector2.ZERO, Vector2(window.size)).has_point(at), "native button lies inside window")
	# Embedded dialogs receive mouse routing from their embedding viewport, not push_input on
	# the child Window. Bypassing that route leaves the child's hovered Control unset.
	var input_viewport: Viewport = window.get_parent().get_viewport() if window.is_embedded() else window
	var input_at := at + Vector2(window.position) if window.is_embedded() else at
	driver.expect(input_viewport.get_visible_rect().has_point(input_at), "embedded button lies inside host viewport")
	var presses := [0]
	var observed := func(): presses[0] += 1
	button.pressed.connect(observed)
	var motion := InputEventMouseMotion.new()
	motion.position = input_at
	motion.window_id = window.get_window_id()
	if ui_only:
		print("Native pointer probe: ", {"embedded": window.is_embedded(), "input_at": input_at, "window": window.size, "scale": window.content_scale_size, "button": button.get_global_rect(), "hovered": str(window.gui_get_hovered_control()), "window_id": window.get_window_id()})
		await native_shot("native-before-click")
	# Submit one complete click, then verify its activation after rendering.
	input_viewport.push_input(motion, true)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = input_at
		event.window_id = window.get_window_id()
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		event.pressed = down
		input_viewport.push_input(event, true)
	await driver.settle()
	button.pressed.disconnect(observed)
	driver.expect(presses[0] == 1, "one native mouse activation: " + button.text)
	if presses[0] != 1:
		await native_shot("failed-native-click")
	check_failures()


func _layout_checks() -> void:
	for dimensions in [Vector2i(1100, 720), Vector2i(1440, 900)]:
		root.size = dimensions
		await driver.settle(25)
		world.hud.inspector_scroll.ensure_control_visible(world.hud.buttons.device)
		await driver.settle()
		driver.expect(world.hud.world_slot.get_global_rect().encloses(world.hud.inspector.get_global_rect()), "inspector remains within world at " + str(dimensions))
		await driver.shot("10-layout-%dx%d" % [dimensions.x, dimensions.y])
		await open_device()
		driver.expect(world.discovery_panel.size.y <= 660 and world.discovery_panel.size.x <= 800, "device window fits minimum supported desktop")
		driver.expect(Rect2(Vector2.ZERO, Vector2(world.discovery_panel.size)).encloses(world.discovery_panel.result_label.get_global_rect()), "operation result remains visible outside inventory scrolling")
		await native_shot("11-actions-%dx%d" % [dimensions.x, dimensions.y])
		await native_click(world.discovery_panel.get_ok_button())
		driver.expect(world.ui.paused and not world._producing(), "operation close preserves explicit pause")
	await driver.click(world.hud.buttons.camera_right)
	await driver.click(world.hud.buttons.zoom_out)
	await driver.shot("12-rotated-ports")


func _restore() -> void:
	ids = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("ids.json")))
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("expected.json")))
	# The final save-and-return increments the file sequence without changing the paused state.
	var actual := Codec.snapshot(world.model, world.store.world_id, world.store.world_name, expected.sequence)
	driver.expect(world.store.sequence >= expected.sequence, "restored file sequence retains monotonic save order")
	driver.expect(Check.equivalent(actual, expected), "independent Boot restores full unchanged schema 2 snapshot")
	await select_device("reactor")
	await driver.shot("13-restored-partial-trial")
	await open_device()
	driver.expect(world.discovery_panel.device_summary.progress.value > 0 and "矿壳试制" in world.discovery_panel.device_summary.values.process.text, "restored panel shows saved recipe and partial progress")
	await native_shot("14-restored-device-actions")
	await native_click(world.discovery_panel.get_ok_button())
	await driver.click(world.hud.buttons.pause)
	await wait_for(func(): return world.model.discovery.trial_completed, 15, "restored partial trial completes naturally")
	driver.expect(world.model.statistics.totals.consumed.crust_sample == 1, "restored trial consumes unique sample once")
	stage("read-complete", "independent Boot restore and natural completion of saved partial batch")
	await driver.click(world.hud.buttons.return)


func finish() -> void:
	if finished:
		return
	finished = true
	write_json("preview-result.json" if preview_only else "read-result.json" if read_mode else "write-result.json", {"assertions": driver.assertions, "failures": driver.failures, "stages": stages,
		"foreground_seconds": foreground_seconds, "focus_pauses": focus_pauses, "pending_focus_pause": focus_pause,
		"input": "Default foundation and explicit discovery selection; Boot/create menus: focused synthetic Enter; preview/mouse placement/cancel/selection/nearby belt: synthetic mouse and Escape; discovery approach: synthetic WASD; no state injection" if preview_only else "Boot menu: focused synthetic Enter; HUD/model selection/drag/embedded operation buttons: synthetic mouse; setup devices: existing precision fields/button signal; legal explicit wiring; recipe dropdown index chosen; walking: synthetic WASD; no injected stock/unlocks/actor position or accelerated time"})
	print("Device interaction Boot: %d assertions, %d failures" % [driver.assertions, driver.failures.size()])
	quit(0 if driver.failures.is_empty() else 1)
