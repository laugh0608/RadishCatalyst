extends RefCounted

const Layout := preload("res://scripts/checks/factory_combination_layout.gd")
var c: SceneTree
var route_back: Array = []
var old_solvent := 0


func _init(check: SceneTree) -> void:
	c = check


func go(name: String) -> void:
	var points: Array = Layout.routes()[name]
	if points[0].x == -18: await c.walk(Vector2(-18, 5))
	for point in points:
		await c.walk(point)
		if c.finished: return
	route_back = points.duplicate()


func back() -> void:
	var points := route_back.duplicate()
	points.reverse()
	for point in points:
		await c.walk(point)
		if c.finished: return
	if not points.is_empty() and points.back().x == -18: await c.walk(Vector2(-3.5, 5))
	route_back.clear()


func pause(value: bool) -> void:
	if c.world.ui.paused != value:
		await c.native_click(c.world.discovery_panel.buttons.pause if c.world.discovery_panel.visible else c.world.hud.buttons.pause)
	c.driver.expect(c.world.ui.paused == value, "explicit player pause preference " + str(value))


func close() -> void:
	if c.world.discovery_panel.visible: await c.driver.key(KEY_ESCAPE)


func open_named(name: String) -> void:
	await c._open_nearby(name)


func configure(name: String, item: String, quota: int, accepting: bool = true) -> void:
	await c._configure(name, item, quota)
	if not accepting:
		await open_named(name)
		await c.native_click(c.world.discovery_panel.admission_controls.accepting_button)
		await close()
	c.driver.expect(c.world.model.by_id(c.ids[name]).accepting == accepting, "gate acceptance explicitly configured " + name)


func accepting(name: String, value: bool) -> void:
	await open_named(name)
	if c.world.model.by_id(c.ids[name]).accepting != value:
		await c.native_click(c.world.discovery_panel.admission_controls.accepting_button)
	c.driver.expect(c.world.model.by_id(c.ids[name]).accepting == value, "gate acceptance " + name)
	await close()


