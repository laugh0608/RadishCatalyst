extends SceneTree

const Model := preload("res://scripts/factory/energy_model.gd")
const E1 := preload("res://scripts/factory/expansion_model.gd")
const Codec := preload("res://scripts/factory/save/codec.gd")
const Store := preload("res://scripts/factory/save/store.gd")
const Layout := preload("res://scripts/checks/factory_energy_layout.gd")
const FirstLayout := preload("res://scripts/checks/factory_expansion_layout.gd")
const Compare := preload("res://scripts/checks/factory_expansion_compare.gd")
const ID := "77777777777777777777777777777777"
var assertions := 0
var failures: Array[String] = []
var evidence := ""
var model: RefCounted
var ids := {}
var milestones := {}


func _init() -> void:
	call_deferred("run")


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	if evidence.is_empty(): evidence = SliceCheckPaths.check_run("factory-production-expansion-e2", false).path_join("state-%d-%d" % [Time.get_unix_time_from_system(), OS.get_process_id()])
	DirAccess.make_dir_recursive_absolute(evidence)
	if "--read" in OS.get_cmdline_user_args():
		_restore()
	else:
		_fuel_and_controls()
		_natural()
		_store()
	_write("read-result.json" if "--read" in OS.get_cmdline_user_args() else "state-result.json", {"assertions": assertions, "failures": failures, "milestones": milestones, "scope": "explicit fixed steps; synthetic recipe/fuel/command fixtures are separate from natural mined C/P/D; actor repositioning is state-only, not Boot evidence"})
	print("E2 state: %d assertions, %d failures" % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)


