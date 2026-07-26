class_name SliceSaveCatalog
extends RefCounted

## Multi-world directory boundary for the slice. Each catalog owns one
## injectable root and returns a single-world SliceSaveService for selected
## entries. Gameplay state stays in schema 6; this class only owns identity,
## metadata, the 30-world limit, migration and recoverable removal.

const MAX_WORLDS := 30
const METADATA_SCHEMA_VERSION := 1
const DEFAULT_ROOT_DIR := "user://saves/slice"
const WORLDS_DIR_NAME := "worlds"
const TRASH_DIR_NAME := "trash"
const LEGACY_SAVE_FILE_NAME := "slice_world.json"
const LEGACY_BACKUP_FILE_NAME := "slice_world.bak.json"
const DEFAULT_WORLD_NAME := "前哨 01"
const MAX_DISPLAY_NAME_LENGTH := 40

var _root_dir: String
var _worlds_dir: String
var _trash_dir: String


func _init(root_dir: String = DEFAULT_ROOT_DIR) -> void:
	_root_dir = root_dir.trim_suffix("/")
	_worlds_dir = _root_dir.path_join(WORLDS_DIR_NAME)
	_trash_dir = _root_dir.path_join(TRASH_DIR_NAME)


func root_directory() -> String:
	return _root_dir


func worlds_directory() -> String:
	return _worlds_dir


func trash_directory() -> String:
	return _trash_dir


func list_worlds() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for directory_name in _directory_names(_worlds_dir):
		result.append(
			_world_summary(
				_worlds_dir.path_join(directory_name),
				directory_name
			)
		)
	result.sort_custom(_world_summary_precedes)
	return result


func list_trash() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for directory_name in _directory_names(_trash_dir):
		var summary := _world_summary(
			_trash_dir.path_join(directory_name),
			directory_name,
			false
		)
		summary["trash_id"] = directory_name
		result.append(summary)
	result.sort_custom(_world_summary_precedes)
	return result


func create_world(display_name: String) -> Dictionary:
	var roots_error := _ensure_roots()
	if roots_error != OK:
		return _failure(
			"创建世界目录失败：%s。" % error_string(roots_error)
		)
	if list_worlds().size() >= MAX_WORLDS:
		return _failure(
			"世界数量已达到上限 %d，请先把一个世界移入回收区。"
			% MAX_WORLDS
		)
	var normalized_name := display_name.strip_edges()
	var name_error := _display_name_error(normalized_name)
	if not name_error.is_empty():
		return _failure(name_error)
	var world_id := _generate_world_id()
	var world_dir := _worlds_dir.path_join(world_id)
	var create_error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(
			world_dir.path_join("backups")
		)
	)
	if create_error != OK:
		return _failure(
			"创建世界 %s 失败：%s。"
			% [normalized_name, error_string(create_error)]
		)
	var now := _local_time_text()
	var metadata := _new_metadata(world_id, normalized_name, now)
	var write_error := _write_json_atomic(
		world_dir.path_join("metadata.json"),
		world_dir.path_join("metadata.tmp.json"),
		metadata
	)
	if write_error != OK:
		_move_partial_world_to_trash(world_dir, world_id)
		return _failure(
			"写入世界元数据失败：%s。" % error_string(write_error)
		)
	return _success({
		"world_id": world_id,
		"display_name": normalized_name,
		"world_dir": world_dir,
	})


func rename_world(world_id: String, display_name: String) -> Dictionary:
	if not _is_safe_world_id(world_id):
		return _failure("世界 ID 无效。")
	var normalized_name := display_name.strip_edges()
	var name_error := _display_name_error(normalized_name)
	if not name_error.is_empty():
		return _failure(name_error)
	var world_dir := _worlds_dir.path_join(world_id)
	var metadata_result := _read_metadata(world_dir)
	if not bool(metadata_result.get("success", false)):
		return metadata_result
	var metadata: Dictionary = metadata_result["data"]
	if String(metadata.get("world_id", "")) != world_id:
		return _failure("世界元数据 ID 与目录不一致，未执行重命名。")
	metadata["display_name"] = normalized_name
	var write_error := _write_json_atomic(
		world_dir.path_join("metadata.json"),
		world_dir.path_join("metadata.tmp.json"),
		metadata
	)
	if write_error != OK:
		return _failure(
			"重命名世界失败：%s。" % error_string(write_error)
		)
	return _success({
		"world_id": world_id,
		"display_name": normalized_name,
	})


