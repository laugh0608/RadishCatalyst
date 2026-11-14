extends "res://scripts/checks/factory_frontier_route.gd"

const Codec := preload("res://scripts/factory/save/codec.gd")
const Loads := Codec.V15.Loads
const CAPS := {"iron_powder": 36, "carbon_powder": 32, "catalyst": 10, "metal_plate": 18, "porous_carrier": 4}
var preparation_events: Array[Dictionary] = []


func prepare(full_layout: Dictionary) -> Dictionary:
	bootstrap()
	energy_line()
	var temporary := prepare_expansion(full_layout.incremental_packs + 4)
	prepare_research(temporary[0])
	walk_near(model.core)
	_must(model.research(Frontier.RESEARCH))
	open_outer_and_prepare_capsules(temporary[0], temporary[1])
	craft(temporary[1], "boring_capsule_assembly", 1)
	walk_to(GATE)
	_must(model.open_passage(Frontier.PASSAGE))
	expand(full_layout, temporary)
	advance_movement = false
	set_enabled("Kh", true)
	set_enabled("Fd", false)
	# D2 is funded by the same real line; no pre-unlocked research or stock injection.
	walk_near(devices.Ts)
	wait_for(func(): return devices.Ts.items.get("mineral_slag", 0) >= 2, 240, "D2 reuse research slag")
	stock(devices.Ts, "mineral_slag", 2, false)
	walk_near(model.core)
	stock(model.core, "mineral_slag", 2, true)
	_must(model.research(P.REUSE))
	wait_for(func(): return devices.T.items.get("construction_pack", 0) >= 13, 900, "D2 research and equipment packs")
	_packs_to_core(13)
	set_enabled("G", false)
	walk_near(devices.G)
	wait_for(func(): return devices.G.fuel.get(CELL, 0) >= 5, 480, "D2 five research and assembly cells")
	stock(devices.G, CELL, 5, false)
	walk_near(model.core)
	stock(model.core, CELL, 5, true)
	set_enabled("A", false)
	for i in 5:
		walk_near(devices.F2)
		wait_for(func(): return devices.F2.output.get("porous_carrier", 0) >= 1, 90, "D2 study carrier")
		stock(devices.F2, "porous_carrier", 1, false)
	walk_near(model.core)
	stock(model.core, "porous_carrier", 5, true)
	_must(model.upgrade_core())
	for study in [model.Buffer.TYPE, model.Dispatch.TYPE, model.Feedback.RESEARCH, Loads.RESEARCH]:
		wait_for(func(): return model.missing_stock(model.research_nodes[study].cost).is_empty(), 240, "D2 research material " + study)
		_must(model.research(study))
	for type in [model.Buffer.TYPE, model.Dispatch.TYPE, "storage", "splitter"]:
		_must(model.assemble(type))
	# Replace existing belt cells using the normal attachment transaction.
	walk_to(Vector2(-0.5, 21.5))
	devices.dispatch = _must(model.place(model.Dispatch.TYPE, Vector2i(0, 21), 0, model.actor)).entity
	_must(model.configure_dispatch(devices.dispatch.id, CELL, 120, 120, 60))
	walk_near(devices.E)
	devices.fuel_split = _must(model.place("splitter", Vector2i(1, 25), 0, model.actor)).entity
	walk_to(Vector2(2.5, 28.5))
	devices.overflow = _must(model.place("storage", Vector2i(2, 26), 0, model.actor)).entity
	var path: Array[Vector2i] = [Vector2i(1, 26), Vector2i(1, 27)]
	_must(model.place_path(path, 0, Vector2i(2, 27)))
	var tail: Dictionary = model.entity_at(Vector2i(1, 27))
	var outlet: Dictionary = model.Logistics.output_connection(model, model.Logistics.ports(model, tail, "output")[0])
	assert(tail.dir == 0 and outlet.ok and outlet.target.id == devices.overflow.id, "overflow belt must turn east into storage")
	set_enabled("A", true)
	set_enabled("G", true)
	# Empty the inactive dispatch's downstream cache through inventory commands;
	# retain its active cell and burn that remainder normally before placing B.
	walk_near(devices.G)
	var cached: int = devices.G.fuel.get(CELL, 0)
	if cached > 0: stock(devices.G, CELL, cached, false)
	walk_near(model.core)
	if model.bag.get(CELL, 0) > 0: stock(model.core, CELL, model.bag[CELL], true)
	# Direct-branch plates remain real material and can fund later production.
	walk_near(devices.Td)
	var direct: int = devices.Td.items.get("metal_plate", 0)
	if direct > 0:
		stock(devices.Td, "metal_plate", direct, false)
		walk_near(model.core)
		stock(model.core, "metal_plate", direct, true)
	var bounded := _bound_stock()
	if not bounded.ok: return bounded
	# Require actual upstream cells, never insert cargo into the dispatch slot.
	var queued: Dictionary = model.entity_at(Vector2i(-1, 21))
	if queued.cargo != CELL:
		return {"ok": false, "reason": "bounded preparation has no cell at the final upstream belt"}
	walk_to(Vector2(2.5, 24.5))
	devices.B = _must(model.place(model.Buffer.TYPE, Vector2i(1, 22), 0, model.actor)).entity
	_must(model.configure_load_group(devices.B.id, [devices.A.id], 100000))
	var ids := {}
	var approaches := {}
	for key in devices:
		ids[key] = devices[key].id
		walk_near(devices[key])
		approaches[key] = {"x": model.actor.x, "z": model.actor.z}
	walk_near(devices.B)
	return {"ok": true, "ids": ids, "approaches": approaches, "caps": CAPS,
		"milestones": milestones, "preparation_seconds": model.time, "events": preparation_events,
		"held": model.material_balance().held, "balanced": model.material_balance().balanced,
		"movement": "existing collision walk; production time fixed-step preparation"}


