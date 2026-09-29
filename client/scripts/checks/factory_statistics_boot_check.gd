extends SceneTree

const Boot := preload("res://scenes/boot/Boot.tscn")
const Driver := preload("res://scripts/checks/factory_window_driver.gd")
const Query := preload("res://scripts/factory/statistics_query.gd")
const Codec := preload("res://scripts/factory/save/codec.gd")
const Check := preload("res://scripts/checks/factory_discovery_check.gd")
var boot: Node
var world: Control
var driver: Node
var run_root := ""
var read_mode := false
var finished := false
var started := 0
var stages: Array = []
var held_keys: Array = []
var ids := {}


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var batch := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--batch="):
			batch = arg.trim_prefix("--batch=")
		read_mode = read_mode or arg == "--read"
	assert(batch.is_valid_filename() and not ".." in batch)
	var repo := SliceCheckPaths.repository_root()
	run_root = repo.path_join("tools/runtime-intake/check-runs/factory-statistics-v1").path_join(batch)
	DirAccess.make_dir_recursive_absolute(run_root)
	driver = Driver.new()
	driver.shot_root = repo.path_join("assets/art-intake/2026-09-29-factory-statistics-preview").path_join(batch)
	DirAccess.make_dir_recursive_absolute(driver.shot_root)
	root.add_child(driver)
	boot = Boot.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(run_root.path_join("slice"))
	boot.factory_save_root = run_root.path_join("factory")
	root.add_child(boot)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1440, 900)
	create_timer(1200).timeout.connect(func(): driver.expect(false, "natural path timeout"); finish())
	await driver.settle(20)
	await driver.click(boot.startup_menu.get_node("ContentRoot/MenuButtons/FactoryButton"))
	if read_mode:
		boot.factory_menu.list.select(0)
		boot.factory_menu.list.item_selected.emit(0)
		boot.factory_menu.continue_button.pressed.emit()
		boot.factory_world._set_paused(true)
	else:
		boot.factory_menu.world_type.select(1)
		boot.factory_menu.title_input.text = "D3 自然生产路径"
		await driver.click(boot.factory_menu.create_button)
	world = boot.factory_world
	driver.world = world
	driver.expect(world != null and world.initialized, "formal Boot world initialized")
	if world == null:
		finish()
		return
	await driver.settle(20)
	started = Time.get_ticks_usec()
	if read_mode:
		await restore_check()
		finish()
		return
	driver.expect(world.model.entities.is_empty() and world.model.bag.is_empty(), "ordinary empty world with zero materials")
	print("Initial statistics button: ", world.hud.buttons.statistics.get_global_rect(), " root: ", root.size, " content: ", root.content_scale_size)
	await driver.click(world.hud.buttons.statistics)
	driver.expect(world.statistics_panel.visible, "initial statistics button opens overlay")
	check_failures()
	await driver.shot("01-empty-statistics")
	await driver.click(world.statistics_panel.buttons.close)
	# Construction uses the same HUD precision fields and placement actions as a player.
	await place("collector", -20, -1, "collector")
	await place("reactor", -13, -2, "basic")
	await place("storage", -6, -1, "warehouse")
	await belts(-18, -14, 0, 0)
	await belts(-10, -7, 0, 0)
	await place("power_source", -20, -6, "source")
	await place("power_junction", -13, -5, "node")
	connect_devices("source", "node")
	connect_devices("source", "collector")
	connect_devices("node", "basic")
	stage("first-line", "empty-world construction and explicit connections")
	await walk(Vector2(2.3, 3.5))
	await panel(-1)
	await press(world.discovery_panel.buttons.sample)
	await press(world.discovery_panel.get_ok_button())
	driver.expect(world.model.discovery.sample_taken, "sample obtained by actual proximity")
	await driver.shot("02-sample-guidance")
	await wait_for(func(): return world.model.by_id(ids.warehouse).items.get("catalyst", 0) >= 2, 70, "ordinary catalyst preparation")
	await walk(Vector2(-5.0, 3.0))
	await panel(ids.warehouse)
	await press(world.discovery_panel.buttons.catalyst_take_all)
	await press(world.discovery_panel.get_ok_button())
	# Remove the terminal through the existing action; goods stay in the bag.
	world.ui.selected = ids.warehouse
	world._action("salvage", null)
	driver.expect(world.model.by_id(ids.warehouse).is_empty(), "terminal recovered via player action")
	await place("reactor", -6, -2, "solvent")
	await place("storage", 0, -1, "warehouse")
	await belts(-3, -1, 0, 0)
	await place("power_junction", -6, -5, "solvent_node")
	connect_devices("node", "solvent_node")
	connect_devices("solvent_node", "solvent")
	await walk(Vector2(-5.0, 2.0))
	await panel(ids.solvent)
	await recipe("solvent_trial")
	await press(world.discovery_panel.buttons.crust_sample_put_one)
	if world.model.by_id(ids.solvent).input.get("catalyst", 0) < 2 and world.model.bag.get("catalyst", 0) > 0:
		await press(world.discovery_panel.buttons.catalyst_put_all)
	await native_shot("03-trial")
	await press(world.discovery_panel.get_ok_button())
	await wait_for(func(): return world.model.discovery.trial_completed, 45, "real-time trial")
	stage("trial", "one unique sample consumed; continuous recipes unlocked")
	await wait_for(func(): return world.model.by_id(ids.solvent).output.is_empty(), 10, "trial product leaves on belt")
	await panel(ids.solvent)
	if not world.model.by_id(ids.solvent).input.is_empty():
		await press(world.discovery_panel.buttons.catalyst_take_all)
	await recipe("crust_solvent")
	if world.model.bag.get("catalyst", 0) > 0:
		await press(world.discovery_panel.buttons.catalyst_put_all)
	await press(world.discovery_panel.get_ok_button())
	await statistics_checks()
	await wait_for(func(): return world.model.by_id(ids.warehouse).items.get("crust_solvent", 0) >= 4, 150, "automatic solvent production for first opening")
	await walk(Vector2(1.0, 2.0))
	await panel(ids.warehouse)
	await press(world.discovery_panel.buttons.crust_solvent_take_all)
	await press(world.discovery_panel.get_ok_button())
	await walk(Vector2(2.7, 0.3))
	await panel(-1)
	await press(world.discovery_panel.buttons.outer)
	await press(world.discovery_panel.get_ok_button())
	await walk(Vector2(8.6, 0.3))
	stage("outer", "four real solvent units spent; actual collision traversal")
	await driver.shot("07-outer-open")
	# Connect the rich line to the first source before measuring capacity shortage.
	await place("power_junction", 2, -1, "passage_node")
	await place("power_junction", 9, -1, "inner_node")
	connect_devices("solvent_node", "passage_node")
	connect_devices("passage_node", "inner_node")
	await place("collector", 10, -1, "rich_collector")
	await place("reactor", 14, -2, "rich")
	await place("power_junction", 14, -5, "rich_node")
	connect_devices("inner_node", "rich_node")
	connect_devices("inner_node", "rich_collector")
	connect_devices("rich_node", "rich")
	await belts(12, 13, 0, 0)
	await walk(Vector2(8.6, 3.0))
	await walk(Vector2(15.0, 3.0))
	await walk(Vector2(15.0, 2.0))
	await panel(ids.rich)
	await recipe("rich_catalyst")
	await press(world.discovery_panel.get_ok_button())
	await place("reactor", 10, 10, "inner_solvent")
	await place("storage", 14, 11, "inner_warehouse")
	await place("power_junction", 14, 4, "mid_node")
	await place("power_junction", 12, 9, "lower_node")
	connect_devices("rich_node", "mid_node")
	connect_devices("mid_node", "lower_node")
	connect_devices("lower_node", "inner_solvent")
	await place("belt", 17, 0)
	await place("belt", 18, 0, "", 1)
	for z in range(1, 8):
		await place("belt", 18, z, "", 1)
	await place("belt", 18, 8, "", 2)
	await belts(9, 17, 8, 2)
	await place("belt", 8, 8, "", 1)
	for z in range(9, 12):
		await place("belt", 8, z, "", 1)
	await place("belt", 8, 12)
	await place("belt", 9, 12)
	await place("belt", 13, 12)
	await walk(Vector2(16.0, 6.0))
	await walk(Vector2(14.0, 9.0))
	await panel(ids.inner_solvent)
	await recipe("crust_solvent")
	await press(world.discovery_panel.get_ok_button())
	await wait_for(func(): return world.model.statistics.totals.produced.get("rich_crystal", 0) > 0, 30, "new resource really produced")
	await driver.click(world.hud.buttons.statistics)
	world.statistics_panel.page.select(1)
	world.statistics_panel.refresh()
	await active(60, "single-source bottleneck observation")
	var before := Query.electricity(world.model, 60)
	driver.expect(before.window.deficit_kj > 0, "statistics reveals real power shortage")
	await driver.shot("08-power-shortage")
	write_json("bottleneck-before.json", before)
	await driver.click(world.statistics_panel.buttons.close)
	await place("power_source", 10, -6, "second_source")
	connect_devices("second_source", "rich_node")
	await driver.click(world.hud.buttons.statistics)
	await active(60, "expanded supply observation")
	var after := Query.electricity(world.model, 60)
	write_json("bottleneck-after.json", after)
	driver.expect(after.window.deficit_kj < before.window.deficit_kj, "expanded supply reduces actual shortage")
	await driver.shot("09-power-improved")
	world.statistics_panel.page.select(0)
	world.statistics_panel.selected_item = "catalyst"
	world.statistics_panel.refresh()
	await driver.shot("10-rich-materials")
	await driver.click(world.statistics_panel.buttons.close)
	stage("rich-return", "real rich production feeds second automatic solvent line; supply expanded")
	await wait_for(func(): return world.model.by_id(ids.inner_warehouse).items.get("crust_solvent", 0) >= 8, 180, "rich-fed eight solvent preparation")
	await walk(Vector2(15.0, 9.8))
	await panel(ids.inner_warehouse)
	await press(world.discovery_panel.buttons.crust_solvent_take_all)
	await press(world.discovery_panel.get_ok_button())
	await walk(Vector2(16.0, 9.0))
	await walk(Vector2(16.0, 2.2))
	await walk(Vector2(19.0, 2.2))
	await walk(Vector2(19.0, 0.4))
	await panel(-1)
	await press(world.discovery_panel.buttons.inner)
	await press(world.discovery_panel.get_ok_button())
	await walk(Vector2(24.6, 0.4))
	driver.expect(world.model.discovery.passages.inner, "second permanent opening")
	stage("inner", "eight rich-fed solvent spent; actual second crossing")
	await driver.shot("11-second-opening")
	await driver.click(world.hud.buttons.pause)
	await driver.click(world.hud.buttons.save)
	write_json("expected.json", Codec.snapshot(world.model, world.store.world_id, world.store.world_name, world.store.sequence))
	await driver.click(world.hud.buttons.return)
	driver.expect(boot.factory_world == null, "saved return releases world")
	finish()


