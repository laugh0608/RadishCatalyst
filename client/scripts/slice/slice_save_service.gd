class_name SliceSaveService
extends RefCounted

## Lightweight save service for the slice world. Physically isolated from the
## frozen legacy SaveService: its own directory, schema and JSON layout, no
## shared code or state. Persists one slice world as plain JSON with atomic
## temp-then-rename writes. Legacy callers keep one backup; multi-world callers
## use autosave.json plus three rotated backups and lightweight metadata.
##
## Schema 6 adds per-reactor inventories and retained production state. Schema
## 2–5 migrate into the current topology; legacy global catalyst is restored to
## core storage, while the obsolete reactor activation flag is discarded.

const SAVE_SCHEMA_VERSION := 6
const MIN_SUPPORTED_SCHEMA_VERSION := 2
const GAME_VERSION := "prototype-slice-06"
const DEFAULT_SAVE_DIR := "user://saves/slice"
const LEGACY_CORE_STORAGE_CAPACITY := 120
const LEGACY_SAVE_FILE_NAME := "slice_world.json"
const WORLD_SAVE_FILE_NAME := "autosave.json"
const WORLD_BACKUP_COUNT := 3
const WORLD_METADATA_SCHEMA_VERSION := 1

var _save_dir: String
var _save_file: String
var _save_temp_file: String
var _save_backup_files: Array[String] = []
var _world_id := ""
var _metadata_file := ""
var _metadata_temp_file := ""


func _init(
	save_dir: String = DEFAULT_SAVE_DIR,
	save_file_name: String = LEGACY_SAVE_FILE_NAME,
	backup_count: int = 1,
	world_id: String = ""
) -> void:
	_save_dir = save_dir.trim_suffix("/")
	_save_file = _save_dir.path_join(save_file_name)
	var stem := save_file_name.trim_suffix(".json")
	_save_temp_file = _save_dir.path_join("%s.tmp.json" % stem)
	_world_id = world_id
	if not _world_id.is_empty():
		_metadata_file = _save_dir.path_join("metadata.json")
		_metadata_temp_file = _save_dir.path_join("metadata.tmp.json")
	if save_file_name == LEGACY_SAVE_FILE_NAME and backup_count == 1:
		_save_backup_files.append(
			_save_dir.path_join("slice_world.bak.json")
		)
		return
	var backups_dir := _save_dir.path_join("backups")
	for index in range(1, maxi(backup_count, 0) + 1):
		_save_backup_files.append(
			backups_dir.path_join("%s.bak.%d.json" % [stem, index])
		)


static func for_world(
	world_dir: String,
	world_id: String
) -> SliceSaveService:
	return SliceSaveService.new(
		world_dir,
		WORLD_SAVE_FILE_NAME,
		WORLD_BACKUP_COUNT,
		world_id
	)


func save_directory() -> String:
	return _save_dir


func save_file_path() -> String:
	return _save_file


func backup_file_paths() -> Array[String]:
	return _save_backup_files.duplicate()


func has_save() -> bool:
	if FileAccess.file_exists(_save_file):
		return true
	for backup_file in _save_backup_files:
		if FileAccess.file_exists(backup_file):
			return true
	return false


