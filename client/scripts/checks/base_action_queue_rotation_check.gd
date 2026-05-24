extends RefCounted

var host


func _init(check_host) -> void:
	host = check_host


func run() -> void:
	_check_candidate_promotes_after_supply_departure()
	_check_candidate_promotes_after_survey_departure()
	_check_candidate_promotes_after_pressure_departure()
	_check_promoted_plan_passes_next_preparation_cycle()
	_check_action_plan_preview_wording_is_shared()
	_check_light_preparation_module_enters_snapshots()
	_check_departure_confirmation_locks_risk_reward_snapshot()
	_check_phase_relay_pad_shows_confirmed_preparation()
	_check_prepared_frontline_window_follows_confirmed_plan()
	_check_frontline_window_stage_review_covers_all_plans()
	_check_review_preparation_runs_two_window_cycles()
	_check_legacy_archived_window_state_stops_loop()


func _check_candidate_promotes_after_supply_departure() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	world_state.set_base_action_state_value(BaseActionDispatchPlan.SUPPLY_PACKAGE_STATUS_KEY, BaseActionDispatchPlan.STATUS_READY)
	world_state.set_base_action_state_value(BaseActionDispatchPlan.CURRENT_PLAN_KEY, BaseActionDispatchPlan.PLAN_STEADY_SUPPLY)
	world_state.set_base_action_state_value(BaseActionDispatchPlan.NEXT_PLAN_CANDIDATE_KEY, BaseActionDispatchPlan.PLAN_PHASE_SURVEY)
	var confirm_messages := BaseActionDispatchPlan.confirm_departure_preparation(world_state)
	host._expect_equal(confirm_messages.size(), 1, "supply rotation setup confirms one departure slot")
	var departure_messages := BaseActionDispatchPlan.apply_departure_preparation(world_state, character_state)
	host._expect_equal(departure_messages.size(), 2, "supply departure should execute package and promote candidate")
	host._expect_text_contains(String(departure_messages[1]), "下一计划候选已进入当前计划槽：信息侦测", "supply departure promotes survey candidate")
	host._expect_equal(
		BaseActionDispatchPlan.get_supply_package_status(world_state),
		BaseActionDispatchPlan.STATUS_USED,
		"supply rotation keeps executed supply package used"
	)
	host._expect_equal(
		BaseActionDispatchPlan.get_current_plan_key(world_state),
		BaseActionDispatchPlan.PLAN_PHASE_SURVEY,
		"supply rotation promotes survey to current plan"
	)
	host._expect_equal(
		BaseActionDispatchPlan.get_survey_intel_status(world_state),
		BaseActionDispatchPlan.STATUS_READY,
		"supply rotation prepares promoted survey plan"
	)
	host._expect_equal(
		BaseActionDispatchPlan.get_next_plan_candidate_key(world_state),
		BaseActionDispatchPlan.PLAN_PRESSURE_CLEARANCE,
		"supply rotation rolls next candidate after promoted survey"
	)
	host._expect_equal(
		BaseActionDispatchPlan.get_departure_plan_key(world_state),
		BaseActionDispatchPlan.PLAN_PHASE_SURVEY,
		"supply rotation clears executed departure slot and exposes promoted current plan"
	)
	host._expect_text_contains(
		BaseActionDispatchPlan.format_direction_hint(world_state),
		"先找到前线异常窗口并按 E 处理",
		"supply rotation direction points to active frontline window before next confirmation"
	)
	BaseActionDispatchPlan.resolve_frontline_window(world_state)
	host._expect_text_contains(
		BaseActionDispatchPlan.format_console_prompt("map_object.frontline_action_console", world_state, character_state),
		"归档本趟反馈",
		"supply rotation action console reviews window feedback before any next departure"
	)


func _check_candidate_promotes_after_survey_departure() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	world_state.set_base_action_state_value(BaseActionDispatchPlan.SURVEY_INTEL_STATUS_KEY, BaseActionDispatchPlan.STATUS_READY)
	world_state.set_base_action_state_value(BaseActionDispatchPlan.CURRENT_PLAN_KEY, BaseActionDispatchPlan.PLAN_PHASE_SURVEY)
	world_state.set_base_action_state_value(BaseActionDispatchPlan.NEXT_PLAN_CANDIDATE_KEY, BaseActionDispatchPlan.PLAN_PRESSURE_CLEARANCE)
	BaseActionDispatchPlan.confirm_departure_preparation(world_state)
	var departure_messages := BaseActionDispatchPlan.apply_departure_preparation(world_state, character_state)
	host._expect_equal(departure_messages.size(), 2, "survey departure should execute intel and promote candidate")
	host._expect_text_contains(String(departure_messages[1]), "压力清障", "survey departure promotes pressure candidate")
	host._expect_equal(
		BaseActionDispatchPlan.get_survey_intel_status(world_state),
		BaseActionDispatchPlan.STATUS_USED,
		"survey rotation keeps executed survey intel used"
	)
	host._expect_equal(
		BaseActionDispatchPlan.get_current_plan_key(world_state),
		BaseActionDispatchPlan.PLAN_PRESSURE_CLEARANCE,
		"survey rotation promotes pressure to current plan"
	)
	host._expect_equal(
		BaseActionDispatchPlan.get_pressure_clearance_status(world_state),
		BaseActionDispatchPlan.STATUS_READY,
		"survey rotation prepares promoted pressure plan"
	)
	BaseActionDispatchPlan.resolve_frontline_window(world_state)
	host._expect_text_contains(
		BaseActionDispatchPlan.format_console_prompt("map_object.frontline_action_console", world_state, character_state),
		"归档本趟反馈",
		"survey rotation action console reviews window feedback before any next departure"
	)


