extends RefCounted

## Shared V4/V5 command and recovery cases; only the matrix injects cargo.
const Codec := preload("res://scripts/factory/save/codec.gd")
const Compare := preload("res://scripts/checks/factory_discovery_check.gd")
const ID := "abababababababababababababababab"
const CELL := Vector2i(-12, -5)


static func snapshot(model: RefCounted) -> Dictionary:
	return Codec.snapshot(model, ID, "物流附件原位改装", 1)


static func state(model: RefCounted) -> Dictionary:
	return {"snapshot": snapshot(model), "revision": model.revision,
		"occupancy": model.occupancy.duplicate(true), "instances": model.instances.duplicate(true),
		"inputs": model.input_sides.duplicate(true)}


static func run(check: SceneTree, model_script: Script) -> void:
	var probe: RefCounted = model_script.new()
	var types := ["splitter", "merger", "admission_gate"] if probe.kits.has("admission_gate") else ["splitter", "merger"]
	for type in types:
		for dir in 4:
			for cargo in ["", "crystal", "catalyst", "crust_solvent", "rich_crystal"]:
				_matrix(check, model_script, type, dir, cargo)
		_failures(check, model_script, type)
		_natural_save(check, model_script, type)
	var legacy := preload("res://scripts/factory/discovery_model.gd").new(true)
	legacy.place("belt", CELL)
	var before := state(legacy)
	check.expect(not legacy.place("splitter", CELL).ok and state(legacy) == before, "replacement: legacy supply cannot gain routing components")


static func _matrix(check: SceneTree, script: Script, type: String, dir: int, cargo: String) -> void:
	var model: RefCounted = script.new()
	var belt: Dictionary = model.place("belt", CELL, dir).entity
	belt.cargo = cargo
	belt.progress = 0.45 if not cargo.is_empty() else 0.0
	belt.batch = 1 if cargo in ["catalyst", "crust_solvent"] else 0
	var label := "replacement %s/%d/%s: " % [type, dir, cargo]
	var before := state(model)
	if not cargo.is_empty():
		check.expect(not model.placement(type, CELL).ok and not model.place(type, CELL).ok and state(model) == before, label + "remote material recovery is rejected atomically")
	model.actor.x = CELL.x + 0.5
	model.actor.z = CELL.y + 2
	before = state(model)
	var held: Dictionary = model.material_balance().held
	check.expect(model.placement(type, CELL).ok and model.placement_direction(type, CELL) == dir, label + "preview inherits belt heading")
	check.expect(state(model) == before, label + "preview is read-only")
	var result: Dictionary = model.place(type, CELL)
	check.expect(result.ok, label + "commit succeeds")
	if not result.ok: return
	var e: Dictionary = result.entity
	check.expect(e.type == type and e.dir == dir and e.id != belt.id and model.by_id(belt.id).is_empty(), label + "fresh identity replaces old belt")
	check.expect(model.entities.size() == 1 and model.entity_at(CELL).id == e.id and not model.input_sides.has(belt.id), label + "spatial and transport indexes updated")
	check.expect(model.kits[type] == 7 and model.kits.belt == 256, label + "one attachment consumed and belt refunded")
	check.expect(model.material_balance().held == held and model.bag == ({} if cargo.is_empty() else {cargo: 1}), label + "all material recovered without loss")
	check.expect(e.cargo == "" and e.progress == 0 and e.batch == 0, label + "new slot has no inherited transit")
	check.expect(snapshot(model).state.statistics == before.snapshot.state.statistics, label + "production and delivery accounting unchanged")
	check.expect(model.revision == before.revision + 1 and model.next_id == before.snapshot.state.next_id + 1, label + "single committed world revision")
	if type == "admission_gate":
		check.expect(e.filter_item == "" and not e.accepting and e.quota_used == 0, label + "gate cannot inherit unfiltered cargo")
	else:
		check.expect(e["output_cursor" if type == "splitter" else "input_cursor"] == 0, label + "new routing cursor")


