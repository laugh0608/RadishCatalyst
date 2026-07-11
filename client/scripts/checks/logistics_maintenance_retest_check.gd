extends RefCounted

const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")

var host


func _init(check_host) -> void:
	host = check_host


func run(root: Node) -> void:
	var gather_system := GatherSystem.new(host.data_registry)
	var prompt_formatter := InteractionPromptFormatter.new(
		host.data_registry,
		ProcessingSystem.new(host.data_registry),
		BuildSystem.new(host.data_registry)
	)
	_check_logistics_maintenance_core_retest(root, gather_system, prompt_formatter)


func _check_logistics_maintenance_core_retest(
	root: Node,
	gather_system: GatherSystem,
	prompt_formatter: InteractionPromptFormatter
) -> void:
	var character := CharacterState.create_default()
	character.current_region_id = "region.demo_stabilization_core"
	character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	character.inventory.items["item.repair_gel"] = 1
	character.inventory.items["item.resistance_vial_t1"] = 2

	var blocked_world := _create_logistics_maintenance_core_retest_world(false)
	var blocked_map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(blocked_map)
	blocked_map.setup(host.data_registry)
	blocked_map.apply_runtime_state(blocked_world, character)
	var blocked_residue := blocked_map.get_node("Interactables/PollutionResidueLogisticsMaintenanceRetestCache") as PrototypeInteractable
	var blocked_guard := blocked_map.get_node("Enemies/PollutedSkitterLogisticsMaintenanceRetestGuard") as PrototypeEnemy
	host._expect_equal(
		blocked_residue.can_interact() == false and blocked_guard.can_be_attacked() == false,
		true,
		"logistics maintenance core retest waits for outfitting confirmation"
	)
	blocked_map.free()

	var ready_world := _create_logistics_maintenance_core_retest_world(true)
	var ready_map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(ready_map)
	ready_map.setup(host.data_registry)
	ready_map.apply_runtime_state(ready_world, character)
	var residue := ready_map.get_node("Interactables/PollutionResidueLogisticsMaintenanceRetestCache") as PrototypeInteractable
	var guard := ready_map.get_node("Enemies/PollutedSkitterLogisticsMaintenanceRetestGuard") as PrototypeEnemy
	var pocket := ready_map.get_node("OpeningSceneLayer/CoreStabilizationLogisticsRetestPocket") as ColorRect
	var residue_marker := ready_map.get_node("OpeningSceneLayer/CoreStabilizationLogisticsRetestResidueMarker") as ColorRect
	var guard_marker := ready_map.get_node("OpeningSceneLayer/CoreStabilizationLogisticsRetestGuardMarker") as ColorRect
	host._expect_equal(
		residue.definition_id == CoreStabilizationPressureFormatter.LOGISTICS_MAINTENANCE_RETEST_RESIDUE_DEFINITION_ID
			and residue.can_interact()
			and guard.can_be_attacked()
			and _is_rect_covering_position(pocket, residue.position)
			and _is_rect_covering_position(residue_marker, residue.position)
			and _is_rect_covering_position(guard_marker, guard.position)
			and guard.position.distance_to(residue.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"logistics maintenance core retest scene opens a guarded core pressure pocket"
	)
	var prompt := prompt_formatter.format_general_interaction_prompt(residue, character, ready_world)
	host._expect_text_contains(prompt, "后勤维护复测守卫", "logistics retest prompt names guard")
	host._expect_text_contains(prompt, "整备台后勤维护收益", "logistics retest prompt explains outfitting payoff")
	host._expect_text_contains(
		CoreStabilizationPressureFormatter.format_core_revisit_next_step(ready_world, character),
		"后勤维护复测压力点已开放",
		"logistics retest core HUD next step points to pressure pocket"
	)
	host._expect_equal(
		CoreGuardAftermathFormatter.get_next_sortie_target_region_id(ready_world),
		"region.demo_stabilization_core",
		"logistics retest map target stays on core station before residue is gathered"
	)
	_check_logistics_maintenance_counter_delta()

	ready_map.player.position = guard.position
	var first_hit := ready_map.try_attack(character, ready_world)
	host._expect_text_contains(
		String(first_hit.get("message", "")),
		"后勤维护复测",
		"logistics retest guard counter names pressure route"
	)
	host._expect_text_contains(
		String(first_hit.get("message", "")),
		"后勤维护已接入",
		"logistics retest guard counter reads logistics maintenance payoff"
	)
	ready_map.try_attack(character, ready_world)
	var defeated := ready_map.try_attack(character, ready_world)
	host._expect_equal(bool(defeated.get("enemy_defeated", false)), true, "logistics retest guard can be defeated")
	host._expect_text_contains(
		String(defeated.get("message", "")),
		"后勤维护复测压力暂时安全",
		"logistics retest guard defeat points to residue processing"
	)

	var gather_result := gather_system.interact_with_object(
		CoreStabilizationPressureFormatter.LOGISTICS_MAINTENANCE_RETEST_RESIDUE_INSTANCE_ID,
		CoreStabilizationPressureFormatter.LOGISTICS_MAINTENANCE_RETEST_RESIDUE_DEFINITION_ID,
		"gather",
		character,
		ready_world
	)
	host._expect_equal(bool(gather_result.get("success", false)), true, "logistics retest residue gather succeeds")
	host._expect_text_contains(
		String(gather_result.get("message", "")),
		"后勤维护复测沉积已回收",
		"logistics retest residue gather points to filter processing"
	)
	host._expect_text_contains(
		String(gather_result.get("message", "")),
		"后勤维护已降低消耗",
		"logistics retest residue gather reads logistics maintenance pressure payoff"
	)
	host._expect_equal(
		CoreGuardAftermathFormatter.get_next_sortie_target_region_id(ready_world),
		"region.outpost_platform",
		"logistics retest map target returns to base after residue is gathered"
	)
	character.inventory.add_fluid("fluid.basic_solvent", 1.0)
	ready_world.quest_state.unlock_effect("recipe.cleanse_residue")
	var processing := ProcessingSystem.new(host.data_registry)
	var filter_start := processing.process_recipe("recipe.cleanse_residue", character, ready_world)
	host._expect_equal(bool(filter_start.get("success", false)), true, "logistics retest residue filtering starts")
	host._expect_text_contains(
		String(filter_start.get("message", "")),
		"后勤维护复测沉积",
		"logistics retest filtering start names residue source"
	)
	var completed := processing.advance_processing(13.0, character, ready_world)
	host._expect_equal(completed.size(), 1, "logistics retest residue filtering completes")
	host._expect_equal(
		CoreStabilizationPressureFormatter.is_logistics_maintenance_retest_processed(ready_world),
		true,
		"logistics retest filtering stores processed state"
	)
	if not completed.is_empty():
		host._expect_text_contains(
			String(completed[0].get("next_step_text", "")),
			"后勤维护复测沉积已处理",
			"logistics retest filtering completion names processed source"
		)
	var outpost_line := DepartureReadinessFormatter.format_crystal_logistics_return_line(ready_world, character)
	host._expect_text_contains(
		outpost_line,
		"沉积已过滤成药剂和污染浆液",
		"logistics retest departure readiness reads processed residue"
	)
	ready_world.current_region_id = "region.outpost_platform"
	host._expect_equal(
		CoreGuardAftermathFormatter.get_next_sortie_target_region_id(ready_world),
		"region.demo_stabilization_core",
		"logistics retest map target can point outward again after filtering"
	)
	ready_map.free()


func _create_logistics_maintenance_core_retest_world(confirmed: bool) -> WorldState:
	var world := WorldState.create_default()
	host._complete_first_minute(world)
	world.current_region_id = "region.demo_stabilization_core"
	world.quest_state.complete_quest("quest.restore_outpost")
	world.quest_state.complete_quest("quest.enter_pollution_edge")
	world.quest_state.complete_quest("quest.write_demo_stabilization_core")
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
	world.set_base_structure_status("structure.pollution_filter_build_site", "completed", "recipe.cleanse_residue")
	FieldOutfittingRuntime.mark_module_calibrated(world)
	FieldOutfittingRuntime.mark_core_archive_maintained(world)
	world.ensure_map_object(
		"map_object_instance.pollution_residue_core_archive_pressure_retest_cache",
		"map_object.pollution_residue_patch",
		"region.pollution_edge"
	)
	world.set_map_object_flag("map_object_instance.pollution_residue_core_archive_pressure_retest_cache", "is_gathered", true)
	world.ensure_map_object(
		CoreStabilizationPressureFormatter.RETEST_READOUT_INSTANCE_ID,
		CoreStabilizationPressureFormatter.RETEST_READOUT_DEFINITION_ID,
		"region.demo_stabilization_core"
	)
	world.set_map_object_flag(CoreStabilizationPressureFormatter.RETEST_READOUT_INSTANCE_ID, "is_gathered", true)
	world.ensure_map_object(
		CoreStabilizationPressureFormatter.LOGISTICS_MAINTENANCE_RETEST_RESIDUE_INSTANCE_ID,
		CoreStabilizationPressureFormatter.LOGISTICS_MAINTENANCE_RETEST_RESIDUE_DEFINITION_ID,
		"region.demo_stabilization_core"
	)
	if confirmed:
		_mark_crystal_logistics_return_gathered(world)
		FieldOutfittingRuntime.mark_logistics_material_processed(world)
		FieldOutfittingRuntime.mark_logistics_maintenance_confirmed(world)
		FieldOutfittingRuntime.mark_logistics_maintenance_pollution_retest_processed(world)
	return world


func _mark_crystal_logistics_return_gathered(world: WorldState) -> void:
	world.ensure_map_object(
		CoreGuardAftermathFormatter.CRYSTAL_LOGISTICS_RETURN_CRYSTAL_INSTANCE_ID,
		"map_object.crystal_cluster",
		"region.crystal_vein_field"
	)
	world.ensure_map_object(
		CoreGuardAftermathFormatter.CRYSTAL_LOGISTICS_RETURN_WRECKAGE_INSTANCE_ID,
		"map_object.field_wreckage",
		"region.crystal_vein_field"
	)
	world.set_map_object_flag(
		CoreGuardAftermathFormatter.CRYSTAL_LOGISTICS_RETURN_CRYSTAL_INSTANCE_ID,
		"is_gathered",
		true
	)
	world.set_map_object_flag(
		CoreGuardAftermathFormatter.CRYSTAL_LOGISTICS_RETURN_WRECKAGE_INSTANCE_ID,
		"is_gathered",
		true
	)


func _check_logistics_maintenance_counter_delta() -> void:
	var counter_runtime := EnemyCounterattackRuntime.new(host.data_registry)
	var plain_world := _create_logistics_maintenance_core_retest_world(false)
	var plain_character := _create_logistics_counter_character()
	var plain_enemy := _create_logistics_retest_enemy()
	var plain_health_before := plain_character.health
	var plain_protection_before := plain_character.protection
	counter_runtime.apply(plain_enemy, plain_character, plain_world, "region.demo_stabilization_core")
	var plain_health_loss := plain_health_before - plain_character.health
	var plain_protection_loss := plain_protection_before - plain_character.protection

	var maintained_world := _create_logistics_maintenance_core_retest_world(true)
	var maintained_character := _create_logistics_counter_character()
	var maintained_enemy := _create_logistics_retest_enemy()
	var maintained_health_before := maintained_character.health
	var maintained_protection_before := maintained_character.protection
	var maintained_message := counter_runtime.apply(
		maintained_enemy,
		maintained_character,
		maintained_world,
		"region.demo_stabilization_core"
	)
	var maintained_health_loss := maintained_health_before - maintained_character.health
	var maintained_protection_loss := maintained_protection_before - maintained_character.protection
	host._expect_equal(
		maintained_health_loss < plain_health_loss,
		true,
		"logistics maintenance lowers core retest counter health pressure"
	)
	host._expect_equal(
		maintained_protection_loss < plain_protection_loss,
		true,
		"logistics maintenance lowers core retest counter protection pressure"
	)
	host._expect_text_contains(
		maintained_message,
		"后勤维护已接入",
		"logistics maintenance counter feedback reads confirmed maintenance state"
	)
	host._expect_text_contains(
		maintained_message,
		"整备台维护已压低",
		"logistics maintenance counter feedback explains lowered pressure"
	)
	plain_enemy.free()
	maintained_enemy.free()


func _create_logistics_counter_character() -> CharacterState:
	var character := CharacterState.create_default()
	character.current_region_id = "region.demo_stabilization_core"
	character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	return character


func _create_logistics_retest_enemy() -> PrototypeEnemy:
	var enemy := PrototypeEnemy.new()
	enemy.definition_id = "enemy.demo_stabilization_logistics_retest_skitter"
	enemy.instance_id = "enemy_instance.polluted_skitter_logistics_maintenance_retest_guard"
	enemy.display_name = "核心复测受扰掠行体"
	return enemy


func _is_rect_covering_position(rect: ColorRect, position: Vector2) -> bool:
	if rect == null:
		return false
	return (
		rect.offset_left <= position.x
		and rect.offset_right >= position.x
		and rect.offset_top <= position.y
		and rect.offset_bottom >= position.y
	)
