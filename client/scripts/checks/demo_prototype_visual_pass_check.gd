extends SceneTree

const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")
const ALPHA_CHECK_EPSILON := 0.00001

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
	_check_playable_space_and_actor_silhouettes()
	_check_key_object_semantic_silhouettes()
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
	var reactor := map.get_node("Interactables/BasicReactor") as PrototypeInteractable
	var departure_gate := map.get_node("Interactables/OutpostDepartureGate") as PrototypeInteractable
	var crystal_layer := map.get_node("DemoCrystalResourceVisualLayer") as DemoCrystalResourceVisualLayer
	var first_path_layer := map.get_node("DemoFirstIndustrialPathVisualLayer") as DemoFirstIndustrialPathVisualLayer
	var pollution_layer := map.get_node("DemoPollutionBoundaryVisualLayer") as DemoPollutionBoundaryVisualLayer
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	_expect_equal(layer != null, true, "current objective guidance layer exists")
	if layer == null:
		map.free()
		return

	map.refresh_world_interactables(world)
	map.update_current_interactable()
	_expect_equal(map.current_interactable, target, "startup interaction prefers current outpost core objective")
	_expect_equal(storage.focus_ring.visible, false, "startup storage does not steal the first interaction focus")
	_expect_equal(reactor.focus_ring.visible, false, "startup reactor does not steal the first interaction focus")
	layer.refresh_guidance(world, character)
	_expect_guidance_target(layer, "OutpostCore", "前哨核心", "startup outpost core target guidance")
	_expect_equal(layer.get_node_or_null("CurrentObjectiveTargetLabel") != null, true, "current target label exists")
	_expect_equal(layer.is_target_name_label_visible(), false, "near current target hides scene text label")
	_expect_equal(layer.get_focus_readability_shape_count() >= 5, true, "current objective layer registers focus readability shapes")
	_expect_equal(layer.has_focus_readability_shape("focus_readability.local_workface_frame"), true, "current objective layer registers local workface frame")
	_expect_equal(layer.has_focus_readability_shape("focus_readability.short_player_tether"), true, "current objective layer registers short player tether")
	_expect_equal(layer.is_local_focus_frame_visible(), true, "startup current objective shows a local focus frame")
	_expect_equal(layer.is_short_focus_tether_visible(), true, "startup current objective uses a short local tether")
	_expect_equal(layer.get_current_focus_readability_mode(), "startup_core", "startup current objective uses core restore focus mode")
	map.player.position = target.position + Vector2(-220.0, 0.0)
	layer.refresh_guidance(world, character)
	_expect_equal(layer.is_target_name_label_visible(), true, "distant current target can show a short scene label")
	_expect_equal(layer.get_target_name_label_text(), "前哨核心", "distant current target label omits redundant prefix")
	_expect_equal(layer.is_local_focus_frame_visible(), true, "distant target keeps local focus frame on the target")
	_expect_equal(layer.is_short_focus_tether_visible(), false, "distant target does not draw a long player tether")
	map.player.position = storage.position
	storage.set_focus_visual(true)
	layer.refresh_guidance(world, character)
	_expect_equal(layer.is_off_target_hint_visible(), false, "focused non-target object does not add center text over the scene")
	var off_target_label := layer.get_node("CurrentObjectiveOffTargetLabel") as Label
	_expect_equal(off_target_label.text, "", "off-target hint text stays empty")

	target.set_restored_outpost_core_visual()
	world.quest_state.complete_quest("quest.restore_outpost")
	world.quest_state.activate_quest("quest.scout_crystal_field")
	map.player.position = VerticalSliceMap.OUTPOST_RESPAWN_POSITION
	map.refresh_world_interactables(world)
	map.update_current_interactable()
	_expect_equal(map.current_interactable, null, "post-restore start does not auto-focus side devices before approach")
	layer.refresh_guidance(world, character)
	_expect_guidance_target(layer, "BasicStorageBuildSite", "基础储存箱", "post-restore storage build guidance")

	world.add_base_structure(
		"structure.basic_storage_build_site",
		"building.basic_storage",
		"region.outpost_platform",
		"map_object_instance.basic_storage_build_site"
	)
	map.refresh_world_interactables(world)
	layer.refresh_guidance(world, character)
	_expect_guidance_target(layer, "OutpostDepartureGate", "外勤出发口", "scout route departure guidance")
	map.player.position = departure_gate.position
	map.update_current_interactable()
	crystal_layer.refresh_focus_visibility(map.player.position)
	_expect_equal(map.current_interactable != null, true, "crystal threshold has a logical interactable")
	if map.current_interactable != null:
		_expect_equal(
			String(map.current_interactable.name),
			"OutpostDepartureGate",
			"crystal threshold still keeps departure gate as logical interactable"
		)
	_expect_equal(
		(departure_gate.get_node("Label") as Label).visible,
		false,
		"crystal threshold hides departure gate interactable label over resource visuals"
	)
	_expect_equal(
		(departure_gate.get_node("FocusRing") as ColorRect).visible,
		false,
		"crystal threshold hides departure gate focus ring over resource visuals"
	)
	map.player.position = VerticalSliceMap.OUTPOST_RESPAWN_POSITION
	map.update_current_interactable()

	world.quest_state.set_objective_progress("quest.scout_crystal_field", "visit_region", "region.crystal_vein_field", 1.0)
	map.refresh_world_interactables(world)
	layer.refresh_guidance(world, character)
	_expect_guidance_target(layer, "CrystalCluster", "晶体采集点", "crystal field gather guidance")

	world.add_base_structure(
		"structure.crystal_collector_build_site",
		"building.crystal_collector_t1",
		"region.crystal_vein_field",
		"map_object_instance.crystal_collector_build_site"
	)
	world.ensure_map_object(
		"map_object_instance.crystal_collector_output",
		"map_object.crystal_collector_output",
		"region.crystal_vein_field"
	)
	map.refresh_world_interactables(world)
	layer.refresh_guidance(world, character)
	_expect_guidance_target(layer, "CrystalCollectorOutput", "采集器输出", "built collector output guidance")
	map.player.position = Vector2(96.0, -118.0)
	character.position = map.player.position
	character.current_region_id = "region.crystal_vein_field"
	first_path_layer.refresh_path_state(world, character)
	first_path_layer.refresh_focus_visibility(map.player.position)
	crystal_layer.refresh_focus_visibility(map.player.position)
	layer.refresh_guidance(world, character)
	map.sync_enemy_states(world)
	map.update_current_interactable()
	_expect_guidance_target(layer, "CrystalCollectorOutput", "采集器输出", "collector output compact guidance target")
	_expect_equal(layer.is_first_path_compact_guidance_active(), true, "first industrial path compacts current target guidance")
	_expect_equal(layer.is_local_focus_frame_visible(), true, "first industrial path keeps a local objective focus frame")
	_expect_equal(layer.get_current_focus_readability_mode(), "first_path", "first industrial path uses local focus readability mode")
	_expect_equal(layer.is_target_route_visible(), false, "first industrial path hides long current target route")
	var collector_output := map.get_node("Interactables/CrystalCollectorOutput") as PrototypeInteractable
	var crystal_focus_region := map.get_node("RegionCrystal") as ColorRect
	var crystal_focus_pollution_region := map.get_node("RegionPollution") as ColorRect
	var crystal_focus_boundary := map.get_node("RegionBoundaryCrystal") as ColorRect
	var crystal_focus_pollution_boundary := map.get_node("RegionBoundaryPollution") as ColorRect
	_expect_equal(map.current_interactable, collector_output, "first industrial path still keeps collector output as logical focus")
	_expect_equal(first_path_layer.visible, false, "crystal workface keeps the full first industrial path hidden")
	_expect_equal(collector_output.label.visible, true, "crystal workface keeps the current interactable label readable")
	_expect_equal(collector_output.focus_ring.visible, true, "crystal workface keeps the current interactable focus ring readable")
	_expect_equal(collector_output.marker.scale != Vector2.ONE, true, "crystal workface enlarges the current interaction marker")
	_expect_equal(crystal_layer.get_muted_crystal_focus_context_rect_count() >= 12, true, "crystal workface mutes old region panels, routes, and boundary frames")
	_expect_equal(_is_rect_alpha_at_most(crystal_focus_region, 0.003), true, "crystal workface keeps the blue crystal panel behind the ore surface")
	_expect_equal(_is_rect_alpha_at_most(crystal_focus_pollution_region, 0.0006), true, "crystal workface suppresses the yellow pollution panel")
	_expect_equal(_is_rect_alpha_at_most(crystal_focus_boundary, 0.0006), true, "crystal workface lowers the crystal boundary frame")
	_expect_equal(_is_rect_alpha_at_most(crystal_focus_pollution_boundary, 0.0006), true, "crystal workface lowers the pollution boundary frame")
	var field_patrol := map.get_node("Enemies/NativeSkitterPatrol") as PrototypeEnemy
	_expect_equal(field_patrol.modulate, PrototypeEnemy.DEFAULT_CONTEXT_MODULATE, "crystal workface leaves enemy pressure readable without the path overlay")
	map.player.position = Vector2(320.0, -118.0)
	first_path_layer.refresh_focus_visibility(map.player.position)
	map.update_current_interactable()
	_expect_equal(field_patrol.modulate, PrototypeEnemy.DEFAULT_CONTEXT_MODULATE, "leaving first industrial path restores enemy context weight")
	map.player.position = VerticalSliceMap.OUTPOST_RESPAWN_POSITION
	character.position = map.player.position
	character.current_region_id = "region.outpost_platform"
	first_path_layer.refresh_focus_visibility(map.player.position)

	world.quest_state.active_quest_ids = ["quest.calibrate_reactor"]
	map.refresh_world_interactables(world)
	layer.refresh_guidance(world, character)
	_expect_guidance_target(layer, "FieldWreckageNorth", "导电废件", "calibration salvage guidance")
	world.quest_state.set_objective_progress("quest.calibrate_reactor", "gather_item", "item.salvage_scrap", 2.0)
	map.refresh_world_interactables(world)
	layer.refresh_guidance(world, character)
	_expect_guidance_target(layer, "BasicReactor", "基础反应器", "calibration reactor guidance")

	world.quest_state.active_quest_ids = ["quest.bring_back_sample"]
	map.refresh_world_interactables(world)
	layer.refresh_guidance(world, character)
	_expect_guidance_target(layer, "AnomalyCrystal", "异常晶体", "anomaly sample guidance")

	world.quest_state.active_quest_ids = ["quest.analyze_anomaly_sample"]
	map.refresh_world_interactables(world)
	layer.refresh_guidance(world, character)
	_expect_guidance_target(layer, "AnomalyResidueNorth", "异常残留物", "anomaly residue guidance")
	world.quest_state.set_objective_progress("quest.analyze_anomaly_sample", "gather_item", "item.anomaly_residue", 1.0)
	map.refresh_world_interactables(world)
	layer.refresh_guidance(world, character)
	_expect_guidance_target(layer, "BasicReactor", "基础反应器", "anomaly analysis reactor guidance")

	world.quest_state.active_quest_ids = ["quest.expand_treatment_point"]
	map.refresh_world_interactables(world)
	layer.refresh_guidance(world, character)
	_expect_guidance_target(layer, "RoughGroundNorth", "粗糙地块", "treatment point first clearing guidance")
	world.quest_state.set_objective_progress("quest.expand_treatment_point", "clear", "map_object.rough_ground", 1.0)
	_mark_map_object_flag(world, "map_object_instance.rough_ground_north", "map_object.rough_ground", "is_cleared", true)
	_mark_map_object_flag(world, "map_object_instance.rough_ground_south", "map_object.rough_ground", "is_cleared", true)
	map.refresh_world_interactables(world)
	layer.refresh_guidance(world, character)
	_expect_guidance_target(layer, "FoundationSiteNorth", "基础地基", "treatment point foundation guidance")
	world.add_base_structure(
		"structure.foundation_site_north",
		"building.foundation_t1",
		"region.pollution_edge",
		"map_object_instance.foundation_site_north"
	)
	world.add_base_structure(
		"structure.foundation_site_south",
		"building.foundation_t1",
		"region.pollution_edge",
		"map_object_instance.foundation_site_south"
	)
	world.quest_state.set_objective_progress("quest.expand_treatment_point", "build", "building.foundation_t1", 1.0)
	map.refresh_world_interactables(world)
	layer.refresh_guidance(world, character)
	_expect_guidance_target(layer, "PollutionFilterBuildSite", "污染过滤器建造点", "treatment point filter build guidance")

	world.add_base_structure(
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.pollution_edge",
		"map_object_instance.pollution_filter_build_site"
	)
	world.quest_state.active_quest_ids = ["quest.enter_pollution_edge"]
	map.refresh_world_interactables(world)
	layer.refresh_guidance(world, character)
	_expect_guidance_target(layer, "OutpostDepartureGate", "外勤出发口", "pollution edge departure guidance")
	map.player.position = Vector2(92.0, -104.0)
	layer.refresh_guidance(world, character)
	_expect_equal(
		String(layer.get_current_target_node().name),
		"OutpostDepartureGate",
		"field position keeps departure gate as logical target"
	)
	_expect_equal(
		layer.is_target_guidance_visible(),
		false,
		"field position hides departure gate scene guidance instead of drawing a long return route"
	)
	_expect_equal(layer.is_local_focus_frame_visible(), false, "field position does not keep a hidden departure focus frame")
	map.player.position = VerticalSliceMap.OUTPOST_RESPAWN_POSITION
	world.quest_state.set_objective_progress("quest.enter_pollution_edge", "visit_region", "region.pollution_edge", 1.0)
	map.refresh_world_interactables(world)
	layer.refresh_guidance(world, character)
	_expect_guidance_target(layer, "PollutionResidue", "污染沉积物", "pollution residue gather guidance")
	map.player.position = Vector2(168.0, 34.0)
	character.position = map.player.position
	character.current_region_id = "region.pollution_edge"
	first_path_layer.refresh_focus_visibility(map.player.position)
	pollution_layer.refresh_focus_visibility(map.player.position)
	layer.refresh_guidance(world, character)
	_expect_guidance_target(layer, "PollutionResidue", "污染沉积物", "pollution boundary compact residue target")
	_expect_equal(first_path_layer.visible, false, "pollution boundary keeps first industrial path out of the treatment frame")
	_expect_equal(layer.is_pollution_compact_guidance_active(), true, "pollution boundary compacts current target guidance")
	_expect_equal(layer.is_target_route_visible(), false, "pollution boundary hides long current target route")
	_expect_equal(layer.is_target_name_label_visible(), false, "pollution boundary hides current target scene label")
	_expect_equal(layer.is_local_focus_frame_visible(), true, "pollution boundary keeps local current target focus frame")
	_expect_equal(layer.get_current_focus_readability_mode(), "pollution", "pollution boundary uses local focus readability mode")
	world.quest_state.set_objective_progress("quest.enter_pollution_edge", "gather_item", "item.polluted_residue", 2.0)
	map.refresh_world_interactables(world)
	layer.refresh_guidance(world, character)
	_expect_guidance_target(layer, "PollutionFilter", "污染过滤器", "pollution filter processing guidance")

	world.current_region_id = "region.demo_stabilization_core"
	world.unlock_region("region.demo_stabilization_core")
	world.quest_state.active_quest_ids = ["quest.write_demo_stabilization_core"]
	world.quest_state.set_objective_progress("quest.write_demo_stabilization_core", "gather_item", "item.core_write_charge", 1.0)
	map.player.position = Vector2(4038.0, -24.0)
	character.position = map.player.position
	character.current_region_id = "region.demo_stabilization_core"
	map.refresh_world_interactables(world)
	layer.refresh_guidance(world, character)
	_expect_guidance_target(layer, "DemoStabilizationCore", "核心写入设备", "core write local guidance")
	_expect_equal(layer.is_core_station_compact_guidance_active(), true, "core station compacts current target guidance")
	_expect_equal(layer.is_target_route_visible(), false, "core station hides long current target route")
	_expect_equal(layer.is_local_focus_frame_visible(), true, "core station keeps local current target focus frame")
	_expect_equal(layer.is_short_focus_tether_visible(), true, "core station uses a short local tether near write device")
	_expect_equal(layer.get_current_focus_readability_mode(), "core_station", "core station uses local focus readability mode")
	map.free()


