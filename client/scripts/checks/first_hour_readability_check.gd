extends RefCounted

const VerticalSliceMapScene := preload("res://scenes/maps/VerticalSliceMap.tscn")
const PrototypeHudScene := preload("res://scenes/ui/PrototypeHud.tscn")
const CrystalSideRouteCheckScript := preload("res://scripts/checks/crystal_side_route_check.gd")

var host


func _init(check_host) -> void:
	host = check_host


func run() -> void:
	_check_opening_scene_layer()
	_check_general_interaction_prompts()
	_check_interactable_focus_labels()
	_check_enemy_focus_labels()
	_check_core_object_visual_profiles()
	_check_object_feedback_states()
	_check_hud_map_runtime_labels()
	_check_hud_runtime_layout_first_pass()
	_check_core_loop_layout()
	CrystalSideRouteCheckScript.new(host).run(host.root)
	_check_treatment_entry_gather_feedback()
	_check_pollution_pressure_consumption()
	_check_filter_module_combat_pressure()
	_check_outer_ring_ridge_spawn_gate()
	_check_ruin_gate_pressure_gate()


func _check_opening_scene_layer() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	host.root.add_child(map)
	var layer := map.get_node("OpeningSceneLayer") as Node2D
	var base_deck := map.get_node("OpeningSceneLayer/BaseDeckFloor") as ColorRect
	var core_pad := map.get_node("OpeningSceneLayer/BaseCorePad") as ColorRect
	var core_marker := map.get_node("OpeningSceneLayer/BaseCoreObjectMarker") as ColorRect
	var core_to_reactor_flow := map.get_node("OpeningSceneLayer/BaseCoreToReactorFlowLine") as ColorRect
	var reactor_pad := map.get_node("OpeningSceneLayer/BaseReactorPad") as ColorRect
	var reactor_marker := map.get_node("OpeningSceneLayer/BaseReactorObjectMarker") as ColorRect
	var reactor_to_exit_flow := map.get_node("OpeningSceneLayer/BaseReactorToExitFlowLine") as ColorRect
	var outfitting_pad := map.get_node("OpeningSceneLayer/BaseOutfittingPad") as ColorRect
	var outfitting_marker := map.get_node("OpeningSceneLayer/BaseOutfittingObjectMarker") as ColorRect
	var outfitting_to_exit_flow := map.get_node("OpeningSceneLayer/BaseOutfittingToExitFlowLine") as ColorRect
	var supply_pad := map.get_node("OpeningSceneLayer/BaseSupplyPad") as ColorRect
	var supply_rail := map.get_node("OpeningSceneLayer/BaseSupplyObjectRail") as ColorRect
	var supply_return_flow := map.get_node("OpeningSceneLayer/BaseSupplyReturnFlowLine") as ColorRect
	var storage_pad := map.get_node("OpeningSceneLayer/BaseStoragePad") as ColorRect
	var storage_marker := map.get_node("OpeningSceneLayer/BaseStorageObjectMarker") as ColorRect
	var exit_lane := map.get_node("OpeningSceneLayer/BaseExitLane") as ColorRect
	var exit_threshold := map.get_node("OpeningSceneLayer/BaseExitThresholdLine") as ColorRect
	var crystal_entry := map.get_node("OpeningSceneLayer/CrystalEntryGround") as ColorRect
	var crystal_vein_track := map.get_node("OpeningSceneLayer/CrystalMainVeinTrack") as ColorRect
	var crystal_start_anchor := map.get_node("OpeningSceneLayer/CrystalMainVeinStartAnchor") as ColorRect
	var crystal_deep_anchor := map.get_node("OpeningSceneLayer/CrystalMainVeinDeepAnchor") as ColorRect
	var crystal_side_route := map.get_node("OpeningSceneLayer/CrystalSideRouteConnector") as ColorRect
	var crystal_scrap := map.get_node("OpeningSceneLayer/CrystalScrapPocket") as ColorRect
	var crystal_salvage_pocket := map.get_node("OpeningSceneLayer/CrystalSalvageObjectPocket") as ColorRect
	var anomaly_pocket := map.get_node("OpeningSceneLayer/CrystalAnomalyPocketMarker") as ColorRect
	var anomaly_return_anchor := map.get_node("OpeningSceneLayer/CrystalAnomalyReturnAnchor") as ColorRect
	var pollution_safe := map.get_node("OpeningSceneLayer/PollutionSafeConstructionBelt") as ColorRect
	var pollution_construction_band := map.get_node("OpeningSceneLayer/PollutionConstructionObjectBand") as ColorRect
	var foundation_north_marker := map.get_node("OpeningSceneLayer/PollutionFoundationNorthMarker") as ColorRect
	var foundation_south_marker := map.get_node("OpeningSceneLayer/PollutionFoundationSouthMarker") as ColorRect
	var pollution_filter_marker := map.get_node("OpeningSceneLayer/PollutionFilterObjectMarker") as ColorRect
	var pollution_danger := map.get_node("OpeningSceneLayer/PollutionDangerField") as ColorRect
	var pollution_boundary := map.get_node("OpeningSceneLayer/PollutionDangerBoundaryLine") as ColorRect
	var pollution_step := map.get_node("OpeningSceneLayer/PollutionConstructionToDangerStep") as ColorRect
	var pollution_residue_pocket := map.get_node("OpeningSceneLayer/PollutionResidueObjectPocket") as ColorRect
	var pollution_entry_residue_marker := map.get_node("OpeningSceneLayer/PollutionEntryResidueMarker") as ColorRect
	var pollution_entry_pressure_marker := map.get_node("OpeningSceneLayer/PollutionEntryPressureMarker") as ColorRect
	var pollution_pressure_route := map.get_node("OpeningSceneLayer/PollutionPressureRouteLine") as ColorRect
	var pollution_gate_pressure_pocket := map.get_node("OpeningSceneLayer/PollutionGatePressurePocket") as ColorRect
	var pollution_gate_pressure_marker := map.get_node("OpeningSceneLayer/PollutionGatePressureMarker") as ColorRect
	var outpost_core := map.get_node("Interactables/OutpostCore") as PrototypeInteractable
	var basic_reactor := map.get_node("Interactables/BasicReactor") as PrototypeInteractable
	var storage_site := map.get_node("Interactables/BasicStorageBuildSite") as PrototypeInteractable
	var outfitting_site := map.get_node("Interactables/FieldOutfittingStationBuildSite") as PrototypeInteractable
	var outfitting_station := map.get_node("Interactables/FieldOutfittingStation") as PrototypeInteractable
	var supply_choice := map.get_node("Interactables/BaseSupplyChoiceConsole") as PrototypeInteractable
	var crystal_cluster := map.get_node("Interactables/CrystalCluster") as PrototypeInteractable
	var rich_crystal := map.get_node("Interactables/RichCrystalVeinNorth") as PrototypeInteractable
	var field_wreckage := map.get_node("Interactables/FieldWreckageNorth") as PrototypeInteractable
	var anomaly := map.get_node("Interactables/AnomalyCrystal") as PrototypeInteractable
	var rough_ground := map.get_node("Interactables/RoughGroundNorth") as PrototypeInteractable
	var rough_ground_south := map.get_node("Interactables/RoughGroundSouth") as PrototypeInteractable
	var foundation_site := map.get_node("Interactables/FoundationSiteNorth") as PrototypeInteractable
	var foundation_site_south := map.get_node("Interactables/FoundationSiteSouth") as PrototypeInteractable
	var filter_site := map.get_node("Interactables/PollutionFilterBuildSite") as PrototypeInteractable
	var entry_residue := map.get_node("Interactables/PollutionResidue") as PrototypeInteractable
	var pollution_residue := map.get_node("Interactables/PollutionResidueDeep") as PrototypeInteractable
	var polluted_enemy := map.get_node("Enemies/PollutedSkitter") as PrototypeEnemy
	var gate_pressure_enemy := map.get_node("Enemies/PollutedSkitterGatePressure") as PrototypeEnemy
	host._expect_equal(layer != null, true, "opening scene readability layer exists")
	host._expect_equal(
		base_deck.offset_left <= VerticalSliceMap.PLAY_BOUNDS_MIN.x + 24.0
			and base_deck.offset_right < VerticalSliceMap.CRYSTAL_REGION_X,
		true,
		"opening scene base deck fills the starting platform"
	)
	host._expect_equal(
		core_pad.offset_left < reactor_pad.offset_left and reactor_pad.offset_left < exit_lane.offset_left,
		true,
		"opening scene base pads read core to manufacturing to exit"
	)
	host._expect_equal(
		_is_rect_covering_position(storage_pad, storage_site.position)
			and _is_rect_covering_position(storage_marker, storage_site.position)
			and storage_pad.offset_left > core_pad.offset_left
			and storage_pad.offset_right < exit_lane.offset_left,
		true,
		"opening scene base storage extension adds a buildable logistics pad"
	)
	host._expect_equal(
		_is_rect_covering_position(outfitting_pad, outfitting_site.position)
			and _is_rect_covering_position(outfitting_marker, outfitting_station.position)
			and outfitting_pad.offset_left > reactor_pad.offset_left
			and outfitting_pad.offset_right <= exit_lane.offset_right,
		true,
		"opening scene outfitting pad reads as the final preparation stop before departure"
	)
	host._expect_equal(
		_is_rect_covering_position(core_marker, outpost_core.position)
			and _is_rect_covering_position(reactor_marker, basic_reactor.position)
			and _is_rect_covering_position(supply_rail, supply_choice.position),
		true,
		"opening scene object markers align with base interactables"
	)
	host._expect_equal(
		core_to_reactor_flow.offset_left >= core_marker.offset_right
			and core_to_reactor_flow.offset_right <= reactor_marker.offset_left
			and reactor_to_exit_flow.offset_left >= reactor_marker.offset_right
			and reactor_to_exit_flow.offset_right <= exit_lane.offset_left
			and outfitting_to_exit_flow.offset_left >= outfitting_marker.offset_right - 2.0
			and outfitting_to_exit_flow.offset_right <= exit_threshold.offset_left
			and supply_return_flow.offset_top < supply_rail.offset_top,
		true,
		"opening scene base flow lines connect core, reactor, outfitting, return rail and exit"
	)
	host._expect_equal(
		supply_pad.offset_top > reactor_pad.offset_top,
		true,
		"opening scene supply pad sits as a lower return lane"
	)
	host._expect_equal(
		exit_threshold.offset_left >= VerticalSliceMap.CRYSTAL_GATE_RETURN_X
			and exit_threshold.offset_right <= VerticalSliceMap.CRYSTAL_REGION_X,
		true,
		"opening scene exit threshold sits at the crystal route edge"
	)
	host._expect_equal(
		crystal_entry.offset_left >= VerticalSliceMap.CRYSTAL_REGION_X
			and crystal_entry.offset_right <= VerticalSliceMap.POLLUTION_REGION_X,
		true,
		"opening scene crystal entry stays inside crystal region"
	)
	host._expect_equal(
		_is_rect_covering_position(crystal_vein_track, crystal_cluster.position)
			and _is_rect_covering_position(crystal_vein_track, rich_crystal.position),
		true,
		"opening scene crystal vein track covers the first resource route"
	)
	host._expect_equal(
		_is_rect_covering_position(crystal_start_anchor, crystal_cluster.position)
			and _is_rect_covering_position(crystal_deep_anchor, rich_crystal.position)
			and crystal_side_route.offset_top > crystal_vein_track.offset_bottom
			and crystal_side_route.offset_bottom < crystal_scrap.offset_top
			and _is_rect_covering_position(anomaly_return_anchor, anomaly.position),
		true,
		"opening scene crystal anchors distinguish main vein, side route and anomaly return"
	)
	host._expect_equal(
		crystal_scrap.offset_top > crystal_entry.offset_bottom,
		true,
		"opening scene crystal scrap pocket is visually separate from main mining lane"
	)
	host._expect_equal(
		_is_rect_covering_position(crystal_salvage_pocket, field_wreckage.position)
			and _is_rect_covering_position(anomaly_pocket, anomaly.position),
		true,
		"opening scene salvage and anomaly pockets align with side objects"
	)
	host._expect_equal(
		pollution_safe.offset_top < VerticalSliceMap.POLLUTION_DEEP_Y
			and pollution_danger.offset_top >= VerticalSliceMap.POLLUTION_DEEP_Y - 2.0,
		true,
		"opening scene pollution belt separates safe construction from danger field"
	)
	host._expect_equal(
		_is_rect_covering_position(pollution_construction_band, rough_ground.position)
			and _is_rect_covering_position(pollution_construction_band, rough_ground_south.position)
			and _is_rect_covering_position(pollution_filter_marker, filter_site.position),
		true,
		"opening scene construction band aligns with clear and build objects"
	)
	host._expect_equal(
		_is_rect_covering_position(foundation_north_marker, foundation_site.position)
			and _is_rect_covering_position(foundation_south_marker, foundation_site_south.position)
			and foundation_north_marker.offset_right <= pollution_filter_marker.offset_left + 4.0
			and foundation_south_marker.offset_left >= pollution_filter_marker.offset_right - 4.0,
		true,
		"opening scene foundation markers flank the pollution filter build marker"
	)
	host._expect_equal(
		pollution_boundary.offset_top <= VerticalSliceMap.POLLUTION_DEEP_Y
			and pollution_boundary.offset_bottom >= VerticalSliceMap.POLLUTION_DEEP_Y
			and pollution_boundary.offset_left == VerticalSliceMap.POLLUTION_REGION_X,
		true,
		"opening scene danger boundary marks the pollution depth line"
	)
	host._expect_equal(
		pollution_step.offset_top >= pollution_safe.offset_bottom
			and pollution_step.offset_bottom <= pollution_danger.offset_top + 4.0,
		true,
		"opening scene pollution step links safe construction belt to danger field"
	)
	host._expect_equal(
		_is_rect_covering_position(pollution_residue_pocket, pollution_residue.position)
			and pollution_residue_pocket.offset_top > VerticalSliceMap.POLLUTION_DEEP_Y,
		true,
		"opening scene residue pocket stays inside the dangerous pollution field"
	)
	host._expect_equal(
		_is_rect_covering_position(pollution_entry_residue_marker, entry_residue.position)
			and _is_rect_covering_position(pollution_entry_pressure_marker, polluted_enemy.position)
			and _is_rect_covering_position(pollution_gate_pressure_pocket, gate_pressure_enemy.position)
			and _is_rect_covering_position(pollution_gate_pressure_marker, gate_pressure_enemy.position),
		true,
		"opening scene danger markers align with entry residue and pressure enemies"
	)
	host._expect_equal(
		pollution_entry_residue_marker.offset_top > pollution_boundary.offset_bottom
			and pollution_entry_pressure_marker.offset_top > pollution_boundary.offset_bottom
			and pollution_gate_pressure_marker.offset_top > pollution_boundary.offset_bottom
			and pollution_entry_residue_marker.offset_left < pollution_entry_pressure_marker.offset_left
			and pollution_entry_pressure_marker.offset_left < pollution_gate_pressure_marker.offset_left
			and pollution_pressure_route.offset_left >= pollution_entry_residue_marker.offset_right - 2.0
			and pollution_pressure_route.offset_right <= pollution_gate_pressure_marker.offset_left + 12.0,
		true,
		"opening scene danger markers step from residue to first pressure to gate pressure"
	)
	map.free()


