extends SceneTree

var TEST_ROOT := SliceCheckPaths.check_run("save-catalog", false)
var MIGRATION_ROOT := SliceCheckPaths.check_run("save-catalog-migration", false)

var failures: Array[String] = []
var assertion_count := 0


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	_remove_tree(TEST_ROOT)
	_remove_tree(MIGRATION_ROOT)
	_run_catalog_checks()
	_run_migration_checks()
	_remove_tree(TEST_ROOT)
	_remove_tree(MIGRATION_ROOT)
	if failures.is_empty():
		print(
			"Slice save catalog checks passed (%d assertions)."
			% assertion_count
		)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _run_catalog_checks() -> void:
	var catalog := SliceSaveCatalog.new(TEST_ROOT)
	_expect_equal(catalog.list_worlds().size(), 0, "new catalog is empty")
	_expect_failure(catalog.create_world(""), "blank world name")
	_expect_failure(
		catalog.create_world("bad\nname"),
		"world name rejects line breaks"
	)

	var alpha_result := catalog.create_world("Alpha")
	var beta_result := catalog.create_world("Beta")
	_expect_success(alpha_result, "create Alpha")
	_expect_success(beta_result, "create Beta")
	var alpha_id := _result_world_id(alpha_result)
	var beta_id := _result_world_id(beta_result)
	_expect(not alpha_id.is_empty(), "Alpha receives a stable id")
	_expect(not beta_id.is_empty(), "Beta receives a stable id")
	_expect(alpha_id != beta_id, "created worlds have unique ids")
	var initial_worlds := catalog.list_worlds()
	_expect_equal(initial_worlds.size(), 2, "catalog lists both worlds")
	_expect(
		not bool(_find_summary(initial_worlds, alpha_id).get("loadable", true)),
		"new world has metadata but no autosave"
	)

	var alpha_service := catalog.service_for_world(alpha_id)
	_expect(alpha_service != null, "catalog returns Alpha service")
	if alpha_service == null:
		return
	for marker in range(1, 5):
		_expect_success(
			alpha_service.save_state(_state(marker)),
			"Alpha save %d" % marker
		)
	var backups := alpha_service.backup_file_paths()
	_expect_equal(backups.size(), 3, "world service exposes three backups")
	_expect_equal(
		int(_read_json(alpha_service.save_file_path()).get("core_energy", 0)),
		4,
		"main autosave keeps newest state"
	)
	for index in range(3):
		_expect_equal(
			int(_read_json(backups[index]).get("core_energy", 0)),
			3 - index,
			"backup %d keeps the expected previous generation" % (index + 1)
		)
	var alpha_summary := _find_summary(catalog.list_worlds(), alpha_id)
	_expect(bool(alpha_summary.get("loadable", false)), "saved Alpha is loadable")
	_expect(bool(alpha_summary.get("core_repaired", false)), "metadata reports core state")
	_expect_equal(
		int(alpha_summary.get("catalyst_count", 0)),
		2,
		"metadata reports catalyst summary"
	)
	_expect_equal(
		String(alpha_summary.get("field_encounter_state", "")),
		"hostile",
		"metadata reports encounter summary"
	)
	_expect_equal(
		int(alpha_summary.get("player_health", 0)),
		100,
		"metadata reports player health"
	)

	_write_text(alpha_service.save_file_path(), "{broken")
	var fallback := alpha_service.load_state()
	_expect_success(fallback, "broken main falls back to first backup")
	_expect_equal(
		int(fallback.get("data", {}).get("core_energy", 0)),
		3,
		"fallback loads the newest valid backup"
	)
	_expect_equal(
		String(fallback.get("source_path", "")),
		backups[0],
		"fallback reports its backup source"
	)

	var renamed := catalog.rename_world(alpha_id, "Alpha Review")
	_expect_success(renamed, "rename Alpha")
	var renamed_summary := _find_summary(catalog.list_worlds(), alpha_id)
	_expect_equal(
		String(renamed_summary.get("display_name", "")),
		"Alpha Review",
		"rename updates display name"
	)
	_expect_equal(
		String(renamed_summary.get("world_id", "")),
		alpha_id,
		"rename preserves stable world id"
	)
	_expect_failure(
		catalog.rename_world("../escape", "No"),
		"path traversal world id is rejected"
	)
	_expect(
		catalog.service_for_world("../escape") == null,
		"unsafe id cannot create a service"
	)

	var trash_result := catalog.move_world_to_trash(beta_id)
	_expect_success(trash_result, "move Beta to trash")
	var trash_id := String(trash_result.get("data", {}).get("trash_id", ""))
	_expect_equal(catalog.list_worlds().size(), 1, "trashed world leaves active list")
	_expect_equal(catalog.list_trash().size(), 1, "trash lists removed world")
	_expect_success(catalog.restore_world(trash_id), "restore Beta")
	_expect_equal(catalog.list_worlds().size(), 2, "restored world returns")
	_expect_equal(catalog.list_trash().size(), 0, "restored world leaves trash")

	var beta_metadata := (
		catalog.worlds_directory()
		.path_join(beta_id)
		.path_join("metadata.json")
	)
	_write_text(beta_metadata, "{broken")
	var damaged_summary := _find_summary(catalog.list_worlds(), beta_id)
	_expect(
		not bool(damaged_summary.get("loadable", true)),
		"damaged metadata isolates one world"
	)
	_expect(
		bool(_find_summary(catalog.list_worlds(), alpha_id).get("loadable", false)),
		"damaged Beta does not block Alpha"
	)

	var created_ids: Array[String] = []
	for number in range(3, SliceSaveCatalog.MAX_WORLDS + 1):
		var create_result := catalog.create_world("World %02d" % number)
		_expect_success(create_result, "create world %02d" % number)
		created_ids.append(_result_world_id(create_result))
	_expect_equal(
		catalog.list_worlds().size(),
		SliceSaveCatalog.MAX_WORLDS,
		"catalog reaches exactly thirty worlds"
	)
	_expect_failure(
		catalog.create_world("World 31"),
		"thirty-first world is rejected"
	)
	var recyclable_id := created_ids[0]
	_expect_success(
		catalog.move_world_to_trash(recyclable_id),
		"moving one world to trash frees capacity"
	)
	_expect_success(
		catalog.create_world("Replacement"),
		"replacement world can use freed capacity"
	)
	_expect_equal(
		catalog.list_worlds().size(),
		SliceSaveCatalog.MAX_WORLDS,
		"replacement returns active count to thirty"
	)


