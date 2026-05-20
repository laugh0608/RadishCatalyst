extends RefCounted

var host


func _init(check_host) -> void:
	host = check_host


func run() -> void:
	_check_loads_valid_build_site_links()
	_check_rejects_invalid_instance_id()
	_check_loads_known_map_object_source()
	_check_rejects_unknown_map_object_source()
	_check_rejects_map_object_source_definition_mismatch()
	_check_rejects_built_definition_mismatch()
	_check_rejects_map_object_unknown_field()
	_check_loads_known_enemy_source()
	_check_rejects_unknown_enemy_source()
	_check_rejects_enemy_source_definition_mismatch()
	_check_rejects_enemy_source_region_mismatch()
	_check_rejects_enemy_unknown_field()


func _check_loads_valid_build_site_links() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.valid.build_site")
	save_data["world"]["map_objects"] = {
		"map_object_instance.foundation_site_north": {
			"definition_id": "building.foundation_t1",
			"region_id": "region.outpost_platform",
			"is_built": true,
			"built_definition_id": "building.foundation_t1"
		}
	}
	save_data["world"]["base_structures"]["structure.foundation_site_north"] = {
		"definition_id": "building.foundation_t1",
		"region_id": "region.outpost_platform",
		"status": "idle",
		"site_instance_id": "map_object_instance.foundation_site_north"
	}
	host._write_save_json(save_data)
	host._expect_success(host.save_service.load_game(), "valid build site links")


func _check_rejects_invalid_instance_id() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.instance_id")
	save_data["world"]["map_objects"] = {
		"bad_instance.crystal": {
			"definition_id": "map_object.crystal_cluster",
			"region_id": "region.outpost_platform"
		}
	}
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "无效实例 ID", "invalid map object instance id")


func _check_loads_known_map_object_source() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.valid.map_object_source")
	host._mark_restore_outpost_completed(save_data)
	save_data["world"]["map_objects"] = {
		"map_object_instance.crystal_cluster_reserve": {
			"definition_id": "map_object.crystal_cluster",
			"region_id": "region.crystal_vein_field",
			"is_gathered": true
		},
		"map_object_instance.crystal_cluster_east": {
			"definition_id": "map_object.crystal_cluster",
			"region_id": "region.crystal_vein_field",
			"is_gathered": true
		},
		"map_object_instance.rough_ground_north": {
			"definition_id": "map_object.rough_ground",
			"region_id": "region.crystal_vein_field",
			"is_cleared": true
		},
		"map_object_instance.frontline_supply_console": {
			"definition_id": "map_object.frontline_supply_console",
			"region_id": "region.outpost_platform",
			"is_sampled": true
		},
		"map_object_instance.supply_return_marker": {
			"definition_id": "map_object.supply_return_marker",
			"region_id": "region.phase_well_tether",
			"is_sampled": true
		},
		"map_object_instance.frontline_route_console": {
			"definition_id": "map_object.frontline_route_console",
			"region_id": "region.outpost_platform",
			"is_sampled": true
		},
		"map_object_instance.route_signal_marker": {
			"definition_id": "map_object.route_signal_marker",
			"region_id": "region.phase_well_tether",
			"is_sampled": true
		},
		"map_object_instance.base_supply_choice_console": {
			"definition_id": "map_object.base_supply_choice_console",
			"region_id": "region.outpost_platform",
			"is_sampled": true
		},
		"map_object_instance.base_survey_choice_console": {
			"definition_id": "map_object.base_survey_choice_console",
			"region_id": "region.outpost_platform",
			"is_sampled": true
		},
		"map_object_instance.base_pressure_choice_console": {
			"definition_id": "map_object.base_pressure_choice_console",
			"region_id": "region.outpost_platform",
			"is_sampled": true
		},
		"map_object_instance.steady_supply_drop_marker": {
			"definition_id": "map_object.steady_supply_drop_marker",
			"region_id": "region.phase_well_tether",
			"is_sampled": true
		},
		"map_object_instance.phase_survey_node_west": {
			"definition_id": "map_object.phase_survey_node_west",
			"region_id": "region.phase_well_tether",
			"is_sampled": true
		},
		"map_object_instance.phase_survey_node_east": {
			"definition_id": "map_object.phase_survey_node_east",
			"region_id": "region.phase_well_tether",
			"is_sampled": true
		},
		"map_object_instance.pressure_clearance_node": {
			"definition_id": "map_object.pressure_clearance_node",
			"region_id": "region.phase_well_tether",
			"is_cleared": true
		}
	}
	host._write_save_json(save_data)
	host._expect_success(host.save_service.load_game(), "known map object source")


