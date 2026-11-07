extends SceneTree

const Boot := preload("res://scenes/boot/Boot.tscn")
const Model := preload("res://scripts/factory/integrated_model.gd")
const Route := preload("res://scripts/checks/factory_base_core_route.gd")
const Journey := preload("res://scripts/checks/factory_progression_journey.gd")
const Driver := preload("res://scripts/checks/factory_window_driver.gd")
var driver := Driver.new()
var boot: Node
var world: Control
var run_root := ""
var framing := false
var progression := false


func _init() -> void:
	call_deferred("run")


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--batch="):
			var batch := arg.trim_prefix("--batch=")
			if batch.is_valid_filename() and ".." not in batch:
				run_root = SliceCheckPaths.check_run("factory-base-core-v1", false).path_join(batch)
	if run_root.is_empty() or not DirAccess.dir_exists_absolute(run_root) or DisplayServer.get_name() == "headless":
		push_error("B1 Boot requires the isolated window runner and its batch directory.")
		quit(2)
		return
	var play := "--play" in OS.get_cmdline_user_args()
	framing = "--framing" in OS.get_cmdline_user_args()
	progression = "--progression" in OS.get_cmdline_user_args()
	var empty_yard := "--empty-yard" in OS.get_cmdline_user_args()
	root.mode = Window.MODE_WINDOWED
	var usable := DisplayServer.screen_get_usable_rect()
	root.size = Vector2i(1440, 900).min(usable.size - Vector2i(32, 48))
	root.move_to_center()
	driver.shot_root = run_root
	root.add_child(driver)
	boot = Boot.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(run_root.path_join("slice"))
	boot.factory_save_root = run_root.path_join("factory")
	boot.factory_core_review = true
	root.add_child(boot)
	await driver.settle(15)
	var model: RefCounted
	if progression:
		var journey := Journey.new()
		journey.prepare_tier_one()
		model = journey.model
		model.actor.x = model.core.x + 3.0
		model.actor.z = model.core.z - 0.6
		driver.expect(model.material_balance().balanced and model.core.items.get("construction_pack", 0) == 3, "checkpoint produced by the factory")
	else:
		model = Model.new()
	if not empty_yard and not progression:
		var route := Route.build(model)
		driver.expect(route.ok and route.get("lengths", []) == [51, 28, 20], "prepared topology uses ordinary build commands")
		if not route.ok:
			_finish()
			return
	driver.expect(boot.open_factory_core_review(model), "Boot entered shared FactoryWorld as isolated memory review")
	world = boot.factory_world
	if world == null:
		_finish()
		return
	driver.world = world
	await driver.settle()
	if play:
		print("Factory B1 review ready: " + run_root)
		return
	if framing:
		await _framing_path(model)
	elif progression:
		await _progression_path(model)
	else:
		await _review_path(model)
	_finish()


