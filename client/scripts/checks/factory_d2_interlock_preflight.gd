extends "res://scripts/checks/factory_d2_fault_preflight.gd"

const Store := preload("res://scripts/factory/save/store.gd")


func _init(folder: String) -> void:
	super(folder, 5)


func derive() -> Dictionary:
	var capacity := _load_candidate()
	if not invalid.is_empty():
		return {"status": "sample_invalid", "reasons": invalid}
	var source := _decode(document)
	var derived := _snapshot(source)
	derived.save_schema_version = Codec.V16.VERSION
	derived.supply_id = Codec.V16.Interlocks.SUPPLY_ID
	derived.ruleset_id = Codec.V16.Interlocks.RULESET_ID
	derived.definitions_sha256 = Codec.V16.definitions_sha256()
	for e in derived.state.entities:
		if e.type == source.Buffer.TYPE:
			e.load_group.interlocks = []
		elif e.type in source.process_types:
			assert(not e.processing, "cannot derive an interlock fixture with an unfinished source")
			e.batch_outcome = "none"
	var store := Store.new(evidence.path_join("factory"), false, false, true)
	var directory := store.root.path_join(document.world_id)
	assert(DirAccess.make_dir_recursive_absolute(directory) == OK)
	_write("factory/" + document.world_id + "/autosave.json", derived)
	var candidate := store.prepare(document.world_id)
	assert(candidate.ok, str(candidate.get("reason", "")))
	assert(store.accept(candidate).ok)
	assert(Compare.equivalent(derived, _snapshot(candidate.model), "schema 16 Store reconstruction"))
	assert(store.release().ok)
	assert(not Store.new(store.root).find_candidate(document.world_id).ok, "ordinary Store accepted schema 16")
	_write("interlock-candidate.json", candidate.document)
	return {"status": "interlock_parent_prepared", "capacity_bounds": capacity,
		"candidate_sha256": FileAccess.get_sha256(evidence.path_join("candidate.json")),
		"derived_sha256": FileAccess.get_sha256(evidence.path_join("interlock-candidate.json")),
		"simulation_ticks_advanced": 0}


func recheck() -> Dictionary:
	document = _read("candidate.json")
	preparation = _read("preparation.json")
	ids = preparation.ids
	var checkpoint := _read("first-order-checkpoint.json")
	var model := _decode(checkpoint)
	assert(Compare.equivalent(checkpoint, _snapshot(model), "first order checkpoint"))
	var a: Dictionary = model.by_id(ids.A)
	var fd: Dictionary = model.by_id(ids.Fd)
	var group: Dictionary = model.by_id(ids.B).load_group
	var first_batch: int = a.active_batch
	assert(a.processing and first_batch > 0 and group.latch == "allow" and not fd.enabled
		and fd.batch_outcome == "completed" and model.start_interlock_reason(a.id).is_empty())
	var start_tick: int = int(checkpoint.state.simulation_tick) - int(document.state.simulation_tick)
	assert(_set_enabled(model, "Fd", true).ok)
	assert(fd.batch_outcome == "none" and not model.start_interlock_reason(a.id).is_empty())
	var malformed := _snapshot(model)
	for e in malformed.state.entities:
		if e.id == ids.Fd:
			e.batch_outcome = "invalid"
	assert(not Codec.decode(malformed, document.world_id).ok)
	var events: Array[Dictionary] = []
	var first_finished := false
	var blocked := false
	var verified_frozen_and_cancelled := false
	for offset in range(1, 401):
		var tick := start_tick + offset
		if fd.processing and not verified_frozen_and_cancelled:
			_check_frozen_and_cancelled(model)
			verified_frozen_and_cancelled = true
		var uncontrolled: Dictionary = model.uncontrolled_work_spec(a)
		var ready: bool = not a.processing and uncontrolled.ready
		var between_samples: bool = group.evaluation_ticks_left > 0
		var old_power_allow: bool = group.latch == "allow"
		var reason: String = model.start_interlock_reason(a.id)
		if ready and old_power_allow and between_samples:
			var restored := _decode(JSON.parse_string(JSON.stringify(_snapshot(model), "", true, true)))
			assert(restored.start_interlock_reason(a.id) == reason)
			assert(not restored.work_spec(restored.by_id(ids.A)).ready)
		var next_batch: int = model.next_batch
		var input: Dictionary = a.input.duplicate()
		model.advance(model.STEP, 1)
		if not first_finished and not a.processing:
			first_finished = true
			events.append({"event": "first_batch_completed", "tick": tick, "batch": first_batch})
		if ready:
			assert(not a.processing and a.active_batch == 0)
			if old_power_allow and between_samples and not reason.is_empty():
				blocked = true
				events.append({"event": "second_batch_blocked_with_old_allow", "tick": tick,
					"reason": reason, "fd_enabled": fd.enabled, "fd_processing": fd.processing,
					"outcome": fd.batch_outcome, "next_batch_before": next_batch,
					"input_before": input, "input_after": a.input.duplicate()})
				break
	var passed := first_finished and blocked and verified_frozen_and_cancelled
	_write("recheck-events.json", events)
	return {"status": "interlock_recheck_passed" if passed else "interlock_recheck_failed",
		"candidate_sha256": FileAccess.get_sha256(evidence.path_join("candidate.json")),
		"derived_sha256": FileAccess.get_sha256(evidence.path_join("interlock-candidate.json")),
		"first_finished": first_finished, "blocked_with_old_allow": blocked,
		"frozen_and_cancelled_rejected": verified_frozen_and_cancelled, "events": events}


func _check_frozen_and_cancelled(model: RefCounted) -> void:
	var clone := _decode(JSON.parse_string(JSON.stringify(_snapshot(model), "", true, true)))
	var fd: Dictionary = clone.by_id(ids.Fd)
	assert(_set_enabled(clone, "Fd", false).ok)
	assert(fd.processing and not clone.start_interlock_reason(ids.A).is_empty())
	var actor: Dictionary = clone.actor.duplicate(true)
	clone.actor.merge(preparation.approaches.Fd, true)
	assert(clone.cancel_batch(fd.id).ok)
	clone.actor.merge(actor, true)
	assert(not fd.processing and fd.batch_outcome == "cancelled" and not clone.start_interlock_reason(ids.A).is_empty())
	var restored := _decode(JSON.parse_string(JSON.stringify(_snapshot(clone), "", true, true)))
	assert(restored.by_id(ids.Fd).batch_outcome == "cancelled" and not restored.start_interlock_reason(ids.A).is_empty())


func _set_enabled(model: RefCounted, role: String, enabled: bool) -> Dictionary:
	var actor: Dictionary = model.actor.duplicate(true)
	model.actor.merge(preparation.approaches[role], true)
	var result: Dictionary = model.set_device_enabled(ids[role], enabled)
	model.actor.merge(actor, true)
	return result
