extends RefCounted

const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")

var host


func _init(check_host) -> void:
	host = check_host


func run(root: Node) -> void:
	_check_layout(root)
	_check_gate(root)
	_check_departure_guidance()
	_check_counter_delta()
	_check_residue_feedback_and_processing(root)


func _check_layout(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var pocket := map.get_node("OpeningSceneLayer/PollutionLogisticsMaintenanceRetestPocket") as ColorRect
	var residue_marker := map.get_node("OpeningSceneLayer/PollutionLogisticsMaintenanceRetestResidueMarker") as ColorRect
	var guard_marker := map.get_node("OpeningSceneLayer/PollutionLogisticsMaintenanceRetestGuardMarker") as ColorRect
	var line := map.get_node("OpeningSceneLayer/PollutionLogisticsMaintenanceRetestLine") as ColorRect
	var residue := map.get_node("Interactables/PollutionResidueLogisticsMaintenancePressureCache") as PrototypeInteractable
	var guard := map.get_node("Enemies/PollutedSkitterLogisticsMaintenancePressureGuard") as PrototypeEnemy
	host._expect_equal(
		residue.position.x >= VerticalSliceMap.POLLUTION_REGION_X
			and residue.position.x < VerticalSliceMap.RUIN_OUTER_RING_X
			and residue.position.y >= VerticalSliceMap.POLLUTION_DEEP_Y,
		true,
		"logistics maintenance pollution retest residue stays inside pollution edge"
	)
	host._expect_equal(
		_is_rect_covering_position(pocket, residue.position)
			and _is_rect_covering_position(residue_marker, residue.position)
			and _is_rect_covering_position(guard_marker, guard.position)
			and line.offset_right <= VerticalSliceMap.RUIN_OUTER_RING_X,
		true,
		"logistics maintenance pollution retest markers align with playable objects"
	)
	host._expect_equal(
		guard.position.distance_to(residue.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"logistics maintenance pollution retest residue is tied to nearby combat"
	)
	map.free()


func _check_gate(root: Node) -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var residue := map.get_node("Interactables/PollutionResidueLogisticsMaintenancePressureCache") as PrototypeInteractable
	var guard := map.get_node("Enemies/PollutedSkitterLogisticsMaintenancePressureGuard") as PrototypeEnemy
	var locked_world := _create_logistics_maintenance_world(false)
	map.sync_enemy_states(locked_world)
	map.refresh_world_interactables(locked_world)
	host._expect_equal(residue.can_interact(), false, "pollution logistics retest residue waits for logistics maintenance")
	host._expect_equal(guard.can_be_attacked(), false, "pollution logistics retest guard waits for logistics maintenance")

	var ready_world := _create_logistics_maintenance_world(true)
	map.sync_enemy_states(ready_world)
	map.refresh_world_interactables(ready_world)
	host._expect_equal(residue.can_interact(), true, "pollution logistics retest residue opens after logistics maintenance")
	host._expect_equal(guard.can_be_attacked(), true, "pollution logistics retest guard opens after logistics maintenance")
	map.free()


func _check_departure_guidance() -> void:
	var world := _create_logistics_maintenance_world(true)
	var character := _create_character()
	host._expect_equal(
		CoreGuardAftermathFormatter.get_next_sortie_target_region_id(world),
		"region.pollution_edge",
		"departure target points logistics maintenance payoff to pollution edge first"
	)
	host._expect_text_contains(
		DepartureReadinessFormatter.format_crystal_logistics_return_line(world, character),
		"污染边界",
		"departure readiness names pollution edge logistics retest"
	)
	host._expect_text_contains(
		DepartureReadinessFormatter.format_crystal_logistics_return_next_step(world, character),
		"污染边界压力点",
		"departure next step points to pollution edge pressure pocket"
	)


func _check_counter_delta() -> void:
	var counter_runtime := EnemyCounterattackRuntime.new(host.data_registry)
	var plain_world := _create_logistics_maintenance_world(false)
	var plain_character := _create_character()
	var plain_enemy := _create_enemy()
	var plain_health_before := plain_character.health
	var plain_protection_before := plain_character.protection
	counter_runtime.apply(plain_enemy, plain_character, plain_world, "region.pollution_edge")
	var plain_health_loss := plain_health_before - plain_character.health
	var plain_protection_loss := plain_protection_before - plain_character.protection

	var maintained_world := _create_logistics_maintenance_world(true)
	var maintained_character := _create_character()
	var maintained_enemy := _create_enemy()
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
		"logistics maintenance lowers pollution edge counter health pressure"
	)
	host._expect_equal(
		maintained_protection_loss < plain_protection_loss,
		true,
		"logistics maintenance lowers pollution edge counter protection pressure"
	)
	host._expect_text_contains(
		maintained_message,
		"污染边界后勤维护复测",
		"pollution edge logistics counter names pressure route"
	)
	host._expect_text_contains(
		maintained_message,
		"后勤维护已接入",
		"pollution edge logistics counter reads confirmed maintenance state"
	)
	plain_enemy.free()
	maintained_enemy.free()


func _check_residue_feedback_and_processing(root: Node) -> void:
	var world := _create_logistics_maintenance_world(true)
	var character := _create_character()
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(host.data_registry)
	var residue := map.get_node("Interactables/PollutionResidueLogisticsMaintenancePressureCache") as PrototypeInteractable
	var prompt := InteractionPromptFormatter.new(
		host.data_registry,
		ProcessingSystem.new(host.data_registry),
		BuildSystem.new(host.data_registry)
	).format_general_interaction_prompt(residue, character, world)
	host._expect_text_contains(prompt, "污染边界后勤维护复测守卫", "pollution logistics retest prompt names guard")
	host._expect_text_contains(prompt, "整备台后勤维护收益", "pollution logistics retest prompt explains payoff")

	var gather_result := GatherSystem.new(host.data_registry).interact_with_object(
		FieldOutfittingRuntime.LOGISTICS_MAINTENANCE_POLLUTION_RETEST_RESIDUE_INSTANCE_ID,
		"map_object.pollution_residue_patch",
		"gather",
		character,
		world
	)
	host._expect_equal(bool(gather_result.get("success", false)), true, "pollution logistics retest residue gather succeeds")
	host._expect_text_contains(
		String(gather_result.get("message", "")),
		"污染边界后勤维护沉积已回收",
		"pollution logistics retest gather names source"
	)
	host._expect_text_contains(
		String(gather_result.get("message", "")),
		"后勤维护已降低消耗",
		"pollution logistics retest gather reads maintenance payoff"
	)
	host._expect_equal(
		CoreGuardAftermathFormatter.get_next_sortie_target_region_id(world),
		"region.outpost_platform",
		"pollution logistics retest routes back to base after residue gather"
	)

	world.quest_state.unlock_effect("recipe.cleanse_residue")
	character.inventory.add_fluid("fluid.basic_solvent", 1.0)
	var processing := ProcessingSystem.new(host.data_registry)
	var start := processing.process_recipe("recipe.cleanse_residue", character, world)
	host._expect_equal(bool(start.get("success", false)), true, "pollution logistics retest residue filtering starts")
	host._expect_text_contains(
		String(start.get("message", "")),
		"污染边界后勤维护沉积",
		"pollution logistics retest filtering start names source"
	)
	var completed := processing.advance_processing(13.0, character, world)
	host._expect_equal(completed.size(), 1, "pollution logistics retest residue filtering completes")
	host._expect_equal(
		FieldOutfittingRuntime.is_logistics_maintenance_pollution_retest_processed(world),
		true,
		"pollution logistics retest filtering stores processed state"
	)
	host._expect_equal(
		CoreGuardAftermathFormatter.get_next_sortie_target_region_id(world),
		"region.demo_stabilization_core",
		"processed pollution logistics retest returns route to core logistics retest"
	)
	map.free()


func _create_logistics_maintenance_world(confirmed: bool) -> WorldState:
	var world := WorldState.create_default()
	host._complete_first_minute(world)
	world.current_region_id = "region.outpost_platform"
	world.quest_state.complete_quest("quest.restore_outpost")
	world.quest_state.complete_quest("quest.enter_pollution_edge")
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
	world.set_base_structure_status("structure.pollution_filter_build_site", "completed", "recipe.cleanse_residue")
	FieldOutfittingRuntime.mark_module_calibrated(world)
	FieldOutfittingRuntime.mark_core_archive_maintained(world)
	_mark_core_retest_readout_gathered(world)
	_mark_crystal_logistics_return_gathered(world)
	FieldOutfittingRuntime.mark_logistics_material_processed(world)
	if confirmed:
		FieldOutfittingRuntime.mark_logistics_maintenance_confirmed(world)
	return world


func _mark_core_retest_readout_gathered(world: WorldState) -> void:
	world.ensure_map_object(
		CoreStabilizationPressureFormatter.RETEST_READOUT_INSTANCE_ID,
		CoreStabilizationPressureFormatter.RETEST_READOUT_DEFINITION_ID,
		"region.demo_stabilization_core"
	)
	world.set_map_object_flag(CoreStabilizationPressureFormatter.RETEST_READOUT_INSTANCE_ID, "is_gathered", true)


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
	world.set_map_object_flag(CoreGuardAftermathFormatter.CRYSTAL_LOGISTICS_RETURN_CRYSTAL_INSTANCE_ID, "is_gathered", true)
	world.set_map_object_flag(CoreGuardAftermathFormatter.CRYSTAL_LOGISTICS_RETURN_WRECKAGE_INSTANCE_ID, "is_gathered", true)


func _create_character() -> CharacterState:
	var character := CharacterState.create_default()
	character.current_region_id = "region.pollution_edge"
	character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	return character


func _create_enemy() -> PrototypeEnemy:
	var enemy := PrototypeEnemy.new()
	enemy.definition_id = "enemy.polluted_skitter"
	enemy.instance_id = FieldOutfittingRuntime.LOGISTICS_MAINTENANCE_POLLUTION_RETEST_GUARD_INSTANCE_ID
	enemy.display_name = "受扰掠行体"
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