func _review_path(model: RefCounted) -> void:
	var core: Dictionary = model.core
	driver.expect(root.has_focus(), "window is focused before sending test input")
	if not root.has_focus():
		return
	driver.expect(core.items.is_empty() and world.store == null and not world.hud.buttons.save.visible, "empty stock and no save UI or Store")
	driver.expect(world.view.camera.projection == Camera3D.PROJECTION_PERSPECTIVE and world.view.yaw == 0.0 and world.view.core_span == 21.0, "C2 camera on the runtime path")
	for cell in [Vector2i(-10, 21), Vector2i(-8, 21), Vector2i(-10, 28)]:
		var belt: Dictionary = model.entity_at(cell)
		driver.expect(world.view.models[belt.id].mask == 4, "straight belt at core port %s" % str(cell))
	await driver.shot("01-spawn")
	var start_z: float = model.actor.z
	await driver.key(KEY_S, true)
	await create_timer(0.23).timeout
	await driver.key(KEY_S, false)
	driver.expect(model.actor.z > start_z and model.near_entity(core), "walk into the core's normal interaction radius")
	await driver.world_click(Vector2i(-8, 24), 2.5)
	driver.expect(world.core_panel.visible and world.core_panel.tabs.current_tab == 0, "click imported core opens inventory")
	if not world.core_panel.visible:
		return
	await driver.shot("02-inventory-empty")
	# TabBar is an ordinary Control, so dispatch a click at its real screen coordinates.
	var tab_bar: TabBar = world.core_panel.tabs.get_tab_bar()
	var at := tab_bar.global_position + tab_bar.get_tab_rect(1).get_center()
	await driver.motion(at)
	await driver.mouse(at, true)
	await driver.mouse(at, false)
	await driver.settle()
	driver.expect(world.core_panel.tabs.current_tab == 1, "open interfaces tab through the real TabBar")
	if world.core_panel.tabs.current_tab != 1:
		return
	var row: Dictionary = world.core_panel.outputs.OUT_S0
	for i in row.item.item_count:
		if row.item.get_item_metadata(i) == "iron_ore":
			row.item.select(i)
			break
	await driver.click(row.enabled)
	driver.expect(not core.outputs.OUT_S0.enabled and core.outputs.OUT_S0.item.is_empty(), "editing draft leaves authoritative configuration untouched")
	await driver.click(row.apply)
	driver.expect(core.outputs.OUT_S0.enabled and core.outputs.OUT_S0.item == "iron_ore", "apply south output config through UI")
	driver.expect(world.view.models[core.id].output_icons.OUT_S0.visible, "applied item marker appears on the model")
	await driver.shot("03-interfaces")
	var ticks: int = model.statistics.ticks
	await create_timer(0.25).timeout
	driver.expect(model.statistics.ticks > ticks, "production continues while interfaces are open")
	await driver.click(world.core_panel.pause_button)
	var paused_ticks: int = model.statistics.ticks
	var paused_cooldown: int = core.outputs.OUT_S0.cooldown_ticks
	await create_timer(0.25).timeout
	driver.expect(model.statistics.ticks == paused_ticks and core.outputs.OUT_S0.cooldown_ticks == paused_cooldown, "explicit pause freezes step and cooldown")
	await driver.click(world.core_panel.pause_button)
	await driver.click(world.core_panel.close_button)
	var deadline := Time.get_ticks_msec() + 150000
	while core.items.get("metal_plate", 0) == 0 and Time.get_ticks_msec() < deadline:
		await process_frame
	driver.expect(core.items.get("metal_plate", 0) > 0 and model.material_balance().balanced and model.bag.is_empty(), "natural plate reaches the core while the visible world runs")
	if core.items.get("metal_plate", 0) == 0:
		return
	await create_timer(0.15).timeout # HUD refreshes at a lower rate than the simulation.
	await driver.shot("04-first-plate")
	await _inventory_receipt_path(model)


func _inventory_receipt_path(model: RefCounted) -> void:
	var core: Dictionary = model.core
	driver.expect(root.has_focus(), "window is focused before final inventory input")
	if not root.has_focus():
		return
	await driver.motion(driver.cell_screen(Vector2i(-8, 24), 2.5))
	await driver.key(KEY_F)
	driver.expect(world.core_panel.visible and world.ui.selected == core.id, "F opens core after return without moving materials by hand")
	if not world.core_panel.visible:
		return
	world.core_panel.tabs.current_tab = 0
	var inventory: OptionButton = world.core_panel.inventory
	for i in inventory.item_count:
		if inventory.get_item_metadata(i) == "metal_plate":
			inventory.select(i)
			break
	world.core_panel.refresh()
	await driver.shot("05-inventory-with-plate")
	await driver.click(world.core_panel.transfer_buttons["取出 1"])
	driver.expect(model.bag.get("metal_plate", 0) == 1, "withdraw plate by inventory button")
	await driver.click(world.core_panel.transfer_buttons["存入 1"])
	driver.expect(model.bag.is_empty() and model.material_balance().balanced, "deposit plate back; total material conserved")
	await driver.click(world.core_panel.close_button)
	await driver.click(world.hud.buttons["return"])
	driver.expect(boot.factory_world == null and boot.factory_menu.visible, "memory session exits through normal Boot return")
	driver.expect(not FileAccess.file_exists(run_root.path_join("factory/autosave.json")) and boot.factory_menu.worlds.is_empty(), "no factory world was written")


