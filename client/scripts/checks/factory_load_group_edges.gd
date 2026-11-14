extends RefCounted

const Model := preload("res://scripts/factory/load_groups_model.gd")
const Rules := Model.Loads
var driver: Node


func _init(check_driver: Node) -> void:
	driver = check_driver


func near(m: RefCounted, e: Dictionary) -> void:
	m.actor.x = e.x - 0.5
	m.actor.z = e.z + 0.5


func fixture() -> Dictionary:
	var m := Model.new()
	m.core.level = 3
	for key in m.research_nodes: m.researched[key] = true
	m.kits.grid_buffer = 3
	m.kits.refinery = 10
	m.kits.assembler = 1
	m.kits.cell_generator = 1
	var b: Dictionary = m.place("grid_buffer", Vector2i(-5, 24)).entity
	var other: Dictionary = m.place("grid_buffer", Vector2i(-5, 27)).entity
	var remote: Dictionary = m.place("grid_buffer", Vector2i(-26, 24)).entity
	var generator: Dictionary = m.place("cell_generator", Vector2i(-29, 24)).entity
	var furnaces: Array[Dictionary] = []
	for z in range(16, 30):
		for x in range(-20, 3):
			var cell := Vector2i(x, z)
			var e := {"type": "refinery", "x": x, "z": z}
			if furnaces.size() < 9 and m.placement("refinery", cell).ok and m.Grid.reachability(m.core, e, m.discovery.passages, m.map_id).ok:
				var placed: Dictionary = m.place("refinery", cell).entity
				placed.input.iron_ore = 2
				furnaces.append(placed)
	driver.expect(furnaces.size() == 9, "fixture has nine actual connected furnaces")
	near(m, b)
	return {"m": m, "b": b, "other": other, "remote": remote, "g": generator, "furnaces": furnaces}


func run() -> void:
	for row in [[-1, "allow", "block"], [0, "allow", "allow"], [19999, "block", "block"],
		[20000, "block", "allow"], [0, "pending", "block"], [19999, "pending", "block"], [20000, "pending", "allow"]]:
		driver.expect(Rules.decision(row[1], row[0]) == row[2], "integer margin edge " + str(row))
	for row in [[99999, 0], [100000, 0], [100001, 0], [100008, 1], [3600000, 60000]]:
		driver.expect(Rules.buffer_w(row[0], 100000, 160) == row[1], "reserve and flooring edge " + str(row))
	_commands()
	_production()
	_lifecycle()
	_topology()
	_budget()
	_physical_merge()
	_cell_recipe()
	_timing_and_cancellation()
	_research_gates()


func _timing_and_cancellation() -> void:
	var slow := fixture()
	var fast := fixture()
	for f in [slow, fast]:
		f.m.configure_load_group(f.b.id, [f.furnaces[0].id, f.furnaces[1].id], 3600000)
		f.m.set_load_group_enabled(f.b.id, true)
	for frame in 300: slow.m.advance(0.1)
	for frame in 1200: fast.m.advance(0.025)
	var codec := preload("res://scripts/factory/save/codec_v15.gd")
	var compare := preload("res://scripts/checks/factory_expansion_compare.gd")
	driver.expect(compare.equivalent(codec.snapshot(slow.m, "fixture", "timing", 1), codec.snapshot(fast.m, "fixture", "timing", 1)), "10 and 40 Hz frame chunks yield identical 600-step control and production")
	var f := fixture()
	var m: RefCounted = f.m
	var member: Dictionary = f.furnaces[0]
	m.advance(m.STEP, 1)
	m.configure_load_group(f.b.id, [member.id], 3600000)
	m.set_load_group_enabled(f.b.id, true)
	near(m, member)
	driver.expect(m.cancel_batch(member.id).ok and not member.processing and m.bag.iron_ore == 2, "cancel returns invested input without removing ownership")
	driver.expect(m.transfer(member.id, "iron_ore", true, true).ok, "return cancelled input through normal transfer")
	m.advance(m.STEP, 1)
	driver.expect(f.b.load_group.latch == "block" and not member.processing and member.input.iron_ore == 2, "cancellation and returned input cannot bypass next sample")
	var before: Dictionary = f.b.load_group.duplicate(true)
	m.actor.x = 20
	m.actor.z = 20
	driver.expect(not m.salvage(member.id, true).ok and f.b.load_group == before, "failed distant salvage preserves membership and cadence")
	# New arrivals between samples consume the saved allow decision without evaluating.
	for e in f.furnaces:
		e.enabled = false
	member.enabled = true
	member.input.clear()
	f.b.load_group.latch = "allow"
	f.b.load_group.evaluation_ticks_left = 10
	member.input.iron_ore = 2
	m.advance(m.STEP, 1)
	driver.expect(member.processing and f.b.load_group.latch == "allow" and f.b.load_group.evaluation_ticks_left == 9, "between-sample arrival uses current allow and advances cadence once")


