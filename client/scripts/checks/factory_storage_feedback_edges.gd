extends RefCounted

const Codec := preload("res://scripts/factory/save/codec.gd")
const Model := Codec.V14.FeedbackModel
const Rules := Model.Feedback
const CELL := "industrial_cell"
var driver: Node


func _init(check_driver: Node) -> void:
	driver = check_driver


func fixture() -> Dictionary:
	var m := Model.new()
	m.core.level = 3
	for key in m.research_nodes:
		m.researched[key] = true
	m.kits.cell_generator = 2
	m.kits.grid_buffer = 3
	m.kits.timed_dispatch = 2
	var g: Dictionary = m.place("cell_generator", Vector2i(-29, 24)).entity
	var b: Dictionary = m.place("grid_buffer", Vector2i(-26, 24)).entity
	var other: Dictionary = m.place("grid_buffer", Vector2i(-26, 27)).entity
	var remote: Dictionary = m.place("grid_buffer", Vector2i(-5, 24)).entity
	var gate: Dictionary = m.place("timed_dispatch", Vector2i(-30, 25), 0).entity
	m.actor.x = -30.5
	m.actor.z = 25.5
	m.configure_dispatch(gate.id, CELL, 10, 10, 1)
	m.configure_storage_feedback(gate.id, b.id, Rules.LOW_J, Rules.HIGH_J)
	m.set_dispatch_active(gate.id, true)
	return {"model": m, "g": g, "b": b, "other": other, "remote": remote, "gate": gate}


func run() -> void:
	for row in [[1099999, "block", "allow"], [1100000, "block", "allow"], [1100001, "block", "block"],
		[1999999, "allow", "allow"], [2000000, "allow", "block"], [2000001, "allow", "block"],
		[1550000, "allow", "allow"], [1550000, "block", "block"],
		[1549999, "pending", "allow"], [1550000, "pending", "block"], [1550001, "pending", "block"]]:
		var f := fixture()
		f.b.stored_j = row[0]
		f.gate.feedback.latch = row[1]
		f.gate.cargo = CELL
		f.gate.progress = 1.0
		f.model.advance(Model.STEP, 1)
		driver.expect(f.gate.feedback.latch == row[2] and f.gate.sent == (1 if row[2] == "allow" else 0), "C2 edge and actual delivery: " + str(row))
	_commands()
	_lifecycle()
	_sampling()
	_shared_source()


func _commands() -> void:
	var f := fixture()
	var m: RefCounted = f.model
	var before: Dictionary = f.gate.duplicate(true)
	for args in [[f.b.id, -1000, 2000000], [f.b.id, 1100001, 2000000], [f.b.id, 2000000, 2000000],
		[f.b.id, 0, 3601000], [f.b.id, 0.0, 2000000], [f.b.id, true, 2000000],
		[0, 0, 1000], [m.next_id, 0, 1000], [str(f.b.id), 0, 1000], [f.remote.id, 0, 1000]]:
		driver.expect(not m.configure_storage_feedback(f.gate.id, args[0], args[1], args[2]).ok and f.gate == before, "invalid configuration is atomic: " + str(args))
	m.actor.x = 0
	m.actor.z = 0
	driver.expect(not m.configure_storage_feedback(f.gate.id, f.b.id, 0, 1000).ok and not m.exit_storage_feedback(f.gate.id).ok and f.gate == before, "remote edits cannot change the gate")
	m.actor.x = -30.5
	m.actor.z = 25.5
	m.researched.erase(Rules.RESEARCH)
	driver.expect(not m.configure_storage_feedback(f.gate.id, f.b.id, 0, 1000).ok and f.gate == before, "missing research cannot bind")
	m.researched[Rules.RESEARCH] = true
	f.gate.feedback.latch = "allow"
	f.gate.cargo = CELL
	f.gate.progress = 0.5
	f.gate.phase_ticks = 71
	f.gate.sent = 1
	before = f.gate.duplicate(true)
	driver.expect(m.configure_storage_feedback(f.gate.id, f.b.id, Rules.LOW_J, Rules.HIGH_J).ok and f.gate == before, "identical config retains decision and all C1 state")
	driver.expect(not m.configure_dispatch(f.gate.id, "crystal", 10, 10, 1).ok and f.gate == before, "feedback forbids switching away from cells")
	driver.expect(m.configure_storage_feedback(f.gate.id, f.other.id, 1000000, 2100000).ok and f.gate.feedback.latch == "pending"
		and f.gate.phase_ticks == 71 and f.gate.sent == 1 and f.gate.cargo == CELL and f.gate.progress == 0.5, "loaded rebinding resets only feedback initialization")
	m.exit_storage_feedback(f.gate.id)
	driver.expect(f.gate.feedback == Rules.defaults() and f.gate.phase_ticks == 71 and f.gate.sent == 1 and f.gate.cargo == CELL, "explicit takeover preserves quota, phase and cargo")
	m.advance(Model.STEP, 1)
	driver.expect(f.gate.sent == 1 and f.gate.cargo == CELL, "takeover cannot bypass used quota")
	f.gate.cargo = ""
	f.gate.progress = 0.0
	m.configure_storage_feedback(f.gate.id, f.b.id, Rules.LOW_J, Rules.HIGH_J)
	f.gate.feedback.latch = "block"
	driver.expect(m.configure_dispatch(f.gate.id, CELL, 20, 5, 1).ok and f.gate.feedback.latch == "block", "C1 schedule changes do not reset hysteresis")


