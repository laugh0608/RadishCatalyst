extends RefCounted

const Model := preload("res://scripts/factory/integrated_model.gd")
const P := Model.Progression
const CELL := Model.Energy.CELL
const STEP := Model.STEP

var model: RefCounted
var layout: Dictionary
var devices := {}
var milestones := {}
var distance := 0.0
var carried := 0
var advance_movement := true


func _init(world_model: RefCounted, route: Dictionary) -> void:
	model = world_model
	layout = route
	devices.core = model.core


func _must(result: Dictionary) -> Dictionary:
	assert(result.ok, str(result.get("reason", "first-run command failed")))
	return result


func _cell(raw: Array) -> Vector2i:
	return Vector2i(raw[0], raw[1])


func build(key: String, type: String, dir := 0) -> Dictionary:
	var spot: Vector2i = _cell(layout.entities[key])
	var e: Dictionary = _must(model.place(type, spot, dir, model.actor)).entity
	devices[key] = e
	return e


func _name(endpoint: Variant) -> String:
	return endpoint if endpoint is String else endpoint[0]


func connect_line(source: String, target: String) -> void:
	for route in layout.routes:
		if _name(route.source) != source or _name(route.target) != target:
			continue
		if route.points.is_empty():
			return
		var path := belt_path(route.points)
		var normal: Vector2i
		if route.target is String:
			for port in model.Logistics.ports(model, model.core, "input"):
				if port.id == route.target:
					normal = Vector2i(port.dx, port.dz)
		else:
			normal = _cell(route.target[2])
		assert(model.DIRS.has(-normal))
		_must(model.place_path(path, model.DIRS.find(-normal)))
		return
	assert(false, "missing route %s to %s" % [source, target])


func belt_path(points: Array) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	if points.is_empty():
		return path
	path.append(_cell(points[0]))
	for point in points.slice(1):
		var end := _cell(point)
		while path.back() != end:
			path.append(path.back() + (end - path.back()).sign())
	return path


func stock(e: Dictionary, item: String, count: int, putting: bool) -> void:
	for i in count:
		_must(model.transfer(e.id, item, putting, false))
		carried += 1


func craft(e: Dictionary, id: String, count: int) -> void:
	walk_near(e)
	if e.recipe_id != id:
		_must(model.change_recipe(e.id, id))
	var recipe: Dictionary = model.recipes[id]
	for i in count:
		for item in recipe.input:
			stock(e, item, recipe.input[item], true)
		model.advance(recipe.seconds + STEP)
		for item in recipe.output:
			stock(e, item, recipe.output[item], false)


func wait_for(ready: Callable, seconds: int, reason: String) -> void:
	for i in seconds:
		if ready.call():
			return
		model.advance(1.0)
	assert(ready.call(), reason)


func _mark(name: String) -> void:
	assert(model.material_balance().balanced, name + " material balance")
	milestones[name] = model.time
	print("First run milestone %s at %.2f s" % [name, model.time])


func bootstrap() -> void:
	assert(model.entities.size() == 1 and model.bag.is_empty() and model.core.items.is_empty())
	for i in range(1, 7):
		build("J%d" % i, "power_junction")
	build("I", "collector")
	build("Q", "collector")
	build("F", "refinery")
	build("Sp", "splitter", 1)
	walk_near(devices.Q)
	wait_for(func(): return devices.Q.buffer.get("crystal", 0) >= 24, 60, "starter crystal stock")
	stock(devices.Q, "crystal", 24, false)
	craft(devices.F, "direct_sintering", 8)
	_must(model.change_recipe(devices.F.id, "direct_refining"))
	walk_near(model.core)
	stock(model.core, "porous_carrier", 8, true)
	connect_line("I", "F")
	connect_line("F", "Sp")
	connect_line("Sp", "IN_N2")
	wait_for(func(): return model.core.items.get("metal_plate", 0) >= 1, 170, "first plate reaches core")
	_mark("first_plate")
	wait_for(func(): return model.core.items.get("metal_plate", 0) >= 9, 120, "I-tier research plates")
	_must(model.research(P.ASSEMBLY))
	_must(model.research(P.POWDERS))
	walk_to(Model.DiscoveryRules.SAMPLE)
	_must(model.survey_sample(true))
	walk_near(model.core)
	_must(model.research(P.SAMPLE))
	assert(model.bag.crust_sample == 1)
	build("R", "reactor")
	build("Sq", "splitter", 1)
	connect_line("Q", "Sq")
	connect_line("Sq", "IN_N1")
	connect_line("OUT_W0", "R")
	connect_line("R", "IN_W0")
	_must(model.configure_output(model.core.id, "OUT_W0", "crystal", true))
	build("A", "assembler")
	build("T", "storage")
	connect_line("Sp", "A")
	stock(model.core, "porous_carrier", 4, false)
	for i in 2:
		walk_near(devices.A)
		stock(devices.A, "porous_carrier", 2, true)
		wait_for(func(): return devices.T.items.get("construction_pack", 0) >= (i + 1) * 2, 150, "construction packs enter terminal")
	_packs_to_core(4)
	_must(model.upgrade_core())
	_must(model.assemble("refinery"))
	_mark("tier_ii")
	wait_for(func(): return model.core.items.get("metal_plate", 0) >= 2 and model.core.items.get("catalyst", 0) >= 1, 100, "E1 research stock")
	_must(model.research(P.CELLS))
	build("F2", "refinery")
	walk_near(devices.F2)
	_must(model.change_recipe(devices.F2.id, "direct_sintering"))
	connect_line("Sq", "F2")
	connect_line("F2", "A")
	wait_for(func(): return devices.T.items.get("construction_pack", 0) >= 5, 350, "parallel branch funds G and E")
	_packs_to_core(5)
	_must(model.assemble("cell_generator"))
	_must(model.assemble("assembler"))


