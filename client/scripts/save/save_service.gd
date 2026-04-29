extends RefCounted
class_name SaveService

const SAVE_SCHEMA_VERSION := 1
const GAME_VERSION := "prototype-slice-01"
const SAVE_DIR := "user://saves"
const SAVE_FILE := "user://saves/slice_01_autosave.json"
const SAVE_BACKUP_FILE := "user://saves/slice_01_autosave.bak.json"


func save_game(world_state: WorldState, character_state: CharacterState) -> Dictionary:
	var dir := DirAccess.open("user://")
	if dir == null:
		return _failure("打开用户存档目录失败。")

	var dir_error := dir.make_dir_recursive("saves")
	if dir_error != OK:
		return _failure("创建存档目录失败：%s。" % error_string(dir_error))

	var now := Time.get_datetime_string_from_system(true, true)
	var save_data := {
		"save_schema_version": SAVE_SCHEMA_VERSION,
		"game_version": GAME_VERSION,
		"created_at": _read_existing_created_at(now),
		"updated_at": now,
		"world": world_state.to_dict(),
		"character": character_state.to_dict()
	}

	var backup_result := _backup_existing_save()
	if not bool(backup_result.get("success", false)):
		return backup_result

	var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file == null:
		return _failure("打开存档文件失败：%s。" % error_string(FileAccess.get_open_error()))

	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	if bool(backup_result.get("backup_created", false)):
		return _success("已保存原型存档，并更新上一份备份。")
	return _success("已保存原型存档。")


func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_FILE):
		return _failure("读取存档失败：未找到原型存档文件，当前运行状态已保留。")

	var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
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

	return {
		"success": true,
		"message": "已读取原型存档。",
		"world_state": WorldState.from_dict(save_data.get("world", {})),
		"character_state": CharacterState.from_dict(save_data.get("character", {}))
	}


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


func _read_existing_created_at(default_created_at: String) -> String:
	if not FileAccess.file_exists(SAVE_FILE):
		return default_created_at

	var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
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


func _backup_existing_save() -> Dictionary:
	if not FileAccess.file_exists(SAVE_FILE):
		return {
			"success": true,
			"backup_created": false
		}

	var copy_error := DirAccess.copy_absolute(
		ProjectSettings.globalize_path(SAVE_FILE),
		ProjectSettings.globalize_path(SAVE_BACKUP_FILE)
	)
	if copy_error != OK:
		return _failure("保存失败：备份现有存档失败：%s。当前存档未被覆盖。" % error_string(copy_error))

	return {
		"success": true,
		"backup_created": true
	}


func _is_number(value) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


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
