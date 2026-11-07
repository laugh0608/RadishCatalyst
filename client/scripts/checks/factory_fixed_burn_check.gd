extends SceneTree

const Journey := preload("res://scripts/checks/factory_fixed_burn_journey.gd")
const Model := Journey.Model
const Store := preload("res://scripts/factory/save/store.gd")
const Codec := Store.Codec
const Step := Model.STEP
const NAME := "整合工厂跨进程"
var checks := 0
var failures: Array[String] = []
var evidence := ""


func _init() -> void:
	call_deferred("run")


func expect(ok: bool, label: String) -> bool:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)
	return ok


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--batch="):
			var name := arg.trim_prefix("--batch=")
			if name.is_valid_filename() and not ".." in name:
				evidence = SliceCheckPaths.check_run("factory-integrated-c-v1", false).path_join(name)
	if evidence.is_empty() or not DirAccess.dir_exists_absolute(evidence):
		push_error("Requires a prepared isolated batch.")
		quit(2)
		return
	var reading := "--read" in OS.get_cmdline_user_args()
	if reading:
		_restore()
	else:
		_burn_boundaries()
		_save()
	var phase := "read" if reading else "write"
	print("Factory integrated C %s: %d checks, %d failures" % [phase, checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _burn_boundaries() -> void:
	var model := Model.new()
	# Controlled edge fixture for two electrically independent sources.
	model.researched[Model.Progression.CELLS] = true
	model.kits.cell_generator = 2
	var g: Dictionary = Journey.must(model.place("cell_generator", Vector2i(-29, -23))).entity
	var other: Dictionary = Journey.must(model.place("cell_generator", Vector2i(-7, 16))).entity
	model.actor.x = -30
	model.actor.z = -22
	model.bag.industrial_cell = 6
	expect(model.transfer(g.id, "industrial_cell", true, true).get("amount", 0) == 5 and model.bag.industrial_cell == 1, "manual fuel caps at five")
	model.advance(1.0)
	expect(g.fuel.industrial_cell == 5 and model.statistics.totals.cells_activated == 0, "default off leaves fuel intact")
	model.set_device_enabled(g.id, true)
	model.actor.x = -8
	model.actor.z = 16
	model.transfer(other.id, "industrial_cell", true, false)
	model.set_device_enabled(other.id, true)
	var before: Dictionary = model.statistics.snapshot()
	var power: Dictionary = model.power_state()
	expect(model.grid.membership[g.id] != model.grid.membership[other.id] and power.spill_kw == 240.0 and power.request_kw == 0.0, "independent networks do not share their supply")
	expect(model.statistics.snapshot() == before and g.fuel.industrial_cell == 5, "power queries never activate fuel")
	model.advance(Step)
	expect(g.burn_remaining_ticks == 1199 and other.burn_remaining_ticks == 1199 and model.statistics.totals.spill_kj == 12.0, "two isolated sources burn one fixed tick at zero load")
	expect(not model.salvage(other.id, true).ok, "generator must stop before recovery")
	model.set_device_enabled(other.id, false)
	model.advance(Step)
	expect(other.burn_remaining_ticks == 1199 and g.burn_remaining_ticks == 1198, "manual stop preserves only its own remaining ticks")
	expect(model.salvage(other.id).get("needs_confirmation", false), "recovery warns before discarding activated fuel")
	expect(model.salvage(other.id, true).ok and is_equal_approx(model.statistics.totals.discarded_kj, 7194.0), "recovery accounts for unspent fuel separately from spill")
	model.actor.x = -30
	model.actor.z = -22
	model.set_device_enabled(g.id, false)
	model.bag = {"crystal": 199}
	expect(not model.salvage(g.id, true).ok and model.by_id(g.id).fuel.industrial_cell == 4, "full bag rejects whole salvage")
	model.bag.clear()
	expect(model.salvage(g.id, true).ok and model.bag.industrial_cell == 4, "unused full cells returned on salvage")
	var ledger := model.energy_balance()
	expect(is_equal_approx(ledger.activated * 7200.0, ledger.released_kj + ledger.remaining_kj + ledger.discarded_kj), "burn ledger conserved across recovery")


func _save() -> void:
	var root_dir := evidence.path_join("factory")
	var store := Store.new(root_dir)
	var created := store.create(NAME, Model.Integrated.SUPPLY_ID, true)
	if not expect(created.ok, "create schema 9: " + created.get("reason", "")):
		return
	var journey := Journey.new()
	journey.model = created.model
	journey.prepare_generator()
	var model := journey.model
	var g := journey.generator
	expect(g.fuel.industrial_cell == 2 and not g.enabled, "natural core output and belts feed a stopped generator")
	journey.prepare_tail()
	expect(g.burn_remaining_ticks == 1 and g.fuel.industrial_cell == 1 and journey.assembler.processing and journey.assembler.recipe_id == "cell_assembly", "tail tick, full fuel and half R12 coexist")
	expect(model.core.outputs.OUT_E0.cooldown_ticks == 16 and model.core.outputs.OUT_S0.cooldown_ticks == 20, "different output cooldowns at checkpoint")
	expect(model.material_balance().balanced, "natural fuel and processing material ledger")
	var id := store.world_id
	var snapshot := Codec.snapshot(model, id, NAME, store.sequence + 1)
	_mutations(snapshot, id)
	var main := store.path("autosave.json")
	var original := FileAccess.get_sha256(main)
	for fault in ["validation", "temporary_write", "readback", "backup", "publish"]:
		store.fault = func(stage): return stage == fault
		expect(not store.save(model).ok and FileAccess.get_sha256(main) == original and g.burn_remaining_ticks == 1, "fault preserves original and in-memory state " + fault)
	store.fault = Callable()
	var saved := store.save(model)
	if not expect(saved.ok, "publish checkpoint: " + saved.get("reason", "")):
		store.release()
		return
	var other := Store.new(root_dir)
	expect(other.find_candidate(id).ok and not other.prepare(id).ok, "schema 9 is listed but an active writer still blocks continue")
	var sequence := store.sequence
	expect(store.release().ok, "writer releases lock")
	model.advance(2 * Step)
	expect(g.burn_remaining_ticks == 1199 and g.fuel.is_empty() and model.statistics.totals.cells_activated == 2, "tail does not debit next cell until the following step")
	_write(evidence.path_join("expected.json"), {"id": id, "sequence": sequence, "generator": g.id, "next": Codec.snapshot(model, id, NAME, sequence)})


func _mutations(snapshot: Dictionary, id: String) -> void:
	for variant in ["definitions", "future", "core", "research", "cooldown", "fuel", "spill", "topology", "stock"]:
		var d := snapshot.duplicate(true)
		match variant:
			"definitions": d.definitions_sha256 = "wrong"
			"future": d.save_schema_version = Codec.V12.VERSION + 1
			"core": d.state.entities[0].x += 1
			"research": d.state.research.completed.erase(Model.Progression.SAMPLE)
			"cooldown": d.state.core.outputs.OUT_S0.cooldown_ticks = 21
			"fuel":
				for e in d.state.entities:
					if e.type == "cell_generator": e.burn_remaining_ticks = 0.5
			"spill": d.state.statistics.totals.spill_kj += 1
			"topology": d.state.power_links.pop_back()
			"stock": d.state.core.items.metal_plate = 99999
		var result := Codec.decode(d, id)
		expect(not result.ok and (result.get("unsupported", false) if variant in ["definitions", "future"] else true), "reject " + variant)


func _restore() -> void:
	var expected: Variant = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("expected.json")))
	if not expect(expected is Dictionary, "read writer manifest"):
		return
	var store := Store.new(evidence.path_join("factory"))
	var found := store.prepare(expected.id)
	if not expect(found.ok, "read checkpoint in a new process: " + found.get("reason", "")):
		return
	var model: RefCounted = found.model
	var g: Dictionary = model.by_id(int(expected.generator))
	expect(g.burn_remaining_ticks == 1 and g.fuel.industrial_cell == 1 and found.document.sequence == expected.sequence, "restored tail and complete fuel")
	expect(store.accept(found).ok, "accept reconstructed session")
	model.advance(2 * Step)
	var actual := Codec.snapshot(model, expected.id, NAME, int(expected.sequence))
	if not expect(_same_snapshot(actual, expected.next), "same two steps produce the same full snapshot"):
		_write(evidence.path_join("actual.json"), actual)
	expect(model.material_balance().balanced and store.release().ok, "restored model conserves stock and releases lock")
	_backups(found.document)
	_recover_and_expand(model, g, expected.id)