func place(type: String, x: int, z: int, name := "", dir := 0) -> void:
	world._action(type, null)
	world.hud.cell_x.value = x
	world.hud.cell_z.value = z
	world.ui.dir = dir
	world._refresh()
	var next: int = world.model.next_id
	# Button signal avoids changing the precision fields by moving the pointer over the world.
	world.hud.buttons.place.pressed.emit()
	driver.expect(world.model.next_id == next + 1, "player precision placement %s at %d,%d: %s" % [type, x, z, world.hud.notice.text])
	if not name.is_empty():
		ids[name] = next
	world._action("cancel", null)
	await process_frame
	check_failures()


func belts(low: int, high: int, z: int, dir: int) -> void:
	for x in range(low, high + 1):
		await place("belt", x, z, "", dir)


func connect_devices(a: String, b: String) -> void:
	# Same authoritative command used by the wiring click; no graph/state injection.
	var result: Dictionary = world.model.connect_power(ids[a], ids[b])
	driver.expect(result.ok, "explicit wiring " + a + " → " + b + ": " + result.get("reason", ""))
	check_failures()


func walk(to: Vector2) -> void:
	world.view.inspection_target = null
	var owner := root.gui_get_focus_owner()
	if owner:
		owner.release_focus()
	var until := Time.get_ticks_usec() + 20000000
	while Vector2(world.actor.x, world.actor.z).distance_to(to) > 0.22:
		check_focus()
		var delta := to - Vector2(world.actor.x, world.actor.z)
		var angle := deg_to_rad(world.view.yaw)
		var input := Vector2(delta.x * cos(angle) - delta.y * sin(angle), delta.x * sin(angle) + delta.y * cos(angle))
		var desired := []
		if absf(input.x) > absf(input.y) * 0.4:
			desired.append(KEY_D if input.x > 0 else KEY_A)
		if absf(input.y) > absf(input.x) * 0.4:
			desired.append(KEY_S if input.y > 0 else KEY_W)
		for code in held_keys:
			if code not in desired:
				push_key(code, false)
		for code in desired:
			if code not in held_keys:
				push_key(code, true)
		held_keys = desired
		await process_frame
		if Time.get_ticks_usec() > until:
			driver.expect(false, "walking blocked at %s toward %s" % [Vector2(world.actor.x, world.actor.z), to])
			finish()
			return
	for code in held_keys:
		push_key(code, false)
	held_keys.clear()
	await driver.settle()


