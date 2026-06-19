extends RefCounted
class_name DemoRouteReturnAndBaseReentryFormatter

const OUTPOST_REGION_ID := "region.outpost_platform"
const POLLUTED_RESIDUE_ID := "item.polluted_residue"
const POLLUTED_SLURRY_ID := "fluid.polluted_slurry"
const SIGNAL_ECHO_TRACE_ID := "item.signal_echo_trace"
const DEEP_RUIN_COORDINATES_ID := "item.deep_ruin_coordinates"
const BASIC_REACTOR_ID := "building.basic_reactor"
const POLLUTION_FILTER_ID := "building.pollution_filter"
const OUTFITTING_STATION_ID := "building.field_outfitting_station"
const OUTPOST_CORE_ID := "building.outpost_core"
const DEPARTURE_GATE_ID := "map_object.outpost_departure_gate"
const PHASE_RELAY_PAD_ID := "map_object.phase_relay_pad"


static func format_hud_summary(world_state: WorldState, character_state: CharacterState) -> Array[String]:
	if not _is_base_region(world_state):
		return []
	var reentry_state := get_primary_reentry_state(world_state, character_state)
	if reentry_state.is_empty():
		return []
	return [
		"返回基地读法：%s -> %s" % [
			String(reentry_state.get("label", "")),
			String(reentry_state.get("device_label", ""))
		],
		"再进入路径：%s；%s" % [
			String(reentry_state.get("value", "")),
			String(reentry_state.get("next_entry_label", ""))
		]
	]


static func format_map_route_hint(
	world_state: WorldState,
	character_state: CharacterState = null
) -> String:
	if not _is_base_region(world_state):
		return ""
	var reentry_state := get_primary_reentry_state(world_state, character_state)
	if reentry_state.is_empty():
		return ""
	return "基地回收：%s" % String(reentry_state.get("map_hint", ""))


