extends RefCounted
class_name SaveService

const SAVE_SCHEMA_VERSION := 1
const GAME_VERSION := "prototype-slice-01"
const SAVE_ROOT_DIR := "user://saves"
const SAVE_SLOT_ROOT_DIR := "user://saves/slots"
const DEFAULT_SLOT_ID := "slot_01"
const SAVE_FILE_NAME := "slice_01_autosave.json"
const SAVE_DIR := "user://saves/slots/slot_01"
const SAVE_FILE := "user://saves/slots/slot_01/slice_01_autosave.json"
const SAVE_BACKUP_FILE := "user://saves/slots/slot_01/slice_01_autosave.bak.1.json"
const SAVE_BACKUP_FILES := [
	"user://saves/slots/slot_01/slice_01_autosave.bak.1.json",
	"user://saves/slots/slot_01/slice_01_autosave.bak.2.json",
	"user://saves/slots/slot_01/slice_01_autosave.bak.3.json"
]
const LEGACY_SAVE_FILE := "user://saves/slice_01_autosave.json"
const LEGACY_SAVE_BACKUP_FILES := [
	"user://saves/slice_01_autosave.bak.1.json",
	"user://saves/slice_01_autosave.bak.2.json",
	"user://saves/slice_01_autosave.bak.3.json"
]
var data_registry: DataRegistry
var content_validator: SaveContentValidator


func save_game(world_state: WorldState, character_state: CharacterState) -> Dictionary:
	return save_game_for_slot(DEFAULT_SLOT_ID, world_state, character_state)


func setup(registry: DataRegistry) -> void:
	data_registry = registry
	content_validator = SaveContentValidator.new(data_registry)


func save_game_for_slot(slot_id: String, world_state: WorldState, character_state: CharacterState) -> Dictionary:
	var paths := _get_slot_paths(slot_id)
	var save_file := String(paths.get("save_file", SAVE_FILE))
	var dir_result := _ensure_slot_dir(paths)
	if not bool(dir_result.get("success", false)):
		return dir_result

	var now := Time.get_datetime_string_from_system(true, true)
	var save_data := {
		"save_schema_version": SAVE_SCHEMA_VERSION,
		"game_version": GAME_VERSION,
		"created_at": _read_existing_created_at(now, save_file),
		"updated_at": now,
		"world": world_state.to_dict(),
		"character": character_state.to_dict()
	}

	var backup_result := _backup_existing_save(paths)
	if not bool(backup_result.get("success", false)):
		return backup_result

	var write_result := _write_save_data(save_file, save_data)
	if not bool(write_result.get("success", false)):
		return write_result

	if bool(backup_result.get("backup_created", false)):
		return _success("已保存原型存档，并轮转最近 3 份备份。")
	return _success("已保存原型存档。")


func load_game() -> Dictionary:
	return load_game_for_slot(DEFAULT_SLOT_ID)


func load_game_for_slot(slot_id: String) -> Dictionary:
	var paths := _get_slot_paths(slot_id)
	var candidates: Array[String] = [String(paths.get("save_file", SAVE_FILE))]
	for backup_path in paths.get("backup_files", SAVE_BACKUP_FILES):
		candidates.append(String(backup_path))

	var first_failure_message := ""
	var attempted_file_count := 0
	for index in range(candidates.size()):
		var save_file := candidates[index]
		if not FileAccess.file_exists(save_file):
			continue

		attempted_file_count += 1
		var read_result := _read_save_file(save_file)
		if bool(read_result.get("success", false)):
			var save_data: Dictionary = read_result.get("save_data", {})
			var message := "已读取原型存档。"
			if index > 0:
				message = "主存档不可用，已从最近备份 %d 恢复原型存档。" % index
			return {
				"success": true,
				"message": message,
				"world_state": WorldState.from_dict(save_data.get("world", {})),
				"character_state": CharacterState.from_dict(save_data.get("character", {})),
				"slot_id": String(paths.get("slot_id", DEFAULT_SLOT_ID)),
				"recovered_from_backup": index > 0,
				"source_file": save_file
			}

		if first_failure_message.is_empty():
			first_failure_message = String(read_result.get("message", "读取存档失败，当前运行状态已保留。"))

	if attempted_file_count > 0:
		return _failure(first_failure_message)

	if String(paths.get("slot_id", DEFAULT_SLOT_ID)) == DEFAULT_SLOT_ID:
		return _load_legacy_save_into_slot(paths)

	return _failure("读取存档失败：未找到原型存档文件或可用备份，当前运行状态已保留。")


