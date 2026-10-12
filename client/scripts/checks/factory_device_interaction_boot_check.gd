extends "res://scripts/checks/factory_statistics_boot_check.gd"

var preview_only := false
var evidence_topic := "factory-device-interaction-v1"
var screenshot_topic := "2026-10-08-factory-device-interaction-preview"
var input_description_override := ""

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
	driver.capture_screenshots = not background_mode
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
		if not await select_device("storage"):
			return
		driver.expect(world.view.port_hints.find_children("*", "Label3D", true, false).is_empty(), kind + " selected device has no floating port text")
		await driver.shot(kind + "-selected-storage")
		await driver.click(world.hud.buttons.zoom_in)
		await driver.click(world.hud.buttons.zoom_in)
		await driver.shot(kind + "-selected-storage-close")
		await driver.click(world.hud.buttons.zoom_out)
		await driver.click(world.hud.buttons.zoom_out)
		await driver.key(KEY_ESCAPE)
		if not await select_device("collector"):
			return
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
	driver.expect(world.model.automatic_power and not world.hud.buttons.has("power_connect") and world.model.by_id(ids.reactor).power_node_id != 0, "node placement automatically powers covered devices without wiring controls")
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
	driver.expect(world.model.entities.is_empty() and world.model.bag.is_empty(), "new world has no injected devices or material")
	var initial_actor: Dictionary = world.actor.duplicate(true)
	var initial_kits: Dictionary = world.model.kits.duplicate()
	await native_click(world.hud.buttons.guide_action)
	driver.expect(world.ui.tool == "collector" and world.model.entities.is_empty() and world.model.kits == initial_kits, "first goal selects collector without building or spending")
	driver.expect(world.actor == initial_actor, "first goal leaves actor in place")
	await driver.key(KEY_ESCAPE)
	# A distant click requests approach only; arriving and waiting must not acquire anything.
	var sample_at: Vector2 = world.hud.viewport_to_screen(world.view.sample_screen())
	await driver.motion(sample_at)
	await driver.mouse(sample_at, true)
	await driver.mouse(sample_at, false)
	await wait_for(func(): return world.model.near_sample() and not world.pending_sample, 10, "sample approach stops at interaction range")
	await active(0.5, "waiting near sample requires explicit confirmation")
	driver.expect(not world.model.discovery.sample_taken and world.model.bag.is_empty(), "arrival and nearby waiting never pick up sample")
	await driver.shot("00-sample-awaits-confirmation")
	await driver.key(KEY_F)
	driver.expect(world.model.discovery.sample_taken, "F retains direct sample interaction when no device is targeted")
	await native_click(world.hud.buttons.discovery)
	driver.expect(world.discovery_panel.guide_overview.visible and "首条产线" in world.discovery_panel.guide_overview.text and "内矿道" in world.discovery_panel.guide_overview.text, "process review retains all journey steps beside the new device panel")
	var frozen: float = world.model.time
	await create_timer(0.4).timeout
	driver.expect(world.model.time == frozen and not world._producing(), "general process review retains pause contract")
	await native_click(world.discovery_panel.buttons.close)
	if ui_only:
		return
	await walk(Vector2(-12, 4))
	await native_click(world.hud.buttons.mission)
	world.view.yaw = 0 # Camera setup only; all travel below uses the real movement path.
	world.view.sync_camera()
	await native_click(world.hud.buttons.pause)
	await place("collector", -20, -1, "collector")
	await place("power_source", -20, -6, "source")
	await place("power_junction", -13, -5, "node")
	await place("reactor", -13, -2, "reactor")
	await place("storage", -6, -1, "warehouse")
	await native_click(world.hud.buttons.belt)
	await driver.drag([Vector2i(-18, 0), Vector2i(-17, 0), Vector2i(-16, 0), Vector2i(-15, 0), Vector2i(-14, 0)])
	await driver.key(KEY_ESCAPE)
	if not await select_device("reactor"):
		return
	driver.expect(not world.discovery_panel.visible and not world.hud.inspector.visible, "far click does not open operations or a duplicate inspector")
	driver.expect("两格内" in world.hud.notice.text and "Tab" in world.hud.notice.text, "far selection explains proximity and nearby target cycling; actual: " + world.hud.notice.text)
	await driver.shot("01-distant-selection")
	await native_click(world.hud.buttons.pause)
	await walk(Vector2(-12, 2.5))
	if not await select_device("reactor"):
		return
	driver.expect(world.discovery_panel.visible and world.discovery_panel.device_only, "near model click directly opens unified panel")
	driver.expect(not world.hud.inspector.visible, "unified panel has no right-side duplicate")
	await wait_for(func(): return world.model.by_id(ids.reactor).processing, 25, "first batch starts with panel open")
	var progress: float = world.model.by_id(ids.reactor).progress
	var actor_at := Vector2(world.actor.x, world.actor.z)
	var count: int = world.model.entities.size()
	await driver.key(KEY_D, true)
	await driver.key(KEY_1)
	await active(1.2, "device panel keeps production and logistics running")
	await driver.key(KEY_D, false)
	driver.expect(world.model.by_id(ids.reactor).progress > progress and world._producing(), "open panel advances real batch progress")
	driver.expect(Vector2(world.actor.x, world.actor.z) == actor_at and world.keys.is_empty() and world.model.entities.size() == count and world.ui.tool.is_empty(), "panel absorbs movement and construction shortcuts")
	driver.expect(absf(world.discovery_panel.device_summary.progress.value - world.model.by_id(ids.reactor).progress * 10) < 3, "display tracks live batch progress")
	await native_shot("02-live-reactor")
	await _layout_checks()
	await native_click(world.discovery_panel.buttons.pause)
	frozen = world.model.time
	await create_timer(0.5).timeout
	driver.expect(world.ui.paused and world.model.time == frozen, "manual pause still stops production inside device panel")
	await driver.key(KEY_ESCAPE)
	driver.expect(not world.discovery_panel.visible and world.ui.paused, "Escape closes without changing pause preference")
	await native_click(world.hud.buttons.pause)
	# Proximity stays valid when the camera points elsewhere; Tab explicitly chooses a target.
	await driver.settle(20)
	var reachable: Array = world.InteractionTarget.candidates(world.model)
	driver.expect(reachable.any(func(t): return t.id == ids.reactor), "nearby reactor is reachable independently of screen center")
	var first: int = world._interaction_target().id
	await native_click(world.hud.buttons.camera_right)
	driver.expect(world._interaction_target().id == first, "camera rotation does not change actor-based interaction target")
	await native_click(world.hud.buttons.camera_left)
	for i in reachable.size():
		if world.ui.focus_device == ids.reactor:
			break
		await driver.key(KEY_TAB)
	driver.expect(world.ui.focus_device == ids.reactor and world.ui.focus_ready, "Tab selects nearby reactor with matching highlight")
	await driver.shot("03-nearby-highlight")
	await driver.key(KEY_F)
	driver.expect(world.discovery_panel.visible and world.discovery_panel.selected == ids.reactor, "F opens the highlighted nearby reactor")
	check_failures()
	if finished:
		return
	await wait_for(func(): return not world.model.by_id(ids.reactor).output.is_empty(), 20, "real output blocks without outgoing belt")
	await driver.settle(20)
	driver.expect("输出尚未清空" in world.discovery_panel.device_summary.production.text, "live panel explains real output backpressure")
	await native_shot("04-output-blocked")
	await native_click(world.discovery_panel.buttons.close)
	await native_click(world.hud.buttons.mission)
	driver.expect("出料被占用" in world.hud.mission.text, "goal explains the same natural output blockage")
	await driver.shot("04-blocked-goal")
	await native_click(world.hud.buttons.guide_action)
	driver.expect(world.discovery_panel.visible and world.discovery_panel.selected == ids.reactor and world._producing(), "blocked goal opens nearby live reactor operations")
	await native_click(world.discovery_panel.buttons.catalyst_take_all)
	driver.expect(world.model.bag.get("catalyst", 0) == 1, "live withdrawal takes actual completed product")
	await native_click(world.discovery_panel.buttons.close)
	await native_click(world.hud.buttons.belt)
	await driver.drag([Vector2i(-10, 0), Vector2i(-9, 0), Vector2i(-8, 0), Vector2i(-7, 0)])
	await driver.key(KEY_ESCAPE)
	await wait_for(func(): return world.model.by_id(ids.warehouse).items.get("catalyst", 0) >= 1, 25, "repaired output delivers naturally")
	await walk(Vector2(-5, 2.5))
	if not await select_device("warehouse"):
		return
	await native_shot("05-storage")
	var stored: int = world.model.by_id(ids.warehouse).items.get("catalyst", 0)
	await wait_for(func(): return world.model.by_id(ids.warehouse).items.get("catalyst", 0) > stored, 20, "warehouse inventory rises while its panel is open")
	await driver.settle(15)
	driver.expect(world.discovery_panel.device_summary.slots.input.catalyst.amount == world.model.by_id(ids.warehouse).items.get("catalyst", 0), "warehouse live inventory is displayed")
	await native_click(world.discovery_panel.buttons.catalyst_take_all)
	driver.expect(world.model.bag.get("catalyst", 0) >= 2, "warehouse supplies natural ingredients for trial")
	await native_click(world.discovery_panel.buttons.close)
	await driver.key(KEY_I)
	driver.expect(world.discovery_panel.inventory_only and world._producing(), "I opens standalone live inventory")
	await native_shot("05-backpack")
	await driver.key(KEY_I)
	driver.expect(not world.discovery_panel.visible, "I closes inventory and returns field input")
	await _other_devices()
	if finished:
		return
	await walk(Vector2(-12, 2.5))
	if not await select_device("reactor"):
		return
	await native_click(world.discovery_panel.buttons.pause)
	# Manual pause is an explicit player action, used here to prepare a deterministic recipe change.
	if world.model.by_id(ids.reactor).processing:
		await native_click(world.discovery_panel.buttons.cancel_batch)
	for item in ["crystal", "catalyst"]:
		if world.model.Items.contents(world.model.by_id(ids.reactor)).get(item, 0) > 0:
			await native_click(world.discovery_panel.buttons[item + "_take_all"])
	world.discovery_panel.recipe.select(world.discovery_panel.recipe_ids.find("solvent_trial"))
	await driver.settle(25)
	driver.expect(world.discovery_panel.recipe_ids[world.discovery_panel.recipe.selected] == "solvent_trial", "periodic refresh preserves player's pending recipe choice")
	await native_click(world.discovery_panel.buttons.recipe)
	driver.expect(world.model.by_id(ids.reactor).recipe_id == "solvent_trial", "near device accepts recipe change")
	await native_click(world.discovery_panel.buttons.crust_sample_put_one)
	await native_click(world.discovery_panel.buttons.catalyst_put_all)
	await native_click(world.discovery_panel.buttons.pause)
	await active(2, "trial starts and progresses inside live device panel")
	await native_click(world.discovery_panel.buttons.pause)
	driver.expect(world.model.by_id(ids.reactor).processing and world.model.by_id(ids.reactor).progress > 0, "partial trial prepared naturally for independent restore")
	await native_shot("10-partial-trial")
	await native_click(world.discovery_panel.buttons.close)
	await native_click(world.hud.buttons.save)
	write_json("expected.json", Codec.snapshot(world.model, world.store.world_id, world.store.world_name, world.store.sequence))
	write_json("ids.json", ids)
	stage("write-complete", "live item grids, nearby F/Tab, manual sample pickup, all device types and partial trial saved")
	await native_click(world.hud.buttons.return)
	driver.expect(boot.factory_world == null, "save and return exits cleanly")


