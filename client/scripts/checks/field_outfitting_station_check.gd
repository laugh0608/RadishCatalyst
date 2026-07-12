extends RefCounted

const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")

var host


func _init(check_host) -> void:
	host = check_host


func run(root: Node) -> void:
	_check_slurry_buffer_tank(root)
	var build_system := BuildSystem.new(host.data_registry)
	var outfitting_world := WorldState.create_default()
	host._complete_first_minute(outfitting_world)
	var outfitting_character := CharacterState.create_default()
	outfitting_character.inventory.items["item.basic_parts"] = 2
	outfitting_character.inventory.items["item.salvage_scrap"] = 1
	var build_result := build_system.build_structure(
		"map_object_instance.field_outfitting_station_build_site",
		"building.field_outfitting_station",
		outfitting_character,
		outfitting_world
	)
	host._expect_equal(bool(build_result.get("success", false)), true, "field outfitting station build succeeds")
	host._expect_equal(
		outfitting_world.has_base_structure_definition("building.field_outfitting_station"),
		true,
		"field outfitting station writes base structure"
	)
	host._expect_equal(
		int(outfitting_character.inventory.items.get("item.basic_parts", 0)),
		0,
		"field outfitting station consumes basic parts"
	)
	host._expect_equal(
		int(outfitting_character.inventory.items.get("item.salvage_scrap", 0)),
		0,
		"field outfitting station consumes salvage scrap"
	)

	var gather_system := GatherSystem.new(host.data_registry)
	var prompt_formatter := InteractionPromptFormatter.new(
		host.data_registry,
		ProcessingSystem.new(host.data_registry),
		build_system
	)
	var missing_module := gather_system.interact_with_object(
		"map_object_instance.field_outfitting_station",
		"building.field_outfitting_station",
		"inspect",
		outfitting_character,
		outfitting_world
	)
	host._expect_failure_feedback(missing_module, "整备材料不足", "field outfitting station missing module feedback")
	outfitting_character.inventory.add_equipment("equipment.filter_module_t1", 1)
	var equip_result := gather_system.interact_with_object(
		"map_object_instance.field_outfitting_station",
		"building.field_outfitting_station",
		"inspect",
		outfitting_character,
		outfitting_world
	)
	host._expect_equal(bool(equip_result.get("success", false)), true, "field outfitting station equips module")
	host._expect_equal(
		bool(equip_result.get("outfitting_module_enabled", false)),
		true,
		"field outfitting station returns progression marker"
	)
	host._expect_equal(
		String(outfitting_character.equipment.get("suit_module", "")),
		"equipment.filter_module_t1",
		"field outfitting station writes suit module"
	)
	host._expect_equal(
		int(outfitting_character.inventory.equipment.get("equipment.filter_module_t1", 0)),
		0,
		"field outfitting station consumes inventory module"
	)
	var missing_calibration_prompt := prompt_formatter.format_outfitting_station_prompt(
		outfitting_character,
		outfitting_world
	)
	host._expect_text_contains(
		missing_calibration_prompt,
		"回晶体侧路补晶体矿和残骸废件",
		"field outfitting station prompt points missing calibration material to crystal side route"
	)
	var missing_calibration := gather_system.interact_with_object(
		"map_object_instance.field_outfitting_station",
		"building.field_outfitting_station",
		"inspect",
		outfitting_character,
		outfitting_world
	)
	host._expect_failure_feedback(missing_calibration, "维护材料不足", "field outfitting station missing calibration feedback")
	host._expect_text_contains(
		String(missing_calibration.get("message", "")),
		"晶体侧路",
		"field outfitting station missing calibration points to side route"
	)
	outfitting_character.inventory.add_ref("item.crystal_ore", FieldOutfittingRuntime.MODULE_CALIBRATION_CRYSTAL_COST)
	outfitting_character.inventory.add_ref("item.salvage_scrap", FieldOutfittingRuntime.MODULE_CALIBRATION_SCRAP_COST)
	var ready_calibration_prompt := prompt_formatter.format_outfitting_station_prompt(
		outfitting_character,
		outfitting_world
	)
	host._expect_text_contains(
		ready_calibration_prompt,
		"E 校准基础过滤模块",
		"field outfitting station prompt exposes calibration action"
	)
	var calibration_result := gather_system.interact_with_object(
		"map_object_instance.field_outfitting_station",
		"building.field_outfitting_station",
		"inspect",
		outfitting_character,
		outfitting_world
	)
	host._expect_equal(bool(calibration_result.get("success", false)), true, "field outfitting station calibration succeeds")
	host._expect_equal(
		bool(calibration_result.get("outfitting_module_calibrated", false)),
		true,
		"field outfitting station returns calibration marker"
	)
	host._expect_equal(
		bool(outfitting_world.get_map_object("map_object_instance.field_outfitting_station").get("module_calibrated", false)),
		true,
		"field outfitting station stores calibration state"
	)
	host._expect_equal(
		int(outfitting_character.inventory.items.get("item.crystal_ore", 0)),
		0,
		"field outfitting station calibration consumes crystal ore"
	)
	host._expect_equal(
		int(outfitting_character.inventory.items.get("item.salvage_scrap", 0)),
		0,
		"field outfitting station calibration consumes salvage scrap"
	)
	var repeat_result := gather_system.interact_with_object(
		"map_object_instance.field_outfitting_station",
		"building.field_outfitting_station",
		"inspect",
		outfitting_character,
		outfitting_world
	)
	host._expect_text_contains(
		String(repeat_result.get("message", "")),
		"已完成晶体校准",
		"field outfitting station repeat check keeps calibrated status"
	)

	var status_text := HudStatusPresenter.new().format_vitals_text(
		host.data_registry,
		outfitting_world,
		outfitting_character
	)
	host._expect_text_contains(status_text, "出发准备：模块已校准", "field outfitting station HUD summary")
	host._expect_text_contains(status_text, "收益：模块校准让污染采集和污染战斗承压继续下降", "field outfitting station HUD payoff")
	outfitting_world.add_base_structure(
		"structure.basic_storage_build_site",
		"building.basic_storage",
		"region.outpost_platform",
		"map_object_instance.basic_storage_build_site"
	)
	outfitting_world.add_base_structure(
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.outpost_platform",
		"map_object_instance.pollution_filter_build_site"
	)
	outfitting_world.quest_state.set_objective_progress("quest.enter_pollution_edge", "craft_item", "item.resistance_vial_t1", 1.0)
	outfitting_character.inventory.consume_ref("item.repair_gel", 1)
	var supply_status_text := HudStatusPresenter.new().format_vitals_text(
		host.data_registry,
		outfitting_world,
		outfitting_character
	)
	host._expect_text_contains(supply_status_text, "出发准备：模块已校准", "field outfitting station keeps module status with supplies")
	host._expect_text_contains(
		supply_status_text,
		"回前哨核心补修复凝胶 / 抗污染药剂",
		"field outfitting station HUD summary includes departure supply restock"
	)
	host._expect_text_contains(
		supply_status_text,
		"收益：模块校准让污染采集和污染战斗承压继续下降",
		"field outfitting station HUD summary explains pressure payoff"
	)
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	map.apply_runtime_state(outfitting_world, outfitting_character)
	var station := map.get_node("Interactables/FieldOutfittingStation") as PrototypeInteractable
	host._expect_equal(station.visible, true, "built field outfitting station is visible")
	host._expect_equal(station.monitoring, true, "built field outfitting station stays interactable")
	host._expect_text_contains(station.label.text, "已校准", "built field outfitting station visual label")
	map.free()
	_check_outfitting_calibration_pressure_payoff(gather_system)
	_check_core_archive_maintenance_payoff(root, gather_system, prompt_formatter)
	_check_logistics_route_sign(root, gather_system, prompt_formatter)
	_check_core_retest_readout_scene(root, prompt_formatter)
	_check_tactical_scan_tool_action(gather_system)


