extends SceneTree

var failures: Array[String] = []
var data_registry := DataRegistry.new()
var log_presenter: HudLogPresenter


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		log_presenter = HudLogPresenter.new(data_registry)
		_run_checks()

	if failures.is_empty():
		print("Demo action feedback readability checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_gather_sample_and_clear_feedback()
	_check_build_and_processing_feedback()
	_check_enemy_defeat_feedback()
	_check_core_write_and_outpost_feedback()


func _check_gather_sample_and_clear_feedback() -> void:
	var world := WorldState.create_default()
	world.current_region_id = "region.pollution_edge"
	var character := CharacterState.create_default()
	character.current_region_id = "region.pollution_edge"
	var gather_system := GatherSystem.new(data_registry)

	var gather_result := gather_system.interact_with_object(
		"map_object_instance.pollution_residue",
		"map_object.pollution_residue_patch",
		"gather",
		character,
		world
	)
	_expect_success(gather_result, "pollution residue gather succeeds")
	_expect_feedback_text(gather_result, "title", "采集完成", "gather feedback title")
	_expect_feedback_text(gather_result, "status", "已采集", "gather feedback status")
	_expect_feedback_text(gather_result, "destination", "污染沉积物", "gather feedback destination")
	_expect_feedback_text(gather_result, "next_step", "污染过滤器", "gather feedback next step")
	_expect_text_contains(
		log_presenter.format_result_log(gather_result),
		"下一步",
		"gather HUD log keeps next step"
	)
	_expect_equal(
		bool(world.get_map_object("map_object_instance.pollution_residue").get("is_gathered", false)),
		true,
		"gather writes object state"
	)

	var sample_world := WorldState.create_default()
	sample_world.current_region_id = "region.crystal_vein_field"
	sample_world.quest_state.active_quest_ids = ["quest.bring_back_sample"]
	var sample_character := CharacterState.create_default()
	sample_character.current_region_id = "region.crystal_vein_field"
	var sample_result := gather_system.interact_with_object(
		"map_object_instance.anomaly_crystal",
		"map_object.anomaly_crystal",
		"sample",
		sample_character,
		sample_world
	)
	_expect_success(sample_result, "anomaly crystal sample succeeds")
	_expect_feedback_text(sample_result, "title", "采样完成", "sample feedback title")
	_expect_feedback_text(sample_result, "status", "已采样", "sample feedback status")
	_expect_feedback_text(sample_result, "next_step", "基础反应器", "sample feedback next step")

	var clear_world := WorldState.create_default()
	clear_world.current_region_id = "region.pollution_edge"
	var clear_character := CharacterState.create_default()
	clear_character.current_region_id = "region.pollution_edge"
	var clear_result := gather_system.interact_with_object(
		"map_object_instance.rough_ground_north",
		"map_object.rough_ground",
		"clear",
		clear_character,
		clear_world
	)
	_expect_success(clear_result, "rough ground clear succeeds")
	_expect_feedback_text(clear_result, "title", "清障完成", "clear feedback title")
	_expect_feedback_text(clear_result, "status", "已清理", "clear feedback status")
	_expect_feedback_text(clear_result, "next_step", "基础地基", "clear feedback next step")
	_expect_equal(
		bool(clear_world.get_map_object("map_object_instance.rough_ground_north").get("is_cleared", false)),
		true,
		"clear writes object state"
	)


func _check_build_and_processing_feedback() -> void:
	var build_world := WorldState.create_default()
	build_world.current_region_id = "region.outpost_platform"
	var build_character := CharacterState.create_default()
	build_character.current_region_id = "region.outpost_platform"
	build_character.inventory.add_item("item.salvage_scrap", 1)
	var build_result := BuildSystem.new(data_registry).build_structure(
		"map_object_instance.field_outfitting_station_build_site",
		"building.field_outfitting_station",
		build_character,
		build_world
	)
	_expect_success(build_result, "field outfitting station build succeeds")
	_expect_feedback_text(build_result, "title", "建造完成", "build feedback title")
	_expect_feedback_text(build_result, "status", "已建成", "build feedback status")
	_expect_feedback_text(build_result, "destination", "基地后勤区", "build feedback destination")
	_expect_feedback_text(build_result, "next_step", "基础过滤模块", "build feedback next step")
	_expect_text_contains(
		log_presenter.format_result_log(build_result),
		"建造完成",
		"build HUD log keeps structured feedback"
	)

	var processing_world := WorldState.create_default()
	processing_world.quest_state.unlock_effect("recipe.process_crystal_ore")
	var processing_character := CharacterState.create_default()
	processing_character.inventory.add_item("item.crystal_ore", 3)
	var processing := ProcessingSystem.new(data_registry)
	var started := processing.process_recipe("recipe.process_crystal_ore", processing_character, processing_world)
	_expect_success(started, "crystal ore processing starts")
	_expect_feedback_text(started, "title", "加工已启动", "processing start feedback title")
	_expect_feedback_text(started, "status", "加工中", "processing start feedback status")

	var completed_results := processing.advance_processing(99.0, processing_character, processing_world)
	_expect_equal(completed_results.size(), 1, "processing completion result exists")
	if completed_results.is_empty():
		return
	var completed := completed_results[0]
	_expect_success(completed, "crystal ore processing completes")
	_expect_feedback_text(completed, "title", "加工完成", "processing completion feedback title")
	_expect_feedback_text(completed, "destination", "背包", "processing completion destination")
	_expect_text_contains(
		log_presenter.format_result_log(completed),
		"下一步",
		"processing completion HUD log keeps next step"
	)


func _check_enemy_defeat_feedback() -> void:
	var map := VerticalSliceMap.new()
	var enemy := PrototypeEnemy.new()
	enemy.display_name = "核心阶段守卫"
	enemy.definition_id = "enemy.demo_stabilization_guard"
	var result := map._enemy_defeat_result(
		enemy,
		"获得：核心写入校验片 x1。",
		"核心阶段守卫已被击败；先回收守卫后的回写缓存，再写入核心稳定设备。"
	)
	_expect_success(result, "demo guard defeat result succeeds")
	_expect_feedback_text(result, "title", "击败", "enemy feedback title")
	_expect_feedback_text(result, "status", "已击败", "enemy feedback status")
	_expect_feedback_text(result, "destination", "核心写入校验片", "enemy feedback destination")
	_expect_feedback_text(result, "next_step", "回写缓存", "enemy feedback next step")
	_expect_text_contains(
		log_presenter.format_result_log(result),
		"击败",
		"enemy HUD log keeps structured feedback"
	)
	enemy.free()
	map.free()


func _check_core_write_and_outpost_feedback() -> void:
	var baseline := DevelopmentBaselineBuilder.new(data_registry).create_baseline_state(
		"baseline.s21_demo_stabilization_core_ready"
	)
	_expect_success(baseline, "S21 baseline creates core write checkpoint")
	if not bool(baseline.get("success", false)):
		return
	var world: WorldState = baseline.get("world_state", null)
	var character: CharacterState = baseline.get("character_state", null)
	if world == null or character == null:
		failures.append("S21 baseline should return world and character states")
		return
	_prepare_core_write_state(world, character)
	var gather_system := GatherSystem.new(data_registry)

	var core_result := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"inspect",
		character,
		world
	)
	_expect_success(core_result, "demo stabilization core write succeeds")
	_expect_feedback_text(core_result, "title", "核心写入完成", "core write feedback title")
	_expect_feedback_text(core_result, "status", "核心稳定设备已写入", "core write feedback status")
	_expect_feedback_text(core_result, "destination", "Demo 完成成果", "core write feedback destination")
	_expect_feedback_text(core_result, "next_step", "前哨核心", "core write feedback next step")
	_expect_equal(
		bool(world.get_map_object("map_object_instance.demo_stabilization_core").get("is_sampled", false)),
		true,
		"core write writes object state"
	)

	world.current_region_id = "region.outpost_platform"
	character.current_region_id = "region.outpost_platform"
	world.quest_state.complete_quest("quest.write_demo_stabilization_core")
	character.health = 73.0
	character.protection = 62.0
	var outpost_result := gather_system.interact_with_object(
		"map_object_instance.outpost_core",
		"building.outpost_core",
		"outpost_core",
		character,
		world
	)
	_expect_success(outpost_result, "outpost core refit succeeds after core write")
	_expect_feedback_text(outpost_result, "title", "前哨整备完成", "outpost feedback title")
	_expect_feedback_text(outpost_result, "status", "出发检查", "outpost feedback status")
	_expect_feedback_text(outpost_result, "destination", "前哨核心", "outpost feedback destination")
	_expect_feedback_text(outpost_result, "next_step", "HUD / 地图", "outpost feedback next step")
	_expect_text_contains(
		log_presenter.format_result_log(outpost_result),
		"前哨整备完成",
		"outpost HUD log keeps structured feedback"
	)


