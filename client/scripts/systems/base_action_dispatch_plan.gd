extends RefCounted
class_name BaseActionDispatchPlan

const CONSOLE_DEFINITION_IDS: Array[String] = [
	"map_object.frontline_action_console",
	"map_object.frontline_supply_console",
	"map_object.frontline_route_console",
	"map_object.base_supply_choice_console",
	"map_object.base_survey_choice_console"
]
const SUPPLY_PACKAGE_STATUS_KEY := "supply_package_status"
const SURVEY_INTEL_STATUS_KEY := "survey_intel_status"
const ROUTE_TARGET_REGION_KEY := "route_target_region_id"
const ROUTE_RISK_NOTE_KEY := "route_risk_note"
const STATUS_READY := "ready"
const STATUS_USED := "used"
const SUPPLY_FEEDBACK_QUEST_ID := "quest.analyze_steady_supply_trace"
const SURVEY_FEEDBACK_QUEST_ID := "quest.analyze_phase_survey_trace"
const ROUTE_TARGET_REGION_ID := "region.phase_well_tether"
const ROUTE_RISK_NOTE := "井系桥前线低压读数线：优先走西侧测绘边界，东侧节点存在短时扰动。"


static func is_action_console(definition_id: String) -> bool:
	return CONSOLE_DEFINITION_IDS.has(definition_id)


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
			return ["行动台整备：下一次出发补给包待装入"]
		SURVEY_FEEDBACK_QUEST_ID:
			world_state.set_base_action_state_value(SURVEY_INTEL_STATUS_KEY, STATUS_READY)
			world_state.set_base_action_state_value(ROUTE_TARGET_REGION_KEY, ROUTE_TARGET_REGION_ID)
			world_state.set_base_action_state_value(ROUTE_RISK_NOTE_KEY, ROUTE_RISK_NOTE)
			return ["行动台情报：下一次出发路线提示待载入"]
		_:
			return []


static func apply_departure_preparation(world_state: WorldState, character_state: CharacterState) -> Array[String]:
	var messages: Array[String] = []
	if world_state == null or character_state == null:
		return messages
	if get_supply_package_status(world_state) == STATUS_READY:
		character_state.inventory.add_item("item.basic_parts", 2)
		character_state.inventory.add_item("item.repair_gel", 1)
		world_state.set_base_action_state_value(SUPPLY_PACKAGE_STATUS_KEY, STATUS_USED)
		messages.append("补给整备包已装入本趟出发：基础零件 +2，修复凝胶 +1。")
	if get_survey_intel_status(world_state) == STATUS_READY:
		world_state.set_base_action_state_value(SURVEY_INTEL_STATUS_KEY, STATUS_USED)
		world_state.set_base_action_state_value(ROUTE_TARGET_REGION_KEY, ROUTE_TARGET_REGION_ID)
		world_state.set_base_action_state_value(ROUTE_RISK_NOTE_KEY, ROUTE_RISK_NOTE)
		messages.append("测绘路线提示已载入：井系桥前线目标显形；风险预告为低压读数线，优先走西侧测绘边界。")
	return messages


static func get_supply_package_status(world_state: WorldState) -> String:
	return _get_preparation_status(world_state, SUPPLY_PACKAGE_STATUS_KEY, SUPPLY_FEEDBACK_QUEST_ID)


static func get_survey_intel_status(world_state: WorldState) -> String:
	return _get_preparation_status(world_state, SURVEY_INTEL_STATUS_KEY, SURVEY_FEEDBACK_QUEST_ID)


static func get_route_target_region_id(world_state: WorldState) -> String:
	if world_state == null:
		return ""
	var status := get_survey_intel_status(world_state)
	if status != STATUS_READY and status != STATUS_USED:
		return ""
	return String(world_state.get_base_action_state_value(ROUTE_TARGET_REGION_KEY, ROUTE_TARGET_REGION_ID))


static func get_route_risk_note(world_state: WorldState) -> String:
	if get_route_target_region_id(world_state).is_empty():
		return ""
	if world_state == null:
		return ""
	return String(world_state.get_base_action_state_value(ROUTE_RISK_NOTE_KEY, ROUTE_RISK_NOTE))


static func format_console_prompt(definition_id: String, world_state: WorldState, character_state: CharacterState) -> String:
	var summary := summarize(world_state, character_state)
	if summary.is_empty():
		return _format_default_console_prompt(definition_id)

	var parts: Array[String] = [
		"基地行动台：%s" % String(summary.get("title", "行动调度")),
		"状态：%s" % String(summary.get("status_progress", "等待下一步行动调度。"))
	]
	var preparation_lines: Array = summary.get("preparation_lines", [])
	for line in preparation_lines:
		parts.append(String(line))
	var console_line := _format_console_action_line(definition_id, String(summary.get("stage", "")))
	if not console_line.is_empty():
		parts.append(console_line)
	return "\n".join(parts)


