extends Node2D
class_name DemoCoreSceneSpaceLayer

const GENERATED_FRAME_PREFIX := "DemoCoreSceneSpaceFrame"
const FRAME_THICKNESS := 4.0

var applied_region_count := 0


func _ready() -> void:
	apply_profile()


func apply_profile() -> void:
	_clear_generated_frames()
	applied_region_count = 0
	for region_id in DemoCoreSceneSpaceProfile.get_region_ids():
		var profile := DemoCoreSceneSpaceProfile.get_region_profile(region_id)
		if profile.is_empty():
			continue
		_apply_region_profile(region_id, profile)
		_create_region_frame(region_id, profile)
		applied_region_count += 1


func get_generated_frame_count() -> int:
	var count := 0
	for child in get_children():
		if String(child.name).begins_with(GENERATED_FRAME_PREFIX):
			count += 1
	return count


func has_role(region_id: String, role: String) -> bool:
	return get_tagged_node_count(region_id, role) > 0


func get_tagged_node_count(region_id: String, role: String = "") -> int:
	if get_parent() == null:
		return 0
	return _count_tagged_descendants(get_parent(), region_id, role)


func _apply_region_profile(region_id: String, profile: Dictionary) -> void:
	for role in DemoCoreSceneSpaceProfile.get_required_roles():
		var role_text := String(role)
		var tint := _get_role_tint(profile, role_text)
		for path in DemoCoreSceneSpaceProfile.get_node_paths_for_role(region_id, role_text):
			_tag_space_node(String(path), region_id, role_text, String(profile.get("material", "")), tint)


func _tag_space_node(path: String, region_id: String, role: String, material: String, tint: Color) -> void:
	var node := _get_map_node(path)
	if node == null:
		return
	node.set_meta("core_scene_region_id", region_id)
	node.set_meta("core_scene_material", material)
	var roles: Array = node.get_meta("core_scene_roles", [])
	if not roles.has(role):
		roles.append(role)
	node.set_meta("core_scene_roles", roles)
	node.set_meta("core_scene_primary_role", String(roles[0]))
	if node is ColorRect:
		_apply_tint(node as ColorRect, tint, _get_role_tint_strength(role))


func _apply_tint(rect: ColorRect, tint: Color, strength: float) -> void:
	if not rect.has_meta("core_scene_original_color"):
		rect.set_meta("core_scene_original_color", rect.color)
	var original: Color = rect.get_meta("core_scene_original_color", rect.color)
	rect.color = original.lerp(tint, strength)


func _create_region_frame(region_id: String, profile: Dictionary) -> void:
	var rect := _get_region_scene_rect(region_id)
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var frame_color: Color = profile.get("surface_frame_color", Color(1, 1, 1, 0.35))
	_create_frame_segment(region_id, "Top", Rect2(rect.position, Vector2(rect.size.x, FRAME_THICKNESS)), frame_color)
	_create_frame_segment(
		region_id,
		"Bottom",
		Rect2(Vector2(rect.position.x, rect.end.y - FRAME_THICKNESS), Vector2(rect.size.x, FRAME_THICKNESS)),
		frame_color
	)
	_create_frame_segment(region_id, "Left", Rect2(rect.position, Vector2(FRAME_THICKNESS, rect.size.y)), frame_color)
	_create_frame_segment(
		region_id,
		"Right",
		Rect2(Vector2(rect.end.x - FRAME_THICKNESS, rect.position.y), Vector2(FRAME_THICKNESS, rect.size.y)),
		frame_color
	)


func _create_frame_segment(region_id: String, suffix: String, rect: Rect2, color: Color) -> void:
	var frame := ColorRect.new()
	frame.name = "%s%s%s" % [GENERATED_FRAME_PREFIX, _make_region_name(region_id), suffix]
	frame.offset_left = rect.position.x
	frame.offset_top = rect.position.y
	frame.offset_right = rect.position.x + rect.size.x
	frame.offset_bottom = rect.position.y + rect.size.y
	frame.color = color
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_meta("core_scene_region_id", region_id)
	frame.set_meta("core_scene_roles", ["surface_frame"])
	frame.set_meta("core_scene_primary_role", "surface_frame")
	add_child(frame)


func _get_region_scene_rect(region_id: String) -> Rect2:
	var rect := Rect2()
	var has_rect := false
	for path in DemoCoreSceneSpaceProfile.get_node_paths_for_role(region_id, DemoCoreSceneSpaceProfile.ROLE_GROUND):
		var color_rect := _get_map_node(String(path)) as ColorRect
		if color_rect == null:
			continue
		var node_rect := color_rect.get_rect()
		if not has_rect:
			rect = node_rect
			has_rect = true
		else:
			rect = rect.merge(node_rect)
	if not has_rect:
		return Rect2()
	return rect


func _get_role_tint(profile: Dictionary, role: String) -> Color:
	var role_tints: Dictionary = profile.get("role_tints", {})
	return role_tints.get(role, Color.WHITE)


func _get_role_tint_strength(role: String) -> float:
	match role:
		DemoCoreSceneSpaceProfile.ROLE_GROUND:
			return 0.22
		DemoCoreSceneSpaceProfile.ROLE_ROUTE:
			return 0.42
		DemoCoreSceneSpaceProfile.ROLE_OBJECT_ANCHOR:
			return 0.36
		DemoCoreSceneSpaceProfile.ROLE_PRESSURE:
			return 0.48
		DemoCoreSceneSpaceProfile.ROLE_RETURN:
			return 0.34
		_:
			return 0.25


func _get_map_node(path: String) -> Node:
	if path.is_empty() or get_parent() == null:
		return null
	return get_parent().get_node_or_null(path)


func _count_tagged_descendants(node: Node, region_id: String, role: String) -> int:
	var count := 0
	for child in node.get_children():
		if _node_matches_role(child, region_id, role):
			count += 1
		count += _count_tagged_descendants(child, region_id, role)
	return count


func _node_matches_role(node: Node, region_id: String, role: String) -> bool:
	if String(node.get_meta("core_scene_region_id", "")) != region_id:
		return false
	if role.is_empty():
		return true
	var roles: Array = node.get_meta("core_scene_roles", [])
	return roles.has(role)


func _make_region_name(region_id: String) -> String:
	var parts := region_id.split(".")
	if parts.is_empty():
		return "Unknown"
	return String(parts[parts.size() - 1]).to_pascal_case()


func _clear_generated_frames() -> void:
	for child in get_children():
		if not String(child.name).begins_with(GENERATED_FRAME_PREFIX):
			continue
		remove_child(child)
		child.free()
