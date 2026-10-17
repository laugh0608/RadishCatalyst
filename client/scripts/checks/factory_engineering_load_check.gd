extends "res://scripts/checks/factory_engineering_prepare_check.gd"

const Layout := Preparation.Layout
const Items := Preparation.Items
var model: RefCounted
var actions: RefCounted
var mode := ""
var details := {}


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
		if arg.begins_with("--mode="): mode = arg.trim_prefix("--mode=")
	if evidence.is_empty(): quit(2); return
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("source.json")))
	engineering_id = source.world_id
	save_sequence = int(source.sequence)
	var decoded := Codec.decode(source, engineering_id)
	expect(decoded.ok, "strict untouched prepared source")
	if not decoded.ok: _finish(); return
	model = decoded.model
	actions = Preparation.new(self)
	actions.model = model
	match mode:
		"capacity": _capacity()
		"density": _density()
		"repair": _repair()
		"competition": _competition()
		_: expect(false, "unknown load probe mode")
	if failures.is_empty():
		var final_doc := doc(model)
		var restored := Codec.decode(final_doc, engineering_id)
		expect(restored.ok, "strict probe endpoint: " + restored.get("reason", ""))
		write_json(evidence.path_join("endpoint.json"), final_doc)
	if actions != null: write_json(evidence.path_join("commands.json"), actions.commands)
	_finish()


