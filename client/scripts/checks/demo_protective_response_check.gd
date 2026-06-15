extends SceneTree

var failures: Array[String] = []
var data_registry := DataRegistry.new()


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		_run_checks()

	if failures.is_empty():
		print("Demo protective response checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_outfitting_prompt_and_confirmation()
	_check_calibration_keeps_priority()
	_check_counterattack_consumes_response()
	_check_triggered_response_requires_refit_before_reconfirm()


func _check_outfitting_prompt_and_confirmation() -> void:
	var world := _create_response_world()
	var character := _create_response_character()
	var formatter := _create_prompt_formatter()

	var prompt := formatter.format_outfitting_station_prompt(character, world)
	_expect_text_contains(prompt, "防护响应：可确认", "outfitting prompt shows protective response ready to confirm")
	_expect_text_contains(prompt, "操作：E 确认防护响应", "outfitting prompt exposes protective response action")

	var result := GatherSystem.new(data_registry).interact_with_object(
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_INSTANCE_ID,
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		"inspect",
		character,
		world
	)
	_expect_equal(bool(result.get("success", false)), true, "protective response confirmation succeeds")
	_expect_equal(bool(result.get("protective_response_ready", false)), true, "protective response result marker exists")
	_expect_equal(FieldOutfittingRuntime.is_protective_response_ready(world), true, "protective response ready state is stored")
	_expect_equal(FieldOutfittingRuntime.has_protective_response_triggered(world), false, "protective response starts untriggered")
	_expect_text_contains(String(result.get("message", "")), "基础防护服、基础过滤模块、修复凝胶和抗污染药剂", "protective response result names inputs")

	var hud_text := HudStatusPresenter.new().format_vitals_text(data_registry, world, character)
	_expect_text_contains(hud_text, "防护响应待命", "HUD shows protective response standby")
	var departure_status := DepartureReadinessFormatter.format_departure_gate_status(world, character)
	_expect_text_contains(departure_status, "防护响应待命", "departure gate status shows protective response standby")


func _check_calibration_keeps_priority() -> void:
	var world := _create_response_world()
	var character := _create_response_character()
	character.inventory.add_ref("item.crystal_ore", FieldOutfittingRuntime.MODULE_CALIBRATION_CRYSTAL_COST)
	character.inventory.add_ref("item.salvage_scrap", FieldOutfittingRuntime.MODULE_CALIBRATION_SCRAP_COST)
	var formatter := _create_prompt_formatter()

	var prompt := formatter.format_outfitting_station_prompt(character, world)
	_expect_text_contains(prompt, "操作：E 校准基础过滤模块", "calibration prompt keeps priority over protective response")
	var result := GatherSystem.new(data_registry).interact_with_object(
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_INSTANCE_ID,
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		"inspect",
		character,
		world
	)
	_expect_equal(bool(result.get("outfitting_module_calibrated", false)), true, "calibration still executes before protective response")
	_expect_equal(FieldOutfittingRuntime.is_protective_response_ready(world), false, "protective response is not armed during calibration")


func _check_counterattack_consumes_response() -> void:
	var counter_runtime := EnemyCounterattackRuntime.new(data_registry)
	var plain_world := _create_response_world()
	var plain_character := _create_response_character()
	var plain_enemy := _create_polluted_enemy("enemy_instance.protective_response_plain")
	var plain_health_before := plain_character.health
	var plain_protection_before := plain_character.protection
	counter_runtime.apply(plain_enemy, plain_character, plain_world, "region.pollution_edge")
	var plain_health_loss := plain_health_before - plain_character.health
	var plain_protection_loss := plain_protection_before - plain_character.protection

	var protected_world := _create_response_world()
	var protected_character := _create_response_character()
	var protected_enemy := _create_polluted_enemy("enemy_instance.protective_response_ready")
	FieldOutfittingRuntime.mark_protective_response_ready(protected_world)
	var protected_health_before := protected_character.health
	var protected_protection_before := protected_character.protection
	var protected_message := counter_runtime.apply(
		protected_enemy,
		protected_character,
		protected_world,
		"region.pollution_edge"
	)
	var protected_health_loss := protected_health_before - protected_character.health
	var protected_protection_loss := protected_protection_before - protected_character.protection

	_expect_equal(protected_health_loss < plain_health_loss, true, "protective response lowers health pressure")
	_expect_equal(protected_protection_loss < plain_protection_loss, true, "protective response lowers protection pressure")
	_expect_equal(FieldOutfittingRuntime.is_protective_response_ready(protected_world), false, "protective response is consumed")
	_expect_equal(FieldOutfittingRuntime.has_protective_response_triggered(protected_world), true, "protective response triggered state persists")
	_expect_text_contains(protected_message, "防护响应已触发", "counter feedback names protective response trigger")
	_expect_text_contains(protected_message, "生命 / 防护承压下降", "counter feedback explains pressure reduction")
	plain_enemy.free()
	protected_enemy.free()


func _check_triggered_response_requires_refit_before_reconfirm() -> void:
	var world := _create_response_world()
	var character := _create_response_character()
	var enemy := _create_polluted_enemy("enemy_instance.protective_response_refit")
	FieldOutfittingRuntime.mark_protective_response_ready(world)
	EnemyCounterattackRuntime.new(data_registry).apply(enemy, character, world, "region.pollution_edge")
	enemy.free()

	var formatter := _create_prompt_formatter()
	var spent_prompt := formatter.format_outfitting_station_prompt(character, world)
	_expect_text_contains(spent_prompt, "防护响应：已触发", "spent response prompt names triggered state")
	_expect_text_contains(spent_prompt, "先回前哨核心补给", "spent response prompt routes to outpost refit")
	var spent_result := GatherSystem.new(data_registry).interact_with_object(
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_INSTANCE_ID,
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		"inspect",
		character,
		world
	)
	_expect_equal(bool(spent_result.get("protective_response_ready", false)), false, "spent response cannot rearm before refit")

	character.restore_vitals_to_full()
	var rearm_result := GatherSystem.new(data_registry).interact_with_object(
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_INSTANCE_ID,
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		"inspect",
		character,
		world
	)
	_expect_equal(bool(rearm_result.get("protective_response_ready", false)), true, "protective response rearms after outpost refit")
	_expect_equal(FieldOutfittingRuntime.is_protective_response_ready(world), true, "rearmed response is stored")
	_expect_equal(FieldOutfittingRuntime.has_protective_response_triggered(world), false, "rearmed response clears triggered flag")


func _create_response_world() -> WorldState:
	var world := WorldState.create_default()
	world.current_region_id = "region.outpost_platform"
	world.quest_state.complete_quest("quest.restore_outpost")
	world.quest_state.complete_quest("quest.enter_pollution_edge")
	world.add_base_structure(
		"structure.basic_storage_build_site",
		"building.basic_storage",
		"region.outpost_platform",
		"map_object_instance.basic_storage_build_site"
	)
	world.add_base_structure(
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.outpost_platform",
		"map_object_instance.pollution_filter_build_site"
	)
	world.add_base_structure(
		"structure.field_outfitting_station_build_site",
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		"region.outpost_platform",
		"map_object_instance.field_outfitting_station_build_site"
	)
	return world


func _create_response_character() -> CharacterState:
	var character := CharacterState.create_default()
	character.current_region_id = "region.outpost_platform"
	character.equipment["suit"] = "equipment.basic_suit"
	character.equipment["suit_module"] = FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID
	character.inventory.items[DepartureSupplyRuntime.REPAIR_GEL_ID] = 1
	character.inventory.items[DepartureSupplyRuntime.RESISTANCE_VIAL_ID] = 1
	character.health = character.max_health
	character.protection = character.max_protection
	return character


func _create_polluted_enemy(instance_id: String) -> PrototypeEnemy:
	var enemy := PrototypeEnemy.new()
	enemy.definition_id = "enemy.polluted_skitter"
	enemy.instance_id = instance_id
	enemy.display_name = "污染跃蛛"
	return enemy


func _create_prompt_formatter() -> InteractionPromptFormatter:
	return InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)


func _expect_equal(actual, expected, message: String) -> void:
	if actual == expected:
		return
	failures.append("%s: expected %s, got %s" % [message, str(expected), str(actual)])


func _expect_text_contains(text: String, expected: String, message: String) -> void:
	if text.contains(expected):
		return
	failures.append("%s: missing '%s' in '%s'" % [message, expected, text])


func _cleanup() -> void:
	data_registry.free()
