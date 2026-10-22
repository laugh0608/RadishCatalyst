extends SceneTree

const Model := preload("res://scripts/factory/expansion_model.gd")
const Legacy := preload("res://scripts/factory/admission_model.gd")
const Codec := preload("res://scripts/factory/save/codec.gd")
const Store := preload("res://scripts/factory/save/store.gd")
const Layout := preload("res://scripts/checks/factory_expansion_layout.gd")
const Compare := preload("res://scripts/checks/factory_expansion_compare.gd")
const ID := "eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee"
var checks := 0
var failures: Array[String] = []
var evidence := ""
var milestones := {}
var ids := {}
var model: RefCounted


func _init() -> void:
	call_deferred("run")


func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error(label)


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	if evidence.is_empty(): evidence = SliceCheckPaths.check_run("factory-production-expansion-e1", false).path_join("state-%d-%d" % [Time.get_unix_time_from_system(), OS.get_process_id()])
	DirAccess.make_dir_recursive_absolute(evidence)
	if "--read" in OS.get_cmdline_user_args():
		_restore()
	else:
		_rules_and_recipes()
		_commands()
		_transport()
		_bootstrap()
		_bad_saves()
		_store()
	_write("read-result.json" if "--read" in OS.get_cmdline_user_args() else "state-result.json", {"assertions": checks, "failures": failures, "milestones": milestones, "scope": "explicit fixed steps and command fixtures; synthetic inputs only in isolated recipe/atomicity/transport tests; A/B production starts empty using actual mining; actor repositioning here is state-only, not formal Boot evidence"})
	print("E1 state: %d assertions, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


static func snapshot(m: RefCounted) -> Dictionary:
	return Codec.snapshot(m, ID, "E1 状态验证", 1)


static func near(m: RefCounted, e: Dictionary) -> void:
	m.actor.x = e.x - 0.6
	m.actor.z = e.z + 0.5


func _write(name: String, value: Variant) -> void:
	var file := FileAccess.open(evidence.path_join(name), FileAccess.WRITE)
	expect(file != null, "write " + name)
	if file != null: file.store_string(JSON.stringify(value, "\t", false, true))


func _roundtrip(m: RefCounted, label: String) -> Dictionary:
	var doc := snapshot(m)
	var result := Codec.decode(JSON.parse_string(JSON.stringify(doc, "", true, true)), ID)
	expect(result.ok, label + " roundtrip: " + result.get("reason", ""))
	if result.ok: expect(Compare.equivalent(snapshot(result.model), doc), label + " complete snapshot")
	return result


func _rules_and_recipes() -> void:
	var fresh := Model.new()
	expect(fresh.owned_count() == 165 and fresh.bag.is_empty() and fresh.entities.is_empty(), "ordinary empty E1 starts with 165 kits")
	expect(fresh.recipes.size() == 11 and fresh.item_ids.size() == 13 and fresh.admission_items.size() == 12, "E1 content counts")
	expect(fresh.ore_sites().size() == 8 and fresh.mineral_at(Vector2i(-28, 10)) == "carbon_ore", "eight map deposits")
	_roundtrip(fresh, "fresh")
	var old := Legacy.new()
	expect(old.admission_items.size() == 4 and old.recipes.size() == 4 and not old.place("refinery", Vector2i(-10, -10)).ok, "V5 remains original whitelist and supply")
	for recipe_id in fresh.recipes:
		var m := Model.new()
		m.discovery.surveyed = true
		m.discovery.sample_taken = true
		m.discovery.trial_completed = recipe_id != "solvent_trial"
		var recipe: Dictionary = m.recipes[recipe_id]
		var type: String = recipe.get("machine", "reactor")
		var e: Dictionary = m.place(type, Vector2i(-10, -10)).entity
		m.place("power_source", Vector2i(-14, -10))
		near(m, e)
		if e.recipe_id != recipe_id: expect(m.change_recipe(e.id, recipe_id).ok, "select " + recipe_id)
		for item in m.item_ids:
			expect(m.input_room(e, item, true) == recipe.input.get(item, 0) * (1 if type == "reactor" else 2), recipe_id + " capacity " + item)
		m.bag = recipe.input.duplicate()
		for item in recipe.input: expect(m.transfer(e.id, item, true, true).ok, "feed " + recipe_id + " " + item)
		m._step(0.05)
		expect(e.processing and e.invested == recipe.input and e.input.is_empty(), recipe_id + " atomic investment")
		expect(m.statistics.totals.consumed.is_empty(), recipe_id + " no premature consumption")
		var active := snapshot(m)
		m.set_source_enabled(m.entities[1].id, false)
		for tick in 10: m._step(0.05)
		expect(e.progress == active.state.entities[0].progress and e.invested == recipe.input, recipe_id + " power loss retains progress")
		m.set_source_enabled(m.entities[1].id, true)
		for tick in int(round(recipe.seconds / 0.05)) - 1: m._step(0.05)
		expect(not e.processing and e.output == recipe.output and e.invested.is_empty(), recipe_id + " complete vector")
		expect(m.completed_by_recipe[recipe_id] == 1 and m.statistics.totals.consumed == recipe.input and m.statistics.totals.produced == recipe.output, recipe_id + " completion accounting")
		for tick in 20: m._step(0.05)
		expect(m.completed_by_recipe[recipe_id] == 1, recipe_id + " output blocks next batch")


func _commands() -> void:
	var m := Model.new()
	var e: Dictionary = m.place("refinery", Vector2i(-10, -10)).entity
	near(m, e)
	for recipe in ["unknown", "iron_crushing", "construction_assembly"]:
		var before := snapshot(m)
		expect(not m.change_recipe(e.id, recipe).ok and snapshot(m) == before, "invalid recipe zero mutation " + recipe)
	m.bag = {"iron_ore": 5}
	expect(m.transfer(e.id, "iron_ore", true, true).ok and e.input.iron_ore == 4 and m.bag.iron_ore == 1, "input capped to two batches")
	var before := snapshot(m)
	expect(not m.change_recipe(e.id, "direct_sintering").ok and snapshot(m) == before, "nonempty recipe switch refused")
	m.place("power_source", Vector2i(-14, -10))
	m._step(0.05)
	m.bag = {"crystal": 200}
	before = snapshot(m)
	expect(not m.cancel_batch(e.id).ok and snapshot(m) == before, "full bag cancel atomic")
	expect(not m.salvage(e.id).ok and snapshot(m) == before, "full bag recovery atomic")
	m.bag = {}
	var energy: float = m.statistics.totals.used_kj
	expect(m.cancel_batch(e.id).ok and m.bag.iron_ore == 2 and not e.processing and m.statistics.totals.used_kj == energy, "cancel original investment without energy refund")
	m.actor.x = 0
	m.actor.z = 0
	before = snapshot(m)
	expect(not m.salvage(e.id).ok and not m.transfer(e.id, "iron_ore", false, true).ok and snapshot(m) == before, "remote operations rejected")
	near(m, e)
	expect(m.salvage(e.id).ok and m.bag.iron_ore == 4 and m.kits.refinery == 1, "recovery returns all inputs and same kit")
	for type in m.Expansion.ASSEMBLY_COST:
		var test := Model.new()
		var cost: int = test.Expansion.ASSEMBLY_COST[type]
		before = snapshot(test)
		expect(not test.assemble(type).ok and snapshot(test) == before, "missing pack atomic " + type)
		test.bag = {"construction_pack": cost}
		expect(test.assemble(type).ok and test.bag.is_empty() and test.kits[type] == test.Expansion.SUPPLY[type] + test.Expansion.yield_for(type), "assembly exact batch " + type)
		expect(test.assembly_counts[type] == 1 and test.statistics.totals.consumed.construction_pack == cost, "assembly ledger " + type)
	m = Model.new()
	m.bag = {"construction_pack": 200}
	for i in 20: expect(m.assemble("belt").ok, "whole belt batch " + str(i))
	expect(m.owned_count() == 325, "20 belt batches yield 160 kits")
	before = snapshot(m)
	expect(not m.assemble("belt").ok and snapshot(m) == before, "one spare slot rejects full eight belt batch")
	expect(m.assemble("power_junction").ok and m.owned_count() == 326, "one kit reaches exact budget")
	before = snapshot(m)
	expect(not m.assemble("refinery").ok and not m.assemble("power_source").ok and snapshot(m) == before, "full budget and unmanufacturable source zero mutation")


func _transport() -> void:
	var m := Model.new()
	var f: Dictionary = m.place("refinery", Vector2i(-12, -10)).entity
	f.recipe_id = "mixed_refining"
	f.output = {"metal_plate": 2, "mineral_slag": 1}
	f.output_batch = 1
	m.next_batch = 2
	m.batch_recipes = {"1": "mixed_refining"}
	var main: Dictionary = m.place("belt", Vector2i(-10, -10)).entity
	var side: Dictionary = m.place("belt", Vector2i(-10, -8)).entity
	m.Logistics.step(m, 0.05)
	expect(main.cargo == "metal_plate" and side.cargo.is_empty() and f.output_cursor == 1, "one source sends one main item in first step")
	m.Logistics.step(m, 0.05)
	expect(side.cargo == "mineral_slag" and main.batch == side.batch and f.output == {"metal_plate": 1}, "shared vector batch through distinct ports")
	var source: Dictionary = m.place("belt", Vector2i(-7, -9)).entity
	var other: Dictionary = m.place("belt", Vector2i(-7, -8)).entity
	var a: Dictionary = m.place("assembler", Vector2i(-6, -9)).entity
	source.cargo = "metal_plate"; source.progress = 1; source.batch = 2
	other.cargo = "porous_carrier"; other.progress = 1; other.batch = 3
	m.Logistics.step(m, 0.05)
	expect(m.Items.count(a.input) == 1, "multiple input ports receive at most once per step")
	m.Logistics.step(m, 0.05)
	expect(a.input == {"metal_plate": 1, "porous_carrier": 1}, "both assembly materials accepted")
	main.cargo = ""; main.batch = 0; main.progress = 0
	m.Logistics.step(m, 0.05)
	expect(main.cargo == "metal_plate" and f.output.is_empty(), "occupied slag belt does not block remaining main item")
	f.output = {"mineral_slag": 1}; f.output_batch = 4; f.input = {"iron_powder": 3, "carbon_powder": 1}
	expect(not m.work_spec(f).ready, "retained slag blocks next batch even when main is empty")
	var gate: Dictionary = m.place("admission_gate", Vector2i(-20, -20)).entity
	near(m, gate)
	for item in m.admission_items: expect(m.configure_admission(gate.id, item, "quota", 1).ok, "E1 gate accepts " + item)
	var old := Legacy.new()
	gate = old.place("admission_gate", Vector2i(-20, -20)).entity
	near(old, gate)
	expect(not old.configure_admission(gate.id, "iron_ore", "quota", 1).ok, "legacy gate rejects E1 mineral")
	var port_model := Model.new()
	var port_source: Dictionary = port_model.place("refinery", Vector2i(-12, -10)).entity
	port_source.recipe_id = "mixed_refining"
	port_source.output = {"metal_plate": 2, "mineral_slag": 1}
	var side_gate: Dictionary = port_model.place("admission_gate", Vector2i(-10, -8)).entity
	near(port_model, side_gate)
	port_model.configure_admission(side_gate.id, "mineral_slag", "unlimited", 0)
	port_model.set_admission_accepting(side_gate.id, true)
	expect(port_model.feedback(side_gate).label == "等待来料", "slag gate diagnosis reads its connected output, not the main product")


func _build(stage: String) -> void:
	var rows := Layout.rows(stage)
	if stage == "B":
		for e in model.entities.duplicate():
			var keep: bool = rows.any(func(row): return row.type == e.type and row.x == e.x and row.z == e.z)
			if not keep:
				near(model, e)
				expect(model.salvage(e.id).ok, "A to B salvage %d" % e.id)
	ids.clear()
	for row in rows:
		var e: Dictionary = model.entity_at(Vector2i(row.x, row.z))
		if e.is_empty():
			var result: Dictionary = model.place(row.type, Vector2i(row.x, row.z), row.dir)
			expect(result.ok, "layout %s place %s" % [stage, row.name])
			if not result.ok: return
			e = result.entity
		ids[row.name] = e.id
	model.actor.x = -3.5; model.actor.z = 5.7
	expect(model.entities.size() == (34 if stage == "A" else 62), stage + " entity count")
	expect(model.power_state().installed_kw == 240, stage + " 240 kW installed")


func _configure(name: String, item: String, quota: int) -> void:
	var gate: Dictionary = model.by_id(ids[name])
	near(model, gate)
	model.set_admission_accepting(gate.id, false)
	expect(model.configure_admission(gate.id, item, "quota", quota).ok, "configure " + name)
	expect(model.set_admission_accepting(gate.id, true).ok, "enable " + name)


func _recipe(name: String, recipe: String) -> void:
	var e: Dictionary = model.by_id(ids[name])
	near(model, e)
	if e.recipe_id != recipe: expect(model.change_recipe(e.id, recipe).ok, "switch " + name + " " + recipe)


func _transfer(name: String, item: String, putting: bool) -> void:
	var e: Dictionary = model.by_id(ids[name])
	near(model, e)
	expect(model.transfer(e.id, item, putting, true).ok, "transfer " + name + " " + item)


func _until(condition: Callable, seconds: float, label: String) -> void:
	for i in int(seconds / 0.05):
		if condition.call(): break
		model._step(0.05)
		if not model.material_balance().balanced:
			expect(false, label + " per-step item balance"); return
	expect(condition.call(), label)
	model.actor.x = -3.5; model.actor.z = 5.7
	_roundtrip(model, label)


func _bootstrap() -> void:
	model = Model.new()
	_build("A")
	_configure("GI", "iron_ore", 8)
	_configure("GQ", "crystal", 6)
	_until(func(): return model.completed_by_recipe.direct_refining == 4 and model.by_id(ids.F).output.is_empty() and model.by_id(ids.U).items.get("crystal", 0) == 6, 100, "A four plates and six crystals")
	_recipe("F", "direct_sintering")
	_transfer("U", "crystal", false)
	_transfer("F", "crystal", true)
	_until(func(): return model.by_id(ids.T).items.get("construction_pack", 0) == 2, 100, "A two construction packs")
	expect(model.completed_by_recipe.direct_refining == 4 and model.completed_by_recipe.direct_sintering == 2 and model.completed_by_recipe.construction_assembly == 2, "A exact 8 iron and 6 crystal recipe consumption")
	milestones.A = {"time": model.time, "recipes": model.completed_by_recipe.duplicate(), "power": model.power_state().duplicate(true)}
	_transfer("T", "construction_pack", false)
	expect(model.assemble("refinery").ok and model.owned_count() == 166 and not model.first_expansion_placed, "manufacture before placement")
	model.actor.x = -3.5; model.actor.z = 5.7
	_roundtrip(model, "manufactured unplaced")
	_write("manufactured.json", snapshot(model))
	expect(model.place("refinery", Vector2i(-12, -5)).ok and model.first_expansion_placed, "place actual second furnace")
	_roundtrip(model, "first expansion placed")
	_write("second-furnace.json", snapshot(model))
	_build("B")
	_recipe("C", "carbon_crushing")
	_recipe("F", "mixed_refining")
	_recipe("R", "slag_sintering")
	_configure("GK", "carbon_ore", 1)
	_until(func(): return model.by_id(ids.K).progress > 5 and model.by_id(ids.K).progress < 10, 10, "carbon partial cycle")
	_write("carbon-partial.json", snapshot(model))
	_until(func(): return model.by_id(ids.U).items.get("carbon_ore", 0) == 1, 30, "B carbon input ready")
	_transfer("U", "carbon_ore", false)
	_transfer("C", "carbon_ore", true)
	_until(func(): return model.by_id(ids.F).input.get("carbon_powder", 0) == 2, 20, "B two carbon powder delivered")
	_recipe("C", "iron_crushing")
	_configure("GI", "iron_ore", 4)
	_configure("GQ", "crystal", 1)
	_until(func(): return model.by_id(ids.F).processing and model.by_id(ids.F).progress > 4, 30, "R08 partial batch")
	_write("state-partial.json", snapshot(model))
	_write("state-context.json", {"ids": ids, "steps": 1600})
	_slag_checkpoint()
	var replay := Codec.decode(JSON.parse_string(JSON.stringify(snapshot(model))), ID)
	if replay.ok:
		for tick in 1600: replay.model._step(0.05)
		_write("state-expected.json", snapshot(replay.model))
	_until(func(): return model.by_id(ids.T).items.get("construction_pack", 0) == 2, 100, "B two recycled construction packs")
	expect(model.completed_by_recipe.mixed_refining == 2 and model.completed_by_recipe.slag_sintering == 1 and model.completed_by_recipe.construction_assembly == 4, "B exact 4 iron 1 carbon 1 crystal route")
	milestones.B = {"time": model.time, "recipes": model.completed_by_recipe.duplicate(), "owned": model.owned_count()}
	_write("state-complete.json", snapshot(model))


func _bad_saves() -> void:
	var doc := snapshot(model)
	var baseline := Codec.decode(doc, ID)
	expect(baseline.ok, "bad-save tests begin from valid state")
	if not baseline.ok: return
	for field in ["ruleset_id", "map_id", "supply_id"]:
		var bad := doc.duplicate(true); bad[field] = "wrong"
		var result := Codec.decode(bad, ID)
		expect(not result.ok and result.unsupported, "fatal mixed identity " + field)
	for field in ["extracted_by_item", "completed_by_recipe", "assembly_counts", "batch_recipes"]:
		var bad := doc.duplicate(true); bad.state[field].unknown = 1
		expect(not Codec.decode(bad, ID).ok, "unknown ledger key " + field)
	var bad := doc.duplicate(true); bad.state.kits.belt += 1
	expect(not Codec.decode(bad, ID).ok, "manufacturing conservation")
	bad = doc.duplicate(true); bad.state.assembly_counts.refinery += 1
	expect(not Codec.decode(bad, ID).ok, "manufacturing counts conservation")
	bad = doc.duplicate(true); bad.state.bag.iron_ore = 1
	expect(not Codec.decode(bad, ID).ok, "unaccounted material rejected")
	bad = doc.duplicate(true); bad.state.first_expansion_placed = false
	expect(not Codec.decode(bad, ID).ok, "second furnace fact required")
	bad = doc.duplicate(true); bad.state.batch_recipes[str(model.next_batch)] = "mixed_refining"
	expect(not Codec.decode(bad, ID).ok, "unreferenced future batch rejected")
	var partial: Variant = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("state-partial.json")))
	for key in ["invested", "output", "progress", "recipe_id", "active_batch", "output_cursor"]:
		bad = partial.duplicate(true)
		var furnace: Dictionary = bad.state.entities.filter(func(e): return e.id == ids.F)[0]
		match key:
			"invested": furnace.invested = {"iron_powder": 2, "carbon_powder": 1}
			"output": furnace.output = {"metal_plate": 1}
			"progress": furnace.progress = 10
			"recipe_id": furnace.recipe_id = "iron_crushing"
			"active_batch": furnace.active_batch = 0
			"output_cursor": furnace.output_cursor = 2
		expect(not Codec.decode(bad, ID).ok, "partial batch rejects bad " + key)
	bad = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("carbon-partial.json")))
	bad.state.entities.filter(func(e): return e.id == ids.K)[0].progress = 20
	expect(not Codec.decode(bad, ID).ok, "carbon full cycle rejected")


