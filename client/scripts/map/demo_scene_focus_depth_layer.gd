extends Node2D
class_name DemoSceneFocusDepthLayer

const NEAR_BASE_REGION_ALPHA := 0.18
const NEAR_EXPEDITION_REGION_ALPHA := 0.045
const DISTANT_REGION_ALPHA := 0.006
const NEAR_BASE_ROUTE_ALPHA := 0.024
const NEAR_EXPEDITION_ROUTE_ALPHA := 0.008
const DISTANT_ROUTE_ALPHA := 0.002
const NEAR_BOUNDARY_ALPHA := 0.22
const DISTANT_BOUNDARY_ALPHA := 0.018
const NEAR_BASE_SCENE_GROUND_ALPHA := 0.18
const NEAR_EXPEDITION_SCENE_GROUND_ALPHA := 0.022
const DISTANT_SCENE_GROUND_ALPHA := 0.003
const REGION_FOCUS_DISTANCE := 160.0
const ROUTE_FOCUS_DISTANCE := 90.0
const BOUNDARY_FOCUS_DISTANCE := 180.0
const SCENE_GROUND_FOCUS_DISTANCE := 90.0

const BASE_REGION_RECT_PATHS := [
	"RegionBase"
]
const EXPEDITION_REGION_RECT_PATHS := [
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
	"RegionDemoStabilizationCore"
]
const BASE_ROUTE_RECT_PATHS := [
	"MainRouteSpine",
	"BaseToCrystalRouteBand",
	"DemoRoutePresentationLayer/DemoRouteBaseBand"
]
const EXPEDITION_ROUTE_RECT_PATHS := [
	"CrystalToPollutionRouteBand",
	"DemoRoutePresentationLayer/DemoRouteCrystalBand",
	"DemoRoutePresentationLayer/DemoRoutePollutionBand",
	"DemoRoutePresentationLayer/DemoRouteRuinBand",
	"DemoRoutePresentationLayer/DemoRouteCoreApproachFlow",
	"DemoRoutePresentationLayer/DemoRouteCoreBand"
]
const BOUNDARY_RECT_PATHS := [
	"RegionBoundaryCrystal",
	"RegionBoundaryPollution",
	"RegionBoundaryRuin"
]
const BASE_SCENE_GROUND_RECT_PATHS := [
	"OpeningSceneLayer/BaseDeckFloor",
	"OpeningSceneLayer/BaseUpperServiceApron",
	"OpeningSceneLayer/BaseCentralWorkYard",
	"OpeningSceneLayer/BaseLowerLogisticsYard",
	"OpeningSceneLayer/BaseDepartureCauseway",
	"OpeningSceneLayer/BaseExitLane"
]
const EXPEDITION_SCENE_GROUND_RECT_PATHS := [
	"OpeningSceneLayer/CrystalEntryGround",
	"OpeningSceneLayer/CrystalNorthRidgeGround",
	"OpeningSceneLayer/CrystalCentralFieldGround",
	"OpeningSceneLayer/CrystalSouthSalvageYard",
	"OpeningSceneLayer/CrystalMainVeinTrack",
	"OpeningSceneLayer/CrystalScrapPocket",
	"OpeningSceneLayer/PollutionConstructionYardGround",
	"OpeningSceneLayer/PollutionEntryPressureGround",
	"OpeningSceneLayer/PollutionDeepResidueField",
	"OpeningSceneLayer/PollutionReturnDrainField",
	"OpeningSceneLayer/PollutionSafeConstructionBelt",
	"OpeningSceneLayer/PollutionDangerField",
	"OpeningSceneLayer/CoreStabilizationArrivalYard",
	"OpeningSceneLayer/CoreStabilizationRecoveryYard",
	"OpeningSceneLayer/CoreStabilizationGuardFieldGround",
	"OpeningSceneLayer/CoreStabilizationWritebackDeck",
	"OpeningSceneLayer/CoreStabilizationRetestYard",
	"OpeningSceneLayer/CoreStabilizationLogisticsRetestYard"
]


