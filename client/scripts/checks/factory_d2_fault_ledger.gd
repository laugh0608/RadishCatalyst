extends RefCounted

const TRACKED := {"core": "metal_plate", "A": "metal_plate", "T": "construction_pack",
	"Td": "metal_plate", "Ts": "mineral_slag", "overflow": "industrial_cell"}
const ROUTES := {"core": ["mixed_refining", "R08_core"], "A": ["mixed_refining", "R08_to_A"],
	"T": ["construction_assembly", "R11_T"], "Td": ["direct_refining", "Fd_Td"],
	"Ts": ["mixed_refining", "slag_Ts"], "overflow": ["cell_assembly", "cells_overflow"]}
const WATCHED := ["I", "Q", "K", "Kh", "C", "Ci", "F", "F2", "Fd", "R", "E", "A"]
const FAULT_START := [2400, 14400]
const REOPEN := [12000, 26400]
const WINDOW := 14400
const RECOVERY_TICKS := 2400
const CELL := "industrial_cell"
const CARRIER := "porous_carrier"
enum Reason {STOPPED = 1, CONTROL = 2, MATERIAL = 4, OUTPUT = 8, UNDERPOWER = 16, IN_FLIGHT = 32, NO_POWER = 64}

var model: RefCounted
var ids: Dictionary
var arm: String
var record_a_state: bool
var trace: FileAccess
var steps := 0
var first_batch: int
var inlets := {}
var inlet_candidates := {}
var events: Array[Dictionary] = []
var errors: Array[String] = []
var receipts := {}
var old_receipts := {}
var blocked_ticks := 0
var continued_finishes := 0
var control_restarts := 0
var waiting_for_restart := false
var control_transition := false
var fault_deficit := 0.0
var fault_exhausted_ticks := 0
var fuel_exhaustion_ticks: Array[int] = []
var recovery := {}
var terminal_full := false
var peak_request_kw := 0.0
var peak_deficit_kw := 0.0
var reason_counts := {}
var primary_reason_counts := {}
var budget := {}
var before := {}
var supply_before := {}
var power_before := {}
var stock_input_max := {}
var a_before := {}
var carrier_branch: Dictionary
var carrier_before := {}
var carrier_receipts := {}
var last_deficit_kw := 0.0
var measure_uncontrolled_recovery := false
var measure_interlocks := false


func _init(world: RefCounted, role_ids: Dictionary, folder: String, arm_name: String, record_assembler := false,
		branch: Dictionary = {}) -> void:
	model = world
	ids = role_ids
	arm = arm_name
	record_a_state = record_assembler
	carrier_branch = branch
	first_batch = model.next_batch
	trace = FileAccess.open(folder.path_join(arm + "-steps.jsonl"), FileAccess.WRITE)
	assert(trace != null, "cannot open D2 trace")
	for key in TRACKED:
		var target: Dictionary = model.by_id(ids[key])
		inlets[key] = []
		for port in model.Logistics.ports(model, target, "input"):
			var connection: Dictionary = model.Logistics.input_connection(model, target, port)
			if connection.ok:
				inlets[key].append(connection.source)
	for item in ["iron_powder", "carbon_powder", "catalyst", "metal_plate", "porous_carrier"]:
		stock_input_max[item] = 0
		for e in model.entities:
			if e.type in model.process_types:
				stock_input_max[item] = maxi(stock_input_max[item], model.recipes[e.recipe_id].input.get(item, 0))
	_reset_window()


func supply_state() -> Dictionary:
	var dispatch: Dictionary = model.by_id(ids.dispatch)
	var g: Dictionary = model.by_id(ids.G)
	var buffer: Dictionary = model.by_id(ids.B)
	return {"active": dispatch.active, "phase_ticks": dispatch.phase_ticks, "sent": dispatch.sent,
		"feedback": dispatch.feedback.latch, "cargo": dispatch.cargo, "progress": dispatch.progress,
		"burn_ticks": g.burn_remaining_ticks, "fuel": g.fuel.duplicate(), "stored_j": buffer.stored_j}