func _check_startup_readability_scope() -> void:
	var map := _create_setup_map()
	var layer := map.get_node("PrototypeVisualPriorityLayer") as PrototypeVisualPriorityLayer
	var base_layer := map.get_node("DemoIndustrialBaseVisualLayer") as DemoIndustrialBaseVisualLayer
	_expect_equal(layer != null, true, "startup visual priority layer exists")
	if layer != null:
		layer.apply_profile()
		layer.refresh_focus_visibility(map.get_player_position())
		_expect_equal(layer.get_generated_cue_count(), 36, "startup still keeps full visual cue evidence")
		_expect_equal(layer.get_visible_generated_cue_count(), 1, "startup only shows the outpost core cue")
		_expect_equal(
			not _get_region_cue_visible(layer, "region.crystal_vein_field", PrototypeVisualPriorityProfile.ROLE_KEY_OBJECT),
			true,
			"startup hides adjacent crystal cue until the first field step"
		)
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
		layer.refresh_focus_visibility(Vector2(112.0, -112.0))
		_expect_equal(
			layer.get_cue_alpha(
				"region.crystal_vein_field",
				PrototypeVisualPriorityProfile.ROLE_KEY_OBJECT
			) <= 0.05
				and layer.get_cue_alpha(
					"region.crystal_vein_field",
					PrototypeVisualPriorityProfile.ROLE_MAIN_ROUTE
				) <= 0.05
				and layer.get_cue_alpha(
					"region.crystal_vein_field",
					PrototypeVisualPriorityProfile.ROLE_HAZARD_OR_FACILITY
				) <= 0.05,
			true,
			"crystal focus keeps visual priority cues below the resource artwork instead of drawing a blue block"
		)
		layer.refresh_focus_visibility(Vector2(298.0, -72.0))
		_expect_equal(
			layer.get_cue_alpha(
				"region.pollution_edge",
				PrototypeVisualPriorityProfile.ROLE_KEY_OBJECT
			) <= 0.05
				and layer.get_cue_alpha(
					"region.pollution_edge",
					PrototypeVisualPriorityProfile.ROLE_MAIN_ROUTE
				) <= 0.05
				and layer.get_cue_alpha(
					"region.pollution_edge",
					PrototypeVisualPriorityProfile.ROLE_HAZARD_OR_FACILITY
				) <= 0.05,
			true,
			"pollution focus keeps visual priority cues below treatment artwork instead of drawing a yellow block"
		)
	if base_layer != null:
		base_layer.apply_visuals()
		base_layer.refresh_chain_state(WorldState.create_default(), CharacterState.create_default())
		_expect_equal(base_layer.is_startup_restore_focus_active(), true, "startup base visual layer uses the core restore focus view")
		_expect_equal(base_layer.get_startup_restore_shape_count() >= 10, true, "startup base visual layer registers restore focus shapes")
		_expect_equal(base_layer.has_startup_restore_shape("startup_restore.outpost_core_focus"), true, "startup restore view marks the outpost core")
		_expect_equal(base_layer.has_startup_restore_shape("startup_restore.disabled_reactor_silhouette"), true, "startup restore view keeps reactor as a muted silhouette")
		_expect_equal(base_layer.has_startup_restore_shape("startup_restore.low_power_alarm"), true, "startup restore view shows low power alarm evidence")
		_expect_equal(base_layer.has_startup_restore_shape("startup_restore.disabled_supply_bus"), true, "startup restore view shows disabled supply bus evidence")
		_expect_equal(base_layer.has_startup_restore_shape("startup_restore.global_planning_layers_muted"), true, "startup restore view records global planning mute")
		_expect_equal(base_layer.has_startup_restore_shape("startup_restore.local_worksite_buffer"), true, "startup restore view replaces the wide planning rectangle with a local worksite buffer")
		_expect_equal(base_layer.has_startup_restore_shape("startup_restore.soft_context_falloff"), true, "startup restore view softens empty far context")
		_expect_equal(base_layer.get_startup_context_mute_count() >= 20, true, "startup restore view mutes route, region and far context layers")
		var scene_focus_layer := map.get_node("DemoSceneFocusDepthLayer") as DemoSceneFocusDepthLayer
		var crystal_region := map.get_node("RegionCrystal") as ColorRect
		var crystal_boundary := map.get_node("RegionBoundaryCrystal") as ColorRect
		var route_spine := map.get_node("MainRouteSpine") as ColorRect
		var base_to_crystal_route := map.get_node("BaseToCrystalRouteBand") as ColorRect
		if scene_focus_layer != null:
			scene_focus_layer.refresh_focus_depth(map.get_player_position())
		_expect_equal(_is_rect_alpha_at_most(crystal_region, 0.0001), true, "startup restore suppresses the old blue crystal region panel")
		_expect_equal(_is_rect_alpha_at_most(crystal_boundary, 0.0001), true, "startup restore suppresses the vertical crystal boundary frame")
		_expect_equal(_is_rect_alpha_at_most(route_spine, 0.0001), true, "startup restore suppresses the cross-screen main route band")
		_expect_equal(_is_rect_alpha_at_most(base_to_crystal_route, 0.0001), true, "startup restore suppresses the blue route strip")
		var reactor := map.get_node("Interactables/BasicReactor") as PrototypeInteractable
		var storage := map.get_node("Interactables/BasicStorageBuildSite") as PrototypeInteractable
		_expect_equal(reactor.modulate.a <= 0.01, true, "startup mutes reactor interactable marker")
		_expect_equal(storage.modulate.a <= 0.01, true, "startup mutes storage interactable marker")
		var restored_world := WorldState.create_default()
		restored_world.quest_state.complete_quest("quest.restore_outpost")
		base_layer.refresh_chain_state(restored_world, CharacterState.create_default())
		_expect_equal(not base_layer.is_startup_restore_focus_active(), true, "restored base visual layer leaves startup focus")
		_expect_equal(base_layer.has_detail_shape("story.outpost.recovered_power_bus"), true, "base restored view keeps recovered power bus evidence")
		_expect_equal(base_layer.has_detail_shape("story.outpost.reactor_cold_start_marks"), true, "base restored view keeps reactor cold start evidence")
		_expect_equal(base_layer.has_detail_shape("story.outpost.storage_recovery_manifest"), true, "base restored view keeps storage recovery evidence")
		_expect_equal(base_layer.has_detail_shape("first_screen.floor.plate_seams"), true, "base first screen has floor plate seams")
		_expect_equal(base_layer.has_detail_shape("first_screen.floor.local_contact_shadows"), true, "base first screen has local contact shadows")
		_expect_equal(base_layer.has_detail_shape("first_screen.floor.disconnected_bus_scars"), true, "base first screen has disconnected bus scars")
		_expect_equal(base_layer.has_detail_shape("first_screen.device.outpost_core.machine_base"), true, "base first screen gives the core a machine base")
		_expect_equal(base_layer.has_detail_shape("first_screen.device.basic_reactor.feed_hopper"), true, "base first screen gives the reactor a feed hopper")
		_expect_equal(base_layer.has_detail_shape("first_screen.device.basic_storage.cargo_trays"), true, "base first screen gives storage cargo trays")
		_expect_equal(base_layer.has_detail_shape("first_screen.device.field_outfitting_station.suit_frame"), true, "base first screen gives outfitting a suit frame")
		_expect_equal(base_layer.has_detail_shape("first_screen.action_feedback.core_inspection_pulse"), true, "base first screen has core inspection feedback")
		_expect_equal(base_layer.has_detail_shape("first_screen.action_feedback.reactor_port_wake"), true, "base first screen has reactor port feedback")
		_expect_equal(base_layer.has_detail_shape("first_screen.action_feedback.storage_outfitting_handshake"), true, "base first screen has storage to outfitting feedback")
	_check_scene_visual_layer_focus_visibility(map)
	_check_runtime_annotation_hidden(map, "DemoRoutePresentationLayer/DemoRouteBaseLabel")
	_check_runtime_annotation_hidden(map, "SceneArtFoundationLayer/SceneArtBaseIdentityLabel")
	_check_runtime_annotation_hidden(map, "NonCoreSceneIdentityLayer/NonCoreRuinIdentityLabel")
	_check_runtime_annotation_hidden(map, "OpeningSceneLayer/BaseCorePadLabel")
	_check_runtime_annotation_hidden(map, "OpeningSceneLayer/BaseExitLaneLabel")
	_check_runtime_annotation_hidden(map, "BaseDirectionLabel")
	map.free()