func write_journey() -> void:
	var w: Control = c.world
	c.driver.expect(w.model.supply_id == c.Codec.V2.Config.ADMISSION_SUPPLY_ID and w.model.entities.is_empty() and w.model.bag.is_empty(), "C0 ordinary V5 zero-material world")
	await c.native_click(w.hud.buttons.mission)
	await c.walk(Vector2(2.5, 2.5))
	await c.driver.key(KEY_F)
	c.driver.expect(w.model.discovery.sample_taken and w.model.bag.get("crust_sample", 0) == 1, "C0 naturally walked and explicitly collected unique sample")
	await c.walk(Vector2(-3.5, 5))
	await c.walk(Vector2(-18, 5))
	for e in Layout.initial_entities():
		await c.place(e.type, e.x, e.z, e.name, e.dir)
		if c.finished: return
	await c.walk(Vector2(-18, 2))
	await configure("g1", "crystal", 0)
	await c.walk(Vector2(-18, 5))
	await c.walk(Vector2(-10, 5))
	await c.walk(Vector2(-10, 2))
	await configure("g3", "catalyst", 2)
	await c.walk(Vector2(-10, 5))
	await c.walk(Vector2(-3.5, 5))
	await go("g4")
	await configure("g4", "crust_solvent", 4)
	await back()
	await go("solvent")
	await open_named("solvent")
	await c.recipe("solvent_trial")
	await c.native_click(w.discovery_panel.buttons.crust_sample_put_one)
	await close()
	await c.wait_for(func(): return w.model.discovery.trial_completed and w.model.by_id(c.ids.solvent).output.is_empty(), 100, "C0 unique sample plus two natural catalysts produce trial included in first quota")
	if c.finished: return
	await open_named("solvent")
	await c.recipe("crust_solvent")
	await close()
	await back()
	await c.walk(Vector2(-10, 5))
	await c.walk(Vector2(-10, 2))
	await configure("g3", "catalyst", 0)
	await c.walk(Vector2(-10, 5))
	await c.walk(Vector2(-3.5, 5))
	c.stage("C0", "ordinary V5 sample/trial; G4 configured four before first product; trial is part of four")
	await c.wait_for(func(): return w.model.by_id(c.ids.g4).quota_used == 4 and w.model.by_id(c.ids.g4).cargo.is_empty() and w.model.by_id(c.ids.solvent_store).items.get("crust_solvent", 0) == 4, 150, "C1 first round exactly four naturally in solvent warehouse")
	if c.finished: return
	await go("solvent_store")
	await open_named("solvent_store")
	await c.native_click(w.discovery_panel.buttons.crust_solvent_take_all)
	c.driver.expect(w.model.bag.get("crust_solvent", 0) == 4 and w.model.by_id(c.ids.solvent_store).items.is_empty(), "C1 withdraw exactly four actual stored solvent")
	await close()
	await back()
	await c.walk(Vector2(2, 5))
	await c.walk(Vector2(2, 0.5))
	await c.walk(Vector2(2.7, 0.5))
	await c.panel(-1)
	await c.native_click(w.discovery_panel.buttons.outer)
	await close()
	await c.walk(Vector2(8.8, 0.5))
	c.driver.expect(w.model.discovery.passages.outer and w.actor.x > 8 and w.model.bag.get("crust_solvent", 0) == 0, "C1 consume four and physically cross opened outer corridor")
	await c.walk(Vector2(2, 0.5))
	await c.walk(Vector2(2, 5))
	await c.walk(Vector2(-3.5, 5))
	c.stage("C1", "four quota deliveries withdrawn and consumed; outer corridor actually crossed")
	await transition()
	if c.finished: return
	await combination()
	if c.finished: return
	await go("g4")
	await c.wait_for(func():
		var gate: Dictionary = w.model.by_id(c.ids.g4)
		return gate.quota_used == 7 and gate.cargo == "crust_solvent" and gate.progress > 0.1 and gate.progress < 0.5,
		240, "C3 seventh delivery and eighth in partial transit")
	if c.finished: return
	await pause(true)
	await accepting("g4", false)
	var gate: Dictionary = w.model.by_id(c.ids.g4)
	c.driver.expect(gate.quota_used == 7 and gate.cargo == "crust_solvent" and gate.progress > 0 and gate.progress < 1 and not gate.accepting, "C3 exact paused 7 plus held eighth checkpoint")
	c.driver.expect(not c.source_trace.witnesses.is_empty(), "C2 at least one of first seven is proven rich-derived through actual input/active/output/G4")
	c.driver.expect(c.source_trace.source_sent.basic and c.source_trace.source_sent.rich, "C2 both processing sources actually sent output")
	c.driver.expect(c.source_trace.source_invested.basic and c.source_trace.source_invested.rich, "C2 ordinary/rich ores actually invested in their matching processing recipes")
	c.driver.expect(c.source_trace.peak_request_kw > 120 and c.source_trace.peak_deficit_kw < 0.000001, "C2 actual working demand exceeds single source with no sampled shortage on real 240kW grid")
	c.check_failures()
	if c.finished: return
	await c.native_click(w.hud.buttons.save)
	var expected: Dictionary = c.Codec.snapshot(w.model, w.store.world_id, w.store.world_name, w.store.sequence)
	c.driver.expect(c.Codec.decode(expected, w.store.world_id).ok, "C3 natural checkpoint strict inventory/batch/quota contract")
	c.write_json("expected.json", expected)
	c.write_json("ids.json", c.ids)
	c.write_json("source-trace.json", c.source_trace.report())
	c.stage("C3", "natural mixed line; rich provenance witnessed among eight; paused and closed G4 with eighth halfway")
	await c.native_click(w.hud.buttons.return)
	c.driver.expect(c.boot.factory_world == null, "C3 formal save return releases world")


