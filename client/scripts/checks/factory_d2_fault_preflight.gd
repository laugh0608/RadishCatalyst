extends RefCounted

const Codec := preload("res://scripts/factory/save/codec.gd")
const Compare := preload("res://scripts/checks/factory_expansion_compare.gd")
const Preflight := preload("res://scripts/checks/factory_d2_preflight.gd")
const Preparation := preload("res://scripts/checks/factory_d2_preparation.gd")
const Workload := preload("res://scripts/checks/factory_d2_workload.gd")
const Ledger := preload("res://scripts/checks/factory_d2_fault_ledger.gd")

const WINDOW := 14400
const SUPPLY := {1200: true, 2400: false, 12000: true, 14400: false, 26400: true}
const COMMAND_PHASE := {1200: 0, 2400: 1200, 12000: 1200, 14400: 1200, 26400: 1200}
const RECIPES := {"C": "carbon_crushing", "Ci": "iron_crushing", "F": "mixed_refining", "F2": "direct_sintering",
	"Fd": "direct_refining", "R": "basic_catalyst", "E": "cell_assembly", "A": "construction_assembly"}
const CELL := "industrial_cell"
var evidence: String
var revision: int
var reference_arm: String
var controlled_arm: String
var document: Dictionary
var preparation: Dictionary
var ids: Dictionary
var invalid: Array[String] = []
var unmet: Array[String] = []
var fd_diagnostic := false
var interlock_cycle_test := false
const FD_ARM := "Fd-drain"


func _init(folder: String, fault_revision := 2) -> void:
	evidence = folder
	revision = fault_revision
	reference_arm = "O%d" % revision
	controlled_arm = "L%d" % revision


func _load_candidate() -> Dictionary:
	document = _read("candidate.json")
	preparation = _read("preparation.json")
	ids = preparation.ids
	var model := _decode(document)
	var saved := _read("prepared-autosave.json")
	_check_p0(model, saved)
	var capacity := Preflight.capacity_bounds(model, ids, model.material_balance().held)
	if revision >= 4:
		_check_carrier_branch(model, capacity)
	for row in capacity.values():
		if row.upper_bound >= row.capacity:
			invalid.append("P0 terminal capacity below 24-minute bound: " + row.item)
	return capacity


func run_fd_diagnostic(short_run: bool) -> Dictionary:
	fd_diagnostic = true
	var capacity := _load_candidate()
	var arms := {}
	var status := "fd_cycle_passed" if short_run else "fd_diagnostic_passed"
	if invalid.is_empty():
		var horizon := 2 * Workload.PERIOD if short_run else 2 * WINDOW
		var run_result := _run_arm(FD_ARM, horizon)
		arms[FD_ARM] = run_result
		var expected_cycles: Array = [2] if short_run else Workload.V3_DELAYED_CYCLES
		for cycle in expected_cycles:
			var edge := _edge_in_cycle(run_result.opening_edges, cycle)
			if edge.is_empty():
				unmet.append("cycle %d: A was not opened after Fd stopped" % cycle)
				continue
			var opening: Dictionary = edge.production_state
			if (opening.fd_enabled or opening.fd_processing or opening.fd_finished_batch <= 0
					or opening.fd_finished_tick > opening.tick or opening.tick % Workload.PERIOD < Workload.FD_CLOSE):
				invalid.append("cycle %d: A opening does not follow the Fd drain" % cycle)
			if not opening.v4_ready_seen:
				invalid.append("cycle %d: v4 production opportunity was not observed" % cycle)
			for order in run_result.orders:
				if order.release / Workload.PERIOD + 1 != cycle:
					continue
				if order.start < edge.tick or order.received < order.finish or order.received > order.deadline or order.received < 0:
					unmet.append("cycle %d: order %d did not start after Fd stopped and reach T by the deadline" % [cycle, order.id])
		_check_arm_windows(FD_ARM, run_result.windows, horizon if short_run else WINDOW, not short_run)
		if not short_run:
			var reference := _read("reference-result.json")
			arms.O4 = reference.arms.O4
			for i in 2:
				var window: Dictionary = run_result.windows[i]
				_check_reference(arms.O4.windows[i], i)
				_check_benefit(arms.O4.windows[i], window, FD_ARM, "O4", i)
	if not invalid.is_empty():
		status = "sample_invalid"
	elif not unmet.is_empty():
		status = "fd_cycle_below_target" if short_run else "strategy_below_target"
	return {"status": status, "reasons": invalid + unmet, "sample_invalid_reasons": invalid,
		"strategy_reasons": unmet, "candidate_sha256": FileAccess.get_sha256(evidence.path_join("candidate.json")),
		"capacity_bounds": capacity, "arms": arms, "natural_clock_result": false,
		"execution_mode": "fd_drain_fixed_step", "c3_enabled": false, "can_start_long_runs": false}