func _check_tactical_scan_tool_action(gather_system: GatherSystem) -> void:
	var runtime := CharacterKitRuntime.new(host.data_registry)
	var locked_result := runtime.no_target_result(CharacterState.create_default(), WorldState.create_default())
	host._expect_equal(bool(locked_result.get("success", true)), false, "tactical scan waits for outfitting station")
	host._expect_text_contains(
		String(locked_result.get("message", "")),
		"出发整备台尚未上线",
		"tactical scan locked feedback names outfitting station"
	)

	var baseline_enemy := _create_tactical_scan_enemy()
	var baseline_world := _create_tactical_scan_world()
	var baseline_character := _create_tactical_scan_character()
	var counter_runtime := EnemyCounterattackRuntime.new(host.data_registry)
	var baseline_health := baseline_character.health
	counter_runtime.apply(baseline_enemy, baseline_character, baseline_world, "region.crystal_vein_field")
	var baseline_loss := baseline_health - baseline_character.health
	baseline_enemy.free()

	var scanned_enemy := _create_tactical_scan_enemy()
	var scanned_world := _create_tactical_scan_world()
	var scanned_character := _create_tactical_scan_character()
	var scan_result := runtime.scan_enemy(
		scanned_enemy,
		scanned_character,
		scanned_world,
		"region.crystal_vein_field"
	)
	host._expect_equal(bool(scan_result.get("success", false)), true, "tactical scan marks enemy")
	host._expect_equal(
		bool(scanned_world.get_enemy("enemy_instance.treatment_skitter").get("tactical_scan_marked", false)),
		true,
		"tactical scan stores enemy marker"
	)
	host._expect_text_contains(scanned_enemy.label.text, "扫描锁定", "tactical scan enemy label shows lock")
	var scanned_health := scanned_character.health
	var counter_message := counter_runtime.apply(scanned_enemy, scanned_character, scanned_world, "region.crystal_vein_field")
	var scanned_loss := scanned_health - scanned_character.health
	host._expect_equal(scanned_loss < baseline_loss, true, "tactical scan reduces enemy counter damage")
	host._expect_text_contains(counter_message, "战术扫描已消耗", "tactical scan counter feedback")
	host._expect_equal(
		bool(scanned_world.get_enemy("enemy_instance.treatment_skitter").get("tactical_scan_marked", true)),
		false,
		"tactical scan enemy marker is consumed"
	)
	host._expect_equal(
		bool(scanned_world.get_enemy("enemy_instance.treatment_skitter").get("tactical_scan_consumed", false)),
		true,
		"tactical scan enemy consumed flag persists"
	)
	scanned_enemy.free()

	var baseline_gather_world := _create_tactical_scan_world()
	var baseline_gather_character := _create_tactical_scan_character()
	var baseline_protection := baseline_gather_character.protection
	var baseline_gather := gather_system.interact_with_object(
		"map_object_instance.tactical_scan_baseline_residue",
		"map_object.pollution_residue_patch",
		"gather",
		baseline_gather_character,
		baseline_gather_world
	)
	host._expect_equal(bool(baseline_gather.get("success", false)), true, "baseline tactical scan gather succeeds")
	var baseline_drain := baseline_protection - baseline_gather_character.protection

	var scanned_gather_world := _create_tactical_scan_world()
	var scanned_gather_character := _create_tactical_scan_character()
	var residue := PrototypeInteractable.new()
	residue.definition_id = "map_object.pollution_residue_patch"
	residue.instance_id = "map_object_instance.pollution_residue"
	residue.interaction_type = "gather"
	var scan_gather_result := runtime.scan_interactable(residue, scanned_gather_character, scanned_gather_world)
	residue.free()
	host._expect_equal(bool(scan_gather_result.get("success", false)), true, "tactical scan marks pollution gather")
	var scanned_protection := scanned_gather_character.protection
	var scanned_gather := gather_system.interact_with_object(
		"map_object_instance.pollution_residue",
		"map_object.pollution_residue_patch",
		"gather",
		scanned_gather_character,
		scanned_gather_world
	)
	var scanned_drain := scanned_protection - scanned_gather_character.protection
	host._expect_equal(bool(scanned_gather.get("success", false)), true, "scanned tactical gather succeeds")
	host._expect_equal(scanned_drain < baseline_drain, true, "tactical scan reduces gather pressure")
	host._expect_text_contains(
		String(scanned_gather.get("message", "")),
		"战术扫描已消耗",
		"tactical scan gather feedback"
	)
	host._expect_equal(
		bool(scanned_gather_world.get_map_object("map_object_instance.pollution_residue").get("tactical_scan_consumed", false)),
		true,
		"tactical scan map marker consumed flag persists"
	)

	var hud_status := HudStatusPresenter.new().format_vitals_text(
		host.data_registry,
		scanned_gather_world,
		scanned_gather_character
	)
	host._expect_text_contains(hud_status, "工具动作：C 战术扫描可用", "HUD exposes tactical scan tool action")
	var save_error := SaveContentValidator.new(host.data_registry).validate_save_content({
		"world": scanned_gather_world.to_dict(),
		"character": scanned_gather_character.to_dict()
	})
	host._expect_equal(save_error, "", "tactical scan runtime state passes save validation")