func _check_scene_visual_layer_focus_visibility(map: VerticalSliceMap) -> void:
	var crystal_layer := map.get_node("DemoCrystalResourceVisualLayer") as DemoCrystalResourceVisualLayer
	var pollution_layer := map.get_node("DemoPollutionBoundaryVisualLayer") as DemoPollutionBoundaryVisualLayer
	var core_layer := map.get_node("DemoCoreStabilizationVisualLayer") as DemoCoreStabilizationVisualLayer
	var scene_focus_layer := map.get_node("DemoSceneFocusDepthLayer") as DemoSceneFocusDepthLayer
	var crystal_region := map.get_node("RegionCrystal") as ColorRect
	var pollution_region := map.get_node("RegionPollution") as ColorRect
	var crystal_boundary := map.get_node("RegionBoundaryCrystal") as ColorRect
	var pollution_boundary := map.get_node("RegionBoundaryPollution") as ColorRect
	var crystal_to_pollution_route := map.get_node("CrystalToPollutionRouteBand") as ColorRect

	crystal_layer.refresh_focus_visibility(Vector2(-250, -48))
	pollution_layer.refresh_focus_visibility(Vector2(-250, -48))
	core_layer.refresh_focus_visibility(Vector2(-250, -48))
	_expect_equal(crystal_layer.visible, false, "startup hides crystal resource detail layer until field departure")
	_expect_equal(pollution_layer.visible, false, "startup hides pollution treatment detail layer")
	_expect_equal(core_layer.visible, false, "startup hides terminal station detail layer")

	crystal_layer.refresh_focus_visibility(Vector2(-38, -104))
	pollution_layer.refresh_focus_visibility(Vector2(-38, -104))
	_expect_equal(crystal_layer.visible, true, "field departure reveals crystal resource detail layer")
	_expect_equal(pollution_layer.visible, false, "field departure still hides pollution treatment detail layer")

	scene_focus_layer.refresh_focus_depth(Vector2(112, -112))
	crystal_layer.refresh_focus_visibility(Vector2(112, -112))
	pollution_layer.refresh_focus_visibility(Vector2(112, -112))
	_expect_equal(crystal_layer.get_muted_crystal_focus_context_rect_count() >= 12, true, "crystal focus mutes old region panels, routes, and boundary frames")
	_expect_equal(_is_rect_alpha_at_most(crystal_region, 0.003), true, "crystal focus lowers the old blue region panel below the mine face")
	_expect_equal(_is_rect_alpha_at_most(pollution_region, 0.0006), true, "crystal focus suppresses the yellow pollution preview panel")
	_expect_equal(_is_rect_alpha_at_most(crystal_boundary, 0.0006), true, "crystal focus lowers the crystal boundary frame below the ore surface")
	_expect_equal(_is_rect_alpha_at_most(pollution_boundary, 0.0006), true, "crystal focus lowers the pollution boundary frame below the ore surface")
	_expect_equal(_is_rect_alpha_at_most(crystal_to_pollution_route, 0.0005), true, "crystal focus keeps the pollution context route behind local workfaces")

	pollution_layer.refresh_focus_visibility(Vector2(258, 34))
	crystal_layer.refresh_focus_visibility(Vector2(258, 34))
	_expect_equal(pollution_layer.visible, true, "pollution approach reveals treatment boundary detail layer")
	_expect_equal(crystal_layer.visible, false, "pollution approach hides crystal resource detail layer")

	core_layer.refresh_focus_visibility(Vector2(3744, 112))
	_expect_equal(core_layer.visible, true, "terminal approach reveals core stabilization detail layer")