func run() -> Dictionary:
	var capacity := _load_candidate()
	var arms := {}
	var paired_edges := []
	if invalid.is_empty():
		for arm in [reference_arm, controlled_arm]:
			arms[arm] = _run_arm(arm, 2 * Workload.PERIOD if interlock_cycle_test else 2 * WINDOW)
		if interlock_cycle_test:
			paired_edges = _paired_edges(arms, [2])
			for arm in arms:
				_check_arm_windows(arm, arms[arm].windows, 2 * Workload.PERIOD, false)
				if not arms[arm].windows[0].overdue.is_empty():
					unmet.append(arm + " missed a short-cycle deadline")
			if not paired_edges[0].matched:
				invalid.append("first fault cycle lacks a paired start, negative budget and controlled restart")
			_check_interlock_starts(arms[controlled_arm], [2])
		else:
			paired_edges = _score(arms)
			if revision == 5:
				_check_interlock_starts(arms[controlled_arm], Workload.V3_DELAYED_CYCLES)
	var status := "interlock_cycle_passed" if interlock_cycle_test else "fault_preflight_passed"
	if not invalid.is_empty():
		status = "sample_invalid"
	elif not unmet.is_empty():
		status = "strategy_below_target"
	var result := {"status": status, "reasons": invalid + unmet, "sample_invalid_reasons": invalid,
		"strategy_reasons": unmet, "execution_mode": "paired_fixed_step_preflight", "natural_clock_result": false,
		"skipped_screenshots": true, "candidate_sha256": FileAccess.get_sha256(evidence.path_join("candidate.json")),
		"capacity_bounds": capacity, "arms": arms, "fault_gate_passed": status == "fault_preflight_passed",
		"can_start_long_runs": false, "pending_gates": ["natural_clock_driver_and_recovery"]}
	if revision == 5:
		result.derived_sha256 = FileAccess.get_sha256(evidence.path_join("interlock-candidate.json"))
	if revision >= 3:
		result.revision = revision
		result.a_delayed_cycles = Workload.V3_DELAYED_CYCLES
		result.paired_edges = paired_edges
	return result


func _check_interlock_starts(run_result: Dictionary, cycles: Array) -> void:
	for cycle in cycles:
		var starts: Array = run_result.interlock_starts.filter(func(edge): return edge.cycle == cycle)
		if starts.size() != 2:
			unmet.append("L5 cycle %d did not start both orders" % cycle)
			continue
		for edge in starts:
			if edge.fd_enabled or edge.fd_processing or edge.fd_outcome != "completed" \
				or edge.fd_tail.get("tick", edge.tick) >= edge.tick or edge.fd_tail.get("batch", 0) <= 0 \
				or edge.fd_tail.tick < (cycle - 1) * Workload.PERIOD + Workload.FD_CLOSE or not edge.reason.is_empty():
				invalid.append("L5 order %d started without the completed and stopped Fd tail" % edge.order)


func _check_carrier_branch(model: RefCounted, capacity: Dictionary) -> void:
	var proof := _read("carrier-proof.json")
	if not proof.ok or proof.candidate_sha256 != FileAccess.get_sha256(evidence.path_join("candidate.json")):
		invalid.append("carrier proof does not match derived P0")
	var branch: Dictionary = preparation.carrier_branch
	var devices: Array[Dictionary] = [model.by_id(ids.F2)]
	for id in branch.path_ids:
		devices.append(model.by_id(id))
	_check_path(model, devices, "F2 carrier overflow")
	var item := "porous_carrier"
	var warehouse: Dictionary = devices.back()
	var recipe: Dictionary = model.recipes[model.by_id(ids.F2).recipe_id]
	var existing: int = model.material_balance().held.get(item, 0)
	var new_output: int = 12 * (ceili(60.0 / recipe.seconds) + 1) * recipe.output[item]
	capacity.carrier_overflow = {"item": item, "initial_world_stock": existing, "new_output_upper_bound": new_output,
		"upper_bound": existing + new_output, "capacity": model.Items.count(warehouse.items) + model.input_room(warehouse, item),
		"horizon_seconds": 1440}