func transition() -> void:
	var w: Control = c.world
	await c.walk(Vector2(-10, 5))
	await c.walk(Vector2(-10, 2))
	await accepting("g3", false)
	await c.walk(Vector2(-10, 5))
	await c.walk(Vector2(-18, 5))
	await c.walk(Vector2(-18, 2))
	await accepting("g1", false)
	await c.walk(Vector2(-18, 5))
	await c.walk(Vector2(-3.5, 5))
	await c.place("storage", -7, 2, "catalyst_store")
	# Remove every old connection through nearby salvage. In-flight goods are
	# returned to the actual bag; none are erased or copied into the new line.
	var before: Dictionary = c.Codec.snapshot(w.model, w.store.world_id, w.store.world_name, w.store.sequence)
	for e in Layout.initial_entities():
		if e.name not in ["g1", "g3"] and e.type != "belt": continue
		var target := Vector2(e.x + 0.5, 1.5)
		await c.walk(Vector2(-3.5, 5))
		await c.walk(Vector2(-3.5, 1.5))
		await c.walk(target)
		await open_named(e.name)
		await pause(true)
		await c.native_click(w.discovery_panel.buttons.salvage)
		c.driver.expect(w.model.entity_at(Vector2i(e.x, e.z)).is_empty(), "C2 nearby lossless salvage of old " + e.name)
		await close()
		await pause(false)
		await c.walk(Vector2(-3.5, 1.5))
		await c.walk(Vector2(-3.5, 5))
		if c.finished: return
	await c.walk(Vector2(-3.5, 5))
	await go("solvent")
	await open_named("solvent")
	await pause(true)
	if w.model.by_id(c.ids.solvent).processing:
		await c.native_click(w.discovery_panel.buttons.cancel_batch)
	for item in ["catalyst", "crust_solvent"]:
		if w.model.Items.contents(w.model.by_id(c.ids.solvent)).get(item, 0) > 0:
			await c.native_click(w.discovery_panel.buttons[item + "_take_all"])
	c.driver.expect(w.model.by_id(c.ids.solvent).input.is_empty() and w.model.by_id(c.ids.solvent).output.is_empty() and not w.model.by_id(c.ids.solvent).processing, "C2 old solvent input/output/investment fully returned")
	await close()
	await pause(false)
	await back()
	old_solvent = w.model.bag.get("crust_solvent", 0)
	await go("catalyst_store")
	await open_named("catalyst_store")
	for item in w.model.DiscoveryRules.ITEMS:
		if w.model.bag.get(item, 0) > 0: await c.native_click(w.discovery_panel.buttons[item + "_put_all"])
	await close()
	await back()
	await go("g4")
	await configure("g4", "crust_solvent", 8, false)
	await back()
	c.write_json("transition.json", {"old_solvent": old_solvent, "before": before, "after": c.Codec.snapshot(w.model, w.store.world_id, w.store.world_name, w.store.sequence), "operation": "nearby salvage seven belts/two gates; cancel and withdraw old solvent contents; all returned material deposited catalyst warehouse"})
	c.stage("C2-transition", "first-line gates/seven belts salvaged; invested material returned; extra old solvent separately retained")


