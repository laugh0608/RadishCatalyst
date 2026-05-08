extends SceneTree

const EntitySourceChecks := preload("res://scripts/checks/save_entity_source_check.gd")
const LEGACY_SAVE_BACKUP_FILE := "user://saves/slice_01_autosave.bak.json"
const QuestObjectiveChecks := preload("res://scripts/checks/save_quest_objective_check.gd")
const QuestUnlockChecks := preload("res://scripts/checks/save_quest_unlock_check.gd")
const StructureRuntimeChecks := preload("res://scripts/checks/save_structure_runtime_check.gd")

var failures: Array[String] = []
var save_service := SaveService.new()
var data_registry := DataRegistry.new()


func _init() -> void:
	_run_checks()
	if failures.is_empty():
		print("Save service runtime checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
		return
	save_service.setup(data_registry)

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

	_check_save_rejects_invalid_current_state()
	_check_slice_end_hook_state_persists()
	_check_slice_complete_state_persists()
	_check_deep_ruin_state_persists()
	_check_save_backup()
	_check_loads_recent_backup_when_primary_is_bad()
	_check_loads_older_backup_when_recent_backup_is_bad()
	_check_all_bad_saves_fail_without_replacing_state()
	_check_named_slot_save_load()
	_check_delete_slot_clears_save_and_backups()
	_check_quick_slot_binding_persists()
	_check_save_slot_summaries()
	_check_migrates_legacy_primary_save()
	_check_migrates_legacy_backup_when_legacy_primary_is_bad()
	_check_existing_slot_blocks_legacy_migration()
	_check_rejects_unknown_inventory_id()
	_check_rejects_negative_inventory_amount()
	_check_rejects_unknown_region_id()
	_check_rejects_invalid_character_position()
	_check_rejects_invalid_enemy_health()
	EntitySourceChecks.new(self).run()
	StructureRuntimeChecks.new(self).run()
	_check_rejects_locked_current_region()
	_check_rejects_region_mismatch()
	_check_rejects_quest_state_overlap()
	_check_rejects_missing_quest_prerequisite()
	_check_rejects_missing_structure_site()
	QuestObjectiveChecks.new(self).run()
	QuestUnlockChecks.new(self).run()
	_check_bad_existing_save_does_not_block_save()


func _write_save_json(data: Dictionary) -> void:
	_write_save_text(JSON.stringify(data, "\t"))


func _write_save_text(content: String) -> void:
	_write_text_file(SaveService.SAVE_FILE, content)


func _write_save_json_to_path(save_path: String, data: Dictionary) -> void:
	_write_text_file(save_path, JSON.stringify(data, "\t"))


func _write_legacy_save_json(data: Dictionary) -> void:
	_write_text_file(SaveService.LEGACY_SAVE_FILE, JSON.stringify(data, "\t"))


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

	if FileAccess.file_exists(SaveService.LEGACY_SAVE_FILE):
		var legacy_remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(SaveService.LEGACY_SAVE_FILE))
		if legacy_remove_error != OK:
			failures.append("could not remove legacy save file: %s" % error_string(legacy_remove_error))


func _remove_backup_files() -> void:
	for backup_path in SaveService.SAVE_BACKUP_FILES:
		var backup_file := String(backup_path)
		if FileAccess.file_exists(backup_file):
			var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(backup_file))
			if remove_error != OK:
				failures.append("could not remove backup file %s: %s" % [backup_file, error_string(remove_error)])

	for backup_path in SaveService.LEGACY_SAVE_BACKUP_FILES:
		var legacy_backup_file := String(backup_path)
		if FileAccess.file_exists(legacy_backup_file):
			var legacy_backup_remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(legacy_backup_file))
			if legacy_backup_remove_error != OK:
				failures.append("could not remove legacy backup file %s: %s" % [legacy_backup_file, error_string(legacy_backup_remove_error)])

	if FileAccess.file_exists(LEGACY_SAVE_BACKUP_FILE):
		var legacy_remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_SAVE_BACKUP_FILE))
		if legacy_remove_error != OK:
			failures.append("could not remove legacy backup file: %s" % error_string(legacy_remove_error))


func _remove_slot_files(slot_id: String) -> void:
	var paths: Array[String] = [_get_slot_save_file(slot_id)]
	for backup_index in range(1, 4):
		paths.append(_get_slot_backup_file(slot_id, backup_index))

	for save_path in paths:
		if not FileAccess.file_exists(save_path):
			continue
		var remove_error := DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
		if remove_error != OK:
			failures.append("could not remove slot save file %s: %s" % [save_path, error_string(remove_error)])


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


