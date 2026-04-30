extends SceneTree

const LEGACY_SAVE_BACKUP_FILE := "user://saves/slice_01_autosave.bak.json"

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
	_remove_backup_files()
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
	if not FileAccess.file_exists(SaveService.SAVE_FILE):
		failures.append("default save should use slot_01 save path")
	if not SaveService.SAVE_FILE.contains("/slots/slot_01/"):
		failures.append("default save path should include slots/slot_01")
	var load_result := save_service.load_game()
	_expect_success(load_result, "load saved default game")
	if bool(load_result.get("success", false)):
		var loaded_world: WorldState = load_result["world_state"]
		var loaded_character: CharacterState = load_result["character_state"]
		_expect_equal(loaded_world.world_id, "world.slice_01.prototype", "loaded world id")
		_expect_equal(loaded_character.stable_id, "character.player", "loaded character id")

	_check_slice_end_hook_state_persists()
	_check_slice_complete_state_persists()
	_check_save_backup()
	_check_loads_recent_backup_when_primary_is_bad()
	_check_loads_older_backup_when_recent_backup_is_bad()
	_check_all_bad_saves_fail_without_replacing_state()
	_check_named_slot_save_load()
	_check_bad_existing_save_does_not_block_save()


func _write_save_json(data: Dictionary) -> void:
	_write_save_text(JSON.stringify(data, "\t"))


func _write_save_text(content: String) -> void:
	_write_text_file(SaveService.SAVE_FILE, content)


func _write_save_json_to_path(save_path: String, data: Dictionary) -> void:
	_write_text_file(save_path, JSON.stringify(data, "\t"))


func _write_text_file(save_path: String, content: String) -> void:
	var dir := DirAccess.open("user://")
	if dir == null:
		failures.append("could not open user://")
		return

	var dir_error := dir.make_dir_recursive("saves/slots/%s" % SaveService.DEFAULT_SLOT_ID)
	if dir_error != OK:
		failures.append("could not create default slot save dir: %s" % error_string(dir_error))
		return

	var file := FileAccess.open(save_path, FileAccess.WRITE)
	if file == null:
		failures.append("could not write save file %s: %s" % [save_path, error_string(FileAccess.get_open_error())])
		return
	file.store_string(content)
	file.close()


func _remove_save_file() -> void:
	if FileAccess.file_exists(SaveService.SAVE_FILE):
		var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveService.SAVE_FILE))
		if remove_error != OK:
			failures.append("could not remove save file: %s" % error_string(remove_error))


func _remove_backup_files() -> void:
	for backup_path in SaveService.SAVE_BACKUP_FILES:
		var backup_file := String(backup_path)
		if FileAccess.file_exists(backup_file):
			var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_file))
			if remove_error != OK:
				failures.append("could not remove backup file %s: %s" % [backup_file, error_string(remove_error)])

	if FileAccess.file_exists(LEGACY_SAVE_BACKUP_FILE):
		var legacy_remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_SAVE_BACKUP_FILE))
		if legacy_remove_error != OK:
			failures.append("could not remove legacy backup file: %s" % error_string(legacy_remove_error))


