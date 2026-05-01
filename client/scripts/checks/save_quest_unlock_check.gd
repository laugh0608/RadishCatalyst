extends RefCounted

var host


func _init(check_host) -> void:
	host = check_host


func run() -> void:
	_check_loads_completed_quest_with_full_unlock_effects()
	_check_loads_active_quest_from_completed_quest()
	_check_rejects_active_quest_without_completed_quest_source()
	_check_rejects_completed_quest_missing_recipe_unlock_effect()
	_check_rejects_completed_quest_missing_quest_unlock_effect()
	_check_rejects_completed_quest_missing_slice_unlock_effect()
	_check_rejects_quest_unlock_without_completed_quest_source()
	_check_rejects_slice_unlock_without_completed_quest_source()


func _check_loads_completed_quest_with_full_unlock_effects() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.valid.full_unlock_effects")
	_mark_bring_back_sample_completed(save_data)
	host._write_save_json(save_data)
	host._expect_success(host.save_service.load_game(), "completed quest with full unlock effects")


func _check_loads_active_quest_from_completed_quest() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.valid.active_quest_source")
	_mark_bring_back_sample_completed(save_data)
	host._write_save_json(save_data)
	host._expect_success(host.save_service.load_game(), "active quest from completed quest")


func _check_rejects_active_quest_without_completed_quest_source() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.active_quest_source")
	host._mark_restore_outpost_completed(save_data)
	save_data["world"]["quest_state"]["active_quest_ids"] = ["quest.defeat_elite_node"]
	save_data["world"]["quest_state"]["completed_quest_ids"] = [
		"quest.restore_outpost",
		"quest.scout_crystal_field",
		"quest.bring_back_sample",
		"quest.make_filter_module",
		"quest.expand_treatment_point",
		"quest.enter_pollution_edge"
	]
	save_data["world"]["quest_state"]["objective_progress"] = {
		"quest.restore_outpost|interact|building.outpost_core": 1,
		"quest.scout_crystal_field|visit_region|region.crystal_vein_field": 1,
		"quest.scout_crystal_field|gather_item|item.crystal_ore": 6,
		"quest.bring_back_sample|sample_object|map_object.anomaly_crystal": 1,
		"quest.bring_back_sample|return_region|region.outpost_platform": 1,
		"quest.make_filter_module|craft_item|equipment.filter_module_t1": 1,
		"quest.expand_treatment_point|build|building.foundation_t1": 2,
		"quest.expand_treatment_point|build|building.pollution_filter": 1,
		"quest.enter_pollution_edge|visit_region|region.pollution_edge": 1,
		"quest.enter_pollution_edge|gather_item|item.polluted_residue": 2,
		"quest.enter_pollution_edge|craft_item|item.resistance_vial_t1": 1,
		"quest.enter_pollution_edge|defeat_enemy|enemy.polluted_skitter": 1
	}
	save_data["world"]["quest_state"]["unlocked_effects"] = [
		"region.outpost_platform",
		"region.crystal_vein_field",
		"recipe.process_crystal_ore",
		"recipe.repair_gel",
		"recipe.make_filter_media",
		"quest.make_filter_module",
		"quest.expand_treatment_point",
		"recipe.foundation_t1",
		"region.pollution_edge",
		"recipe.cleanse_residue",
		"region.locked_ruin_gate"
	]
	save_data["world"]["unlocked_region_ids"] = [
		"region.outpost_platform",
		"region.crystal_vein_field",
		"region.pollution_edge",
		"region.locked_ruin_gate"
	]
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "进行中任务缺少已完成任务来源", "active quest without completed quest source")


func _check_rejects_completed_quest_missing_recipe_unlock_effect() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.missing_recipe_unlock")
	host._mark_restore_outpost_completed(save_data)
	save_data["world"]["quest_state"]["unlocked_effects"].erase("recipe.process_crystal_ore")
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "已完成任务缺少解锁效果", "completed quest missing recipe unlock")


func _check_rejects_completed_quest_missing_quest_unlock_effect() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.missing_quest_unlock")
	_mark_bring_back_sample_completed(save_data)
	save_data["world"]["quest_state"]["unlocked_effects"].erase("quest.make_filter_module")
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "已完成任务缺少解锁效果", "completed quest missing quest unlock")


func _check_rejects_completed_quest_missing_slice_unlock_effect() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.missing_slice_unlock")
	_mark_slice_complete(save_data)
	save_data["world"]["quest_state"]["unlocked_effects"].erase("slice_01_complete")
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "已完成任务缺少解锁效果", "completed quest missing slice unlock")


