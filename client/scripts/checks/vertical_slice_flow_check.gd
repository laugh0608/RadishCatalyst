extends SceneTree

const GameRootScript := preload("res://scripts/game/game_root.gd")

var failures: Array[String] = []
var data_registry := DataRegistry.new()
var world_state := WorldState.create_default()
var character_state := CharacterState.create_default()


func _init() -> void:
	_run_checks()
	if failures.is_empty():
		print("Vertical slice flow checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
		return

	_expect_equal(world_state.quest_state.active_quest_ids, ["quest.restore_outpost"], "initial active quest")
	_check_onboarding_hints()
	_check_status_panel_summary()
	_check_region_markers()
	_check_region_presence_bounds()
	_check_pollution_gate_runtime_bounds()
	_check_new_game_state_reset()
	_check_outpost_core_restored_visual()
	_check_early_interaction_processed_visuals()
	_check_pollution_enemy_defeated_visual()
	_check_quest_completion_panel_text()
	_check_build_prompts()
	_check_supply_feedback()
	_check_hud_feedback_presenter()
	_check_pollution_status_hints()
	_check_region_prompt_formatter()
	_check_failure_feedback_logs()
	_check_device_panel_formatting()

	_complete_active_quest("quest.restore_outpost", [
		{"type": "interact", "target_id": "building.outpost_core", "amount": 1}
	])
	_expect_active_quest("quest.scout_crystal_field", "after restore outpost")
	_expect_array_has(world_state.unlocked_region_ids, "region.crystal_vein_field", "restore unlocks crystal region")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.process_crystal_ore", "restore unlocks crystal recipe")

	_complete_active_quest("quest.scout_crystal_field", [
		{"type": "visit_region", "target_id": "region.crystal_vein_field", "amount": 1},
		{"type": "gather_item", "target_id": "item.crystal_ore", "amount": 6}
	])
	_expect_active_quest("quest.calibrate_reactor", "after scout crystal field")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.reactor_calibrator", "scout unlocks reactor calibrator recipe")

	_complete_active_quest("quest.calibrate_reactor", [
		{"type": "gather_item", "target_id": "item.salvage_scrap", "amount": 4},
		{"type": "craft_item", "target_id": "item.reactor_calibrator", "amount": 1}
	])
	_expect_active_quest("quest.bring_back_sample", "after calibrate reactor")

	_complete_active_quest("quest.bring_back_sample", [
		{"type": "sample_object", "target_id": "map_object.anomaly_crystal", "amount": 1},
		{"type": "return_region", "target_id": "region.outpost_platform", "amount": 1}
	])
	_expect_active_quest("quest.make_filter_module", "after bring back sample")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.make_filter_media", "sample unlocks filter media recipe")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.basic_filter_module", "sample unlocks filter module recipe")

	_complete_active_quest("quest.make_filter_module", [
		{"type": "craft_item", "target_id": "equipment.filter_module_t1", "amount": 1}
	])
	_expect_active_quest("quest.expand_treatment_point", "after make filter module")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.foundation_t1", "filter module unlocks foundation recipe")

	_complete_active_quest("quest.expand_treatment_point", [
		{"type": "build", "target_id": "building.foundation_t1", "amount": 2},
		{"type": "build", "target_id": "building.pollution_filter", "amount": 1}
	])
	_expect_active_quest("quest.enter_pollution_edge", "after expand treatment point")
	_expect_array_has(world_state.unlocked_region_ids, "region.pollution_edge", "treatment point unlocks pollution edge region")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.cleanse_residue", "treatment point unlocks residue recipe")

	_complete_active_quest("quest.enter_pollution_edge", [
		{"type": "visit_region", "target_id": "region.pollution_edge", "amount": 1},
		{"type": "gather_item", "target_id": "item.polluted_residue", "amount": 2},
		{"type": "craft_item", "target_id": "item.resistance_vial_t1", "amount": 1},
		{"type": "defeat_enemy", "target_id": "enemy.polluted_skitter", "amount": 1}
	])
	_expect_active_quest("quest.unlock_ruin_signal", "after enter pollution edge")
	_expect_array_has(world_state.unlocked_region_ids, "region.locked_ruin_gate", "pollution edge unlocks ruin gate region")
	_expect_array_has(world_state.quest_state.completed_quest_ids, "quest.enter_pollution_edge", "pollution edge completed")
	_expect_array_missing(world_state.quest_state.active_quest_ids, "quest.defeat_elite_node", "prototype should not activate unimplemented elite node")

	_complete_active_quest("quest.unlock_ruin_signal", [
		{"type": "inspect", "target_id": "map_object.ruin_gate", "amount": 1}
	])
	_expect_equal(world_state.quest_state.active_quest_ids, [], "after ruin signal has no active quest")
	_expect_array_has(world_state.quest_state.completed_quest_ids, "quest.unlock_ruin_signal", "ruin signal completed")
	_expect_array_has(world_state.quest_state.unlocked_effects, "slice_01_complete", "slice completion unlock")

	_check_processing_runtime()
	_check_evacuation_feedback()


func _check_onboarding_hints() -> void:
	var hud := PrototypeHud.new()
	var hint_world := WorldState.create_default()
	var hint_character := CharacterState.create_default()

	_expect_hint_contains(hud, hint_world, hint_character, "quest.restore_outpost", "前哨核心", "restore outpost onboarding hint")

	hint_world.current_region_id = "region.crystal_vein_field"
	_expect_hint_contains(hud, hint_world, hint_character, "quest.scout_crystal_field", "采集晶体簇", "crystal field onboarding hint")
	_expect_hint_contains(hud, hint_world, hint_character, "quest.calibrate_reactor", "外勤残骸", "calibration onboarding hint")

	_expect_hint_contains(hud, hint_world, hint_character, "quest.expand_treatment_point", "2 块地基", "foundation onboarding hint")
	hint_world.add_base_structure("structure.foundation_site_north", "building.foundation_t1", "region.pollution_edge")
	hint_world.add_base_structure("structure.foundation_site_south", "building.foundation_t1", "region.pollution_edge")
	_expect_hint_contains(hud, hint_world, hint_character, "quest.expand_treatment_point", "污染过滤器", "pollution filter onboarding hint")

	hint_character.protection = 30.0
	hint_character.equipment["suit_module"] = "equipment.filter_module_t1"
	_expect_hint_contains(hud, hint_world, hint_character, "quest.enter_pollution_edge", "防护偏低", "low protection onboarding hint")

	hint_world.quest_state.unlocked_effects.append("slice_01_complete")
	_expect_hint_contains(hud, hint_world, hint_character, "", "更深区域信号", "slice complete onboarding hint")
	hud.free()


