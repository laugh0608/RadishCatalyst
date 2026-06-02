extends RefCounted
class_name BaseActionDispatchPlan

const CONSOLE_DEFINITION_IDS: Array[String] = [
	"map_object.frontline_action_console",
	"map_object.frontline_supply_console",
	"map_object.frontline_route_console",
	"map_object.base_supply_choice_console",
	"map_object.base_survey_choice_console",
	"map_object.base_pressure_choice_console"
]
const FRONTLINE_ACTION_CONSOLE_ID := "map_object.frontline_action_console"
const FRONTLINE_ACTION_QUEST_IDS: Array[String] = [
	"quest.plan_stability_frontline_action",
	"quest.confirm_supply_frontline_action",
	"quest.confirm_route_frontline_action"
]
const SUPPLY_PACKAGE_STATUS_KEY := "supply_package_status"
const SURVEY_INTEL_STATUS_KEY := "survey_intel_status"
const PRESSURE_CLEARANCE_STATUS_KEY := "pressure_clearance_status"
const ROUTE_TARGET_REGION_KEY := "route_target_region_id"
const ROUTE_RISK_NOTE_KEY := "route_risk_note"
const CURRENT_PLAN_KEY := "current_departure_plan_key"
const NEXT_PLAN_CANDIDATE_KEY := "next_departure_plan_candidate_key"
const DEPARTURE_PLAN_KEY := "departure_plan_key"
const DEPARTURE_PLAN_TARGET_KEY := "departure_plan_target"
const DEPARTURE_PLAN_REWARD_KEY := "departure_plan_reward"
const DEPARTURE_PLAN_RISK_KEY := "departure_plan_risk"
const DEPARTURE_PLAN_RISK_PROFILE_KEY := "departure_plan_risk_profile"
const DEPARTURE_PLAN_COST_KEY := "departure_plan_cost"
const DEPARTURE_PLAN_MODULE_KEY := "departure_plan_module"
const DEPARTURE_PLAN_MODULE_EFFECT_KEY := "departure_plan_module_effect"
const LAST_DEPARTURE_PLAN_KEY := "last_departure_plan_key"
const FRONTLINE_WINDOW_STATUS_KEY := "frontline_window_status"
const FRONTLINE_WINDOW_PLAN_KEY := "frontline_window_plan_key"
const FRONTLINE_WINDOW_MODULE_KEY := "frontline_window_module"
const FRONTLINE_WINDOW_MODULE_EFFECT_KEY := "frontline_window_module_effect"
const FRONTLINE_WINDOW_FEEDBACK_KEY := "frontline_window_feedback"
const FRONTLINE_WINDOW_FEEDBACK_ACKED_KEY := "frontline_window_feedback_acked"
const FRONTLINE_WINDOW_ARCHIVED_PLAN_KEY := "frontline_window_archived_plan_key"
const FRONTLINE_WINDOW_ARCHIVED_MODULE_KEY := "frontline_window_archived_module"
const FRONTLINE_WINDOW_ARCHIVED_MODULE_EFFECT_KEY := "frontline_window_archived_module_effect"
const FRONTLINE_WINDOW_ARCHIVED_FEEDBACK_KEY := "frontline_window_archived_feedback"
const FRONTLINE_WINDOW_REVIEW_COUNT_KEY := "frontline_window_review_count"
const FRONTLINE_WINDOW_OBJECT_ID := "map_object.prepared_frontline_window"
const FRONTLINE_WINDOW_INSTANCE_ID := "map_object_instance.prepared_frontline_window"
const FRONTLINE_WINDOW_REVIEW_LIMIT := 2
const PRESSURE_CLEARANCE_GUARD_INSTANCE_ID := "enemy_instance.pressure_clearance_guard"
const OVERPRESSURE_MODULE_NAME := BaseActionPlanPreview.OVERPRESSURE_MODULE_NAME
const STATUS_READY := "ready"
const STATUS_QUEUED := "queued"
const STATUS_USED := "used"
const STATUS_ACTIVE := "active"
const STATUS_RESOLVED := "resolved"
const PLAN_STEADY_SUPPLY := "steady_supply_buffer"
const PLAN_PHASE_SURVEY := "phase_survey_intel"
const PLAN_PRESSURE_CLEARANCE := "pressure_clearance_guard"
const SUPPLY_FEEDBACK_QUEST_ID := "quest.analyze_steady_supply_trace"
const SURVEY_FEEDBACK_QUEST_ID := "quest.analyze_phase_survey_trace"
const PRESSURE_FEEDBACK_QUEST_ID := "quest.analyze_pressure_clearance_trace"
const ROUTE_TARGET_REGION_ID := "region.phase_well_tether"
const ROUTE_RISK_NOTE := "锚定桥前线低压读数线：优先走西侧测绘边界，东侧节点存在短时扰动。"
static func is_action_console(definition_id: String) -> bool:
	return CONSOLE_DEFINITION_IDS.has(definition_id)

static func get_frontline_action_console_quest_id(quest_state: QuestState) -> String:
	if quest_state == null:
		return ""
	for quest_id in FRONTLINE_ACTION_QUEST_IDS:
		if quest_state.has_active_quest(quest_id):
			return quest_id
	return ""

static func is_frontline_action_console_ready(world_state: WorldState) -> bool:
	if world_state != null and has_unreviewed_frontline_window_feedback(world_state):
		return true
	if world_state != null and not get_frontline_window_feedback(world_state).is_empty():
		return false
	if world_state != null and _is_base_action_review_complete(world_state):
		return false
	return (
		world_state != null
		and (
			not get_frontline_action_console_quest_id(world_state.quest_state).is_empty()
			or has_pending_departure_preparation(world_state)
		)
	)

static func summarize(world_state: WorldState, character_state: CharacterState = null) -> Dictionary:
	var stage := _get_stage(world_state)
	if stage.is_empty():
		return {}

	var summary := {
		"stage": stage,
		"title": _format_title(stage),
		"direction": _format_direction(stage, world_state),
		"onboarding": _format_onboarding(stage),
		"status_goal": _format_status_goal(stage, world_state),
		"status_progress": _format_status_progress(stage, world_state),
		"preparation_lines": _format_preparation_lines(stage, world_state, character_state)
	}
	return summary

static func format_direction_hint(world_state: WorldState) -> String:
	var summary := summarize(world_state)
	return String(summary.get("direction", ""))

static func format_onboarding_hint(world_state: WorldState) -> String:
	var summary := summarize(world_state)
	return String(summary.get("onboarding", ""))

static func format_status_goal(world_state: WorldState) -> String:
	var summary := summarize(world_state)
	return String(summary.get("status_goal", ""))

static func format_status_progress(world_state: WorldState) -> String:
	var summary := summarize(world_state)
	return String(summary.get("status_progress", ""))

static func format_departure_preparation_prompt(world_state: WorldState) -> String:
	if world_state == null:
		return ""
	var departure_plan := get_departure_plan_key(world_state)
	if departure_plan == PLAN_STEADY_SUPPLY and get_supply_package_status(world_state) == STATUS_QUEUED:
		return _format_relay_preparation_preview(world_state, departure_plan)
	if departure_plan == PLAN_PHASE_SURVEY and get_survey_intel_status(world_state) == STATUS_QUEUED:
		return _format_relay_preparation_preview(world_state, departure_plan)
	if departure_plan == PLAN_PRESSURE_CLEARANCE and get_pressure_clearance_status(world_state) == STATUS_QUEUED:
		return _format_relay_preparation_preview(world_state, departure_plan)
	return ""

static func register_feedback_completion(world_state: WorldState, quest_id: String) -> Array[String]:
	if world_state == null:
		return []
	match quest_id:
		SUPPLY_FEEDBACK_QUEST_ID:
			world_state.set_base_action_state_value(SUPPLY_PACKAGE_STATUS_KEY, STATUS_READY)
			_set_current_plan_slot(world_state, PLAN_STEADY_SUPPLY)
			return ["行动台整备：下一次出发补给包待装入"]
		SURVEY_FEEDBACK_QUEST_ID:
			world_state.set_base_action_state_value(SURVEY_INTEL_STATUS_KEY, STATUS_READY)
			world_state.set_base_action_state_value(ROUTE_TARGET_REGION_KEY, ROUTE_TARGET_REGION_ID)
			world_state.set_base_action_state_value(ROUTE_RISK_NOTE_KEY, ROUTE_RISK_NOTE)
			_set_current_plan_slot(world_state, PLAN_PHASE_SURVEY)
			return ["行动台情报：下一次出发路线提示待载入"]
		PRESSURE_FEEDBACK_QUEST_ID:
			world_state.set_base_action_state_value(PRESSURE_CLEARANCE_STATUS_KEY, STATUS_READY)
			_set_current_plan_slot(world_state, PLAN_PRESSURE_CLEARANCE)
			return ["行动台清障：下一次出发防护整备待装入"]
		_:
			return []

static func has_pending_departure_preparation(world_state: WorldState) -> bool:
	return get_supply_package_status(world_state) == STATUS_READY or get_survey_intel_status(world_state) == STATUS_READY or get_pressure_clearance_status(world_state) == STATUS_READY

static func confirm_departure_preparation(world_state: WorldState) -> Array[String]:
	var messages: Array[String] = []
	if world_state == null:
		return messages
	if is_frontline_window_active(world_state):
		messages.append("前线异常窗口仍待处理：先在锚定桥前线的异常窗口按 E 处理本趟结果，再回基地确认下一计划。")
		return messages
	if has_unreviewed_frontline_window_feedback(world_state):
		messages.append("前线异常窗口反馈仍待归档：先在基地行动台按 E 归档本趟结果，再决定后续扩展。")
		return messages
	if _is_base_action_review_complete(world_state):
		messages.append("高压窗口目标已完成：当前原型到此收口，不再继续确认下一趟。")
		return messages
	var current_plan_key := get_current_plan_key(world_state)
	if current_plan_key.is_empty():
		current_plan_key = get_departure_plan_key(world_state)
	if current_plan_key == PLAN_STEADY_SUPPLY and get_supply_package_status(world_state) == STATUS_READY:
		world_state.set_base_action_state_value(SUPPLY_PACKAGE_STATUS_KEY, STATUS_QUEUED)
		world_state.set_base_action_state_value(DEPARTURE_PLAN_KEY, PLAN_STEADY_SUPPLY)
		world_state.set_base_action_state_value(CURRENT_PLAN_KEY, PLAN_STEADY_SUPPLY)
		_set_departure_confirmation_snapshot(world_state, PLAN_STEADY_SUPPLY)
		messages.append(_format_departure_confirmation_message(PLAN_STEADY_SUPPLY, world_state))
	if current_plan_key == PLAN_PHASE_SURVEY and get_survey_intel_status(world_state) == STATUS_READY:
		world_state.set_base_action_state_value(SURVEY_INTEL_STATUS_KEY, STATUS_QUEUED)
		world_state.set_base_action_state_value(ROUTE_TARGET_REGION_KEY, ROUTE_TARGET_REGION_ID)
		world_state.set_base_action_state_value(ROUTE_RISK_NOTE_KEY, ROUTE_RISK_NOTE)
		world_state.set_base_action_state_value(DEPARTURE_PLAN_KEY, PLAN_PHASE_SURVEY)
		world_state.set_base_action_state_value(CURRENT_PLAN_KEY, PLAN_PHASE_SURVEY)
		_set_departure_confirmation_snapshot(world_state, PLAN_PHASE_SURVEY)
		messages.append(_format_departure_confirmation_message(PLAN_PHASE_SURVEY, world_state))
	if current_plan_key == PLAN_PRESSURE_CLEARANCE and get_pressure_clearance_status(world_state) == STATUS_READY:
		world_state.set_base_action_state_value(PRESSURE_CLEARANCE_STATUS_KEY, STATUS_QUEUED)
		world_state.set_base_action_state_value(DEPARTURE_PLAN_KEY, PLAN_PRESSURE_CLEARANCE)
		world_state.set_base_action_state_value(CURRENT_PLAN_KEY, PLAN_PRESSURE_CLEARANCE)
		_set_departure_confirmation_snapshot(world_state, PLAN_PRESSURE_CLEARANCE)
		messages.append(_format_departure_confirmation_message(PLAN_PRESSURE_CLEARANCE, world_state))
	return messages