func set_enabled(key: String, enabled: bool) -> void:
	var e: Dictionary = devices[key]
	if e.enabled == enabled: return
	walk_near(e)
	_must(model.set_device_enabled(e.id, enabled))
	preparation_events.append({"tick": model.statistics.ticks, "device": key, "enabled": enabled})


func set_when_idle(key: String, enabled: bool) -> void:
	if not enabled and devices[key].get("processing", false): return
	set_enabled(key, enabled)


func _bound_stock() -> Dictionary:
	# Produce finished goods to consume excess intermediate stock. Sources and
	# buffers retain everything; only legal production/enable commands are used.
	var initial: Dictionary = model.material_balance().held
	# A full cell cycle plus its input transport allowance for each excess
	# catalyst. This bounds preparation, not a measured workload or stock cap.
	var seconds: int = maxi(600, (maxi(0, initial.get("catalyst", 0) - CAPS.catalyst) + 5) * 24 + 120)
	preparation_events.append({"stage": "bound_stock", "initial": initial, "caps": CAPS, "timeout_seconds": seconds})
	for tick in seconds * 20:
		var held: Dictionary = model.material_balance().held
		var excess := false
		for item in CAPS:
			if held.get(item, 0) > CAPS[item]: excess = true
		var ready: bool = not excess and devices.G.burn_remaining_ticks == 0
		for key in ["F", "F2", "Fd", "R", "E", "A", "C", "Ci"]:
			var enable: bool = not ready
			match key:
				"Fd": enable = false
				"F": enable = enable and held.get("metal_plate", 0) <= 16
				"F2": enable = enable and held.get("porous_carrier", 0) <= 3
				"R": enable = enable and held.get("catalyst", 0) <= 9
				"C": enable = enable and held.get("carbon_powder", 0) <= 30
				"Ci": enable = enable and held.get("iron_powder", 0) <= 33
			set_when_idle(key, enable)
		var idle := true
		for key in ["F", "F2", "Fd", "R", "E", "A", "C", "Ci"]:
			if devices[key].processing: idle = false
		if ready and idle:
			# Upstream processors are enabled in all arms by the common workload at t0.
			return {"ok": true}
		model.advance(model.STEP, 1)
	return {"ok": false, "reason": "intermediate stock did not reach the frozen two-cycle caps before the calculated preparation timeout", "timeout_seconds": seconds, "held": model.material_balance().held, "caps": CAPS}