func _check_playable_space_and_actor_silhouettes() -> void:
	var map := _create_setup_map()
	var base_layer := map.get_node("DemoIndustrialBaseVisualLayer") as DemoIndustrialBaseVisualLayer
	base_layer.apply_visuals()
	_expect_equal(base_layer.get_playable_space_shape_count() >= 11, true, "base visual layer registers playable space shapes")
	_expect_equal(base_layer.has_playable_space_shape("space.walkway.core_to_reactor"), true, "base space shows core to reactor walkway")
	_expect_equal(base_layer.has_playable_space_shape("space.walkway.departure_staging_lane"), true, "base space shows departure staging lane")
	_expect_equal(base_layer.has_playable_space_shape("space.device_zone.basic_reactor"), true, "base space shows reactor equipment zone")
	_expect_equal(base_layer.has_playable_space_shape("space.player_start.staging_pad"), true, "base space shows player start staging pad")
	_expect_equal(base_layer.has_playable_space_shape("space.safety_threshold.departure_gate"), true, "base space shows departure safety threshold")

	var player := map.get_node("Player") as PlayerController
	_expect_equal(player.get_visual_part_count() >= 13, true, "player uses multiple readable silhouette parts")
	_expect_equal(player.has_visual_part("suit.helmet"), true, "player silhouette has helmet")
	_expect_equal(player.has_visual_part("suit.visor"), true, "player silhouette has visor")
	_expect_equal(player.has_visual_part("suit.backpack"), true, "player silhouette has backpack")
	_expect_equal(player.has_visual_part("suit.shoulder_plates"), true, "player silhouette has shoulder plates")
	_expect_equal(player.has_visual_part("suit.tool_harness"), true, "player silhouette has tool harness")
	_expect_equal(player.has_visual_part("stance.forward_boot"), true, "player silhouette has a forward stance boot")
	_expect_equal(player.has_visual_part("tool.forward_arm"), true, "player silhouette has forward tool arm")
	_expect_equal(player.has_visual_part("tool.rear_brace"), true, "player silhouette has rear tool brace")
	_expect_equal(player.has_visual_part("tool.cutter_tip"), true, "player silhouette has cutter tip")
	_expect_equal(player.has_visual_part("direction.helmet_beacon"), true, "player silhouette has a helmet beacon")

	var treatment_enemy := map.get_node("Enemies/TreatmentSkitter") as PrototypeEnemy
	var polluted_enemy := map.get_node("Enemies/PollutedSkitter") as PrototypeEnemy
	var elite_enemy := map.get_node("Enemies/EliteResidueNode") as PrototypeEnemy
	_expect_equal(treatment_enemy.get_silhouette_part_count() >= 6, true, "treatment enemy has silhouette parts")
	_expect_equal(treatment_enemy.get_silhouette_profile(), "treatment", "treatment enemy uses treatment silhouette")
	_expect_equal(polluted_enemy.get_silhouette_profile(), "polluted", "polluted enemy uses polluted silhouette")
	_expect_equal(elite_enemy.get_silhouette_profile(), "elite", "elite node uses elite silhouette")
	_expect_equal(polluted_enemy.has_silhouette_part("enemy_shape.pressure_core"), true, "enemy silhouette has pressure core")
	_expect_equal(polluted_enemy.has_silhouette_part("enemy_shape.threat_eye"), true, "enemy silhouette has threat eye")
	map.free()


