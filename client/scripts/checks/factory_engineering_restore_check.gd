extends "res://scripts/checks/factory_engineering_prepare_check.gd"


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	if evidence.is_empty(): quit(2); return
	var inputs: Array = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("selected-inputs.json")))
	var checkpoints := []
	DirAccess.make_dir_recursive_absolute(evidence.path_join("checkpoints"))
	for name in inputs:
		var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("inputs").path_join(name)))
		engineering_id = source.world_id
		save_sequence = int(source.sequence)
		var restored := Codec.decode(source, engineering_id)
		expect(restored.ok and Config.matches(source), "strict engineering checkpoint " + name)
		if not restored.ok: continue
		expect(Compare.equivalent(source, doc(restored.model)), "complete checkpoint round trip " + name)
		write_json(evidence.path_join("checkpoints").path_join(name), source)
		restored.model.advance(1, 20)
		var expected := doc(restored.model)
		expect(Codec.decode(expected, engineering_id).ok, "strict 20-step checkpoint continuation " + name)
		var future: String = name.trim_suffix(".json") + "-continued.json"
		write_json(evidence.path_join("checkpoints").path_join(future), expected)
		checkpoints.append({"source": name, "continuation": future})
	write_json(evidence.path_join("checkpoints.json"), checkpoints)
	write_json(evidence.path_join("result.json"), {"mode": "checkpoint-write", "assertions": assertions,
		"failures": failures, "scope": "Independent explicit 20-step expected trajectories, no performance claim"})
	print("Engineering checkpoint trajectories: %d assertions, %d failures" % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)
