extends SceneTree

const Boot := preload("res://scenes/boot/Boot.tscn")
const Store := preload("res://scripts/factory/save/store.gd")
const Codec := Store.Codec
const Preparation := preload("res://scripts/checks/factory_d2_preparation.gd")
const Preflight := preload("res://scripts/checks/factory_d2_preflight.gd")
const Feasibility := preload("res://scripts/checks/factory_d2_feasibility.gd")
const FaultPreflight := preload("res://scripts/checks/factory_d2_fault_preflight.gd")
const FaultPreparation := preload("res://scripts/checks/factory_d2_fault_preparation.gd")
const InterlockPreflight := preload("res://scripts/checks/factory_d2_interlock_preflight.gd")
var evidence := ""
var boot: Node


func _init() -> void:
	call_deferred("run")


func run() -> void:
	var mode := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--batch="):
			var batch := arg.trim_prefix("--batch=")
			if batch.is_valid_filename() and ".." not in batch:
				evidence = SliceCheckPaths.check_run("factory-d2-production-v1", false).path_join(batch)
		if arg.begins_with("--mode="): mode = arg.trim_prefix("--mode=")
	if evidence.is_empty() or not DirAccess.dir_exists_absolute(evidence):
		quit(2)
		return
	if mode == "prepare": await _prepare()
	elif mode == "fault-prepare-v4":
		var result := FaultPreparation.run(evidence, _read("candidate.json"), _read("preparation.json"))
		_write("result.json", result)
		quit(0 if result.status == "fault_v4_prepared" else 3)
	elif mode == "preflight":
		var check := Preflight.new(evidence)
		var result: Dictionary = check.run()
		_write("result.json", result)
		quit(0 if result.status == "preflight_passed" else 3)
	elif mode == "feasibility":
		var check := Feasibility.new(evidence)
		var result: Dictionary = check.run()
		_write("result.json", result)
		quit(0 if result.status == "feasibility_passed" else 3)
	elif mode in ["fault-preflight-v2", "fault-preflight-v3", "fault-preflight-v4"]:
		var check := FaultPreflight.new(evidence, int(mode.right(1)))
		var result: Dictionary = check.run()
		_write("result.json", result)
		quit(0 if result.status == "fault_preflight_passed" else 3)
	elif mode in ["fault-fd-cycle", "fault-fd-diagnostic"]:
		var check := FaultPreflight.new(evidence, 4)
		var short_run := mode == "fault-fd-cycle"
		var result: Dictionary = check.run_fd_diagnostic(short_run)
		_write("result.json", result)
		quit(0 if result.status in ["fd_cycle_passed", "fd_diagnostic_passed"] else 3)
	elif mode in ["fault-prepare-v5", "fault-v5-cycle", "fault-v5-recheck", "fault-preflight-v5"]:
		var check := InterlockPreflight.new(evidence)
		var result: Dictionary
		match mode:
			"fault-prepare-v5": result = check.derive()
			"fault-v5-recheck": result = check.recheck()
			_:
				check.interlock_cycle_test = mode == "fault-v5-cycle"
				result = check.run()
		_write("result.json", result)
		quit(0 if result.status in ["interlock_parent_prepared", "interlock_cycle_passed",
			"interlock_recheck_passed", "fault_preflight_passed"] else 3)
	else: quit(2)


func _prepare() -> void:
	boot = Boot.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(evidence.path_join("slice"))
	boot.factory_save_root = evidence.path_join("factory")
	boot.factory_controls_context = true
	root.add_child(boot)
	for frame in 12: await process_frame
	boot.startup_menu.find_child("FactoryButton", true, false).pressed.emit()
	for frame in 5: await process_frame
	var menu: Control = boot.factory_menu
	for i in menu.world_type.item_count:
		if menu.world_type.get_item_metadata(i) == Codec.V15.Loads.SUPPLY_ID:
			menu.world_type.select(i)
	menu.title_input.text = "D2 长期对照准备候选"
	menu.create_button.pressed.emit()
	for frame in 5: await process_frame
	var world: Control = boot.factory_world
	if world == null or not world.initialized:
		_write("result.json", {"status": "preparation_error", "reason": "formal Boot creation failed"})
		quit(1)
		return
	world._set_paused(true)
	var initial := Codec.snapshot(world.model, world.store.world_id, world.store.world_name, world.store.sequence)
	_write("initial.json", initial)
	assert(initial.save_schema_version == 15 and world.model.core.items.is_empty() and world.model.entities.size() == 1)
	var route := Preparation.new(world.model, _read("starter.json"))
	var prepared := route.prepare(_read("layout.json"))
	_write("preparation.json", prepared)
	var saved: Dictionary = world.store.save(world.model)
	if not saved.ok:
		_write("result.json", {"status": "preparation_error", "reason": saved.reason})
		quit(1)
		return
	var candidate := Store.new(boot.factory_save_root, false, false, true).find_candidate(world.store.world_id)
	assert(candidate.ok)
	_write("candidate.json", candidate.document)
	assert(world.store.release().ok)
	_write("result.json", {"status": "prepared_candidate" if prepared.ok else "preparation_invalid", "reason": prepared.get("reason", ""),
		"simulation_seconds": world.model.time, "material_balance": world.model.material_balance(), "natural_clock_result": false})
	quit(0 if prepared.ok else 3)


func _read(file: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(evidence.path_join(file)))


func _write(file: String, data: Variant) -> void:
	var handle := FileAccess.open(evidence.path_join(file), FileAccess.WRITE)
	assert(handle != null, "cannot write D2 evidence " + file)
	handle.store_string(JSON.stringify(data, "", true, true))
