extends SceneTree

var failures: Array[String] = []
var data_registry := DataRegistry.new()


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		_run_checks()

	if failures.is_empty():
		print("Demo field loop payoff checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_formatter_tracks_base_payoff()
	_check_outfitting_prompt_and_confirmation()
	_check_pressure_payoff_runtime()
	_check_payoff_state_roundtrip()


func _check_formatter_tracks_base_payoff() -> void:
	var world := _create_payoff_world()
	var character := _create_payoff_character()

	var hud_lines := DemoFieldLoopPayoffFormatter.format_hud_summary(world, character)
	_expect_array_text_contains(hud_lines, "外勤收益兑现", "field loop HUD names payoff readiness")
	_expect_array_text_contains(hud_lines, "出发整备台确认收益整备", "field loop HUD points to outfitting station")
	_expect_equal(
		DemoFieldLoopPayoffFormatter.can_confirm_payoff(world, character),
		true,
		"field loop payoff is confirmable after base analysis"
	)


func _check_outfitting_prompt_and_confirmation() -> void:
	var world := _create_payoff_world()
	var character := _create_payoff_character()
	var prompt_formatter := InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)

	var prompt := prompt_formatter.format_outfitting_station_prompt(character, world)
	_expect_text_contains(prompt, "外勤收益兑现", "outfitting prompt shows field loop payoff")
	_expect_text_contains(prompt, "E 确认外勤收益整备", "outfitting prompt exposes field loop action")

	var result := GatherSystem.new(data_registry).interact_with_object(
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_INSTANCE_ID,
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		"inspect",
		character,
		world
	)
	_expect_equal(bool(result.get("success", false)), true, "field loop payoff confirmation succeeds")
	_expect_equal(
		bool(result.get("field_loop_payoff_confirmed", false)),
		true,
		"field loop payoff result exposes progression marker"
	)
	_expect_text_contains(
		String(result.get("message", "")),
		"出发整备台完成外勤收益兑现",
		"field loop payoff result explains base payoff"
	)
	_expect_equal(
		FieldOutfittingRuntime.is_field_loop_payoff_confirmed(world),
		true,
		"field loop payoff writes outfitting station state"
	)

	var confirmed_hud := HudStatusPresenter.new().format_vitals_text(data_registry, world, character)
	_expect_text_contains(confirmed_hud, "外勤收益：回波匣解析已接入整备台", "HUD shows confirmed field loop payoff")
	_expect_text_contains(confirmed_hud, "外勤收益已兑现", "HUD compact state shows confirmed payoff")


func _check_pressure_payoff_runtime() -> void:
	var baseline_world := _create_payoff_world()
	var baseline_character := _create_payoff_character()
	var payoff_world := _create_payoff_world()
	var payoff_character := _create_payoff_character()
	DemoFieldLoopPayoffFormatter.mark_payoff_confirmed(payoff_world)

	var gather_system := GatherSystem.new(data_registry)
	baseline_world.current_region_id = "region.ruin_outer_ring"
	baseline_character.current_region_id = "region.ruin_outer_ring"
	payoff_world.current_region_id = "region.ruin_outer_ring"
	payoff_character.current_region_id = "region.ruin_outer_ring"

	var baseline_result := gather_system.interact_with_object(
		DemoFieldLoopPayoffFormatter.OUTER_RING_ECHO_RESIDUE_INSTANCE_ID,
		"map_object.pollution_residue_patch",
		"gather",
		baseline_character,
		baseline_world
	)
	var payoff_result := gather_system.interact_with_object(
		DemoFieldLoopPayoffFormatter.OUTER_RING_ECHO_RESIDUE_INSTANCE_ID,
		"map_object.pollution_residue_patch",
		"gather",
		payoff_character,
		payoff_world
	)
	_expect_equal(bool(baseline_result.get("success", false)), true, "baseline echo residue gather succeeds")
	_expect_equal(bool(payoff_result.get("success", false)), true, "payoff echo residue gather succeeds")
	_expect_less_than(
		100.0 - payoff_character.protection,
		100.0 - baseline_character.protection,
		"field loop payoff lowers pollution gather pressure"
	)
	_expect_text_contains(
		String(payoff_result.get("message", "")),
		"外勤收益整备",
		"payoff gather feedback names field loop payoff"
	)


func _check_payoff_state_roundtrip() -> void:
	var world := _create_payoff_world()
	var character := _create_payoff_character()
	DemoFieldLoopPayoffFormatter.mark_payoff_confirmed(world)

	var restored_world := WorldState.from_dict(world.to_dict())
	_expect_equal(
		DemoFieldLoopPayoffFormatter.is_payoff_confirmed(restored_world),
		true,
		"field loop payoff survives world state roundtrip"
	)

	var save_world := _create_save_validation_world()
	var save_error := SaveContentValidator.new(data_registry).validate_save_content({
		"save_schema_version": SaveService.SAVE_SCHEMA_VERSION,
		"game_version": SaveService.GAME_VERSION,
		"world": save_world.to_dict(),
		"character": character.to_dict()
	})
	_expect_equal(save_error, "", "save validator accepts field loop payoff state")


func _create_payoff_world() -> WorldState:
	var world := WorldState.create_default()
	world.current_region_id = "region.outpost_platform"
	for quest_id in [
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
		"quest.analyze_deep_signal"
	]:
		world.quest_state.complete_quest(quest_id)
	world.add_base_structure(
		"structure.field_outfitting_station_build_site",
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		"region.outpost_platform",
		"map_object_instance.field_outfitting_station_build_site"
	)
	var outfitting_site := world.ensure_map_object(
		"map_object_instance.field_outfitting_station_build_site",
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		"region.outpost_platform"
	)
	outfitting_site["is_built"] = true
	outfitting_site["built_definition_id"] = FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID
	world.ensure_map_object(
		DemoFieldLoopPayoffFormatter.SIGNAL_ECHO_CACHE_INSTANCE_ID,
		"map_object.signal_echo_cache",
		"region.ruin_outer_ring"
	)["is_sampled"] = true
	return world


func _create_payoff_character() -> CharacterState:
	var character := CharacterState.create_default()
	character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	return character


func _create_save_validation_world() -> WorldState:
	var world := WorldState.create_default()
	world.add_base_structure(
		"structure.field_outfitting_station_build_site",
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		"region.outpost_platform",
		"map_object_instance.field_outfitting_station_build_site"
	)
	var outfitting_site := world.ensure_map_object(
		"map_object_instance.field_outfitting_station_build_site",
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		"region.outpost_platform"
	)
	outfitting_site["is_built"] = true
	outfitting_site["built_definition_id"] = FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID
	DemoFieldLoopPayoffFormatter.mark_payoff_confirmed(world)
	return world


func _expect_equal(actual, expected, context: String) -> void:
	if actual == expected:
		return
	failures.append("%s: expected %s, got %s" % [context, str(expected), str(actual)])


func _expect_less_than(actual: float, expected: float, context: String) -> void:
	if actual < expected:
		return
	failures.append("%s: expected %s to be less than %s" % [context, str(actual), str(expected)])


func _expect_text_contains(text: String, expected: String, context: String) -> void:
	if text.find(expected) >= 0:
		return
	failures.append("%s: expected text to contain '%s', got '%s'" % [context, expected, text])


func _expect_array_text_contains(lines: Array[String], expected: String, context: String) -> void:
	_expect_text_contains("\n".join(lines), expected, context)


func _cleanup() -> void:
	data_registry.free()
