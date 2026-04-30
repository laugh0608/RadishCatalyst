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


func save_game(world_state: WorldState, character_state: CharacterState) -> Dictionary:
	return save_game_for_slot(DEFAULT_SLOT_ID, world_state, character_state)


func setup(registry: DataRegistry) -> void:
	data_registry = registry


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
	if data_registry == null:
		return ""

	var world_data: Dictionary = save_data.get("world", {})
	var character_data: Dictionary = save_data.get("character", {})
	var world_error := _validate_world_content(world_data)
	if not world_error.is_empty():
		return world_error
	var character_error := _validate_character_content(character_data)
	if not character_error.is_empty():
		return character_error
	return ""


func _validate_world_content(world_data: Dictionary) -> String:
	var current_region_id := String(world_data.get("current_region_id", "region.outpost_platform"))
	var region_error := _validate_definition_ref(current_region_id, "region.", "world.current_region_id")
	if not region_error.is_empty():
		return region_error

	var weather_error := _validate_definition_ref(String(world_data.get("current_weather_id", "weather.clear")), "weather.", "world.current_weather_id")
	if not weather_error.is_empty():
		return weather_error

	var time_minutes = world_data.get("time_minutes", 480)
	if not _is_number(time_minutes) or int(time_minutes) < 0:
		return "读取存档失败：world.time_minutes 必须是非负数字，当前运行状态已保留。"

	var unlocked_region_ids = world_data.get("unlocked_region_ids", [])
	if unlocked_region_ids is Array:
		for region_id in unlocked_region_ids:
			region_error = _validate_definition_ref(String(region_id), "region.", "world.unlocked_region_ids")
			if not region_error.is_empty():
				return region_error

	var pollution_levels = world_data.get("pollution_levels", {})
	if pollution_levels is Dictionary:
		for region_id in pollution_levels:
			region_error = _validate_definition_ref(String(region_id), "region.", "world.pollution_levels")
			if not region_error.is_empty():
				return region_error
			var pollution_value = pollution_levels[region_id]
			if not _is_number(pollution_value) or float(pollution_value) < 0.0:
				return "读取存档失败：world.pollution_levels 中存在无效污染值，当前运行状态已保留。"

	var map_objects_error := _validate_runtime_object_map(world_data.get("map_objects", {}), "map_object.", "world.map_objects")
	if not map_objects_error.is_empty():
		return map_objects_error
	var enemies_error := _validate_runtime_object_map(world_data.get("enemies", {}), "enemy.", "world.enemies")
	if not enemies_error.is_empty():
		return enemies_error
	var structures_error := _validate_runtime_object_map(world_data.get("base_structures", {}), "building.", "world.base_structures")
	if not structures_error.is_empty():
		return structures_error

	var quest_state = world_data.get("quest_state", {})
	if quest_state is Dictionary:
		var quest_error := _validate_quest_content(quest_state)
		if not quest_error.is_empty():
			return quest_error

	return ""


func _validate_character_content(character_data: Dictionary) -> String:
	var region_error := _validate_definition_ref(String(character_data.get("current_region_id", "region.outpost_platform")), "region.", "character.current_region_id")
	if not region_error.is_empty():
		return region_error

	var max_health_value = character_data.get("max_health", 100.0)
	var health_value = character_data.get("health", 100.0)
	if not _is_number(max_health_value) or not _is_number(health_value):
		return "读取存档失败：character.health 必须是数字，当前运行状态已保留。"
	var max_health := float(max_health_value)
	var health := float(health_value)
	if max_health <= 0.0 or health < 0.0 or health > max_health:
		return "读取存档失败：character.health 超出有效范围，当前运行状态已保留。"

	var max_protection_value = character_data.get("max_protection", 100.0)
	var protection_value = character_data.get("protection", 100.0)
	if not _is_number(max_protection_value) or not _is_number(protection_value):
		return "读取存档失败：character.protection 必须是数字，当前运行状态已保留。"
	var max_protection := float(max_protection_value)
	var protection := float(protection_value)
	if max_protection <= 0.0 or protection < 0.0 or protection > max_protection:
		return "读取存档失败：character.protection 超出有效范围，当前运行状态已保留。"

	var position = character_data.get("position", {})
	if position is Dictionary:
		if not _is_number(position.get("x", 0.0)) or not _is_number(position.get("y", 0.0)):
			return "读取存档失败：character.position 坐标必须是数字，当前运行状态已保留。"

	var equipment = character_data.get("equipment", {})
	if equipment is Dictionary:
		for slot_name in equipment:
			var equipment_id := String(equipment[slot_name])
			if equipment_id.is_empty():
				continue
			var equipment_error := _validate_definition_ref(equipment_id, "equipment.", "character.equipment.%s" % String(slot_name))
			if not equipment_error.is_empty():
				return equipment_error

	var quick_slots = character_data.get("quick_slots", [])
	if quick_slots is Array:
		for quick_slot_id in quick_slots:
			var item_id := String(quick_slot_id)
			if item_id.is_empty():
				continue
			var quick_slot_error := _validate_definition_ref(item_id, "item.", "character.quick_slots")
			if not quick_slot_error.is_empty():
				return quick_slot_error

	var inventory_error := _validate_inventory_content(character_data.get("inventory", {}), "character.inventory")
	if not inventory_error.is_empty():
		return inventory_error

	return ""


