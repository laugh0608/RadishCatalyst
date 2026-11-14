extends SceneTree

const Model := preload("res://scripts/factory/energy_model.gd")
const Codec := preload("res://scripts/factory/save/codec.gd")
const Store := preload("res://scripts/factory/save/store.gd")
const Compare := preload("res://scripts/checks/factory_expansion_compare.gd")
const ID := "88888888888888888888888888888888"
var checks := 0
var failures: Array[String] = []
var evidence := ""


func _init() -> void:
	call_deferred("run")


func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)


func close(a: float, b: float) -> bool:
	return absf(a - b) < 1e-7


func snap(m: RefCounted) -> Dictionary:
	return Codec.snapshot(m, ID, "待机耗电验证", 1)


func write(name: String, value: Variant) -> void:
	var file := FileAccess.open(evidence.path_join(name), FileAccess.WRITE)
	expect(file != null, "write " + name)
	if file != null: file.store_string(JSON.stringify(value, "\t", false, true))


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	if evidence.is_empty():
		evidence = SliceCheckPaths.check_run("factory-energy-and-focus-feedback-v1", false).path_join("state-%d-%d" % [Time.get_unix_time_from_system(), OS.get_process_id()])
	DirAccess.make_dir_recursive_absolute(evidence)
	if "--read" in OS.get_cmdline_user_args():
		_restore()
	else:
		_power()
		_save_and_copy()
	write("read-result.json" if "--read" in OS.get_cmdline_user_args() else "state-result.json", {"assertions": checks, "failures": failures, "scope": "fixed-step power fixtures; mined partial-batch persistence and explicit source-preserving copies; no window or natural-clock claim"})
	print("Standby state: %d assertions, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _power() -> void:
	# Isolated synthetic fixtures exercise power, not material conservation.
	for enabled_rule in [false, true]:
		var m := Model.new(enabled_rule)
		m.place("power_source", Vector2i(-18, -15))
		var f: Dictionary = m.place("refinery", Vector2i(-15, -10)).entity
		var d: Dictionary = m.grid.allocate(m, 0.05).devices[f.id]
		expect(close(d.request_kw, 6 if enabled_rule else 0), "only V8 charges empty furnace")
		m._step(0.05)
		expect(not f.processing and f.progress == 0 and close(m.statistics.totals.used_kj, 0.3 if enabled_rule else 0), "idle energy makes no progress")
		m.actor.x = f.x - 0.6; m.actor.z = f.z + 0.5
		expect(m.set_device_enabled(f.id, false).ok, "local stop")
		var before := snap(m)
		expect(m.grid.allocate(m, 0.05).devices[f.id].request_kw == 0, "manual stop requests zero")
		for i in 10: m.power_state(); m.feedback(f); m._refresh_automatic_power()
		expect(Compare.equivalent(before, snap(m)), "queries never account energy")
		expect(m.set_device_enabled(f.id, true).ok, "local restart")
		f.processing = true; f.progress = 7.99; f.invested = {"iron_ore": 2}
		d = m.grid.allocate(m, 0.05).devices[f.id]
		expect(close(d.request_kw, 16.8 if enabled_rule else 12) and close(d.work, 0.01), "tail step includes only remaining work and optional standby")
		f.progress = 1.0
		d = m.grid.allocate(m, 0.05).devices[f.id]
		expect(close(d.request_kw, 60) and d.standby_request_kw == 0, "full working step never adds idle twice")
	var m := Model.new(true)
	var f: Dictionary = m.place("refinery", Vector2i(-15, -10)).entity
	var d: Dictionary = m.grid.allocate(m, 0.05).devices[f.id]
	expect(close(d.request_kw, 6) and close(d.supplied_kw, 0) and d.network == -1, "unplugged idle requests but consumes zero")
	m._step(0.05)
	expect(m.statistics.totals.standby_kj == 0 and m.statistics.totals.used_kj == 0, "unplugged idle not billed")
	m.first_expansion_placed = true; m.kits.cell_generator = 1
	var g: Dictionary = m.place("cell_generator", Vector2i(-10, -10)).entity
	g.remaining_kj = 0.42
	f.processing = true; f.progress = 7.99; f.invested = {"iron_ore": 2}
	d = m.grid.allocate(m, 0.05).devices[f.id]
	expect(close(d.fraction, 0.5) and close(d.supplied_kw, 8.4) and close(d.standby_supplied_kw, 2.4), "finite fuel scales work and idle by same fraction")
	var plan: Dictionary = m.grid.allocate(m, 0.05)
	expect(close(plan.work[f.id], 0.005), "tail shortage keeps original remaining-work budget")
	m._step(0.05)
	expect(close(m.statistics.totals.used_kj, 0.42) and close(m.statistics.totals.standby_kj, 0.12) and close(g.remaining_kj, 0), "tail bills work 0.30 and idle 0.12 once")
	d = m.grid.allocate(m, 0.05).devices[f.id]
	expect(d.request_kw > 6 and close(d.supplied_kw, 0), "no fuel preserves running demand instead of disguising shortage as idle")
	for type in Model.Energy.STANDBY_KW:
		var probe := {"type": type, "enabled": true, "progress": 0.0, "processing": false, "output": {}, "input": {}, "recipe_id": {"refinery": "direct_refining", "crusher": "iron_crushing", "assembler": "construction_assembly", "reactor": "basic_catalyst"}.get(type, ""), "buffer": {"crystal": 50}, "mineral": "crystal"}
		expect(m.work_spec(probe).standby_kw == Model.Energy.STANDBY_KW[type] and not m.work_spec(probe).ready, "idle specification " + type)
		probe.enabled = false
		expect(m.work_spec(probe).standby_kw == 0 and not m.work_spec(probe).ready, "off specification " + type)
	for recipe in ["basic_catalyst", "crust_solvent", "rich_catalyst"]:
		var probe := {"type": "reactor", "enabled": true, "processing": false, "output": {}, "input": {}, "recipe_id": recipe}
		expect(m.work_spec(probe).standby_kw == 4, "reactor idle independent of recipe " + recipe)


func _save_and_copy() -> void:
	var m := Model.new(true)
	var c: Dictionary = m.place("collector", Vector2i(-28, -12)).entity
	var f: Dictionary = m.place("refinery", Vector2i(-24, -12)).entity
	m.place("power_source", Vector2i(-27, -16))
	for i in 45: m._step(0.05)
	m.actor.x = -28.6; m.actor.z = -11.5
	expect(m.transfer(c.id, "iron_ore", false, true).ok, "mine real copy-test inputs")
	m.actor.x = -24.6; m.actor.z = -11.5
	expect(m.transfer(f.id, "iron_ore", true, true).ok, "transfer real inputs")
	for i in 23: m._step(0.05)
	expect(f.processing and f.progress > 0 and m.statistics.totals.standby_kj > 0, "nonempty work and idle history")
	var doc := snap(m)
	var restored := Codec.decode(JSON.parse_string(JSON.stringify(doc)), ID)
	expect(restored.ok and Compare.equivalent(snap(restored.model), doc), "V8 exact roundtrip including partial bucket")
	for change in ["negative", "exceeds_total", "missing", "unknown", "bucket", "identity", "legacy"]:
		var bad: Dictionary = doc.duplicate(true)
		match change:
			"negative": bad.state.statistics.totals.standby_kj = -1.0
			"exceeds_total": bad.state.statistics.totals.standby_kj = bad.state.statistics.totals.used_kj + 1
			"missing": bad.state.statistics.current.erase("standby_kj")
			"unknown": bad.state.statistics.totals.idle_loss = 0
			"bucket": bad.state.statistics.buckets[0].standby_kj += 0.1
			"identity": bad.ruleset_id = Model.Energy.RULESET_ID
			"legacy": bad.save_schema_version = 7; bad.ruleset_id = Model.Energy.RULESET_ID
		expect(not Codec.decode(bad, ID).ok, "reject invalid standby save " + change)
	write("partial.json", doc)
	for i in 1600: m._step(0.05)
	write("expected.json", snap(m))
	expect(m.statistics.buckets.size() >= 60 and m.statistics.window(60).standby_kj > 0, "standby window aggregated")
	# A V7 source retains its original simulation and statistics schema.
	var old := Model.new()
	old.place("refinery", Vector2i(-24, -12))
	old.place("power_source", Vector2i(-27, -16))
	for i in 25: old._step(0.05)
	var old_doc := snap(old)
	expect(old_doc.save_schema_version == 7 and not old.statistics.totals.has("standby_kj"), "V7 identity and fields unchanged")
	var source_hash := JSON.stringify(old_doc).sha256_text()
	var copied := Codec.V8.copy_from(old_doc, "88888888888888888888888888888889", "旧 E2 显式复制", source_hash)
	expect(copied.ok, "copy old E2 to V8")
	if copied.ok:
		expect(copied.model.statistics.totals.standby_kj == 0 and copied.model.statistics.totals.used_kj == old.statistics.totals.used_kj, "copy does not retroactively charge standby")
		copied.model._step(0.05)
		expect(close(copied.model.statistics.totals.standby_kj, 0.3) and Compare.equivalent(old_doc, snap(old)), "only copy starts idle accounting")
	var store := Store.new(evidence.path_join("factory"))
	var created := store.create("新版新建", Model.Energy.SUPPLY_ID, true)
	expect(created.ok and created.model.standby_power, "Store creates current E2 rules")
	if created.ok:
		expect(not store.save(old).ok, "V8 session rejects old rules with same supply")
		store.release()


func _restore() -> void:
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("partial.json")))
	var restored := Codec.decode(doc, ID)
	expect(restored.ok, "independent V8 restore")
	if not restored.ok: return
	for i in 1600: restored.model._step(0.05)
	var expected: Variant = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("expected.json")))
	expect(Compare.equivalent(snap(restored.model), expected), "independent work-idle trajectory identical")
