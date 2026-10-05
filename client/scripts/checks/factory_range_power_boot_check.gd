extends "res://scripts/checks/factory_device_interaction_boot_check.gd"

const RangeCheck := preload("res://scripts/checks/factory_range_power_check.gd")
const Store := preload("res://scripts/factory/save/store.gd")


func run() -> void:
	evidence_topic = "factory-range-power-v1"
	screenshot_topic = "2026-10-05-factory-range-power-preview"
	await super.run()


func _first_line() -> void:
	driver.expect(world.model.automatic_power and world.model.entities.is_empty(), "formal new discovery world starts with automatic power rules")
	driver.expect(world.view.sample_icon.visible and not world.hud.sample_button.visible, "distant sample has icon and no name")
	await driver.shot("01-sample-distant")
	await driver.key(KEY_F)
	driver.expect(not world.model.discovery.sample_taken and world.model.bag.is_empty(), "remote F cannot take sample")
	await walk(Vector2(1.5, 3.2))
	await driver.settle(10)
	driver.expect(world.hud.sample_button.visible, "walking close reveals sample name and pickup action")
	check_failures()
	if finished:
		return
	await driver.shot("02-sample-near")
	root.size = Vector2i(1100, 720)
	await driver.settle(25)
	driver.expect(world.hud.world_slot.get_global_rect().encloses(world.hud.sample_button.get_global_rect()), "sample action stays inside minimum window")
	await driver.shot("03-sample-minimum")
	root.size = Vector2i(1440, 900)
	await driver.settle(25)
	await driver.key(KEY_F)
	driver.expect(world.model.discovery.sample_taken and world.model.bag.get("crust_sample", 0) == 1, "F performs real unique pickup")
	driver.expect(not world.hud.sample_button.visible and not is_instance_valid(world.view.sample_icon), "picked-up sample clears shape, icon and name")
	await driver.key(KEY_F)
	driver.expect(world.model.statistics.totals.acquired.get("crust_sample", 0) == 1, "repeat key cannot duplicate sample")
	await driver.shot("04-sample-picked-up")
	check_failures()
	if finished:
		return
	await walk(Vector2(-12, 4))
	await driver.click(world.hud.buttons.pause)
	for spec in [["collector", -20, -1, "collector"], ["reactor", -13, -2, "reactor"], ["storage", -6, -1, "warehouse"],
		["power_source", -20, -6, "source"], ["power_junction", -17, -3, "node"]]:
		await _mouse_place(spec[0], Vector2i(spec[1], spec[2]), spec[3])
		if finished:
			return
	driver.expect(world.model.power_links.size() == 1 and world.model.by_id(ids.reactor).power_node_id != 0, "mouse placements automatically connect source, node and consumer")
	driver.expect(not world.hud.buttons.power_connect.visible and "自动接电" in world.hud.power_help.text, "automatic world explains coverage and hides manual wire controls")
	await driver.shot("05-node-automatically-connected")
	await driver.click(world.hud.buttons.belt)
	await driver.drag([Vector2i(-18, 0), Vector2i(-17, 0), Vector2i(-16, 0), Vector2i(-15, 0), Vector2i(-14, 0)])
	await driver.key(KEY_ESCAPE)
	await driver.click(world.hud.buttons.belt)
	await driver.drag([Vector2i(-10, 0), Vector2i(-9, 0), Vector2i(-8, 0), Vector2i(-7, 0)])
	await driver.key(KEY_ESCAPE)
	await driver.click(world.hud.buttons.pause)
	await wait_for(func(): return world.model.delivered > 0, 35, "ordinary line delivers catalyst without any wiring command")
	if finished:
		return
	await select_device("reactor")
	await driver.shot("06-natural-automatic-production")
	await wait_for(func(): return world.model.by_id(ids.reactor).processing and world.model.by_id(ids.reactor).progress > 1, 15, "natural partial batch for blackout")
	await select_device("source")
	await driver.click(world.hud.buttons.power_toggle)
	var progress: float = world.model.by_id(ids.reactor).progress
	await active(0.7, "automatic network blackout")
	driver.expect(world.model.by_id(ids.reactor).progress == progress, "turning off source holds actual batch")
	await select_device("reactor")
	driver.expect("无启用电源" in world.hud.device_summary.power.text, "connected but unpowered network explains its cause")
	await driver.shot("07-automatic-network-blackout")
	await select_device("source")
	await driver.click(world.hud.buttons.power_toggle)
	await active(0.3, "automatic network resumes")
	await driver.click(world.hud.buttons.pause)
	await select_device("reactor")
	driver.expect(world.model.by_id(ids.reactor).processing and world.model.by_id(ids.reactor).progress > progress, "repowered partial batch continues")
	await driver.shot("08-save-partial-batch")
	await driver.click(world.hud.buttons.save)
	write_json("expected.json", Codec.snapshot(world.model, world.store.world_id, world.store.world_name, world.store.sequence))
	write_json("ids.json", ids)
	stage("new-world-complete", "natural automatic production, direct F pickup and partial-batch save")
	await driver.click(world.hud.buttons.return)
	check_failures()
	if finished:
		return
	await _upgrade_and_click_pickup()