func _validate_runtime_object_map(value, expected_definition_prefix: String, label: String) -> String:
	if not (value is Dictionary):
		return ""

	for instance_id in value:
		var entry = value[instance_id]
		if not (entry is Dictionary):
			return "读取存档失败：%s 中存在无效对象状态，当前运行状态已保留。" % label

		var definition_error := _validate_definition_ref(String(entry.get("definition_id", "")), expected_definition_prefix, "%s.%s.definition_id" % [label, String(instance_id)])
		if not definition_error.is_empty():
			return definition_error

		var region_id := String(entry.get("region_id", ""))
		if not region_id.is_empty():
			var region_error := _validate_definition_ref(region_id, "region.", "%s.%s.region_id" % [label, String(instance_id)])
			if not region_error.is_empty():
				return region_error

		if expected_definition_prefix == "enemy.":
			var max_health = entry.get("max_health", 1.0)
			var health = entry.get("health", max_health)
			if not _is_number(max_health) or not _is_number(health):
				return "读取存档失败：%s 中存在无效敌人生命值，当前运行状态已保留。" % label
			if float(max_health) <= 0.0 or float(health) < 0.0 or float(health) > float(max_health):
				return "读取存档失败：%s 中敌人生命值超出有效范围，当前运行状态已保留。" % label

	return ""


func _validate_quest_content(quest_state: Dictionary) -> String:
	for field_name in ["active_quest_ids", "completed_quest_ids"]:
		var quest_ids = quest_state.get(field_name, [])
		if not (quest_ids is Array):
			continue
		for quest_id in quest_ids:
			var quest_error := _validate_definition_ref(String(quest_id), "quest.", "quest_state.%s" % field_name)
			if not quest_error.is_empty():
				return quest_error

	var objective_progress = quest_state.get("objective_progress", {})
	if objective_progress is Dictionary:
		for objective_key in objective_progress:
			var progress = objective_progress[objective_key]
			if not _is_number(progress) or float(progress) < 0.0:
				return "读取存档失败：quest_state.objective_progress 中存在无效进度值，当前运行状态已保留。"

			var parts := String(objective_key).split("|", false)
			if parts.size() != 3:
				return "读取存档失败：quest_state.objective_progress 中存在无效目标键，当前运行状态已保留。"
			var quest_error := _validate_definition_ref(parts[0], "quest.", "quest_state.objective_progress")
			if not quest_error.is_empty():
				return quest_error
			var target_error := _validate_known_or_special_ref(parts[2], "quest_state.objective_progress")
			if not target_error.is_empty():
				return target_error

	var unlocked_effects = quest_state.get("unlocked_effects", [])
	if unlocked_effects is Array:
		for effect_id in unlocked_effects:
			var effect_error := _validate_known_or_special_ref(String(effect_id), "quest_state.unlocked_effects")
			if not effect_error.is_empty():
				return effect_error

	return ""


func _validate_inventory_content(value, label: String) -> String:
	if not (value is Dictionary):
		return ""

	var items = value.get("items", {})
	if items is Dictionary:
		for item_id in items:
			var item_error := _validate_definition_ref(String(item_id), "item.", "%s.items" % label)
			if not item_error.is_empty():
				return item_error
			var item_amount = items[item_id]
			if not _is_whole_number(item_amount) or int(item_amount) < 0:
				return "读取存档失败：%s.items 中存在无效数量，当前运行状态已保留。" % label

	var fluids = value.get("fluids", {})
	if fluids is Dictionary:
		for fluid_id in fluids:
			var fluid_error := _validate_definition_ref(String(fluid_id), "fluid.", "%s.fluids" % label)
			if not fluid_error.is_empty():
				return fluid_error
			var fluid_amount = fluids[fluid_id]
			if not _is_number(fluid_amount) or float(fluid_amount) < 0.0:
				return "读取存档失败：%s.fluids 中存在无效数量，当前运行状态已保留。" % label

	var capacity_slots = value.get("capacity_slots", 24)
	if not _is_whole_number(capacity_slots) or int(capacity_slots) < 0:
		return "读取存档失败：%s.capacity_slots 必须是非负数字，当前运行状态已保留。" % label
	return ""


func _validate_known_or_special_ref(definition_id: String, label: String) -> String:
	if definition_id == "slice_01_complete":
		return ""
	if definition_id.is_empty():
		return "读取存档失败：%s 中存在空 ID，当前运行状态已保留。" % label
	if not data_registry.has_definition(definition_id):
		return "读取存档失败：%s 引用了未知定义 ID：%s，当前运行状态已保留。" % [label, definition_id]
	return ""


func _validate_definition_ref(definition_id: String, expected_prefix: String, label: String) -> String:
	if definition_id.is_empty():
		return "读取存档失败：%s 缺少定义 ID，当前运行状态已保留。" % label
	if not definition_id.begins_with(expected_prefix):
		return "读取存档失败：%s 使用了错误类型的定义 ID：%s，当前运行状态已保留。" % [label, definition_id]
	if not data_registry.has_definition(definition_id):
		return "读取存档失败：%s 引用了未知定义 ID：%s，当前运行状态已保留。" % [label, definition_id]
	return ""


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