func _check_candidate_promotes_after_pressure_departure() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	world_state.set_base_action_state_value(BaseActionDispatchPlan.PRESSURE_CLEARANCE_STATUS_KEY, BaseActionDispatchPlan.STATUS_READY)
	world_state.set_base_action_state_value(BaseActionDispatchPlan.CURRENT_PLAN_KEY, BaseActionDispatchPlan.PLAN_PRESSURE_CLEARANCE)
	world_state.set_base_action_state_value(BaseActionDispatchPlan.NEXT_PLAN_CANDIDATE_KEY, BaseActionDispatchPlan.PLAN_STEADY_SUPPLY)
	BaseActionDispatchPlan.confirm_departure_preparation(world_state)
	var departure_messages := BaseActionDispatchPlan.apply_departure_preparation(world_state, character_state)
	host._expect_equal(departure_messages.size(), 2, "pressure departure should execute package and promote candidate")
	host._expect_text_contains(String(departure_messages[1]), "低风险补给", "pressure departure promotes supply candidate")
	host._expect_equal(
		BaseActionDispatchPlan.get_pressure_clearance_status(world_state),
		BaseActionDispatchPlan.STATUS_USED,
		"pressure rotation keeps executed pressure package used"
	)
	host._expect_equal(
		BaseActionDispatchPlan.get_current_plan_key(world_state),
		BaseActionDispatchPlan.PLAN_STEADY_SUPPLY,
		"pressure rotation promotes supply to current plan"
	)
	host._expect_equal(
		BaseActionDispatchPlan.get_supply_package_status(world_state),
		BaseActionDispatchPlan.STATUS_READY,
		"pressure rotation prepares promoted supply plan"
	)
	BaseActionDispatchPlan.resolve_frontline_window(world_state)
	host._expect_text_contains(
		BaseActionDispatchPlan.format_console_prompt("map_object.frontline_action_console", world_state, character_state),
		"归档本趟反馈",
		"pressure rotation action console reviews window feedback before any next departure"
	)


func _check_promoted_plan_passes_next_preparation_cycle() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	var gather_system := GatherSystem.new(host.data_registry)
	world_state.set_base_action_state_value(BaseActionDispatchPlan.SUPPLY_PACKAGE_STATUS_KEY, BaseActionDispatchPlan.STATUS_READY)
	world_state.set_base_action_state_value(BaseActionDispatchPlan.CURRENT_PLAN_KEY, BaseActionDispatchPlan.PLAN_STEADY_SUPPLY)
	world_state.set_base_action_state_value(BaseActionDispatchPlan.NEXT_PLAN_CANDIDATE_KEY, BaseActionDispatchPlan.PLAN_PHASE_SURVEY)
	var first_confirm_result := gather_system.interact_with_object(
		"map_object_instance.frontline_action_console",
		BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID,
		"inspect",
		character_state,
		world_state
	)
	host._expect_equal(bool(first_confirm_result.get("success", false)), true, "preparation review first action console confirmation succeeds")
	BaseActionDispatchPlan.apply_departure_preparation(world_state, character_state)
	host._expect_equal(
		BaseActionDispatchPlan.get_current_plan_key(world_state),
		BaseActionDispatchPlan.PLAN_PHASE_SURVEY,
		"preparation review promotes survey after first departure"
	)
	var premature_confirm_result := gather_system.interact_with_object(
		"map_object_instance.frontline_action_console",
		BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID,
		"inspect",
		character_state,
		world_state
	)
	host._expect_text_contains(
		String(premature_confirm_result.get("message", "")),
		"前线异常窗口仍待处理",
		"preparation review blocks next confirmation while frontline window is active"
	)
	BaseActionDispatchPlan.resolve_frontline_window(world_state)
	var second_confirm_result := gather_system.interact_with_object(
		"map_object_instance.frontline_action_console",
		BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID,
		"inspect",
		character_state,
		world_state
	)
	host._expect_equal(bool(second_confirm_result.get("success", false)), true, "preparation review promoted action console confirmation succeeds")
	host._expect_text_contains(
		String(second_confirm_result.get("message", "")),
		"下一趟仍需在行动台确认整备槽",
		"preparation review records window feedback and opens manual review preparation"
	)
	host._expect_equal(
		BaseActionDispatchPlan.is_frontline_action_console_ready(world_state),
		true,
		"preparation review leaves action console ready for manual next confirmation"
	)
	host._expect_equal(
		BaseActionDispatchPlan.format_status_progress(world_state),
		"相位测绘反馈已归档；到前线行动台按 E 确认测绘路线整备槽",
		"preparation review leaves the promoted plan waiting for manual confirmation"
	)


