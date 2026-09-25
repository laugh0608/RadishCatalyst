extends SceneTree

const Model := preload("res://scripts/factory/discovery_model.gd")
const PowerCheck := preload("res://scripts/checks/factory_power_check.gd")
const Codec := preload("res://scripts/factory/save/codec.gd")
const Store := preload("res://scripts/factory/save/store.gd")
const ID := "1234567890abcdef1234567890abcdef"
var assertions := 0
var failures: Array[String] = []
var evidence_root := ""


func _init() -> void:
	call_deferred("run")


func expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
		push_error(label)


func doc(m: RefCounted) -> Dictionary:
	return Codec.snapshot(m, ID, "开拓状态验证", 1)


func roundtrip(m: RefCounted, label: String) -> RefCounted:
	var restored := Codec.decode(JSON.parse_string(JSON.stringify(doc(m), "", false, true)), ID)
	expect(restored.ok, label + " decode: " + restored.get("reason", ""))
	if not restored.ok:
		return m
	expect(equivalent(doc(restored.model), doc(m)), label + " complete snapshot")
	var a: RefCounted = Codec.decode(doc(m), ID).model
	a.advance(2)
	restored.model.advance(2)
	expect(equivalent(doc(a), doc(restored.model)), label + " next 40 steps")
	return restored.model


func near(m: RefCounted, id: int) -> void:
	var e: Dictionary = m.by_id(id)
	m.actor.x = e.x - 1.0
	m.actor.z = e.z + 0.5


func transfer(m: RefCounted, id: int, item: String, putting: bool, all_items := true) -> void:
	var result: Dictionary = m.transfer(id, item, putting, all_items)
	expect(result.ok, "transfer " + item + ": " + result.get("reason", ""))


func reject_unchanged(m: RefCounted, operation: Callable, label: String) -> void:
	var before := doc(m)
	var result: Dictionary = operation.call()
	expect(not result.ok and before == doc(m), label + " rejected atomically")


