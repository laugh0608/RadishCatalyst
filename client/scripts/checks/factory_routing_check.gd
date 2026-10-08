extends SceneTree

const Model := preload("res://scripts/factory/routing_model.gd")
const Legacy := preload("res://scripts/factory/discovery_model.gd")
const Codec := preload("res://scripts/factory/save/codec.gd")
const Store := preload("res://scripts/factory/save/store.gd")
const Compare := preload("res://scripts/checks/factory_discovery_check.gd")
const ID := "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
var checks := 0
var failures: Array[String] = []
var evidence := ""


func _init() -> void:
	call_deferred("run")


func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)
		push_error(label)


static func line() -> RefCounted:
	var model := Model.new()
	model.place("collector", Vector2i(-20, -1))
	model.place("splitter", Vector2i(-18, 0))
	model.place("reactor", Vector2i(-13, -2))
	model.place("reactor", Vector2i(-13, 4))
	model.place("merger", Vector2i(-6, 0))
	model.place("storage", Vector2i(-3, -1))
	model.place("power_source", Vector2i(-19, -6))
	model.place("power_junction", Vector2i(-13, 2))
	for x in range(-17, -13): model.place("belt", Vector2i(x, 0))
	for z in range(1, 6): model.place("belt", Vector2i(-18, z), 1)
	for x in range(-18, -13): model.place("belt", Vector2i(x, 6))
	for x in range(-10, -6): model.place("belt", Vector2i(x, 0))
	for x in range(-10, -6): model.place("belt", Vector2i(x, 6))
	for z in range(6, 0, -1): model.place("belt", Vector2i(-6, z), 3)
	for x in range(-5, -3): model.place("belt", Vector2i(x, 0))
	return model


