extends "res://scripts/checks/factory_engineering_check.gd"

const Preparation := preload("res://scripts/checks/factory_engineering_preparation.gd")
const Observer := preload("res://scripts/checks/factory_engineering_observer.gd")
var engineering_id := ""
var save_sequence := 1


func doc(model: RefCounted) -> Dictionary:
	return Codec.snapshot(model, engineering_id, "工程规模验证 · 持续生产", save_sequence)


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	if evidence.is_empty(): quit(2); return
	if "--read" in OS.get_cmdline_user_args():
		_read_prepared()
		return
	var store := Store.new(evidence.path_join("worlds"), true)
	var created := store.create("工程规模验证 · 持续生产", Config.SUPPLY_ID, true)
	expect(created.ok, "fresh isolated engineering world")
	if not created.ok:
		quit(1)
		return
	engineering_id = store.world_id
	var preparation := Preparation.new(self)
	preparation.model = created.model
	var result := {"mode": "prepare", "ready": false}
	var prelude_ok := preparation.prelude()
	result.prelude_ok = prelude_ok
	result.prelude_state = doc(preparation.model)
	if prelude_ok and failures.is_empty() and preparation.full_layout():
		result.geometry = preparation.audit()
		result.full_layout_start_tick = preparation.model.statistics.ticks
		write_json(evidence.path_join("full-layout-start.json"), doc(preparation.model))
		if failures.is_empty():
			var observer := Observer.new(preparation.model)
			result.preparation = observer.advance(12000)
			observer.assert_work(self, "600-second preparation")
			for index in 20:
				for key in ["branch_feed", "branch_bypass", "merge_solvent", "merge_bypass"]:
					expect(observer.counts[index][key] > 0, "actual transfer both branches / merge inputs %d %s" % [index, key])
			preparation.model.statistics_ui.window_seconds = 600
			var snapshot := doc(preparation.model)
			var decoded := Codec.decode(snapshot, engineering_id)
			expect(decoded.ok, "strict prepared engineering decode: " + decoded.get("reason", ""))
			expect(preparation.model.statistics.buckets.size() == 600, "complete 600-second history")
			var saved := store.save(preparation.model)
			expect(saved.ok, "formal Store publishes prepared engineering snapshot: " + saved.get("reason", ""))
			save_sequence = store.sequence
			write_json(evidence.path_join("source.json"), doc(preparation.model))
			if decoded.ok:
				decoded.model.advance(1, 20)
				write_json(evidence.path_join("continuation.json"), doc(decoded.model))
			result.ready = failures.is_empty()
	expect(store.release().ok, "prepared world releases session lock")
	write_json(evidence.path_join("commands.json"), preparation.commands)
	result.assertions = assertions
	result.failures = failures
	result.scope = "S0-B explicit model construction/movement/production; no actor, cargo, research or statistics injection. Movement preparation does not advance production. Not foreground performance."
	write_json(evidence.path_join("result.json"), result)
	print("Engineering preparation: %d assertions, %d failures" % [assertions, failures.size()])
	quit(0 if failures.is_empty() and result.ready else 1)


func _read_prepared() -> void:
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("source.json")))
	engineering_id = source.world_id
	save_sequence = int(source.sequence)
	var restored := Codec.decode(source, engineering_id)
	expect(restored.ok, "independent prepared engineering decode")
	if restored.ok:
		expect(Compare.equivalent(source, doc(restored.model)), "prepared exact first state")
		restored.model.advance(1, 20)
		var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("continuation.json")))
		expect(Compare.equivalent(expected, doc(restored.model)), "prepared exact 20-step trajectory")
	write_json(evidence.path_join("result.json"), {"mode": "prepare-read", "assertions": assertions, "failures": failures})
	print("Engineering preparation restore: %d assertions, %d failures" % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)