func _check_save_backup() -> void:
	_remove_save_file()
	_remove_backup_files()

	_save_world_with_id("world.backup.first", "save first backup source")
	_expect_no_backup_files("first save")

	_save_world_with_id("world.backup.second", "save second with backup")
	_expect_backup_world_id(String(SaveService.SAVE_BACKUP_FILES[0]), "world.backup.first", "second save bak1")

	_save_world_with_id("world.backup.third", "save third with backup rotation")
	_expect_backup_world_id(String(SaveService.SAVE_BACKUP_FILES[0]), "world.backup.second", "third save bak1")
	_expect_backup_world_id(String(SaveService.SAVE_BACKUP_FILES[1]), "world.backup.first", "third save bak2")

	_save_world_with_id("world.backup.fourth", "save fourth with backup rotation")
	_expect_backup_world_id(String(SaveService.SAVE_BACKUP_FILES[0]), "world.backup.third", "fourth save bak1")
	_expect_backup_world_id(String(SaveService.SAVE_BACKUP_FILES[1]), "world.backup.second", "fourth save bak2")
	_expect_backup_world_id(String(SaveService.SAVE_BACKUP_FILES[2]), "world.backup.first", "fourth save bak3")

	_save_world_with_id("world.backup.fifth", "save fifth with backup rotation")
	_expect_backup_world_id(String(SaveService.SAVE_BACKUP_FILES[0]), "world.backup.fourth", "fifth save bak1")
	_expect_backup_world_id(String(SaveService.SAVE_BACKUP_FILES[1]), "world.backup.third", "fifth save bak2")
	_expect_backup_world_id(String(SaveService.SAVE_BACKUP_FILES[2]), "world.backup.second", "fifth save bak3")


func _save_world_with_id(world_id: String, label: String) -> void:
	var world_state := WorldState.create_default()
	world_state.world_id = world_id
	_expect_success(save_service.save_game(world_state, CharacterState.create_default()), label)


func _expect_backup_world_id(backup_path: String, expected_world_id: String, label: String) -> void:
	if not FileAccess.file_exists(backup_path):
		failures.append("%s should create backup file: %s" % [label, backup_path])
		return

	var backup_data := _read_json_file(backup_path)
	var backup_world = backup_data.get("world", {})
	if backup_world is Dictionary:
		_expect_equal(String(backup_world.get("world_id", "")), expected_world_id, label)
	else:
		failures.append("%s world block should be dictionary" % label)


func _expect_no_backup_files(label: String) -> void:
	for backup_path in SaveService.SAVE_BACKUP_FILES:
		var backup_file := String(backup_path)
		if FileAccess.file_exists(backup_file):
			failures.append("%s should not create backup file: %s" % [label, backup_file])


func _check_bad_existing_save_does_not_block_save() -> void:
	_write_save_text("{")
	var result := save_service.save_game(WorldState.create_default(), CharacterState.create_default())
	_expect_success(result, "save over bad existing save")
	if not FileAccess.file_exists(SaveService.SAVE_BACKUP_FILE):
		failures.append("save over bad existing save should still create backup")


func _check_loads_recent_backup_when_primary_is_bad() -> void:
	_remove_save_file()
	_remove_backup_files()
	_write_save_text("{")
	_write_save_json_to_path(String(SaveService.SAVE_BACKUP_FILES[0]), _make_save_data("world.recovered.bak1"))

	var result := save_service.load_game()
	_expect_success(result, "load bak1 after bad primary")
	if not bool(result.get("success", false)):
		return

	_expect_equal(bool(result.get("recovered_from_backup", false)), true, "bak1 load should mark recovery")
	_expect_equal(String(result.get("source_file", "")), String(SaveService.SAVE_BACKUP_FILES[0]), "bak1 source file")
	_expect_recovered_world_id(result, "world.recovered.bak1", "bak1 recovered world")
	var message := String(result.get("message", ""))
	if not message.contains("备份 1"):
		failures.append("bak1 recovery message should mention backup 1, got: %s" % message)


func _check_loads_older_backup_when_recent_backup_is_bad() -> void:
	_remove_save_file()
	_remove_backup_files()
	_write_save_text("{")
	_write_text_file(String(SaveService.SAVE_BACKUP_FILES[0]), "{")
	_write_save_json_to_path(String(SaveService.SAVE_BACKUP_FILES[1]), _make_save_data("world.recovered.bak2"))

	var result := save_service.load_game()
	_expect_success(result, "load bak2 after bad primary and bak1")
	if not bool(result.get("success", false)):
		return

	_expect_equal(bool(result.get("recovered_from_backup", false)), true, "bak2 load should mark recovery")
	_expect_equal(String(result.get("source_file", "")), String(SaveService.SAVE_BACKUP_FILES[1]), "bak2 source file")
	_expect_recovered_world_id(result, "world.recovered.bak2", "bak2 recovered world")
	var message := String(result.get("message", ""))
	if not message.contains("备份 2"):
		failures.append("bak2 recovery message should mention backup 2, got: %s" % message)


