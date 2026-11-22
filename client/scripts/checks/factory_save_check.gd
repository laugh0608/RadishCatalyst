extends SceneTree

const Store := preload("res://scripts/factory/save/store.gd")
const Codec := Store.Codec
var failures: Array[String] = []
var checks := 0
var run_root := ""


func _init() -> void:
	call_deferred("_run")


func expect(condition: bool, context: String) -> void:
	checks += 1
	if not condition:
		failures.append(context)


func write(path: String, value: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	assert(file != null)
	file.store_string(value)
	file.close()


func _run() -> void:
	run_root = ProjectSettings.globalize_path("res://").path_join("../tools/runtime-intake/check-runs/factory-foundation-v1").simplify_path()
	run_root = run_root.path_join("save-%d-%d" % [Time.get_unix_time_from_system(), OS.get_process_id()])
	var store := Store.new(run_root)
	var created := store.create("保存故障检查")
	expect(created.ok, "initial commit: " + created.get("reason", ""))
	if not created.ok:
		finish()
		return
	var model: RefCounted = created.model
	var id: String = store.world_id
	expect(FileAccess.file_exists(store.path("autosave.json")), "new world committed before entry")
	var rival := Store.new(run_root)
	expect(not rival.prepare(id).ok, "second writer blocked")
	expect(not rival.recover_stale_lock(id).ok, "active owner cannot be reclaimed")
	model.place("collector", Vector2i(-8, -1))
	model.advance(17.375)
	expect(store.save(model).ok, "fractional clock save")
	var baseline := FileAccess.get_sha256(store.path("autosave.json"))
	var before_state := Codec.snapshot(model, id, store.world_name, store.sequence)
	for stage in ["validation", "temporary_write", "readback", "backup", "publish"]:
		store.fault = func(at): return at == stage
		var result := store.save(model)
		expect(not result.ok, "injected " + stage + " rejected")
		expect(FileAccess.get_sha256(store.path("autosave.json")) == baseline, stage + " preserves main")
		expect(Codec.snapshot(model, id, store.world_name, store.sequence) == before_state, stage + " preserves live state/sequence")
		var backup := store.find_candidate(id)
		expect(backup.ok, stage + " retains a valid candidate")
	store.fault = func(stage): return stage == "metadata"
	var metadata := store.save(model)
	expect(metadata.ok and not metadata.warning.is_empty(), "metadata warning after successful main commit")
	store.fault = Callable()
	expect(store.save(model).ok, "retry succeeds")
	var main_path := store.path("autosave.json")
	var backup_path := store.path("backups/autosave.bak.1.json")
	var metadata_path := store.path("metadata.json")
	var identity_record := FileAccess.get_file_as_string(metadata_path)
	var backup_hash := FileAccess.get_sha256(backup_path)
	expect(store.release().ok, "normal lock release")
	write(main_path, "{corrupt")
	var restore := Store.new(run_root)
	write(metadata_path, JSON.stringify({"world_id": id, "sequence": store.sequence}))
	var unknown := restore.prepare(id)
	expect(not unknown.ok and "无法确认主档" in unknown.get("reason", ""), "legacy summary does not identify a malformed main")
	expect(FileAccess.get_file_as_string(main_path) == "{corrupt" and FileAccess.get_sha256(backup_path) == backup_hash,
		"unknown identity preserves main and backup")
	write(metadata_path, identity_record)
	var candidate := restore.prepare(id)
	expect(candidate.ok and candidate.source == backup_path, "select newest valid backup")
	expect(FileAccess.get_file_as_string(main_path) == "{corrupt", "candidate read does not publish")
	if candidate.ok:
		restore.fault = func(stage): return stage == "reconstruction"
		expect(not restore.accept(candidate).ok and not restore.loaded, "view/model rebuild failure blocks autosave")
		expect(FileAccess.get_sha256(backup_path) == backup_hash, "rebuild failure preserves source")
		restore.fault = func(stage): return stage == "publish"
		expect(not restore.accept(candidate).ok, "recovery publish failure")
		expect(FileAccess.get_file_as_string(main_path) == "{corrupt" and FileAccess.get_sha256(backup_path) == backup_hash, "recovery failure preserves main/source")
		restore.fault = Callable()
		write(metadata_path, "{}")
		expect(not restore.accept(candidate).ok and not restore.loaded and FileAccess.get_file_as_string(main_path) == "{corrupt",
			"changed recovery identity record blocks publish")
		write(metadata_path, identity_record)
		write(backup_path, FileAccess.get_file_as_string(backup_path) + " ")
		expect(not restore.accept(candidate).ok, "candidate source hash change rejected")
		candidate = restore.find_candidate(id)
		expect(restore.accept(candidate).ok, "explicit candidate reread and successful recovery")
		expect(restore.loaded and FileAccess.get_file_as_string(main_path) != "{corrupt", "successful recovery publishes after reconstruction")
		restore.release()
	var future: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(main_path))
	future.save_schema_version = 2
	write(main_path, JSON.stringify(future))
	var reader := Store.new(run_root)
	expect(not reader.prepare(id).ok, "future main refuses old backup fallback")
	expect(JSON.parse_string(FileAccess.get_file_as_string(main_path)).save_schema_version == 2, "future main unchanged")
	write(main_path, "{bad")
	for index in range(1, 4):
		write(run_root.path_join(id).path_join("backups/autosave.bak.%d.json" % index), "{bad")
	expect(not reader.prepare(id).ok, "all corrupt stops load")
	expect(FileAccess.get_file_as_string(main_path) == "{bad", "never blank-overwrite invalid world")
	expect(not DirAccess.dir_exists_absolute(run_root.path_join(id).path_join("session.lock")), "failed prepare releases own lock")
	var clean := Store.new(run_root.path_join("external"))
	var new_world := clean.create("外部修改检查")
	expect(new_world.ok, "external conflict fixture")
	if new_world.ok:
		write(clean.path("autosave.json"), FileAccess.get_file_as_string(clean.path("autosave.json")) + " ")
		expect(not clean.save(new_world.model).ok, "external main edit blocks overwrite")
		clean.release()
	_check_metadata_after_upgrade()
	finish()


func _check_metadata_after_upgrade() -> void:
	var store := Store.new(run_root.path_join("upgrade"))
	var created := store.create("升级故障检查", Codec.V2.Config.SUPPLY_ID)
	expect(created.ok, "create V2 upgrade fixture")
	if not created.ok:
		return
	var id := store.world_id
	expect(store.save(created.model).ok and store.release().ok, "save V2 with recovery identity and a backup")
	var candidate := store.prepare(id)
	expect(candidate.ok, "open V2 before upgrade")
	if not candidate.ok:
		return
	var upgraded := store.upgrade_automatic(candidate)
	expect(upgraded.ok, "stage V3 upgrade")
	if not upgraded.ok:
		store.release()
		return
	store.fault = func(stage): return stage == "metadata"
	var result := store.accept(upgraded)
	expect(result.ok and result.get("upgraded_automatic", false) and not result.get("warning", "").is_empty(),
		"V3 publishes despite metadata update fault")
	expect(store.release().ok and not FileAccess.file_exists(store.path("metadata.json")), "V2 identity did not survive V3 publication")
	write(store.path("autosave.json"), "{corrupt")
	expect(not store.find_candidate(id).ok and FileAccess.get_file_as_string(store.path("autosave.json")) == "{corrupt",
		"malformed upgraded primary cannot recover pre-upgrade backup")


func finish() -> void:
	print("Factory save checks: %d assertions, %d failures; evidence %s" % [checks, failures.size(), run_root])
	for failure in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)