func delete_game_for_slot(slot_id: String) -> Dictionary:
	var paths := _get_slot_paths(slot_id)
	var candidates: Array[String] = [String(paths.get("save_file", SAVE_FILE))]
	for backup_path in paths.get("backup_files", SAVE_BACKUP_FILES):
		candidates.append(String(backup_path))
	if String(paths.get("slot_id", DEFAULT_SLOT_ID)) == DEFAULT_SLOT_ID:
		candidates.append(LEGACY_SAVE_FILE)
		for legacy_backup_path in LEGACY_SAVE_BACKUP_FILES:
			candidates.append(String(legacy_backup_path))

	var deleted_count := 0
	for save_file in candidates:
		if not FileAccess.file_exists(save_file):
			continue
		var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(save_file))
		if remove_error != OK:
			return _failure("清空槽位失败：删除存档文件失败：%s。" % error_string(remove_error))
		deleted_count += 1

	if deleted_count <= 0:
		return _success("槽位已是空槽。")
	return _success("已清空槽位存档和备份。")


func get_save_slot_summaries(slot_ids: Array[String]) -> Array[Dictionary]:
	var summaries: Array[Dictionary] = []
	for slot_id in slot_ids:
		summaries.append(get_save_slot_summary(slot_id))
	return summaries


func get_save_slot_summary(slot_id: String) -> Dictionary:
	var paths := _get_slot_paths(slot_id)
	var candidates: Array[String] = [String(paths.get("save_file", SAVE_FILE))]
	for backup_path in paths.get("backup_files", SAVE_BACKUP_FILES):
		candidates.append(String(backup_path))

	var first_failure_message := ""
	var attempted_file_count := 0
	for index in range(candidates.size()):
		var save_file := candidates[index]
		if not FileAccess.file_exists(save_file):
			continue

		attempted_file_count += 1
		var read_result := _read_save_file(save_file)
		if bool(read_result.get("success", false)):
			return _format_slot_summary(
				String(paths.get("slot_id", DEFAULT_SLOT_ID)),
				read_result.get("save_data", {}),
				index,
				false,
				save_file
			)

		if first_failure_message.is_empty():
			first_failure_message = String(read_result.get("message", "存档不可读取。"))

	if attempted_file_count > 0:
		return {
			"slot_id": String(paths.get("slot_id", DEFAULT_SLOT_ID)),
			"display_name": _format_slot_display_name(String(paths.get("slot_id", DEFAULT_SLOT_ID))),
			"status": "存档不可读取",
			"details": first_failure_message,
			"has_loadable_save": false
		}

	if String(paths.get("slot_id", DEFAULT_SLOT_ID)) == DEFAULT_SLOT_ID:
		var legacy_summary := _get_legacy_slot_summary(paths)
		if bool(legacy_summary.get("has_loadable_save", false)):
			return legacy_summary

	return {
		"slot_id": String(paths.get("slot_id", DEFAULT_SLOT_ID)),
		"display_name": _format_slot_display_name(String(paths.get("slot_id", DEFAULT_SLOT_ID))),
		"status": "空槽位",
		"details": "尚未保存原型进度。",
		"has_loadable_save": false
	}


