extends RefCounted

const Codec := preload("res://scripts/factory/save/codec.gd")
const Feedback := Codec.V14.Feedback
const Buffer := Feedback.Storage
const CELL := "industrial_cell"
const GATE_CELL := Vector2i(0, 21)
const StoragePath := preload("res://scripts/checks/factory_grid_storage_path.gd")
const Edges := preload("res://scripts/checks/factory_storage_feedback_edges.gd")
const Saves := preload("res://scripts/checks/factory_storage_feedback_saves.gd")
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
	var gate: Dictionary = model.entity_at(GATE_CELL)
	route.walk_near(g)
	route._must(model.set_device_enabled(g.id, false))
	route.wait_for(func(): return g.fuel.get(CELL, 0) >= 4, 720, "natural cells for E2, assembly, C2 and charging reserve")
	route.stock(g, CELL, 3, false)
	route.wait_for(func(): return route.devices.T.items.get("construction_pack", 0) >= 18, 1200, "natural packs for storage and seven peak-load furnaces")
	route._packs_to_core(18)
	route.stock(model.core, CELL, 3, true)
	# Reserve one actual carrier before the assembler consumes it.
	var carrier: Dictionary = route.devices.F2
	route.walk_near(carrier)
	route.wait_for(func(): return carrier.output.get("porous_carrier", 0) >= 1, 60, "natural carrier for C2")
	route.stock(carrier, "porous_carrier", 1, false)
	route.walk_near(model.core)
	route.stock(model.core, "porous_carrier", 1, true)
	var panel: Control = world.core_panel
	world._open_device(model.core.id)
	panel.tabs.current_tab = 2
	_choose(panel.research_choice, Buffer.TYPE)
	await driver.settle()
	await host._click(panel.research_button)
	panel.tabs.current_tab = 4
	_choose(panel.assembly_choice, Buffer.TYPE)
	await driver.settle()
	await host._click(panel.assembly_button)
	driver.expect(model.researched.has(Buffer.TYPE) and model.kits[Buffer.TYPE] == 1 and model.core.items.get(CELL, 0) == 1, "natural E2 study and assembly leave one C2 cell")
	panel.tabs.current_tab = 2
	_choose(panel.research_choice, Feedback.RESEARCH)
	await driver.settle()
	var before: Dictionary = model.core.items.duplicate()
	await host._click(panel.research_button)
	driver.expect(model.researched.has(Feedback.RESEARCH), "core III exposes and completes C2 research")
	for item in Feedback.NODE.cost:
		driver.expect(model.core.items.get(item, 0) == before.get(item, 0) - Feedback.NODE.cost[item], "C2 exact debit: " + item)
	driver.expect(not model.research(Feedback.RESEARCH).ok and model.material_balance().balanced, "duplicate research cannot pay twice")
	await host._click(panel.close_button)
	route.walk_to(Vector2(2.5, 24.5))
	if host.windowed:
		await host._click(world.hud.buttons[Buffer.TYPE])
		await driver.world_click(Vector2i(1, 22))
		await driver.key(KEY_ESCAPE)
	else:
		route._must(model.place(Buffer.TYPE, Vector2i(1, 22), 0, model.actor))
	var b: Dictionary = model.entity_at(Vector2i(1, 22))
	driver.expect(b.type == Buffer.TYPE and b.stored_j == 0, "C2 uses newly built empty storage")
	var peak: Array[Dictionary] = []
	var helper := StoragePath.new(host, route)
	route.walk_near(model.core)
	for i in 7:
		route._must(model.assemble("refinery"))
		peak.append(route._must(model.place("refinery", helper._refinery_site())).entity)
	var iron: Dictionary = route.devices.I
	route.walk_near(iron)
	route.wait_for(func(): return iron.buffer.get("iron_ore", 0) >= 42, 480, "natural ore for three batches of peak load")
	route.stock(iron, "iron_ore", 42, false)
	var running: Array[int] = []
	for device in model.entities:
		if model.DiscoveryRules.POWER.has(device.type) and device.enabled:
			running.append(device.id)
			route.walk_near(device)
			route._must(model.set_device_enabled(device.id, false))
	route.walk_near(gate)
	world._open_device(gate.id)
	await driver.settle()
	var controls: Control = world.discovery_panel.feedback_controls
	driver.expect(controls.visible and gate.feedback.mode == "timed", "feedback controls are visible only for the new schema")
	controls.source.select(controls.source_ids.find(b.id))
	controls.source.item_selected.emit(controls.source.selected)
	await host._click(controls.apply_button)
	driver.expect(gate.feedback.latch == "pending" and gate.feedback.source_id == b.id, "panel binding saves pending until next simulation step")
	model.advance(model.STEP, 1)
	world.discovery_panel.refresh()
	driver.expect(gate.feedback.latch == "allow", "empty storage allows fuel")
	await driver.shot("08-feedback-bound")
	world.discovery_panel.close_panel()
	route.walk_near(g)
	route._must(model.set_device_enabled(g.id, true))
	var totals: Dictionary = model.statistics.totals.duplicate(true)
	var fuel_before: int = g.fuel.get(CELL, 0)
	var stored_before: int = b.stored_j
	# Only genuine G surplus charges the empty buffer; no energy fixture here.
	route.wait_for(func(): return b.stored_j >= 2100000, 60, "real fuel charges through the upper threshold")
	model.advance(model.STEP, 1)
	route.walk_near(gate)
	world._open_device(gate.id)
	await driver.settle()
	driver.expect(gate.feedback.latch == "block" and "高电量" in model.feedback(gate).label, "high energy visibly blocks fuel")
	await driver.shot("09-feedback-high")
	if host.windowed:
		host.root.size = Vector2i(1100, 720)
		await driver.settle(12)
		await driver.shot("10-feedback-minimum")
		host.root.size = Vector2i(1440, 900).min(DisplayServer.screen_get_usable_rect().size - Vector2i(32, 48))
		await driver.settle(12)
	world.discovery_panel.close_panel()
	route.walk_near(g)
	route._must(model.set_device_enabled(g.id, false))
	for furnace in peak:
		route.walk_near(furnace)
		route._must(model.set_device_enabled(furnace.id, true))
	var plates: int = model.completed_by_recipe.direct_refining
	for wave in 3:
		for furnace in peak:
			route.walk_near(furnace)
			route.stock(furnace, "iron_ore", 2, true)
		model.advance(8.0, 160)
		for furnace in peak:
			route.walk_near(furnace)
			route.stock(furnace, "metal_plate", 1, false)
	var peak_plates: int = model.completed_by_recipe.direct_refining - plates
	driver.expect(b.stored_j <= Feedback.LOW_J, "real 420 kW peak load drains through the lower threshold")
	model.advance(model.STEP, 1)
	route.walk_near(gate)
	world._open_device(gate.id)
	await driver.settle()
	driver.expect(gate.feedback.latch == "allow" and model.completed_by_recipe.direct_refining > plates, "low energy resumes permission while real furnaces produce")
	await driver.shot("11-feedback-low")
	world.discovery_panel.close_panel()
	route.walk_near(b)
	route._must(model.set_device_enabled(b.id, false))
	route.walk_near(gate)
	world._open_device(gate.id)
	await driver.settle()
	driver.expect("停用" in controls.status.text, "disabled binding reason is visible")
	await driver.shot("12-feedback-invalid")
	var phase: int = gate.phase_ticks
	var sent: int = gate.sent
	await host._click(controls.exit_button)
	driver.expect(gate.feedback.mode == "timed" and gate.phase_ticks == phase and gate.sent == sent, "panel takeover preserves phase and quota")
	world.discovery_panel.close_panel()
	route.walk_near(b)
	route._must(model.set_device_enabled(b.id, true))
	for furnace in peak:
		route.walk_near(furnace)
		route._must(model.set_device_enabled(furnace.id, false))
	route.walk_near(g)
	route._must(model.set_device_enabled(g.id, true))
	route.wait_for(func(): return b.stored_j >= 1500000, 60, "charge a real hysteresis-band checkpoint")
	route._must(model.set_device_enabled(g.id, false))
	# Resume the original production chain; peak fixtures stay disabled.
	for id in running:
		if peak.any(func(e): return e.id == id):
			continue
		var device: Dictionary = model.by_id(id)
		route.walk_near(device)
		route._must(model.set_device_enabled(id, true))
	route.walk_near(gate)
	world._open_device(gate.id)
	await driver.settle()
	controls.source.select(controls.source_ids.find(b.id))
	controls.source.item_selected.emit(controls.source.selected)
	await host._click(controls.apply_button)
	model.advance(model.STEP, 1)
	driver.expect(gate.feedback.latch == "allow" and b.stored_j > Feedback.LOW_J and b.stored_j < Feedback.HIGH_J, "checkpoint has a naturally charged in-band allow decision")
	world.discovery_panel.close_panel()
	var waiting_fuel: int = g.fuel.get(CELL, 0)
	route.wait_for(func(): return g.fuel.get(CELL, 0) > waiting_fuel, 125, "feedback permission delivers a real cell at the next C1 window")
	driver.expect(g.fuel.get(CELL, 0) == waiting_fuel + 1 and gate.sent == 1 and gate.feedback.latch == "allow",
		"real C2 supply sends exactly one cell into the stopped generator")
	route.wait_for(func(): return gate.cargo == CELL and gate.progress >= 1.0 and gate.sent == 1, 300, "staged natural cell and spent quota for cross-process check")
	route.walk_near(gate)
	var stats: Dictionary = model.statistics.totals
	var report := {"execution_mode": "window" if host.windowed else "headless", "fixed_step_fixture": true,
		"activated_cells": stats.cells_activated - totals.cells_activated, "stored_j": b.stored_j,
		"stored_before_j": stored_before,
		"delivered_cells": g.fuel.get(CELL, 0) - fuel_before + stats.cells_activated - totals.cells_activated,
		"deficit_kj": stats.deficit_kj - totals.deficit_kj, "spill_kj": stats.spill_kj - totals.spill_kj,
		"charge_j": stats.charge_j - totals.charge_j, "discharge_j": stats.discharge_j - totals.discharge_j,
		"storage_loss_j": stats.storage_loss_j - totals.storage_loss_j, "peak_plates": peak_plates,
		"skipped_screenshots": driver.skipped_screenshots}
	var file := FileAccess.open(host.evidence.path_join("feedback-metrics.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "", true, true))
	driver.expect(model.material_balance().balanced, "C2 natural path preserves the complete material ledger")
	Edges.new(driver).run()
	if driver.failures.is_empty() and not host.loads:
		Saves.new(host).write_variants(model)


func _choose(button: OptionButton, id: String) -> void:
	for i in button.item_count:
		if button.get_item_metadata(i) == id:
			button.select(i)
			button.item_selected.emit(i)
			return
