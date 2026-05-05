extends RefCounted
class_name HudFeedbackPresenter


func show_evacuation_feedback(result: Dictionary, hud: PrototypeHud) -> void:
	var feedback := get_evacuation_feedback(result)
	if feedback.is_empty():
		return
	hud.show_evacuation_feedback(feedback)


func show_supply_feedback(result: Dictionary, hud: PrototypeHud) -> void:
	var feedback := get_supply_feedback(result)
	if feedback.is_empty():
		return
	hud.show_supply_feedback(feedback)


func format_quest_completion_panel_texts(feedback: Dictionary) -> Dictionary:
	if feedback.is_empty():
		return {}
	return {
		"title": _format_quest_completion_panel_title(feedback),
		"detail": _format_quest_completion_details(feedback)
	}


func get_evacuation_feedback(result: Dictionary) -> Dictionary:
	var feedback = result.get("evacuation_feedback", {})
	if feedback is Dictionary:
		return feedback
	return {}


func get_supply_feedback(result: Dictionary) -> Dictionary:
	var feedback = result.get("supply_feedback", {})
	if feedback is Dictionary:
		return feedback
	return {}


func _format_quest_completion_panel_title(feedback: Dictionary) -> String:
	var panel_title := String(feedback.get("panel_title", ""))
	if not panel_title.strip_edges().is_empty():
		return panel_title
	var title := String(feedback.get("title", "任务完成"))
	if title.find("切片结尾") >= 0:
		return "切片完成"
	return "任务完成"


func _format_quest_completion_details(feedback: Dictionary) -> String:
	var details: Array[String] = []
	var completed_text := String(feedback.get("completed_text", ""))
	if completed_text.strip_edges().is_empty():
		completed_text = _format_completed_text_from_title(String(feedback.get("title", "")))
	_append_detail(details, completed_text)
	_append_detail(details, String(feedback.get("reward_text", "")))
	_append_detail(details, String(feedback.get("unlock_text", "")))
	_append_detail(details, _format_note_detail(String(feedback.get("note_text", ""))))
	_append_detail(details, String(feedback.get("next_goal_text", "")))
	if details.is_empty():
		return "暂无任务完成反馈"
	return "\n".join(details)


func _format_completed_text_from_title(title: String) -> String:
	if title.begins_with("任务完成："):
		return "完成：%s" % title.trim_prefix("任务完成：")
	if title.strip_edges().is_empty():
		return ""
	return "完成：%s" % title


func _format_note_detail(note_text: String) -> String:
	if note_text.strip_edges().is_empty() or note_text.begins_with("提示："):
		return note_text
	return "提示：%s" % note_text


func _append_detail(details: Array[String], text: String) -> void:
	if text.strip_edges().is_empty():
		return
	details.append(text)