func _is_rect_covering_position(rect: ColorRect, position: Vector2) -> bool:
	if rect == null:
		return false
	return (
		rect.offset_left <= position.x
		and rect.offset_right >= position.x
		and rect.offset_top <= position.y
		and rect.offset_bottom >= position.y
	)


func _check_general_interaction_prompts() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	host.root.add_child(map)
	map.setup(host.data_registry)
	var formatter := InteractionPromptFormatter.new(
		host.data_registry,
		ProcessingSystem.new(host.data_registry),
		BuildSystem.new(host.data_registry)
	)
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var crystal := map.get_node("Interactables/CrystalCluster") as PrototypeInteractable
	var wreckage := map.get_node("Interactables/FieldWreckageNorth") as PrototypeInteractable
	var anomaly := map.get_node("Interactables/AnomalyCrystal") as PrototypeInteractable
	var residue := map.get_node("Interactables/PollutionResidue") as PrototypeInteractable
	var crystal_prompt := formatter.format_general_interaction_prompt(crystal, character, world)
	host._expect_text_contains(crystal_prompt, "对象：晶体簇", "first-hour crystal prompt names focused object")
	host._expect_text_contains(crystal_prompt, "用途：采集基础资源", "first-hour crystal prompt explains resource use")
	host._expect_text_contains(crystal_prompt, "产物：晶体矿物 x3", "first-hour crystal prompt lists gathered output")
	host._expect_text_contains(crystal_prompt, "操作：按 E 采集", "first-hour crystal prompt exposes gather action")
	var wreckage_prompt := formatter.format_general_interaction_prompt(wreckage, character, world)
	host._expect_text_contains(wreckage_prompt, "用途：回收残骸材料", "first-hour wreckage prompt explains salvage use")
	host._expect_text_contains(wreckage_prompt, "产物：导电废件 x2", "first-hour wreckage prompt lists salvage output")
	var anomaly_prompt := formatter.format_general_interaction_prompt(anomaly, character, world)
	host._expect_text_contains(anomaly_prompt, "用途：采集异常样本", "first-hour anomaly prompt explains sample use")
	host._expect_text_contains(anomaly_prompt, "样本：异常样本 x1", "first-hour anomaly prompt lists sample result")
	host._expect_text_contains(anomaly_prompt, "操作：按 E 采样", "first-hour anomaly prompt exposes sample action")
	world.add_base_structure(
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.pollution_edge",
		"map_object_instance.pollution_filter_build_site"
	)
	var residue_prompt := formatter.format_general_interaction_prompt(residue, character, world)
	host._expect_text_contains(residue_prompt, "采完沉积物先回处理点过滤器做药剂", "first-hour residue prompt links gather to filter")
	host._expect_text_contains(residue_prompt, "受扰敌人和门前压力点", "first-hour residue prompt links danger markers to pressure cleanup")
	world.quest_state.active_quest_ids = ["quest.enter_pollution_edge"]
	world.quest_state.set_objective_progress("quest.enter_pollution_edge", "gather_item", "item.polluted_residue", 2)
	world.quest_state.set_objective_progress("quest.enter_pollution_edge", "craft_item", "item.resistance_vial_t1", 1)
	var status_presenter := HudStatusPresenter.new()
	var pollution_objective_text := status_presenter.format_objective_text(host.data_registry, world, character)
	host._expect_text_contains(
		pollution_objective_text,
		"链路：处理药剂->带药剂回污染边界->清理受扰敌人/门前压力点",
		"first-hour pollution objective HUD keeps the vial return chain"
	)
	var pollution_base_text := status_presenter.format_vitals_text(host.data_registry, world, character)
	host._expect_text_contains(pollution_base_text, "外出链：带药剂回污染边界", "first-hour base summary points back to field")
	host._expect_text_contains(
		pollution_base_text,
		"补第二批沉积物，再清理受扰敌人和门前压力点",
		"first-hour base summary points to residue and pressure cleanup"
	)
	world.ensure_map_object(crystal.instance_id, crystal.definition_id, "region.crystal_vein_field")
	world.set_map_object_flag(crystal.instance_id, "is_gathered", true)
	host._expect_text_contains(
		formatter.format_general_interaction_prompt(crystal, character, world),
		"状态：已采集",
		"first-hour gathered crystal prompt shows completed state"
	)
	host._expect_text_missing(
		formatter.format_general_interaction_prompt(crystal, character, world),
		"操作：按 E 采集",
		"first-hour gathered crystal prompt hides repeat gather action"
	)
	map.free()


