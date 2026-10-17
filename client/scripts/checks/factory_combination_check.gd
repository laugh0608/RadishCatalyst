extends SceneTree

const Layout := preload("res://scripts/checks/factory_combination_layout.gd")
const Model := preload("res://scripts/factory/admission_model.gd")
const Codec := preload("res://scripts/factory/save/codec.gd")
const Compare := preload("res://scripts/checks/factory_discovery_check.gd")
const Rules := preload("res://data/factory/discovery_rules.gd")
const Items := preload("res://scripts/factory/items.gd")
const REPLAY_STEPS := 400
var checks := 0
var failures: Array[String] = []
var evidence := ""
var source_path := ""
var source_kind := "explicit-snapshot"
var metadata := {"world_id": "cccccccccccccccccccccccccccccccc", "name": "C 状态夹具", "sequence": 1}
var observations := {}


func _init() -> void:
	call_deferred("run")


func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)


func run() -> void:
	var args := OS.get_cmdline_user_args()
	for arg in args:
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
		if arg.begins_with("--snapshot="): source_path = arg.trim_prefix("--snapshot=")
		if arg.begins_with("--source-kind="): source_kind = arg.trim_prefix("--source-kind=")
	if evidence.is_empty():
		evidence = SliceCheckPaths.check_run("factory-conveyor-combination-v1", false).path_join("state-%d-%d" % [Time.get_unix_time_from_system(), OS.get_process_id()])
	expect(evidence.is_absolute_path(), "evidence uses an absolute isolated directory")
	if not evidence.is_absolute_path(): quit(1); return
	expect(DirAccess.make_dir_recursive_absolute(evidence) == OK, "create evidence directory")
	var mode := "geometry" if "--geometry" in args else "state"
	if "--read" in args:
		mode = "process-read"
		_restore()
	else:
		_geometry()
		if mode == "state":
			_fault_commands()
			_natural_snapshot()
	write_json("geometry-result.json" if mode == "geometry" else "read-result.json" if mode == "process-read" else "state-result.json", {
		"assertions": checks, "failures": failures, "mode": mode,
		"evidence_scope": "constructed geometry and synthetic cargo command fixtures; source-derived fixed-step state replay when snapshot supplied; no natural Boot or window claims",
		"source_snapshot": source_path, "source_kind": source_kind, "observations": observations,
	})
	print("Combination %s: %d assertions, %d failures" % [mode, checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func write_json(name: String, value: Variant) -> void:
	var file := FileAccess.open(evidence.path_join(name), FileAccess.WRITE)
	expect(file != null, "open evidence " + name)
	if file != null:
		file.store_string(JSON.stringify(value, "\t", false, true))
		file.close()


func _fixture(rows: Array[Dictionary], opened: bool) -> Dictionary:
	var model := Model.new()
	model.discovery.passages.outer = opened
	var ids := {}
	for row in rows:
		var result: Dictionary = model.place(row.type, Vector2i(row.x, row.z), row.dir)
		expect(result.ok, "geometry placement %s: %s" % [row.name, result.get("reason", "")])
		if result.ok: ids[row.name] = result.entity.id
	return {"model": model, "ids": ids}


func _chain(targets: Dictionary, chain: Array) -> void:
	for i in range(chain.size() - 1):
		if not targets.has(chain[i]): targets[chain[i]] = []
		targets[chain[i]].append(chain[i + 1])


func _targets() -> Dictionary:
	var targets := {}
	_chain(targets, ["collector", "m1", "s1", "g1", "belt_-15_0", "belt_-14_0", "basic", "belt_-10_0", "m2", "s2", "g3", "solvent", "g4", "solvent_store"])
	var rich: Array = ["s1", "g2"]
	for z in range(2, 8): rich.append("belt_-17_%d" % z)
	for x in range(-17, -13): rich.append("belt_%d_8" % x)
	rich.append_array(["rich", "belt_-10_8"])
	for z in range(8, 0, -1): rich.append("belt_-9_%d" % z)
	rich.append("m2")
	_chain(targets, rich)
	_chain(targets, ["s2", "belt_-8_1", "belt_-8_2", "belt_-8_3", "catalyst_store"])
	var ore: Array = ["rich_collector", "belt_12_0"]
	for x in range(12, 1, -1): ore.append("belt_%d_1" % x)
	for z in range(1, -3, -1): ore.append("belt_1_%d" % z)
	for x in range(1, -18, -1): ore.append("belt_%d_-3" % x)
	ore.append_array(["belt_-18_-3", "belt_-18_-2", "belt_-18_-1", "m1"])
	_chain(targets, ore)
	return targets


func _geometry() -> void:
	var initial := _fixture(Layout.initial_entities(), false)
	var combined := _fixture(Layout.combination_entities(), true)
	var model: RefCounted = combined.model
	var ids: Dictionary = combined.ids
	expect(initial.model.entities.size() == 17 and model.entities.size() == 84, "initial/final entity counts are 17/84")
	var counts := {}
	for row in Layout.combination_entities(): counts[row.type] = counts.get(row.type, 0) + 1
	expect(counts == {"collector": 2, "reactor": 3, "storage": 2, "power_source": 2, "power_junction": 4, "merger": 2, "splitter": 2, "admission_gate": 4, "belt": 63}, "exact final type counts and 63 belts")
	for key in model.kits:
		expect(model.kits[key] + counts.get(key, 0) == Rules.admission_supply()[key], "ordinary supply conservation " + key)
	var initial_rows := {}
	for row in Layout.initial_entities(): initial_rows[row.name] = row
	var retained: Array[String] = []
	var relocated: Array[String] = []
	for row in Layout.combination_entities():
		if not initial_rows.has(row.name): continue
		if initial_rows[row.name] == row: retained.append(row.name)
		else: relocated.append(row.name)
	retained.sort()
	relocated.sort()
	expect(relocated == ["g1", "g3"], "only reused named gates relocate; driver must salvage and replace")
	for name in ["collector", "basic", "solvent", "solvent_store", "source_a", "node_a", "node_b"]:
		expect(name in retained, "retained initial device " + name)
	var targets := _targets()
	var actual_connections := {}
	for name in ids:
		var e: Dictionary = model.by_id(ids[name])
		if e.type in ["storage", "power_source", "power_junction"]: continue
		var actual: Array[String] = []
		for port in model.Logistics.ports(model, e, "output"):
			var connection: Dictionary = model.Logistics.output_connection(model, port)
			if connection.ok:
				actual.append(str(ids.find_key(connection.target.id)))
				expect(model.Logistics.receiving_port(model, connection.target, port) == connection.input, "opposing receiving port " + name)
			else:
				expect(e.type == "splitter", "only unused splitter outlet can be disconnected " + name)
		var expected: Array = targets.get(name, []).duplicate()
		actual.sort()
		expected.sort()
		expect(actual == expected, "exact connected targets %s: %s" % [name, str(actual)])
		expect(actual.size() == (2 if e.type == "splitter" else 1), "output count " + name)
		actual_connections[name] = actual
	model.power_state()
	var group: int = model.grid.membership[ids.source_a]
	for name in ["source_b", "node_a", "node_b", "node_c", "node_d"]:
		expect(model.grid.membership[ids[name]] == group, "same actual electrical network " + name)
	var expected_links: Array = []
	var power_chain: Array = ["source_a", "node_a", "node_b", "node_c", "node_d", "source_b"]
	for i in range(power_chain.size() - 1):
		expected_links.append([mini(ids[power_chain[i]], ids[power_chain[i + 1]]), maxi(ids[power_chain[i]], ids[power_chain[i + 1]])])
	expected_links.sort_custom(func(a, b): return a[0] < b[0] or (a[0] == b[0] and a[1] < b[1]))
	expect(model.power_links == expected_links, "exact five-link automatic grid chain")
	for name in ["collector", "rich_collector", "basic", "rich", "solvent"]:
		var e: Dictionary = model.by_id(ids[name])
		expect(e.power_node_id != 0 and model.grid.membership.get(e.power_node_id, -1) == group, "consumer actually attached " + name)
	# 此过渡服务廊只适用于初始七带和新建催化剂仓；最终 G2 会占路。
	var service: Array = [Vector2(-3.5, 5), Vector2(-3.5, 1.5), Vector2(-17.5, 1.5)]
	expect(initial.model.place("storage", Vector2i(-7, 2)).ok, "initial transition catalyst store placement")
	_sample_route(initial.model, "initial_service", service)
	for row in Layout.initial_entities():
		if row.name not in ["g1", "g3"] and row.type != "belt": continue
		initial.model.actor.x = row.x + 0.5
		initial.model.actor.z = 1.5
		expect(not initial.model.blocked_for_actor(initial.model.actor.x, initial.model.actor.z), "initial recovery service point remains walkable " + row.name)
		expect(initial.model.near_entity(initial.model.by_id(initial.ids[row.name])), "initial recovery endpoint reaches " + row.name)
	var routes := Layout.routes()
	for name in routes:
		if name == "inner_cross": continue
		_sample_route(model, name, routes[name])
		if ids.has(name):
			var point: Vector2 = routes[name].back()
			model.actor.x = point.x
			model.actor.z = point.y
			expect(model.near_entity(model.by_id(ids[name])), "route endpoint interaction permission " + name)
	var outer: Vector2 = routes.outer.back()
	model.actor.x = outer.x
	model.actor.z = outer.y
	expect(model.near_entity(model.by_id(ids.rich_collector)), "outer endpoint reaches rich collector")
	var inner: Vector2 = routes.inner_approach.back()
	model.actor.x = inner.x
	model.actor.z = inner.y
	expect(model.near_passage("inner"), "inner approach is within legal opening range")
	model.discovery.passages.inner = true
	_sample_route(model, "inner_cross", routes.inner_cross)
	write_json("layout.json", {"rows": Layout.combination_entities(), "initial": Layout.initial_entities(), "connections": actual_connections, "power_links": model.power_links, "counts": counts, "retained": retained, "relocated": relocated, "scope": "constructed geometry; explicit passage flags and actor samples"})


func _sample_route(model: RefCounted, name: String, points: Array) -> void:
	for i in range(points.size() - 1):
		var first: Vector2 = points[i]
		var last: Vector2 = points[i + 1]
		var samples := ceili(first.distance_to(last) / 0.05)
		for sample in samples + 1:
			var point := first.lerp(last, float(sample) / maxi(1, samples))
			expect(not model.blocked_for_actor(point.x, point.y), "0.05 route sample %s %s" % [name, str(point)])


func _near(model: RefCounted, e: Dictionary) -> void:
	model.actor.x = e.x + 0.5
	model.actor.z = e.z + 1.5


func _configure(model: RefCounted, e: Dictionary, item: String, limit := 0) -> void:
	_near(model, e)
	expect(model.configure_admission(e.id, item, "unlimited" if limit == 0 else "quota", limit).ok, "fixture configure " + item)
	expect(model.set_admission_accepting(e.id, true).ok, "fixture enable " + item)


func _contents(model: RefCounted) -> Dictionary:
	var result: Dictionary = model.bag.duplicate()
	for e in model.entities: Items.merge(result, Items.contents(e))
	return result


func _fault_commands() -> void:
	# Deliberately synthetic inventories isolate commands/arbitration; never decoded
	# as a legal natural world and never used as a Boot production checkpoint.
	var f := _fixture(Layout.combination_entities(), true)
	var model: RefCounted = f.model
	var ids: Dictionary = f.ids
	var s1: Dictionary = model.by_id(ids.s1)
	var g1: Dictionary = model.by_id(ids.g1)
	var g2: Dictionary = model.by_id(ids.g2)
	_configure(model, g1, "crystal")
	_configure(model, g2, "rich_crystal")
	s1.cargo = "rich_crystal"
	s1.progress = 1.0
	var held := _contents(model)
	model._logistics(0.05)
	expect(s1.cargo.is_empty() and g1.cargo.is_empty() and g2.cargo == "rich_crystal" and _contents(model) == held, "S1 rejects wrong filter and retries rich branch without loss")
	_near(model, g1)
	model.set_admission_accepting(g1.id, false)
	s1.cargo = "crystal"
	s1.progress = 1.0
	held = _contents(model)
	var cursor: int = s1.output_cursor
	model._logistics(0.05)
	expect(s1.cargo == "crystal" and s1.output_cursor == cursor and _contents(model) == held, "closed ordinary branch holds head cargo rather than bypassing queue")
	model.set_admission_accepting(g1.id, true)
	model._logistics(0.05)
	expect(s1.cargo.is_empty() and g1.cargo == "crystal" and _contents(model) == held, "reopening correct filter resumes head cargo")
	var s2: Dictionary = model.by_id(ids.s2)
	var g3: Dictionary = model.by_id(ids.g3)
	var branch: Dictionary = model.by_id(ids["belt_-8_1"])
	_configure(model, g3, "catalyst")
	s2.cargo = "catalyst"
	s2.progress = 1.0
	branch.cargo = "catalyst"
	branch.progress = 0.0
	held = _contents(model)
	model._logistics(0.05)
	expect(s2.cargo.is_empty() and g3.cargo == "catalyst" and _contents(model) == held, "S2 skips occupied inventory branch for available formulation branch")
	s2.cargo = "catalyst"
	s2.progress = 1.0
	cursor = s2.output_cursor
	held = _contents(model)
	model._logistics(0.05)
	expect(s2.cargo == "catalyst" and s2.output_cursor == cursor and _contents(model) == held and model.feedback(s2).kind == "blocked", "all S2 branches blocked retain cargo cursor and diagnostic")
	_near(model, branch)
	expect(model.salvage(branch.id).ok and _contents(model) == held, "salvaging held obstructing segment returns complete cargo")
	expect(model.place("belt", Vector2i(-8, 1), 1).ok, "replace repaired branch using returned kit")
	model._logistics(0.05)
	expect(s2.cargo.is_empty() and _contents(model) == held, "repaired branch resumes without loss")
	var g4: Dictionary = model.by_id(ids.g4)
	_configure(model, g4, "crust_solvent", 8)
	g4.quota_used = 7
	g4.cargo = "crust_solvent"
	g4.batch = 1
	g4.progress = 0.4
	_near(model, g4)
	var before := Codec.snapshot(model, metadata.world_id, metadata.name, 1)
	expect(not model.configure_admission(g4.id, "crystal", "unlimited", 0).ok and not model.reset_admission(g4.id).ok and not model.rotate(g4.id).ok and Codec.snapshot(model, metadata.world_id, metadata.name, 1) == before, "held eighth item rejects configuration reset and rotation atomically")
	model.bag = {"crystal": 200}
	before = Codec.snapshot(model, metadata.world_id, metadata.name, 1)
	expect(not model.salvage(g4.id).ok and Codec.snapshot(model, metadata.world_id, metadata.name, 1) == before, "full bag rejects whole held-gate recovery without mutation")
	model.bag = {}
	held = _contents(model)
	expect(model.salvage(g4.id).ok and _contents(model) == held and model.bag.crust_solvent == 1, "held gate salvage returns kit and cargo without material loss")
	_gap_counterexample()


func _gap_counterexample() -> void:
	var model := Model.new()
	var split: Dictionary = model.place("splitter", Vector2i(-14, -6)).entity
	var gap: Dictionary = model.place("belt", Vector2i(-13, -6)).entity
	var gate: Dictionary = model.place("admission_gate", Vector2i(-12, -6)).entity
	_configure(model, gate, "crystal")
	split.cargo = "rich_crystal"
	split.progress = 1.0
	var held := _contents(model)
	model._logistics(0.05)
	expect(split.cargo.is_empty() and gap.cargo == "rich_crystal", "counterexample ordinary belt admits wrong cargo before filter")
	for i in 25: model._logistics(0.05)
	expect(gap.cargo == "rich_crystal" and gate.cargo.is_empty() and _contents(model) == held, "wrong cargo backs up in intermediate belt with exact conservation")
	_near(model, gap)
	expect(model.salvage(gap.id).ok and model.bag.rich_crystal == 1 and _contents(model) == held, "counterexample wrong segment salvages cargo intact")


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		expect(false, "missing input " + path)
		return {}
	var value: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	expect(value is Dictionary, "JSON object input " + path)
	return value if value is Dictionary else {}


func _snapshot(model: RefCounted) -> Dictionary:
	return Codec.snapshot(model, metadata.world_id, metadata.name, int(metadata.sequence))


func _clone(document: Dictionary) -> RefCounted:
	var decoded := Codec.decode(document, document.get("world_id", ""))
	expect(decoded.ok, "strict V5 restore: " + decoded.get("reason", ""))
	return decoded.model if decoded.ok else null


func _ids(model: RefCounted) -> Dictionary:
	var ids := {}
	for row in Layout.combination_entities():
		var e: Dictionary = model.entity_at(Vector2i(row.x, row.z))
		expect(not e.is_empty() and e.type == row.type and e.x == row.x and e.z == row.z and e.dir == row.dir, "source matches final layout " + row.name)
		if not e.is_empty(): ids[row.name] = e.id
	return ids


func _natural_snapshot() -> void:
	expect(not source_path.is_empty() and source_path.is_absolute_path(), "state requires --snapshot=absolute-path from a traceable strict C3 snapshot")
	if source_path.is_empty() or not source_path.is_absolute_path(): return
	var document := _read_json(source_path)
	if document.is_empty(): return
	expect(document.get("save_schema_version", 0) == 5, "source uses schema 5")
	for key in ["world_id", "name", "sequence"]:
		if not document.has(key): expect(false, "source metadata " + key); return
		metadata[key] = document[key]
	var model: RefCounted = _clone(document)
	if model == null: return
	var ids := _ids(model)
	if ids.size() != 84: return
	expect(model.entities.size() == 84, "source has exactly the final 84 entities")
	expect(model.discovery.sample_taken and model.discovery.trial_completed and model.discovery.passages.outer and not model.discovery.passages.inner, "source preserves unique trial and outer-open/inner-closed progression")
	for entry in [["g1", "crystal"], ["g2", "rich_crystal"], ["g3", "catalyst"]]:
		var e: Dictionary = model.by_id(ids[entry[0]])
		expect(e.filter_item == entry[1] and e.quota_mode == "unlimited", "source mixed-line filter " + entry[0])
	for entry in [["basic", "basic_catalyst"], ["rich", "rich_catalyst"], ["solvent", "crust_solvent"]]:
		expect(model.by_id(ids[entry[0]]).recipe_id == entry[1], "source real recipe " + entry[0])
	var gate: Dictionary = model.by_id(ids.g4)
	expect(gate.quota_limit == 8 and gate.quota_used == 7 and gate.cargo == "crust_solvent" and gate.progress > 0 and gate.progress < 1 and not gate.accepting, "source C3 is closed 7/8 plus partially transported eighth item")
	expect(model.by_id(ids.solvent_store).items.get("crust_solvent", 0) == 7, "source new-round store contains seven released items")
	var totals: Dictionary = model.statistics.totals
	for item in ["crystal", "rich_crystal"]:
		expect(totals.produced.get(item, 0) > 0 and totals.consumed.get(item, 0) > 0, "source actual extraction and recipe consumption " + item)
	var canonical := _snapshot(model)
	write_json("state-partial.json", canonical)
	write_json("state-context.json", {"metadata": metadata, "replay_steps": REPLAY_STEPS, "source_path": source_path, "source_kind": source_kind, "source_sha256": FileAccess.get_sha256(source_path), "scope": "source-derived state fixtures; actor positions and explicit fixed steps are test operations, not natural Boot inputs"})
	observations.source_sha256 = FileAccess.get_sha256(source_path)
	_invalid_snapshots(canonical, ids)
	_replay(canonical)
	_quota_fault(canonical, ids)
	_material_batches(canonical, ids)
	for fps in [30, 60, 144]:
		var framed: RefCounted = _clone(canonical)
		var reference: RefCounted = _clone(canonical)
		if framed == null or reference == null: continue
		for frame in fps * 6: framed.advance(1.0 / fps)
		for step in 120: reference.advance(0.05)
		var actual := _snapshot(framed)
		var expected := _snapshot(reference)
		expect(framed.statistics.ticks == reference.statistics.ticks, "same fixed tick count at %d FPS" % fps)
		actual.state.remainder = 0.0
		expected.state.remainder = 0.0
		expect(Compare.equivalent(actual, expected), "complete state statistics batches and quota match at %d FPS" % fps)
		expect(Codec.decode(_snapshot(framed), metadata.world_id).ok, "strict per-material conservation at %d FPS" % fps)


func _replay(document: Dictionary) -> void:
	var normal: RefCounted = _clone(document)
	var reordered: RefCounted = _clone(document)
	if normal == null or reordered == null: return
	reordered.entities.reverse()
	for step in REPLAY_STEPS:
		normal.advance(0.05)
		reordered.advance(0.05)
		expect(Compare.equivalent(_snapshot(normal), _snapshot(reordered)), "source-derived reordered fixed-step trajectory %d" % step)
		if step % 20 == 0:
			var valid := Codec.decode(_snapshot(normal), metadata.world_id)
			expect(valid.ok, "source-derived strict materials batches and quota step %d: %s" % [step, valid.get("reason", "")])
	write_json("state-expected.json", _snapshot(normal))


func _quota_fault(document: Dictionary, ids: Dictionary) -> void:
	var normal: RefCounted = _clone(document)
	if normal == null: return
	var gate: Dictionary = normal.by_id(ids.g4)
	var before_count: int = normal.statistics.totals.delivered.get("crust_solvent", 0)
	for step in 30: normal.advance(0.05)
	expect(gate.quota_used == 8 and gate.cargo.is_empty() and normal.by_id(ids.solvent_store).items.get("crust_solvent", 0) == 8, "restored closed G4 drains exactly the eighth item to eight-item store")
	expect(normal.statistics.totals.delivered.get("crust_solvent", 0) == before_count + 1, "last delivery increments exactly once")
	_near(normal, gate)
	expect(normal.set_admission_accepting(gate.id, true).ok, "explicitly reopen exhausted G4")
	for step in 300: normal.advance(0.05)
	expect(gate.quota_used == 8 and gate.cargo.is_empty() and normal.by_id(ids.solvent_store).items.get("crust_solvent", 0) == 8, "reopening cannot admit ninth solvent")
	expect(Codec.decode(_snapshot(normal), metadata.world_id).ok, "exhausted continuation retains strict material conservation")
	var blocked: RefCounted = _clone(document)
	if blocked == null: return
	var sink: Dictionary = blocked.by_id(ids.solvent_store)
	var endpoint: Vector2 = Layout.routes().solvent_store.back()
	blocked.actor.x = endpoint.x
	blocked.actor.z = endpoint.y
	var held := _contents(blocked)
	expect(blocked.salvage(sink.id).ok and _contents(blocked) == held, "source-derived legal sink disconnection retains seven stored items in bag")
	gate = blocked.by_id(ids.g4)
	for step in 30: blocked.advance(0.05)
	expect(gate.quota_used == 7 and gate.cargo == "crust_solvent" and gate.progress == 1.0, "disconnected final outlet retains 7/8 and held eighth cargo")
	expect(Codec.decode(_snapshot(blocked), metadata.world_id).ok, "blocked seventh-plus-one branch remains a strict legal world")
	expect(blocked.place("storage", Vector2i(-2, -1)).ok, "legal returned kit repairs final sink")
	blocked.advance(0.05)
	expect(gate.quota_used == 8 and gate.cargo.is_empty(), "repair commits held final output exactly once")
	expect(blocked.bag.get("crust_solvent", 0) == 7 and blocked.entity_at(Vector2i(-2, -1)).items.get("crust_solvent", 0) == 1, "repair accounts separately for bag seven and sink one")
	expect(Codec.decode(_snapshot(blocked), metadata.world_id).ok, "repaired source-derived branch remains strictly conserved")
	write_json("quota-repair.json", _snapshot(blocked))


func _material_batches(document: Dictionary, ids: Dictionary) -> void:
	var model: RefCounted = _clone(document)
	if model == null: return
	var completed := {"basic": 0, "rich": 0}
	var rich_batches: Array[int] = []
	for step in 2400:
		var previous := {}
		for name in completed:
			var e: Dictionary = model.by_id(ids[name])
			previous[name] = {"processing": e.processing, "active_batch": e.active_batch}
		model.advance(0.05)
		for name in completed:
			var e: Dictionary = model.by_id(ids[name])
			if previous[name].processing and not e.processing and previous[name].active_batch > 0:
				completed[name] += 1
		var rich: Dictionary = model.by_id(ids.rich)
		if rich.output_batch > 0:
			var batch: int = rich.output_batch
			var amount: int = Items.count(rich.output)
			var holders := 1 if amount > 0 else 0
			for e in model.entities:
				if model.Logistics.transport(e) and e.batch == batch:
					expect(e.cargo == "catalyst", "rich batch cannot change material")
					amount += 1
					holders += 1
			expect(amount <= 3, "rich multi-output batch never exceeds recipe quantity")
			if amount == 3 and holders >= 2 and batch not in rich_batches: rich_batches.append(batch)
		if step % 20 == 0:
			var valid := Codec.decode(_snapshot(model), metadata.world_id)
			expect(valid.ok, "two-minutes source-derived material/batch conservation %d: %s" % [step, valid.get("reason", "")])
		expect(model.by_id(ids.basic).input.get("rich_crystal", 0) == 0 and model.by_id(ids.rich).input.get("crystal", 0) == 0, "two filters keep incompatible raw minerals out of recipes")
	expect(completed.basic > 0 and completed.rich > 0, "both processing recipes complete new real batches during explicit continuation")
	expect(not rich_batches.is_empty(), "rich recipe three-item batch is actually split across producer and transport slots")
	observations.continued_recipe_completions = completed
	observations.rich_three_piece_batches = rich_batches
	observations.explicit_continuation_steps = 2400
	write_json("state-continuation.json", _snapshot(model))


func _restore() -> void:
	var context := _read_json(evidence.path_join("state-context.json"))
	var document := _read_json(evidence.path_join("state-partial.json"))
	var expected := _read_json(evidence.path_join("state-expected.json"))
	if context.is_empty() or document.is_empty() or expected.is_empty(): return
	expect(context.get("replay_steps", 0) == REPLAY_STEPS and context.has("metadata"), "independent process receives declared replay context")
	if not context.has("metadata"): return
	metadata = context.metadata
	source_path = context.get("source_path", "")
	source_kind = context.get("source_kind", "explicit-snapshot")
	observations.source_sha256 = context.get("source_sha256", "")
	var model: RefCounted = _clone(document)
	var expected_model: RefCounted = _clone(expected)
	if model == null or expected_model == null: return
	expect(Compare.equivalent(_snapshot(model), document), "independent process initial frame exactly restores full authoritative snapshot")
	for step in REPLAY_STEPS: model.advance(0.05)
	expect(Codec.decode(_snapshot(model), metadata.world_id).ok, "independent process endpoint passes strict schema5 conservation")
	expect(Compare.equivalent(_snapshot(model), _snapshot(expected_model)), "independent process reproduces complete transport production batches quota statistics and discovery")
	write_json("state-actual.json", _snapshot(model))


func _invalid_snapshots(document: Dictionary, ids: Dictionary) -> void:
	for fault in ["ordinary_material", "rich_material", "quota_reservation", "held_filter", "supply", "batch", "raw_recipe"]:
		var invalid: Dictionary = document.duplicate(true)
		var gate := {}
		var rich := {}
		for e in invalid.state.entities:
			if e.id == ids.g4: gate = e
			if e.id == ids.rich: rich = e
		match fault:
			"ordinary_material": invalid.state.bag.crystal = invalid.state.bag.get("crystal", 0) + 1
			"rich_material": invalid.state.bag.rich_crystal = invalid.state.bag.get("rich_crystal", 0) + 1
			"quota_reservation": gate.quota_used = 8
			"held_filter": gate.filter_item = "catalyst"
			"supply": invalid.state.kits.admission_gate += 1
			"batch": gate.batch = invalid.state.next_batch + 1
			"raw_recipe": rich.input.crystal = 1
		expect(not Codec.decode(invalid, metadata.world_id).ok, "strict C source rejects invalid " + fault)