func _recover_and_expand(model: RefCounted, g: Dictionary, id: String) -> void:
	var journey := Journey.new()
	journey.model = model
	journey.iron = model.entity_at(Vector2i(-28, -12))
	journey.crystal = model.entity_at(Vector2i(-20, 11))
	journey.refinery = model.entity_at(Vector2i(-16, 24))
	journey.assembler = model.entity_at(Vector2i(-5, 26))
	journey.reactor = model.entity_at(Vector2i(-5, 21))
	journey.crusher = model.entity_at(Vector2i(-10, 28))
	model.advance(60.0)
	expect(g.burn_remaining_ticks == 0 and g.fuel.is_empty() and model.power_state().available_kw == 360.0, "exhaustion leaves the core active")
	journey.carry(journey.assembler, model.core, "industrial_cell", 1)
	model.advance(8.0)
	expect(g.burn_remaining_ticks > 0 and model.statistics.totals.cells_activated == 3 and model.power_state().available_kw == 480.0, "core output automatically restarts the fuel-starved generator")
	journey.near(g)
	Journey.must(model.set_device_enabled(g.id, false))
	journey.make(journey.refinery, "direct_refining", 24)
	journey.make(journey.refinery, "direct_sintering", 12)
	journey.make(journey.assembler, "construction_assembly", 12)
	journey.near(model.core)
	for i in 6:
		Journey.must(model.assemble("refinery"))
	journey.place("power_junction", Vector2i(-13, 20))
	var furnaces := [journey.refinery]
	journey.recipe(journey.refinery, "direct_refining")
	for cell in [Vector2i(-18, 19), Vector2i(-20, 21), Vector2i(-13, 16), Vector2i(-16, 16), Vector2i(-10, 18), Vector2i(-3, 17)]:
		var placed: Dictionary = model.place("refinery", cell)
		if not expect(placed.ok, "expansion refinery at %s: %s" % [cell, placed.get("reason", "")]):
			return
		furnaces.append(placed.entity)
	for furnace in furnaces:
		journey.carry(journey.iron, furnace, "iron_ore", 2)
	journey.near(g)
	var before := Codec.snapshot(model, id, NAME, 1)
	var copy := Codec.decode(before, id)
	if not expect(copy.ok, "same-source expansion checkpoint is save-valid: " + copy.get("reason", "")):
		return
	var baseline: RefCounted = copy.model
	var already: int = model.completed_by_recipe.direct_refining
	var demand: float = model.power_state().request_kw
	expect(demand > 360.0 and demand <= 480.0 and baseline.power_state().deficit_kw > 0.0, "seven naturally fed furnaces exceed core capacity")
	Journey.must(model.set_device_enabled(g.id, true))
	expect(model.power_state().deficit_kw == 0.0, "generator covers the measured deficit")
	baseline.advance(8.0)
	model.advance(8.0)
	expect(model.completed_by_recipe.direct_refining - already == 7 and baseline.completed_by_recipe.direct_refining == already,
		"same raw inputs over eight seconds produce seven plates with G and zero without")
	expect(model.material_balance().balanced and baseline.material_balance().balanced, "both comparison branches conserve actual materials")
	print("Factory integrated expansion: %.1f kW demand; 8 s output %d vs %d plates" % [demand,
		baseline.completed_by_recipe.direct_refining - already, model.completed_by_recipe.direct_refining - already])