static func snapshot(model: RefCounted) -> Dictionary:
	return Codec.snapshot(model, ID, "分流汇合定向检查", 1)


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	if evidence.is_empty():
		evidence = SliceCheckPaths.check_run("factory-conveyor-routing-v1", false).path_join("state-%d-%d" % [Time.get_unix_time_from_system(), OS.get_process_id()])
	DirAccess.make_dir_recursive_absolute(evidence)
	if "--read" in OS.get_cmdline_user_args():
		_restore()
	else:
		_ports_and_commands()
		_routing()
		_competition_and_saturation()
		_natural_and_codec()
		_store()
		_upgrade_failures()
	var result := {"checks": checks, "failures": failures, "execution_mode": "headless-state", "fixtures": "constructed topology; explicit fixed-step time; IO faults isolated"}
	var file := FileAccess.open(evidence.path_join("read-result.json" if "--read" in OS.get_cmdline_user_args() else "state-result.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("Factory routing checks: %d assertions, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _ports_and_commands() -> void:
	var old := Legacy.new(true)
	expect(not old.place("splitter", Vector2i(-12, -5)).ok, "legacy supply rejects new types")
	for dir in 4:
		var model := Model.new()
		var e: Dictionary = model.place("splitter", Vector2i(-12, -5), dir).entity
		var inputs: Array = Model.Logistics.ports(model, e, "input")
		var outputs: Array = Model.Logistics.ports(model, e, "output")
		expect(inputs.size() == 1 and outputs.size() == 3 and Vector2i(inputs[0].dx, inputs[0].dz) == -model.DIRS[dir], "rotated splitter port count/direction %d" % dir)
		var before := snapshot(model)
		expect(not model.place("merger", Vector2i(-12, -5)).ok and snapshot(model) == before, "occupied placement atomic %d" % dir)
		e.output_cursor = 2
		expect(model.rotate(e.id).ok and e.dir == (dir + 1) % 4 and e.output_cursor == 0, "empty rotate resets local cursor %d" % dir)
		e.cargo = "crystal"
		e.progress = 0.4
		before = snapshot(model)
		expect(not model.rotate(e.id).ok and snapshot(model) == before, "loaded rotate preserves cargo %d" % dir)
		model.bag = {"crystal": 200}
		before = snapshot(model)
		expect(not model.salvage(e.id).ok and snapshot(model) == before, "full bag salvage atomic %d" % dir)
		model.bag = {}
		expect(model.salvage(e.id).ok and model.bag.crystal == 1 and model.kits.splitter == 8, "salvage returns kit and cargo %d" % dir)


func _routing() -> void:
	# These intentionally synthetic cargo fixtures isolate arbitration, not save validity.
	var model := Model.new()
	var splitter: Dictionary = model.place("splitter", Vector2i(-12, -5)).entity
	var targets: Array[Dictionary] = []
	for side in [0, 3, 1]:
		targets.append(model.place("belt", Vector2i(-12, -5) + model.DIRS[side], side).entity)
	var counts := [0, 0, 0]
	for i in 12:
		splitter.cargo = "crystal"
		splitter.progress = 1.0
		model._logistics(0.05)
		for t in targets.size():
			if not targets[t].cargo.is_empty():
				counts[t] += 1
				targets[t].cargo = ""
				targets[t].progress = 0.0
	expect(counts == [4, 4, 4], "splitter three active branches receive equal successful turns")
	targets[1].cargo = "crystal"
	targets[1].progress = 1.0
	for i in 6:
		splitter.cargo = "crystal"
		splitter.progress = 1.0
		model._logistics(0.05)
		var chosen := 0 if not targets[0].cargo.is_empty() else 2
		expect(chosen == (0 if i % 2 == 0 else 2), "blocked branch skipped turn %d" % i)
		targets[chosen].cargo = ""
		targets[chosen].progress = 0.0
	for target in targets: target.cargo = "crystal"
	splitter.cargo = "crystal"
	splitter.progress = 1.0
	var cursor: int = splitter.output_cursor
	model._logistics(0.05)
	expect(splitter.cargo == "crystal" and splitter.output_cursor == cursor and model.feedback(splitter).kind == "blocked", "all blocked retains cargo cursor and visible reason")
	targets[1].cargo = ""
	model._logistics(0.05)
	expect(splitter.cargo.is_empty() and splitter.output_cursor == 2, "unblock resumes saved priority")
	var merge_model := Model.new()
	var merger: Dictionary = merge_model.place("merger", Vector2i(-12, -5)).entity
	var sources: Array[Dictionary] = []
	for side in [2, 3, 1]: sources.append(merge_model.place("belt", Vector2i(-12, -5) + model.DIRS[side], (side + 2) % 4).entity)
	var order: Array[int] = []
	for i in 9:
		for source in sources:
			source.cargo = "crystal"
			source.progress = 1.0
		merger.cargo = ""
		merger.progress = 0.0
		merge_model._logistics(0.05)
		for j in sources.size():
			if sources[j].cargo.is_empty(): order.append(j)
	expect(order == [0, 1, 2, 0, 1, 2, 0, 1, 2], "merger continuously ready inputs rotate without starvation")
	var chain := Model.new()
	var first: Dictionary = chain.place("splitter", Vector2i(-12, -5)).entity
	var second: Dictionary = chain.place("merger", Vector2i(-11, -5)).entity
	var end: Dictionary = chain.place("belt", Vector2i(-10, -5)).entity
	first.cargo = "crystal"
	first.progress = 1.0
	chain._logistics(0.05)
	expect(second.cargo == "crystal" and second.progress == 0 and end.cargo.is_empty(), "adjacent accessories move once per step")
	for i in 19: chain._logistics(0.05)
	expect(end.cargo.is_empty(), "new slot cargo cannot leave before twenty steps")
	chain._logistics(0.05)
	expect(end.cargo == "crystal", "twentieth step completes accessory travel")


func _natural_and_codec() -> void:
	var model := line()
	expect(model.entities.size() == 38 and model.kits.splitter == 7 and model.kits.merger == 7, "ordinary fixture fits expected placement budget")
	model.advance(90)
	expect(model.by_id(3).processing and model.by_id(4).processing and model.delivered >= 8, "natural fixed-step split production and merged delivery")
	var doc := snapshot(model)
	var decoded := Codec.decode(doc, ID)
	expect(decoded.ok, "schema4 full line strict roundtrip: " + decoded.get("reason", ""))
	if not decoded.ok: return
	var restored: RefCounted = decoded.model
	expect(snapshot(restored) == doc, "codec preserves every authoritative field")
	# Opposite dictionary/array traversal must not change new-world arbitration.
	restored.entities.reverse()
	for i in 200:
		model.advance(0.05)
		restored.advance(0.05)
		var a := snapshot(model)
		var b := snapshot(restored)
		b.state.entities.sort_custom(func(x, y): return x.id < y.id)
		expect(a == b, "per-tick ordering and restoration %d" % i)
		expect(Codec.decode(a, ID).ok, "per-tick material and batch conservation %d" % i)
	for fps in [30, 60, 144]:
		var framed: RefCounted = Codec.decode(doc, ID).model
		for frame in fps * 3: framed.advance(1.0 / fps)
		var reference: RefCounted = Codec.decode(doc, ID).model
		reference.advance(3.0)
		var framed_doc := snapshot(framed)
		var reference_doc := snapshot(reference)
		framed_doc.state.remainder = 0.0
		reference_doc.state.remainder = 0.0
		expect(framed_doc == reference_doc, "same fixed-step state at %d FPS" % fps)
	for mutate in ["cursor", "sample", "entry", "budget", "graph", "future", "batch"]:
		var invalid: Dictionary = doc.duplicate(true)
		match mutate:
			"cursor": invalid.state.entities[1].output_cursor = 3
			"sample": invalid.state.entities[1].cargo = "crust_sample"
			"entry": invalid.state.entities[1].entry = [0, 1]
			"budget": invalid.state.kits.splitter += 1
			"graph": invalid.state.entities[0].power_node_id = 0
			"future": invalid.save_schema_version = 5
			"batch": invalid.state.entities[1].batch = invalid.state.next_batch + 1
		expect(not Codec.decode(invalid, ID).ok, "strict decoder rejects " + mutate)
	var file := FileAccess.open(evidence.path_join("half.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(doc, "", true, true))
	file.close()
	var expected: RefCounted = Codec.decode(doc, ID).model
	expected.advance(7.35)
	file = FileAccess.open(evidence.path_join("expected.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(snapshot(expected), "", true, true))
	file.close()


func _restore() -> void:
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("half.json")))
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("expected.json")))
	var result := Codec.decode(doc, ID)
	expect(result.ok, "independent process decodes snapshot")
	if result.ok:
		result.model.advance(7.35)
		var actual_file := FileAccess.open(evidence.path_join("actual.json"), FileAccess.WRITE)
		actual_file.store_string(JSON.stringify(snapshot(result.model), "", true, true))
		actual_file.close()
		var decoded_expected := Codec.decode(expected, ID)
		expect(decoded_expected.ok, "expected snapshot is strictly valid")
		expect(decoded_expected.ok and Compare.equivalent(snapshot(result.model), snapshot(decoded_expected.model)), "independent process resumes exact transport production and statistics")


func _store() -> void:
	var store := Store.new(evidence.path_join("store"))
	var created := store.create("旧世界升级夹具", Codec.V2.Config.SUPPLY_ID, true)
	expect(created.ok, "create isolated schema3")
	if not created.ok: return
	var id: String = store.world_id
	var original := FileAccess.get_file_as_string(store.path("autosave.json"))
	store.release()
	var candidate := store.prepare(id)
	var staged := store.upgrade_routing(candidate)
	expect(staged.ok and FileAccess.get_file_as_string(store.path("autosave.json")) == original, "staging routing upgrade preserves original file")
	store.fault = func(stage): return stage == "upgrade_backup"
	expect(not store.accept(staged).ok and FileAccess.get_file_as_string(store.path("autosave.json")) == original, "failed upgrade backup keeps main untouched")
	store.release()
	store.fault = Callable()
	candidate = store.prepare(id)
	staged = store.upgrade_routing(candidate)
	var accepted := store.accept(staged)
	expect(accepted.ok, "schema3-to-4 upgrade publishes: " + accepted.get("reason", ""))
	var retained := false
	for name in DirAccess.get_files_at(store.path("backups")):
		if name.begins_with("pre-routing-v3-"):
			retained = FileAccess.get_file_as_string(store.path("backups/" + name)) == original
	expect(retained, "independent original snapshot retained byte-for-byte")
	store.release()
	candidate = store.prepare(id)
	expect(candidate.ok and candidate.document.save_schema_version == 4 and candidate.model.kits.splitter == 8, "reopened upgraded world has schema4 and exact grant")
	store.release()


func _competition_and_saturation() -> void:
	var model := Model.new()
	var split: Dictionary = model.place("splitter", Vector2i(-13, -5)).entity
	var merge: Dictionary = model.place("merger", Vector2i(-12, -5)).entity
	var competitor: Dictionary = model.place("belt", Vector2i(-12, -6), 1).entity
	var alternative: Dictionary = model.place("belt", Vector2i(-13, -6)).entity
	merge.input_cursor = 1
	split.cargo = "crystal"
	split.progress = 1.0
	competitor.cargo = "rich_crystal"
	competitor.progress = 1.0
	model._logistics(0.05)
	expect(merge.cargo == "rich_crystal" and alternative.cargo == "crystal" and split.cargo.is_empty(), "losing splitter retries free alternative in same arbitration transaction")
	expect(split.output_cursor == 2 and merge.input_cursor == 2, "only successful alternative and winning input advance cursors")
	var held: Dictionary = model.material_balance().held
	expect(held.get("crystal", 0) == 1 and held.get("rich_crystal", 0) == 1, "shared-target conflict cannot duplicate or overwrite either cargo")
	var ring := Model.new()
	var cells := [Vector2i(-12, -5), Vector2i(-11, -5), Vector2i(-11, -4), Vector2i(-12, -4)]
	for i in 4:
		var e: Dictionary = ring.place("belt", cells[i], i).entity
		e.cargo = "crystal"
		e.progress = 1.0
	var before := snapshot(ring)
	ring._logistics(0.05)
	expect(snapshot(ring) == before, "full closed loop cannot perform hidden capacity-free swap")
	ring.by_id(1).cargo = ""
	ring.by_id(1).progress = 0.0
	ring._logistics(0.05)
	expect(ring.by_id(1).cargo == "crystal" and ring.by_id(4).cargo.is_empty(), "one released gap moves only one edge")
	var timed := Model.new()
	var source: Dictionary = timed.place("belt", Vector2i(-13, -5)).entity
	var middle: Dictionary = timed.place("merger", Vector2i(-12, -5)).entity
	var sink: Dictionary = timed.place("storage", Vector2i(-11, -6)).entity
	var received: Array[int] = []
	for tick in 85:
		source.cargo = "crystal"
		source.progress = 1.0
		var was_empty: bool = middle.cargo.is_empty()
		timed._logistics(0.05)
		if was_empty and not middle.cargo.is_empty(): received.append(tick)
	expect(received == [0, 21, 42, 63, 84] and sink.items.crystal == 4, "saturated single-slot throughput is one item per twenty-one ticks")
	var mixed := Model.new()
	var distributor: Dictionary = mixed.place("splitter", Vector2i(-14, 0)).entity
	mixed.place("reactor", Vector2i(-13, -2))
	mixed.place("belt", Vector2i(-14, 1), 1)
	distributor.cargo = "rich_crystal"
	distributor.progress = 1.0
	var outputs := Model.Logistics.ports(mixed, distributor, "output")
	expect(Model.Logistics.output_status(mixed, distributor, outputs[0], "rich_crystal").reason == "目标不收该物品", "direct incompatible recipe explains rejection")
	mixed._logistics(0.05)
	expect(mixed.entity_at(Vector2i(-14, 1)).cargo == "rich_crystal", "mixed cargo skips incompatible immediate receiver")
	distributor.cargo = "crust_sample"
	distributor.progress = 1.0
	mixed._logistics(0.05)
	expect(distributor.cargo == "crust_sample", "unique sample never enters automatic transport")


func _upgrade_failures() -> void:
	for fault_stage in ["reconstruction", "validation", "temporary_write", "readback", "publish"]:
		var store := Store.new(evidence.path_join("failure-" + fault_stage))
		var created := store.create("升级失败隔离", Codec.V2.Config.SUPPLY_ID, true)
		expect(created.ok, "prepare IO fixture " + fault_stage)
		if not created.ok: continue
		var id: String = store.world_id
		var original := FileAccess.get_file_as_string(store.path("autosave.json"))
		store.release()
		var candidate := store.upgrade_routing(store.prepare(id))
		store.fault = func(stage): return stage == fault_stage
		expect(not store.accept(candidate).ok and FileAccess.get_file_as_string(store.path("autosave.json")) == original, "upgrade failure preserves original " + fault_stage)
		store.release()
		expect(not DirAccess.dir_exists_absolute(store.path("session.lock")), "failed upgrade lock released " + fault_stage)
	var store := Store.new(evidence.path_join("version-boundary"))
	var created := store.create("版本边界隔离", Codec.V2.Config.SUPPLY_ID, true)
	expect(created.ok, "prepare legacy version fixture")
	if not created.ok: return
	var id: String = store.world_id
	var original := FileAccess.get_file_as_string(store.path("autosave.json"))
	var competing := Store.new(store.root)
	expect(not competing.prepare(id).ok, "concurrent upgrade cannot take another live lock")
	store.release()
	store.prepare(id)
	store.release()
	expect(FileAccess.get_file_as_string(store.path("autosave.json")) == original, "cancelled load/upgrade never changes original")
	var candidate := store.upgrade_routing(store.prepare(id))
	var file := FileAccess.open(store.path("autosave.json"), FileAccess.WRITE)
	file.store_string(original + " ")
	file.close()
	expect(not store.accept(candidate).ok and FileAccess.get_file_as_string(store.path("autosave.json")) == original + " ", "external source change blocks upgrade publication")
	store.release()
	DirAccess.make_dir_recursive_absolute(store.path("backups"))
	file = FileAccess.open(store.path("backups/autosave.bak.1.json"), FileAccess.WRITE)
	file.store_string(original)
	file.close()
	var newer: Dictionary = Codec.V4.upgrade(JSON.parse_string(original)).document
	newer.state.kits.splitter = -1
	file = FileAccess.open(store.path("autosave.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(newer))
	file.close()
	expect(not store.find_candidate(id).ok, "damaged schema4 cannot silently recover schema3 backup")
	newer.save_schema_version = 5
	file = FileAccess.open(store.path("autosave.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(newer))
	file.close()
	var future := store.find_candidate(id)
	expect(not future.ok and future.get("unsupported", false), "future schema blocks all backup fallback")
