extends SceneTree

const Model := preload("res://scripts/factory/discovery_model.gd")
const Codec := preload("res://scripts/factory/save/codec.gd")
const Store := preload("res://scripts/factory/save/store.gd")
const ID := "1234567890abcdef1234567890abcdef"
var assertions := 0
var failures: Array[String] = []
var check_root := ""


func _init() -> void:
	call_deferred("run")


func expect(ok: bool, label: String) -> void:
	assertions += 1
	if not ok:
		failures.append(label)
		push_error(label)


static func build_line(model: RefCounted, power_first := false) -> RefCounted:
	var machines := [["collector", Vector2i(-20, -1)], ["reactor", Vector2i(-13, -2)], ["storage", Vector2i(-6, -1)]]
	var nodes := [["power_source", Vector2i(-20, -6)], ["power_junction", Vector2i(-17, -3)]]
	for spec in nodes + machines if power_first else machines + nodes:
		model.place(spec[0], spec[1])
	for x in range(-18, -13):
		model.place("belt", Vector2i(x, 0))
	for x in range(-10, -6):
		model.place("belt", Vector2i(x, 0))
	return model


static func snapshot(model: RefCounted) -> Dictionary:
	return Codec.snapshot(model, ID, "范围供电检查", 1)


func run() -> void:
	check_root = ProjectSettings.globalize_path("res://../tools/runtime-intake/check-runs/factory-range-power-v1/state-%d-%d" % [Time.get_unix_time_from_system(), OS.get_process_id()]).simplify_path()
	for power_first in [false, true]:
		var model := build_line(Model.new(true), power_first)
		expect(model.power_links.size() == 1, "nodes connect automatically regardless of build order")
		var reactor: Dictionary = model.entity_at(Vector2i(-13, -2))
		expect(reactor.power_node_id != 0, "reactor automatically joins a reachable node")
		model.advance(9.35)
		expect(reactor.processing and reactor.progress > 0, "no wiring commands needed for a natural in-progress batch")
		var source: Dictionary = model.entity_at(Vector2i(-20, -6))
		var progress: float = reactor.progress
		model.set_source_enabled(source.id, false)
		model.advance(0.5)
		expect(reactor.progress == progress and model.power_state().supplied_kw == 0, "automatic network blackout preserves batch")
		model.set_source_enabled(source.id, true)
		var count: int = model.grid.rebuild_count
		model.advance(0.5)
		expect(model.grid.rebuild_count == count, "fixed steps do not rebuild automatic topology")
		var saved := snapshot(model)
		var loaded := Codec.decode(JSON.parse_string(JSON.stringify(saved, "", false, true)), ID)
		expect(saved.save_schema_version == 3 and loaded.ok and loaded.model.automatic_power, "strict schema 3 restores automatic rules")
		if loaded.ok:
			model.advance(25)
			loaded.model.advance(25)
			expect(snapshot(model) == snapshot(loaded.model) and model.delivered > 0, "restored natural production matches uninterrupted trajectory")
		var before := snapshot(model)
		expect(not model.connect_power(source.id, reactor.id).ok and not model.disconnect_power(source.id, reactor.id).ok and snapshot(model) == before, "automatic graph rejects manual rewrites without mutation")
		var node: Dictionary = model.entity_at(Vector2i(-17, -3))
		expect(not model.salvage(node.id).ok and snapshot(model) == before, "connected node recovery still requires confirmation")
		expect(model.salvage(node.id, true).ok and reactor.power_node_id == 0, "removing sole reachable node disconnects consumer")
		_reject_graph(saved)
	_multinetwork()
	_capacity_and_boundaries()
	_sample()
	_upgrade()
	_fallback()
	print("Factory range power: %d assertions, %d failures." % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _reject_graph(saved: Dictionary) -> void:
	var bad: Dictionary = saved.duplicate(true)
	bad.state.power_links.clear()
	expect(not Codec.decode(bad, ID).ok, "incomplete automatic node graph rejected instead of repaired")
	bad = saved.duplicate(true)
	for e in bad.state.entities:
		if e.type == "reactor":
			e.power_node_id = 0
	expect(not Codec.decode(bad, ID).ok, "forged automatic consumer attachment rejected")
	bad = saved.duplicate(true)
	bad.save_schema_version = 4
	expect(Codec.decode(bad, ID).get("unsupported", false), "future schema blocks fallback")
	bad = saved.duplicate(true)
	bad.ruleset_id = Model.DiscoveryRules.RULESET_ID
	expect(Codec.decode(bad, ID).get("unsupported", false), "mixed manual rules and schema 3 blocks fallback")


func _multinetwork() -> void:
	# Geometry fixture around an open corridor; a consumer sees two nodes whose
	# direct segment crosses the shell, so the consumer must not bridge their grids.
	var model := Model.new(true)
	model.discovery.passages.outer = true
	var west: Dictionary = model.place("power_source", Vector2i(-3, -2)).entity
	var a: Dictionary = model.place("power_junction", Vector2i(3, 1)).entity
	var east: Dictionary = model.place("power_source", Vector2i(10, 3)).entity
	var b: Dictionary = model.place("power_junction", Vector2i(8, 3)).entity
	model.set_source_enabled(east.id, false)
	var consumer: Dictionary = model.place("reactor", Vector2i(7, -1)).entity
	expect(model.grid.groups.size() == 2, "consumer does not bridge two terrain-separated node networks")
	expect(consumer.power_node_id == a.id, "enabled network wins over nearer unpowered network")
	model.set_source_enabled(west.id, false)
	expect(consumer.power_node_id == b.id, "equal power priority uses nearest reachable node")
	model.set_source_enabled(east.id, true)
	expect(consumer.power_node_id == b.id and model.grid.groups.size() == 2, "source toggle reconnects without merging through consumers")
	var tied := Model.new(true)
	var first: Dictionary = tied.place("power_junction", Vector2i(-5, -3)).entity
	tied.place("power_junction", Vector2i(-5, 1))
	var reactor: Dictionary = tied.place("reactor", Vector2i(-2, -2)).entity
	expect(reactor.power_node_id == first.id, "distance ties choose lowest stable node ID")
	tied.entities.reverse()
	tied._refresh_automatic_power()
	expect(reactor.power_node_id == first.id, "entity iteration order cannot change automatic attachment")
	var closed := Model.new(true)
	closed.place("power_source", Vector2i(0, -2))
	expect(not closed.place("power_junction", Vector2i(8, 0)).ok, "automatic power does not authorize building in a sealed area")
	closed.discovery.surveyed = true
	closed.discovery.sample_taken = true
	closed.discovery.trial_completed = true
	closed.bag = {"crust_solvent": 4}
	closed.actor.x = 3.5
	closed.actor.z = 0
	var count: int = closed.grid.rebuild_count
	expect(closed.open_passage("outer").ok and closed.grid.rebuild_count > count, "real passage command refreshes automatic topology")
	var frontier: Dictionary = closed.place("power_junction", Vector2i(8, 0)).entity
	expect(closed.connections(frontier.id).size() == 1, "opened corridor permits automatic extension")


func _sample() -> void:
	var model := Model.new(true)
	model.actor.x = -1
	model.actor.z = 2.5
	var before := snapshot(model)
	expect(not model.near_sample() and not model.survey_sample(true).ok and snapshot(model) == before, "remote pickup is rejected without changing state")
	model.actor.x = 0.5
	expect(model.near_sample(), "sample interaction includes exact two-cell boundary")
	model.bag = {"crystal": 200}
	expect(not model.survey_sample(true).ok and not model.discovery.sample_taken and model.discovery.surveyed, "full bag keeps sample on ground and records only survey")
	model.bag.clear()
	expect(model.survey_sample(true).ok and model.bag.crust_sample == 1, "nearby pickup acquires the unique sample")
	before = snapshot(model)
	expect(not model.survey_sample(true).ok and snapshot(model) == before, "repeat pickup creates no second sample or statistic")
	var restored := Codec.decode(before, ID)
	expect(restored.ok and restored.model.discovery.sample_taken and restored.model.bag.crust_sample == 1, "schema 3 preserves sample uniqueness")


func _capacity_and_boundaries() -> void:
	var model := build_line(Model.new(true))
	model.place("reactor", Vector2i(-17, 1))
	model.place("reactor", Vector2i(-24, -2))
	# Deliberate demand fixture, distinct from the naturally produced line above.
	for e in model.entities:
		if e.type == "reactor":
			e.input = {"crystal": 2}
	model.revision += 1
	var power: Dictionary = model.power_state()
	expect(is_equal_approx(power.request_kw, 140.0) and is_equal_approx(power.supplied_kw, 120.0), "automatic coverage retains finite capacity")
	for device in power.devices.values():
		expect(is_equal_approx(device.fraction, 120.0 / 140.0), "automatic network shares shortage proportionally")
	model.advance(0.05)
	expect(is_equal_approx(model.statistics.totals.used_kj, 6.0), "automatic topology preserves fixed-step energy accounting")
	var edge := Model.new(true)
	var node: Dictionary = edge.place("power_junction", Vector2i(-13, -5)).entity
	var reactor: Dictionary = edge.place("reactor", Vector2i(-8, -6)).entity
	var far: Dictionary = edge.place("power_junction", Vector2i(-1, -5)).entity
	expect(reactor.power_node_id == node.id and edge.power_links == [[node.id, far.id]], "automatic assignment includes exact six and twelve cell boundaries")
	var beyond := Model.new(true)
	beyond.place("power_junction", Vector2i(-13, -5))
	var device: Dictionary = beyond.place("reactor", Vector2i(-7, -6)).entity
	beyond.place("power_junction", Vector2i(-26, -5))
	expect(device.power_node_id == 0 and beyond.power_links.is_empty(), "beyond-radius placements do not silently connect")


func _fallback() -> void:
	var store := Store.new(check_root.path_join("fallback"))
	var old := store.create("升级版本保护", Model.DiscoveryRules.SUPPLY_ID)
	store.save(old.model)
	var id: String = store.world_id
	store.release()
	var upgrade := Store.new(store.root)
	var candidate := upgrade.upgrade_automatic(upgrade.prepare(id))
	expect(upgrade.accept(candidate).ok, "fallback fixture upgrades normally")
	var document := Codec.snapshot(candidate.model, id, upgrade.world_name, upgrade.sequence)
	var main_path: String = upgrade.path("autosave.json")
	upgrade.release()
	document.state.power_links = [[1, 2]]
	var file := FileAccess.open(main_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(document))
	file.close()
	var reader := Store.new(store.root)
	expect(not reader.prepare(id).ok, "known automatic main cannot fall back to a legacy manual backup")
	expect(not DirAccess.dir_exists_absolute(reader.path("session.lock")), "failed upgraded recovery releases its own lock")


func _upgrade() -> void:
	var store := Store.new(check_root)
	var created := store.create("旧世界升级检查", Model.DiscoveryRules.SUPPLY_ID)
	expect(created.ok, "legacy fixture is saved through normal Store")
	if not created.ok:
		return
	var old: RefCounted = build_line(created.model)
	var source: Dictionary = old.entity_at(Vector2i(-20, -6))
	var node: Dictionary = old.entity_at(Vector2i(-17, -3))
	old.connect_power(source.id, node.id)
	old.connect_power(node.id, old.entity_at(Vector2i(-20, -1)).id)
	old.connect_power(node.id, old.entity_at(Vector2i(-13, -2)).id)
	old.advance(9.35)
	old.actor.x = 1.5
	old.actor.z = 3.2
	expect(old.survey_sample(true).ok and old.entity_at(Vector2i(-13, -2)).processing, "legacy fixture has real partial batch and collected sample")
	var old_state: Dictionary = snapshot(old).state
	expect(store.save(old).ok, "legacy progressed world saved")
	var id: String = store.world_id
	var original_path: String = store.path("autosave.json")
	var original_hash := FileAccess.get_sha256(original_path)
	var sequence: int = store.sequence
	expect(store.release().ok, "legacy session releases lock")
	for stage in ["reconstruction", "upgrade_backup", "temporary_write", "readback", "publish"]:
		var retry := Store.new(check_root)
		var candidate := retry.prepare(id)
		expect(candidate.ok, "legacy candidate remains readable after previous fault")
		candidate = retry.upgrade_automatic(candidate)
		expect(candidate.ok and FileAccess.get_sha256(original_path) == original_hash, "staging upgrade has no disk mutation")
		retry.fault = func(at): return at == stage
		expect(not retry.accept(candidate).ok and FileAccess.get_sha256(original_path) == original_hash, stage + " fault preserves legacy main")
		retry.release()
	var current := Store.new(check_root)
	var candidate := current.upgrade_automatic(current.prepare(id))
	expect(current.accept(candidate).ok and current.sequence == sequence + 1, "reconstructed upgrade publishes once")
	var retained := DirAccess.get_files_at(current.path("backups"))
	var originals := Array(retained).filter(func(name): return name.begins_with("pre-auto-power-v2-") and name.ends_with(".json"))
	expect(originals.size() == 1 and FileAccess.get_sha256(current.path("backups/" + originals[0])) == original_hash, "immutable upgrade source matches original bytes")
	var document := Codec.snapshot(candidate.model, id, current.world_name, current.sequence)
	expect(document.save_schema_version == 3 and candidate.model.power_links.size() == 1, "upgrade activates real automatic graph")
	var new_state: Dictionary = document.state.duplicate(true)
	for state in [old_state, new_state]:
		state.erase("power_links")
		for e in state.entities:
			e.erase("power_node_id")
	expect(old_state == new_state, "upgrade preserves every non-power state field, including partial batch, clock, sample, inventory and statistics")
	for i in 4:
		expect(current.save(candidate.model).ok, "automatic saves validate and rotate regular backups")
	expect(FileAccess.get_sha256(current.path("backups/" + originals[0])) == original_hash, "regular rotation retains independent legacy source")
	current.release()
	var reopened := Store.new(check_root)
	var loaded := reopened.prepare(id)
	expect(loaded.ok and loaded.model.automatic_power and reopened.accept(loaded).ok, "new Store session reconstructs automatic world")
	loaded.model.advance(25)
	expect(loaded.model.delivered > 0, "upgraded existing layout produces without reconnecting")
	reopened.release()
