extends RefCounted

const Codec := preload("res://scripts/factory/save/codec.gd")
const Workload := preload("res://scripts/checks/factory_d2_workload.gd")
const Compare := preload("res://scripts/checks/factory_expansion_compare.gd")
var evidence: String
var invalid: Array[String] = []


func _init(folder: String) -> void:
	evidence = folder


func run() -> Dictionary:
	var doc: Dictionary = _read("candidate.json")
	var preparation: Dictionary = _read("preparation.json")
	var decoded := Codec.decode(doc, doc.world_id)
	if not decoded.ok: return {"status": "preflight_error", "reason": decoded.reason}
	var model: RefCounted = decoded.model
	var ids: Dictionary = preparation.ids
	var g: Dictionary = model.by_id(ids.G)
	var buffer: Dictionary = model.by_id(ids.B)
	var dispatch: Dictionary = model.by_id(ids.dispatch)
	if not g.enabled or not buffer.enabled or buffer.load_group.enabled or buffer.load_group.reserve_j != 100000:
		invalid.append("P0 generator, storage or disabled C3 baseline differs")
	if dispatch.active or dispatch.period_s != 120 or dispatch.window_s != 120 or dispatch.quota != 60 or dispatch.feedback.mode != "timed":
		invalid.append("P0 inactive continuous dispatch baseline differs")
	if g.burn_remaining_ticks != 0 or not g.fuel.is_empty() or buffer.stored_j != 0:
		invalid.append("P0 generator or storage is not empty")
	if not dispatch.cargo.is_empty() or dispatch.phase_ticks != 0 or dispatch.sent != 0:
		invalid.append("P0 dispatch is not empty at phase zero")
	for key in Workload.PROCESSORS:
		if model.by_id(ids[key]).processing: invalid.append("P0 in-flight work " + key)
	var held: Dictionary = model.material_balance().held
	for item in preparation.caps:
		if held.get(item, 0) > preparation.caps[item]: invalid.append("P0 stock cap " + item)
	var capacity := capacity_bounds(model, ids, held)
	for row in capacity.values():
		if row.upper_bound >= row.capacity: invalid.append("terminal capacity cannot cover the full horizon: " + row.item)
	# Empty B remains identical; the continuous B arm uses its preconfigured C1.
	var actor: Dictionary = model.actor.duplicate(true)
	model.actor.merge(preparation.approaches.dispatch, true)
	var enabled: Dictionary = model.set_dispatch_active(dispatch.id, true)
	model.actor.merge(actor, true)
	if not enabled.ok: invalid.append(enabled.reason)
	var workload := Workload.new(model, preparation)
	var t0: Dictionary = model.statistics.totals.duplicate(true)
	var completed: Dictionary = model.completed_by_recipe.duplicate()
	var first_batch: int = model.next_batch
	var received_mixed := 0
	var high_ticks := 0
	var low_ticks := 0
	var peak_kw := 0.0
	var core_inlets: Array[Dictionary] = []
	for port in model.Logistics.ports(model, model.core, "input"):
		var connection: Dictionary = model.Logistics.input_connection(model, model.core, port)
		if connection.ok: core_inlets.append(connection.source)
	var trace := FileAccess.open(evidence.path_join("preflight-steps.jsonl"), FileAccess.WRITE)
	var start_doc := Codec.snapshot(model, doc.world_id, "D2 preflight", 1)
	var reference: RefCounted = Codec.decode(start_doc, doc.world_id).model
	var reference_workload := Workload.new(reference, preparation)
	for tick in 4800:
		workload.before_step()
		var arrivals := []
		for belt in core_inlets:
			if belt.get("cargo", "") == "metal_plate" and belt.get("batch", 0) >= first_batch and model.batch_recipes.get(str(belt.batch), "") == "mixed_refining":
				arrivals.append({"id": belt.id, "batch": belt.batch})
		var query_before := {}
		if tick == 0: query_before = Codec.snapshot(model, doc.world_id, "query", 1)
		model.power_state()
		model.load_group_budget(buffer)
		if tick == 0 and not Compare.equivalent(query_before, Codec.snapshot(model, doc.world_id, "query", 1)):
			invalid.append("queries change the saved world")
		var energy_before: float = model.statistics.totals.requested_kj
		model.advance(model.STEP, 1)
		workload.after_step()
		var kw: float = (model.statistics.totals.requested_kj - energy_before) / model.STEP
		peak_kw = maxf(peak_kw, kw)
		if kw > 360.0 + 1e-6: high_ticks += 1
		if tick % 2400 < 1200 and kw < 120.0 - 1e-6: low_ticks += 1
		for arrival in arrivals:
			if model.by_id(arrival.id).cargo.is_empty(): received_mixed += 1
		var row := {"tick": tick + 1, "request_kw": kw, "mixed_core_received": received_mixed,
			"orders_received": workload.orders.filter(func(o): return o.received >= 0).size(),
			"stored_j": buffer.stored_j, "fuel_ticks": g.burn_remaining_ticks,
			"machines": {}, "totals": model.statistics.totals.duplicate(true)}
		for key in Workload.PROCESSORS:
			var e: Dictionary = model.by_id(ids[key])
			row.machines[key] = {"enabled": e.enabled, "processing": e.processing, "progress": e.progress,
				"input": e.input.duplicate(), "output": e.output.duplicate(), "batch": e.active_batch}
		trace.store_line(JSON.stringify(row, "", true, true))
		if tick < 600:
			reference_workload.before_step()
			reference.advance(reference.STEP, 1)
			reference_workload.after_step()
			if tick == 599 and not Compare.equivalent(Codec.snapshot(reference, doc.world_id, "compare", 1), Codec.snapshot(model, doc.world_id, "compare", 1)):
				invalid.append("600-step observed and unobserved trajectories differ")
	trace.close()
	invalid.append_array(workload.errors)
	var mixed: int = model.completed_by_recipe.mixed_refining - completed.mixed_refining
	var packs: int = workload.orders.filter(func(o): return o.received >= 0).size()
	if mixed < 8: invalid.append("two-cycle reference completes fewer than eight R08 batches")
	if received_mixed < 8: invalid.append("two-cycle reference receives fewer than eight new mixed plates at core")
	if packs != 4 or not workload.overdue().is_empty(): invalid.append("two-cycle reference misses on-time delivery of four construction packs")
	if high_ticks == 0: invalid.append("reference never forms a real demand peak above 360 kW")
	var totals: Dictionary = model.statistics.totals
	var deficit: float = totals.deficit_kj - t0.deficit_kj
	if deficit > 0.001: invalid.append("continuous reference has a real power deficit")
	if not model.material_balance().balanced: invalid.append("material ledger mismatch")
	var residual: float = (totals.base_supplied_kj - t0.base_supplied_kj) + (totals.fuel_released_kj - t0.fuel_released_kj) \
		- (totals.used_kj - t0.used_kj) - (totals.spill_kj - t0.spill_kj) - (totals.storage_loss_j - t0.storage_loss_j) / 1000.0 - buffer.stored_j / 1000.0
	if absf(residual) > 0.001: invalid.append("energy ledger mismatch")
	_write("after.json", Codec.snapshot(model, doc.world_id, "preflight after", 1))
	_write("commands.json", workload.commands)
	_write("orders.json", workload.orders)
	var result := {"status": "preflight_passed" if invalid.is_empty() else "sample_invalid", "reasons": invalid,
		"mode": "fixed_step_preflight_only", "seconds": 240, "mixed_batches": mixed, "mixed_core_received": received_mixed,
		"packs_received": packs, "overdue": workload.overdue(), "peak_kw": peak_kw, "high_seconds": high_ticks / 20.0,
		"low_prepare_seconds": low_ticks / 20.0, "deficit_kj": deficit, "energy_residual_kj": residual,
		"initial_stock": held, "final_stock": model.material_balance().held, "observed_ticks": 600,
		"capacity_bounds": capacity, "two_cycle_checks_passed": invalid.is_empty(),
		"can_start_long_runs": false, "pending_gates": ["fault_feasibility", "natural_clock_driver_and_recovery"]}
	return result