func before_step(tick: int) -> void:
	var group: Dictionary = model.by_id(ids.B).load_group
	var supply := supply_state()
	supply_before = supply
	budget = model.load_group_budget(model.by_id(ids.B)) if group.evaluation_ticks_left == 0 else {}
	power_before = {"request": model.statistics.totals.requested_kj,
		"deficit": model.statistics.totals.deficit_kj, "supplied": model.statistics.totals.supplied_kj, "activation": model.statistics.totals.cells_activated,
		"fuel_released": model.statistics.totals.fuel_released_kj, "latch": group.latch,
		"evaluation_ticks_left": group.evaluation_ticks_left}
	# All tracked transport inlets have one output and cannot refill in the
	# same step. T is direct from A and is reconciled against its item delta.
	inlet_candidates.clear()
	for key in TRACKED:
		var item: String = TRACKED[key]
		var target: Dictionary = model.by_id(ids[key])
		inlet_candidates[key] = []
		for source in inlets[key]:
			if model.Logistics.transport(source) and source.cargo == item:
				inlet_candidates[key].append(_candidate(source, source.batch))
			elif key == "T" and source.id == ids.A:
				var batch: int = source.output_batch if source.output.has(item) else source.active_batch
				inlet_candidates[key].append(_candidate(source, batch))
		if key in ["T", "Td", "Ts", "overflow"] and model.input_room(target, item) <= 0:
			terminal_full = true
	before.clear()
	for key in WATCHED:
		var e: Dictionary = model.by_id(ids[key])
		var reason := 0
		if not e.enabled:
			reason |= Reason.STOPPED
		if e.get("processing", false):
			reason |= Reason.IN_FLIGHT
		elif model.process_types.has(e.type):
			if not e.output.is_empty():
				reason |= Reason.OUTPUT
			if not model.Items.contains(e.input, model.recipes[e.recipe_id].input):
				reason |= Reason.MATERIAL
		elif model.Items.count(e.buffer) >= 50:
			reason |= Reason.OUTPUT
		before[key] = {"reason": reason, "batch": e.get("active_batch", 0)}
	before.T = model.by_id(ids.T).items.get("construction_pack", 0)
	if record_a_state:
		var assembler: Dictionary = model.by_id(ids.A)
		a_before = {"enabled": assembler.enabled, "processing": assembler.processing,
			"ready_without_control": not assembler.processing and model.uncontrolled_work_spec(assembler).ready,
			"input": assembler.input.duplicate(), "output": assembler.output.duplicate(),
			"evaluation_ticks_left": group.evaluation_ticks_left}
	if not carrier_branch.is_empty():
		var f2: Dictionary = model.by_id(ids.F2)
		var split: Dictionary = model.by_id(carrier_branch.split_id)
		var tail: Dictionary = model.by_id(carrier_branch.path_ids[-2])
		var warehouse: Dictionary = model.by_id(carrier_branch.warehouse_id)
		carrier_before = {"f2_batch": f2.active_batch, "split_batch": split.batch, "tail_batch": tail.batch,
			"warehouse": warehouse.items.get(CARRIER, 0), "a_input": model.by_id(ids.A).input.get(CARRIER, 0)}
		terminal_full = terminal_full or model.input_room(warehouse, CARRIER) <= 0
	if tick in REOPEN:
		recovery.start_tick = tick
		recovery.deadline = tick + RECOVERY_TICKS