func _check_action_plan_preview_wording_is_shared() -> void:
	var choice_world := WorldState.create_default()
	var character_state := CharacterState.create_default()
	choice_world.quest_state.completed_quest_ids.append("quest.analyze_route_signal_trace")
	var choice_prompt := BaseActionDispatchPlan.format_console_prompt(
		"map_object.base_supply_choice_console",
		choice_world,
		character_state
	)
	host._expect_text_contains(choice_prompt, "方案 A：稳场补给；模块：稳相垫片；风险：低。", "preview wording shows supply choice summary")
	host._expect_text_contains(choice_prompt, "风险拆解：目标密度 低；路线扰动 低；防护消耗 低。", "preview wording shows supply risk profile")
	host._expect_text_contains(choice_prompt, "方案 B：相位测绘；模块：回波透镜；风险：中。", "preview wording shows survey choice summary")
	host._expect_text_contains(choice_prompt, "风险拆解：目标密度 中；路线扰动 中；防护消耗 低。", "preview wording shows survey risk profile")
	host._expect_text_contains(choice_prompt, "方案 C：压力清障；模块：防护涂层；风险：高。", "preview wording shows pressure choice summary")
	host._expect_text_contains(choice_prompt, "目标：清除 1 处前线压力扰点；收益：修复凝胶 +1、抗污染药剂 +1；代价：整备槽。", "preview wording shows pressure choice result")

	var survey_world := WorldState.create_default()
	survey_world.set_base_action_state_value(BaseActionDispatchPlan.SURVEY_INTEL_STATUS_KEY, BaseActionDispatchPlan.STATUS_READY)
	survey_world.set_base_action_state_value(BaseActionDispatchPlan.CURRENT_PLAN_KEY, BaseActionDispatchPlan.PLAN_PHASE_SURVEY)
	var current_plan_prompt := BaseActionDispatchPlan.format_console_prompt(
		BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID,
		survey_world,
		character_state
	)
	host._expect_text_contains(current_plan_prompt, "计划：信息侦测；模块：回波透镜；风险：中。", "preview wording shows current plan summary")
	host._expect_text_contains(current_plan_prompt, "风险拆解：目标密度 中；路线扰动 中；防护消耗 低；说明：需要按低压读数线避开东侧短时扰动。", "preview wording shows current plan risk profile")
	host._expect_text_contains(current_plan_prompt, "收益：目标显形和路线风险预告；代价：占用本次出发整备槽，不额外发放资源。", "preview wording shows current plan reward and cost")
	host._expect_text_contains(current_plan_prompt, "模块效果：放大测绘回波", "preview wording shows current plan preparation module")

	var candidate_world := WorldState.create_default()
	candidate_world.set_base_action_state_value(BaseActionDispatchPlan.SUPPLY_PACKAGE_STATUS_KEY, BaseActionDispatchPlan.STATUS_READY)
	candidate_world.set_base_action_state_value(BaseActionDispatchPlan.CURRENT_PLAN_KEY, BaseActionDispatchPlan.PLAN_STEADY_SUPPLY)
	candidate_world.set_base_action_state_value(BaseActionDispatchPlan.NEXT_PLAN_CANDIDATE_KEY, BaseActionDispatchPlan.PLAN_PHASE_SURVEY)
	var candidate_prompt := BaseActionDispatchPlan.format_console_prompt(
		"map_object.base_pressure_choice_console",
		candidate_world,
		character_state
	)
	host._expect_text_contains(candidate_prompt, "按 E 替换下一计划候选：压力清障；模块：防护涂层；风险：高（目标低 / 路线高 / 防护中）", "preview wording shows compact replacement candidate summary")
	host._expect_text_contains(candidate_prompt, "收益：修复凝胶 +1、抗污染药剂 +1", "preview wording keeps replacement candidate reward")
	host._expect_text_contains(candidate_prompt, "候选判断：替换为压力清障：路线扰动高、防护消耗中", "preview wording explains replacement candidate tradeoff")
	host._expect_text_contains(" ".join(BaseActionDispatchPlan.select_next_plan_candidate_for_console("map_object.base_pressure_choice_console", candidate_world)), "候选判断：保留压力清障", "candidate replacement result keeps second-level decision note")