func _check_status_panel_summary() -> void:
	var hud := PrototypeHud.new()
	var status_world := WorldState.create_default()
	var status_character := CharacterState.create_default()
	var status_text := hud.format_status_text(data_registry, status_world, status_character)
	_expect_text_contains(status_text, "目标：恢复前哨", "status keeps current goal")
	_expect_text_contains(status_text, "进度：交互 前哨核心 0/1", "status keeps objective progress")
	_expect_text_contains(status_text, "状态：生命 100 / 100；防护 100 / 100", "status keeps health and protection")
	_expect_text_contains(status_text, "快捷栏：1 修复凝胶 x1", "status keeps quick slots")
	_expect_text_contains(status_text, "关键物资：基础零件 x4", "status keeps key resources")
	_expect_text_missing(status_text, "区域：", "status removes minimap region duplicate")
	_expect_text_missing(status_text, "方向：", "status removes minimap direction duplicate")
	_expect_text_missing(status_text, "提示：", "status removes onboarding duplicate")
	_expect_text_missing(status_text, "坐标：", "status removes debug coordinate duplicate")
	_expect_text_missing(status_text, "背包：", "status removes full inventory duplicate")
	if status_text.split("\n").size() > 8:
		failures.append("status panel should stay compact, got %d lines: %s" % [status_text.split("\n").size(), status_text])
	hud.free()


func _check_region_markers() -> void:
	var hud := PrototypeHud.new()
	var marker_world := WorldState.create_default()
	_expect_text_contains(
		hud._format_region_markers(marker_world, "quest.restore_outpost"),
		"基地：当前位置，目标",
		"outpost marker as current objective"
	)
	_expect_text_contains(
		hud._format_region_markers(marker_world, "quest.restore_outpost"),
		"晶体：东侧，未解锁",
		"locked crystal marker"
	)
	var initial_map_labels := hud.format_map_marker_labels(marker_world, "quest.restore_outpost")
	_expect_array_has(initial_map_labels, "基地\n当前\n目标", "outpost minimap current target marker")
	_expect_array_has(initial_map_labels, "晶体\n未解锁", "crystal minimap locked marker")

	marker_world.unlock_region("region.crystal_vein_field")
	_expect_text_contains(
		hud._format_region_markers(marker_world, "quest.scout_crystal_field"),
		"晶体：东侧，目标",
		"crystal marker as objective"
	)
	_expect_array_has(
		hud.format_map_marker_labels(marker_world, "quest.scout_crystal_field"),
		"晶体\n目标",
		"crystal minimap objective marker"
	)

	marker_world.quest_state.set_objective_progress(
		"quest.bring_back_sample",
		"sample_object",
		"map_object.anomaly_crystal",
		1.0
	)
	_expect_text_contains(
		hud._format_region_markers(marker_world, "quest.bring_back_sample"),
		"基地：当前位置，目标",
		"sample return marker as objective"
	)

	marker_world.unlock_region("region.locked_ruin_gate")
	_expect_text_contains(
		hud._format_region_markers(marker_world, "quest.unlock_ruin_signal"),
		"遗迹：东端，目标",
		"ruin gate marker as objective"
	)
	_expect_array_has(
		hud.format_map_marker_labels(marker_world, "quest.unlock_ruin_signal"),
		"遗迹\n目标",
		"ruin gate minimap objective marker"
	)
	hud.free()


func _check_region_presence_bounds() -> void:
	var map := VerticalSliceMap.new()
	_expect_equal(
		map._get_region_id_for_position(Vector2(253, -104)),
		"region.crystal_vein_field",
		"pollution treatment point should not count as pollution"
	)
	_expect_equal(
		map._get_region_id_for_position(Vector2(253, 30)),
		"region.pollution_edge",
		"pollution lower area should count as pollution"
	)
	_expect_equal(
		map._get_region_id_for_position(Vector2(190, -104)),
		"region.crystal_vein_field",
		"gap before pollution visual edge should remain crystal"
	)
	map.free()


func _check_pollution_gate_runtime_bounds() -> void:
	var map := VerticalSliceMap.new()
	map.player = PlayerController.new()
	var gate_world := WorldState.create_default()
	gate_world.unlock_region("region.crystal_vein_field")
	var gate_character := CharacterState.create_default()
	map.player.position = Vector2(253, 30)
	map.update_region_presence(gate_world, gate_character)
	_expect_equal(map.player.position.x, 195.0, "locked pollution edge should push player before visual region")
	_expect_equal(gate_world.current_region_id, "region.crystal_vein_field", "locked pollution edge should return to crystal side")

	var unlocked_world := WorldState.create_default()
	unlocked_world.unlock_region("region.crystal_vein_field")
	unlocked_world.unlock_region("region.pollution_edge")
	var unlocked_character := CharacterState.create_default()
	map.last_reported_region_id = unlocked_world.current_region_id
	map.player.position = Vector2(253, 30)
	map.update_region_presence(unlocked_world, unlocked_character)
	_expect_equal(unlocked_world.current_region_id, "region.pollution_edge", "unlocked pollution edge should update current region")
	_expect_equal(unlocked_character.current_region_id, "region.pollution_edge", "unlocked pollution edge should update character region")
	map.player.free()
	map.free()


