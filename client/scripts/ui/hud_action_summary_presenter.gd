extends RefCounted
class_name HudActionSummaryPresenter

const LINE_MAX_CHARACTERS := 48
const RUNTIME_TEXT_ELLIPSIS := "..."


func format_label_text(
	objective_text: String,
	context_prompt_text: String,
	runtime_hint_text: String,
	last_log_summary_text: String
) -> String:
	var current_text := _format_objective(objective_text)
	if current_text.is_empty():
		current_text = "基地现场"
	var action_text := _format_step(context_prompt_text, runtime_hint_text, last_log_summary_text)
	if action_text.is_empty():
		action_text = "下一步：靠近可操作对象"
	return "%s\n%s" % [
		"当前：%s" % _shorten_runtime_text(current_text, LINE_MAX_CHARACTERS - 3),
		_shorten_runtime_text(action_text, LINE_MAX_CHARACTERS)
	]


func format_tooltip_text(
	objective_text: String,
	context_prompt_text: String,
	runtime_hint_text: String,
	last_log_summary_text: String
) -> String:
	return "\n".join([
		_format_objective(objective_text),
		context_prompt_text.strip_edges(),
		runtime_hint_text.strip_edges(),
		last_log_summary_text
	]).strip_edges()


func _format_objective(objective_text: String) -> String:
	for line in _get_clean_runtime_lines(objective_text):
		if line.begins_with("目标："):
			return line.substr("目标：".length())
	for line in _get_clean_runtime_lines(objective_text):
		if line == "当前目标" or line.begins_with("进度：") or line.begins_with("关键材料"):
			continue
		return line
	return ""


func _format_step(context_prompt_text: String, runtime_hint_text: String, last_log_summary_text: String) -> String:
	var prompt_step := _find_action_summary_line(context_prompt_text, ["操作：", "下一步：", "状态："])
	if not prompt_step.is_empty():
		return prompt_step
	var hint_step := _find_action_summary_line(runtime_hint_text, ["方向：", "提示："])
	if not hint_step.is_empty():
		return "下一步：%s" % _strip_runtime_line_prefix(hint_step)
	if not last_log_summary_text.is_empty():
		return "最近：%s" % last_log_summary_text
	return ""


func _find_action_summary_line(text: String, prefixes: Array[String]) -> String:
	var lines := _get_clean_runtime_lines(text)
	for prefix in prefixes:
		for line in lines:
			if line.begins_with(prefix):
				return line
	return ""


func _strip_runtime_line_prefix(line: String) -> String:
	var colon_index := line.find("：")
	if colon_index < 0:
		return line
	return line.substr(colon_index + 1).strip_edges()


func _get_clean_runtime_lines(text: String) -> Array[String]:
	var lines: Array[String] = []
	var normalized := text.replace("\r\n", "\n").replace("\r", "\n")
	for raw_line in normalized.split("\n", false):
		var line := String(raw_line).strip_edges()
		if line.is_empty():
			continue
		lines.append(line)
	return lines


func _shorten_runtime_text(text: String, max_characters: int) -> String:
	if text.length() <= max_characters:
		return text
	var visible_characters := maxi(0, max_characters - RUNTIME_TEXT_ELLIPSIS.length())
	return "%s%s" % [text.substr(0, visible_characters), RUNTIME_TEXT_ELLIPSIS]