func push_key(code: int, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = pressed
	root.push_input(event, true)


func panel(id: int) -> void:
	world.ui.selected = id # Stable ID selection; location/proximity remains natural walking.
	world._refresh()
	await driver.settle()
	await driver.click(world.hud.buttons.discovery)
	driver.expect(world.discovery_panel.visible, "native process panel opens")


func press(control: Button) -> void:
	driver.expect(control.is_visible_in_tree() and not control.disabled and control.get_window().has_focus(), "native command available " + control.text)
	check_failures()
	control.grab_focus()
	for held in [true, false]:
		var event := InputEventKey.new()
		event.physical_keycode = KEY_ENTER
		event.keycode = KEY_ENTER
		event.pressed = held
		control.get_window().push_input(event, true)
		await process_frame
	await driver.settle()


func recipe(id: String) -> void:
	var index: int = world.discovery_panel.recipe_ids.find(id)
	driver.expect(index >= 0, "recipe known " + id)
	check_failures()
	world.discovery_panel.recipe.select(index)
	await press(world.discovery_panel.buttons.recipe)
	driver.expect(world.model.by_id(world.ui.selected).recipe_id == id, "recipe change succeeded " + id)
	check_failures()


func wait_for(condition: Callable, timeout: float, reason: String) -> void:
	var start := Time.get_ticks_usec()
	while not condition.call():
		check_focus()
		await process_frame
		if (Time.get_ticks_usec() - start) / 1000000.0 > timeout:
			driver.expect(false, "waiting timed out: " + reason)
			finish()
			return
	stage("wait", reason)


func active(seconds: float, reason: String) -> void:
	var until: float = world.model.time + seconds
	await wait_for(func(): return world.model.time >= until, seconds + 20, reason)


func check_focus() -> void:
	if not root.has_focus():
		driver.expect(false, "focus_lost: stop without refocusing")
		finish()


func check_failures() -> void:
	if not driver.failures.is_empty():
		finish()


func stage(name: String, reason: String) -> void:
	stages.append({"stage": name, "reason": reason, "elapsed_seconds": (Time.get_ticks_usec() - started) / 1000000.0, "simulation_seconds": world.model.time, "active_seconds": world.production_clock.active_usec / 1000000.0})
	write_json("stages.json", stages)
	print("D3 stage: ", stages.back())


func native_shot(name: String) -> void:
	await driver.settle()
	world.discovery_panel.get_texture().get_image().save_png(driver.shot_root.path_join(name + ".png"))


func statistics_checks() -> void:
	await driver.click(world.hud.buttons.statistics)
	var panel: Control = world.statistics_panel
	panel.selected_item = "catalyst"
	panel.refresh()
	var before: float = world.model.time
	await active(2, "statistics stays live")
	driver.expect(world.model.time > before, "statistics does not pause simulation")
	await driver.click(panel.buttons.catalyst_favorite)
	panel.window_choice.select(1)
	panel.window_choice.item_selected.emit(1)
	panel.filter.select(2)
	panel.filter.item_selected.emit(2)
	driver.expect(panel.rows.catalyst.box.visible and not panel.rows.crystal.box.visible, "favorite filtering")
	panel.filter.select(0)
	panel.filter.item_selected.emit(0)
	panel.sort_choice.select(1)
	panel.sort_choice.item_selected.emit(1)
	var actor_before := Vector2(world.actor.x, world.actor.z)
	await driver.key(KEY_W, true)
	await create_timer(0.15).timeout
	await driver.key(KEY_W, false)
	driver.expect(actor_before == Vector2(world.actor.x, world.actor.z), "statistics blocks movement input")
	world._focus_lost() # Inject focus transition without switching the user's foreground app.
	before = world.model.time
	await create_timer(0.2).timeout
	driver.expect(world.model.time == before, "statistics obeys focus pause without zero buckets")
	world._focus_gained()
	await driver.shot("04-material-statistics")
	await driver.click(panel.buttons.pause)
	before = world.model.time
	await create_timer(0.3).timeout
	driver.expect(world.model.time == before, "explicit pause freezes samples")
	await driver.click(panel.buttons.pause)
	root.mode = Window.MODE_MAXIMIZED
	await driver.settle(25)
	await driver.shot("05-maximized-statistics")
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1100, 720)
	await driver.settle(25)
	driver.expect(Rect2(Vector2.ZERO, root.get_visible_rect().size).encloses(panel.buttons.close.get_global_rect()), "small-window close remains visible")
	await driver.shot("06-small-statistics")
	root.size = Vector2i(1440, 900)
	await driver.settle(15)
	# Target known production equipment; location must never teleport the engineer.
	var position := Vector2(world.actor.x, world.actor.z)
	# Scroll a real device button into view, then click it.
	var device: Button = panel.buttons["device_%d" % ids.basic]
	var scroll := panel.body.get_parent() as ScrollContainer
	scroll.ensure_control_visible(device)
	await driver.settle()
	await driver.click(device)
	await driver.settle()
	driver.expect(not panel.visible and world.ui.selected == ids.basic and position == Vector2(world.actor.x, world.actor.z), "device localization opens inspector without moving player")


