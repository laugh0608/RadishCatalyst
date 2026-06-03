extends RefCounted

var host


func _init(check_host) -> void:
	host = check_host


func run() -> void:
	var processing := ProcessingSystem.new(host.data_registry)
	_check_phase_survey_choice_entry()
	_check_phase_survey_field_targets()
	_check_phase_survey_feedback_guidance(processing)
	_check_s20_phase_survey_baseline()


func _check_phase_survey_choice_entry() -> void:
	var builder := DevelopmentBaselineBuilder.new(host.data_registry)
	var s19_result := builder.create_baseline_state("baseline.s19_route_action_feedback_ready")
	host._expect_equal(bool(s19_result.get("success", false)), true, "S19 baseline generation for phase survey choice entry")
	if not bool(s19_result.get("success", false)):
		return

	var s19_world: WorldState = s19_result.get("world_state", null)
	var s19_character: CharacterState = s19_result.get("character_state", null)
	if s19_world == null or s19_character == null:
		host.failures.append("S19 baseline should return states for phase survey choice entry")
		return

	var survey_prompt := BaseActionDispatchPlan.format_console_prompt(
		"map_object.base_survey_choice_console",
		s19_world,
		s19_character
	)
	host._expect_text_contains(survey_prompt, "按 E 选择：相位测绘方案", "S19 survey console exposes choice action")
	host._expect_text_contains(survey_prompt, "读取西侧和东侧", "S19 survey console explains two-point target")
	host._expect_text_contains(survey_prompt, "目标显形和路线风险预告", "S19 survey console explains route hint payoff")

	var runtime := QuestRuntime.new(host.data_registry)
	var choice_result := runtime.advance_for_interaction(
		s19_world,
		s19_character,
		{
			"definition_id": "map_object.base_survey_choice_console",
			"interaction_type": "inspect"
		},
		{"success": true}
	)
	host._expect_equal(bool(choice_result.get("accepted", false)), true, "phase survey choice advances active quest")
	host._expect_equal(
		s19_world.quest_state.active_quest_ids,
		["quest.inspect_phase_survey_nodes"],
		"phase survey choice activates two-node field target"
	)


func _check_phase_survey_field_targets() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	world_state.quest_state.active_quest_ids = ["quest.inspect_phase_survey_nodes"]
	var formatter := InteractionPromptFormatter.new(
		host.data_registry,
		ProcessingSystem.new(host.data_registry),
		BuildSystem.new(host.data_registry)
	)
	var gather := GatherSystem.new(host.data_registry)
	var runtime := QuestRuntime.new(host.data_registry)
	var west_node := _make_interactable(
		"map_object_instance.phase_survey_node_west",
		"map_object.phase_survey_node_west"
	)
	var east_node := _make_interactable(
		"map_object_instance.phase_survey_node_east",
		"map_object.phase_survey_node_east"
	)

	host._expect_text_contains(
		formatter.format_frontline_action_target_prompt(west_node, character_state, world_state),
		"当前进度 0/2",
		"phase survey west prompt starts at two-node progress"
	)
	var west_result := gather.interact_with_object(
		west_node.instance_id,
		west_node.definition_id,
		west_node.interaction_type,
		character_state,
		world_state
	)
	host._expect_equal(bool(west_result.get("success", false)), true, "phase survey west interaction succeeds")
	host._expect_text_contains(String(west_result.get("message", "")), "继续读取东侧测绘点", "phase survey west result points to east node")
	runtime.advance_for_interaction(
		world_state,
		character_state,
		{
			"definition_id": west_node.definition_id,
			"interaction_type": west_node.interaction_type
		},
		{"success": true}
	)
	host._expect_text_contains(
		formatter.format_frontline_action_target_prompt(east_node, character_state, world_state),
		"当前进度 1/2",
		"phase survey east prompt keeps partial progress"
	)
	var east_result := gather.interact_with_object(
		east_node.instance_id,
		east_node.definition_id,
		east_node.interaction_type,
		character_state,
		world_state
	)
	host._expect_equal(bool(east_result.get("success", false)), true, "phase survey east interaction succeeds")
	host._expect_text_contains(String(east_result.get("message", "")), "回基地解析路线提示", "phase survey east result points back to base analysis")
	runtime.advance_for_interaction(
		world_state,
		character_state,
		{
			"definition_id": east_node.definition_id,
			"interaction_type": east_node.interaction_type
		},
		{"success": true}
	)
	host._expect_equal(
		world_state.quest_state.active_quest_ids,
		["quest.analyze_phase_survey_trace"],
		"phase survey nodes activate feedback analysis"
	)
	host._expect_array_has(world_state.quest_state.unlocked_effects, "recipe.phase_survey_feedback", "phase survey nodes unlock feedback recipe")
	west_node.free()
	east_node.free()