func _check_new_game_state_reset() -> void:
	var game_root = GameRootScript.new()
	var new_state := game_root.create_new_game_state()
	var reset_world: WorldState = new_state.get("world_state", null)
	var reset_character: CharacterState = new_state.get("character_state", null)
	if reset_world == null or reset_character == null:
		failures.append("new game state should include world and character")
		game_root.free()
		return

	_expect_equal(reset_world.current_region_id, "region.outpost_platform", "new game resets world region")
	_expect_equal(reset_character.current_region_id, "region.outpost_platform", "new game resets character region")
	_expect_equal(reset_world.quest_state.active_quest_ids, ["quest.restore_outpost"], "new game resets active quest")
	_expect_array_missing(reset_world.unlocked_region_ids, "region.crystal_vein_field", "new game should not keep crystal unlock")
	_expect_equal(int(reset_character.inventory.items.get("item.basic_parts", 0)), 4, "new game resets starting parts")
	_expect_equal(String(reset_character.equipment.get("suit_module", "")), "", "new game clears suit module")
	game_root.free()


func _check_outpost_core_restored_visual() -> void:
	var temp_root := Node.new()
	var outpost_core := _create_visual_check_interactable(
		temp_root,
		"map_object_instance.outpost_core",
		"building.outpost_core",
		"outpost_core",
		"前哨核心"
	)
	var default_color := outpost_core.marker.color
	outpost_core.set_restored_outpost_core_visual()
	_expect_equal(outpost_core.visible, true, "restored outpost core remains visible")
	_expect_equal(outpost_core.monitoring, false, "restored outpost core disables repeat interaction")
	_expect_equal(outpost_core.marker.color == default_color, false, "restored outpost core changes color")
	_expect_text_contains(outpost_core.label.text, "已恢复", "restored outpost core label")
	outpost_core.set_default_visual()
	_expect_equal(outpost_core.monitoring, true, "new game outpost core enables interaction")
	_expect_equal(outpost_core.marker.color, default_color, "new game outpost core restores default color")
	temp_root.free()


func _check_early_interaction_processed_visuals() -> void:
	var map := VerticalSliceMap.new()
	map.player = PlayerController.new()
	map.interactables_root = Node2D.new()
	map.add_child(map.player)
	map.add_child(map.interactables_root)

	var crystal := _create_visual_check_interactable(
		map.interactables_root,
		"map_object_instance.crystal_cluster",
		"map_object.crystal_cluster",
		"gather",
		"晶体簇"
	)
	var salvage := _create_visual_check_interactable(
		map.interactables_root,
		"map_object_instance.field_wreckage_north",
		"map_object.field_wreckage",
		"gather",
		"外勤残骸"
	)
	var anomaly := _create_visual_check_interactable(
		map.interactables_root,
		"map_object_instance.anomaly_crystal",
		"map_object.anomaly_crystal",
		"sample",
		"异常晶体"
	)
	var rough_ground := _create_visual_check_interactable(
		map.interactables_root,
		"map_object_instance.rough_ground_north",
		"map_object.rough_ground",
		"clear",
		"粗糙地面"
	)
	var residue := _create_visual_check_interactable(
		map.interactables_root,
		"map_object_instance.pollution_residue",
		"map_object.pollution_residue_patch",
		"gather",
		"污染沉积斑"
	)
	var ruin_gate := _create_visual_check_interactable(
		map.interactables_root,
		"map_object_instance.ruin_gate",
		"map_object.ruin_gate",
		"inspect",
		"封锁遗迹入口"
	)
	var default_crystal_color := crystal.marker.color
	var default_salvage_color := salvage.marker.color
	var default_ruin_color := ruin_gate.marker.color

	var visual_world := WorldState.create_default()
	visual_world.ensure_map_object(crystal.instance_id, crystal.definition_id, "region.crystal_vein_field")
	visual_world.set_map_object_flag(crystal.instance_id, "is_gathered", true)
	visual_world.ensure_map_object(salvage.instance_id, salvage.definition_id, "region.crystal_vein_field")
	visual_world.set_map_object_flag(salvage.instance_id, "is_gathered", true)
	visual_world.ensure_map_object(anomaly.instance_id, anomaly.definition_id, "region.crystal_vein_field")
	visual_world.set_map_object_flag(anomaly.instance_id, "is_sampled", true)
	visual_world.ensure_map_object(rough_ground.instance_id, rough_ground.definition_id, "region.pollution_edge")
	visual_world.set_map_object_flag(rough_ground.instance_id, "is_cleared", true)
	visual_world.ensure_map_object(residue.instance_id, residue.definition_id, "region.pollution_edge")
	visual_world.set_map_object_flag(residue.instance_id, "is_gathered", true)
	visual_world.quest_state.completed_quest_ids.append("quest.unlock_ruin_signal")
	map.refresh_world_interactables(visual_world)

	_expect_equal(crystal.visible, true, "gathered crystal remains visible")
	_expect_equal(crystal.monitoring, false, "gathered crystal disables repeat interaction")
	_expect_equal(crystal.marker.color == default_crystal_color, false, "gathered crystal changes color")
	_expect_text_contains(crystal.label.text, "已采集", "gathered crystal label")
	_expect_equal(salvage.visible, true, "gathered salvage remains visible")
	_expect_equal(salvage.monitoring, false, "gathered salvage disables repeat interaction")
	_expect_equal(salvage.marker.color == default_salvage_color, false, "gathered salvage changes color")
	_expect_text_contains(salvage.label.text, "已回收", "gathered salvage label")
	_expect_equal(anomaly.visible, true, "sampled anomaly remains visible")
	_expect_equal(anomaly.monitoring, false, "sampled anomaly disables repeat interaction")
	_expect_text_contains(anomaly.label.text, "已采样", "sampled anomaly label")
	_expect_equal(rough_ground.visible, true, "cleared rough ground remains visible")
	_expect_equal(rough_ground.monitoring, false, "cleared rough ground disables repeat interaction")
	_expect_text_contains(rough_ground.label.text, "已清理", "cleared rough ground label")
	_expect_equal(residue.visible, true, "gathered residue remains visible")
	_expect_equal(residue.monitoring, false, "gathered residue disables repeat interaction")
	_expect_text_contains(residue.label.text, "已回收", "gathered residue label")
	_expect_equal(ruin_gate.visible, true, "confirmed ruin gate remains visible")
	_expect_equal(ruin_gate.monitoring, false, "confirmed ruin gate disables repeat interaction")
	_expect_equal(ruin_gate.marker.color == default_ruin_color, false, "confirmed ruin gate changes color")
	_expect_text_contains(ruin_gate.label.text, "信号已确认", "confirmed ruin gate label")

	var reset_world := WorldState.create_default()
	map.refresh_world_interactables(reset_world)
	_expect_equal(crystal.monitoring, true, "new game crystal enables interaction")
	_expect_equal(crystal.marker.color, default_crystal_color, "new game crystal restores default color")
	_expect_equal(crystal.label.text, "晶体簇", "new game crystal restores label")
	_expect_equal(salvage.monitoring, true, "new game salvage enables interaction")
	_expect_equal(salvage.marker.color, default_salvage_color, "new game salvage restores default color")
	_expect_equal(salvage.label.text, "外勤残骸", "new game salvage restores label")
	_expect_equal(ruin_gate.monitoring, true, "new game ruin gate enables interaction")
	_expect_equal(ruin_gate.marker.color, default_ruin_color, "new game ruin gate restores default color")

	map.free()


