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
	_check_s20_survey_departure_window()


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


func _check_s20_survey_departure_window() -> void:
	var builder := DevelopmentBaselineBuilder.new(host.data_registry)
	var s20_result := builder.create_baseline_state("baseline.s20_phase_survey_feedback_ready")
	host._expect_equal(bool(s20_result.get("success", false)), true, "S20 baseline generation for survey departure window")
	if not bool(s20_result.get("success", false)):
		return

	var world_state: WorldState = s20_result.get("world_state", null)
	var character_state: CharacterState = s20_result.get("character_state", null)
	if world_state == null or character_state == null:
		host.failures.append("S20 baseline should return states for survey departure window")
		return

	var gather := GatherSystem.new(host.data_registry)
	var slot_result := gather.interact_with_object(
		"map_object_instance.frontline_action_console",
		BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID,
		"inspect",
		character_state,
		world_state
	)
	host._expect_equal(bool(slot_result.get("success", false)), true, "S20 survey departure slot confirmation succeeds")
	host._expect_text_contains(String(slot_result.get("message", "")), "出发整备槽已确认：信息侦测计划", "S20 survey slot confirmation explains plan")
	host._expect_text_contains(String(slot_result.get("message", "")), "窗口结果预览", "S20 survey slot confirmation previews shared window")
	host._expect_equal(
		BaseActionDispatchPlan.get_survey_intel_status(world_state),
		BaseActionDispatchPlan.STATUS_QUEUED,
		"S20 survey intel becomes queued after slot confirmation"
	)
	host._expect_text_contains(
		BaseActionDispatchPlan.format_departure_preparation_prompt(world_state),
		"本次整备：信息侦测已确认",
		"S20 relay preparation prompt shows confirmed survey plan"
	)
	host._expect_text_contains(
		BaseActionDispatchPlan.format_status_progress(world_state),
		"到相位回投台按 E 出发",
		"S20 queued status points to phase relay pad"
	)

	var departure_messages := BaseActionDispatchPlan.apply_departure_preparation(world_state, character_state)
	host._expect_equal(departure_messages.size(), 2, "S20 survey departure loads intel and promotes candidate")
	host._expect_text_contains(String(departure_messages[0]), "信息侦测计划已执行", "S20 survey departure execution explains route intel")
	host._expect_text_contains(String(departure_messages[0]), "同一前线异常窗口已载入侦测解法", "S20 survey departure execution points to shared window")
	host._expect_text_contains(String(departure_messages[1]), "下一计划候选已进入当前计划槽", "S20 survey departure promotes next candidate")
	host._expect_equal(
		BaseActionDispatchPlan.is_frontline_window_active(world_state),
		true,
		"S20 survey departure activates shared frontline window"
	)
	host._expect_equal(
		BaseActionDispatchPlan.get_frontline_window_plan_key(world_state),
		BaseActionDispatchPlan.PLAN_PHASE_SURVEY,
		"S20 survey departure persists window plan"
	)
	var window_prompt := BaseActionDispatchPlan.format_frontline_window_prompt(world_state)
	host._expect_text_contains(window_prompt, "已载入信息侦测计划", "S20 active window prompt shows survey plan")
	host._expect_text_contains(window_prompt, "两处路线回波", "S20 active window prompt keeps survey target readable")
	host._expect_text_contains(window_prompt, "按 E 处理窗口", "S20 active window prompt exposes interaction")

	var window_result := gather.interact_with_object(
		"map_object_instance.prepared_frontline_window",
		"map_object.prepared_frontline_window",
		"inspect",
		character_state,
		world_state
	)
	host._expect_equal(bool(window_result.get("success", false)), true, "S20 survey shared window interaction succeeds")
	host._expect_text_contains(String(window_result.get("message", "")), "前线异常窗口已按信息侦测计划处理", "S20 survey window result explains feedback")
	host._expect_text_contains(
		BaseActionDispatchPlan.format_status_progress(world_state),
		"按 E 收口本轮结果",
		"S20 resolved window status asks for feedback archival"
	)
	var archive_result := gather.interact_with_object(
		"map_object_instance.frontline_action_console",
		BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID,
		"inspect",
		character_state,
		world_state
	)
	host._expect_equal(bool(archive_result.get("success", false)), true, "S20 survey window feedback archival succeeds")
	host._expect_text_contains(String(archive_result.get("message", "")), "前线异常窗口反馈已归档", "S20 survey archival confirms feedback")
	host._expect_text_contains(String(archive_result.get("message", "")), "当前计划槽", "S20 survey archival explains next plan slot")
	host._expect_equal(
		BaseActionDispatchPlan.get_current_plan_key(world_state),
		BaseActionDispatchPlan.PLAN_PRESSURE_CLEARANCE,
		"S20 survey archival promotes pressure clearance into current slot"
	)
	host._expect_equal(
		BaseActionDispatchPlan.get_next_plan_candidate_key(world_state),
		BaseActionDispatchPlan.PLAN_STEADY_SUPPLY,
		"S20 survey archival rotates supply into next candidate"
	)
	host._expect_equal(
		BaseActionDispatchPlan.get_pressure_clearance_status(world_state),
		BaseActionDispatchPlan.STATUS_READY,
		"S20 survey archival prepares pressure clearance package"
	)

	var pressure_prompt := BaseActionDispatchPlan.format_console_prompt(
		BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID,
		world_state,
		character_state
	)
	host._expect_text_contains(pressure_prompt, "按 E 确认：清障防护整备槽", "S20 pressure slot prompt exposes confirmation action")
	host._expect_text_contains(pressure_prompt, "计划：压力清障", "S20 pressure slot prompt shows current pressure plan")
	host._expect_text_contains(pressure_prompt, "下一计划候选：低风险补给", "S20 pressure slot prompt shows rotated supply candidate")
	host._expect_text_contains(pressure_prompt, "透镜校准读数已归档，清障候选会提前标出东侧短时扰动位置", "S20 pressure slot prompt carries survey feedback into clearance")

	var supply_candidate_prompt := BaseActionDispatchPlan.format_console_prompt(
		"map_object.base_supply_choice_console",
		world_state,
		character_state
	)
	host._expect_text_contains(supply_candidate_prompt, "下一计划候选已是：低风险补给", "S20 supply candidate prompt shows rotated candidate")
	host._expect_text_contains(supply_candidate_prompt, "透镜校准读数已归档", "S20 supply candidate prompt explains survey carryover")

	var pressure_confirm_result := gather.interact_with_object(
		"map_object_instance.frontline_action_console",
		BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID,
		"inspect",
		character_state,
		world_state
	)
	host._expect_equal(bool(pressure_confirm_result.get("success", false)), true, "S20 pressure departure slot confirmation succeeds")
	host._expect_text_contains(String(pressure_confirm_result.get("message", "")), "出发整备槽已确认：压力清障计划", "S20 pressure confirmation explains plan")
	var pressure_departure_messages := BaseActionDispatchPlan.apply_departure_preparation(world_state, character_state)
	host._expect_equal(pressure_departure_messages.size(), 2, "S20 pressure departure loads defensive package and promotes candidate")
	host._expect_text_contains(String(pressure_departure_messages[0]), "压力清障防护计划已执行", "S20 pressure departure execution explains guard-first route")
	host._expect_text_contains(String(pressure_departure_messages[1]), "低风险补给", "S20 pressure departure promotes supply candidate")
	host._expect_equal(
		BaseActionDispatchPlan.get_frontline_window_plan_key(world_state),
		BaseActionDispatchPlan.PLAN_PRESSURE_CLEARANCE,
		"S20 pressure departure activates pressure window"
	)
	var pressure_window_prompt := BaseActionDispatchPlan.format_frontline_window_prompt(world_state)
	host._expect_text_contains(pressure_window_prompt, "已载入压力清障计划", "S20 pressure window prompt shows current plan")
	host._expect_text_contains(pressure_window_prompt, "当前步骤：清障扰动守卫仍在压制异常窗口", "S20 pressure window prompt gates window behind guard")
	var blocked_window_result := gather.interact_with_object(
		"map_object_instance.prepared_frontline_window",
		"map_object.prepared_frontline_window",
		"inspect",
		character_state,
		world_state
	)
	host._expect_equal(bool(blocked_window_result.get("success", true)), false, "S20 pressure window blocks direct interaction before guard defeat")
	host._expect_text_contains(String(blocked_window_result.get("message", "")), "先靠近守卫按 J 攻击", "S20 pressure window result explains guard blocker")


func _make_interactable(instance_id: String, definition_id: String) -> PrototypeInteractable:
	var interactable := PrototypeInteractable.new()
	interactable.instance_id = instance_id
	interactable.definition_id = definition_id
	interactable.interaction_type = "inspect"
	return interactable
