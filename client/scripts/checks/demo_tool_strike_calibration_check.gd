extends SceneTree

var failures: Array[String] = []
var data_registry := DataRegistry.new()


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		_run_checks()

	if failures.is_empty():
		print("Demo tool strike calibration checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_outfitting_prompt_and_confirmation()
	_check_filter_module_equipping_keeps_priority()
	_check_counterattack_consumes_calibration()
	_check_triggered_calibration_requires_parts_before_reconfirm()


func _check_outfitting_prompt_and_confirmation() -> void:
	var world := _create_tool_world()
	var character := _create_tool_character()
	var formatter := _create_prompt_formatter()

	var prompt := formatter.format_outfitting_station_prompt(character, world)
	_expect_text_contains(prompt, "工具打击校准：可确认", "outfitting prompt shows tool calibration ready")
	_expect_text_contains(prompt, "操作：E 确认工具打击校准", "outfitting prompt exposes tool calibration action")
	_expect_text_contains(
		RecipePurposeHints.format_recipe_goal_hint("recipe.process_crystal_ore", world),
		"工具打击校准",
		"reactor recipe purpose names tool calibration"
	)

	var result := GatherSystem.new(data_registry).interact_with_object(
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_INSTANCE_ID,
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		"inspect",
		character,
		world
	)
	_expect_equal(bool(result.get("success", false)), true, "tool calibration confirmation succeeds")
	_expect_equal(bool(result.get("tool_strike_calibration_ready", false)), true, "tool calibration result marker exists")
	_expect_equal(FieldOutfittingRuntime.is_tool_strike_calibration_ready(world), true, "tool calibration ready state is stored")
	_expect_equal(FieldOutfittingRuntime.has_tool_strike_calibration_triggered(world), false, "tool calibration starts untriggered")
	_expect_equal(int(character.inventory.items.get("item.basic_parts", 0)), 0, "tool calibration consumes basic parts")
	_expect_text_contains(String(result.get("message", "")), "基础零件已写入基础多用工具", "tool calibration result names inputs")

	var hud_text := HudStatusPresenter.new().format_vitals_text(data_registry, world, character)
	_expect_text_contains(hud_text, "工具校准待命", "HUD shows tool calibration standby")
	var departure_status := DepartureReadinessFormatter.format_departure_gate_status(world, character)
	_expect_text_contains(departure_status, "工具校准待命", "departure gate status shows tool calibration standby")


func _check_filter_module_equipping_keeps_priority() -> void:
	var world := _create_tool_world()
	var character := _create_tool_character()
	character.inventory.add_ref(FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID, 1)
	var formatter := _create_prompt_formatter()

	var prompt := formatter.format_outfitting_station_prompt(character, world)
	_expect_text_contains(prompt, "操作：E 装配基础过滤模块", "filter module equip keeps priority over tool calibration")
	var result := GatherSystem.new(data_registry).interact_with_object(
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_INSTANCE_ID,
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		"inspect",
		character,
		world
	)
	_expect_equal(bool(result.get("outfitting_module_enabled", false)), true, "module equip still executes before tool calibration")
	_expect_equal(FieldOutfittingRuntime.is_tool_strike_calibration_ready(world), false, "tool calibration is not armed during module equip")
	_expect_equal(int(character.inventory.items.get("item.basic_parts", 0)), 2, "module equip does not consume tool calibration parts")


func _check_counterattack_consumes_calibration() -> void:
	var counter_runtime := EnemyCounterattackRuntime.new(data_registry)
	var plain_world := _create_tool_world()
	var plain_character := _create_tool_character()
	var plain_enemy := _create_polluted_enemy("enemy_instance.tool_strike_plain")
	var plain_health_before := plain_character.health
	var plain_protection_before := plain_character.protection
	counter_runtime.apply(plain_enemy, plain_character, plain_world, "region.pollution_edge")
	var plain_health_loss := plain_health_before - plain_character.health
	var plain_protection_loss := plain_protection_before - plain_character.protection

	var calibrated_world := _create_tool_world()
	var calibrated_character := _create_tool_character()
	var calibrated_enemy := _create_polluted_enemy("enemy_instance.tool_strike_ready")
	FieldOutfittingRuntime.mark_tool_strike_calibration_ready(calibrated_world)
	var calibrated_health_before := calibrated_character.health
	var calibrated_protection_before := calibrated_character.protection
	var calibrated_message := counter_runtime.apply(
		calibrated_enemy,
		calibrated_character,
		calibrated_world,
		"region.pollution_edge"
	)
	var calibrated_health_loss := calibrated_health_before - calibrated_character.health
	var calibrated_protection_loss := calibrated_protection_before - calibrated_character.protection

	_expect_equal(calibrated_health_loss < plain_health_loss, true, "tool calibration lowers health pressure")
	_expect_equal(calibrated_protection_loss < plain_protection_loss, true, "tool calibration lowers protection pressure")
	_expect_equal(FieldOutfittingRuntime.is_tool_strike_calibration_ready(calibrated_world), false, "tool calibration is consumed")
	_expect_equal(FieldOutfittingRuntime.has_tool_strike_calibration_triggered(calibrated_world), true, "tool calibration triggered state persists")
	_expect_text_contains(calibrated_message, "工具打击校准已触发", "counter feedback names tool calibration trigger")
	_expect_text_contains(calibrated_message, "输出压制", "counter feedback explains output pressure reduction")
	plain_enemy.free()
	calibrated_enemy.free()


func _check_triggered_calibration_requires_parts_before_reconfirm() -> void:
	var world := _create_tool_world()
	var character := _create_tool_character()
	var enemy := _create_polluted_enemy("enemy_instance.tool_strike_reconfirm")
	var confirm_result := GatherSystem.new(data_registry).interact_with_object(
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_INSTANCE_ID,
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		"inspect",
		character,
		world
	)
	_expect_equal(bool(confirm_result.get("tool_strike_calibration_ready", false)), true, "tool calibration initial confirm succeeds")
	EnemyCounterattackRuntime.new(data_registry).apply(enemy, character, world, "region.pollution_edge")
	enemy.free()

	var formatter := _create_prompt_formatter()
	var spent_prompt := formatter.format_outfitting_station_prompt(character, world)
	_expect_text_contains(spent_prompt, "工具打击校准：已触发", "spent tool calibration prompt names triggered state")
	_expect_text_contains(spent_prompt, "先回基础反应器加工基础零件", "spent tool calibration routes to reactor")
	var spent_result := GatherSystem.new(data_registry).interact_with_object(
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_INSTANCE_ID,
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		"inspect",
		character,
		world
	)
	_expect_equal(bool(spent_result.get("tool_strike_calibration_ready", false)), false, "spent calibration cannot rearm before parts")

	character.inventory.add_ref("item.basic_parts", FieldOutfittingRuntime.TOOL_STRIKE_CALIBRATION_BASIC_PARTS_COST)
	var rearm_result := GatherSystem.new(data_registry).interact_with_object(
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_INSTANCE_ID,
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		"inspect",
		character,
		world
	)
	_expect_equal(bool(rearm_result.get("tool_strike_calibration_ready", false)), true, "tool calibration rearms after basic parts")
	_expect_equal(FieldOutfittingRuntime.is_tool_strike_calibration_ready(world), true, "rearmed tool calibration is stored")
	_expect_equal(FieldOutfittingRuntime.has_tool_strike_calibration_triggered(world), false, "rearmed tool calibration clears triggered flag")


func _create_tool_world() -> WorldState:
	var world := WorldState.create_default()
	world.current_region_id = "region.outpost_platform"
	world.quest_state.complete_quest("quest.restore_outpost")
	world.quest_state.complete_quest("quest.enter_pollution_edge")
	world.add_base_structure(
		"structure.field_outfitting_station_build_site",
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		"region.outpost_platform",
		"map_object_instance.field_outfitting_station_build_site"
	)
	return world


func _create_tool_character() -> CharacterState:
	var character := CharacterState.create_default()
	character.current_region_id = "region.outpost_platform"
	character.equipment["tool"] = FieldOutfittingRuntime.BASIC_TOOL_ID
	character.equipment["suit"] = "equipment.basic_suit"
	character.equipment["suit_module"] = ""
	character.inventory.items.clear()
	character.inventory.equipment.clear()
	character.inventory.items["item.basic_parts"] = FieldOutfittingRuntime.TOOL_STRIKE_CALIBRATION_BASIC_PARTS_COST
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