func _check_pollution_enemy_defeated_visual() -> void:
	var enemy := _create_visual_check_enemy("enemy.polluted_skitter", "受扰掠行体", 40.0, "polluted")
	var default_polluted_color := enemy.sprite.color
	enemy.apply_saved_state({
		"health": 0.0,
		"is_defeated": true
	})
	_expect_equal(enemy.defeated, true, "polluted enemy restored defeated state")
	_expect_equal(enemy.can_be_attacked(), false, "polluted enemy disables repeat attack")
	_expect_equal(enemy.sprite.color == default_polluted_color, false, "polluted enemy defeated changes color")
	_expect_text_contains(enemy.label.text, "污染已压制", "polluted enemy defeated label")
	enemy.free()


func _check_quest_completion_panel_text() -> void:
	var hud := PrototypeHud.new()
	var details := hud._format_quest_completion_details({
		"panel_title": "任务完成",
		"completed_text": "完成：恢复前哨",
		"reward_text": "奖励：基础零件 x4",
		"unlock_text": "解锁：晶体矿脉区",
		"note_text": "",
		"next_goal_text": "新目标：勘探晶体矿脉"
	})
	_expect_text_contains(details, "完成：恢复前哨", "completion details completed row")
	_expect_text_contains(details, "奖励：基础零件 x4", "completion details reward row")
	_expect_text_contains(details, "解锁：晶体矿脉区", "completion details unlock row")
	_expect_text_contains(details, "新目标：勘探晶体矿脉", "completion details next row")
	_expect_text_contains(
		hud._format_quest_completion_details({
			"title": "任务完成：带回样本",
			"reward_text": "奖励：无直接物资"
		}),
		"完成：带回样本",
		"completion details title fallback"
	)
	_expect_equal(
		hud._format_quest_completion_panel_title({"panel_title": "切片完成"}),
		"切片完成",
		"completion panel title"
	)
	_expect_text_contains(
		hud._format_quest_completion_details({
			"completed_text": "完成：解锁后续入口",
			"note_text": "切片结尾：更深区域信号已确认，后续内容待开放"
		}),
		"提示：切片结尾",
		"completion note prefix"
	)
	hud.free()


func _check_build_prompts() -> void:
	var build_world := WorldState.create_default()
	var build_character := CharacterState.create_default()
	var formatter := InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)

	var rough_ground := PrototypeInteractable.new()
	rough_ground.definition_id = "map_object.rough_ground"
	rough_ground.interaction_type = "clear"
	rough_ground.instance_id = "map_object_instance.rough_ground_north"
	_expect_text_contains(
		formatter.format_clear_prompt(rough_ground, build_character, build_world),
		"阻挡建造",
		"rough ground prompt"
	)

	var foundation_site := PrototypeInteractable.new()
	foundation_site.definition_id = "building.foundation_t1"
	foundation_site.interaction_type = "build"
	foundation_site.instance_id = "map_object_instance.foundation_site_north"
	foundation_site.prerequisite_instance_id = "map_object_instance.rough_ground_north"
	_expect_text_contains(
		formatter.format_build_prompt(foundation_site, build_character, build_world),
		"地面仍然粗糙",
		"foundation blocked prompt"
	)

	build_world.ensure_map_object("map_object_instance.rough_ground_north", "map_object.rough_ground", "region.pollution_edge")
	build_world.set_map_object_flag("map_object_instance.rough_ground_north", "is_cleared", true)
	_expect_text_contains(
		formatter.format_build_prompt(foundation_site, build_character, build_world),
		"缺少建造材料",
		"foundation missing material prompt"
	)

	build_character.inventory.add_item("item.foundation_material", 1)
	_expect_text_contains(
		formatter.format_build_prompt(foundation_site, build_character, build_world),
		"按 E 建造",
		"foundation ready prompt"
	)

	var filter_site := PrototypeInteractable.new()
	filter_site.definition_id = "building.pollution_filter"
	filter_site.interaction_type = "build"
	filter_site.instance_id = "map_object_instance.pollution_filter_build_site"
	_expect_text_contains(
		formatter.format_build_prompt(filter_site, build_character, build_world),
		"基础地基：0 / 2",
		"pollution filter foundation status"
	)
	build_world.add_base_structure("structure.foundation_site_north", "building.foundation_t1", "region.pollution_edge")
	build_world.add_base_structure("structure.foundation_site_south", "building.foundation_t1", "region.pollution_edge")
	_expect_text_contains(
		formatter.format_build_prompt(filter_site, build_character, build_world),
		"缺少建造材料",
		"pollution filter missing material prompt"
	)
	rough_ground.free()
	foundation_site.free()
	filter_site.free()


