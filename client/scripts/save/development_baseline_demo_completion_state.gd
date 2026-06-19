extends RefCounted
class_name DevelopmentBaselineDemoCompletionState


static func apply(
	world_state: WorldState,
	character_state: CharacterState,
	guard_max_health: float
) -> void:
	_apply_overpressure_review_state(world_state)
	_apply_demo_quest_state(world_state)
	_apply_outpost_review_structures(world_state)
	_apply_core_completion_objects(world_state, guard_max_health)
	_apply_character_review_state(character_state)


static func _apply_overpressure_review_state(world_state: WorldState) -> void:
	world_state.add_deployed_phase_relay_anchor("map_object_instance.phase_return_anchor_chamber")
	world_state.set_active_phase_relay_anchor("map_object_instance.phase_return_anchor_tether")
	world_state.unlock_region("region.demo_stabilization_core")
	world_state.set_base_action_state_value(
		BaseActionDispatchPlan.FRONTLINE_WINDOW_REVIEW_COUNT_KEY,
		BaseActionDispatchPlan.FRONTLINE_WINDOW_REVIEW_LIMIT + 1
	)
	world_state.set_base_action_state_value(
		BaseActionDispatchPlan.FRONTLINE_WINDOW_ARCHIVED_PLAN_KEY,
		BaseActionDispatchPlan.PLAN_PRESSURE_CLEARANCE
	)
	world_state.set_base_action_state_value(
		BaseActionDispatchPlan.FRONTLINE_WINDOW_ARCHIVED_FEEDBACK_KEY,
		"高压窗口反馈已归档：三类模块收益已经支撑更危险目标；当前原型到此收口，不再继续确认下一趟。"
	)
	world_state.set_base_action_state_value(
		BaseActionDispatchPlan.FRONTLINE_WINDOW_STATUS_KEY,
		BaseActionDispatchPlan.STATUS_RESOLVED
	)
	world_state.set_base_action_state_value(
		BaseActionDispatchPlan.FRONTLINE_WINDOW_PLAN_KEY,
		BaseActionDispatchPlan.PLAN_PRESSURE_CLEARANCE
	)
	world_state.set_base_action_state_value(
		BaseActionDispatchPlan.FRONTLINE_WINDOW_FEEDBACK_KEY,
		"高压窗口稳定数据已归档：三类模块收益共同支撑了更危险目标。"
	)
	world_state.set_base_action_state_value(
		BaseActionDispatchPlan.FRONTLINE_WINDOW_FEEDBACK_ACKED_KEY,
		true
	)


static func _apply_demo_quest_state(world_state: WorldState) -> void:
	world_state.quest_state.active_quest_ids.clear()
	world_state.quest_state.set_objective_progress(
		"quest.enter_demo_stabilization_core",
		"visit_region",
		"region.demo_stabilization_core",
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
		"quest.enter_demo_stabilization_core",
		"quest.prepare_demo_stabilization_buffer",
		"quest.defeat_demo_stabilization_guard",
		"quest.write_demo_stabilization_core"
	]:
		world_state.quest_state.complete_quest(quest_id)
	world_state.quest_state.unlock_effect("recipe.core_stabilization_buffer")
	world_state.quest_state.unlock_effect("slice_01_complete")


static func _apply_outpost_review_structures(world_state: WorldState) -> void:
	_mark_structure_built(
		world_state,
		"structure.basic_storage_build_site",
		"building.basic_storage",
		"region.outpost_platform",
		"map_object_instance.basic_storage_build_site"
	)
	_mark_structure_built(
		world_state,
		"structure.field_outfitting_station_build_site",
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		"region.outpost_platform",
		"map_object_instance.field_outfitting_station_build_site"
	)
	FieldOutfittingRuntime.mark_module_calibrated(world_state)
	FieldOutfittingRuntime.mark_core_archive_maintained(world_state)
	DemoFieldLoopPayoffFormatter.mark_payoff_confirmed(world_state)


static func _apply_core_completion_objects(world_state: WorldState, guard_max_health: float) -> void:
	var guard := world_state.ensure_enemy(
		"enemy_instance.demo_stabilization_guard",
		"enemy.demo_stabilization_guard",
		"region.demo_stabilization_core",
		guard_max_health
	)
	guard["health"] = 0.0
	guard["is_defeated"] = true
	guard["drops_granted"] = true
	guard["core_buffer_used"] = true
	_mark_object_gathered(
		world_state,
		"map_object_instance.demo_stabilization_recovery_cache",
		"map_object.demo_stabilization_recovery_cache",
		"region.demo_stabilization_core"
	)
	_mark_object_gathered(
		world_state,
		"map_object_instance.demo_stabilization_guard_cache",
		"map_object.demo_stabilization_guard_cache",
		"region.demo_stabilization_core"
	)
	_mark_object_sampled(
		world_state,
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"region.demo_stabilization_core"
	)


static func _apply_character_review_state(character_state: CharacterState) -> void:
	character_state.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	character_state.quick_slots = ["item.repair_gel", "item.resistance_vial_t1"]
	character_state.inventory = _make_inventory(
		{
			"item.basic_parts": 20,
			"item.frontline_action_report": 1,
			"item.short_action_feedback": 1,
			"item.route_action_feedback": 1,
			"item.phase_survey_feedback": 1,
			"item.repair_gel": 3,
			"item.resistance_vial_t1": 3,
			"item.core_write_charge": 1
		},
		{},
		{"fluid.basic_solvent": 2.0}
	)


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


static func _make_inventory(items: Dictionary, equipment: Dictionary, fluids: Dictionary) -> InventoryState:
	var inventory := InventoryState.new()
	inventory.items = items.duplicate(true)
	inventory.equipment = equipment.duplicate(true)
	inventory.fluids = fluids.duplicate(true)
	inventory.capacity_slots = 24
	return inventory