func _check_phase_survey_feedback_guidance(processing: ProcessingSystem) -> void:
	host._expect_text_contains(
		RecipePurposeHints.format_recipe_goal_hint("recipe.phase_survey_feedback"),
		"前线行动台确认测绘路线整备槽",
		"phase survey feedback purpose points to departure slot"
	)
	host._expect_text_contains(
		processing._get_completion_next_step("recipe.phase_survey_feedback"),
		"前线行动台确认测绘路线整备槽",
		"phase survey feedback completion points to departure slot"
	)
	var missing_feedback_hint := processing._format_mid_demo_missing_input_supply_hint(
		host.data_registry.get_definition("recipe.phase_survey_feedback"),
		CharacterState.create_default().inventory
	)
	host._expect_text_contains(
		missing_feedback_hint,
		"读取西侧和东侧两处相位测绘点",
		"phase survey feedback missing trace points back to field nodes"
	)

	var reactor := PrototypeInteractable.new()
	reactor.definition_id = "building.basic_reactor"
	reactor.interaction_type = "process_recipe"
	reactor.recipe_id = "recipe.process_crystal_ore"
	reactor.set_recipe_cycle([
		"recipe.process_crystal_ore",
		"recipe.phase_survey_feedback"
	])
	var reactor_world := WorldState.create_default()
	reactor_world.quest_state.active_quest_ids = ["quest.analyze_phase_survey_trace"]
	reactor_world.quest_state.unlock_effect("recipe.phase_survey_feedback")
	var reactor_character := CharacterState.create_default()
	reactor_character.inventory.add_item("item.phase_survey_trace", 1)
	var reactor_texts := HudDevicePanelPresenter.new().format_device_panel_texts(
		host.data_registry,
		processing,
		reactor,
		reactor_character,
		reactor_world
	)
	host._expect_text_contains(
		String(reactor_texts.get("status", "")),
		"前线行动台确认测绘路线整备槽",
		"reactor device panel explains phase survey feedback payoff"
	)
	host._expect_text_contains(
		String(reactor_texts.get("recipes", "")),
		"当前目标",
		"reactor device panel marks phase survey feedback as current target"
	)
	reactor.free()


func _check_s20_phase_survey_baseline() -> void:
	var builder := DevelopmentBaselineBuilder.new(host.data_registry)
	var s20_result := builder.create_baseline_state("baseline.s20_phase_survey_feedback_ready")
	host._expect_equal(bool(s20_result.get("success", false)), true, "S20 baseline generation for phase survey feedback")
	if not bool(s20_result.get("success", false)):
		return

	var s20_world: WorldState = s20_result.get("world_state", null)
	var s20_character: CharacterState = s20_result.get("character_state", null)
	if s20_world == null or s20_character == null:
		host.failures.append("S20 baseline should return states for phase survey feedback")
		return

	var s20_status := HudStatusPresenter.new().format_status_text(host.data_registry, s20_world, s20_character)
	host._expect_text_contains(s20_status, "目标：相位测绘反馈已归档", "S20 status panel shows survey feedback completion")
	host._expect_text_contains(s20_status, "按 E 确认测绘路线整备槽", "S20 status panel points to departure slot")
	host._expect_text_contains(
		BaseActionDispatchPlan.format_console_prompt("map_object.frontline_action_console", s20_world, s20_character),
		"按 E 确认：测绘路线整备槽",
		"S20 frontline action console exposes survey departure confirmation"
	)
	host._expect_text_contains(
		BaseActionDispatchPlan.format_console_prompt("map_object.frontline_action_console", s20_world, s20_character),
		"下一计划候选：压力清障",
		"S20 frontline action console shows next pressure candidate"
	)


func _make_interactable(instance_id: String, definition_id: String) -> PrototypeInteractable:
	var interactable := PrototypeInteractable.new()
	interactable.instance_id = instance_id
	interactable.definition_id = definition_id
	interactable.interaction_type = "inspect"
	return interactable
