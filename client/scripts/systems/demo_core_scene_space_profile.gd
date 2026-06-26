extends RefCounted
class_name DemoCoreSceneSpaceProfile

const ROLE_GROUND := "ground"
const ROLE_ROUTE := "route"
const ROLE_OBJECT_ANCHOR := "object_anchor"
const ROLE_PRESSURE := "pressure"
const ROLE_RETURN := "return"

const CORE_REGION_IDS := [
	"region.outpost_platform",
	"region.crystal_vein_field",
	"region.pollution_edge",
	"region.demo_stabilization_core"
]

const REQUIRED_REGION_KEYS := [
	"title",
	"material",
	"surface_frame_color",
	"role_tints",
	"ground_nodes",
	"route_nodes",
	"object_anchor_nodes",
	"pressure_nodes",
	"return_nodes",
	"primary_object_nodes",
	"primary_enemy_nodes"
]

const REQUIRED_ROLES := [
	ROLE_GROUND,
	ROLE_ROUTE,
	ROLE_OBJECT_ANCHOR,
	ROLE_PRESSURE,
	ROLE_RETURN
]

const ROLE_NODE_KEYS := {
	ROLE_GROUND: "ground_nodes",
	ROLE_ROUTE: "route_nodes",
	ROLE_OBJECT_ANCHOR: "object_anchor_nodes",
	ROLE_PRESSURE: "pressure_nodes",
	ROLE_RETURN: "return_nodes"
}

