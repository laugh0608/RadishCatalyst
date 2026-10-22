extends RefCounted

const CASES := ["raw-closed", "wrong-gap", "sink-blocked", "g4-blocked", "quota-reset", "power-shortage"]
var c: SceneTree
var j: RefCounted
var fault := ""


func _init(check: SceneTree, journey: RefCounted) -> void:
	c = check
	j = journey


func run(id: String) -> void:
	fault = id
	c.driver.expect(id in CASES, "explicit supported independent C fault")
	c.ids = JSON.parse_string(FileAccess.get_file_as_string(c.run_root.path_join("ids.json")))
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(c.run_root.path_join("expected.json")))
	c.driver.expect(c.Check.equivalent(expected, snapshot(expected.sequence)), "C-R independent copy first frame exactly matches C3 parent")
	var gate: Dictionary = entity("g4")
	c.driver.expect(gate.quota_used == 7 and gate.cargo == "crust_solvent" and not gate.accepting and c.world.ui.paused, "C-R requires unconsumed paused seven-plus-held-eighth checkpoint")
	c.check_failures()
	if c.finished: return
	c.stage("C-R-start", "independent C3 copy: " + fault)
	match id:
		"g4-blocked": await g4_blocked()
		"quota-reset": await quota_reset()
		"raw-closed": await raw_closed()
		"wrong-gap": await wrong_gap()
		"sink-blocked": await sink_blocked()
		"power-shortage": await power_shortage()
	if c.finished: return
	await j.close()
	await j.pause(true)
	var final := snapshot()
	c.driver.expect(c.Codec.decode(final, c.world.store.world_id).ok, "C-R final strict material/batch/quota conservation: " + fault)
	c.check_failures()
	if c.finished: return
	await c.native_click(c.world.hud.buttons.save)
	c.write_json("fault-final.json", snapshot())
	c.stage("C-R-complete", "actual isolated fault and recovery: " + fault)
	await c.native_click(c.world.hud.buttons.return)
	c.driver.expect(c.boot.factory_world == null, "C-R formal save-return releases copied world")


func entity(name: String) -> Dictionary:
	return c.world.model.by_id(c.ids[name])


func snapshot(sequence: int = -1) -> Dictionary:
	return c.Codec.snapshot(c.world.model, c.world.store.world_id, c.world.store.world_name, c.world.store.sequence if sequence < 0 else sequence)


func save_evidence(label: String) -> void:
	c.write_json("fault-" + label + ".json", snapshot())


func reach_hub() -> void:
	await j.close()
	await j.pause(false)
	await c.walk(Vector2(-3.5, 5))


func salvage(name: String) -> void:
	await j.open_named(name)
	await c.native_click(c.world.discovery_panel.buttons.salvage)
	c.driver.expect(entity(name).is_empty(), "C-R actual nearby salvage " + name)
	await j.close()


func drain_eighth() -> void:
	await j.pause(false)
	await c.wait_for(func(): return entity("g4").quota_used == 8 and entity("g4").cargo.is_empty() and entity("solvent_store").items.get("crust_solvent", 0) == 8, 12, "C-R naturally finish original eighth before branch-specific operations")


