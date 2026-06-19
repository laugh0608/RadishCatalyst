extends RefCounted
class_name HudLogPresenter

const STARTUP_LOG := "前哨已启动。WASD 移动，E 交互，J 攻击，Q 设备面板，1/2 使用补给。先检查前哨核心。"

var data_registry: DataRegistry


func _init(registry: DataRegistry = null) -> void:
	data_registry = registry


func format_startup_log() -> String:
	return STARTUP_LOG


func format_result_log(result: Dictionary) -> String:
	if bool(result.get("success", false)):
		return format_success_result_log(result)
	return format_failure_result_log(result)


func format_success_result_log(result: Dictionary) -> String:
	var feedback = result.get("success_feedback", {})
	if not feedback is Dictionary or feedback.is_empty():
		return String(result.get("message", ""))

	var title := String(feedback.get("title", "操作完成"))
	var details: Array[String] = []
	_append_log_detail(details, "下一步", _compact_next_step(String(feedback.get("next_step", ""))))
	_append_log_detail(details, "去向", _compact_destination(String(feedback.get("destination", ""))))
	var industrial_line := _compact_next_step(String(feedback.get("industrial_spine", "")))
	_append_log_detail(details, "工艺", industrial_line)
	_append_log_detail(details, "设备", _compact_device_operation(String(feedback.get("device_operation", ""))))
	if bool(feedback.get("show_resource_chain", false)):
		_append_log_detail(details, "资源链", _compact_next_step(String(feedback.get("resource_chain", ""))))
	_append_log_detail(details, "再进入", _compact_next_step(String(feedback.get("base_reentry", ""))))
	_append_log_detail(details, "状态", _compact_status(String(feedback.get("status", ""))))
	if details.is_empty():
		return title
	return "%s\n%s" % [title, "；".join(details)]


func format_failure_result_log(result: Dictionary) -> String:
	var message := String(result.get("message", "操作未完成。"))
	var feedback = result.get("failure_feedback", {})
	if not feedback is Dictionary or feedback.is_empty():
		return message

	var title := String(feedback.get("title", "操作未完成"))
	var detail := String(feedback.get("detail", ""))
	if detail.strip_edges().is_empty():
		return "%s：%s" % [title, message]
	return "%s：%s 下一步：%s" % [title, message, detail]


func format_slot_result_log(slot_id: String, result: Dictionary) -> String:
	return "%s：%s" % [_format_slot_name(slot_id), String(result.get("message", ""))]


func format_new_game_log() -> String:
	return "已从头开始新原型进度；当前进度尚未保存。"


func format_no_device_panel_target_log() -> String:
	return "附近没有可查看的加工设备；靠近基础反应器或污染过滤器后按 Q。"


func format_device_panel_opened_log(device_id: String) -> String:
	return "已打开设备面板：%s。" % _get_display_name(device_id)


func format_filter_module_already_enabled_log(is_pollution_edge_ready: bool) -> String:
	if is_pollution_edge_ready:
		return "基础过滤模块已启用，污染边界区已标记。"
	return "基础过滤模块已启用。"


func format_filter_module_missing_log() -> String:
	return "背包中没有基础过滤模块，无法启用。"


func format_filter_module_enabled_log(is_pollution_edge_ready: bool) -> String:
	if is_pollution_edge_ready:
		return "已启用基础过滤模块，污染边界区已标记，污染消耗和污染反击压力降低。"
	return "已启用基础过滤模块，污染反击压力降低。还需要先扩建污染处理点，才能稳定推进污染边界。"


func format_recommended_recipe_selected_log(recipe_id: String) -> String:
	return "已为当前目标选中配方：%s。" % _get_display_name(recipe_id)


func format_region_entered_log(region_id: String) -> String:
	return "已进入：%s。" % _get_display_name(region_id)


func join_messages(messages: Array[String]) -> String:
	var clean_messages: Array[String] = []
	for message in messages:
		if message.strip_edges().is_empty():
			continue
		clean_messages.append(message)
	return " ".join(clean_messages)


func _append_log_detail(details: Array[String], label: String, text: String) -> void:
	if text.strip_edges().is_empty():
		return
	details.append("%s：%s" % [label, text])


func _compact_status(text: String) -> String:
	var compact := text.strip_edges().trim_suffix("。")
	compact = compact.replace("，预计 ", " ")
	compact = compact.replace(" 秒完成", " 秒")
	return compact


func _compact_destination(text: String) -> String:
	var compact := text.strip_edges()
	if compact.is_empty():
		return ""
	compact = compact.replace("。 副产已放入背包：", "；副产：")
	compact = compact.replace("产物已放入背包：", "")
	compact = compact.replace("副产已放入背包：", "副产：")
	compact = compact.replace("建造结果已写入", "")
	compact = compact.trim_suffix("。")
	if compact.is_empty():
		return ""
	return _shorten_text(compact, 34)


func _compact_next_step(text: String) -> String:
	var compact := text.strip_edges().trim_suffix("。")
	if compact.is_empty():
		return ""
	if compact.find("等待设备完成") >= 0:
		return "Q 设备面板查看进度"
	var semicolon_index := compact.find("；")
	if semicolon_index >= 0:
		compact = compact.substr(0, semicolon_index)
	var sentence_index := compact.find("。")
	if sentence_index >= 0:
		compact = compact.substr(0, sentence_index)
	compact = compact.replace("按 Q 打开设备面板", "Q 设备面板")
	return _shorten_text(compact, 36)


func _compact_device_operation(text: String) -> String:
	var compact := text.strip_edges().trim_suffix("。")
	if compact.is_empty():
		return ""
	compact = compact.replace("设备操作完成：", "")
	compact = compact.replace("设备操作：", "")
	compact = compact.replace(
		"核心稳压缓冲包完成后回核心稳定站按入口确认、侧边补给、阶段守卫、回写缓存继续",
		"核心缓冲包完成后回核心站：入口确认、侧边补给、阶段守卫、回写缓存"
	)
	return _shorten_text(compact, 44)


func _shorten_text(text: String, max_length: int) -> String:
	if text.length() <= max_length:
		return text
	return "%s..." % text.substr(0, maxi(0, max_length - 3))


func _format_slot_name(slot_id: String) -> String:
	if slot_id.begins_with("slot_"):
		var suffix := slot_id.trim_prefix("slot_")
		if suffix.is_valid_int():
			return "槽位 %02d" % int(suffix)
	return slot_id


func _get_display_name(definition_id: String) -> String:
	if definition_id.is_empty():
		return ""
	if data_registry == null:
		return definition_id

	var definition := data_registry.get_definition(definition_id)
	if definition.is_empty():
		return definition_id

	return data_registry.get_text(String(definition.get("display_name_key", definition_id)))
