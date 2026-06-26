extends RefCounted
class_name DevelopmentVisualReviewCheckpointState

const CRYSTAL_FIELD_ID := "region.crystal_vein_field"
const OUTPOST_REGION_ID := "region.outpost_platform"
const CRYSTAL_COLLECTOR_STRUCTURE_ID := "structure.crystal_collector_build_site"
const CRYSTAL_COLLECTOR_BUILDING_ID := "building.crystal_collector_t1"
const CRYSTAL_COLLECTOR_SITE_INSTANCE_ID := "map_object_instance.crystal_collector_build_site"
const CRYSTAL_COLLECTOR_OUTPUT_INSTANCE_ID := "map_object_instance.crystal_collector_output"
const CRYSTAL_COLLECTOR_OUTPUT_ID := "map_object.crystal_collector_output"
const CORE_STATION_REGION_ID := "region.demo_stabilization_core"


static func apply(checkpoint_id: String, world_state: WorldState, character_state: CharacterState) -> void:
	match checkpoint_id:
		"visual_review.crystal_collector_output":
			_prepare_crystal_collector_output(world_state, character_state)
		"visual_review.base_handoff":
			_prepare_base_handoff(world_state, character_state)
		"visual_review.core_station":
			_prepare_core_station_feedback(world_state, character_state)


static func _prepare_crystal_collector_output(world_state: WorldState, character_state: CharacterState) -> void:
	_prepare_restored_outpost(world_state)
	world_state.quest_state.active_quest_ids = ["quest.scout_crystal_field"]
	world_state.quest_state.set_objective_progress("quest.scout_crystal_field", "visit_region", CRYSTAL_FIELD_ID, 1.0)
	world_state.quest_state.set_objective_progress("quest.scout_crystal_field", "gather_item", "item.crystal_ore", 3.0)
	_mark_crystal_collector_ready(world_state)
	character_state.inventory = _make_inventory({"item.basic_parts": 2}, {}, {})


static func _prepare_base_handoff(world_state: WorldState, character_state: CharacterState) -> void:
	_prepare_restored_outpost(world_state)
	world_state.quest_state.completed_quest_ids = ["quest.restore_outpost", "quest.scout_crystal_field"]
	world_state.quest_state.active_quest_ids = ["quest.calibrate_reactor"]
	world_state.quest_state.unlocked_effects = [
		OUTPOST_REGION_ID,
		CRYSTAL_FIELD_ID,
		"recipe.process_crystal_ore",
		"recipe.repair_gel",
		"recipe.reactor_calibrator"
	]
	world_state.quest_state.set_objective_progress("quest.scout_crystal_field", "visit_region", CRYSTAL_FIELD_ID, 1.0)
	world_state.quest_state.set_objective_progress("quest.scout_crystal_field", "gather_item", "item.crystal_ore", 3.0)
	world_state.quest_state.set_objective_progress("quest.calibrate_reactor", "gather_item", "item.salvage_scrap", 2.0)
	_mark_crystal_collector_ready(world_state)
	_mark_object_gathered(world_state, CRYSTAL_COLLECTOR_OUTPUT_INSTANCE_ID, CRYSTAL_COLLECTOR_OUTPUT_ID, CRYSTAL_FIELD_ID)
	_mark_base_handoff_structures(world_state)
	character_state.inventory = _make_inventory({"item.basic_parts": 2, "item.repair_gel": 1}, {}, {})


static func _prepare_core_station_feedback(world_state: WorldState, character_state: CharacterState) -> void:
	world_state.unlock_region(CORE_STATION_REGION_ID)
	world_state.current_region_id = CORE_STATION_REGION_ID
	character_state.current_region_id = CORE_STATION_REGION_ID
	character_state.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	character_state.quick_slots = ["item.repair_gel", "item.resistance_vial_t1"]
	character_state.inventory = _make_inventory(
		{
			"item.basic_parts": 4,
			"item.repair_gel": 2,
			"item.resistance_vial_t1": 2,
			"item.core_write_charge": 1
		},
		{},
		{"fluid.basic_solvent": 2.0, "fluid.polluted_slurry": 1.0}
	)

	_complete_core_station_quests(world_state)
	_prepare_core_station_support_structures(world_state)
	_prepare_core_station_objects(world_state)