func g4_blocked() -> void:
	# At C3 the actor is within range of both G4 and its downstream warehouse;
	# removal occurs while paused, before the eighth can move.
	var bag_before: int = c.world.model.bag.get("crust_solvent", 0)
	var stored: int = entity("solvent_store").items.get("crust_solvent", 0)
	await salvage("solvent_store")
	c.driver.expect(stored == 7 and c.world.model.bag.get("crust_solvent", 0) == bag_before + 7, "C-R downstream warehouse salvage returns all seven actual solvent")
	await j.pause(false)
	await c.wait_for(func(): return entity("g4").progress >= 0.999, 4, "C-R held eighth reaches missing downstream and blocks")
	await j.open_named("g4")
	await j.pause(true)
	var before := snapshot()
	var controls: Control = c.world.discovery_panel.admission_controls
	controls.limit.value = 9
	await c.driver.settle()
	c.driver.expect(controls.apply_button.disabled and controls.reset_button.disabled, "C-R held gate disables configuration and reset")
	for button in [controls.apply_button, controls.reset_button]:
		var point: Vector2 = button.get_global_rect().get_center()
		await c.driver.motion(point)
		await c.driver.mouse(point, true)
		await c.driver.mouse(point, false)
	await c.native_click(c.world.discovery_panel.buttons.rotate_selected)
	c.driver.expect(c.Check.equivalent(before, snapshot(before.sequence)), "C-R held configuration/reset/rotation attempts preserve full authoritative state")
	c.driver.expect("持货" in controls.hint.text and "货物" in c.world.discovery_panel.result_label.text, "C-R held rejection explains cargo constraint")
	await j.close()
	await j.pause(false)
	await c.active(2, "C-R blocked final cargo remains intact while upstream runs")
	c.driver.expect(entity("g4").quota_used == 7 and entity("g4").cargo == "crust_solvent", "C-R blocked eighth is neither lost nor double-counted")
	await j.pause(true)
	save_evidence("g4-blocked")
	if c.visual_only:
		await j.open_named("g4")
		await c.native_shot("11-eighth-blocked-downstream-missing")
		await j.close()
	await c.place("storage", -2, -1, "solvent_store")
	await j.open_named("solvent_store")
	await c.native_click(c.world.discovery_panel.buttons.crust_solvent_put_all)
	c.driver.expect(entity("solvent_store").items.get("crust_solvent", 0) == 7 and c.world.model.bag.get("crust_solvent", 0) == bag_before, "C-R all seven recovered goods restored through real transfer")
	await j.close()
	await drain_eighth()
	await c.active(2, "C-R repaired final transfer counted once")
	c.driver.expect(entity("g4").quota_used == 8 and entity("g4").cargo.is_empty() and entity("solvent_store").items.get("crust_solvent", 0) == 8, "C-R repair delivers exactly eighth once")
	if c.visual_only:
		await j.pause(true)
		await j.open_named("g4")
		await c.native_shot("12-eight-of-eight-exhausted")
		await j.close()


func quota_reset() -> void:
	await drain_eighth()
	if c.finished: return
	await j.accepting("g4", true)
	await c.active(2, "C-R exhausted gate reopened without reset")
	c.driver.expect(entity("g4").quota_used == 8 and entity("g4").cargo.is_empty() and entity("solvent_store").items.get("crust_solvent", 0) == 8, "C-R enable alone cannot begin a new round")
	await j.open_named("g4")
	await c.native_click(c.world.discovery_panel.admission_controls.reset_button)
	c.driver.expect(entity("g4").quota_used == 0 and entity("g4").accepting and entity("g4").quota_limit == 8, "C-R explicit empty reset starts configured new round")
	await j.close()
	await c.wait_for(func(): return entity("g4").quota_used >= 1 and entity("solvent_store").items.get("crust_solvent", 0) >= 9, 40, "C-R reset permits an actual additional naturally produced solvent")


func raw_closed() -> void:
	await reach_hub()
	await j.go("g2")
	await j.accepting("g2", false)
	await j.back()
	await c.wait_for(func(): return entity("s1").cargo == "rich_crystal" and entity("s1").progress >= 0.999 and entity("g2").cargo.is_empty(), 90, "C-R closed rich receiver leaves rich queue head blocking both incompatible S1 exits")
	if c.finished: return
	var cargo_batch: int = entity("s1").batch
	await c.active(2, "C-R mixed queue cannot skip closed rich head")
	c.driver.expect(entity("s1").cargo == "rich_crystal" and entity("s1").batch == cargo_batch and not entity("g2").accepting, "C-R closed branch holds wrong-for-G1 head intact")
	save_evidence("raw-head-blocked")
	await j.go("g2")
	await j.accepting("g2", true)
	c.start_trace()
	await c.wait_for(func(): return entity("g2").cargo == "rich_crystal", 8, "C-R reopened G2 receives real rich head")
	await j.back()
	await c.wait_for(func(): return c.source_trace.source_sent.rich and c.source_trace.source_completed.rich, 50, "C-R reopening raw gate restores actual rich processing/output")


func wrong_gap() -> void:
	await reach_hub()
	await j.go("g2")
	await j.accepting("g2", false)
	await j.back()
	await j.go("g1")
	await j.accepting("g1", false)
	await c.wait_for(func(): return entity("g1").cargo.is_empty(), 15, "C-R original crystal gate drains before counterexample relocation")
	await j.pause(true)
	await salvage("g1")
	await salvage("belt_-15_0")
	await c.place("belt", -16, 0, "wrong_gap")
	await c.place("admission_gate", -15, 0, "g1")
	await j.configure("g1", "crystal", 0)
	await j.pause(false)
	await c.wait_for(func(): return entity("wrong_gap").cargo == "rich_crystal" and entity("wrong_gap").progress >= 0.999 and entity("g1").cargo.is_empty(), 90, "C-R ordinary gap accepts wrong material before downstream crystal gate rejects it")
	if c.finished: return
	await j.pause(true)
	save_evidence("wrong-gap-blocked")
	var rich_before: int = c.world.model.bag.get("rich_crystal", 0)
	await salvage("wrong_gap")
	c.driver.expect(c.world.model.bag.get("rich_crystal", 0) == rich_before + 1, "C-R wrong gap salvage returns the exact held rich crystal")
	await salvage("g1")
	await c.place("admission_gate", -16, 0, "g1")
	await c.place("belt", -15, 0, "belt_-15_0")
	await j.configure("g1", "crystal", 0)
	await j.pause(false)
	await j.back()
	await j.go("g2")
	await j.accepting("g2", true)
	await j.back()
	c.start_trace()
	await c.wait_for(func(): return c.source_trace.source_sent.basic and c.source_trace.source_sent.rich, 60, "C-R direct adjacent filters restore both real processing branches")
	c.driver.expect(c.world.model.bag.get("rich_crystal", 0) == rich_before + 1, "C-R repaired topology preserves salvaged wrong material in bag")