func energy_line() -> void:
	build("K", "collector")
	build("C", "crusher")
	build("G", "cell_generator")
	build("E", "assembler")
	walk_near(devices.C)
	_must(model.change_recipe(devices.C.id, "carbon_crushing"))
	walk_near(devices.E)
	_must(model.change_recipe(devices.E.id, "cell_assembly"))
	connect_line("K", "C")
	connect_line("C", "IN_N0")
	connect_line("OUT_N0", "E")
	connect_line("OUT_E0", "E")
	connect_line("OUT_S0", "E")
	connect_line("E", "G")
	assert(model.kits.belt == 96 and layout.belts == 160)
	walk_near(model.core)
	for row in [["OUT_N0", "catalyst"], ["OUT_E0", "metal_plate"], ["OUT_S0", "carbon_powder"]]:
		_must(model.configure_output(model.core.id, row[0], row[1], true))
	wait_for(func(): return devices.G.fuel.get(CELL, 0) >= 2, 180, "natural three-input cells fill G")
	assert(not devices.G.enabled and model.statistics.totals.cells_activated == 0)
	_mark("two_cells_delivered")


func _packs_to_core(count: int) -> void:
	walk_near(devices.T)
	stock(devices.T, "construction_pack", count, false)
	walk_near(model.core)
	stock(model.core, "construction_pack", count, true)


func steady() -> Dictionary:
	var gen: Dictionary = devices.G
	walk_near(gen)
	if not gen.enabled:
		_must(model.set_device_enabled(gen.id, true))
	var before: Dictionary = model.statistics.totals.duplicate(true)
	var cells_before: int = model.completed_by_recipe.cell_assembly
	var packs_before: int = model.completed_by_recipe.construction_assembly
	var tick_before: int = model.statistics.ticks
	var peak := 0.0
	for second in 180:
		# Leave any pending time from the window clock outside this sample.
		model.advance(1.0, 20)
		peak = maxf(peak, model.power_state().request_kw)
		assert(gen.burn_remaining_ticks > 0 or not gen.fuel.is_empty(), "continuous supply starved")
	var after: Dictionary = model.statistics.totals
	var released: float = after.fuel_released_kj - before.fuel_released_kj
	var spill: float = after.spill_kj - before.spill_kj
	var packs: int = model.completed_by_recipe.construction_assembly - packs_before
	var cells: int = model.completed_by_recipe.cell_assembly - cells_before
	var ticks: int = model.statistics.ticks - tick_before
	var activations: int = after.cells_activated - before.cells_activated
	assert(ticks == 3600 and is_equal_approx(released, 120.0 * 180) and activations == 3,
		"steady sample: %s ticks, %s kJ, %s activations" % [ticks, released, activations])
	assert(packs > 0 and cells >= 3 and is_equal_approx(after.deficit_kj, before.deficit_kj))
	_mark("continuous_burn")
	return {"seconds": 180, "peak_sampled_kw": peak, "cells": cells, "packs": packs,
		"released_kj": released, "activations": activations, "spill_kj": spill, "buffer": gen.fuel.get(CELL, 0)}


