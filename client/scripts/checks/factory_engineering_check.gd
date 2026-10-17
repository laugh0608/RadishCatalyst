extends SceneTree

const Model := preload("res://scripts/factory/engineering_model.gd")
const Config := preload("res://data/factory/engineering_rules.gd")
const Rules := preload("res://data/factory/discovery_rules.gd")
const Codec := preload("res://scripts/factory/save/codec.gd")
const Store := preload("res://scripts/factory/save/store.gd")
const Compare := preload("res://scripts/checks/factory_discovery_check.gd")
const ID := "edededededededededededededededed"
var evidence := ""
var assertions := 0
var failures: Array[String] = []


func _init() -> void:
	call_deferred("run")


func expect(condition: bool, label: String) -> void:
	assertions += 1
	if not condition:
		failures.append(label)
		push_error(label)


func doc(model: RefCounted) -> Dictionary:
	return Codec.snapshot(model, ID, "工程规模验证", 1)


func write_json(path: String, value: Variant) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(JSON.stringify(value, "", true, true))
	file.close()


func reject(value: Dictionary, label: String, fatal := false) -> void:
	var before := JSON.stringify(value)
	var result := Codec.decode(value, ID)
	expect(not result.ok and (not fatal or result.get("unsupported", false)) and JSON.stringify(value) == before, label)


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	if evidence.is_empty():
		quit(2)
		return
	if "--read" in OS.get_cmdline_user_args():
		var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("source.json")))
		var restored := Codec.decode(source, ID)
		expect(restored.ok, "independent process accepts engineering identity")
		if restored.ok:
			expect(Compare.equivalent(source, doc(restored.model)), "independent process exact initial state")
			restored.model.advance(1, 20)
			var expected: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join("continuation.json")))
			expect(Compare.equivalent(expected, doc(restored.model)), "independent process exact 20-step continuation")
	else:
		_identity()
		_map()
		var powered := _power()
		_store(powered)
		await _boot()
		write_json(evidence.path_join("source.json"), doc(powered))
		powered.advance(1, 20)
		write_json(evidence.path_join("continuation.json"), doc(powered))
	write_json(evidence.path_join("result.json"), {"assertions": assertions, "failures": failures, "scope": "S0-A identity/map/isolated persistence, constructed empty layouts; no preparation or performance claim"})
	print("Engineering identity: %d assertions, %d failures" % [assertions, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _identity() -> void:
	var normal := doc(Codec.V5.AdmissionModel.new())
	var engineering := doc(Model.new())
	expect(Config.matches(engineering) and Codec.decode(engineering, ID).ok, "exact engineering identity accepted")
	expect(normal.supply_id == Rules.ADMISSION_SUPPLY_ID and Codec.decode(normal, ID).ok, "ordinary V5 remains accepted")
	for base in [normal, engineering]:
		for key in ["ruleset_id", "map_id", "supply_id"]:
			for value in ["unknown", normal[key] if base == engineering else engineering[key], null]:
				var broken: Dictionary = base.duplicate(true)
				if value == null: broken.erase(key)
				else: broken[key] = value
				reject(broken, "fatal identity mismatch %s %s" % [key, str(value)], true)
	var old_reader := Codec.V2.decode_world(engineering, ID, 5, Rules.ADMISSION_RULESET_ID, Codec.V5.AdmissionModel.new())
	expect(not old_reader.ok and old_reader.get("unsupported", false), "old V5 identity contract refuses engineering")
	var disguised := normal.duplicate(true)
	disguised.state.kits = engineering.state.kits
	reject(disguised, "ordinary identity cannot claim engineering supply")
	var broken := engineering.duplicate(true)
	broken.state.kits.belt -= 1
	reject(broken, "engineering kit conservation")
	broken = engineering.duplicate(true)
	broken.state.actor.x = 32
	reject(broken, "engineering actor bounds")
	broken = engineering.duplicate(true)
	broken.save_schema_version = 6
	reject(broken, "future schema fatal", true)


func _map() -> void:
	var model := Model.new()
	var minerals := {"crystal": 0, "rich_crystal": 0}
	for cell in model.ore_sites():
		var placed: Dictionary = model.place("collector", cell)
		expect(placed.ok, "fixed ore footprint %s" % str(cell))
		if placed.ok: minerals[placed.entity.mineral] += 1
	expect(minerals == {"crystal": 10, "rich_crystal": 10}, "checkerboard mineral identity independent of x")
	expect(Codec.decode(doc(model), ID).ok, "all 20 fixed minerals survive codec")
	var broken := doc(model)
	broken.state.entities[0].mineral = "rich_crystal"
	reject(broken, "wrong mineral rejected")
	broken = doc(model)
	broken.state.entities[0].x += 1
	reject(broken, "non-ore collector rejected")
	broken = doc(model)
	broken.state.actor.x = -29.5
	broken.state.actor.z = -26.5
	reject(broken, "actor collision rejected")
	for x in [4, 8, 20, 24, 31]:
		expect(Rules.open_cell(Vector2i(x, 8), model.discovery.passages, Config.MAP_ID), "engineering ground open %d" % x)
	expect(not Rules.open_cell(Vector2i(32, 0), model.discovery.passages, Config.MAP_ID), "engineering outer boundary closed")
	expect(not Rules.open_cell(Vector2i(0, 0), model.discovery.passages, "unknown"), "unknown map closed")
	var ordinary := Codec.V5.AdmissionModel.new()
	expect(not ordinary.placement("belt", Vector2i(4, 8)).ok and model.placement("belt", Vector2i(4, 8)).ok, "ordinary mineral barrier retained")
	expect(not ordinary.Grid.line_open(Vector2(3, 8), Vector2(5, 8), ordinary.discovery.passages) and model.Grid.line_open(Vector2(3, 8), Vector2(5, 8), model.discovery.passages, model.map_id), "power line uses selected map")
	expect(not ordinary.blocked_for_actor(0, 0) and ordinary.blocked_for_actor(4.5, 8.5) and not model.blocked_for_actor(4.5, 8.5), "actor uses selected map")


func _power() -> RefCounted:
	var model := Model.new()
	for row in 5:
		for column in 8:
			expect(model.place("power_source", Vector2i(-30 + 4 * column, -30 + 4 * row)).ok, "finite source placement")
	for index in 20:
		expect(model.place("power_junction", Vector2i(-30 + index, -9)).ok, "finite junction placement")
	model.advance(0.05)
	var snapshot := doc(model)
	expect(model.power_links.size() > 91 and model.grid.groups.size() == 1, "engineering topology exceeds ordinary edge ceiling")
	expect(model.power_state().installed_kw == 4800 and model.statistics.totals.installed_kj == 240, "finite 4800 kW statistics")
	var decoded := Codec.decode(snapshot, ID)
	expect(decoded.ok and Compare.equivalent(snapshot, doc(decoded.model)), "engineering graph and statistics exact reconstruction")
	var broken := snapshot.duplicate(true)
	broken.state.power_links.pop_back()
	reject(broken, "automatic topology mismatch rejected without repair")
	broken = snapshot.duplicate(true)
	broken.state.power_links.resize(1771)
	reject(broken, "engineering graph hard ceiling")
	broken = snapshot.duplicate(true)
	broken.state.statistics.current.installed_kj = 240.01
	broken.state.statistics.totals.installed_kj = 240.01
	reject(broken, "engineering energy ceiling")
	var record := model.Statistics.record()
	record.installed_kj = 4800.0
	record.available_kj = 4800.0
	record.requested_kj = 3600.0
	record.used_kj = 3600.0
	record.supplied_kj = 3600.0
	expect(Codec.V2.Validator.valid_record(record, 1, 4800, 3600) and not Codec.V2.Validator.valid_record(record, 1), "profile upper bound does not raise ordinary ceiling")
	record.requested_kj += 1
	record.deficit_kj = 1
	expect(not Codec.V2.Validator.valid_record(record, 1, 4800, 3600), "engineering request ceiling")
	return model


func _store(model: RefCounted) -> void:
	var root_path := evidence.path_join("worlds")
	var plain := Store.new(root_path)
	expect(not plain.create("不能创建", Config.SUPPLY_ID, true).ok and not DirAccess.dir_exists_absolute(root_path), "default creation rejected before IO")
	expect(not Store.new(Store.DEFAULT_ROOT, true).allow_engineering, "production root cannot enable engineering")
	var store := Store.new(root_path, true)
	var created := store.create("工程规模验证", Config.SUPPLY_ID, true)
	expect(created.ok, "isolated engineering creation")
	if not created.ok: return
	var id: String = store.world_id
	var saved := store.save(model)
	expect(saved.ok, "engineering atomic save: " + saved.get("reason", ""))
	if not saved.ok:
		store.release()
		return
	var original := FileAccess.get_sha256(store.path("autosave.json"))
	var sequence: int = store.sequence
	for stage in ["validation", "temporary_write", "readback", "backup", "publish"]:
		store.fault = func(at): return at == stage
		expect(not store.save(model).ok and store.sequence == sequence and FileAccess.get_sha256(store.path("autosave.json")) == original, "IO fault retains main and sequence " + stage)
	store.fault = Callable()
	expect(not Store.new(root_path, true).acquire(id).ok, "exclusive session lock")
	expect(not store.save(Codec.V5.AdmissionModel.new()).ok and FileAccess.get_sha256(store.path("autosave.json")) == original, "engineering cannot save as ordinary")
	expect(store.release().ok, "engineering lock release")
	expect(not plain.prepare(id).ok and FileAccess.get_sha256(store.path("autosave.json")) == original, "default continuation refuses engineering without writing")
	var current := store.prepare(id)
	expect(current.ok and store.accept(current).ok, "isolated reconstruction acceptance")
	store.release()
	# Corrupt content retains a parseable identity; same-schema opposite identity may not recover.
	var broken: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(store.path("autosave.json")))
	broken.state.kits.belt -= 1
	write_json(store.path("autosave.json"), broken)
	var ordinary := Codec.snapshot(Codec.V5.AdmissionModel.new(), id, "普通备份", 1)
	write_json(store.path("backups/autosave.bak.1.json"), ordinary)
	var before := FileAccess.get_sha256(store.path("autosave.json"))
	var candidate := store.find_candidate(id)
	expect(not candidate.ok and candidate.get("unsupported", false) and before == FileAccess.get_sha256(store.path("autosave.json")), "same-schema cross-identity backup cannot recover")
	broken.save_schema_version = 6
	write_json(store.path("autosave.json"), broken)
	candidate = store.find_candidate(id)
	expect(not candidate.ok and candidate.get("unsupported", false), "future main cannot recover ordinary backup")


func _boot() -> void:
	var root_path := evidence.path_join("boot-worlds")
	var store := Store.new(root_path, true)
	var created := store.create("工程规模验证 · 身份与地图", Config.SUPPLY_ID, true)
	expect(created.ok, "Boot isolated engineering source")
	if not created.ok: return
	var original := FileAccess.get_sha256(store.path("autosave.json"))
	store.release()
	var scene := load("res://scenes/boot/Boot.tscn") as PackedScene
	var boot := scene.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(evidence.path_join("slice-default"))
	boot.factory_save_root = root_path
	root.add_child(boot)
	boot.startup_menu.factory_requested.emit()
	await process_frame
	var menu: Control = boot.factory_menu
	menu.list.select(0)
	menu.list.item_selected.emit(0)
	expect(menu.world_type.item_count == 2 and menu.continue_button.disabled and not menu.worlds[0].ok, "default formal menu hides engineering continuation and offers no engineering creation")
	expect(FileAccess.get_sha256(store.path("autosave.json")) == original, "default menu keeps engineering source unchanged")
	boot.free()
	boot = scene.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(evidence.path_join("slice-engineering"))
	boot.factory_save_root = root_path
	boot.factory_engineering_context = true
	root.add_child(boot)
	boot.startup_menu.factory_requested.emit()
	await process_frame
	menu = boot.factory_menu
	menu.list.select(0)
	menu.list.item_selected.emit(0)
	expect(not menu.continue_button.disabled and "工程规模验证" in menu.worlds[0].name, "explicit isolated Boot permits engineering continuation")
	menu.continue_button.pressed.emit()
	expect(boot.factory_world != null and boot.factory_world.initialized, "formal engineering reconstruction")
	if boot.factory_world != null:
		var world: Control = boot.factory_world
		world.model.measure_steps = false
		expect(world.model.map_id == Config.MAP_ID and world.model.ore_sites().size() == 20, "formal Boot retains fixed engineering map")
		expect(world.view.barriers.get_child_count() == 2, "engineering view shows only unpicked sample and icon, no ordinary mineral shell")
		world._action("return", null)
		await process_frame
	expect(not DirAccess.dir_exists_absolute(store.path("session.lock")), "formal engineering return releases lock")
	boot.free()