func run() -> void:
	evidence_root = ProjectSettings.globalize_path("res://../tools/runtime-intake/check-runs/factory-discovery-v1/d2-b-20260925")
	DirAccess.make_dir_recursive_absolute(evidence_root)
	if "--read-multi" in OS.get_cmdline_user_args():
		var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(evidence_root.path_join("multi-output.json")))
		var loaded := Codec.decode(saved, ID)
		expect(loaded.ok, "independent process loads partial batch")
		if loaded.ok:
			loaded.model.advance(20)
			var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(evidence_root.path_join("multi-expected.json")))
			expect(equivalent(doc(loaded.model), expected), "independent process 400-step trajectory")
		print("Discovery cross-process: %d assertions, %d failures" % [assertions, failures.size()])
		quit(0 if failures.is_empty() else 1)
		return
	var m := PowerCheck.line()
	m.connect_power(13, 1)
	m.connect_power(14, 2)
	roundtrip(m, "sample still on ground")
	m.actor.x = 2.5
	m.actor.z = 3.5
	fixture(m, "sample-ready")
	m.advance(290, 6000)
	expect(m.by_id(3).items.get("catalyst", 0) >= 24, "natural ordinary line produces opening materials")
	reject_unchanged(m, func(): return m.transfer(3, "catalyst", false, true), "remote withdrawal")
	near(m, 3)
	transfer(m, 3, "catalyst", false)
	m.actor.x = 2.5
	m.actor.z = 3.5
	expect(m.survey_sample().ok and not m.discovery.sample_taken, "survey does not take sample")
	expect(m.survey_sample(true).ok, "pick unique sample")
	reject_unchanged(m, func(): return m.survey_sample(true), "second pickup")
	roundtrip(m, "sample in bag")
	near(m, 3)
	transfer(m, 3, "crust_sample", true)
	roundtrip(m, "sample in storage")
	transfer(m, 3, "crust_sample", false)
	near(m, 2)
	if m.by_id(2).processing:
		expect(m.cancel_batch(2).ok, "cancel ordinary batch")
	for item in ["crystal", "catalyst"]:
		if Model.Items.contents(m.by_id(2)).get(item, 0) > 0:
			transfer(m, 2, item, false)
	expect(m.change_recipe(2, "solvent_trial").ok, "select unlocked trial")
	fixture(m, "trial-ready")
	transfer(m, 2, "crust_sample", true)
	roundtrip(m, "unique sample in trial input")
	reject_unchanged(m, func(): return m.change_recipe(2, "basic_catalyst"), "switch with input")
	transfer(m, 2, "catalyst", true)
	m.advance(4.5)
	roundtrip(m, "sample in half trial")
	var used: float = m.statistics.totals.used_kj
	var material: Dictionary = m.statistics.totals.consumed.duplicate()
	expect(m.cancel_batch(2).ok and m.bag.crust_sample == 1, "trial cancel returns unique original sample")
	expect(m.statistics.totals.used_kj == used and m.statistics.totals.consumed == material and not m.discovery.trial_completed, "cancel preserves energy without fake consumption or unlock")
	roundtrip(m, "canceled trial")
	transfer(m, 2, "crust_sample", true)
	transfer(m, 2, "catalyst", true)
	m.advance(10)
	expect(m.discovery.trial_completed and m.statistics.totals.consumed.crust_sample == 1, "trial consumes unique sample once and unlocks")
	# Existing output belt receives the trial product in the same final step.
	m.advance(5)
	near(m, 3)
	transfer(m, 3, "crust_solvent", false)
	near(m, 2)
	expect(m.change_recipe(2, "crust_solvent").ok, "switch to repeatable solvent")
	for i in 3:
		transfer(m, 2, "catalyst", true)
		m.advance(8)
	m.advance(5)
	near(m, 3)
	transfer(m, 3, "crust_solvent", false)
	expect(m.bag.crust_solvent == 4, "trial plus 3 repeatable batches provide first opening")
	roundtrip(m, "before first opening")
	reject_unchanged(m, func(): return m.open_passage("outer"), "distant opening")
	m.actor.x = 2.5
	m.actor.z = 0.5
	reject_unchanged(m, func(): return m.open_passage("inner"), "second passage prerequisite")
	expect(not Model.Grid.line_open(Vector2(2.5, 0.5), Vector2(9.5, 0.5), m.discovery.passages), "closed passage blocks electrical edge")
	fixture(m, "outer-ready")
	expect(m.open_passage("outer").ok and m.statistics.totals.consumed.crust_solvent == 4, "first passage debits once")
	reject_unchanged(m, func(): return m.open_passage("outer"), "repeated opening")
	expect(not m.blocked_for_actor(5.5, 0.5) and m.placement("belt", Vector2i(5, 0)).ok, "opened geometry allows walk and building")
	expect(m.blocked_for_actor(5.5, 2.5) and not m.placement("belt", Vector2i(5, 2)).ok, "outside aperture still blocked")
	expect(Model.Grid.line_open(Vector2(2.5, 0.5), Vector2(9.5, 0.5), m.discovery.passages), "opening permits actual electrical edge")
	roundtrip(m, "first opening permanent")
	var collector: Dictionary = m.place("collector", Vector2i(10, -1)).entity
	var reactor: Dictionary = m.place("reactor", Vector2i(14, -2)).entity
	var source: Dictionary = m.place("power_source", Vector2i(10, -6)).entity
	expect(m.connect_power(source.id, collector.id).ok and m.connect_power(source.id, reactor.id).ok, "new region explicit power connections")
	for x in range(17, 20):
		m.place("belt", Vector2i(x, 0))
	m.advance(1)
	near(m, collector.id)
	transfer(m, collector.id, "rich_crystal", false)
	near(m, reactor.id)
	expect(m.change_recipe(reactor.id, "rich_catalyst").ok, "select rich recipe")
	transfer(m, reactor.id, "rich_crystal", true)
	var first_source: Dictionary = m.by_id(13)
	m.set_source_enabled(first_source.id, false)
	used = m.statistics.totals.used_kj
	m.advance(0.05)
	expect(absf(m.statistics.totals.used_kj - used - 5) < 1e-7, "rich reactor 80kW plus collector 20kW")
	m.advance(11.95)
	expect(reactor.output.get("catalyst", 0) == 2, "three-product batch retains two after first belt transfer")
	roundtrip(m, "partial three-product batch")
	fixture(m, "rich-half")
	var half := doc(m)
	var file := FileAccess.open(evidence_root.path_join("multi-output.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(half, "\t", false, true))
	file.close()
	var projected: RefCounted = Codec.decode(half, ID).model
	projected.advance(20)
	file = FileAccess.open(evidence_root.path_join("multi-expected.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(doc(projected), "\t", false, true))
	file.close()
	m.advance(2.1)
	expect(reactor.output.is_empty(), "three units transfer individually")
	roundtrip(m, "same batch in three belts")
	m.set_source_enabled(first_source.id, true)
	near(m, 2)
	for i in 8:
		transfer(m, 2, "catalyst", true)
		m.advance(8)
	m.advance(5)
	near(m, 3)
	transfer(m, 3, "crust_solvent", false)
	m.actor.x = 18.5
	m.actor.z = 0.5
	fixture(m, "inner-ready")
	expect(m.open_passage("inner").ok and m.statistics.totals.consumed.crust_solvent == 12, "second opening spends additional eight")
	expect(m.placement("collector", Vector2i(26, -13)).ok and not m.blocked_for_actor(22.5, 0.5), "deep mine and aperture accessible")
	roundtrip(m, "both openings")
	_test_rejections(half)
	_test_capacity()
	_test_automatic_chain(m)
	_test_legacy_fixture()
	print("Factory discovery checks: %d assertions, %d failures" % [assertions, failures.size()])
	file = FileAccess.open(evidence_root.path_join("state-result.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"assertions": assertions, "failures": failures}, "\t"))
	quit(0 if failures.is_empty() else 1)


func _test_rejections(saved: Dictionary) -> void:
	for mutation in ["sample_duplicate", "sample_belt", "cost_mismatch", "bad_recipe", "bad_mineral", "extra_output", "bad_invested", "bad_consumption", "fraction", "unknown", "future"]:
		var bad := saved.duplicate(true)
		match mutation:
			"sample_duplicate": bad.state.bag.crust_sample = 1
			"sample_belt": bad.state.entities[3].cargo = "crust_sample"
			"cost_mismatch": bad.state.discovery.passages.outer = false
			"bad_recipe": bad.state.entities[1].recipe_id = "future_recipe"
			"bad_mineral": bad.state.entities[0].mineral = "rich_crystal"
			"extra_output": bad.state.entities[15].output.catalyst = 4
			"bad_invested": bad.state.entities[1].invested.catalyst = 2
			"bad_consumption": bad.state.statistics.totals.consumed.crystal += 1
			"fraction": bad.state.bag.crystal = 1.5
			"unknown": bad.state.extra = true
			"future": bad.save_schema_version = 3
		var decoded := Codec.decode(bad, ID)
		expect(not decoded.ok, mutation + " rejected")
		if mutation in ["future", "bad_recipe"]:
			expect(decoded.get("unsupported", false), mutation + " blocks fallback")


func _test_capacity() -> void:
	# Deliberately synthetic inventory fixtures exercise command atomicity only.
	var m := Model.new()
	m.actor.x = 2.5
	m.actor.z = 3.5
	m.bag = {"crystal": 200}
	expect(not m.survey_sample(true).ok and m.discovery.surveyed and not m.discovery.sample_taken and m.bag == {"crystal": 200}, "full bag survey retains ground sample")
	var e: Dictionary = m.place("reactor", Vector2i(-5, -2)).entity
	near(m, e.id)
	e.processing = true
	e.active_batch = 1
	e.invested = {"crystal": 2}
	e.progress = 3.0
	reject_unchanged(m, func(): return m.cancel_batch(e.id), "full bag cancellation")
	reject_unchanged(m, func(): return m.salvage(e.id), "full bag salvage")
	e.processing = false
	e.active_batch = 0
	e.invested.clear()
	e.progress = 0.0
	transfer(m, e.id, "crystal", true)
	expect(e.input == {"crystal": 2} and m.bag.crystal == 198, "put all caps at one recipe batch")
	reject_unchanged(m, func(): return m.transfer(e.id, "catalyst", true, true), "wrong ingredient")
	m.bag = {"crystal": 199}
	transfer(m, e.id, "crystal", false)
	expect(m.bag.crystal == 200 and e.input.crystal == 1, "take all caps at bag capacity")


func _test_legacy_fixture() -> void:
	# Retained D2-A document; only final LF normalized for repository hygiene.
	var path := "res://scripts/checks/fixtures/factory_discovery_d2a.json"
	if not FileAccess.file_exists(path):
		expect(false, "retained D2-A fixture required")
		return
	var hash := FileAccess.get_sha256(path)
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(path))
	var restored := Codec.decode(saved, saved.world_id)
	expect(restored.ok, "existing D2-A schema 2 loads: " + restored.get("reason", ""))
	expect(FileAccess.get_sha256(path) == hash, "existing fixture remains byte identical")
	if restored.ok:
		restored.model.advance(20)
		expect(Codec.decode(Codec.snapshot(restored.model, saved.world_id, saved.name, saved.sequence + 1), saved.world_id).ok, "existing ordinary world continues without migration")


static func equivalent(a: Variant, b: Variant, path := "state") -> bool:
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size():
			return false
		for key in a:
			if not b.has(key) or not equivalent(a[key], b[key], path + "." + key):
				return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size():
			return false
		for i in a.size():
			if not equivalent(a[i], b[i], path + "[%d]" % i):
				return false
		return true
	if (a is int or a is float) and (b is int or b is float):
		if a == floor(a) and b == floor(b):
			return a == b
		if absf(a - b) <= 1e-12:
			return true
	if a != b:
		print("snapshot mismatch ", path, ": ", a, " / ", b)
	return a == b


func fixture(m: RefCounted, name: String) -> void:
	var file := FileAccess.open(evidence_root.path_join(name + ".json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(doc(m), "\t", false, true))
	file.close()


func _test_automatic_chain(unlocked: RefCounted) -> void:
	# Continue a naturally unlocked state; relocate only the actor for test commands.
	var m: RefCounted = Codec.decode(doc(unlocked), ID).model
	near(m, 3)
	for item in m.by_id(3).items.keys():
		transfer(m, 3, item, false)
	expect(m.salvage(3).ok, "remove empty terminal for continuous chain")
	var solvent: Dictionary = m.place("reactor", Vector2i(-6, -2)).entity
	near(m, solvent.id)
	expect(m.change_recipe(solvent.id, "crust_solvent").ok, "downstream solvent recipe")
	var node: Dictionary = m.place("power_junction", Vector2i(-6, -5)).entity
	expect(m.connect_power(14, node.id).ok and m.connect_power(node.id, solvent.id).ok, "chain shares explicit 120kW grid")
	var storage: Dictionary = m.place("storage", Vector2i(0, -1)).entity
	for x in range(-3, 0):
		m.place("belt", Vector2i(x, 0))
	near(m, 2)
	for item in m.by_id(2).input.keys():
		transfer(m, 2, item, false)
	expect(m.change_recipe(2, "basic_catalyst").ok, "restore upstream basic recipe")
	var prior: int = m.statistics.totals.produced.crust_solvent
	m.advance(58)
	fixture(m, "automatic-chain")
	expect(storage.items.get("crust_solvent", 0) >= 2 and m.statistics.totals.produced.crust_solvent >= prior + 2, "collector to catalyst to solvent to warehouse is automatic")
	roundtrip(m, "automatic solvent chain")