func _research_gates() -> void:
	var m := Model.new()
	m.actor.x = m.core.x - 0.5
	m.actor.z = m.core.z + 0.5
	m.core.items = Rules.NODE.cost.duplicate()
	var stock: Dictionary = m.core.items.duplicate()
	driver.expect(not m.research(Rules.RESEARCH).ok and m.core.items == stock, "C3 research rejects low core tier without payment")
	m.core.level = 3
	driver.expect(not m.research(Rules.RESEARCH).ok and m.core.items == stock, "C3 research rejects missing C2 without payment")
	m.researched[Rules.Feedback.RESEARCH] = true
	m.core.items.clear()
	driver.expect(not m.research(Rules.RESEARCH).ok and m.core.items.is_empty() and not m.researched.has(Rules.RESEARCH), "C3 research rejects missing stock atomically")


func _commands() -> void:
	var f := fixture()
	var m: RefCounted = f.m
	var ids: Array = f.furnaces.map(func(e): return e.id)
	var initial: Dictionary = f.b.duplicate(true)
	for members in [[], ids, [ids[0], ids[0]], [0], [true], [1.5], [f.b.id], [m.next_id]]:
		driver.expect(not m.configure_load_group(f.b.id, members, 100000).ok and f.b == initial, "reject invalid member list atomically " + str(members))
	for reserve in [-1, 1, 3601000, true, 100000.5, "100000"]:
		driver.expect(not m.configure_load_group(f.b.id, [ids[0]], reserve).ok and f.b == initial, "reject invalid reserve " + str(reserve))
	driver.expect(m.configure_load_group(f.b.id, ids.slice(0, 8), 0).ok, "eight members and zero reserve accepted")
	driver.expect(m.configure_load_group(f.b.id, [ids[0]], 3600000).ok and m.set_load_group_enabled(f.b.id, true).ok, "one member and max reserve accepted")
	m.advance(m.STEP, 1)
	var before: Dictionary = f.b.load_group.duplicate(true)
	driver.expect(m.configure_load_group(f.b.id, [ids[0]], 3600000).ok and f.b.load_group == before, "same config does not reset cadence")
	near(m, f.other)
	driver.expect(not m.configure_load_group(f.other.id, [ids[0]], 100000).ok, "enabled ownership cannot duplicate")
	near(m, f.b)
	m.set_load_group_enabled(f.b.id, false)
	near(m, f.other)
	driver.expect(not m.configure_load_group(f.other.id, [ids[0]], 100000).ok, "disabled ownership remains exclusive")
	near(m, f.remote)
	driver.expect(not m.configure_load_group(f.remote.id, [ids[1]], 100000).ok, "cross-grid configuration rejected")
	m.actor.x = 20
	m.actor.z = 20
	driver.expect(not m.clear_load_group(f.b.id).ok and not m.remove_load_member(f.b.id, ids[0]).ok, "remote control rejected")
	near(m, f.b)
	m.researched.erase(Rules.RESEARCH)
	driver.expect(not m.configure_load_group(f.b.id, [ids[1]], 100000).ok, "research required")