func _check_delete_slot_clears_save_and_backups() -> void:
	var slot_id := "slot_03"
	_remove_slot_files(slot_id)
	var first_world := WorldState.create_default()
	first_world.world_id = "world.delete.first"
	_expect_success(save_service.save_game_for_slot(slot_id, first_world, CharacterState.create_default()), "save delete slot first")
	var second_world := WorldState.create_default()
	second_world.world_id = "world.delete.second"
	_expect_success(save_service.save_game_for_slot(slot_id, second_world, CharacterState.create_default()), "save delete slot second")
	if not FileAccess.file_exists(_get_slot_save_file(slot_id)):
		failures.append("delete slot setup should create primary save")
	if not FileAccess.file_exists(_get_slot_backup_file(slot_id, 1)):
		failures.append("delete slot setup should create backup")

	var delete_result := save_service.delete_game_for_slot(slot_id)
	_expect_success(delete_result, "delete slot")
	if FileAccess.file_exists(_get_slot_save_file(slot_id)):
		failures.append("delete slot should remove primary save")
	for backup_index in range(1, 4):
		if FileAccess.file_exists(_get_slot_backup_file(slot_id, backup_index)):
			failures.append("delete slot should remove backup %d" % backup_index)

	var empty_summary := save_service.get_save_slot_summary(slot_id)
	_expect_equal(String(empty_summary.get("status", "")), "空槽位", "deleted slot summary status")
	_expect_equal(bool(empty_summary.get("has_loadable_save", true)), false, "deleted slot should not be loadable")


func _check_quick_slot_binding_persists() -> void:
	var slot_id := "slot_02"
	var character_state := CharacterState.create_default()
	_expect_success(
		character_state.bind_quick_slot(0, "item.resistance_vial_t1", data_registry),
		"bind resistance vial to slot 1"
	)
	_expect_success(character_state.bind_quick_slot(1, "", data_registry), "clear quick slot 2")
	_expect_failure_message(
		character_state.bind_quick_slot(0, "item.basic_parts", data_registry),
		"暂不能绑定到快捷栏",
		"reject unsupported quick slot item"
	)

	var save_result := save_service.save_game_for_slot(slot_id, WorldState.create_default(), character_state)
	_expect_success(save_result, "save quick slot bindings")
	var load_result := save_service.load_game_for_slot(slot_id)
	_expect_success(load_result, "load quick slot bindings")
	if not bool(load_result.get("success", false)):
		return

	var loaded_character: CharacterState = load_result["character_state"]
	_expect_equal(loaded_character.quick_slots, ["item.resistance_vial_t1", ""], "quick slot bindings persist")


func _check_save_slot_summaries() -> void:
	var slot_id := "slot_03"
	_remove_slot_files(slot_id)

	var empty_summary := save_service.get_save_slot_summary(slot_id)
	_expect_equal(bool(empty_summary.get("has_loadable_save", true)), false, "empty slot should not be loadable")
	_expect_equal(String(empty_summary.get("status", "")), "空槽位", "empty slot status")

	var world_state := WorldState.create_default()
	world_state.world_id = "world.slot.summary"
	_expect_success(save_service.save_game_for_slot(slot_id, world_state, CharacterState.create_default()), "save slot summary")

	var saved_summary := save_service.get_save_slot_summary(slot_id)
	_expect_equal(bool(saved_summary.get("has_loadable_save", false)), true, "saved slot should be loadable")
	_expect_equal(String(saved_summary.get("status", "")), "可读取", "saved slot status")
	var saved_details := String(saved_summary.get("details", ""))
	if not saved_details.contains("最近保存"):
		failures.append("saved slot summary should mention update time, got: %s" % saved_details)

	var summaries := save_service.get_save_slot_summaries(["slot_01", slot_id])
	_expect_equal(summaries.size(), 2, "slot summary list size")
	_expect_equal(String(summaries[1].get("slot_id", "")), slot_id, "slot summary list order")

	var later_world_state := WorldState.create_default()
	later_world_state.world_id = "world.slot.summary.latest"
	_expect_success(save_service.save_game_for_slot(slot_id, later_world_state, CharacterState.create_default()), "save slot summary with backup")
	_write_text_file(_get_slot_save_file(slot_id), "{")

	var backup_summary := save_service.get_save_slot_summary(slot_id)
	_expect_equal(bool(backup_summary.get("has_loadable_save", false)), true, "bad primary summary should still be loadable from backup")
	_expect_equal(bool(backup_summary.get("recovered_from_backup", false)), true, "bad primary summary should mark backup")
	if not String(backup_summary.get("status", "")).contains("备份 1"):
		failures.append("bad primary summary should mention backup 1, got: %s" % String(backup_summary.get("status", "")))


