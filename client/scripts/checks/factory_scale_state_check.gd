extends SceneTree

const Fixture := preload("res://scripts/checks/factory_load_fixture.gd")
const Codec := preload("res://scripts/factory/save/codec.gd")


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var fixture := Fixture.build()
	if not fixture.ok:
		push_error(fixture.reason)
		quit(1)
		return
	var model: RefCounted = fixture.model
	assert(model.entities.size() == 1100)
	assert(model.kits == {"collector": 0, "reactor": 0, "storage": 0, "belt": 0})
	model.measure_steps = true
	var before := Time.get_ticks_usec()
	model.advance(3000, 60000)
	var elapsed := (Time.get_ticks_usec() - before) / 1000000.0
	var cargo := 0
	var machines := {}
	for e in model.entities:
		if e.type == "belt":
			cargo += 0 if e.cargo.is_empty() else 1
		else:
			var label: String = model.feedback(e).kind
			machines[label] = machines.get(label, 0) + 1
	var document := Codec.snapshot(model, "0123456789abcdef0123456789abcdef", "首档满载夹具", 1)
	var valid := Codec.decode(document, document.world_id)
	if not valid.ok:
		push_error(valid.reason)
		quit(1)
		return
	assert(model.material_balance().equivalent == model.generated)
	assert(cargo == 1000, "Full real-rule in-transit capacity")
	model.step_samples.sort()
	var result := {"fixture": fixture.description, "entities": model.entities.size(), "cargo": cargo,
		"machine_states": machines, "simulation_seconds": model.time, "wall_seconds": elapsed,
		"simulation_step_ms": {"p95": model.step_samples[int(model.step_samples.size() * 0.95)], "max": model.step_samples.back()}}
	var run_root := SliceCheckPaths.check_run("factory-foundation-v1", false)
	var file := FileAccess.open(run_root.path_join("scale-full-state.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(document, "", true, true))
	file.close()
	file = FileAccess.open(run_root.path_join("scale-state-result.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("Factory scale state passed: ", JSON.stringify(result))
	quit(0)