const REGION_PROFILES := {
	"region.outpost_platform": {
		"title": "前哨平台空间读法",
		"material": "alloy_deck",
		"surface_frame_color": Color(0.34, 0.72, 0.68, 0.42),
		"role_tints": {
			ROLE_GROUND: Color(0.11, 0.24, 0.25, 1.0),
			ROLE_ROUTE: Color(0.28, 0.58, 0.52, 1.0),
			ROLE_OBJECT_ANCHOR: Color(0.56, 0.78, 0.72, 1.0),
			ROLE_PRESSURE: Color(0.78, 0.63, 0.3, 1.0),
			ROLE_RETURN: Color(0.36, 0.66, 0.62, 1.0)
		},
		"ground_nodes": [
			"OpeningSceneLayer/BaseDeckFloor",
			"OpeningSceneLayer/BaseUpperServiceApron",
			"OpeningSceneLayer/BaseCentralWorkYard",
			"OpeningSceneLayer/BaseLowerLogisticsYard",
			"OpeningSceneLayer/BaseDepartureCauseway"
		],
		"route_nodes": [
			"OpeningSceneLayer/BaseCoreToReactorFlowLine",
			"OpeningSceneLayer/BaseReactorToExitFlowLine",
			"OpeningSceneLayer/BaseOutfittingToExitFlowLine",
			"OpeningSceneLayer/BaseLogisticsRouteFlowLine",
			"OpeningSceneLayer/BaseExitThresholdLine"
		],
		"object_anchor_nodes": [
			"OpeningSceneLayer/BaseCorePad",
			"OpeningSceneLayer/BaseReactorPad",
			"OpeningSceneLayer/BaseOutfittingPad",
			"OpeningSceneLayer/BaseSupplyPad",
			"OpeningSceneLayer/BaseStoragePad",
			"OpeningSceneLayer/BaseSlurryBufferPad",
			"OpeningSceneLayer/BaseLogisticsRouteSignPad"
		],
		"pressure_nodes": [
			"OpeningSceneLayer/BaseExitLane",
			"OpeningSceneLayer/BaseExitThresholdLine",
			"OpeningSceneLayer/BaseLogisticsShelf"
		],
		"return_nodes": [
			"OpeningSceneLayer/BaseSupplyPad",
			"OpeningSceneLayer/BaseSupplyObjectRail",
			"OpeningSceneLayer/BaseSupplyReturnFlowLine",
			"OpeningSceneLayer/BaseSlurryBufferFlowLine"
		],
		"primary_object_nodes": [
			"Interactables/OutpostCore",
			"Interactables/BasicReactor",
			"Interactables/FieldOutfittingStation",
			"Interactables/OutpostDepartureGate"
		],
		"primary_enemy_nodes": []
	},
	"region.crystal_vein_field": {
		"title": "晶体矿脉空间读法",
		"material": "crystal_vein",
		"surface_frame_color": Color(0.4, 0.72, 0.98, 0.42),
		"role_tints": {
			ROLE_GROUND: Color(0.09, 0.18, 0.31, 1.0),
			ROLE_ROUTE: Color(0.2, 0.52, 0.82, 1.0),
			ROLE_OBJECT_ANCHOR: Color(0.54, 0.82, 1.0, 1.0),
			ROLE_PRESSURE: Color(0.88, 0.34, 0.28, 1.0),
			ROLE_RETURN: Color(0.32, 0.58, 0.72, 1.0)
		},
		"ground_nodes": [
			"OpeningSceneLayer/CrystalEntryGround",
			"OpeningSceneLayer/CrystalNorthRidgeGround",
			"OpeningSceneLayer/CrystalCentralFieldGround",
			"OpeningSceneLayer/CrystalSouthSalvageYard"
		],
		"route_nodes": [
			"OpeningSceneLayer/CrystalMainVeinTrack",
			"OpeningSceneLayer/CrystalSideRouteConnector",
			"OpeningSceneLayer/CrystalLogisticsSpurLine",
			"OpeningSceneLayer/CrystalLogisticsReturnLine"
		],
		"object_anchor_nodes": [
			"OpeningSceneLayer/CrystalMainVeinStartAnchor",
			"OpeningSceneLayer/CrystalMainVeinDeepAnchor",
			"OpeningSceneLayer/CrystalSalvageObjectPocket",
			"OpeningSceneLayer/CrystalLogisticsResourcePocket",
			"OpeningSceneLayer/CrystalAnomalyPocketMarker"
		],
		"pressure_nodes": [
			"OpeningSceneLayer/CrystalLogisticsGuardMarker",
			"OpeningSceneLayer/CrystalLogisticsReturnGuardMarker",
			"OpeningSceneLayer/CrystalAnomalyPocketMarker"
		],
		"return_nodes": [
			"OpeningSceneLayer/CrystalScrapPocket",
			"OpeningSceneLayer/CrystalLogisticsReturnLine",
			"OpeningSceneLayer/CrystalLogisticsReturnPocket"
		],
		"primary_object_nodes": [
			"Interactables/CrystalCluster",
			"Interactables/CrystalClusterEast",
			"Interactables/FieldWreckageNorth",
			"Interactables/AnomalyCrystal"
		],
		"primary_enemy_nodes": [
			"Enemies/NativeSkitter",
			"Enemies/NativeSkitterPatrol",
			"Enemies/NativeSkitterLogisticsGuard"
		]
	},
	"region.pollution_edge": {
		"title": "污染边界空间读法",
		"material": "pollution_sludge",
		"surface_frame_color": Color(0.9, 0.72, 0.25, 0.42),
		"role_tints": {
			ROLE_GROUND: Color(0.24, 0.24, 0.1, 1.0),
			ROLE_ROUTE: Color(0.74, 0.58, 0.2, 1.0),
			ROLE_OBJECT_ANCHOR: Color(0.55, 0.62, 0.32, 1.0),
			ROLE_PRESSURE: Color(0.88, 0.36, 0.14, 1.0),
			ROLE_RETURN: Color(0.54, 0.38, 0.12, 1.0)
		},
		"ground_nodes": [
			"OpeningSceneLayer/PollutionConstructionYardGround",
			"OpeningSceneLayer/PollutionEntryPressureGround",
			"OpeningSceneLayer/PollutionDeepResidueField",
			"OpeningSceneLayer/PollutionReturnDrainField"
		],
		"route_nodes": [
			"OpeningSceneLayer/PollutionSafeConstructionBelt",
			"OpeningSceneLayer/PollutionConstructionToDangerStep",
			"OpeningSceneLayer/PollutionPressureRouteLine",
			"OpeningSceneLayer/PollutionCoreArchiveRouteLine"
		],
		"object_anchor_nodes": [
			"OpeningSceneLayer/PollutionConstructionObjectBand",
			"OpeningSceneLayer/PollutionFoundationNorthMarker",
			"OpeningSceneLayer/PollutionFoundationSouthMarker",
			"OpeningSceneLayer/PollutionFilterObjectMarker",
			"OpeningSceneLayer/PollutionResidueObjectPocket"
		],
		"pressure_nodes": [
			"OpeningSceneLayer/PollutionDangerField",
			"OpeningSceneLayer/PollutionDangerBoundaryLine",
			"OpeningSceneLayer/PollutionGatePressurePocket",
			"OpeningSceneLayer/PollutionGatePressureMarker"
		],
		"return_nodes": [
			"OpeningSceneLayer/PollutionVialReturnPocket",
			"OpeningSceneLayer/PollutionSlurryReturnPocket",
			"OpeningSceneLayer/PollutionCoreArchiveReturnPocket",
			"OpeningSceneLayer/PollutionLogisticsMaintenanceRetestPocket"
		],
		"primary_object_nodes": [
			"Interactables/PollutionResidue",
			"Interactables/RoughGroundNorth",
			"Interactables/FoundationSiteNorth",
			"Interactables/PollutionFilter"
		],
		"primary_enemy_nodes": [
			"Enemies/TreatmentSkitterNorth",
			"Enemies/PollutedSkitter",
			"Enemies/PollutedSkitterGatePressure"
		]
	},
	"region.demo_stabilization_core": {
		"title": "核心稳定站空间读法",
		"material": "stabilization_core",
		"surface_frame_color": Color(0.46, 0.96, 0.86, 0.44),
		"role_tints": {
			ROLE_GROUND: Color(0.12, 0.28, 0.27, 1.0),
			ROLE_ROUTE: Color(0.34, 0.7, 0.62, 1.0),
			ROLE_OBJECT_ANCHOR: Color(0.52, 0.86, 0.74, 1.0),
			ROLE_PRESSURE: Color(0.9, 0.34, 0.2, 1.0),
			ROLE_RETURN: Color(0.34, 0.56, 0.5, 1.0)
		},
		"ground_nodes": [
			"OpeningSceneLayer/CoreStabilizationArrivalYard",
			"OpeningSceneLayer/CoreStabilizationRecoveryYard",
			"OpeningSceneLayer/CoreStabilizationGuardFieldGround",
			"OpeningSceneLayer/CoreStabilizationWritebackDeck",
			"OpeningSceneLayer/CoreStabilizationRetestYard",
			"OpeningSceneLayer/CoreStabilizationLogisticsRetestYard"
		],
		"route_nodes": [
			"OpeningSceneLayer/CoreStabilizationApproachLane",
			"OpeningSceneLayer/CoreStabilizationWritebackLine",
			"OpeningSceneLayer/CoreStabilizationRetestLine",
			"OpeningSceneLayer/CoreStabilizationLogisticsRetestLine"
		],
		"object_anchor_nodes": [
			"OpeningSceneLayer/CoreStabilizationRecoveryPocket",
			"OpeningSceneLayer/CoreStabilizationGuardPressureZone",
			"OpeningSceneLayer/CoreStabilizationCorePad",
			"OpeningSceneLayer/CoreStabilizationRetestPocket",
			"OpeningSceneLayer/CoreStabilizationLogisticsRetestPocket"
		],
		"pressure_nodes": [
			"OpeningSceneLayer/CoreStabilizationGuardFieldGround",
			"OpeningSceneLayer/CoreStabilizationGuardPressureZone",
			"OpeningSceneLayer/CoreStabilizationLogisticsRetestGuardMarker"
		],
		"return_nodes": [
			"OpeningSceneLayer/CoreStabilizationRecoveryYard",
			"OpeningSceneLayer/CoreStabilizationRecoveryPocket",
			"OpeningSceneLayer/CoreStabilizationRetestPocket",
			"OpeningSceneLayer/CoreStabilizationLogisticsRetestPocket"
		],
		"primary_object_nodes": [
			"Interactables/DemoStabilizationCore",
			"Interactables/DemoStabilizationRecoveryCache",
			"Interactables/DemoStabilizationGuardCache",
			"Interactables/DemoStabilizationRetestReadoutCache",
			"Interactables/PollutionResidueLogisticsMaintenanceRetestCache"
		],
		"primary_enemy_nodes": [
			"Enemies/DemoStabilizationGuard",
			"Enemies/PollutedSkitterLogisticsMaintenanceRetestGuard"
		]
	}
}


