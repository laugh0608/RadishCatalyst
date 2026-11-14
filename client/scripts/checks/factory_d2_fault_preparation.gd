extends "res://scripts/checks/factory_integrated_first_route.gd"

const Store := preload("res://scripts/factory/save/store.gd")
const Compare := preload("res://scripts/checks/factory_expansion_compare.gd")
const D2Preparation := preload("res://scripts/checks/factory_d2_preparation.gd")
const CARRIER := "porous_carrier"
const SPLIT := Vector2i(-13, 13)
const WAREHOUSE := Vector2i(-13, 10)
const BRANCH: Array[Vector2i] = [Vector2i(-13, 12), Vector2i(-14, 12), Vector2i(-14, 11)]


static func run(folder: String, source: Dictionary, manifest: Dictionary) -> Dictionary:
	var store := Store.new(folder.path_join("factory"), false, false, true)
	var candidate := store.prepare(source.world_id)
	assert(candidate.ok, str(candidate.get("reason", "")))
	assert(store.accept(candidate).ok)
	var route := new(candidate.model, {})
	route.advance_movement = false
	var source_state := Store.Codec.snapshot(route.model, source.world_id, source.name, int(source.sequence))
	assert(Compare.equivalent(source, source_state, "original P0 Store copy"))
	var construction := route.build_carrier_branch(manifest)
	_write(folder, "derivation.json", construction)
	if not construction.ok:
		assert(store.release().ok)
		return {"status": "fault_v4_preparation_invalid", "reason": construction.reason}
	var saved := store.save(route.model)
	assert(saved.ok, str(saved.get("reason", "")))
	assert(store.release().ok)
	var frozen := store.find_candidate(source.world_id)
	assert(frozen.ok and frozen.source.ends_with("/autosave.json"))
	var proof := _prove_carrier_route(frozen.model, manifest)
	# The proof consumes a decoded copy. The published Store file is still the cold candidate.
	assert(FileAccess.get_sha256(frozen.source) == frozen.hash)
	_write(folder, "carrier-proof-trace.json", proof)
	if not proof.ok:
		return {"status": "fault_v4_preparation_invalid", "reason": proof.reason}
	_write(folder, "candidate.json", frozen.document)
	_write(folder, "preparation.json", manifest)
	proof.candidate_sha256 = FileAccess.get_sha256(folder.path_join("candidate.json"))
	_write(folder, "carrier-proof.json", proof)
	return {"status": "fault_v4_prepared", "proof": proof}


func build_carrier_branch(manifest: Dictionary) -> Dictionary:
	var ids: Dictionary = manifest.ids
	var start: int = model.statistics.ticks
	var start_held: Dictionary = model.material_balance().held
	var start_kits: int = model.kits.belt
	var a: Dictionary = model.by_id(ids.A)
	var f2: Dictionary = model.by_id(ids.F2)
	var old_belt: Dictionary = model.entity_at(SPLIT).duplicate(true)
	if old_belt.get("type") != "belt" or old_belt.cargo != CARRIER:
		return {"ok": false, "reason": "P0 carrier belt or its original cargo differs"}
	var cost: int = model.assembly_costs.splitter + model.assembly_costs.storage
	var terminal: Dictionary = model.by_id(ids.T)
	walk_near(terminal)
	stock(terminal, "construction_pack", cost, false)
	walk_near(model.core)
	stock(model.core, "construction_pack", cost, true)
	_must(model.assemble("splitter"))
	_must(model.assemble("storage"))
	walk_near(a)
	var split_result := _must(model.place("splitter", SPLIT, 0, model.actor))
	# The placement transaction returned the old belt cargo to the bag.
	# Bags have no batch reference, so retire its now-unreferenced batch.
	model.prune_batches()
	var split: Dictionary = split_result.entity
	walk_to(Vector2(-12.5, 12.5))
	var warehouse: Dictionary = _must(model.place("storage", WAREHOUSE, 0, model.actor)).entity
	var belts: Array = _must(model.place_path(BRANCH, 0, WAREHOUSE + Vector2i.DOWN)).entities
	var path_ids: Array = [split.id]
	for belt in belts:
		path_ids.append(belt.id)
	path_ids.append(warehouse.id)
	manifest.carrier_branch = {"path_ids": path_ids, "warehouse_id": warehouse.id, "split_id": split.id,
		"assembly_packs": cost, "belt_count": BRANCH.size(), "replaced_belt": old_belt.id,
		"recovered_items": split_result.recovered_items}
	for key in ids:
		walk_near(model.by_id(ids[key]))
		manifest.approaches[key] = {"x": model.actor.x, "z": model.actor.z}
	walk_near(model.by_id(ids.B))
	var balance: Dictionary = model.material_balance()
	var expected := start_held.duplicate()
	model.Items.add(expected, "construction_pack", -cost)
	var links := [_connected(f2, split), _connected(split, a)]
	for i in path_ids.size() - 1:
		links.append(_connected(model.by_id(path_ids[i]), model.by_id(path_ids[i + 1])))
	var maximum: int = 12 * (ceili(60.0 / model.recipes[f2.recipe_id].seconds) + 1) * model.recipes[f2.recipe_id].output[CARRIER]
	var total_bound: int = maximum + balance.held.get(CARRIER, 0)
	var capacity: int = model.input_room(warehouse, CARRIER)
	var caps_ok := true
	for item in D2Preparation.CAPS:
		caps_ok = caps_ok and balance.held.get(item, 0) <= D2Preparation.CAPS[item]
	var checks := {"links": not links.has(false), "balance": balance.balanced,
		"stock": Compare.equivalent(expected, balance.held), "caps": caps_ok, "capacity": total_bound < capacity,
		"clock": model.statistics.ticks == start, "belt_replaced": split_result.replaced_belt == old_belt.id,
		"carrier_recovered": split_result.recovered_items == {CARRIER: 1},
		"belt_count": model.kits.belt == start_kits + 1 - BRANCH.size()}
	var ok := not checks.values().has(false)
	manifest.held = balance.held
	manifest.balanced = balance.balanced
	return {"ok": ok, "reason": "" if ok else "derived topology, cost, stock, capacity or frozen time differs",
		"branch": manifest.carrier_branch, "checks": checks, "links": links, "before_stock": start_held, "after_stock": balance.held,
		"carrier_capacity_bound": total_bound, "carrier_capacity": capacity, "simulation_ticks": model.statistics.ticks - start}


