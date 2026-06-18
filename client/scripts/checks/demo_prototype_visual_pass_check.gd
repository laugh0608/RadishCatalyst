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
		print("Demo prototype visual pass checks passed.")
		_cleanup()
		quit(0)
		return

	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _run_checks() -> void:
	_check_visual_priority_profile_coverage()
	_check_scene_visual_priority_layer()
	_check_current_objective_guidance_layer()
	_check_startup_readability_scope()
	_check_visual_state_methods()
	_check_visual_refresher_state_alignment()


func _check_visual_priority_profile_coverage() -> void:
	var region_ids := PrototypeVisualPriorityProfile.get_region_ids()
	_expect_equal(region_ids.size(), 12, "visual priority profile covers twelve regions")
	for region_id in region_ids:
		var profile := PrototypeVisualPriorityProfile.get_region_profile(region_id)
		for key in PrototypeVisualPriorityProfile.get_required_region_keys():
			_expect_equal(profile.has(key), true, "%s has visual profile key %s" % [region_id, key])
		_expect_rect_has_size(profile.get("main_route_rect", Rect2()), "%s main route cue has size" % region_id)
		_expect_rect_has_size(profile.get("key_object_rect", Rect2()), "%s key object cue has size" % region_id)
		_expect_rect_has_size(
			profile.get("hazard_or_facility_rect", Rect2()),
			"%s hazard or facility cue has size" % region_id
		)
	for state_id in PrototypeVisualPriorityProfile.get_required_state_ids():
		var state_profile := PrototypeVisualPriorityProfile.get_state_profile(state_id)
		_expect_equal(state_profile.is_empty(), false, "%s state profile exists" % state_id)
		_expect_equal(state_profile.has("color"), true, "%s state has color" % state_id)
		_expect_equal(state_profile.has("label"), true, "%s state has label" % state_id)


func _check_scene_visual_priority_layer() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	var layer := map.get_node("PrototypeVisualPriorityLayer") as PrototypeVisualPriorityLayer
	_expect_equal(layer != null, true, "prototype visual priority layer exists")
	if layer != null:
		layer.apply_profile()
		_expect_equal(layer.applied_region_count, 12, "visual priority layer applies twelve region profiles")
		_expect_equal(layer.get_generated_cue_count(), 36, "visual priority layer creates three cues per region")
		for region_id in PrototypeVisualPriorityProfile.get_region_ids():
			_check_region_cues(map, layer, region_id)
	map.free()


func _check_current_objective_guidance_layer() -> void:
	var map := _create_setup_map()
	var layer := map.get_node("CurrentObjectiveGuidanceLayer") as CurrentObjectiveGuidanceLayer
	var target := map.get_node("Interactables/OutpostCore") as PrototypeInteractable
	var storage := map.get_node("Interactables/BasicStorageBuildSite") as PrototypeInteractable
	_expect_equal(layer != null, true, "current objective guidance layer exists")
	if layer == null:
		map.free()
		return

	layer.refresh_guidance()
	_expect_equal(layer.is_target_guidance_visible(), true, "startup outpost core target guidance is visible")
	_expect_equal(layer.get_node_or_null("CurrentObjectiveTargetLabel") != null, true, "current target label exists")
	storage.set_focus_visual(true)
	layer.refresh_guidance()
	_expect_equal(layer.is_off_target_hint_visible(), true, "focused non-target object shows current objective hint")
	target.set_restored_outpost_core_visual()
	layer.refresh_guidance()
	_expect_equal(layer.is_target_guidance_visible(), false, "current objective guidance hides after outpost core restore")
	map.free()


func _check_startup_readability_scope() -> void:
	var map := _create_setup_map()
	var layer := map.get_node("PrototypeVisualPriorityLayer") as PrototypeVisualPriorityLayer
	_expect_equal(layer != null, true, "startup visual priority layer exists")
	if layer != null:
		layer.apply_profile()
		layer.refresh_focus_visibility(map.get_player_position())
		_expect_equal(layer.get_generated_cue_count(), 36, "startup still keeps full visual cue evidence")
		_expect_equal(layer.get_visible_generated_cue_count(), 6, "startup only shows nearby outpost and crystal cues")
		_expect_equal(
			_get_region_cue_visible(layer, "region.pollution_edge", PrototypeVisualPriorityProfile.ROLE_MAIN_ROUTE),
			false,
			"startup hides pollution visual cue outside the readable opening frame"
		)
		_expect_equal(
			_get_region_cue_visible(layer, "region.outpost_platform", PrototypeVisualPriorityProfile.ROLE_KEY_OBJECT),
			true,
			"startup keeps outpost key object cue visible"
		)
	_check_runtime_annotation_hidden(map, "DemoRoutePresentationLayer/DemoRouteBaseLabel")
	_check_runtime_annotation_hidden(map, "SceneArtFoundationLayer/SceneArtBaseIdentityLabel")
	_check_runtime_annotation_hidden(map, "NonCoreSceneIdentityLayer/NonCoreRuinIdentityLabel")
	_check_runtime_annotation_hidden(map, "OpeningSceneLayer/BaseCorePadLabel")
	_check_runtime_annotation_hidden(map, "BaseDirectionLabel")
	map.free()


