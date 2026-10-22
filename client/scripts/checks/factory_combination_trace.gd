extends Node

# External evidence only. Never writes the model. A missed fixed step invalidates
# pending provenance rather than interpreting aggregate production as a transfer.
var model: RefCounted
var ids: Dictionary
var previous := {}
var paths := {}
var rich_in_input := 0
var certified_solvent := {}
var events: Array = []
var gaps: Array = []
var witnesses: Array = []
var source_sent := {"basic": false, "rich": false}
var source_completed := {"basic": false, "rich": false}
var ticks_observed := 0
var enabled := false
var peak_request_kw := 0.0
var peak_deficit_kw := 0.0
var peak_power := {}
var source_invested := {"basic": false, "rich": false}


func attach(value: RefCounted, names: Dictionary) -> void:
	model = value
	ids = names
	process_priority = 100000
	previous = sample()
	enabled = true


func sample() -> Dictionary:
	var result := {"tick": model.statistics.ticks, "entities": {}}
	for name in ["basic", "rich", "belt_-10_0", "belt_-10_8", "belt_-8_1", "m2", "s2", "g3", "solvent", "g4"]:
		if ids.has(name): result.entities[name] = model.by_id(ids[name]).duplicate(true)
	return result


func event(kind: String, data: Dictionary) -> void:
	events.append(data.merged({"kind": kind, "tick": model.statistics.ticks}))


