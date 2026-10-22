extends "res://scripts/checks/factory_engineering_prepare_check.gd"

const Live := preload("res://scripts/checks/factory_engineering_live_observer.gd")


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	if evidence.is_empty(): quit(2); return
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("source.json")))
	var restored := Codec.decode(source, source.world_id)
	expect(restored.ok, "strict prepared world")
	if not restored.ok: quit(1); return
	var model: RefCounted = restored.model
	var exact := Observer.new(model)
	var live := Live.new(model)
	# Simulate varying frame batches, including the application's eight-step catch-up.
	for index in 600:
		exact.advance(index % 8 + 1)
		live.observe()
	var report := live.report().duplicate(true)
	expect(report.errors.is_empty(), "bounded frame observations reconcile without gaps")
	for row in live.devices:
		expect(row.count == exact.counts[row.cell][row.name], "per-device frame/step counts agree %d" % row.id)
	expect(report.max_conservative_event_gap_or_tail_seconds <= 120, "conservative rolling coverage")
	expect(report.max_observation_gap_seconds <= 0.4, "eight-step catch-up remains observable")
	var unchanged := Codec.snapshot(model, source.world_id, source.name, int(source.sequence))
	live.observe()
	live.report()
	expect(Compare.equivalent(unchanged, Codec.snapshot(model, source.world_id, source.name, int(source.sequence))), "observer never changes state")
	model.advance(1.05, 21)
	live.observe()
	expect(live.errors.has("observation interval outside (0, 1] seconds"), "unobservable frame gap fails closed")
	write_json(evidence.path_join("workload.json"), report)
	write_json(evidence.path_join("result.json"), {"mode": "workload-check", "assertions": assertions, "failures": failures,
		"scope": "Explicit-step instrumentation validation; not performance"})
	print("Live workload observer: %d assertions, %d failures" % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)