func _check_region_cues(map: VerticalSliceMap, layer: PrototypeVisualPriorityLayer, region_id: String) -> void:
	var profile := PrototypeVisualPriorityProfile.get_region_profile(region_id)
	var background := map.get_node_or_null(String(profile.get("background_path", ""))) as ColorRect
	_expect_equal(background != null, true, "%s background node exists" % region_id)
	if background != null:
		_expect_equal(
			String(background.get_meta("visual_priority_role", "")),
			"background",
			"%s background carries visual priority role" % region_id
		)
		_expect_color_close(
			background.color,
			profile.get("background_color", Color.WHITE),
			"%s background color matches visual priority profile" % region_id
		)
	for role in [
		PrototypeVisualPriorityProfile.ROLE_MAIN_ROUTE,
		PrototypeVisualPriorityProfile.ROLE_KEY_OBJECT,
		PrototypeVisualPriorityProfile.ROLE_HAZARD_OR_FACILITY
	]:
		var cue_name := "PrototypeVisualPriority%s" % PrototypeVisualPriorityProfile.make_cue_name(region_id, role)
		var cue := layer.get_node_or_null(cue_name) as ColorRect
		_expect_equal(cue != null, true, "%s %s visual cue exists" % [region_id, role])
		if cue != null:
			_expect_equal(String(cue.get_meta("visual_priority_role", "")), role, "%s %s cue role" % [region_id, role])
			_expect_equal(
				String(cue.get_meta("visual_priority_region_id", "")),
				region_id,
				"%s %s cue region id" % [region_id, role]
			)


func _get_region_cue_visible(layer: PrototypeVisualPriorityLayer, region_id: String, role: String) -> bool:
	var cue_name := "PrototypeVisualPriority%s" % PrototypeVisualPriorityProfile.make_cue_name(region_id, role)
	var cue := layer.get_node_or_null(cue_name) as ColorRect
	if cue == null:
		return false
	return cue.visible


func _check_runtime_annotation_hidden(map: VerticalSliceMap, path: String) -> void:
	var label := map.get_node_or_null(path) as Label
	_expect_equal(label != null, true, "%s annotation label exists" % path)
	if label == null:
		return
	_expect_equal(label.visible, false, "%s annotation label hidden during playable runtime" % path)


func _check_visual_state_methods() -> void:
	var interactable := _create_test_interactable("VisualStateObject", "building.foundation_t1", "build", "视觉状态对象")
	_expect_equal(interactable.set_missing_prerequisite_visual(), true, "missing prerequisite visual applies")
	_expect_marker_state(interactable, PrototypeVisualPriorityProfile.STATE_MISSING_PREREQUISITE, "missing prerequisite")
	_expect_equal(interactable.set_device_busy_visual(), true, "device busy visual applies")
	_expect_marker_state(interactable, PrototypeVisualPriorityProfile.STATE_DEVICE_BUSY, "device busy")
	_expect_equal(interactable.set_core_write_blocked_visual(), true, "core write blocked visual applies")
	_expect_marker_state(interactable, PrototypeVisualPriorityProfile.STATE_CORE_WRITE_BLOCKED, "core write blocked")
	interactable.free()


func _check_visual_refresher_state_alignment() -> void:
	_check_build_prerequisite_visual()
	_check_processing_busy_visual()
	_check_danger_active_visual()
	_check_core_write_blocked_visual()
	_check_processed_object_visual()


func _check_build_prerequisite_visual() -> void:
	var map := _create_setup_map()
	var world := WorldState.create_default()
	map.refresh_world_interactables(world)
	var build_site := map.get_node("Interactables/FoundationSiteNorth") as PrototypeInteractable
	_expect_marker_state(
		build_site,
		PrototypeVisualPriorityProfile.STATE_MISSING_PREREQUISITE,
		"foundation build missing prerequisite visual"
	)
	map.free()


