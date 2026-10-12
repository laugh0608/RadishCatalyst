extends SceneTree

const Model := preload("res://scripts/factory/admission_model.gd")
const Codec := preload("res://scripts/factory/save/codec.gd")
const Store := preload("res://scripts/factory/save/store.gd")
const RoutingCheck := preload("res://scripts/checks/factory_routing_check.gd")
const Compare := preload("res://scripts/checks/factory_discovery_check.gd")
const DevicePanel := preload("res://scripts/factory/discovery_panel.gd")
const ID := "dddddddddddddddddddddddddddddddd"
var checks := 0
var failures: Array[String] = []
var evidence := ""


func _init() -> void:
	Engine.max_fps = 60
	call_deferred("run")


func expect(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
		push_error(message)


static func snapshot(model: RefCounted) -> Dictionary:
	return Codec.snapshot(model, ID, "准入口定向验证", 1)


static func near(model: RefCounted, e: Dictionary) -> void:
	model.actor.x = e.x + 0.5
	model.actor.z = e.z + 1.5


static func crystal_line() -> RefCounted:
	var model := Model.new()
	model.place("collector", Vector2i(-20, -1))
	var gate: Dictionary = model.place("admission_gate", Vector2i(-18, 0)).entity
	model.place("storage", Vector2i(-17, -1))
	model.place("power_source", Vector2i(-22, -5))
	near(model, gate)
	model.configure_admission(gate.id, "crystal", "quota", 4)
	model.set_admission_accepting(gate.id, true)
	return model


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	if evidence.is_empty(): evidence = SliceCheckPaths.check_run("factory-item-admission-v1", false).path_join("state-%d-%d" % [Time.get_unix_time_from_system(), OS.get_process_id()])
	DirAccess.make_dir_recursive_absolute(evidence)
	if "--read" in OS.get_cmdline_user_args():
		_restore()
	else:
		_commands()
		_transport()
		_natural_and_codec()
		_legacy_trajectory()
		_combined()
		_store()
		await _panel()
	write_json("read-result.json" if "--read" in OS.get_cmdline_user_args() else "state-result.json", {"assertions": checks, "failures": failures, "mode": "headless-state", "fixtures": "constructed topology, explicit fixed steps and isolated IO faults; synthetic cargo only for command/arbitration cases; actor positioning only in state fixtures"})
	print("Admission state: %d assertions, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _commands() -> void:
	for dir in 4:
		var model := Model.new()
		var e: Dictionary = model.place("admission_gate", Vector2i(-12, -5), dir).entity
		expect(model.kits.admission_gate == 7 and not e.accepting and e.filter_item == "", "new gate is unconfigured and closed %d" % dir)
		var inputs: Array = model.Logistics.ports(model, e, "input")
		var outputs: Array = model.Logistics.ports(model, e, "output")
		expect(inputs.size() == 1 and outputs.size() == 1 and Vector2i(inputs[0].dx, inputs[0].dz) == -model.DIRS[dir], "rotated one-in/one-out ports %d" % dir)
		var before := snapshot(model)
		expect(not model.configure_admission(e.id, "crystal", "quota", 4).ok and snapshot(model) == before, "remote configuration has zero mutation %d" % dir)
		near(model, e)
		before = snapshot(model)
		expect(not model.set_admission_accepting(e.id, true).ok and snapshot(model) == before, "unconfigured gate cannot open %d" % dir)
		for args in [["crust_sample", "quota", 4], ["crystal", "cycle", 4], ["crystal", "quota", 0], ["crystal", "quota", 1000001], ["crystal", "quota", 1.5], ["crystal", "quota", true], ["crystal", "unlimited", 4]]:
			expect(not model.configure_admission(e.id, args[0], args[1], args[2]).ok and snapshot(model) == before, "illegal settings rejected atomically %d %s" % [dir, str(args)])
		expect(model.configure_admission(e.id, "crystal", "quota", 4).ok and not e.accepting, "apply settings preserves closed switch %d" % dir)
		expect(model.configure_admission(e.id, "crystal", "quota", 1000000).ok and e.quota_limit == 1000000, "maximum quota is accepted exactly %d" % dir)
		model.configure_admission(e.id, "crystal", "quota", 4)
		e.quota_used = 2
		before = snapshot(model)
		expect(model.configure_admission(e.id, "crystal", "quota", 4).ok and snapshot(model) == before, "identical settings keep used count %d" % dir)
		model.set_admission_accepting(e.id, true)
		model.set_admission_accepting(e.id, false)
		model.set_admission_accepting(e.id, true)
		expect(e.quota_used == 2 and model.rotate(e.id).ok and e.quota_used == 2, "switches and empty rotation preserve quota %d" % dir)
		e.cargo = "crystal"
		e.progress = 0.4
		before = snapshot(model)
		expect(not model.reset_admission(e.id).ok and not model.configure_admission(e.id, "catalyst", "quota", 8).ok and not model.rotate(e.id).ok and snapshot(model) == before, "held cargo prevents reset configuration and rotation %d" % dir)
		model.bag = {"crystal": 200}
		before = snapshot(model)
		expect(not model.salvage(e.id).ok and snapshot(model) == before, "full bag rejects whole gate recovery %d" % dir)
		model.bag = {}
		expect(model.salvage(e.id).ok and model.bag.crystal == 1 and model.kits.admission_gate == 8, "recovery returns kit and held item %d" % dir)


func _transport() -> void:
	var wrong := Model.new()
	var wrong_source: Dictionary = wrong.place("belt", Vector2i(-13, -5), 2).entity
	var wrong_gate: Dictionary = wrong.place("admission_gate", Vector2i(-12, -5)).entity
	near(wrong, wrong_gate)
	wrong.configure_admission(wrong_gate.id, "crystal", "unlimited", 0)
	wrong.set_admission_accepting(wrong_gate.id, true)
	wrong_source.cargo = "rich_crystal"
	expect(wrong.feedback(wrong_gate).label == "方向不匹配", "wrong-facing adjacent cargo is not reported as incoming material")
	var model := Model.new()
	var source: Dictionary = model.place("belt", Vector2i(-13, -5)).entity
	var gate: Dictionary = model.place("admission_gate", Vector2i(-12, -5)).entity
	var sink: Dictionary = model.place("storage", Vector2i(-11, -6)).entity
	near(model, gate)
	model.configure_admission(gate.id, "crystal", "quota", 1)
	model.set_admission_accepting(gate.id, true)
	source.cargo = "rich_crystal"
	source.progress = 1.0
	model._logistics(0.05)
	expect(source.cargo == "rich_crystal" and gate.cargo.is_empty() and gate.quota_used == 0, "wrong input stays upstream")
	source.cargo = "crystal"
	model._logistics(0.05)
	expect(source.cargo.is_empty() and gate.cargo == "crystal" and gate.progress == 0 and gate.quota_used == 0, "receipt reserves last quota without counting output")
	model.set_admission_accepting(gate.id, false)
	for i in 19: model._logistics(0.05)
	expect(sink.items.is_empty(), "closed receiver does not shorten held cargo travel")
	model._logistics(0.05)
	expect(sink.items.crystal == 1 and gate.quota_used == 1 and gate.cargo.is_empty(), "closed receiver drains held cargo and counts successful output")
	model.set_admission_accepting(gate.id, true)
	source.cargo = "crystal"
	source.progress = 1.0
	model._logistics(0.05)
	expect(gate.cargo.is_empty() and source.cargo == "crystal" and gate.quota_used == 1, "reopening exhausted quota cannot receive again")
	expect(model.reset_admission(gate.id).ok and gate.accepting and gate.quota_used == 0, "explicit empty reset preserves switch")
	model._logistics(0.05)
	sink.items = {"crystal": 200}
	for i in 20: model._logistics(0.05)
	expect(gate.cargo == "crystal" and gate.quota_used == 0, "blocked final output keeps reservation and count")
	sink.items = {}
	model._logistics(0.05)
	expect(gate.cargo.is_empty() and gate.quota_used == 1, "unblocked output commits count exactly once")
	var split_model := Model.new()
	var split: Dictionary = split_model.place("splitter", Vector2i(-12, -5)).entity
	var first: Dictionary = split_model.place("admission_gate", Vector2i(-11, -5)).entity
	var second: Dictionary = split_model.place("admission_gate", Vector2i(-12, -4), 1).entity
	near(split_model, first)
	split_model.configure_admission(first.id, "crystal", "unlimited", 0)
	split_model.set_admission_accepting(first.id, true)
	near(split_model, second)
	split_model.configure_admission(second.id, "rich_crystal", "unlimited", 0)
	split_model.set_admission_accepting(second.id, true)
	split.cargo = "rich_crystal"
	split.progress = 1
	split_model._logistics(0.05)
	expect(first.cargo.is_empty() and second.cargo == "rich_crystal" and split.cargo.is_empty(), "splitter retries a directly compatible admission branch")


func _natural_and_codec() -> void:
	var model := crystal_line()
	var gate: Dictionary = model.by_id(2)
	while model.time < 30 and not (gate.quota_used == 3 and gate.cargo == "crystal" and gate.progress > 0.1 and gate.progress < 0.8): model.advance(0.05)
	expect(gate.quota_used == 3 and gate.cargo == "crystal", "natural production reaches third output and fourth partial item")
	var doc := snapshot(model)
	var decoded := Codec.decode(JSON.parse_string(JSON.stringify(doc, "", false, true)), ID)
	expect(decoded.ok, "strict schema5 natural snapshot roundtrip: " + decoded.get("reason", ""))
	if not decoded.ok: return
	write_json("partial.json", doc)
	var restored: RefCounted = decoded.model
	restored.entities.reverse()
	for i in 120:
		model.advance(0.05)
		restored.advance(0.05)
		expect(Compare.equivalent(snapshot(model), snapshot(restored)), "restored/reordered per-step trajectory %d" % i)
		expect(Codec.decode(snapshot(model), ID).ok, "per-step strict material/batch/quota conservation %d" % i)
	expect(gate.quota_used == 4 and gate.cargo.is_empty() and model.by_id(3).items.crystal == 4, "only fourth item exits after restore point")
	write_json("expected.json", snapshot(model))
	for fps in [30, 60, 144]:
		var framed: RefCounted = Codec.decode(doc, ID).model
		var reference: RefCounted = Codec.decode(doc, ID).model
		for frame in fps * 3: framed.advance(1.0 / fps)
		reference.advance(3.0)
		var a := snapshot(framed)
		var b := snapshot(reference)
		a.state.remainder = 0.0
		b.state.remainder = 0.0
		expect(Compare.equivalent(a, b), "quota fixed-step consistency at %d FPS" % fps)
	for key in ["extra", "item", "mode", "limit", "used", "switch", "entry", "cargo", "unlimited", "future", "budget"]:
		var invalid: Dictionary = doc.duplicate(true)
		var g: Dictionary = invalid.state.entities[1]
		match key:
			"extra": g.hidden_quota = 1
			"item": g.filter_item = "catalyst"
			"mode": g.quota_mode = "rate"
			"limit": g.quota_limit = 4.5
			"used": g.quota_used = 4
			"switch": g.accepting = 1
			"entry": g.entry = [1, 0]
			"cargo": g.cargo = "crust_sample"
			"unlimited": g.quota_mode = "unlimited"
			"future": invalid.save_schema_version = 6
			"budget": invalid.state.kits.admission_gate += 1
		expect(not Codec.decode(invalid, ID).ok, "strict rejection of " + key)
	expect(not Codec.V4.decode(doc, ID).ok, "old V4 codec explicitly refuses V5")
	near(model, gate)
	model.configure_admission(gate.id, "crystal", "unlimited", 0)
	model.advance(6)
	expect(model.by_id(3).items.crystal > 4 and gate.quota_used == 0 and Codec.decode(snapshot(model), ID).ok, "unlimited mode filters without cumulative quota fields")


func _legacy_trajectory() -> void:
	var old := RoutingCheck.line()
	old.advance(30)
	var upgraded := Codec.V5.upgrade(Codec.snapshot(old, ID, "旧 V4 轨迹", 1))
	expect(upgraded.ok, "valid V4 upgrades to V5")
	if not upgraded.ok: return
	var current: RefCounted = upgraded.model
	for i in 80:
		old.advance(0.05)
		current.advance(0.05)
		var a: Dictionary = snapshot(old).state
		var b: Dictionary = snapshot(current).state
		b.kits.erase("admission_gate")
		expect(Compare.equivalent(a, b), "unchanged old-line trajectory without gates %d" % i)


func _store() -> void:
	for fault in ["upgrade_backup", "reconstruction", "temporary_write", "readback", "publish"]:
		var store := Store.new(evidence.path_join("fault-" + fault))
		var created := store.create("V4 升级故障", Codec.V2.Config.ROUTING_SUPPLY_ID, true)
		expect(created.ok, "create isolated V4 " + fault)
		if not created.ok: continue
		var original := FileAccess.get_file_as_string(store.path("autosave.json"))
		var id: String = store.world_id
		store.release()
		var candidate := store.prepare(id)
		var staged := store.upgrade_admission(candidate)
		expect(staged.ok and FileAccess.get_file_as_string(store.path("autosave.json")) == original, "staging preserves original " + fault)
		store.fault = func(stage): return stage == fault
		var result := store.accept(staged)
		expect(not result.ok and FileAccess.get_file_as_string(store.path("autosave.json")) == original, "failed upgrade preserves main " + fault)
		store.release()
		store.fault = Callable()
		candidate = store.prepare(id)
		staged = store.upgrade_admission(candidate)
		expect(staged.ok and store.accept(staged).ok, "retry commits one valid upgrade " + fault)
		var retained := false
		for name in DirAccess.get_files_at(store.path("backups")):
			if name.begins_with("pre-admission-v4-") and FileAccess.get_file_as_string(store.path("backups/" + name)) == original: retained = true
		expect(retained, "independent source retained byte-for-byte " + fault)
		store.release()
		candidate = store.prepare(id)
		expect(candidate.ok and candidate.document.save_schema_version == 5 and candidate.model.kits.admission_gate == 8 and not store.upgrade_admission(candidate).ok, "cannot grant twice " + fault)
		store.release()

	var changed := Store.new(evidence.path_join("source-hash"))
	changed.create("来源哈希保护", Codec.V2.Config.ROUTING_SUPPLY_ID, true)
	var source_id: String = changed.world_id
	changed.release()
	var changed_candidate := changed.upgrade_admission(changed.prepare(source_id))
	var source := FileAccess.get_file_as_string(changed.path("autosave.json")) + " "
	var file := FileAccess.open(changed.path("autosave.json"), FileAccess.WRITE)
	file.store_string(source)
	file.close()
	expect(not changed.accept(changed_candidate).ok and FileAccess.get_file_as_string(changed.path("autosave.json")) == source, "changed source hash blocks publication")
	changed.release()
	var future := Store.new(evidence.path_join("future"))
	future.create("未来版本保护", Codec.V2.Config.ADMISSION_SUPPLY_ID, true)
	var future_id: String = future.world_id
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(future.path("autosave.json")))
	var old: Dictionary = doc.duplicate(true)
	old.save_schema_version = 4
	old.ruleset_id = Codec.V2.Config.ROUTING_RULESET_ID
	old.supply_id = Codec.V2.Config.ROUTING_SUPPLY_ID
	old.state.kits.erase("admission_gate")
	DirAccess.make_dir_recursive_absolute(future.path("backups"))
	file = FileAccess.open(future.path("backups/autosave.bak.1.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	doc.save_schema_version = 6
	file = FileAccess.open(future.path("autosave.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(doc))
	file.close()
	future.release()
	expect(not future.prepare(future_id).ok, "future primary blocks old V4 backup fallback")


func _combined() -> void:
	var old := RoutingCheck.line()
	var upgraded := Codec.V5.upgrade(Codec.snapshot(old, ID, "组合夹具", 1))
	if not upgraded.ok: expect(false, "combined fixture upgrades"); return
	var model: RefCounted = upgraded.model
	var gates: Array[Dictionary] = []
	for cell in [Vector2i(-16, 0), Vector2i(-16, 6)]:
		model.salvage(model.entity_at(cell).id)
		var gate: Dictionary = model.place("admission_gate", cell).entity
		near(model, gate)
		model.configure_admission(gate.id, "crystal", "quota" if cell.y == 0 else "unlimited", 2 if cell.y == 0 else 0)
		model.set_admission_accepting(gate.id, true)
		gates.append(gate)
	var batches := [{}, {}]
	for tick in 2400:
		model.advance(0.05)
		for index in 2:
			var e: Dictionary = model.by_id(3 + index)
			if e.active_batch > 0: batches[index][e.active_batch] = true
	write_json("combined.json", snapshot(model))
	write_json("combined-batches.json", {"first": batches[0].keys(), "second": batches[1].keys()})
	expect(gates[0].quota_used == 2 and gates[0].cargo.is_empty(), "combined finite branch stops at two crystals")
	expect(batches[0].size() == 1 and batches[1].size() >= 4 and model.delivered >= 4, "split/filter/reactor/merge/warehouse combination completes one finite and repeated other batches")
	expect(Codec.decode(snapshot(model), ID).ok, "combined batch transit and statistics remain strictly conserved")


func _panel() -> void:
	var model := crystal_line()
	var gate: Dictionary = model.by_id(2)
	var panel := DevicePanel.new()
	root.add_child(panel)
	expect(panel.show_device(model, gate.id) and panel.admission_controls.visible and not panel.bag_frame.visible, "nearby gate uses dedicated configuration and no manual inventory transfer")
	var controls: Control = panel.admission_controls
	var before := snapshot(model)
	controls.item.select(2)
	panel.refresh()
	expect(controls.item.selected == 2 and snapshot(model) == before, "production refresh preserves uncommitted filter choice")
	panel.close_panel()
	panel.show_device(model, gate.id)
	expect(controls.item.selected == 1 and snapshot(model) == before, "close/reopen discards uncommitted candidate")
	controls.limit.value = 1
	controls.apply_button.pressed.emit()
	expect(gate.quota_limit == 1 and gate.accepting and "重置" in panel.result_label.text, "apply command reports new round while keeping switch")
	panel.queue_free()
	await process_frame


func _restore() -> void:
	var partial: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("partial.json")))
	var restored := Codec.decode(partial, ID)
	expect(restored.ok, "independent process decodes partial schema5")
	if not restored.ok: return
	restored.model.advance(6)
	var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("expected.json")))
	expect(Compare.equivalent(snapshot(restored.model), expected), "independent process preserves partial quota and resulting trajectory")


func write_json(name: String, value: Variant) -> void:
	var file := FileAccess.open(evidence.path_join(name), FileAccess.WRITE)
	file.store_string(JSON.stringify(value, "\t", false, true))
	file.close()