func save_state(state: Dictionary) -> Dictionary:
	var absolute_save_dir := ProjectSettings.globalize_path(_save_dir)
	var dir_error := DirAccess.make_dir_recursive_absolute(absolute_save_dir)
	if dir_error != OK and not DirAccess.dir_exists_absolute(absolute_save_dir):
		return _failure("创建切片存档目录失败：%s。" % error_string(dir_error))
	if not _save_backup_files.is_empty():
		var backup_dir := ProjectSettings.globalize_path(
			_save_backup_files[0].get_base_dir()
		)
		var backup_dir_error := DirAccess.make_dir_recursive_absolute(backup_dir)
		if (
			backup_dir_error != OK
			and not DirAccess.dir_exists_absolute(backup_dir)
		):
			return _failure(
				"创建切片备份目录失败：%s。"
				% error_string(backup_dir_error)
			)

	var save_data := {
		"save_schema_version": SAVE_SCHEMA_VERSION,
		"game_version": GAME_VERSION,
		"updated_at": _local_time_text(),
		"pocket": _inventory_dict(state.get("pocket", {})),
		"core_storage": _inventory_dict(state.get("core_storage", {})),
		"core_repaired": bool(state.get("core_repaired", false)),
		"core_energy": int(state.get("core_energy", 0)),
		"harvested_clusters": _string_array(state.get("harvested_clusters", [])),
		"buildings": state.get("buildings", []),
		"next_building_serial": int(state.get("next_building_serial", 1)),
		"player_x": float(state.get("player_x", 0.0)),
		"player_y": float(state.get("player_y", 0.0))
	}
	var building_result := SliceBuildingSaveCodec.validate_schema_six(
		save_data["buildings"], save_data["next_building_serial"]
	)
	if not bool(building_result.get("success", false)):
		return building_result
	var building_data: Dictionary = building_result["data"]
	save_data["buildings"] = building_data["buildings"]
	save_data["next_building_serial"] = building_data["next_building_serial"]

	var temp := FileAccess.open(_save_temp_file, FileAccess.WRITE)
	if temp == null:
		return _failure("打开切片存档临时文件失败：%s。" % error_string(FileAccess.get_open_error()))
	temp.store_string(JSON.stringify(save_data, "\t"))
	temp.close()

	var backup_error := _rotate_backups()
	if backup_error != OK:
		return _failure(
			"备份切片存档失败：%s。当前主档未被覆盖。"
			% error_string(backup_error)
		)

	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(_save_temp_file),
		ProjectSettings.globalize_path(_save_file)
	)
	if rename_error != OK:
		return _failure("写入切片存档失败：%s。" % error_string(rename_error))
	var metadata_error := _update_world_metadata(save_data)
	if not metadata_error.is_empty():
		return {
			"success": true,
			"message": "已保存世界状态，但更新列表摘要失败：%s。" % metadata_error,
			"warning": metadata_error,
		}
	return _success("已保存切片存档。")


func load_state() -> Dictionary:
	var last_failure: Dictionary = {}
	var candidates: Array[String] = [_save_file]
	candidates.append_array(_save_backup_files)
	for save_file in candidates:
		if not FileAccess.file_exists(save_file):
			continue
		var read_result := _read_file(save_file)
		if bool(read_result.get("success", false)):
			read_result["source_path"] = save_file
			return read_result
		last_failure = read_result
	if not last_failure.is_empty():
		return last_failure
	return _failure("读取切片存档失败：未找到可用存档，当前运行状态已保留。")


func get_summary() -> Dictionary:
	var result := load_state()
	var display_name := "切片存档"
	var metadata := _read_world_metadata()
	if not metadata.is_empty():
		display_name = String(metadata.get("display_name", display_name))
	if not bool(result.get("success", false)):
		var status := "存档不可读取" if has_save() else "空存档"
		var details := String(result.get("message", "")) if has_save() else "尚未保存切片进度。"
		return {
			"has_loadable_save": false,
			"display_name": display_name,
			"status": status,
			"details": details
		}

	var data: Dictionary = result.get("data", {})
	var repaired_text := "核心已修复" if bool(data.get("core_repaired", false)) else "核心未修复"
	var pocket_dict: Dictionary = data.get("pocket", {})
	var core_storage_dict: Dictionary = data.get("core_storage", {})
	var contents = pocket_dict.get("contents", {})
	var core_contents = core_storage_dict.get("contents", {})
	var crystal := int(contents.get(SliceWorld.ITEM_CRYSTAL, 0)) if contents is Dictionary else 0
	var stored := 0
	if core_contents is Dictionary:
		for amount in core_contents.values():
			stored += int(amount)
	var details := "背包晶体 %d；核心仓库 %d；%s；最近保存 %s" % [
		crystal,
		stored,
		repaired_text,
		String(data.get("updated_at", "未知时间"))
	]
	return {
		"has_loadable_save": true,
		"display_name": display_name,
		"status": "可读取",
		"details": details
	}


