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
			"baseline.s20_phase_survey_feedback_ready",
			"baseline.s21_demo_stabilization_core_ready"
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
			_expect_frontline_action_console_interaction_advances(
				loaded_world,
				loaded_character,
				"quest.plan_stability_frontline_action",
				"quest.survey_stability_echo_probe",
				"S16 baseline"
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
			_expect_frontline_action_console_interaction_advances(
				loaded_world,
				loaded_character,
				"quest.confirm_supply_frontline_action",
				"quest.inspect_supply_return_marker",
				"S17 baseline"
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
			_expect_frontline_action_console_interaction_advances(
				loaded_world,
				loaded_character,
				"quest.confirm_route_frontline_action",
				"quest.inspect_route_signal_marker",
				"S18 baseline"
			)
		if baseline_id == "baseline.s19_route_action_feedback_ready":
			host._expect_array_has(
				loaded_world.quest_state.completed_quest_ids,
				"quest.analyze_route_signal_trace",
				"S19 baseline should complete route action feedback"
			)
			host._expect_equal(
				loaded_world.quest_state.active_quest_ids,
				["quest.choose_steady_supply_action", "quest.choose_phase_survey_action", "quest.choose_pressure_clearance_action"],
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
		if baseline_id == "baseline.s21_demo_stabilization_core_ready":
			host._expect_array_has(
				loaded_world.unlocked_region_ids,
				"region.demo_stabilization_core",
				"S21 baseline should unlock demo stabilization core"
			)
			host._expect_array_has(
				loaded_world.quest_state.active_quest_ids,
				"quest.enter_demo_stabilization_core",
				"S21 baseline should activate demo core entry"
			)
			host._expect_array_missing(
				loaded_world.quest_state.completed_quest_ids,
				"quest.write_demo_stabilization_core",
				"S21 baseline should not complete demo core write"
			)
			host._expect_equal(
				loaded_world.current_region_id,
				"region.phase_well_tether",
				"S21 baseline should start before demo core region"
			)
			host._expect_equal(
				loaded_character.current_region_id,
				"region.phase_well_tether",
				"S21 baseline character should start before demo core region"
			)
			host._expect_equal(
				int(loaded_world.get_base_action_state_value(BaseActionDispatchPlan.FRONTLINE_WINDOW_REVIEW_COUNT_KEY, 0)),
				BaseActionDispatchPlan.FRONTLINE_WINDOW_REVIEW_LIMIT + 1,
				"S21 baseline should keep overpressure review archived"
			)
			host._expect_text_contains(
				String(loaded_world.get_base_action_state_value(BaseActionDispatchPlan.FRONTLINE_WINDOW_ARCHIVED_FEEDBACK_KEY, "")),
				"高压窗口反馈已归档",
				"S21 baseline should keep overpressure archive feedback"
			)
	_check_visual_review_checkpoints()


func _check_visual_review_checkpoints() -> void:
	for definition in DevelopmentBaselineCatalog.get_visual_review_checkpoint_definitions():
		var checkpoint_id := String(definition.get("id", ""))
		var label := "visual review checkpoint %s" % checkpoint_id
		if checkpoint_id.is_empty():
			host.failures.append("visual review checkpoint should define id")
			continue

		var result: Dictionary = host.development_baseline_builder.create_visual_review_checkpoint_state(checkpoint_id)
		host._expect_success(result, "%s create" % label)
		if not bool(result.get("success", false)):
			continue

		host._expect_text_contains(
			String(result.get("message", "")),
			"已载入截图定位",
			"%s message" % label
		)
		var returned_definition: Dictionary = result.get("visual_review_checkpoint_definition", {})
		host._expect_equal(
			String(returned_definition.get("id", "")),
			checkpoint_id,
			"%s returned definition" % label
		)

		var world_state: WorldState = result.get("world_state", null)
		var character_state: CharacterState = result.get("character_state", null)
		if world_state == null or character_state == null:
			host.failures.append("%s should return world and character states" % label)
			continue

		var expected_region_id := String(definition.get("region_id", ""))
		var expected_position: Vector2 = definition.get("position", Vector2.ZERO)
		host._expect_equal(world_state.current_region_id, expected_region_id, "%s world region" % label)
		host._expect_equal(character_state.current_region_id, expected_region_id, "%s character region" % label)
		_expect_position_close(character_state.position, expected_position, "%s character position" % label)
		_check_visual_review_checkpoint_runtime_state(checkpoint_id, world_state, character_state, label)

		var slot_id := "visual_review_check_%s" % checkpoint_id.replace(".", "_")
		host._remove_slot_files(slot_id)
		host._expect_success(
			host.save_service.save_game_for_slot(slot_id, world_state, character_state),
			"%s save" % label
		)
		var load_result: Dictionary = host.save_service.load_game_for_slot(slot_id)
		host._expect_success(load_result, "%s load" % label)
		if bool(load_result.get("success", false)):
			var loaded_world: WorldState = load_result["world_state"]
			var loaded_character: CharacterState = load_result["character_state"]
			host._expect_equal(loaded_world.current_region_id, expected_region_id, "%s loaded world region" % label)
			host._expect_equal(loaded_character.current_region_id, expected_region_id, "%s loaded character region" % label)
			_expect_position_close(loaded_character.position, expected_position, "%s loaded character position" % label)
		host._remove_slot_files(slot_id)


func _check_visual_review_checkpoint_runtime_state(
	checkpoint_id: String,
	world_state: WorldState,
	character_state: CharacterState,
	label: String
) -> void:
	match checkpoint_id:
		"visual_review.crystal_collector_output":
			host._expect_equal(world_state.quest_state.active_quest_ids, ["quest.scout_crystal_field"], "%s active quest" % label)
			host._expect_array_missing(world_state.quest_state.completed_quest_ids, "quest.enter_pollution_edge", "%s avoids pollution chain" % label)
			host._expect_equal(world_state.has_base_structure_definition("building.crystal_collector_t1"), true, "%s collector built" % label)
			host._expect_equal(
				bool(world_state.get_map_object("map_object_instance.crystal_collector_output").get("is_gathered", false)),
				false,
				"%s collector output stays ready"
			)
			host._expect_text_contains(
				DemoResourceChainStateFormatter.format_chain_state_line(world_state, character_state),
				"采集设备待收料",
				"%s resource chain line"
			)
		"visual_review.base_handoff":
			host._expect_equal(world_state.quest_state.active_quest_ids, ["quest.calibrate_reactor"], "%s active quest" % label)
			host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.scout_crystal_field", "%s completed scout" % label)
			host._expect_array_missing(world_state.quest_state.completed_quest_ids, "quest.enter_pollution_edge", "%s avoids pollution chain" % label)
			host._expect_equal(world_state.has_base_structure_definition("building.basic_storage"), true, "%s storage built" % label)
			host._expect_equal(world_state.has_base_structure_definition("building.field_outfitting_station"), true, "%s outfitting built" % label)
			host._expect_equal(int(character_state.inventory.items.get("item.crystal_ore", 0)), 0, "%s keeps reactor feed cleared" % label)
			host._expect_text_contains(
				DemoResourceChainStateFormatter.format_chain_state_line(world_state, character_state),
				"外勤整备可用",
				"%s resource chain line"
			)
		"visual_review.pollution_short_challenge":
			host._expect_equal(world_state.quest_state.active_quest_ids, ["quest.enter_pollution_edge"], "%s active quest" % label)
			host._expect_array_has(world_state.quest_state.completed_quest_ids, "quest.expand_treatment_point", "%s completed treatment expansion" % label)
			host._expect_array_missing(world_state.quest_state.completed_quest_ids, "quest.enter_pollution_edge", "%s keeps pollution challenge active" % label)
			host._expect_equal(world_state.has_base_structure_definition("building.pollution_filter"), true, "%s pollution filter built" % label)
			host._expect_equal(
				String(world_state.base_structures.get("structure.pollution_filter_build_site", {}).get("status", "")),
				"completed",
				"%s pollution filter completed"
			)
			host._expect_equal(
				VerticalSliceMapSurface.get_region_id_for_position(character_state.position),
				"region.pollution_edge",
				"%s position remains inside pollution surface region"
			)
			host._expect_text_contains(
				HudMapPresenter.new().format_demo_route_title(world_state, "quest.enter_pollution_edge"),
				"污染排压",
				"%s minimap route title"
			)
			host._expect_equal(
				String(character_state.equipment.get("suit_module", "")),
				FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID,
				"%s filter module equipped"
			)
			host._expect_equal(int(character_state.inventory.items.get("item.resistance_vial_t1", 0)) >= 1, true, "%s vial ready" % label)
			host._expect_equal(int(character_state.inventory.items.get("item.repair_gel", 0)) >= 1, true, "%s repair gel ready" % label)
			host._expect_equal(int(character_state.inventory.items.get("item.polluted_residue", 0)) >= 1, true, "%s residue return primed" % label)
			host._expect_equal(
				bool(world_state.get_enemy("enemy_instance.polluted_skitter").get("is_defeated", true)),
				false,
				"%s keeps local combat pocket active"
			)
		"visual_review.core_station":
			host._expect_array_has(
				world_state.quest_state.completed_quest_ids,
				"quest.write_demo_stabilization_core",
				"%s completed core write quest" % label
			)
			host._expect_equal(
				bool(world_state.get_map_object("map_object_instance.demo_stabilization_recovery_cache").get("is_gathered", false)),
				true,
				"%s marks recovery supply gathered"
			)
			host._expect_equal(
				bool(world_state.get_enemy("enemy_instance.demo_stabilization_guard").get("is_defeated", false)),
				true,
				"%s marks guard pressure cleared"
			)
			host._expect_equal(
				bool(world_state.get_map_object("map_object_instance.demo_stabilization_guard_cache").get("is_gathered", false)),
				true,
				"%s marks guard writeback cache gathered"
			)
			host._expect_equal(
				bool(world_state.get_map_object("map_object_instance.demo_stabilization_core").get("is_sampled", false)),
				true,
				"%s marks core write completed"
			)
			host._expect_equal(
				CoreStabilizationPressureFormatter.has_retest_readout(world_state),
				true,
				"%s marks retest readout recovered"
			)
			host._expect_equal(
				CoreStabilizationPressureFormatter.is_logistics_maintenance_retest_processed(world_state),
				true,
				"%s marks logistics return processed"
			)


func _expect_position_close(actual: Vector2, expected: Vector2, context: String) -> void:
	if actual.distance_to(expected) > 0.1:
		host.failures.append("%s expected %s, got %s" % [context, var_to_str(expected), var_to_str(actual)])


func _expect_frontline_action_console_interaction_advances(
	world_state: WorldState,
	character_state: CharacterState,
	expected_completed_quest_id: String,
	expected_next_quest_id: String,
	label: String
) -> void:
	var interaction_result := GatherSystem.new(host.data_registry).interact_with_object(
		"map_object_instance.frontline_action_console",
		BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID,
		"inspect",
		character_state,
		world_state
	)
	host._expect_success(interaction_result, "%s frontline action console interaction" % label)
	if not bool(interaction_result.get("success", false)):
		return
	var quest_result := QuestRuntime.new(host.data_registry).advance_for_interaction(
		world_state,
		character_state,
		{
			"definition_id": BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID,
			"interaction_type": "inspect"
		},
		interaction_result
	)
	if not bool(quest_result.get("accepted", false)):
		host.failures.append("%s frontline action console should advance quest runtime" % label)
	host._expect_array_has(
		world_state.quest_state.completed_quest_ids,
		expected_completed_quest_id,
		"%s should complete %s through real action console interaction" % [label, expected_completed_quest_id]
	)
	host._expect_array_has(
		world_state.quest_state.active_quest_ids,
		expected_next_quest_id,
		"%s should activate %s through real action console interaction" % [label, expected_next_quest_id]
	)
