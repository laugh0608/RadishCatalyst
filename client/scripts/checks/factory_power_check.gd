extends SceneTree

const Model := preload("res://scripts/factory/discovery_model.gd")
const Codec := preload("res://scripts/factory/save/codec.gd")
const Store := preload("res://scripts/factory/save/store.gd")
const ID := "1234567890abcdef1234567890abcdef"
var assertions := 0
var failures: Array[String] = []


func _init() -> void:
	call_deferred("run")


func expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
		push_error(label)


func close(a: float, b: float, label: String) -> void:
	expect(absf(a - b) < 1e-7, label + " (%s / %s)" % [a, b])


static func line() -> RefCounted:
	var m := Model.new()
	m.place("collector", Vector2i(-20, -1))
	m.place("reactor", Vector2i(-13, -2))
	m.place("storage", Vector2i(-6, -1))
	for x in range(-18, -13):
		m.place("belt", Vector2i(x, 0))
	for x in range(-10, -6):
		m.place("belt", Vector2i(x, 0))
	m.place("power_source", Vector2i(-20, -6)) # 13
	m.place("power_junction", Vector2i(-13, -5)) # 14
	m.connect_power(13, 14)
	return m


func doc(m: RefCounted) -> Dictionary:
	return Codec.snapshot(m, ID, "D2-A", 1)


func reject(value: Dictionary, label: String, unsupported := false) -> void:
	var result := Codec.decode(value, ID)
	expect(not result.ok, label)
	if unsupported:
		expect(result.get("unsupported", false), label + " blocks fallback")