func _check_interactable_focus_labels() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	host.root.add_child(map)
	map.setup(host.data_registry)
	map.refresh_world_interactables(WorldState.create_default())
	var crystal := map.get_node("Interactables/CrystalCluster") as PrototypeInteractable
	var crystal_east := map.get_node("Interactables/CrystalClusterEast") as PrototypeInteractable
	host._expect_equal(crystal.label.visible, false, "first-hour non-current crystal label starts hidden")
	host._expect_equal(crystal.marker.scale, Vector2.ONE, "first-hour non-current crystal marker is not enlarged")

	map.player.position = crystal.position
	map.update_current_interactable()
	host._expect_equal(map.current_interactable, crystal, "first-hour nearest crystal becomes current interactable")
	host._expect_equal(crystal.label.visible, true, "first-hour current crystal label is visible")
	host._expect_equal(crystal.marker.scale, PrototypeInteractable.FOCUSED_MARKER_SCALE, "first-hour current crystal marker is enlarged")
	host._expect_equal(crystal_east.label.visible, false, "first-hour nearby non-current crystal label remains hidden")
	map.free()


func _check_enemy_focus_labels() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	host.root.add_child(map)
	map.setup(host.data_registry)
	var world := WorldState.create_default()
	map.sync_enemy_states(world)
	var enemy := map.get_node("Enemies/NativeSkitter") as PrototypeEnemy
	var patrol := map.get_node("Enemies/NativeSkitterPatrol") as PrototypeEnemy
	var polluted := map.get_node("Enemies/PollutedSkitter") as PrototypeEnemy
	var gate_pressure := map.get_node("Enemies/PollutedSkitterGatePressure") as PrototypeEnemy
	host._expect_equal(enemy.label.visible, false, "first-hour enemy label starts hidden when out of range")

	map.player.position = enemy.position
	map.update_current_interactable()
	host._expect_equal(enemy.label.visible, true, "first-hour nearest attack target label is visible")
	host._expect_equal(enemy.sprite.scale, PrototypeEnemy.FOCUSED_SPRITE_SCALE, "first-hour nearest attack target is enlarged")
	host._expect_equal(patrol.label.visible, false, "first-hour non-current enemy label remains hidden")

	map.player.position = polluted.position
	map.update_current_interactable()
	host._expect_text_contains(polluted.label.text, "入口压力点", "first-hour polluted enemy focus label names entry pressure")

	world.quest_state.active_quest_ids = ["quest.defeat_elite_node"]
	map.sync_enemy_states(world)
	map.player.position = gate_pressure.position
	map.update_current_interactable()
	host._expect_text_contains(gate_pressure.label.text, "门前压力点", "first-hour gate pressure enemy label names ruin-gate pressure")
	host._expect_equal(gate_pressure.label.visible, true, "first-hour gate pressure label is visible when focused")
	map.free()


func _check_core_object_visual_profiles() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	host.root.add_child(map)
	map.setup(host.data_registry)
	var crystal := map.get_node("Interactables/CrystalCluster") as PrototypeInteractable
	var rich_crystal := map.get_node("Interactables/RichCrystalVeinNorth") as PrototypeInteractable
	var wreckage := map.get_node("Interactables/FieldWreckageNorth") as PrototypeInteractable
	var residue := map.get_node("Interactables/PollutionResidue") as PrototypeInteractable
	var rough_ground := map.get_node("Interactables/RoughGroundNorth") as PrototypeInteractable
	var foundation_site := map.get_node("Interactables/FoundationSiteNorth") as PrototypeInteractable
	var filter_site := map.get_node("Interactables/PollutionFilterBuildSite") as PrototypeInteractable
	var storage_site := map.get_node("Interactables/BasicStorageBuildSite") as PrototypeInteractable
	var reactor := map.get_node("Interactables/BasicReactor") as PrototypeInteractable
	var ruin_gate := map.get_node("Interactables/RuinGate") as PrototypeInteractable
	host._expect_equal(crystal.marker.size, Vector2(26.0, 30.0), "object visuals make crystal nodes tall resource markers")
	host._expect_equal(rich_crystal.marker.size, Vector2(34.0, 38.0), "object visuals make rich crystal visibly larger")
	host._expect_equal(wreckage.marker.size, Vector2(34.0, 18.0), "object visuals make wreckage a low salvage marker")
	host._expect_equal(residue.marker.size, Vector2(30.0, 18.0), "object visuals make pollution residue a low hazard marker")
	host._expect_equal(rough_ground.marker.size, Vector2(38.0, 20.0), "object visuals make rough ground a construction blocker marker")
	host._expect_equal(foundation_site.marker.size, Vector2(34.0, 22.0), "object visuals make foundation sites compact build markers")
	host._expect_equal(storage_site.marker.size, Vector2(38.0, 24.0), "object visuals make storage build sites compact logistics markers")
	host._expect_equal(filter_site.marker.size, Vector2(44.0, 28.0), "object visuals make pollution filter build site wider than foundation")
	host._expect_equal(reactor.marker.size, Vector2(40.0, 30.0), "object visuals make base reactor a device marker")
	host._expect_equal(ruin_gate.marker.size, Vector2(24.0, 44.0), "object visuals make ruin gate a vertical exit marker")

	var treatment_enemy := map.get_node("Enemies/TreatmentSkitter") as PrototypeEnemy
	var polluted_enemy := map.get_node("Enemies/PollutedSkitter") as PrototypeEnemy
	var elite_enemy := map.get_node("Enemies/EliteResidueNode") as PrototypeEnemy
	host._expect_equal(treatment_enemy.sprite.size, PrototypeEnemy.TREATMENT_ENEMY_SIZE, "enemy visuals distinguish treatment low-pressure guards")
	host._expect_equal(polluted_enemy.sprite.size, PrototypeEnemy.POLLUTED_ENEMY_SIZE, "enemy visuals distinguish polluted pressure enemies")
	host._expect_equal(elite_enemy.sprite.size, PrototypeEnemy.ELITE_ENEMY_SIZE, "enemy visuals distinguish elite pressure node")
	map.free()