func _finish() -> void:
	write_json(evidence.path_join("result.json"), {"mode": mode, "assertions": assertions, "failures": failures,
		"details": details, "scope": "Independent prepared copy, explicit fixed-step model probe; no foreground or performance claim"})
	print("Engineering %s: %d assertions, %d failures" % [mode, assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _capacity() -> void:
	var observer := Observer.new(model)
	var phases := []
	for phase in 4:
		var before := observer.counts.duplicate(true)
		observer.advance(9000)
		var delta := []
		for index in 20:
			var row := {}
			for key in ["catalyst", "solvent", "upper-store", "lower-store"]:
				row[key] = observer.counts[index][key] - before[index][key]
				expect(row[key] > 0, "450-second phase %d cell %d %s" % [phase, index, key])
			delta.append(row)
		phases.append(delta)
		print("Capacity phase %d complete, max warehouse %d" % [phase + 1, observer.max_store])
	observer.advance(2000)
	observer.assert_work(self, "1900-second continuation plus prepared 600")
	for index in 20:
		var c: Dictionary = observer.cells[index]
		var limit := 188 if c.collector.mineral == "rich_crystal" else 175
		for name in ["upper-store", "lower-store"]:
			expect(Items.count(c[name].items) <= limit, "2500-second approved warehouse bound %d %s" % [index, name])
	details = {"phases": phases, "observation": observer.report(), "total_full_layout_seconds": 2500}


func _density_counts() -> Dictionary:
	var ordinary := 0
	var attachments := 0
	var outputs := 0
	var free_storage := 0
	var free_inputs := 0
	var raw_full := true
	for e in model.entities:
		if model.Logistics.transport(e) and not e.cargo.is_empty():
			if e.type == "belt": ordinary += 1
			else: attachments += 1
		if e.type == "reactor":
			outputs += Items.count(e.output)
			for item in model.DiscoveryRules.RECIPES[e.recipe_id].input:
				free_inputs += model.input_room(e, item)
		if e.type == "storage": free_storage += 200 - Items.count(e.items)
	for index in 20:
		var cell := Layout.ids(model, index)
		for name in cell:
			if name.begins_with("raw-") and model.by_id(cell[name]).cargo.is_empty(): raw_full = false
	return {"total": ordinary + attachments, "belts": ordinary, "attachments": attachments,
		"reactor_outputs": outputs, "warehouse_free": free_storage, "reactor_input_free": free_inputs, "raw_belts_full": raw_full,
		"lower_after_power_off": ordinary + attachments - free_storage - free_inputs,
		"upper_after_power_off": ordinary + attachments + outputs}


func _density() -> void:
	# Quota changes are explicit commands on empty gates, never counter assignments.
	for index in 20:
		actions.names = Layout.ids(model, index)
		if not actions.near("g3"): return
		if not actions.require(model.set_admission_accepting(actions.names.g3, false), "stop G3 before density configuration"): return
		for step in 80:
			if model.by_id(actions.names.g3).cargo.is_empty(): break
			model.advance(0.05, 1)
		if not actions.require(model.configure_admission(actions.names.g3, "catalyst", "unlimited", 0), "density unlimited bypass"): return
		if not actions.require(model.set_admission_accepting(actions.names.g3, true), "density resume G3"): return
	var start_tick: int = model.statistics.ticks
	var target := {}
	for second in 8000:
		model.advance(1, 20)
		var state := _density_counts()
		if second % 600 == 0: print("Density preparation %ds, transport %d, warehouse free %d" % [second, state.total, state.warehouse_free])
		if state.raw_belts_full and state.lower_after_power_off >= 910 and state.upper_after_power_off <= 995:
			target = state
			break
	expect(not target.is_empty(), "natural density with proven 910..995 post-stop bound")
	if target.is_empty(): return
	for index in 20:
		actions.names = Layout.ids(model, index)
		if not actions.near("g1"): return
		if not actions.require(model.set_admission_accepting(actions.names.g1, false), "density stop raw admission"): return
		for name in ["source-a", "source-b"]:
			if not actions.near(name): return
			if not actions.require(model.set_source_enabled(actions.names[name], false), "density finite power off"): return
	var observation := _natural_cargo(600)
	expect(observation.minimum >= 900 and observation.maximum <= 1000 and observation.transfers > 0, "30 seconds natural high-density logistics in agreed range")
	var repair_observations := []
	for index in [1, 3, 4]:
		var selected := Layout.ids(model, index)
		expect(not model.by_id(selected["bypass-10"]).cargo.is_empty(), "density repair targets an actually occupied belt")
		if not failures.is_empty(): return
		if not _repair_belt(index, "bypass-10"): return
		repair_observations.append(_natural_cargo(100))
	for row in repair_observations:
		expect(row.minimum >= 900 and row.maximum <= 1000 and row.transfers > 0, "density gap repair moves cargo without leaving range")
	details = {"preparation_steps": model.statistics.ticks - start_tick - 900, "candidate": target,
		"natural_30_seconds": observation, "repairs": repair_observations, "final": _density_counts(),
		"bag_retained": model.bag.duplicate(), "power": model.power_state(),
		"classification": "raw admission stopped, all finite sources disabled; actual passive congestion and repair, not continuous production performance"}


func _natural_cargo(steps: int) -> Dictionary:
	var minimum := 1120
	var maximum := 0
	var transfers := 0
	for step in steps:
		var moving := []
		for e in model.entities:
			if model.Logistics.transport(e) and not e.cargo.is_empty() and e.progress >= 0.95 - 1e-9: moving.append(e)
		model.advance(0.05, 1)
		for e in moving:
			if e.cargo.is_empty(): transfers += 1
		var count := 0
		for e in model.entities:
			if model.Logistics.transport(e) and not e.cargo.is_empty(): count += 1
		minimum = mini(minimum, count)
		maximum = maxi(maximum, count)
	return {"seconds": steps * 0.05, "minimum": minimum, "maximum": maximum, "transfers": transfers}


func _repair_belt(index: int, name: String) -> bool:
	actions.names = Layout.ids(model, index)
	var e: Dictionary = model.by_id(actions.names[name])
	var row := {"x": e.x, "z": e.z, "dir": e.dir}
	var held: Dictionary = model.material_balance().held
	if not actions.near(name): return false
	var before := doc(model)
	expect(not model.salvage(model.next_id + 100).ok and Compare.equivalent(before, doc(model)), "wrong recovery target cannot mutate another entity")
	if not actions.require(model.salvage(e.id), "lossless belt salvage %d %s" % [index, name]): return false
	if not actions.require(model.place("belt", Vector2i(row.x, row.z), row.dir), "rebuild belt at original position"): return false
	expect(model.material_balance().held == held and model.kits.belt == 0, "repair preserves every physical item and belt kit")
	return true


func _repair() -> void:
	for index in [0, 1, 4]:
		if not _repair_belt(index, "raw-4"): return
	for e in model.entities:
		if e.type == "power_source" and e.id != Layout.ids(model, 0)["source-a"]:
			if not actions.require(Layout.walk(model, Vector2.ZERO, e), "walk source shutdown"): return
			if not actions.require(model.set_source_enabled(e.id, false), "disable all but one source"): return
	var deficit: Dictionary = model.power_state()
	expect(deficit.installed_kw == 4800 and deficit.available_kw == 120 and deficit.request_kw > 120 and deficit.deficit_kw > 0, "finite one-source overload really exists")
	var proportional := true
	for device in deficit.devices.values():
		if device.request_kw > 0: proportional = proportional and absf(device.fraction - 120.0 / deficit.request_kw) < 1e-8
	expect(proportional, "overload distributes actual proportional work")
	model.advance(2, 40)
	write_json(evidence.path_join("deficit.json"), doc(model))
	for e in model.entities:
		if e.type == "power_source" and not e.enabled:
			if not actions.require(Layout.walk(model, Vector2.ZERO, e), "walk source restore"): return
			if not actions.require(model.set_source_enabled(e.id, true), "restore finite source"): return
	var cell := Layout.ids(model, 0)
	var node: Dictionary = model.by_id(cell.node)
	var old := Vector2i(node.x, node.z)
	if not actions.require(Layout.walk(model, Vector2.ZERO, node), "walk node relocation"): return
	if not actions.require(model.salvage(node.id, true), "confirmed node disconnect"): return
	var moved: Dictionary = model.place("power_junction", old + Vector2i(0, -1))
	if not actions.require(moved, "temporary legal node position"): return
	var moved_edges: int = model.power_links.size()
	if not actions.require(Layout.walk(model, Vector2.ZERO, moved.entity), "walk relocated node"): return
	if not actions.require(model.salvage(moved.entity.id, true), "recover relocated node"): return
	if not actions.require(model.place("power_junction", old), "restore original node geometry"): return
	model.advance(2, 40)
	var power: Dictionary = model.power_state()
	expect(power.available_kw == 4800 and power.deficit_kw == 0 and model.power_links.size() == 198, "power and original topology restored")
	details = {"overload": deficit, "restored": power, "relocated_edge_count": moved_edges, "held": model.material_balance(), "bag_retained": model.bag.duplicate()}


func _competition() -> void:
	var cell := Layout.ids(model, 1)
	var gate: Dictionary = model.by_id(cell.g3)
	var found := false
	for tick in 40000:
		model.advance(0.05, 1)
		if gate.quota_used == 127 and not gate.cargo.is_empty():
			found = true
			break
	expect(found, "natural rich bypass reaches 127 plus one held")
	if not found: return
	write_json(evidence.path_join("quota-held.json"), doc(model))
	actions.names = cell
	if not actions.near("g3"): return
	if not actions.require(model.set_admission_accepting(gate.id, false), "stop receiving last quota item"): return
	write_json(evidence.path_join("quota-stopped-held.json"), doc(model))
	for tick in 1200:
		model.advance(0.05, 1)
		if gate.quota_used == 128 and gate.cargo.is_empty(): break
	expect(gate.quota_used == 128 and gate.cargo.is_empty() and not gate.accepting, "last held item drains into exhausted closed gate")
	write_json(evidence.path_join("quota-exhausted.json"), doc(model))
	if not actions.require(model.reset_admission(gate.id), "explicit empty quota reset"): return
	expect(gate.quota_used == 0 and not gate.accepting and gate.quota_limit == 128, "reset preserves limit and receive switch")
	write_json(evidence.path_join("quota-reset.json"), doc(model))
	if not actions.require(model.set_admission_accepting(gate.id, true), "resume reset bypass"): return
	# Remove the downstream distributor legally to accumulate two real contenders.
	var wins := {"solvent": 0, "bypass": 0}
	for trial in 2:
		cell = Layout.ids(model, 1)
		actions.names = cell
		var split: Dictionary = model.by_id(cell.distribute)
		var at := Vector2i(split.x, split.z)
		if not actions.near("distribute"): return
		if not actions.require(model.salvage(split.id), "hold merger output by recovering distributor"): return
		var merge: Dictionary = model.by_id(cell.merge)
		var solvent: Dictionary = model.by_id(cell["solvent-0"])
		gate = model.by_id(cell.g3)
		var ready := false
		for tick in 2400:
			model.advance(0.05, 1)
			if not merge.cargo.is_empty() and not solvent.cargo.is_empty() and solvent.progress >= 1 and not gate.cargo.is_empty() and gate.progress >= 1:
				ready = true
				break
		expect(ready, "two real ready merger contenders under downstream block")
		if not ready: return
		if not actions.require(model.place("splitter", at), "restore distributor for contention"): return
		model.advance(0.05, 1) # Drain the previously held merger item.
		expect(merge.cargo.is_empty(), "merger emptied before actual simultaneous contention")
		model.advance(0.05, 1)
		var winner := "solvent" if merge.input_cursor == 2 else "bypass"
		wins[winner] += 1
		expect(not merge.cargo.is_empty(), "real contention selects one actual input")
	expect(wins.solvent == 1 and wins.bypass == 1, "two real simultaneous contentions alternate winner")
	details = {"wins": wins, "quota_checkpoints": ["quota-held.json", "quota-stopped-held.json", "quota-exhausted.json", "quota-reset.json"], "bag_retained": model.bag.duplicate()}