func _check_light_preparation_module_enters_snapshots() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	world_state.set_base_action_state_value(BaseActionDispatchPlan.SURVEY_INTEL_STATUS_KEY, BaseActionDispatchPlan.STATUS_READY)
	world_state.set_base_action_state_value(BaseActionDispatchPlan.CURRENT_PLAN_KEY, BaseActionDispatchPlan.PLAN_PHASE_SURVEY)
	var confirm_messages := BaseActionDispatchPlan.confirm_departure_preparation(world_state)
	host._expect_text_contains(" ".join(confirm_messages), "模块：回波透镜；风险：中", "departure confirmation includes preparation module")
	host._expect_equal(
		String(world_state.get_base_action_state_value(BaseActionDispatchPlan.DEPARTURE_PLAN_MODULE_KEY, "")),
		"回波透镜",
		"departure confirmation stores preparation module"
	)
	host._expect_equal(
		String(world_state.get_base_action_state_value(BaseActionDispatchPlan.DEPARTURE_PLAN_RISK_PROFILE_KEY, "")),
		"目标密度 中；路线扰动 中；防护消耗 低",
		"departure confirmation stores deterministic risk profile"
	)
	host._expect_text_contains(
		BaseActionDispatchPlan.format_departure_preparation_prompt(world_state),
		"风险：中（目标中 / 路线中 / 防护低）",
		"phase relay prompt exposes compact confirmed risk profile"
	)
	var departure_messages := BaseActionDispatchPlan.apply_departure_preparation(world_state, character_state)
	host._expect_text_contains(" ".join(departure_messages), "轻量整备模块：回波透镜", "departure execution carries preparation module")
	host._expect_equal(
		String(world_state.get_base_action_state_value(BaseActionDispatchPlan.FRONTLINE_WINDOW_MODULE_KEY, "")),
		"回波透镜",
		"frontline window stores preparation module"
	)
	host._expect_text_contains(
		BaseActionDispatchPlan.format_frontline_window_prompt(world_state),
		"风险：中（目标中 / 路线中 / 防护低）",
		"frontline window prompt shows compact active risk profile"
	)
	BaseActionDispatchPlan.resolve_frontline_window(world_state)
	host._expect_text_contains(
		BaseActionDispatchPlan.format_console_prompt(BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID, world_state, character_state),
		"轻量整备模块：回波透镜",
		"resolved action console feedback preserves preparation module"
	)


func _check_departure_confirmation_locks_risk_reward_snapshot() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	var starting_parts := int(character_state.inventory.items.get("item.basic_parts", 0))
	var starting_repair := int(character_state.inventory.items.get("item.repair_gel", 0))
	var starting_vial := int(character_state.inventory.items.get("item.resistance_vial_t1", 0))
	world_state.set_base_action_state_value(BaseActionDispatchPlan.PRESSURE_CLEARANCE_STATUS_KEY, BaseActionDispatchPlan.STATUS_READY)
	world_state.set_base_action_state_value(BaseActionDispatchPlan.CURRENT_PLAN_KEY, BaseActionDispatchPlan.PLAN_PRESSURE_CLEARANCE)
	world_state.set_base_action_state_value(BaseActionDispatchPlan.NEXT_PLAN_CANDIDATE_KEY, BaseActionDispatchPlan.PLAN_STEADY_SUPPLY)
	var confirm_messages := BaseActionDispatchPlan.confirm_departure_preparation(world_state)
	host._expect_text_contains(" ".join(confirm_messages), "压力清障计划；模块：防护涂层；风险：高", "departure confirmation records high-risk summary")
	host._expect_text_contains(" ".join(confirm_messages), "收益：修复凝胶 +1、抗污染药剂 +1；代价：占用本次出发整备槽", "departure confirmation records high-risk reward preview")
	host._expect_equal(
		String(world_state.get_base_action_state_value(BaseActionDispatchPlan.DEPARTURE_PLAN_RISK_KEY, "")),
		"高",
		"departure confirmation stores accepted risk"
	)
	host._expect_equal(
		String(world_state.get_base_action_state_value(BaseActionDispatchPlan.DEPARTURE_PLAN_REWARD_KEY, "")),
		"修复凝胶 +1、抗污染药剂 +1",
		"departure confirmation stores accepted reward"
	)
	world_state.set_base_action_state_value(BaseActionDispatchPlan.SUPPLY_PACKAGE_STATUS_KEY, BaseActionDispatchPlan.STATUS_QUEUED)
	var departure_messages := BaseActionDispatchPlan.apply_departure_preparation(world_state, character_state)
	host._expect_text_contains(" ".join(departure_messages), "已按高风险收益确认出发", "departure execution follows accepted high-risk plan")
	host._expect_equal(
		int(character_state.inventory.items.get("item.basic_parts", 0)),
		starting_parts,
		"departure confirmation does not execute an unconfirmed queued supply package"
	)
	host._expect_equal(
		int(character_state.inventory.items.get("item.repair_gel", 0)),
		starting_repair + 1,
		"departure confirmation executes accepted pressure repair reward"
	)
	host._expect_equal(
		int(character_state.inventory.items.get("item.resistance_vial_t1", 0)),
		starting_vial + 1,
		"departure confirmation executes accepted pressure vial reward"
	)
	host._expect_equal(
		String(world_state.get_base_action_state_value(BaseActionDispatchPlan.DEPARTURE_PLAN_RISK_KEY, "")),
		"",
		"departure execution clears accepted risk snapshot"
	)