func _create_tactical_scan_world() -> WorldState:
	var world := WorldState.create_default()
	var site := world.ensure_map_object(
		"map_object_instance.field_outfitting_station_build_site",
		"building.field_outfitting_station",
		"region.outpost_platform"
	)
	site["is_built"] = true
	site["built_definition_id"] = "building.field_outfitting_station"
	world.add_base_structure(
		"structure.field_outfitting_station_build_site",
		"building.field_outfitting_station",
		"region.outpost_platform",
		"map_object_instance.field_outfitting_station_build_site"
	)
	return world


func _create_tactical_scan_character() -> CharacterState:
	var character := CharacterState.create_default()
	character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	return character


func _create_tactical_scan_enemy() -> PrototypeEnemy:
	var enemy := PrototypeEnemy.new()
	enemy.definition_id = "enemy.treatment_skitter"
	enemy.instance_id = "enemy_instance.treatment_skitter"
	enemy.display_name = "处理点扰动体"
	enemy.max_health = 35.0
	enemy.label = Label.new()
	enemy.add_child(enemy.label)
	return enemy


func _check_outfitting_calibration_pressure_payoff(gather_system: GatherSystem) -> void:
	var uncalibrated_world := WorldState.create_default()
	uncalibrated_world.add_base_structure(
		"structure.field_outfitting_station_build_site",
		"building.field_outfitting_station",
		"region.outpost_platform",
		"map_object_instance.field_outfitting_station_build_site"
	)
	var uncalibrated_character := CharacterState.create_default()
	uncalibrated_character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	var uncalibrated_before := uncalibrated_character.protection
	var uncalibrated_result := gather_system.interact_with_object(
		"map_object_instance.outfitting_pressure_uncalibrated",
		"map_object.pollution_residue_patch",
		"gather",
		uncalibrated_character,
		uncalibrated_world
	)
	host._expect_equal(bool(uncalibrated_result.get("success", false)), true, "uncalibrated module pollution gather succeeds")
	var uncalibrated_loss := uncalibrated_before - uncalibrated_character.protection

	var calibrated_world := WorldState.create_default()
	calibrated_world.add_base_structure(
		"structure.field_outfitting_station_build_site",
		"building.field_outfitting_station",
		"region.outpost_platform",
		"map_object_instance.field_outfitting_station_build_site"
	)
	FieldOutfittingRuntime.mark_module_calibrated(calibrated_world)
	var calibrated_character := CharacterState.create_default()
	calibrated_character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	var calibrated_before := calibrated_character.protection
	var calibrated_result := gather_system.interact_with_object(
		"map_object_instance.outfitting_pressure_calibrated",
		"map_object.pollution_residue_patch",
		"gather",
		calibrated_character,
		calibrated_world
	)
	host._expect_equal(bool(calibrated_result.get("success", false)), true, "calibrated module pollution gather succeeds")
	var calibrated_loss := calibrated_before - calibrated_character.protection
	host._expect_equal(
		calibrated_loss < uncalibrated_loss,
		true,
		"field outfitting station calibration lowers pollution gather pressure"
	)
	host._expect_text_contains(
		String(calibrated_result.get("message", "")),
		"过滤模块校准已降低消耗",
		"pollution gather feedback reads outfitting calibration"
	)
	_check_outfitting_calibration_counterattack_payoff()