func _check_p0(model: RefCounted, saved: Dictionary) -> void:
	if not Compare.equivalent(_snapshot(model), _snapshot(_decode(saved)), "P0 Store save"):
		invalid.append("prepared candidate differs from the Store autosave")
	var g: Dictionary = model.by_id(ids.G)
	var buffer: Dictionary = model.by_id(ids.B)
	var dispatch: Dictionary = model.by_id(ids.dispatch)
	if not g.enabled or not buffer.enabled or g.burn_remaining_ticks != 0 or not g.fuel.is_empty() or buffer.stored_j != 0:
		invalid.append("P0 generator and storage must be enabled and empty")
	if dispatch.active or dispatch.filter_item != CELL or dispatch.period_s != 120 or dispatch.window_s != 120 \
			or dispatch.quota != 60 or dispatch.feedback != model.Feedback.defaults() \
			or not dispatch.cargo.is_empty() or dispatch.phase_ticks != 0 or dispatch.sent != 0:
		invalid.append("P0 inactive continuous dispatch configuration or empty phase differs")
	var expected_group: Dictionary = model.Loads.defaults()
	expected_group.member_ids = [ids.A]
	if not Compare.equivalent(buffer.load_group, expected_group) or not model.load_group_binding(buffer).ok:
		invalid.append("P0 load group must be bound, disabled, pending, with A only and 100 kJ reserve")
	var material: Dictionary = model.material_balance()
	if not preparation.ok or not material.balanced or not Compare.equivalent(material.held, preparation.held) \
			or not Compare.equivalent(preparation.caps, Preparation.CAPS):
		invalid.append("P0 inventory or preparation manifest differs")
	if model.remainder < 0.0 or model.remainder >= model.STEP:
		invalid.append("P0 has a full pending simulation step")
	for item in Preparation.CAPS:
		if material.held.get(item, 0) > Preparation.CAPS[item]:
			invalid.append("P0 exceeds the frozen inventory cap: " + item)
	for key in RECIPES:
		var e: Dictionary = model.by_id(ids[key])
		if e.processing or e.recipe_id != RECIPES[key] or not model.recipe_available(e.recipe_id):
			invalid.append("P0 work in progress or incorrect recipe: " + key)
	var network: int = model.load_network(model.core)
	if network < 0 or model.grid.groups[network].base_capacity_kw != 360.0:
		invalid.append("P0 core network must supply 360 kW")
	for key in RECIPES.keys() + ["G", "B", "I", "Q", "K", "Kh"]:
		if network < 0 or model.load_network(model.by_id(ids[key])) != network:
			invalid.append("P0 device outside core network: " + key)
	var actor: Dictionary = model.actor.duplicate(true)
	for key in ids:
		model.actor.merge(preparation.approaches[key], true)
		if model.blocked_for_actor(model.actor.x, model.actor.z) or not model.near_entity(model.by_id(ids[key])):
			invalid.append("P0 command approach invalid: " + key)
	model.actor.merge(actor, true)
	var layout := _read("layout.json")
	for key in layout.entities:
		var e: Dictionary = model.by_id(ids[key])
		var rect: Array = layout.entities[key]
		if e.x != rect[0] or e.z != rect[1] or model.CATALOG[e.type].w != rect[2] or model.CATALOG[e.type].d != rect[3]:
			invalid.append("P0 device layout differs: " + key)
	for route in layout.routes:
		_check_route(model, route)
	var overflow_route: Array[Dictionary] = [model.by_id(ids.fuel_split), model.entity_at(Vector2i(1, 26)),
		model.entity_at(Vector2i(1, 27)), model.by_id(ids.overflow)]
	_check_path(model, overflow_route, "cell overflow")