func _lifecycle() -> void:
	var f := fixture()
	var m: RefCounted = f.model
	f.b.stored_j = 1500000
	f.gate.feedback.latch = "allow"
	f.gate.cargo = CELL
	f.gate.progress = 1.0
	f.b.enabled = false
	m.revision += 1
	m.advance(Model.STEP, 1)
	driver.expect(f.gate.feedback.latch == "allow" and f.gate.sent == 0 and f.gate.phase_ticks == 1, "disabled source blocks only departure and retains latch")
	f.b.enabled = true
	m.revision += 1
	m.advance(Model.STEP, 1)
	driver.expect(f.gate.sent == 1 and f.gate.cargo.is_empty() and f.g.fuel[CELL] == 1, "re-enable source resumes in hysteresis band, stopped G still accepts fuel")
	m.set_dispatch_active(f.gate.id, false)
	var frozen: Dictionary = f.gate.duplicate(true)
	f.b.stored_j = 2200000
	m.advance(11.0, 220)
	driver.expect(f.gate == frozen, "stopped gate freezes phase and decision despite changed energy")
	m.set_dispatch_active(f.gate.id, true)
	m.advance(Model.STEP, 1)
	driver.expect(f.gate.feedback.latch == "block", "re-enabled gate samples before departure")
	# A temporarily missing automatic attachment is a valid runtime failure.
	f.b.power_node_id = 0
	f.gate.feedback.latch = "allow"
	m.revision += 1
	m.advance(Model.STEP, 1)
	driver.expect("未接网" in m.storage_feedback_reason(f.gate) and f.gate.feedback.latch == "allow", "disconnected source retains hysteresis")
	f.b.power_node_id = f.g.id
	f.b.stored_j = 1500000
	m.revision += 1
	m.advance(Model.STEP, 1)
	driver.expect(f.gate.feedback.latch == "allow", "reconnection in band does not midpoint-reset")
	f.gate.feedback.source_id = f.remote.id
	m.advance(Model.STEP, 1)
	driver.expect("同一电网" in m.storage_feedback_reason(f.gate), "existing cross-network binding fails closed")
	f.gate.feedback.source_id = f.b.id
	m.actor.x = -26.5
	m.actor.z = 24.5
	driver.expect(not m.salvage(f.b.id, true).ok and f.gate.feedback.source_id == f.b.id, "failed live charged salvage preserves binding")
	m.set_device_enabled(f.b.id, false)
	driver.expect(m.salvage(f.b.id).get("needs_confirmation", false) and f.gate.feedback.source_id == f.b.id, "unconfirmed salvage preserves binding")
	driver.expect(m.salvage(f.b.id, true).ok and f.gate.feedback.source_id == 0 and f.gate.feedback.latch == "pending"
		and f.gate.feedback.mode == "storage" and m.statistics.totals.storage_discarded_j == 1500000, "source removal clears references atomically with energy loss")
	var replacement: Dictionary = m.place("grid_buffer", Vector2i(-26, 24)).entity
	driver.expect(replacement.stored_j == 0 and f.gate.feedback.source_id == 0, "replacement at same position never auto-binds")
	m.actor.x = -30.5
	m.actor.z = 25.5
	m.configure_storage_feedback(f.gate.id, replacement.id, Rules.LOW_J, Rules.HIGH_J)
	m.actor.x = -29.5
	m.actor.z = 23.5
	driver.expect(m.salvage(f.g.id, true).ok, "stopped G can be removed")
	driver.expect("直连" in m.storage_feedback_reason(f.gate), "removed G breaks the actual port binding")
	var second: Dictionary = m.place("cell_generator", Vector2i(-29, 24)).entity
	m.advance(Model.STEP, 1)
	driver.expect(f.gate.feedback.source_id == replacement.id and f.gate.feedback.latch == "allow" and second.id != f.g.id, "replacement G derives its target from the port")