func restore_check() -> void:
	world._set_paused(true)
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(run_root.path_join("expected.json")))
	var actual := Codec.snapshot(world.model, world.store.world_id, world.store.world_name, expected.sequence)
	driver.expect(Check.equivalent(actual, expected), "independent Boot restores complete saved state")
	driver.expect(world.model.discovery.passages.inner and world.model.discovery.passages.outer, "independent Boot restores permanent openings")
	driver.expect(world.model.statistics_ui == expected.state.statistics_ui, "independent Boot restores statistics preferences")
	driver.expect(world.model.statistics.totals.consumed.crust_solvent == 12, "independent Boot retains exactly twelve opening consumption")
	await driver.click(world.hud.buttons.statistics)
	await driver.shot("12-restored-statistics")
	await driver.click(world.statistics_panel.buttons.close)
	await driver.click(world.hud.buttons.return)


func write_json(name: String, value: Variant) -> void:
	var file := FileAccess.open(run_root.path_join(name), FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "\t", false, true))


func finish() -> void:
	if finished:
		return
	finished = true
	write_json("read-result.json" if read_mode else "write-result.json", {"assertions": driver.assertions, "failures": driver.failures, "stages": stages,
		"input": "Boot synthetic mouse; build HUD precision fields/button signal; legal wiring commands; stable-ID selection; native buttons synthetic Enter; walking synthetic WASD; no inventory/unlock/actor-position injection or accelerated time"})
	print("D3 Boot: %d assertions, %d failures" % [driver.assertions, driver.failures.size()])
	quit(0 if driver.failures.is_empty() else 1)
