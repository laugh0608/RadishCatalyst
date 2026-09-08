extends SceneTree

const Model := preload("res://scripts/factory/model.gd")
const View := preload("res://scripts/factory/view.gd")
var failures: Array[String] = []
var checkpoints := 0
var record_root := ""


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var repo := ProjectSettings.globalize_path("res://").path_join("..").simplify_path()
	record_root = repo.path_join("tools/runtime-intake/check-runs/godot-production-line")
	var path := record_root.path_join("parity-fixtures.json")
	if not FileAccess.file_exists(path):
		push_error("Generate the Web oracle with production/verify-parity.mjs first")
		quit(1)
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(data is Dictionary)
	for scenario in data.scenarios:
		if scenario.name in ["placement and movement", "drag skips backtracks obstacles atomic commit"]:
			continue # Demo map/supply boundaries differ; formal checks cover these.
		var model := Model.new()
		var actor := {"x": -3.5, "z": 5.7, "angle": 0.0, "walk": 0.0, "moving": false}
		var index := 0
		for step in scenario.steps:
			var result := _command(model, actor, step.command)
			var actual := _snapshot(model, actor, result)
			var expected: Dictionary = step.expected.duplicate(true)
			_normalize(expected, false)
			_normalize(actual, true)
			var mismatch := _compare(expected, actual, "state")
			checkpoints += 1
			if not mismatch.is_empty():
				failures.append("%s step %d (%s): %s" % [scenario.name, index, step.command.op, mismatch])
				break
			var balance := model.material_balance()
			if balance.generated != balance.equivalent:
				failures.append("Material conservation: " + scenario.name)
				break
			for type in Model.INITIAL_KITS:
				if model.kits[type] + model.entities.filter(func(e): return e.type == type).size() != Model.INITIAL_KITS[type]:
					failures.append("Kit conservation: " + scenario.name)
			index += 1
	for curve in data.curves:
		var p := View.travel_position(Model.DIRS[int(curve.entry)], int(curve.dir), curve.progress)
		var expected := Vector2(curve.position[0], curve.position[1])
		checkpoints += 1
		if p.distance_to(expected) > 0.000001:
			failures.append("Curve position mismatch: " + str(curve))
	var file := FileAccess.open(record_root.path_join("../factory-foundation-v1/parity-result.json").simplify_path(), FileAccess.WRITE)
	if file == null:
		failures.append("Unable to write model result")
	else:
		file.store_string(JSON.stringify({"checkpoints": checkpoints, "scenarios": data.scenarios.size() - 2, "failures": failures,
			"scope": "8 unchanged Web production scenarios, 40 curves; omit Demo-only boundary/tutorial and normalize approved supply, dirty revision and batch identity semantics"}, "\t") + "\n")
		file.close()
	print("Formal factory Web parity: %d checkpoints, %d failures" % [checkpoints, failures.size()])
	for failure in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _command(model: RefCounted, actor: Dictionary, c: Dictionary) -> Dictionary:
	var result := {"ok": true}
	var cell := Vector2i(c.get("x", 0), c.get("z", 0))
	var entity: Dictionary = model.entity_at(cell)
	var id: int = entity.get("id", -1)
	match c.op:
		"place": result = model.place(c.type, cell, int(c.get("dir", 0)), c.get("actor"))
		"advance": model.advance(c.seconds)
		"salvage": result = model.salvage(id)
		"deposit": result = model.deposit(id)
		"rotate": result = model.rotate(id)
		"path": result = model.place_path(_path(c.path), int(c.get("dir", 0)))
		"preview":
			result = model.extend_path(_path(c.path), cell)
			var path := []
			for point in result.path:
				path.append([point.x, point.y])
			result.path = path
		"fixture":
			if c.has("bag"):
				model.generated += int(c.bag.crystal + 2 * c.bag.catalyst - model.bag.crystal - 2 * model.bag.catalyst)
				model.bag = c.bag.duplicate()
			if c.has("entity"):
				entity.merge(c.entity, true)
				if c.entity.has("cargo") and not c.entity.cargo.is_empty():
					model.generated += 2 if c.entity.cargo == "catalyst" else 1
			if c.has("actor"):
				actor.merge(c.actor, true)
		"feed":
			for source in c.sources:
				var e: Dictionary = model.entity_at(Vector2i(source[0], source[1]))
				if e.cargo.is_empty():
					e.cargo = "crystal"
					e.progress = 0.0
					model.generated += 1
		"move": model.move_actor(actor, c.dx, c.dz, c.dt)
		_: assert(false, "Unknown parity command: " + c.op)
	var filtered := {"ok": result.ok}
	for key in ["reason", "path", "amount", "items", "type"]:
		if result.has(key):
			filtered[key] = result[key]
	return filtered


func _path(source: Array) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	for point in source:
		path.append(Vector2i(point[0], point[1]))
	return path


func _snapshot(model: RefCounted, actor: Dictionary, result: Dictionary) -> Dictionary:
	var entities := []
	var connected := []
	for e in model.entities:
		var copy: Dictionary = e.duplicate()
		if e.type == "reactor":
			copy.output_batch = e.get("output_batch", 0)
			connected.append(model.input_connected(e))
		if e.type == "belt":
			copy.entry = [e.entry.x, e.entry.y]
			copy.batch = e.get("batch", 0)
			copy.inputs = model.belt_inputs(e)
		copy.feedback = model.feedback(e)
		copy.contents = Model.contents(e)
		entities.append(copy)
	return {"entities": entities, "kits": model.kits.duplicate(), "bag": model.bag, "next_id": model.next_id,
		"revision": model.revision, "time": model.time, "remainder": model.remainder,
		"generated": model.generated, "completed": model.completed, "delivered": model.delivered,

		"balance": model.material_balance(), "connected": connected, "actor": actor, "result": result}


func _compare(expected: Variant, actual: Variant, path: String) -> String:
	if expected is Dictionary and actual is Dictionary:
		if expected.size() != actual.size():
			return path + " keys: " + str(expected.keys()) + " != " + str(actual.keys())
		for key in expected:
			if not actual.has(key):
				return path + " missing " + key
			var diff := _compare(expected[key], actual[key], path + "." + key)
			if not diff.is_empty():
				return diff
	elif expected is Array and actual is Array:
		if expected.size() != actual.size():
			return path + " length " + str(expected.size()) + " != " + str(actual.size())
		for i in expected.size():
			var diff := _compare(expected[i], actual[i], path + "[%d]" % i)
			if not diff.is_empty():
				return diff
	elif (expected is int or expected is float) and (actual is int or actual is float):
		if absf(float(expected) - float(actual)) > 0.00001:
			return path + ": " + str(expected) + " != " + str(actual)
	elif expected != actual:
		return path + ": " + str(expected) + " != " + str(actual)
	return ""


func _normalize(state: Dictionary, formal: bool) -> void:
	state.erase("lesson")
	state.erase("revision")
	state.erase("delivered_batch")
	if formal:
		for type in state.kits:
			state.kits[type] -= Model.INITIAL_KITS[type] - (24 if type == "belt" else 1)
	for e in state.entities:
		# Formal batches are allocated at start; salvaged batches are never reused.
		# The oracle allocates at completion. Compare physical state here.
		e.erase("active_batch")
		e.erase("output_batch")
		e.erase("batch")
