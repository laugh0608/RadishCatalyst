extends RefCounted

var host


func _init(check_host) -> void:
	host = check_host


func run() -> void:
	_check_counter_delta()
	_check_departure_and_hud_feedback()
	_check_signal_echo_object_feedback()
	_check_save_state_reuses_outfitting_station()


func _check_counter_delta() -> void:
	var counter_runtime := EnemyCounterattackRuntime.new(host.data_registry)
	var basic_world := _create_outer_ring_world(false, false)
	var basic_character := _create_character()
	var basic_enemy := _create_enemy()
	var basic_health_before := basic_character.health
	var basic_protection_before := basic_character.protection
	counter_runtime.apply(basic_enemy, basic_character, basic_world, "region.ruin_outer_ring")
	var basic_health_loss := basic_health_before - basic_character.health
	var basic_protection_loss := basic_protection_before - basic_character.protection

	var calibrated_world := _create_outer_ring_world(true, false)
	var calibrated_character := _create_character()
	var calibrated_enemy := _create_enemy()
	var calibrated_health_before := calibrated_character.health
	var calibrated_protection_before := calibrated_character.protection
	var calibrated_message := counter_runtime.apply(
		calibrated_enemy,
		calibrated_character,
		calibrated_world,
		"region.ruin_outer_ring"
	)
	var calibrated_health_loss := calibrated_health_before - calibrated_character.health
	var calibrated_protection_loss := calibrated_protection_before - calibrated_character.protection

	var maintained_world := _create_outer_ring_world(true, true)
	var maintained_character := _create_character()
	var maintained_enemy := _create_enemy()
	var maintained_health_before := maintained_character.health
	var maintained_protection_before := maintained_character.protection
	var maintained_message := counter_runtime.apply(
		maintained_enemy,
		maintained_character,
		maintained_world,
		"region.ruin_outer_ring"
	)
	var maintained_health_loss := maintained_health_before - maintained_character.health
	var maintained_protection_loss := maintained_protection_before - maintained_character.protection

	host._expect_equal(
		calibrated_health_loss < basic_health_loss,
		true,
		"outer ring module calibration lowers phase guard health pressure"
	)
	host._expect_equal(
		calibrated_protection_loss < basic_protection_loss,
		true,
		"outer ring module calibration lowers phase guard protection pressure"
	)
	host._expect_equal(
		maintained_health_loss < calibrated_health_loss,
		true,
		"outer ring logistics maintenance further lowers phase guard health pressure"
	)
	host._expect_equal(
		maintained_protection_loss < calibrated_protection_loss,
		true,
		"outer ring logistics maintenance further lowers phase guard protection pressure"
	)
	host._expect_text_contains(
		calibrated_message,
		"模块校准已接入",
		"outer ring phase guard counter reads calibration"
	)
	host._expect_text_contains(
		calibrated_message,
		"遗迹外圈相位反击",
		"outer ring phase guard counter names scene pressure"
	)
	host._expect_text_contains(
		maintained_message,
		"后勤维护已接入",
		"outer ring phase guard counter reads logistics maintenance"
	)
	basic_enemy.free()
	calibrated_enemy.free()
	maintained_enemy.free()


func _check_departure_and_hud_feedback() -> void:
	var world := _create_outer_ring_world(true, false)
	var character := _create_character()
	world.current_region_id = "region.outpost_platform"
	var gate_status := DepartureReadinessFormatter.format_departure_gate_status(world, character)
	var gate_next_step := DepartureReadinessFormatter.format_departure_gate_next_step(world, character)
	host._expect_text_contains(gate_status, "遗迹外圈", "departure gate payoff names outer ring")
	host._expect_text_contains(gate_status, "校准收益", "departure gate payoff reads calibration")
	host._expect_text_contains(gate_next_step, "相位守卫", "departure gate next step points to phase guard")

	var hud_text := HudStatusPresenter.new().format_vitals_text(host.data_registry, world, character)
	host._expect_text_contains(hud_text, "出发准备：模块已校准", "HUD keeps calibrated module state")
	host._expect_text_contains(hud_text, "遗迹外圈", "HUD payoff names outer ring pressure")

	var hint_presenter := HudHintPresenter.new()
	var active_hint := hint_presenter.format_onboarding_hint(world, character, "quest.salvage_signal_echo")
	var direction_hint := hint_presenter.format_direction_hint(world, character, "quest.salvage_signal_echo")
	host._expect_text_contains(active_hint, "模块状态", "HUD active hint reads outfitting state")
	host._expect_text_contains(direction_hint, "外圈相位承压", "HUD direction hint reads outer ring module pressure")