func expect(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures.append(label)
		push_error(label)


static func snapshot(m: RefCounted) -> Dictionary:
	return Codec.snapshot(m, ID, "E2 状态验证", 1)


static func near(m: RefCounted, e: Dictionary) -> void:
	m.actor.x = e.x - 0.6
	m.actor.z = e.z + 0.5


func _write(name: String, value: Variant) -> void:
	var file := FileAccess.open(evidence.path_join(name), FileAccess.WRITE)
	expect(file != null, "write " + name)
	if file != null: file.store_string(JSON.stringify(value, "\t", false, true))


func _roundtrip(m: RefCounted, label: String) -> Dictionary:
	m.actor.x = -3.5; m.actor.z = 5.7
	var doc := snapshot(m)
	var result := Codec.decode(JSON.parse_string(JSON.stringify(doc, "", true, true)), ID)
	expect(result.ok, label + " roundtrip: " + result.get("reason", ""))
	if result.ok: expect(Compare.equivalent(snapshot(result.model), doc), label + " complete snapshot")
	return result


func _fuel_and_controls() -> void:
	var fresh := Model.new()
	expect(fresh.owned_count() == 165 and fresh.recipes.size() == 12 and fresh.item_ids.size() == 14 and fresh.kits.cell_generator == 0, "E2 starts with original supply and no fuel")
	_roundtrip(fresh, "fresh")
	expect(not fresh.recipe_available("cell_assembly") and not fresh.assemble("cell_generator").ok, "energy unlock requires second furnace")
	# Deliberate isolated input/kit fixtures, never used for natural or persistence proof.
	var m := Model.new()
	m.first_expansion_placed = true
	m.kits.cell_generator = 2
	m.kits.refinery = 3
	var g: Dictionary = m.place("cell_generator", Vector2i(-10, -10)).entity
	var g2: Dictionary = m.place("cell_generator", Vector2i(-10, -6)).entity
	var f: Dictionary = m.place("refinery", Vector2i(-15, -10)).entity
	g.fuel = {"industrial_cell": 2}
	g2.fuel = {"industrial_cell": 1}
	f.input = {"iron_ore": 2}
	var source: Dictionary = m.place("power_source", Vector2i(-18, -15)).entity
	var before := snapshot(m)
	for i in 20:
		m.power_state(); m.grid.allocate(m, 0.05); m.feedback(g); m._refresh_automatic_power()
	expect(Compare.equivalent(snapshot(m), before), "queries and topology never burn fuel")
	m._step(0.05)
	expect(g.remaining_kj == 0 and g.fuel.industrial_cell == 2 and m.statistics.totals.cells_activated == 0, "base covers 60 kW with no fuel activation")
	m.set_source_enabled(source.id, false)
	m._step(0.05)
	expect(g.remaining_kj == 7198.5 and g2.remaining_kj == 7198.5 and m.statistics.totals.cells_activated == 2, "two generators share actual 60 kW and activate once each")
	g.remaining_kj = 0.5; g.fuel.clear(); g2.remaining_kj = 100
	var allocation := m.grid.allocate(m, 0.05)
	expect(allocation.sources[g.id] == 10 and allocation.sources[g2.id] == 50, "finite tail caps at 10 kW and redistributes to 50 kW")
	m._step(0.05)
	expect(g.remaining_kj == 0 and g2.remaining_kj == 97.5, "tail step consumes exact available energy")
	near(m, g2); m.set_device_enabled(g2.id, false)
	g.remaining_kj = 1; g.fuel = {"industrial_cell": 1}
	m._step(0.05)
	expect(g.remaining_kj == 7198 and g.fuel.is_empty(), "cross-cell step activates only needed next cell")
	g.remaining_kj = 3; g.fuel = {"industrial_cell": 1}
	var activated: int = m.statistics.totals.cells_activated
	m._step(0.05)
	expect(g.remaining_kj == 0 and g.fuel.industrial_cell == 1 and m.statistics.totals.cells_activated == activated, "exact exhaustion does not preactivate next cell")
	near(m, f); m.set_device_enabled(f.id, false)
	var progress: float = f.progress
	before = snapshot(m)
	for i in 10: m._step(0.05)
	expect(f.progress == progress and g.remaining_kj == 0 and g.fuel.industrial_cell == 1, "consumer stop preserves partial and burns no fuel")
	var belt: Dictionary = m.place("belt", Vector2i(-16, -10)).entity
	belt.cargo = "iron_ore"; belt.progress = 1
	m._step(0.05)
	expect(f.input.get("iron_ore", 0) == 1 and belt.cargo.is_empty(), "stopped consumer still accepts passive logistics")
	near(m, f); expect(m.set_device_enabled(f.id, true).ok, "resume consumer")
	m._step(0.05)
	expect(f.progress > progress, "resume advances same batch")
	near(m, g); m.set_device_enabled(g.id, false)
	g.remaining_kj = 1234; g.fuel = {"industrial_cell": 4}; m.bag = {"industrial_cell": 3}
	expect(m.transfer(g.id, "industrial_cell", true, true).ok and g.fuel.industrial_cell == 5 and m.bag.industrial_cell == 2, "manual fuel capped at five")
	expect(not m.transfer(g.id, "industrial_cell", true, true).ok and not m.transfer(g.id, "crystal", true, true).ok, "full and wrong fuel rejected")
	expect(m.transfer(g.id, "industrial_cell", false, true).ok and g.remaining_kj == 1234 and g.fuel.is_empty(), "only intact fuel can be withdrawn")
	m.bag = {"crystal": 200}; g.fuel = {"industrial_cell": 1}
	before = snapshot(m)
	expect(not m.salvage(g.id, true).ok and Compare.equivalent(before, snapshot(m)), "full bag recovery rejects atomically")
	m.bag.clear()
	expect(m.salvage(g.id).get("needs_confirmation", false), "remaining energy requires explicit recovery confirmation")
	var lost: float = m.statistics.totals.discarded_kj
	expect(m.salvage(g.id, true).ok and m.bag.industrial_cell == 1 and m.statistics.totals.discarded_kj == lost + 1234, "confirmed recovery returns intact fuel and records loss")
	m = Model.new(); m.first_expansion_placed = true
	var e: Dictionary = m.place("assembler", Vector2i(-10, -10)).entity
	m.place("power_source", Vector2i(-15, -10))
	near(m, e); m.change_recipe(e.id, "cell_assembly")
	e.input = {"metal_plate": 1, "carbon_powder": 2, "catalyst": 1}
	for i in 240: m._step(0.05)
	expect(e.output == {"industrial_cell": 1} and m.completed_by_recipe.cell_assembly == 1 and is_equal_approx(m.statistics.totals.used_kj, 480), "three-input R12 produces one cell at 480 kJ")
	var shares := m.Grid.capped_equal_share([1, 2], {1: 120.0, 2: 120.0}, 260)
	expect(shares == {1: 120.0, 2: 120.0}, "two generators cannot satisfy a 260 kW gap")


func _rows(rows: Array) -> void:
	for e in model.entities.duplicate():
		if rows.any(func(row): return row.type == e.type and row.x == e.x and row.z == e.z and row.dir == e.dir): continue
		near(model, e)
		var result: Dictionary = model.salvage(e.id, true)
		expect(result.ok, "rebuild salvage " + str(e.id) + ": " + result.get("reason", ""))
		if not result.ok: return
	ids.clear()
	for row in rows:
		var e: Dictionary = model.entity_at(Vector2i(row.x, row.z))
		if e.is_empty():
			var result: Dictionary = model.place(row.type, Vector2i(row.x, row.z), row.dir)
			expect(result.ok, "place " + row.name + ": " + result.get("reason", ""))
			if not result.ok: return
			e = result.entity
		ids[row.name] = e.id
	model.actor.x = -3.5; model.actor.z = 5.7


func _profile(stage: String) -> void:
	_rows(Layout.rows(stage))
	for name in Layout.recipes(stage): _recipe(name, Layout.recipes(stage)[name])
	_roundtrip(model, "layout " + stage)


func _recipe(name: String, recipe: String) -> void:
	var e: Dictionary = model.by_id(ids[name])
	near(model, e)
	if e.recipe_id != recipe: expect(model.change_recipe(e.id, recipe).ok, "recipe " + name)


func _gate(name: String, item: String, amount: int) -> void:
	var e: Dictionary = model.by_id(ids[name])
	near(model, e)
	model.set_admission_accepting(e.id, false)
	for i in 2400:
		if e.cargo.is_empty(): break
		model._step(0.05)
	expect(e.cargo.is_empty(), "drained gate " + name)
	expect(model.configure_admission(e.id, item, "quota", amount).ok, "quota " + name)
	if e.quota_used > 0: expect(model.reset_admission(e.id).ok, "reset " + name)
	expect(model.set_admission_accepting(e.id, true).ok, "start " + name)


func _take(name: String, item: String, putting := false) -> void:
	var e: Dictionary = model.by_id(ids[name])
	near(model, e)
	expect(model.transfer(e.id, item, putting, true).ok, "transfer " + name + " " + item)


func _until(condition: Callable, seconds: float, label: String) -> void:
	for i in int(seconds / 0.05):
		if condition.call(): break
		model._step(0.05)
		if i % 20 == 0 and not model.material_balance().balanced:
			expect(false, label + " material balance"); return
	expect(condition.call(), label)
	_roundtrip(model, label)


func _natural() -> void:
	model = Model.new()
	_rows(FirstLayout.rows("A"))
	_gate("GI", "iron_ore", 8); _gate("GQ", "crystal", 6)
	_until(func(): return model.completed_by_recipe.direct_refining == 4 and model.by_id(ids.F).output.is_empty() and model.by_id(ids.U).items.get("crystal", 0) == 6, 120, "E2 original E1 raw input")
	_recipe("F", "direct_sintering"); _take("U", "crystal"); _take("F", "crystal", true)
	_until(func(): return model.by_id(ids.T).items.get("construction_pack", 0) == 2, 120, "natural first two packs")
	_take("T", "construction_pack")
	expect(model.assemble("refinery").ok and model.place("refinery", Vector2i(-12, -5)).ok and model.first_expansion_placed, "natural second furnace unlock")
	_profile("P")
	_gate("GI", "iron_ore", 12); _gate("GQ", "crystal", 9)
	_until(func(): return model.by_id(ids.T1).items.get("construction_pack", 0) == 3, 300, "P makes first generator cost")
	_take("T1", "construction_pack"); expect(model.assemble("cell_generator").ok, "manufacture first G")
	_profile("C")
	var g: Dictionary = model.by_id(ids.G)
	near(model, g); model.set_device_enabled(g.id, false)
	_gate("GI", "iron_ore", 4); _gate("GQ", "crystal", 4); _gate("GK", "carbon_ore", 2); _gate("GF", "industrial_cell", 2)
	_until(func(): return g.fuel.get("industrial_cell", 0) == 2, 240, "C naturally manufactures two cells")
	near(model, g); model.set_device_enabled(g.id, true)
	model._step(0.05)
	expect(g.remaining_kj == 0 and model.statistics.totals.cells_activated == 0 and model.power_state().request_kw <= 220, "C cold-start uses base power without fuel burn")
	milestones.C = {"time": model.time, "owned": model.owned_count(), "energy": model.energy_balance()}
	_roundtrip(model, "C ready"); _write("compact.json", snapshot(model))
	_profile("P")
	_gate("GI", "iron_ore", 100); _gate("GQ", "crystal", 75)
	_until(func(): return model.by_id(ids.T1).items.get("construction_pack", 0) == 25, 600, "P manufactures remaining 25 packs")
	_take("T1", "construction_pack")
	for type in ["collector", "refinery", "refinery", "refinery", "assembler", "assembler", "admission_gate", "splitter", "splitter"]:
		expect(model.assemble(type).ok, "D manufacture " + type)
	for i in 10: expect(model.assemble("belt").ok, "D manufacture eight belts")
	expect(model.owned_count() == 256 and model.bag.get("construction_pack", 0) == 0, "D exact thirty-pack cumulative construction")
	_profile("D")
	g = model.by_id(ids.G); near(model, g); model.set_device_enabled(g.id, false)
	_take("G", "industrial_cell", true)
	_gate("GI", "iron_ore", 80); _gate("GQ", "crystal", 60); _gate("GK", "carbon_ore", 6); _gate("GQE", "crystal", 12); _gate("GF", "industrial_cell", 6)
	_until(func(): return model.power_state().request_kw > 240, 300, "D natural real power deficit")
	_roundtrip(model, "D comparison parent"); _write("demand.json", snapshot(model)); _write("state-context.json", {"ids": ids})
	_compare()
	_bad_saves()
	_reclaim_active_generator()
	_expand_and_recover()


func _packs(m: RefCounted) -> int:
	return m.by_id(ids.T1).items.get("construction_pack", 0) + m.by_id(ids.T2).items.get("construction_pack", 0)


func _compare() -> void:
	var doc := snapshot(model)
	var start := _packs(model)
	var results := {}
	for enabled in [false, true]:
		var restored := Codec.decode(doc, ID)
		expect(restored.ok, "comparison restores exact parent")
		if not restored.ok: return
		var m: RefCounted = restored.model
		var g: Dictionary = m.by_id(ids.G)
		near(m, g)
		if g.enabled != enabled: m.set_device_enabled(g.id, enabled)
		var elapsed := 0.0
		var peak := 0.0
		var energy_before: float = m.statistics.totals.cell_supplied_kj
		while _packs(m) < start + 4 and elapsed < 360:
			peak = maxf(peak, m.power_state().request_kw)
			m._step(0.05); elapsed += 0.05
		expect(_packs(m) >= start + 4, "same four packs " + str(enabled))
		results[str(enabled)] = {"seconds": elapsed, "peak_requested_kw": peak, "cell_supplied_kj": m.statistics.totals.cell_supplied_kj - energy_before}
		_roundtrip(m, "four packs " + str(enabled))
		_write("comparison-on.json" if enabled else "comparison-off.json", snapshot(m))
		if enabled: model = m
	expect(results["true"].seconds < results["false"].seconds and results["true"].cell_supplied_kj > 0, "generator improves actual four-pack arrival time")
	milestones.comparison = results
	_write("partial.json", snapshot(model))
	var copy := Codec.decode(snapshot(model), ID)
	if copy.ok:
		for i in 1600: copy.model._step(0.05)
		_write("expected.json", snapshot(copy.model))
	_write("milestones.json", milestones)


func _enabled(name: String, enabled: bool) -> void:
	var entity: Dictionary = model.by_id(ids[name])
	near(model, entity)
	expect(model.set_device_enabled(entity.id, enabled).ok, "device enabled " + name + " " + str(enabled))


func _expand_and_recover() -> void:
	for name in ["T1", "T2"]:
		if model.by_id(ids[name]).items.get("construction_pack", 0) > 0: _take(name, "construction_pack")
	expect(model.assemble("cell_generator").ok and model.assemble("splitter").ok, "D+ spends four real packs")
	_profile("D+")
	expect(model.owned_count() == 258, "D+ total ownership is 258")
	_gate("GI", "iron_ore", 256); _gate("GQ", "crystal", 192)
	_gate("GK", "carbon_ore", 6); _gate("GQE", "crystal", 12); _gate("GF", "industrial_cell", 6)
	_until(func():
		var allocation: Dictionary = model.power_state()
		return allocation.sources.get(ids.G, 0) > 0 and allocation.sources.get(ids.G2, 0) > 0,
		360, "D+ two generators really supply together")
	model._step(0.05)
	expect(model.by_id(ids.G).remaining_kj > 0 and model.by_id(ids.G2).remaining_kj > 0, "both generators commit real fuel consumption")
	milestones.two_generators = {"time": model.time, "energy": model.energy_balance(), "power": model.power_state()}
	var gate: Dictionary = model.by_id(ids.GF)
	near(model, gate); expect(model.set_admission_accepting(gate.id, false).ok, "close real fuel admission")
	# Allow the finite downstream path to drain before taking all intact cells away.
	for i in 200: model._step(0.05)
	for name in ["G", "G2"]:
		if model.by_id(ids[name]).fuel.get("industrial_cell", 0) > 0: _take(name, "industrial_cell")
	var activated: int = model.statistics.totals.cells_activated
	_until(func(): return model.by_id(ids.G).remaining_kj == 0 and model.by_id(ids.G2).remaining_kj == 0,
		900, "real factory demand exhausts both active cells")
	expect(model.statistics.totals.cells_activated == activated, "closed and drained fuel cannot activate withdrawn cells")
	expect(model.power_state().available_kw == 240 and model.power_state().request_kw > 240, "exhausted grid falls back to original 240 kW under real demand")
	_write("exhausted.json", snapshot(model))
	for name in ["Q", "F2", "F3", "H1", "H2", "A1", "A2"]: _enabled(name, false)
	var batches := {}
	for name in ["F2", "F3", "H1", "H2", "A1", "A2"]:
		var entity: Dictionary = model.by_id(ids[name])
		batches[name] = {"progress": entity.progress, "invested": entity.invested.duplicate(true)}
	_gate("GI", "iron_ore", 32); _gate("GK", "carbon_ore", 2); _gate("GQE", "crystal", 4); _gate("GF", "industrial_cell", 2)
	var produced: int = model.completed_by_recipe.cell_assembly
	_until(func(): return model.completed_by_recipe.cell_assembly > produced and (model.by_id(ids.G).fuel.get("industrial_cell", 0) + model.by_id(ids.G2).fuel.get("industrial_cell", 0)) > 0,
		480, "base-powered energy chain manufactures and delivers replacement cell")
	expect(model.power_state().request_kw <= 220 and model.statistics.totals.cells_activated == activated, "recovery chain remains within base supply")
	for name in batches:
		var entity: Dictionary = model.by_id(ids[name])
		expect(entity.progress == batches[name].progress and entity.invested == batches[name].invested, "load shedding preserves batch " + name)
	for name in ["Q", "F2", "F3", "H1", "H2", "A1", "A2"]: _enabled(name, true)
	_until(func(): return model.statistics.totals.cells_activated > activated, 180, "resumed production uses newly manufactured fuel")
	milestones.recovery = {"time": model.time, "energy": model.energy_balance(), "manufactured_cells": model.completed_by_recipe.cell_assembly}
	_write("recovered.json", snapshot(model)); _write("milestones.json", milestones)


func _bad_saves() -> void:
	var doc := snapshot(model)
	for change in ["negative", "overflow", "fake_fuel", "fake_activation", "fake_loss", "extra_field", "enabled", "origin", "premature"]:
		var bad := doc.duplicate(true)
		var g: Dictionary = bad.state.entities.filter(func(e): return e.type == "cell_generator")[0]
		match change:
			"negative": g.remaining_kj = -1
			"overflow": g.remaining_kj = 7201
			"fake_fuel": g.fuel.industrial_cell = 6
			"fake_activation": bad.state.statistics.totals.cells_activated += 1
			"fake_loss": bad.state.statistics.totals.discarded_kj += 1
			"extra_field": g.output = {}
			"enabled": g.enabled = 1
			"origin": bad.state.energy_origin = {"source_id": ID}
			"premature": bad.state.first_expansion_placed = false
		expect(not Codec.decode(bad, ID).ok, "strict V7 rejects " + change)
	for field in ["ruleset_id", "map_id", "supply_id"]:
		var bad := doc.duplicate(true); bad[field] = "wrong"
		var result := Codec.decode(bad, ID)
		expect(not result.ok and result.get("unsupported", false), "fatal identity " + field)


func _reclaim_active_generator() -> void:
	var parent := snapshot(model)
	var decoded := Codec.decode(parent, ID)
	expect(decoded.ok, "restore natural energy ledger for recovery-loss test")
	if not decoded.ok: return
	var copy: RefCounted = decoded.model
	var generator: Dictionary = copy.by_id(ids.G)
	var remaining: float = generator.remaining_kj
	var intact: int = generator.fuel.get("industrial_cell", 0)
	var held: int = copy.bag.get("industrial_cell", 0)
	near(copy, generator)
	expect(remaining > 0 and copy.salvage(generator.id, true).ok, "recover a genuinely fueled natural generator")
	expect(copy.statistics.totals.discarded_kj == remaining and copy.bag.get("industrial_cell", 0) == held + intact and copy.owned_count() == model.owned_count(), "natural recovery records only active energy loss and returns all intact cells and kit")
	_roundtrip(copy, "natural positive recovery loss")
	_write("reclaimed-generator.json", snapshot(copy))
	expect(Compare.equivalent(parent, snapshot(model)), "recovery-loss branch leaves production parent unchanged")


func _store() -> void:
	var root := evidence.path_join("factory")
	var store := Store.new(root)
	var source := store.create("E1 复制来源", E1.Expansion.SUPPLY_ID, true)
	expect(source.ok, "create isolated E1 copy source")
	if not source.ok: return
	expect(store.save(source.model).ok, "source backup exists before copy rejection tests")
	var source_id: String = store.world_id
	var source_file: String = store.path("autosave.json")
	var bytes := FileAccess.get_file_as_bytes(source_file)
	var hash := FileAccess.get_sha256(source_file)
	var selected_sequence: int = store.sequence
	var copy := Store.new(root)
	expect(not copy.copy_energy(source_id, selected_sequence, hash, "锁占用副本").ok, "occupied source rejects copy")
	store.release()
	for stage in ["validation", "temporary_write", "readback", "publish", "copy_source_changed", "copy_publish"]:
		copy = Store.new(root); copy.fault = func(point): return point == stage
		var result := copy.copy_energy(source_id, selected_sequence, hash, "失败副本")
		expect(not result.ok and copy.list_worlds().size() == 1 and FileAccess.get_file_as_bytes(source_file) == bytes, "copy failure atomic " + stage)
	var future: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(source_file))
	future.save_schema_version = 99
	for damaged in ["{broken", JSON.stringify(future)]:
		var file := FileAccess.open(source_file, FileAccess.WRITE)
		file.store_string(damaged); file.close()
		copy = Store.new(root)
		expect(not copy.copy_energy(source_id, selected_sequence, hash, "不可复制来源").ok and FileAccess.get_file_as_string(source_file) == damaged and copy.list_worlds().size() == 1, "bad main or future identity refuses copy without silently using backup")
		file = FileAccess.open(source_file, FileAccess.WRITE)
		file.store_buffer(bytes); file.close()
	copy = Store.new(root)
	expect(not copy.copy_energy(source_id, selected_sequence + 1, hash, "过时选择").ok, "stale selection refuses copy")
	var result := copy.copy_energy(source_id, selected_sequence, hash, "E2 复制结果")
	expect(result.ok and copy.world_id != source_id and FileAccess.get_file_as_bytes(source_file) == bytes, "successful copy preserves original bytes and independent identity")
	if result.ok:
		expect(result.model.energy_origin.source_id == source_id and result.model.owned_count() == 165, "copy records source and adds no supply")
		expect(not copy.save(E1.new()).ok, "E2 session rejects E1 identity")
		expect(copy.save(model).ok, "save natural D model")
		var original := FileAccess.get_file_as_bytes(copy.path("autosave.json"))
		for stage in ["validation", "temporary_write", "readback", "backup", "publish"]:
			copy.fault = func(point): return point == stage
			expect(not copy.save(model).ok and FileAccess.get_file_as_bytes(copy.path("autosave.json")) == original, "save failure atomic " + stage)
		copy.fault = Callable()
		copy.release()


func _restore() -> void:
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("partial.json")))
	var restored := Codec.decode(doc, ID)
	expect(restored.ok, "independent partial energy restore")
	if not restored.ok: return
	model = restored.model
	for i in 1600: model._step(0.05)
	var expected: Variant = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("expected.json")))
	expect(Compare.equivalent(snapshot(model), expected), "independent 80-second trajectory matches")
	_roundtrip(model, "independent final")
