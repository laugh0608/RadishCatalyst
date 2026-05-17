extends RefCounted
class_name HudDevelopmentBaselinePresenter


func format_selected_baseline(definition: Dictionary, current_index: int, total_count: int) -> String:
	if definition.is_empty():
		return "开发基线读取中..."

	return "%d/%d %s\n阶段：%s\n适用：%s" % [
		current_index + 1,
		total_count,
		String(definition.get("display_name", "开发基线")),
		String(definition.get("summary", "")),
		String(definition.get("recommended_for", ""))
	]