func _other_devices() -> void:
	await walk(Vector2(-16, 3))
	await walk(Vector2(-21, 3))
	await walk(Vector2(-21, 2))
	if not await select_device("collector"):
		return
	driver.expect(world.discovery_panel.visible and world.discovery_panel.device_summary.cards.output.visible, "near collector shows live extraction buffer")
	await native_shot("06-collector")
	await native_click(world.discovery_panel.buttons.close)
	await walk(Vector2(-21, -3))
	await walk(Vector2(-21, -2))
	await walk(Vector2(-19, -2))
	if not await select_device("source"):
		return
	driver.expect(world.discovery_panel.buttons.power_toggle.visible, "source action is inside unified panel")
	await native_click(world.discovery_panel.buttons.power_toggle)
	await active(0.5, "source disabled through live panel")
	driver.expect(not world.model.by_id(ids.source).enabled and world.model.power_state().supplied_kw == 0, "source command immediately affects live grid")
	await native_shot("07-source-off")
	await native_click(world.discovery_panel.buttons.power_toggle)
	driver.expect(world.model.by_id(ids.source).enabled, "same panel resumes source")
	await native_click(world.discovery_panel.buttons.close)
	await walk(Vector2(-15, -2.5))
	await walk(Vector2(-14, -4))
	if not await select_device("node"):
		return
	driver.expect(world.discovery_panel.visible and not world.discovery_panel.buttons.power_connect.visible, "automatic node uses unified network details without manual wiring")
	await native_shot("08-node")
	await native_click(world.discovery_panel.buttons.close)
	await walk(Vector2(-14, -2.5))
	await walk(Vector2(-14, 2))
	ids.belt = world.model.entity_at(Vector2i(-14, 0)).id
	if not await select_device("belt"):
		return
	driver.expect(world.discovery_panel.buttons.rotate_selected.visible, "belt provides its action in unified panel")
	await native_shot("09-belt")
	await native_click(world.discovery_panel.buttons.close)