func _ready() -> void:
	refresh_focus_depth(_resolve_focus_position())


func _process(_delta: float) -> void:
	refresh_focus_depth(_resolve_focus_position())


func refresh_focus_depth(focus_position: Vector2) -> void:
	_apply_focus_alpha(BASE_REGION_RECT_PATHS, focus_position, REGION_FOCUS_DISTANCE, NEAR_BASE_REGION_ALPHA, DISTANT_REGION_ALPHA)
	_apply_focus_alpha(EXPEDITION_REGION_RECT_PATHS, focus_position, REGION_FOCUS_DISTANCE, NEAR_EXPEDITION_REGION_ALPHA, DISTANT_REGION_ALPHA)
	_apply_focus_alpha(BASE_ROUTE_RECT_PATHS, focus_position, ROUTE_FOCUS_DISTANCE, NEAR_BASE_ROUTE_ALPHA, DISTANT_ROUTE_ALPHA)
	_apply_focus_alpha(EXPEDITION_ROUTE_RECT_PATHS, focus_position, ROUTE_FOCUS_DISTANCE, NEAR_EXPEDITION_ROUTE_ALPHA, DISTANT_ROUTE_ALPHA)
	_apply_focus_alpha(BOUNDARY_RECT_PATHS, focus_position, BOUNDARY_FOCUS_DISTANCE, NEAR_BOUNDARY_ALPHA, DISTANT_BOUNDARY_ALPHA)
	_apply_focus_alpha(
		BASE_SCENE_GROUND_RECT_PATHS,
		focus_position,
		SCENE_GROUND_FOCUS_DISTANCE,
		NEAR_BASE_SCENE_GROUND_ALPHA,
		DISTANT_SCENE_GROUND_ALPHA
	)
	_apply_focus_alpha(
		EXPEDITION_SCENE_GROUND_RECT_PATHS,
		focus_position,
		SCENE_GROUND_FOCUS_DISTANCE,
		NEAR_EXPEDITION_SCENE_GROUND_ALPHA,
		DISTANT_SCENE_GROUND_ALPHA
	)


func get_scene_focus_alpha(rect_path: String) -> float:
	var rect := _get_color_rect(rect_path)
	if rect == null:
		return -1.0
	return rect.color.a


func _apply_focus_alpha(
	rect_paths: Array,
	focus_position: Vector2,
	focus_distance: float,
	near_alpha: float,
	distant_alpha: float
) -> void:
	for rect_path in rect_paths:
		var rect := _get_color_rect(String(rect_path))
		if rect == null:
			continue
		var color := rect.color
		color.a = near_alpha if _is_rect_near_focus(rect, focus_position, focus_distance) else distant_alpha
		rect.color = color


func _resolve_focus_position() -> Vector2:
	var map_root := get_parent()
	if map_root == null:
		return Vector2.ZERO
	var player := map_root.get_node_or_null("Player") as Node2D
	if player == null:
		return Vector2.ZERO
	return player.position


func _get_color_rect(rect_path: String) -> ColorRect:
	var map_root := get_parent()
	if map_root == null:
		return null
	return map_root.get_node_or_null(rect_path) as ColorRect


func _is_rect_near_focus(rect: ColorRect, focus_position: Vector2, focus_distance: float) -> bool:
	var region := Rect2(
		Vector2(rect.offset_left, rect.offset_top),
		Vector2(rect.offset_right - rect.offset_left, rect.offset_bottom - rect.offset_top)
	)
	if region.has_point(focus_position):
		return true
	return _distance_to_rect(region, focus_position) <= focus_distance


func _distance_to_rect(region: Rect2, position: Vector2) -> float:
	var nearest := Vector2(
		clampf(position.x, region.position.x, region.position.x + region.size.x),
		clampf(position.y, region.position.y, region.position.y + region.size.y)
	)
	return nearest.distance_to(position)