func _production() -> void:
	var f := fixture()
	var m: RefCounted = f.m
	for i in range(5, 9): f.furnaces[i].input.clear()
	m.advance(m.STEP, 1)
	for i in [5, 6]: f.furnaces[i].input.iron_ore = 2
	var members := [f.furnaces[4].id, f.furnaces[5].id, f.furnaces[6].id]
	m.configure_load_group(f.b.id, members, 3600000)
	m.set_load_group_enabled(f.b.id, true)
	var progress: float = f.furnaces[4].progress
	m.advance(m.STEP, 1)
	driver.expect(f.b.load_group.latch == "block" and f.b.load_group.evaluation_ticks_left == 19, "first sample blocks 420 kW and sets cadence")
	driver.expect(f.furnaces[4].progress > progress and not f.furnaces[5].processing and f.furnaces[5].input.iron_ore == 2, "in-flight batch continues; new batch keeps inputs")
	driver.expect(m.work_spec(f.furnaces[5]).standby_kw == 6 and not m.work_spec(f.furnaces[5]).ready, "blocked idle keeps standby")
	var before: Dictionary = f.b.load_group.duplicate(true)
	m.power_state()
	m.load_group_budget(f.b)
	m.feedback(f.furnaces[5])
	driver.expect(f.b.load_group == before, "UI and power queries cannot sample")
	m.advance(19 * m.STEP, 19)
	driver.expect(f.b.load_group.evaluation_ticks_left == 0 and f.b.load_group.latch == "block", "sample held for exactly twenty ticks")
	m.advance(8.0, 160)
	driver.expect(f.furnaces[4].output.get("metal_plate", 0) == 1 and f.furnaces[5].processing and f.b.load_group.latch == "allow", "in-flight finishes and lower demand resumes candidates")
	near(m, f.furnaces[5])
	m.set_device_enabled(f.furnaces[5].id, false)
	progress = f.furnaces[5].progress
	m.advance(1.0, 20)
	driver.expect(f.furnaces[5].progress == progress and not f.furnaces[5].enabled, "manual stop freezes processing despite group allow")
	near(m, f.b)
	m.set_load_group_enabled(f.b.id, false)
	driver.expect(not f.furnaces[5].enabled and f.b.load_group.latch == "pending" and f.b.load_group.evaluation_ticks_left == 0, "takeover never reenables a manual stop")


func _lifecycle() -> void:
	var f := fixture()
	var m: RefCounted = f.m
	var member: Dictionary = f.furnaces[0]
	m.configure_load_group(f.b.id, [member.id], 100000)
	near(m, member)
	var before: Dictionary = f.b.load_group.duplicate(true)
	driver.expect(not m.change_recipe(member.id, "mixed_refining").ok and f.b.load_group == before, "failed recipe edit retains group")
	member.input.clear()
	driver.expect(m.change_recipe(member.id, "mixed_refining").ok and f.b.load_group.latch == "pending", "legal recipe change retains membership and resets")
	driver.expect(m.salvage(member.id, true).ok and f.b.load_group.member_ids.is_empty() and not f.b.load_group.enabled, "last member salvage disables empty group")
	near(m, f.b)
	m.configure_load_group(f.b.id, [f.furnaces[1].id], 100000)
	driver.expect(m.salvage(f.b.id).get("needs_confirmation", false), "even empty-energy grouped storage requires salvage confirmation")
	driver.expect(m.salvage(f.b.id, true).ok and m.load_group_owner(f.furnaces[1].id).is_empty(), "source salvage releases ownership")


func _topology() -> void:
	var f := fixture()
	var m: RefCounted = f.m
	m.configure_load_group(f.b.id, [f.furnaces[0].id], 100000)
	m.set_load_group_enabled(f.b.id, true)
	near(m, f.other)
	m.configure_load_group(f.other.id, [f.furnaces[1].id], 100000)
	driver.expect(not m.set_load_group_enabled(f.other.id, true).ok, "cannot enable a second group in same network")
	# Topology fixture: both configurations were enabled before a merge.
	f.other.load_group.enabled = true
	f.b.load_group.latch = "allow"
	f.other.load_group.latch = "allow"
	driver.expect("合网冲突" in m.load_group_reason(f.b) and "合网冲突" in m.load_group_reason(f.other), "merged groups both fail closed without selecting a winner")
	m.set_load_group_enabled(f.other.id, false)
	driver.expect(m.load_group_reason(f.b).is_empty(), "explicitly disabling one resolves conflict")
	f.furnaces[0].power_node_id = f.g.id
	driver.expect("同一电网" in m.load_group_reason(f.b) and not m.work_spec(f.furnaces[0]).ready, "one split member blocks the entire group immediately")
	m._refresh_automatic_power()
	driver.expect(m.load_group_reason(f.b).is_empty(), "reconnect preserves decision")
	near(m, f.b)
	m.set_device_enabled(f.b.id, false)
	m.advance(m.STEP, 1)
	driver.expect(f.b.load_group.latch == "allow" and "停用" in m.load_group_reason(f.b), "disabled source blocks without erasing history")