func _prepare_core_write_state(world: WorldState, character: CharacterState) -> void:
	world.current_region_id = "region.demo_stabilization_core"
	character.current_region_id = "region.demo_stabilization_core"
	world.unlock_region("region.demo_stabilization_core")
	world.quest_state.active_quest_ids.clear()
	world.quest_state.activate_quest("quest.write_demo_stabilization_core")
	world.quest_state.set_objective_progress(
		"quest.write_demo_stabilization_core",
		"gather_item",
		"item.core_write_charge",
		1.0
	)
	world.ensure_enemy(
		"enemy_instance.demo_stabilization_guard",
		"enemy.demo_stabilization_guard",
		"region.demo_stabilization_core",
		156.0
	)
	world.update_enemy_health("enemy_instance.demo_stabilization_guard", 0.0, true)
	world.ensure_map_object(
		"map_object_instance.demo_stabilization_guard_cache",
		"map_object.demo_stabilization_guard_cache",
		"region.demo_stabilization_core"
	)
	world.set_map_object_flag("map_object_instance.demo_stabilization_guard_cache", "is_gathered", true)
	world.ensure_map_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"region.demo_stabilization_core"
	)
	character.inventory.add_item("item.core_write_charge", 1)
	character.inventory.add_item("item.resistance_vial_t1", 1)


func _expect_success(result: Dictionary, context: String) -> void:
	_expect_equal(bool(result.get("success", false)), true, context)
	if not bool(result.get("success", false)):
		failures.append("%s: message '%s'" % [context, String(result.get("message", ""))])


func _expect_feedback_text(result: Dictionary, key: String, expected: String, context: String) -> void:
	var feedback: Dictionary = result.get("success_feedback", {})
	if feedback.is_empty():
		failures.append("%s: expected success feedback, got '%s'" % [context, str(result)])
		return
	_expect_text_contains(String(feedback.get(key, "")), expected, context)


func _expect_equal(actual, expected, context: String) -> void:
	if actual == expected:
		return
	failures.append("%s: expected %s, got %s" % [context, str(expected), str(actual)])


func _expect_text_contains(text: String, expected: String, context: String) -> void:
	if text.find(expected) >= 0:
		return
	failures.append("%s: expected text to contain '%s', got '%s'" % [context, expected, text])


func _cleanup() -> void:
	if data_registry != null:
		data_registry.free()