func _check_phase_relay_pad_shows_confirmed_preparation() -> void:
	var formatter := InteractionPromptFormatter.new(
		host.data_registry,
		ProcessingSystem.new(host.data_registry),
		BuildSystem.new(host.data_registry)
	)
	var world_state := WorldState.create_default()
	world_state.quest_state.completed_quest_ids.append("quest.deploy_phase_relay_anchor")
	world_state.set_active_phase_relay_anchor("map_object_instance.phase_return_anchor_tether")
	world_state.set_base_action_state_value(BaseActionDispatchPlan.PRESSURE_CLEARANCE_STATUS_KEY, BaseActionDispatchPlan.STATUS_READY)
	world_state.set_base_action_state_value(BaseActionDispatchPlan.CURRENT_PLAN_KEY, BaseActionDispatchPlan.PLAN_PRESSURE_CLEARANCE)
	BaseActionDispatchPlan.confirm_departure_preparation(world_state)
	var prompt := formatter.format_phase_relay_pad_prompt(world_state)
	host._expect_text_contains(prompt, "本次整备：压力清障已确认", "phase relay pad prompt shows queued pressure preparation")
	host._expect_text_contains(prompt, "收益：修复凝胶 +1、抗污染药剂 +1", "phase relay pad prompt shows pressure reward")
	host._expect_text_contains(prompt, "风险：高", "phase relay pad prompt shows pressure risk")
	host._expect_text_contains(prompt, "代价：占用本次出发整备槽", "phase relay pad prompt shows pressure cost")
	host._expect_text_contains(prompt, "按 E 回投", "phase relay pad prompt keeps departure input")


func _check_prepared_frontline_window_follows_confirmed_plan() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	world_state.set_base_action_state_value(BaseActionDispatchPlan.PRESSURE_CLEARANCE_STATUS_KEY, BaseActionDispatchPlan.STATUS_READY)
	world_state.set_base_action_state_value(BaseActionDispatchPlan.CURRENT_PLAN_KEY, BaseActionDispatchPlan.PLAN_PRESSURE_CLEARANCE)
	BaseActionDispatchPlan.confirm_departure_preparation(world_state)
	BaseActionDispatchPlan.apply_departure_preparation(world_state, character_state)
	host._expect_equal(
		BaseActionDispatchPlan.is_frontline_window_active(world_state),
		true,
		"frontline window becomes active after confirmed departure"
	)
	host._expect_equal(
		BaseActionDispatchPlan.get_frontline_window_plan_key(world_state),
		BaseActionDispatchPlan.PLAN_PRESSURE_CLEARANCE,
		"frontline window stores the executed plan key"
	)
	host._expect_text_contains(
		BaseActionDispatchPlan.format_direction_hint(world_state),
		"先找到前线异常窗口并按 E 处理",
		"active frontline window direction should not send player back to the action console"
	)
	var blocked_confirm_messages := BaseActionDispatchPlan.confirm_departure_preparation(world_state)
	host._expect_text_contains(
		" ".join(blocked_confirm_messages),
		"前线异常窗口仍待处理",
		"active frontline window blocks the next departure confirmation"
	)
	var formatter := InteractionPromptFormatter.new(
		host.data_registry,
		ProcessingSystem.new(host.data_registry),
		BuildSystem.new(host.data_registry)
	)
	var window := PrototypeInteractable.new()
	window.instance_id = BaseActionDispatchPlan.FRONTLINE_WINDOW_INSTANCE_ID
	window.definition_id = BaseActionDispatchPlan.FRONTLINE_WINDOW_OBJECT_ID
	window.interaction_type = "inspect"
	host._expect_text_contains(
		formatter.format_frontline_action_target_prompt(window, character_state, world_state),
		"已载入压力清障计划",
		"frontline window prompt uses confirmed plan"
	)
	var result := GatherSystem.new(host.data_registry).interact_with_object(
		window.instance_id,
		window.definition_id,
		window.interaction_type,
		character_state,
		world_state
	)
	host._expect_equal(bool(result.get("success", false)), true, "frontline window interaction succeeds")
	host._expect_text_contains(
		String(result.get("message", "")),
		"压力清障计划处理",
		"frontline window result explains pressure plan"
	)
	host._expect_equal(
		BaseActionDispatchPlan.is_frontline_window_active(world_state),
		false,
		"frontline window is no longer active after resolution"
	)
	host._expect_text_contains(
		BaseActionDispatchPlan.format_frontline_window_prompt(world_state),
		"已处理",
		"frontline window prompt shows resolved state"
	)
	host._expect_text_contains(
		BaseActionDispatchPlan.format_frontline_window_prompt(world_state),
		"完成态收益：扰动残压已转成下一轮风险回落依据",
		"resolved frontline window prompt should explain completion payoff"
	)
	host._expect_text_contains(
		BaseActionDispatchPlan.format_console_prompt(
			BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID,
			world_state,
			character_state
		),
		"前线窗口反馈：前线异常窗口已按压力清障计划处理",
		"action console carries resolved frontline window feedback"
	)
	var action_console_prompt := BaseActionDispatchPlan.format_console_prompt(
		BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID,
		world_state,
		character_state
	)
	host._expect_text_contains(
		action_console_prompt,
		"完成态收益：扰动残压已转成下一轮风险回落依据",
		"action console should explain resolved window payoff"
	)
	host._expect_text_contains(
		action_console_prompt,
		"归档本趟反馈",
		"action console should ask for feedback archival instead of previewing another loop"
	)
	var review_result := GatherSystem.new(host.data_registry).interact_with_object(
		"map_object_instance.frontline_action_console",
		BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID,
		"inspect",
		character_state,
		world_state
	)
	host._expect_text_contains(
		String(review_result.get("message", "")),
		"下一趟仍需在行动台确认整备槽",
		"action console acknowledgement opens manual review preparation"
	)
	host._expect_equal(
		BaseActionDispatchPlan.is_frontline_action_console_ready(world_state),
		true,
		"acknowledged frontline window feedback keeps next preparation manual"
	)
	host._expect_equal(
		BaseActionDispatchPlan.apply_departure_preparation(world_state, character_state).size(),
		0,
		"acknowledged frontline window feedback does not auto-dispatch without confirmation"
	)
	window.free()