func _budget() -> void:
	var f := fixture()
	var m: RefCounted = f.m
	for i in range(1, 9):
		f.furnaces[i].enabled = false
	m.configure_load_group(f.b.id, [f.furnaces[0].id], 100000)
	var budget: Dictionary = m.load_group_budget(f.b)
	driver.expect(budget.ok and budget.horizon_ticks == 160 and budget.demand_w == 60000 and budget.supply_w == 360000, "budget uses full batch duration and excludes disabled loads")
	f.other.stored_j = 3600000
	driver.expect(m.load_group_budget(f.b).supply_w == 360000, "other buffers are not merged into budget")
	f.b.stored_j = 100008
	driver.expect(m.load_group_budget(f.b).buffer_w == 1, "budget floors integer watts")
	# Move the generator into the source network by an explicit topology fixture.
	var network: int = m.load_network(f.b)
	f.g.enabled = true
	m.grid.groups[network].generators.append(f.g.id)
	for row in [[159, 0], [160, 120000], [161, 120000], [0, 0]]:
		f.g.burn_remaining_ticks = row[0]
		f.g.fuel.industrial_cell = 5
		driver.expect(m.load_group_budget(f.b).supply_w == 360001 + row[1], "active G horizon; cached cells excluded " + str(row))
	f.furnaces[0].input.clear()
	driver.expect(not m.load_group_budget(f.b).ok, "no candidates does not invent a horizon")


func _physical_merge() -> void:
	var f := fixture()
	var m: RefCounted = f.m
	var remote_member: Dictionary = m.place("refinery", Vector2i(-29, 27)).entity
	m.configure_load_group(f.b.id, [f.furnaces[0].id], 100000)
	driver.expect(m.set_load_group_enabled(f.b.id, true).ok, "core group enables independently")
	near(m, f.remote)
	driver.expect(m.configure_load_group(f.remote.id, [remote_member.id], 100000).ok and m.set_load_group_enabled(f.remote.id, true).ok, "remote grid group enables independently")
	var bridge: Dictionary
	for cell in [Vector2i(-18, 25)]:
		var placed: Dictionary = m.place("power_junction", cell)
		driver.expect(placed.ok, "place actual bridge node " + str(cell))
		if placed.ok: bridge = placed.entity
	driver.expect("合网冲突" in m.load_group_reason(f.b) and "合网冲突" in m.load_group_reason(f.remote), "actual placement merges two grids and blocks both groups")
	near(m, bridge)
	driver.expect(m.salvage(bridge.id, true).ok and m.load_network(f.b) != m.load_network(f.remote), "actual bridge removal splits grids again")
	driver.expect(m.load_group_binding(f.b).ok and m.load_group_binding(f.remote).ok, "split clears both conflicts without erasing configurations")


func _cell_recipe() -> void:
	var f := fixture()
	var m: RefCounted = f.m
	for i in [0, 1]:
		near(m, f.furnaces[i])
		driver.expect(m.salvage(f.furnaces[i].id, true).ok, "clear assembler footprint in fixture")
	var a: Dictionary = m.place("assembler", Vector2i(-11, 19)).entity
	near(m, f.b)
	driver.expect(m.configure_load_group(f.b.id, [a.id], 100000).ok, "non-cell assembler joins")
	near(m, a)
	driver.expect(m.change_recipe(a.id, Rules.EXCLUDED_RECIPE).ok and f.b.load_group.member_ids.is_empty() and not f.b.load_group.enabled, "cell recipe atomically leaves the group")
	near(m, f.b)
	driver.expect(not m.configure_load_group(f.b.id, [a.id], 100000).ok, "cell assembly cannot rejoin")