func _check_migrates_legacy_primary_save() -> void:
	_remove_save_file()
	_remove_backup_files()
	_write_legacy_save_json(_make_save_data("world.legacy.primary"))

	var result := save_service.load_game()
	_expect_success(result, "migrate legacy primary")
	if not bool(result.get("success", false)):
		return

	_expect_equal(bool(result.get("migrated_from_legacy", false)), true, "legacy primary should mark migration")
	_expect_equal(String(result.get("source_file", "")), SaveService.LEGACY_SAVE_FILE, "legacy primary source file")
	_expect_recovered_world_id(result, "world.legacy.primary", "legacy primary migrated world")
	if not FileAccess.file_exists(SaveService.SAVE_FILE):
		failures.append("legacy migration should write default slot save")
	if not FileAccess.file_exists(SaveService.LEGACY_SAVE_FILE):
		failures.append("legacy migration should keep original legacy file")
	var message := String(result.get("message", ""))
	if not message.contains("旧原型存档"):
		failures.append("legacy primary migration message should mention old prototype save, got: %s" % message)


func _check_migrates_legacy_backup_when_legacy_primary_is_bad() -> void:
	_remove_save_file()
	_remove_backup_files()
	_write_text_file(SaveService.LEGACY_SAVE_FILE, "{")
	_write_save_json_to_path(String(SaveService.LEGACY_SAVE_BACKUP_FILES[0]), _make_save_data("world.legacy.bak1"))

	var result := save_service.load_game()
	_expect_success(result, "migrate legacy bak1 after bad legacy primary")
	if not bool(result.get("success", false)):
		return

	_expect_equal(bool(result.get("migrated_from_legacy", false)), true, "legacy bak1 should mark migration")
	_expect_equal(String(result.get("source_file", "")), String(SaveService.LEGACY_SAVE_BACKUP_FILES[0]), "legacy bak1 source file")
	_expect_recovered_world_id(result, "world.legacy.bak1", "legacy bak1 migrated world")
	if not FileAccess.file_exists(SaveService.SAVE_FILE):
		failures.append("legacy backup migration should write default slot save")
	var message := String(result.get("message", ""))
	if not message.contains("旧原型备份 1"):
		failures.append("legacy backup migration message should mention backup 1, got: %s" % message)


func _check_existing_slot_blocks_legacy_migration() -> void:
	_remove_save_file()
	_remove_backup_files()
	_write_save_text("{")
	_write_legacy_save_json(_make_save_data("world.legacy.should_not_load"))

	var result := save_service.load_game()
	_expect_failure_message(result, "JSON 解析失败", "bad slot should not fall back to legacy")
	if result.has("world_state") or result.has("character_state"):
		failures.append("bad existing slot should not return legacy state")


func _check_rejects_unknown_inventory_id() -> void:
	_remove_save_file()
	_remove_backup_files()
	var save_data := _make_save_data("world.invalid.unknown_item")
	save_data["character"]["inventory"]["items"]["item.missing_debug"] = 1
	_write_save_json(save_data)
	_expect_failure_message(save_service.load_game(), "未知定义 ID", "unknown inventory item")


func _check_rejects_negative_inventory_amount() -> void:
	_remove_save_file()
	_remove_backup_files()
	var save_data := _make_save_data("world.invalid.negative_item")
	save_data["character"]["inventory"]["items"]["item.basic_parts"] = -1
	_write_save_json(save_data)
	_expect_failure_message(save_service.load_game(), "无效数量", "negative inventory amount")


func _check_rejects_unknown_region_id() -> void:
	_remove_save_file()
	_remove_backup_files()
	var save_data := _make_save_data("world.invalid.region")
	save_data["world"]["current_region_id"] = "region.missing_debug"
	_write_save_json(save_data)
	_expect_failure_message(save_service.load_game(), "未知定义 ID", "unknown world region")


func _check_rejects_invalid_character_position() -> void:
	_remove_save_file()
	_remove_backup_files()
	var save_data := _make_save_data("world.invalid.position")
	save_data["character"]["position"] = {
		"x": "bad",
		"y": 0
	}
	_write_save_json(save_data)
	_expect_failure_message(save_service.load_game(), "character.position", "invalid character position")