func _check_outfitting_calibration_counterattack_payoff() -> void:
	var counter_runtime := EnemyCounterattackRuntime.new(host.data_registry)
	var uncalibrated_enemy := PrototypeEnemy.new()
	uncalibrated_enemy.definition_id = "enemy.polluted_skitter"
	uncalibrated_enemy.instance_id = "enemy_instance.outfitting_counter_uncalibrated"
	uncalibrated_enemy.display_name = "污染跃蛛"
	var uncalibrated_world := WorldState.create_default()
	uncalibrated_world.add_base_structure(
		"structure.field_outfitting_station_build_site",
		"building.field_outfitting_station",
		"region.outpost_platform",
		"map_object_instance.field_outfitting_station_build_site"
	)
	var uncalibrated_character := CharacterState.create_default()
	uncalibrated_character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	var uncalibrated_health_before := uncalibrated_character.health
	var uncalibrated_protection_before := uncalibrated_character.protection
	counter_runtime.apply(uncalibrated_enemy, uncalibrated_character, uncalibrated_world, "region.pollution_edge")
	var uncalibrated_health_loss := uncalibrated_health_before - uncalibrated_character.health
	var uncalibrated_protection_loss := uncalibrated_protection_before - uncalibrated_character.protection

	var calibrated_enemy := PrototypeEnemy.new()
	calibrated_enemy.definition_id = "enemy.polluted_skitter"
	calibrated_enemy.instance_id = "enemy_instance.outfitting_counter_calibrated"
	calibrated_enemy.display_name = "污染跃蛛"
	var calibrated_world := WorldState.create_default()
	calibrated_world.add_base_structure(
		"structure.field_outfitting_station_build_site",
		"building.field_outfitting_station",
		"region.outpost_platform",
		"map_object_instance.field_outfitting_station_build_site"
	)
	FieldOutfittingRuntime.mark_module_calibrated(calibrated_world)
	var calibrated_character := CharacterState.create_default()
	calibrated_character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	var calibrated_health_before := calibrated_character.health
	var calibrated_protection_before := calibrated_character.protection
	var calibrated_message := counter_runtime.apply(
		calibrated_enemy,
		calibrated_character,
		calibrated_world,
		"region.pollution_edge"
	)
	var calibrated_health_loss := calibrated_health_before - calibrated_character.health
	var calibrated_protection_loss := calibrated_protection_before - calibrated_character.protection
	host._expect_equal(
		calibrated_health_loss < uncalibrated_health_loss,
		true,
		"field outfitting station calibration lowers pollution counter health pressure"
	)
	host._expect_equal(
		calibrated_protection_loss < uncalibrated_protection_loss,
		true,
		"field outfitting station calibration lowers pollution counter protection pressure"
	)
	host._expect_text_contains(
		calibrated_message,
		"出发整备台校准已接入",
		"pollution counter feedback reads outfitting calibration"
	)
	uncalibrated_enemy.free()
	calibrated_enemy.free()