func _check_supply_feedback() -> void:
	var supply_character := CharacterState.create_default()
	supply_character.health = 45.0
	var repair_result := supply_character.use_quick_slot(0, data_registry)
	_expect_equal(bool(repair_result.get("success", false)), true, "repair gel should be usable")
	_expect_equal(supply_character.health, 80.0, "repair gel health recovery")
	_expect_feedback_contains(repair_result, "生命 +35", "repair gel feedback")
	_expect_feedback_contains(repair_result, "当前 80 / 100", "repair gel current health feedback")

	var full_health_character := CharacterState.create_default()
	var full_health_blocked := full_health_character.use_quick_slot(0, data_registry)
	_expect_equal(bool(full_health_blocked.get("success", true)), false, "full health should block repair gel")
	_expect_feedback_contains(full_health_blocked, "生命已满", "full health supply feedback")

	var missing_repair_result := supply_character.use_quick_slot(0, data_registry)
	_expect_equal(bool(missing_repair_result.get("success", true)), false, "missing repair gel should fail")
	_expect_feedback_contains(missing_repair_result, "基础反应器", "missing repair gel refill hint")

	var missing_vial_character := CharacterState.create_default()
	missing_vial_character.protection = 30.0
	missing_vial_character.inventory.items.erase("item.resistance_vial_t1")
	var missing_vial_result := missing_vial_character.use_quick_slot(1, data_registry)
	_expect_equal(bool(missing_vial_result.get("success", true)), false, "missing vial should fail")
	_expect_feedback_contains(missing_vial_result, "污染过滤器", "missing vial refill hint")


func _check_hud_feedback_presenter() -> void:
	var presenter := HudFeedbackPresenter.new()
	var supply_feedback := {
		"title": "补给已使用",
		"detail": "生命 +35"
	}
	var evacuation_feedback := {
		"title": "撤离前哨",
		"reason_text": "生命耗尽"
	}

	_expect_equal(
		presenter.get_supply_feedback({"supply_feedback": supply_feedback}),
		supply_feedback,
		"presenter extracts supply feedback"
	)
	_expect_equal(
		presenter.get_evacuation_feedback({"evacuation_feedback": evacuation_feedback}),
		evacuation_feedback,
		"presenter extracts evacuation feedback"
	)
	_expect_equal(
		presenter.get_supply_feedback({"supply_feedback": "invalid"}),
		{},
		"presenter ignores invalid supply feedback"
	)
	_expect_equal(
		presenter.get_evacuation_feedback({}),
		{},
		"presenter ignores missing evacuation feedback"
	)


func _check_pollution_status_hints() -> void:
	var hud := PrototypeHud.new()
	var pollution_world := WorldState.create_default()
	var pollution_character := CharacterState.create_default()
	_expect_text_contains(
		hud._format_pollution_status(data_registry, pollution_world, pollution_character),
		"无持续污染压力",
		"stable region pollution status"
	)

	pollution_world.current_region_id = "region.pollution_edge"
	pollution_character.current_region_id = "region.pollution_edge"
	_expect_text_contains(
		hud._format_pollution_status(data_registry, pollution_world, pollution_character),
		"未启用过滤模块",
		"pollution status without module"
	)

	pollution_character.equipment["suit_module"] = "equipment.filter_module_t1"
	_expect_text_contains(
		hud._format_pollution_status(data_registry, pollution_world, pollution_character),
		"消耗 x0.65",
		"pollution status with module"
	)

	pollution_character.protection = 30.0
	_expect_text_contains(
		hud._format_pollution_status(data_registry, pollution_world, pollution_character),
		"防护危险",
		"low protection pollution status"
	)
	hud.free()


func _check_region_prompt_formatter() -> void:
	var formatter := InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)
	var gate_world := WorldState.create_default()
	var gate_character := CharacterState.create_default()
	_expect_text_contains(
		formatter.format_pollution_gate_hint(gate_world, gate_character),
		"处理点扩建",
		"pollution gate requires treatment point"
	)
	_expect_text_contains(
		formatter.format_pollution_gate_hint(gate_world, gate_character),
		"启用基础过滤模块",
		"pollution gate requires module"
	)
	gate_character.protection = 30.0
	_expect_text_contains(
		formatter.format_pollution_entry_warning(gate_character),
		"污染边界警告",
		"pollution entry warning title"
	)
	_expect_text_contains(
		formatter.format_region_gate_blocked_log("污染边界尚未稳定。", "需要：先完成处理点扩建。"),
		"通行受阻：污染边界",
		"region gate blocked log title"
	)
	_expect_text_contains(
		formatter.format_region_gate_blocked_log("污染边界尚未稳定。", "需要：先完成处理点扩建。"),
		"下一步：需要：先完成处理点扩建。",
		"region gate blocked next step"
	)

	var ruin_world := WorldState.create_default()
	_expect_text_contains(
		formatter.format_ruin_gate_prompt(ruin_world),
		"先治理污染边界",
		"ruin gate blocked prompt"
	)
	ruin_world.quest_state.completed_quest_ids.append("quest.enter_pollution_edge")
	_expect_text_contains(
		formatter.format_ruin_gate_prompt(ruin_world),
		"按 E 确认",
		"ruin gate ready prompt"
	)
	ruin_world.quest_state.completed_quest_ids.append("quest.unlock_ruin_signal")
	_expect_text_contains(
		formatter.format_ruin_gate_prompt(ruin_world),
		"后续内容待开放",
		"ruin gate completed prompt"
	)