func _check_object_feedback_states() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	host.root.add_child(map)
	map.setup(host.data_registry)
	var formatter := InteractionPromptFormatter.new(
		host.data_registry,
		ProcessingSystem.new(host.data_registry),
		BuildSystem.new(host.data_registry)
	)
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var crystal := map.get_node("Interactables/CrystalCluster") as PrototypeInteractable
	var wreckage := map.get_node("Interactables/FieldWreckageNorth") as PrototypeInteractable
	var anomaly := map.get_node("Interactables/AnomalyCrystal") as PrototypeInteractable
	var residue := map.get_node("Interactables/PollutionResidue") as PrototypeInteractable
	var rough_ground := map.get_node("Interactables/RoughGroundNorth") as PrototypeInteractable
	var foundation_site := map.get_node("Interactables/FoundationSiteNorth") as PrototypeInteractable
	var storage_site := map.get_node("Interactables/BasicStorageBuildSite") as PrototypeInteractable
	var filter_site := map.get_node("Interactables/PollutionFilterBuildSite") as PrototypeInteractable
	var filter_device := map.get_node("Interactables/PollutionFilter") as PrototypeInteractable

	world.ensure_map_object(crystal.instance_id, crystal.definition_id, "region.crystal_vein_field")
	world.set_map_object_flag(crystal.instance_id, "is_gathered", true)
	world.ensure_map_object(wreckage.instance_id, wreckage.definition_id, "region.crystal_vein_field")
	world.set_map_object_flag(wreckage.instance_id, "is_gathered", true)
	world.ensure_map_object(anomaly.instance_id, anomaly.definition_id, "region.crystal_vein_field")
	world.set_map_object_flag(anomaly.instance_id, "is_sampled", true)
	world.ensure_map_object(residue.instance_id, residue.definition_id, "region.pollution_edge")
	world.set_map_object_flag(residue.instance_id, "is_gathered", true)
	world.ensure_map_object(rough_ground.instance_id, rough_ground.definition_id, "region.pollution_edge")
	world.set_map_object_flag(rough_ground.instance_id, "is_cleared", true)
	world.ensure_map_object(foundation_site.instance_id, foundation_site.definition_id, "region.pollution_edge")
	world.set_map_object_flag(foundation_site.instance_id, "is_built", true)
	world.map_objects[foundation_site.instance_id]["built_definition_id"] = "building.foundation_t1"
	world.ensure_map_object(storage_site.instance_id, storage_site.definition_id, "region.outpost_platform")
	world.set_map_object_flag(storage_site.instance_id, "is_built", true)
	world.map_objects[storage_site.instance_id]["built_definition_id"] = "building.basic_storage"
	world.ensure_map_object(filter_site.instance_id, filter_site.definition_id, "region.pollution_edge")
	world.set_map_object_flag(filter_site.instance_id, "is_built", true)
	world.map_objects[filter_site.instance_id]["built_definition_id"] = "building.pollution_filter"
	world.add_base_structure(
		"structure.pollution_filter_build_site",
		"building.pollution_filter",
		"region.pollution_edge",
		filter_site.instance_id
	)
	map.refresh_world_interactables(world)

	host._expect_equal(crystal.marker.color, PrototypeInteractable.GATHERED_CRYSTAL_COLOR, "object feedback darkens gathered crystal")
	host._expect_equal(crystal.marker.size, PrototypeInteractable.GATHERED_CRYSTAL_SIZE, "object feedback flattens gathered crystal")
	host._expect_text_contains(crystal.label.text, "已采集", "object feedback labels gathered crystal")
	host._expect_equal(wreckage.marker.color, PrototypeInteractable.GATHERED_SALVAGE_COLOR, "object feedback recolors salvaged wreckage")
	host._expect_equal(wreckage.marker.size, PrototypeInteractable.GATHERED_SALVAGE_SIZE, "object feedback flattens salvaged wreckage")
	host._expect_text_contains(wreckage.label.text, "已回收", "object feedback labels salvaged wreckage")
	host._expect_equal(anomaly.marker.color, PrototypeInteractable.SAMPLED_ANOMALY_COLOR, "object feedback recolors sampled anomaly")
	host._expect_equal(anomaly.marker.size, PrototypeInteractable.SAMPLED_ANOMALY_SIZE, "object feedback compacts sampled anomaly")
	host._expect_text_contains(anomaly.label.text, "已采样", "object feedback labels sampled anomaly")
	host._expect_equal(residue.marker.color, PrototypeInteractable.GATHERED_RESIDUE_COLOR, "object feedback recolors gathered residue")
	host._expect_equal(residue.marker.size, PrototypeInteractable.GATHERED_RESIDUE_SIZE, "object feedback flattens gathered residue")
	host._expect_text_contains(residue.label.text, "已回收", "object feedback labels gathered residue")
	host._expect_equal(rough_ground.marker.color, PrototypeInteractable.CLEARED_GROUND_COLOR, "object feedback recolors cleared rough ground")
	host._expect_equal(rough_ground.marker.size, PrototypeInteractable.CLEARED_GROUND_SIZE, "object feedback thins cleared rough ground")
	host._expect_text_contains(rough_ground.label.text, "已清理", "object feedback labels cleared rough ground")
	host._expect_equal(foundation_site.marker.color, PrototypeInteractable.BUILT_FOUNDATION_COLOR, "object feedback recolors built foundation")
	host._expect_equal(foundation_site.marker.size, PrototypeInteractable.BUILT_FOUNDATION_SIZE, "object feedback widens built foundation")
	host._expect_text_contains(foundation_site.label.text, "基础地基", "object feedback labels built foundation")
	host._expect_text_contains(foundation_site.label.text, "已铺设", "object feedback labels foundation built state")
	host._expect_equal(storage_site.marker.color, PrototypeInteractable.BUILT_STORAGE_COLOR, "object feedback recolors built storage")
	host._expect_text_contains(storage_site.label.text, "基础储存箱", "object feedback labels built storage")
	host._expect_text_contains(storage_site.label.text, "已接入", "object feedback labels storage benefit")
	host._expect_equal(filter_site.marker.color, PrototypeInteractable.BUILT_FILTER_COLOR, "object feedback marks completed filter build site")
	host._expect_equal(filter_device.visible, true, "object feedback shows pollution filter device after build")
	host._expect_equal(filter_device.monitoring, true, "object feedback enables pollution filter device after build")
	host._expect_equal(filter_device.marker.size, Vector2(48.0, 36.0), "object feedback makes online filter larger than build site")
	host._expect_text_contains(filter_device.label.text, "已上线", "object feedback labels online pollution filter")

	var wreckage_prompt := formatter.format_general_interaction_prompt(wreckage, character, world)
	host._expect_text_contains(wreckage_prompt, "状态：已回收", "object feedback prompt explains salvaged state")
	host._expect_text_missing(wreckage_prompt, "操作：按 E 采集", "object feedback prompt hides salvaged action")
	var anomaly_prompt := formatter.format_general_interaction_prompt(anomaly, character, world)
	host._expect_text_contains(anomaly_prompt, "状态：已采样", "object feedback prompt explains sampled state")
	host._expect_text_missing(anomaly_prompt, "操作：按 E 采样", "object feedback prompt hides sampled action")
	var residue_prompt := formatter.format_general_interaction_prompt(residue, character, world)
	host._expect_text_contains(residue_prompt, "回过滤器处理沉积物", "object feedback prompt links residue to filter")
	var rough_prompt := formatter.format_clear_prompt(rough_ground, character, world)
	host._expect_text_contains(rough_prompt, "状态：已清理", "object feedback clear prompt explains completed ground")
	var foundation_prompt := formatter.format_build_prompt(foundation_site, character, world)
	host._expect_text_contains(foundation_prompt, "状态：已建成", "object feedback build prompt explains completed site")
	host._expect_text_contains(foundation_prompt, "下一个建造点", "object feedback build prompt points to next construction target")
	map.free()