func after_step(tick: int, orders: Array) -> void:
	steps = tick
	var index := 0 if tick <= WINDOW else 1
	var supply := supply_state()
	var totals: Dictionary = model.statistics.totals
	var group: Dictionary = model.by_id(ids.B).load_group
	var request: float = (totals.requested_kj - power_before.request) / model.STEP
	var deficit: float = totals.deficit_kj - power_before.deficit
	last_deficit_kw = deficit / model.STEP
	peak_request_kw = maxf(peak_request_kw, request)
	peak_deficit_kw = maxf(peak_deficit_kw, deficit / model.STEP)
	var activation: bool = totals.cells_activated > power_before.activation
	var fuel_released: bool = totals.fuel_released_kj > power_before.fuel_released
	control_transition = group.latch != power_before.latch
	if supply.phase_ticks == 0 and supply_before.phase_ticks != 0:
		_event(tick, "dispatch_window_open", supply)
	if supply.active and supply.phase_ticks == 1 and supply_before.phase_ticks == 0 and tick == 1201:
		_event(tick - 1, "initial_dispatch_window_open", supply_before)
	if supply.sent > supply_before.sent:
		_event(tick, "dispatch_sent", supply)
	if activation:
		_event(tick, "generator_activation", supply)
		if tick > REOPEN[index] and recovery.activation_tick == -1:
			recovery.activation_tick = tick
	if supply_before.burn_ticks > 0 and supply.burn_ticks == 0:
		_event(tick, "generator_exhausted", supply)
		if tick > FAULT_START[index] and recovery.activation_tick == -1:
			fuel_exhaustion_ticks.append(tick)
	if tick > FAULT_START[index] and recovery.activation_tick == -1:
		fault_deficit += deficit
		if not fuel_released and supply_before.fuel.is_empty() and supply_before.burn_ticks == 0:
			fault_exhausted_ticks += 1
	if control_transition:
		_event(tick, "control_latch", {"before": power_before.latch, "after": group.latch, "budget": budget})
	var assembler: Dictionary = model.by_id(ids.A)
	var previous_batch: int = before.A.batch
	var a_ready: bool = before.A.reason == 0
	var interlock_reason: String = model.start_interlock_reason(assembler.id) if measure_interlocks and a_ready else ""
	var blocked: bool = group.enabled and (group.latch != "allow" or not interlock_reason.is_empty()) and a_ready
	if blocked:
		blocked_ticks += 1
		if not waiting_for_restart:
			_event(tick, "controlled_start_blocked", {"latch": group.latch, "budget": budget})
		waiting_for_restart = true
	if previous_batch > 0 and not assembler.processing:
		continued_finishes += 1
		_event(tick, "assembly_finished", {"batch": previous_batch, "latch": group.latch})
	if previous_batch == 0 and assembler.processing:
		var batch: int = assembler.active_batch
		_event(tick, "assembly_started", {"batch": batch, "latch": group.latch, "following_block": waiting_for_restart})
		if waiting_for_restart:
			control_restarts += 1
			waiting_for_restart = false
		if (group.enabled or measure_uncontrolled_recovery) and recovery.start_tick >= 0 and tick <= recovery.deadline:
			recovery.started_batches[str(batch)] = tick
	var handoffs := _observe_receipts(tick, orders)
	if not carrier_branch.is_empty():
		_observe_carriers(tick, previous_batch == 0 and assembler.processing, handoffs)
	var reasons := {}
	for key in WATCHED:
		var reason: int = before[key].reason
		if key == "A" and blocked:
			reason |= Reason.CONTROL
		# P0 asserts a single core network. Any requested work on that
		# network receives the same allocation fraction in this step.
		if reason & (Reason.STOPPED | Reason.CONTROL | Reason.MATERIAL | Reason.OUTPUT) == 0 and deficit > 1e-6 * model.STEP:
			reason |= Reason.NO_POWER if totals.supplied_kj == power_before.supplied else Reason.UNDERPOWER
		reasons[key] = reason
		var counts: Dictionary = reason_counts.get_or_add(key, {})
		var bit := str(reason)
		counts[bit] = counts.get(bit, 0) + 1
		var primary := str(_primary_reason(reason))
		var primary_counts: Dictionary = primary_reason_counts.get_or_add(key, {})
		primary_counts[primary] = primary_counts.get(primary, 0) + 1
	var row := {"tick": tick, "request_kw": request, "deficit_kw": deficit / model.STEP,
		"supply": supply, "c3_latch": group.latch, "c3_evaluation_ticks_left": group.evaluation_ticks_left,
		"candidate_budget": budget, "reasons": reasons, "a_batch": assembler.active_batch, "receipts": handoffs}
	if measure_interlocks:
		row.interlock_reason = interlock_reason
	if record_a_state:
		row.a_before = a_before
	if tick % 20 == 0:
		row.inventory = model.material_balance().held
		row.orders_delivered = orders.filter(func(o): return o.received >= 0).size()
		row.orders_outstanding = orders.size() - row.orders_delivered
	trace.store_line(JSON.stringify(row, "", true, true))


