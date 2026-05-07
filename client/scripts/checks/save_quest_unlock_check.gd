extends RefCounted

var host


func _init(check_host) -> void:
	host = check_host


func run() -> void:
	_check_loads_completed_quest_with_full_unlock_effects()
	_check_loads_completed_quest_chain_sources()
	_check_loads_active_quest_from_completed_quest()
	_check_rejects_active_quest_without_completed_quest_source()
	_check_rejects_completed_quest_without_chain_source()
	_check_rejects_recipe_unlock_effect_without_completed_quest_source()
	_check_rejects_world_region_unlock_without_completed_quest_source()
	_check_rejects_region_unlock_effect_without_world_region()
	_check_rejects_region_unlock_effect_without_completed_quest_source()
	_check_rejects_completed_quest_missing_recipe_unlock_effect()
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


func _check_loads_completed_quest_chain_sources() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.valid.completed_quest_chain_sources")
	_mark_slice_complete(save_data)
	host._write_save_json(save_data)
	host._expect_success(host.save_service.load_game(), "completed quest chain sources")


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
	save_data["world"]["quest_state"]["active_quest_ids"] = ["quest.unlock_ruin_signal"]
	save_data["world"]["quest_state"]["completed_quest_ids"] = [
		"quest.restore_outpost",
		"quest.scout_crystal_field",
		"quest.calibrate_reactor",
		"quest.bring_back_sample",
		"quest.analyze_anomaly_sample",
		"quest.make_filter_module",
		"quest.prepare_treatment_supplies",
		"quest.expand_treatment_point",
		"quest.enter_pollution_edge"
	]
	save_data["world"]["quest_state"]["objective_progress"] = {
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
		"quest.enter_pollution_edge|defeat_enemy|enemy.polluted_skitter": 1
	}
	save_data["world"]["quest_state"]["unlocked_effects"] = [
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
		"recipe.cleanse_residue"
	]
	save_data["world"]["unlocked_region_ids"] = [
		"region.outpost_platform",
		"region.crystal_vein_field",
		"region.pollution_edge"
	]
	host._write_save_json(save_data)
	host._expect_failure_message(
		host.save_service.load_game(),
		"任务前置关系不完整",
		"active quest without completed quest source"
	)


func _check_rejects_completed_quest_without_chain_source() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.completed_quest_chain_source")
	_mark_slice_complete(save_data)
	save_data["world"]["quest_state"]["completed_quest_ids"].erase("quest.defeat_elite_node")
	save_data["world"]["quest_state"]["objective_progress"].erase("quest.defeat_elite_node|defeat_enemy|enemy.elite_residue_node")
	host._write_save_json(save_data)
	host._expect_failure_message(
		host.save_service.load_game(),
		"任务前置关系不完整",
		"completed quest without chain source"
	)


func _check_rejects_recipe_unlock_effect_without_completed_quest_source() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.unlocked_effect_recipe_source")
	host._mark_restore_outpost_completed(save_data)
	save_data["world"]["quest_state"]["unlocked_effects"].append("recipe.basic_filter_module")
	host._write_save_json(save_data)
	host._expect_failure_message(
		host.save_service.load_game(),
		"quest_state.unlocked_effects 中的配方解锁缺少已完成任务 unlock_effects 来源",
		"unlocked_effects recipe without completed quest source"
	)


func _check_rejects_world_region_unlock_without_completed_quest_source() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.world_region_unlock_source")
	save_data["world"]["unlocked_region_ids"] = ["region.outpost_platform", "region.crystal_vein_field"]
	host._write_save_json(save_data)
	host._expect_failure_message(
		host.save_service.load_game(),
		"world.unlocked_region_ids 中的非默认区域缺少已完成任务 unlock_effects 来源",
		"world unlocked region without completed quest source"
	)


func _check_rejects_region_unlock_effect_without_world_region() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.unlocked_effect_region_not_in_world")
	save_data["world"]["quest_state"]["unlocked_effects"].append("region.crystal_vein_field")
	host._write_save_json(save_data)
	host._expect_failure_message(
		host.save_service.load_game(),
		"quest_state.unlocked_effects 中的区域解锁未同步到 world.unlocked_region_ids",
		"unlocked_effects region missing world region"
	)


