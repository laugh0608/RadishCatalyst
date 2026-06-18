extends Node2D
class_name CurrentObjectiveGuidanceLayer

const TARGET_PATH := "Interactables/OutpostCore"
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
const OFF_TARGET_LABEL_TEXT := "不是当前目标\n先去前哨核心"

var target_halo: ColorRect
var target_pin: ColorRect
var route_horizontal: ColorRect
var route_vertical: ColorRect
var target_label: Label
var off_target_label: Label


func _ready() -> void:
	z_index = 80
	_ensure_visual_nodes()
	refresh_guidance()


func _process(_delta: float) -> void:
	refresh_guidance()


func refresh_guidance() -> void:
	_ensure_visual_nodes()
	var target := _get_target()
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


func _ensure_visual_nodes() -> void:
	if target_halo != null:
		return
	target_halo = _create_color_rect(TARGET_GUIDANCE_NAME, TARGET_COLOR)
	target_pin = _create_color_rect(TARGET_PIN_NAME, TARGET_PIN_COLOR)
	route_horizontal = _create_color_rect(ROUTE_HORIZONTAL_NAME, ROUTE_COLOR)
	route_vertical = _create_color_rect(ROUTE_VERTICAL_NAME, ROUTE_COLOR)
	target_label = _create_label(TARGET_LABEL_NAME, "当前目标：前哨核心")
	off_target_label = _create_label(OFF_TARGET_LABEL_NAME, OFF_TARGET_LABEL_TEXT)


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
	_set_rect(target_halo, target.position + Vector2(-46.0, -46.0), Vector2(92.0, 92.0))
	_set_rect(target_pin, target.position + Vector2(-6.0, -72.0), Vector2(12.0, 32.0))
	_set_label_rect(target_label, target.position + Vector2(-92.0, -112.0), Vector2(184.0, 26.0))


func _position_route_visuals(target: PrototypeInteractable) -> void:
	var player := _get_player()
	if player == null:
		route_horizontal.visible = false
		route_vertical.visible = false
		return
	var start := player.position
	var end := target.position
	var corner := Vector2(end.x, start.y)
	_set_rect_between(route_horizontal, start, corner, 8.0)
	_set_rect_between(route_vertical, corner, end, 8.0)


func _refresh_off_target_hint(target: PrototypeInteractable) -> void:
	var focused := _get_focused_non_target_interactable(target)
	if focused == null:
		off_target_label.visible = false
		return
	_set_label_rect(off_target_label, focused.position + Vector2(-92.0, -82.0), Vector2(184.0, 42.0))
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


func _get_target() -> PrototypeInteractable:
	return _get_map_node(TARGET_PATH) as PrototypeInteractable


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
	if target.interaction_type != "outpost_core":
		return false
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