func _check_core_archive_maintenance_payoff(
	root: Node,
	gather_system: GatherSystem,
	prompt_formatter: InteractionPromptFormatter
) -> void:
	var world := WorldState.create_default()
	host._complete_first_minute(world)
	world.quest_state.complete_quest("quest.write_demo_stabilization_core")
	world.add_base_structure(
		"structure.field_outfitting_station_build_site",
		"building.field_outfitting_station",
		"region.outpost_platform",
		"map_object_instance.field_outfitting_station_build_site"
	)
	var character := CharacterState.create_default()
	character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	var prompt := prompt_formatter.format_outfitting_station_prompt(character, world)
	host._expect_text_contains(
		prompt,
		"E 接入核心归档维护",
		"core archive maintenance prompt exposes outfitting action"
	)
	var maintenance_result := gather_system.interact_with_object(
		"map_object_instance.field_outfitting_station",
		"building.field_outfitting_station",
		"inspect",
		character,
		world
	)
	host._expect_equal(bool(maintenance_result.get("success", false)), true, "core archive maintenance succeeds")
	host._expect_equal(
		bool(maintenance_result.get("core_archive_maintained", false)),
		true,
		"core archive maintenance returns progression marker"
	)
	host._expect_equal(
		FieldOutfittingRuntime.is_core_archive_maintained(world),
		true,
		"core archive maintenance writes outfitting station state"
	)
	host._expect_text_contains(
		String(maintenance_result.get("message", "")),
		"核心稳定数据已接入基础过滤模块",
		"core archive maintenance feedback explains module connection"
	)
	var hud_text := HudStatusPresenter.new().format_vitals_text(host.data_registry, world, character)
	host._expect_text_contains(hud_text, "出发准备：模块归档维护", "core archive maintenance HUD module state")
	host._expect_text_contains(hud_text, "核心归档维护已接入", "core archive maintenance HUD payoff")

	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	map.apply_runtime_state(world, character)
	var station := map.get_node("Interactables/FieldOutfittingStation") as PrototypeInteractable
	host._expect_text_contains(station.label.text, "归档维护", "core archive maintenance scene label")
	map.free()

	_check_core_archive_maintenance_gather_payoff(gather_system)
	_check_core_archive_maintenance_counterattack_payoff()


func _check_logistics_route_sign(
	root: Node,
	gather_system: GatherSystem,
	prompt_formatter: InteractionPromptFormatter
) -> void:
	var world := WorldState.create_default()
	host._complete_first_minute(world)
	world.current_region_id = "region.outpost_platform"
	world.quest_state.complete_quest("quest.restore_outpost")
	world.quest_state.complete_quest("quest.write_demo_stabilization_core")
	world.add_base_structure(
		"structure.basic_storage_build_site",
		"building.basic_storage",
		"region.outpost_platform",
		"map_object_instance.basic_storage_build_site"
	)
	world.add_base_structure(
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.outpost_platform",
		"map_object_instance.pollution_filter_build_site"
	)
	world.add_base_structure(
		"structure.field_outfitting_station_build_site",
		"building.field_outfitting_station",
		"region.outpost_platform",
		"map_object_instance.field_outfitting_station_build_site"
	)
	world.add_base_structure(
		"structure.slurry_buffer_tank_build_site",
		"building.slurry_buffer_tank",
		"region.outpost_platform",
		"map_object_instance.slurry_buffer_tank_build_site"
	)
	world.set_base_structure_status("structure.pollution_filter_build_site", "completed", "recipe.cleanse_residue")
	FieldOutfittingRuntime.mark_module_calibrated(world)
	FieldOutfittingRuntime.mark_core_archive_maintained(world)
	world.ensure_map_object(
		"map_object_instance.pollution_residue_core_archive_route_cache",
		"map_object.pollution_residue_patch",
		"region.pollution_edge"
	)
	world.ensure_map_object(
		"map_object_instance.pollution_residue_core_archive_return_cache",
		"map_object.pollution_residue_patch",
		"region.pollution_edge"
	)
	world.set_map_object_flag("map_object_instance.pollution_residue_core_archive_route_cache", "is_gathered", true)
	world.set_map_object_flag("map_object_instance.pollution_residue_core_archive_return_cache", "is_gathered", true)

	var character := CharacterState.create_default()
	character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	character.inventory.items["item.repair_gel"] = 1
	character.inventory.items["item.resistance_vial_t1"] = 2

	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	map.apply_runtime_state(world, character)
	var route_sign := map.get_node("Interactables/OutpostLogisticsRouteSign") as PrototypeInteractable
	var route_pad := map.get_node("OpeningSceneLayer/BaseLogisticsRouteSignPad") as ColorRect
	var route_marker := map.get_node("OpeningSceneLayer/BaseLogisticsRouteSignMarker") as ColorRect
	var route_flow := map.get_node("OpeningSceneLayer/BaseLogisticsRouteFlowLine") as ColorRect
	var storage_marker := map.get_node("OpeningSceneLayer/BaseStorageObjectMarker") as ColorRect
	var exit_lane := map.get_node("OpeningSceneLayer/BaseExitLane") as ColorRect
	host._expect_equal(
		route_sign.definition_id == "map_object.outpost_logistics_route_sign"
			and route_sign.single_use == false
			and _is_rect_covering_position(route_pad, route_sign.position)
			and _is_rect_covering_position(route_marker, route_sign.position),
		true,
		"logistics route sign is a repeatable base route interactable"
	)
	host._expect_equal(
		route_flow.offset_left >= storage_marker.offset_left
			and route_flow.offset_right <= exit_lane.offset_left,
		true,
		"logistics route sign flow line connects storage lane to departure lane"
	)
	var prompt := prompt_formatter.format_general_interaction_prompt(route_sign, character, world)
	host._expect_text_contains(prompt, "对象：后勤路线牌", "logistics route sign prompt names object")
	host._expect_text_contains(prompt, "前哨核心：已恢复", "logistics route sign prompt reads outpost core")
	host._expect_text_contains(prompt, "储存箱：已接入补给", "logistics route sign prompt reads storage")
	host._expect_text_contains(prompt, "浆液缓冲罐：双药剂补给", "logistics route sign prompt reads slurry buffer")
	host._expect_text_contains(prompt, "出发整备台：", "logistics route sign prompt reads outfitting station")
	host._expect_text_contains(prompt, "外勤出发口：", "logistics route sign prompt reads departure gate")
	host._expect_text_contains(prompt, "操作：按 E 检查后勤路线", "logistics route sign prompt exposes inspect action")

	var result := gather_system.interact_with_object(
		"map_object_instance.outpost_logistics_route_sign",
		"map_object.outpost_logistics_route_sign",
		"inspect",
		character,
		world
	)
	host._expect_equal(bool(result.get("success", false)), true, "logistics route sign inspect succeeds")
	host._expect_text_contains(String(result.get("message", "")), "后勤路线牌检查", "logistics route sign feedback names check")
	host._expect_text_contains(String(result.get("message", "")), "储存箱：已接入补给", "logistics route sign feedback includes storage state")
	host._expect_text_contains(String(result.get("message", "")), "浆液缓冲罐：双药剂补给", "logistics route sign feedback includes slurry buffer state")
	host._expect_equal(
		bool(world.get_map_object("map_object_instance.outpost_logistics_route_sign").get("is_sampled", false)),
		false,
		"logistics route sign remains repeatable after inspect"
	)
	map.free()


