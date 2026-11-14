extends RefCounted

const Store := preload("res://scripts/factory/save/store.gd")
const Codec := Store.Codec
const Feedback := Codec.V14.Feedback
const Compare := preload("res://scripts/checks/factory_expansion_compare.gd")
var host: SceneTree
var driver: Node


func _init(check: SceneTree) -> void:
	host = check
	driver = host.driver


func write_variants(model: RefCounted) -> void:
	var id: String = host.boot.factory_world.store.world_id
	var document := Codec.snapshot(model, id, "C2 variants", 1)
	var rows := []
	for name in ["allow", "block", "pending", "stopped", "source-disabled", "source-removed", "g-removed"]:
		var restored := Codec.decode(document, id)
		if not restored.ok:
			driver.expect(false, "C2 starting snapshot decodes: " + restored.reason)
			return
		var m: RefCounted = restored.model
		var gate: Dictionary = m.entity_at(Vector2i(0, 21))
		var source: Dictionary = m.by_id(gate.feedback.source_id)
		match name:
			"block":
				m.configure_storage_feedback(gate.id, source.id, 1000000, 1900000)
				m.advance(m.STEP, 1)
				driver.expect(gate.feedback.latch == "block", "second in-band checkpoint has a legitimate blocked decision")
			"pending": m.configure_storage_feedback(gate.id, source.id, 1000000, 2100000)
			"stopped": m.set_dispatch_active(gate.id, false)
			"source-disabled", "source-removed":
				m.actor.x = 2.5
				m.actor.z = 24.5
				driver.expect(m.set_device_enabled(source.id, false).ok, "stop variant storage")
				if name == "source-removed":
					driver.expect(m.salvage(source.id, true).ok and gate.feedback.source_id == 0, "source removal variant atomically clears ID")
			"g-removed":
				m.actor.x = 3.5
				m.actor.z = 20.5
				var g: Dictionary = m.entity_at(Vector2i(1, 20))
				driver.expect(m.salvage(g.id, true).ok, "G removal is a legal broken-port checkpoint")
		var before := Codec.snapshot(m, id, name, 1)
		driver.expect(Codec.decode(before, id).ok, "legal variant decodes: " + name)
		rows.append({"name": name, "before": before, "trajectory": _trajectory(m), "after": Codec.snapshot(m, id, name, 1)})
	var file := FileAccess.open(host.evidence.path_join("feedback-variants.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(rows, "", true, true))
	_mutations(document, id)
	_transactions(document, id)


func read_variants() -> void:
	var rows: Variant = JSON.parse_string(FileAccess.get_file_as_string(host.evidence.path_join("feedback-variants.json")))
	driver.expect(rows is Array and rows.size() == 7, "independent process has seven feedback checkpoints")
	if not rows is Array:
		return
	for row in rows:
		var id: String = row.before.world_id
		var decoded := Codec.decode(row.before, id)
		driver.expect(decoded.ok, "independent variant decode: " + row.name)
		if not decoded.ok:
			continue
		var m: RefCounted = decoded.model
		driver.expect(Compare.equivalent(Codec.snapshot(m, id, row.name, 1), row.before), "complete pre-step state retained: " + row.name)
		driver.expect(Compare.equivalent(_trajectory(m), row.trajectory) and Compare.equivalent(Codec.snapshot(m, id, row.name, 1), row.after),
			"all 600 resumed steps match without extra sampling: " + row.name)


func _trajectory(model: RefCounted) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for tick in 600:
		model.advance(model.STEP, 1)
		var devices: Array[Dictionary] = []
		for entity in model.entities:
			if entity.type in [Feedback.Timed.TYPE, Feedback.Storage.TYPE, "cell_generator"]:
				var state: Dictionary = entity.duplicate(true)
				if state.has("entry"):
					state.entry = [state.entry.x, state.entry.y]
				devices.append(state)
		# Integer controls/energy/stock remain exact. Float energy totals use the
		# existing 1e-9 JSON round-trip tolerance, just like the full snapshots.
		result.append({"tick": model.statistics.ticks, "devices": devices,
			"core_items": model.core.items.duplicate(), "totals": model.statistics.totals.duplicate(true)})
	return result


func _gate(document: Dictionary) -> Dictionary:
	for entity in document.state.entities:
		if entity.type == Feedback.Timed.TYPE:
			return entity
	return {}


func _mutations(doc: Dictionary, id: String) -> void:
	for change in [{"mode": "unknown"}, {"mode": "timed"}, {"latch": "unknown"}, {"latch": true},
		{"source_id": -1}, {"source_id": 0}, {"source_id": 1}, {"source_id": doc.state.next_id},
		{"source_id": 0.5}, {"source_id": true}, {"low_j": -1000}, {"low_j": 1100001},
		{"high_j": 3601000}, {"high_j": 1100000}, {"low_j": "1100000"}, {"extra": 1}]:
		var invalid := doc.duplicate(true)
		_gate(invalid).feedback.merge(change, true)
		driver.expect(not Codec.decode(invalid, id).ok, "strict C2 rejection: " + str(change))
	for key in ["mode", "source_id", "low_j", "high_j", "latch"]:
		var invalid := doc.duplicate(true)
		_gate(invalid).feedback.erase(key)
		driver.expect(not Codec.decode(invalid, id).ok, "missing feedback field rejected: " + key)
	var invalid := doc.duplicate(true)
	_gate(invalid).erase("feedback")
	driver.expect(not Codec.decode(invalid, id).ok, "schema 14 requires feedback even for pure timed gates")
	invalid = doc.duplicate(true)
	invalid.state.research.completed.erase(Feedback.RESEARCH)
	driver.expect(not Codec.decode(invalid, id).ok, "feedback without research cannot decode")
	invalid = doc.duplicate(true)
	invalid.state.core.items.industrial_cell = invalid.state.core.items.get("industrial_cell", 0) + 1
	driver.expect(not Codec.decode(invalid, id).ok, "C2 non-fuel debit cannot be refunded")
	invalid = doc.duplicate(true)
	invalid.definitions_sha256 = Codec.V13.PIN
	driver.expect(not Codec.decode(invalid, id).ok, "C1 digest cannot read C2")
	driver.expect(not Codec.V13.decode(doc, id).ok and not Codec.V1.decode(doc, id).ok, "old decoder rejects future C2 identity")
	var old := Codec.V13.snapshot(Codec.V13.TimedModel.new(), id, "old C1", 1)
	driver.expect(old.definitions_sha256 == Codec.V13.PIN and Codec.decode(old, id).ok, "C1 identity and digest remain unchanged")
	for single_inlet in [false, true]:
		var frontier := Codec.V10.snapshot(Codec.V10.FrontierModel.new(single_inlet), id, "D1 identity", 1)
		var restored := Codec.decode(frontier, id)
		driver.expect(restored.ok and restored.model.single_inlet_belts == single_inlet
			and not restored.model.research_nodes.has(Feedback.RESEARCH), "both D1 identities retain their own routing and studies")
	var fresh := Codec.V14.FeedbackModel.new()
	driver.expect(Codec.decode(Codec.snapshot(fresh, id, "fresh C2", 1), id).ok and not fresh.researched.has(Feedback.RESEARCH), "fresh C2 begins with no research or materials granted")


func _transactions(doc: Dictionary, id: String) -> void:
	var root_dir: String = host.evidence.path_join("feedback-io")
	var store := Store.new(root_dir, false, false, true)
	var created := store.create("C2 IO", Feedback.SUPPLY_ID, true)
	driver.expect(created.ok, "isolated C2 Store creates normally")
	if not created.ok:
		return
	var model: RefCounted = Codec.decode(doc, id).model
	driver.expect(store.save(model).ok, "publish real feedback state")
	var main := store.path("autosave.json")
	var hash := FileAccess.get_sha256(main)
	for stage in ["validation", "temporary_write", "readback", "backup", "publish"]:
		store.fault = func(at): return at == stage
		driver.expect(not store.save(model).ok and FileAccess.get_sha256(main) == hash, "C2 IO failure preserves original: " + stage)
	store.fault = Callable()
	driver.expect(not Store.new(root_dir).save(model).ok and not Store.new(root_dir).find_candidate(store.world_id).ok, "ordinary Store refuses save and continue")
	driver.expect(store.save(model).ok, "save after faults succeeds")
	var world_id := store.world_id
	var damaged: Dictionary = Codec.snapshot(model, world_id, "C2 IO", store.sequence)
	_gate(damaged).feedback.low_j = -1000
	driver.expect(store.release().ok, "C2 IO session releases")
	var file := FileAccess.open(main, FileAccess.WRITE)
	file.store_string(JSON.stringify(damaged))
	file.close()
	var recovered := Store.new(root_dir, false, false, true)
	var candidate := recovered.prepare(world_id)
	driver.expect(candidate.ok and candidate.source.ends_with("autosave.bak.1.json"), "same-identity backup can recover a corrupt C2 field")
	if candidate.ok:
		driver.expect(recovered.accept(candidate).ok and recovered.save(candidate.model, candidate).ok, "explicit C2 backup recovery publishes valid state")
		recovered.release()
	var cross_root: String = host.evidence.path_join("feedback-cross-identity")
	var folder := cross_root.path_join(id)
	DirAccess.make_dir_recursive_absolute(folder.path_join("backups"))
	var legacy := Codec.V13.snapshot(Codec.V13.TimedModel.new(), id, "C1", 1)
	damaged.world_id = id
	for row in [["autosave.json", damaged], ["backups/autosave.bak.1.json", legacy]]:
		file = FileAccess.open(folder.path_join(row[0]), FileAccess.WRITE)
		file.store_string(JSON.stringify(row[1]))
		file.close()
	driver.expect(not Store.new(cross_root, false, false, true).find_candidate(id).ok, "C2 cannot recover from a C1 backup")