static func _failures(check: SceneTree, script: Script, type: String) -> void:
	var model: RefCounted = script.new()
	var belt: Dictionary = model.place("belt", CELL, 2).entity
	belt.cargo = "crystal"
	belt.progress = 0.75
	model.bag = {"crystal": 200}
	var before := state(model)
	check.expect(not model.placement(type, CELL).ok and not model.place(type, CELL).ok and state(model) == before, "replacement %s: full bag rejects loaded belt atomically" % type)
	belt.cargo = ""
	belt.progress = 0.0
	check.expect(model.place(type, CELL, 3).ok and model.entity_at(CELL).dir == 3, "replacement %s: full bag permits empty belt and explicit heading" % type)
	before = state(model)
	check.expect(not model.place(type, CELL).ok and not model.place("belt", CELL).ok and state(model) == before, "replacement %s: attachments cannot be overwritten in either direction" % type)
	model = script.new()
	belt = model.place("belt", CELL).entity
	for dir in [-2, 4]:
		before = state(model)
		check.expect(not model.place(type, CELL, dir).ok and state(model) == before, "replacement %s: invalid heading %d preserves belt" % [type, dir])
	model.kits[type] = 0
	before = state(model)
	check.expect(not model.place(type, CELL).ok and state(model) == before, "replacement %s: missing kit has no mutation" % type)
	model.kits[type] = 8
	var actor := {"x": CELL.x + 0.5, "z": CELL.y + 0.5}
	before = state(model)
	check.expect(not model.placement(type, CELL, actor).ok and not model.place(type, CELL, 0, actor).ok and state(model) == before, "replacement %s: actor collision preserves belt" % type)
	model.place("storage", Vector2i(-8, -5))
	before = state(model)
	check.expect(not model.place(type, Vector2i(-8, -5)).ok and state(model) == before, "replacement %s: machine cannot be overwritten" % type)
	check.expect(not model.place(type, Vector2i(40, 40)).ok and state(model) == before, "replacement %s: map boundary unchanged" % type)
	check.expect(not model.place(type, Vector2i(10, 0)).ok and state(model) == before, "replacement %s: unopened mineral barrier unchanged" % type)
	# Hover can be legal and later become invalid while production continues.
	check.expect(model.placement(type, CELL).ok, "replacement %s: empty preview starts valid" % type)
	belt.cargo = "crystal"
	model.bag = {"crystal": 200}
	before = state(model)
	check.expect(not model.place(type, CELL).ok and state(model) == before, "replacement %s: commit revalidates cargo/capacity after preview" % type)
	model.bag = {}
	model.salvage(belt.id)
	var occupied: Dictionary = model.place("merger", CELL).entity
	before = state(model)
	check.expect(not model.place(type, CELL).ok and model.entity_at(CELL).id == occupied.id and state(model) == before, "replacement %s: changed occupant cannot be silently removed" % type)


static func _natural_save(check: SceneTree, script: Script, type: String) -> void:
	var model: RefCounted = script.new()
	model.place("collector", Vector2i(-20, -1))
	var cell := Vector2i(-18, 0)
	model.place("belt", cell)
	model.place("belt", Vector2i(-17, 0))
	model.place("storage", Vector2i(-16, -1))
	model.place("power_source", Vector2i(-22, -5))
	model.advance(1.5)
	check.expect(model.entity_at(cell).cargo == "crystal" and Codec.decode(snapshot(model), ID).ok, "replacement %s: naturally produced loaded belt is strictly valid" % type)
	model.actor.x = -18
	model.actor.z = 2
	var before: Dictionary = model.material_balance().held
	var result: Dictionary = model.place(type, cell)
	check.expect(result.ok and model.material_balance().held == before, "replacement %s: natural material conservation" % type)
	if not result.ok: return
	if type == "admission_gate":
		model.actor.x = -18
		model.actor.z = 2
		check.expect(model.configure_admission(result.entity.id, "crystal", "unlimited", 0).ok and model.set_admission_accepting(result.entity.id, true).ok, "replacement: new gate can be explicitly configured and enabled")
	var doc := snapshot(model)
	var decoded := Codec.decode(doc, ID)
	check.expect(decoded.ok, "replacement %s: strict save immediately after replacement" % type)
	if not decoded.ok: return
	_write(check, "replacement-" + type + "-start.json", doc)
	model.advance(6.0)
	decoded.model.advance(6.0)
	check.expect(Compare.equivalent(snapshot(model), snapshot(decoded.model)), "replacement %s: restored neighbor arbitration and transport match" % type)
	check.expect(model.entity_at(Vector2i(-16, -1)).items.get("crystal", 0) > 0, "replacement %s: rebuilt neighbors keep delivering naturally" % type)
	_write(check, "replacement-" + type + "-expected.json", snapshot(model))


static func restore(check: SceneTree, model_script: Script) -> void:
	var probe: RefCounted = model_script.new()
	var types := ["splitter", "merger", "admission_gate"] if probe.kits.has("admission_gate") else ["splitter", "merger"]
	for type in types:
		var path: String = check.evidence.path_join("replacement-" + type + "-start.json")
		if not FileAccess.file_exists(path):
			check.expect(false, "replacement: missing source " + type)
			continue
		var loaded := Codec.decode(JSON.parse_string(FileAccess.get_file_as_string(path)), ID)
		check.expect(loaded.ok, "replacement %s: independent process strictly restores" % type)
		if not loaded.ok: continue
		loaded.model.advance(6.0)
		var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(check.evidence.path_join("replacement-" + type + "-expected.json")))
		check.expect(Compare.equivalent(snapshot(loaded.model), expected), "replacement %s: independent process continues identical production" % type)


static func _write(check: SceneTree, name: String, value: Dictionary) -> void:
	var file := FileAccess.open(check.evidence.path_join(name), FileAccess.WRITE)
	check.expect(file != null, "replacement: evidence file " + name)
	if file != null:
		file.store_string(JSON.stringify(value, "\t"))
		file.close()
