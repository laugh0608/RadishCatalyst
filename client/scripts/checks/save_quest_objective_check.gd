extends RefCounted

var host


func _init(check_host) -> void:
	host = check_host


func run() -> void:
	_check_loads_active_quest_with_partial_defined_objective_progress()
	_check_rejects_objective_progress_for_untracked_quest()
	_check_rejects_quest_progress_with_undefined_objective_type()
	_check_rejects_quest_progress_with_undefined_objective_target()
	_check_loads_completed_quest_with_objectives()
	_check_rejects_completed_quest_without_objective_progress()
	_check_rejects_completed_quest_with_partial_objective_progress()


func _check_loads_active_quest_with_partial_defined_objective_progress() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.valid.active_partial_objective")
	host._mark_restore_outpost_completed(save_data)
	save_data["world"]["quest_state"]["active_quest_ids"] = ["quest.scout_crystal_field"]
	save_data["world"]["quest_state"]["objective_progress"]["quest.scout_crystal_field|visit_region|region.crystal_vein_field"] = 1
	host._write_save_json(save_data)
	host._expect_success(host.save_service.load_game(), "active quest with partial defined objective progress")


func _check_rejects_objective_progress_for_untracked_quest() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.untracked_objective_progress")
	save_data["world"]["quest_state"]["objective_progress"]["quest.scout_crystal_field|visit_region|region.crystal_vein_field"] = 1
	host._write_save_json(save_data)
	host._expect_failure_message(
		host.save_service.load_game(),
		"quest_state.objective_progress 记录了未处于进行中或已完成状态的任务",
		"objective progress for untracked quest"
	)


func _check_rejects_quest_progress_with_undefined_objective_type() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.undefined_objective_type")
	host._mark_restore_outpost_completed(save_data)
	save_data["world"]["quest_state"]["active_quest_ids"] = ["quest.scout_crystal_field"]
	save_data["world"]["quest_state"]["objective_progress"]["quest.scout_crystal_field|inspect|region.crystal_vein_field"] = 1
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "任务未定义的目标", "undefined quest objective type")


func _check_rejects_quest_progress_with_undefined_objective_target() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.undefined_objective_target")
	host._mark_restore_outpost_completed(save_data)
	save_data["world"]["quest_state"]["active_quest_ids"] = ["quest.scout_crystal_field"]
	save_data["world"]["quest_state"]["objective_progress"]["quest.scout_crystal_field|gather_item|item.basic_parts"] = 1
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "任务未定义的目标", "undefined quest objective target")


func _check_loads_completed_quest_with_objectives() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.valid.completed_objectives")
	host._mark_restore_outpost_completed(save_data)
	host._write_save_json(save_data)
	host._expect_success(host.save_service.load_game(), "completed quest with objective progress")


func _check_rejects_completed_quest_without_objective_progress() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.completed_without_objectives")
	save_data["world"]["quest_state"]["active_quest_ids"] = []
	save_data["world"]["quest_state"]["completed_quest_ids"] = ["quest.restore_outpost"]
	save_data["world"]["quest_state"]["objective_progress"] = {}
	save_data["world"]["quest_state"]["unlocked_effects"] = ["region.outpost_platform", "region.crystal_vein_field", "recipe.process_crystal_ore"]
	save_data["world"]["unlocked_region_ids"] = ["region.outpost_platform", "region.crystal_vein_field"]
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "已完成任务目标进度不足", "completed quest without objective progress")


func _check_rejects_completed_quest_with_partial_objective_progress() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.completed_partial_objectives")
	save_data["world"]["quest_state"]["active_quest_ids"] = []
	save_data["world"]["quest_state"]["completed_quest_ids"] = ["quest.restore_outpost", "quest.scout_crystal_field"]
	save_data["world"]["quest_state"]["objective_progress"] = {
		"quest.restore_outpost|interact|building.outpost_core": 1,
		"quest.scout_crystal_field|visit_region|region.crystal_vein_field": 1,
		"quest.scout_crystal_field|gather_item|item.crystal_ore": 3
	}
	save_data["world"]["quest_state"]["unlocked_effects"] = ["region.outpost_platform", "region.crystal_vein_field", "recipe.process_crystal_ore", "recipe.repair_gel"]
	save_data["world"]["unlocked_region_ids"] = ["region.outpost_platform", "region.crystal_vein_field"]
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "已完成任务目标进度不足", "completed quest with partial objective progress")
