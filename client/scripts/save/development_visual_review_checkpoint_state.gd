extends RefCounted
class_name DevelopmentVisualReviewCheckpointState

const CRYSTAL_FIELD_ID := "region.crystal_vein_field"
const OUTPOST_REGION_ID := "region.outpost_platform"
const CRYSTAL_COLLECTOR_STRUCTURE_ID := "structure.crystal_collector_build_site"
const CRYSTAL_COLLECTOR_BUILDING_ID := "building.crystal_collector_t1"
const CRYSTAL_COLLECTOR_SITE_INSTANCE_ID := "map_object_instance.crystal_collector_build_site"
const CRYSTAL_COLLECTOR_OUTPUT_INSTANCE_ID := "map_object_instance.crystal_collector_output"
const CRYSTAL_COLLECTOR_OUTPUT_ID := "map_object.crystal_collector_output"


static func apply(checkpoint_id: String, world_state: WorldState, character_state: CharacterState) -> void:
	match checkpoint_id:
		"visual_review.crystal_collector_output":
			_prepare_crystal_collector_output(world_state, character_state)
		"visual_review.base_handoff":
			_prepare_base_handoff(world_state, character_state)


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
	world_state.quest_state.set_objective_progress("quest.scout_crystal_field", "gather_item", "item.crystal_ore", 6.0)
	world_state.quest_state.set_objective_progress("quest.calibrate_reactor", "gather_item", "item.salvage_scrap", 4.0)
	_mark_crystal_collector_ready(world_state)
	_mark_object_gathered(world_state, CRYSTAL_COLLECTOR_OUTPUT_INSTANCE_ID, CRYSTAL_COLLECTOR_OUTPUT_ID, CRYSTAL_FIELD_ID)
	_mark_base_handoff_structures(world_state)
	character_state.inventory = _make_inventory({"item.basic_parts": 2, "item.repair_gel": 1}, {}, {})


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


static func _make_inventory(items: Dictionary, equipment: Dictionary, fluids: Dictionary) -> InventoryState:
	var inventory := InventoryState.new()
	inventory.items = items.duplicate(true)
	inventory.equipment = equipment.duplicate(true)
	inventory.fluids = fluids.duplicate(true)
	return inventory