func _check_core_retest_readout_scene(root: Node, prompt_formatter: InteractionPromptFormatter) -> void:
	var character := CharacterState.create_default()
	character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	character.inventory.items["item.repair_gel"] = 1
	character.inventory.items["item.resistance_vial_t1"] = 2

	var blocked_world := _create_core_retest_readout_scene_world(false)
	var blocked_map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(blocked_map)
	blocked_map.setup(host.data_registry)
	blocked_map.apply_runtime_state(blocked_world, character)
	var blocked_readout := blocked_map.get_node("Interactables/DemoStabilizationRetestReadoutCache") as PrototypeInteractable
	host._expect_equal(
		blocked_readout.visible == false and blocked_readout.monitoring == false,
		true,
		"core retest readout cache stays hidden before pollution pressure retest is processed"
	)
	blocked_map.free()

	var ready_world := _create_core_retest_readout_scene_world(true)
	var ready_map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(ready_map)
	ready_map.setup(host.data_registry)
	ready_map.apply_runtime_state(ready_world, character)
	var readout := ready_map.get_node("Interactables/DemoStabilizationRetestReadoutCache") as PrototypeInteractable
	var pocket := ready_map.get_node("OpeningSceneLayer/CoreStabilizationRetestPocket") as ColorRect
	var marker := ready_map.get_node("OpeningSceneLayer/CoreStabilizationRetestReadoutMarker") as ColorRect
	var line := ready_map.get_node("OpeningSceneLayer/CoreStabilizationRetestLine") as ColorRect
	host._expect_equal(
		readout.definition_id == CoreStabilizationPressureFormatter.RETEST_READOUT_DEFINITION_ID
			and readout.visible
			and readout.monitoring
			and _is_rect_covering_position(pocket, readout.position)
			and _is_rect_covering_position(marker, readout.position)
			and line.offset_left >= 4050.0
			and line.offset_right <= readout.position.x + 8.0,
		true,
		"core retest readout cache appears as a gated core station target"
	)
	var prompt := prompt_formatter.format_general_interaction_prompt(readout, character, ready_world)
	host._expect_text_contains(prompt, "核心复测读数缓存", "core retest scene prompt names readout cache")
	host._expect_text_contains(prompt, "基础零件 x1，修复凝胶 x1", "core retest scene prompt shows drops")
	host._expect_text_contains(prompt, "回收后带基础零件和修复凝胶回前哨核心", "core retest scene prompt points back to base")
	ready_map.free()


func _check_core_archive_maintenance_gather_payoff(gather_system: GatherSystem) -> void:
	var plain_world := _create_core_archive_maintenance_world(false)
	var plain_character := CharacterState.create_default()
	plain_character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	var plain_before := plain_character.protection
	var plain_result := gather_system.interact_with_object(
		"map_object_instance.core_archive_pressure_plain",
		"map_object.pollution_residue_patch",
		"gather",
		plain_character,
		plain_world
	)
	host._expect_equal(bool(plain_result.get("success", false)), true, "plain core archive gather succeeds")
	var plain_loss := plain_before - plain_character.protection

	var maintained_world := _create_core_archive_maintenance_world(true)
	var maintained_character := CharacterState.create_default()
	maintained_character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	var maintained_before := maintained_character.protection
	var maintained_result := gather_system.interact_with_object(
		"map_object_instance.core_archive_pressure_maintained",
		"map_object.pollution_residue_patch",
		"gather",
		maintained_character,
		maintained_world
	)
	host._expect_equal(bool(maintained_result.get("success", false)), true, "maintained core archive gather succeeds")
	var maintained_loss := maintained_before - maintained_character.protection
	host._expect_equal(
		maintained_loss < plain_loss,
		true,
		"core archive maintenance lowers pollution gather pressure"
	)
	host._expect_text_contains(
		String(maintained_result.get("message", "")),
		"核心归档维护已降低消耗",
		"pollution gather feedback reads core archive maintenance"
	)


