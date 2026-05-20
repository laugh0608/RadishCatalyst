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
const LAST_DEPARTURE_PLAN_KEY := "last_departure_plan_key"
const STATUS_READY := "ready"
const STATUS_QUEUED := "queued"
const STATUS_USED := "used"
const PLAN_STEADY_SUPPLY := "steady_supply_buffer"
const PLAN_PHASE_SURVEY := "phase_survey_intel"
const PLAN_PRESSURE_CLEARANCE := "pressure_clearance_guard"
const SUPPLY_FEEDBACK_QUEST_ID := "quest.analyze_steady_supply_trace"
const SURVEY_FEEDBACK_QUEST_ID := "quest.analyze_phase_survey_trace"
const PRESSURE_FEEDBACK_QUEST_ID := "quest.analyze_pressure_clearance_trace"
const ROUTE_TARGET_REGION_ID := "region.phase_well_tether"
const ROUTE_RISK_NOTE := "井系桥前线低压读数线：优先走西侧测绘边界，东侧节点存在短时扰动。"


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
		"status_goal": _format_status_goal(stage),
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
	var current_plan_key := get_current_plan_key(world_state)
	if current_plan_key.is_empty():
		current_plan_key = get_departure_plan_key(world_state)
	if current_plan_key == PLAN_STEADY_SUPPLY and get_supply_package_status(world_state) == STATUS_READY:
		world_state.set_base_action_state_value(SUPPLY_PACKAGE_STATUS_KEY, STATUS_QUEUED)
		world_state.set_base_action_state_value(DEPARTURE_PLAN_KEY, PLAN_STEADY_SUPPLY)
		world_state.set_base_action_state_value(CURRENT_PLAN_KEY, PLAN_STEADY_SUPPLY)
		messages.append("出发整备槽已确认：低风险补给计划待随下一次相位回投装入。")
	if current_plan_key == PLAN_PHASE_SURVEY and get_survey_intel_status(world_state) == STATUS_READY:
		world_state.set_base_action_state_value(SURVEY_INTEL_STATUS_KEY, STATUS_QUEUED)
		world_state.set_base_action_state_value(ROUTE_TARGET_REGION_KEY, ROUTE_TARGET_REGION_ID)
		world_state.set_base_action_state_value(ROUTE_RISK_NOTE_KEY, ROUTE_RISK_NOTE)
		world_state.set_base_action_state_value(DEPARTURE_PLAN_KEY, PLAN_PHASE_SURVEY)
		world_state.set_base_action_state_value(CURRENT_PLAN_KEY, PLAN_PHASE_SURVEY)
		messages.append("出发整备槽已确认：信息侦测计划待随下一次相位回投载入。")
	if current_plan_key == PLAN_PRESSURE_CLEARANCE and get_pressure_clearance_status(world_state) == STATUS_READY:
		world_state.set_base_action_state_value(PRESSURE_CLEARANCE_STATUS_KEY, STATUS_QUEUED)
		world_state.set_base_action_state_value(DEPARTURE_PLAN_KEY, PLAN_PRESSURE_CLEARANCE)
		world_state.set_base_action_state_value(CURRENT_PLAN_KEY, PLAN_PRESSURE_CLEARANCE)
		messages.append("出发整备槽已确认：压力清障防护计划待随下一次相位回投装入。")
	return messages


