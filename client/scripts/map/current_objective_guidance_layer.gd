extends Node2D
class_name CurrentObjectiveGuidanceLayer

const INTERACTABLES_PATH := "Interactables"
const PLAYER_PATH := "Player"
const TARGET_GUIDANCE_NAME := "CurrentObjectiveTargetHalo"
const TARGET_PIN_NAME := "CurrentObjectiveTargetPin"
const ROUTE_HORIZONTAL_NAME := "CurrentObjectiveRouteHorizontal"
const ROUTE_VERTICAL_NAME := "CurrentObjectiveRouteVertical"
const TARGET_LABEL_NAME := "CurrentObjectiveTargetLabel"
const OFF_TARGET_LABEL_NAME := "CurrentObjectiveOffTargetLabel"
const TARGET_COLOR := Color(0.28, 0.96, 1.0, 0.38)
const TARGET_PIN_COLOR := Color(0.82, 1.0, 0.95, 0.82)
const ROUTE_COLOR := Color(0.38, 0.94, 0.96, 0.34)
const GUIDANCE_LABEL_FONT_SIZE := 10
const OUTPOST_CORE_TARGET := {"path": "Interactables/OutpostCore", "label": "前哨核心"}
const BASIC_STORAGE_TARGET := {"path": "Interactables/BasicStorageBuildSite", "label": "基础储存箱"}
const BASIC_REACTOR_TARGET := {"path": "Interactables/BasicReactor", "label": "基础反应器"}
const OUTPOST_GATE_TARGET := {"path": "Interactables/OutpostDepartureGate", "label": "外勤出发口"}
const CRYSTAL_CLUSTER_TARGET := {"path": "Interactables/CrystalCluster", "label": "晶体采集点"}
const FIELD_WRECKAGE_TARGET := {"path": "Interactables/FieldWreckageNorth", "label": "导电废件"}
const ANOMALY_CRYSTAL_TARGET := {"path": "Interactables/AnomalyCrystal", "label": "异常晶体"}
const ANOMALY_RESIDUE_TARGET := {"path": "Interactables/AnomalyResidueNorth", "label": "异常残留物"}
const ROUGH_GROUND_NORTH_TARGET := {"path": "Interactables/RoughGroundNorth", "label": "粗糙地块"}
const ROUGH_GROUND_SOUTH_TARGET := {"path": "Interactables/RoughGroundSouth", "label": "粗糙地块"}
const FOUNDATION_NORTH_TARGET := {"path": "Interactables/FoundationSiteNorth", "label": "基础地基"}
const FOUNDATION_SOUTH_TARGET := {"path": "Interactables/FoundationSiteSouth", "label": "基础地基"}
const POLLUTION_FILTER_BUILD_TARGET := {"path": "Interactables/PollutionFilterBuildSite", "label": "污染过滤器建造点"}
const POLLUTION_RESIDUE_TARGET := {"path": "Interactables/PollutionResidue", "label": "污染沉积物"}
const POLLUTION_FILTER_TARGET := {"path": "Interactables/PollutionFilter", "label": "污染过滤器"}
const NO_TARGET := {"path": "", "label": ""}

var target_halo: ColorRect
var target_pin: ColorRect
var route_horizontal: ColorRect
var route_vertical: ColorRect
var target_label: Label
var off_target_label: Label
var current_world_state: WorldState
var current_character_state: CharacterState
var current_target: PrototypeInteractable
var current_target_label_text := "前哨核心"


func _ready() -> void:
	z_index = 80
	_ensure_visual_nodes()
	refresh_guidance()


func _process(_delta: float) -> void:
	refresh_guidance()


func refresh_guidance(world_state: WorldState = null, character_state: CharacterState = null) -> void:
	if world_state != null:
		current_world_state = world_state
	if character_state != null:
		current_character_state = character_state
	_ensure_visual_nodes()
	var target_info := _resolve_current_target()
	current_target_label_text = String(target_info.get("label", ""))
	var target := _get_target_from_info(target_info)
	current_target = target
	var active := _is_target_active(target)
	_set_target_visuals_visible(active)
	if not active:
		return

	_position_target_visuals(target)
	_position_route_visuals(target)
	_refresh_off_target_hint(target)


func is_target_guidance_visible() -> bool:
	_ensure_visual_nodes()
	return target_halo != null and target_halo.visible


func is_off_target_hint_visible() -> bool:
	_ensure_visual_nodes()
	return off_target_label != null and off_target_label.visible


func get_current_target_node() -> PrototypeInteractable:
	return current_target


func get_current_target_label_text() -> String:
	return current_target_label_text


func _ensure_visual_nodes() -> void:
	if target_halo != null:
		return
	target_halo = _create_color_rect(TARGET_GUIDANCE_NAME, TARGET_COLOR)
	target_pin = _create_color_rect(TARGET_PIN_NAME, TARGET_PIN_COLOR)
	route_horizontal = _create_color_rect(ROUTE_HORIZONTAL_NAME, ROUTE_COLOR)
	route_vertical = _create_color_rect(ROUTE_VERTICAL_NAME, ROUTE_COLOR)
	target_label = _create_label(TARGET_LABEL_NAME, "目标：前哨核心")
	off_target_label = _create_label(OFF_TARGET_LABEL_NAME, "")