func _progression_path(model: RefCounted) -> void:
	driver.expect(root.has_focus(), "window focused before progression input")
	if not root.has_focus():
		await _close_review()
		return
	await driver.world_click(Vector2i(-8, 24), 2.5)
	var panel: PanelContainer = world.core_panel
	driver.expect(panel.visible and panel.tabs.get_tab_count() == 5, "core opens with all progression pages")
	if not panel.visible:
		await _close_review()
		return
	await _select_tab(panel, 2)
	# Choose the visible node by its option metadata, then submit through the button.
	for i in panel.research_choice.item_count:
		if panel.research_choice.get_item_metadata(i) == Journey.P.SAMPLE:
			panel.research_choice.select(i)
			panel.research_choice.item_selected.emit(i)
			break
	await driver.shot("01-sample-research")
	await driver.click(panel.research_button)
	driver.expect(model.researched.has(Journey.P.SAMPLE) and model.bag.get("crust_sample", 0) == 1, "research UI preserves the unique sample")
	await _select_tab(panel, 3)
	await driver.shot("02-upgrade-ready")
	await driver.click(panel.upgrade_button)
	driver.expect(model.core.level == 2 and model.core.items.get("construction_pack", 0) == 1, "upgrade UI debits exactly two packs")
	var visual: Node3D = world.view.models[model.core.id].root
	var tiers := visual.find_child("TierModules", true, false)
	driver.expect(tiers != null and tiers.get_node("II").visible and not tiers.get_node("I").visible, "tier II mesh visibly replaces tier I")
	await driver.shot("03-core-ii")
	await _select_tab(panel, 4)
	await driver.click(panel.assembly_button)
	driver.expect(model.kits.belt == 264 and not model.core.items.has("construction_pack") and model.material_balance().balanced, "assembly UI makes eight belts and preserves ledger")
	await driver.shot("04-assembly")
	await driver.click(panel.close_button)
	await driver.shot("05-core-ii-world")
	await _close_review()


func _select_tab(panel: PanelContainer, index: int) -> void:
	var bar: TabBar = panel.tabs.get_tab_bar()
	var at := bar.global_position + bar.get_tab_rect(index).get_center()
	await driver.motion(at)
	await driver.mouse(at, true)
	await driver.mouse(at, false)
	await driver.settle()
	driver.expect(panel.tabs.current_tab == index, "clicked " + panel.tabs.get_tab_title(index))


func _close_review() -> void:
	if world.core_panel.visible:
		world.core_panel.close()
	world._request_exit("return")
	await driver.settle()
	driver.expect(boot.factory_world == null and boot.factory_menu.visible, "isolated Boot returns normally")


func _framing_path(model: RefCounted) -> void:
	root.size = world.get_window().min_size
	root.move_to_center()
	await driver.settle(25)
	var native_size := DisplayServer.window_get_size(root.get_window_id())
	var rendered := root.get_texture().get_image().get_size()
	driver.expect(root.has_focus() and native_size == root.min_size and rendered.x == native_size.x,
		"focused minimum window: native %s, rendered content %s" % [native_size, rendered])
	if not root.has_focus():
		return
	var id: int = model.core.id
	for step in 5:
		model.move_actor(model.actor, 0, 1, 0.06)
	for face in ["N", "E", "S", "W"]:
		driver.expect(model.configure_output(id, "OUT_%s0" % face, "iron_ore", true).ok, "configured marker on " + face)
	await driver.settle()
	for port in world.view.models[id].output_icons.values():
		driver.expect(port.visible and port.texture != null, "applied output icon ready")
	for click in 6:
		await driver.click(world.hud.buttons.zoom_in)
	driver.expect(world.view.core_span == 16.0, "near zoom clamps at 16")
	_expect_marker_clearance(id)
	await driver.shot("06-minimum-near")
	for click in 13:
		await driver.click(world.hud.buttons.zoom_out)
	driver.expect(world.view.core_span == 28.0, "far zoom clamps at 28")
	_expect_marker_clearance(id)
	await driver.shot("07-minimum-far")
	await driver.click(world.hud.buttons["return"])


func _expect_marker_clearance(id: int) -> void:
	for icon in world.view.models[id].output_icons.values():
		var point: Vector2 = world.hud.viewport_to_screen(world.view.project(icon.global_position))
		var prompt: Button = world.hud.interaction_button
		driver.expect(world.hud.world_image.get_global_rect().has_point(point)
			and (not prompt.visible or not prompt.get_global_rect().grow(12).has_point(point)), "output marker clears interaction prompt")



func _finish() -> void:
	var input := "window click, walk and F; option selection injected; only route topology prepared; production runs on the normal clock"
	if framing:
		input = "zoom buttons; four applied marker fixtures at native minimum window"
	elif progression:
		input = "naturally produced checkpoint; actual research, upgrade and assembly button input"
	var result := {"assertions": driver.assertions, "failures": driver.failures, "input": input}
	var report := FileAccess.open(run_root.path_join("window-result.json"), FileAccess.WRITE)
	if report != null:
		report.store_string(JSON.stringify(result, "\t"))
		report.close()
	print("Factory core window: " + JSON.stringify(result))
	quit(0 if driver.failures.is_empty() else 1)
