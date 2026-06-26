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
		print("Demo initial art identity checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_profile_scope_and_boundaries()
	_check_scene_layer_applies_identity_shapes()
	_check_representative_scene_nodes_are_tagged()


func _check_profile_scope_and_boundaries() -> void:
	var identity_ids := DemoInitialArtIdentityProfile.get_identity_ids()
	_expect_equal(identity_ids.size(), 9, "initial art identity profile covers nine identities")
	for identity_id in identity_ids:
		var profile := DemoInitialArtIdentityProfile.get_identity_profile(identity_id)
		for key in DemoInitialArtIdentityProfile.get_required_identity_keys():
			_expect_equal(profile.has(key), true, "%s has identity profile key %s" % [identity_id, key])
		_expect_rect_has_size(profile.get("body_rect", Rect2()), "%s body rect has size" % identity_id)
		_expect_rect_has_size(profile.get("accent_rect", Rect2()), "%s accent rect has size" % identity_id)
	_expect_equal(
		PrototypeVisualPriorityProfile.get_region_ids().size(),
		12,
		"initial art identity does not add a thirteenth region"
	)
	_expect_equal(
		_count_profiles_for_role(DemoInitialArtIdentityProfile.ROLE_DEVICE),
		5,
		"initial art identity covers five core devices"
	)


func _check_scene_layer_applies_identity_shapes() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node_or_null("DemoInitialArtIdentityLayer") as DemoInitialArtIdentityLayer
	_expect_equal(layer != null, true, "initial art identity layer exists")
	if layer == null:
		map.free()
		return

	layer.apply_profile()
	_expect_equal(layer.applied_identity_count, 9, "initial art identity layer applies nine identities")
	_expect_equal(layer.get_generated_shape_count(), 18, "initial art identity layer creates body and accent shapes")
	for identity_id in DemoInitialArtIdentityProfile.get_identity_ids():
		_expect_equal(layer.has_identity(String(identity_id)), true, "%s generated body shape exists" % identity_id)
	_expect_greater_or_equal(
		layer.get_tagged_anchor_count(DemoInitialArtIdentityProfile.ROLE_DEVICE),
		8,
		"device anchors and scene markers are tagged"
	)
	map.free()


func _check_representative_scene_nodes_are_tagged() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node("DemoInitialArtIdentityLayer") as DemoInitialArtIdentityLayer
	layer.apply_profile()
	for path in [
		"Interactables/OutpostCore",
		"Interactables/BasicReactor",
		"Interactables/BasicStorageBuildSite",
		"Interactables/FieldOutfittingStation",
		"Interactables/PollutionFilter",
		"Interactables/CrystalCluster",
		"Interactables/PollutionResidue",
		"OpeningSceneLayer/PollutionGatePressureMarker",
		"Interactables/DemoStabilizationCore"
	]:
		var node := map.get_node_or_null(String(path))
		_expect_equal(node != null, true, "%s exists for initial art identity" % path)
		if node == null:
			continue
		_expect_equal(node.has_meta("initial_art_identity_id"), true, "%s carries identity metadata" % path)
		_expect_equal(
			not String(node.get_meta("initial_art_material", "")).is_empty(),
			true,
			"%s carries material metadata" % path
		)
	var reactor_marker := map.get_node("OpeningSceneLayer/BaseReactorObjectMarker") as ColorRect
	_expect_equal(
		String(reactor_marker.get_meta("initial_art_material", "")),
		DemoInitialArtIdentityProfile.MATERIAL_REACTOR_HEAT,
		"reactor scene marker carries heat material"
	)
	map.free()


func _count_profiles_for_role(role: String) -> int:
	var count := 0
	for identity_id in DemoInitialArtIdentityProfile.get_identity_ids():
		var profile := DemoInitialArtIdentityProfile.get_identity_profile(String(identity_id))
		if String(profile.get("role", "")) == role:
			count += 1
	return count


func _expect_equal(actual, expected, context: String) -> void:
	if actual == expected:
		return
	failures.append("%s: expected %s, got %s" % [context, str(expected), str(actual)])


func _expect_greater_or_equal(actual: int, expected: int, context: String) -> void:
	if actual >= expected:
		return
	failures.append("%s: expected at least %s, got %s" % [context, str(expected), str(actual)])


func _expect_rect_has_size(rect: Rect2, context: String) -> void:
	if rect.size.x > 0.0 and rect.size.y > 0.0:
		return
	failures.append("%s: expected positive rect size, got %s" % [context, str(rect)])


func _cleanup() -> void:
	data_registry.free()
