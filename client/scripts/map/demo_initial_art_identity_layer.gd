extends Node2D
class_name DemoInitialArtIdentityLayer

const GENERATED_IDENTITY_PREFIX := "DemoInitialArtIdentity"
const GENERATED_ACCENT_SUFFIX := "Accent"
const SCENE_TINT_STRENGTH := 0.45

var applied_identity_count := 0


func _ready() -> void:
	apply_profile()


func apply_profile() -> void:
	_clear_generated_shapes()
	applied_identity_count = 0
	for identity_id in DemoInitialArtIdentityProfile.get_identity_ids():
		var profile := DemoInitialArtIdentityProfile.get_identity_profile(identity_id)
		if profile.is_empty():
			continue
		_apply_identity_profile(identity_id, profile)
		applied_identity_count += 1


func get_generated_shape_count() -> int:
	var count := 0
	for child in get_children():
		if String(child.name).begins_with(GENERATED_IDENTITY_PREFIX):
			count += 1
	return count


func get_tagged_anchor_count(role: String = "") -> int:
	if get_parent() == null:
		return 0
	return _count_tagged_descendants(get_parent(), role)


func has_identity(identity_id: String) -> bool:
	var body_name := "%s%s" % [
		GENERATED_IDENTITY_PREFIX,
		DemoInitialArtIdentityProfile.make_node_name(identity_id)
	]
	return get_node_or_null(body_name) != null


func _apply_identity_profile(identity_id: String, profile: Dictionary) -> void:
	var role := String(profile.get("role", ""))
	var material := String(profile.get("material", ""))
	var anchor_path := String(profile.get("anchor_path", ""))
	var scene_path := String(profile.get("scene_path", ""))
	_tag_node(anchor_path, identity_id, role, material)
	_tag_node(scene_path, identity_id, role, material)
	_tint_scene_rect(scene_path, profile.get("body_color", Color.WHITE))
	_create_identity_shape(identity_id, profile, "body_rect", "", profile.get("body_color", Color.WHITE))
	_create_identity_shape(
		identity_id,
		profile,
		"accent_rect",
		GENERATED_ACCENT_SUFFIX,
		profile.get("accent_color", Color.WHITE)
	)


func _tag_node(path: String, identity_id: String, role: String, material: String) -> void:
	var node := _get_map_node(path)
	if node == null:
		return
	node.set_meta("initial_art_identity_id", identity_id)
	node.set_meta("initial_art_role", role)
	node.set_meta("initial_art_material", material)


func _tint_scene_rect(path: String, tint: Color) -> void:
	var rect := _get_map_node(path) as ColorRect
	if rect == null:
		return
	if not rect.has_meta("initial_art_original_color"):
		rect.set_meta("initial_art_original_color", rect.color)
	var original: Color = rect.get_meta("initial_art_original_color", rect.color)
	rect.color = original.lerp(tint, SCENE_TINT_STRENGTH)


func _create_identity_shape(
	identity_id: String,
	profile: Dictionary,
	rect_key: String,
	name_suffix: String,
	color: Color
) -> void:
	var rect: Rect2 = profile.get(rect_key, Rect2())
	if rect.size.x <= 0.0 or rect.size.y <= 0.0:
		return
	var shape := ColorRect.new()
	shape.name = "%s%s" % [
		GENERATED_IDENTITY_PREFIX,
		DemoInitialArtIdentityProfile.make_node_name(identity_id, name_suffix)
	]
	shape.offset_left = rect.position.x
	shape.offset_top = rect.position.y
	shape.offset_right = rect.position.x + rect.size.x
	shape.offset_bottom = rect.position.y + rect.size.y
	shape.color = color
	shape.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shape.set_meta("initial_art_identity_id", identity_id)
	shape.set_meta("initial_art_role", String(profile.get("role", "")))
	shape.set_meta("initial_art_material", String(profile.get("material", "")))
	add_child(shape)


func _get_map_node(path: String) -> Node:
	if path.is_empty() or get_parent() == null:
		return null
	return get_parent().get_node_or_null(path)


func _count_tagged_descendants(node: Node, role: String) -> int:
	var count := 0
	for child in node.get_children():
		if child.has_meta("initial_art_identity_id"):
			if role.is_empty() or String(child.get_meta("initial_art_role", "")) == role:
				count += 1
		count += _count_tagged_descendants(child, role)
	return count


func _clear_generated_shapes() -> void:
	for child in get_children():
		if not String(child.name).begins_with(GENERATED_IDENTITY_PREFIX):
			continue
		remove_child(child)
		child.free()