func _check_rejects_invalid_enemy_health() -> void:
	_remove_save_file()
	_remove_backup_files()
	var save_data := _make_save_data("world.invalid.enemy_health")
	save_data["world"]["enemies"] = {
		"enemy_instance.polluted_skitter": {
			"definition_id": "enemy.polluted_skitter",
			"region_id": "region.pollution_edge",
			"health": 10,
			"max_health": 5
		}
	}
	save_data["world"]["unlocked_region_ids"] = ["region.outpost_platform", "region.pollution_edge"]
	_write_save_json(save_data)
	_expect_failure_message(save_service.load_game(), "敌人生命值超出有效范围", "invalid enemy health")


func _check_save_rejects_invalid_current_state() -> void:
	var invalid_world := WorldState.create_default()
	var invalid_character := CharacterState.create_default()
	invalid_world.current_region_id = "region.deep_ruin_threshold"
	invalid_character.current_region_id = "region.deep_ruin_threshold"
	var result := save_service.save_game(invalid_world, invalid_character)
	_expect_failure_message(result, "未通过存档校验", "save rejects invalid current state")
	_expect_failure_message(result, "世界当前区域尚未解锁", "save invalid current state keeps validator detail")


func _check_rejects_locked_current_region() -> void:
	_remove_save_file()
	_remove_backup_files()
	var save_data := _make_save_data("world.invalid.locked_region")
	save_data["world"]["current_region_id"] = "region.pollution_edge"
	save_data["character"]["current_region_id"] = "region.pollution_edge"
	_write_save_json(save_data)
	_expect_failure_message(save_service.load_game(), "世界当前区域尚未解锁", "locked current region")


func _check_rejects_region_mismatch() -> void:
	_remove_save_file()
	_remove_backup_files()
	var save_data := _make_save_data("world.invalid.region_mismatch")
	save_data["world"]["unlocked_region_ids"] = ["region.outpost_platform", "region.crystal_vein_field"]
	save_data["world"]["current_region_id"] = "region.crystal_vein_field"
	save_data["character"]["current_region_id"] = "region.outpost_platform"
	_write_save_json(save_data)
	_expect_failure_message(save_service.load_game(), "世界区域与角色区域不一致", "world character region mismatch")


func _check_rejects_quest_state_overlap() -> void:
	_remove_save_file()
	_remove_backup_files()
	var save_data := _make_save_data("world.invalid.quest_overlap")
	_mark_restore_outpost_completed(save_data)
	save_data["world"]["quest_state"]["active_quest_ids"] = ["quest.restore_outpost"]
	save_data["world"]["quest_state"]["completed_quest_ids"] = ["quest.restore_outpost"]
	_write_save_json(save_data)
	_expect_failure_message(save_service.load_game(), "任务同时处于进行中和已完成状态", "quest overlap")


func _check_rejects_missing_quest_prerequisite() -> void:
	_remove_save_file()
	_remove_backup_files()
	var save_data := _make_save_data("world.invalid.quest_prerequisite")
	save_data["world"]["quest_state"]["objective_progress"] = {
		"quest.make_filter_module|craft_item|equipment.filter_module_t1": 1
	}
	save_data["world"]["quest_state"]["active_quest_ids"] = ["quest.make_filter_module"]
	save_data["world"]["quest_state"]["completed_quest_ids"] = []
	_write_save_json(save_data)
	_expect_failure_message(save_service.load_game(), "任务前置关系不完整", "missing quest prerequisite")


func _check_rejects_missing_structure_site() -> void:
	_remove_save_file()
	_remove_backup_files()
	var save_data := _make_save_data("world.invalid.structure_site")
	save_data["world"]["base_structures"]["structure.foundation_site_north"] = {
		"definition_id": "building.foundation_t1",
		"region_id": "region.outpost_platform",
		"status": "idle",
		"site_instance_id": "map_object_instance.foundation_site_north"
	}
	_write_save_json(save_data)
	_expect_failure_message(save_service.load_game(), "引用了不存在的建造点", "missing structure site")