func _check_hud_map_runtime_labels() -> void:
	var hud := PrototypeHudScene.instantiate() as PrototypeHud
	host.root.add_child(hud)
	hud._ensure_runtime_nodes()
	host._expect_equal(
		hud._format_map_marker_runtime_label("基地\n当前\n目标"),
		"基地\n当前 / 目标",
		"first-hour minimap keeps current target state compact"
	)
	host._expect_equal(
		hud._format_map_marker_runtime_label("晶体\n未解锁"),
		"晶体",
		"first-hour minimap hides low-value locked status text"
	)
	hud._set_control_rect(hud.map_panel, Vector2.ZERO, Vector2(560.0, 232.0))
	hud._layout_map_panel_contents()
	host._expect_equal(
		hud.map_marker_labels[0].position.y != hud.map_marker_labels[1].position.y,
		true,
		"first-hour minimap marker labels use staggered lanes"
	)
	hud.free()


func _check_hud_runtime_layout_first_pass() -> void:
	var hud := PrototypeHudScene.instantiate() as PrototypeHud
	host.root.add_child(hud)
	hud._ensure_runtime_nodes()
	hud._layout_runtime_panels(true)
	var viewport_size := hud._get_runtime_viewport_size()
	host._expect_equal(hud.map_panel.size.y <= 190.0, true, "HUD first pass keeps minimap compact")
	host._expect_equal(hud.status_panel.position.y > hud.map_panel.position.y + hud.map_panel.size.y, true, "HUD first pass stacks objective below minimap")
	host._expect_equal(hud.status_panel.position.x <= 20.0, true, "HUD first pass keeps objective on the left edge")
	host._expect_equal(hud.vitals_panel.position.x + hud.vitals_panel.size.x >= viewport_size.x - 20.0, true, "HUD first pass keeps vitals on the right edge")
	host._expect_equal(hud.vitals_panel.size.y <= 184.0, true, "HUD first pass keeps vitals summary compact")
	host._expect_equal(absf(hud.prompt_panel.position.x + hud.prompt_panel.size.x * 0.5 - viewport_size.x * 0.5) <= 1.0, true, "HUD first pass centers interaction prompt")
	host._expect_equal(hud.prompt_panel.size.y <= 144.0, true, "HUD first pass lowers prompt height")
	host._expect_equal(hud.log_panel.size.y >= 96.0, true, "HUD first pass reserves two log rows")
	host._expect_equal(hud.log_panel.size.y <= 120.0, true, "HUD first pass keeps log rail compact")
	host._expect_equal(hud.log_label.size.y >= 60.0, true, "HUD first pass keeps two-row log text visible")
	host._expect_equal(hud.log_panel.position.x + hud.log_panel.size.x < hud.prompt_panel.position.x, true, "HUD first pass keeps log separate from prompt")
	host._expect_equal(_controls_overlap(hud.completion_panel, hud.prompt_panel), false, "HUD first pass keeps quest feedback above prompt")
	host._expect_equal(_controls_overlap(hud.device_panel, hud.evacuation_panel), false, "HUD first pass keeps device panel separate from evacuation feedback")
	host._expect_equal(_controls_overlap(hud.device_panel, hud.supply_feedback_panel), false, "HUD first pass keeps device panel separate from supply feedback")
	hud.free()


func _controls_overlap(a: Control, b: Control) -> bool:
	if a == null or b == null:
		return false
	return Rect2(a.position, a.size).intersects(Rect2(b.position, b.size), false)