func _mouse_place(type: String, cell: Vector2i, tag: String) -> void:
	await driver.click(world.hud.buttons[type])
	ids[tag] = world.model.next_id
	await driver.world_click(cell)
	driver.expect(world.model.by_id(ids[tag]).get("type", "") == type, "real mouse places " + type)
	check_failures()


func _upgrade_and_click_pickup() -> void:
	# A prepared legacy layout specifically tests migration; it is not claimed as
	# a naturally built player path. The new-world production above is separate.
	var legacy := Store.new(run_root.path_join("factory"))
	var created := legacy.create("旧接线布局 · 升级复核", RangeCheck.Model.DiscoveryRules.SUPPLY_ID)
	var model: RefCounted = RangeCheck.build_line(created.model)
	driver.expect(legacy.save(model).ok, "prepared legacy layout saved without wire connections")
	var id: String = legacy.world_id
	var file: String = legacy.path("autosave.json")
	var hash := FileAccess.get_sha256(file)
	legacy.release()
	boot.factory_menu.refresh()
	var index: int = boot.factory_menu.worlds.find_custom(func(entry): return entry.id == id)
	boot.factory_menu.list.select(index)
	boot.factory_menu.list.item_selected.emit(index)
	await press(boot.factory_menu.continue_button)
	driver.expect(boot.factory_menu.upgrade_dialog.visible, "legacy menu explicitly announces rule upgrade")
	await driver.shot("09-upgrade-confirmation")
	await _upgrade_click(boot.factory_menu.upgrade_dialog.get_cancel_button())
	driver.expect(FileAccess.get_sha256(file) == hash and not DirAccess.dir_exists_absolute(legacy.path("session.lock")), "cancelling upgrade leaves original file and locks untouched")
	await press(boot.factory_menu.continue_button)
	await _upgrade_click(boot.factory_menu.upgrade_dialog.get_ok_button())
	world = boot.factory_world
	driver.world = world
	driver.expect(world != null and world.initialized and world.model.automatic_power, "confirmed upgrade reconstructs automatic world")
	check_failures()
	if finished:
		return
	await driver.settle(10)
	var backups: Array = Array(DirAccess.get_files_at(legacy.path("backups"))).filter(func(name): return name.begins_with("pre-auto-power-v2-") and name.ends_with(".json"))
	driver.expect(backups.size() == 1 and FileAccess.get_sha256(legacy.path("backups/" + backups[0])) == hash, "real menu upgrade retains original bytes outside rotating backups")
	driver.expect(world.model.entity_at(Vector2i(-13, -2)).power_node_id != 0, "existing user's-style layout is powered after upgrade")
	await walk(Vector2(-4, 4))
	var at: Vector2 = world.hud.viewport_to_screen(world.view.sample_screen())
	await driver.motion(at)
	await driver.mouse(at, true)
	await driver.mouse(at, false)
	await driver.settle()
	driver.expect(world.pending_sample, "clicking distant icon starts a real approach")
	await driver.key(KEY_ESCAPE)
	driver.expect(not world.pending_sample and not world.model.discovery.sample_taken, "Escape cancels pending pickup without acquiring sample")
	at = world.hud.viewport_to_screen(world.view.sample_screen())
	await driver.motion(at)
	await driver.mouse(at, true)
	await driver.mouse(at, false)
	await wait_for(func(): return world.model.discovery.sample_taken, 8, "ground icon click approaches and picks up")
	if finished:
		return
	driver.expect(world.model.bag.get("crust_sample", 0) == 1 and world.model.statistics.totals.acquired.crust_sample == 1, "ground interaction acquires exactly one real sample")
	await driver.shot("10-ground-click-picked-up")
	await walk(Vector2(-12, 4))
	await wait_for(func(): return world.model.delivered > 0, 30, "upgraded old layout produces without manual reconnection")
	await driver.shot("11-upgraded-layout-producing")
	stage("upgrade-complete", "explicit menu upgrade with retained original, direct ground pickup and natural production")
	await driver.click(world.hud.buttons.return)