func combination() -> void:
	var w: Control = c.world
	for e in Layout.combination_entities():
		if e.name in ["collector", "basic", "solvent", "solvent_store", "source_a", "node_a", "node_b", "g4", "catalyst_store"]: continue
		await c.place(e.type, e.x, e.z, e.name, e.dir)
		if c.finished: return
	c.driver.expect(w.model.entities.size() == 84, "C2 exact 84-entity ordinary combination layout")
	await go("rich")
	await open_named("rich")
	await c.recipe("rich_catalyst")
	await close()
	await back()
	for setting in [["g1", "crystal"], ["g2", "rich_crystal"], ["g3", "catalyst"]]:
		await go(setting[0])
		await configure(setting[0], setting[1], 0, false)
		await back()
	var power: Dictionary = w.model.power_state()
	var network := -1
	for name in ["collector", "rich_collector", "basic", "rich", "solvent"]:
		var device: Dictionary = power.devices[c.ids[name]]
		if network == -1: network = device.network
		c.driver.expect(device.network == network and w.model.by_id(c.ids[name]).power_node_id != 0, "C2 same automatic network covers " + name)
	c.driver.expect(power.installed_kw == 240 and w.model.grid.groups[network].capacity_kw == 240, "C2 two real enabled sources share 240kW network")
	c.start_trace()
	# Rich path starts first so the finite eight-item round can include an actual
	# enriched batch despite its long inbound journey. Ordinary feed follows.
	await go("g2")
	await accepting("g2", true)
	await back()
	await go("g3")
	await accepting("g3", true)
	await back()
	await go("g4")
	await accepting("g4", true)
	await back()
	await go("g1")
	await accepting("g1", true)
	await back()
	c.stage("C2", "84 actual entities; both original ore types, real 240kW same network; read-only fixed-step provenance active")


func restore_journey(completed: bool, visual: bool) -> void:
	var w: Control = c.world
	c.ids = JSON.parse_string(FileAccess.get_file_as_string(c.run_root.path_join("ids.json")))
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(c.run_root.path_join("expected.json")))
	var actual: Dictionary = c.Codec.snapshot(w.model, w.store.world_id, w.store.world_name, expected.sequence)
	c.driver.expect(c.Check.equivalent(expected, actual), "C5" if completed else "C4" + " first-frame independent Boot full snapshot matches at identical sequence")
	c.check_failures()
	if c.finished: return
	if visual:
		await visual_review()
		return
	if completed:
		await completion_restore()
		return
	var gate: Dictionary = w.model.by_id(c.ids.g4)
	c.driver.expect(gate.quota_used == 7 and gate.cargo == "crust_solvent" and not gate.accepting and gate.progress > 0 and gate.progress < 1, "C4 restores exact closed partial eighth")
	await pause(false)
	await c.wait_for(func(): return gate.quota_used == 8 and gate.cargo.is_empty() and w.model.by_id(c.ids.solvent_store).items.get("crust_solvent", 0) == 8, 12, "C4 closed gate drains exactly eighth into warehouse")
	if c.finished: return
	await accepting("g4", true)
	await c.active(2, "C4 re-enable exhausted quota retains eight")
	c.driver.expect(gate.quota_used == 8 and gate.cargo.is_empty(), "C4 switch does not reset quota or accept ninth")
	await back_to_hub_from_g4()
	var context: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(c.run_root.path_join("transition.json")))
	old_solvent = context.old_solvent
	if w.model.bag.get("crust_solvent", 0) > 0:
		await go("catalyst_store")
		await open_named("catalyst_store")
		await c.native_click(w.discovery_panel.buttons.crust_solvent_put_all)
		await close()
		await back()
	c.driver.expect(w.model.bag.get("crust_solvent", 0) == 0 and w.model.by_id(c.ids.catalyst_store).items.get("crust_solvent", 0) == old_solvent, "C4 all old solvent segregated before withdrawing this round")
	await go("solvent_store")
	await open_named("solvent_store")
	await c.native_click(w.discovery_panel.buttons.crust_solvent_take_all)
	c.driver.expect(w.model.bag.get("crust_solvent", 0) == 8 and w.model.by_id(c.ids.solvent_store).items.get("crust_solvent", 0) == 0, "C4 withdraw only new eight from emptied first-round store")
	await close()
	await back()
	await go("outer")
	await go("inner_approach")
	await c.panel(-1)
	await c.native_click(w.discovery_panel.buttons.inner)
	await close()
	await go("inner_cross")
	c.driver.expect(w.model.discovery.passages.inner and w.actor.x > 24 and w.model.bag.get("crust_solvent", 0) == 0 and w.model.statistics.totals.consumed.crust_solvent == 12, "C4 actual inner crossing consumes new eight, total twelve")
	c.driver.expect(w.model.by_id(c.ids.catalyst_store).items.get("crust_solvent", 0) == old_solvent, "C4 segregated extra old solvent preserved")
	await pause(true)
	await c.native_click(w.hud.buttons.save)
	c.write_json("completion-expected.json", c.Codec.snapshot(w.model, w.store.world_id, w.store.world_name, w.store.sequence))
	c.write_json("completion-context.json", {"old_solvent": old_solvent})
	c.stage("C4", "independent restore; closed eighth drained; exhausted switch retained quota; new eight consumed at inner corridor and physically crossed")
	await c.native_click(w.hud.buttons.return)
	c.driver.expect(c.boot.factory_world == null, "C4 saves completed world and releases lock")