static func capacity_bounds(model: RefCounted, ids: Dictionary, held: Dictionary) -> Dictionary:
	# Count every existing physical item as if it could arrive at this terminal.
	# Each processor gets a conservative extra tail batch every period. No
	# routing ratio or expected shortage is used to make a warehouse fit.
	var result := {}
	for key in ["T", "Td", "Ts", "overflow"]:
		var item: String = {"T": "construction_pack", "Td": "metal_plate", "Ts": "mineral_slag", "overflow": "industrial_cell"}[key]
		var machine: String = {"T": "A", "Td": "Fd", "Ts": "F", "overflow": "E"}[key]
		var recipe: Dictionary = model.recipes[model.by_id(ids[machine]).recipe_id]
		var opportunities := 25.0 if key == "Td" else 60.0
		var batches := 24 if key == "T" else 12 * (ceili(opportunities / recipe.seconds) + 1)
		var existing: int = held.get(item, 0)
		var terminal: Dictionary = model.by_id(ids[key])
		result[key] = {"item": item, "initial_world_stock": existing, "new_output_upper_bound": batches * recipe.output[item],
			"upper_bound": existing + batches * recipe.output[item],
			"capacity": model.Items.count(terminal.items) + model.input_room(terminal, item), "horizon_seconds": 1440}
	return result


func _read(file: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join(file)))


func _write(file: String, data: Variant) -> void:
	var handle := FileAccess.open(evidence.path_join(file), FileAccess.WRITE)
	assert(handle != null)
	handle.store_string(JSON.stringify(data, "", true, true))