static func apply_departure_preparation(world_state: WorldState, character_state: CharacterState) -> Array[String]:
	var messages: Array[String] = []
	if world_state == null or character_state == null:
		return messages
	var departure_plan_key := _get_confirmed_departure_plan_key(world_state)
	if not _has_departure_confirmation_snapshot(world_state):
		return messages
	if departure_plan_key == PLAN_STEADY_SUPPLY and get_supply_package_status(world_state) == STATUS_QUEUED:
		character_state.inventory.add_item("item.basic_parts", 2)
		character_state.inventory.add_item("item.repair_gel", 1)
		world_state.set_base_action_state_value(SUPPLY_PACKAGE_STATUS_KEY, STATUS_USED)
		messages.append(_format_departure_execution_message(PLAN_STEADY_SUPPLY, world_state))
	if departure_plan_key == PLAN_PHASE_SURVEY and get_survey_intel_status(world_state) == STATUS_QUEUED:
		world_state.set_base_action_state_value(SURVEY_INTEL_STATUS_KEY, STATUS_USED)
		world_state.set_base_action_state_value(ROUTE_TARGET_REGION_KEY, ROUTE_TARGET_REGION_ID)
		world_state.set_base_action_state_value(ROUTE_RISK_NOTE_KEY, ROUTE_RISK_NOTE)
		messages.append(_format_departure_execution_message(PLAN_PHASE_SURVEY, world_state))
	if departure_plan_key == PLAN_PRESSURE_CLEARANCE and get_pressure_clearance_status(world_state) == STATUS_QUEUED:
		character_state.inventory.add_item("item.repair_gel", 1)
		character_state.inventory.add_item("item.resistance_vial_t1", 1)
		world_state.set_base_action_state_value(PRESSURE_CLEARANCE_STATUS_KEY, STATUS_USED)
		messages.append(_format_departure_execution_message(PLAN_PRESSURE_CLEARANCE, world_state))
	if not departure_plan_key.is_empty() and not messages.is_empty():
		world_state.set_base_action_state_value(LAST_DEPARTURE_PLAN_KEY, departure_plan_key)
		_activate_frontline_window(world_state, departure_plan_key)
		messages.append(_promote_next_plan_candidate(world_state, departure_plan_key))
	return messages

static func is_frontline_window_object(definition_id: String) -> bool:
	return definition_id == FRONTLINE_WINDOW_OBJECT_ID

