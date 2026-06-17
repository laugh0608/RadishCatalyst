extends RefCounted
class_name DemoActionBlockerRecoveryFormatter


static func format_interaction_prerequisite_failure(
	reason: String,
	gap: String,
	recovery_route: String
) -> Dictionary:
	return _build_feedback("交互前置不足", reason, gap, recovery_route)


static func format_already_processed_failure(
	object_name: String,
	state_label: String,
	recovery_route: String
) -> Dictionary:
	return _build_feedback(
		"目标已处理",
		"%s已处于完成态。" % object_name,
		state_label,
		recovery_route
	)


static func format_build_prerequisite_failure(
	building_name: String,
	reason: String,
	gap: String,
	recovery_route: String
) -> Dictionary:
	return _build_feedback(
		"建造前置不足",
		"%s无法建造：%s" % [building_name, _trim_sentence(reason)],
		gap,
		recovery_route
	)


static func format_build_material_failure(
	building_name: String,
	missing_costs: Array[String],
	recovery_route: String
) -> Dictionary:
	return _build_feedback(
		"建造材料不足",
		"%s建造材料不足。" % building_name,
		"缺少：%s。" % ", ".join(missing_costs),
		recovery_route
	)


static func format_processing_missing_input_failure(
	recipe_name: String,
	missing_inputs: Array[String],
	recovery_route: String
) -> Dictionary:
	return _build_feedback(
		"原料不足",
		"%s无法启动加工。" % recipe_name,
		"缺少原料：%s。" % ", ".join(missing_inputs),
		recovery_route
	)


static func format_processing_busy_failure(
	recipe_name: String,
	active_status: String,
	recovery_route: String
) -> Dictionary:
	return _build_feedback(
		"设备加工中",
		"%s暂不能启动。" % recipe_name,
		active_status,
		recovery_route
	)


static func format_supply_failure(title: String, reason: String, recovery_route: String) -> Dictionary:
	return _build_feedback(
		title,
		reason,
		"快捷栏、背包数量或当前生命 / 防护状态未满足使用条件。",
		recovery_route
	)


static func format_core_write_failure(reason: String, recovery_route: String) -> Dictionary:
	return _build_feedback(
		"核心写入受阻",
		reason,
		_get_core_write_gap(reason),
		recovery_route
	)


static func _build_feedback(
	title: String,
	reason: String,
	gap: String,
	recovery_route: String
) -> Dictionary:
	var detail_parts: Array[String] = []
	_append_detail(detail_parts, "原因", reason)
	_append_detail(detail_parts, "缺口", gap)
	_append_detail(detail_parts, "恢复", recovery_route)
	return {
		"title": title,
		"detail": "；".join(detail_parts)
	}


static func _get_core_write_gap(reason: String) -> String:
	if reason.find("守卫") >= 0:
		return "核心阶段守卫状态仍未写入已击败。"
	if reason.find("校验片") >= 0:
		return "核心写入校验片任务进度仍不足 1 / 1。"
	if reason.find("开放") >= 0:
		return "核心写入任务尚未成为当前目标。"
	return "核心写入前置仍未满足。"


static func _append_detail(parts: Array[String], label: String, text: String) -> void:
	var clean_text := _trim_sentence(text)
	if clean_text.is_empty():
		return
	parts.append("%s：%s" % [label, clean_text])


static func _trim_sentence(text: String) -> String:
	return text.strip_edges().trim_suffix("。")
