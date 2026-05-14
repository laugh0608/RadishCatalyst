extends RefCounted

const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")

var host


func _init(check_host) -> void:
	host = check_host


func run() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	host.root.add_child(map)
	map.player = map.get_node("Player")
	map.interactables_root = map.get_node("Interactables")
	map.enemies_root = map.get_node("Enemies")
	for interactable in map.interactables_root.get_children():
		if interactable is PrototypeInteractable:
			interactable.label = interactable.get_node("Label")
			interactable.marker = interactable.get_node("Marker")
	for enemy in map.enemies_root.get_children():
		if enemy is PrototypeEnemy:
			enemy.label = enemy.get_node("Label")
			enemy.sprite = enemy.get_node("Sprite")
			enemy.collision_shape = enemy.get_node("CollisionShape2D")
	map.setup(host.data_registry)
	var relay_world := WorldState.create_default()
	relay_world.unlock_region("region.crystal_vein_field")
	relay_world.unlock_region("region.pollution_edge")
	relay_world.unlock_region("region.locked_ruin_gate")
	relay_world.unlock_region("region.ruin_outer_ring")
	relay_world.unlock_region("region.deep_ruin_threshold")
	relay_world.current_region_id = "region.deep_ruin_threshold"
	relay_world.quest_state.active_quest_ids = ["quest.deploy_phase_relay_anchor"]
	relay_world.quest_state.completed_quest_ids = [
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
		"quest.unlock_ruin_signal",
		"quest.scout_ruin_outer_ring",
		"quest.assemble_phase_anchor",
		"quest.stabilize_outer_ring_barrier",
		"quest.secure_outer_ring_signal",
		"quest.salvage_signal_echo",
		"quest.analyze_deep_signal",
		"quest.unlock_deep_ruin_entrance",
		"quest.harvest_phase_filament",
		"quest.refine_phase_filament",
		"quest.assemble_deep_override",
		"quest.unlock_deep_ruin_cache",
		"quest.analyze_deep_core",
		"quest.activate_deep_array",
		"quest.assemble_deep_signal_matrix"
	]
	var relay_character := CharacterState.create_default()
	relay_character.current_region_id = "region.deep_ruin_threshold"
	relay_character.position = Vector2(854, 96)
	relay_character.inventory.add_item("item.deep_signal_matrix", 1)
	map.apply_runtime_state(relay_world, relay_character)
	map.update_current_interactable()
	host._expect_equal(
		map.current_interactable.definition_id,
		"map_object.phase_return_anchor",
		"phase relay anchor should be current interactable in deep region"
	)
	var deploy_result := map.try_interact(relay_character, relay_world)
	host._expect_equal(bool(deploy_result.get("success", false)), true, "phase relay anchor deployment should succeed")
	host._expect_equal(int(relay_character.inventory.items.get("item.deep_signal_matrix", 0)), 0, "phase relay anchor deployment consumes deep signal matrix")
	host._expect_equal(relay_world.active_phase_relay_anchor_id, "map_object_instance.phase_return_anchor", "phase relay anchor deployment records active anchor")
	host._expect_equal(
		relay_world.get_deployed_phase_relay_anchor_ids(),
		["map_object_instance.phase_return_anchor"],
		"phase relay anchor deployment records deployed anchors"
	)
	var relay_runtime := QuestRuntime.new(host.data_registry)
	var deploy_runtime_result := relay_runtime.advance_for_interaction(
		relay_world,
		relay_character,
		{
			"definition_id": "map_object.phase_return_anchor",
			"interaction_type": "inspect",
			"recipe_id": ""
		},
		deploy_result
	)
	host._expect_array_has(relay_world.quest_state.completed_quest_ids, "quest.deploy_phase_relay_anchor", "phase relay deployment completes quest")
	host._expect_equal(Array(deploy_runtime_result.get("completion_feedbacks", [])).size(), 1, "phase relay deployment emits completion feedback")
	host._expect_array_has(relay_world.quest_state.active_quest_ids, "quest.reenter_phase_frontline", "phase relay deployment activates reentry quest")
	map.refresh_world_interactables(relay_world)
	map.update_current_interactable()
	var return_result := map.try_interact(relay_character, relay_world)
	host._expect_equal(bool(return_result.get("success", false)), true, "phase relay anchor return to outpost should succeed")
	host._expect_equal(relay_world.current_region_id, "region.outpost_platform", "phase relay anchor return updates world region")
	host._expect_equal(relay_character.current_region_id, "region.outpost_platform", "phase relay anchor return updates character region")
	host._expect_equal(
		map.current_interactable.definition_id,
		"map_object.phase_relay_pad",
		"phase relay pad should become current interactable after returning to outpost"
	)
	var pad_result := map.try_interact(relay_character, relay_world)
	host._expect_equal(bool(pad_result.get("success", false)), true, "phase relay pad return to deep anchor should succeed")
	host._expect_equal(relay_world.current_region_id, "region.deep_ruin_threshold", "phase relay pad updates world region back to deep")
	host._expect_equal(relay_character.current_region_id, "region.deep_ruin_threshold", "phase relay pad updates character region back to deep")
	var pad_runtime_result := relay_runtime.advance_for_interaction(
		relay_world,
		relay_character,
		{
			"definition_id": "map_object.phase_relay_pad",
			"interaction_type": "inspect",
			"recipe_id": ""
		},
		pad_result
	)
	host._expect_array_has(relay_world.quest_state.completed_quest_ids, "quest.reenter_phase_frontline", "phase relay pad completes reentry quest")
	host._expect_array_has(relay_world.quest_state.active_quest_ids, "quest.trace_phase_splinters", "phase relay pad activates phase splinter tracing quest")
	host._expect_equal(Array(pad_runtime_result.get("completion_feedbacks", [])).size(), 1, "phase relay pad emits completion feedback")
	relay_runtime.reconcile_active_objectives(relay_world, relay_character)
	host._expect_equal(
		relay_world.quest_state.get_objective_progress("quest.trace_phase_splinters", "visit_region", "region.deep_ruin_threshold"),
		1.0,
		"phase relay reentry should immediately count current deep region for splinter tracing"
	)
	host._expect_equal(
		map.current_interactable.definition_id,
		"map_object.phase_return_anchor",
		"phase relay anchor should become current interactable after returning to deep region"
	)

	var locked_splinter_world := WorldState.create_default()
	locked_splinter_world.unlock_region("region.deep_ruin_threshold")
	locked_splinter_world.current_region_id = "region.deep_ruin_threshold"
	var locked_splinter_character := CharacterState.create_default()
	locked_splinter_character.current_region_id = "region.deep_ruin_threshold"
	locked_splinter_character.position = Vector2(1036, -102)
	map.apply_runtime_state(locked_splinter_world, locked_splinter_character)
	map.update_current_interactable()
	host._expect_equal(
		map.current_interactable == null,
		true,
		"disabled phase splinter clusters should not remain interactable before relay reentry"
	)
	var chamber_anchor_world := WorldState.create_default()
	for region_id in [
		"region.crystal_vein_field",
		"region.pollution_edge",
		"region.locked_ruin_gate",
		"region.ruin_outer_ring",
		"region.deep_ruin_threshold",
		"region.inner_phase_well",
		"region.phase_well_sink",
		"region.phase_well_chamber"
	]:
		chamber_anchor_world.unlock_region(region_id)
	chamber_anchor_world.current_region_id = "region.phase_well_chamber"
	chamber_anchor_world.quest_state.active_quest_ids = ["quest.collect_heart_spine"]
	chamber_anchor_world.quest_state.completed_quest_ids = [
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
		"quest.unlock_ruin_signal",
		"quest.scout_ruin_outer_ring",
		"quest.assemble_phase_anchor",
		"quest.stabilize_outer_ring_barrier",
		"quest.secure_outer_ring_signal",
		"quest.salvage_signal_echo",
		"quest.analyze_deep_signal",
		"quest.unlock_deep_ruin_entrance",
		"quest.harvest_phase_filament",
		"quest.refine_phase_filament",
		"quest.assemble_deep_override",
		"quest.unlock_deep_ruin_cache",
		"quest.analyze_deep_core",
		"quest.activate_deep_array",
		"quest.assemble_deep_signal_matrix",
		"quest.deploy_phase_relay_anchor",
		"quest.reenter_phase_frontline",
		"quest.trace_phase_splinters",
		"quest.refine_phase_splinters",
		"quest.inspect_phase_fault_spire",
		"quest.analyze_inner_fault_trace",
		"quest.collect_fault_residue",
		"quest.refine_fault_residue",
		"quest.unlock_phase_well",
		"quest.analyze_phase_well_locator",
		"quest.collect_well_flux",
		"quest.refine_well_flux",
		"quest.inspect_inner_phase_well",
		"quest.analyze_phase_well_core",
		"quest.collect_well_ash",
		"quest.refine_well_ash",
		"quest.assemble_phase_well_pike",
		"quest.inspect_phase_well_sink",
		"quest.analyze_phase_well_heart"
	]
	chamber_anchor_world.set_active_phase_relay_anchor("map_object_instance.phase_return_anchor")
	var chamber_anchor_character := CharacterState.create_default()
	chamber_anchor_character.current_region_id = "region.phase_well_chamber"
	chamber_anchor_character.position = Vector2(2068, 96)
	map.apply_runtime_state(chamber_anchor_world, chamber_anchor_character)
	map.update_current_interactable()
	host._expect_equal(
		map.current_interactable.instance_id,
		"map_object_instance.phase_return_anchor_chamber",
		"phase well chamber anchor should become current interactable in chamber region"
	)
	var chamber_anchor_result := map.try_interact(chamber_anchor_character, chamber_anchor_world)
	host._expect_equal(bool(chamber_anchor_result.get("success", false)), true, "phase well chamber anchor return to outpost should succeed")
	host._expect_equal(
		chamber_anchor_world.active_phase_relay_anchor_id,
		"map_object_instance.phase_return_anchor_chamber",
		"phase well chamber anchor should replace active relay anchor"
	)
	host._expect_equal(
		chamber_anchor_world.get_deployed_phase_relay_anchor_ids(),
		[
			"map_object_instance.phase_return_anchor",
			"map_object_instance.phase_return_anchor_chamber"
		],
		"phase well chamber anchor should keep both deployed anchors"
	)
	host._expect_equal(chamber_anchor_world.current_region_id, "region.outpost_platform", "phase well chamber anchor return updates world region")
	host._expect_equal(chamber_anchor_character.current_region_id, "region.outpost_platform", "phase well chamber anchor return updates character region")
	host._expect_equal(
		map.current_interactable.definition_id,
		"map_object.phase_relay_pad",
		"phase relay pad should become current interactable after returning from chamber anchor"
	)
	var cycle_to_deep_result := map.try_cycle_recipe(chamber_anchor_world)
	host._expect_equal(bool(cycle_to_deep_result.get("success", false)), true, "phase relay pad should cycle back to deep anchor")
	host._expect_equal(
		chamber_anchor_world.active_phase_relay_anchor_id,
		"map_object_instance.phase_return_anchor",
		"phase relay pad cycle should switch active relay anchor back to deep"
	)
	var cycle_back_to_chamber_result := map.try_cycle_recipe(chamber_anchor_world)
	host._expect_equal(bool(cycle_back_to_chamber_result.get("success", false)), true, "phase relay pad should cycle back to chamber anchor")
	host._expect_equal(
		chamber_anchor_world.active_phase_relay_anchor_id,
		"map_object_instance.phase_return_anchor_chamber",
		"phase relay pad cycle should switch active relay anchor back to chamber"
	)
	var chamber_pad_result := map.try_interact(chamber_anchor_character, chamber_anchor_world)
	host._expect_equal(bool(chamber_pad_result.get("success", false)), true, "phase relay pad return to chamber anchor should succeed")
	host._expect_equal(chamber_anchor_world.current_region_id, "region.phase_well_chamber", "phase relay pad should return world to chamber region")
	host._expect_equal(chamber_anchor_character.current_region_id, "region.phase_well_chamber", "phase relay pad should return character to chamber region")
	host._expect_equal(
		map.current_interactable.instance_id,
		"map_object_instance.phase_return_anchor_chamber",
		"phase well chamber anchor should become current interactable after returning from base"
	)
	map.free()