func _check_failure_feedback_logs() -> void:
	var game_root = GameRootScript.new()
	var no_target_map := VerticalSliceMap.new()
	var no_target := no_target_map.try_interact(CharacterState.create_default(), WorldState.create_default())
	_expect_failure_feedback(no_target, "交互未执行", "no target interaction feedback")
	_expect_text_contains(
		game_root._format_failure_result_log(no_target),
		"下一步：靠近带名称的目标",
		"no target failure log"
	)
	no_target_map.free()

	var no_enemy_map := VerticalSliceMap.new()
	no_enemy_map.enemies_root = Node2D.new()
	var no_enemy := no_enemy_map.try_attack(CharacterState.create_default(), WorldState.create_default())
	_expect_failure_feedback(no_enemy, "攻击未命中", "no enemy attack feedback")
	no_enemy_map.enemies_root.free()
	no_enemy_map.free()

	var processing := ProcessingSystem.new(data_registry)
	var processing_world := WorldState.create_default()
	var processing_character := CharacterState.create_default()
	processing_world.quest_state.unlock_effect("recipe.process_crystal_ore")
	var missing_inputs := processing.process_recipe("recipe.process_crystal_ore", processing_character, processing_world)
	_expect_failure_feedback(missing_inputs, "原料不足", "processing missing inputs feedback")

	processing_character.inventory.add_item("item.crystal_ore", 3)
	var started := processing.process_recipe("recipe.process_crystal_ore", processing_character, processing_world)
	_expect_equal(bool(started.get("success", false)), true, "processing starts before in-progress failure")
	var in_progress := processing.process_recipe("recipe.process_crystal_ore", processing_character, processing_world)
	_expect_failure_feedback(in_progress, "设备加工中", "processing in progress feedback")

	var build_system := BuildSystem.new(data_registry)
	var build_world := WorldState.create_default()
	var build_character := CharacterState.create_default()
	var blocked_build := build_system.build_structure(
		"map_object_instance.pollution_filter_build_site",
		"building.pollution_filter",
		build_character,
		build_world
	)
	_expect_failure_feedback(blocked_build, "建造前置不足", "build prerequisite feedback")

	game_root.free()


func _check_device_panel_formatting() -> void:
	var hud := PrototypeHud.new()
	var processing := ProcessingSystem.new(data_registry)
	var device_world := WorldState.create_default()
	var device_character := CharacterState.create_default()
	var reactor := PrototypeInteractable.new()
	reactor.definition_id = "building.basic_reactor"
	reactor.interaction_type = "process_recipe"
	reactor.recipe_id = "recipe.process_crystal_ore"
	reactor.set_recipe_cycle([
		"recipe.process_crystal_ore",
		"recipe.reactor_calibrator",
		"recipe.make_filter_media",
		"recipe.basic_filter_module",
		"recipe.foundation_t1",
		"recipe.repair_gel"
	])
	device_world.quest_state.unlock_effect("recipe.process_crystal_ore")
	device_character.inventory.add_item("item.crystal_ore", 3)

	var texts := hud.format_device_panel_texts(data_registry, processing, reactor, device_character, device_world)
	_expect_text_contains(String(texts.get("title", "")), "基础反应器", "device panel title")
	_expect_text_contains(String(texts.get("status", "")), "当前配方：处理晶体矿物", "device panel current recipe")
	_expect_text_contains(String(texts.get("recipes", "")), "> 1. 处理晶体矿物：可加工", "device panel recipe list")
	_expect_text_contains(String(texts.get("operations", "")), "E 启动当前配方", "device panel process operation")
	_expect_text_contains(String(texts.get("operations", "")), "R 切换配方", "device panel cycle operation")
	_expect_text_contains(String(texts.get("operations", "")), "Q 关闭面板", "device panel close operation")

	var filter := PrototypeInteractable.new()
	filter.definition_id = "building.pollution_filter"
	filter.interaction_type = "process_recipe"
	filter.recipe_id = "recipe.cleanse_residue"
	filter.set_recipe_cycle(["recipe.cleanse_residue"])
	var filter_world := WorldState.create_default()
	var filter_character := CharacterState.create_default()
	filter_world.quest_state.unlock_effect("recipe.cleanse_residue")
	filter_world.add_base_structure(
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.pollution_edge",
		"map_object_instance.pollution_filter_build_site"
	)
	var filter_texts := hud.format_device_panel_texts(data_registry, processing, filter, filter_character, filter_world)
	_expect_text_contains(String(filter_texts.get("title", "")), "污染过滤器", "filter device panel title")
	_expect_text_contains(String(filter_texts.get("recipes", "")), "缺 污染沉积物 x2", "filter device panel missing input")
	_expect_text_contains(String(filter_texts.get("operations", "")), "E 尝试当前配方", "filter device panel blocked operation")

	reactor.free()
	filter.free()
	hud.free()


func _complete_active_quest(quest_id: String, progress_refs: Array) -> void:
	if not world_state.quest_state.has_active_quest(quest_id):
		failures.append("%s should be active before completion" % quest_id)
		return

	for progress_ref in progress_refs:
		if not progress_ref is Dictionary:
			continue
		world_state.quest_state.set_objective_progress(
			quest_id,
			String(progress_ref.get("type", "")),
			String(progress_ref.get("target_id", "")),
			float(progress_ref.get("amount", 1.0))
		)

	if not _are_objectives_complete(quest_id):
		failures.append("%s objectives should be complete before applying rewards" % quest_id)
		return

	var quest := data_registry.get_definition(quest_id)
	world_state.quest_state.complete_quest(quest_id)
	_grant_refs(quest.get("rewards", []))
	for effect_id in quest.get("unlock_effects", []):
		_apply_unlock(String(effect_id))
	for next_quest_id in quest.get("next_quest_ids", []):
		world_state.quest_state.activate_quest(String(next_quest_id))


func _are_objectives_complete(quest_id: String) -> bool:
	var quest := data_registry.get_definition(quest_id)
	if quest.is_empty():
		failures.append("missing quest definition: %s" % quest_id)
		return false

	for objective in quest.get("objectives", []):
		if not objective is Dictionary:
			continue
		var objective_type := String(objective.get("type", ""))
		var target_id := String(objective.get("target_id", ""))
		var required_amount := float(objective.get("amount", 1.0))
		var current_amount := world_state.quest_state.get_objective_progress(quest_id, objective_type, target_id)
		if current_amount < required_amount:
			return false
	return true


func _grant_refs(refs: Array) -> void:
	for ref in refs:
		if not ref is Dictionary:
			continue

		var definition_id := String(ref.get("id", ""))
		var amount := float(ref.get("amount", 0.0))
		if definition_id.is_empty() or amount <= 0.0:
			continue
		character_state.inventory.add_ref(definition_id, amount)


