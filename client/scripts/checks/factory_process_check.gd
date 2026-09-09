extends SceneTree

const Store := preload("res://scripts/factory/save/store.gd")
const Codec := Store.Codec
var root_path := ""
var phase := ""
var failures: Array[String] = []
var checks := 0
var scale := false


func _init() -> void:
	call_deferred("_run")


func expect(condition: bool, label: String) -> void:
	checks += 1
	if not condition:
		failures.append(label)


func write_json(path: String, value: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(value, "", true, true))
	file.close()


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--scale":
			scale = true
		if arg.begins_with("--phase="):
			phase = arg.trim_prefix("--phase=")
		if arg.begins_with("--batch="):
			var batch := arg.trim_prefix("--batch=")
			assert(batch.is_valid_filename() and not ".." in batch)
			root_path = SliceCheckPaths.check_run("factory-foundation-v1", false).path_join(batch)
	assert(not root_path.is_empty())
	match phase:
		"write":
			if scale:
				_write_scale_world()
			else:
				_write_world()
		"read": _read_world()
		"hold":
			var store := Store.new(root_path.path_join("lock"))
			var result := store.create("跨进程独占")
			expect(result.ok, "create lock owner")
			write_json(root_path.path_join("lock-owner.json"), {"id": store.world_id, "pid": OS.get_process_id()})
			# Leave the process alive for a concurrent probe, then exit without release.
			print("Factory lock holder ready")
			await create_timer(15).timeout
		"probe", "recover":
			var info: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(root_path.path_join("lock-owner.json")))
			var store := Store.new(root_path.path_join("lock"))
			expect(not store.prepare(info.id).ok, "existing lock blocks new writer")
			var recovered := store.recover_stale_lock(info.id)
			expect(recovered.ok == (phase == "recover"), "recover only after owner process exits: " + recovered.get("reason", ""))
			if recovered.ok:
				var candidate := store.prepare(info.id)
				expect(candidate.ok and store.accept(candidate).ok, "new writer after explicit stale recovery")
				store.release()
		_: expect(false, "unknown phase")
	write_json(root_path.path_join(phase + "-result.json"), {"assertions": checks, "failures": failures, "scale": scale})
	print("Factory process %s: %d assertions, %d failures" % [phase, checks, failures.size()])
	for failure in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)


func _write_world() -> void:
	var store := Store.new(root_path.path_join("worlds"))
	var created := store.create("跨进程半批与转角")
	expect(created.ok, "create persistence world")
	if not created.ok:
		return
	var model: RefCounted = created.model
	for spec in [["collector", -8, -1], ["reactor", -1, -2], ["storage", 6, -1]]:
		expect(model.place(spec[0], Vector2i(spec[1], spec[2])).ok, "build machine")
	for x in [-6, -5, -4, -3, -2]:
		expect(model.place("belt", Vector2i(x, 0)).ok, "build input")
	var path: Array[Vector2i] = [Vector2i(2, 0), Vector2i(2, 1), Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(4, 1), Vector2i(4, 0), Vector2i(5, 0)]
	expect(model.place_path(path).ok, "build curved route")
	model.advance(20.375)
	expect(model.entity_at(Vector2i(-1, -2)).processing, "in-process reactor fixture")
	expect(model.entities.any(func(e): return e.type == "belt" and e.cargo == "catalyst"), "cargo fixture")
	var recovered: Dictionary = model.salvage(model.entity_at(Vector2i(-4, 0)).id)
	expect(recovered.ok and model.bag.crystal > 0, "recycled cargo fixture")
	var before: Dictionary = Codec.snapshot(model, store.world_id, store.world_name, 1)
	expect(store.save(model).ok, "save in-flight state")
	write_json(root_path.path_join("expected-before.json"), before)
	model.advance(87.25)
	write_json(root_path.path_join("expected-after.json"), Codec.snapshot(model, store.world_id, store.world_name, 1))
	write_json(root_path.path_join("world.json"), {"id": store.world_id})
	store.release()