func _rotate_backups() -> Error:
	if not FileAccess.file_exists(_save_file):
		return OK
	for index in range(_save_backup_files.size() - 1, 0, -1):
		var source := _save_backup_files[index - 1]
		if not FileAccess.file_exists(source):
			continue
		var copy_error := DirAccess.copy_absolute(
			ProjectSettings.globalize_path(source),
			ProjectSettings.globalize_path(_save_backup_files[index])
		)
		if copy_error != OK:
			return copy_error
	if _save_backup_files.is_empty():
		return OK
	return DirAccess.copy_absolute(
		ProjectSettings.globalize_path(_save_file),
		ProjectSettings.globalize_path(_save_backup_files[0])
	)


func _update_world_metadata(save_data: Dictionary) -> String:
	if _metadata_file.is_empty():
		return ""
	var metadata := _read_world_metadata()
	var now := String(save_data.get("updated_at", _local_time_text()))
	if metadata.is_empty():
		metadata = {
			"metadata_schema_version": WORLD_METADATA_SCHEMA_VERSION,
			"world_id": _world_id,
			"display_name": "未命名世界",
			"created_at": now,
			"play_time_seconds": 0,
		}
	metadata["metadata_schema_version"] = WORLD_METADATA_SCHEMA_VERSION
	metadata["world_id"] = _world_id
	metadata["updated_at"] = now
	metadata["game_version"] = GAME_VERSION
	metadata["save_schema_version"] = SAVE_SCHEMA_VERSION
	metadata["core_repaired"] = bool(save_data.get("core_repaired", false))
	var buildings = save_data.get("buildings", [])
	metadata["building_count"] = buildings.size() if buildings is Array else 0
	metadata["catalyst_count"] = _saved_item_count(
		save_data,
		SliceWorld.ITEM_CATALYST
	)
	var file := FileAccess.open(_metadata_temp_file, FileAccess.WRITE)
	if file == null:
		return error_string(FileAccess.get_open_error())
	file.store_string(JSON.stringify(metadata, "\t"))
	file.close()
	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(_metadata_temp_file),
		ProjectSettings.globalize_path(_metadata_file)
	)
	return "" if rename_error == OK else error_string(rename_error)


func _read_world_metadata() -> Dictionary:
	if _metadata_file.is_empty() or not FileAccess.file_exists(_metadata_file):
		return {}
	var file := FileAccess.open(_metadata_file, FileAccess.READ)
	if file == null:
		return {}
	var parsed = JSON.parse_string(file.get_as_text())
	file.close()
	return parsed if parsed is Dictionary else {}


func _saved_item_count(save_data: Dictionary, item_id: String) -> int:
	var total := _inventory_item_count(save_data.get("pocket", {}), item_id)
	total += _inventory_item_count(save_data.get("core_storage", {}), item_id)
	var buildings = save_data.get("buildings", [])
	if not (buildings is Array):
		return total
	for building in buildings:
		if not (building is Dictionary):
			continue
		var state = building.get("state", {})
		if not (state is Dictionary):
			continue
		total += _inventory_item_count(state.get("inventory", {}), item_id)
		total += _inventory_item_count(
			state.get("input_inventory", {}),
			item_id
		)
		total += _inventory_item_count(
			state.get("output_inventory", {}),
			item_id
		)
		var cargo = state.get("cargo", {})
		if cargo is Dictionary and String(cargo.get("item_id", "")) == item_id:
			total += 1
	return total


func _inventory_item_count(value, item_id: String) -> int:
	if not (value is Dictionary):
		return 0
	var contents = value.get("contents", {})
	return int(contents.get(item_id, 0)) if contents is Dictionary else 0