func _store() -> void:
	var store := Store.new(evidence.path_join("factory"))
	var created := store.create("E1 文件验证", Model.Expansion.SUPPLY_ID, true)
	expect(created.ok, "create schema 6 store")
	if not created.ok: return
	var id: String = store.world_id
	expect(store.save(model).ok, "save completed natural-state model")
	var original := FileAccess.get_file_as_string(store.path("autosave.json"))
	for fault in ["validation", "temporary_write", "readback", "backup", "publish"]:
		store.fault = func(stage): return stage == fault
		var result := store.save(model)
		expect(not result.ok and FileAccess.get_file_as_string(store.path("autosave.json")) == original, "IO failure preserves main " + fault)
	store.fault = Callable()
	expect(not store.save(Legacy.new()).ok and FileAccess.get_file_as_string(store.path("autosave.json")) == original, "E1 session cannot write V5 identity")
	store.release()
	var fresh := Store.new(evidence.path_join("factory"))
	var candidate := fresh.prepare(id)
	expect(candidate.ok, "fresh session restores E1")
	if candidate.ok: expect(fresh.accept(candidate).ok, "restored E1 session accepted")
	fresh.release()
	# Independent disk mutations exercise recovery identity boundaries; never touch the source model.
	var main_path: String = store.path("autosave.json")
	var backup_path: String = store.path("backups/autosave.bak.1.json")
	var original_doc: Dictionary = JSON.parse_string(original)
	var damaged: Dictionary = original_doc.duplicate(true)
	damaged.state.kits.belt += 1
	expect(store._write(main_path, JSON.stringify(damaged, "", true, true)).ok, "write bad-count fixture")
	expect(store._write(backup_path, original).ok, "retain same-identity recovery fixture")
	var recovered: Dictionary = fresh.find_candidate(id)
	expect(recovered.ok and recovered.source == backup_path, "same-identity backup can recover invalid counts")
	var foreign: Dictionary = Codec.snapshot(Legacy.new(), id, "V5 foreign backup", 1)
	expect(store._write(backup_path, JSON.stringify(foreign, "", true, true)).ok, "write foreign backup fixture")
	var rejected: Dictionary = fresh.find_candidate(id)
	expect(not rejected.ok and rejected.get("unsupported", false), "backup cannot cross E1 and V5 identity")
	expect(store._write(backup_path, original).ok, "restore E1 backup fixture")
	for pair in [["save_schema_version", 7], ["ruleset_id", "future_expansion"], ["map_id", Codec.V2.Config.MAP_ID], ["supply_id", Codec.V2.Config.ADMISSION_SUPPLY_ID]]:
		damaged = original_doc.duplicate(true)
		damaged[pair[0]] = pair[1]
		var text := JSON.stringify(damaged, "", true, true)
		expect(store._write(main_path, text).ok, "write unsupported identity fixture")
		rejected = fresh.find_candidate(id)
		expect(not rejected.ok and rejected.get("unsupported", false) and FileAccess.get_file_as_string(main_path) == text, "unsupported identity blocks fallback without rewriting " + pair[0])
	expect(store._write(main_path, original).ok, "restore isolated valid main after fault checks")


