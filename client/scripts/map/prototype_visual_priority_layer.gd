extends Node2D
class_name PrototypeVisualPriorityLayer

const GENERATED_CUE_PREFIX := "PrototypeVisualPriority"

var applied_region_count := 0


func _ready() -> void:
	apply_profile()


func apply_profile() -> void:
	_clear_generated_cues()
	applied_region_count = 0
	for region_id in PrototypeVisualPriorityProfile.get_region_ids():
		var profile := PrototypeVisualPriorityProfile.get_region_profile(region_id)
		if profile.is_empty():
			continue
		_apply_region_profile(region_id, profile)
		applied_region_count += 1


func get_generated_cue_count() -> int:
	var count := 0
	for child in get_children():
		if String(child.name).begins_with(GENERATED_CUE_PREFIX):
			count += 1
	return count


func _apply_region_profile(region_id: String, profile: Dictionary) -> void:
	_style_existing_color_rect(
		String(profile.get("background_path", "")),
		profile.get("background_color", Color.WHITE),
		region_id,
		"background"
	)
	_tag_existing_node(String(profile.get("key_object_path", "")), region_id, PrototypeVisualPriorityProfile.ROLE_KEY_OBJECT)
	_tag_existing_node(
		String(profile.get("hazard_or_facility_path", "")),
		region_id,
		PrototypeVisualPriorityProfile.ROLE_HAZARD_OR_FACILITY
	)
	_create_priority_cue(
		region_id,
		PrototypeVisualPriorityProfile.ROLE_MAIN_ROUTE,
		profile.get("main_route_rect", Rect2()),
		profile.get("main_route_color", Color.WHITE)
	)
	_create_priority_cue(
		region_id,
		PrototypeVisualPriorityProfile.ROLE_KEY_OBJECT,
		profile.get("key_object_rect", Rect2()),
		profile.get("key_object_color", Color.WHITE)
	)
	_create_priority_cue(
		region_id,
		PrototypeVisualPriorityProfile.ROLE_HAZARD_OR_FACILITY,
		profile.get("hazard_or_facility_rect", Rect2()),
		profile.get("hazard_or_facility_color", Color.WHITE)
	)


func _style_existing_color_rect(path: String, color: Color, region_id: String, role: String) -> void:
	var node := _get_map_node(path)
	if node == null:
		return
	node.set_meta("visual_priority_region_id", region_id)
	node.set_meta("visual_priority_role", role)
	if node is ColorRect:
		(node as ColorRect).color = color


func _tag_existing_node(path: String, region_id: String, role: String) -> void:
	var node := _get_map_node(path)
	if node == null:
		return
	node.set_meta("visual_priority_region_id", region_id)
	node.set_meta("visual_priority_role", role)


func _create_priority_cue(region_id: String, role: String, rect: Rect2, color: Color) -> void:
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var cue := ColorRect.new()
	cue.name = "%s%s" % [GENERATED_CUE_PREFIX, PrototypeVisualPriorityProfile.make_cue_name(region_id, role)]
	cue.offset_left = rect.position.x
	cue.offset_top = rect.position.y
	cue.offset_right = rect.position.x + rect.size.x
	cue.offset_bottom = rect.position.y + rect.size.y
	cue.color = color
	cue.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cue.set_meta("visual_priority_region_id", region_id)
	cue.set_meta("visual_priority_role", role)
	add_child(cue)


func _get_map_node(path: String) -> Node:
	if path.is_empty() or get_parent() == null:
		return null
	return get_parent().get_node_or_null(path)


func _clear_generated_cues() -> void:
	for child in get_children():
		if not String(child.name).begins_with(GENERATED_CUE_PREFIX):
			continue
		remove_child(child)
		child.free()