func _create_color_rect(node_name: String, color: Color) -> ColorRect:
	var rect := ColorRect.new()
	rect.name = node_name
	rect.color = color
	rect.visible = false
	add_child(rect)
	return rect


func _create_label(node_name: String, text: String) -> Label:
	var label := Label.new()
	label.name = node_name
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", GUIDANCE_LABEL_FONT_SIZE)
	label.add_theme_color_override("font_color", Color(0.88, 0.96, 0.94, 0.86))
	label.add_theme_color_override("font_shadow_color", Color(0.02, 0.04, 0.045, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.visible = false
	add_child(label)
	return label


func _set_target_visuals_visible(visible: bool) -> void:
	for node in [target_halo, target_pin, route_horizontal, route_vertical, target_label]:
		if node != null:
			node.visible = visible
	if off_target_label != null and not visible:
		off_target_label.visible = false


func _position_target_visuals(target: PrototypeInteractable) -> void:
	_set_rect(target_halo, target.position + Vector2(-34.0, -34.0), Vector2(68.0, 68.0))
	_set_rect(target_pin, target.position + Vector2(-4.0, -48.0), Vector2(8.0, 20.0))
	target_label.text = "目标：%s" % current_target_label_text
	_set_label_rect(target_label, target.position + Vector2(-58.0, -70.0), Vector2(116.0, 18.0))


func _position_route_visuals(target: PrototypeInteractable) -> void:
	var player := _get_player()
	if player == null:
		route_horizontal.visible = false
		route_vertical.visible = false
		return
	var start := player.position
	var end := target.position
	var corner := Vector2(end.x, start.y)
	_set_rect_between(route_horizontal, start, corner, 6.0)
	_set_rect_between(route_vertical, corner, end, 6.0)


func _refresh_off_target_hint(target: PrototypeInteractable) -> void:
	var focused := _get_focused_non_target_interactable(target)
	if focused == null:
		off_target_label.visible = false
		return
	off_target_label.text = "→ %s" % current_target_label_text
	_set_label_rect(off_target_label, focused.position + Vector2(-46.0, -48.0), Vector2(92.0, 18.0))
	off_target_label.visible = true


func _set_rect(rect: ColorRect, top_left: Vector2, size: Vector2) -> void:
	if rect == null:
		return
	rect.offset_left = top_left.x
	rect.offset_top = top_left.y
	rect.offset_right = top_left.x + size.x
	rect.offset_bottom = top_left.y + size.y


func _set_rect_between(rect: ColorRect, start: Vector2, end: Vector2, thickness: float) -> void:
	if rect == null:
		return
	var left := minf(start.x, end.x) - thickness * 0.5
	var top := minf(start.y, end.y) - thickness * 0.5
	var width := absf(start.x - end.x) + thickness
	var height := absf(start.y - end.y) + thickness
	_set_rect(rect, Vector2(left, top), Vector2(width, height))
	rect.visible = width > thickness or height > thickness


func _set_label_rect(label: Label, top_left: Vector2, size: Vector2) -> void:
	if label == null:
		return
	label.offset_left = top_left.x
	label.offset_top = top_left.y
	label.offset_right = top_left.x + size.x
	label.offset_bottom = top_left.y + size.y


func _resolve_current_target() -> Dictionary:
	var world_state := current_world_state
	if world_state == null:
		return OUTPOST_CORE_TARGET
	if _has_active_quest(world_state, "quest.restore_outpost"):
		return OUTPOST_CORE_TARGET
	if _should_guide_basic_storage(world_state):
		return BASIC_STORAGE_TARGET

	match _get_active_quest_id(world_state):
		"quest.scout_crystal_field":
			return _resolve_scout_crystal_target(world_state)
		"quest.calibrate_reactor":
			return _resolve_calibrate_reactor_target(world_state)
		"quest.bring_back_sample":
			return ANOMALY_CRYSTAL_TARGET
		"quest.analyze_anomaly_sample":
			return _resolve_anomaly_analysis_target(world_state)
		"quest.make_filter_module":
			return BASIC_REACTOR_TARGET
		"quest.prepare_treatment_supplies":
			return _resolve_treatment_supply_target(world_state)
		"quest.expand_treatment_point":
			return _resolve_treatment_point_target(world_state)
		"quest.enter_pollution_edge":
			return _resolve_pollution_edge_target(world_state)

	if not _has_completed_quest(world_state, "quest.restore_outpost"):
		return OUTPOST_CORE_TARGET
	return NO_TARGET


func _resolve_scout_crystal_target(world_state: WorldState) -> Dictionary:
	if _quest_progress(world_state, "quest.scout_crystal_field", "visit_region", "region.crystal_vein_field") < 1.0:
		return OUTPOST_GATE_TARGET
	return CRYSTAL_CLUSTER_TARGET


func _resolve_calibrate_reactor_target(world_state: WorldState) -> Dictionary:
	if _quest_progress(world_state, "quest.calibrate_reactor", "gather_item", "item.salvage_scrap") < 4.0:
		return FIELD_WRECKAGE_TARGET
	return BASIC_REACTOR_TARGET


func _resolve_anomaly_analysis_target(world_state: WorldState) -> Dictionary:
	if _quest_progress(world_state, "quest.analyze_anomaly_sample", "gather_item", "item.anomaly_residue") < 2.0:
		return ANOMALY_RESIDUE_TARGET
	return BASIC_REACTOR_TARGET


func _resolve_treatment_supply_target(world_state: WorldState) -> Dictionary:
	if _quest_progress(world_state, "quest.prepare_treatment_supplies", "craft_item", "item.repair_gel") < 1.0:
		return BASIC_REACTOR_TARGET
	return OUTPOST_GATE_TARGET


func _resolve_treatment_point_target(world_state: WorldState) -> Dictionary:
	if _quest_progress(world_state, "quest.expand_treatment_point", "clear", "map_object.rough_ground") < 1.0:
		return ROUGH_GROUND_NORTH_TARGET
	if _quest_progress(world_state, "quest.expand_treatment_point", "clear", "map_object.rough_ground") < 2.0:
		return ROUGH_GROUND_SOUTH_TARGET
	var foundation_count := world_state.count_base_structures("building.foundation_t1")
	if foundation_count < 1:
		return FOUNDATION_NORTH_TARGET
	if foundation_count < 2:
		return FOUNDATION_SOUTH_TARGET
	if not world_state.has_base_structure_definition("building.pollution_filter"):
		return POLLUTION_FILTER_BUILD_TARGET
	return OUTPOST_GATE_TARGET


func _resolve_pollution_edge_target(world_state: WorldState) -> Dictionary:
	if _quest_progress(world_state, "quest.enter_pollution_edge", "visit_region", "region.pollution_edge") < 1.0:
		return OUTPOST_GATE_TARGET
	if _quest_progress(world_state, "quest.enter_pollution_edge", "gather_item", "item.polluted_residue") < 4.0:
		return POLLUTION_RESIDUE_TARGET
	if _quest_progress(world_state, "quest.enter_pollution_edge", "craft_item", "item.resistance_vial_t1") < 1.0:
		return POLLUTION_FILTER_TARGET
	return OUTPOST_GATE_TARGET


func _should_guide_basic_storage(world_state: WorldState) -> bool:
	if world_state.has_base_structure_definition("building.basic_storage"):
		return false
	if not _has_completed_quest(world_state, "quest.restore_outpost"):
		return false
	if not _has_active_quest(world_state, "quest.scout_crystal_field"):
		return false
	return (
		_quest_progress(world_state, "quest.scout_crystal_field", "visit_region", "region.crystal_vein_field") <= 0.0
		and _quest_progress(world_state, "quest.scout_crystal_field", "gather_item", "item.crystal_ore") <= 0.0
	)


func _get_target_from_info(target_info: Dictionary) -> PrototypeInteractable:
	var target_path := String(target_info.get("path", ""))
	if target_path.is_empty():
		return null
	return _get_map_node(target_path) as PrototypeInteractable


func _get_player() -> Node2D:
	return _get_map_node(PLAYER_PATH) as Node2D


func _get_focused_non_target_interactable(target: PrototypeInteractable) -> PrototypeInteractable:
	var interactables := _get_map_node(INTERACTABLES_PATH)
	if interactables == null:
		return null
	for child in interactables.get_children():
		if child == target or not child is PrototypeInteractable:
			continue
		var interactable := child as PrototypeInteractable
		if _is_interactable_focused(interactable):
			return interactable
	return null


func _is_target_active(target: PrototypeInteractable) -> bool:
	if target == null or not target.visible or not target.monitoring:
		return false
	if target.interaction_type == "outpost_core":
		var label := target.get_node_or_null("Label") as Label
		if label != null and label.text.find("已恢复") >= 0:
			return false
	return true


func _is_interactable_focused(interactable: PrototypeInteractable) -> bool:
	var focus_ring := interactable.get_node_or_null("FocusRing") as ColorRect
	return focus_ring != null and focus_ring.visible


func _get_map_node(path: String) -> Node:
	var map := get_parent()
	if map == null:
		return null
	return map.get_node_or_null(path)


func _get_active_quest_id(world_state: WorldState) -> String:
	if world_state == null or world_state.quest_state.active_quest_ids.is_empty():
		return ""
	return String(world_state.quest_state.active_quest_ids[0])


func _has_active_quest(world_state: WorldState, quest_id: String) -> bool:
	return world_state != null and world_state.quest_state.has_active_quest(quest_id)


func _has_completed_quest(world_state: WorldState, quest_id: String) -> bool:
	return world_state != null and world_state.quest_state.has_completed_quest(quest_id)


func _quest_progress(world_state: WorldState, quest_id: String, objective_type: String, target_id: String) -> float:
	if world_state == null:
		return 0.0
	return world_state.quest_state.get_objective_progress(quest_id, objective_type, target_id)