static func format_device_status_line(
	device_id: String,
	recipe_id: String,
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if not _is_base_region(world_state):
		return ""
	var reentry_state := get_primary_reentry_state(world_state, character_state)
	if reentry_state.is_empty():
		return ""
	if device_id == String(reentry_state.get("device_id", "")):
		return "返回基地读法：%s" % String(reentry_state.get("device_line", ""))
	if _is_related_recipe(recipe_id, reentry_state):
		return "返回基地读法：%s" % String(reentry_state.get("device_line", ""))
	if device_id == OUTPOST_CORE_ID:
		return format_outpost_core_reentry_line(world_state, character_state)
	return ""


static func format_outpost_core_reentry_line(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if not _is_base_region(world_state):
		return ""
	var reentry_state := get_primary_reentry_state(world_state, character_state)
	if reentry_state.is_empty():
		return ""
	return "返回基地读法：先在前哨核心确认补给，再从%s继续。" % String(reentry_state.get("next_entry_name", "外勤出发口"))


static func format_departure_reentry_line(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if not _is_base_region(world_state):
		return ""
	var reentry_state := get_primary_reentry_state(world_state, character_state)
	if reentry_state.is_empty():
		return ""
	if String(reentry_state.get("next_entry_id", "")) != DEPARTURE_GATE_ID:
		return ""
	return "返回基地读法：%s" % String(reentry_state.get("departure_line", ""))


static func format_phase_relay_reentry_line(
	world_state: WorldState,
	character_state: CharacterState
) -> String:
	if not _is_base_region(world_state):
		return ""
	var reentry_state := get_primary_reentry_state(world_state, character_state)
	if reentry_state.is_empty():
		return ""
	if String(reentry_state.get("next_entry_id", "")) != PHASE_RELAY_PAD_ID:
		return ""
	return "返回基地读法：%s" % String(reentry_state.get("departure_line", ""))


static func format_result_feedback_line(recipe_id: String, world_state: WorldState = null) -> String:
	if not _should_show_result_feedback(world_state):
		return ""
	match recipe_id:
		"recipe.cleanse_residue":
			return "返回基地读法：沉积物已转成药剂和浆液，下一步外勤出发口；先前哨核心补给。"
		"recipe.reclaim_basic_parts":
			return "返回基地读法：污染浆液已回收成基础零件；补齐整备后从外勤出发口继续。"
		"recipe.deep_signal_analysis":
			return _format_deep_signal_result_line(world_state)
		"recipe.phase_splinter_refining":
			return "返回基地读法：裂相碎屑已筛成透镜胚片；下一步在基础反应器调准中继镜，再回投前线。"
		_:
			return ""


static func get_recommended_recipe_id_for_device(
	device_id: String,
	character_state: CharacterState,
	world_state: WorldState
) -> String:
	if not _is_base_region(world_state) or character_state == null:
		return ""
	if device_id == POLLUTION_FILTER_ID:
		if character_state.inventory.has_ref(POLLUTED_RESIDUE_ID, 2):
			return "recipe.cleanse_residue"
		return ""
	if device_id != BASIC_REACTOR_ID:
		return ""
	if character_state.inventory.has_ref(SIGNAL_ECHO_TRACE_ID, 1):
		return "recipe.deep_signal_analysis"
	if character_state.inventory.has_ref(POLLUTED_SLURRY_ID, 1):
		return "recipe.reclaim_basic_parts"
	return ""


static func get_primary_reentry_state(
	world_state: WorldState,
	character_state: CharacterState
) -> Dictionary:
	if not _is_base_region(world_state):
		return {}
	if character_state != null:
		if character_state.inventory.has_ref(POLLUTED_RESIDUE_ID, 2):
			return _polluted_residue_state()
		if character_state.inventory.has_ref(SIGNAL_ECHO_TRACE_ID, 1):
			return _signal_echo_state(world_state)
		if character_state.inventory.has_ref(DEEP_RUIN_COORDINATES_ID, 1):
			return _deep_coordinates_state(world_state)
		if DemoFieldLoopPayoffFormatter.can_confirm_payoff(world_state, character_state):
			return _field_payoff_state(world_state)
		if character_state.inventory.has_ref(POLLUTED_SLURRY_ID, 1):
			return _polluted_slurry_state()
	if _has_relay_return_entry(world_state):
		return _phase_relay_state()
	return {}


static func _polluted_residue_state() -> Dictionary:
	return {
		"label": "污染沉积物已带回",
		"device_id": POLLUTION_FILTER_ID,
		"device_label": "污染过滤器",
		"recipe_id": "recipe.cleanse_residue",
		"value": "处理成抗污染药剂和污染浆液",
		"next_entry_id": DEPARTURE_GATE_ID,
		"next_entry_name": "外勤出发口",
		"next_entry_label": "前哨核心补给后，从外勤出发口再进入污染 / 遗迹路线",
		"map_hint": "沉积物先到污染过滤器处理，补给后从外勤出发口再进入",
		"device_line": "外勤带回污染沉积物；本设备处理成药剂和浆液，之后回前哨核心补给再出发。",
		"departure_line": "污染处理完成后确认药剂和防护，再从这里返回污染 / 遗迹路线。"
	}


static func _polluted_slurry_state() -> Dictionary:
	return {
		"label": "污染浆液待分流",
		"device_id": BASIC_REACTOR_ID,
		"device_label": "基础反应器",
		"recipe_id": "recipe.reclaim_basic_parts",
		"value": "回收成基础零件或保留给后续组装",
		"next_entry_id": DEPARTURE_GATE_ID,
		"next_entry_name": "外勤出发口",
		"next_entry_label": "确认补给后，从外勤出发口继续下一段外勤",
		"map_hint": "浆液回基础反应器分流，补给后从外勤出发口继续",
		"device_line": "污染浆液已经回到基地；本设备可回收基础零件，或保留给遗迹 / 核心组装。",
		"departure_line": "副产分流完成后确认补给，再从这里继续外勤路线。"
	}


static func _signal_echo_state(world_state: WorldState) -> Dictionary:
	var next_entry_id := _get_deep_route_entry_id(world_state)
	var next_entry_name := _get_entry_name(next_entry_id)
	return {
		"label": "回波痕迹已带回",
		"device_id": BASIC_REACTOR_ID,
		"device_label": "基础反应器",
		"recipe_id": "recipe.deep_signal_analysis",
		"value": "解析成裂相坐标并打开下一段路线读法",
		"next_entry_id": next_entry_id,
		"next_entry_name": next_entry_name,
		"next_entry_label": "解析后补给，再从%s进入裂相路线" % next_entry_name,
		"map_hint": "回波痕迹先到基础反应器解析，再从%s进入裂相路线" % next_entry_name,
		"device_line": "回波痕迹已经回到基地；本设备解析裂相坐标，完成后补给并进入下一段路线。",
		"departure_line": "裂相坐标解析后确认补给，再从这里进入裂相路线。"
	}


static func _deep_coordinates_state(world_state: WorldState) -> Dictionary:
	var next_entry_id := _get_deep_route_entry_id(world_state)
	var next_entry_name := _get_entry_name(next_entry_id)
	return {
		"label": "裂相坐标已解析",
		"device_id": OUTPOST_CORE_ID,
		"device_label": "前哨核心",
		"recipe_id": "",
		"value": "补给后进入裂相路线",
		"next_entry_id": next_entry_id,
		"next_entry_name": next_entry_name,
		"next_entry_label": "从%s再进入裂相路线" % next_entry_name,
		"map_hint": "裂相坐标已就绪，前哨核心补给后从%s再进入" % next_entry_name,
		"device_line": "裂相坐标已经完成解析；先补给，再从%s进入下一段。" % next_entry_name,
		"departure_line": "裂相坐标已就绪，确认补给后从这里进入下一段。"
	}


static func _field_payoff_state(world_state: WorldState) -> Dictionary:
	var next_entry_id := _get_deep_route_entry_id(world_state)
	var next_entry_name := _get_entry_name(next_entry_id)
	return {
		"label": "外勤收益待确认",
		"device_id": OUTFITTING_STATION_ID,
		"device_label": "出发整备台",
		"recipe_id": "",
		"value": "确认回波解析收益并降低下一趟承压",
		"next_entry_id": next_entry_id,
		"next_entry_name": next_entry_name,
		"next_entry_label": "确认收益后，从%s继续下一趟" % next_entry_name,
		"map_hint": "出发整备台确认收益，再从%s继续下一趟" % next_entry_name,
		"device_line": "外勤收益已经回基地；本设备确认收益整备，完成后回到出发入口。",
		"departure_line": "外勤收益确认后再出发，下一趟承压会降低。"
	}


static func _phase_relay_state() -> Dictionary:
	return {
		"label": "前线锚点已部署",
		"device_id": PHASE_RELAY_PAD_ID,
		"device_label": "相位回投台",
		"recipe_id": "",
		"value": "从基地重返已部署前线锚点",
		"next_entry_id": PHASE_RELAY_PAD_ID,
		"next_entry_name": "相位回投台",
		"next_entry_label": "从相位回投台再进入深段路线",
		"map_hint": "前线锚点已部署，补给后从相位回投台回到深段",
		"device_line": "已部署前线锚点；补给后从相位回投台直接返回深段。",
		"departure_line": "已部署前线锚点，确认补给后从这里回到深段路线。"
	}


static func _is_base_region(world_state: WorldState) -> bool:
	return world_state != null and world_state.current_region_id == OUTPOST_REGION_ID


static func _is_related_recipe(recipe_id: String, reentry_state: Dictionary) -> bool:
	var state_recipe_id := String(reentry_state.get("recipe_id", ""))
	return not state_recipe_id.is_empty() and recipe_id == state_recipe_id


static func _get_deep_route_entry_id(world_state: WorldState) -> String:
	if _has_relay_return_entry(world_state):
		return PHASE_RELAY_PAD_ID
	return DEPARTURE_GATE_ID


static func _get_entry_name(entry_id: String) -> String:
	if entry_id == PHASE_RELAY_PAD_ID:
		return "相位回投台"
	return "外勤出发口"


static func _has_relay_return_entry(world_state: WorldState) -> bool:
	if world_state == null:
		return false
	return world_state.has_active_phase_relay_anchor() or world_state.get_deployed_phase_relay_anchor_count() > 0


static func _should_show_result_feedback(world_state: WorldState) -> bool:
	if world_state == null:
		return true
	if world_state.current_region_id != OUTPOST_REGION_ID:
		return false
	return world_state.quest_state.active_quest_ids.is_empty()


static func _format_deep_signal_result_line(world_state: WorldState) -> String:
	var entry_name := _get_entry_name(_get_deep_route_entry_id(world_state))
	return "返回基地读法：回波痕迹已解析成裂相坐标；前哨核心补给后，从%s进入裂相路线。" % entry_name