# JSON readers can round fractional values by one ULP. Integers remain exact.
func _same_snapshot(actual: Variant, expected: Variant) -> bool:
	if actual is Dictionary:
		if not expected is Dictionary or actual.size() != expected.size():
			return false
		for key in actual:
			if not expected.has(key) or not _same_snapshot(actual[key], expected[key]):
				return false
		return true
	if actual is Array:
		if not expected is Array or actual.size() != expected.size():
			return false
		for i in actual.size():
			if not _same_snapshot(actual[i], expected[i]):
				return false
		return true
	if actual is float and (expected is float or expected is int):
		return absf(actual - expected) <= 1e-10 + 1e-12 * maxf(absf(actual), absf(expected))
	return actual == expected


func _backups(doc: Dictionary) -> void:
	var id: String = doc.world_id
	var store := Store.new(evidence.path_join("recovery"))
	var folder: String = store.root.path_join(id)
	DirAccess.make_dir_recursive_absolute(folder.path_join("backups"))
	var main := folder.path_join("autosave.json")
	var backup := folder.path_join("backups/autosave.bak.1.json")
	_write(backup, doc)
	var wrong := doc.duplicate(true)
	wrong.definitions_sha256 = "wrong"
	_write(main, wrong)
	expect(store.find_candidate(id).get("unsupported", false), "wrong identity never falls back to valid backup")
	var file := FileAccess.open(main, FileAccess.WRITE)
	file.store_string("{")
	file.close()
	var candidate := store.prepare(id)
	if expect(candidate.ok and candidate.source == backup, "malformed main offers the same-identity backup"):
		var accepted := store.accept(candidate)
		expect(accepted.ok and accepted.get("recovered_from") == backup and store.sequence == int(doc.sequence) + 1, "backup recovery publishes next sequence")
	store.release()


func _write(path: String, value: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(value, "", true, true))
	file.close()
