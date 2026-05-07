extends RefCounted
class_name HudLogPresenter

const STARTUP_LOG := "前哨原型已启动。WASD 移动，E 交互，J 攻击，R 切换设备配方，Q 打开或关闭设备面板，F 启用过滤模块，1/2 使用快捷栏；K / L 操作默认槽位，Tab 显示或隐藏存档 / 快捷栏调试面板。先检查前哨核心。"

var data_registry: DataRegistry


func _init(registry: DataRegistry = null) -> void:
	data_registry = registry


func format_startup_log() -> String:
	return STARTUP_LOG


func format_result_log(result: Dictionary) -> String:
	if bool(result.get("success", false)):
		return String(result.get("message", ""))
	return format_failure_result_log(result)


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
		return "已启用基础过滤模块，污染边界区已标记，污染防护消耗降低。"
	return "已启用基础过滤模块。还需要先扩建污染处理点，才能稳定推进污染边界。"


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