func s2_sent_to_g3() -> bool:
	for event in c.source_trace.events:
		if event.kind == "s2_handoff" and event.target == "g3": return true
	return false


func sink_blocked() -> void:
	await drain_eighth()
	await j.configure("g4", "crust_solvent", 0)
	await reach_hub()
	await j.go("catalyst_store")
	await salvage("belt_-8_3")
	await j.back()
	await c.wait_for(func(): return entity("belt_-8_1").cargo == "catalyst" and entity("belt_-8_1").progress >= 0.999 and entity("belt_-8_2").cargo == "catalyst", 35, "C-R disconnected storage branch fills its actual intermediate slots")
	if c.finished: return
	c.start_trace()
	await c.wait_for(s2_sent_to_g3, 30, "C-R S2 actually hands catalyst to accepting solvent branch while warehouse branch is blocked")
	await j.go("g3")
	await j.accepting("g3", false)
	await j.back()
	await c.wait_for(func(): return entity("s2").cargo == "catalyst" and entity("s2").progress >= 0.999, 15, "C-R both S2 outlets blocked retains actual cargo")
	await j.pause(true)
	var blocked := entity("s2").duplicate(true)
	save_evidence("s2-all-blocked")
	await j.pause(false)
	await c.active(2, "C-R full blockage conserves held catalyst")
	c.driver.expect(entity("s2").cargo == blocked.cargo and entity("s2").batch == blocked.batch and entity("s2").progress >= 0.999, "C-R all-blocked S2 retains same batch")
	var stored: int = entity("catalyst_store").items.get("catalyst", 0)
	await c.place("belt", -8, 3, "belt_-8_3")
	await j.go("g3")
	await j.accepting("g3", true)
	await j.back()
	await c.wait_for(func(): return entity("catalyst_store").items.get("catalyst", 0) > stored, 15, "C-R repaired storage branch resumes actual catalyst receipt")


func source_approach() -> void:
	for point in [Vector2(-18, 5), Vector2(-21, 5), Vector2(-21, -7), Vector2(-19, -7)]:
		await c.walk(point)
		if c.finished: return


func source_return() -> void:
	for point in [Vector2(-21, -7), Vector2(-21, 5), Vector2(-18, 5), Vector2(-3.5, 5)]:
		await c.walk(point)
		if c.finished: return


func power_shortage() -> void:
	await reach_hub()
	await source_approach()
	await j.open_named("source_a")
	await c.native_click(c.world.discovery_panel.buttons.power_toggle)
	c.driver.expect(not entity("source_a").enabled, "C-R one real source explicitly disabled")
	await j.close()
	await c.wait_for(func():
		var power: Dictionary = c.world.model.power_state()
		return power.request_kw > 120 and power.deficit_kw > 0 and power.available_kw == 120,
		35, "C-R actual working demand exceeds remaining 120kW source")
	if c.finished: return
	var shortage: Dictionary = c.world.model.power_state().duplicate(true)
	var slowed := false
	for device in shortage.devices.values():
		if device.request_kw > 0 and device.fraction > 0 and device.fraction < 1: slowed = true
	c.driver.expect(slowed, "C-R actual active consumers receive fractional work under shortage")
	c.write_json("fault-power-shortage.json", shortage)
	await j.open_named("source_a")
	await c.native_click(c.world.discovery_panel.buttons.power_toggle)
	await j.close()
	await c.wait_for(func(): return c.world.model.power_state().available_kw == 240 and c.world.model.power_state().deficit_kw < 0.000001, 3, "C-R restoring real second source removes actual shortage")
	c.write_json("fault-power-restored.json", c.world.model.power_state())
	await source_return()