func _apply_unlock(effect_id: String) -> void:
	if effect_id.begins_with("region."):
		world_state.unlock_region(effect_id)
	world_state.quest_state.unlock_effect(effect_id)


func _check_processing_runtime() -> void:
	var processing := ProcessingSystem.new(data_registry)
	var processing_world := WorldState.create_default()
	var processing_character := CharacterState.create_default()
	processing_world.quest_state.unlock_effect("recipe.process_crystal_ore")
	processing_character.inventory.add_item("item.crystal_ore", 3)

	var start_result := processing.process_recipe("recipe.process_crystal_ore", processing_character, processing_world)
	_expect_equal(bool(start_result.get("success", false)), true, "processing should start")
	_expect_equal(int(processing_character.inventory.items.get("item.crystal_ore", 0)), 0, "processing consumes inputs on start")
	_expect_equal(int(processing_character.inventory.items.get("item.basic_parts", 0)), 4, "processing should not grant outputs on start")

	var reactor: Dictionary = processing_world.base_structures.get("structure.basic_reactor", {})
	_expect_equal(String(reactor.get("status", "")), "in_progress", "reactor status after start")
	_expect_equal(String(reactor.get("active_recipe_id", "")), "recipe.process_crystal_ore", "reactor active recipe")

	var partial_results := processing.advance_processing(3.0, processing_character, processing_world)
	_expect_equal(partial_results.size(), 0, "processing should not complete early")
	reactor = processing_world.base_structures.get("structure.basic_reactor", {})
	_expect_equal(float(reactor.get("progress_seconds", 0.0)), 3.0, "reactor partial progress")

	var status := processing.get_recipe_status("recipe.process_crystal_ore", processing_character, processing_world)
	if String(status.get("message", "")).find("加工中") < 0:
		failures.append("processing status should show in progress, got %s" % var_to_str(status))

	var completed_results := processing.advance_processing(10.0, processing_character, processing_world)
	_expect_equal(completed_results.size(), 1, "processing should complete after duration")
	if not completed_results.is_empty():
		_expect_text_contains(
			String(completed_results[0].get("message", "")),
			"产物已放入背包：基础零件 x2",
			"processing completion log destination"
		)
		_expect_text_contains(
			String(completed_results[0].get("message", "")),
			"下一步：",
			"processing completion log next step"
		)
	_expect_equal(int(processing_character.inventory.items.get("item.basic_parts", 0)), 6, "processing grants outputs on completion")
	reactor = processing_world.base_structures.get("structure.basic_reactor", {})
	_expect_equal(String(reactor.get("status", "")), "completed", "reactor status after completion")
	_expect_equal(String(reactor.get("active_recipe_id", "")), "", "reactor clears active recipe after completion")
	_expect_equal(String(reactor.get("last_recipe_id", "")), "recipe.process_crystal_ore", "reactor last recipe after completion")
	_expect_equal(int(reactor.get("completed_runs", 0)), 1, "reactor completed runs")
	var completed_status := processing.get_recipe_status("recipe.process_crystal_ore", processing_character, processing_world)
	_expect_text_contains(
		String(completed_status.get("last_completion", "")),
		"刚完成：处理晶体矿物",
		"processing panel last completion"
	)
	_expect_text_contains(
		String(completed_status.get("last_destination", "")),
		"产物已放入背包：基础零件 x2",
		"processing panel destination"
	)
	_expect_text_contains(
		String(completed_status.get("last_next_step", "")),
		"按 R 切换",
		"processing panel next step"
	)

	var filter_world := WorldState.create_default()
	var filter_character := CharacterState.create_default()
	filter_world.quest_state.unlock_effect("recipe.cleanse_residue")
	filter_world.add_base_structure(
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.pollution_edge",
		"map_object_instance.pollution_filter_build_site"
	)
	filter_character.inventory.add_item("item.polluted_residue", 2)
	filter_character.inventory.add_fluid("fluid.basic_solvent", 1.0)

	var filter_start := processing.process_recipe("recipe.cleanse_residue", filter_character, filter_world)
	_expect_equal(bool(filter_start.get("success", false)), true, "pollution filter should start")
	_expect_equal(filter_world.base_structures.has("structure.pollution_filter"), false, "processing should reuse built pollution filter structure")
	var filter_completed := processing.advance_processing(20.0, filter_character, filter_world)
	_expect_equal(filter_completed.size(), 1, "pollution filter should complete")
	if not filter_completed.is_empty():
		_expect_text_contains(
			String(filter_completed[0].get("message", "")),
			"产物已放入背包：抗污染药剂 I x1",
			"pollution filter completion log output destination"
		)
		_expect_text_contains(
			String(filter_completed[0].get("message", "")),
			"副产已放入背包：污染浆液 x1",
			"pollution filter completion log byproduct destination"
		)
		_expect_text_contains(
			String(filter_completed[0].get("message", "")),
			"继续采集沉积物并清理受扰敌人",
			"pollution filter completion log next step"
		)
	_expect_equal(int(filter_character.inventory.items.get("item.resistance_vial_t1", 0)), 1, "pollution filter grants vial")
	_expect_equal(float(filter_character.inventory.fluids.get("fluid.polluted_slurry", 0.0)), 1.0, "pollution filter grants byproduct")
	var filter_status := processing.get_recipe_status("recipe.cleanse_residue", filter_character, filter_world)
	_expect_text_contains(
		String(filter_status.get("last_completion", "")),
		"刚完成：处理污染沉积物",
		"pollution filter panel last completion"
	)
	_expect_text_contains(
		String(filter_status.get("last_destination", "")),
		"副产已放入背包：污染浆液 x1",
		"pollution filter panel byproduct destination"
	)
	_expect_text_contains(
		String(filter_status.get("last_next_step", "")),
		"抗污染药剂",
		"pollution filter panel next step"
	)