func _check_core_archive_maintenance_counterattack_payoff() -> void:
	var counter_runtime := EnemyCounterattackRuntime.new(host.data_registry)
	var plain_enemy := PrototypeEnemy.new()
	plain_enemy.definition_id = "enemy.polluted_skitter"
	plain_enemy.instance_id = "enemy_instance.core_archive_counter_plain"
	plain_enemy.display_name = "污染跃蛛"
	var plain_world := _create_core_archive_maintenance_world(false)
	var plain_character := CharacterState.create_default()
	plain_character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	var plain_health_before := plain_character.health
	var plain_protection_before := plain_character.protection
	counter_runtime.apply(plain_enemy, plain_character, plain_world, "region.pollution_edge")
	var plain_health_loss := plain_health_before - plain_character.health
	var plain_protection_loss := plain_protection_before - plain_character.protection

	var maintained_enemy := PrototypeEnemy.new()
	maintained_enemy.definition_id = "enemy.polluted_skitter"
	maintained_enemy.instance_id = "enemy_instance.core_archive_counter_maintained"
	maintained_enemy.display_name = "污染跃蛛"
	var maintained_world := _create_core_archive_maintenance_world(true)
	var maintained_character := CharacterState.create_default()
	maintained_character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	var maintained_health_before := maintained_character.health
	var maintained_protection_before := maintained_character.protection
	var maintained_message := counter_runtime.apply(
		maintained_enemy,
		maintained_character,
		maintained_world,
		"region.pollution_edge"
	)
	var maintained_health_loss := maintained_health_before - maintained_character.health
	var maintained_protection_loss := maintained_protection_before - maintained_character.protection
	host._expect_equal(
		maintained_health_loss < plain_health_loss,
		true,
		"core archive maintenance lowers pollution counter health pressure"
	)
	host._expect_equal(
		maintained_protection_loss < plain_protection_loss,
		true,
		"core archive maintenance lowers pollution counter protection pressure"
	)
	host._expect_text_contains(
		maintained_message,
		"核心归档维护已接入",
		"pollution counter feedback reads core archive maintenance"
	)
	plain_enemy.free()
	maintained_enemy.free()


func _create_core_archive_maintenance_world(maintained: bool) -> WorldState:
	var world := WorldState.create_default()
	host._complete_first_minute(world)
	world.quest_state.complete_quest("quest.write_demo_stabilization_core")
	world.add_base_structure(
		"structure.field_outfitting_station_build_site",
		"building.field_outfitting_station",
		"region.outpost_platform",
		"map_object_instance.field_outfitting_station_build_site"
	)
	if maintained:
		FieldOutfittingRuntime.mark_core_archive_maintained(world)
	return world


func _create_core_retest_readout_scene_world(ready: bool) -> WorldState:
	var world := _create_core_archive_maintenance_world(true)
	world.current_region_id = "region.demo_stabilization_core"
	world.quest_state.complete_quest("quest.restore_outpost")
	world.quest_state.complete_quest("quest.enter_pollution_edge")
	world.add_base_structure(
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.outpost_platform",
		"map_object_instance.pollution_filter_build_site"
	)
	if not ready:
		return world
	world.set_base_structure_status(
		"structure.pollution_filter_build_site",
		"completed",
		"recipe.cleanse_residue"
	)
	world.ensure_map_object(
		"map_object_instance.pollution_residue_core_archive_pressure_retest_cache",
		"map_object.pollution_residue_patch",
		"region.pollution_edge"
	)
	world.set_map_object_flag(
		"map_object_instance.pollution_residue_core_archive_pressure_retest_cache",
		"is_gathered",
		true
	)
	return world


func _is_rect_covering_position(rect: ColorRect, position: Vector2) -> bool:
	if rect == null:
		return false
	return (
		rect.offset_left <= position.x
		and rect.offset_right >= position.x
		and rect.offset_top <= position.y
		and rect.offset_bottom >= position.y
	)


