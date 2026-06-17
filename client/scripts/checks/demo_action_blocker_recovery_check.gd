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
		print("Demo action blocker recovery checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_gather_and_sample_prerequisite_blockers()
	_check_already_processed_object_blocker()
	_check_build_blockers()
	_check_processing_blockers()
	_check_supply_blockers()
	_check_core_write_blockers()


func _check_gather_and_sample_prerequisite_blockers() -> void:
	var gather_system := GatherSystem.new(data_registry)

	var sample_world := WorldState.create_default()
	sample_world.current_region_id = "region.crystal_vein_field"
	sample_world.quest_state.active_quest_ids = ["quest.calibrate_reactor"]
	var sample_character := CharacterState.create_default()
	sample_character.current_region_id = "region.crystal_vein_field"
	var sample_result := gather_system.interact_with_object(
		"map_object_instance.anomaly_crystal",
		"map_object.anomaly_crystal",
		"sample",
		sample_character,
		sample_world
	)
	_expect_failure(sample_result, "anomaly crystal sample should be blocked before quest gate")
	_expect_blocker_detail(sample_result, "反应器校准件", "sample prerequisite blocker detail")
	_expect_text_contains(
		HudStatusPresenter.new().format_status_text(data_registry, sample_world, sample_character),
		"反应器校准件",
		"sample blocker HUD objective still points to reactor calibrator"
	)
	_expect_text_contains(
		log_presenter.format_result_log(sample_result),
		"下一步",
		"sample blocker HUD log keeps recovery route"
	)

	var residue_world := WorldState.create_default()
	residue_world.current_region_id = "region.crystal_vein_field"
	residue_world.quest_state.active_quest_ids = ["quest.bring_back_sample"]
	var residue_character := CharacterState.create_default()
	residue_character.current_region_id = "region.crystal_vein_field"
	var residue_result := gather_system.interact_with_object(
		"map_object_instance.anomaly_residue_patch",
		"map_object.anomaly_residue_patch",
		"gather",
		residue_character,
		residue_world
	)
	_expect_failure(residue_result, "anomaly residue gather should be blocked before analysis gate")
	_expect_blocker_detail(residue_result, "异常晶体样本", "gather prerequisite blocker detail")


func _check_already_processed_object_blocker() -> void:
	var world := WorldState.create_default()
	world.current_region_id = "region.pollution_edge"
	var character := CharacterState.create_default()
	character.current_region_id = "region.pollution_edge"
	var instance_id := "map_object_instance.rough_ground_north"
	world.ensure_map_object(instance_id, "map_object.rough_ground", "region.pollution_edge")
	world.set_map_object_flag(instance_id, "is_cleared", true)

	var result := GatherSystem.new(data_registry).interact_with_object(
		instance_id,
		"map_object.rough_ground",
		"clear",
		character,
		world
	)
	_expect_failure(result, "already-cleared rough ground should block repeat clear")
	_expect_blocker_detail(result, "基础地基", "already processed object recovery route")
	_expect_equal(
		bool(world.get_map_object(instance_id).get("is_cleared", false)),
		true,
		"already processed blocker keeps cleared object state"
	)
	_expect_text_contains(
		DemoInteractionAffordanceFormatter.format_definition_affordance_line(
			"map_object.rough_ground",
			"clear",
			instance_id,
			world.get_map_object(instance_id),
			world,
			character
		),
		"已处理",
		"already processed object affordance still reads completed state"
	)


func _check_build_blockers() -> void:
	var build_system := BuildSystem.new(data_registry)

	var prerequisite_world := WorldState.create_default()
	prerequisite_world.current_region_id = "region.pollution_edge"
	var prerequisite_character := CharacterState.create_default()
	prerequisite_character.current_region_id = "region.pollution_edge"
	var prerequisite_result := build_system.build_structure(
		"map_object_instance.pollution_filter_build_site",
		"building.pollution_filter",
		prerequisite_character,
		prerequisite_world
	)
	_expect_failure(prerequisite_result, "pollution filter should be blocked before foundations")
	_expect_blocker_detail(prerequisite_result, "基础地基", "build prerequisite blocker detail")
	var filter_status := build_system.get_build_status(
		"map_object_instance.pollution_filter_build_site",
		"building.pollution_filter",
		prerequisite_character,
		prerequisite_world
	)
	_expect_text_contains(
		String(filter_status.get("next_step", "")),
		"基础地基",
		"build status keeps foundation recovery route"
	)

	var material_world := WorldState.create_default()
	material_world.current_region_id = "region.outpost_platform"
	var material_character := CharacterState.create_default()
	material_character.current_region_id = "region.outpost_platform"
	var material_result := build_system.build_structure(
		"map_object_instance.field_outfitting_station_build_site",
		"building.field_outfitting_station",
		material_character,
		material_world
	)
	_expect_failure(material_result, "field outfitting station should be blocked by missing scrap")
	_expect_blocker_detail(material_result, "导电废件", "build material blocker detail")


func _check_processing_blockers() -> void:
	var processing := ProcessingSystem.new(data_registry)

	var missing_world := WorldState.create_default()
	missing_world.quest_state.active_quest_ids = ["quest.scout_crystal_field"]
	missing_world.quest_state.unlock_effect("recipe.process_crystal_ore")
	var missing_character := CharacterState.create_default()
	var missing_result := processing.process_recipe(
		"recipe.process_crystal_ore",
		missing_character,
		missing_world
	)
	_expect_failure(missing_result, "crystal ore processing should be blocked by missing ore")
	_expect_blocker_detail(missing_result, "晶体矿物", "processing missing input blocker detail")
	_expect_text_contains(
		HudHintPresenter.new().format_direction_hint(missing_world, missing_character, "quest.scout_crystal_field"),
		"晶体矿脉区",
		"processing missing input HUD hint points back to crystal field"
	)

	var busy_world := WorldState.create_default()
	busy_world.quest_state.unlock_effect("recipe.process_crystal_ore")
	busy_world.set_base_structure_status("structure.basic_reactor", "in_progress", "recipe.process_crystal_ore")
	busy_world.set_base_structure_progress("structure.basic_reactor", 2.0)
	var busy_character := CharacterState.create_default()
	busy_character.inventory.add_item("item.crystal_ore", 3)
	var busy_result := processing.process_recipe(
		"recipe.process_crystal_ore",
		busy_character,
		busy_world
	)
	_expect_failure(busy_result, "processing should be blocked while device is busy")
	_expect_blocker_detail(busy_result, "等待设备完成", "processing busy blocker detail")
	_expect_equal(
		String(busy_world.base_structures["structure.basic_reactor"].get("status", "")),
		"in_progress",
		"processing busy blocker keeps device in-progress state"
	)


func _check_supply_blockers() -> void:
	var no_supply_character := CharacterState.create_default()
	no_supply_character.health = 50.0
	no_supply_character.inventory.items.erase("item.repair_gel")
	var no_supply_result := no_supply_character.use_quick_slot(0, data_registry)
	_expect_failure(no_supply_result, "repair gel quick slot should be blocked without item")
	_expect_blocker_detail(no_supply_result, "基础反应器", "missing supply blocker detail")
	var no_supply_feedback: Dictionary = no_supply_result.get("supply_feedback", {})
	_expect_text_contains(
		String(no_supply_feedback.get("detail", "")),
		"修复凝胶",
		"missing supply HUD panel keeps refill route"
	)
	_expect_text_contains(
		log_presenter.format_result_log(no_supply_result),
		"下一步",
		"missing supply HUD log keeps recovery route"
	)

	var full_character := CharacterState.create_default()
	var full_result := full_character.use_quick_slot(0, data_registry)
	_expect_failure(full_result, "repair gel quick slot should be blocked at full health")
	_expect_blocker_detail(full_result, "生命已满", "full-health supply blocker detail")


func _check_core_write_blockers() -> void:
	var gather_system := GatherSystem.new(data_registry)

	var guard_world := _create_core_write_world()
	var guard_character := _create_core_write_character()
	var guard_result := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"inspect",
		guard_character,
		guard_world
	)
	_expect_failure(guard_result, "core write should be blocked by active guard")
	_expect_blocker_detail(guard_result, "核心阶段守卫", "core write guard blocker detail")
	_expect_equal(
		bool(guard_world.get_enemy("enemy_instance.demo_stabilization_guard").get("is_defeated", false)),
		false,
		"core guard blocker keeps enemy undefeated state"
	)
	_expect_text_contains(
		HudMapPresenter.new().format_demo_route_hint(guard_world, "quest.write_demo_stabilization_core", guard_character),
		"核心稳定站",
		"core guard blocker map keeps core station route"
	)

	var charge_world := _create_core_write_world()
	var charge_character := _create_core_write_character()
	charge_world.update_enemy_health("enemy_instance.demo_stabilization_guard", 0.0, true)
	var charge_result := gather_system.interact_with_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"inspect",
		charge_character,
		charge_world
	)
	_expect_failure(charge_result, "core write should be blocked without core write charge")
	_expect_blocker_detail(charge_result, "校验片", "core write charge blocker detail")
	_expect_text_contains(
		HudHintPresenter.new().format_direction_hint(
			charge_world,
			charge_character,
			"quest.write_demo_stabilization_core"
		),
		"回写缓存",
		"core write charge blocker HUD hint points to guard cache"
	)