func move_world_to_trash(world_id: String) -> Dictionary:
	if not _is_safe_world_id(world_id):
		return _failure("世界 ID 无效。")
	var roots_error := _ensure_roots()
	if roots_error != OK:
		return _failure(
			"创建回收目录失败：%s。" % error_string(roots_error)
		)
	var source := _worlds_dir.path_join(world_id)
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(source)):
		return _failure("未找到要回收的世界。")
	var trash_id := _unique_trash_id(world_id)
	var destination := _trash_dir.path_join(trash_id)
	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(source),
		ProjectSettings.globalize_path(destination)
	)
	if rename_error != OK:
		return _failure(
			"移动世界到回收区失败：%s。" % error_string(rename_error)
		)
	return _success({
		"world_id": world_id,
		"trash_id": trash_id,
	})


func restore_world(trash_id: String) -> Dictionary:
	if not _is_safe_directory_name(trash_id):
		return _failure("回收项 ID 无效。")
	var roots_error := _ensure_roots()
	if roots_error != OK:
		return _failure(
			"创建世界目录失败：%s。" % error_string(roots_error)
		)
	if list_worlds().size() >= MAX_WORLDS:
		return _failure(
			"世界数量已达到上限 %d，无法恢复回收项。" % MAX_WORLDS
		)
	var source := _trash_dir.path_join(trash_id)
	var metadata_result := _read_metadata(source)
	if not bool(metadata_result.get("success", false)):
		return metadata_result
	var metadata: Dictionary = metadata_result["data"]
	var world_id := String(metadata.get("world_id", ""))
	if not _is_safe_world_id(world_id):
		return _failure("回收项中的世界 ID 无效。")
	var destination := _worlds_dir.path_join(world_id)
	if DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(destination)):
		return _failure("同 ID 世界已经存在，未覆盖当前世界。")
	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(source),
		ProjectSettings.globalize_path(destination)
	)
	if rename_error != OK:
		return _failure(
			"恢复世界失败：%s。" % error_string(rename_error)
		)
	return _success({"world_id": world_id})


func service_for_world(world_id: String) -> SliceSaveService:
	if not _is_safe_world_id(world_id):
		return null
	var world_dir := _worlds_dir.path_join(world_id)
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(world_dir)):
		return null
	var metadata_result := _read_metadata(world_dir)
	if not bool(metadata_result.get("success", false)):
		return null
	var metadata: Dictionary = metadata_result["data"]
	if String(metadata.get("world_id", "")) != world_id:
		return null
	return SliceSaveService.for_world(world_dir, world_id)


func migrate_legacy_single_world(
	display_name: String = DEFAULT_WORLD_NAME
) -> Dictionary:
	if not list_worlds().is_empty():
		return _success({"migrated": false, "reason": "worlds_exist"})
	var legacy_service := SliceSaveService.new(_root_dir)
	if not legacy_service.has_save():
		return _success({"migrated": false, "reason": "legacy_missing"})
	var legacy_result := legacy_service.load_state()
	if not bool(legacy_result.get("success", false)):
		return _failure(
			"旧单档不可读取，未创建迁移世界：%s"
			% String(legacy_result.get("message", "未知错误"))
		)
	var normalized_name := display_name.strip_edges()
	var name_error := _display_name_error(normalized_name)
	if not name_error.is_empty():
		return _failure(name_error)
	var roots_error := _ensure_roots()
	if roots_error != OK:
		return _failure(
			"创建迁移目录失败：%s。" % error_string(roots_error)
		)
	var world_id := _generate_world_id()
	var staging_dir := _root_dir.path_join(".migration-%s" % world_id)
	var stage_error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(
			staging_dir.path_join("backups")
		)
	)
	if stage_error != OK:
		return _failure(
			"创建迁移暂存目录失败：%s。" % error_string(stage_error)
		)
	var now := _local_time_text()
	var metadata_error := _write_json_atomic(
		staging_dir.path_join("metadata.json"),
		staging_dir.path_join("metadata.tmp.json"),
		_new_metadata(world_id, normalized_name, now)
	)
	if metadata_error != OK:
		return _failure(
			"写入迁移元数据失败：%s。" % error_string(metadata_error)
		)
	var service := SliceSaveService.for_world(staging_dir, world_id)
	var state: Dictionary = legacy_result["data"]
	var first_save := service.save_state(state)
	if not bool(first_save.get("success", false)):
		return _failure(
			"迁移写入失败：%s"
			% String(first_save.get("message", "未知错误"))
		)
	var second_save := service.save_state(state)
	if not bool(second_save.get("success", false)):
		return _failure(
			"迁移备份写入失败：%s"
			% String(second_save.get("message", "未知错误"))
		)
	var readback := service.load_state()
	if (
		not bool(readback.get("success", false))
		or not _migration_states_match(
			state,
			readback.get("data", {})
		)
	):
		return _failure(
			"迁移读回校验失败，旧单档保持原位且未发布新世界。"
		)
	var destination := _worlds_dir.path_join(world_id)
	var publish_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(staging_dir),
		ProjectSettings.globalize_path(destination)
	)
	if publish_error != OK:
		return _failure(
			"发布迁移世界失败：%s。旧单档保持原位。"
			% error_string(publish_error)
		)
	return _success({
		"migrated": true,
		"world_id": world_id,
		"legacy_source_path": String(
			legacy_result.get("source_path", "")
		),
	})