static func get_region_ids() -> Array:
	return CORE_REGION_IDS.duplicate()


static func get_region_profile(region_id: String) -> Dictionary:
	var profile: Dictionary = REGION_PROFILES.get(region_id, {})
	return profile.duplicate(true)


static func get_required_region_keys() -> Array:
	return REQUIRED_REGION_KEYS.duplicate()


static func get_required_roles() -> Array:
	return REQUIRED_ROLES.duplicate()


static func get_node_paths_for_role(region_id: String, role: String) -> Array:
	var profile := get_region_profile(region_id)
	var key := String(ROLE_NODE_KEYS.get(role, ""))
	if key.is_empty():
		return []
	var nodes: Array = profile.get(key, [])
	return nodes.duplicate()


static func get_primary_object_paths(region_id: String) -> Array:
	var profile := get_region_profile(region_id)
	var nodes: Array = profile.get("primary_object_nodes", [])
	return nodes.duplicate()


static func get_primary_enemy_paths(region_id: String) -> Array:
	var profile := get_region_profile(region_id)
	var nodes: Array = profile.get("primary_enemy_nodes", [])
	return nodes.duplicate()


static func get_all_scene_node_paths(region_id: String) -> Array:
	var paths: Array = []
	for role in REQUIRED_ROLES:
		for path in get_node_paths_for_role(region_id, String(role)):
			if not paths.has(path):
				paths.append(path)
	return paths