func _check_route(model: RefCounted, route: Dictionary) -> void:
	var from: Dictionary = model.core if route.source is String else model.by_id(ids[route.source[0]])
	var to: Dictionary = model.core if route.target is String else model.by_id(ids[route.target[0]])
	var devices: Array[Dictionary] = [from]
	for i in route.points.size():
		var start := Vector2i(route.points[i][0], route.points[i][1])
		devices.append(model.entity_at(start))
		if i + 1 == route.points.size():
			continue
		var finish := Vector2i(route.points[i + 1][0], route.points[i + 1][1])
		var direction := (finish - start).sign()
		for j in range(1, absi(finish.x - start.x) + absi(finish.y - start.y)):
			devices.append(model.entity_at(start + direction * j))
	devices.append(to)
	_check_path(model, devices, "%s %s → %s" % [route.item, route.source, route.target])
	if to.id == ids.G:
		var queued := devices.filter(func(e): return e.get("cargo") == CELL)
		if queued.size() < 2 or devices[-2].get("id") != ids.dispatch or devices[-3].get("cargo") != CELL:
			invalid.append("P0 fuel route does not have two reachable cells and a ready upstream cell")


func _check_path(model: RefCounted, devices: Array[Dictionary], label: String) -> void:
	for i in devices.size() - 1:
		var source: Dictionary = devices[i]
		var target: Dictionary = devices[i + 1]
		if source.is_empty() or target.is_empty():
			invalid.append("P0 route has a missing device: " + label)
			return
		var connected := false
		for port in model.Logistics.ports(model, source, "output"):
			var connection: Dictionary = model.Logistics.output_connection(model, port)
			if connection.ok and connection.target.id == target.id:
				connected = true
				break
		if not connected:
			invalid.append("P0 route is disconnected: %s (#%d → #%d)" % [label, source.id, target.id])
			return


func _setup(model: RefCounted, arm: String) -> void:
	var actor: Dictionary = model.actor.duplicate(true)
	model.actor.merge(preparation.approaches.dispatch, true)
	var dispatch: Dictionary = model.by_id(ids.dispatch)
	assert(model.configure_dispatch(dispatch.id, CELL, 120, 10, 1).ok)
	assert(model.configure_storage_feedback(dispatch.id, int(ids.B), 1100000, 2000000).ok)
	if arm == controlled_arm:
		model.actor.merge(preparation.approaches.B, true)
		assert(model.set_load_group_enabled(int(ids.B), true).ok)
	model.actor.merge(actor, true)


func _assert_initial_difference(model: RefCounted, original: Dictionary, arm: String) -> void:
	var expected := original.duplicate(true)
	for e in expected.state.entities:
		if e.id == ids.dispatch:
			e.window_s = 10
			e.quota = 1
			e.feedback = {"mode": "storage", "source_id": int(ids.B), "low_j": 1100000,
				"high_j": 2000000, "latch": "pending"}
		elif e.id == ids.B:
			e.load_group.enabled = arm == controlled_arm
	if not Compare.equivalent(expected, _snapshot(model), arm + " initial strategy whitelist"):
		invalid.append(arm + " initial state differs outside strategy whitelist")


func _step_supply(model: RefCounted, tick: int) -> void:
	if not SUPPLY.has(tick):
		return
	var actor: Dictionary = model.actor.duplicate(true)
	model.actor.merge(preparation.approaches.dispatch, true)
	assert(model.set_dispatch_active(int(ids.dispatch), SUPPLY[tick]).ok)
	model.actor.merge(actor, true)


