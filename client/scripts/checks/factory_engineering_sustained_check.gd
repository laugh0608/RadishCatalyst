extends "res://scripts/checks/factory_engineering_boot_check.gd"

const LiveObserver := preload("res://scripts/checks/factory_engineering_live_observer.gd")
var observer: RefCounted
var phase_work: Array[Dictionary] = []
var phase_start := {}


func load_world(label: String) -> bool:
	if not await super.load_world(label): return false
	observer = LiveObserver.new(world.model)
	process_frame.connect(_observe)
	return true


func _observe() -> void:
	if observer != null and is_instance_valid(world) and not interrupted:
		observer.observe()


func _sample_started(label: String) -> void:
	observer.observe()
	phase_start = {"label": label, "tick": observer.previous_tick,
		"counts": observer.devices.map(func(row): return row.count), "density_index": observer.density.size()}


func _sample_finished(label: String) -> void:
	observer.observe()
	var counts := []
	for index in observer.devices.size():
		var row: Dictionary = observer.devices[index]
		counts.append({"id": row.id, "cell": row.cell, "name": row.name,
			"events": row.count - phase_start.counts[index]})
		if mode == "sustained": driver.expect(counts.back().events > 0, "actual phase work %s device %d" % [label, row.id])
	var saves: Array = world.save_samples.duplicate(true)
	var save_ms: Array[float] = []
	for save in saves:
		driver.expect(save.ok, "automatic save succeeded " + label)
		save_ms.append(save.duration_ms)
	# At least floor(duration / 30)-1 saves, allowing boundary placement.
	driver.expect(saves.size() >= maxi(1, int(duration / 30) - 1), "periodic saves present " + label)
	phase_work.append({"label": label, "start_tick": phase_start.tick, "end_tick": observer.previous_tick,
		"devices": counts, "autosaves": saves, "autosave_ms": summary(save_ms),
		"density_sampled_each_second": observer.density.slice(phase_start.density_index)})
	_validate_work()


func _validate_work() -> void:
	var report: Dictionary = observer.report()
	driver.expect(report.errors.is_empty(), "complete live observations agree with model totals")
	driver.expect(report.max_conservative_event_gap_or_tail_seconds <= 120, "every device works in every complete 120 seconds including phase transitions")
	driver.expect(report.max_store < 200 and report.deficit_kj_total == 0, "no warehouse full or power deficit")
	driver.expect((report.end_tick - report.start_tick) * 0.05 <= 1900, "warmup and four phases fit prepared capacity horizon")


func close_world() -> void:
	_observe()
	if process_frame.is_connected(_observe): process_frame.disconnect(_observe)
	await super.close_world()


func finish() -> void:
	if finished: return
	if observer != null:
		_observe()
		write_json("workload.json", observer.report())
		if not interrupted: _validate_work()
	if process_frame.is_connected(_observe): process_frame.disconnect(_observe)
	super.finish()
	var report: Dictionary = read_json("result.json")
	report.scope = "D4-S1 engineering sustained acceptance" if mode == "sustained" else "D4-S1 headless instrumentation preflight; no foreground performance claim"
	report.sustained_acceptance = mode == "sustained" and phases.size() == 4 and not interrupted and driver.failures.is_empty()
	report.short_screening_passed = false
	report.phase_work = phase_work
	report.sampling = "Original sampler; real active wall clock, raw frames/steps and automatic-save stalls retained; read-only frame observer"
	write_json("result.json", report)