func _write_scale_world() -> void:
	var base := SliceCheckPaths.check_run("factory-foundation-v1", false)
	var document: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(base.path_join("scale-full-state.json")))
	var decoded := Codec.decode(document, document.world_id)
	expect(decoded.ok, "validate real-rule full-scale fixture")
	if not decoded.ok:
		return
	var model: RefCounted = decoded.model
	expect(model.entities.size() == 1100, "100 machines and 1000 belts")
	expect(model.entities.filter(func(e): return e.type == "belt" and not e.cargo.is_empty()).size() == 1000, "1000 carried items")
	var store := Store.new(root_path.path_join("worlds"))
	expect(store.create("满载跨进程", Codec.Rules.ENGINEERING_SUPPLY).ok, "create isolated engineering save")
	expect(store.save(model).ok, "save full-scale state")
	write_json(root_path.path_join("expected-before.json"), Codec.snapshot(model, store.world_id, store.world_name, 1))
	# 两个进程执行相同真实拆改，验证恢复后的拓扑与继续推进。
	_scale_edits(model)
	model.advance(87.25)
	write_json(root_path.path_join("expected-after.json"), Codec.snapshot(model, store.world_id, store.world_name, 1))
	write_json(root_path.path_join("world.json"), {"id": store.world_id})
	store.release()


func _scale_edits(model: RefCounted) -> void:
	for ore in Codec.Rules.ore_sites():
		var cell: Vector2i = ore + Vector2i(3, 1)
		var entity: Dictionary = model.entity_at(cell)
		var old_id: int = entity.id
		var direction: int = entity.dir
		expect(model.salvage(old_id).ok, "recover loaded belt " + str(cell))
		expect(model.by_id(old_id).is_empty() and not model.input_sides.has(old_id), "remove old index " + str(cell))
		var placed: Dictionary = model.place("belt", cell, direction)
		expect(placed.ok and placed.entity.id > old_id, "replace with fresh identity " + str(cell))
		model.advance(0.1)
		expect(model.entities.size() == 1100 and model.material_balance().equivalent == model.generated, "scale edit preserves kits and material " + str(cell))
	var before: Dictionary = Codec.snapshot(model, "0123456789abcdef0123456789abcdef", "索引复核", 1)
	var occupancy: Dictionary = model.occupancy.duplicate(true)
	var neighbors: Dictionary = model.input_sides.duplicate(true)
	model.rebuild_indexes()
	expect(model.occupancy == occupancy and model.input_sides == neighbors, "incremental indexes agree with reconstruction")
	expect(Codec.snapshot(model, "0123456789abcdef0123456789abcdef", "索引复核", 1) == before, "index rebuild does not change authoritative state")


func _read_world() -> void:
	var info: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(root_path.path_join("world.json")))
	var store := Store.new(root_path.path_join("worlds"))
	var candidate := store.prepare(info.id)
	expect(candidate.ok, "independent process decodes state")
	if not candidate.ok:
		return
	expect(store.accept(candidate).ok, "independent process accepts reconstructed candidate")
	var before: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(root_path.path_join("expected-before.json")))
	var after: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(root_path.path_join("expected-after.json")))
	var model: RefCounted = candidate.model
	expect(_equal(Codec.snapshot(model, store.world_id, store.world_name, 1), before), "all fields survive process exit")
	if scale:
		_scale_edits(model)
	model.advance(87.25)
	expect(_equal(Codec.snapshot(model, store.world_id, store.world_name, 1), after), "future trajectory matches uninterrupted process")
	expect(store.save(model).ok, "save again in new process")
	store.release()


func _equal(a: Variant, b: Variant) -> bool:
	if a is Dictionary and b is Dictionary:
		if a.size() != b.size():
			return false
		for key in a:
			if not b.has(key) or not _equal(a[key], b[key]):
				return false
		return true
	if a is Array and b is Array:
		if a.size() != b.size():
			return false
		for i in a.size():
			if not _equal(a[i], b[i]):
				return false
		return true
	if a is float and b is float:
		return absf(a - b) <= 1e-12
	return a == b