static func _get_stage(world_state: WorldState) -> String:
	if world_state == null:
		return ""
	var quest_state := world_state.quest_state
	if quest_state.has_completed_quest("quest.analyze_phase_survey_trace"):
		return "phase_survey_ready"
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
	if quest_state.has_active_quest("quest.choose_steady_supply_action") or quest_state.has_active_quest("quest.choose_phase_survey_action") or quest_state.has_completed_quest("quest.analyze_route_signal_trace"):
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
			return "巡线反馈已归档：回基地行动台选择稳场补给或相位测绘，决定下一趟是低风险补给还是路线侦测。"
		"steady_supply_dispatched":
			return "稳场补给行动已派发：用相位回投返回井系桥前线，读取一处补给投放点后回基地。"
		"steady_supply_return":
			return "稳场补给回执已带回：回基地使用基础反应器，把补给收益解析成下一轮整备资源。"
		"steady_supply_ready":
			if get_supply_package_status(world_state) == STATUS_USED:
				return "稳场补给反馈已归档：补给整备包已经装入本趟出发，资源缓冲会随背包一起带到前线。"
			return "稳场补给反馈已归档：补给整备已进入行动台，下一趟外出会装入基础零件和修复凝胶缓冲。"
		"phase_survey_dispatched":
			return "相位测绘行动已派发：用相位回投返回井系桥前线，读取西侧和东侧两处测绘点。"
		"phase_survey_return":
			return "相位测绘记录已带回：回基地使用基础反应器，把测绘收益解析成下一趟路线提示。"
		"phase_survey_ready":
			if get_survey_intel_status(world_state) == STATUS_USED:
				return "相位测绘反馈已归档：测绘路线提示已经载入本趟出发，井系桥前线目标和风险预告保持显形。"
			return "相位测绘反馈已归档：测绘整备已进入行动台，下一趟外出会载入井系桥前线路线提示、目标显形和风险预告。"
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
		"steady_supply_dispatched", "steady_supply_return":
			return "当前行动选择偏稳：目标少、路线短，收益集中在基础零件和修复凝胶。"
		"phase_survey_dispatched", "phase_survey_return":
			return "当前行动选择偏侦测：要读取两处目标，收益集中在路线判断和风险预告。"
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
		_:
			return _format_title(stage)


static func _format_status_progress(stage: String, world_state: WorldState) -> String:
	match stage:
		"choice_ready":
			return "行动台待选择：稳场补给提供低风险补给包；相位测绘提供两点路线提示"
		"steady_supply_ready":
			if get_supply_package_status(world_state) == STATUS_USED:
				return "稳场补给反馈已归档；本趟出发已装入基础零件和修复凝胶补给包"
			return "稳场补给反馈已归档；下一次从基地回投会装入基础零件和修复凝胶补给包"
		"phase_survey_ready":
			if get_survey_intel_status(world_state) == STATUS_USED:
				return "相位测绘反馈已归档；本趟出发已载入井系桥前线目标和风险预告"
			return "相位测绘反馈已归档；下一次从基地回投会载入井系桥前线目标和风险预告"
		"steady_supply_dispatched":
			return "稳场补给已选择；前线目标压缩为一处补给投放点"
		"phase_survey_dispatched":
			return "相位测绘已选择；前线目标展开为西侧和东侧两处测绘点"
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
				"方案 B：相位测绘；目标 2 处；回报偏路线提示和风险预告。"
			]
		"steady_supply_ready":
			var package_status := get_supply_package_status(world_state)
			var package_line := "出发补给包：待装入；基础零件 +2，修复凝胶 +1。"
			if package_status == STATUS_USED:
				package_line = "出发补给包：已装入本趟回投；资源缓冲已进入背包。"
			return [
				"整备：基础零件 %d；修复凝胶 %d。" % [parts_count, repair_count],
				package_line,
				"效果：下一趟出发优先按补给缓冲规划，适合低风险回收。"
			]
		"phase_survey_ready":
			var intel_status := get_survey_intel_status(world_state)
			var intel_line := "路线提示：待载入；目标显形到井系桥前线。"
			if intel_status == STATUS_USED:
				intel_line = "路线提示：已载入本趟回投；井系桥前线目标保持显形。"
			return [
				"整备：抗污染药剂 %d；基础零件 %d。" % [vial_count, parts_count],
				intel_line,
				"风险预告：%s" % get_route_risk_note(world_state)
			]
		"steady_supply_dispatched", "steady_supply_return":
			return ["已选：稳场补给；目标少、路线短，收益偏整备资源。"]
		"phase_survey_dispatched", "phase_survey_return":
			return ["已选：相位测绘；目标多、信息量高，收益偏路线提示。"]
		_:
			return ["整备：沿用当前补给；行动台等待本趟返回数据。"]


static func _format_console_action_line(definition_id: String, stage: String) -> String:
	match definition_id:
		"map_object.frontline_action_console":
			if stage == "first_ready":
				return "按 E 确认：稳窗回访。"
		"map_object.frontline_supply_console":
			if stage == "short_ready":
				return "按 E 确认：补给短行动。"
		"map_object.frontline_route_console":
			if stage == "route_ready":
				return "按 E 确认：巡线短行动。"
		"map_object.base_supply_choice_console":
			if stage == "choice_ready":
				return "按 E 选择：稳场补给方案。"
		"map_object.base_survey_choice_console":
			if stage == "choice_ready":
				return "按 E 选择：相位测绘方案。"
	return "当前终端已纳入行动台；按 HUD 目标推进。"


static func _format_default_console_prompt(definition_id: String) -> String:
	match definition_id:
		"map_object.base_supply_choice_console":
			return "基地行动台：稳场补给方案\n状态：等待巡线反馈归档后开放选择。"
		"map_object.base_survey_choice_console":
			return "基地行动台：相位测绘方案\n状态：等待巡线反馈归档后开放选择。"
		_:
			return "基地行动台：行动调度\n状态：等待前置目标完成。"


static func _get_item_count(character_state: CharacterState, item_id: String) -> int:
	if character_state == null:
		return 0
	return int(character_state.inventory.items.get(item_id, 0))


static func _get_preparation_status(world_state: WorldState, key: String, feedback_quest_id: String) -> String:
	if world_state == null:
		return ""
	var explicit_status := String(world_state.get_base_action_state_value(key, ""))
	if not explicit_status.is_empty():
		return explicit_status
	if world_state.quest_state.has_completed_quest(feedback_quest_id):
		return STATUS_READY
	return ""
