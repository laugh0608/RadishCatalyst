extends RefCounted

var host


func _init(check_host) -> void:
	host = check_host


func run() -> void:
	_check_candidate_promotes_after_supply_departure()
	_check_candidate_promotes_after_survey_departure()
	_check_candidate_promotes_after_pressure_departure()


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