func _mark_restore_outpost_completed(save_data: Dictionary) -> void:
	save_data["world"]["unlocked_region_ids"] = ["region.outpost_platform", "region.crystal_vein_field"]
	save_data["world"]["quest_state"]["active_quest_ids"] = []
	save_data["world"]["quest_state"]["completed_quest_ids"] = ["quest.restore_outpost"]
	save_data["world"]["quest_state"]["objective_progress"] = {"quest.restore_outpost|interact|building.outpost_core": 1}
	save_data["world"]["quest_state"]["unlocked_effects"] = ["region.outpost_platform", "region.crystal_vein_field", "recipe.process_crystal_ore"]

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
	world_state.unlock_region("region.ruin_outer_ring")
	world_state.current_region_id = "region.pollution_edge"
	world_state.quest_state.active_quest_ids = ["quest.scout_ruin_outer_ring"]
	world_state.quest_state.completed_quest_ids = [
		"quest.restore_outpost",
		"quest.scout_crystal_field",
		"quest.calibrate_reactor",
		"quest.bring_back_sample",
		"quest.analyze_anomaly_sample",
		"quest.make_filter_module",
		"quest.prepare_treatment_supplies",
		"quest.expand_treatment_point",
		"quest.enter_pollution_edge",
		"quest.defeat_elite_node",
		"quest.unlock_ruin_signal"
	]
	world_state.quest_state.objective_progress = {
		"quest.restore_outpost|interact|building.outpost_core": 1,
		"quest.scout_crystal_field|visit_region|region.crystal_vein_field": 1,
		"quest.scout_crystal_field|gather_item|item.crystal_ore": 6,
		"quest.calibrate_reactor|gather_item|item.salvage_scrap": 4,
		"quest.calibrate_reactor|craft_item|item.reactor_calibrator": 1,
		"quest.bring_back_sample|sample_object|map_object.anomaly_crystal": 1,
		"quest.analyze_anomaly_sample|gather_item|item.anomaly_residue": 2,
		"quest.analyze_anomaly_sample|craft_item|item.sample_analysis": 1,
		"quest.make_filter_module|craft_item|equipment.filter_module_t1": 1,
		"quest.prepare_treatment_supplies|craft_item|item.repair_gel": 1,
		"quest.prepare_treatment_supplies|defeat_enemy|enemy.treatment_skitter": 1,
		"quest.expand_treatment_point|build|building.foundation_t1": 2,
		"quest.expand_treatment_point|build|building.pollution_filter": 1,
		"quest.enter_pollution_edge|visit_region|region.pollution_edge": 1,
		"quest.enter_pollution_edge|gather_item|item.polluted_residue": 2,
		"quest.enter_pollution_edge|craft_item|item.resistance_vial_t1": 1,
		"quest.enter_pollution_edge|defeat_enemy|enemy.polluted_skitter": 1,
		"quest.defeat_elite_node|defeat_enemy|enemy.elite_residue_node": 1,
		"quest.unlock_ruin_signal|inspect|map_object.ruin_gate": 1
	}
	world_state.quest_state.unlocked_effects = [
		"region.outpost_platform",
		"region.crystal_vein_field",
		"recipe.process_crystal_ore",
		"recipe.repair_gel",
		"recipe.reactor_calibrator",
		"recipe.analyze_anomaly_sample",
		"recipe.make_filter_media",
		"recipe.basic_filter_module",
		"recipe.foundation_t1",
		"region.pollution_edge",
		"recipe.cleanse_residue",
		"region.locked_ruin_gate",
		"region.ruin_outer_ring"
	]

	var character_state := CharacterState.create_default()
	character_state.current_region_id = "region.pollution_edge"
	_expect_success(save_service.save_game(world_state, character_state), "save slice end hook state")
	var load_result := save_service.load_game()
	_expect_success(load_result, "load slice end hook state")
	if not bool(load_result.get("success", false)):
		return

	var loaded_world: WorldState = load_result["world_state"]
	_expect_array_has(loaded_world.unlocked_region_ids, "region.locked_ruin_gate", "slice hook unlocked ruin gate region")
	_expect_array_has(loaded_world.unlocked_region_ids, "region.ruin_outer_ring", "slice hook unlocked outer ring region")
	_expect_array_has(loaded_world.quest_state.active_quest_ids, "quest.scout_ruin_outer_ring", "slice hook active outer ring scout quest")
	_expect_array_has(loaded_world.quest_state.completed_quest_ids, "quest.enter_pollution_edge", "slice hook completed pollution edge quest")
	_expect_array_has(loaded_world.quest_state.completed_quest_ids, "quest.defeat_elite_node", "slice hook completed elite node quest")
	_expect_array_has(loaded_world.quest_state.completed_quest_ids, "quest.unlock_ruin_signal", "slice hook completed ruin signal quest")
	_expect_array_has(loaded_world.quest_state.unlocked_effects, "region.locked_ruin_gate", "slice hook persisted ruin gate unlock")
	_expect_array_has(loaded_world.quest_state.unlocked_effects, "region.ruin_outer_ring", "slice hook persisted outer ring unlock")
	_expect_equal(
		loaded_world.quest_state.get_objective_progress("quest.enter_pollution_edge", "defeat_enemy", "enemy.polluted_skitter"),
		1.0,
		"slice hook polluted enemy objective"
	)
	_expect_equal(
		loaded_world.quest_state.get_objective_progress("quest.defeat_elite_node", "defeat_enemy", "enemy.elite_residue_node"),
		1.0,
		"slice hook elite node objective"
	)


