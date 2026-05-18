extends RefCounted

var host


func _init(check_host) -> void:
	host = check_host


func run() -> void:
	for definition in host.development_baseline_builder.get_baseline_definitions():
		var baseline_id := String(definition.get("id", ""))
		var code := String(definition.get("code", "baseline")).to_lower()
		var slot_id := "baseline_check_%s" % code
		host._remove_slot_files(slot_id)
		var baseline_result: Dictionary = host.development_baseline_builder.create_baseline_state(baseline_id)
		host._expect_success(baseline_result, "create %s development baseline" % code)
		if not bool(baseline_result.get("success", false)):
			continue

		var world_state: WorldState = baseline_result.get("world_state", null)
		var character_state: CharacterState = baseline_result.get("character_state", null)
		if world_state == null or character_state == null:
			host.failures.append("%s development baseline should return world and character states" % code)
			continue

		host._expect_success(
			host.save_service.save_game_for_slot(slot_id, world_state, character_state),
			"save %s development baseline" % code
		)
		var load_result: Dictionary = host.save_service.load_game_for_slot(slot_id)
		host._expect_success(load_result, "load %s development baseline" % code)
		if not bool(load_result.get("success", false)):
			continue

		var loaded_world: WorldState = load_result["world_state"]
		var loaded_character: CharacterState = load_result["character_state"]
		host._expect_equal(loaded_world.current_region_id, world_state.current_region_id, "%s baseline world region" % code)
		host._expect_equal(loaded_character.current_region_id, character_state.current_region_id, "%s baseline character region" % code)
		host._expect_equal(loaded_world.quest_state.active_quest_ids, world_state.quest_state.active_quest_ids, "%s baseline active quests" % code)
		host._expect_equal(loaded_world.quest_state.completed_quest_ids, world_state.quest_state.completed_quest_ids, "%s baseline completed quests" % code)
		var expected_vitals := CharacterProgressionStats.get_expected_vitals(loaded_world.quest_state)
		host._expect_equal(
			loaded_character.max_health,
			float(expected_vitals.get("max_health", 100.0)),
			"%s baseline max health follows progression" % code
		)
		host._expect_equal(
			loaded_character.max_protection,
			float(expected_vitals.get("max_protection", 100.0)),
			"%s baseline max protection follows progression" % code
		)
		if baseline_id == "baseline.s5_phase_relay_online" or baseline_id == "baseline.s6_inner_fault_trace_ready" or baseline_id == "baseline.s7_phase_well_locator_ready" or baseline_id == "baseline.s8_phase_well_core_ready" or baseline_id == "baseline.s9_phase_well_heart_ready":
			host._expect_equal(
				loaded_world.active_phase_relay_anchor_id,
				"map_object_instance.phase_return_anchor",
				"%s baseline active phase relay anchor" % code.to_upper()
			)
			host._expect_equal(
				loaded_world.get_deployed_phase_relay_anchor_ids(),
				["map_object_instance.phase_return_anchor"],
				"%s baseline deployed phase relay anchors" % code.to_upper()
			)
		if baseline_id in [
			"baseline.s10_phase_well_spindle_ready",
			"baseline.s11_phase_well_weave_core_ready",
			"baseline.s12_phase_well_knot_core_ready",
			"baseline.s13_phase_well_anchor_core_ready"
		]:
			host._expect_equal(
				loaded_world.active_phase_relay_anchor_id,
				"map_object_instance.phase_return_anchor_chamber",
				"%s baseline active phase relay anchor" % code.to_upper()
			)
			host._expect_equal(
				loaded_world.get_deployed_phase_relay_anchor_ids(),
				[
					"map_object_instance.phase_return_anchor",
					"map_object_instance.phase_return_anchor_chamber"
				],
				"%s baseline deployed phase relay anchors" % code.to_upper()
			)
		if baseline_id in [
			"baseline.s14_phase_well_anchor_field_stabilized",
			"baseline.s15_phase_well_stability_readout_ready",
			"baseline.s16_phase_well_stability_window_calibrated",
			"baseline.s17_frontline_action_report_ready",
			"baseline.s18_short_action_feedback_ready",
			"baseline.s19_route_action_feedback_ready",
			"baseline.s20_phase_survey_feedback_ready"
		]:
			host._expect_equal(
				loaded_world.active_phase_relay_anchor_id,
				"map_object_instance.phase_return_anchor_tether",
				"%s baseline active phase relay anchor" % code.to_upper()
			)
			host._expect_equal(
				loaded_world.get_deployed_phase_relay_anchor_ids(),
				[
					"map_object_instance.phase_return_anchor",
					"map_object_instance.phase_return_anchor_chamber",
					"map_object_instance.phase_return_anchor_tether"
				],
				"%s baseline deployed phase relay anchors" % code.to_upper()
			)
		if baseline_id == "baseline.s14_phase_well_anchor_field_stabilized":
			host._expect_array_has(
				loaded_world.quest_state.completed_quest_ids,
				"quest.stabilize_phase_well_anchor_field",
				"S14 baseline should complete anchor field stabilization"
			)
			host._expect_equal(
				int(loaded_character.inventory.items.get("item.phase_well_echo_shard", 0)),
				1,
				"S14 baseline should keep phase well echo shard"
			)
			var anchor_field_state := loaded_world.get_map_object("map_object_instance.phase_well_anchor_field")
			host._expect_equal(
				bool(anchor_field_state.get("anchor_field_stabilized", false)),
				true,
				"S14 baseline should keep anchor field stabilized"
			)
		if baseline_id == "baseline.s15_phase_well_stability_readout_ready":
			host._expect_array_has(
				loaded_world.quest_state.completed_quest_ids,
				"quest.analyze_phase_well_echo_shard",
				"S15 baseline should complete echo shard analysis"
			)
			host._expect_equal(
				loaded_world.quest_state.active_quest_ids,
				["quest.calibrate_phase_well_stability_window"],
				"S15 baseline should activate stability window calibration"
			)
			host._expect_equal(
				int(loaded_character.inventory.items.get("item.phase_well_stability_readout", 0)),
				1,
				"S15 baseline should keep phase well stability readout"
			)
			var readout_anchor_field_state := loaded_world.get_map_object("map_object_instance.phase_well_anchor_field")
			host._expect_equal(
				bool(readout_anchor_field_state.get("anchor_field_stabilized", false)),
				true,
				"S15 baseline should keep anchor field stabilized"
			)
		if baseline_id == "baseline.s16_phase_well_stability_window_calibrated":
			host._expect_array_has(
				loaded_world.quest_state.completed_quest_ids,
				"quest.calibrate_phase_well_stability_window",
				"S16 baseline should complete stability window calibration"
			)
			host._expect_equal(
				loaded_world.quest_state.active_quest_ids,
				["quest.plan_stability_frontline_action"],
				"S16 baseline should activate frontline action confirmation"
			)
			for node_instance_id in [
				"map_object_instance.phase_well_stability_node_west",
				"map_object_instance.phase_well_stability_node_core",
				"map_object_instance.phase_well_stability_node_east"
			]:
				var node_state := loaded_world.get_map_object(node_instance_id)
				host._expect_equal(
					bool(node_state.get("stability_node_calibrated", false)),
					true,
					"S16 baseline should keep %s calibrated" % node_instance_id
				)
		if baseline_id == "baseline.s17_frontline_action_report_ready":
			host._expect_array_has(
				loaded_world.quest_state.completed_quest_ids,
				"quest.analyze_stability_echo_sample",
				"S17 baseline should complete stability echo report"
			)
			host._expect_equal(
				loaded_world.quest_state.active_quest_ids,
				["quest.confirm_supply_frontline_action"],
				"S17 baseline should activate supply frontline action"
			)
			host._expect_equal(
				int(loaded_character.inventory.items.get("item.frontline_action_report", 0)),
				1,
				"S17 baseline should keep frontline action report"
			)
			host._expect_equal(
				int(loaded_character.inventory.items.get("item.repair_gel", 0)),
				2,
				"S17 baseline should keep base feedback repair gel"
			)
			host._expect_equal(
				int(loaded_character.inventory.items.get("item.resistance_vial_t1", 0)),
				2,
				"S17 baseline should keep base feedback resistance vial"
			)
			var console_state := loaded_world.get_map_object("map_object_instance.frontline_action_console")
			host._expect_equal(
				bool(console_state.get("is_sampled", false)),
				true,
				"S17 baseline should keep frontline action console confirmed"
			)
			var probe_state := loaded_world.get_map_object("map_object_instance.stability_echo_probe")
			host._expect_equal(
				bool(probe_state.get("is_sampled", false)),
				true,
				"S17 baseline should keep stability echo probe sampled"
			)
		if baseline_id == "baseline.s18_short_action_feedback_ready":
			host._expect_array_has(
				loaded_world.quest_state.completed_quest_ids,
				"quest.analyze_supply_return_trace",
				"S18 baseline should complete short action feedback"
			)
			host._expect_equal(
				loaded_world.quest_state.active_quest_ids,
				["quest.confirm_route_frontline_action"],
				"S18 baseline should activate route frontline action"
			)
			host._expect_equal(
				int(loaded_character.inventory.items.get("item.short_action_feedback", 0)),
				1,
				"S18 baseline should keep short action feedback"
			)
			host._expect_equal(
				int(loaded_character.inventory.items.get("item.repair_gel", 0)),
				3,
				"S18 baseline should keep second feedback repair gel"
			)
			host._expect_equal(
				int(loaded_character.inventory.items.get("item.resistance_vial_t1", 0)),
				3,
				"S18 baseline should keep second feedback resistance vial"
			)
			var supply_console_state := loaded_world.get_map_object("map_object_instance.frontline_action_console")
			host._expect_equal(
				bool(supply_console_state.get("is_sampled", false)),
				true,
				"S18 baseline should keep unified frontline action console confirmed"
			)
			var supply_marker_state := loaded_world.get_map_object("map_object_instance.supply_return_marker")
			host._expect_equal(
				bool(supply_marker_state.get("is_sampled", false)),
				true,
				"S18 baseline should keep supply marker sampled"
			)
		if baseline_id == "baseline.s19_route_action_feedback_ready":
			host._expect_array_has(
				loaded_world.quest_state.completed_quest_ids,
				"quest.analyze_route_signal_trace",
				"S19 baseline should complete route action feedback"
			)
			host._expect_equal(
				loaded_world.quest_state.active_quest_ids,
				["quest.choose_steady_supply_action", "quest.choose_phase_survey_action"],
				"S19 baseline should activate base action choices"
			)
			host._expect_equal(
				int(loaded_character.inventory.items.get("item.route_action_feedback", 0)),
				1,
				"S19 baseline should keep route action feedback"
			)
			host._expect_equal(
				int(loaded_character.inventory.items.get("item.repair_gel", 0)),
				4,
				"S19 baseline should keep third feedback repair gel"
			)
			host._expect_equal(
				int(loaded_character.inventory.items.get("item.resistance_vial_t1", 0)),
				4,
				"S19 baseline should keep third feedback resistance vial"
			)
			var route_console_state := loaded_world.get_map_object("map_object_instance.frontline_action_console")
			host._expect_equal(
				bool(route_console_state.get("is_sampled", false)),
				true,
				"S19 baseline should keep unified frontline action console confirmed"
			)
			var route_marker_state := loaded_world.get_map_object("map_object_instance.route_signal_marker")
			host._expect_equal(
				bool(route_marker_state.get("is_sampled", false)),
				true,
				"S19 baseline should keep route marker sampled"
			)
		if baseline_id == "baseline.s20_phase_survey_feedback_ready":
			host._expect_array_has(
				loaded_world.quest_state.completed_quest_ids,
				"quest.analyze_phase_survey_trace",
				"S20 baseline should complete phase survey feedback"
			)
			host._expect_array_has(
				loaded_world.quest_state.completed_quest_ids,
				"quest.choose_phase_survey_action",
				"S20 baseline should choose phase survey action"
			)
			host._expect_equal(
				loaded_world.quest_state.active_quest_ids,
				[],
				"S20 baseline should not keep an active quest"
			)
			host._expect_equal(
				int(loaded_character.inventory.items.get("item.phase_survey_feedback", 0)),
				1,
				"S20 baseline should keep phase survey feedback"
			)
			host._expect_equal(
				int(loaded_character.inventory.items.get("item.resistance_vial_t1", 0)),
				5,
				"S20 baseline should keep survey feedback resistance vial"
			)
			host._expect_equal(
				BaseActionDispatchPlan.get_survey_intel_status(loaded_world),
				BaseActionDispatchPlan.STATUS_READY,
				"S20 baseline should keep survey route intel ready"
			)
			host._expect_equal(
				BaseActionDispatchPlan.get_route_target_region_id(loaded_world),
				"region.phase_well_tether",
				"S20 baseline should keep revealed survey target"
			)
			var survey_console_state := loaded_world.get_map_object("map_object_instance.base_survey_choice_console")
			host._expect_equal(
				bool(survey_console_state.get("is_sampled", false)),
				true,
				"S20 baseline should keep survey choice confirmed"
			)
			for survey_node_id in [
				"map_object_instance.phase_survey_node_west",
				"map_object_instance.phase_survey_node_east"
			]:
				var survey_node_state := loaded_world.get_map_object(survey_node_id)
				host._expect_equal(
					bool(survey_node_state.get("is_sampled", false)),
					true,
					"S20 baseline should keep %s sampled" % survey_node_id
				)