static func _complete_core_station_quests(world_state: WorldState) -> void:
	world_state.quest_state.active_quest_ids.clear()
	world_state.quest_state.set_objective_progress(
		"quest.enter_demo_stabilization_core",
		"visit_region",
		CORE_STATION_REGION_ID,
		1.0
	)
	world_state.quest_state.set_objective_progress(
		"quest.prepare_demo_stabilization_buffer",
		"gather_item",
		"item.polluted_residue",
		2.0
	)
	world_state.quest_state.set_objective_progress(
		"quest.prepare_demo_stabilization_buffer",
		"defeat_enemy",
		"enemy.polluted_skitter",
		1.0
	)
	world_state.quest_state.set_objective_progress(
		"quest.prepare_demo_stabilization_buffer",
		"craft_item",
		"item.core_stabilization_buffer",
		1.0
	)
	world_state.quest_state.set_objective_progress(
		"quest.defeat_demo_stabilization_guard",
		"defeat_enemy",
		"enemy.demo_stabilization_guard",
		1.0
	)
	world_state.quest_state.set_objective_progress(
		"quest.write_demo_stabilization_core",
		"gather_item",
		"item.core_write_charge",
		1.0
	)
	world_state.quest_state.set_objective_progress(
		"quest.write_demo_stabilization_core",
		"inspect",
		"map_object.demo_stabilization_core",
		1.0
	)
	for quest_id in [
		"quest.restore_outpost",
		"quest.enter_demo_stabilization_core",
		"quest.prepare_demo_stabilization_buffer",
		"quest.defeat_demo_stabilization_guard",
		"quest.write_demo_stabilization_core"
	]:
		world_state.quest_state.complete_quest(quest_id)
	world_state.quest_state.unlock_effect("recipe.core_stabilization_buffer")
	world_state.quest_state.unlock_effect("slice_01_complete")


static func _prepare_core_station_support_structures(world_state: WorldState) -> void:
	_mark_structure_built(
		world_state,
		"structure.field_outfitting_station_build_site",
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		OUTPOST_REGION_ID,
		"map_object_instance.field_outfitting_station_build_site"
	)
	_mark_structure_built(
		world_state,
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.pollution_edge",
		"map_object_instance.pollution_filter_build_site"
	)
	world_state.set_base_structure_status("structure.pollution_filter_build_site", "completed", "recipe.cleanse_residue")
	FieldOutfittingRuntime.mark_module_calibrated(world_state)
	FieldOutfittingRuntime.mark_core_archive_maintained(world_state)
	FieldOutfittingRuntime.mark_logistics_maintenance_confirmed(world_state)
	FieldOutfittingRuntime.mark_logistics_maintenance_pollution_retest_processed(world_state)


static func _prepare_core_station_objects(world_state: WorldState) -> void:
	var guard := world_state.ensure_enemy(
		"enemy_instance.demo_stabilization_guard",
		"enemy.demo_stabilization_guard",
		CORE_STATION_REGION_ID,
		156.0
	)
	guard["health"] = 0.0
	guard["is_defeated"] = true
	guard["drops_granted"] = true
	guard["core_buffer_used"] = true
	guard["core_side_supply_used"] = true
	guard["pressure_vial_used"] = true
	_mark_object_gathered(
		world_state,
		"map_object_instance.demo_stabilization_recovery_cache",
		"map_object.demo_stabilization_recovery_cache",
		CORE_STATION_REGION_ID
	)
	_mark_object_gathered(
		world_state,
		"map_object_instance.demo_stabilization_guard_cache",
		"map_object.demo_stabilization_guard_cache",
		CORE_STATION_REGION_ID
	)
	_mark_object_sampled(
		world_state,
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		CORE_STATION_REGION_ID
	)
	_mark_object_gathered(
		world_state,
		CoreStabilizationPressureFormatter.PRESSURE_RETEST_RESIDUE_INSTANCE_ID,
		"map_object.pollution_residue_patch",
		"region.pollution_edge"
	)
	_mark_object_gathered(
		world_state,
		CoreStabilizationPressureFormatter.RETEST_READOUT_INSTANCE_ID,
		CoreStabilizationPressureFormatter.RETEST_READOUT_DEFINITION_ID,
		CORE_STATION_REGION_ID
	)
	_mark_object_gathered(
		world_state,
		CoreStabilizationPressureFormatter.LOGISTICS_MAINTENANCE_RETEST_RESIDUE_INSTANCE_ID,
		CoreStabilizationPressureFormatter.LOGISTICS_MAINTENANCE_RETEST_RESIDUE_DEFINITION_ID,
		CORE_STATION_REGION_ID
	)
	CoreStabilizationPressureFormatter.mark_logistics_maintenance_retest_processed(world_state)
	_mark_enemy_defeated(
		world_state,
		"enemy_instance.polluted_skitter_logistics_maintenance_retest_guard",
		"enemy.demo_stabilization_logistics_retest_skitter",
		CORE_STATION_REGION_ID
	)