func _process(_delta: float) -> void:
	if not enabled: return
	var current := sample()
	var distance: int = current.tick - previous.tick
	if distance == 0: return
	if distance != 1:
		gaps.append({"from_tick": previous.tick, "to_tick": current.tick, "discarded_paths": paths.duplicate(true), "rich_input_discarded": rich_in_input})
		paths.clear()
		rich_in_input = 0
		certified_solvent.clear()
		previous = current
		return
	ticks_observed += 1
	var power: Dictionary = model.power_state()
	peak_deficit_kw = maxf(peak_deficit_kw, power.deficit_kw)
	if power.request_kw > peak_request_kw:
		peak_request_kw = power.request_kw
		peak_power = power.duplicate(true)
	var a: Dictionary = previous.entities
	var b: Dictionary = current.entities
	for name in ["basic", "rich"]:
		if not a.has(name) or a[name].is_empty(): continue
		var old: Dictionary = a[name]
		var now: Dictionary = b[name]
		if now.active_batch > 0 and now.active_batch != old.active_batch:
			var required: Dictionary = model.DiscoveryRules.RECIPES[now.recipe_id].input
			var exact_input: bool = now.invested == required
			source_invested[name] = source_invested[name] or exact_input
			event("source_invested", {"source": name, "active_batch": now.active_batch, "recipe": now.recipe_id, "input_before": old.input.duplicate(), "invested": now.invested.duplicate(), "matches_recipe": exact_input})
		var outlet_name := "belt_-10_0" if name == "basic" else "belt_-10_8"
		var outlet: Dictionary = b.get(outlet_name, {})
		var old_outlet: Dictionary = a.get(outlet_name, {})
		# A one-unit output can complete and leave within the same fixed step.
		# Match the preceding active batch to the newly occupied adjacent belt;
		# comparing only output counts would miss this legitimate transfer.
		var immediate: bool = old.active_batch > 0 and old.processing and not now.processing and outlet.get("cargo", "") == "catalyst" and outlet.get("batch", 0) == old.active_batch and old_outlet.get("cargo", "").is_empty()
		var buffered: bool = old.output.get("catalyst", 0) > now.output.get("catalyst", 0) and outlet.get("cargo", "") == "catalyst" and outlet.get("batch", 0) == old.output_batch and old_outlet.get("cargo", "").is_empty()
		if old.active_batch > 0 and old.processing and not now.processing and (now.output_batch == old.active_batch or immediate):
			source_completed[name] = true
			event("source_completed", {"source": name, "completed_batch": old.active_batch, "invested": old.invested.duplicate(), "completion_in_output": now.output_batch == old.active_batch, "completion_sent_directly": immediate})
		if immediate or buffered:
			var sent_batch: int = old.active_batch if immediate else old.output_batch
			source_sent[name] = true
			event("producer_sent", {"source": name, "batch": sent_batch, "completed_and_sent_same_step": immediate, "adjacent_outlet": outlet_name})
			if name == "rich" and not paths.has(str(sent_batch)): paths[str(sent_batch)] = {"producer": true}

	for name in ["m2", "s2", "g3"]:
		if not b.has(name) or b[name].is_empty(): continue
		var now: Dictionary = b[name]
		var old: Dictionary = a[name]
		if now.cargo == "catalyst" and (old.cargo != now.cargo or old.batch != now.batch):
			var key := str(now.batch)
			if not paths.has(key): continue
			var needed := "producer" if name == "m2" else "m2" if name == "s2" else "s2"
			if paths[key].has(needed):
				paths[key][name] = true
				event("rich_transport", {"target": name, "rich_batch": now.batch})
	if a.has("s2") and not a.s2.is_empty() and a.s2.cargo == "catalyst" and b.s2.cargo.is_empty():
		for target in ["g3", "belt_-8_1"]:
			if a.has(target) and a[target].get("cargo", "").is_empty() and b[target].get("cargo", "") == "catalyst" and b[target].get("batch", 0) == a.s2.batch:
				event("s2_handoff", {"target": target, "batch": a.s2.batch})
	if a.has("solvent") and not a.solvent.is_empty():
		var old: Dictionary = a.solvent
		var now: Dictionary = b.solvent
		# Production runs before logistics. A new active batch consumes the whole
		# previous two-item input before any same-step G3 delivery is appended.
		if now.active_batch > 0 and now.active_batch != old.active_batch:
			if old.input.get("catalyst", 0) == 2 and rich_in_input > 0:
				certified_solvent[str(now.active_batch)] = true
				event("rich_invested", {"solvent_batch": now.active_batch, "rich_units": rich_in_input, "input_before": old.input.duplicate()})
			rich_in_input = 0
		if old.active_batch > 0 and certified_solvent.has(str(old.active_batch)):
			var finished_in_output: bool = now.output_batch == old.active_batch and now.output.get("crust_solvent", 0) > 0
			var finished_in_gate: bool = b.has("g4") and b.g4.get("cargo", "") == "crust_solvent" and b.g4.get("batch", 0) == old.active_batch and a.g4.get("cargo", "").is_empty()
			if finished_in_output or finished_in_gate:
				event("certified_solvent_completed", {"solvent_batch": old.active_batch, "same_step_to_g4": finished_in_gate})
		if a.has("g3") and not a.g3.is_empty() and a.g3.cargo == "catalyst" and b.g3.cargo.is_empty():
			var key := str(a.g3.batch)
			var consumed := 2 if now.active_batch > 0 and now.active_batch != old.active_batch else 0
			if now.input.get("catalyst", 0) == old.input.get("catalyst", 0) - consumed + 1 and paths.has(key) and paths[key].has("g3"):
				rich_in_input += 1
				event("rich_entered_solvent_input", {"rich_batch": a.g3.batch, "input_after": now.input.duplicate()})
	if a.has("g4") and not a.g4.is_empty():
		var old: Dictionary = a.g4
		var now: Dictionary = b.g4
		if old.cargo == "crust_solvent" and now.quota_used == old.quota_used + 1 and old.quota_limit == 8 and certified_solvent.has(str(old.batch)):
			var witness := {"solvent_batch": old.batch, "round_position": now.quota_used, "tick": current.tick}
			witnesses.append(witness)
			event("certified_solvent_passed_g4", witness)
	previous = current


func report() -> Dictionary:
	return {"observation": "read-only after-world process; only consecutive fixed-step transitions admitted", "continuous_steps": ticks_observed, "gaps": gaps, "events": events, "source_sent": source_sent, "source_completed": source_completed, "source_invested": source_invested, "peak_request_kw": peak_request_kw, "peak_deficit_kw": peak_deficit_kw, "peak_power": peak_power, "witnesses": witnesses, "pending_paths": paths, "pending_rich_input": rich_in_input, "pending_certified_solvent": certified_solvent}
