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
		if baseline_id == "baseline.s10_phase_well_spindle_ready" or baseline_id == "baseline.s11_phase_well_weave_core_ready":
			host._expect_equal(
				loaded_world.active_phase_relay_anchor_id,
				"map_object_instance.phase_return_anchor_chamber",
				"%s baseline active phase relay anchor" % code.to_upper()
			)
