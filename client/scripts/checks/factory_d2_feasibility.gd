extends RefCounted

## Eligibility forecast only. Explicit steps never count as natural-clock scores.
const Codec := preload("res://scripts/factory/save/codec.gd")
const Workload := preload("res://scripts/checks/factory_d2_workload.gd")
var evidence: String
var reasons: Array[String] = []


func _init(folder: String) -> void:
	evidence = folder


func run() -> Dictionary:
	var document: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("candidate.json")))
	var preparation: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("preparation.json")))
	var arms := {}
	for arm in ["B", "O"]:
		arms[arm] = _forecast(document, preparation, arm)
		if not arms[arm].ok: reasons.append_array(arms[arm].reasons)
	return {"status": "feasibility_passed" if reasons.is_empty() else "sample_invalid", "reasons": reasons,
		"execution_mode": "fixed_step_eligibility_forecast", "natural_clock_result": false,
		"skipped_screenshots": true, "arms": arms, "eligibility_forecast_passed": reasons.is_empty(),
		"can_start_long_runs": false, "pending_gates": ["full_receipt_ledger", "natural_clock_driver_and_recovery"]}


func _forecast(document: Dictionary, preparation: Dictionary, arm: String) -> Dictionary:
	var decoded := Codec.decode(document, document.world_id)
	assert(decoded.ok, "feasibility parent must strictly decode")
	var model: RefCounted = decoded.model
	var ids: Dictionary = preparation.ids
	var dispatch: Dictionary = model.by_id(ids.dispatch)
	var g: Dictionary = model.by_id(ids.G)
	var buffer: Dictionary = model.by_id(ids.B)
	var actor: Dictionary = model.actor.duplicate(true)
	model.actor.merge(preparation.approaches.dispatch, true)
	if arm == "O":
		assert(model.configure_dispatch(dispatch.id, "industrial_cell", 120, 10, 1).ok)
		assert(model.configure_storage_feedback(dispatch.id, int(buffer.id), 1100000, 2000000).ok)
	assert(model.set_dispatch_active(dispatch.id, true).ok)
	model.actor.merge(actor, true)
	var workload := Workload.new(model, preparation)
	var boundaries := [_boundary(model, ids)]
	var windows := []
	var local_reasons: Array[String] = []
	var trace := FileAccess.open(evidence.path_join("forecast-" + arm + ".jsonl"), FileAccess.WRITE)
	assert(trace != null)
	var high_ticks := 0
	var low_ticks := 0
	var exhausted_ticks := 0
	var deficit_peak_kw := 0.0
	var min_storage_j: int = buffer.stored_j
	var max_storage_j: int = buffer.stored_j
	var events := []
	for tick in 28800:
		if arm == "O" and tick in [7200, 12000, 21600, 26400]:
			var active: bool = tick in [12000, 26400]
			model.actor.merge(preparation.approaches.dispatch, true)
			assert(model.set_dispatch_active(dispatch.id, active).ok)
			model.actor.merge(actor, true)
			events.append({"tick": tick, "dispatch_active": active, "before": _boundary(model, ids)})
		workload.before_step()
		var before: Dictionary = model.statistics.totals.duplicate(true)
		model.advance(model.STEP, 1)
		workload.after_step()
		var totals: Dictionary = model.statistics.totals
		var kw: float = (totals.requested_kj - before.requested_kj) / model.STEP
		var deficit_kw: float = (totals.deficit_kj - before.deficit_kj) / model.STEP
		if kw > 360.0 + 1e-6: high_ticks += 1
		if tick % 2400 < 1200 and kw < 120.0 - 1e-6: low_ticks += 1
		if g.burn_remaining_ticks == 0 and g.fuel.is_empty(): exhausted_ticks += 1
		deficit_peak_kw = maxf(deficit_peak_kw, deficit_kw)
		min_storage_j = mini(min_storage_j, buffer.stored_j)
		max_storage_j = maxi(max_storage_j, buffer.stored_j)
		trace.store_line(JSON.stringify({"tick": tick + 1, "request_kw": kw, "deficit_kw": deficit_kw,
			"stored_j": buffer.stored_j, "burn_ticks": g.burn_remaining_ticks, "fuel": g.fuel,
			"dispatch_phase": dispatch.phase_ticks, "dispatch_active": dispatch.active, "sent": dispatch.sent,
			"feedback": dispatch.feedback.latch, "totals": totals}, "", true, true))
		if (tick + 1) % 14400 == 0:
			var end := _boundary(model, ids)
			var start: Dictionary = boundaries.back()
			var deltas := {}
			for key in end.totals:
				if end.totals[key] is int or end.totals[key] is float:
					deltas[key] = end.totals[key] - start.totals[key]
			var energy_residual: float = deltas.base_supplied_kj + deltas.fuel_released_kj + start.stored_j / 1000.0 \
				- deltas.used_kj - deltas.spill_kj - deltas.storage_loss_j / 1000.0 - end.stored_j / 1000.0
			var produced_cells: int = end.completed.cell_assembly - start.completed.cell_assembly
			var cell_residual: int = end.stock.get("industrial_cell", 0) - start.stock.get("industrial_cell", 0) - produced_cells + deltas.cells_activated
			var window := {"start_tick": tick + 1 - 14400, "end_tick": tick + 1, "delta": deltas,
				"energy_residual_kj": energy_residual, "cell_residual": cell_residual,
				"high_seconds": high_ticks / 20.0, "low_prepare_seconds": low_ticks / 20.0,
				"fuel_empty_seconds": exhausted_ticks / 20.0, "min_storage_j": min_storage_j, "max_storage_j": max_storage_j,
				"deficit_peak_kw": deficit_peak_kw, "mixed_batches": end.completed.mixed_refining - start.completed.mixed_refining,
				"packs_received": end.terminals.T - start.terminals.T, "direct_received": end.terminals.Td - start.terminals.Td,
				"produced_cells": produced_cells, "overdue": workload.overdue().duplicate(true)}
			windows.append(window)
			boundaries.append(end)
			var label := arm + " window " + str(windows.size()) + ": "
			if not end.balanced or cell_residual != 0 or absf(energy_residual) > 0.001:
				local_reasons.append(label + "ledger mismatch")
			if arm == "B":
				if window.mixed_batches < 24 or window.packs_received < 12 or not window.overdue.is_empty():
					local_reasons.append(label + "production or on-time pack delivery below reference eligibility")
				if window.direct_received == 0 or produced_cells == 0 or high_ticks < 200 or low_ticks < 1200:
					local_reasons.append(label + "branch output or demand shape below reference eligibility")
				if deltas.deficit_kj > 0.001 or deficit_peak_kw > 1e-6:
					local_reasons.append(label + "continuous reference has a real deficit")
			elif deltas.deficit_kj < 100.0:
				local_reasons.append(label + "O fault never reaches the required 100 kJ deficit")
			high_ticks = 0
			low_ticks = 0
			exhausted_ticks = 0
			deficit_peak_kw = 0.0
			min_storage_j = buffer.stored_j
			max_storage_j = buffer.stored_j
	trace.close()
	local_reasons.append_array(workload.errors)
	_write("forecast-" + arm + "-after.json", Codec.snapshot(model, document.world_id, document.name, 1))
	_write("forecast-" + arm + "-orders.json", workload.orders)
	_write("forecast-" + arm + "-commands.json", workload.commands)
	return {"ok": local_reasons.is_empty(), "reasons": local_reasons, "windows": windows, "boundaries": boundaries, "fault_events": events}


func _boundary(model: RefCounted, ids: Dictionary) -> Dictionary:
	var terminals := {}
	for key in ["T", "Td", "Ts", "overflow"]:
		terminals[key] = model.Items.count(model.by_id(ids[key]).items)
	return {"totals": model.statistics.totals.duplicate(true), "stock": model.material_balance().held,
		"balanced": model.material_balance().balanced, "stored_j": model.stored_joules(),
		"burn_ticks": model.by_id(ids.G).burn_remaining_ticks, "fuel": model.by_id(ids.G).fuel.duplicate(),
		"terminals": terminals, "completed": model.completed_by_recipe.duplicate()}


func _write(name: String, data: Variant) -> void:
	var file := FileAccess.open(evidence.path_join(name), FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(data, "", true, true))