func _run_arm(arm: String, horizon := 2 * WINDOW) -> Dictionary:
	var model := _decode(_read("interlock-candidate.json") if revision == 5 else document)
	var original := _snapshot(model)
	_setup(model, arm)
	_assert_initial_difference(model, original, arm)
	_write(arm + "-start.json", _snapshot(model))
	var shadow := _decode(_read("interlock-candidate.json") if revision == 5 else document)
	_setup(shadow, arm)
	var delayed_cycles: Array = Workload.V3_DELAYED_CYCLES if revision == 3 else []
	var work := Workload.new(model, preparation, delayed_cycles, revision >= 4, fd_diagnostic, revision == 5)
	var shadow_work := Workload.new(shadow, preparation, delayed_cycles, revision >= 4, fd_diagnostic, revision == 5)
	var ledger := Ledger.new(model, ids, evidence, arm, revision >= 3, preparation.get("carrier_branch", {}))
	ledger.measure_uncontrolled_recovery = fd_diagnostic
	ledger.measure_interlocks = revision == 5
	var dispatch: Dictionary = model.by_id(ids.dispatch)
	var events: Array[Dictionary] = []
	var windows: Array[Dictionary] = []
	var boundaries: Array[Dictionary] = [ledger.boundary()]
	var opening_edges: Array[Dictionary] = []
	var comparisons := 0
	var compare_failed := false
	for tick in horizon:
		if SUPPLY.has(tick):
			var before := ledger.supply_state()
			if before.phase_ticks != COMMAND_PHASE[tick] or before.active == SUPPLY[tick]:
				invalid.append("%s unexpected dispatch state before command at %d" % [arm, tick])
			_step_supply(model, tick)
			var after := ledger.supply_state()
			if not Compare.equivalent(before.merged({"active": SUPPLY[tick]}, true), after):
				invalid.append("%s dispatch command altered retained state at %d" % [arm, tick])
			events.append({"tick": tick, "before": before, "after": after})
		work.before_step()
		ledger.before_step(tick)
		var delayed_edge := revision == 3 and tick % Workload.PERIOD == Workload.V3_A_OPEN and work.a_open_phase() == Workload.V3_A_OPEN
		model.advance(model.STEP, 1)
		work.after_step()
		ledger.after_step(tick + 1, work.orders)
		if interlock_cycle_test and arm == controlled_arm and work.interlock_starts.size() == 1 \
			and work.interlock_starts[0].tick == tick + 1:
			_write("first-order-checkpoint.json", _snapshot(model))
		if delayed_edge or not work.opening_state.is_empty():
			opening_edges.append(_opening_edge(ledger, work, tick + 1))
		_step_supply(shadow, tick)
		shadow_work.before_step()
		shadow.advance(shadow.STEP, 1)
		shadow_work.after_step()
		if not compare_failed and ((tick + 1) % 600 == 0 or ledger.control_transition or SUPPLY.has(tick)
				or delayed_edge or not work.opening_state.is_empty()):
			comparisons += 1
			compare_failed = not Compare.equivalent(_snapshot(model), _snapshot(shadow), arm + " read-only step " + str(tick + 1)) \
			or not Compare.equivalent(work.orders, shadow_work.orders, arm + " read-only orders")
			if compare_failed:
				invalid.append("%s observed and unobserved trajectories diverge at step %d" % [arm, tick + 1])
		if (tick + 1) % WINDOW == 0 or tick + 1 == horizon:
			var end := ledger.boundary()
			var window := ledger.close_window(boundaries.back(), end, work.overdue())
			windows.append(window)
			boundaries.append(end)
			_write("%s-boundary-%d.json" % [arm, tick + 1], _snapshot(model))
			if revision >= 3:
				print("%s window %d: peak deficit %.3f kW, unserved energy %.6f kWh" %
					[arm, windows.size(), window.peak_deficit_kw, window.deficit_kj / 3600.0])
			else:
				print("%s fixed-step window %d completed, deficit %.3f kJ" % [arm, windows.size(), window.deficit_kj])
	invalid.append_array(work.errors)
	invalid.append_array(ledger.errors)
	ledger.close()
	_write(arm + "-orders.json", work.orders)
	_write(arm + "-commands.json", {"workload": work.commands, "supply": events})
	_write(arm + "-events.json", ledger.events)
	var result := {"windows": windows, "boundaries": boundaries, "observation_comparisons": comparisons,
		"observed_steps": work.tick, "read_only_observation_passed": not compare_failed,
		"supply_command_count": events.size(), "final_phase_ticks": dispatch.phase_ticks}
	if revision >= 3:
		result.opening_edges = opening_edges
		for edge in opening_edges:
			# The order dictionary is updated by the workload until the last step.
			var order: Dictionary = edge.order
			edge.restarted_after_block = (edge.negative_sample_blocked and not order.is_empty()
				and order.start > edge.tick
				and ledger.events.any(func(event): return (
					event.kind == "control_latch" and event.tick > edge.tick
					and event.tick <= order.start and event.data.after == "allow")))
		_write(arm + "-opening-edges.json", opening_edges)
	if revision >= 4:
		_write(arm + "-state-checks.json", work.opening_attempts)
	if revision == 5:
		_write(arm + "-interlock-starts.json", work.interlock_starts)
		result.interlock_starts = work.interlock_starts
	if fd_diagnostic or revision == 5:
		result.orders = work.orders
	return result


