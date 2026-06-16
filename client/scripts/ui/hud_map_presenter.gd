extends RefCounted
class_name HudMapPresenter

const MAP_MARKER_CURRENT_COLOR := Color(0.18, 0.86, 0.93, 1.0)
const MAP_MARKER_TARGET_COLOR := Color(1.0, 0.78, 0.28, 1.0)
const MAP_MARKER_UNLOCKED_COLOR := Color(0.55, 0.72, 0.66, 1.0)
const MAP_MARKER_LOCKED_COLOR := Color(0.28, 0.32, 0.32, 1.0)
const ROUTE_STAGE_BY_REGION := {
	"region.outpost_platform": "基地整备",
	"region.crystal_vein_field": "晶体采集",
	"region.pollution_edge": "污染排压",
	"region.ruin_outer_ring": "遗迹外圈",
	"region.deep_ruin_threshold": "深段推进",
	"region.inner_phase_well": "深段推进",
	"region.phase_well_sink": "深段推进",
	"region.phase_well_chamber": "深段推进",
	"region.phase_well_loom": "深段推进",
	"region.phase_well_frame": "深段推进",
	"region.phase_well_tether": "深段推进",
	"region.demo_stabilization_core": "核心稳定站"
}
const ROUTE_PURPOSE_BY_STAGE := {
	"基地整备": "加工/补给/确认出发",
	"晶体采集": "矿物和残骸带回基地",
	"污染排压": "沉积物过滤成药剂",
	"遗迹外圈": "回波和沉积物回基地解析",
	"深段推进": "解析/回投/锚定桥推进",
	"核心稳定站": "补给/守卫/写入反馈",
	"外勤推进": "按当前目标推进"
}

var target_region_resolver: QuestTargetRegionResolver


func configure(data_registry: DataRegistry, map: VerticalSliceMap) -> void:
	if data_registry == null:
		target_region_resolver = null
		return
	target_region_resolver = QuestTargetRegionResolver.new(data_registry)
	target_region_resolver.configure_from_map(map)


func get_marker_view_data(world_state: WorldState, quest_id: String) -> Array[Dictionary]:
	var target_region_id := _get_quest_target_region_id(world_state, quest_id)
	var view_data: Array[Dictionary] = []
	for marker in _get_region_marker_data():
		var region_id := String(marker.get("region_id", ""))
		view_data.append({
			"label": _format_map_marker_label(marker, world_state, target_region_id, quest_id),
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
			var route_risk_note := BaseActionDispatchPlan.get_route_risk_note(world_state)
			if not route_risk_note.is_empty() and quest_id.is_empty():
				marker_parts.append("测绘预告")
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


func format_demo_route_title(world_state: WorldState, _quest_id: String) -> String:
	return "外勤路线：%s" % _get_route_stage_label(world_state.current_region_id)


func format_demo_route_hint(world_state: WorldState, quest_id: String) -> String:
	var demo_completion_hint := DemoMainlineCompletionFormatter.format_map_route_hint(world_state)
	if not demo_completion_hint.is_empty():
		return demo_completion_hint
	var current_stage := _get_route_stage_label(world_state.current_region_id)
	var target_region_id := _get_quest_target_region_id(world_state, quest_id)
	var target_stage := _get_route_stage_label(target_region_id)
	var hint_region_id := world_state.current_region_id
	var route_hint := _get_route_stage_purpose(current_stage)
	if not target_region_id.is_empty() and target_stage != current_stage:
		hint_region_id = target_region_id
		route_hint = "目标：%s · %s" % [target_stage, _get_route_stage_purpose(target_stage)]
	var scene_hint := SceneArtFoundationFormatter.format_map_route_hint(hint_region_id)
	if not scene_hint.is_empty():
		return "%s · %s" % [route_hint, scene_hint]
	var non_core_scene_hint := NonCoreSceneIdentityFormatter.format_map_route_hint(hint_region_id)
	var transition_hint := FunctionalTransitionRouteSupportFormatter.format_map_route_hint(hint_region_id)
	if not non_core_scene_hint.is_empty() and not transition_hint.is_empty():
		return "%s · %s · %s" % [route_hint, non_core_scene_hint, transition_hint]
	if not non_core_scene_hint.is_empty():
		return "%s · %s" % [route_hint, non_core_scene_hint]
	if not transition_hint.is_empty():
		return "%s · %s" % [route_hint, transition_hint]
	return route_hint


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
			"region_id": "region.ruin_outer_ring",
			"label": "封锁",
			"direction": "更东"
		},
		{
			"region_id": "region.deep_ruin_threshold",
			"label": "裂相",
			"direction": "更深"
		},
		{
			"region_id": "region.inner_phase_well",
			"label": "回声",
			"direction": "更东"
		},
		{
			"region_id": "region.phase_well_sink",
			"label": "盐壳",
			"direction": "更深"
		},
		{
			"region_id": "region.phase_well_chamber",
			"label": "碎晶",
			"direction": "更东"
		},
		{
			"region_id": "region.phase_well_loom",
			"label": "风蚀",
			"direction": "更东"
		},
		{
			"region_id": "region.phase_well_frame",
			"label": "锁相",
			"direction": "更东"
		},
		{
			"region_id": "region.phase_well_tether",
			"label": "锚定",
			"direction": "更东"
		},
		{
			"region_id": "region.demo_stabilization_core",
			"label": "核心",
			"direction": "更东"
		}
	]


