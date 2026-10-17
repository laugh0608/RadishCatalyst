extends RefCounted

const Codec := preload("res://scripts/factory/save/codec.gd")
const Layout := preload("res://scripts/checks/factory_combination_layout.gd")
const Rules := preload("res://data/factory/discovery_rules.gd")
const Items := preload("res://scripts/factory/items.gd")
const Compare := preload("res://scripts/checks/factory_discovery_check.gd")


static func decode_source(source: Variant, prepared := false) -> Dictionary:
	if not source is Dictionary or source.get("save_schema_version") != 5 or not source.get("world_id") is String:
		return {"ok": false, "reason": "Expected an explicit schema 5 source"}
	var decoded := Codec.decode(source, source.world_id)
	if not decoded.ok: return decoded
	var model: RefCounted = decoded.model
	if model.supply_id != Rules.ADMISSION_SUPPLY_ID or not model.discovery.passages.outer or not model.discovery.passages.inner or not model.discovery.trial_completed:
		return {"ok": false, "reason": "Expected ordinary V5 completed discovery world"}
	var power: Dictionary = model.power_state()
	if power.installed_kw != 240 or power.available_kw != 240 or model.grid.groups.size() != 1:
		return {"ok": false, "reason": "Expected two enabled finite sources in one connected grid"}
	var ids := {}
	for row in Layout.combination_entities():
		for e in model.entities:
			if e.type == row.type and e.x == row.x and e.z == row.z and e.dir == row.dir:
				ids[row.name] = e.id
	if ids.size() != 84 or model.entities.size() != 84:
		return {"ok": false, "reason": "Expected the recorded 84 entity C layout"}
	for pair in [["basic", "basic_catalyst"], ["rich", "rich_catalyst"], ["solvent", "crust_solvent"]]:
		if model.by_id(ids[pair[0]]).recipe_id != pair[1]:
			return {"ok": false, "reason": "Unexpected processing recipe"}
	for pair in [["g1", "crystal"], ["g2", "rich_crystal"], ["g3", "catalyst"]]:
		var gate: Dictionary = model.by_id(ids[pair[0]])
		if gate.filter_item != pair[1] or gate.quota_mode != "unlimited" or not gate.accepting:
			return {"ok": false, "reason": "Required material branch is closed or limited"}
	var g4: Dictionary = model.by_id(ids.g4)
	if g4.filter_item != "crust_solvent" or not g4.accepting:
		return {"ok": false, "reason": "Expected configured solvent receiver"}
	if prepared:
		if g4.quota_mode != "unlimited" or model.statistics.buckets.size() != 600 or model.statistics_ui.window_seconds != 600:
			return {"ok": false, "reason": "Prepared source needs unlimited G4 and full ten minute history"}
	elif g4.quota_mode != "quota" or g4.quota_limit != 8 or g4.quota_used != 8 or not g4.cargo.is_empty():
		return {"ok": false, "reason": "Expected exhausted, empty C completion checkpoint"}
	return {"ok": true, "model": model, "ids": ids}


static func contents(model: RefCounted) -> Dictionary:
	var result: Dictionary = model.bag.duplicate()
	for e in model.entities: Items.merge(result, Items.contents(e))
	return result


static func balance(model: RefCounted) -> Dictionary:
	var result := {}
	var held := contents(model)
	for item in Rules.ITEMS:
		result[item] = held.get(item, 0) - model.statistics.totals.produced.get(item, 0) + model.statistics.totals.consumed.get(item, 0) - model.statistics.totals.acquired.get(item, 0)
	return result


static func walk(model: RefCounted, target: Vector2) -> bool:
	# Preparation uses the real collision/movement command, with explicit movement steps.
	# No production time, materials, passages or actor coordinates are injected.
	for _step in 2400:
		var delta := target - Vector2(model.actor.x, model.actor.z)
		if delta.length() < 0.04: return true
		model.move_actor(model.actor, delta.x, delta.y, minf(0.02, delta.length() / 3.3))
	return false


static func observe(model: RefCounted, steps: int) -> Dictionary:
	var before: Dictionary = model.statistics.totals.duplicate(true)
	var completions := {"basic_catalyst": 0, "rich_catalyst": 0, "crust_solvent": 0}
	var peak_kw := 0.0
	var max_deficit_kw := 0.0
	for _step in steps:
		var working := {}
		for e in model.entities:
			if e.type == "reactor" and e.processing: working[e.id] = e.active_batch
		model.advance(0.05, 1)
		for id in working:
			var e: Dictionary = model.by_id(id)
			if not e.processing or e.active_batch != working[id]: completions[e.recipe_id] += 1
		var power: Dictionary = model.power_state()
		peak_kw = maxf(peak_kw, power.request_kw)
		max_deficit_kw = maxf(max_deficit_kw, power.deficit_kw)
	var changes := {}
	for kind in ["produced", "consumed", "delivered"]:
		changes[kind] = {}
		for item in Rules.ITEMS:
			changes[kind][item] = model.statistics.totals[kind].get(item, 0) - before[kind].get(item, 0)
	return {"steps": steps, "seconds": steps * 0.05, "completions": completions,
		"changes": changes, "peak_requested_kw": peak_kw, "max_deficit_kw": max_deficit_kw}