func _check_rejects_quest_unlock_without_completed_quest_source() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.quest_unlock_source")
	host._mark_restore_outpost_completed(save_data)
	save_data["world"]["quest_state"]["unlocked_effects"].append("quest.make_filter_module")
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "任务解锁效果缺少已完成任务来源", "quest unlock without completed quest source")


func _check_rejects_slice_unlock_without_completed_quest_source() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.slice_unlock_source")
	host._mark_restore_outpost_completed(save_data)
	save_data["world"]["quest_state"]["unlocked_effects"].append("slice_01_complete")
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "任务解锁效果缺少已完成任务来源", "slice unlock without completed quest source")


func _mark_bring_back_sample_completed(save_data: Dictionary) -> void:
	save_data["world"]["unlocked_region_ids"] = ["region.outpost_platform", "region.crystal_vein_field"]
	save_data["world"]["quest_state"]["active_quest_ids"] = ["quest.make_filter_module"]
	save_data["world"]["quest_state"]["completed_quest_ids"] = [
		"quest.restore_outpost",
		"quest.scout_crystal_field",
		"quest.bring_back_sample"
	]
	save_data["world"]["quest_state"]["objective_progress"] = {
		"quest.restore_outpost|interact|building.outpost_core": 1,
		"quest.scout_crystal_field|visit_region|region.crystal_vein_field": 1,
		"quest.scout_crystal_field|gather_item|item.crystal_ore": 6,
		"quest.bring_back_sample|sample_object|map_object.anomaly_crystal": 1,
		"quest.bring_back_sample|return_region|region.outpost_platform": 1
	}
	save_data["world"]["quest_state"]["unlocked_effects"] = [
		"region.outpost_platform",
		"region.crystal_vein_field",
		"recipe.process_crystal_ore",
		"recipe.repair_gel",
		"recipe.make_filter_media",
		"quest.make_filter_module"
	]


func _mark_slice_complete(save_data: Dictionary) -> void:
	save_data["world"]["unlocked_region_ids"] = [
		"region.outpost_platform",
		"region.crystal_vein_field",
		"region.pollution_edge",
		"region.locked_ruin_gate"
	]
	save_data["world"]["current_region_id"] = "region.locked_ruin_gate"
	save_data["character"]["current_region_id"] = "region.locked_ruin_gate"
	save_data["world"]["quest_state"]["active_quest_ids"] = []
	save_data["world"]["quest_state"]["completed_quest_ids"] = [
		"quest.restore_outpost",
		"quest.scout_crystal_field",
		"quest.bring_back_sample",
		"quest.make_filter_module",
		"quest.expand_treatment_point",
		"quest.enter_pollution_edge",
		"quest.unlock_ruin_signal"
	]
	save_data["world"]["quest_state"]["objective_progress"] = {
		"quest.restore_outpost|interact|building.outpost_core": 1,
		"quest.scout_crystal_field|visit_region|region.crystal_vein_field": 1,
		"quest.scout_crystal_field|gather_item|item.crystal_ore": 6,
		"quest.bring_back_sample|sample_object|map_object.anomaly_crystal": 1,
		"quest.bring_back_sample|return_region|region.outpost_platform": 1,
		"quest.make_filter_module|craft_item|equipment.filter_module_t1": 1,
		"quest.expand_treatment_point|build|building.foundation_t1": 2,
		"quest.expand_treatment_point|build|building.pollution_filter": 1,
		"quest.enter_pollution_edge|visit_region|region.pollution_edge": 1,
		"quest.enter_pollution_edge|gather_item|item.polluted_residue": 2,
		"quest.enter_pollution_edge|craft_item|item.resistance_vial_t1": 1,
		"quest.enter_pollution_edge|defeat_enemy|enemy.polluted_skitter": 1,
		"quest.unlock_ruin_signal|inspect|map_object.ruin_gate": 1
	}
	save_data["world"]["quest_state"]["unlocked_effects"] = [
		"region.outpost_platform",
		"region.crystal_vein_field",
		"recipe.process_crystal_ore",
		"recipe.repair_gel",
		"recipe.make_filter_media",
		"quest.make_filter_module",
		"quest.expand_treatment_point",
		"recipe.foundation_t1",
		"region.pollution_edge",
		"recipe.cleanse_residue",
		"region.locked_ruin_gate",
		"slice_01_complete"
	]