func back_to_hub_from_g4() -> void:
	await close()
	await c.walk(Vector2(-3.5, 5))


func completion_restore() -> void:
	var w: Control = c.world
	var gate: Dictionary = w.model.by_id(c.ids.g4)
	c.driver.expect(w.model.discovery.passages.outer and w.model.discovery.passages.inner and w.model.discovery.sample_taken and w.model.discovery.trial_completed, "C5 both permanent passages and unique trial facts restored")
	c.driver.expect(w.model.statistics.totals.consumed.crust_sample == 1 and w.model.statistics.totals.consumed.crust_solvent == 12 and gate.quota_used == 8 and gate.cargo.is_empty(), "C5 unique sample, twelve opening use and exhausted quota retained")
	var stored: int = w.model.by_id(c.ids.catalyst_store).items.get("catalyst", 0)
	c.start_trace()
	await pause(false)
	await c.wait_for(func(): return w.model.by_id(c.ids.catalyst_store).items.get("catalyst", 0) > stored and c.source_trace.source_sent.basic and c.source_trace.source_sent.rich and c.source_trace.source_completed.basic and c.source_trace.source_completed.rich, 60, "C5 both restored processing sources complete and send actual output, catalyst storage increases")
	c.driver.expect(c.source_trace.source_sent.basic and c.source_trace.source_sent.rich and c.source_trace.source_completed.basic and c.source_trace.source_completed.rich, "C5 both basic/rich source completions and actual outgoing batches witnessed at consecutive fixed steps")
	c.driver.expect(gate.quota_used == 8 and gate.cargo.is_empty(), "C5 continued production cannot evade exhausted quota")
	await pause(true)
	await c.native_click(w.hud.buttons.save)
	c.write_json("completion-read-final.json", c.Codec.snapshot(w.model, w.store.world_id, w.store.world_name, w.store.sequence))
	c.stage("C5", "independent completion restore preserves discoveries/quota; catalyst processing and actual storage continue")
	await c.native_click(w.hud.buttons.return)


