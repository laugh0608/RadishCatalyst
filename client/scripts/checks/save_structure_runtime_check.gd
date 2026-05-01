extends RefCounted

var host


func _init(check_host) -> void:
	host = check_host


func run() -> void:
	_check_rejects_unknown_structure_source()
	_check_rejects_structure_source_definition_mismatch()
	_check_rejects_structure_source_site_mismatch()
	_check_rejects_structure_unknown_field()
	_check_loads_valid_structure_runtime_state()
	_check_rejects_structure_invalid_status()
	_check_rejects_structure_invalid_completed_runs()
	_check_rejects_structure_unknown_last_recipe()
	_check_rejects_structure_last_recipe_mismatch()
	_check_rejects_structure_locked_last_recipe()
	_check_loads_valid_structure_in_progress_state()
	_check_rejects_in_progress_without_active_recipe()
	_check_rejects_in_progress_without_progress()
	_check_rejects_structure_invalid_progress()
	_check_rejects_structure_progress_exceeds_duration()
	_check_rejects_structure_active_recipe_mismatch()
	_check_rejects_structure_locked_active_recipe()
	_check_rejects_idle_structure_with_active_recipe()
	_check_loads_valid_structure_buffers()
	_check_rejects_structure_buffer_unknown_item()
	_check_rejects_structure_buffer_negative_amount()
	_check_rejects_structure_buffer_unknown_field()
	_check_rejects_structure_buffer_capacity_exceeds_storage()


func _check_rejects_unknown_structure_source() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.unknown_structure_source")
	save_data["world"]["base_structures"]["structure.debug_extra"] = {
		"definition_id": "building.basic_reactor",
		"region_id": "region.outpost_platform",
		"status": "idle"
	}
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "没有匹配的原型建筑来源", "unknown structure source")


func _check_rejects_structure_source_definition_mismatch() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.structure_source_definition")
	save_data["world"]["base_structures"]["structure.basic_reactor"] = {
		"definition_id": "building.pollution_filter",
		"region_id": "region.outpost_platform",
		"status": "idle"
	}
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "原型建筑定义不一致", "structure source definition mismatch")


func _check_rejects_structure_source_site_mismatch() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.structure_source_site")
	save_data["world"]["base_structures"]["structure.foundation_site_north"] = {
		"definition_id": "building.foundation_t1",
		"region_id": "region.outpost_platform",
		"status": "idle",
		"site_instance_id": "map_object_instance.foundation_site_south"
	}
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "原型建筑建造点来源不一致", "structure source site mismatch")


func _check_rejects_structure_unknown_field() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.structure_unknown_field")
	save_data["world"]["base_structures"]["structure.basic_reactor"] = {
		"definition_id": "building.basic_reactor",
		"region_id": "region.outpost_platform",
		"status": "idle",
		"temporary_power_draw": 10
	}
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "包含不允许的字段", "structure unknown field")


func _check_loads_valid_structure_runtime_state() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.valid.structure_runtime_state")
	host._mark_restore_outpost_completed(save_data)
	save_data["world"]["base_structures"]["structure.basic_reactor"] = {
		"definition_id": "building.basic_reactor",
		"region_id": "region.outpost_platform",
		"status": "completed",
		"last_recipe_id": "recipe.process_crystal_ore",
		"completed_runs": 2
	}
	host._write_save_json(save_data)
	host._expect_success(host.save_service.load_game(), "valid structure runtime state")


func _check_rejects_structure_invalid_status() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.structure_status")
	save_data["world"]["base_structures"]["structure.basic_reactor"] = {
		"definition_id": "building.basic_reactor",
		"region_id": "region.outpost_platform",
		"status": "running"
	}
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "无效建筑状态", "invalid structure status")


func _check_rejects_structure_invalid_completed_runs() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.structure_completed_runs")
	save_data["world"]["base_structures"]["structure.basic_reactor"] = {
		"definition_id": "building.basic_reactor",
		"region_id": "region.outpost_platform",
		"status": "completed",
		"last_recipe_id": "recipe.process_crystal_ore",
		"completed_runs": -1
	}
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "completed_runs 必须是非负整数", "invalid structure completed runs")


