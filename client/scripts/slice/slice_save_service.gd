class_name SliceSaveService
extends RefCounted

## Lightweight save service for the slice world. Physically isolated from the
## frozen legacy SaveService: its own directory, schema and JSON layout, no
## shared code or state. Persists the slice loop state as plain JSON with one
## rotated backup and an atomic temp-then-rename write.
##
## Schema 5 adds L4 conveyor cargo while retaining the stable building topology
## introduced by schema 4. Schema 2 / 3 collectors migrate into that topology;
## schema 1 remains unsupported.

const SAVE_SCHEMA_VERSION := 5
const MIN_SUPPORTED_SCHEMA_VERSION := 2
const GAME_VERSION := "prototype-slice-05"
const DEFAULT_SAVE_DIR := "user://saves/slice"
const LEGACY_CORE_STORAGE_CAPACITY := 120

var _save_dir: String
var _save_file: String
var _save_backup_file: String
var _save_temp_file: String


func _init(save_dir: String = DEFAULT_SAVE_DIR) -> void:
	_save_dir = save_dir.trim_suffix("/")
	_save_file = _save_dir.path_join("slice_world.json")
	_save_backup_file = _save_dir.path_join("slice_world.bak.json")
	_save_temp_file = _save_dir.path_join("slice_world.tmp.json")


func has_save() -> bool:
	return FileAccess.file_exists(_save_file) or FileAccess.file_exists(_save_backup_file)


func save_state(state: Dictionary) -> Dictionary:
	var absolute_save_dir := ProjectSettings.globalize_path(_save_dir)
	var dir_error := DirAccess.make_dir_recursive_absolute(absolute_save_dir)
	if dir_error != OK and not DirAccess.dir_exists_absolute(absolute_save_dir):
		return _failure("创建切片存档目录失败：%s。" % error_string(dir_error))

	var save_data := {
		"save_schema_version": SAVE_SCHEMA_VERSION,
		"game_version": GAME_VERSION,
		"updated_at": _local_time_text(),
		"pocket": _inventory_dict(state.get("pocket", {})),
		"core_storage": _inventory_dict(state.get("core_storage", {})),
		"catalyst_count": int(state.get("catalyst_count", 0)),
		"core_repaired": bool(state.get("core_repaired", false)),
		"core_energy": int(state.get("core_energy", 0)),
		"reactor_active": bool(state.get("reactor_active", false)),
		"harvested_clusters": _string_array(state.get("harvested_clusters", [])),
		"buildings": state.get("buildings", []),
		"next_building_serial": int(state.get("next_building_serial", 1)),
		"player_x": float(state.get("player_x", 0.0)),
		"player_y": float(state.get("player_y", 0.0))
	}
	var building_result := SliceBuildingSaveCodec.validate_schema_five(
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

	if FileAccess.file_exists(_save_file):
		var backup_error := DirAccess.copy_absolute(
			ProjectSettings.globalize_path(_save_file),
			ProjectSettings.globalize_path(_save_backup_file)
		)
		if backup_error != OK:
			return _failure("备份切片存档失败：%s。当前存档未被覆盖。" % error_string(backup_error))

	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(_save_temp_file),
		ProjectSettings.globalize_path(_save_file)
	)
	if rename_error != OK:
		return _failure("写入切片存档失败：%s。" % error_string(rename_error))
	return _success("已保存切片存档。")


func load_state() -> Dictionary:
	var last_failure: Dictionary = {}
	for save_file in [_save_file, _save_backup_file]:
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
	if not bool(result.get("success", false)):
		var status := "存档不可读取" if has_save() else "空存档"
		var details := String(result.get("message", "")) if has_save() else "尚未保存切片进度。"
		return {
			"has_loadable_save": false,
			"display_name": "切片存档",
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
		"display_name": "切片存档",
		"status": "可读取",
		"details": details
	}


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
	if version >= 4:
		building_result = SliceBuildingSaveCodec.validate_schema_five(
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
	if not bool(building_result.get("success", false)):
		return building_result
	var building_data: Dictionary = building_result["data"]

	return {
		"success": true,
		"message": "已读取切片存档。",
		"data": {
			"pocket": pocket,
			"core_storage": core_storage,
			"catalyst_count": int(save_data.get("catalyst_count", 0)),
			"core_repaired": bool(save_data.get("core_repaired", false)),
			"core_energy": int(save_data.get("core_energy", 0)),
			"reactor_active": bool(save_data.get("reactor_active", false)),
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


func _local_time_text() -> String:
	return Time.get_datetime_string_from_system(false, true)


func _success(message: String) -> Dictionary:
	return {"success": true, "message": message}


func _failure(message: String) -> Dictionary:
	return {"success": false, "message": message}
