extends RefCounted

const Codec := preload("res://scripts/factory/save/codec.gd")
const Loads := Codec.V15.Loads
const Edges := preload("res://scripts/checks/factory_load_group_edges.gd")
const Saves := preload("res://scripts/checks/factory_load_group_saves.gd")
var host: SceneTree
var route: RefCounted
var model: RefCounted
var driver: Node
var world: Control


func _init(check: SceneTree, journey: RefCounted) -> void:
	host = check
	route = journey
	model = journey.model
	driver = check.driver
	world = host.boot.factory_world


func exercise() -> void:
	var unpublished := Codec.snapshot(model, world.store.world_id, "pre-C3", 1)
	var parsed: Variant = JSON.parse_string(JSON.stringify(unpublished, "", true, true))
	driver.expect(not model.researched.has(Loads.RESEARCH) and Codec.decode(parsed, world.store.world_id).ok, "unresearched default load groups survive JSON numeric representation")
	var saved: Dictionary = world.store.save(model)
	driver.expect(saved.ok, "real Store round-trip before C3 study: " + saved.get("reason", ""))
	if not saved.ok: return
	var source: Dictionary = model.entity_at(Vector2i(1, 22))
	var g: Dictionary = route.devices.G
	# Continue the already established C2 production route; all goods are real.
	var carrier: Dictionary = route.devices.F2
	for i in 2:
		route.walk_near(carrier)
		route.wait_for(func(): return carrier.output.get("porous_carrier", 0) >= 1, 120, "natural carrier for C3")
		route.stock(carrier, "porous_carrier", 1, false)
	route.wait_for(func(): return route.devices.T.items.get("construction_pack", 0) >= 3, 240, "natural C3 pack")
	route._packs_to_core(3)
	route.walk_near(g)
	route.stock(g, "industrial_cell", 1, false)
	route.walk_near(model.core)
	route.stock(model.core, "industrial_cell", 1, true)
	route.stock(model.core, "porous_carrier", 2, true)
	var panel: Control = world.core_panel
	world._open_device(model.core.id)
	panel.tabs.current_tab = 2
	for i in panel.research_choice.item_count:
		if panel.research_choice.get_item_metadata(i) == Loads.RESEARCH:
			panel.research_choice.select(i)
			panel.research_choice.item_selected.emit(i)
	await driver.settle()
	var before: Dictionary = model.core.items.duplicate()
	await host._click(panel.research_button)
	driver.expect(model.researched.has(Loads.RESEARCH), "natural C3 research through core panel")
	for item in Loads.NODE.cost:
		driver.expect(model.core.items.get(item, 0) == before.get(item, 0) - Loads.NODE.cost[item], "C3 exact study debit " + item)
	driver.expect(not model.research(Loads.RESEARCH).ok and model.material_balance().balanced, "C3 no double payment or free materials")
	await host._click(panel.close_button)
	route._must(model.assemble("grid_buffer"))
	var site := _storage_site()
	var second: Dictionary = route._must(model.place("grid_buffer", site, 0, model.actor)).entity
	var peak: Array[Dictionary] = []
	for e in model.entities:
		if e.type == "refinery" and e.recipe_id == "direct_refining" and not e.enabled:
			peak.append(e)
	driver.expect(peak.size() == 7, "reuse the seven naturally assembled C2 peak furnaces")
	if peak.size() != 7: return
	var iron: Dictionary = route.devices.I
	route.walk_near(iron)
	route.wait_for(func(): return iron.buffer.get("iron_ore", 0) >= 28, 120, "natural ore for two C3 waves")
	route.stock(iron, "iron_ore", 28, false)
	for e in model.entities:
		if (model.DiscoveryRules.POWER.has(e.type) or e.type == "cell_generator") and e.enabled:
			route.walk_near(e)
			route._must(model.set_device_enabled(e.id, false))
	for e in peak:
		route.walk_near(e)
		route._must(model.set_device_enabled(e.id, true))
	for i in 5:
		route.walk_near(peak[i])
		route.stock(peak[i], "iron_ore", 2, true)
	model.advance(model.STEP, 1)
	for i in [5, 6]:
		route.walk_near(peak[i])
		route.stock(peak[i], "iron_ore", 2, true)
	route.walk_near(source)
	world._open_device(source.id)
	await driver.settle()
	var controls: Control = world.discovery_panel.load_controls
	driver.expect(controls.visible and not source.load_group.enabled, "C3 controls shown on storage; start disabled")
	for i in [4, 5, 6]:
		controls.choices[peak[i].id].set_pressed(true)
	controls.reserve.value = 3600
	await _control_click(controls.apply_button)
	driver.expect(source.load_group.member_ids.size() == 3 and not source.load_group.enabled, "applying members does not auto-enable")
	await _control_click(controls.enable_button)
	await driver.shot("14-load-configured")
	var totals: Dictionary = model.statistics.totals.duplicate(true)
	var completed: int = model.completed_by_recipe.direct_refining
	model.advance(model.STEP, 1)
	world.discovery_panel.refresh()
	driver.expect(source.load_group.latch == "block" and peak[4].processing and not peak[5].processing, "live 420 kW request blocks only new batches")
	await driver.shot("15-load-blocked")
	if host.windowed:
		host.root.size = Vector2i(1100, 720)
		await driver.settle(12)
		world.discovery_panel.scroll.scroll_vertical = 0
		var unchanged: Dictionary = source.load_group.duplicate(true)
		await _control_click(controls.apply_button)
		driver.expect(source.load_group == unchanged, "minimum-window apply preserves identical configuration and cadence")
		await driver.shot("16-load-minimum")
		host.root.size = Vector2i(1440, 900).min(DisplayServer.screen_get_usable_rect().size - Vector2i(32, 48))
		await driver.settle(12)
	world.discovery_panel.close_panel()
	route.walk_near(peak[4])
	world._open_device(peak[4].id)
	await driver.settle()
	driver.expect("在制继续" in world.discovery_panel.load_member_status.text, "member panel explains in-flight work")
	await driver.shot("17-load-inflight")
	world.discovery_panel.close_panel()
	model.advance(9.0, 180)
	driver.expect(peak[4].output.get("metal_plate", 0) == 1 and peak[5].processing and source.load_group.latch == "allow", "completed protected work frees budget for delayed batches")
	route.walk_near(source)
	world._open_device(source.id)
	await driver.settle()
	await driver.shot("18-load-resumed")
	route._must(model.set_device_enabled(source.id, false))
	world.discovery_panel.refresh()
	driver.expect("停用" in controls.status.text, "invalid source reason remains visible")
	await driver.shot("19-load-invalid")
	await _control_click(controls.enable_button)
	driver.expect(not source.load_group.enabled and peak[5].processing, "panel takeover retains in-flight work")
	world.discovery_panel.close_panel()
	route._must(model.set_device_enabled(source.id, true))
	model.advance(9.0, 180)
	for e in peak:
		route.walk_near(e)
		route.stock(e, "metal_plate", 1, false)
	driver.expect(model.completed_by_recipe.direct_refining - completed == 7, "all seven real batches complete with three controlled members")
	var report := {"execution_mode": "window" if host.windowed else "headless", "fixed_step_fixture": true,
		"plates": 7, "deficit_kj": model.statistics.totals.deficit_kj - totals.deficit_kj,
		"cells_activated": model.statistics.totals.cells_activated - totals.cells_activated,
		"stored_j": source.stored_j, "skipped_screenshots": driver.skipped_screenshots}
	# Re-create a real partial-production checkpoint with held input and countdown.
	for i in 5:
		route.walk_near(peak[i])
		route.stock(peak[i], "iron_ore", 2, true)
	model.advance(model.STEP, 1)
	for i in [5, 6]:
		route.walk_near(peak[i])
		route.stock(peak[i], "iron_ore", 2, true)
	route.walk_near(second)
	route._must(model.configure_load_group(second.id, [peak[0].id], 100000))
	route.walk_near(source)
	route._must(model.set_load_group_enabled(source.id, true))
	model.advance(model.STEP, 1)
	driver.expect(source.load_group.latch == "block" and source.load_group.evaluation_ticks_left == 19 and model.material_balance().balanced, "saved checkpoint has real in-flight work, held input, latch and cadence")
	var file := FileAccess.open(host.evidence.path_join("load-metrics.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "", true, true))
	Edges.new(driver).run()
	if driver.failures.is_empty(): Saves.new(host).write_variants(model)


func _control_click(button: Button) -> void:
	world.discovery_panel.scroll.ensure_control_visible(button)
	await driver.settle()
	await host._click(button)


func _storage_site() -> Vector2i:
	for z in range(17, 30):
		for x in range(-22, 2):
			var cell := Vector2i(x, z)
			if model.placement("grid_buffer", cell, model.actor).ok and model.Grid.reachability(model.core,
				{"type": "grid_buffer", "x": x, "z": z}, model.discovery.passages, model.map_id).ok:
				return cell
	assert(false, "no storage site near core")
	return Vector2i.ZERO