func _restore() -> void:
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("state-partial.json")))
	var result := Codec.decode(doc, ID)
	expect(result.ok, "independent R08 checkpoint decode")
	if not result.ok: return
	model = result.model
	for tick in 1600:
		model._step(0.05)
		if not model.material_balance().balanced: expect(false, "independent replay conservation"); return
	var expected: Variant = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("state-expected.json")))
	expect(Compare.equivalent(snapshot(model), expected), "independent 80 second complete continuation")
	for name in ["carbon-partial.json", "manufactured.json", "second-furnace.json", "slag-held.json", "state-complete.json"]:
		doc = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join(name)))
		result = Codec.decode(doc, ID)
		expect(result.ok, "independent checkpoint " + name)


func _slag_checkpoint() -> void:
	var clone := Codec.decode(snapshot(model), ID)
	expect(clone.ok, "slag scenario begins from valid production checkpoint")
	if not clone.ok: return
	var m: RefCounted = clone.model
	var belt: Dictionary = m.entity_at(Vector2i(-16, -9))
	near(m, belt)
	expect(m.salvage(belt.id).ok, "remove slag output connection with real recovery")
	var f: Dictionary = m.by_id(ids.F)
	for tick in 300:
		m._step(0.05)
		if f.output == {"mineral_slag": 1}: break
	expect(f.output == {"mineral_slag": 1} and not f.processing and not m.work_spec(f).ready, "main drains while slag retained, next batch blocked")
	m.actor.x = -3.5; m.actor.z = 5.7
	_roundtrip(m, "slag retained")
	_write("slag-held.json", snapshot(m))
	var invalid := snapshot(m)
	var source: Dictionary = invalid.state.entities.filter(func(e): return e.id == f.id)[0]
	source.output_batch = 0
	expect(not Codec.decode(invalid, ID).ok, "held slag requires valid batch")
	invalid = snapshot(m)
	invalid.state.batch_recipes[str(f.output_batch)] = "direct_refining"
	expect(not Codec.decode(invalid, ID).ok, "slag batch cannot claim single-output recipe")
	invalid = snapshot(m)
	invalid.state.batch_recipes.erase(str(f.output_batch))
	expect(not Codec.decode(invalid, ID).ok, "missing live source rejected")