func _check_key_object_semantic_silhouettes() -> void:
	var map := _create_setup_map()
	var key_objects := [
		{
			"path": "Interactables/OutpostCore",
			"silhouette_id": PrototypeInteractable.SILHOUETTE_OUTPOST_CORE,
			"part": "semantic.outpost_core.status_lights",
			"extra_part": "semantic.outpost_core.machine_base"
		},
		{
			"path": "Interactables/BasicReactor",
			"silhouette_id": PrototypeInteractable.SILHOUETTE_BASIC_REACTOR,
			"part": "semantic.basic_reactor.heat_chamber",
			"extra_part": "semantic.basic_reactor.feed_hopper"
		},
		{
			"path": "Interactables/BasicStorageBuildSite",
			"silhouette_id": PrototypeInteractable.SILHOUETTE_BASIC_STORAGE,
			"part": "semantic.basic_storage.shelf_bins",
			"extra_part": "semantic.basic_storage.cargo_tray"
		},
		{
			"path": "Interactables/FieldOutfittingStation",
			"silhouette_id": PrototypeInteractable.SILHOUETTE_FIELD_OUTFITTING_STATION,
			"part": "semantic.field_outfitting_station.module_rack",
			"extra_part": "semantic.field_outfitting_station.suit_frame"
		},
		{
			"path": "Interactables/PollutionFilter",
			"silhouette_id": PrototypeInteractable.SILHOUETTE_POLLUTION_FILTER,
			"part": "semantic.pollution_filter.twin_columns",
			"extra_part": "semantic.pollution_filter.clean_output"
		},
		{
			"path": "Interactables/CrystalCollectorBuildSite",
			"silhouette_id": PrototypeInteractable.SILHOUETTE_CRYSTAL_COLLECTOR,
			"part": "semantic.crystal_collector.output_tray",
			"extra_part": "semantic.crystal_collector.drill_arm"
		},
		{
			"path": "Interactables/DemoStabilizationCore",
			"silhouette_id": PrototypeInteractable.SILHOUETTE_CORE_WRITE_DEVICE,
			"part": "semantic.core_write_device.write_ring",
			"extra_part": "semantic.core_write_device.verify_panel"
		}
	]
	for object_profile in key_objects:
		var object := map.get_node(String(object_profile["path"])) as PrototypeInteractable
		_expect_equal(
			object.get_semantic_silhouette_id(),
			String(object_profile["silhouette_id"]),
			"%s uses semantic silhouette id" % object_profile["path"]
		)
		_expect_equal(
			object.get_semantic_silhouette_part_count() >= 3,
			true,
			"%s exposes multiple semantic silhouette parts" % object_profile["path"]
		)
		_expect_equal(
			object.has_semantic_silhouette_part(String(object_profile["part"])),
			true,
			"%s exposes role-specific semantic part" % object_profile["path"]
		)
		_expect_equal(
			object.has_semantic_silhouette_part(String(object_profile["extra_part"])),
			true,
			"%s exposes first-screen machine detail part" % object_profile["path"]
		)
	var collector_output := map.get_node("Interactables/CrystalCollectorOutput") as PrototypeInteractable
	_expect_equal(
		collector_output.get_semantic_silhouette_id(),
		PrototypeInteractable.SILHOUETTE_CRYSTAL_COLLECTOR,
		"collector output shares collector semantic silhouette"
	)
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


func _is_rect_alpha_at_most(rect: ColorRect, max_alpha: float) -> bool:
	return rect != null and rect.color.a <= max_alpha + ALPHA_CHECK_EPSILON


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


func _expect_guidance_target(
	layer: CurrentObjectiveGuidanceLayer,
	expected_node_name: String,
	expected_label_text: String,
	context: String
) -> void:
	var target := layer.get_current_target_node()
	_expect_equal(target != null, true, "%s target exists" % context)
	if target != null:
		_expect_equal(String(target.name), expected_node_name, "%s target node" % context)
	_expect_text_contains(layer.get_current_target_label_text(), expected_label_text, "%s target label" % context)
	_expect_equal(layer.is_target_guidance_visible(), true, "%s target guidance visible" % context)


func _mark_map_object_flag(
	world: WorldState,
	instance_id: String,
	definition_id: String,
	flag_name: String,
	value: bool
) -> void:
	world.ensure_map_object(instance_id, definition_id)
	world.set_map_object_flag(instance_id, flag_name, value)


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
