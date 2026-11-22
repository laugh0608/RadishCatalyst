extends RefCounted

const PROCESSORS := ["F", "F2", "Fd", "R", "E", "A"]
const PERIOD := 2400
const A_OPEN := 1200
const FD_CLOSE := 1700
const V3_A_OPEN := 1300
const V3_DELAYED_CYCLES := [2, 3, 4, 5, 7, 8, 9, 10, 11]
const LoadRules := preload("res://data/factory/load_group_rules.gd")
var model: RefCounted
var ids: Dictionary
var approaches: Dictionary
var delayed_a_cycles: Array
var state_gate: bool
var wait_for_fd: bool
var use_interlock: bool
var interlock_cycle := false
var interlock_starts: Array[Dictionary] = []
var start_state := {}
var fd_tail := {}
var observed_ready_cycle := 0
var fd_batch_before := 0
var fd_finished_tick := -1
var fd_finished_batch := 0
var opened_cycle := 0
var first_cycle_batch := 0
var opening_state := {}
var opening_attempts: Array[Dictionary] = []
var tick := 0
var orders: Array[Dictionary] = []
var commands: Array[Dictionary] = []
var errors: Array[String] = []
var previous_batch := 0
var previous_processing := false
var received_before := 0
var initial_output := 0


func _init(m: RefCounted, manifest: Dictionary, a_delay_cycles: Array = [], use_state_gate := false,
		wait_for_fd_stop := false, use_start_interlock := false) -> void:
	model = m
	ids = manifest.ids
	approaches = manifest.approaches
	delayed_a_cycles = a_delay_cycles
	state_gate = use_state_gate
	wait_for_fd = wait_for_fd_stop
	use_interlock = use_start_interlock
	initial_output = model.by_id(ids.A).output.get("construction_pack", 0)
	received_before = model.by_id(ids.T).items.get("construction_pack", 0)


func a_open_phase() -> int:
	return V3_A_OPEN if (tick / PERIOD + 1) in delayed_a_cycles else A_OPEN


func before_step() -> bool:
	var phase := tick % PERIOD
	opening_state = {}
	if use_interlock and phase == 0:
		var fault_cycle := (tick / PERIOD + 1) in V3_DELAYED_CYCLES
		if fault_cycle != interlock_cycle:
			var b: Dictionary = model.by_id(ids.B)
			var rules: Array = [{"member_id": ids.A, "source_id": ids.Fd,
				"condition": model.Interlocks.CONDITION}] if fault_cycle else []
			var actor: Dictionary = model.actor.duplicate(true)
			model.actor.merge(approaches.B, true)
			var applied: Dictionary = model.configure_load_group(b.id, b.load_group.member_ids, b.load_group.reserve_j, rules)
			model.actor.merge(actor, true)
			commands.append({"tick": tick, "interlocks": rules, "ok": applied.ok})
			if not applied.ok:
				errors.append("configure A start interlock at tick %d: %s" % [tick, applied.reason])
				return false
			interlock_cycle = fault_cycle
		fd_tail = {}
	if tick == 0:
		for key in ["I", "Q", "Kh", "C", "Ci"]: set_enabled(key, true)
		set_enabled("K", false)
	if phase == A_OPEN:
		first_cycle_batch = model.next_batch
		fd_finished_tick = -1
		fd_finished_batch = 0
		for i in 2:
			orders.append({"id": orders.size() + 1, "release": tick, "deadline": tick - phase + PERIOD,
				"start": -1, "finish": -1, "received": -1, "batch": 0})
	var pending := false
	for order in orders:
		if order.start < 0: pending = true
	for key in PROCESSORS:
		var e: Dictionary = model.by_id(ids[key])
		var active: bool = phase >= A_OPEN
		if key == "Fd": active = active and phase < FD_CLOSE
		if key == "A": active = pending and _a_can_open(phase)
		if active or not e.processing: set_enabled(key, active)
	var assembler: Dictionary = model.by_id(ids.A)
	previous_batch = assembler.active_batch
	previous_processing = assembler.processing
	if wait_for_fd or use_interlock:
		fd_batch_before = model.by_id(ids.Fd).active_batch
	if use_interlock:
		var fd: Dictionary = model.by_id(ids.Fd)
		start_state = {"fd_enabled": fd.enabled, "fd_processing": fd.processing,
			"fd_outcome": fd.batch_outcome, "fd_tail": fd_tail.duplicate(),
			"reason": model.start_interlock_reason(assembler.id)}
	return true