static func is_frontline_window_active(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return String(world_state.get_base_action_state_value(FRONTLINE_WINDOW_STATUS_KEY, "")) == STATUS_ACTIVE

static func get_frontline_window_feedback(world_state: WorldState) -> String:
	if world_state == null:
		return ""
	if String(world_state.get_base_action_state_value(FRONTLINE_WINDOW_STATUS_KEY, "")) != STATUS_RESOLVED:
		return ""
	return String(world_state.get_base_action_state_value(FRONTLINE_WINDOW_FEEDBACK_KEY, ""))

static func has_unreviewed_frontline_window_feedback(world_state: WorldState) -> bool:
	if get_frontline_window_feedback(world_state).is_empty():
		return false
	return not bool(world_state.get_base_action_state_value(FRONTLINE_WINDOW_FEEDBACK_ACKED_KEY, false))

static func acknowledge_frontline_window_feedback(world_state: WorldState) -> Array[String]:
	var messages: Array[String] = []
	if world_state == null or not has_unreviewed_frontline_window_feedback(world_state):
		return messages
	var feedback := get_frontline_window_feedback(world_state)
	var plan_key := get_frontline_window_plan_key(world_state)
	var resolved_outcome_key := _get_effective_window_outcome_key(world_state, plan_key)
	var had_legacy_archived_feedback := (
		world_state.get_base_action_state_value(FRONTLINE_WINDOW_REVIEW_COUNT_KEY, null) == null
		and not _get_archived_frontline_window_feedback(world_state).is_empty()
	)
	world_state.set_base_action_state_value(FRONTLINE_WINDOW_FEEDBACK_ACKED_KEY, true)
	world_state.set_base_action_state_value(FRONTLINE_WINDOW_ARCHIVED_PLAN_KEY, plan_key)
	world_state.set_base_action_state_value(FRONTLINE_WINDOW_ARCHIVED_MODULE_KEY, String(world_state.get_base_action_state_value(FRONTLINE_WINDOW_MODULE_KEY, "")))
	world_state.set_base_action_state_value(FRONTLINE_WINDOW_ARCHIVED_MODULE_EFFECT_KEY, String(world_state.get_base_action_state_value(FRONTLINE_WINDOW_MODULE_EFFECT_KEY, "")))
	world_state.set_base_action_state_value(FRONTLINE_WINDOW_ARCHIVED_FEEDBACK_KEY, feedback)
	world_state.set_base_action_state_value(FRONTLINE_WINDOW_STATUS_KEY, "")
	world_state.set_base_action_state_value(FRONTLINE_WINDOW_PLAN_KEY, "")
	world_state.set_base_action_state_value(FRONTLINE_WINDOW_MODULE_KEY, "")
	world_state.set_base_action_state_value(FRONTLINE_WINDOW_MODULE_EFFECT_KEY, "")
	world_state.set_base_action_state_value(FRONTLINE_WINDOW_FEEDBACK_KEY, "")
	world_state.set_base_action_state_value(DEPARTURE_PLAN_KEY, "")
	_clear_departure_confirmation_snapshot(world_state)
	var review_count := _increment_frontline_window_review_count(world_state, had_legacy_archived_feedback)
	if resolved_outcome_key == BaseActionWindowOutcome.PLAN_OVERPRESSURE_WINDOW:
		_clear_review_plan_slots(world_state)
		messages.append("高压窗口反馈已归档：三类模块收益已经支撑更危险目标；当前原型到此收口，不再继续确认下一趟。")
		return messages
	if had_legacy_archived_feedback:
		_clear_review_plan_slots(world_state)
		messages.append("前线异常窗口反馈已归档：连续两轮窗口复盘已完成；当前原型到此收口，不再继续确认下一趟。")
		return messages
	if review_count >= FRONTLINE_WINDOW_REVIEW_LIMIT:
		_prepare_overpressure_window_slot(world_state)
		messages.append("前线异常窗口反馈已归档：两轮复盘收益已合并为高压窗口目标；当前计划槽：高压窗口。下一趟仍需在行动台确认三模块联锁整备槽，不会自动派发。")
		return messages
	_prepare_review_plan_slots(world_state, plan_key)
	var current_plan := get_current_plan_key(world_state)
	var next_candidate := get_next_plan_candidate_key(world_state)
	messages.append("前线异常窗口反馈已归档：本轮整备结果已经进入行动台记录；当前计划槽：%s；下一计划候选：%s。下一趟仍需在行动台确认整备槽，不会自动派发。" % [
		_format_plan_label(current_plan),
		_format_plan_label(next_candidate)
	])
	return messages

static func is_frontline_window_interactable(definition_id: String, world_state: WorldState) -> bool:
	return is_frontline_window_object(definition_id) and is_frontline_window_active(world_state)

static func get_frontline_window_plan_key(world_state: WorldState) -> String:
	if world_state == null:
		return ""
	var plan_key := String(world_state.get_base_action_state_value(FRONTLINE_WINDOW_PLAN_KEY, ""))
	if _is_known_plan_key(plan_key):
		return plan_key
	return ""

static func get_frontline_window_blocker(world_state: WorldState) -> String:
	return "清障扰动守卫仍在压制异常窗口：先靠近守卫按 J 攻击，击退后再对窗口按 E 处理。" if _is_pressure_clearance_guard_required(world_state) else ""

static func format_frontline_window_prompt(world_state: WorldState) -> String:
	if world_state == null:
		return "前线异常窗口：等待基地整备计划。"
	var status := String(world_state.get_base_action_state_value(FRONTLINE_WINDOW_STATUS_KEY, ""))
	var plan_key := get_frontline_window_plan_key(world_state)
	if status == STATUS_RESOLVED:
		var feedback := String(world_state.get_base_action_state_value(FRONTLINE_WINDOW_FEEDBACK_KEY, ""))
		if feedback.is_empty():
			feedback = "窗口已处理，返回基地行动台安排下一轮。"
		var payoff := _format_frontline_window_completion_payoff(world_state)
		if payoff.is_empty():
			return "前线异常窗口：已处理。\n反馈：%s" % feedback
		return "前线异常窗口：已处理。\n反馈：%s\n完成态收益：%s" % [feedback, payoff]
	if status != STATUS_ACTIVE or plan_key.is_empty():
		return "前线异常窗口：等待相位回投执行已确认整备槽。"
	var preview := _get_plan_preview_for_world(world_state, plan_key)
	var blocker := get_frontline_window_blocker(world_state)
	var outcome_key := _get_effective_window_outcome_key(world_state, plan_key)
	if not blocker.is_empty():
		return "前线异常窗口：已载入%s计划；模块：%s；风险：%s（%s）。\n本趟目标：%s。\n当前步骤：%s" % [String(preview.get("label", "")), _format_window_module_name(world_state, preview), String(preview.get("risk", "")), _format_compact_risk_profile(String(preview.get("risk_profile", ""))), BaseActionWindowOutcome.get_window_target(outcome_key, String(preview.get("target", ""))), blocker]
	return "前线异常窗口：已载入%s计划；模块：%s；风险：%s（%s）。\n本趟目标：%s。\n处理结果：%s。\n按 E 处理窗口。" % [String(preview.get("label", "")), _format_window_module_name(world_state, preview), String(preview.get("risk", "")), _format_compact_risk_profile(String(preview.get("risk_profile", ""))), BaseActionWindowOutcome.get_window_target(outcome_key, String(preview.get("target", ""))), BaseActionWindowOutcome.get_window_result(outcome_key, String(preview.get("reward", "")))]

static func resolve_frontline_window(world_state: WorldState) -> Array[String]:
	var messages: Array[String] = []
	if world_state == null:
		return messages
	if not is_frontline_window_active(world_state):
		return messages
	var plan_key := get_frontline_window_plan_key(world_state)
	if plan_key.is_empty():
		return messages
	var feedback := _format_frontline_window_resolution_message(plan_key, world_state)
	world_state.set_base_action_state_value(FRONTLINE_WINDOW_STATUS_KEY, STATUS_RESOLVED)
	world_state.set_base_action_state_value(FRONTLINE_WINDOW_FEEDBACK_KEY, feedback)
	world_state.set_base_action_state_value(FRONTLINE_WINDOW_FEEDBACK_ACKED_KEY, false)
	messages.append(feedback)
	return messages

static func get_supply_package_status(world_state: WorldState) -> String:
	return _get_preparation_status(world_state, SUPPLY_PACKAGE_STATUS_KEY, SUPPLY_FEEDBACK_QUEST_ID)

static func get_survey_intel_status(world_state: WorldState) -> String:
	return _get_preparation_status(world_state, SURVEY_INTEL_STATUS_KEY, SURVEY_FEEDBACK_QUEST_ID)

static func get_pressure_clearance_status(world_state: WorldState) -> String:
	return _get_preparation_status(world_state, PRESSURE_CLEARANCE_STATUS_KEY, PRESSURE_FEEDBACK_QUEST_ID)

static func get_route_target_region_id(world_state: WorldState) -> String:
	if world_state == null:
		return ""
	var status := get_survey_intel_status(world_state)
	if status != STATUS_READY and status != STATUS_QUEUED:
		return ""
	return String(world_state.get_base_action_state_value(ROUTE_TARGET_REGION_KEY, ROUTE_TARGET_REGION_ID))

static func get_route_risk_note(world_state: WorldState) -> String:
	if get_route_target_region_id(world_state).is_empty():
		return ""
	if world_state == null:
		return ""
	return String(world_state.get_base_action_state_value(ROUTE_RISK_NOTE_KEY, ROUTE_RISK_NOTE))

static func get_departure_plan_key(world_state: WorldState) -> String:
	if world_state == null:
		return ""
	var explicit_plan := String(world_state.get_base_action_state_value(DEPARTURE_PLAN_KEY, ""))
	if not explicit_plan.is_empty():
		return explicit_plan
	var current_plan := get_current_plan_key(world_state)
	if not current_plan.is_empty():
		return current_plan
	if get_supply_package_status(world_state) == STATUS_READY or get_supply_package_status(world_state) == STATUS_QUEUED:
		return PLAN_STEADY_SUPPLY
	if get_survey_intel_status(world_state) == STATUS_READY or get_survey_intel_status(world_state) == STATUS_QUEUED:
		return PLAN_PHASE_SURVEY
	if get_pressure_clearance_status(world_state) == STATUS_READY or get_pressure_clearance_status(world_state) == STATUS_QUEUED:
		return PLAN_PRESSURE_CLEARANCE
	return String(world_state.get_base_action_state_value(LAST_DEPARTURE_PLAN_KEY, ""))

static func get_current_plan_key(world_state: WorldState) -> String:
	if world_state == null:
		return ""
	var explicit_plan := String(world_state.get_base_action_state_value(CURRENT_PLAN_KEY, ""))
	if not explicit_plan.is_empty():
		return explicit_plan
	if get_supply_package_status(world_state) == STATUS_READY or get_supply_package_status(world_state) == STATUS_QUEUED:
		return PLAN_STEADY_SUPPLY
	if get_survey_intel_status(world_state) == STATUS_READY or get_survey_intel_status(world_state) == STATUS_QUEUED:
		return PLAN_PHASE_SURVEY
	if get_pressure_clearance_status(world_state) == STATUS_READY or get_pressure_clearance_status(world_state) == STATUS_QUEUED:
		return PLAN_PRESSURE_CLEARANCE
	return ""

static func get_next_plan_candidate_key(world_state: WorldState) -> String:
	if world_state == null:
		return ""
	var explicit_candidate := String(world_state.get_base_action_state_value(NEXT_PLAN_CANDIDATE_KEY, ""))
	if _is_known_plan_key(explicit_candidate):
		return explicit_candidate
	return _get_alternate_plan_key(get_current_plan_key(world_state))

static func get_last_departure_plan_key(world_state: WorldState) -> String:
	if world_state == null:
		return ""
	return String(world_state.get_base_action_state_value(LAST_DEPARTURE_PLAN_KEY, ""))

static func is_plan_candidate_console_ready(definition_id: String, world_state: WorldState) -> bool:
	return _is_plan_candidate_console(definition_id) and _can_replace_next_plan_candidate(world_state)

static func is_plan_candidate_console(definition_id: String) -> bool:
	return _is_plan_candidate_console(definition_id)

static func is_plan_choice_console_ready(definition_id: String, world_state: WorldState) -> bool:
	if world_state == null:
		return false
	match definition_id:
		"map_object.base_supply_choice_console":
			return world_state.quest_state.has_active_quest("quest.choose_steady_supply_action")
		"map_object.base_survey_choice_console":
			return world_state.quest_state.has_active_quest("quest.choose_phase_survey_action")
		"map_object.base_pressure_choice_console":
			return world_state.quest_state.has_active_quest("quest.choose_pressure_clearance_action")
		_:
			return false

static func select_next_plan_candidate_for_console(definition_id: String, world_state: WorldState) -> Array[String]:
	var plan_key := _get_plan_key_for_console(definition_id)
	if plan_key.is_empty() or not _can_replace_next_plan_candidate(world_state):
		return []
	world_state.set_base_action_state_value(NEXT_PLAN_CANDIDATE_KEY, plan_key)
	var decision_note := _format_candidate_decision_note(world_state, plan_key)
	var decision_text := ""
	if not decision_note.is_empty():
		decision_text = "候选判断：%s" % decision_note
	return ["下一计划候选已更新：%s。\n%s\n%s" % [
		_format_plan_label(plan_key),
		_format_candidate_preview(plan_key, world_state),
		decision_text
	]]

static func format_console_prompt(definition_id: String, world_state: WorldState, character_state: CharacterState) -> String:
	var summary := summarize(world_state, character_state)
	if summary.is_empty():
		return _format_default_console_prompt(definition_id)

	var parts: Array[String] = [
		"基地行动台：%s" % String(summary.get("title", "行动调度")),
		"状态：%s" % String(summary.get("status_progress", "等待下一步行动调度。"))
	]
	var console_line := _format_console_action_line(definition_id, String(summary.get("stage", "")), world_state)
	if not console_line.is_empty():
		parts.append(console_line)
	var preparation_lines: Array = summary.get("preparation_lines", [])
	for line in preparation_lines:
		parts.append(String(line))
	return "\n".join(parts)

static func _get_stage(world_state: WorldState) -> String:
	if world_state == null:
		return ""
	if is_frontline_window_active(world_state):
		return "frontline_window_active"
	if not get_frontline_window_feedback(world_state).is_empty():
		if world_state.current_region_id != "region.outpost_platform":
			return "frontline_window_return"
		if has_unreviewed_frontline_window_feedback(world_state):
			return "frontline_window_review"
	if _is_base_action_review_complete(world_state):
		return "frontline_window_complete"
	var preparation_stage := _get_current_preparation_stage(world_state)
	if not preparation_stage.is_empty():
		return preparation_stage
	var quest_state := world_state.quest_state
	if quest_state.has_completed_quest("quest.analyze_phase_survey_trace"):
		return "phase_survey_ready"
	if quest_state.has_completed_quest("quest.analyze_pressure_clearance_trace"):
		return "pressure_clearance_ready"
	if quest_state.has_active_quest("quest.analyze_pressure_clearance_trace") or quest_state.has_completed_quest("quest.clear_pressure_frontline_hazard"):
		return "pressure_clearance_return"
	if quest_state.has_active_quest("quest.clear_pressure_frontline_hazard") or quest_state.has_completed_quest("quest.choose_pressure_clearance_action"):
		return "pressure_clearance_dispatched"
	if quest_state.has_completed_quest("quest.analyze_steady_supply_trace"):
		return "steady_supply_ready"
	if quest_state.has_active_quest("quest.analyze_phase_survey_trace") or quest_state.has_completed_quest("quest.inspect_phase_survey_nodes"):
		return "phase_survey_return"
	if quest_state.has_active_quest("quest.inspect_phase_survey_nodes") or quest_state.has_completed_quest("quest.choose_phase_survey_action"):
		return "phase_survey_dispatched"
	if quest_state.has_active_quest("quest.analyze_steady_supply_trace") or quest_state.has_completed_quest("quest.inspect_steady_supply_drop"):
		return "steady_supply_return"
	if quest_state.has_active_quest("quest.inspect_steady_supply_drop") or quest_state.has_completed_quest("quest.choose_steady_supply_action"):
		return "steady_supply_dispatched"
	if quest_state.has_active_quest("quest.choose_steady_supply_action") or quest_state.has_active_quest("quest.choose_phase_survey_action") or quest_state.has_active_quest("quest.choose_pressure_clearance_action") or quest_state.has_completed_quest("quest.analyze_route_signal_trace"):
		return "choice_ready"
	if quest_state.has_active_quest("quest.analyze_route_signal_trace") or quest_state.has_completed_quest("quest.inspect_route_signal_marker"):
		return "route_return"
	if quest_state.has_active_quest("quest.inspect_route_signal_marker") or quest_state.has_completed_quest("quest.confirm_route_frontline_action"):
		return "route_dispatched"
	if quest_state.has_active_quest("quest.confirm_route_frontline_action") or quest_state.has_completed_quest("quest.analyze_supply_return_trace"):
		return "route_ready"
	if quest_state.has_active_quest("quest.analyze_supply_return_trace") or quest_state.has_completed_quest("quest.inspect_supply_return_marker"):
		return "short_return"
	if quest_state.has_active_quest("quest.inspect_supply_return_marker") or quest_state.has_completed_quest("quest.confirm_supply_frontline_action"):
		return "short_dispatched"
	if quest_state.has_active_quest("quest.confirm_supply_frontline_action") or quest_state.has_completed_quest("quest.analyze_stability_echo_sample"):
		return "short_ready"
	if quest_state.has_active_quest("quest.analyze_stability_echo_sample") or quest_state.has_completed_quest("quest.survey_stability_echo_probe"):
		return "first_return"
	if quest_state.has_active_quest("quest.survey_stability_echo_probe") or quest_state.has_completed_quest("quest.plan_stability_frontline_action"):
		return "first_dispatched"
	if quest_state.has_active_quest("quest.plan_stability_frontline_action") or quest_state.has_completed_quest("quest.calibrate_phase_well_stability_window"):
		return "first_ready"
	return ""

static func _format_title(stage: String) -> String:
	match stage:
		"frontline_window_active":
			return "前线异常窗口待处理"
		"frontline_window_return":
			return "前线窗口反馈待归档"
		"frontline_window_review":
			return "前线窗口反馈待归档"
		"frontline_window_complete":
			return "整备窗口已收口"
		"first_ready":
			return "稳窗回访待确认"
		"first_dispatched":
			return "稳窗回访已派发"
		"first_return":
			return "稳窗回波待解析"
		"short_ready":
			return "补给短行动待确认"
		"short_dispatched":
			return "补给短行动已派发"
		"short_return":
			return "补给回执待解析"
		"route_ready":
			return "巡线短行动待确认"
		"route_dispatched":
			return "巡线短行动已派发"
		"route_return":
			return "巡线信标待解析"
		"choice_ready":
			return "行动方案待选择"
		"steady_supply_dispatched":
			return "稳场补给已派发"
		"steady_supply_return":
			return "稳场补给待解析"
		"steady_supply_ready":
			return "补给整备已生效"
		"phase_survey_dispatched":
			return "相位测绘已派发"
		"phase_survey_return":
			return "相位测绘待解析"
		"phase_survey_ready":
			return "测绘整备已生效"
		"pressure_clearance_dispatched":
			return "压力清障已派发"
		"pressure_clearance_return":
			return "压力清障待解析"
		"pressure_clearance_ready":
			return "清障整备已生效"
		_:
			return "行动调度"

static func _format_direction(stage: String, world_state: WorldState) -> String:
	match stage:
		"frontline_window_active":
			var blocker := get_frontline_window_blocker(world_state)
			if not blocker.is_empty():
				return "本趟压力清障已载入锚定桥前线：当前计划=压力清障，模块=防护涂层。先按 J 击退清障扰动守卫，再处理异常窗口。"
			return "本趟整备已随相位回投载入锚定桥前线：先找到前线异常窗口并按 E 处理，再回基地行动台查看反馈和下一计划。"
		"frontline_window_return":
			return "前线异常窗口已处理：用前线回传锚点回基地，在基地行动台按 E 归档本趟反馈。"
		"frontline_window_review":
			return "前线异常窗口反馈已带回基地：在行动台按 E 归档本趟结果；归档后本轮原型收口，不会自动派发下一趟。"
		"frontline_window_complete":
			return "连续两轮窗口复盘已完成：本轮原型到此收口，不再继续确认下一趟。"
		"first_ready":
			return "稳窗相位序已完成现场校准：回基地在行动台确认稳窗回访，本趟只派发锚定桥东侧稳窗回波探点。"
		"first_dispatched":
			return "稳窗回访已派发：用相位回投返回锚定桥东侧，读取稳窗回波探点后回基地。"
		"first_return":
			return "稳窗回波样本已带回：回基地使用基础反应器，把样本解析成前线行动回报。"
		"short_ready":
			return "前线行动回报已归档：回基地在前线行动台确认补给短行动，本趟只派发补给回执标记。"
		"short_dispatched":
			return "补给短行动已派发：用相位回投返回锚定桥前线，读取补给回执标记。"
		"short_return":
			return "补给回执读数已带回：回基地使用基础反应器，把读数解析成短行动反馈记录。"
		"route_ready":
			return "短行动反馈已归档：回基地在前线行动台确认巡线短行动，本趟只派发巡线信标。"
		"route_dispatched":
			return "巡线短行动已派发：用相位回投返回锚定桥前线，读取巡线信标。"
		"route_return":
			return "巡线信标读数已带回：回基地使用基础反应器，把读数解析成巡线反馈记录。"
		"choice_ready":
			return "巡线反馈已归档：回基地行动台选择稳场补给、相位测绘或压力清障，决定下一趟风险收益。"
		"steady_supply_dispatched":
			return "稳场补给行动已派发：用相位回投返回锚定桥前线，读取一处补给投放点后回基地。"
		"steady_supply_return":
			return "稳场补给回执已带回：回基地使用基础反应器，把补给收益解析成下一轮整备资源。"
		"steady_supply_ready":
			if get_supply_package_status(world_state) == STATUS_USED:
				return "稳场补给反馈已归档：补给整备包已经装入本趟出发，资源缓冲会随背包一起带到前线。"
			if get_supply_package_status(world_state) == STATUS_QUEUED:
				return "稳场补给整备槽已确认：下一步到相位回投台按 E 出发，回投时会装入基础零件和修复凝胶缓冲。"
			return "稳场补给反馈已归档：回基地在前线行动台确认出发整备槽，再从相位回投台外出。"
		"phase_survey_dispatched":
			return "相位测绘行动已派发：用相位回投返回锚定桥前线，读取西侧和东侧两处测绘点。"
		"phase_survey_return":
			return "相位测绘记录已带回：回基地使用基础反应器，把测绘收益解析成下一趟路线提示。"
		"phase_survey_ready":
			if get_survey_intel_status(world_state) == STATUS_USED:
				return "相位测绘路线情报已生效：锚定桥前线目前没有新的可交互目标；返回基地行动台安排下一计划。"
			if get_survey_intel_status(world_state) == STATUS_QUEUED:
				return "相位测绘整备槽已确认：下一步到相位回投台按 E 出发，回投时会载入锚定桥前线目标和风险预告。"
			return "相位测绘反馈已归档：回基地在前线行动台确认出发整备槽，再从相位回投台外出。"
		"pressure_clearance_dispatched":
			return "压力清障行动已派发：用相位回投返回锚定桥前线，清除一处前线压力扰点后回基地。"
		"pressure_clearance_return":
			return "压力清障回执已带回：回基地使用基础反应器，把清障收益解析成下一轮防护整备。"
		"pressure_clearance_ready":
			if _is_overpressure_plan(world_state, PLAN_PRESSURE_CLEARANCE):
				return "三类模块收益已合并：回基地在前线行动台确认高压窗口整备槽，再从相位回投台外出。"
			if get_pressure_clearance_status(world_state) == STATUS_USED:
				return "压力清障反馈已归档：防护整备已经装入本趟出发，后续清障分支可继续沿用行动台。"
			if get_pressure_clearance_status(world_state) == STATUS_QUEUED:
				return "压力清障整备槽已确认：下一步到相位回投台按 E 出发，回投时会装入修复凝胶和抗污染药剂。"
			return "压力清障反馈已归档：回基地在前线行动台确认清障防护整备槽，再从相位回投台外出。"
		_:
			return ""

static func _format_onboarding(stage: String) -> String:
	match stage:
		"frontline_window_active":
			return "下一计划已经预排，但它不能替代本趟前线结果；先处理同一异常窗口，回基地后再确认下一轮整备。"
		"frontline_window_return", "frontline_window_review":
			return "同一窗口的关键验证点是返回反馈，而不是无限重复出发；先把本趟结果归档。"
		"frontline_window_complete":
			return "当前阶段只验证一轮整备结果如何影响同一前线窗口，不继续自动循环。"
		"choice_ready":
			return "行动台现在处理真实取舍：补给方案减少前线目标压力并回收整备物资，测绘方案增加读数成本但换来路线提示。"
		"steady_supply_ready":
			return "补给方案不是终点：反馈记录已经转成可见整备收益，后续行动要把资源缓冲纳入出发判断。"
		"phase_survey_ready":
			return "测绘方案不是终点：反馈记录已经转成可见提示收益，后续行动要把路线信息纳入目标选择。"
		"pressure_clearance_ready":
			return "清障方案不是终点：反馈记录已经转成防护整备收益，后续高风险行动继续复用行动台。"
		"steady_supply_dispatched", "steady_supply_return":
			return "当前行动选择偏稳：目标少、路线短，收益集中在基础零件和修复凝胶。"
		"phase_survey_dispatched", "phase_survey_return":
			return "当前行动选择偏侦测：要读取两处目标，收益集中在路线判断和风险预告。"
		"pressure_clearance_dispatched", "pressure_clearance_return":
			return "当前行动选择偏高风险：只清一处压力扰点，收益集中在防护和续战补给。"
		"route_ready", "route_dispatched", "route_return":
			return "巡线反馈用于支撑后续行动选择，不再继续新增同构短行动。"
		"first_ready", "first_dispatched", "first_return", "short_ready", "short_dispatched", "short_return":
			return "行动台把基地确认、前线读取和返回解析收成同一条调度链，后续收益会进入整备或路线提示。"
		_:
			return ""

static func _format_status_goal(stage: String, world_state: WorldState = null) -> String:
	match stage:
		"frontline_window_active":
			return "前线异常窗口待处理"
		"frontline_window_return":
			return "前线窗口反馈待回基地归档"
		"frontline_window_review":
			return "前线窗口反馈待归档"
		"frontline_window_complete":
			return "整备窗口反馈已归档"
		"choice_ready":
			return "基地行动方案待选择"
		"steady_supply_ready":
			return "补给整备已生效"
		"phase_survey_ready":
			return "测绘整备已生效"
		"pressure_clearance_ready":
			if _is_overpressure_plan(world_state, PLAN_PRESSURE_CLEARANCE):
				return "高压窗口整备待确认"
			return "清障整备已生效"
		_:
			return _format_title(stage)

static func _format_status_progress(stage: String, world_state: WorldState) -> String:
	match stage:
		"frontline_window_active":
			var plan_label := _format_plan_label(get_frontline_window_plan_key(world_state))
			if not get_frontline_window_blocker(world_state).is_empty():
				return "本趟%s计划已载入；模块：防护涂层；当前步骤：按 J 击退清障扰动守卫" % plan_label
			return "本趟%s计划已载入同一前线异常窗口；先在窗口按 E 处理结果" % plan_label
		"frontline_window_return":
			return "前线窗口已处理；下一步用前线回传锚点回基地归档反馈"
		"frontline_window_review":
			return "本趟窗口反馈待归档；到基地行动台按 E 收口本轮结果"
		"frontline_window_complete":
			return "连续两轮窗口复盘已完成；行动台不再继续确认下一趟"
		"choice_ready":
			return "行动台待选择：稳场补给低风险；相位测绘给路线提示；压力清障高风险换防护"
		"steady_supply_ready":
			if get_supply_package_status(world_state) == STATUS_USED:
				return "稳场补给反馈已归档；本趟出发已装入基础零件和修复凝胶补给包"
			if get_supply_package_status(world_state) == STATUS_QUEUED:
				return "稳场补给整备槽已确认；到相位回投台按 E 出发，回投时装入补给包"
			return "稳场补给反馈已归档；到前线行动台按 E 确认出发补给整备槽"
		"phase_survey_ready":
			if get_survey_intel_status(world_state) == STATUS_USED:
				return "相位测绘路线情报已生效；锚定桥前线没有新交互目标，返回基地行动台安排下一计划"
			if get_survey_intel_status(world_state) == STATUS_QUEUED:
				return "相位测绘整备槽已确认；到相位回投台按 E 出发，回投时载入路线提示"
			return "相位测绘反馈已归档；到前线行动台按 E 确认测绘路线整备槽"
		"pressure_clearance_ready":
			if _is_overpressure_plan(world_state, PLAN_PRESSURE_CLEARANCE):
				return "三类模块收益已合并；到前线行动台按 E 确认高压窗口整备槽"
			if get_pressure_clearance_status(world_state) == STATUS_USED:
				return "压力清障反馈已归档；本趟出发已装入修复凝胶和抗污染药剂"
			if get_pressure_clearance_status(world_state) == STATUS_QUEUED:
				return "压力清障整备槽已确认；到相位回投台按 E 出发，回投时装入防护补给"
			return "压力清障反馈已归档；到前线行动台按 E 确认清障防护整备槽"
		"steady_supply_dispatched":
			return "稳场补给已选择；前线目标压缩为一处补给投放点"
		"phase_survey_dispatched":
			return "相位测绘已选择；前线目标展开为西侧和东侧两处测绘点"
		"pressure_clearance_dispatched":
			return "压力清障已选择；前线目标为一处压力扰点清除"
		_:
			return _format_direction(stage, world_state)

static func _format_preparation_lines(stage: String, world_state: WorldState, character_state: CharacterState) -> Array[String]:
	var parts_count := _get_item_count(character_state, "item.basic_parts")
	var repair_count := _get_item_count(character_state, "item.repair_gel")
	var vial_count := _get_item_count(character_state, "item.resistance_vial_t1")
	match stage:
		"frontline_window_active":
			var lines: Array[String] = [
				format_frontline_window_prompt(world_state),
				"下一计划已预排，但要等本趟窗口处理并回基地后再确认。"
			]
			lines.append_array(_format_plan_queue_lines(world_state))
			return lines
		"frontline_window_return", "frontline_window_review", "frontline_window_complete":
			var feedback_lines: Array[String] = _format_frontline_window_feedback_lines(world_state)
			if feedback_lines.is_empty():
				feedback_lines.append("前线窗口反馈：等待本趟窗口结果。")
			if stage == "frontline_window_complete":
				feedback_lines.append("阶段边界：连续两轮复盘已完成，不再继续确认下一趟。")
			else:
				feedback_lines.append("下一步：回基地行动台归档反馈，而不是继续确认下一轮出发。")
			return feedback_lines
		"choice_ready":
			return [
				_format_choice_preview_line("方案 A", PLAN_STEADY_SUPPLY),
				_format_choice_preview_line("方案 B", PLAN_PHASE_SURVEY),
				_format_choice_preview_line("方案 C", PLAN_PRESSURE_CLEARANCE)
			]
		"steady_supply_ready":
			var package_status := get_supply_package_status(world_state)
			var package_line := "出发补给包：待确认；基础零件 +2，修复凝胶 +1。"
			if package_status == STATUS_QUEUED:
				package_line = "出发补给包：整备槽已确认；到相位回投台按 E 出发时装入。"
			if package_status == STATUS_USED:
				package_line = "出发补给包：已装入本趟回投；资源缓冲已进入背包。"
			var supply_lines: Array[String] = [
				"整备：基础零件 %d；修复凝胶 %d。" % [parts_count, repair_count],
				package_line
			]
			supply_lines.append_array(_format_frontline_window_feedback_lines(world_state))
			supply_lines.append_array(_format_plan_queue_lines(world_state))
			supply_lines.append_array(_format_departure_plan_lines(PLAN_STEADY_SUPPLY, world_state))
			return supply_lines
		"phase_survey_ready":
			var intel_status := get_survey_intel_status(world_state)
			var intel_line := "路线提示：待确认；目标显形到锚定桥前线。"
			if intel_status == STATUS_QUEUED:
				intel_line = "路线提示：整备槽已确认；到相位回投台按 E 出发时载入。"
			if intel_status == STATUS_USED:
				intel_line = "路线提示：已完成本趟验证；锚定桥前线没有新的可交互目标。"
			var survey_lines: Array[String] = [
				"整备：抗污染药剂 %d；基础零件 %d。" % [vial_count, parts_count],
				intel_line,
				"风险预告：%s" % get_route_risk_note(world_state)
			]
			survey_lines.append_array(_format_frontline_window_feedback_lines(world_state))
			survey_lines.append_array(_format_plan_queue_lines(world_state))
			survey_lines.append_array(_format_departure_plan_lines(PLAN_PHASE_SURVEY, world_state))
			return survey_lines
		"pressure_clearance_ready":
			if _is_overpressure_plan(world_state, PLAN_PRESSURE_CLEARANCE):
				var overpressure_lines: Array[String] = [
					"整备：三类模块收益已归档；基础零件 %d；修复凝胶 %d；抗污染药剂 %d。" % [parts_count, repair_count, vial_count],
					"高压窗口：待确认；复用稳相缓存、透镜校准和防护涂层收益。"
				]
				overpressure_lines.append_array(_format_frontline_window_feedback_lines(world_state))
				overpressure_lines.append_array(_format_departure_plan_lines(PLAN_PRESSURE_CLEARANCE, world_state))
				return overpressure_lines
			var pressure_status := get_pressure_clearance_status(world_state)
			var pressure_line := "防护整备：待确认；修复凝胶 +1，抗污染药剂 +1。"
			if pressure_status == STATUS_QUEUED:
				pressure_line = "防护整备：整备槽已确认；到相位回投台按 E 出发时装入。"
			if pressure_status == STATUS_USED:
				pressure_line = "防护整备：已装入本趟回投；续战补给已进入背包。"
			var pressure_lines: Array[String] = [
				"整备：抗污染药剂 %d；修复凝胶 %d。" % [vial_count, repair_count],
				pressure_line
			]
			pressure_lines.append_array(_format_frontline_window_feedback_lines(world_state))
			pressure_lines.append_array(_format_plan_queue_lines(world_state))
			pressure_lines.append_array(_format_departure_plan_lines(PLAN_PRESSURE_CLEARANCE, world_state))
			return pressure_lines
		"steady_supply_dispatched", "steady_supply_return":
			return ["已选：稳场补给；目标少、路线短，收益偏整备资源。"]
		"phase_survey_dispatched", "phase_survey_return":
			return ["已选：相位测绘；目标多、信息量高，收益偏路线提示。"]
		"pressure_clearance_dispatched", "pressure_clearance_return":
			return ["已选：压力清障；目标少、风险高，收益偏防护整备。"]
		_:
			return ["整备：沿用当前补给；行动台等待本趟返回数据。"]

static func _format_console_action_line(definition_id: String, stage: String, world_state: WorldState) -> String:
	match definition_id:
		FRONTLINE_ACTION_CONSOLE_ID:
			match stage:
				"frontline_window_review":
					return "按 E 归档本趟反馈。"
				"frontline_window_complete":
					return "本轮已收口；不自动派发下一趟。"
				"first_ready":
					return "按 E 确认：稳窗回访，只派发稳窗回波探点。"
				"short_ready":
					return "按 E 确认：补给短行动，只派发补给回执标记。"
				"route_ready":
					return "按 E 确认：巡线短行动，只派发巡线信标。"
				"steady_supply_ready":
					return "按 E 确认：出发补给整备槽。"
				"phase_survey_ready":
					return "按 E 确认：测绘路线整备槽。"
				"pressure_clearance_ready":
					if _is_overpressure_plan(world_state, PLAN_PRESSURE_CLEARANCE):
						return "按 E 确认：高压窗口三模块联锁整备槽。"
					return "按 E 确认：清障防护整备槽。"
		"map_object.frontline_supply_console":
			if stage == "short_ready":
				return "确认入口已并入前线行动台。"
		"map_object.frontline_route_console":
			if stage == "route_ready":
				return "确认入口已并入前线行动台。"
		"map_object.base_supply_choice_console":
			if stage == "choice_ready":
				return "按 E 选择：稳场补给方案。"
			if is_plan_candidate_console_ready(definition_id, world_state):
				return _format_candidate_console_action_line(PLAN_STEADY_SUPPLY, world_state)
		"map_object.base_survey_choice_console":
			if stage == "choice_ready":
				return "按 E 选择：相位测绘方案。"
			if is_plan_candidate_console_ready(definition_id, world_state):
				return _format_candidate_console_action_line(PLAN_PHASE_SURVEY, world_state)
		"map_object.base_pressure_choice_console":
			if stage == "choice_ready":
				return "按 E 选择：压力清障方案。"
			if is_plan_candidate_console_ready(definition_id, world_state):
				return _format_candidate_console_action_line(PLAN_PRESSURE_CLEARANCE, world_state)
	return "当前终端已纳入行动台；按 HUD 目标推进。"

static func _format_default_console_prompt(definition_id: String) -> String:
	match definition_id:
		"map_object.base_supply_choice_console":
			return "基地行动台：稳场补给方案\n状态：等待巡线反馈归档后开放选择。"
		"map_object.base_survey_choice_console":
			return "基地行动台：相位测绘方案\n状态：等待巡线反馈归档后开放选择。"
		"map_object.base_pressure_choice_console":
			return "基地行动台：压力清障方案\n状态：等待巡线反馈归档后开放选择。"
		_:
			return "基地行动台：行动调度\n状态：等待前置目标完成。"

static func _get_item_count(character_state: CharacterState, item_id: String) -> int:
	if character_state == null:
		return 0
	return int(character_state.inventory.items.get(item_id, 0))

static func _format_departure_plan_lines(plan_key: String, world_state: WorldState) -> Array[String]:
	var preview := _get_plan_preview_for_world(world_state, plan_key)
	if preview.is_empty():
		return []
	var lines: Array[String] = [
		"计划：%s；模块：%s；风险：%s。" % [
			String(preview.get("label", "")),
			String(preview.get("module", "")),
			String(preview.get("risk", ""))
		],
		"风险拆解：%s；说明：%s。" % [String(preview.get("risk_profile", "")), String(preview.get("risk_detail", ""))],
		"目标：%s。" % String(preview.get("target", "")),
		"收益：%s；代价：%s。" % [String(preview.get("reward", "")), String(preview.get("cost", ""))],
		"模块效果：%s。" % String(preview.get("module_effect", ""))
	]
	var window_preview := _format_window_outcome_preview_line_for_world(plan_key, world_state)
	if not window_preview.is_empty():
		lines.append(window_preview)
	var feedback_note := _format_window_feedback_plan_note(world_state, plan_key)
	if not feedback_note.is_empty():
		lines.append("行动台预告：%s。" % feedback_note)
	var carryover_line := _format_window_feedback_carryover_line(world_state, plan_key)
	if not carryover_line.is_empty():
		lines.append(carryover_line)
	return lines

static func _format_plan_queue_lines(world_state: WorldState) -> Array[String]:
	var current_plan := get_current_plan_key(world_state)
	var next_candidate := get_next_plan_candidate_key(world_state)
	var lines: Array[String] = []
	if not current_plan.is_empty():
		lines.append("当前计划槽：%s。" % _format_plan_label(current_plan))
	if not next_candidate.is_empty():
		var feedback_note := _format_window_feedback_plan_note(world_state, next_candidate)
		if feedback_note.is_empty():
			lines.append("下一计划候选：%s；可在对应方案终端替换。" % _format_plan_label(next_candidate))
		else:
			lines.append("下一计划候选：%s；窗口反馈预告：%s；可在对应方案终端替换。" % [_format_plan_label(next_candidate), feedback_note])
		var decision_note := _format_candidate_decision_note(world_state, next_candidate)
		if not decision_note.is_empty():
			lines.append("候选判断：%s" % decision_note)
	return lines

static func _format_frontline_window_feedback_lines(world_state: WorldState) -> Array[String]:
	var feedback := get_frontline_window_feedback(world_state)
	if feedback.is_empty():
		feedback = _get_archived_frontline_window_feedback(world_state)
	if feedback.is_empty():
		return []
	var lines: Array[String] = ["前线窗口反馈：%s" % feedback]
	var module_line := _format_resolved_frontline_window_module_line(world_state)
	if not module_line.is_empty():
		lines.append(module_line)
	var payoff := _format_frontline_window_completion_payoff(world_state)
	if not payoff.is_empty():
		lines.append("完成态收益：%s" % payoff)
	return lines

static func _get_resolved_frontline_window_plan_key(world_state: WorldState) -> String:
	var plan_key := get_frontline_window_plan_key(world_state)
	if not get_frontline_window_feedback(world_state).is_empty() and not plan_key.is_empty():
		return plan_key
	return _get_archived_frontline_window_plan_key(world_state)

static func _get_resolved_frontline_window_outcome_key(world_state: WorldState) -> String:
	var plan_key := _get_resolved_frontline_window_plan_key(world_state)
	return _get_effective_window_outcome_key(world_state, plan_key)

static func _get_archived_frontline_window_feedback(world_state: WorldState) -> String:
	if world_state == null:
		return ""
	return String(world_state.get_base_action_state_value(FRONTLINE_WINDOW_ARCHIVED_FEEDBACK_KEY, ""))

static func _get_archived_frontline_window_plan_key(world_state: WorldState) -> String:
	if world_state == null:
		return ""
	var plan_key := String(world_state.get_base_action_state_value(FRONTLINE_WINDOW_ARCHIVED_PLAN_KEY, ""))
	if _is_known_plan_key(plan_key):
		return plan_key
	return ""

static func _format_frontline_window_completion_payoff(world_state: WorldState) -> String:
	return BaseActionWindowOutcome.get_payoff(_get_resolved_frontline_window_outcome_key(world_state))

static func _format_window_module_name(world_state: WorldState, fallback_preview: Dictionary) -> String:
	var module := ""
	if world_state != null:
		module = String(world_state.get_base_action_state_value(FRONTLINE_WINDOW_MODULE_KEY, ""))
	if module.is_empty():
		module = String(fallback_preview.get("module", ""))
	if module.is_empty():
		return "未定模块"
	return module

static func _format_resolved_frontline_window_module_line(world_state: WorldState) -> String:
	if world_state == null:
		return ""
	var module := String(world_state.get_base_action_state_value(FRONTLINE_WINDOW_MODULE_KEY, ""))
	var module_effect := String(world_state.get_base_action_state_value(FRONTLINE_WINDOW_MODULE_EFFECT_KEY, ""))
	if module.is_empty():
		module = String(world_state.get_base_action_state_value(FRONTLINE_WINDOW_ARCHIVED_MODULE_KEY, ""))
	if module_effect.is_empty():
		module_effect = String(world_state.get_base_action_state_value(FRONTLINE_WINDOW_ARCHIVED_MODULE_EFFECT_KEY, ""))
	if module.is_empty() or module_effect.is_empty():
		return ""
	return "轻量整备模块：%s；效果：%s" % [module, module_effect]

static func _get_effective_window_outcome_key(world_state: WorldState, plan_key: String) -> String:
	if plan_key == PLAN_PRESSURE_CLEARANCE:
		var module := ""
		if world_state != null:
			module = String(world_state.get_base_action_state_value(FRONTLINE_WINDOW_MODULE_KEY, ""))
			if module.is_empty():
				module = String(world_state.get_base_action_state_value(FRONTLINE_WINDOW_ARCHIVED_MODULE_KEY, ""))
		if module == OVERPRESSURE_MODULE_NAME or _is_overpressure_plan(world_state, plan_key):
			return BaseActionWindowOutcome.PLAN_OVERPRESSURE_WINDOW
	return plan_key

static func _format_window_feedback_plan_note(world_state: WorldState, plan_key: String) -> String:
	var source_plan := _get_resolved_frontline_window_outcome_key(world_state)
	if source_plan.is_empty() or plan_key.is_empty():
		return ""
	return BaseActionWindowOutcome.get_plan_note(source_plan, plan_key)

static func _format_window_feedback_carryover_line(world_state: WorldState, plan_key: String) -> String:
	var source_plan := _get_resolved_frontline_window_outcome_key(world_state)
	var carryover := BaseActionWindowOutcome.get_carryover(source_plan, plan_key)
	if source_plan == PLAN_PHASE_SURVEY and not carryover.is_empty():
		var risk_note := String(world_state.get_base_action_state_value(ROUTE_RISK_NOTE_KEY, ROUTE_RISK_NOTE))
		if risk_note.is_empty():
			risk_note = ROUTE_RISK_NOTE
		return "%s风险预告：%s" % [carryover, risk_note]
	return carryover

static func _format_candidate_console_action_line(plan_key: String, world_state: WorldState) -> String:
	var decision_note := _format_candidate_decision_note(world_state, plan_key)
	if not decision_note.is_empty():
		decision_note = "\n候选判断：%s" % decision_note
	if get_next_plan_candidate_key(world_state) == plan_key:
		return "下一计划候选已是：%s。%s" % [_format_candidate_preview(plan_key, world_state), decision_note]
	return "按 E 替换下一计划候选：%s。%s" % [_format_candidate_preview(plan_key, world_state), decision_note]

static func _format_candidate_decision_note(world_state: WorldState, candidate_plan_key: String) -> String:
	if world_state == null or not _is_known_plan_key(candidate_plan_key):
		return ""
	var current_plan := get_current_plan_key(world_state)
	var current_label := _format_plan_label(current_plan)
	var candidate_label := _format_plan_label(candidate_plan_key)
	var prefix := "保留%s" % candidate_label
	if candidate_plan_key != get_next_plan_candidate_key(world_state):
		prefix = "替换为%s" % candidate_label
	var basis := ""
	match candidate_plan_key:
		PLAN_STEADY_SUPPLY:
			basis = "目标密度低，适合把当前%s后的空档转成资源缓冲" % current_label
		PLAN_PHASE_SURVEY:
			basis = "目标密度中，适合把当前%s后的反馈转成路线和目标预告" % current_label
		PLAN_PRESSURE_CLEARANCE:
			basis = "路线扰动高、防护消耗中，适合在当前%s后集中处理已知扰点" % current_label
	if _get_resolved_frontline_window_plan_key(world_state) == PLAN_PRESSURE_CLEARANCE and candidate_plan_key == PLAN_PRESSURE_CLEARANCE:
		basis = "涂层样本已改良，继续清障降为低防护消耗，不会打开新循环"
	if _get_resolved_frontline_window_plan_key(world_state) == PLAN_PHASE_SURVEY and candidate_plan_key == PLAN_STEADY_SUPPLY:
		basis = "透镜校准读数已归档，低风险补给可贴近西侧低扰动边界回收资源"
	if _get_resolved_frontline_window_plan_key(world_state) == PLAN_PHASE_SURVEY and candidate_plan_key == PLAN_PHASE_SURVEY:
		basis = "透镜校准读数已归档，继续测绘会按低扰动路线复核两处回波"
	if _get_resolved_frontline_window_plan_key(world_state) == PLAN_PHASE_SURVEY and candidate_plan_key == PLAN_PRESSURE_CLEARANCE:
		basis = "透镜校准读数已归档，清障会提前标出扰点并把路线扰动降为中"
	if _get_resolved_frontline_window_plan_key(world_state) == PLAN_STEADY_SUPPLY and candidate_plan_key == PLAN_PHASE_SURVEY:
		basis = "稳相缓存样本已归档，测绘两点往返有补给兜底"
	if _get_resolved_frontline_window_plan_key(world_state) == PLAN_STEADY_SUPPLY and candidate_plan_key == PLAN_STEADY_SUPPLY:
		basis = "稳相缓存样本已改良，继续补给会强化基础零件缓冲"
	if _get_resolved_frontline_window_plan_key(world_state) == PLAN_STEADY_SUPPLY and candidate_plan_key == PLAN_PRESSURE_CLEARANCE:
		basis = "稳相缓存样本已归档，清障前可先确认防护补给覆盖扰点处理"
	return "%s：%s；不影响当前出发整备槽。" % [prefix, basis]

static func _set_current_plan_slot(world_state: WorldState, plan_key: String) -> void:
	world_state.set_base_action_state_value(CURRENT_PLAN_KEY, plan_key)
	if String(world_state.get_base_action_state_value(NEXT_PLAN_CANDIDATE_KEY, "")).is_empty():
		world_state.set_base_action_state_value(NEXT_PLAN_CANDIDATE_KEY, _get_alternate_plan_key(plan_key))

static func _prepare_review_plan_slots(world_state: WorldState, source_plan_key: String) -> void:
	var current_plan := get_current_plan_key(world_state)
	if current_plan.is_empty():
		current_plan = _get_review_current_plan_key(source_plan_key)
	if current_plan.is_empty():
		current_plan = _get_alternate_plan_key(source_plan_key)
	if current_plan.is_empty():
		return
	_set_plan_status(world_state, current_plan, STATUS_READY)
	if source_plan_key == PLAN_PHASE_SURVEY:
		world_state.set_base_action_state_value(ROUTE_TARGET_REGION_KEY, ROUTE_TARGET_REGION_ID)
		world_state.set_base_action_state_value(ROUTE_RISK_NOTE_KEY, ROUTE_RISK_NOTE)
	world_state.set_base_action_state_value(CURRENT_PLAN_KEY, current_plan)
	var next_candidate := get_next_plan_candidate_key(world_state)
	if next_candidate.is_empty() or next_candidate == current_plan:
		next_candidate = _get_review_candidate_plan_key(source_plan_key, current_plan)
	world_state.set_base_action_state_value(NEXT_PLAN_CANDIDATE_KEY, next_candidate)

static func _clear_review_plan_slots(world_state: WorldState) -> void:
	world_state.set_base_action_state_value(CURRENT_PLAN_KEY, "")
	world_state.set_base_action_state_value(NEXT_PLAN_CANDIDATE_KEY, "")
	world_state.set_base_action_state_value(DEPARTURE_PLAN_KEY, "")
	world_state.set_base_action_state_value(SUPPLY_PACKAGE_STATUS_KEY, STATUS_USED)
	world_state.set_base_action_state_value(SURVEY_INTEL_STATUS_KEY, STATUS_USED)
	world_state.set_base_action_state_value(PRESSURE_CLEARANCE_STATUS_KEY, STATUS_USED)
	_clear_departure_confirmation_snapshot(world_state)

static func _prepare_overpressure_window_slot(world_state: WorldState) -> void:
	world_state.set_base_action_state_value(SUPPLY_PACKAGE_STATUS_KEY, STATUS_USED)
	world_state.set_base_action_state_value(SURVEY_INTEL_STATUS_KEY, STATUS_USED)
	world_state.set_base_action_state_value(PRESSURE_CLEARANCE_STATUS_KEY, STATUS_READY)
	world_state.set_base_action_state_value(CURRENT_PLAN_KEY, PLAN_PRESSURE_CLEARANCE)
	world_state.set_base_action_state_value(NEXT_PLAN_CANDIDATE_KEY, "")
	world_state.set_base_action_state_value(DEPARTURE_PLAN_KEY, "")
	_clear_departure_confirmation_snapshot(world_state)

static func _increment_frontline_window_review_count(world_state: WorldState, had_legacy_archived_feedback: bool) -> int:
	var explicit_count = world_state.get_base_action_state_value(FRONTLINE_WINDOW_REVIEW_COUNT_KEY, null)
	var review_count := 1
	if explicit_count != null:
		review_count = int(explicit_count) + 1
	elif had_legacy_archived_feedback:
		review_count = FRONTLINE_WINDOW_REVIEW_LIMIT
	world_state.set_base_action_state_value(FRONTLINE_WINDOW_REVIEW_COUNT_KEY, review_count)
	return review_count

static func _get_frontline_window_review_count(world_state: WorldState) -> int:
	if world_state == null:
		return 0
	var explicit_count = world_state.get_base_action_state_value(FRONTLINE_WINDOW_REVIEW_COUNT_KEY, null)
	if explicit_count != null:
		return int(explicit_count)
	if not _get_archived_frontline_window_feedback(world_state).is_empty():
		return FRONTLINE_WINDOW_REVIEW_LIMIT
	return 0

static func _has_reached_frontline_window_review_limit(world_state: WorldState) -> bool:
	return _get_frontline_window_review_count(world_state) >= FRONTLINE_WINDOW_REVIEW_LIMIT

static func _is_base_action_review_complete(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	if world_state.get_base_action_state_value(FRONTLINE_WINDOW_REVIEW_COUNT_KEY, null) == null and not _get_archived_frontline_window_feedback(world_state).is_empty():
		return true
	return _get_frontline_window_review_count(world_state) > FRONTLINE_WINDOW_REVIEW_LIMIT

static func _is_overpressure_plan(world_state: WorldState, plan_key: String) -> bool:
	return plan_key == PLAN_PRESSURE_CLEARANCE and _get_frontline_window_review_count(world_state) >= FRONTLINE_WINDOW_REVIEW_LIMIT and not _is_base_action_review_complete(world_state)

static func _get_review_current_plan_key(source_plan_key: String) -> String:
	match source_plan_key:
		PLAN_STEADY_SUPPLY:
			return PLAN_STEADY_SUPPLY
		PLAN_PHASE_SURVEY:
			return PLAN_PHASE_SURVEY
		PLAN_PRESSURE_CLEARANCE:
			return PLAN_STEADY_SUPPLY
	return PLAN_STEADY_SUPPLY

static func _get_review_candidate_plan_key(source_plan_key: String, current_plan_key: String) -> String:
	match source_plan_key:
		PLAN_STEADY_SUPPLY:
			return PLAN_PHASE_SURVEY
		PLAN_PHASE_SURVEY:
			return PLAN_STEADY_SUPPLY
		PLAN_PRESSURE_CLEARANCE:
			return PLAN_PRESSURE_CLEARANCE
	var alternate := _get_alternate_plan_key(current_plan_key)
	if alternate.is_empty():
		return PLAN_PHASE_SURVEY
	return alternate

static func _can_replace_next_plan_candidate(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	if is_frontline_window_active(world_state):
		return false
	if not get_frontline_window_feedback(world_state).is_empty():
		return false
	if world_state.quest_state.has_active_quest("quest.choose_steady_supply_action"):
		return false
	if world_state.quest_state.has_active_quest("quest.choose_phase_survey_action"):
		return false
	if world_state.quest_state.has_active_quest("quest.choose_pressure_clearance_action"):
		return false
	if _is_overpressure_plan(world_state, get_current_plan_key(world_state)):
		return false
	return not get_current_plan_key(world_state).is_empty()

static func _is_plan_candidate_console(definition_id: String) -> bool:
	return definition_id == "map_object.base_supply_choice_console" or definition_id == "map_object.base_survey_choice_console" or definition_id == "map_object.base_pressure_choice_console"

static func _get_plan_key_for_console(definition_id: String) -> String:
	match definition_id:
		"map_object.base_supply_choice_console":
			return PLAN_STEADY_SUPPLY
		"map_object.base_survey_choice_console":
			return PLAN_PHASE_SURVEY
		"map_object.base_pressure_choice_console":
			return PLAN_PRESSURE_CLEARANCE
		_:
			return ""

static func _get_alternate_plan_key(plan_key: String) -> String:
	if plan_key == PLAN_STEADY_SUPPLY:
		return PLAN_PHASE_SURVEY
	if plan_key == PLAN_PHASE_SURVEY:
		return PLAN_PRESSURE_CLEARANCE
	if plan_key == PLAN_PRESSURE_CLEARANCE:
		return PLAN_STEADY_SUPPLY
	return ""

static func _get_current_preparation_stage(world_state: WorldState) -> String:
	var current_plan := get_current_plan_key(world_state)
	if current_plan == PLAN_STEADY_SUPPLY and not get_supply_package_status(world_state).is_empty():
		return "steady_supply_ready"
	if current_plan == PLAN_PHASE_SURVEY and not get_survey_intel_status(world_state).is_empty():
		return "phase_survey_ready"
	if current_plan == PLAN_PRESSURE_CLEARANCE and not get_pressure_clearance_status(world_state).is_empty():
		return "pressure_clearance_ready"
	return ""

static func _promote_next_plan_candidate(world_state: WorldState, executed_plan_key: String) -> String:
	if _is_overpressure_plan(world_state, executed_plan_key):
		world_state.set_base_action_state_value(CURRENT_PLAN_KEY, "")
		world_state.set_base_action_state_value(NEXT_PLAN_CANDIDATE_KEY, "")
		world_state.set_base_action_state_value(DEPARTURE_PLAN_KEY, "")
		_clear_departure_confirmation_snapshot(world_state)
		return "高压窗口不预排下一候选：先处理本趟窗口并回基地归档，确认三类模块收益是否足够支撑更危险目标。"
	var promoted_plan_key := get_next_plan_candidate_key(world_state)
	if promoted_plan_key.is_empty():
		promoted_plan_key = _get_alternate_plan_key(executed_plan_key)
	if promoted_plan_key.is_empty():
		world_state.set_base_action_state_value(DEPARTURE_PLAN_KEY, "")
		_clear_departure_confirmation_snapshot(world_state)
		return "下一计划候选为空：返回基地行动台选择或替换后续方案。"

	_set_plan_status(world_state, promoted_plan_key, STATUS_READY)
	world_state.set_base_action_state_value(CURRENT_PLAN_KEY, promoted_plan_key)
	world_state.set_base_action_state_value(NEXT_PLAN_CANDIDATE_KEY, _get_alternate_plan_key(promoted_plan_key))
	world_state.set_base_action_state_value(DEPARTURE_PLAN_KEY, "")
	_clear_departure_confirmation_snapshot(world_state)
	return "下一计划候选已进入当前计划槽：%s；回基地在前线行动台按 E 确认，或在方案终端替换下一候选。" % _format_plan_label(promoted_plan_key)

static func _activate_frontline_window(world_state: WorldState, plan_key: String) -> void:
	var preview := _get_departure_confirmation_preview(world_state, plan_key)
	world_state.set_base_action_state_value(FRONTLINE_WINDOW_STATUS_KEY, STATUS_ACTIVE)
	world_state.set_base_action_state_value(FRONTLINE_WINDOW_PLAN_KEY, plan_key)
	world_state.set_base_action_state_value(FRONTLINE_WINDOW_MODULE_KEY, String(preview.get("module", "")))
	world_state.set_base_action_state_value(FRONTLINE_WINDOW_MODULE_EFFECT_KEY, String(preview.get("module_effect", "")))
	world_state.set_base_action_state_value(FRONTLINE_WINDOW_FEEDBACK_KEY, "")
	world_state.set_base_action_state_value(FRONTLINE_WINDOW_FEEDBACK_ACKED_KEY, false)
	if world_state.map_objects.has(FRONTLINE_WINDOW_INSTANCE_ID):
		world_state.map_objects[FRONTLINE_WINDOW_INSTANCE_ID]["is_sampled"] = false
		world_state.map_objects[FRONTLINE_WINDOW_INSTANCE_ID]["is_cleared"] = false

static func _format_frontline_window_resolution_message(plan_key: String, world_state: WorldState = null) -> String:
	return BaseActionWindowOutcome.get_resolution(_get_effective_window_outcome_key(world_state, plan_key))

static func _set_plan_status(world_state: WorldState, plan_key: String, status: String) -> void:
	match plan_key:
		PLAN_STEADY_SUPPLY:
			world_state.set_base_action_state_value(SUPPLY_PACKAGE_STATUS_KEY, status)
		PLAN_PHASE_SURVEY:
			world_state.set_base_action_state_value(SURVEY_INTEL_STATUS_KEY, status)
			if status == STATUS_READY or status == STATUS_QUEUED:
				world_state.set_base_action_state_value(ROUTE_TARGET_REGION_KEY, ROUTE_TARGET_REGION_ID)
				world_state.set_base_action_state_value(ROUTE_RISK_NOTE_KEY, ROUTE_RISK_NOTE)
		PLAN_PRESSURE_CLEARANCE:
			world_state.set_base_action_state_value(PRESSURE_CLEARANCE_STATUS_KEY, status)

static func _format_plan_label(plan_key: String) -> String:
	return String(_get_plan_preview(plan_key).get("label", "未定计划"))

static func _get_plan_preview(plan_key: String) -> Dictionary:
	return BaseActionPlanPreview.get_plan_preview(plan_key)

static func _get_plan_preview_for_world(world_state: WorldState, plan_key: String) -> Dictionary:
	if _is_overpressure_plan(world_state, plan_key):
		return BaseActionPlanPreview.get_overpressure_window_preview().duplicate(true)
	return _get_plan_preview(plan_key)

static func _format_choice_preview_line(prefix: String, plan_key: String) -> String:
	var preview := _get_plan_preview(plan_key)
	if preview.is_empty():
		return "%s：未定计划。" % prefix
	return "%s：%s；模块：%s；风险：%s。\n风险拆解：%s。\n目标：%s；收益：%s；代价：整备槽。\n%s" % [
		prefix,
		String(preview.get("choice_label", preview.get("label", ""))),
		String(preview.get("module", "")),
		String(preview.get("risk", "")),
		String(preview.get("risk_profile", "")),
		String(preview.get("target", "")),
		String(preview.get("reward", "")),
		_format_window_outcome_preview_line(plan_key)
	]

static func _format_candidate_preview(plan_key: String, world_state: WorldState = null) -> String:
	var preview := _get_plan_preview(plan_key)
	if preview.is_empty():
		return "未定计划"
	var text := "%s；模块：%s；风险：%s（%s）；收益：%s" % [
		String(preview.get("label", "")),
		String(preview.get("module", "")),
		String(preview.get("risk", "")),
		_format_compact_risk_profile(String(preview.get("risk_profile", ""))),
		String(preview.get("reward", ""))
	]
	var window_preview := _format_window_outcome_preview_line(plan_key)
	if not window_preview.is_empty():
		text = "%s\n%s" % [text, window_preview]
	var feedback_note := _format_window_feedback_plan_note(world_state, plan_key)
	if not feedback_note.is_empty():
		text = "%s\n窗口反馈：%s" % [text, feedback_note]
	return text

static func _format_relay_preparation_preview(world_state: WorldState, plan_key: String) -> String:
	var preview := _get_departure_confirmation_preview(world_state, plan_key)
	if preview.is_empty():
		return ""
	return "本次整备：%s已确认；模块：%s；风险：%s（%s）\n收益：%s；代价：%s\n%s" % [
		String(preview.get("label", "")),
		String(preview.get("module", "")),
		String(preview.get("risk", "")),
		_format_compact_risk_profile(String(preview.get("risk_profile", ""))),
		String(preview.get("reward", "")),
		String(preview.get("cost", "")),
		_format_window_outcome_preview_line(plan_key)
	]

static func _format_compact_risk_profile(risk_profile: String) -> String:
	if risk_profile.is_empty():
		return "未定"
	var compact := risk_profile
	compact = compact.replace("目标密度 ", "目标")
	compact = compact.replace("路线扰动 ", "路线")
	compact = compact.replace("防护消耗 ", "防护")
	return compact.replace("；", " / ")

static func _get_confirmed_departure_plan_key(world_state: WorldState) -> String:
	if world_state == null:
		return ""
	return String(world_state.get_base_action_state_value(DEPARTURE_PLAN_KEY, ""))

static func _has_departure_confirmation_snapshot(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	if _get_confirmed_departure_plan_key(world_state).is_empty():
		return false
	for key in [
		DEPARTURE_PLAN_TARGET_KEY,
		DEPARTURE_PLAN_REWARD_KEY,
		DEPARTURE_PLAN_RISK_KEY,
		DEPARTURE_PLAN_RISK_PROFILE_KEY,
		DEPARTURE_PLAN_COST_KEY,
		DEPARTURE_PLAN_MODULE_KEY,
		DEPARTURE_PLAN_MODULE_EFFECT_KEY
	]:
		if String(world_state.get_base_action_state_value(key, "")).is_empty():
			return false
	return true

static func _set_departure_confirmation_snapshot(world_state: WorldState, plan_key: String) -> void:
	var preview := _get_plan_preview_for_world(world_state, plan_key)
	if preview.is_empty():
		return
	world_state.set_base_action_state_value(DEPARTURE_PLAN_TARGET_KEY, String(preview.get("target", "")))
	world_state.set_base_action_state_value(DEPARTURE_PLAN_REWARD_KEY, String(preview.get("reward", "")))
	world_state.set_base_action_state_value(DEPARTURE_PLAN_RISK_KEY, String(preview.get("risk", "")))
	world_state.set_base_action_state_value(DEPARTURE_PLAN_RISK_PROFILE_KEY, String(preview.get("risk_profile", "")))
	world_state.set_base_action_state_value(DEPARTURE_PLAN_COST_KEY, String(preview.get("cost", "")))
	world_state.set_base_action_state_value(DEPARTURE_PLAN_MODULE_KEY, String(preview.get("module", "")))
	world_state.set_base_action_state_value(DEPARTURE_PLAN_MODULE_EFFECT_KEY, String(preview.get("module_effect", "")))

static func _clear_departure_confirmation_snapshot(world_state: WorldState) -> void:
	world_state.set_base_action_state_value(DEPARTURE_PLAN_TARGET_KEY, "")
	world_state.set_base_action_state_value(DEPARTURE_PLAN_REWARD_KEY, "")
	world_state.set_base_action_state_value(DEPARTURE_PLAN_RISK_KEY, "")
	world_state.set_base_action_state_value(DEPARTURE_PLAN_RISK_PROFILE_KEY, "")
	world_state.set_base_action_state_value(DEPARTURE_PLAN_COST_KEY, "")
	world_state.set_base_action_state_value(DEPARTURE_PLAN_MODULE_KEY, "")
	world_state.set_base_action_state_value(DEPARTURE_PLAN_MODULE_EFFECT_KEY, "")

static func _get_departure_confirmation_preview(world_state: WorldState, plan_key: String) -> Dictionary:
	var preview := _get_plan_preview(plan_key).duplicate(true)
	if world_state == null or preview.is_empty():
		return preview
	var target := String(world_state.get_base_action_state_value(DEPARTURE_PLAN_TARGET_KEY, ""))
	var reward := String(world_state.get_base_action_state_value(DEPARTURE_PLAN_REWARD_KEY, ""))
	var risk := String(world_state.get_base_action_state_value(DEPARTURE_PLAN_RISK_KEY, ""))
	var risk_profile := String(world_state.get_base_action_state_value(DEPARTURE_PLAN_RISK_PROFILE_KEY, ""))
	var cost := String(world_state.get_base_action_state_value(DEPARTURE_PLAN_COST_KEY, ""))
	var module := String(world_state.get_base_action_state_value(DEPARTURE_PLAN_MODULE_KEY, ""))
	var module_effect := String(world_state.get_base_action_state_value(DEPARTURE_PLAN_MODULE_EFFECT_KEY, ""))
	if not target.is_empty():
		preview["target"] = target
	if not reward.is_empty():
		preview["reward"] = reward
	if not risk.is_empty():
		preview["risk"] = risk
	if not risk_profile.is_empty():
		preview["risk_profile"] = risk_profile
	if not cost.is_empty():
		preview["cost"] = cost
	if not module.is_empty():
		preview["module"] = module
	if not module_effect.is_empty():
		preview["module_effect"] = module_effect
	return preview

static func _format_departure_confirmation_message(plan_key: String, world_state: WorldState = null) -> String:
	var preview := _get_plan_preview_for_world(world_state, plan_key)
	if preview.is_empty():
		return "出发整备槽已确认：未定计划。"
	return "出发整备槽已确认：%s计划；模块：%s；风险：%s。\n风险拆解：%s。\n目标：%s；收益：%s；代价：%s。\n%s" % [
		String(preview.get("label", "")),
		String(preview.get("module", "")),
		String(preview.get("risk", "")),
		String(preview.get("risk_profile", "")),
		String(preview.get("target", "")),
		String(preview.get("reward", "")),
		String(preview.get("cost", "")),
		_format_window_outcome_preview_line_for_world(plan_key, world_state)
	]

static func _format_window_outcome_preview_line(plan_key: String) -> String:
	var window_target := BaseActionWindowOutcome.get_window_target(plan_key)
	var window_result := BaseActionWindowOutcome.get_window_result(plan_key)
	if window_target.is_empty() or window_result.is_empty():
		return ""
	return "窗口结果预览：%s；%s。" % [window_target, window_result]

static func _format_window_outcome_preview_line_for_world(plan_key: String, world_state: WorldState) -> String:
	var outcome_key := _get_effective_window_outcome_key(world_state, plan_key)
	var window_target := BaseActionWindowOutcome.get_window_target(outcome_key)
	var window_result := BaseActionWindowOutcome.get_window_result(outcome_key)
	if window_target.is_empty() or window_result.is_empty():
		return ""
	return "窗口结果预览：%s；%s。" % [window_target, window_result]

static func _format_departure_execution_message(plan_key: String, world_state: WorldState = null) -> String:
	var preview := _get_plan_preview_for_world(world_state, plan_key)
	match plan_key:
		PLAN_STEADY_SUPPLY:
			return "低风险补给计划已执行：当前计划：低风险补给；轻量整备模块：%s；目标：读取补给缓存。基础零件 +2，修复凝胶 +1；已按%s风险收益确认出发，先在前线处理窗口再回基地。" % [String(preview.get("module", "")), String(preview.get("risk", ""))]
		PLAN_PHASE_SURVEY:
			return "信息侦测计划已执行：当前计划：信息侦测；轻量整备模块：%s；目标：校准两处路线回波。同一前线异常窗口已载入侦测解法；已按%s风险收益确认出发，先在前线处理窗口再回基地。" % [String(preview.get("module", "")), String(preview.get("risk", ""))]
		PLAN_PRESSURE_CLEARANCE:
			if String(preview.get("module", "")) == OVERPRESSURE_MODULE_NAME:
				return "高压窗口计划已执行：当前计划：高压窗口；轻量整备模块：%s；目标：按三类模块收益处理更危险窗口。修复凝胶 +1，抗污染药剂 +1；已按%s风险收益确认出发。" % [String(preview.get("module", "")), String(preview.get("risk", ""))]
			return "压力清障防护计划已执行：当前计划：压力清障；轻量整备模块：%s；目标：先按 J 击退清障扰动守卫，再按 E 处理异常窗口。修复凝胶 +1，抗污染药剂 +1；已按%s风险收益确认出发。" % [String(preview.get("module", "")), String(preview.get("risk", ""))]
		_:
			return "出发计划已执行。"

static func _is_pressure_clearance_guard_required(world_state: WorldState) -> bool:
	return world_state != null and is_frontline_window_active(world_state) and get_frontline_window_plan_key(world_state) == PLAN_PRESSURE_CLEARANCE and not bool(world_state.get_enemy(PRESSURE_CLEARANCE_GUARD_INSTANCE_ID).get("is_defeated", false))

static func _is_known_plan_key(plan_key: String) -> bool:
	return plan_key == PLAN_STEADY_SUPPLY or plan_key == PLAN_PHASE_SURVEY or plan_key == PLAN_PRESSURE_CLEARANCE

static func _get_preparation_status(world_state: WorldState, key: String, feedback_quest_id: String) -> String:
	if world_state == null:
		return ""
	var explicit_status := String(world_state.get_base_action_state_value(key, ""))
	if not explicit_status.is_empty():
		return explicit_status
	if world_state.quest_state.has_completed_quest(feedback_quest_id):
		return STATUS_READY
	return ""