func _load_legacy_save_into_slot(paths: Dictionary) -> Dictionary:
	var legacy_candidates: Array[String] = [LEGACY_SAVE_FILE]
	for backup_path in LEGACY_SAVE_BACKUP_FILES:
		legacy_candidates.append(String(backup_path))

	var first_failure_message := ""
	var attempted_file_count := 0
	for index in range(legacy_candidates.size()):
		var legacy_file := legacy_candidates[index]
		if not FileAccess.file_exists(legacy_file):
			continue

		attempted_file_count += 1
		var read_result := _read_save_file(legacy_file)
		if bool(read_result.get("success", false)):
			var save_data: Dictionary = read_result.get("save_data", {})
			var migration_result := _migrate_save_data_to_slot(paths, save_data)
			if not bool(migration_result.get("success", false)):
				return migration_result

			var message := "已从旧原型存档迁移到默认槽位。"
			if index > 0:
				message = "已从旧原型备份 %d 迁移到默认槽位。" % index
			return {
				"success": true,
				"message": message,
				"world_state": WorldState.from_dict(save_data.get("world", {})),
				"character_state": CharacterState.from_dict(save_data.get("character", {})),
				"slot_id": String(paths.get("slot_id", DEFAULT_SLOT_ID)),
				"migrated_from_legacy": true,
				"source_file": legacy_file
			}

		if first_failure_message.is_empty():
			first_failure_message = String(read_result.get("message", "读取旧原型存档失败，当前运行状态已保留。"))

	if attempted_file_count > 0:
		return _failure("读取旧原型存档失败：%s" % first_failure_message)

	return _failure("读取存档失败：未找到原型存档文件或可用备份，当前运行状态已保留。")


func _get_legacy_slot_summary(paths: Dictionary) -> Dictionary:
	var legacy_candidates: Array[String] = [LEGACY_SAVE_FILE]
	for backup_path in LEGACY_SAVE_BACKUP_FILES:
		legacy_candidates.append(String(backup_path))

	for index in range(legacy_candidates.size()):
		var legacy_file := legacy_candidates[index]
		if not FileAccess.file_exists(legacy_file):
			continue

		var read_result := _read_save_file(legacy_file)
		if bool(read_result.get("success", false)):
			return _format_slot_summary(
				String(paths.get("slot_id", DEFAULT_SLOT_ID)),
				read_result.get("save_data", {}),
				index,
				true,
				legacy_file
			)

	return {
		"slot_id": String(paths.get("slot_id", DEFAULT_SLOT_ID)),
		"display_name": _format_slot_display_name(String(paths.get("slot_id", DEFAULT_SLOT_ID))),
		"status": "空槽位",
		"details": "尚未保存原型进度。",
		"has_loadable_save": false
	}


func _migrate_save_data_to_slot(paths: Dictionary, save_data: Dictionary) -> Dictionary:
	var dir_result := _ensure_slot_dir(paths)
	if not bool(dir_result.get("success", false)):
		return _failure("旧原型存档可读取，但迁移到默认槽位失败：%s" % String(dir_result.get("message", "")))

	var save_file := String(paths.get("save_file", SAVE_FILE))
	var write_result := _write_save_data(save_file, save_data)
	if not bool(write_result.get("success", false)):
		return _failure("旧原型存档可读取，但迁移到默认槽位失败：%s" % String(write_result.get("message", "")))

	return _success("已迁移旧原型存档。")


func _read_save_file(save_file: String) -> Dictionary:
	if not FileAccess.file_exists(save_file):
		return _failure("读取存档失败：未找到原型存档文件，当前运行状态已保留。")

	var file := FileAccess.open(save_file, FileAccess.READ)
	if file == null:
		return _failure("读取存档失败：打开存档文件失败：%s。当前运行状态已保留。" % error_string(FileAccess.get_open_error()))

	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_error := json.parse(content)
	if parse_error != OK:
		return _failure("读取存档失败：JSON 解析失败：%s（第 %d 行）。当前运行状态已保留。" % [
			json.get_error_message(),
			json.get_error_line()
		])

	var save_data = json.data
	if not save_data is Dictionary:
		return _failure("读取存档失败：存档根对象格式无效，当前运行状态已保留。")

	var validation_error := _validate_save_data(save_data)
	if not validation_error.is_empty():
		return _failure(validation_error)
	var content_error := _validate_save_content(save_data)
	if not content_error.is_empty():
		return _failure(content_error)

	return {
		"success": true,
		"message": "已读取原型存档。",
		"save_data": save_data
	}