func _check_rejects_structure_unknown_last_recipe() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.structure_unknown_recipe")
	save_data["world"]["base_structures"]["structure.basic_reactor"] = {
		"definition_id": "building.basic_reactor",
		"region_id": "region.outpost_platform",
		"status": "completed",
		"last_recipe_id": "recipe.debug_unknown",
		"completed_runs": 1
	}
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "引用了未知定义 ID", "unknown structure last recipe")


func _check_rejects_structure_last_recipe_mismatch() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.structure_recipe_mismatch")
	host._mark_restore_outpost_completed(save_data)
	save_data["world"]["base_structures"]["structure.pollution_filter_build_site"] = {
		"definition_id": "building.pollution_filter",
		"region_id": "region.outpost_platform",
		"status": "completed",
		"site_instance_id": "map_object_instance.pollution_filter_build_site",
		"last_recipe_id": "recipe.process_crystal_ore",
		"completed_runs": 1
	}
	save_data["world"]["map_objects"]["map_object_instance.pollution_filter_build_site"] = {
		"definition_id": "building.pollution_filter",
		"region_id": "region.outpost_platform",
		"is_built": true,
		"built_definition_id": "building.pollution_filter"
	}
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "last_recipe_id 与建筑定义不一致", "structure last recipe mismatch")


func _check_rejects_structure_locked_last_recipe() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.structure_locked_last_recipe")
	host._mark_restore_outpost_completed(save_data)
	save_data["world"]["base_structures"]["structure.basic_reactor"] = {
		"definition_id": "building.basic_reactor",
		"region_id": "region.outpost_platform",
		"status": "completed",
		"last_recipe_id": "recipe.basic_filter_module",
		"completed_runs": 1
	}
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "尚未解锁的配方", "locked structure last recipe")


func _check_loads_valid_structure_in_progress_state() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.valid.structure_in_progress")
	host._mark_restore_outpost_completed(save_data)
	save_data["world"]["base_structures"]["structure.basic_reactor"] = {
		"definition_id": "building.basic_reactor",
		"region_id": "region.outpost_platform",
		"status": "in_progress",
		"active_recipe_id": "recipe.process_crystal_ore",
		"progress_seconds": 4.0,
		"completed_runs": 1,
		"last_recipe_id": "recipe.process_crystal_ore"
	}
	host._write_save_json(save_data)
	host._expect_success(host.save_service.load_game(), "valid structure in progress state")


func _check_rejects_in_progress_without_active_recipe() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.structure_missing_active_recipe")
	save_data["world"]["base_structures"]["structure.basic_reactor"] = {
		"definition_id": "building.basic_reactor",
		"region_id": "region.outpost_platform",
		"status": "in_progress",
		"progress_seconds": 1.0
	}
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "加工中状态缺少 active_recipe_id", "missing active recipe")


func _check_rejects_in_progress_without_progress() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.structure_missing_progress")
	save_data["world"]["base_structures"]["structure.basic_reactor"] = {
		"definition_id": "building.basic_reactor",
		"region_id": "region.outpost_platform",
		"status": "in_progress",
		"active_recipe_id": "recipe.make_filter_media"
	}
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "加工中状态缺少 progress_seconds", "missing progress seconds")


func _check_rejects_structure_invalid_progress() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.structure_progress")
	host._mark_restore_outpost_completed(save_data)
	save_data["world"]["base_structures"]["structure.basic_reactor"] = {
		"definition_id": "building.basic_reactor",
		"region_id": "region.outpost_platform",
		"status": "in_progress",
		"active_recipe_id": "recipe.process_crystal_ore",
		"progress_seconds": -0.5
	}
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "progress_seconds 必须是非负数字", "invalid progress seconds")


func _check_rejects_structure_progress_exceeds_duration() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.structure_progress_duration")
	host._mark_restore_outpost_completed(save_data)
	save_data["world"]["base_structures"]["structure.basic_reactor"] = {
		"definition_id": "building.basic_reactor",
		"region_id": "region.outpost_platform",
		"status": "in_progress",
		"active_recipe_id": "recipe.process_crystal_ore",
		"progress_seconds": 7.0
	}
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "progress_seconds 超出配方时长", "progress exceeds recipe duration")


