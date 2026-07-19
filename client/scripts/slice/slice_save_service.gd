class_name SliceSaveService
extends RefCounted

## Lightweight save service for the slice world. Physically isolated from the
## frozen legacy SaveService: its own directory, schema and JSON layout, no
## shared code or state. Persists the slice loop state as plain JSON with one
## rotated backup and an atomic temp-then-rename write.
##
## Schema 2 (L0 resource model, docs/features/slice-item-inventory-model-v1.md):
## the player backpack is stored as an inventory dict and collectors carry their
## output buffer. Schema 1 (the abstract global-counter prototype) is not
## migrated — a version mismatch starts a fresh slice, acceptable for the single
## throwaway prototype save in the slice phase.

const SAVE_SCHEMA_VERSION := 2
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
		"pocket": _inventory_dict(state.get("pocket", {})),
		"catalyst_count": int(state.get("catalyst_count", 0)),
		"core_repaired": bool(state.get("core_repaired", false)),
		"core_energy": int(state.get("core_energy", 0)),
		"reactor_active": bool(state.get("reactor_active", false)),
		"harvested_clusters": _string_array(state.get("harvested_clusters", [])),
		"collectors": _collector_array(state.get("collectors", [])),
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
	var pocket_dict: Dictionary = data.get("pocket", {})
	var contents = pocket_dict.get("contents", {})
	var crystal := int(contents.get(SliceWorld.ITEM_CRYSTAL, 0)) if contents is Dictionary else 0
	var details := "背包晶体 %d；%s；最近保存 %s" % [
		crystal,
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
			"pocket": _inventory_dict(save_data.get("pocket", {})),
			"catalyst_count": int(save_data.get("catalyst_count", 0)),
			"core_repaired": bool(save_data.get("core_repaired", false)),
			"core_energy": int(save_data.get("core_energy", 0)),
			"reactor_active": bool(save_data.get("reactor_active", false)),
			"harvested_clusters": _string_array(save_data.get("harvested_clusters", [])),
			"collectors": _collector_array(save_data.get("collectors", [])),
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


## Collectors travel as [{cell:[x, y], buffer:n}, ...]; malformed entries drop.
func _collector_array(value) -> Array:
	var result: Array = []
	if value is Array:
		for item in value:
			if not (item is Dictionary):
				continue
			var cell = item.get("cell", null)
			if cell is Array and cell.size() == 2:
				result.append({
					"cell": [int(cell[0]), int(cell[1])],
					"buffer": int(item.get("buffer", 0))
				})
	return result


func _local_time_text() -> String:
	return Time.get_datetime_string_from_system(false, true)


func _success(message: String) -> Dictionary:
	return {"success": true, "message": message}


func _failure(message: String) -> Dictionary:
	return {"success": false, "message": message}