func _create_core_write_world() -> WorldState:
	var world := WorldState.create_default()
	world.current_region_id = "region.demo_stabilization_core"
	world.unlock_region("region.demo_stabilization_core")
	world.quest_state.active_quest_ids = ["quest.write_demo_stabilization_core"]
	world.ensure_enemy(
		"enemy_instance.demo_stabilization_guard",
		"enemy.demo_stabilization_guard",
		"region.demo_stabilization_core",
		156.0
	)
	world.ensure_map_object(
		"map_object_instance.demo_stabilization_core",
		"map_object.demo_stabilization_core",
		"region.demo_stabilization_core"
	)
	return world


func _create_core_write_character() -> CharacterState:
	var character := CharacterState.create_default()
	character.current_region_id = "region.demo_stabilization_core"
	return character


func _expect_failure(result: Dictionary, context: String) -> void:
	_expect_equal(bool(result.get("success", false)), false, context)
	if bool(result.get("success", false)):
		failures.append("%s: expected failure, got '%s'" % [context, str(result)])


func _expect_blocker_detail(result: Dictionary, expected: String, context: String) -> void:
	var feedback: Dictionary = result.get("failure_feedback", {})
	if feedback.is_empty():
		failures.append("%s: expected failure feedback, got '%s'" % [context, str(result)])
		return
	var detail := String(feedback.get("detail", ""))
	_expect_text_contains(detail, "原因", "%s reason label" % context)
	_expect_text_contains(detail, "缺口", "%s gap label" % context)
	_expect_text_contains(detail, "恢复", "%s recovery label" % context)
	_expect_text_contains(detail, expected, context)


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