func _check_core_loop_layout() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	host.root.add_child(map)
	map.setup(host.data_registry)

	var outpost := map.get_node("Interactables/OutpostCore") as PrototypeInteractable
	var reactor := map.get_node("Interactables/BasicReactor") as PrototypeInteractable
	var base_choice := map.get_node("Interactables/BaseSupplyChoiceConsole") as PrototypeInteractable
	host._expect_equal(
		reactor.position.x > outpost.position.x,
		true,
		"first-hour base reactor sits on the exit side of the outpost core"
	)
	host._expect_equal(
		base_choice.position.x < reactor.position.x,
		true,
		"first-hour late action terminals stay away from the first manufacturing exit"
	)

	var first_crystal := map.get_node("Interactables/CrystalCluster") as PrototypeInteractable
	var side_crystal := map.get_node("Interactables/CrystalClusterSidePocket") as PrototypeInteractable
	var approach_crystal := map.get_node("Interactables/CrystalClusterTreatmentApproach") as PrototypeInteractable
	var south_wreckage := map.get_node("Interactables/FieldWreckageSouthPocket") as PrototypeInteractable
	var gate_cache := map.get_node("Interactables/FieldWreckageGateCache") as PrototypeInteractable
	var approach_wreckage := map.get_node("Interactables/FieldWreckageTreatmentApproach") as PrototypeInteractable
	var return_crystal := map.get_node("Interactables/CrystalClusterFoundationReturn") as PrototypeInteractable
	var return_wreckage := map.get_node("Interactables/FieldWreckageFoundationReturn") as PrototypeInteractable
	var anomaly := map.get_node("Interactables/AnomalyCrystal") as PrototypeInteractable
	var native := map.get_node("Enemies/NativeSkitter") as PrototypeEnemy
	var treatment_skitter := map.get_node("Enemies/TreatmentSkitter") as PrototypeEnemy
	var treatment_skitter_north := map.get_node("Enemies/TreatmentSkitterNorth") as PrototypeEnemy
	var treatment_skitter_return := map.get_node("Enemies/TreatmentSkitterReturn") as PrototypeEnemy
	host._expect_equal(
		first_crystal.position.distance_to(native.position) > 120.0,
		true,
		"first-hour first crystal node starts before the low-pressure combat pocket"
	)
	host._expect_equal(
		side_crystal.position.distance_to(native.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"first-hour side crystal pocket introduces optional low-pressure combat"
	)
	host._expect_equal(
		south_wreckage.position.y > first_crystal.position.y and anomaly.position.y > first_crystal.position.y,
		true,
		"first-hour salvage and anomaly sample line sits off the main crystal route"
	)
	host._expect_equal(
		gate_cache.position.x > south_wreckage.position.x,
		true,
		"first-hour gate cache gives a final scrap pocket before treatment construction"
	)
	host._expect_equal(
		approach_crystal.position.x > gate_cache.position.x and approach_wreckage.position.x > gate_cache.position.x,
		true,
		"first-hour treatment approach adds resource choices after the first salvage pocket"
	)
	host._expect_equal(
		approach_wreckage.position.distance_to(treatment_skitter.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"first-hour treatment approach salvage is tied to the first guarded construction lane"
	)
	host._expect_equal(
		approach_crystal.position.distance_to(treatment_skitter_north.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"first-hour treatment approach crystal is tied to the second guarded construction lane"
	)
	host._expect_equal(
		return_crystal.position.x > approach_crystal.position.x and return_wreckage.position.x > approach_wreckage.position.x,
		true,
		"first-hour treatment entrance adds a final crystal and salvage return pocket"
	)
	host._expect_equal(
		return_crystal.position.y < VerticalSliceMap.POLLUTION_DEEP_Y and return_wreckage.position.y < VerticalSliceMap.POLLUTION_DEEP_Y,
		true,
		"first-hour treatment entrance return pocket stays in the safe construction belt"
	)
	host._expect_equal(
		return_crystal.position.distance_to(treatment_skitter_return.position) <= VerticalSliceMap.ATTACK_RANGE
			and return_wreckage.position.distance_to(treatment_skitter_return.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"first-hour treatment entrance return pocket is tied to a low-pressure guard"
	)

	var rough_ground := map.get_node("Interactables/RoughGroundNorth") as PrototypeInteractable
	var filter_site := map.get_node("Interactables/PollutionFilterBuildSite") as PrototypeInteractable
	var entry_residue := map.get_node("Interactables/PollutionResidue") as PrototypeInteractable
	var outer_residue := map.get_node("Interactables/PollutionResidueOuterPocket") as PrototypeInteractable
	var deep_residue := map.get_node("Interactables/PollutionResidueDeep") as PrototypeInteractable
	var ridge_residue := map.get_node("Interactables/PollutionResidueRidgeCache") as PrototypeInteractable
	var core_buffer_residue := map.get_node("Interactables/CoreBufferResidueCache") as PrototypeInteractable
	var outer_echo_residue := map.get_node("Interactables/OuterRingEchoResidueCache") as PrototypeInteractable
	var signal_echo_cache := map.get_node("Interactables/SignalEchoCache") as PrototypeInteractable
	var polluted := map.get_node("Enemies/PollutedSkitter") as PrototypeEnemy
	var ridge_polluted := map.get_node("Enemies/PollutedSkitterRidge") as PrototypeEnemy
	var core_buffer_polluted := map.get_node("Enemies/CoreBufferPollutedSkitter") as PrototypeEnemy
	var gate_polluted := map.get_node("Enemies/PollutedSkitterGatePressure") as PrototypeEnemy
	var elite := map.get_node("Enemies/EliteResidueNode") as PrototypeEnemy
	var ruin_guard := map.get_node("Enemies/RuinPhaseGuard") as PrototypeEnemy
	var ruin_gate := map.get_node("Interactables/RuinGate") as PrototypeInteractable
	host._expect_equal(
		rough_ground.position.y < VerticalSliceMap.POLLUTION_DEEP_Y and filter_site.position.y < VerticalSliceMap.POLLUTION_DEEP_Y,
		true,
		"first-hour treatment construction stays in the safe northern belt"
	)
	host._expect_equal(
		entry_residue.position.x >= VerticalSliceMap.POLLUTION_REGION_X and entry_residue.position.y >= VerticalSliceMap.POLLUTION_DEEP_Y,
		true,
		"first-hour entry residue sits inside the pollution danger field"
	)
	host._expect_equal(
		entry_residue.position.x < outer_residue.position.x and outer_residue.position.x < deep_residue.position.x,
		true,
		"first-hour pollution residue pockets step from entry to deep risk"
	)
	host._expect_equal(
		polluted.position.distance_to(entry_residue.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"first-hour first pollution residue is guarded by visible pressure"
	)
	host._expect_equal(
		deep_residue.position.distance_to(elite.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"first-hour deep pollution reward sits near the higher-risk elite node"
	)
	host._expect_equal(
		ridge_residue.position.x > outer_residue.position.x and ridge_residue.position.x < ruin_gate.position.x,
		true,
		"first-hour ridge residue gives a risky pickup before the ruin gate"
	)
	host._expect_equal(
		ridge_polluted.position.distance_to(ridge_residue.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"first-hour ridge residue is guarded by visible pollution pressure"
	)
	host._expect_equal(
		core_buffer_residue.position.x > ridge_residue.position.x and core_buffer_residue.position.x < VerticalSliceMap.RUIN_OUTER_RING_X,
		true,
		"core buffer supply residue extends the pollution edge without entering a new region"
	)
	host._expect_equal(
		core_buffer_polluted.position.distance_to(core_buffer_residue.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"core buffer supply residue is guarded by visible pollution pressure"
	)
	host._expect_equal(
		gate_polluted.position.distance_to(ruin_gate.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"first-hour ruin gate has a visible pollution pressure guard"
	)
	host._expect_equal(
		gate_polluted.position.x > outer_residue.position.x and gate_polluted.position.x < ruin_gate.position.x,
		true,
		"first-hour gate pressure sits between residue collection and ruin signal"
	)
	host._expect_equal(
		outer_echo_residue.position.x > signal_echo_cache.position.x,
		true,
		"outer ring echo residue is exposed past the signal echo cache after guard pressure"
	)
	host._expect_equal(
		outer_echo_residue.position.distance_to(ruin_guard.position) <= VerticalSliceMap.ATTACK_RANGE,
		true,
		"outer ring echo residue is tied to the phase guard combat pocket"
	)
	host._expect_equal(
		ruin_gate.position.x > elite.position.x,
		true,
		"first-hour ruin gate remains beyond the elite pollution pressure"
	)
	map.free()


func _check_treatment_entry_gather_feedback() -> void:
	var gather_system := GatherSystem.new(host.data_registry)
	var world := WorldState.create_default()
	var character := CharacterState.create_default()
	var crystal_result := gather_system.interact_with_object(
		"map_object_instance.crystal_cluster_foundation_return",
		"map_object.crystal_cluster",
		"gather",
		character,
		world
	)
	host._expect_text_contains(
		String(crystal_result.get("message", "")),
		"晶体簇已采集",
		"first-hour treatment entrance crystal log names completed state"
	)
	host._expect_text_contains(
		String(crystal_result.get("message", "")),
		"现场保留已采集标记",
		"first-hour treatment entrance crystal log matches visual state"
	)
	host._expect_text_contains(
		String(crystal_result.get("message", "")),
		"回基地加工基础零件或地基材料",
		"first-hour treatment entrance crystal points back to manufacturing"
	)
	var wreckage_result := gather_system.interact_with_object(
		"map_object_instance.field_wreckage_foundation_return",
		"map_object.field_wreckage",
		"gather",
		character,
		world
	)
	host._expect_text_contains(
		String(wreckage_result.get("message", "")),
		"外勤残骸已回收",
		"first-hour treatment entrance salvage log names completed state"
	)
	host._expect_text_contains(
		String(wreckage_result.get("message", "")),
		"现场保留已回收标记",
		"first-hour treatment entrance salvage log matches visual state"
	)
	host._expect_text_contains(
		String(wreckage_result.get("message", "")),
		"若地基或过滤器缺料",
		"first-hour treatment entrance salvage explains construction supply use"
	)


func _check_pollution_pressure_consumption() -> void:
	var gather_system := GatherSystem.new(host.data_registry)
	var no_module_world := WorldState.create_default()
	var no_module_character := CharacterState.create_default()
	var no_module_result := gather_system.interact_with_object(
		"map_object_instance.pollution_residue_ridge_cache",
		"map_object.pollution_residue_patch",
		"gather",
		no_module_character,
		no_module_world
	)
	host._expect_equal(bool(no_module_result.get("success", false)), true, "first-hour ridge residue gather succeeds")
	host._expect_equal(no_module_character.protection, 76.0, "first-hour ridge residue consumes higher unfiltered protection")
	host._expect_text_contains(String(no_module_result.get("message", "")), "污染脊沉积", "first-hour ridge residue explains ridge pressure")

	var module_world := WorldState.create_default()
	var module_character := CharacterState.create_default()
	module_character.equipment["suit_module"] = "equipment.filter_module_t1"
	var module_result := gather_system.interact_with_object(
		"map_object_instance.pollution_residue_ridge_cache",
		"map_object.pollution_residue_patch",
		"gather",
		module_character,
		module_world
	)
	host._expect_equal(bool(module_result.get("success", false)), true, "first-hour filtered ridge residue gather succeeds")
	host._expect_equal(int(roundf(module_character.protection * 10.0)), 844, "first-hour filter module lowers ridge pressure drain")
	host._expect_text_contains(String(module_result.get("message", "")), "过滤模块已降低消耗", "first-hour ridge residue logs filter benefit")

	var echo_world := WorldState.create_default()
	var echo_character := CharacterState.create_default()
	var echo_result := gather_system.interact_with_object(
		"map_object_instance.outer_ring_echo_residue_cache",
		"map_object.pollution_residue_patch",
		"gather",
		echo_character,
		echo_world
	)
	host._expect_equal(bool(echo_result.get("success", false)), true, "outer ring echo residue gather succeeds")
	host._expect_equal(int(roundf(echo_character.protection * 10.0)), 745, "outer ring echo residue adds high pollution pressure")
	host._expect_text_contains(String(echo_result.get("message", "")), "污染回波沉积", "outer ring echo residue explains filter return")


func _check_filter_module_combat_pressure() -> void:
	var map := VerticalSliceMap.new()
	map.data_registry = host.data_registry
	var enemy := PrototypeEnemy.new()
	enemy.definition_id = "enemy.polluted_skitter"
	enemy.display_name = "受扰掠行体"

	var no_module_character := CharacterState.create_default()
	var no_module_message := map._apply_enemy_counterattack(enemy, no_module_character)
	host._expect_equal(no_module_character.health, 94.0, "filter module baseline polluted counter health pressure")
	host._expect_equal(no_module_character.protection, 97.0, "filter module baseline polluted counter protection pressure")
	host._expect_text_contains(no_module_message, "防护 -3", "filter module baseline counter message")

	var module_character := CharacterState.create_default()
	module_character.equipment["suit_module"] = "equipment.filter_module_t1"
	var module_message := map._apply_enemy_counterattack(enemy, module_character)
	host._expect_equal(int(roundf(module_character.health * 10.0)), 949, "filter module buffers polluted counter health pressure")
	host._expect_equal(int(roundf(module_character.protection * 10.0)), 983, "filter module buffers polluted counter protection pressure")
	host._expect_text_contains(module_message, "防护 -1.7", "filter module counter message shows lower protection pressure")

	enemy.instance_id = "enemy_instance.polluted_skitter_ridge"
	var ridge_character := CharacterState.create_default()
	var ridge_message := map._apply_enemy_counterattack(enemy, ridge_character)
	host._expect_equal(int(roundf(ridge_character.health * 10.0)), 928, "ridge polluted guard adds higher health pressure")
	host._expect_equal(int(roundf(ridge_character.protection * 10.0)), 964, "ridge polluted guard adds higher protection pressure")
	host._expect_text_contains(ridge_message, "污染脊守卫压迫更强", "ridge polluted guard counter message explains pressure")
	var ridge_vial_world := WorldState.create_default()
	ridge_vial_world.ensure_enemy(enemy.instance_id, enemy.definition_id, "region.pollution_edge", 30.0)
	var ridge_vial_character := CharacterState.create_default()
	ridge_vial_character.inventory.add_item("item.resistance_vial_t1", 1)
	var ridge_vial_message := map._apply_enemy_counterattack(enemy, ridge_vial_character, ridge_vial_world)
	host._expect_equal(int(ridge_vial_character.inventory.items.get("item.resistance_vial_t1", 0)), 0, "ridge pressure consumes one vial for pressure venting")
	host._expect_equal(int(roundf(ridge_vial_character.health * 10.0)), 968, "ridge pressure vial reduces health pressure")
	host._expect_equal(int(roundf(ridge_vial_character.protection * 10.0)), 984, "ridge pressure vial reduces protection pressure")
	host._expect_equal(bool(ridge_vial_world.get_enemy(enemy.instance_id).get("pressure_vial_used", false)), true, "ridge pressure records vial venting on enemy state")
	host._expect_text_contains(ridge_vial_message, "抗污染药剂已自动接入污染脊排压", "ridge pressure vial message explains preparation benefit")
	ridge_vial_character.inventory.add_item("item.resistance_vial_t1", 1)
	var repeated_ridge_message := map._apply_enemy_counterattack(enemy, ridge_vial_character, ridge_vial_world)
	host._expect_equal(int(ridge_vial_character.inventory.items.get("item.resistance_vial_t1", 0)), 1, "ridge pressure does not consume vial twice on same enemy")
	host._expect_text_contains(repeated_ridge_message, "污染脊守卫压迫更强", "ridge repeated counter returns to regular pressure hint")

	enemy.definition_id = "enemy.ruin_phase_guard"
	enemy.display_name = "相位守卫"
	enemy.instance_id = "enemy_instance.ruin_phase_guard"
	var ruin_guard_character := CharacterState.create_default()
	var ruin_guard_message := map._apply_enemy_counterattack(enemy, ruin_guard_character)
	host._expect_equal(int(roundf(ruin_guard_character.health * 10.0)), 880, "ruin phase guard echo counter adds health pressure")
	host._expect_equal(int(roundf(ruin_guard_character.protection * 10.0)), 940, "ruin phase guard echo counter adds protection pressure")
	host._expect_text_contains(ruin_guard_message, "相位守卫回波夹带污染压力", "ruin phase guard no-module message explains pressure")

	var filtered_ruin_guard_character := CharacterState.create_default()
	filtered_ruin_guard_character.equipment["suit_module"] = "equipment.filter_module_t1"
	var filtered_ruin_guard_message := map._apply_enemy_counterattack(enemy, filtered_ruin_guard_character)
	host._expect_equal(int(roundf(filtered_ruin_guard_character.health * 10.0)), 898, "filter module reduces ruin guard health pressure")
	host._expect_equal(int(roundf(filtered_ruin_guard_character.protection * 10.0)), 967, "filter module reduces ruin guard protection pressure")
	host._expect_text_contains(filtered_ruin_guard_message, "基础过滤模块缓冲了外圈回波反击", "ruin phase guard module message explains combat benefit")

	enemy.definition_id = "enemy.polluted_skitter"
	enemy.display_name = "受扰掠行体"
	enemy.instance_id = "enemy_instance.polluted_skitter_gate_pressure"
	var gate_world := WorldState.create_default()
	gate_world.ensure_enemy(enemy.instance_id, enemy.definition_id, "region.pollution_edge", 30.0)
	var vial_character := CharacterState.create_default()
	vial_character.inventory.add_item("item.resistance_vial_t1", 1)
	var vial_message := map._apply_enemy_counterattack(enemy, vial_character, gate_world)
	host._expect_equal(int(vial_character.inventory.items.get("item.resistance_vial_t1", 0)), 0, "gate pressure consumes one vial for pressure venting")
	host._expect_equal(int(roundf(vial_character.health * 10.0)), 964, "gate pressure vial reduces health pressure")
	host._expect_equal(int(roundf(vial_character.protection * 10.0)), 982, "gate pressure vial reduces protection pressure")
	host._expect_equal(bool(gate_world.get_enemy(enemy.instance_id).get("pressure_vial_used", false)), true, "gate pressure records vial venting on enemy state")
	host._expect_text_contains(vial_message, "抗污染药剂已自动接入门前排压", "gate pressure vial message explains preparation benefit")
	vial_character.inventory.add_item("item.resistance_vial_t1", 1)
	var repeated_message := map._apply_enemy_counterattack(enemy, vial_character, gate_world)
	host._expect_equal(int(vial_character.inventory.items.get("item.resistance_vial_t1", 0)), 1, "gate pressure does not consume vial twice on same enemy")
	host._expect_text_contains(repeated_message, "门前污染压力更高", "gate pressure repeated counter returns to regular pressure hint")

	var no_vial_gate_world := WorldState.create_default()
	no_vial_gate_world.ensure_enemy(enemy.instance_id, enemy.definition_id, "region.pollution_edge", 30.0)
	var no_vial_gate_character := CharacterState.create_default()
	var no_vial_gate_message := map._apply_enemy_counterattack(enemy, no_vial_gate_character, no_vial_gate_world)
	host._expect_equal(int(roundf(no_vial_gate_character.health * 10.0)), 919, "gate pressure without vial keeps full health pressure")
	host._expect_equal(int(roundf(no_vial_gate_character.protection * 10.0)), 960, "gate pressure without vial keeps full protection pressure")
	host._expect_equal(bool(no_vial_gate_world.get_enemy(enemy.instance_id).get("pressure_vial_used", false)), false, "gate pressure without vial does not mark vial usage")
	host._expect_text_contains(no_vial_gate_message, "门前污染压力更高", "gate pressure without vial explains full pressure")

	gate_world.quest_state.active_quest_ids = ["quest.defeat_elite_node"]
	var restored_world := WorldState.from_dict(gate_world.to_dict())
	var restored_map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	host.root.add_child(restored_map)
	restored_map.setup(host.data_registry)
	restored_map.sync_enemy_states(restored_world)
	var restored_gate_enemy := restored_map.get_node("Enemies/PollutedSkitterGatePressure") as PrototypeEnemy
	var restored_character := CharacterState.create_default()
	restored_character.inventory.add_item("item.resistance_vial_t1", 1)
	var restored_message := restored_map._apply_enemy_counterattack(restored_gate_enemy, restored_character, restored_world)
	host._expect_equal(int(restored_character.inventory.items.get("item.resistance_vial_t1", 0)), 1, "restored gate pressure does not consume a second vial")
	host._expect_text_contains(restored_message, "门前污染压力更高", "restored gate pressure keeps used-vial state")
	var restored_meta_character := CharacterState.create_default()
	restored_meta_character.inventory.add_item("item.resistance_vial_t1", 1)
	restored_map._apply_enemy_counterattack(restored_gate_enemy, restored_meta_character)
	host._expect_equal(int(restored_meta_character.inventory.items.get("item.resistance_vial_t1", 0)), 1, "synced gate pressure meta prevents fallback double consumption")
	restored_map.free()

	enemy.instance_id = "enemy_instance.core_buffer_polluted_skitter"
	var core_buffer_world := WorldState.create_default()
	core_buffer_world.ensure_enemy(enemy.instance_id, enemy.definition_id, "region.pollution_edge", 30.0)
	var core_buffer_character := CharacterState.create_default()
	core_buffer_character.inventory.add_item("item.resistance_vial_t1", 1)
	var core_buffer_message := map._apply_enemy_counterattack(enemy, core_buffer_character, core_buffer_world)
	host._expect_equal(int(core_buffer_character.inventory.items.get("item.resistance_vial_t1", 0)), 0, "core buffer pressure consumes one vial for pressure venting")
	host._expect_equal(int(roundf(core_buffer_character.health * 10.0)), 968, "core buffer pressure vial reduces health pressure")
	host._expect_equal(int(roundf(core_buffer_character.protection * 10.0)), 984, "core buffer pressure vial reduces protection pressure")
	host._expect_equal(bool(core_buffer_world.get_enemy(enemy.instance_id).get("pressure_vial_used", false)), true, "core buffer pressure records vial venting on enemy state")
	host._expect_text_contains(core_buffer_message, "抗污染药剂已自动接入补料点排压", "core buffer pressure vial message explains preparation benefit")
	var core_buffer_no_vial_world := WorldState.create_default()
	core_buffer_no_vial_world.ensure_enemy(enemy.instance_id, enemy.definition_id, "region.pollution_edge", 30.0)
	var core_buffer_no_vial_character := CharacterState.create_default()
	var core_buffer_no_vial_message := map._apply_enemy_counterattack(enemy, core_buffer_no_vial_character, core_buffer_no_vial_world)
	host._expect_equal(int(roundf(core_buffer_no_vial_character.health * 10.0)), 928, "core buffer pressure without vial keeps full health pressure")
	host._expect_equal(int(roundf(core_buffer_no_vial_character.protection * 10.0)), 964, "core buffer pressure without vial keeps full protection pressure")
	host._expect_text_contains(core_buffer_no_vial_message, "补料点污染压力更强", "core buffer pressure without vial explains full pressure")
	enemy.free()
	map.free()


func _check_ruin_gate_pressure_gate() -> void:
	var map := VerticalSliceMap.new()
	map.data_registry = host.data_registry
	var gate_world := WorldState.create_default()
	gate_world.quest_state.completed_quest_ids.append("quest.defeat_elite_node")
	gate_world.quest_state.active_quest_ids = ["quest.unlock_ruin_signal"]
	gate_world.ensure_enemy("enemy_instance.polluted_skitter_gate_pressure", "enemy.polluted_skitter", "region.pollution_edge", 30.0)
	var blocked_result := map._inspect_ruin_gate(gate_world)
	host._expect_equal(bool(blocked_result.get("success", true)), false, "first-hour ruin gate blocks while gate pressure enemy is active")
	host._expect_failure_feedback(blocked_result, "门前压力未清", "first-hour ruin gate pressure failure feedback")
	gate_world.update_enemy_health("enemy_instance.polluted_skitter_gate_pressure", 0.0, true)
	var opened_result := map._inspect_ruin_gate(gate_world)
	host._expect_equal(bool(opened_result.get("success", false)), true, "first-hour ruin gate opens after gate pressure enemy is defeated")
	map.free()


func _check_outer_ring_ridge_spawn_gate() -> void:
	var map := VerticalSliceMapScene.instantiate() as VerticalSliceMap
	host.root.add_child(map)
	map.setup(host.data_registry)
	var ridge_residue := map.get_node("Interactables/PollutionResidueRidgeCache") as PrototypeInteractable
	var ridge_enemy := map.get_node("Enemies/PollutedSkitterRidge") as PrototypeEnemy
	var outer_echo_residue := map.get_node("Interactables/OuterRingEchoResidueCache") as PrototypeInteractable
	var core_buffer_residue := map.get_node("Interactables/CoreBufferResidueCache") as PrototypeInteractable
	var core_buffer_enemy := map.get_node("Enemies/CoreBufferPollutedSkitter") as PrototypeEnemy
	var locked_world := WorldState.create_default()
	map.sync_enemy_states(locked_world)
	map.refresh_world_interactables(locked_world)
	host._expect_equal(ridge_residue.can_interact(), false, "outer ring ridge residue is gated before outer ring scouting")
	host._expect_equal(ridge_enemy.can_be_attacked(), false, "outer ring ridge guard is gated before outer ring scouting")
	host._expect_equal(outer_echo_residue.can_interact(), false, "outer ring echo residue is gated before echo salvage")
	host._expect_equal(core_buffer_residue.can_interact(), false, "core buffer supply residue is gated before buffer preparation")
	host._expect_equal(core_buffer_enemy.can_be_attacked(), false, "core buffer supply guard is gated before buffer preparation")

	var scout_world := WorldState.create_default()
	scout_world.quest_state.active_quest_ids = ["quest.scout_ruin_outer_ring"]
	map.sync_enemy_states(scout_world)
	map.refresh_world_interactables(scout_world)
	host._expect_equal(ridge_residue.can_interact(), true, "outer ring ridge residue opens during outer ring scouting")
	host._expect_equal(ridge_enemy.can_be_attacked(), true, "outer ring ridge guard spawns during outer ring scouting")
	host._expect_equal(outer_echo_residue.can_interact(), false, "outer ring echo residue stays gated during outer ring scouting")
	host._expect_equal(core_buffer_residue.can_interact(), false, "core buffer supply residue stays gated during outer ring scouting")

	var echo_world := WorldState.create_default()
	echo_world.quest_state.active_quest_ids = ["quest.salvage_signal_echo"]
	map.sync_enemy_states(echo_world)
	map.refresh_world_interactables(echo_world)
	host._expect_equal(outer_echo_residue.can_interact(), false, "outer ring echo residue stays gated before phase guard defeat")

	var post_guard_world := WorldState.create_default()
	post_guard_world.quest_state.active_quest_ids = ["quest.salvage_signal_echo"]
	post_guard_world.ensure_enemy("enemy_instance.ruin_phase_guard", "enemy.ruin_phase_guard", "region.ruin_outer_ring", 48.0)
	post_guard_world.update_enemy_health("enemy_instance.ruin_phase_guard", 0.0, true)
	map.sync_enemy_states(post_guard_world)
	map.refresh_world_interactables(post_guard_world)
	host._expect_equal(outer_echo_residue.can_interact(), true, "outer ring echo residue opens after phase guard defeat")

	var buffer_world := WorldState.create_default()
	buffer_world.quest_state.active_quest_ids = ["quest.prepare_demo_stabilization_buffer"]
	map.sync_enemy_states(buffer_world)
	map.refresh_world_interactables(buffer_world)
	host._expect_equal(core_buffer_residue.can_interact(), true, "core buffer supply residue opens during buffer preparation")
	host._expect_equal(core_buffer_enemy.can_be_attacked(), true, "core buffer supply guard spawns during buffer preparation")
	map.free()
