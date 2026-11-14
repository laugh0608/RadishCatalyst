extends RefCounted

const Codec := preload("res://scripts/factory/save/codec.gd")
const Dispatch := Codec.V13.Dispatch
const CELL := "industrial_cell"
const GATE_CELL := Vector2i(0, 21)

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
	route.wait_for(func(): return route.devices.T.items.get("construction_pack", 0) >= 1, 180, "naturally assembled C1 construction pack")
	route._packs_to_core(1)
	route.wait_for(func(): return model.missing_stock(Dispatch.NODE.cost).is_empty(), 180, "natural C1 research materials")
	var stock: Dictionary = model.core.items.duplicate()
	world._open_device(model.core.id)
	var panel: Control = world.core_panel
	panel.tabs.current_tab = 2
	_choose(panel.research_choice, Dispatch.TYPE)
	await driver.settle()
	await host._click(panel.research_button)
	driver.expect(model.researched.has(Dispatch.TYPE) and model.core.items.get("metal_plate", 0) == stock.metal_plate - 2
		and model.core.items.get("catalyst", 0) == stock.catalyst - 1, "core III completes C1 with exact material debit")
	panel.tabs.current_tab = 4
	_choose(panel.assembly_choice, Dispatch.TYPE)
	await driver.settle()
	await host._click(panel.assembly_button)
	driver.expect(model.kits[Dispatch.TYPE] == 1 and model.core.items.get("construction_pack", 0) == stock.construction_pack - 1,
		"assembly spends one natural construction pack")
	await host._click(panel.close_button)

	route.walk_near(g)
	route._must(model.set_device_enabled(g.id, false))
	var capacity: int = model.Energy.FUEL_CAPACITY
	route.wait_for(func(): return g.fuel.get(CELL, 0) == capacity, 300, "the stopped generator fills from natural cell production")
	var remaining_burn: int = g.burn_remaining_ticks
	route.advance_movement = false
	route.walk_to(Vector2(-0.5, 21.5))
	var belt: Dictionary = model.entity_at(GATE_CELL)
	var belt_kits: int = model.kits.belt
	var belt_item: String = belt.cargo
	var bag_count: int = model.bag.get(belt_item, 0)
	await driver.settle()
	if host.windowed:
		await host._click(world.hud.buttons[Dispatch.TYPE])
		await driver.world_click(GATE_CELL)
		await driver.key(KEY_ESCAPE)
	else:
		route._must(model.place(Dispatch.TYPE, GATE_CELL, 0, model.actor))
	var gate: Dictionary = model.entity_at(GATE_CELL)
	if gate.get("type", "") != Dispatch.TYPE:
		driver.expect(false, "C1 fits at the last straight belt at (0,21)")
		return
	driver.expect(gate.dir == 0 and model.kits.belt == belt_kits + 1 and model.by_id(belt.id).is_empty(),
		"placement returns the replaced belt and faces the generator")
	driver.expect(belt_item.is_empty() or model.bag.get(belt_item, 0) == bag_count + 1, "any replaced belt cargo returns to the backpack")
	await driver.shot("07-timed-device")
	route.walk_near(gate)
	if host.windowed:
		await driver.world_click(GATE_CELL, 0.3)
	else:
		world._open_device(gate.id)
	await driver.settle()
	var controls: Control = world.discovery_panel.dispatch_controls
	driver.expect(controls.visible and controls.toggle_button.disabled and not gate.active and gate.cargo.is_empty(),
		"new C1 starts unconfigured with a disabled enable button")
	controls.item.select(controls.allowed.find(CELL) + 1)
	controls.item.item_selected.emit(controls.item.selected)
	driver.expect(controls.period.value == 120 and controls.window.value == 10 and controls.quota.value == 1,
		"panel offers the audited 120 s / 10 s / 1 item sample")
	await host._click(controls.apply_button)
	var incoming: Dictionary = model.entity_at(GATE_CELL + Vector2i.LEFT)
	route.wait_for(func(): return incoming.cargo == CELL and incoming.progress >= 1.0 - 1e-9, 120, "one more natural cell queues behind C1")
	driver.expect(gate.cargo.is_empty() and gate.phase_ticks == 0, "configured but disabled C1 rejects incoming cargo and freezes phase")
	await host._click(controls.toggle_button)
	driver.expect(gate.active and gate.phase_ticks == 0, "apply and enable defer simulation until the next tick")
	model.advance(3.0, 60)
	world.discovery_panel.refresh()
	driver.expect(gate.progress == 1.0 and gate.cargo == CELL and gate.sent == 0 and g.fuel[CELL] == capacity
		and "目标已满" in model.feedback(gate).label,
		"blocked window holds a ready cell without consuming quota: %s / %s" % [str(gate), str(model.feedback(gate))])
	await driver.shot("04-timed-window-blocked")

	model.advance(7.0, 140)
	route.walk_near(g)
	route.stock(g, CELL, 1, false)
	model.advance(109.95, 2199)
	driver.expect(gate.phase_ticks == 2399 and gate.sent == 0 and gate.cargo == CELL and g.fuel[CELL] == capacity - 1,
		"space freed after the window stays empty until the next cycle")
	model.advance(0.05, 1)
	driver.expect(gate.phase_ticks == 0 and gate.sent == 0 and g.fuel[CELL] == capacity - 1, "last closed tick rolls over without a departure")
	model.advance(0.05, 1)
	driver.expect(gate.phase_ticks == 1 and gate.sent == 1 and gate.cargo.is_empty() and g.fuel[CELL] == capacity
		and g.burn_remaining_ticks == remaining_burn, "first open tick fills the generator without altering its current burn")
	model.advance(2.0, 40)
	route.walk_near(g)
	route.stock(g, CELL, 1, false)
	model.advance(0.05, 1)
	driver.expect(gate.cargo == CELL and gate.sent == 1 and g.fuel[CELL] == capacity - 1 and "额度" in model.feedback(gate).label,
		"the current window cannot send a second cell even with available fuel space")

	route.walk_near(gate)
	world.discovery_panel.refresh()
	await host._click(controls.toggle_button)
	var frozen: Dictionary = gate.duplicate()
	model.advance(121.0, 2420)
	driver.expect(gate == frozen, "local stop freezes cargo, progress, quota and phase across an entire cycle")
	await driver.shot("05-timed-stopped")
	await host._click(controls.toggle_button)
	route.walk_near(g)
	route._must(model.set_device_enabled(g.id, true))
	model.advance(0.05, 1)
	driver.expect(gate.active and gate.phase_ticks == frozen.phase_ticks + 1 and gate.sent == 1
		and g.burn_remaining_ticks > 0 and model.material_balance().balanced, "re-enable continues phase and generator burn follows its own clock")
	world.discovery_panel.close_panel()
	var to_edge: int = gate.period_s * Dispatch.TICKS_PER_SECOND - 1 - gate.phase_ticks
	model.advance(to_edge * model.STEP, to_edge)
	driver.expect(gate.phase_ticks == 2399 and gate.sent == 1 and gate.cargo == CELL and g.fuel.get(CELL, 0) < capacity,
		"checkpoint is one closed tick from rollover with a staged cell and available downstream space")
	_exact_boundary()


