extends SceneTree

const Model := preload("res://scripts/factory/model.gd")
const Codec := preload("res://scripts/factory/save/codec.gd")
const ID := "0123456789abcdef0123456789abcdef"
var failures: Array[String] = []
var checks := 0


func _init() -> void:
	call_deferred("_run")


func expect(condition: bool, context: String) -> void:
	checks += 1
	if not condition:
		failures.append(context)


func line(model: RefCounted, offset := Vector2i.ZERO) -> void:
	for spec in [["collector", -8, -1], ["reactor", -1, -2], ["storage", 6, -1]]:
		expect(model.place(spec[0], Vector2i(spec[1], spec[2]) + offset).ok, "place " + spec[0])
	for x in [-6, -5, -4, -3, -2, 2, 3, 4, 5]:
		expect(model.place("belt", Vector2i(x, 0) + offset).ok, "place line belt")


func _run() -> void:
	var model := Model.new()
	expect(Model.Rules.ore_sites().size() == 25, "25 resource sites")
	expect(model.kits == {"collector": 8, "reactor": 16, "storage": 8, "belt": 256}, "normal supply")
	expect(not model.place("collector", Vector2i(-7, -1)).ok, "collector must cover ore")
	expect(not model.place("reactor", Vector2i(30, 0)).ok, "map boundary")
	line(model)
	line(model, Vector2i(0, 12))
	model.advance(17.375)
	var snapshot := Codec.snapshot(model, ID, "双产线", 1)
	var decoded := Codec.decode(JSON.parse_string(JSON.stringify(snapshot, "", true, true)), ID)
	expect(decoded.ok, "in-process snapshot: " + decoded.get("reason", ""))
	if decoded.ok:
		expect(equal_state(Codec.snapshot(decoded.model, ID, "双产线", 1), snapshot), "JSON roundtrip: exact counts, time within 1e-12 seconds")
		model.advance(60)
		decoded.model.advance(60)
		expect(Codec.snapshot(decoded.model, ID, "双产线", 1) == Codec.snapshot(model, ID, "双产线", 1), "same production after load")
	var first: Dictionary = model.entity_at(Vector2i(6, -1))
	var second: Dictionary = model.entity_at(Vector2i(6, 11))
	expect(first.catalyst > 0 and first.catalyst == second.catalyst, "independent lines deliver")
	model.salvage(model.entity_at(Vector2i(-2, 0)).id)
	model.advance(90)
	var first_before: int = first.catalyst
	var second_before: int = second.catalyst
	model.advance(60)
	expect(first.catalyst == first_before and second.catalyst > second_before, "cut one line without affecting another")
	var reactor: Dictionary = model.entity_at(Vector2i(-1, -2))
	expect(model.feedback(reactor).kind == "waiting", "cut reactor actually starves")
	model.place("belt", Vector2i(-2, 0))
	model.advance(30)
	expect(first.catalyst > first_before, "same cut line recovers")
	expect(model.material_balance().equivalent == model.generated, "two-line conservation")
	var original := Codec.snapshot(model, ID, "双产线", 1)
	var malformed: Array[Dictionary] = []
	for field in ["next_id", "next_batch", "generated", "completed", "delivered"]:
		var bad: Dictionary = original.duplicate(true)
		bad.state[field] = 1.5
		malformed.append(bad)
	for mutation in [
		func(d): d.save_schema_version = 2,
		func(d): d.world_kind = "slice",
		func(d): d.ruleset_id = "future",
		func(d): d.extra = true,
		func(d): d.state.time = NAN,
		func(d): d.state.remainder = INF,
		func(d): d.state.bag.crystal = 201,
		func(d): d.state.kits.belt += 1,
		func(d): d.state.actor.x = -8.0; d.state.actor.z = -1.0,
		func(d): d.state.entities[1].id = d.state.entities[0].id,
		func(d): d.state.entities[0].x = 200,
		func(d): d.state.entities[0].buffer = 0.5,
		func(d): d.state.entities[1].input = 3,
		func(d): d.state.entities[1].processing = "yes",
		func(d): d.state.entities[3].entry = [1, 1],
		func(d): d.state.entities[3].cursor = d.state.next_id,
	]:
		var bad: Dictionary = original.duplicate(true)
		mutation.call(bad)
		malformed.append(bad)
	for i in malformed.size():
		expect(not Codec.decode(malformed[i], ID).ok, "reject malformed %d" % i)
	var before := Codec.snapshot(model, ID, "双产线", 1)
	var invalid_path: Array[Vector2i] = [Vector2i(0, 20), Vector2i(2, 20)]
	expect(not model.place_path(invalid_path).ok and Codec.snapshot(model, ID, "双产线", 1) == before, "atomic rejected path")
	var clock_model := Model.new()
	clock_model.advance(1.2, 8)
	expect(is_equal_approx(clock_model.time, 0.4) and is_equal_approx(clock_model.remainder, 0.8), "preserve long-frame remainder")
	clock_model.advance(0)
	expect(is_equal_approx(clock_model.time, 1.2) and clock_model.remainder < 1e-8, "drain backlog without lost production")
	var old_id: int = model.entity_at(Vector2i(-2, 0)).id
	model.salvage(old_id)
	var new_entity: Dictionary = model.place("belt", Vector2i(-2, 0)).entity
	expect(new_entity.id > old_id and model.by_id(old_id).is_empty(), "stable non-reused identity and removal index")
	var after := Codec.snapshot(model, ID, "双产线", 1)
	model.rebuild_indexes()
	expect(Codec.snapshot(model, ID, "双产线", 1) == after, "indexes are derived")
	print("Factory state checks: %d assertions, %d failures" % [checks, failures.size()])
	for failure in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)


func equal_state(a: Variant, b: Variant) -> bool:
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size():
			return false
		for key in a:
			if not b.has(key) or not equal_state(a[key], b[key]):
				return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size():
			return false
		for i in a.size():
			if not equal_state(a[i], b[i]):
				return false
		return true
	if a is float and b is float:
		return absf(a - b) <= 1e-12
	return a == b