func _check_frontline_window_stage_review_covers_all_plans() -> void:
	_expect_frontline_window_stage_review(
		BaseActionDispatchPlan.PLAN_STEADY_SUPPLY,
		BaseActionDispatchPlan.PLAN_PHASE_SURVEY,
		"完成态收益：稳定样本已转成下一轮资源缓冲依据",
		"资源缓冲承接：稳定样本已归档，基础零件 / 修复凝胶可覆盖两处读数往返",
		"下一计划候选：压力清障；窗口反馈预告：稳定样本已归档，清障候选会先说明防护补给再处理扰点"
	)
	_expect_frontline_window_stage_review(
		BaseActionDispatchPlan.PLAN_PHASE_SURVEY,
		BaseActionDispatchPlan.PLAN_PRESSURE_CLEARANCE,
		"完成态收益：路线读数已转成下一轮目标预告依据",
		"路线情报承接：目标预告=东侧短时扰动位置；路线扰动=高；防护消耗=中",
		"下一计划候选：低风险补给；窗口反馈预告：路线读数已归档，补给候选会贴近西侧已显形路线投放"
	)
	_expect_frontline_window_stage_review(
		BaseActionDispatchPlan.PLAN_PRESSURE_CLEARANCE,
		BaseActionDispatchPlan.PLAN_STEADY_SUPPLY,
		"完成态收益：扰动残压已转成下一轮风险回落依据",
		"残压回落承接：目标预告=低压窗口补给回收；路线扰动=低；防护消耗=低。",
		"下一计划候选：信息侦测；窗口反馈预告：残压已收束，测绘候选可把低干扰路线转成目标预告"
	)


func _check_review_preparation_runs_two_window_cycles() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	var gather_system := GatherSystem.new(host.data_registry)
	world_state.set_base_action_state_value(BaseActionDispatchPlan.SUPPLY_PACKAGE_STATUS_KEY, BaseActionDispatchPlan.STATUS_READY)
	world_state.set_base_action_state_value(BaseActionDispatchPlan.CURRENT_PLAN_KEY, BaseActionDispatchPlan.PLAN_STEADY_SUPPLY)
	world_state.set_base_action_state_value(BaseActionDispatchPlan.NEXT_PLAN_CANDIDATE_KEY, BaseActionDispatchPlan.PLAN_PHASE_SURVEY)

	var first_confirm := gather_system.interact_with_object(
		"map_object_instance.frontline_action_console",
		BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID,
		"inspect",
		character_state,
		world_state
	)
	host._expect_equal(bool(first_confirm.get("success", false)), true, "two-cycle review first confirmation succeeds")
	BaseActionDispatchPlan.apply_departure_preparation(world_state, character_state)
	BaseActionDispatchPlan.resolve_frontline_window(world_state)
	var first_review := gather_system.interact_with_object(
		"map_object_instance.frontline_action_console",
		BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID,
		"inspect",
		character_state,
		world_state
	)
	host._expect_text_contains(
		String(first_review.get("message", "")),
		"当前计划槽：信息侦测",
		"two-cycle review archives first window and exposes promoted current plan"
	)
	host._expect_text_contains(
		BaseActionDispatchPlan.format_console_prompt(BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID, world_state, character_state),
		"前线窗口反馈：前线异常窗口已按低风险补给计划处理",
		"two-cycle review keeps first archived feedback visible before second confirmation"
	)
	host._expect_equal(
		BaseActionDispatchPlan.apply_departure_preparation(world_state, character_state).size(),
		0,
		"two-cycle review cannot launch second window before manual confirmation"
	)

	var second_confirm := gather_system.interact_with_object(
		"map_object_instance.frontline_action_console",
		BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID,
		"inspect",
		character_state,
		world_state
	)
	host._expect_text_contains(
		String(second_confirm.get("message", "")),
		"信息侦测计划",
		"two-cycle review manually confirms the second departure slot"
	)
	var second_departure := BaseActionDispatchPlan.apply_departure_preparation(world_state, character_state)
	host._expect_equal(second_departure.size(), 2, "two-cycle review applies second confirmed departure")
	host._expect_equal(
		BaseActionDispatchPlan.get_frontline_window_plan_key(world_state),
		BaseActionDispatchPlan.PLAN_PHASE_SURVEY,
		"two-cycle review second window uses the confirmed survey plan"
	)
	host._expect_equal(
		BaseActionDispatchPlan.get_current_plan_key(world_state),
		BaseActionDispatchPlan.PLAN_PRESSURE_CLEARANCE,
		"two-cycle review promotes the next candidate after second departure"
	)
	BaseActionDispatchPlan.resolve_frontline_window(world_state)
	var second_review_prompt := BaseActionDispatchPlan.format_console_prompt(
		BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID,
		world_state,
		character_state
	)
	host._expect_text_contains(
		second_review_prompt,
		"前线窗口反馈：前线异常窗口已按信息侦测计划处理",
		"two-cycle review second resolved window replaces the visible feedback"
	)
	host._expect_text_contains(
		second_review_prompt,
		"完成态收益：路线读数已转成下一轮目标预告依据",
		"two-cycle review second resolved window uses the second payoff"
	)
	var second_review := gather_system.interact_with_object(
		"map_object_instance.frontline_action_console",
		BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID,
		"inspect",
		character_state,
		world_state
	)
	host._expect_text_contains(
		String(second_review.get("message", "")),
		"连续两轮窗口复盘已完成",
		"two-cycle review archives second feedback and stops the prototype loop"
	)
	host._expect_equal(
		BaseActionDispatchPlan.is_frontline_action_console_ready(world_state),
		false,
		"two-cycle review disables the action console after the second archive"
	)
	host._expect_equal(
		BaseActionDispatchPlan.apply_departure_preparation(world_state, character_state).size(),
		0,
		"two-cycle review cannot launch a third window after completion"
	)