func _format_map_marker_label(marker: Dictionary, world_state: WorldState, target_region_id: String, quest_id: String) -> String:
	var region_id := String(marker.get("region_id", ""))
	var rows: Array[String] = [String(marker.get("label", region_id))]
	if world_state.current_region_id == region_id:
		rows.append("当前")
	if target_region_id == region_id:
		rows.append("目标")
		if quest_id.is_empty() and not BaseActionDispatchPlan.get_route_risk_note(world_state).is_empty():
			rows.append("测绘预告")
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


func _get_route_stage_label(region_id: String) -> String:
	if ROUTE_STAGE_BY_REGION.has(region_id):
		return String(ROUTE_STAGE_BY_REGION[region_id])
	return "外勤推进"


func _get_route_stage_purpose(stage_label: String) -> String:
	if ROUTE_PURPOSE_BY_STAGE.has(stage_label):
		return String(ROUTE_PURPOSE_BY_STAGE[stage_label])
	return String(ROUTE_PURPOSE_BY_STAGE["外勤推进"])


func _get_quest_target_region_id(world_state: WorldState, quest_id: String) -> String:
	if quest_id.is_empty():
		return _get_runtime_followup_region_id(world_state)
	if target_region_resolver == null:
		return ""
	return target_region_resolver.resolve_target_region_id(world_state, quest_id)


func _get_runtime_followup_region_id(world_state: WorldState) -> String:
	if BaseActionDispatchPlan.is_frontline_window_active(world_state):
		return "region.phase_well_tether"
	if not BaseActionDispatchPlan.get_frontline_window_feedback(world_state).is_empty():
		if world_state.current_region_id != "region.outpost_platform":
			return "region.outpost_platform"
		return ""
	var dispatch_route_region_id := BaseActionDispatchPlan.get_route_target_region_id(world_state)
	if not dispatch_route_region_id.is_empty():
		return dispatch_route_region_id
	var next_sortie_target_region_id := CoreGuardAftermathFormatter.get_next_sortie_target_region_id(world_state)
	if not next_sortie_target_region_id.is_empty():
		return next_sortie_target_region_id
	if world_state.quest_state.has_completed_quest("quest.write_demo_stabilization_core"):
		return ""
	if _has_completed_frontline_window_review(world_state):
		return "region.demo_stabilization_core"
	if world_state.quest_state.has_completed_quest("quest.calibrate_phase_well_stability_window"):
		return ""
	if world_state.quest_state.has_completed_quest("quest.analyze_phase_well_echo_shard"):
		return "region.phase_well_tether"
	if world_state.quest_state.has_completed_quest("quest.stabilize_phase_well_anchor_field"):
		return ""
	if world_state.quest_state.has_completed_quest("quest.inspect_phase_well_tether"):
		return "region.outpost_platform"
	if world_state.quest_state.has_completed_quest("quest.inspect_phase_well_frame"):
		return "region.outpost_platform"
	if world_state.quest_state.has_completed_quest("quest.inspect_phase_well_loom"):
		return "region.outpost_platform"
	if world_state.quest_state.has_completed_quest("quest.inspect_phase_well_chamber"):
		return "region.outpost_platform"
	if world_state.quest_state.has_completed_quest("quest.inspect_phase_well_sink"):
		return "region.outpost_platform"
	if world_state.quest_state.has_completed_quest("quest.inspect_inner_phase_well"):
		return "region.outpost_platform"
	if world_state.quest_state.has_completed_quest("quest.unlock_phase_well"):
		return "region.outpost_platform"
	if (
		world_state.current_region_id == "region.outpost_platform"
		and world_state.quest_state.has_completed_quest("quest.deploy_phase_relay_anchor")
	):
		return "region.deep_ruin_threshold"
	return ""


func _has_completed_frontline_window_review(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	var review_count = world_state.get_base_action_state_value(BaseActionDispatchPlan.FRONTLINE_WINDOW_REVIEW_COUNT_KEY, null)
	if review_count != null:
		return int(review_count) > BaseActionDispatchPlan.FRONTLINE_WINDOW_REVIEW_LIMIT
	var archived_feedback := String(world_state.get_base_action_state_value(BaseActionDispatchPlan.FRONTLINE_WINDOW_ARCHIVED_FEEDBACK_KEY, ""))
	return not archived_feedback.is_empty()