func run() -> void:
	var m := line()
	var before := doc(m)
	expect(not m.connect_power(13, 14).ok, "duplicate rejected")
	expect(not m.connect_power(13, 13).ok, "self loop rejected")
	expect(not m.connect_power(13, 3).ok, "passive storage rejected")
	expect(not m.connect_power(13, 2).ok, "consumer distance rejected")
	expect(doc(m) == before, "failed commands zero mutation")
	m.advance(2)
	expect(m.generated == 0 and m.next_batch == 1, "unwired no production or batch")
	close(m.power_state().deficit_kw, 20, "unwired deficit survives isolated capacity")
	close(m.statistics.totals.used_kj, 0, "unwired zero energy")
	expect(m.connect_power(13, 1).ok and m.connect_power(14, 2).ok, "wire ordinary line")
	m.advance(9.35)
	expect(m.by_id(2).processing, "natural half batch reached")
	var saved := doc(m)
	var decoded := Codec.decode(JSON.parse_string(JSON.stringify(saved, "", false, true)), ID)
	expect(decoded.ok, "joint schema half batch accepted: " + decoded.get("reason", ""))
	if not decoded.ok:
		quit(1)
		return
	var resumed: RefCounted = decoded.model
	close(resumed.by_id(2).progress, m.by_id(2).progress, "half batch fraction restored")
	close(resumed.statistics.totals.used_kj, m.statistics.totals.used_kj, "energy restored")
	m.advance(35)
	resumed.advance(35)
	expect(doc(m) == doc(resumed), "post-load full trajectory equal")
	expect(m.completed > 0 and m.delivered > 0, "ordinary line real delivery")
	expect(m.statistics.totals.produced.catalyst == m.completed, "completion counted once")
	expect(m.statistics.totals.consumed.crystal == 2 * m.completed, "only completed batches consume")
	expect(m.statistics.totals.delivered.catalyst == m.delivered, "transfer tracked separately")
	close(m.statistics.totals.supplied_kj, m.statistics.totals.used_kj, "energy conservation")
	var progress: float = m.by_id(2).progress
	var energy: float = m.statistics.totals.used_kj
	var batch: int = m.next_batch
	expect(m.set_source_enabled(13, false).ok, "switch source off")
	m.advance(2)
	close(m.by_id(2).progress, progress, "blackout preserves half batch")
	close(m.statistics.totals.used_kj, energy, "blackout no energy")
	expect(m.next_batch == batch, "blackout no batch allocation")
	expect(Model.Items.count(m.by_id(1).buffer) < 50, "passive output transport remains available")
	m.set_source_enabled(13, true)
	m.advance(1)
	expect(m.by_id(2).progress != progress or m.next_batch > batch, "power resumes original work")
	before = doc(m)
	var count: int = m.grid.rebuild_count
	m.power_state()
	m.power_state()
	expect(m.grid.rebuild_count == count, "topology cache reused")
	expect(doc(m) == before, "view graph rebuild has no events")
	before = doc(m)
	expect(not m.salvage(13).ok and doc(m) == before, "connected removal requires confirmation")
	expect(m.salvage(13, true).ok and m.by_id(1).power_node_id == 0 and m.power_links.is_empty(), "confirmed removal clears references")
	close(m.statistics.totals.used_kj, before.state.statistics.totals.used_kj, "salvage never refunds energy")
	var ordinary := Codec.V1.Model.new()
	var legacy := Codec.snapshot(ordinary, ID, "旧工厂", 1)
	expect(legacy.save_schema_version == 1 and Codec.decode(legacy, ID).ok, "schema 1 remains schema 1")
	expect(not Codec.V1.decode(saved, ID).ok and Codec.V1.decode(saved, ID).unsupported, "old reader rejects schema 2")
	for key in ["ruleset_id", "map_id", "supply_id"]:
		var bad := saved.duplicate(true)
		bad[key] = "unknown"
		reject(bad, "mixed identity " + key, true)
	var future := saved.duplicate(true)
	future.save_schema_version = 3
	reject(future, "future schema", true)
	var bad := saved.duplicate(true)
	bad.state.discovery.passages.outer = true
	reject(bad, "passage prerequisites rejected")
	for mutation in ["duplicate_link", "fractional_item", "bad_reference", "overlap_bucket", "nan_energy", "unknown_field", "bad_investment", "bad_energy"]:
		bad = saved.duplicate(true)
		match mutation:
			"duplicate_link": bad.state.power_links.append(bad.state.power_links[0])
			"fractional_item": bad.state.entities[0].buffer.crystal = 1.5
			"bad_reference": bad.state.entities[0].power_node_id = 3
			"overlap_bucket": bad.state.statistics.buckets[1].start_tick = 0
			"nan_energy": bad.state.statistics.current.used_kj = NAN
			"unknown_field": bad.state.extra = 1
			"bad_investment": bad.state.entities[1].invested.crystal = 1
			"bad_energy": bad.state.statistics.totals.supplied_kj += 1
		reject(bad, mutation)
	var boundary := saved.duplicate(true)
	boundary.state.entities[0].progress = 1.0 - 5e-9
	boundary.state.entities[1].progress = 10.0 - 5e-9
	var fractional := Codec.decode(boundary, ID)
	expect(fractional.ok, "fractional powered near-completion save accepted")
	if fractional.ok:
		expect(fractional.model.by_id(1).progress == boundary.state.entities[0].progress and fractional.model.by_id(2).progress == boundary.state.entities[1].progress, "near-completion restore does not snap progress")
	boundary.state.entities[0].progress = 1.0
	reject(boundary, "completed cycle cannot remain in progress")
	_test_stalls_and_cancel()
	_test_distribution()
	_test_buckets()
	_test_store(saved)
	print("Factory power checks: %d assertions, %d failures" % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _test_distribution() -> void:
	var m := Model.new()
	var source: Dictionary = m.place("power_source", Vector2i(-20, -8)).entity
	var node: Dictionary = m.place("power_junction", Vector2i(-17, -3)).entity
	m.connect_power(source.id, node.id)
	for cell in [Vector2i(-23, -3), Vector2i(-20, 1), Vector2i(-15, -3), Vector2i(-16, 1)]:
		var e: Dictionary = m.place("reactor", cell).entity
		e.input = {"crystal": 2} # Arithmetic fixture: independent from save/material tests.
		expect(m.connect_power(node.id, e.id).ok, "overload consumer connection")
	m.advance(0.05)
	for e in m.entities:
		if e.type == "reactor":
			close(e.progress, 0.0375, "120/160 fair work")
	close(m.statistics.totals.used_kj, 6, "120 kW full step is 6 kJ")
	var second: Dictionary = m.place("power_source", Vector2i(-12, -8)).entity
	close(m.power_state().deficit_kw, 40, "isolated spare cannot erase shortfall")
	m.connect_power(second.id, source.id)
	var a: Dictionary = m.power_state()
	close(a.sources[source.id], 80, "first source proportional output")
	close(a.sources[second.id], 80, "second source proportional output")
	m.connect_power(second.id, node.id)
	close(m.power_state().supplied_kw, 160, "cycle counts sources once")
	m.advance(0.05)
	close(m.statistics.totals.used_kj, 14, "second source restores full speed")
	m.disconnect_power(second.id, source.id)
	m.disconnect_power(second.id, node.id)
	close(m.power_state().supplied_kw, 120, "split restores limited supply")
	for e in m.entities:
		if e.type == "reactor":
			e.progress = 9.99
	var prior: float = m.statistics.totals.used_kj
	m.advance(0.05)
	close(m.statistics.totals.used_kj - prior, 1.6, "four final 0.01s steps cost 1.6 kJ")
	var batch: int = m.next_batch
	m.advance(0.05)
	expect(m.next_batch == batch, "full output idle no next batch")
	close(m.power_state().request_kw, 0, "output blocked requests zero")
	var gates := {"outer": false, "inner": false}
	expect(not Model.Grid.line_open(Vector2(1.5, -1.5), Vector2(9.5, -1.5), gates), "closed passage rejects line")
	gates.outer = true
	expect(Model.Grid.line_open(Vector2(1.5, -1.5), Vector2(9.5, -1.5), gates), "opened passage permits line")
	expect(not Model.Grid.line_open(Vector2(1.5, -2), Vector2(9.5, -2), gates), "edge grazing closed cell rejects")
	expect(not m.placement("belt", Vector2i(10, 2)).ok, "closed area rejects construction")
	expect(m.blocked_for_actor(4, 0), "closed terrain blocks actor")


func _test_buckets() -> void:
	var m := Model.new()
	expect(not m.statistics.window(60).has_samples, "zero coverage is no sample")
	m.advance(0.95)
	expect(m.statistics.buckets.is_empty(), "partial second hidden")
	var decoded := Codec.decode(doc(m), ID)
	expect(decoded.ok, "half bucket save")
	m.advance(0.05)
	expect(m.statistics.buckets.size() == 1 and m.statistics.current.ticks == 0, "exact second closes once")
	m.advance(600, 13000)
	expect(m.statistics.buckets.size() == 600 and m.statistics.buckets[0].start_tick == 20, "600 second bounded history")
	expect(Codec.decode(doc(m), ID).ok, "truncated history accepted")
	close(m.statistics.window(60).seconds, 60, "window uses full seconds")
	var stats := Model.Statistics.new()
	var p := {"installed_kw": 0, "available_kw": 0, "request_kw": 0, "supplied_kw": 0, "deficit_kw": 0}
	for i in 20:
		stats.begin_step(p, 0.05)
		if i == 19:
			stats.event("produced", "crystal", 1)
		stats.end_step()
	stats.event("acquired", "crust_sample", 1)
	expect(stats.buckets[0].produced.crystal == 1 and stats.buckets[0].acquired.crust_sample == 1 and stats.current.produced.is_empty(), "step and command boundary count once")


func _test_store(saved: Dictionary) -> void:
	var root_path := ProjectSettings.globalize_path("res://../tools/runtime-intake/check-runs/factory-power-v1").path_join("store-%d-%d" % [Time.get_unix_time_from_system(), OS.get_process_id()])
	var store := Store.new(root_path)
	var created := store.create("电力保护", Model.DiscoveryRules.SUPPLY_ID)
	expect(created.ok, "Store creates schema 2")
	if not created.ok:
		return
	var document := saved.duplicate(true)
	document.world_id = store.world_id
	var model: RefCounted = Codec.decode(document, store.world_id).model
	expect(store.save(model).ok, "Store saves natural half batch")
	var hash := FileAccess.get_sha256(store.path("autosave.json"))
	store.release()
	var other := Store.new(root_path)
	var result := other.prepare(store.world_id)
	expect(result.ok and result.model.by_id(2).processing, "Store rebuild before first simulation")
	expect(other.accept(result).ok, "Store accepts candidate")
	other.release()
	document.save_schema_version = 3
	var file := FileAccess.open(store.path("autosave.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(document))
	file.close()
	var future_hash := FileAccess.get_sha256(store.path("autosave.json"))
	var candidate := other.find_candidate(store.world_id)
	expect(not candidate.ok and candidate.unsupported, "future main never falls back to valid older backup")
	expect(FileAccess.get_sha256(store.path("autosave.json")) == future_hash and future_hash != hash, "refusal keeps future main bytes")


func _test_stalls_and_cancel() -> void:
	var m := line()
	m.connect_power(13, 1)
	m.connect_power(14, 2)
	m.advance(1)
	expect(m.generated == 1 and m.statistics.buckets[0].produced.crystal == 1, "actual production at exact second belongs to closing bucket")
	m.advance(8)
	expect(m.by_id(2).processing and m.statistics.totals.consumed.is_empty(), "starting batch only reserves inputs")
	var energy: float = m.statistics.totals.used_kj
	var amount: int = Model.Items.count(m.by_id(2).input) + 2
	expect(m.salvage(2).ok and m.bag.get("crystal", 0) == amount, "in-flight salvage returns original inputs")
	close(m.statistics.totals.used_kj, energy, "cancel does not refund used energy")
	expect(m.statistics.totals.consumed.is_empty() and m.statistics.totals.produced.get("catalyst", 0) == 0, "cancel invents neither consumption nor output")
	expect(Codec.decode(doc(m), ID).ok, "canceled work with spent energy persists")
	var before := doc(m)
	expect(not m.disconnect_power(13, 3).ok and doc(m) == before, "missing link removal zero mutation")
	m.advance(610, 13000)
	expect(Model.Items.count(m.by_id(1).buffer) == 50, "real buffer reaches backpressure")
	close(m.power_state().request_kw, 0, "full buffer consumes no power")
	expect(Codec.decode(doc(m), ID).ok, "nonzero truncated production history persists")
	var n := Model.new()
	var source: Dictionary = n.place("power_source", Vector2i(-20, -7)).entity
	var e: Dictionary = n.place("reactor", Vector2i(-17, -3)).entity
	n.connect_power(source.id, e.id)
	n.set_source_enabled(source.id, false)
	e.input = {"crystal": 2} # Synthetic work-readiness fixture.
	var batch: int = n.next_batch
	n.advance(0.05)
	expect(e.input == {"crystal": 2} and not e.processing and e.progress == 0 and n.next_batch == batch, "blackout with ready inputs never opens batch")
	n.set_source_enabled(source.id, true)
	n.advance(0.05)
	expect(e.processing and e.input.is_empty() and e.progress > 0, "fully off grid self-starts after switch on")
	var power: Dictionary = n.power_state()
	n.entities.reverse()
	n.rebuild_indexes()
	n.grid.revision = -1
	expect(n.grid.allocate(n, 0.05).devices == power.devices, "allocation independent of entity order")
	n.set_source_enabled(source.id, false)
	expect(n.salvage(source.id, true).ok and n.kits.power_source == 2, "source kit fully recovered")
	expect(n.place("power_source", Vector2i(-20, -7)).ok and n.kits.power_source == 1, "all-off grid can place source without energy")