func _read_file(save_file: String) -> Dictionary:
	var file := FileAccess.open(save_file, FileAccess.READ)
	if file == null:
		return _failure("打开切片存档失败：%s。当前运行状态已保留。" % error_string(FileAccess.get_open_error()))
	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(content) != OK:
		return _failure("切片存档 JSON 解析失败：%s（第 %d 行）。当前运行状态已保留。" % [
			json.get_error_message(), json.get_error_line()
		])
	if not (json.data is Dictionary):
		return _failure("切片存档根对象格式无效，当前运行状态已保留。")

	var save_data: Dictionary = json.data
	var version := int(save_data.get("save_schema_version", -1))
	if version < MIN_SUPPORTED_SCHEMA_VERSION or version > SAVE_SCHEMA_VERSION:
		return _failure("切片存档版本不兼容（文件版本 %d，当前支持 %d），当前运行状态已保留。" % [
			version, SAVE_SCHEMA_VERSION
		])

	var pocket := _inventory_dict(save_data.get("pocket", {}))
	var core_storage := _inventory_dict(save_data.get("core_storage", {}))
	var building_result: Dictionary
	if version >= 6:
		building_result = SliceBuildingSaveCodec.validate_schema_six(
			save_data.get("buildings", null),
			save_data.get("next_building_serial", null)
		)
	elif version >= 4:
		building_result = SliceBuildingSaveCodec.migrate_schema_five(
			save_data.get("buildings", null),
			save_data.get("next_building_serial", null)
		)
	else:
		building_result = SliceBuildingSaveCodec.migrate_legacy_collectors(
			save_data.get("collectors", [])
		)
		if bool(save_data.get("carrying_collector", false)):
			pocket = SliceBuildingSaveCodec.add_legacy_carried_collector(pocket)
		if version == 2:
			core_storage = {
				"capacity": LEGACY_CORE_STORAGE_CAPACITY,
				"contents": {},
			}
	if version <= 5:
		core_storage = _restore_legacy_item(
			core_storage,
			SliceWorld.ITEM_CATALYST,
			int(save_data.get("catalyst_count", 0))
		)
	if not bool(building_result.get("success", false)):
		return building_result
	var building_data: Dictionary = building_result["data"]

	return {
		"success": true,
		"message": "已读取切片存档。",
		"data": {
			"pocket": pocket,
			"core_storage": core_storage,
			"catalyst_count": 0,
			"core_repaired": bool(save_data.get("core_repaired", false)),
			"core_energy": int(save_data.get("core_energy", 0)),
			"reactor_active": false,
			"harvested_clusters": _string_array(save_data.get("harvested_clusters", [])),
			"buildings": building_data["buildings"],
			"next_building_serial": building_data["next_building_serial"],
			"player_x": float(save_data.get("player_x", 0.0)),
			"player_y": float(save_data.get("player_y", 0.0)),
			"updated_at": String(save_data.get("updated_at", ""))
		}
	}


func _string_array(value) -> Array[String]:
	var result: Array[String] = []
	if value is Array:
		for item in value:
			result.append(String(item))
	return result


## Normalizes an inventory payload to {capacity, contents{item:count>0}}.
func _inventory_dict(value) -> Dictionary:
	var capacity := 0
	var contents := {}
	if value is Dictionary:
		capacity = int(value.get("capacity", 0))
		var raw = value.get("contents", {})
		if raw is Dictionary:
			for key in raw:
				var n := int(raw[key])
				if n > 0:
					contents[String(key)] = n
	return {"capacity": capacity, "contents": contents}


func _restore_legacy_item(
	inventory: Dictionary,
	item_id: String,
	amount: int
) -> Dictionary:
	var restored := inventory.duplicate(true)
	if amount <= 0:
		return restored
	var contents: Dictionary = restored.get("contents", {})
	contents[item_id] = int(contents.get(item_id, 0)) + amount
	restored["contents"] = contents
	return restored


func _local_time_text() -> String:
	return Time.get_datetime_string_from_system(false, true)


func _success(message: String) -> Dictionary:
	return {"success": true, "message": message}


func _failure(message: String) -> Dictionary:
	return {"success": false, "message": message}