func _primary_reason(reason: int) -> int:
	for flag in [Reason.STOPPED, Reason.CONTROL, Reason.MATERIAL, Reason.OUTPUT, Reason.NO_POWER, Reason.UNDERPOWER, Reason.IN_FLIGHT]:
		if reason & flag:
			return flag
	return 0


func _observe_carriers(tick: int, a_started: bool, handoffs: Array[Dictionary]) -> void:
	var f2: Dictionary = model.by_id(ids.F2)
	var split: Dictionary = model.by_id(carrier_branch.split_id)
	var warehouse: Dictionary = model.by_id(carrier_branch.warehouse_id)
	var assembler: Dictionary = model.by_id(ids.A)
	if split.batch > 0 and split.batch != carrier_before.split_batch:
		_event(tick, "f2_to_carrier_splitter", {"batch": split.batch, "source_id": f2.id, "target_id": split.id})
	if f2.active_batch > 0 and carrier_before.f2_batch == 0:
		_event(tick, "f2_started", {"batch": f2.active_batch})
	if assembler.input.get(CARRIER, 0) > carrier_before.a_input - int(a_started):
		_record_carrier_handoff(tick, "F2_to_A", carrier_before.split_batch, split.id, assembler.id, handoffs)
	if warehouse.items.get(CARRIER, 0) > carrier_before.warehouse:
		_record_carrier_handoff(tick, "F2_overflow", carrier_before.tail_batch, carrier_branch.path_ids[-2], warehouse.id, handoffs)


func _record_carrier_handoff(tick: int, role: String, batch: int, source: int, target: int, handoffs: Array[Dictionary]) -> void:
	var event := {"batch": batch, "source_id": source, "target_id": target, "item": CARRIER,
		"recipe": "direct_sintering", "new_since_p0": batch >= first_batch}
	if batch <= 0:
		errors.append("%s tick %d: %s carrier receipt missing batch" % [arm, tick, role])
	carrier_receipts[role] += 1
	handoffs.append(event)
	_event(tick, role, event)


func _candidate(source: Dictionary, batch: int) -> Dictionary:
	return {"source": source, "batch": batch, "recipe": model.batch_recipes.get(str(batch), "")}


func _observe_receipts(tick: int, orders: Array) -> Array[Dictionary]:
	var handoffs: Array[Dictionary] = []
	for key in TRACKED:
		for candidate in inlet_candidates[key]:
			var source: Dictionary = candidate.source
			var handed_over: bool = source.cargo.is_empty() if model.Logistics.transport(source) \
			else model.by_id(ids.T).items.get("construction_pack", 0) > before.T
			if not handed_over:
				continue
			var batch: int = candidate.batch
			var expected: Array = ROUTES[key]
			var current: bool = batch >= first_batch and candidate.recipe == expected[0]
			var counts := receipts if current else old_receipts
			counts[expected[1]] += 1
			handoffs.append({"source_id": source.id, "target_id": ids[key], "item": TRACKED[key], "batch": batch,
				"recipe": candidate.recipe, "new_since_p0": current})
			if current and key == "T":
				var matches := orders.filter(func(order): return order.batch == batch and order.received == tick)
				if matches.size() != 1:
					errors.append("%s T receipt at %d does not match R11 order for batch %d" % [arm, tick, batch])
				var started: int = recovery.started_batches.get(str(batch), -1)
				if started > recovery.start_tick and recovery.received_tick == -1 and tick <= recovery.deadline:
					recovery.started_tick = started
					recovery.received_tick = tick
					recovery.batch = batch
	return handoffs


