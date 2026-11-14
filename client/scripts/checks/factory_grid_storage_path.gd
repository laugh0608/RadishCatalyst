extends RefCounted

const Buffer := preload("res://data/factory/grid_storage_rules.gd")
const Codec := preload("res://scripts/factory/save/codec.gd")
const Model := Codec.V12.StorageModel
const CELL := Model.Energy.CELL
const GRID := Model.Grid
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
	world = check.boot.factory_world


func exercise() -> void:
	var g: Dictionary = route.devices.G
	var iron: Dictionary = route.devices.I
	route.wait_for(func(): return route.devices.T.items.get("construction_pack", 0) >= 18, 1200, "E2 and seven test furnaces use naturally assembled packs")
	route._packs_to_core(18)
	route.walk_near(g)
	route.wait_for(func(): return g.fuel.get(CELL, 0) >= 4, 250, "E2 costs two naturally assembled cells and reserves fuel for charging")
	route.stock(g, CELL, 2, false)
	route.walk_near(model.core)
	route.stock(model.core, CELL, 2, true)
	world._open_device(model.core.id)
	var panel: Control = world.core_panel
	panel.tabs.current_tab = 2
	_choose(panel.research_choice, Buffer.TYPE)
	await driver.settle()
	await host._click(panel.research_button)
	driver.expect(model.researched.has(Buffer.TYPE) and model.core.items.get(CELL, 0) == 1, "E2 research consumes one cell")
	panel.tabs.current_tab = 4
	_choose(panel.assembly_choice, Buffer.TYPE)
	await driver.settle()
	await host._click(panel.assembly_button)
	driver.expect(model.kits[Buffer.TYPE] == 1 and model.core.items.get(CELL, 0) == 0, "buffer assembly consumes one cell")
	driver.expect(not model.assemble(Buffer.TYPE).ok and model.kits[Buffer.TYPE] == 1, "missing cell prevents partial assembly")
	await host._click(panel.close_button)
	route.walk_to(Vector2(2.5, 24.5))
	var cell := Vector2i(1, 22)
	if host.windowed:
		await host._click(world.hud.buttons[Buffer.TYPE])
		await driver.world_click(cell)
		await driver.key(KEY_ESCAPE)
	else:
		route._must(model.place(Buffer.TYPE, cell, 0, model.actor))
	var e: Dictionary = model.entity_at(cell)
	if e.get("type", "") != Buffer.TYPE:
		driver.expect(false, "place the 2×2 buffer at the audited site")
		return
	driver.expect(e.stored_j == 0 and e.power_node_id == g.id and not GRID.is_node(e), "buffer is born empty and auto-attaches as a non-relaying endpoint")
	route._must(model.set_device_enabled(e.id, false))
	route.walk_near(model.core)
	var furnaces: Array[Dictionary] = []
	for i in 7:
		route._must(model.assemble("refinery"))
		var candidate := _refinery_site()
		furnaces.append(route._must(model.place("refinery", candidate)).entity)
	route.walk_near(iron)
	route.wait_for(func(): return iron.buffer.get("iron_ore", 0) >= 14, 120, "naturally mined ore for the peak load")
	route.stock(iron, "iron_ore", 14, false)
	route.advance_movement = false
	for device in model.entities:
		if model.DiscoveryRules.POWER.has(device.type) and device.enabled:
			route.walk_near(device)
			route._must(model.set_device_enabled(device.id, false))
	route.walk_near(e)
	route._must(model.set_device_enabled(e.id, true))
	var previous: Dictionary = model.statistics.totals.duplicate(true)
	var plan: Dictionary = model.power_state()
	driver.expect(plan.charge_j == 3000 and plan.discharge_j == 0 and e.stored_j == 0, "power preview is read-only and charging is capped")
	model.advance(1.0, 20)
	driver.expect(e.stored_j == 54000 and model.statistics.totals.storage_loss_j - previous.storage_loss_j == 6000, "one second gives 54 kJ after 6 kJ charge loss")
	model.advance(70.0, 1400)
	driver.expect(e.stored_j == Buffer.CAPACITY_J and model.power_state().charge_j == 0 and model.power_state().spill_kw > 0, "full buffer spills excess")
	route.walk_near(e)
	world._open_device(e.id)
	await driver.settle()
	driver.expect(world.discovery_panel.visible and world.discovery_panel.buttons.device_toggle.visible, "storage has its own operation panel")
	await driver.shot("04-buffer-full")
	await host._click(world.discovery_panel.buttons.device_toggle)
	driver.expect(not e.enabled and model.stored_joules() == Buffer.CAPACITY_J, "panel stop retains energy")
	await host._click(world.discovery_panel.buttons.device_toggle)
	world.discovery_panel.close_panel()
	route.walk_near(g)
	route._must(model.set_device_enabled(g.id, false))
	for furnace in furnaces:
		route.walk_near(furnace)
		route.stock(furnace, "iron_ore", 2, true)
		route._must(model.set_device_enabled(furnace.id, true))
	plan = model.power_state()
	driver.expect(is_equal_approx(plan.request_kw, 420.0) and plan.deficit_kw < 1e-9 and plan.discharge_j == 3000 and plan.charge_j == 0,
		"seven fed furnaces reach 420 kW and buffer adds exactly 60 kW")
	var checkpoint: Dictionary = Codec.snapshot(model, world.store.world_id, world.store.world_name, world.store.sequence)
	var baseline: Dictionary = Codec.decode(checkpoint, world.store.world_id)
	if baseline.ok:
		var copy: RefCounted = baseline.model
		copy.by_id(e.id).enabled = false
		copy.revision += 1
		var already: int = model.completed_by_recipe.direct_refining
		copy.advance(8.0, 160)
		var with_buffer: Dictionary = Codec.decode(checkpoint, world.store.world_id)
		with_buffer.model.advance(8.0, 160)
		driver.expect(copy.completed_by_recipe.direct_refining == already and with_buffer.model.completed_by_recipe.direct_refining == already + 7,
			"same natural inputs make seven plates in eight seconds with E2 and zero without")
	else:
		driver.expect(false, "pre-discharge checkpoint decodes: " + baseline.reason)
	model.advance(0.5, 10)
	driver.expect(e.stored_j == 3570000 and model.material_balance().balanced, "half a second discharges exactly 30 kJ with balanced material account")
	route.walk_near(e)
	world._open_device(e.id)
	await driver.settle()
	await driver.shot("05-buffer-discharging")
	world.discovery_panel.close_panel()
	await host._click(world.hud.buttons.statistics)
	var statistics: Control = world.statistics_panel
	statistics.page.select(1)
	statistics.page.item_selected.emit(1)
	await driver.settle()
	driver.expect("累计充入" in statistics.power_summary.text and "拆除损失" in statistics.power_summary.text,
		"electricity page separates storage flows and losses")
	await driver.shot("06-storage-electricity")
	await host._click(statistics.buttons.close)
	_exact_boundaries()