func _check_slice_complete_state_persists() -> void:
	var world_state := WorldState.create_default()
	world_state.unlock_region("region.crystal_vein_field")
	world_state.unlock_region("region.pollution_edge")
	world_state.unlock_region("region.locked_ruin_gate")
	world_state.unlock_region("region.ruin_outer_ring")
	world_state.current_region_id = "region.ruin_outer_ring"
	world_state.quest_state.active_quest_ids = []
	world_state.quest_state.completed_quest_ids = [
		"quest.restore_outpost",
		"quest.scout_crystal_field",
		"quest.calibrate_reactor",
		"quest.bring_back_sample",
		"quest.analyze_anomaly_sample",
		"quest.make_filter_module",
		"quest.prepare_treatment_supplies",
		"quest.expand_treatment_point",
		"quest.enter_pollution_edge",
		"quest.defeat_elite_node",
		"quest.unlock_ruin_signal",
		"quest.scout_ruin_outer_ring",
		"quest.assemble_phase_anchor",
		"quest.stabilize_outer_ring_barrier",
		"quest.secure_outer_ring_signal"
	]
	world_state.quest_state.objective_progress = {
		"quest.restore_outpost|interact|building.outpost_core": 1,
		"quest.scout_crystal_field|visit_region|region.crystal_vein_field": 1,
		"quest.scout_crystal_field|gather_item|item.crystal_ore": 6,
		"quest.calibrate_reactor|gather_item|item.salvage_scrap": 4,
		"quest.calibrate_reactor|craft_item|item.reactor_calibrator": 1,
		"quest.bring_back_sample|sample_object|map_object.anomaly_crystal": 1,
		"quest.analyze_anomaly_sample|gather_item|item.anomaly_residue": 2,
		"quest.analyze_anomaly_sample|craft_item|item.sample_analysis": 1,
		"quest.make_filter_module|craft_item|equipment.filter_module_t1": 1,
		"quest.prepare_treatment_supplies|craft_item|item.repair_gel": 1,
		"quest.prepare_treatment_supplies|defeat_enemy|enemy.treatment_skitter": 1,
		"quest.expand_treatment_point|build|building.foundation_t1": 2,
		"quest.expand_treatment_point|build|building.pollution_filter": 1,
		"quest.enter_pollution_edge|visit_region|region.pollution_edge": 1,
		"quest.enter_pollution_edge|gather_item|item.polluted_residue": 2,
		"quest.enter_pollution_edge|craft_item|item.resistance_vial_t1": 1,
		"quest.enter_pollution_edge|defeat_enemy|enemy.polluted_skitter": 1,
		"quest.defeat_elite_node|defeat_enemy|enemy.elite_residue_node": 1,
		"quest.unlock_ruin_signal|inspect|map_object.ruin_gate": 1,
		"quest.scout_ruin_outer_ring|visit_region|region.ruin_outer_ring": 1,
		"quest.scout_ruin_outer_ring|gather_item|item.relay_shard": 2,
		"quest.assemble_phase_anchor|craft_item|item.phase_anchor": 1,
		"quest.stabilize_outer_ring_barrier|inspect|map_object.outer_ring_barrier": 1,
		"quest.secure_outer_ring_signal|inspect|map_object.outer_ring_console": 1
	}
	world_state.quest_state.unlocked_effects = [
		"region.outpost_platform",
		"region.crystal_vein_field",
		"recipe.process_crystal_ore",
		"recipe.repair_gel",
		"recipe.reactor_calibrator",
		"recipe.analyze_anomaly_sample",
		"recipe.make_filter_media",
		"recipe.basic_filter_module",
		"recipe.foundation_t1",
		"region.pollution_edge",
		"recipe.cleanse_residue",
		"region.locked_ruin_gate",
		"region.ruin_outer_ring",
		"recipe.phase_anchor",
		"slice_01_complete"
	]

	var character_state := CharacterState.create_default()
	character_state.current_region_id = "region.ruin_outer_ring"
	character_state.position = Vector2(578, -64)
	_expect_success(save_service.save_game(world_state, character_state), "save slice complete state")
	var load_result := save_service.load_game()
	_expect_success(load_result, "load slice complete state")
	if not bool(load_result.get("success", false)):
		return

	var loaded_world: WorldState = load_result["world_state"]
	var loaded_character: CharacterState = load_result["character_state"]
	_expect_array_has(loaded_world.quest_state.completed_quest_ids, "quest.unlock_ruin_signal", "slice complete ruin signal quest")
	_expect_array_has(loaded_world.quest_state.completed_quest_ids, "quest.defeat_elite_node", "slice complete elite node quest")
	_expect_array_has(loaded_world.quest_state.completed_quest_ids, "quest.secure_outer_ring_signal", "slice complete outer ring quest")
	_expect_array_has(loaded_world.quest_state.unlocked_effects, "slice_01_complete", "slice complete unlock effect")
	_expect_equal(
		loaded_world.quest_state.get_objective_progress("quest.secure_outer_ring_signal", "inspect", "map_object.outer_ring_console"),
		1.0,
		"slice complete console objective"
	)
	_expect_equal(loaded_world.current_region_id, "region.ruin_outer_ring", "slice complete world region")
	_expect_equal(loaded_character.current_region_id, "region.ruin_outer_ring", "slice complete character region")
	_expect_equal(loaded_character.position, Vector2(578, -64), "slice complete character position")