func _check_processing_busy_visual() -> void:
	var map := _create_setup_map()
	var world := WorldState.create_default()
	world.set_base_structure_status("structure.basic_reactor", "in_progress", "recipe.process_crystal_ore")
	map.refresh_world_interactables(world)
	var reactor := map.get_node("Interactables/BasicReactor") as PrototypeInteractable
	_expect_marker_state(reactor, PrototypeVisualPriorityProfile.STATE_DEVICE_BUSY, "reactor busy visual")
	map.free()


func _check_danger_active_visual() -> void:
	var map := _create_setup_map()
	var world := WorldState.create_default()
	world.quest_state.active_quest_ids = ["quest.salvage_signal_echo"]
	world.ensure_enemy("enemy_instance.ruin_phase_guard", "enemy.ruin_phase_guard", "region.ruin_outer_ring", 18.0)
	map.refresh_world_interactables(world)
	var signal_echo := map.get_node("Interactables/SignalEchoCache") as PrototypeInteractable
	_expect_marker_state(signal_echo, PrototypeVisualPriorityProfile.STATE_DANGER_ACTIVE, "signal echo danger visual")
	map.free()


func _check_core_write_blocked_visual() -> void:
	var map := _create_setup_map()
	var world := WorldState.create_default()
	world.current_region_id = "region.demo_stabilization_core"
	world.quest_state.active_quest_ids = ["quest.write_demo_stabilization_core"]
	world.ensure_enemy(
		"enemy_instance.demo_stabilization_guard",
		"enemy.demo_stabilization_guard",
		"region.demo_stabilization_core",
		28.0
	)
	map.refresh_world_interactables(world)
	var core := map.get_node("Interactables/DemoStabilizationCore") as PrototypeInteractable
	_expect_marker_state(core, PrototypeVisualPriorityProfile.STATE_CORE_WRITE_BLOCKED, "core write blocked visual")
	map.free()


func _check_processed_object_visual() -> void:
	var map := _create_setup_map()
	var world := WorldState.create_default()
	world.ensure_map_object(
		"map_object_instance.crystal_cluster",
		"map_object.crystal_cluster",
		"region.crystal_vein_field"
	)
	world.set_map_object_flag("map_object_instance.crystal_cluster", "is_gathered", true)
	map.refresh_world_interactables(world)
	var crystal := map.get_node("Interactables/CrystalCluster") as PrototypeInteractable
	var label := crystal.get_node("Label") as Label
	_expect_equal(crystal.monitoring, false, "processed crystal disables monitoring")
	_expect_text_contains(label.text, "已采集", "processed crystal keeps processed visual label")
	map.free()


func _create_setup_map() -> VerticalSliceMap:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	root.add_child(map)
	map.setup(data_registry)
	return map


func _create_test_interactable(
	node_name: String,
	definition_id: String,
	interaction_type: String,
	display_name: String
) -> PrototypeInteractable:
	var interactable := PrototypeInteractable.new()
	interactable.name = node_name
	interactable.definition_id = definition_id
	interactable.interaction_type = interaction_type
	var marker := ColorRect.new()
	marker.name = "Marker"
	interactable.add_child(marker)
	var focus_ring := ColorRect.new()
	focus_ring.name = "FocusRing"
	interactable.add_child(focus_ring)
	var label := Label.new()
	label.name = "Label"
	interactable.add_child(label)
	interactable.setup(display_name)
	return interactable


func _expect_marker_state(interactable: PrototypeInteractable, state_id: String, context: String) -> void:
	var state_profile := PrototypeVisualPriorityProfile.get_state_profile(state_id)
	var marker := interactable.get_node("Marker") as ColorRect
	var label := interactable.get_node("Label") as Label
	_expect_color_close(marker.color, state_profile.get("color", Color.WHITE), "%s marker color" % context)
	_expect_text_contains(label.text, String(state_profile.get("label", "")), "%s label" % context)


func _expect_rect_has_size(rect: Rect2, context: String) -> void:
	_expect_equal(rect.size.x > 0.0 and rect.size.y > 0.0, true, context)


func _expect_color_close(actual: Color, expected: Color, context: String) -> void:
	if (
		absf(actual.r - expected.r) <= 0.001
		and absf(actual.g - expected.g) <= 0.001
		and absf(actual.b - expected.b) <= 0.001
		and absf(actual.a - expected.a) <= 0.001
	):
		return
	failures.append("%s: expected %s, got %s" % [context, str(expected), str(actual)])


func _expect_equal(actual, expected, context: String) -> void:
	if actual == expected:
		return
	failures.append("%s: expected %s, got %s" % [context, str(expected), str(actual)])


func _expect_text_contains(text: String, expected: String, context: String) -> void:
	if text.find(expected) >= 0:
		return
	failures.append("%s: expected text to contain '%s', got '%s'" % [context, expected, text])


func _cleanup() -> void:
	data_registry.free()