func _world_summary(
	world_dir: String,
	directory_name: String,
	require_directory_match: bool = true
) -> Dictionary:
	var metadata_result := _read_metadata(world_dir)
	if not bool(metadata_result.get("success", false)):
		return {
			"world_id": directory_name,
			"display_name": "无法读取的世界",
			"updated_at": "",
			"status": "元数据损坏",
			"loadable": false,
			"error": String(metadata_result.get("message", "")),
		}
	var metadata: Dictionary = metadata_result["data"]
	var world_id := String(metadata.get("world_id", ""))
	if require_directory_match and world_id != directory_name:
		return {
			"world_id": directory_name,
			"display_name": String(
				metadata.get("display_name", directory_name)
			),
			"updated_at": String(metadata.get("updated_at", "")),
			"status": "世界 ID 不一致",
			"loadable": false,
			"error": "元数据世界 ID 与目录不一致。",
		}
	var service := SliceSaveService.for_world(world_dir, world_id)
	var has_save := service.has_save()
	return {
		"world_id": world_id,
		"display_name": String(metadata.get("display_name", world_id)),
		"created_at": String(metadata.get("created_at", "")),
		"updated_at": String(metadata.get("updated_at", "")),
		"game_version": String(metadata.get("game_version", "")),
		"save_schema_version": int(
			metadata.get("save_schema_version", 0)
		),
		"core_repaired": bool(metadata.get("core_repaired", false)),
		"building_count": int(metadata.get("building_count", 0)),
		"catalyst_count": int(metadata.get("catalyst_count", 0)),
		"status": "可读取" if has_save else "新世界",
		"loadable": has_save,
	}


func _read_metadata(world_dir: String) -> Dictionary:
	var path := world_dir.path_join("metadata.json")
	if not FileAccess.file_exists(path):
		return _failure("世界元数据缺失。")
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return _failure(
			"打开世界元数据失败：%s。"
			% error_string(FileAccess.get_open_error())
		)
	var content := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(content) != OK or not (json.data is Dictionary):
		return _failure("世界元数据 JSON 无效。")
	var metadata: Dictionary = json.data
	if (
		int(metadata.get("metadata_schema_version", 0))
		!= METADATA_SCHEMA_VERSION
	):
		return _failure("世界元数据版本不兼容。")
	if String(metadata.get("display_name", "")).strip_edges().is_empty():
		return _failure("世界显示名为空。")
	return _success(metadata)


func _new_metadata(
	world_id: String,
	display_name: String,
	now: String
) -> Dictionary:
	return {
		"metadata_schema_version": METADATA_SCHEMA_VERSION,
		"world_id": world_id,
		"display_name": display_name,
		"created_at": now,
		"updated_at": now,
		"game_version": SliceSaveService.GAME_VERSION,
		"save_schema_version": SliceSaveService.SAVE_SCHEMA_VERSION,
		"play_time_seconds": 0,
		"core_repaired": false,
		"building_count": 0,
		"catalyst_count": 0,
	}


func _write_json_atomic(
	path: String,
	temp_path: String,
	data: Dictionary
) -> Error:
	var file := FileAccess.open(temp_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	return DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temp_path),
		ProjectSettings.globalize_path(path)
	)


func _ensure_roots() -> Error:
	var worlds_error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(_worlds_dir)
	)
	if (
		worlds_error != OK
		and not DirAccess.dir_exists_absolute(
			ProjectSettings.globalize_path(_worlds_dir)
		)
	):
		return worlds_error
	var trash_error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(_trash_dir)
	)
	if (
		trash_error != OK
		and not DirAccess.dir_exists_absolute(
			ProjectSettings.globalize_path(_trash_dir)
		)
	):
		return trash_error
	return OK


