extends SceneTree

const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")

var failures: Array[String] = []
var data_registry := DataRegistry.new()


func _init() -> void:
	if not data_registry.load_all():
		failures.append("data registry should load all static data")
	else:
		_run_checks()

	if failures.is_empty():
		print("Demo core scene playable space checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_profile_covers_core_regions_without_expansion()
	_check_scene_space_layer_applies_roles()
	_check_scene_space_frames_step_back_in_workfaces()
	_check_representative_objects_and_enemies_sit_on_space_surfaces()


func _check_profile_covers_core_regions_without_expansion() -> void:
	var core_region_ids := DemoCoreSceneSpaceProfile.get_region_ids()
	_expect_equal(core_region_ids.size(), 4, "core scene space profile covers four core regions")
	for region_id in core_region_ids:
		var profile := DemoCoreSceneSpaceProfile.get_region_profile(region_id)
		for key in DemoCoreSceneSpaceProfile.get_required_region_keys():
			_expect_equal(profile.has(key), true, "%s has scene space key %s" % [region_id, key])
		for role in DemoCoreSceneSpaceProfile.get_required_roles():
			_expect_greater_or_equal(
				DemoCoreSceneSpaceProfile.get_node_paths_for_role(region_id, String(role)).size(),
				1,
				"%s has at least one %s scene node" % [region_id, String(role)]
			)
		_expect_greater_or_equal(
			DemoCoreSceneSpaceProfile.get_node_paths_for_role(region_id, DemoCoreSceneSpaceProfile.ROLE_GROUND).size(),
			2,
			"%s has multiple ground surfaces" % region_id
		)
		_expect_greater_or_equal(
			DemoCoreSceneSpaceProfile.get_primary_object_paths(region_id).size(),
			4,
			"%s has representative object anchors" % region_id
		)
	_expect_equal(PrototypeVisualPriorityProfile.get_region_ids().size(), 12, "playable map still uses twelve regions")


func _check_scene_space_layer_applies_roles() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node_or_null("DemoCoreSceneSpaceLayer") as DemoCoreSceneSpaceLayer
	_expect_equal(layer != null, true, "demo core scene space layer exists")
	if layer == null:
		map.free()
		return

	layer.apply_profile()
	_expect_equal(layer.applied_region_count, 4, "scene space layer applies four core region profiles")
	_expect_equal(layer.get_generated_frame_count(), 16, "scene space layer creates four frame segments per core region")
	for region_id in DemoCoreSceneSpaceProfile.get_region_ids():
		for role in DemoCoreSceneSpaceProfile.get_required_roles():
			var role_text := String(role)
			_expect_equal(layer.has_role(region_id, role_text), true, "%s has role %s on scene nodes" % [region_id, role_text])
		_expect_greater_or_equal(
			layer.get_tagged_node_count(region_id, DemoCoreSceneSpaceProfile.ROLE_GROUND),
			2,
			"%s tags multiple ground nodes" % region_id
		)
		_expect_greater_or_equal(
			layer.get_tagged_node_count(region_id, DemoCoreSceneSpaceProfile.ROLE_OBJECT_ANCHOR),
			2,
			"%s tags multiple object anchor nodes" % region_id
		)
	map.free()


func _check_scene_space_frames_step_back_in_workfaces() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node_or_null("DemoCoreSceneSpaceLayer") as DemoCoreSceneSpaceLayer
	_expect_equal(layer != null, true, "demo core scene space layer exists for focus frame check")
	if layer == null:
		map.free()
		return

	layer.apply_profile()
	var restored_alpha := layer.get_max_generated_frame_alpha()
	layer.refresh_frame_focus(Vector2(112.0, -112.0))
	_expect_equal(layer.get_generated_frame_count(), 16, "scene space keeps generated frames for role coverage")
	_expect_equal(layer.get_muted_frame_count(), 16, "scene space mutes all generated frames in resource workfaces")
	_expect_equal(
		layer.get_max_generated_frame_alpha() <= DemoCoreSceneSpaceLayer.FOCUSED_FRAME_ALPHA + 0.0005,
		true,
		"scene space frames step behind the current workface"
	)
	layer.refresh_frame_focus(Vector2(-250.0, -48.0))
	_expect_equal(layer.get_muted_frame_count(), 0, "scene space restores frames outside resource workfaces")
	_expect_equal(
		layer.get_max_generated_frame_alpha() > DemoCoreSceneSpaceLayer.FOCUSED_FRAME_ALPHA,
		true,
		"scene space restores readable frame alpha outside workfaces"
	)
	_expect_equal(restored_alpha > DemoCoreSceneSpaceLayer.FOCUSED_FRAME_ALPHA, true, "scene space has a stronger default frame alpha")
	map.free()


func _check_representative_objects_and_enemies_sit_on_space_surfaces() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(data_registry)
	var layer := map.get_node("DemoCoreSceneSpaceLayer") as DemoCoreSceneSpaceLayer
	layer.apply_profile()

	for region_id in DemoCoreSceneSpaceProfile.get_region_ids():
		var surface_paths := DemoCoreSceneSpaceProfile.get_all_scene_node_paths(region_id)
		for object_path in DemoCoreSceneSpaceProfile.get_primary_object_paths(region_id):
			_check_actor_space_position(map, String(object_path), region_id, surface_paths)
		for enemy_path in DemoCoreSceneSpaceProfile.get_primary_enemy_paths(region_id):
			_check_actor_space_position(map, String(enemy_path), region_id, surface_paths)
	map.free()


func _check_actor_space_position(map: VerticalSliceMap, path: String, region_id: String, surface_paths: Array) -> void:
	var actor := map.get_node_or_null(path) as Node2D
	_expect_equal(actor != null, true, "%s exists for core scene space check" % path)
	if actor == null:
		return
	_expect_equal(
		_is_position_on_any_surface(map, actor.position, surface_paths),
		true,
		"%s sits on a tagged core scene surface" % path
	)


func _is_position_on_any_surface(map: VerticalSliceMap, position: Vector2, surface_paths: Array) -> bool:
	for surface_path in surface_paths:
		var surface := map.get_node_or_null(String(surface_path)) as ColorRect
		if surface == null:
			continue
		if surface.get_rect().grow(8.0).has_point(position):
			return true
	return false


func _expect_equal(actual, expected, context: String) -> void:
	if actual == expected:
		return
	failures.append("%s: expected %s, got %s" % [context, str(expected), str(actual)])


func _expect_greater_or_equal(actual: int, expected: int, context: String) -> void:
	if actual >= expected:
		return
	failures.append("%s: expected at least %s, got %s" % [context, str(expected), str(actual)])


func _cleanup() -> void:
	data_registry.free()
