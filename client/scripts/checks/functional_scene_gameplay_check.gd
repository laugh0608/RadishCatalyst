extends SceneTree

var failures: Array[String] = []
var data_registry := DataRegistry.new()


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		_run_checks()

	if failures.is_empty():
		print("Functional scene gameplay checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_formatter_covers_functional_scene_gameplay()
	_check_hud_summary_uses_scene_gameplay()
	_check_interaction_prompts_show_scene_gameplay()
	_check_runtime_interaction_results_show_scene_gameplay()


func _check_formatter_covers_functional_scene_gameplay() -> void:
	var region_ids := FunctionalSceneGameplayFormatter.get_region_ids()
	_expect_equal(region_ids.size(), 8, "functional scene gameplay covers eight non-core regions")

	var pending_state := {
		"definition_id": "map_object.phase_well_chamber_shunt_node",
		"region_id": "region.phase_well_chamber",
		"is_sampled": false
	}
	var pending_line := FunctionalSceneGameplayFormatter.format_object_gameplay_line(
		"map_object.phase_well_chamber_shunt_node",
		pending_state,
		"region.phase_well_chamber"
	)
	_expect_text_contains(pending_line, "现场玩法：碎晶分流读数", "pending gameplay line names shunt reading")
	_expect_text_contains(pending_line, "状态：待处理", "pending gameplay line names pending state")
	_expect_text_contains(pending_line, "回基地", "pending gameplay line keeps base followup")

	pending_state["is_sampled"] = true
	var complete_line := FunctionalSceneGameplayFormatter.format_object_gameplay_line(
		"map_object.phase_well_chamber_shunt_node",
		pending_state,
		"region.phase_well_chamber"
	)
	_expect_text_contains(complete_line, "状态：已处理", "complete gameplay line names processed state")
	_expect_text_contains(complete_line, "碎晶回收线稳定", "complete gameplay line names scene result")

	var tether_followup := FunctionalSceneGameplayFormatter.format_result_followup_line(
		"map_object.phase_well_tether_knot_node",
		null,
		"region.phase_well_tether"
	)
	_expect_text_contains(tether_followup, "现场阶段：锚定桥结点确认已完成", "result followup names completed bridge knot")
	_expect_text_contains(tether_followup, "核心稳定站", "result followup points to stabilization value")


func _check_hud_summary_uses_scene_gameplay() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	world.current_region_id = "region.phase_well_frame"
	world.ensure_map_object("map_object_instance.frame_route_blocker_check", "map_object.phase_well_frame_route_blocker", "region.phase_well_frame")

	var vitals_text := HudStatusPresenter.new().format_vitals_text(data_registry, world, character)
	_expect_text_contains(vitals_text, "现场玩法：锁相框架现场玩法", "HUD vitals show functional scene gameplay")
	_expect_text_contains(vitals_text, "现场进度：0/2", "HUD vitals show scene gameplay progress")
	_expect_text_contains(vitals_text, "清开一条侧路", "HUD vitals show next scene gameplay step")


func _check_interaction_prompts_show_scene_gameplay() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var formatter := InteractionPromptFormatter.new(
		data_registry,
		ProcessingSystem.new(data_registry),
		BuildSystem.new(data_registry)
	)

	world.current_region_id = "region.phase_well_chamber"
	var shunt := _create_interactable(
		"map_object_instance.functional_scene_shunt_prompt",
		"map_object.phase_well_chamber_shunt_node",
		"inspect"
	)
	var shunt_prompt := formatter.format_field_reading_prompt(shunt, world)
	_expect_text_contains(shunt_prompt, "现场玩法：碎晶分流读数", "field reading prompt shows gameplay stage")
	_expect_text_contains(shunt_prompt, "状态：待处理", "field reading prompt shows pending gameplay state")
	shunt.free()

	world.current_region_id = "region.phase_well_tether"
	var tether_prompt := formatter.format_phase_well_tether_prompt(world, character)
	_expect_text_contains(tether_prompt, "现场玩法：锚定桥断面勘验", "specialized prompt shows gameplay stage")
	_expect_text_contains(tether_prompt, "取出稳场锚核", "specialized prompt shows operation value")


func _check_runtime_interaction_results_show_scene_gameplay() -> void:
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var gather_system := GatherSystem.new(data_registry)

	world.current_region_id = "region.phase_well_chamber"
	character.current_region_id = "region.phase_well_chamber"
	var shunt_result := gather_system.interact_with_object(
		"map_object_instance.functional_scene_shunt_result",
		"map_object.phase_well_chamber_shunt_node",
		"inspect",
		character,
		world
	)
	_expect_equal(bool(shunt_result.get("success", false)), true, "field reading interaction succeeds")
	_expect_text_contains(String(shunt_result.get("message", "")), "现场阶段：碎晶分流读数已完成", "field reading result shows gameplay followup")
	_expect_equal(
		bool(world.get_map_object("map_object_instance.functional_scene_shunt_result").get("is_sampled", false)),
		true,
		"field reading writes map object sampled state"
	)

	world.current_region_id = "region.phase_well_frame"
	character.current_region_id = "region.phase_well_frame"
	var clear_result := gather_system.interact_with_object(
		"map_object_instance.functional_scene_frame_blocker",
		"map_object.phase_well_frame_route_blocker",
		"clear",
		character,
		world
	)
	_expect_equal(bool(clear_result.get("success", false)), true, "frame blocker clear succeeds")
	_expect_text_contains(String(clear_result.get("message", "")), "现场阶段：锁相侧路清理已完成", "clear result shows gameplay followup")
	_expect_equal(
		bool(world.get_map_object("map_object_instance.functional_scene_frame_blocker").get("is_cleared", false)),
		true,
		"frame blocker writes cleared state"
	)

	var vitals_text := HudStatusPresenter.new().format_vitals_text(data_registry, world, character)
	_expect_text_contains(vitals_text, "现场进度：1/2", "HUD updates gameplay progress after clear")


func _create_interactable(instance_id: String, definition_id: String, interaction_type: String) -> PrototypeInteractable:
	var interactable := PrototypeInteractable.new()
	interactable.instance_id = instance_id
	interactable.definition_id = definition_id
	interactable.interaction_type = interaction_type
	return interactable


func _expect_equal(actual, expected, context: String) -> void:
	if actual == expected:
		return
	failures.append("%s: expected %s, got %s" % [context, str(expected), str(actual)])


func _expect_text_contains(text: String, expected: String, context: String) -> void:
	if text.find(expected) >= 0:
		return
	failures.append("%s: expected text to contain '%s', got '%s'" % [context, expected, text])


func _cleanup() -> void:
	data_registry.free()