func _check_evacuation_feedback() -> void:
	var map := VerticalSliceMap.new()
	map.player = PlayerController.new()
	var evacuation_world := WorldState.create_default()
	var evacuation_character := CharacterState.create_default()
	evacuation_character.health = 0.0
	evacuation_character.protection = 80.0
	evacuation_character.current_region_id = "region.pollution_edge"
	evacuation_world.current_region_id = "region.pollution_edge"

	var feedback := map._evacuate_if_needed(evacuation_character, evacuation_world, "combat")
	_expect_equal(String(feedback.get("title", "")), "撤离前哨", "evacuation feedback title")
	_expect_equal(String(feedback.get("reason_text", "")), "生命耗尽", "evacuation reason")
	_expect_equal(evacuation_world.current_region_id, "region.outpost_platform", "evacuation world region")
	_expect_equal(evacuation_character.current_region_id, "region.outpost_platform", "evacuation character region")
	_expect_equal(evacuation_character.health, 60.0, "evacuation health recovery")
	if String(feedback.get("retry_text", "")).find("修复凝胶") < 0:
		failures.append("evacuation retry text should mention repair gel, got %s" % var_to_str(feedback))
	var hud := PrototypeHud.new()
	var panel_texts := hud.format_evacuation_panel_texts(feedback)
	_expect_equal(String(panel_texts.get("title", "")), "撤离结果：生命耗尽", "evacuation panel title")
	_expect_text_contains(String(panel_texts.get("detail", "")), "原因：生命耗尽", "evacuation panel reason")
	_expect_text_contains(String(panel_texts.get("detail", "")), "恢复：已撤回前哨", "evacuation panel recovery")
	_expect_text_contains(String(panel_texts.get("detail", "")), "再尝试前：按 1 使用修复凝胶", "evacuation panel retry")
	hud.free()
	map.player.free()
	map.free()


func _expect_active_quest(quest_id: String, label: String) -> void:
	_expect_array_has(world_state.quest_state.active_quest_ids, quest_id, label)


func _expect_equal(actual, expected, label: String) -> void:
	if actual != expected:
		failures.append("%s expected %s, got %s" % [label, var_to_str(expected), var_to_str(actual)])


func _expect_array_has(values: Array, expected_value: String, label: String) -> void:
	if not values.has(expected_value):
		failures.append("%s should contain %s, got %s" % [label, expected_value, var_to_str(values)])


func _expect_array_missing(values: Array, unexpected_value: String, label: String) -> void:
	if values.has(unexpected_value):
		failures.append("%s should not contain %s, got %s" % [label, unexpected_value, var_to_str(values)])


func _expect_hint_contains(hud: PrototypeHud, hint_world: WorldState, hint_character: CharacterState, quest_id: String, expected_text: String, label: String) -> void:
	var hint := hud._format_onboarding_hint(hint_world, hint_character, quest_id)
	if hint.find(expected_text) < 0:
		failures.append("%s should contain %s, got %s" % [label, expected_text, hint])


func _expect_text_contains(text: String, expected_text: String, label: String) -> void:
	if text.find(expected_text) < 0:
		failures.append("%s should contain %s, got %s" % [label, expected_text, text])


func _expect_text_missing(text: String, unexpected_text: String, label: String) -> void:
	if text.find(unexpected_text) >= 0:
		failures.append("%s should not contain %s, got %s" % [label, unexpected_text, text])


func _expect_feedback_contains(result: Dictionary, expected_text: String, label: String) -> void:
	var feedback = result.get("supply_feedback", {})
	if not feedback is Dictionary:
		failures.append("%s should include supply feedback, got %s" % [label, var_to_str(result)])
		return

	var text := "%s %s" % [
		String(feedback.get("title", "")),
		String(feedback.get("detail", ""))
	]
	_expect_text_contains(text, expected_text, label)


func _create_visual_check_interactable(
	parent: Node,
	instance_id: String,
	definition_id: String,
	interaction_type: String,
	display_name: String
) -> PrototypeInteractable:
	var interactable := PrototypeInteractable.new()
	var marker := ColorRect.new()
	marker.name = "Marker"
	marker.offset_left = -16.0
	marker.offset_top = -16.0
	marker.offset_right = 16.0
	marker.offset_bottom = 16.0
	marker.color = PrototypeInteractable.DEFAULT_MARKER_COLOR
	interactable.add_child(marker)
	interactable.marker = marker
	var label := Label.new()
	label.name = "Label"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interactable.add_child(label)
	interactable.label = label
	parent.add_child(interactable)
	interactable.instance_id = instance_id
	interactable.definition_id = definition_id
	interactable.interaction_type = interaction_type
	interactable.setup(display_name)
	return interactable


func _create_visual_check_enemy(
	definition_id: String,
	display_name: String,
	max_health: float,
	category: String
) -> PrototypeEnemy:
	var enemy := PrototypeEnemy.new()
	var collision_shape := CollisionShape2D.new()
	collision_shape.name = "CollisionShape2D"
	collision_shape.shape = CircleShape2D.new()
	enemy.add_child(collision_shape)
	enemy.collision_shape = collision_shape
	var sprite := ColorRect.new()
	sprite.name = "Sprite"
	sprite.color = Color(0.8, 0.313726, 0.215686, 1)
	enemy.add_child(sprite)
	enemy.sprite = sprite
	var label := Label.new()
	label.name = "Label"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	enemy.add_child(label)
	enemy.label = label
	enemy.definition_id = definition_id
	enemy.setup(display_name, max_health, category)
	return enemy


func _expect_failure_feedback(result: Dictionary, expected_title: String, label: String) -> void:
	_expect_equal(bool(result.get("success", true)), false, "%s success state" % label)
	var feedback = result.get("failure_feedback", {})
	if not feedback is Dictionary:
		failures.append("%s should include failure feedback, got %s" % [label, var_to_str(result)])
		return
	_expect_equal(String(feedback.get("title", "")), expected_title, label)
	if String(feedback.get("detail", "")).strip_edges().is_empty():
		failures.append("%s should include next-step detail, got %s" % [label, var_to_str(feedback)])


func _cleanup() -> void:
	data_registry.free()