func _check_deep_ruin_state_persists() -> void:
	_remove_save_file()
	_remove_backup_files()
	var world_state := WorldState.create_default()
	world_state.unlock_region("region.crystal_vein_field")
	world_state.unlock_region("region.pollution_edge")
	world_state.unlock_region("region.locked_ruin_gate")
	world_state.unlock_region("region.ruin_outer_ring")
	world_state.unlock_region("region.deep_ruin_threshold")
	world_state.current_region_id = "region.deep_ruin_threshold"
	world_state.quest_state.active_quest_ids = []
	world_state.quest_state.completed_quest_ids = [
		"quest.restore_outpost",
		"quest.scout_crystal_field",
		"quest.calibrate_reactor",
		"quest.bring_back_sample",
		"quest.analyze_anomaly_sample",
		"quest.make_filter_module",
		"quest.prepare_treatment_supplies",
		"quest.expand_treatment_point",
		"quest.enter_pollution_edge",
		"quest.defeat_elite_node",
		"quest.unlock_ruin_signal",
		"quest.scout_ruin_outer_ring",
		"quest.assemble_phase_anchor",
		"quest.stabilize_outer_ring_barrier",
		"quest.secure_outer_ring_signal",
		"quest.salvage_signal_echo",
		"quest.analyze_deep_signal",
		"quest.unlock_deep_ruin_entrance",
		"quest.harvest_phase_filament",
		"quest.refine_phase_filament",
		"quest.assemble_deep_override",
		"quest.unlock_deep_ruin_cache"
	]
	world_state.quest_state.objective_progress = {
		"quest.restore_outpost|interact|building.outpost_core": 1,
		"quest.scout_crystal_field|visit_region|region.crystal_vein_field": 1,
		"quest.scout_crystal_field|gather_item|item.crystal_ore": 6,
		"quest.calibrate_reactor|gather_item|item.salvage_scrap": 4,
		"quest.calibrate_reactor|craft_item|item.reactor_calibrator": 1,
		"quest.bring_back_sample|sample_object|map_object.anomaly_crystal": 1,
		"quest.analyze_anomaly_sample|gather_item|item.anomaly_residue": 2,
		"quest.analyze_anomaly_sample|craft_item|item.sample_analysis": 1,
		"quest.make_filter_module|craft_item|equipment.filter_module_t1": 1,
		"quest.prepare_treatment_supplies|craft_item|item.repair_gel": 1,
		"quest.prepare_treatment_supplies|defeat_enemy|enemy.treatment_skitter": 1,
		"quest.expand_treatment_point|build|building.foundation_t1": 2,
		"quest.expand_treatment_point|build|building.pollution_filter": 1,
		"quest.enter_pollution_edge|visit_region|region.pollution_edge": 1,
		"quest.enter_pollution_edge|gather_item|item.polluted_residue": 2,
		"quest.enter_pollution_edge|craft_item|item.resistance_vial_t1": 1,
		"quest.enter_pollution_edge|defeat_enemy|enemy.polluted_skitter": 1,
		"quest.defeat_elite_node|defeat_enemy|enemy.elite_residue_node": 1,
		"quest.unlock_ruin_signal|inspect|map_object.ruin_gate": 1,
		"quest.scout_ruin_outer_ring|visit_region|region.ruin_outer_ring": 1,
		"quest.scout_ruin_outer_ring|gather_item|item.relay_shard": 2,
		"quest.assemble_phase_anchor|craft_item|item.phase_anchor": 1,
		"quest.stabilize_outer_ring_barrier|inspect|map_object.outer_ring_barrier": 1,
		"quest.secure_outer_ring_signal|inspect|map_object.outer_ring_console": 1,
		"quest.salvage_signal_echo|defeat_enemy|enemy.ruin_phase_guard": 1,
		"quest.salvage_signal_echo|inspect|map_object.signal_echo_cache": 1,
		"quest.analyze_deep_signal|craft_item|item.deep_ruin_coordinates": 1,
		"quest.unlock_deep_ruin_entrance|inspect|map_object.deep_ruin_door": 1,
		"quest.harvest_phase_filament|visit_region|region.deep_ruin_threshold": 1,
		"quest.harvest_phase_filament|defeat_enemy|enemy.deep_ruin_sentinel": 1,
		"quest.harvest_phase_filament|gather_item|item.phase_filament": 2,
		"quest.refine_phase_filament|craft_item|item.resonance_filter": 1,
		"quest.assemble_deep_override|craft_item|item.deep_override_key": 1,
		"quest.unlock_deep_ruin_cache|inspect|map_object.deep_ruin_latch": 1
	}
	world_state.quest_state.unlocked_effects = [
		"region.outpost_platform",
		"region.crystal_vein_field",
		"recipe.process_crystal_ore",
		"recipe.repair_gel",
		"recipe.reactor_calibrator",
		"recipe.analyze_anomaly_sample",
		"recipe.make_filter_media",
		"recipe.basic_filter_module",
		"recipe.foundation_t1",
		"region.pollution_edge",
		"recipe.cleanse_residue",
		"region.locked_ruin_gate",
		"region.ruin_outer_ring",
		"recipe.phase_anchor",
		"slice_01_complete",
		"recipe.deep_signal_analysis",
		"region.deep_ruin_threshold",
		"recipe.phase_filament_refining",
		"recipe.deep_override_key"
	]

	var character_state := CharacterState.create_default()
	character_state.current_region_id = "region.deep_ruin_threshold"
	character_state.position = Vector2(764, 12)
	character_state.inventory.add_item("item.deep_ruin_core", 1)
	_expect_success(save_service.save_game(world_state, character_state), "save deep ruin first pass state")
	var load_result := save_service.load_game()
	_expect_success(load_result, "load deep ruin first pass state")
	if not bool(load_result.get("success", false)):
		return

	var loaded_world: WorldState = load_result["world_state"]
	var loaded_character: CharacterState = load_result["character_state"]
	_expect_equal(loaded_world.current_region_id, "region.deep_ruin_threshold", "deep ruin world region")
	_expect_equal(loaded_character.current_region_id, "region.deep_ruin_threshold", "deep ruin character region")
	_expect_equal(loaded_character.position, Vector2(764, 12), "deep ruin character position")
	_expect_equal(loaded_world.quest_state.active_quest_ids, [], "deep ruin first pass should not keep active quest")
	_expect_array_has(loaded_world.unlocked_region_ids, "region.deep_ruin_threshold", "deep ruin region persists")
	_expect_array_has(loaded_world.quest_state.completed_quest_ids, "quest.unlock_deep_ruin_cache", "deep ruin latch quest persists")
	_expect_array_has(loaded_world.quest_state.unlocked_effects, "recipe.deep_override_key", "deep override recipe unlock persists")
	_expect_equal(int(loaded_character.inventory.items.get("item.deep_ruin_core", 0)), 1, "deep ruin reward persists")


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


func _get_slot_save_file(slot_id: String) -> String:
	return "user://saves/slots/%s/%s" % [slot_id, SaveService.SAVE_FILE_NAME]


func _get_slot_backup_file(slot_id: String, backup_index: int) -> String:
	return "user://saves/slots/%s/slice_01_autosave.bak.%d.json" % [slot_id, backup_index]


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


func _cleanup() -> void:
	data_registry.free()