func _sampling() -> void:
	var f := fixture()
	var m: RefCounted = f.model
	f.b.stored_j = 1999999
	f.gate.feedback.latch = "allow"
	f.g.enabled = true
	f.g.fuel[CELL] = 1
	m.revision += 1
	var snapshot: Dictionary = Codec.snapshot(m, "00000000000000000000000000000001", "fixture", 1)
	m.power_state()
	m.feedback(f.gate)
	m.storage_feedback_binding(f.gate, f.b.id)
	driver.expect(Codec.snapshot(m, snapshot.world_id, snapshot.name, 1) == snapshot, "UI, power and binding queries never sample or burn")
	m.advance(Model.STEP, 1)
	driver.expect(f.b.stored_j > Rules.HIGH_J and f.gate.feedback.latch == "allow", "current-step charging cannot change the step-start decision")
	m.advance(Model.STEP, 1)
	driver.expect(f.gate.feedback.latch == "block", "crossed threshold is sampled on the next step")
	f.gate.cargo = CELL
	f.gate.progress = 1.0
	f.gate.phase_ticks = 199
	f.gate.window_s = 1
	f.b.stored_j = 0
	m.advance(Model.STEP, 1)
	driver.expect(f.gate.feedback.latch == "allow" and f.gate.sent == 0 and f.gate.cargo == CELL, "permission cannot bypass closed C1 window")
	f.gate.phase_ticks = 0
	f.g.fuel[CELL] = 5
	m.advance(Model.STEP, 1)
	driver.expect(f.gate.sent == 0 and f.gate.cargo == CELL, "full G holds cargo without spending quota")
	f.g.fuel[CELL] = 4
	m.advance(Model.STEP, 1)
	driver.expect(f.gate.sent == 1 and f.gate.cargo.is_empty(), "actual delivery spends exactly one quota")


func _shared_source() -> void:
	for reverse in [false, true]:
		var f := fixture()
		var m: RefCounted = f.model
		var second_g: Dictionary = m.place("cell_generator", Vector2i(-29, 28)).entity
		var second: Dictionary = m.place("timed_dispatch", Vector2i(-30, 29), 0).entity
		m.actor.x = -30.5
		m.actor.z = 29.5
		m.configure_dispatch(second.id, CELL, 10, 10, 1)
		driver.expect(m.configure_storage_feedback(second.id, f.b.id, Rules.LOW_J, Rules.HIGH_J).ok, "multiple gates can bind one same-grid source")
		m.set_dispatch_active(second.id, true)
		f.b.stored_j = Rules.HIGH_J - 1
		for gate in [f.gate, second]:
			gate.feedback.latch = "allow"
			gate.cargo = CELL
			gate.progress = 1.0
		f.g.enabled = true
		f.g.fuel[CELL] = 1
		m.revision += 1
		if reverse:
			m.entities.reverse()
		m.advance(Model.STEP, 1)
		driver.expect(f.gate.sent == 1 and second.sent == 1 and second_g.fuel[CELL] == 1
			and f.gate.feedback.latch == "allow" and second.feedback.latch == "allow", "all gates use the same pre-charge reading regardless of traversal")
		m.advance(Model.STEP, 1)
		driver.expect(f.gate.feedback.latch == "block" and second.feedback.latch == "block", "both gates observe charging on the following tick")
		m.actor.x = -26.5
		m.actor.z = 24.5
		m.set_device_enabled(f.b.id, false)
		driver.expect(m.salvage(f.b.id, true).ok and f.gate.feedback.source_id == 0 and second.feedback.source_id == 0, "source salvage clears every bound gate")