func visual_review() -> void:
	var w: Control = c.world
	var before: Dictionary = c.Codec.snapshot(w.model, w.store.world_id, w.store.world_name, w.store.sequence)
	var actor_before := Vector2(w.actor.x, w.actor.z)
	c.write_json("visual-readonly-before.json", before)
	await open_named("g4")
	await c._gate_layout()
	await c.native_shot("01-restored-seven-and-held-eighth")
	var point: Vector2 = Vector2(w.actor.x, w.actor.z)
	await c.driver.key(KEY_W, true)
	await c.driver.settle(8)
	await c.driver.key(KEY_W, false)
	c.driver.expect(Vector2(w.actor.x, w.actor.z) == point and w.keys.is_empty() and w.ui.paused, "C-V device panel absorbs real routed movement without leaking keys")
	await close()
	var original_target: int = w._interaction_target().get("id", -1)
	c.driver.expect(w._interaction_target().get("count", 0) > 1, "C-V multiple nearby devices permit actual Tab cycle")
	await c.driver.key(KEY_TAB)
	c.driver.expect(w._interaction_target().get("id", -1) != original_target, "C-V Tab actually changes nearby highlighted target")
	await c.driver.key(KEY_F)
	c.driver.expect(w.discovery_panel.visible, "C-V F opens the selected nearby device")
	await c.native_shot("02-tab-selected-nearby-device")
	await close()
	await c.driver.key(KEY_I)
	c.driver.expect(w.discovery_panel.inventory_only, "C-V I opens standalone inventory")
	await c.native_shot("03-isolated-inventory")
	await c.driver.key(KEY_I)
	for frame in [
		["04-complete-mixed-line", Vector3(-5, 0, 2.5), 0.7],
		["05-s1-adjacent-two-filters", Vector3(-16.5, 0, 0.8), 2.2],
		["06-basic-rich-processing", Vector3(-11.5, 0, 3.5), 1.4],
		["07-m2-s2-catalyst-allocation", Vector3(-8.2, 0, 1.5), 2.2],
	]:
		w.view.inspection_target = frame[1]
		w.view.zoom = frame[2]
		w.view.yaw = 0
		w.view.sync_camera()
		await c.driver.settle(10)
		await c.driver.shot(frame[0])
	await c.native_click(w.hud.buttons.statistics)
	await c.native_click(w.statistics_panel.buttons.catalyst)
	var scroll: ScrollContainer = w.statistics_panel.body.get_parent()
	scroll.ensure_control_visible(w.statistics_panel.detail_summary)
	await c.driver.settle(8)
	c.driver.expect("在途" in w.statistics_panel.detail_summary.text and "在制原投入" in w.statistics_panel.detail_summary.text, "C-V actual catalyst statistics distinguish transit/invested/storage")
	await c.driver.shot("08-statistics-catalyst-in-transit")
	var locator: Button = w.statistics_panel.buttons["device_%d" % c.ids.basic]
	scroll.ensure_control_visible(locator)
	await c.driver.settle(8)
	await c.native_click(locator)
	c.driver.expect(not w.statistics_panel.visible and w.ui.selected == c.ids.basic and Vector2(w.actor.x, w.actor.z) == actor_before, "C-V actual statistics locate selects basic reactor and leaves actor in place")
	await c.driver.shot("09-statistics-locate-basic")
	await c.driver.key(KEY_ESCAPE)
	await c.native_click(w.hud.buttons.build)
	await c.native_click(w.hud.buttons.admission_gate)
	w.hud.cell_x.value = -3
	w.hud.cell_z.value = 4
	await c.driver.key(KEY_R)
	await c.driver.shot("10-gate-rotated-preview")
	await c.driver.key(KEY_ESCAPE)
	var after: Dictionary = c.Codec.snapshot(w.model, w.store.world_id, w.store.world_name, before.sequence)
	c.write_json("visual-readonly-after.json", after)
	c.driver.expect(c.Check.equivalent(before, after), "C-V paused framing/panels/Tab/F/I/preview/statistics locate preserve complete authoritative state")
	c.stage("C-V-readonly", "C3 original images; 1100x720/1440x900 gate panel; Tab/F/I, absorbed movement, camera framing, rotated ghost and actual statistics locate; full paused state unchanged")
	c.check_failures()
	if c.finished: return
	w.view.inspection_target = null
	w.view.zoom = 1
	w.view.yaw = 25
	w.view.sync_camera()
	# A short, isolated checkpoint demonstration. This changes only the copied
	# review world and does not claim to rerun the C0-C4 natural journey.
	await c.Faults.new(c, self).g4_blocked()
	if c.finished: return
	c.stage("C-V-short-checkpoint-demo", "copied C3 only: real warehouse salvage, held-item rejection, short natural blocked transit, full refund/repair and eighth drain; not a C0-C4 production run")
	await c.native_click(w.hud.buttons.return)
	c.driver.expect(c.boot.factory_world == null, "C-V saves only isolated visual copy and returns")