static func apply_departure_preparation(world_state: WorldState, character_state: CharacterState) -> Array[String]:
	var messages: Array[String] = []
	if world_state == null or character_state == null:
		return messages
	var departure_plan_key := get_departure_plan_key(world_state)
	if get_supply_package_status(world_state) == STATUS_QUEUED:
		character_state.inventory.add_item("item.basic_parts", 2)
		character_state.inventory.add_item("item.repair_gel", 1)
		world_state.set_base_action_state_value(SUPPLY_PACKAGE_STATUS_KEY, STATUS_USED)
		if departure_plan_key.is_empty():
			departure_plan_key = PLAN_STEADY_SUPPLY
		messages.append("低风险补给计划已执行：基础零件 +2，修复凝胶 +1。")
	if get_survey_intel_status(world_state) == STATUS_QUEUED:
		world_state.set_base_action_state_value(SURVEY_INTEL_STATUS_KEY, STATUS_USED)
		world_state.set_base_action_state_value(ROUTE_TARGET_REGION_KEY, ROUTE_TARGET_REGION_ID)
		world_state.set_base_action_state_value(ROUTE_RISK_NOTE_KEY, ROUTE_RISK_NOTE)
		if departure_plan_key.is_empty():
			departure_plan_key = PLAN_PHASE_SURVEY
		messages.append("信息侦测计划已执行：本趟路线情报已验证；井系桥前线暂无新交互目标，返回基地行动台安排下一计划。")
	if get_pressure_clearance_status(world_state) == STATUS_QUEUED:
		character_state.inventory.add_item("item.repair_gel", 1)
		character_state.inventory.add_item("item.resistance_vial_t1", 1)
		world_state.set_base_action_state_value(PRESSURE_CLEARANCE_STATUS_KEY, STATUS_USED)
		if departure_plan_key.is_empty():
			departure_plan_key = PLAN_PRESSURE_CLEARANCE
		messages.append("压力清障防护计划已执行：修复凝胶 +1，抗污染药剂 +1。")
	if not departure_plan_key.is_empty() and not messages.is_empty():
		world_state.set_base_action_state_value(LAST_DEPARTURE_PLAN_KEY, departure_plan_key)
		messages.append(_promote_next_plan_candidate(world_state, departure_plan_key))
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


static func select_next_plan_candidate_for_console(definition_id: String, world_state: WorldState) -> Array[String]:
	var plan_key := _get_plan_key_for_console(definition_id)
	if plan_key.is_empty() or not _can_replace_next_plan_candidate(world_state):
		return []
	world_state.set_base_action_state_value(NEXT_PLAN_CANDIDATE_KEY, plan_key)
	return ["下一计划候选已更新：%s。当前出发整备槽不变。" % _format_plan_label(plan_key)]


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
		"first_ready":
			return "稳窗相位序已完成现场校准：回基地在行动台确认稳窗回访，把前线窗口转成下一趟外出目标。"
		"first_dispatched":
			return "稳窗回访已派发：用相位回投返回井系桥东侧，读取稳窗回波探点后回基地。"
		"first_return":
			return "稳窗回波样本已带回：回基地使用基础反应器，把样本解析成前线行动回报。"
		"short_ready":
			return "前线行动回报已归档：回基地在行动台确认补给短行动，把上一趟收益转成下一趟补给目标。"
		"short_dispatched":
			return "补给短行动已派发：用相位回投返回井系桥前线，读取补给回执标记。"
		"short_return":
			return "补给回执读数已带回：回基地使用基础反应器，把读数解析成短行动反馈记录。"
		"route_ready":
			return "短行动反馈已归档：回基地在行动台确认巡线短行动，把连续行动接到路线信标。"
		"route_dispatched":
			return "巡线短行动已派发：用相位回投返回井系桥前线，读取巡线信标。"
		"route_return":
			return "巡线信标读数已带回：回基地使用基础反应器，把读数解析成巡线反馈记录。"
		"choice_ready":
			return "巡线反馈已归档：回基地行动台选择稳场补给、相位测绘或压力清障，决定下一趟风险收益。"
		"steady_supply_dispatched":
			return "稳场补给行动已派发：用相位回投返回井系桥前线，读取一处补给投放点后回基地。"
		"steady_supply_return":
			return "稳场补给回执已带回：回基地使用基础反应器，把补给收益解析成下一轮整备资源。"
		"steady_supply_ready":
			if get_supply_package_status(world_state) == STATUS_USED:
				return "稳场补给反馈已归档：补给整备包已经装入本趟出发，资源缓冲会随背包一起带到前线。"
			if get_supply_package_status(world_state) == STATUS_QUEUED:
				return "稳场补给整备槽已确认：下一步到相位回投台按 E 出发，回投时会装入基础零件和修复凝胶缓冲。"
			return "稳场补给反馈已归档：回基地在前线行动台确认出发整备槽，再从相位回投台外出。"
		"phase_survey_dispatched":
			return "相位测绘行动已派发：用相位回投返回井系桥前线，读取西侧和东侧两处测绘点。"
		"phase_survey_return":
			return "相位测绘记录已带回：回基地使用基础反应器，把测绘收益解析成下一趟路线提示。"
		"phase_survey_ready":
			if get_survey_intel_status(world_state) == STATUS_USED:
				return "相位测绘路线情报已生效：井系桥前线目前没有新的可交互目标；返回基地行动台安排下一计划。"
			if get_survey_intel_status(world_state) == STATUS_QUEUED:
				return "相位测绘整备槽已确认：下一步到相位回投台按 E 出发，回投时会载入井系桥前线目标和风险预告。"
			return "相位测绘反馈已归档：回基地在前线行动台确认出发整备槽，再从相位回投台外出。"
		"pressure_clearance_dispatched":
			return "压力清障行动已派发：用相位回投返回井系桥前线，清除一处前线压力扰点后回基地。"
		"pressure_clearance_return":
			return "压力清障回执已带回：回基地使用基础反应器，把清障收益解析成下一轮防护整备。"
		"pressure_clearance_ready":
			if get_pressure_clearance_status(world_state) == STATUS_USED:
				return "压力清障反馈已归档：防护整备已经装入本趟出发，后续清障分支可继续沿用行动台。"
			if get_pressure_clearance_status(world_state) == STATUS_QUEUED:
				return "压力清障整备槽已确认：下一步到相位回投台按 E 出发，回投时会装入修复凝胶和抗污染药剂。"
			return "压力清障反馈已归档：回基地在前线行动台确认清障防护整备槽，再从相位回投台外出。"
		_:
			return ""