func _check_slurry_buffer_tank(root: Node) -> void:
	var build_system := BuildSystem.new(host.data_registry)
	var gather_system := GatherSystem.new(host.data_registry)
	var formatter := InteractionPromptFormatter.new(
		host.data_registry,
		ProcessingSystem.new(host.data_registry),
		build_system
	)
	var tank_site := PrototypeInteractable.new()
	tank_site.definition_id = "building.slurry_buffer_tank"
	tank_site.interaction_type = "build"
	tank_site.instance_id = "map_object_instance.slurry_buffer_tank_build_site"

	var blocked_world := WorldState.create_default()
	var blocked_character := CharacterState.create_default()
	var blocked_result := build_system.build_structure(
		tank_site.instance_id,
		tank_site.definition_id,
		blocked_character,
		blocked_world
	)
	host._expect_failure_feedback(blocked_result, "建造前置不足", "slurry buffer tank blocks before pollution filter")
	host._expect_text_contains(
		String(blocked_result.get("message", "")),
		"需要先建成污染过滤器",
		"slurry buffer tank requires pollution filter"
	)

	blocked_world.add_base_structure(
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.pollution_edge",
		"map_object_instance.pollution_filter_build_site"
	)
	var first_vial_blocked := build_system.build_structure(
		tank_site.instance_id,
		tank_site.definition_id,
		blocked_character,
		blocked_world
	)
	host._expect_text_contains(
		String(first_vial_blocked.get("message", "")),
		"跑通首支抗污染药剂",
		"slurry buffer tank requires first vial processing"
	)

	var build_world := WorldState.create_default()
	build_world.add_base_structure(
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.pollution_edge",
		"map_object_instance.pollution_filter_build_site"
	)
	build_world.quest_state.set_objective_progress("quest.enter_pollution_edge", "craft_item", "item.resistance_vial_t1", 1.0)
	var build_character := CharacterState.create_default()
	build_character.inventory.items.clear()
	build_character.inventory.fluids.clear()
	var missing_prompt := formatter.format_build_prompt(tank_site, build_character, build_world)
	host._expect_text_contains(missing_prompt, "污染浆液缓冲罐", "slurry buffer prompt names tank")
	host._expect_text_contains(missing_prompt, "缺少建造材料", "slurry buffer prompt shows missing materials")
	host._expect_text_contains(missing_prompt, "污染过滤器处理出污染浆液", "slurry buffer prompt points to filter byproduct")

	build_character.inventory.add_item("item.basic_parts", 2)
	build_character.inventory.add_fluid("fluid.polluted_slurry", 1.0)
	var build_result := build_system.build_structure(
		tank_site.instance_id,
		tank_site.definition_id,
		build_character,
		build_world
	)
	host._expect_equal(bool(build_result.get("success", false)), true, "slurry buffer tank build succeeds")
	host._expect_equal(
		build_world.has_base_structure_definition("building.slurry_buffer_tank"),
		true,
		"slurry buffer tank registers base structure"
	)
	host._expect_equal(
		int(build_character.inventory.items.get("item.basic_parts", 0)),
		0,
		"slurry buffer tank consumes basic parts"
	)
	host._expect_equal(
		float(build_character.inventory.fluids.get("fluid.polluted_slurry", 0.0)),
		0.0,
		"slurry buffer tank consumes polluted slurry"
	)
	host._expect_text_contains(
		String(build_result.get("message", "")),
		"抗污染药剂可补到 2 份",
		"slurry buffer tank build feedback explains double vial supply"
	)

	build_world.quest_state.complete_quest("quest.restore_outpost")
	build_world.add_base_structure(
		"structure.basic_storage_build_site",
		"building.basic_storage",
		"region.outpost_platform",
		"map_object_instance.basic_storage_build_site"
	)
	var supply_character := CharacterState.create_default()
	supply_character.inventory.items.erase("item.resistance_vial_t1")
	var outpost_result := gather_system.interact_with_object(
		"map_object_instance.outpost_core",
		"building.outpost_core",
		"outpost_core",
		supply_character,
		build_world
	)
	host._expect_text_contains(
		String(outpost_result.get("message", "")),
		"污染浆液缓冲罐补抗污染药剂",
		"slurry buffer tank outpost restock names buffer source"
	)
	host._expect_equal(
		int(supply_character.inventory.items.get("item.resistance_vial_t1", 0)),
		2,
		"slurry buffer tank raises vial restock target to two"
	)

	var hud_text := HudStatusPresenter.new().format_vitals_text(
		host.data_registry,
		build_world,
		supply_character
	)
	host._expect_text_contains(hud_text, "抗污染药剂 x2已备", "slurry buffer tank HUD shows double vial ready")
	host._expect_text_contains(hud_text, "前哨可补双药剂", "slurry buffer tank HUD explains pressure payoff")
	var gate_result := gather_system.interact_with_object(
		"map_object_instance.outpost_departure_gate",
		"map_object.outpost_departure_gate",
		"inspect",
		supply_character,
		build_world
	)
	host._expect_text_contains(
		String(gate_result.get("message", "")),
		"抗污染药剂 x2已备",
		"slurry buffer tank departure gate shows double vial ready"
	)

	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var scene_site := map.get_node("Interactables/SlurryBufferTankBuildSite") as PrototypeInteractable
	var locked_world := WorldState.create_default()
	map.refresh_world_interactables(locked_world)
	host._expect_equal(scene_site.can_interact(), false, "slurry buffer tank site hidden before filter route")
	map.refresh_world_interactables(build_world)
	host._expect_equal(scene_site.can_interact(), false, "slurry buffer tank completed site is no longer interactable")
	host._expect_text_contains(scene_site.label.text, "浆液缓冲罐", "slurry buffer tank built scene label")
	host._expect_text_contains(scene_site.label.text, "已接入", "slurry buffer tank built scene state")
	map.free()
	tank_site.free()