func _check_all_bad_saves_fail_without_replacing_state() -> void:
	_remove_save_file()
	_remove_backup_files()
	_write_save_text("{")
	for backup_path in SaveService.SAVE_BACKUP_FILES:
		_write_text_file(String(backup_path), "{")

	var result := save_service.load_game()
	_expect_failure_message(result, "JSON 解析失败", "all bad saves")
	if result.has("world_state") or result.has("character_state"):
		failures.append("all bad saves should not return replacement state")


func _check_named_slot_save_load() -> void:
	var slot_id := "slot_02"
	var world_state := WorldState.create_default()
	world_state.world_id = "world.slot.02"
	var save_result := save_service.save_game_for_slot(slot_id, world_state, CharacterState.create_default())
	_expect_success(save_result, "save named slot")

	var load_result := save_service.load_game_for_slot(slot_id)
	_expect_success(load_result, "load named slot")
	if not bool(load_result.get("success", false)):
		return

	_expect_equal(String(load_result.get("slot_id", "")), slot_id, "named slot id")
	_expect_recovered_world_id(load_result, "world.slot.02", "named slot world")


func _make_save_data(world_id: String) -> Dictionary:
	var world_state := WorldState.create_default()
	world_state.world_id = world_id
	return {
		"save_schema_version": SaveService.SAVE_SCHEMA_VERSION,
		"game_version": SaveService.GAME_VERSION,
		"created_at": "2026-04-30T00:00:00",
		"updated_at": "2026-04-30T00:00:00",
		"world": world_state.to_dict(),
		"character": CharacterState.create_default().to_dict()
	}


func _expect_recovered_world_id(result: Dictionary, expected_world_id: String, label: String) -> void:
	var world_state: WorldState = result.get("world_state", null)
	if world_state == null:
		failures.append("%s should return world state" % label)
		return
	_expect_equal(world_state.world_id, expected_world_id, label)


func _check_slice_end_hook_state_persists() -> void:
	var world_state := WorldState.create_default()
	world_state.unlock_region("region.crystal_vein_field")
	world_state.unlock_region("region.pollution_edge")
	world_state.unlock_region("region.locked_ruin_gate")
	world_state.current_region_id = "region.pollution_edge"
	world_state.quest_state.active_quest_ids = ["quest.unlock_ruin_signal"]
	world_state.quest_state.completed_quest_ids = [
		"quest.restore_outpost",
		"quest.scout_crystal_field",
		"quest.bring_back_sample",
		"quest.make_filter_module",
		"quest.expand_treatment_point",
		"quest.enter_pollution_edge"
	]
	world_state.quest_state.objective_progress = {
		"quest.enter_pollution_edge|visit_region|region.pollution_edge": 1,
		"quest.enter_pollution_edge|gather_item|item.polluted_residue": 2,
		"quest.enter_pollution_edge|craft_item|item.resistance_vial_t1": 1,
		"quest.enter_pollution_edge|defeat_enemy|enemy.polluted_skitter": 1
	}
	world_state.quest_state.unlocked_effects = [
		"region.outpost_platform",
		"region.crystal_vein_field",
		"region.pollution_edge",
		"region.locked_ruin_gate"
	]

	_expect_success(save_service.save_game(world_state, CharacterState.create_default()), "save slice end hook state")
	var load_result := save_service.load_game()
	_expect_success(load_result, "load slice end hook state")
	if not bool(load_result.get("success", false)):
		return

	var loaded_world: WorldState = load_result["world_state"]
	_expect_array_has(loaded_world.unlocked_region_ids, "region.locked_ruin_gate", "slice hook unlocked ruin gate region")
	_expect_array_has(loaded_world.quest_state.active_quest_ids, "quest.unlock_ruin_signal", "slice hook active ruin signal quest")
	_expect_array_has(loaded_world.quest_state.completed_quest_ids, "quest.enter_pollution_edge", "slice hook completed pollution edge quest")
	_expect_array_has(loaded_world.quest_state.unlocked_effects, "region.locked_ruin_gate", "slice hook persisted ruin gate unlock")
	_expect_equal(
		loaded_world.quest_state.get_objective_progress("quest.enter_pollution_edge", "defeat_enemy", "enemy.polluted_skitter"),
		1.0,
		"slice hook polluted enemy objective"
	)


