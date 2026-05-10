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
	host._expect_equal(
		map.current_interactable.definition_id,
		"map_object.phase_return_anchor",
		"phase relay anchor should become current interactable after returning to deep region"
	)
	map.free()