func _connected(source: Dictionary, target: Dictionary) -> bool:
	for port in model.Logistics.ports(model, source, "output"):
		var link: Dictionary = model.Logistics.output_connection(model, port)
		if link.ok and link.target.id == target.id:
			return true
	return false


static func _prove_carrier_route(world: RefCounted, manifest: Dictionary) -> Dictionary:
	var a: Dictionary = world.by_id(manifest.ids.A)
	var f2: Dictionary = world.by_id(manifest.ids.F2)
	var split: Dictionary = world.by_id(manifest.carrier_branch.split_id)
	var warehouse: Dictionary = world.by_id(manifest.carrier_branch.warehouse_id)
	var route := new(world, {})
	route.advance_movement = false
	route.walk_near(f2)
	assert(not a.enabled and not a.processing and world.input_room(a, CARRIER) == 0)
	assert(world.set_device_enabled(f2.id, true).ok)
	var mixed_furnace: Dictionary = world.by_id(manifest.ids.F)
	route.walk_near(mixed_furnace)
	assert(world.set_device_enabled(mixed_furnace.id, true).ok)
	var initial_batch: int = world.next_batch
	var first_exit := -1
	var second_start := -1
	var warehouse_tick := -1
	var first_exit_batch := 0
	var a_enabled_tick := -1
	var a_start_tick := -1
	var a_refill_tick := -1
	var a_refill_batch := 0
	var events := []
	for tick in range(1, 60 * 20 + 1):
		var before_f2: int = f2.active_batch
		var before_carriers: int = a.input.get(CARRIER, 0)
		var before_split_batch: int = split.batch
		var before_warehouse: int = warehouse.items.get(CARRIER, 0)
		var before_a: bool = a.processing
		world.advance(world.STEP, 1)
		if a_enabled_tick < 0:
			assert(not a.processing and world.input_room(a, CARRIER) == 0)
			if first_exit < 0 and split.batch >= initial_batch and split.cargo == CARRIER:
				first_exit = tick
				first_exit_batch = split.batch
				events.append({"tick": tick, "event": "f2_to_splitter", "batch": first_exit_batch})
			if second_start < 0 and first_exit >= 0 and f2.active_batch > first_exit_batch and f2.active_batch != before_f2:
				second_start = tick
				events.append({"tick": tick, "event": "f2_restarted_with_a_full", "batch": f2.active_batch})
			if warehouse_tick < 0 and warehouse.items.get(CARRIER, 0) > before_warehouse:
				warehouse_tick = tick
				events.append({"tick": tick, "event": "carrier_overflow_receipt"})
			if second_start >= 0 and warehouse_tick >= 0:
				route.walk_near(a)
				assert(world.set_device_enabled(a.id, true).ok)
				a_enabled_tick = tick
		else:
			var started: bool = not before_a and a.processing
			if a_start_tick < 0 and started:
				a_start_tick = tick
				events.append({"tick": tick, "event": "a_consumed_carrier", "batch": a.active_batch})
			if a_start_tick >= 0 and a.input.get(CARRIER, 0) > before_carriers - int(started):
				a_refill_tick = tick
				a_refill_batch = before_split_batch
				events.append({"tick": tick, "event": "carrier_refilled_a", "batch": a_refill_batch})
				break
	var ok: bool = (first_exit > 0 and second_start > first_exit and warehouse_tick > first_exit
		and a_start_tick > a_enabled_tick and a_refill_tick >= a_start_tick and a_refill_batch >= initial_batch
		and world.material_balance().balanced)
	return {"ok": ok, "reason": "" if ok else "F2 overflow, restart, A consumption or carrier refill was not proven",
		"f2_exit_tick": first_exit, "f2_restart_tick": second_start, "overflow_tick": warehouse_tick,
		"a_enabled_after_tick": a_enabled_tick, "a_start_tick": a_start_tick, "a_refill_tick": a_refill_tick,
		"a_refill_batch": a_refill_batch, "events": events, "fixed_step_only": true}


static func _write(folder: String, name: String, value: Variant) -> void:
	var file := FileAccess.open(folder.path_join(name), FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(value, "", true, true))
	assert(file.get_error() == OK)