func _a_can_open(phase: int) -> bool:
	var cycle := tick / PERIOD + 1
	if cycle not in V3_DELAYED_CYCLES or not (state_gate or wait_for_fd):
		return phase >= a_open_phase()
	if phase < A_OPEN:
		return false
	if opened_cycle == cycle:
		return true
	if wait_for_fd:
		if tick % LoadRules.INTERVAL == 0 and observed_ready_cycle != cycle:
			var attempt := _record_v4_conditions(cycle)
			if attempt.ready:
				observed_ready_cycle = cycle
		var fd: Dictionary = model.by_id(ids.Fd)
		if phase < FD_CLOSE or fd.enabled or fd.processing:
			return false
		opened_cycle = cycle
		opening_state = {"tick": tick, "cycle": cycle, "fd_enabled": fd.enabled, "fd_processing": fd.processing,
			"fd_finished_tick": fd_finished_tick, "fd_finished_batch": fd_finished_batch,
			"v4_ready_seen": observed_ready_cycle == cycle}
		return true
	if tick % LoadRules.INTERVAL != 0:
		return false
	var attempt := _record_v4_conditions(cycle)
	if attempt.ready:
		opened_cycle = cycle
		opening_state = attempt
	return attempt.ready


func _record_v4_conditions(cycle: int) -> Dictionary:
	var a: Dictionary = model.by_id(ids.A)
	var f2: Dictionary = model.by_id(ids.F2)
	var checks := {"A": not a.processing and a.output.is_empty() and model.recipe_available(a.recipe_id)
		and model.Items.contains(a.input, model.recipes[a.recipe_id].input),
		"F2": f2.enabled and f2.processing and f2.active_batch >= first_cycle_batch,
		"crushers": _ready("C") or _ready("Ci")}
	for key in ["F", "Fd", "R", "E", "I", "Q", "Kh"]:
		checks[key] = _ready(key)
	var ready := not checks.values().has(false)
	var attempt := {"tick": tick, "cycle": cycle, "checks": checks, "f2_batch": f2.active_batch, "ready": ready,
		"opened": ready and not wait_for_fd}
	opening_attempts.append(attempt)
	return attempt


func _ready(role: String) -> bool:
	return model.uncontrolled_work_spec(model.by_id(ids[role])).ready


func after_step() -> void:
	tick += 1
	if wait_for_fd and fd_batch_before > 0 and not model.by_id(ids.Fd).processing:
		fd_finished_tick = tick
		fd_finished_batch = fd_batch_before
	if use_interlock and fd_batch_before > 0:
		var fd: Dictionary = model.by_id(ids.Fd)
		if not fd.processing and fd.batch_outcome == "completed":
			fd_tail = {"tick": tick, "batch": fd_batch_before}
	var assembler: Dictionary = model.by_id(ids.A)
	if assembler.processing and not previous_processing:
		var assigned := false
		for order in orders:
			if order.start < 0:
				order.start = tick
				order.batch = assembler.active_batch
				if use_interlock and interlock_cycle:
					interlock_starts.append(start_state.merged({"tick": tick,
						"cycle": (tick - 1) / PERIOD + 1, "order": order.id, "batch": order.batch}))
				assigned = true
				break
		if not assigned: errors.append("assembly started without an outstanding order")
	if previous_processing and not assembler.processing:
		for order in orders:
			if order.batch == previous_batch: order.finish = tick
	var received: int = model.by_id(ids.T).items.get("construction_pack", 0)
	for i in received - received_before:
		if initial_output > 0:
			initial_output -= 1
			continue
		var assigned := false
		for order in orders:
			if order.finish >= 0 and order.received < 0:
				order.received = tick
				assigned = true
				break
		if not assigned: errors.append("terminal receipt has no completed new assembly order")
	received_before = received


func set_enabled(key: String, enabled: bool) -> void:
	var e: Dictionary = model.by_id(ids[key])
	if e.enabled == enabled: return
	var actor: Dictionary = model.actor.duplicate(true)
	model.actor.merge(approaches[key], true)
	var result: Dictionary = model.set_device_enabled(e.id, enabled)
	model.actor.merge(actor, true)
	commands.append({"tick": tick, "device": key, "enabled": enabled, "ok": result.ok})
	if not result.ok: errors.append("command " + key + ": " + result.reason)


func overdue() -> Array:
	return orders.filter(func(order): return order.deadline <= tick and (order.received < 0 or order.received > order.deadline))