func _upgrade_click(button: Button) -> void:
	var window := button.get_window()
	await wait_for_focus(window)
	await driver.settle()
	var viewport: Viewport = window.get_parent().get_viewport() if window.is_embedded() else window
	var at := button.get_global_rect().get_center() + (Vector2(window.position) if window.is_embedded() else Vector2.ZERO)
	var count := [0]
	var observed := func(): count[0] += 1
	button.pressed.connect(observed)
	var motion := InputEventMouseMotion.new()
	motion.position = at
	viewport.push_input(motion, true)
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
		event.pressed = down
		viewport.push_input(event, true)
		await process_frame
	await driver.settle()
	button.pressed.disconnect(observed)
	driver.expect(count[0] == 1, "one real upgrade-dialog activation: " + button.text)
	check_failures()


func _restore() -> void:
	ids = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("ids.json")))
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("expected.json")))
	var actual := Codec.snapshot(world.model, world.store.world_id, world.store.world_name, expected.sequence)
	driver.expect(Check.equivalent(actual, expected) and actual.save_schema_version == 3, "independent Boot restores full automatic snapshot")
	driver.expect(world.model.automatic_power and world.model.bag.crust_sample == 1 and world.model.statistics.totals.acquired.crust_sample == 1, "restore preserves power mode and unique sample")
	driver.expect(not is_instance_valid(world.view.sample_icon) and not world.hud.sample_button.visible, "collected ground sample remains absent after restart")
	await select_device("reactor")
	await driver.shot("12-restored-automatic-world")
	var delivered: int = world.model.delivered
	await driver.click(world.hud.buttons.pause)
	await wait_for(func(): return world.model.delivered > delivered, 20, "restored partial batch completes naturally")
	driver.expect(world.model.statistics.totals.acquired.crust_sample == 1, "continued production does not repeat pickup")
	await driver.shot("13-restored-natural-production")
	stage("read-complete", "schema 3 full restore and natural completion of saved batch")
	await driver.click(world.hud.buttons.return)


func finish() -> void:
	if finished:
		return
	finished = true
	write_json("read-result.json" if read_mode else "write-result.json", {"assertions": driver.assertions, "failures": driver.failures,
		"stages": stages, "foreground_seconds": foreground_seconds, "focus_pauses": focus_pauses, "pending_focus_pause": focus_pause,
		"input": "Boot/create/upgrade entry: focused synthetic Enter; restore selection/continue: list/button signals for first-frame snapshot. Models, HUD, upgrade dialog and ground icon: routed synthetic mouse; walking: WASD; near pickup: F. New world uses natural production without wiring, stock/actor injection or time acceleration. Legacy upgrade separately uses a declared prepared disconnected layout."})
	print("Range power Boot: %d assertions, %d failures" % [driver.assertions, driver.failures.size()])
	quit(0 if driver.failures.is_empty() else 1)