func select_device(name: String) -> bool:
	await wait_for_focus()
	var e: Dictionary = world.model.by_id(ids[name])
	var shape: Dictionary = world.model.CATALOG[e.type]
	# The thin belt bed sits below the machinery click height; a ray at 1.1 misses it.
	var height := 0.2 if e.type == "belt" else 1.1
	var projected: Vector2 = world.view.project(Vector3(e.x + shape.w * 0.5, height, e.z + shape.d * 0.5))
	var point: Vector2 = world.hud.viewport_to_screen(projected)
	driver.expect(world.hud.world_point(point) != null, "selected model is not under HUD")
	driver.expect(world.view.hit(projected) == ids[name], "click ray intersects intended model: " + name)
	if not driver.failures.is_empty():
		await driver.shot("failed-model-ray-" + name)
		check_failures()
		return false
	await driver.motion(point)
	await driver.mouse(point, true)
	await driver.mouse(point, false)
	await driver.settle()
	driver.expect(world.ui.selected == ids[name], "real model click selects " + name)
	if not driver.failures.is_empty():
		await driver.shot("failed-model-click-" + name)
	check_failures()
	return not finished


func open_device() -> void:
	if not world.discovery_panel.visible:
		await driver.key(KEY_F)
	driver.expect(world.discovery_panel.visible and world.discovery_panel.device_only, "nearby device operation opens")
	check_failures()


