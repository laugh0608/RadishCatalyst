extends SceneTree

var failures: Array[String] = []
var save_service := SaveService.new()


func _init() -> void:
	_run_checks()
	if failures.is_empty():
		print("Save service runtime checks passed.")
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	quit(1)


func _run_checks() -> void:
	_remove_save_file()
	_expect_failure_message(save_service.load_game(), "未找到原型存档文件", "missing file")

	_write_save_text("{")
	_expect_failure_message(save_service.load_game(), "JSON 解析失败", "invalid JSON")

	_write_save_json({
		"world": {},
		"character": {}
	})
	_expect_failure_message(save_service.load_game(), "缺少 save_schema_version", "missing schema version")

	_write_save_json({
		"save_schema_version": "1",
		"world": {},
		"character": {}
	})
	_expect_failure_message(save_service.load_game(), "save_schema_version 类型错误", "wrong schema version type")

	_write_save_json({
		"save_schema_version": SaveService.SAVE_SCHEMA_VERSION + 1,
		"world": {},
		"character": {}
	})
	_expect_failure_message(save_service.load_game(), "存档版本不兼容", "incompatible schema version")

	_write_save_json({
		"save_schema_version": SaveService.SAVE_SCHEMA_VERSION,
		"character": {}
	})
	_expect_failure_message(save_service.load_game(), "缺少 world", "missing world block")

	_write_save_json({
		"save_schema_version": SaveService.SAVE_SCHEMA_VERSION,
		"world": [],
		"character": {}
	})
	_expect_failure_message(save_service.load_game(), "world 世界状态块类型错误", "wrong world block type")

	_write_save_json({
		"save_schema_version": SaveService.SAVE_SCHEMA_VERSION,
		"world": {}
	})
	_expect_failure_message(save_service.load_game(), "缺少 character", "missing character block")

	_write_save_json({
		"save_schema_version": SaveService.SAVE_SCHEMA_VERSION,
		"world": {},
		"character": []
	})
	_expect_failure_message(save_service.load_game(), "character 角色状态块类型错误", "wrong character block type")

	_write_save_json({
		"save_schema_version": SaveService.SAVE_SCHEMA_VERSION,
		"world": {
			"unlocked_region_ids": "bad",
			"pollution_levels": "bad",
			"map_objects": "bad",
			"enemies": "bad",
			"base_structures": "bad",
			"quest_state": "bad"
		},
		"character": {
			"equipment": "bad",
			"quick_slots": "bad",
			"inventory": "bad"
		}
	})
	var fallback_result := save_service.load_game()
	_expect_success(fallback_result, "fallback load")
	if bool(fallback_result.get("success", false)):
		var world_state: WorldState = fallback_result["world_state"]
		var character_state: CharacterState = fallback_result["character_state"]
		_expect_equal(world_state.unlocked_region_ids, ["region.outpost_platform"], "fallback world regions")
		_expect_equal(world_state.pollution_levels.get("region.pollution_edge"), 1.0, "fallback pollution")
		_expect_equal(character_state.quick_slots, ["item.repair_gel", "item.resistance_vial_t1"], "fallback quick slots")
		if not character_state.inventory.has_ref("item.basic_parts", 4):
			failures.append("fallback inventory should keep starting basic parts")

	_write_save_json({
		"save_schema_version": SaveService.SAVE_SCHEMA_VERSION,
		"world": {},
		"character": {}
	})
	var minimal_result := save_service.load_game()
	_expect_success(minimal_result, "minimal old save load")
	if bool(minimal_result.get("success", false)):
		var minimal_character: CharacterState = minimal_result["character_state"]
		if not minimal_character.inventory.has_ref("item.basic_parts", 4):
			failures.append("minimal old save should keep starting basic parts")

	var save_result := save_service.save_game(WorldState.create_default(), CharacterState.create_default())
	_expect_success(save_result, "save default game")
	var load_result := save_service.load_game()
	_expect_success(load_result, "load saved default game")
	if bool(load_result.get("success", false)):
		var loaded_world: WorldState = load_result["world_state"]
		var loaded_character: CharacterState = load_result["character_state"]
		_expect_equal(loaded_world.world_id, "world.slice_01.prototype", "loaded world id")
		_expect_equal(loaded_character.stable_id, "character.player", "loaded character id")


func _write_save_json(data: Dictionary) -> void:
	_write_save_text(JSON.stringify(data, "\t"))


func _write_save_text(content: String) -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		failures.append("could not open user://")
		return

	var dir_error := dir.make_dir_recursive("saves")
	if dir_error != OK:
		failures.append("could not create saves dir: %s" % error_string(dir_error))
		return

	var file := FileAccess.open(SaveService.SAVE_FILE, FileAccess.WRITE)
	if file == null:
		failures.append("could not write save file: %s" % error_string(FileAccess.get_open_error()))
		return
	file.store_string(content)
	file.close()


func _remove_save_file() -> void:
	if FileAccess.file_exists(SaveService.SAVE_FILE):
		var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveService.SAVE_FILE))
		if remove_error != OK:
			failures.append("could not remove save file: %s" % error_string(remove_error))


func _expect_success(result: Dictionary, label: String) -> void:
	if not bool(result.get("success", false)):
		failures.append("%s should succeed, got: %s" % [label, result.get("message", "")])


func _expect_failure_message(result: Dictionary, expected_message: String, label: String) -> void:
	if bool(result.get("success", false)):
		failures.append("%s should fail" % label)
		return

	var message := String(result.get("message", ""))
	if not message.contains(expected_message):
		failures.append("%s should contain '%s', got: %s" % [label, expected_message, message])


func _expect_equal(actual, expected, label: String) -> void:
	if actual != expected:
		failures.append("%s expected %s, got %s" % [label, var_to_str(expected), var_to_str(actual)])