func boundary() -> Dictionary:
	var in_flight := {}
	var terminals := {}
	var route_stock := {}
	for key in TRACKED:
		route_stock[ROUTES[key][1]] = 0
	for e in model.entities:
		if model.Logistics.transport(e) and e.batch >= first_batch:
			var recipe: String = model.batch_recipes.get(str(e.batch), "")
			if recipe == "mixed_refining" and e.cargo == "metal_plate":
				route_stock.R08_core += 1
			elif recipe == "mixed_refining" and e.cargo == "mineral_slag":
				route_stock.slag_Ts += 1
			elif recipe == "direct_refining" and e.cargo == "metal_plate":
				route_stock.Fd_Td += 1
			elif recipe == "construction_assembly" and e.cargo == "construction_pack":
				route_stock.R11_T += 1
		elif e.type in model.process_types:
			model.Items.merge(in_flight, e.invested)
			if e.output_batch >= first_batch:
				if e.id == ids.F:
					route_stock.R08_core += e.output.get("metal_plate", 0)
					route_stock.slag_Ts += e.output.get("mineral_slag", 0)
				elif e.id == ids.Fd:
					route_stock.Fd_Td += e.output.get("metal_plate", 0)
				elif e.id == ids.A:
					route_stock.R11_T += e.output.get("construction_pack", 0)
	for key in ["T", "Td", "Ts", "overflow"]:
		terminals[key] = model.Items.count(model.by_id(ids[key]).items)
	if not carrier_branch.is_empty():
		terminals.carrier_overflow = model.by_id(carrier_branch.warehouse_id).items.get(CARRIER, 0)
		var buffered: int = model.by_id(ids.F2).output.get(CARRIER, 0)
		for id in carrier_branch.path_ids.slice(0, -1):
			buffered += int(model.by_id(id).cargo == CARRIER)
		route_stock.carrier = buffered
	return {"tick": steps, "totals": model.statistics.totals.duplicate(true), "material": model.material_balance(),
		"in_flight_inputs": in_flight, "completed": model.completed_by_recipe.duplicate(), "terminals": terminals,
		"route_stock": route_stock, "supply": supply_state()}