func _format_slot_summary(
	slot_id: String,
	save_data: Dictionary,
	source_index: int,
	is_legacy_source: bool,
	source_file: String
) -> Dictionary:
	var status := "可读取"
	if is_legacy_source:
		status = "旧原型存档可导入"
	elif source_index > 0:
		status = "主档不可用，可从备份 %d 恢复" % source_index

	return {
		"slot_id": slot_id,
		"display_name": _format_slot_display_name(slot_id),
		"status": status,
		"details": _format_slot_details(save_data),
		"has_loadable_save": true,
		"source_file": source_file,
		"recovered_from_backup": source_index > 0,
		"migrated_from_legacy": is_legacy_source
	}


func _format_slot_details(save_data: Dictionary) -> String:
	var parts: Array[String] = []
	var updated_at := String(save_data.get("updated_at", ""))
	if updated_at.is_empty():
		updated_at = String(save_data.get("created_at", "未知时间"))
	parts.append("最近保存：%s" % updated_at)

	var world_data = save_data.get("world", {})
	if world_data is Dictionary:
		var region_id := String(world_data.get("current_region_id", ""))
		if not region_id.is_empty():
			parts.append("区域：%s" % _get_display_name(region_id))

		var quest_state = world_data.get("quest_state", {})
		if quest_state is Dictionary:
			var active_quest_ids = quest_state.get("active_quest_ids", [])
			if active_quest_ids is Array and not active_quest_ids.is_empty():
				parts.append("目标：%s" % _get_display_name(String(active_quest_ids[0])))
			elif _get_string_array(quest_state.get("unlocked_effects", [])).has("slice_01_complete"):
				parts.append("目标：第一切片已完成")

	return "；".join(parts)


func _format_slot_display_name(slot_id: String) -> String:
	if slot_id.begins_with("slot_"):
		var suffix := slot_id.trim_prefix("slot_")
		if suffix.is_valid_int():
			return "槽位 %02d" % int(suffix)
	return slot_id


func _get_display_name(definition_id: String) -> String:
	if data_registry == null or definition_id.is_empty():
		return definition_id
	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id
	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))


func _validate_save_data(save_data: Dictionary) -> String:
	if not save_data.has("save_schema_version"):
		return "读取存档失败：缺少 save_schema_version，当前运行状态已保留。"
	if not _is_number(save_data["save_schema_version"]):
		return "读取存档失败：save_schema_version 类型错误，应为数字，当前运行状态已保留。"

	var save_schema_version := int(save_data["save_schema_version"])
	if save_schema_version != SAVE_SCHEMA_VERSION:
		return "读取存档失败：存档版本不兼容（文件版本 %d，当前支持 %d），当前运行状态已保留。" % [
			save_schema_version,
			SAVE_SCHEMA_VERSION
		]

	if not save_data.has("world"):
		return "读取存档失败：缺少 world 世界状态块，当前运行状态已保留。"
	if not (save_data["world"] is Dictionary):
		return "读取存档失败：world 世界状态块类型错误，当前运行状态已保留。"

	if not save_data.has("character"):
		return "读取存档失败：缺少 character 角色状态块，当前运行状态已保留。"
	if not (save_data["character"] is Dictionary):
		return "读取存档失败：character 角色状态块类型错误，当前运行状态已保留。"

	return ""


func _validate_save_content(save_data: Dictionary) -> String:
	if content_validator == null:
		return ""
	return content_validator.validate_save_content(save_data)


func _get_string_array(value, default_values: Array[String] = []) -> Array[String]:
	var result: Array[String] = []
	if not (value is Array):
		result.assign(default_values)
		return result
	for item in value:
		result.append(String(item))
	return result


func _read_existing_created_at(default_created_at: String, save_file: String) -> String:
	if not FileAccess.file_exists(save_file):
		return default_created_at

	var file := FileAccess.open(save_file, FileAccess.READ)
	if file == null:
		return default_created_at

	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(content) != OK:
		return default_created_at
	if not (json.data is Dictionary):
		return default_created_at

	var created_at = json.data.get("created_at", "")
	if created_at is String and not created_at.strip_edges().is_empty():
		return created_at
	return default_created_at