func _check_legacy_archived_window_state_stops_loop() -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	world_state.set_base_action_state_value(BaseActionDispatchPlan.FRONTLINE_WINDOW_ARCHIVED_PLAN_KEY, BaseActionDispatchPlan.PLAN_PHASE_SURVEY)
	world_state.set_base_action_state_value(BaseActionDispatchPlan.FRONTLINE_WINDOW_ARCHIVED_FEEDBACK_KEY, "旧版归档反馈")
	world_state.set_base_action_state_value(BaseActionDispatchPlan.CURRENT_PLAN_KEY, BaseActionDispatchPlan.PLAN_PRESSURE_CLEARANCE)
	world_state.set_base_action_state_value(BaseActionDispatchPlan.PRESSURE_CLEARANCE_STATUS_KEY, BaseActionDispatchPlan.STATUS_READY)
	host._expect_equal(
		BaseActionDispatchPlan.is_frontline_action_console_ready(world_state),
		false,
		"legacy archived window state should not keep the action console in an endless loop"
	)
	host._expect_text_contains(
		BaseActionDispatchPlan.format_status_progress(world_state),
		"行动台不再继续确认下一趟",
		"legacy archived window state should present a completion status"
	)
	var confirm_messages := BaseActionDispatchPlan.confirm_departure_preparation(world_state)
	host._expect_text_contains(
		" ".join(confirm_messages),
		"连续两轮窗口复盘已完成",
		"legacy archived window state blocks another departure confirmation"
	)
	host._expect_equal(
		BaseActionDispatchPlan.apply_departure_preparation(world_state, character_state).size(),
		0,
		"legacy archived window state cannot execute another departure"
	)

	var resolving_world := WorldState.create_default()
	resolving_world.set_base_action_state_value(BaseActionDispatchPlan.FRONTLINE_WINDOW_ARCHIVED_PLAN_KEY, BaseActionDispatchPlan.PLAN_STEADY_SUPPLY)
	resolving_world.set_base_action_state_value(BaseActionDispatchPlan.FRONTLINE_WINDOW_ARCHIVED_FEEDBACK_KEY, "旧版上一轮归档反馈")
	resolving_world.set_base_action_state_value(BaseActionDispatchPlan.FRONTLINE_WINDOW_STATUS_KEY, BaseActionDispatchPlan.STATUS_RESOLVED)
	resolving_world.set_base_action_state_value(BaseActionDispatchPlan.FRONTLINE_WINDOW_PLAN_KEY, BaseActionDispatchPlan.PLAN_PHASE_SURVEY)
	resolving_world.set_base_action_state_value(BaseActionDispatchPlan.FRONTLINE_WINDOW_FEEDBACK_KEY, "旧版当前窗口反馈")
	resolving_world.set_base_action_state_value(BaseActionDispatchPlan.FRONTLINE_WINDOW_FEEDBACK_ACKED_KEY, false)
	var review_messages := BaseActionDispatchPlan.acknowledge_frontline_window_feedback(resolving_world)
	host._expect_text_contains(
		" ".join(review_messages),
		"连续两轮窗口复盘已完成",
		"legacy resolving window archive should stop immediately when an older archive already exists"
	)
	host._expect_equal(
		BaseActionDispatchPlan.is_frontline_action_console_ready(resolving_world),
		false,
		"legacy resolving window archive should not reopen action confirmation"
	)


