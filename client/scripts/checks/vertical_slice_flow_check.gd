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
	_check_region_markers()
	_check_quest_completion_panel_text()
	_check_build_prompts()
	_check_supply_feedback()
	_check_pollution_status_hints()
	_check_failure_feedback_logs()

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
	_expect_active_quest("quest.bring_back_sample", "after scout crystal field")

	_complete_active_quest("quest.bring_back_sample", [
		{"type": "sample_object", "target_id": "map_object.anomaly_crystal", "amount": 1},
		{"type": "return_region", "target_id": "region.outpost_platform", "amount": 1}
	])
	_expect_active_quest("quest.make_filter_module", "after bring back sample")
	_expect_array_has(world_state.quest_state.unlocked_effects, "recipe.make_filter_media", "sample unlocks filter media recipe")

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

	marker_world.unlock_region("region.crystal_vein_field")
	_expect_text_contains(
		hud._format_region_markers(marker_world, "quest.scout_crystal_field"),
		"晶体：东侧，目标",
		"crystal marker as objective"
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
	hud.free()


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
	var game_root = GameRootScript.new()
	game_root.data_registry = data_registry
	game_root.build_system = BuildSystem.new(data_registry)
	game_root.world_state = WorldState.create_default()
	game_root.character_state = CharacterState.create_default()

	var rough_ground := PrototypeInteractable.new()
	rough_ground.definition_id = "map_object.rough_ground"
	rough_ground.interaction_type = "clear"
	rough_ground.instance_id = "map_object_instance.rough_ground_north"
	_expect_text_contains(
		game_root._format_clear_prompt(rough_ground),
		"阻挡建造",
		"rough ground prompt"
	)

	var foundation_site := PrototypeInteractable.new()
	foundation_site.definition_id = "building.foundation_t1"
	foundation_site.interaction_type = "build"
	foundation_site.instance_id = "map_object_instance.foundation_site_north"
	foundation_site.prerequisite_instance_id = "map_object_instance.rough_ground_north"
	_expect_text_contains(
		game_root._format_build_prompt(foundation_site),
		"地面仍然粗糙",
		"foundation blocked prompt"
	)

	game_root.world_state.ensure_map_object("map_object_instance.rough_ground_north", "map_object.rough_ground", "region.pollution_edge")
	game_root.world_state.set_map_object_flag("map_object_instance.rough_ground_north", "is_cleared", true)
	_expect_text_contains(
		game_root._format_build_prompt(foundation_site),
		"缺少建造材料",
		"foundation missing material prompt"
	)

	game_root.character_state.inventory.add_item("item.foundation_material", 1)
	_expect_text_contains(
		game_root._format_build_prompt(foundation_site),
		"按 E 建造",
		"foundation ready prompt"
	)

	var filter_site := PrototypeInteractable.new()
	filter_site.definition_id = "building.pollution_filter"
	filter_site.interaction_type = "build"
	filter_site.instance_id = "map_object_instance.pollution_filter_build_site"
	_expect_text_contains(
		game_root._format_build_prompt(filter_site),
		"基础地基：0 / 2",
		"pollution filter foundation status"
	)
	game_root.world_state.add_base_structure("structure.foundation_site_north", "building.foundation_t1", "region.pollution_edge")
	game_root.world_state.add_base_structure("structure.foundation_site_south", "building.foundation_t1", "region.pollution_edge")
	_expect_text_contains(
		game_root._format_build_prompt(filter_site),
		"缺少建造材料",
		"pollution filter missing material prompt"
	)
	rough_ground.free()
	foundation_site.free()
	filter_site.free()
	game_root.free()


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

	var game_root = GameRootScript.new()
	game_root.world_state = WorldState.create_default()
	game_root.character_state = CharacterState.create_default()
	_expect_text_contains(
		game_root._get_pollution_gate_hint(),
		"处理点扩建",
		"pollution gate requires treatment point"
	)
	_expect_text_contains(
		game_root._get_pollution_gate_hint(),
		"启用基础过滤模块",
		"pollution gate requires module"
	)
	game_root.free()


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

	_expect_text_contains(
		game_root._format_region_gate_blocked_log("污染边界尚未稳定。", "需要：先完成处理点扩建。"),
		"通行受阻：污染边界",
		"region gate blocked log title"
	)
	_expect_text_contains(
		game_root._format_region_gate_blocked_log("污染边界尚未稳定。", "需要：先完成处理点扩建。"),
		"下一步：需要：先完成处理点扩建。",
		"region gate blocked next step"
	)
	game_root.free()


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
	_expect_equal(int(processing_character.inventory.items.get("item.basic_parts", 0)), 6, "processing grants outputs on completion")
	reactor = processing_world.base_structures.get("structure.basic_reactor", {})
	_expect_equal(String(reactor.get("status", "")), "completed", "reactor status after completion")
	_expect_equal(String(reactor.get("active_recipe_id", "")), "", "reactor clears active recipe after completion")
	_expect_equal(String(reactor.get("last_recipe_id", "")), "recipe.process_crystal_ore", "reactor last recipe after completion")
	_expect_equal(int(reactor.get("completed_runs", 0)), 1, "reactor completed runs")

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
	_expect_equal(int(filter_character.inventory.items.get("item.resistance_vial_t1", 0)), 1, "pollution filter grants vial")
	_expect_equal(float(filter_character.inventory.fluids.get("fluid.polluted_slurry", 0.0)), 1.0, "pollution filter grants byproduct")


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
