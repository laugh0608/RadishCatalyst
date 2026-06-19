extends Node2D
class_name PrototypeVisualPriorityLayer

const GENERATED_CUE_PREFIX := "PrototypeVisualPriority"
const FOCUS_VISIBLE_RADIUS := 500.0
const UNRESOLVED_FOCUS_POSITION := Vector2(1.0e20, 1.0e20)
const PLAYABLE_ANNOTATION_LAYER_NAMES := [
	"DemoRoutePresentationLayer",
	"SceneArtFoundationLayer",
	"NonCoreSceneIdentityLayer"
]

var applied_region_count := 0


func _ready() -> void:
	configure_playable_annotation_visibility()
	apply_profile()


func _process(_delta: float) -> void:
	refresh_focus_visibility()


func apply_profile() -> void:
	configure_playable_annotation_visibility()
	_clear_generated_cues()
	applied_region_count = 0
	for region_id in PrototypeVisualPriorityProfile.get_region_ids():
		var profile := PrototypeVisualPriorityProfile.get_region_profile(region_id)
		if profile.is_empty():
			continue
		_apply_region_profile(region_id, profile)
		applied_region_count += 1
	refresh_focus_visibility()


func get_generated_cue_count() -> int:
	var count := 0
	for child in get_children():
		if String(child.name).begins_with(GENERATED_CUE_PREFIX):
			count += 1
	return count


func get_visible_generated_cue_count() -> int:
	var count := 0
	for child in get_children():
		if String(child.name).begins_with(GENERATED_CUE_PREFIX) and child.visible:
			count += 1
	return count


func refresh_focus_visibility(focus_position: Vector2 = UNRESOLVED_FOCUS_POSITION) -> void:
	var resolved_focus := focus_position
	if resolved_focus == UNRESOLVED_FOCUS_POSITION:
		resolved_focus = _get_player_position()
	if resolved_focus == UNRESOLVED_FOCUS_POSITION:
		return
	for child in get_children():
		if not String(child.name).begins_with(GENERATED_CUE_PREFIX):
			continue
		if not child is ColorRect:
			continue
		var cue := child as ColorRect
		cue.visible = cue.get_rect().get_center().distance_to(resolved_focus) <= FOCUS_VISIBLE_RADIUS


func configure_playable_annotation_visibility() -> void:
	for layer_name in PLAYABLE_ANNOTATION_LAYER_NAMES:
		_set_descendant_labels_visible(_get_map_node(layer_name), false)
	_set_descendant_labels_visible(_get_map_node("OpeningSceneLayer"), false)
	if get_parent() == null:
		return
	for child in get_parent().get_children():
		if child is Label and String(child.name).ends_with("DirectionLabel"):
			(child as Label).visible = false


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


func _get_player_position() -> Vector2:
	if get_parent() == null:
		return UNRESOLVED_FOCUS_POSITION
	var player := get_parent().get_node_or_null("Player") as Node2D
	if player == null:
		return UNRESOLVED_FOCUS_POSITION
	return player.position


func _set_descendant_labels_visible(node: Node, is_visible: bool) -> void:
	if node == null:
		return
	for child in node.get_children():
		if child is Label:
			(child as Label).visible = is_visible
		_set_descendant_labels_visible(child, is_visible)


func _clear_generated_cues() -> void:
	for child in get_children():
		if not String(child.name).begins_with(GENERATED_CUE_PREFIX):
			continue
		remove_child(child)
		child.free()