func _choose(button: OptionButton, id: String) -> void:
	for i in button.item_count:
		if button.get_item_metadata(i) == id:
			button.select(i)
			button.item_selected.emit(i)
			return


func _exact_boundary() -> void:
	var fixture := Codec.V13.TimedModel.new()
	fixture.researched[Dispatch.TYPE] = true
	fixture.kits[Dispatch.TYPE] = 1
	var gate: Dictionary = fixture.place(Dispatch.TYPE, Vector2i(-30, 23), 0).entity
	var incoming: Dictionary = fixture.place("belt", Vector2i(-31, 23), 0).entity
	var outgoing: Dictionary = fixture.place("belt", Vector2i(-29, 23), 0).entity
	fixture.actor.x = -29.5
	fixture.actor.z = 22.0
	driver.expect(not fixture.configure_dispatch(gate.id, "crust_sample", 5, 1, 1).ok
		and not fixture.configure_dispatch(gate.id, "crystal", 5, 1, 2).ok
		and fixture.configure_dispatch(gate.id, "crystal", 5, 1, 1).ok, "strict whitelist and one-second single-slot cap")
	fixture.set_dispatch_active(gate.id, true)
	incoming.cargo = "iron_ore"
	incoming.progress = 1.0
	fixture.advance(0.05, 1)
	driver.expect(gate.cargo.is_empty() and incoming.cargo == "iron_ore", "wrong material stays upstream")
	incoming.cargo = "crystal"
	fixture.advance(1.0, 20)
	driver.expect(gate.cargo == "crystal" and gate.sent == 0 and outgoing.cargo.is_empty(), "an initially empty slot misses a one-second window")
	fixture.advance(3.95, 79)
	driver.expect(gate.phase_ticks == 0 and gate.progress == 1.0 and outgoing.cargo.is_empty(), "preloaded cargo waits at the exact rollover")
	fixture.advance(0.05, 1)
	driver.expect(gate.sent == 1 and gate.cargo.is_empty() and outgoing.cargo == "crystal", "a ready item passes on the first tick of a one-second window")
	driver.expect(Dispatch.quota_limit(1) == 1 and Dispatch.quota_limit(2) == 2
		and Dispatch.quota_limit(21) == 20 and Dispatch.quota_limit(600) == 60, "quota includes the 21-tick refill gap and hard cap")


func validate_saved(doc: Dictionary, id: String) -> void:
	var old := Codec.V12.snapshot(Codec.V12.StorageModel.new(), id, doc.name, 1)
	var decoded := Codec.decode(old, id)
	driver.expect(decoded.ok and not decoded.model.kits.has(Dispatch.TYPE), "schema 12 continues without C1")
	for change in [{"phase_ticks": 2400}, {"phase_ticks": 0, "sent": 1}, {"cargo": "crystal"}, {"quota": 61}]:
		var invalid := doc.duplicate(true)
		for entity in invalid.state.entities:
			if entity.type == Dispatch.TYPE:
				entity.merge(change, true)
		driver.expect(not Codec.decode(invalid, id).ok, "forged C1 state is rejected: " + str(change))
