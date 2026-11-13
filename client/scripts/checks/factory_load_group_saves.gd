extends RefCounted

const Store := preload("res://scripts/factory/save/store.gd")
const Codec := Store.Codec
const Loads := Codec.V15.Loads
const Compare := preload("res://scripts/checks/factory_expansion_compare.gd")
var host: SceneTree
var driver: Node


func _init(check: SceneTree) -> void:
	host = check
	driver = check.driver


func source(model: RefCounted) -> Dictionary:
	return model.entity_at(Vector2i(1, 22))


func write_variants(model: RefCounted) -> void:
	var id: String = host.boot.factory_world.store.world_id
	var doc := Codec.snapshot(model, id, "C3 variants", 1)
	var rows := []
	for name in ["block-19", "countdown-1", "countdown-0", "pending", "allow", "control-off", "source-off", "manual-stop", "source-removed", "member-removed", "conflict", "disconnected"]:
		var decoded := Codec.decode(doc, id)
		driver.expect(decoded.ok, "C3 starting document strict decode" + decoded.get("reason", ""))
		if not decoded.ok: return
		var m: RefCounted = decoded.model
		var b := source(m)
		match name:
			"countdown-1": m.advance(18 * m.STEP, 18)
			"countdown-0": m.advance(19 * m.STEP, 19)
			"pending": driver.expect(m.configure_load_group(b.id, b.load_group.member_ids, 100000).ok, "pending variant applies real config")
			"allow":
				for e in m.entities:
					if e.type == "refinery" and e.id not in b.load_group.member_ids and e.enabled:
						_near(m, e)
						driver.expect(m.set_device_enabled(e.id, false).ok, "reduce uncontrolled demand")
				m.advance(20 * m.STEP, 20)
				driver.expect(b.load_group.latch == "allow", "allow checkpoint uses genuine budget")
			"control-off": driver.expect(m.set_load_group_enabled(b.id, false).ok, "disabled group variant")
			"source-off", "source-removed":
				driver.expect(m.set_device_enabled(b.id, false).ok, "disabled storage variant")
				if name == "source-removed": driver.expect(m.salvage(b.id, true).ok, "C3 removal also clears C2 reference")
			"manual-stop", "member-removed":
				var member: Dictionary = m.by_id(b.load_group.member_ids[-1])
				_near(m, member)
				if name == "manual-stop": driver.expect(m.set_device_enabled(member.id, false).ok, "manual stop variant")
				else: driver.expect(m.salvage(member.id, true).ok, "member salvage variant")
			"conflict":
				# Saved topology fixture represents two legitimately enabled grids after a merge.
				for e in m.entities:
					if e.type == "grid_buffer" and e.id != b.id:
						e.load_group.enabled = true
						driver.expect("合网冲突" in m.load_group_reason(e) and "合网冲突" in m.load_group_reason(b), "both merged groups block")
			"disconnected":
				var nodes: Array = m.entities.filter(func(e): return e.type in ["power_junction", "cell_generator"])
				for e in nodes:
					_near(m, e)
					driver.expect(m.salvage(e.id, true).ok, "remove isolated topology node")
				driver.expect(not m.load_group_binding(b).ok, "detached source is a legal saved binding")
		var before := Codec.snapshot(m, id, name, 1)
		var check := Codec.decode(before, id)
		driver.expect(check.ok, "variant strict decode " + name + ": " + check.get("reason", ""))
		rows.append({"name": name, "before": before, "trajectory": trajectory(m), "after": Codec.snapshot(m, id, name, 1)})
	var file := FileAccess.open(host.evidence.path_join("load-variants.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(rows, "", true, true))
	_mutations(doc, id)
	_transactions(doc, id)


func read_variants() -> void:
	var rows: Variant = JSON.parse_string(FileAccess.get_file_as_string(host.evidence.path_join("load-variants.json")))
	driver.expect(rows is Array and rows.size() == 12, "twelve independent C3 checkpoints")
	if not rows is Array: return
	for row in rows:
		var decoded := Codec.decode(row.before, row.before.world_id)
		driver.expect(decoded.ok, "independent decode " + row.name)
		if not decoded.ok: continue
		var m: RefCounted = decoded.model
		driver.expect(Compare.equivalent(Codec.snapshot(m, row.before.world_id, row.name, 1), row.before), "complete pre-step snapshot " + row.name)
		driver.expect(Compare.equivalent(trajectory(m), row.trajectory) and Compare.equivalent(Codec.snapshot(m, row.before.world_id, row.name, 1), row.after), "600-step production and control trajectory " + row.name)


func trajectory(model: RefCounted) -> Array:
	var result := []
	for tick in 600:
		model.advance(model.STEP, 1)
		var entities := []
		for e in model.entities:
			if e.type in ["grid_buffer", "timed_dispatch", "cell_generator", "refinery", "assembler"]:
				var state: Dictionary = e.duplicate(true)
				if state.has("entry"): state.entry = [state.entry.x, state.entry.y]
				entities.append(state)
		result.append({"entities": entities, "next_batch": model.next_batch, "completed": model.completed_by_recipe.duplicate(), "totals": model.statistics.totals.duplicate(true)})
	return result


func _group(doc: Dictionary) -> Dictionary:
	for e in doc.state.entities:
		if e.type == "grid_buffer" and e.x == 1 and e.z == 22: return e.load_group
	return {}


func _mutations(doc: Dictionary, id: String) -> void:
	var members: Array = _group(doc).member_ids
	for change in [{"enabled": 1}, {"enabled": false}, {"member_ids": []}, {"member_ids": [true]},
		{"member_ids": [1]}, {"member_ids": [doc.state.next_id]}, {"member_ids": [members[0], members[0]]},
		{"member_ids": [members[1], members[0]]}, {"member_ids": [members[0], 0.5]},
		{"member_ids": members + members + members}, {"reserve_j": -1000}, {"reserve_j": 100001},
		{"reserve_j": 3601000}, {"reserve_j": true}, {"latch": "unknown"}, {"latch": true},
		{"evaluation_ticks_left": -1}, {"evaluation_ticks_left": 20}, {"evaluation_ticks_left": 0.5}, {"extra": 1}]:
		var bad := doc.duplicate(true)
		_group(bad).merge(change, true)
		driver.expect(not Codec.decode(bad, id).ok, "C3 mutation rejected " + str(change))
	for key in _group(doc):
		var bad := doc.duplicate(true)
		_group(bad).erase(key)
		driver.expect(not Codec.decode(bad, id).ok, "missing group field rejected " + key)
	var bad := doc.duplicate(true)
	bad.state.research.completed.erase(Loads.RESEARCH)
	driver.expect(not Codec.decode(bad, id).ok, "missing C3 research rejected")
	bad = doc.duplicate(true)
	bad.definitions_sha256 = Codec.V14.PIN
	driver.expect(not Codec.decode(bad, id).ok and not Codec.V14.decode(doc, id).ok, "C3 cannot use C2 identity or decoder")
	for kind in ["duplicate-owner", "cell-member", "missing-object", "wrong-entity"]:
		bad = doc.duplicate(true)
		for e in bad.state.entities:
			if kind == "duplicate-owner" and e.type == "grid_buffer" and e.x != 1:
				e.load_group.member_ids = [members[0]]
			if kind == "cell-member" and e.type == "assembler" and e.recipe_id == "cell_assembly":
				_group(bad).member_ids = [e.id]
			if kind == "missing-object" and e.type == "grid_buffer": e.erase("load_group")
			if kind == "wrong-entity" and e.type == "refinery": e.load_group = Loads.defaults()
		driver.expect(not Codec.decode(bad, id).ok, "C3 reference or field ownership rejection " + kind)
	var fresh := Codec.V15.LoadModel.new()
	driver.expect(Codec.decode(Codec.snapshot(fresh, id, "fresh", 1), id).ok and not fresh.researched.has(Loads.RESEARCH), "new C3 starts without free research")


func _transactions(doc: Dictionary, id: String) -> void:
	var root_dir: String = host.evidence.path_join("load-io")
	var store := Store.new(root_dir, false, false, true)
	var created := store.create("C3 IO", Loads.SUPPLY_ID, true)
	driver.expect(created.ok, "isolated C3 Store creates")
	if not created.ok: return
	var model: RefCounted = Codec.decode(doc, id).model
	driver.expect(store.save(model).ok, "publish C3 fixture")
	var main := store.path("autosave.json")
	var hash := FileAccess.get_sha256(main)
	for stage in ["validation", "temporary_write", "readback", "backup", "publish"]:
		store.fault = func(at): return at == stage
		driver.expect(not store.save(model).ok and FileAccess.get_sha256(main) == hash, "C3 IO protects original at " + stage)
	store.fault = Callable()
	driver.expect(not Store.new(root_dir).find_candidate(store.world_id).ok and not Store.new(root_dir).save(model).ok, "ordinary Store cannot continue or save C3")
	driver.expect(store.save(model).ok, "C3 saves after faults")
	var world_id := store.world_id
	var damaged := Codec.snapshot(model, world_id, "C3 IO", store.sequence)
	_group(damaged).evaluation_ticks_left = 20
	driver.expect(store.release().ok, "C3 releases session")
	var file := FileAccess.open(main, FileAccess.WRITE)
	file.store_string(JSON.stringify(damaged))
	file.close()
	var recovered := Store.new(root_dir, false, false, true)
	var candidate := recovered.prepare(world_id)
	driver.expect(candidate.ok and candidate.source.ends_with("autosave.bak.1.json"), "same-identity C3 backup recovery")
	if candidate.ok:
		driver.expect(recovered.accept(candidate).ok and recovered.save(candidate.model, candidate).ok, "explicit backup publication")
		recovered.release()

	var cross_root: String = host.evidence.path_join("load-cross-identity")
	var folder := cross_root.path_join(id)
	DirAccess.make_dir_recursive_absolute(folder.path_join("backups"))
	damaged.world_id = id
	var legacy := Codec.V14.snapshot(Codec.V14.FeedbackModel.new(), id, "C2", 1)
	for row in [["autosave.json", damaged], ["backups/autosave.bak.1.json", legacy]]:
		file = FileAccess.open(folder.path_join(row[0]), FileAccess.WRITE)
		file.store_string(JSON.stringify(row[1]))
		file.close()
	driver.expect(not Store.new(cross_root, false, false, true).find_candidate(id).ok, "C3 cannot recover from a C2 backup")


func _near(model: RefCounted, e: Dictionary) -> void:
	var route := preload("res://scripts/checks/factory_integrated_first_route.gd").new(model, {})
	route.advance_movement = false
	route.walk_near(e)
