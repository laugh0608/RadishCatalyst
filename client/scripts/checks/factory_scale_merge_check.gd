extends SceneTree

const Fixture := preload("res://scripts/checks/factory_load_fixture.gd")
const Model := Fixture.Model
const Codec := preload("res://scripts/factory/save/codec.gd")
var failures: Array[String] = []
var checks := 0


func _init() -> void:
	call_deferred("_run")


func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)


func _run() -> void:
	var built := Fixture.build()
	expect(built.ok, "build engineering fixture with formal commands")
	if not built.ok:
		_finish({})
		return
	var model: RefCounted = built.model
	# 将第二列最上方矿点的出料接到第一列输入带；其原有带全部拆回。
	for e in model.entities.duplicate():
		if e.type == "belt" and e.x >= -20 and e.x <= -9 and e.z >= -28 and e.z <= -17:
			expect(model.salvage(e.id).ok, "remove unused source-line belt")
	expect(model.kits.belt == 40, "reroute exactly one forty-belt line")
	var route := Fixture.route([Vector2i(-18, -24), Vector2i(-18, -23), Vector2i(-17, -23),
		Vector2i(-17, -30), Vector2i(-27, -30), Vector2i(-27, -29)])
	var directions := Model.path_directions(route, 1)
	directions[-1] = 1
	for i in route.size():
		expect(model.place("belt", route[i], directions[i]).ok, "ore-fed merge route " + str(route[i]))
	var spare_count: int = model.kits.belt
	for i in spare_count:
		expect(model.place("belt", Vector2i(-32 + i, -32)).ok, "boundary spare belt")
	expect(model.entities.size() == 1100 and model.kits.belt == 0, "maintain 100 machines and 1000 belts")
	var target: Dictionary = model.entity_at(Vector2i(-27, -28))
	var west: Dictionary = model.entity_at(Vector2i(-28, -28))
	var north: Dictionary = model.entity_at(Vector2i(-27, -29))
	var winners := {west.id: 0, north.id: 0}
	var deliveries := {west.id: 0, north.id: 0}
	var contested := 0
	for tick in 6000:
		var was_empty: bool = target.cargo.is_empty()
		var both_ready: bool = was_empty and not west.cargo.is_empty() and not north.cargo.is_empty() and west.progress >= 0.95 - 1e-9 and north.progress >= 0.95 - 1e-9
		var expected: int = north.id if target.cursor >= west.id and target.cursor < north.id else west.id
		model.advance(Model.STEP)
		if was_empty and not target.cargo.is_empty():
			deliveries[target.cursor] += 1
		if both_ready:
			contested += 1
			expect(target.cursor == expected, "round-robin winner during actual contention")
			winners[target.cursor] += 1
		if tick % 100 == 0:
			expect(model.material_balance().equivalent == model.generated, "large merge conserves material")
	expect(contested >= 10 and winners[west.id] > 0 and winners[north.id] > 0, "both real ore sources win contention")
	expect(deliveries[west.id] > 0 and deliveries[north.id] > 0, "both sources actually feed shared route")
	expect(model.entity_at(Vector2i(-23, -21)).catalyst > 0, "shared reactor delivers catalyst")
	# 场坪边界上的构件可拆回 / 重建，越界命令必须原子拒绝。
	var edge: Dictionary = model.entity_at(Vector2i(-32, -32))
	expect(model.salvage(edge.id).ok, "salvage legal boundary cell")
	var before := Codec.snapshot(model, "0123456789abcdef0123456789abcdef", "规模汇流", 1)
	for cell in [Vector2i(-33, -32), Vector2i(32, 0), Vector2i(0, 32), Vector2i(0, -33)]:
		expect(not model.place("belt", cell).ok, "reject outside map " + str(cell))
	expect(Codec.snapshot(model, before.world_id, before.name, 1) == before, "rejected edge commands preserve full state")
	expect(model.place("belt", Vector2i(-32, -32)).ok, "rebuild legal boundary cell")
	var snapshot := Codec.snapshot(model, before.world_id, before.name, 1)
	expect(Codec.decode(snapshot, before.world_id).ok, "merged scale state remains saveable")
	var base := SliceCheckPaths.check_run("factory-foundation-v1", false)
	var file := FileAccess.open(base.path_join("scale-merge-state.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(snapshot, "", true, true))
	file.close()
	_finish({"entities": model.entities.size(), "seconds": model.time, "contested": contested,
		"wins": winners, "deliveries_to_merge": deliveries, "disconnected_spare_belts": spare_count,
		"description": "100 machines / 1000 belts; two real ore sources share one input; one original line disconnected; spare belts on map edge"})


func _finish(observations: Dictionary) -> void:
	var base := SliceCheckPaths.check_run("factory-foundation-v1", false)
	var file := FileAccess.open(base.path_join("scale-merge-result.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"assertions": checks, "failures": failures, "observations": observations}, "\t"))
	file.close()
	print("Factory scale merge: %d assertions, %d failures" % [checks, failures.size()])
	for failure in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)