static func _format_onboarding(stage: String) -> String:
	match stage:
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


static func _format_status_goal(stage: String) -> String:
	match stage:
		"choice_ready":
			return "基地行动方案待选择"
		"steady_supply_ready":
			return "补给整备已生效"
		"phase_survey_ready":
			return "测绘整备已生效"
		"pressure_clearance_ready":
			return "清障整备已生效"
		_:
			return _format_title(stage)


static func _format_status_progress(stage: String, world_state: WorldState) -> String:
	match stage:
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
				return "相位测绘路线情报已生效；井系桥前线没有新交互目标，返回基地行动台安排下一计划"
			if get_survey_intel_status(world_state) == STATUS_QUEUED:
				return "相位测绘整备槽已确认；到相位回投台按 E 出发，回投时载入路线提示"
			return "相位测绘反馈已归档；到前线行动台按 E 确认测绘路线整备槽"
		"pressure_clearance_ready":
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
		"choice_ready":
			return [
				"方案 A：稳场补给；目标 1 处；回报偏基础零件和修复凝胶。",
				"方案 B：相位测绘；目标 2 处；回报偏路线提示和风险预告。",
				"方案 C：压力清障；清除 1 处压力扰点；回报偏防护整备。"
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
			supply_lines.append_array(_format_plan_queue_lines(world_state))
			supply_lines.append_array(_format_departure_plan_lines(PLAN_STEADY_SUPPLY))
			return supply_lines
		"phase_survey_ready":
			var intel_status := get_survey_intel_status(world_state)
			var intel_line := "路线提示：待确认；目标显形到井系桥前线。"
			if intel_status == STATUS_QUEUED:
				intel_line = "路线提示：整备槽已确认；到相位回投台按 E 出发时载入。"
			if intel_status == STATUS_USED:
				intel_line = "路线提示：已完成本趟验证；井系桥前线没有新的可交互目标。"
			var survey_lines: Array[String] = [
				"整备：抗污染药剂 %d；基础零件 %d。" % [vial_count, parts_count],
				intel_line,
				"风险预告：%s" % get_route_risk_note(world_state)
			]
			survey_lines.append_array(_format_plan_queue_lines(world_state))
			survey_lines.append_array(_format_departure_plan_lines(PLAN_PHASE_SURVEY))
			return survey_lines
		"pressure_clearance_ready":
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
			pressure_lines.append_array(_format_plan_queue_lines(world_state))
			pressure_lines.append_array(_format_departure_plan_lines(PLAN_PRESSURE_CLEARANCE))
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
				"first_ready":
					return "按 E 确认：稳窗回访。"
				"short_ready":
					return "按 E 确认：补给短行动。"
				"route_ready":
					return "按 E 确认：巡线短行动。"
				"steady_supply_ready":
					return "按 E 确认：出发补给整备槽。"
				"phase_survey_ready":
					return "按 E 确认：测绘路线整备槽。"
				"pressure_clearance_ready":
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


static func _format_departure_plan_lines(plan_key: String) -> Array[String]:
	match plan_key:
		PLAN_STEADY_SUPPLY:
			return [
				"计划：低风险补给；预计收益为基础零件 +2、修复凝胶 +1。",
				"风险：低；不增加前线读点，适合补资源缓冲。",
				"代价：占用本次出发整备槽，回投时一次性消耗。"
			]
		PLAN_PHASE_SURVEY:
			return [
				"计划：信息侦测；预计收益为目标显形和路线风险预告。",
				"风险：中；需要按低压读数线避开东侧短时扰动。",
				"代价：占用本次出发整备槽，不额外发放资源。"
			]
		PLAN_PRESSURE_CLEARANCE:
			return [
				"计划：压力清障；预计收益为修复凝胶 +1、抗污染药剂 +1。",
				"风险：高；需要清除一处前线压力扰点。",
				"代价：占用本次出发整备槽，回投时一次性装入。"
			]
		_:
			return []


static func _format_plan_queue_lines(world_state: WorldState) -> Array[String]:
	var current_plan := get_current_plan_key(world_state)
	var next_candidate := get_next_plan_candidate_key(world_state)
	var lines: Array[String] = []
	if not current_plan.is_empty():
		lines.append("当前计划槽：%s。" % _format_plan_label(current_plan))
	if not next_candidate.is_empty():
		lines.append("下一计划候选：%s；可在对应方案终端替换。" % _format_plan_label(next_candidate))
	return lines


static func _format_candidate_console_action_line(plan_key: String, world_state: WorldState) -> String:
	if get_next_plan_candidate_key(world_state) == plan_key:
		return "下一计划候选已是：%s。" % _format_plan_label(plan_key)
	return "按 E 替换下一计划候选：%s。" % _format_plan_label(plan_key)


static func _set_current_plan_slot(world_state: WorldState, plan_key: String) -> void:
	world_state.set_base_action_state_value(CURRENT_PLAN_KEY, plan_key)
	if String(world_state.get_base_action_state_value(NEXT_PLAN_CANDIDATE_KEY, "")).is_empty():
		world_state.set_base_action_state_value(NEXT_PLAN_CANDIDATE_KEY, _get_alternate_plan_key(plan_key))


static func _can_replace_next_plan_candidate(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	if world_state.quest_state.has_active_quest("quest.choose_steady_supply_action"):
		return false
	if world_state.quest_state.has_active_quest("quest.choose_phase_survey_action"):
		return false
	if world_state.quest_state.has_active_quest("quest.choose_pressure_clearance_action"):
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
	var promoted_plan_key := get_next_plan_candidate_key(world_state)
	if promoted_plan_key.is_empty():
		promoted_plan_key = _get_alternate_plan_key(executed_plan_key)
	if promoted_plan_key.is_empty():
		world_state.set_base_action_state_value(DEPARTURE_PLAN_KEY, "")
		return "下一计划候选为空：返回基地行动台选择或替换后续方案。"

	_set_plan_status(world_state, promoted_plan_key, STATUS_READY)
	world_state.set_base_action_state_value(CURRENT_PLAN_KEY, promoted_plan_key)
	world_state.set_base_action_state_value(NEXT_PLAN_CANDIDATE_KEY, _get_alternate_plan_key(promoted_plan_key))
	world_state.set_base_action_state_value(DEPARTURE_PLAN_KEY, "")
	return "下一计划候选已进入当前计划槽：%s；回基地在前线行动台按 E 确认，或在方案终端替换下一候选。" % _format_plan_label(promoted_plan_key)


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
	match plan_key:
		PLAN_STEADY_SUPPLY:
			return "低风险补给"
		PLAN_PHASE_SURVEY:
			return "信息侦测"
		PLAN_PRESSURE_CLEARANCE:
			return "压力清障"
		_:
			return "未定计划"


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