func _run_migration_checks() -> void:
	var legacy_main := MIGRATION_ROOT.path_join("slice_world.json")
	var legacy_backup := MIGRATION_ROOT.path_join("slice_world.bak.json")
	DirAccess.make_dir_recursive_absolute(MIGRATION_ROOT)
	_write_text(
		legacy_backup, JSON.stringify(_schema_seven_save(7), "\t")
	)
	_write_text(
		legacy_main, JSON.stringify(_schema_seven_save(8), "\t")
	)
	_expect(FileAccess.file_exists(legacy_main), "legacy main exists before migration")
	_expect(FileAccess.file_exists(legacy_backup), "legacy backup exists before migration")
	var legacy_main_sha := FileAccess.get_sha256(legacy_main)

	var catalog := SliceSaveCatalog.new(MIGRATION_ROOT)
	var migration := catalog.migrate_legacy_single_world("Imported Review")
	_expect_success(migration, "migrate legacy single world")
	_expect(
		bool(migration.get("data", {}).get("migrated", false)),
		"migration reports a published world"
	)
	var world_id := _result_world_id(migration)
	var worlds := catalog.list_worlds()
	_expect_equal(worlds.size(), 1, "migration publishes exactly one world")
	_expect_equal(
		String(worlds[0].get("display_name", "")),
		"Imported Review",
		"migration preserves requested display name"
	)
	var world_service := catalog.service_for_world(world_id)
	_expect(world_service != null, "migrated world has a service")
	if world_service != null:
		_expect_equal(
			int(_read_json(world_service.save_file_path()).get(
				"save_schema_version", 0
			)),
			7,
			"catalog import preserves the raw schema 7 candidate"
		)
		_expect_equal(
			FileAccess.get_sha256(world_service.save_file_path()),
			legacy_main_sha,
			"catalog import does not rewrite legacy bytes before world rebuild"
		)
		var restored := world_service.load_state()
		_expect_success(restored, "migrated world reads back")
		_expect_equal(
			int(restored.get("data", {}).get("core_energy", 0)),
			8,
			"migration preserves newest legacy state"
		)
		_expect(
			bool(restored.get("migration_required", false)),
			"imported world remains pending until reconstructed"
		)
		_expect(
			FileAccess.file_exists(world_service.backup_file_paths()[0]),
			"migration publishes a first world backup"
		)
	_expect(FileAccess.file_exists(legacy_main), "migration preserves legacy main")
	_expect(FileAccess.file_exists(legacy_backup), "migration preserves legacy backup")
	var repeated := catalog.migrate_legacy_single_world("Duplicate")
	_expect_success(repeated, "repeated migration is a safe no-op")
	_expect(
		not bool(repeated.get("data", {}).get("migrated", true)),
		"existing worlds prevent duplicate import"
	)
	_expect_equal(catalog.list_worlds().size(), 1, "duplicate import creates nothing")


