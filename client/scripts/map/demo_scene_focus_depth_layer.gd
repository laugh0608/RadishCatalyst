extends Node2D
class_name DemoSceneFocusDepthLayer

const NEAR_BASE_REGION_ALPHA := 0.18
const NEAR_EXPEDITION_REGION_ALPHA := 0.016
const DISTANT_REGION_ALPHA := 0.006
const NEAR_BASE_ROUTE_ALPHA := 0.024
const NEAR_EXPEDITION_ROUTE_ALPHA := 0.0025
const DISTANT_ROUTE_ALPHA := 0.001
const NEAR_BOUNDARY_ALPHA := 0.22
const DISTANT_BOUNDARY_ALPHA := 0.018
const NEAR_BASE_SCENE_GROUND_ALPHA := 0.18
const NEAR_EXPEDITION_SCENE_GROUND_ALPHA := 0.0035
const DISTANT_SCENE_GROUND_ALPHA := 0.0015
const POLLUTION_FOCUS_MIN_X := 180.0
const CRYSTAL_CARRYOVER_SCENE_GROUND_ALPHA := 0.001
const CRYSTAL_CARRYOVER_ROUTE_ALPHA := 0.0005
const POLLUTION_CARRYOVER_BASE_ROUTE_ALPHA := 0.0005
const CRYSTAL_FOCUS_REGION_ALPHA := 0.006
const CRYSTAL_FOCUS_MIN_X := -80.0
const CRYSTAL_FOCUS_MAX_X := 220.0
const REGION_FOCUS_DISTANCE := 160.0
const ROUTE_FOCUS_DISTANCE := 70.0
const BOUNDARY_FOCUS_DISTANCE := 180.0
const SCENE_GROUND_FOCUS_DISTANCE := 70.0
const STARTUP_CORE_FOCUS_MAX_X := -140.0
const STARTUP_BASE_REGION_ALPHA := 0.004
const STARTUP_BASE_SCENE_GROUND_ALPHA := 0.006
const STARTUP_CONTEXT_ALPHA := 0.0

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
const CRYSTAL_ROUTE_RECT_PATHS := [
	"CrystalToPollutionRouteBand",
	"DemoRoutePresentationLayer/DemoRouteCrystalBand"
]
const POLLUTION_CARRYOVER_BASE_ROUTE_RECT_PATHS := [
	"MainRouteSpine",
	"BaseToCrystalRouteBand"
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
const CRYSTAL_SCENE_GROUND_RECT_PATHS := [
	"OpeningSceneLayer/CrystalEntryGround",
	"OpeningSceneLayer/CrystalNorthRidgeGround",
	"OpeningSceneLayer/CrystalCentralFieldGround",
	"OpeningSceneLayer/CrystalSouthSalvageYard",
	"OpeningSceneLayer/CrystalMainVeinTrack",
	"OpeningSceneLayer/CrystalScrapPocket"
]


func _ready() -> void:
	refresh_focus_depth(_resolve_focus_position())


func _process(_delta: float) -> void:
	refresh_focus_depth(_resolve_focus_position())


func refresh_focus_depth(focus_position: Vector2) -> void:
	if _is_startup_restore_focus_active(focus_position):
		_apply_startup_restore_focus_alpha()
		return
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
	if focus_position.x >= POLLUTION_FOCUS_MIN_X:
		_apply_constant_alpha(CRYSTAL_ROUTE_RECT_PATHS, CRYSTAL_CARRYOVER_ROUTE_ALPHA)
		_apply_constant_alpha(POLLUTION_CARRYOVER_BASE_ROUTE_RECT_PATHS, POLLUTION_CARRYOVER_BASE_ROUTE_ALPHA)
		_apply_constant_alpha(CRYSTAL_SCENE_GROUND_RECT_PATHS, CRYSTAL_CARRYOVER_SCENE_GROUND_ALPHA)
	elif focus_position.x >= CRYSTAL_FOCUS_MIN_X and focus_position.x <= CRYSTAL_FOCUS_MAX_X:
		_apply_constant_alpha(["RegionCrystal"], CRYSTAL_FOCUS_REGION_ALPHA)


func get_scene_focus_alpha(rect_path: String) -> float:
	var rect := _get_color_rect(rect_path)
	if rect == null:
		return -1.0
	return rect.color.a


func _apply_startup_restore_focus_alpha() -> void:
	_apply_constant_alpha(BASE_REGION_RECT_PATHS, STARTUP_BASE_REGION_ALPHA)
	_apply_constant_alpha(EXPEDITION_REGION_RECT_PATHS, STARTUP_CONTEXT_ALPHA)
	_apply_constant_alpha(BASE_ROUTE_RECT_PATHS, STARTUP_CONTEXT_ALPHA)
	_apply_constant_alpha(EXPEDITION_ROUTE_RECT_PATHS, STARTUP_CONTEXT_ALPHA)
	_apply_constant_alpha(BOUNDARY_RECT_PATHS, STARTUP_CONTEXT_ALPHA)
	_apply_constant_alpha(BASE_SCENE_GROUND_RECT_PATHS, STARTUP_BASE_SCENE_GROUND_ALPHA)
	_apply_constant_alpha(EXPEDITION_SCENE_GROUND_RECT_PATHS, STARTUP_CONTEXT_ALPHA)


func _is_startup_restore_focus_active(focus_position: Vector2) -> bool:
	if focus_position.x > STARTUP_CORE_FOCUS_MAX_X:
		return false
	var map_root := get_parent()
	if map_root == null:
		return true
	var base_layer := map_root.get_node_or_null("DemoIndustrialBaseVisualLayer") as DemoIndustrialBaseVisualLayer
	if base_layer == null:
		return true
	return base_layer.is_startup_restore_focus_active()


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


func _apply_constant_alpha(rect_paths: Array, alpha: float) -> void:
	for rect_path in rect_paths:
		var rect := _get_color_rect(String(rect_path))
		if rect == null:
			continue
		var color := rect.color
		color.a = alpha
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