func _opening_edge(ledger: RefCounted, work: RefCounted, tick: int) -> Dictionary:
	var assembler: Dictionary = ledger.model.by_id(ids.A)
	var group: Dictionary = ledger.model.by_id(ids.B).load_group
	var order := {}
	for candidate in work.orders:
		if candidate.start < 0 or candidate.start == tick:
			order = candidate
			break
	var sampled: bool = ledger.a_before.evaluation_ticks_left == 0
	var opened: bool = assembler.processing and not ledger.a_before.processing
	var negative_budget: bool = (ledger.budget.get("ok", false) and ledger.budget.margin_w < 0
		and int(ids.A) in ledger.budget.candidate_ids)
	var blocked: bool = (group.enabled and sampled and negative_budget and ledger.a_before.ready_without_control
		and group.latch == "block" and not assembler.processing)
	return {"tick": tick, "cycle": (tick - 1) / Workload.PERIOD + 1,
		"a_before": ledger.a_before, "order": order, "supply_before": ledger.supply_before,
		"budget": ledger.budget, "latch_before": ledger.power_before.latch, "latch_after": group.latch,
		"opened": opened, "negative_sample_blocked": blocked, "production_state": work.opening_state,
		"deficit_kw": ledger.last_deficit_kw, "actual_c3_sample": group.enabled and sampled}


func _paired_edges(arms: Dictionary, cycles: Array = Workload.V3_DELAYED_CYCLES) -> Array:
	var reference: Array = arms[reference_arm].opening_edges
	var controlled: Array = arms[controlled_arm].opening_edges
	if revision >= 4:
		return _pair_state_openings(reference, controlled, cycles)
	if reference.size() != Workload.V3_DELAYED_CYCLES.size() or controlled.size() != reference.size():
		invalid.append("v3 must observe all nine planned A opening edges in each arm")
		return []
	var edges := []
	for i in reference.size():
		var o: Dictionary = reference[i]
		var l: Dictionary = controlled[i]
		var cycle: int = Workload.V3_DELAYED_CYCLES[i]
		var tick := (cycle - 1) * Workload.PERIOD + Workload.V3_A_OPEN + 1
		if o.tick != tick or l.tick != tick:
			invalid.append("v3 observed A opening edge at the wrong step: cycle %d" % cycle)
		var starts_same_order: bool = not o.order.is_empty() and not l.order.is_empty() and o.order.id == l.order.id
		var matched: bool = (o.tick == tick and l.tick == tick and o.a_before.ready_without_control and o.opened
			and l.negative_sample_blocked and l.restarted_after_block and starts_same_order)
		edges.append({"cycle": cycle, "tick": tick, "matched": matched})
	return edges


func _pair_state_openings(reference: Array, controlled: Array, cycles: Array) -> Array:
	var edges := []
	for cycle in cycles:
		var o := _edge_in_cycle(reference, cycle)
		var l := _edge_in_cycle(controlled, cycle)
		var matched := false
		if not o.is_empty() and not l.is_empty():
			matched = (o.opened and o.a_before.ready_without_control and l.actual_c3_sample
				and l.negative_sample_blocked and l.restarted_after_block and not o.order.is_empty()
				and not l.order.is_empty() and o.order.id == l.order.id and o.deficit_kw > 1e-6
				and o.supply_before.burn_ticks == 0 and l.supply_before.burn_ticks == 0
				and o.supply_before.fuel.is_empty() and l.supply_before.fuel.is_empty())
		edges.append({"cycle": cycle, "tick": l.get("tick", -1), "reference_tick": o.get("tick", -1), "matched": matched})
	return edges