func native_click(button: Button) -> void:
	if button.has_meta("item_id") and not button.is_visible_in_tree():
		var slot: Button = world.discovery_panel.item_button(button.get_meta("item_id"), button.get_meta("bag_side"))
		driver.expect(slot != null, "material has a visible selectable slot")
		if slot == null:
			check_failures()
			return
		await native_click(slot)
	var label := button.text
	var window: Window = button.get_window()
	await wait_for_focus(window)
	if world.discovery_panel.scroll.is_ancestor_of(button):
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
	# Save-and-return frees the whole world and its button after activation.
	if is_instance_valid(button):
		button.pressed.disconnect(observed)
	driver.expect(presses[0] == 1, "one native mouse activation: " + label)
	if presses[0] != 1:
		await native_shot("failed-native-click")
	check_failures()


func _layout_checks() -> void:
	for dimensions in [Vector2i(1100, 720), Vector2i(1440, 900)]:
		root.size = dimensions
		await driver.settle(25)
		var bounds: Rect2 = root.get_visible_rect()
		driver.expect(bounds.encloses(world.discovery_panel.frame.get_global_rect()), "unified panel fits supported window " + str(dimensions))
		driver.expect(world.discovery_panel.frame.get_global_rect().encloses(world.discovery_panel.result_label.get_global_rect()), "result stays visible outside scrolling")
		driver.expect(world.discovery_panel.frame.get_global_rect().encloses(world.discovery_panel.buttons.close.get_global_rect()), "close remains reachable")
		await native_shot("layout-%dx%d" % [dimensions.x, dimensions.y])


