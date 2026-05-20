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
	_check_departure_confirmation_locks_risk_reward_snapshot()
	_check_phase_relay_pad_shows_confirmed_preparation()


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
		BaseActionDispatchPlan.format_console_prompt("map_object.frontline_action_console", world_state, character_state),
		"按 E 确认：测绘路线整备槽",
		"supply rotation action console confirms promoted survey slot"
	)
	host._expect_text_contains(
		BaseActionDispatchPlan.format_direction_hint(world_state),
		"确认出发整备槽",
		"supply rotation direction points to action console confirmation"
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
	host._expect_text_contains(
		BaseActionDispatchPlan.format_console_prompt("map_object.frontline_action_console", world_state, character_state),
		"按 E 确认：清障防护整备槽",
		"survey rotation action console confirms promoted pressure slot"
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
	host._expect_text_contains(
		BaseActionDispatchPlan.format_console_prompt("map_object.frontline_action_console", world_state, character_state),
		"按 E 确认：出发补给整备槽",
		"pressure rotation action console confirms promoted supply slot"
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
		"信息侦测计划",
		"preparation review second confirmation explains promoted survey plan"
	)
	host._expect_equal(
		BaseActionDispatchPlan.get_survey_intel_status(world_state),
		BaseActionDispatchPlan.STATUS_QUEUED,
		"preparation review promoted survey becomes queued"
	)
	var second_departure_messages := BaseActionDispatchPlan.apply_departure_preparation(world_state, character_state)
	host._expect_text_contains(
		" ".join(second_departure_messages),
		"信息侦测计划已执行",
		"preparation review second departure executes promoted plan"
	)
	host._expect_equal(
		BaseActionDispatchPlan.get_current_plan_key(world_state),
		BaseActionDispatchPlan.PLAN_PRESSURE_CLEARANCE,
		"preparation review second departure promotes pressure candidate"
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
	host._expect_text_contains(choice_prompt, "方案 A：稳场补给；目标：读取 1 处稳场补给投放点；收益：基础零件 +2、修复凝胶 +1；风险：低；代价：整备槽。", "preview wording shows supply choice risk and reward")
	host._expect_text_contains(choice_prompt, "方案 B：相位测绘；目标：读取西侧和东侧 2 处相位测绘点；收益：目标显形和路线风险预告；风险：中；代价：整备槽。", "preview wording shows survey choice risk and reward")
	host._expect_text_contains(choice_prompt, "方案 C：压力清障；目标：清除 1 处前线压力扰点；收益：修复凝胶 +1、抗污染药剂 +1；风险：高；代价：整备槽。", "preview wording shows pressure choice risk and reward")

	var survey_world := WorldState.create_default()
	survey_world.set_base_action_state_value(BaseActionDispatchPlan.SURVEY_INTEL_STATUS_KEY, BaseActionDispatchPlan.STATUS_READY)
	survey_world.set_base_action_state_value(BaseActionDispatchPlan.CURRENT_PLAN_KEY, BaseActionDispatchPlan.PLAN_PHASE_SURVEY)
	var current_plan_prompt := BaseActionDispatchPlan.format_console_prompt(
		BaseActionDispatchPlan.FRONTLINE_ACTION_CONSOLE_ID,
		survey_world,
		character_state
	)
	host._expect_text_contains(current_plan_prompt, "计划：信息侦测；目标：读取西侧和东侧 2 处相位测绘点；收益：目标显形和路线风险预告。", "preview wording shows current plan reward")
	host._expect_text_contains(current_plan_prompt, "风险：中；需要按低压读数线避开东侧短时扰动。", "preview wording shows current plan risk detail")
	host._expect_text_contains(current_plan_prompt, "代价：占用本次出发整备槽，不额外发放资源。", "preview wording shows current plan cost detail")

	var candidate_world := WorldState.create_default()
	candidate_world.set_base_action_state_value(BaseActionDispatchPlan.SUPPLY_PACKAGE_STATUS_KEY, BaseActionDispatchPlan.STATUS_READY)
	candidate_world.set_base_action_state_value(BaseActionDispatchPlan.CURRENT_PLAN_KEY, BaseActionDispatchPlan.PLAN_STEADY_SUPPLY)
	candidate_world.set_base_action_state_value(BaseActionDispatchPlan.NEXT_PLAN_CANDIDATE_KEY, BaseActionDispatchPlan.PLAN_PHASE_SURVEY)
	var candidate_prompt := BaseActionDispatchPlan.format_console_prompt(
		"map_object.base_pressure_choice_console",
		candidate_world,
		character_state
	)
	host._expect_text_contains(candidate_prompt, "按 E 替换下一计划候选：压力清障；收益：修复凝胶 +1、抗污染药剂 +1；风险：高；代价：整备槽。", "preview wording shows replacement candidate risk and reward")


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
	host._expect_text_contains(" ".join(confirm_messages), "收益：修复凝胶 +1、抗污染药剂 +1；风险：高", "departure confirmation records high-risk reward preview")
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