func _check_rejects_region_unlock_effect_without_completed_quest_source() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.unlocked_effect_region_source")
	save_data["world"]["unlocked_region_ids"] = ["region.outpost_platform", "region.crystal_vein_field"]
	save_data["world"]["quest_state"]["unlocked_effects"].append("region.crystal_vein_field")
	host._write_save_json(save_data)
	host._expect_failure_message(
		host.save_service.load_game(),
		"quest_state.unlocked_effects 中的区域解锁缺少已完成任务 unlock_effects 来源",
		"unlocked_effects region without completed quest source"
	)


func _check_rejects_completed_quest_missing_recipe_unlock_effect() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.missing_recipe_unlock")
	host._mark_restore_outpost_completed(save_data)
	save_data["world"]["quest_state"]["unlocked_effects"].erase("recipe.process_crystal_ore")
	host._write_save_json(save_data)
	host._expect_failure_message(
		host.save_service.load_game(),
		"quest_state.unlocked_effects 缺少已完成任务声明的解锁效果",
		"completed quest missing recipe unlock"
	)


func _check_rejects_completed_quest_missing_slice_unlock_effect() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.missing_slice_unlock")
	_mark_slice_complete(save_data)
	save_data["world"]["quest_state"]["unlocked_effects"].erase("slice_01_complete")
	host._write_save_json(save_data)
	host._expect_failure_message(
		host.save_service.load_game(),
		"quest_state.unlocked_effects 缺少已完成任务声明的解锁效果",
		"completed quest missing slice unlock"
	)


func _check_rejects_quest_unlock_without_completed_quest_source() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.quest_unlock_source")
	host._mark_restore_outpost_completed(save_data)
	save_data["world"]["quest_state"]["unlocked_effects"].append("quest.make_filter_module")
	host._write_save_json(save_data)
	host._expect_failure_message(
		host.save_service.load_game(),
		"quest_state.unlocked_effects 中的非区域 / 配方解锁缺少已完成任务 unlock_effects 来源",
		"quest unlock without completed quest source"
	)


func _check_rejects_slice_unlock_without_completed_quest_source() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.slice_unlock_source")
	host._mark_restore_outpost_completed(save_data)
	save_data["world"]["quest_state"]["unlocked_effects"].append("slice_01_complete")
	host._write_save_json(save_data)
	host._expect_failure_message(
		host.save_service.load_game(),
		"quest_state.unlocked_effects 中的非区域 / 配方解锁缺少已完成任务 unlock_effects 来源",
		"slice unlock without completed quest source"
	)


func _mark_bring_back_sample_completed(save_data: Dictionary) -> void:
	save_data["world"]["unlocked_region_ids"] = ["region.outpost_platform", "region.crystal_vein_field"]
	save_data["world"]["quest_state"]["active_quest_ids"] = ["quest.analyze_anomaly_sample"]
	save_data["world"]["quest_state"]["completed_quest_ids"] = [
		"quest.restore_outpost",
		"quest.scout_crystal_field",
		"quest.calibrate_reactor",
		"quest.bring_back_sample"
	]
	save_data["world"]["quest_state"]["objective_progress"] = {
		"quest.restore_outpost|interact|building.outpost_core": 1,
		"quest.scout_crystal_field|visit_region|region.crystal_vein_field": 1,
		"quest.scout_crystal_field|gather_item|item.crystal_ore": 6,
		"quest.calibrate_reactor|gather_item|item.salvage_scrap": 4,
		"quest.calibrate_reactor|craft_item|item.reactor_calibrator": 1,
		"quest.bring_back_sample|sample_object|map_object.anomaly_crystal": 1
	}
	save_data["world"]["quest_state"]["unlocked_effects"] = [
		"region.outpost_platform",
		"region.crystal_vein_field",
		"recipe.process_crystal_ore",
		"recipe.repair_gel",
		"recipe.reactor_calibrator",
		"recipe.analyze_anomaly_sample"
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
	save_data["world"]["quest_state"]["objective_progress"] = {
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
	save_data["world"]["quest_state"]["unlocked_effects"] = [
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
		"slice_01_complete"
	]