func _ensure_slot_dir(paths: Dictionary) -> Dictionary:
	var dir := DirAccess.open("user://")
	if dir == null:
		return _failure("打开用户存档目录失败。")

	var dir_error := dir.make_dir_recursive(String(paths.get("save_dir_relative", "saves/slots/%s" % DEFAULT_SLOT_ID)))
	if dir_error != OK:
		return _failure("创建存档目录失败：%s。" % error_string(dir_error))

	return _success("存档目录已准备。")


func _write_save_data(save_file: String, save_data: Dictionary) -> Dictionary:
	var file := FileAccess.open(save_file, FileAccess.WRITE)
	if file == null:
		return _failure("打开存档文件失败：%s。" % error_string(FileAccess.get_open_error()))

	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	return _success("已写入存档文件。")


func _backup_existing_save(paths: Dictionary) -> Dictionary:
	var save_file := String(paths.get("save_file", SAVE_FILE))
	var backup_file := String(paths.get("backup_file", SAVE_BACKUP_FILE))
	var backup_files: Array = paths.get("backup_files", SAVE_BACKUP_FILES)
	if not FileAccess.file_exists(save_file):
		return {
			"success": true,
			"backup_created": false
		}

	var rotation_error := _rotate_backup_files(backup_files)
	if rotation_error != OK:
		return _failure("保存失败：轮转存档备份失败：%s。当前存档未被覆盖。" % error_string(rotation_error))

	var copy_error := DirAccess.copy_absolute(
		ProjectSettings.globalize_path(save_file),
		ProjectSettings.globalize_path(backup_file)
	)
	if copy_error != OK:
		return _failure("保存失败：备份现有存档失败：%s。当前存档未被覆盖。" % error_string(copy_error))

	return {
		"success": true,
		"backup_created": true
	}


func _rotate_backup_files(backup_files: Array) -> Error:
	for index in range(backup_files.size() - 1, 0, -1):
		var source_path := String(backup_files[index - 1])
		var target_path := String(backup_files[index])
		if FileAccess.file_exists(target_path):
			var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(target_path))
			if remove_error != OK:
				return remove_error
		if not FileAccess.file_exists(source_path):
			continue

		var rename_error := DirAccess.rename_absolute(
			ProjectSettings.globalize_path(source_path),
			ProjectSettings.globalize_path(target_path)
		)
		if rename_error != OK:
			return rename_error

	return OK


func _get_slot_paths(slot_id: String) -> Dictionary:
	var clean_slot_id := _sanitize_slot_id(slot_id)
	var save_dir_relative := "saves/slots/%s" % clean_slot_id
	var save_dir := "%s/%s" % [SAVE_SLOT_ROOT_DIR, clean_slot_id]
	var save_file := "%s/%s" % [save_dir, SAVE_FILE_NAME]
	var backup_files: Array[String] = []
	for backup_index in range(1, 4):
		backup_files.append("%s/slice_01_autosave.bak.%d.json" % [save_dir, backup_index])

	return {
		"slot_id": clean_slot_id,
		"save_dir": save_dir,
		"save_dir_relative": save_dir_relative,
		"save_file": save_file,
		"backup_file": backup_files[0],
		"backup_files": backup_files
	}


func _sanitize_slot_id(slot_id: String) -> String:
	var raw_slot_id := slot_id.strip_edges()
	if raw_slot_id.is_empty():
		return DEFAULT_SLOT_ID

	var allowed := "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_-"
	var clean_slot_id := ""
	for index in range(raw_slot_id.length()):
		var character := raw_slot_id.substr(index, 1)
		if allowed.contains(character):
			clean_slot_id += character
		else:
			clean_slot_id += "_"

	if clean_slot_id.strip_edges().is_empty():
		return DEFAULT_SLOT_ID
	return clean_slot_id


func _is_number(value) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


func _is_whole_number(value) -> bool:
	return _is_number(value) and is_equal_approx(float(value), roundf(float(value)))


func _success(message: String) -> Dictionary:
	return {
		"success": true,
		"message": message
	}


func _failure(message: String) -> Dictionary:
	return {
		"success": false,
		"message": message
	}