static func assert_work(driver: Node, observation: Dictionary, label: String) -> void:
	for recipe in observation.completions:
		driver.expect(observation.completions[recipe] > 0, label + " actual completion " + recipe)
	driver.expect(observation.changes.delivered.catalyst > 0 and observation.changes.delivered.crust_solvent > 0, label + " both products really enter storage")
	driver.expect(observation.max_deficit_kw == 0 and observation.peak_requested_kw > 0 and observation.peak_requested_kw <= 240, label + " finite connected power without deficit")


static func describe(model: RefCounted) -> Dictionary:
	var counts := {}
	var states := {}
	var stores := {}
	for e in model.entities:
		counts[e.type] = counts.get(e.type, 0) + 1
		if e.type in ["collector", "reactor"]:
			var status: String = model.feedback(e).label
			states[status] = states.get(status, 0) + 1
		if e.type == "storage": stores[str(e.id)] = {"items": e.items.duplicate(), "free": 200 - Items.count(e.items)}
	return {"entities": counts, "working_states": states, "stores": stores, "held": contents(model), "power": model.power_state()}


static func prepare(source: Dictionary, driver: Node) -> Dictionary:
	var decoded := decode_source(source)
	driver.expect(decoded.ok, "strict ordinary V5 C completion source: " + decoded.get("reason", ""))
	if not decoded.ok: return {}
	var model: RefCounted = decoded.model
	var initial := describe(model)
	var conserved := balance(model)
	var actor_before: Dictionary = source.state.actor.duplicate(true)
	var g4: Dictionary = model.by_id(decoded.ids.g4)
	var gate_before: Dictionary = g4.duplicate(true)
	var points := [Vector2(24.5, 0.5), Vector2(19, 0.5), Vector2(18.5, 0.5), Vector2(18.5, 2.5), Vector2(8.8, 2.5), Vector2(8.8, 0.5), Vector2(2, 0.5), Vector2(2, 5), Vector2(-3.5, 5), Vector2(-3.5, 1.6)]
	for point in points:
		var reached := walk(model, point)
		driver.expect(reached, "preparation collision-checked walk " + str(point))
		if not reached: return {}
	var configured: Dictionary = model.configure_admission(g4.id, "crust_solvent", "unlimited", 0)
	driver.expect(configured.ok, "nearby empty G4 configured through authoritative command")
	if not configured.ok: return {}
	driver.expect(model.set_admission_accepting(g4.id, true).ok, "G4 accepting through authoritative command")
	driver.expect(walk(model, Vector2(-3.5, 5)), "preparation ends at accessible factory hub")
	driver.expect(balance(model) == conserved and contents(model) == initial.held, "configuration and movement preserve every material")
	var before_time: float = model.time
	var before_remainder: float = model.remainder
	var preparation := observe(model, 12000)
	driver.expect(absf(model.time - before_time - 600.0) < 0.00001 and absf(model.remainder - before_remainder) < 0.00001, "exactly 600 seconds of completed steps with source remainder preserved")
	assert_work(driver, preparation, "600 second preparation")
	model.statistics_ui.window_seconds = 600
	var prepared := Codec.snapshot(model, source.world_id, "D4 V5 普通供给性能对照", 1)
	driver.expect(decode_source(prepared, true).ok, "prepared full history satisfies strict V5 source contract")
	driver.expect(model.statistics.window(600).seconds == 600, "all 600 complete seconds participate in ten minute query")
	driver.expect(balance(model) == conserved, "preparation material balance including invested inputs")
	var probe: RefCounted = Codec.decode(prepared, prepared.world_id).model
	var work := observe(probe, 900)
	assert_work(driver, work, "45 second continuation probe")
	driver.expect(balance(probe) == conserved, "continuation conserves material account")
	driver.expect(Codec.decode(Codec.snapshot(probe, source.world_id, prepared.name, 1), source.world_id).ok, "continuation remains strictly saveable")
	return {"snapshot": prepared, "continuation": Codec.snapshot(probe, source.world_id, prepared.name, 1),
		"report": {"ready": driver.failures.is_empty(), "initial": initial, "prepared": describe(model),
			"actor_before": actor_before, "actor_after": prepared.state.actor, "gate_before": gate_before,
			"gate_after": g4.duplicate(true), "preparation": preparation, "probe": work,
			"operations": "Real collision/movement steps without production, nearby empty G4 unlimited configuration; then 12000 explicit production steps. No inventory edits, kits, passage flags or supply changes. Probe uses a separate decoded copy."}}


static func check_rejections(source: Dictionary, prepared: Dictionary, driver: Node) -> void:
	for kind in ["schema", "supply", "quota", "closed", "passage", "power"]:
		var bad: Dictionary = source.duplicate(true)
		match kind:
			"schema": bad.save_schema_version = 4
			"supply": bad.supply_id = "factory_load_100_v1"
			"quota":
				for e in bad.state.entities:
					if e.type == "admission_gate" and e.quota_mode == "quota": e.quota_used = 9
			"closed":
				for e in bad.state.entities:
					if e.type == "admission_gate": e.accepting = false
			"passage": bad.state.discovery.passages.inner = false
			"power":
				for e in bad.state.entities:
					if e.type == "power_source": e.enabled = false
		driver.expect(not decode_source(bad).ok, "reject unsuitable preparation source " + kind)
	var incomplete: Dictionary = prepared.duplicate(true)
	incomplete.state.statistics_ui.window_seconds = 60
	driver.expect(not decode_source(incomplete, true).ok, "reject prepared source without ten minute window")
	driver.expect(not decode_source({}).ok, "reject missing source fields without default repair")