func _check_slice_complete_state_persists() -> void:
	var world_state := WorldState.create_default()
	world_state.unlock_region("region.crystal_vein_field")
	world_state.unlock_region("region.pollution_edge")
	world_state.unlock_region("region.locked_ruin_gate")
	world_state.current_region_id = "region.locked_ruin_gate"
	world_state.quest_state.active_quest_ids = []
	world_state.quest_state.completed_quest_ids = [
		"quest.restore_outpost",
		"quest.scout_crystal_field",
		"quest.bring_back_sample",
		"quest.make_filter_module",
		"quest.expand_treatment_point",
		"quest.enter_pollution_edge",
		"quest.unlock_ruin_signal"
	]
	world_state.quest_state.objective_progress = {
		"quest.unlock_ruin_signal|inspect|map_object.ruin_gate": 1
	}
	world_state.quest_state.unlocked_effects = [
		"region.outpost_platform",
		"region.crystal_vein_field",
		"region.pollution_edge",
		"region.locked_ruin_gate",
		"slice_01_complete"
	]

	var character_state := CharacterState.create_default()
	character_state.current_region_id = "region.locked_ruin_gate"
	character_state.position = Vector2(342, -20)
	_expect_success(save_service.save_game(world_state, character_state), "save slice complete state")
	var load_result := save_service.load_game()
	_expect_success(load_result, "load slice complete state")
	if not bool(load_result.get("success", false)):
		return

	var loaded_world: WorldState = load_result["world_state"]
	var loaded_character: CharacterState = load_result["character_state"]
	_expect_array_has(loaded_world.quest_state.completed_quest_ids, "quest.unlock_ruin_signal", "slice complete ruin signal quest")
	_expect_array_has(loaded_world.quest_state.unlocked_effects, "slice_01_complete", "slice complete unlock effect")
	_expect_equal(
		loaded_world.quest_state.get_objective_progress("quest.unlock_ruin_signal", "inspect", "map_object.ruin_gate"),
		1.0,
		"slice complete inspect objective"
	)
	_expect_equal(loaded_world.current_region_id, "region.locked_ruin_gate", "slice complete world region")
	_expect_equal(loaded_character.current_region_id, "region.locked_ruin_gate", "slice complete character region")
	_expect_equal(loaded_character.position, Vector2(342, -20), "slice complete character position")


func _read_json_file(save_path: String) -> Dictionary:
	var file := FileAccess.open(save_path, FileAccess.READ)
	if file == null:
		failures.append("could not read json file: %s" % save_path)
		return {}

	var content := file.get_as_text()
	file.close()
	var json := JSON.new()
	if json.parse(content) != OK:
		failures.append("could not parse json file: %s" % save_path)
		return {}
	if not (json.data is Dictionary):
		failures.append("json file root should be dictionary: %s" % save_path)
		return {}
	return json.data


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


func _expect_array_has(values: Array, expected_value: String, label: String) -> void:
	if not values.has(expected_value):
		failures.append("%s should contain %s, got %s" % [label, expected_value, var_to_str(values)])