func _check_rejects_unknown_map_object_source() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.unknown_map_object_source")
	save_data["world"]["map_objects"] = {
		"map_object_instance.debug_extra": {
			"definition_id": "map_object.crystal_cluster",
			"region_id": "region.outpost_platform"
		}
	}
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "没有匹配的原型地图对象来源", "unknown map object source")


func _check_rejects_map_object_source_definition_mismatch() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.map_object_source_mismatch")
	save_data["world"]["map_objects"] = {
		"map_object_instance.ruin_gate": {
			"definition_id": "map_object.crystal_cluster",
			"region_id": "region.locked_ruin_gate"
		}
	}
	save_data["world"]["unlocked_region_ids"] = ["region.outpost_platform", "region.locked_ruin_gate"]
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "原型地图对象定义不一致", "map object source definition mismatch")


func _check_rejects_built_definition_mismatch() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.built_definition_mismatch")
	save_data["world"]["map_objects"] = {
		"map_object_instance.foundation_site_north": {
			"definition_id": "building.foundation_t1",
			"region_id": "region.outpost_platform",
			"is_built": true,
			"built_definition_id": "building.pollution_filter"
		}
	}
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "建成定义与原型地图对象定义不一致", "built definition mismatch")


func _check_rejects_map_object_unknown_field() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.map_object_unknown_field")
	save_data["world"]["map_objects"] = {
		"map_object_instance.crystal_cluster": {
			"definition_id": "map_object.crystal_cluster",
			"region_id": "region.crystal_vein_field",
			"is_gathered": false,
			"debug_spawn_note": "should not be saved"
		}
	}
	save_data["world"]["unlocked_region_ids"] = ["region.outpost_platform", "region.crystal_vein_field"]
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "包含不允许的字段", "map object unknown field")


func _check_loads_known_enemy_source() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.valid.enemy_source")
	host._mark_restore_outpost_completed(save_data)
	save_data["world"]["enemies"] = {
		"enemy_instance.native_skitter": {
			"definition_id": "enemy.native_skitter",
			"region_id": "region.crystal_vein_field",
			"health": 20,
			"max_health": 20,
			"is_defeated": false
		}
	}
	host._write_save_json(save_data)
	host._expect_success(host.save_service.load_game(), "known enemy source")


func _check_rejects_unknown_enemy_source() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.unknown_enemy_source")
	save_data["world"]["enemies"] = {
		"enemy_instance.debug_extra": {
			"definition_id": "enemy.native_skitter",
			"region_id": "region.crystal_vein_field",
			"health": 20,
			"max_health": 20
		}
	}
	save_data["world"]["unlocked_region_ids"] = ["region.outpost_platform", "region.crystal_vein_field"]
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "没有匹配的原型敌人来源", "unknown enemy source")


func _check_rejects_enemy_source_definition_mismatch() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.enemy_source_definition")
	save_data["world"]["enemies"] = {
		"enemy_instance.native_skitter": {
			"definition_id": "enemy.polluted_skitter",
			"region_id": "region.crystal_vein_field",
			"health": 20,
			"max_health": 20
		}
	}
	save_data["world"]["unlocked_region_ids"] = ["region.outpost_platform", "region.crystal_vein_field"]
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "原型敌人定义不一致", "enemy source definition mismatch")


func _check_rejects_enemy_source_region_mismatch() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.enemy_source_region")
	save_data["world"]["enemies"] = {
		"enemy_instance.polluted_skitter": {
			"definition_id": "enemy.polluted_skitter",
			"region_id": "region.crystal_vein_field",
			"health": 30,
			"max_health": 30
		}
	}
	save_data["world"]["unlocked_region_ids"] = ["region.outpost_platform", "region.crystal_vein_field"]
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "原型敌人区域不一致", "enemy source region mismatch")


func _check_rejects_enemy_unknown_field() -> void:
	host._remove_save_file()
	host._remove_backup_files()
	var save_data: Dictionary = host._make_save_data("world.invalid.enemy_unknown_field")
	save_data["world"]["enemies"] = {
		"enemy_instance.native_skitter": {
			"definition_id": "enemy.native_skitter",
			"region_id": "region.crystal_vein_field",
			"health": 20,
			"max_health": 20,
			"aggro_target_id": "character.player"
		}
	}
	save_data["world"]["unlocked_region_ids"] = ["region.outpost_platform", "region.crystal_vein_field"]
	host._write_save_json(save_data)
	host._expect_failure_message(host.save_service.load_game(), "包含不允许的字段", "enemy unknown field")