func _expect_frontline_window_stage_review(
	executed_plan_key: String,
	promoted_plan_key: String,
	expected_payoff: String,
	expected_current_preview: String,
	expected_next_candidate_preview: String
) -> void:
	var world_state := WorldState.create_default()
	var character_state := CharacterState.create_default()
	world_state.set_base_action_state_value(BaseActionDispatchPlan.CURRENT_PLAN_KEY, executed_plan_key)
	world_state.set_base_action_state_value(BaseActionDispatchPlan.NEXT_PLAN_CANDIDATE_KEY, promoted_plan_key)
	_set_ready_status_for_plan(world_state, executed_plan_key)

	var confirm_messages := BaseActionDispatchPlan.confirm_departure_preparation(world_state)
	host._expect_equal(confirm_messages.size(), 1, "stage review confirms one departure slot for %s" % executed_plan_key)
	var departure_messages := BaseActionDispatchPlan.apply_departure_preparation(world_state, character_state)
	host._expect_equal(departure_messages.size(), 2, "stage review applies departure and promotes candidate for %s" % executed_plan_key)
	host._expect_equal(
		BaseActionDispatchPlan.get_frontline_window_plan_key(world_state),
		executed_plan_key,
		"stage review window stores executed plan %s" % executed_plan_key
	)
	host._expect_equal(
		BaseActionDispatchPlan.get_current_plan_key(world_state),
		promoted_plan_key,
		"stage review promotes expected plan after %s" % executed_plan_key
	)

	var window_messages := BaseActionDispatchPlan.resolve_frontline_window(world_state)
	host._expect_equal(window_messages.size(), 1, "stage review resolves frontline window for %s" % executed_plan_key)
	host._expect_text_contains(
		BaseActionDispatchPlan.format_frontline_window_prompt(world_state),
		expected_payoff,
		"stage review resolved window payoff for %s" % executed_plan_key
	)
	var action_console_prompt := BaseActionDispatchPlan.format_console_prompt(
		BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID,
		world_state,
		character_state
	)
	host._expect_text_contains(
		action_console_prompt,
		expected_payoff,
		"stage review action console payoff for %s" % executed_plan_key
	)
	host._expect_text_contains(
		action_console_prompt,
		"归档本趟反馈",
		"stage review asks to archive feedback before another departure for %s" % executed_plan_key
	)

	var review_result := GatherSystem.new(host.data_registry).interact_with_object(
		"map_object_instance.frontline_action_console",
		BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID,
		"inspect",
		character_state,
		world_state
	)
	host._expect_text_contains(
		String(review_result.get("message", "")),
		"下一趟仍需在行动台确认整备槽",
		"stage review archives feedback and waits for manual confirmation for %s" % executed_plan_key
	)
	host._expect_equal(
		BaseActionDispatchPlan.is_frontline_action_console_ready(world_state),
		true,
		"stage review keeps manual next confirmation available for %s" % executed_plan_key
	)
	host._expect_equal(
		BaseActionDispatchPlan.apply_departure_preparation(world_state, character_state).size(),
		0,
		"stage review does not execute the next plan before confirmation for %s" % executed_plan_key
	)
	var reviewed_prompt := BaseActionDispatchPlan.format_console_prompt(
		BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID,
		world_state,
		character_state
	)
	host._expect_text_contains(
		reviewed_prompt,
		expected_current_preview,
		"stage review current plan preview reflects archived window feedback for %s" % executed_plan_key
	)
	host._expect_text_contains(
		reviewed_prompt,
		expected_next_candidate_preview,
		"stage review next candidate preview reflects archived window feedback for %s" % executed_plan_key
	)
	host._expect_text_contains(
		reviewed_prompt,
		"候选判断：保留",
		"stage review explains why the queued next candidate can be kept for %s" % executed_plan_key
	)


func _set_ready_status_for_plan(world_state: WorldState, plan_key: String) -> void:
	match plan_key:
		BaseActionDispatchPlan.PLAN_STEADY_SUPPLY:
			world_state.set_base_action_state_value(BaseActionDispatchPlan.SUPPLY_PACKAGE_STATUS_KEY, BaseActionDispatchPlan.STATUS_READY)
		BaseActionDispatchPlan.PLAN_PHASE_SURVEY:
			world_state.set_base_action_state_value(BaseActionDispatchPlan.SURVEY_INTEL_STATUS_KEY, BaseActionDispatchPlan.STATUS_READY)
		BaseActionDispatchPlan.PLAN_PRESSURE_CLEARANCE:
			world_state.set_base_action_state_value(BaseActionDispatchPlan.PRESSURE_CLEARANCE_STATUS_KEY, BaseActionDispatchPlan.STATUS_READY)