func alternatives_and_passages() -> void:
	wait_for(func(): return devices.T.items.get("construction_pack", 0) >= 8, 180, "parallel branch funds optional processing")
	_packs_to_core(8)
	for type in ["crusher", "refinery", "reactor", "collector"]:
		_must(model.assemble(type))
	var powder: Dictionary = _must(model.place("crusher", Vector2i(-14, 23))).entity
	var mixed: Dictionary = _must(model.place("refinery", Vector2i(-17, 28))).entity
	var trial: Dictionary = _must(model.place("reactor", Vector2i(-15, 28))).entity
	_must(model.place("power_junction", Vector2i(-18, 28)))
	# Reserve stock for the optional recipes after the uninterrupted supply measurement.
	var routed := [["OUT_N0", "catalyst"], ["OUT_E0", "metal_plate"], ["OUT_S0", "carbon_powder"]]
	for row in routed:
		_must(model.configure_output(model.core.id, row[0], row[1], false))
	wait_for(func(): return model.core.items.get("metal_plate", 0) >= 4 and model.core.items.get("carbon_powder", 0) >= 6 \
		and model.core.items.get("catalyst", 0) >= 24 and model.core.items.get("crystal", 0) >= 2, 240, "optional branch reserve")
	_must(model.research(P.MIXED))
	stock(model.core, "carbon_powder", 4, false)
	stock(model.core, "crystal", 1, false)
	stock(model.core, "catalyst", 24, false)
	walk_near(devices.I)
	wait_for(func(): return devices.I.buffer.get("iron_ore", 0) >= 8, 90, "real iron for powder branch")
	stock(devices.I, "iron_ore", 8, false)
	craft(powder, "iron_crushing", 4)
	craft(mixed, "mixed_refining", 2)
	walk_near(model.core)
	stock(model.core, "mineral_slag", 2, true)
	_must(model.research(P.REUSE))
	craft(mixed, "mixed_refining", 2)
	craft(mixed, "slag_sintering", 1)
	walk_near(model.core)
	stock(model.core, "metal_plate", 8, true)
	stock(model.core, "porous_carrier", 2, true)
	_mark("co_product_reuse")
	craft(trial, "solvent_trial", 1)
	assert(model.discovery.trial_completed and not model.bag.has("crust_sample"))
	craft(trial, "crust_solvent", 11)
	walk_to(Vector2(3, 0))
	_must(model.open_passage("outer"))
	walk_to(Vector2(19, 0))
	_must(model.open_passage("inner"))
	for cell in [Vector2i(-14, 0), Vector2i(-4, 0), Vector2i(5, 0), Vector2i(10, 1)]:
		_must(model.place("power_junction", cell))
	var rich: Dictionary = _must(model.place("collector", Vector2i(10, -1))).entity
	walk_near(rich)
	wait_for(func(): return rich.buffer.get("rich_crystal", 0) >= 1, 30, "opened rich ore has power")
	stock(rich, "rich_crystal", 1, false)
	craft(trial, "rich_catalyst", 1)
	walk_near(model.core)
	stock(model.core, "catalyst", 3, true)
	for row in routed:
		_must(model.configure_output(model.core.id, row[0], row[1], true))
	var previous: int = model.completed_by_recipe.cell_assembly
	wait_for(func(): return model.completed_by_recipe.cell_assembly > previous and devices.G.burn_remaining_ticks > 0, 120, "fuel production resumes after optional branch")
	_mark("rich_ore_return")


func walk_near(e: Dictionary) -> void:
	if model.near_entity(e):
		return
	var shape: Dictionary = model.CATALOG[e.type]
	var goals := {}
	for x in range(e.x * 2 - 1, (e.x + shape.w) * 2 + 2):
		for z in range(e.z * 2 - 1, (e.z + shape.d) * 2 + 2):
			if not model.blocked_for_actor(x * 0.5, z * 0.5):
				goals[Vector2i(x, z)] = true
	_walk(goals)
	assert(model.near_entity(e), "walk ended outside interaction range")


func walk_to(target: Vector2) -> void:
	_walk({Vector2i((target * 2.0).round()): true})


func _walk(goals: Dictionary) -> void:
	var start := Vector2i((Vector2(model.actor.x, model.actor.z) * 2.0).round())
	var visited := {start: start}
	var queue: Array[Vector2i] = [start]
	var cursor := 0
	var end := start
	while cursor < queue.size():
		end = queue[cursor]
		cursor += 1
		if goals.has(end):
			break
		for dir in Model.DIRS:
			var next: Vector2i = end + dir
			if visited.has(next) or model.blocked_for_actor(next.x * 0.5, next.y * 0.5):
				continue
			visited[next] = end
			queue.append(next)
	assert(goals.has(end), "no walkable approach")
	var path: Array[Vector2i] = []
	while end != start:
		path.append(end)
		end = visited[end]
	path.reverse()
	var seconds := 0.0
	for cell in path:
		var target := Vector2(cell) * 0.5
		while true:
			var diff := target - Vector2(model.actor.x, model.actor.z)
			if diff.length() < 0.0001:
				break
			var dt := minf(0.06, diff.length() / 3.3)
			model.move_actor(model.actor, diff.x, diff.y, dt)
			seconds += dt
			assert((target - Vector2(model.actor.x, model.actor.z)).length() < diff.length(), "physical walk blocked")
	distance += seconds * 3.3
	if not advance_movement:
		return
	while seconds > 60.0:
		model.advance(60.0)
		seconds -= 60.0
	model.advance(seconds)
