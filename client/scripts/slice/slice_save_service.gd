class_name SliceSaveService
extends RefCounted

## Lightweight save service for the slice world. Physically isolated from the
## frozen legacy SaveService: its own directory, schema and JSON layout, no
## shared code or state. Persists the slice loop state (crystal and catalyst
## counts, the repaired and reactor-active flags, harvested cluster names,
## placed collectors, carry state, player position) as plain JSON with one
## rotated backup and an atomic temp-then-rename write. New fields are appended
## as optional keys (default on absence), so schema stays 1 with no migration.

const SAVE_SCHEMA_VERSION := 1
const GAME_VERSION := "prototype-slice-01"
const SAVE_DIR := "user://saves/slice"
const SAVE_FILE := "user://saves/slice/slice_world.json"
const SAVE_BACKUP_FILE := "user://saves/slice/slice_world.bak.json"
const SAVE_TEMP_FILE := "user://saves/slice/slice_world.tmp.json"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_FILE) or FileAccess.file_exists(SAVE_BACKUP_FILE)


func save_state(state: Dictionary) -> Dictionary:
	var dir_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(SAVE_DIR))
	if dir_error != OK and not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(SAVE_DIR)):
		return _failure("创建切片存档目录失败：%s。" % error_string(dir_error))

	var save_data := {
		"save_schema_version": SAVE_SCHEMA_VERSION,
		"game_version": GAME_VERSION,
		"updated_at": _local_time_text(),
		"crystal_count": int(state.get("crystal_count", 0)),
		"catalyst_count": int(state.get("catalyst_count", 0)),
		"core_repaired": bool(state.get("core_repaired", false)),
		"core_energy": int(state.get("core_energy", 0)),
		"reactor_active": bool(state.get("reactor_active", false)),
		"harvested_clusters": _string_array(state.get("harvested_clusters", [])),
		"collectors": _cell_array(state.get("collectors", [])),
		"carrying_collector": bool(state.get("carrying_collector", false)),
		"player_x": float(state.get("player_x", 0.0)),
		"player_y": float(state.get("player_y", 0.0))
	}

	var temp := FileAccess.open(SAVE_TEMP_FILE, FileAccess.WRITE)
	if temp == null:
		return _failure("打开切片存档临时文件失败：%s。" % error_string(FileAccess.get_open_error()))
	temp.store_string(JSON.stringify(save_data, "\t"))
	temp.close()

	if FileAccess.file_exists(SAVE_FILE):
		var backup_error := DirAccess.copy_absolute(
			ProjectSettings.globalize_path(SAVE_FILE),
			ProjectSettings.globalize_path(SAVE_BACKUP_FILE)
		)
		if backup_error != OK:
			return _failure("备份切片存档失败：%s。当前存档未被覆盖。" % error_string(backup_error))

	var rename_error := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(SAVE_TEMP_FILE),
		ProjectSettings.globalize_path(SAVE_FILE)
	)
	if rename_error != OK:
		return _failure("写入切片存档失败：%s。" % error_string(rename_error))
	return _success("已保存切片存档。")


func load_state() -> Dictionary:
	for save_file in [SAVE_FILE, SAVE_BACKUP_FILE]:
		if not FileAccess.file_exists(save_file):
			continue
		var read_result := _read_file(save_file)
		if bool(read_result.get("success", false)):
			return read_result
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
	var details := "晶体 %d；%s；最近保存 %s" % [
		int(data.get("crystal_count", 0)),
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
	if version != SAVE_SCHEMA_VERSION:
		return _failure("切片存档版本不兼容（文件版本 %d，当前支持 %d），当前运行状态已保留。" % [
			version, SAVE_SCHEMA_VERSION
		])

	return {
		"success": true,
		"message": "已读取切片存档。",
		"data": {
			"crystal_count": int(save_data.get("crystal_count", 0)),
			"catalyst_count": int(save_data.get("catalyst_count", 0)),
			"core_repaired": bool(save_data.get("core_repaired", false)),
			"core_energy": int(save_data.get("core_energy", 0)),
			"reactor_active": bool(save_data.get("reactor_active", false)),
			"harvested_clusters": _string_array(save_data.get("harvested_clusters", [])),
			"collectors": _cell_array(save_data.get("collectors", [])),
			"carrying_collector": bool(save_data.get("carrying_collector", false)),
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


## Collector cells travel as [[x, y], ...]; malformed entries are dropped.
func _cell_array(value) -> Array:
	var result: Array = []
	if value is Array:
		for item in value:
			if item is Array and item.size() == 2:
				result.append([int(item[0]), int(item[1])])
	return result


func _local_time_text() -> String:
	return Time.get_datetime_string_from_system(false, true)


func _success(message: String) -> Dictionary:
	return {"success": true, "message": message}


func _failure(message: String) -> Dictionary:
	return {"success": false, "message": message}
