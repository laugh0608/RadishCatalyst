extends RefCounted
class_name HudMapPresenter

const MAP_MARKER_CURRENT_COLOR := Color(0.18, 0.86, 0.93, 1.0)
const MAP_MARKER_TARGET_COLOR := Color(1.0, 0.78, 0.28, 1.0)
const MAP_MARKER_UNLOCKED_COLOR := Color(0.55, 0.72, 0.66, 1.0)
const MAP_MARKER_LOCKED_COLOR := Color(0.28, 0.32, 0.32, 1.0)


func get_marker_view_data(world_state: WorldState, quest_id: String) -> Array[Dictionary]:
	var target_region_id := _get_quest_target_region_id(world_state, quest_id)
	var view_data: Array[Dictionary] = []
	for marker in _get_region_marker_data():
		var region_id := String(marker.get("region_id", ""))
		view_data.append({
			"label": _format_map_marker_label(marker, world_state, target_region_id),
			"color": _get_map_marker_color(region_id, world_state, target_region_id)
		})
	return view_data


func format_region_markers(world_state: WorldState, quest_id: String) -> String:
	var target_region_id := _get_quest_target_region_id(world_state, quest_id)
	var parts: Array[String] = []
	for marker in _get_region_marker_data():
		var region_id := String(marker.get("region_id", ""))
		var marker_parts: Array[String] = []
		if world_state.current_region_id == region_id:
			marker_parts.append("当前位置")
		else:
			marker_parts.append(String(marker.get("direction", "")))

		if target_region_id == region_id:
			marker_parts.append("目标")
		elif world_state.unlocked_region_ids.has(region_id):
			marker_parts.append("已解锁")
		else:
			marker_parts.append("未解锁")

		parts.append("%s：%s" % [
			String(marker.get("label", region_id)),
			"，".join(marker_parts)
		])
	return "；".join(parts)


func format_map_marker_labels(world_state: WorldState, quest_id: String) -> Array[String]:
	var labels: Array[String] = []
	for marker_view in get_marker_view_data(world_state, quest_id):
		labels.append(String(marker_view.get("label", "")))
	return labels


func _get_region_marker_data() -> Array[Dictionary]:
	return [
		{
			"region_id": "region.outpost_platform",
			"label": "基地",
			"direction": "西侧"
		},
		{
			"region_id": "region.crystal_vein_field",
			"label": "晶体",
			"direction": "东侧"
		},
		{
			"region_id": "region.pollution_edge",
			"label": "污染",
			"direction": "东南"
		},
		{
			"region_id": "region.locked_ruin_gate",
			"label": "遗迹",
			"direction": "东端"
		}
	]


func _format_map_marker_label(marker: Dictionary, world_state: WorldState, target_region_id: String) -> String:
	var region_id := String(marker.get("region_id", ""))
	var rows: Array[String] = [String(marker.get("label", region_id))]
	if world_state.current_region_id == region_id:
		rows.append("当前")
	if target_region_id == region_id:
		rows.append("目标")
	elif world_state.unlocked_region_ids.has(region_id):
		rows.append("已解锁")
	else:
		rows.append("未解锁")
	return "\n".join(rows)


func _get_map_marker_color(region_id: String, world_state: WorldState, target_region_id: String) -> Color:
	if world_state.current_region_id == region_id:
		return MAP_MARKER_CURRENT_COLOR
	if target_region_id == region_id:
		return MAP_MARKER_TARGET_COLOR
	if world_state.unlocked_region_ids.has(region_id):
		return MAP_MARKER_UNLOCKED_COLOR
	return MAP_MARKER_LOCKED_COLOR


func _get_quest_target_region_id(world_state: WorldState, quest_id: String) -> String:
	match quest_id:
		"quest.restore_outpost":
			return "region.outpost_platform"
		"quest.scout_crystal_field":
			return "region.crystal_vein_field"
		"quest.calibrate_reactor":
			if world_state.quest_state.get_objective_progress(quest_id, "gather_item", "item.salvage_scrap") < 4.0:
				return "region.crystal_vein_field"
			return "region.outpost_platform"
		"quest.bring_back_sample":
			if world_state.quest_state.get_objective_progress(quest_id, "sample_object", "map_object.anomaly_crystal") <= 0.0:
				return "region.crystal_vein_field"
			return "region.outpost_platform"
		"quest.analyze_anomaly_sample":
			if world_state.quest_state.get_objective_progress(quest_id, "gather_item", "item.anomaly_residue") < 2.0:
				return "region.crystal_vein_field"
			return "region.outpost_platform"
		"quest.make_filter_module":
			return "region.outpost_platform"
		"quest.prepare_treatment_supplies":
			if world_state.quest_state.get_objective_progress(quest_id, "craft_item", "item.repair_gel") <= 0.0:
				return "region.outpost_platform"
			return "region.crystal_vein_field"
		"quest.expand_treatment_point", "quest.enter_pollution_edge", "quest.defeat_elite_node":
			return "region.pollution_edge"
		"quest.unlock_ruin_signal":
			return "region.locked_ruin_gate"
		_:
			return ""