func _restore() -> void:
	ids = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("ids.json")))
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("expected.json")))
	# The final save-and-return increments the file sequence without changing the paused state.
	var actual := Codec.snapshot(world.model, world.store.world_id, world.store.world_name, expected.sequence)
	driver.expect(world.store.sequence >= expected.sequence, "restored file sequence retains monotonic save order")
	driver.expect(Check.equivalent(actual, expected), "independent Boot restores full unchanged exploration snapshot")
	if not await select_device("reactor"):
		return
	await driver.shot("13-restored-partial-trial")
	await open_device()
	driver.expect(world.discovery_panel.device_summary.progress.value > 0 and "矿壳试制" in world.discovery_panel.device_summary.values.process.text, "restored panel shows saved recipe and partial progress")
	await native_shot("14-restored-device-actions")
	await native_click(world.discovery_panel.buttons.close)
	driver.expect("试制" in world.hud.mission.text, "restored goal derives partial trial from saved facts")
	await native_click(world.hud.buttons.guide_action)
	driver.expect(world.discovery_panel.visible and world.discovery_panel.selected == ids.reactor and world.ui.paused, "restored goal opens same nearby device and preserves explicit pause")
	await native_click(world.discovery_panel.buttons.close)
	await driver.click(world.hud.buttons.pause)
	await wait_for(func(): return world.model.discovery.trial_completed, 15, "restored partial trial completes naturally")
	driver.expect(world.model.statistics.totals.consumed.crust_sample == 1, "restored trial consumes unique sample once")
	await driver.settle(20)
	driver.expect("外矿道" in world.hud.mission.text and "/ 4" in world.hud.mission.text, "completed trial advances goal to four opening materials")
	await driver.shot("15-restored-next-goal")
	await walk(Vector2(-14, 2))
	await driver.settle(20)
	var before: Dictionary = world._interaction_target()
	driver.expect(before.get("count", 0) > 1, "walking beside belt and reactor offers multiple reachable targets")
	check_failures()
	if finished:
		return
	await driver.key(KEY_TAB)
	var chosen: Dictionary = world._interaction_target()
	driver.expect(chosen.id != before.id and world.ui.focus_device == chosen.id, "Tab changes target and matching device highlight")
	await native_click(world.hud.buttons.camera_right)
	driver.expect(world._interaction_target().id == chosen.id, "cycled target survives camera rotation")
	await driver.shot("16-nearby-target-cycle")
	await driver.key(KEY_F)
	driver.expect(world.discovery_panel.visible and world.discovery_panel.selected == chosen.id, "F opens the exact cycled nearby target")
	await native_click(world.discovery_panel.buttons.close)
	stage("read-complete", "independent Boot restore and natural completion of saved partial batch")
	await driver.click(world.hud.buttons.return)


func finish() -> void:
	if finished:
		return
	finished = true
	var input_description := "Default foundation and explicit discovery selection; Boot/create menus: focused synthetic Enter; preview/mouse placement/cancel/selection/nearby belt: synthetic mouse and Escape; discovery approach: synthetic WASD; no state injection" if preview_only else "Boot menu: Control-focused synthetic Enter; HUD/model selection/drag/live panel buttons: synthetic mouse; setup devices: precision fields/button signal; automatic wiring; recipe dropdown selected; walking: synthetic WASD; F/Tab/I/Escape: routed synthetic input; no injected stock/unlocks/actor position or accelerated time"
	if not input_description_override.is_empty():
		input_description = input_description_override
	write_json("preview-result.json" if preview_only else "read-result.json" if read_mode else "write-result.json", {"assertions": driver.assertions, "failures": driver.failures, "stages": stages,
		"foreground_seconds": foreground_seconds, "focus_pauses": focus_pauses, "pending_focus_pause": focus_pause,
		"input": input_description}.merged(execution_evidence()))
	print("Device interaction Boot: %d assertions, %d failures" % [driver.assertions, driver.failures.size()])
	quit(0 if driver.failures.is_empty() else 1)
