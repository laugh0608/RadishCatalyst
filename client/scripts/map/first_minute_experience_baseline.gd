extends RefCounted
class_name FirstMinuteExperienceBaseline

const OUTPOST_CORE_DAMAGED_TEXTURE := preload("res://assets/sprites/demo_presentation_rebuild/outpost_core_damaged.png")
const OUTPOST_CORE_REPAIRED_TEXTURE := preload("res://assets/sprites/demo_presentation_rebuild/outpost_core_repaired.png")
const LEGACY_PRESENTATION_NODE_PATHS := [
	"RegionBase",
	"RegionCrystal",
	"RegionPollution",
	"RegionRuinOuterRing",
	"RegionDeepRuin",
	"RegionInnerPhaseWell",
	"RegionPhaseWellSink",
	"RegionPhaseWellChamber",
	"RegionPhaseWellLoom",
	"RegionPhaseWellFrame",
	"RegionPhaseWellTether",
	"RegionDemoStabilizationCore",
	"MainRouteSpine",
	"BaseToCrystalRouteBand",
	"CrystalToPollutionRouteBand",
	"RegionBoundaryCrystal",
	"RegionBoundaryPollution",
	"RegionBoundaryRuin",
	"DemoRoutePresentationLayer",
	"SceneArtFoundationLayer",
	"NonCoreSceneIdentityLayer",
	"FunctionalTransitionSpatialPlayabilityLayer",
	"MidfieldRoutePlayabilityLayer",
	"WindCorridorTransitionPlayabilityLayer",
	"OpeningSceneLayer",
	"DemoCoreSceneSpaceLayer",
	"DemoInitialArtIdentityLayer",
	"DemoIndustrialBaseVisualLayer",
	"DemoCrystalResourceVisualLayer",
	"DemoPollutionBoundaryVisualLayer",
	"DemoCoreStabilizationVisualLayer",
	"DemoSceneFocusDepthLayer",
	"PrototypeVisualPriorityLayer",
	"DemoRegionIndustrialValueLayer",
	"DemoFirstIndustrialPathVisualLayer",
	"DemoBaseHandoffAssetArtPass",
	"DemoBaseFirstScreenSceneLayer",
	"DemoPlayableSceneRebuildLayer",
	"CurrentObjectiveGuidanceLayer",
	"DemoBaseStartupPresentationLayer",
]
const INTRO_BASE_DEVICE_SPRITE_PATHS := [
	"DemoPresentationFirstScreen/BasicReactor",
	"DemoPresentationFirstScreen/StorageSilos",
	"DemoPresentationFirstScreen/OutfittingWorkbench",
	"DemoPresentationFirstScreen/PipeCoreToReactor",
	"DemoPresentationFirstScreen/PipeReactorCorner",
	"DemoPresentationFirstScreen/PipeStorageOutfitting",
	"DemoPresentationFirstScreen/PipeValve",
]
const INTRO_CRYSTAL_VISUAL_PATHS := [
	"DemoPresentationFieldZones/CrystalGroundTileMap",
	"DemoPresentationFieldZones/CrystalClusterVisualMain",
	"DemoPresentationFieldZones/CrystalClusterVisualEast",
	"DemoPresentationFieldZones/CrystalClusterVisualSouth",
	"DemoPresentationFieldZones/CrystalClusterVisualReserve",
]


func disable_legacy_presentation_nodes(map_root: Node) -> void:
	if map_root == null:
		return
	for node_path in LEGACY_PRESENTATION_NODE_PATHS:
		var node := map_root.get_node_or_null(String(node_path))
		if node == null:
			continue
		if node is CanvasItem:
			(node as CanvasItem).visible = false
		node.set_process(false)
		node.set_physics_process(false)


func apply_scene_visibility(map_root: Node, world_state: WorldState) -> void:
	disable_legacy_presentation_nodes(map_root)
	if map_root == null or world_state == null:
		return
	var outpost_restored := world_state.quest_state.has_completed_quest("quest.restore_outpost")
	var crystal_scout_completed := world_state.quest_state.has_completed_quest("quest.scout_crystal_field")
	var crystal_collector_built := world_state.has_base_structure_definition("building.crystal_collector_t1")
	var pollution_filter_built := world_state.has_base_structure_definition("building.pollution_filter")

	var outpost_core_sprite := map_root.get_node_or_null("DemoPresentationFirstScreen/OutpostCoreDamaged") as Sprite2D
	if outpost_core_sprite != null:
		outpost_core_sprite.texture = OUTPOST_CORE_REPAIRED_TEXTURE if outpost_restored else OUTPOST_CORE_DAMAGED_TEXTURE

	_set_canvas_paths_visible(map_root, INTRO_BASE_DEVICE_SPRITE_PATHS, crystal_scout_completed)
	_set_canvas_paths_visible(map_root, INTRO_CRYSTAL_VISUAL_PATHS, outpost_restored)
	_set_canvas_path_visible(map_root, "DemoPresentationFirstScreen/ResourceCollector", crystal_collector_built)
	_set_canvas_path_visible(map_root, "DemoPresentationFieldZones/CrystalResourceCollectorField", crystal_collector_built)
	_set_canvas_path_visible(map_root, "DemoPresentationFieldZones/CrystalCableSpool", crystal_collector_built)
	_set_canvas_path_visible(map_root, "DemoPresentationFieldZones/CrystalWorkLightPole", crystal_collector_built)
	_set_canvas_path_visible(map_root, "DemoPresentationFirstScreen/PollutionFilterStaged", pollution_filter_built)
	_set_canvas_path_visible(map_root, "DemoPresentationFieldZones/PollutionFilterField", pollution_filter_built)
	_set_canvas_path_visible(map_root, "DemoPresentationFieldZones/PollutionSupplyCrate", pollution_filter_built)


func is_interactable_allowed(interactable: PrototypeInteractable, world_state: WorldState) -> bool:
	if interactable == null or world_state == null:
		return true
	var crystal_scout_completed := world_state.quest_state.has_completed_quest("quest.scout_crystal_field")
	if crystal_scout_completed:
		return true

	var outpost_restored := world_state.quest_state.has_completed_quest("quest.restore_outpost")
	if not outpost_restored:
		return interactable.name == "OutpostCore"

	if interactable.name == "OutpostCore":
		return false
	if interactable.definition_id == "map_object.crystal_cluster":
		return interactable.position.x <= 230.0
	if interactable.definition_id == "map_object.field_wreckage":
		return interactable.position.x <= 240.0 and interactable.position.y >= 40.0
	return false


func _set_canvas_paths_visible(map_root: Node, node_paths: Array, should_show: bool) -> void:
	for node_path in node_paths:
		_set_canvas_path_visible(map_root, String(node_path), should_show)


func _set_canvas_path_visible(map_root: Node, node_path: String, should_show: bool) -> void:
	var item := map_root.get_node_or_null(node_path) as CanvasItem
	if item == null:
		return
	item.visible = should_show