func close_window(start: Dictionary, end: Dictionary, overdue: Array) -> Dictionary:
	var delta := {}
	for key in model.statistics.energy_keys() + model.statistics.count_keys():
		delta[key] = end.totals[key] - start.totals[key]
	for key in model.statistics.MATERIAL:
		delta[key] = _diff(start.totals[key], end.totals[key])
	var completed := _diff(start.completed, end.completed)
	var stock_change := _diff(start.material.held, end.material.held)
	var s0: int = start.supply.stored_j
	var s1: int = end.supply.stored_j
	var r0: int = start.supply.burn_ticks
	var r1: int = end.supply.burn_ticks
	var energy_residual: float = delta.base_supplied_kj + delta.fuel_released_kj - delta.used_kj - delta.spill_kj \
			- delta.discarded_kj + (s0 - s1 - delta.storage_loss_j - delta.storage_discarded_j) / 1000.0
	var c_burn: float = delta.cells_activated + (r0 - r1) / 1200.0
	var c_adjusted: float = c_burn + (s0 - s1) / 7200000.0
	var cells_produced: int = delta.produced.get(CELL, 0)
	var cell_residual: int = stock_change.get(CELL, 0) - cells_produced + delta.cells_activated
	var route_change := _diff(start.route_stock, end.route_stock)
	_check_receipts(start, end, completed, route_change)
	recovery.passed = recovery.started_tick > recovery.start_tick and recovery.received_tick >= recovery.started_tick \
			and recovery.received_tick <= recovery.deadline
	var window := {"start_tick": start.tick, "end_tick": end.tick, "delta": delta, "completed": completed,
		"receipts": receipts, "other_receipts": old_receipts, "stock_change": stock_change, "max_batch_input": stock_input_max,
		"balanced": start.material.balanced and end.material.balanced, "energy_residual_kj": energy_residual,
		"cell_residual": cell_residual, "c_burn": c_burn, "c_adjusted": c_adjusted,
		"burn_residual_kj": c_burn * 7200.0 - delta.fuel_released_kj,
		"terminal_full": terminal_full, "deficit_kj": delta.deficit_kj, "fault_deficit_kj": fault_deficit,
		"fault_exhausted_ticks": fault_exhausted_ticks, "fuel_exhaustion_ticks": fuel_exhaustion_ticks,
		"blocked_ticks": blocked_ticks, "continued_finishes": continued_finishes, "control_restarts": control_restarts,
		"recovery": recovery, "overdue": overdue.duplicate(true), "reason_counts": reason_counts,
		"primary_reason_counts": primary_reason_counts}
	if record_a_state:
		window.merge({"peak_request_kw": peak_request_kw, "peak_deficit_kw": peak_deficit_kw})
	if not carrier_branch.is_empty():
		window.carrier_receipts = carrier_receipts
		var produced: int = delta.produced.get(CARRIER, 0)
		if produced != route_change.carrier + carrier_receipts.F2_to_A + carrier_receipts.F2_overflow:
			errors.append("%s tick %d: carrier production, route stock and receipts differ" % [arm, end.tick])
		if carrier_receipts.F2_overflow != end.terminals.carrier_overflow - start.terminals.carrier_overflow:
			errors.append("%s tick %d: carrier warehouse receipts differ" % [arm, end.tick])
	_reset_window()
	return window


func _check_receipts(start: Dictionary, end: Dictionary, completed: Dictionary, route_change: Dictionary) -> void:
	for entry in [["R08_core", "mixed_refining", "metal_plate"], ["slag_Ts", "mixed_refining", "mineral_slag"],
			["Fd_Td", "direct_refining", "metal_plate"], ["R11_T", "construction_assembly", "construction_pack"]]:
		var key: String = entry[0]
		var produced: int = completed[entry[1]] * model.recipes[entry[1]].output[entry[2]]
		var received: int = receipts[key] + (receipts.R08_to_A if key == "R08_core" else 0)
		if produced != received + route_change[key]:
			errors.append("%s tick %d: %s new output, handoff and route stock do not balance" % [arm, end.tick, key])
	for key in ["T", "Td", "Ts", "overflow"]:
		var route: String = ROUTES[key][1]
		if receipts[route] + old_receipts[route] != end.terminals[key] - start.terminals[key]:
			errors.append("%s tick %d: %s handoffs do not match terminal inventory change" % [arm, end.tick, key])


func _reset_window() -> void:
	receipts = {}
	for key in TRACKED:
		receipts[ROUTES[key][1]] = 0
	old_receipts = receipts.duplicate()
	carrier_receipts = {"F2_to_A": 0, "F2_overflow": 0}
	blocked_ticks = 0
	continued_finishes = 0
	control_restarts = 0
	fault_deficit = 0.0
	fault_exhausted_ticks = 0
	fuel_exhaustion_ticks = []
	terminal_full = false
	peak_request_kw = 0.0
	peak_deficit_kw = 0.0
	reason_counts = {}
	primary_reason_counts = {}
	recovery = {"start_tick": -1, "deadline": -1, "activation_tick": -1,
		"started_batches": {}, "started_tick": -1, "received_tick": -1, "batch": 0}


func _diff(start: Dictionary, end: Dictionary) -> Dictionary:
	var result := {}
	for key in start.keys() + end.keys():
		result[key] = end.get(key, 0) - start.get(key, 0)
	return result


func _event(tick: int, kind: String, data: Dictionary) -> void:
	events.append({"tick": tick, "kind": kind, "data": data})


func close() -> void:
	assert(trace.get_error() == OK, "cannot write D2 trace")
	trace.close()