func _choose(button: OptionButton, id: String) -> void:
	for i in button.item_count:
		if button.get_item_metadata(i) == id:
			button.select(i)
			button.item_selected.emit(i)
			return


func _refinery_site() -> Vector2i:
	for z in range(17, 30):
		for x in range(-22, 2):
			var cell := Vector2i(x, z)
			if not model.placement("refinery", cell, model.actor).ok:
				continue
			var e := {"type": "refinery", "x": x, "z": z}
			for node in model.entities:
				if GRID.is_node(node) and GRID.reachability(node, e, model.discovery.passages, model.map_id).ok:
					if model.grid.membership.has(node.id) and model.grid.groups[model.grid.membership[node.id]].base_capacity_kw > 0:
						return cell
	assert(false, "no accessible refinery site")
	return Vector2i.ZERO


func _exact_boundaries() -> void:
	var fixture := Model.new()
	fixture.researched[Buffer.TYPE] = true
	fixture.kits[Buffer.TYPE] = 3
	fixture.kits[Model.Energy.GENERATOR] = 1
	fixture.researched[Model.Progression.CELLS] = true
	var g: Dictionary = fixture.place(Model.Energy.GENERATOR, Vector2i(-29, 24)).entity
	var first: Dictionary = fixture.place(Buffer.TYPE, Vector2i(-26, 24)).entity
	var second: Dictionary = fixture.place(Buffer.TYPE, Vector2i(-26, 27)).entity
	var core_buffer: Dictionary = fixture.place(Buffer.TYPE, Vector2i(-5, 24)).entity
	g.enabled = true
	g.fuel[CELL] = 1
	first.stored_j = Buffer.CAPACITY_J - 9
	fixture.revision += 1
	var plan: Dictionary = fixture.power_state()
	driver.expect(plan.buffers[first.id].charge_j == 10 and plan.buffers[second.id].charge_j == 3000,
		"whole charging packets fill the first buffer before the next buffer")
	driver.expect(plan.buffers[core_buffer.id].network != plan.buffers[first.id].network
		and plan.buffers[core_buffer.id].charge_j == 0, "isolated G cannot charge across grids and the core does not charge storage")
	g.enabled = false
	fixture.actor.x = -26.5
	fixture.actor.z = 24.5
	fixture.salvage(g.id, true)
	fixture.advance(Model.STEP, 1)
	driver.expect(first.power_node_id == 0 and first.stored_j == Buffer.CAPACITY_J - 9, "detaching a charged buffer preserves its energy")


func validate_saved(doc: Dictionary, id: String) -> void:
	var older := Codec.V11.snapshot(Codec.V11.ControlsModel.new(), id, doc.name, 1)
	driver.expect(Codec.decode(older, id).ok and not Codec.decode(older, id).model.kits.has(Buffer.TYPE), "schema 11 continues without E2 fields")
	var invalid := doc.duplicate(true)
	for entity in invalid.state.entities:
		if entity.type == Buffer.TYPE:
			entity.stored_j += 1
	driver.expect(not Codec.decode(invalid, id).ok, "forged stored energy is rejected")
	invalid = doc.duplicate(true)
	invalid.state.statistics.totals.storage_loss_j += 1
	driver.expect(not Codec.decode(invalid, id).ok, "forged conversion loss is rejected")
	invalid = doc.duplicate(true)
	for entity in invalid.state.entities:
		if entity.type == Buffer.TYPE:
			entity.power_node_id = invalid.state.core.entity_id
	driver.expect(not Codec.decode(invalid, id).ok, "forged power attachment is rejected")
	var restored: RefCounted = Codec.decode(doc, id).model
	var e: Dictionary = restored.entities.filter(func(row): return row.type == Buffer.TYPE)[0]
	var joules: int = e.stored_j
	restored.set_device_enabled(e.id, false)
	var first: Dictionary = restored.salvage(e.id)
	driver.expect(first.get("needs_confirmation", false) and e.stored_j == joules, "charged salvage requires confirmation")
	var confirmed: Dictionary = restored.salvage(e.id, true)
	driver.expect(confirmed.ok and restored.stored_joules() == 0 and restored.statistics.totals.storage_discarded_j == joules,
		"confirmed salvage books the exact stored energy loss")
	var replacement: Dictionary = restored.place(Buffer.TYPE, Vector2i(e.x, e.z))
	driver.expect(replacement.ok and replacement.entity.stored_j == 0 and Codec.decode(Codec.snapshot(restored, id, doc.name, doc.sequence), id).ok,
		"replacing starts empty and the discard ledger decodes")