func _directory_names(path: String) -> Array[String]:
	var result: Array[String] = []
	var absolute_path := ProjectSettings.globalize_path(path)
	var dir := DirAccess.open(absolute_path)
	if dir == null:
		return result
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		if (
			dir.current_is_dir()
			and not entry.begins_with(".")
			and _is_safe_directory_name(entry)
		):
			result.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()
	result.sort()
	return result


func _generate_world_id() -> String:
	var unix_time := int(Time.get_unix_time_from_system())
	var tick_suffix := int(Time.get_ticks_usec() % 1000000)
	var base := "world_%d_%06d" % [unix_time, tick_suffix]
	var candidate := base
	var collision_index := 1
	while (
		DirAccess.dir_exists_absolute(
			ProjectSettings.globalize_path(
				_worlds_dir.path_join(candidate)
			)
		)
		or DirAccess.dir_exists_absolute(
			ProjectSettings.globalize_path(
				_trash_dir.path_join(candidate)
			)
		)
	):
		candidate = "%s_%d" % [base, collision_index]
		collision_index += 1
	return candidate


func _unique_trash_id(world_id: String) -> String:
	var timestamp := _local_time_text()
	for character in ["-", ":", " ", "T"]:
		timestamp = timestamp.replace(character, "")
	var base := "%s_%s" % [world_id, timestamp]
	var candidate := base
	var collision_index := 1
	while DirAccess.dir_exists_absolute(
		ProjectSettings.globalize_path(
			_trash_dir.path_join(candidate)
		)
	):
		candidate = "%s_%d" % [base, collision_index]
		collision_index += 1
	return candidate


func _world_summary_precedes(left: Dictionary, right: Dictionary) -> bool:
	var left_time := String(left.get("updated_at", ""))
	var right_time := String(right.get("updated_at", ""))
	if left_time != right_time:
		return left_time > right_time
	return String(left.get("world_id", "")) < String(
		right.get("world_id", "")
	)


func _display_name_error(display_name: String) -> String:
	if display_name.is_empty():
		return "世界名称不能为空。"
	if display_name.length() > MAX_DISPLAY_NAME_LENGTH:
		return "世界名称不能超过 %d 个字符。" % MAX_DISPLAY_NAME_LENGTH
	if (
		display_name.contains("\n")
		or display_name.contains("\r")
		or display_name.contains("\t")
	):
		return "世界名称不能包含换行或制表符。"
	return ""


func _is_safe_world_id(world_id: String) -> bool:
	return (
		world_id.begins_with("world_")
		and _is_safe_directory_name(world_id)
		and world_id.length() <= 80
	)


func _is_safe_directory_name(directory_name: String) -> bool:
	return (
		not directory_name.is_empty()
		and directory_name != "."
		and directory_name != ".."
		and not directory_name.contains("/")
		and not directory_name.contains("\\")
		and not directory_name.contains("..")
	)


func _migration_states_match(left: Dictionary, right) -> bool:
	if not (right is Dictionary):
		return false
	for key in [
		"pocket",
		"core_storage",
		"core_repaired",
		"core_energy",
		"harvested_clusters",
		"buildings",
		"next_building_serial",
	]:
		if left.get(key) != right.get(key):
			return false
	return (
		is_equal_approx(
			float(left.get("player_x", 0.0)),
			float(right.get("player_x", 0.0))
		)
		and is_equal_approx(
			float(left.get("player_y", 0.0)),
			float(right.get("player_y", 0.0))
		)
	)


func _move_partial_world_to_trash(
	world_dir: String,
	world_id: String
) -> void:
	var trash_error := DirAccess.make_dir_recursive_absolute(
		ProjectSettings.globalize_path(_trash_dir)
	)
	if trash_error != OK:
		return
	DirAccess.rename_absolute(
		ProjectSettings.globalize_path(world_dir),
		ProjectSettings.globalize_path(
			_trash_dir.path_join("%s_create_failed" % world_id)
		)
	)


func _local_time_text() -> String:
	return Time.get_datetime_string_from_system(false, true)


func _success(data: Dictionary) -> Dictionary:
	return {
		"success": true,
		"data": data,
	}


func _failure(message: String) -> Dictionary:
	return {
		"success": false,
		"message": message,
	}