func _state(marker: int) -> Dictionary:
	return {
		"pocket": {
			"contents": {SliceWorld.ITEM_CRYSTAL: marker},
		},
		"core_storage": {
			"contents": {SliceWorld.ITEM_CATALYST: 2},
		},
		"core_repaired": true,
		"core_energy": marker,
		"harvested_clusters": ["CrystalSmall1"],
		"buildings": [],
		"next_building_serial": 1,
		"player_x": 400.0 + marker,
		"player_y": 576.0,
	}


func _schema_seven_save(marker: int) -> Dictionary:
	return {
		"save_schema_version": 7,
		"game_version": "prototype-slice-07",
		"updated_at": "2026-08-08T00:00:00",
		"pocket": {
			"capacity": 30,
			"contents": {SliceWorld.ITEM_CRYSTAL: marker},
		},
		"core_storage": {
			"capacity": 120,
			"contents": {SliceWorld.ITEM_CATALYST: 2},
		},
		"core_repaired": true,
		"core_energy": marker,
		"harvested_clusters": ["CrystalSmall1"],
		"buildings": [],
		"next_building_serial": 1,
		"player_x": 400.0 + marker,
		"player_y": 576.0,
		"player_health": 100,
		"field_encounter": {"state": "hostile", "enemy_health": 60},
	}


func _find_summary(
	summaries: Array[Dictionary],
	world_id: String
) -> Dictionary:
	for summary in summaries:
		if String(summary.get("world_id", "")) == world_id:
			return summary
	return {}


func _result_world_id(result: Dictionary) -> String:
	return String(result.get("data", {}).get("world_id", ""))


func _read_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		failures.append("could not read %s" % path)
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	if not (parsed is Dictionary):
		failures.append("%s should contain a JSON object" % path)
		return {}
	return parsed


func _write_text(path: String, content: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures.append("could not write %s" % path)
		return
	file.store_string(content)
	file.close()


func _remove_tree(path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	if not DirAccess.dir_exists_absolute(absolute_path):
		return
	var dir := DirAccess.open(absolute_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		var child := absolute_path.path_join(entry)
		if dir.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(child)
		entry = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(absolute_path)


func _expect_success(result: Dictionary, context: String) -> void:
	_expect(
		bool(result.get("success", false)),
		"%s: %s" % [context, String(result.get("message", ""))]
	)


func _expect_failure(result: Dictionary, context: String) -> void:
	_expect(
		not bool(result.get("success", false)),
		"%s should fail" % context
	)


func _expect_equal(actual, expected, context: String) -> void:
	_expect(
		actual == expected,
		"%s: expected %s, got %s"
		% [context, str(expected), str(actual)]
	)


func _expect(condition: bool, context: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(context)