func _check_signal_echo_object_feedback() -> void:
	var formatter := InteractionPromptFormatter.new(
		host.data_registry,
		ProcessingSystem.new(host.data_registry),
		BuildSystem.new(host.data_registry)
	)
	var world := _create_outer_ring_world(true, false)
	var character := _create_character()
	var guard_prompt := formatter.format_signal_echo_cache_prompt(world, character)
	host._expect_text_contains(guard_prompt, "相位守卫仍在压制", "signal echo prompt keeps guard blocker")
	host._expect_text_contains(guard_prompt, "模块校准已接入", "signal echo prompt reads calibration")

	world.update_enemy_health("enemy_instance.ruin_phase_guard", 0.0, true)
	var residue_prompt := formatter.format_signal_echo_cache_prompt(world, character)
	host._expect_text_contains(residue_prompt, "污染回波沉积", "signal echo prompt keeps residue step")
	host._expect_text_contains(residue_prompt, "遗迹外圈相位反击", "signal echo prompt names outer ring pressure")

	var gather_system := GatherSystem.new(host.data_registry)
	var basic_world := _create_outer_ring_world(false, false)
	var basic_character := _create_character()
	var basic_protection_before := basic_character.protection
	var basic_result := gather_system.interact_with_object(
		"map_object_instance.outer_ring_echo_residue_cache",
		"map_object.pollution_residue_patch",
		"gather",
		basic_character,
		basic_world
	)
	var basic_loss := basic_protection_before - basic_character.protection

	var calibrated_world := _create_outer_ring_world(true, false)
	var calibrated_character := _create_character()
	var calibrated_protection_before := calibrated_character.protection
	var calibrated_result := gather_system.interact_with_object(
		"map_object_instance.outer_ring_echo_residue_cache",
		"map_object.pollution_residue_patch",
		"gather",
		calibrated_character,
		calibrated_world
	)
	var calibrated_loss := calibrated_protection_before - calibrated_character.protection
	host._expect_equal(bool(basic_result.get("success", false)), true, "basic outer ring echo residue gather succeeds")
	host._expect_equal(
		bool(calibrated_result.get("success", false)),
		true,
		"calibrated outer ring echo residue gather succeeds"
	)
	host._expect_equal(
		calibrated_loss < basic_loss,
		true,
		"outer ring calibration lowers echo residue gather pressure"
	)
	host._expect_text_contains(
		String(calibrated_result.get("message", "")),
		"模块校准已接入",
		"outer ring echo residue gather reads calibration"
	)


func _check_save_state_reuses_outfitting_station() -> void:
	var world := _create_outer_ring_world(true, true)
	var character := _create_character()
	var station_state := world.get_map_object(FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_INSTANCE_ID)
	host._expect_equal(bool(station_state.get(FieldOutfittingRuntime.MODULE_CALIBRATED_FLAG, false)), true, "outer ring pressure uses station calibration flag")
	host._expect_equal(bool(station_state.get(FieldOutfittingRuntime.LOGISTICS_MAINTENANCE_CONFIRMED_FLAG, false)), true, "outer ring pressure uses station maintenance flag")
	var world_data := world.to_dict()
	var character_data := character.to_dict()
	var saved_station: Dictionary = world_data.get("map_objects", {}).get(
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_INSTANCE_ID,
		{}
	)
	host._expect_equal(
		bool(saved_station.get(FieldOutfittingRuntime.MODULE_CALIBRATED_FLAG, false)),
		true,
		"outer ring calibration flag serializes on station"
	)
	host._expect_equal(
		bool(saved_station.get(FieldOutfittingRuntime.LOGISTICS_MAINTENANCE_CONFIRMED_FLAG, false)),
		true,
		"outer ring maintenance flag serializes on station"
	)
	host._expect_equal(
		String(character_data.get("equipment", {}).get("suit_module", "")),
		FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID,
		"outer ring equipped module serializes on character"
	)


func _create_outer_ring_world(calibrated: bool, maintained: bool) -> WorldState:
	var world := WorldState.create_default()
	world.current_region_id = "region.ruin_outer_ring"
	world.unlock_region("region.ruin_outer_ring")
	world.quest_state.completed_quest_ids = [
		"quest.restore_outpost",
		"quest.make_filter_module",
		"quest.unlock_ruin_signal",
		"quest.scout_ruin_outer_ring",
		"quest.stabilize_outer_ring_barrier",
		"quest.secure_outer_ring_signal"
	]
	world.quest_state.active_quest_ids = ["quest.salvage_signal_echo"]
	world.add_base_structure(
		"structure.field_outfitting_station_build_site",
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_REGION_ID,
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_INSTANCE_ID
	)
	if calibrated:
		FieldOutfittingRuntime.mark_module_calibrated(world)
	if maintained:
		FieldOutfittingRuntime.mark_logistics_maintenance_confirmed(world)
	world.ensure_enemy("enemy_instance.ruin_phase_guard", "enemy.ruin_phase_guard", "region.ruin_outer_ring", 48.0)
	return world


func _create_character() -> CharacterState:
	var character := CharacterState.create_default()
	character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	return character


func _create_enemy() -> PrototypeEnemy:
	var enemy := PrototypeEnemy.new()
	enemy.definition_id = "enemy.ruin_phase_guard"
	enemy.instance_id = "enemy_instance.ruin_phase_guard"
	enemy.display_name = "相位守卫"
	return enemy