func _check_rejects_structure_active_recipe_mismatch() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.structure_active_recipe_mismatch")
	host._mark_restore_outpost_completed(save_data)
	save_data["world"]["base_structures"]["structure.pollution_filter_build_site"] = {
		"definition_id": "building.pollution_filter",
		"region_id": "region.outpost_platform",
		"status": "in_progress",
		"site_instance_id": "map_object_instance.pollution_filter_build_site",
		"active_recipe_id": "recipe.process_crystal_ore",
		"progress_seconds": 1.0
	}
	save_data["world"]["map_objects"]["map_object_instance.pollution_filter_build_site"] = {
		"definition_id": "building.pollution_filter",
		"region_id": "region.outpost_platform",
		"is_built": true,
		"built_definition_id": "building.pollution_filter"
	}
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "active_recipe_id 与建筑定义不一致", "structure active recipe mismatch")


func _check_rejects_structure_locked_active_recipe() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.structure_locked_active_recipe")
	host._mark_restore_outpost_completed(save_data)
	save_data["world"]["base_structures"]["structure.basic_reactor"] = {
		"definition_id": "building.basic_reactor",
		"region_id": "region.outpost_platform",
		"status": "in_progress",
		"active_recipe_id": "recipe.basic_filter_module",
		"progress_seconds": 1.0
	}
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "尚未解锁的配方", "locked structure active recipe")


func _check_rejects_idle_structure_with_active_recipe() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.structure_idle_active_recipe")
	save_data["world"]["base_structures"]["structure.basic_reactor"] = {
		"definition_id": "building.basic_reactor",
		"region_id": "region.outpost_platform",
		"status": "idle",
		"active_recipe_id": "recipe.process_crystal_ore"
	}
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "非加工中状态不应记录 active_recipe_id", "idle with active recipe")


func _check_loads_valid_structure_buffers() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.valid.structure_buffers")
	host._mark_restore_outpost_completed(save_data)
	save_data["world"]["base_structures"]["structure.basic_reactor"] = {
		"definition_id": "building.basic_reactor",
		"region_id": "region.outpost_platform",
		"status": "in_progress",
		"active_recipe_id": "recipe.process_crystal_ore",
		"progress_seconds": 2.0,
		"input_buffer": {
			"items": {
				"item.crystal_ore": 3
			},
			"fluids": {},
			"capacity_slots": 6
		},
		"output_buffer": {
			"items": {
				"item.basic_parts": 1
			},
			"capacity_slots": 6
		}
	}
	host._write_save_json(save_data)
	host._expect_success(host.save_service.load_game(), "valid structure buffers")


func _check_rejects_structure_buffer_unknown_item() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.structure_buffer_unknown_item")
	save_data["world"]["base_structures"]["structure.basic_reactor"] = {
		"definition_id": "building.basic_reactor",
		"region_id": "region.outpost_platform",
		"status": "idle",
		"input_buffer": {
			"items": {
				"item.debug_unknown": 1
			}
		}
	}
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "引用了未知定义 ID", "structure buffer unknown item")


func _check_rejects_structure_buffer_negative_amount() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.structure_buffer_negative_amount")
	save_data["world"]["base_structures"]["structure.basic_reactor"] = {
		"definition_id": "building.basic_reactor",
		"region_id": "region.outpost_platform",
		"status": "idle",
		"output_buffer": {
			"items": {
				"item.basic_parts": -1
			}
		}
	}
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "items 中存在无效数量", "structure buffer negative item")


func _check_rejects_structure_buffer_unknown_field() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.structure_buffer_unknown_field")
	save_data["world"]["base_structures"]["structure.basic_reactor"] = {
		"definition_id": "building.basic_reactor",
		"region_id": "region.outpost_platform",
		"status": "idle",
		"input_buffer": {
			"items": {},
			"temperature": 120
		}
	}
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "包含不允许的字段", "structure buffer unknown field")


func _check_rejects_structure_buffer_capacity_exceeds_storage() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.structure_buffer_capacity")
	save_data["world"]["base_structures"]["structure.basic_reactor"] = {
		"definition_id": "building.basic_reactor",
		"region_id": "region.outpost_platform",
		"status": "idle",
		"input_buffer": {
			"items": {},
			"capacity_slots": 7
		}
	}
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "capacity_slots 超出建筑储存槽位", "structure buffer capacity")
