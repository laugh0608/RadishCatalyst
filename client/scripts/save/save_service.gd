extends RefCounted
class_name SaveService

const SAVE_SCHEMA_VERSION := 1
const GAME_VERSION := "prototype-slice-01"
const SAVE_DIR := "user://saves"
const SAVE_FILE := "user://saves/slice_01_autosave.json"


func save_game(world_state: WorldState, character_state: CharacterState) -> Dictionary:
	var dir := DirAccess.open("user://")
	if dir == null:
		return _failure("打开用户存档目录失败。")

	var dir_error := dir.make_dir_recursive("saves")
	if dir_error != OK:
		return _failure("创建存档目录失败：%s。" % error_string(dir_error))

	var save_data := {
		"save_schema_version": SAVE_SCHEMA_VERSION,
		"game_version": GAME_VERSION,
		"updated_at": Time.get_datetime_string_from_system(true, true),
		"world": world_state.to_dict(),
		"character": character_state.to_dict()
	}

	var file := FileAccess.open(SAVE_FILE, FileAccess.WRITE)
	if file == null:
		return _failure("打开存档文件失败：%s。" % error_string(FileAccess.get_open_error()))

	file.store_string(JSON.stringify(save_data, "\t"))
	file.close()
	return _success("已保存原型存档。")


func load_game() -> Dictionary:
	if not FileAccess.file_exists(SAVE_FILE):
		return _failure("还没有可读取的原型存档。")

	var file := FileAccess.open(SAVE_FILE, FileAccess.READ)
	if file == null:
		return _failure("打开存档文件失败：%s。" % error_string(FileAccess.get_open_error()))

	var content := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_error := json.parse(content)
	if parse_error != OK:
		return _failure("解析存档失败：%s。" % json.get_error_message())

	var save_data = json.data
	if not save_data is Dictionary:
		return _failure("存档格式无效。")
	if int(save_data.get("save_schema_version", 0)) != SAVE_SCHEMA_VERSION:
		return _failure("存档版本不兼容。")

	return {
		"success": true,
		"message": "已读取原型存档。",
		"world_state": WorldState.from_dict(save_data.get("world", {})),
		"character_state": CharacterState.from_dict(save_data.get("character", {}))
	}


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