func _edge_in_cycle(edges: Array, cycle: int) -> Dictionary:
	for edge in edges:
		if edge.cycle == cycle:
			return edge
	return {}


func _check_arm_windows(arm: String, windows: Array, ticks_per_window: int, check_stock := true) -> void:
	for i in windows.size():
		var window: Dictionary = windows[i]
		var label := "%s window %d: " % [arm, i + 1]
		if (window.end_tick - window.start_tick != ticks_per_window or not window.balanced or window.cell_residual != 0
				or absf(window.energy_residual_kj) > 0.001 or absf(window.burn_residual_kj) > 0.001
				or window.delta.storage_discarded_j != 0 or window.delta.discarded_kj != 0.0 or window.terminal_full):
			invalid.append(label + "horizon, ledger or terminal capacity failed")
		if check_stock:
			for item in Preparation.CAPS:
				var change: int = window.stock_change[item]
				if change < -window.max_batch_input[item] or (i == 1 and change < 0 and windows[0].stock_change[item] < 0):
					invalid.append("%s: unstable %s inventory (%+d)" % [label, item, change])


func _check_reference(reference: Dictionary, index: int) -> void:
	if reference.fault_deficit_kj < 100.0 or reference.fault_exhausted_ticks == 0 or reference.fuel_exhaustion_ticks.is_empty():
		invalid.append("window %d: %s needs at least 100 kJ during the attributed fault and actual G exhaustion" % [index + 1, reference_arm])


func _check_benefit(reference: Dictionary, measured: Dictionary, arm: String, reference_name: String, index: int) -> void:
	var label := "window %d: " % (index + 1)
	if measured.deficit_kj > reference.deficit_kj * 0.5:
		unmet.append(label + arm + " deficit exceeds 50% of " + reference_name)
	for key in ["R08_core", "R11_T", "Fd_Td"]:
		if measured.receipts[key] * 100 < reference.receipts[key] * 95:
			unmet.append(label + key + " " + arm + " receipts below 95% of " + reference_name)
	if not measured.overdue.is_empty():
		unmet.append(label + arm + " has overdue R11 orders")
	if not measured.recovery.passed:
		unmet.append(label + arm + " missed a start and delivery within 120 seconds of fuel reopening")
	for key in ["c_burn", "c_adjusted"]:
		if measured[key] > reference[key]:
			unmet.append(label + arm + " " + key + " exceeds " + reference_name)


func _score(arms: Dictionary) -> Array:
	var edges := _paired_edges(arms) if revision >= 3 else []
	for arm in arms:
		_check_arm_windows(arm, arms[arm].windows, WINDOW)
	for i in 2:
		var reference: Dictionary = arms[reference_arm].windows[i]
		var controlled: Dictionary = arms[controlled_arm].windows[i]
		var label := "window %d: " % (i + 1)
		_check_reference(reference, i)
		if controlled.blocked_ticks == 0 or controlled.continued_finishes == 0 or controlled.control_restarts == 0:
			invalid.append(label + controlled_arm + " requires actual C3 blocking, retained in-flight completion and controlled restart")
		if revision >= 3 and not edges.any(func(edge): return edge.matched and edge.tick > i * WINDOW and edge.tick <= (i + 1) * WINDOW):
			invalid.append(label + "no paired A opening, negative C3 sample, and restart at a planned fault edge")
		_check_benefit(reference, controlled, controlled_arm, reference_arm, i)
	return edges


func _decode(doc: Dictionary) -> RefCounted:
	var decoded := Codec.decode(doc, document.world_id)
	assert(decoded.ok, "D2 fault parent must strictly decode: " + str(decoded.get("reason", "")))
	return decoded.model


func _snapshot(model: RefCounted) -> Dictionary:
	return Codec.snapshot(model, document.world_id, document.name, int(document.sequence))


func _read(name: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join(name)))


func _write(name: String, data: Variant) -> void:
	var file := FileAccess.open(evidence.path_join(name), FileAccess.WRITE)
	assert(file != null, "cannot write " + name)
	file.store_string(JSON.stringify(data, "", true, true))
	assert(file.get_error() == OK, "cannot write " + name)