static func _prepare_restored_outpost(world_state: WorldState) -> void:
	world_state.unlock_region(CRYSTAL_FIELD_ID)
	world_state.quest_state.active_quest_ids.clear()
	world_state.quest_state.completed_quest_ids = ["quest.restore_outpost"]
	world_state.quest_state.objective_progress.clear()
	world_state.quest_state.unlocked_effects = [OUTPOST_REGION_ID, CRYSTAL_FIELD_ID, "recipe.process_crystal_ore"]
	world_state.quest_state.set_objective_progress("quest.restore_outpost", "interact", "building.outpost_core", 1.0)


static func _mark_crystal_collector_ready(world_state: WorldState) -> void:
	_mark_structure_built(
		world_state,
		CRYSTAL_COLLECTOR_STRUCTURE_ID,
		CRYSTAL_COLLECTOR_BUILDING_ID,
		CRYSTAL_FIELD_ID,
		CRYSTAL_COLLECTOR_SITE_INSTANCE_ID
	)
	world_state.ensure_map_object(CRYSTAL_COLLECTOR_OUTPUT_INSTANCE_ID, CRYSTAL_COLLECTOR_OUTPUT_ID, CRYSTAL_FIELD_ID)


static func _mark_base_handoff_structures(world_state: WorldState) -> void:
	_mark_structure_built(
		world_state,
		"structure.basic_storage_build_site",
		"building.basic_storage",
		OUTPOST_REGION_ID,
		"map_object_instance.basic_storage_build_site"
	)
	_mark_structure_built(
		world_state,
		"structure.field_outfitting_station_build_site",
		"building.field_outfitting_station",
		OUTPOST_REGION_ID,
		"map_object_instance.field_outfitting_station_build_site"
	)
	world_state.set_base_structure_status("structure.basic_reactor", "completed", "recipe.repair_gel")


static func _mark_structure_built(
	world_state: WorldState,
	structure_id: String,
	definition_id: String,
	region_id: String,
	site_instance_id: String
) -> void:
	var object_state := world_state.ensure_map_object(site_instance_id, definition_id, region_id)
	object_state["is_built"] = true
	object_state["built_definition_id"] = definition_id
	world_state.add_base_structure(structure_id, definition_id, region_id, site_instance_id)


static func _mark_object_gathered(
	world_state: WorldState,
	instance_id: String,
	definition_id: String,
	region_id: String
) -> void:
	var object_state := world_state.ensure_map_object(instance_id, definition_id, region_id)
	object_state["is_gathered"] = true


static func _mark_object_sampled(
	world_state: WorldState,
	instance_id: String,
	definition_id: String,
	region_id: String
) -> void:
	var object_state := world_state.ensure_map_object(instance_id, definition_id, region_id)
	object_state["is_sampled"] = true


static func _mark_enemy_defeated(
	world_state: WorldState,
	instance_id: String,
	definition_id: String,
	region_id: String
) -> void:
	var enemy_state := world_state.ensure_enemy(instance_id, definition_id, region_id, 1.0)
	enemy_state["health"] = 0.0
	enemy_state["is_defeated"] = true


static func _make_inventory(items: Dictionary, equipment: Dictionary, fluids: Dictionary) -> InventoryState:
	var inventory := InventoryState.new()
	inventory.items = items.duplicate(true)
	inventory.equipment = equipment.duplicate(true)
	inventory.fluids = fluids.duplicate(true)
	return inventory
