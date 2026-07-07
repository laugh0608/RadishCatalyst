extends SceneTree

const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")

var failures: Array[String] = []
var data_registry := DataRegistry.new()


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		_run_checks()

	if failures.is_empty():
		print("Demo interaction affordance checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_general_prompt_affordance_states()
	_check_outpost_and_outfitting_affordance_lines()
	_check_build_and_clear_affordance_lines()
	_check_signal_echo_and_core_guard_affordance()
	_check_hud_map_route_alignment()
	_check_scene_visual_affordance_labels()
	_check_first_minute_current_objective_selection()
	_check_enemy_focus_affordance_labels()


func _check_general_prompt_affordance_states() -> void:
	var formatter := _create_interaction_formatter()
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	world.current_region_id = "region.pollution_edge"
	character.current_region_id = "region.pollution_edge"
	var residue := _create_interactable(
		"map_object_instance.pollution_residue_affordance",
		"map_object.pollution_residue_patch",
		"gather"
	)
	var residue_prompt := formatter.format_general_interaction_prompt(residue, character, world)
	_expect_text_contains(residue_prompt, "可辨识：可处理", "pollution residue prompt shows processable affordance")
	_expect_text_contains(residue_prompt, "状态：可采集", "pollution residue prompt keeps gather status")

	world.ensure_map_object(
		residue.instance_id,
		residue.definition_id,
		"region.pollution_edge"
	)["is_gathered"] = true
	var processed_prompt := formatter.format_general_interaction_prompt(residue, character, world)
	_expect_text_contains(processed_prompt, "可辨识：已处理", "processed residue prompt shows completed affordance")
	_expect_text_contains(processed_prompt, "现场保留已回收标记", "processed residue prompt keeps visual marker explanation")
	residue.free()


func _check_outpost_and_outfitting_affordance_lines() -> void:
	var formatter := _create_interaction_formatter()
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var outpost_prompt := formatter.format_outpost_core_prompt(world, character)
	_expect_text_contains(outpost_prompt, "可辨识：可交互", "unrestored outpost core prompt shows interactable affordance")

	world.quest_state.complete_quest("quest.restore_outpost")
	character.health = 45.0
	character.protection = 30.0
	var restored_prompt := formatter.format_outpost_core_prompt(world, character)
	_expect_text_contains(restored_prompt, "可辨识：可整备", "restored outpost core prompt shows readiness affordance")

	var unbuilt_outfitting_prompt := formatter.format_outfitting_station_prompt(character, world)
	_expect_text_contains(unbuilt_outfitting_prompt, "可辨识：缺条件", "unbuilt outfitting prompt shows missing condition")
	world.add_base_structure(
		"structure.field_outfitting_station",
		"building.field_outfitting_station",
		"region.outpost_platform",
		"map_object_instance.field_outfitting_station_build_site"
	)
	character.inventory.add_equipment(FieldOutfittingRuntime.BASIC_FILTER_MODULE_ID, 1)
	var ready_outfitting_prompt := formatter.format_outfitting_station_prompt(character, world)
	_expect_text_contains(ready_outfitting_prompt, "可辨识：可交互", "outfitting prompt shows module install affordance")
	world.ensure_map_object(
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_INSTANCE_ID,
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_REGION_ID
	)[FieldOutfittingRuntime.MODULE_CALIBRATED_FLAG] = true
	var calibrated_prompt := formatter.format_outfitting_station_prompt(character, world)
	_expect_text_contains(calibrated_prompt, "可辨识：已处理", "calibrated outfitting prompt shows processed affordance")


func _check_build_and_clear_affordance_lines() -> void:
	var formatter := _create_interaction_formatter()
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var build_site := _create_interactable(
		"map_object_instance.field_outfitting_station_build_site",
		"building.field_outfitting_station",
		"build"
	)
	var missing_build_prompt := formatter.format_build_prompt(build_site, character, world)
	_expect_text_contains(missing_build_prompt, "可辨识：缺条件", "build prompt shows missing material affordance")
	character.inventory.add_ref("item.basic_parts", 2)
	character.inventory.add_ref("item.salvage_scrap", 1)
	var ready_build_prompt := formatter.format_build_prompt(build_site, character, world)
	_expect_text_contains(ready_build_prompt, "可辨识：可建造", "build prompt shows ready affordance")
	build_site.free()

	var rough_ground := _create_interactable(
		"map_object_instance.rough_ground_north",
		"map_object.rough_ground",
		"clear"
	)
	var clear_prompt := formatter.format_clear_prompt(rough_ground, character, world)
	_expect_text_contains(clear_prompt, "可辨识：可处理", "clear prompt shows clearable affordance")
	world.ensure_map_object(
		rough_ground.instance_id,
		rough_ground.definition_id,
		"region.outpost_platform"
	)["is_cleared"] = true
	var cleared_prompt := formatter.format_clear_prompt(rough_ground, character, world)
	_expect_text_contains(cleared_prompt, "可辨识：已处理", "cleared prompt shows processed affordance")
	rough_ground.free()


func _check_signal_echo_and_core_guard_affordance() -> void:
	var formatter := _create_interaction_formatter()
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	world.current_region_id = "region.ruin_outer_ring"
	world.quest_state.complete_quest("quest.secure_outer_ring_signal")
	world.quest_state.active_quest_ids = ["quest.salvage_signal_echo"]
	world.ensure_enemy(
		"enemy_instance.ruin_phase_guard",
		"enemy.ruin_phase_guard",
		"region.ruin_outer_ring",
		90.0
	)
	var blocked_signal_prompt := formatter.format_signal_echo_cache_prompt(world, character)
	_expect_text_contains(blocked_signal_prompt, "可辨识：危险仍在", "signal echo prompt shows enemy pressure")
	_expect_text_contains(blocked_signal_prompt, "相位守卫", "signal echo prompt names blocking guard")

	world.update_enemy_health("enemy_instance.ruin_phase_guard", 0.0, true)
	world.quest_state.set_objective_progress("quest.salvage_signal_echo", "gather_item", "item.polluted_residue", 2.0)
	var ready_signal_prompt := formatter.format_signal_echo_cache_prompt(world, character)
	_expect_text_contains(ready_signal_prompt, "可辨识：可交互", "signal echo prompt shows ready interaction")

	var guard_cache := _create_interactable(
		DemoInteractionAffordanceFormatter.DEMO_GUARD_CACHE_INSTANCE_ID,
		"map_object.demo_stabilization_guard_cache",
		"gather"
	)
	var core_world := WorldState.create_default()
	var core_character := CharacterState.create_default()
	core_world.current_region_id = "region.demo_stabilization_core"
	core_world.ensure_enemy(
		"enemy_instance.demo_stabilization_guard",
		"enemy.demo_stabilization_guard",
		"region.demo_stabilization_core",
		156.0
	)
	var blocked_cache_prompt := formatter.format_general_interaction_prompt(guard_cache, core_character, core_world)
	_expect_text_contains(blocked_cache_prompt, "可辨识：危险仍在", "guard cache prompt shows core guard pressure")
	core_world.update_enemy_health("enemy_instance.demo_stabilization_guard", 0.0, true)
	core_world.quest_state.active_quest_ids = ["quest.write_demo_stabilization_core"]
	core_world.ensure_map_object(
		guard_cache.instance_id,
		guard_cache.definition_id,
		"region.demo_stabilization_core"
	)["is_gathered"] = true
	var gathered_cache_prompt := formatter.format_general_interaction_prompt(guard_cache, core_character, core_world)
	_expect_text_contains(gathered_cache_prompt, "可辨识：已处理", "guard cache prompt shows gathered state")
	guard_cache.free()


func _check_hud_map_route_alignment() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	world.current_region_id = "region.ruin_outer_ring"
	character.current_region_id = "region.ruin_outer_ring"
	world.quest_state.complete_quest("quest.secure_outer_ring_signal")
	world.quest_state.active_quest_ids = ["quest.salvage_signal_echo"]
	world.ensure_enemy(
		"enemy_instance.ruin_phase_guard",
		"enemy.ruin_phase_guard",
		"region.ruin_outer_ring",
		90.0
	)
	var status_text := HudStatusPresenter.new().format_status_text(data_registry, world, character)
	_expect_text_contains(status_text, "当前目标", "HUD keeps current objective while guard blocks object")
	_expect_text_contains(status_text, "当前危险", "HUD keeps danger state while guard blocks object")
	var map_hint := _create_map_presenter().format_demo_route_hint(world, "quest.salvage_signal_echo")
	_expect_text_contains(map_hint, "封锁遗迹", "map hint keeps outer ring route")
	_expect_text_contains(map_hint, "旧设施短副本入口", "map hint keeps map visual target")


func _check_scene_visual_affordance_labels() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(data_registry)
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	world.quest_state.complete_quest("quest.restore_outpost")
	world.ensure_map_object(
		"map_object_instance.pollution_residue",
		"map_object.pollution_residue_patch",
		"region.pollution_edge"
	)["is_gathered"] = true
	world.ensure_map_object(
		"map_object_instance.rough_ground_north",
		"map_object.rough_ground",
		"region.outpost_platform"
	)["is_cleared"] = true
	world.add_base_structure(
		"structure.field_outfitting_station",
		"building.field_outfitting_station",
		"region.outpost_platform",
		"map_object_instance.field_outfitting_station_build_site"
	)
	world.ensure_map_object(
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_INSTANCE_ID,
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_ID,
		FieldOutfittingRuntime.FIELD_OUTFITTING_STATION_REGION_ID
	)[FieldOutfittingRuntime.MODULE_CALIBRATED_FLAG] = true
	world.current_region_id = "region.outpost_platform"
	character.current_region_id = "region.outpost_platform"
	map.apply_runtime_state(world, character)

	var residue := map.get_node("Interactables/PollutionResidue") as PrototypeInteractable
	_expect_equal(residue.visible, true, "processed pollution residue remains visible")
	_expect_equal(residue.monitoring, false, "processed pollution residue stops interaction")
	_expect_text_contains(residue.label.text, "已回收", "processed pollution residue label")

	var rough_ground := map.get_node("Interactables/RoughGroundNorth") as PrototypeInteractable
	_expect_equal(rough_ground.visible, true, "cleared rough ground remains visible")
	_expect_equal(rough_ground.monitoring, false, "cleared rough ground stops interaction")
	_expect_text_contains(rough_ground.label.text, "已清理", "cleared rough ground label")

	var station := map.get_node("Interactables/FieldOutfittingStation") as PrototypeInteractable
	_expect_equal(station.visible, true, "calibrated outfitting station remains visible")
	_expect_equal(station.monitoring, true, "calibrated outfitting station remains inspectable")
	_expect_text_contains(station.label.text, "已校准", "calibrated outfitting station label")

	world.current_region_id = "region.demo_stabilization_core"
	character.current_region_id = "region.demo_stabilization_core"
	world.quest_state.active_quest_ids = ["quest.write_demo_stabilization_core"]
	world.ensure_enemy(
		"enemy_instance.demo_stabilization_guard",
		"enemy.demo_stabilization_guard",
		"region.demo_stabilization_core",
		156.0
	)
	world.update_enemy_health("enemy_instance.demo_stabilization_guard", 0.0, true)
	map.apply_runtime_state(world, character)
	var guard_cache := map.get_node("Interactables/DemoStabilizationGuardCache") as PrototypeInteractable
	_expect_equal(guard_cache.visible, true, "guard cache visible after guard defeated")
	_expect_equal(guard_cache.monitoring, true, "guard cache interactable after guard defeated")
	world.ensure_map_object(
		DemoInteractionAffordanceFormatter.DEMO_GUARD_CACHE_INSTANCE_ID,
		"map_object.demo_stabilization_guard_cache",
		"region.demo_stabilization_core"
	)["is_gathered"] = true
	map.apply_runtime_state(world, character)
	_expect_text_contains(guard_cache.label.text, "已回收", "gathered guard cache label")
	map.free()


func _check_first_minute_current_objective_selection() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(data_registry)

	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	world.quest_state.complete_quest("quest.restore_outpost")
	world.quest_state.active_quest_ids = ["quest.scout_crystal_field"]
	map.apply_runtime_state(world, character)

	var crystal := map.get_node("Interactables/CrystalCluster") as PrototypeInteractable
	map.player.position = crystal.position + Vector2(-48.0, 0.0)
	map.player.facing_direction = Vector2.RIGHT
	var forward_target := InteractableTargetSelector.select_interactable(
		map.player,
		map.interactables_root,
		world
	)
	_expect_equal(forward_target, crystal, "scout crystal objective selects forward crystal")

	map.player.facing_direction = Vector2.LEFT
	var backward_target := InteractableTargetSelector.select_interactable(
		map.player,
		map.interactables_root,
		world
	)
	_expect_equal(backward_target, null, "scout crystal objective respects facing at extended range")
	map.free()


func _check_enemy_focus_affordance_labels() -> void:
	var enemy := PrototypeEnemy.new()
	enemy.definition_id = "enemy.demo_stabilization_guard"
	enemy.instance_id = "enemy_instance.demo_stabilization_guard"
	enemy.add_child(ColorRect.new())
	enemy.get_child(0).name = "Sprite"
	enemy.add_child(Label.new())
	enemy.get_child(1).name = "Label"
	enemy.add_child(ColorRect.new())
	enemy.get_child(2).name = "FocusRing"
	var collision := CollisionShape2D.new()
	collision.shape = RectangleShape2D.new()
	enemy.add_child(collision)
	collision.name = "CollisionShape2D"
	enemy.setup("核心阶段守卫", 156.0, "elite_node")
	_expect_text_contains(enemy.label.text, "核心回写压力", "active demo guard label shows danger role")
	enemy.mark_defeated()
	_expect_text_contains(enemy.label.text, "已击败", "defeated demo guard label shows cleared state")
	enemy.free()


func _create_interaction_formatter() -> InteractionPromptFormatter:
	return InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)


func _create_map_presenter() -> HudMapPresenter:
	var presenter := HudMapPresenter.new()
	presenter.target_region_resolver = QuestTargetRegionResolver.new(data_registry)
	return presenter


func _create_interactable(instance_id: String, definition_id: String, interaction_type: String) -> PrototypeInteractable:
	var interactable := PrototypeInteractable.new()
	interactable.instance_id = instance_id
	interactable.definition_id = definition_id
	interactable.interaction_type = interaction_type
	interactable.single_use = false
	return interactable


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
