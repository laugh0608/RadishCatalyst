extends RefCounted
class_name PrototypeVisualPriorityProfile

const ROLE_MAIN_ROUTE := "main_route"
const ROLE_KEY_OBJECT := "key_object"
const ROLE_HAZARD_OR_FACILITY := "hazard_or_facility"

const STATE_AVAILABLE := "available"
const STATE_PROCESSED := "processed"
const STATE_MISSING_PREREQUISITE := "missing_prerequisite"
const STATE_DANGER_ACTIVE := "danger_active"
const STATE_DEVICE_READY := "device_ready"
const STATE_DEVICE_BUSY := "device_busy"
const STATE_CORE_WRITE_BLOCKED := "core_write_blocked"

const REQUIRED_REGION_KEYS := [
	"cue_name",
	"title",
	"background_path",
	"main_route_rect",
	"key_object_path",
	"key_object_rect",
	"hazard_or_facility_path",
	"hazard_or_facility_rect",
	"background_color",
	"main_route_color",
	"key_object_color",
	"hazard_or_facility_color"
]

const REQUIRED_STATE_IDS := [
	STATE_AVAILABLE,
	STATE_PROCESSED,
	STATE_MISSING_PREREQUISITE,
	STATE_DANGER_ACTIVE,
	STATE_DEVICE_READY,
	STATE_DEVICE_BUSY,
	STATE_CORE_WRITE_BLOCKED
]

const REGION_IDS := [
	"region.outpost_platform",
	"region.crystal_vein_field",
	"region.pollution_edge",
	"region.ruin_outer_ring",
	"region.deep_ruin_threshold",
	"region.inner_phase_well",
	"region.phase_well_sink",
	"region.phase_well_chamber",
	"region.phase_well_loom",
	"region.phase_well_frame",
	"region.phase_well_tether",
	"region.demo_stabilization_core"
]

const ROLE_CUE_SUFFIXES := {
	ROLE_MAIN_ROUTE: "Route",
	ROLE_KEY_OBJECT: "KeyObject",
	ROLE_HAZARD_OR_FACILITY: "HazardFacility"
}

const REGION_PROFILES := {
	"region.outpost_platform": {
		"cue_name": "OutpostPlatform",
		"title": "前哨平台视觉优先级",
		"background_path": "RegionBase",
		"main_route_rect": Rect2(Vector2(-326.0, -52.0), Vector2(288.0, 14.0)),
		"key_object_path": "Interactables/OutpostCore",
		"key_object_rect": Rect2(Vector2(-324.0, -116.0), Vector2(50.0, 50.0)),
		"hazard_or_facility_path": "Interactables/BasicReactor",
		"hazard_or_facility_rect": Rect2(Vector2(-204.0, -112.0), Vector2(90.0, 96.0)),
		"background_color": Color(0.098, 0.184, 0.196, 1.0),
		"main_route_color": Color(0.22, 0.52, 0.48, 0.58),
		"key_object_color": Color(0.4, 0.86, 0.84, 0.52),
		"hazard_or_facility_color": Color(0.82, 0.66, 0.26, 0.46)
	},
	"region.crystal_vein_field": {
		"cue_name": "CrystalVeinField",
		"title": "晶体矿脉视觉优先级",
		"background_path": "RegionCrystal",
		"main_route_rect": Rect2(Vector2(2.0, -190.0), Vector2(226.0, 18.0)),
		"key_object_path": "Interactables/CrystalCluster",
		"key_object_rect": Rect2(Vector2(8.0, -110.0), Vector2(42.0, 46.0)),
		"hazard_or_facility_path": "Interactables/AnomalyCrystal",
		"hazard_or_facility_rect": Rect2(Vector2(118.0, 112.0), Vector2(112.0, 58.0)),
		"background_color": Color(0.086, 0.146, 0.24, 1.0),
		"main_route_color": Color(0.22, 0.54, 0.86, 0.56),
		"key_object_color": Color(0.44, 0.76, 1.0, 0.58),
		"hazard_or_facility_color": Color(0.72, 0.42, 0.86, 0.5)
	},
	"region.pollution_edge": {
		"cue_name": "PollutionEdge",
		"title": "污染边界视觉优先级",
		"background_path": "RegionPollution",
		"main_route_rect": Rect2(Vector2(248.0, -42.0), Vector2(130.0, 12.0)),
		"key_object_path": "Interactables/PollutionResidue",
		"key_object_rect": Rect2(Vector2(244.0, 18.0), Vector2(132.0, 154.0)),
		"hazard_or_facility_path": "OpeningSceneLayer/PollutionDangerField",
		"hazard_or_facility_rect": Rect2(Vector2(286.0, 54.0), Vector2(46.0, 44.0)),
		"background_color": Color(0.22, 0.212, 0.086, 1.0),
		"main_route_color": Color(0.84, 0.66, 0.2, 0.56),
		"key_object_color": Color(0.82, 0.72, 0.22, 0.54),
		"hazard_or_facility_color": Color(0.9, 0.38, 0.16, 0.52)
	},
	"region.ruin_outer_ring": {
		"cue_name": "RuinOuterRing",
		"title": "封锁遗迹视觉优先级",
		"background_path": "RegionRuinOuterRing",
		"main_route_rect": Rect2(Vector2(386.0, -4.0), Vector2(288.0, 16.0)),
		"key_object_path": "Interactables/SignalEchoCache",
		"key_object_rect": Rect2(Vector2(596.0, 20.0), Vector2(54.0, 42.0)),
		"hazard_or_facility_path": "Interactables/OuterRingBarrier",
		"hazard_or_facility_rect": Rect2(Vector2(398.0, -96.0), Vector2(260.0, 22.0)),
		"background_color": Color(0.142, 0.138, 0.212, 1.0),
		"main_route_color": Color(0.5, 0.46, 0.78, 0.54),
		"key_object_color": Color(0.5, 0.84, 0.72, 0.52),
		"hazard_or_facility_color": Color(0.82, 0.48, 0.3, 0.5)
	},
	"region.deep_ruin_threshold": {
		"cue_name": "DeepRuinThreshold",
		"title": "裂相脊视觉优先级",
		"background_path": "RegionDeepRuin",
		"main_route_rect": Rect2(Vector2(704.0, -48.0), Vector2(730.0, 16.0)),
		"key_object_path": "Interactables/DeepSignalArray",
		"key_object_rect": Rect2(Vector2(858.0, -108.0), Vector2(50.0, 50.0)),
		"hazard_or_facility_path": "Interactables/PhaseFaultSpire",
		"hazard_or_facility_rect": Rect2(Vector2(1212.0, 38.0), Vector2(48.0, 48.0)),
		"background_color": Color(0.176, 0.126, 0.18, 1.0),
		"main_route_color": Color(0.72, 0.44, 0.62, 0.5),
		"key_object_color": Color(0.58, 0.82, 0.96, 0.52),
		"hazard_or_facility_color": Color(0.9, 0.5, 0.24, 0.5)
	},
	"region.inner_phase_well": {
		"cue_name": "InnerPhaseWell",
		"title": "回声台地视觉优先级",
		"background_path": "RegionInnerPhaseWell",
		"main_route_rect": Rect2(Vector2(1480.0, -24.0), Vector2(260.0, 16.0)),
		"key_object_path": "Interactables/InnerPhaseWell",
		"key_object_rect": Rect2(Vector2(1710.0, -28.0), Vector2(52.0, 42.0)),
		"hazard_or_facility_path": "Interactables/WellFluxPressureVentWest",
		"hazard_or_facility_rect": Rect2(Vector2(1564.0, 0.0), Vector2(170.0, 28.0)),
		"background_color": Color(0.118, 0.15, 0.226, 1.0),
		"main_route_color": Color(0.34, 0.62, 0.92, 0.5),
		"key_object_color": Color(0.68, 0.86, 0.96, 0.52),
		"hazard_or_facility_color": Color(0.78, 0.56, 0.34, 0.46)
	},
	"region.phase_well_sink": {
		"cue_name": "PhaseWellSink",
		"title": "盐壳浅滩视觉优先级",
		"background_path": "RegionPhaseWellSink",
		"main_route_rect": Rect2(Vector2(1768.0, -50.0), Vector2(250.0, 16.0)),
		"key_object_path": "Interactables/PhaseWellSink",
		"key_object_rect": Rect2(Vector2(1990.0, -70.0), Vector2(54.0, 50.0)),
		"hazard_or_facility_path": "Interactables/WellAshCrustNorth",
		"hazard_or_facility_rect": Rect2(Vector2(1780.0, -44.0), Vector2(220.0, 24.0)),
		"background_color": Color(0.196, 0.14, 0.108, 1.0),
		"main_route_color": Color(0.76, 0.54, 0.3, 0.5),
		"key_object_color": Color(0.84, 0.78, 0.5, 0.52),
		"hazard_or_facility_color": Color(0.7, 0.5, 0.32, 0.5)
	},
	"region.phase_well_chamber": {
		"cue_name": "PhaseWellChamber",
		"title": "碎晶沟谷视觉优先级",
		"background_path": "RegionPhaseWellChamber",
		"main_route_rect": Rect2(Vector2(2054.0, -38.0), Vector2(250.0, 16.0)),
		"key_object_path": "Interactables/PhaseWellChamber",
		"key_object_rect": Rect2(Vector2(2262.0, -36.0), Vector2(54.0, 46.0)),
		"hazard_or_facility_path": "Interactables/PhaseWellChamberShuntWest",
		"hazard_or_facility_rect": Rect2(Vector2(2084.0, -122.0), Vector2(160.0, 32.0)),
		"background_color": Color(0.212, 0.108, 0.128, 1.0),
		"main_route_color": Color(0.62, 0.5, 0.9, 0.5),
		"key_object_color": Color(0.9, 0.54, 0.58, 0.52),
		"hazard_or_facility_color": Color(0.52, 0.72, 0.94, 0.46)
	},
	"region.phase_well_loom": {
		"cue_name": "PhaseWellLoom",
		"title": "风蚀管廊视觉优先级",
		"background_path": "RegionPhaseWellLoom",
		"main_route_rect": Rect2(Vector2(2334.0, -40.0), Vector2(250.0, 16.0)),
		"key_object_path": "Interactables/PhaseWellLoom",
		"key_object_rect": Rect2(Vector2(2542.0, -36.0), Vector2(54.0, 46.0)),
		"hazard_or_facility_path": "Interactables/PhaseWellLoomTensionNorth",
		"hazard_or_facility_rect": Rect2(Vector2(2340.0, -96.0), Vector2(180.0, 36.0)),
		"background_color": Color(0.22, 0.14, 0.118, 1.0),
		"main_route_color": Color(0.52, 0.66, 0.68, 0.5),
		"key_object_color": Color(0.86, 0.66, 0.5, 0.52),
		"hazard_or_facility_color": Color(0.58, 0.74, 0.62, 0.46)
	},
	"region.phase_well_frame": {
		"cue_name": "PhaseWellFrame",
		"title": "锁相框架视觉优先级",
		"background_path": "RegionPhaseWellFrame",
		"main_route_rect": Rect2(Vector2(2618.0, -38.0), Vector2(250.0, 16.0)),
		"key_object_path": "Interactables/PhaseWellFrame",
		"key_object_rect": Rect2(Vector2(2824.0, -36.0), Vector2(54.0, 46.0)),
		"hazard_or_facility_path": "Interactables/PhaseWellFrameRouteNorth",
		"hazard_or_facility_rect": Rect2(Vector2(2622.0, -36.0), Vector2(188.0, 80.0)),
		"background_color": Color(0.238, 0.158, 0.124, 1.0),
		"main_route_color": Color(0.44, 0.7, 0.52, 0.5),
		"key_object_color": Color(0.68, 0.9, 0.62, 0.52),
		"hazard_or_facility_color": Color(0.86, 0.52, 0.28, 0.48)
	},
	"region.phase_well_tether": {
		"cue_name": "PhaseWellTether",
		"title": "锚定桥视觉优先级",
		"background_path": "RegionPhaseWellTether",
		"main_route_rect": Rect2(Vector2(2896.0, -26.0), Vector2(720.0, 18.0)),
		"key_object_path": "Interactables/PhaseWellAnchorField",
		"key_object_rect": Rect2(Vector2(3350.0, -32.0), Vector2(62.0, 52.0)),
		"hazard_or_facility_path": "Interactables/PhaseWellStabilityNodeCore",
		"hazard_or_facility_rect": Rect2(Vector2(3300.0, -132.0), Vector2(230.0, 32.0)),
		"background_color": Color(0.246, 0.166, 0.13, 1.0),
		"main_route_color": Color(0.32, 0.78, 0.7, 0.5),
		"key_object_color": Color(0.56, 0.94, 0.82, 0.52),
		"hazard_or_facility_color": Color(0.72, 0.82, 0.42, 0.46)
	},
	"region.demo_stabilization_core": {
		"cue_name": "DemoStabilizationCore",
		"title": "核心稳定站视觉优先级",
		"background_path": "RegionDemoStabilizationCore",
		"main_route_rect": Rect2(Vector2(3660.0, -88.0), Vector2(424.0, 18.0)),
		"key_object_path": "Interactables/DemoStabilizationCore",
		"key_object_rect": Rect2(Vector2(3990.0, -72.0), Vector2(100.0, 100.0)),
		"hazard_or_facility_path": "OpeningSceneLayer/CoreStabilizationGuardPressureZone",
		"hazard_or_facility_rect": Rect2(Vector2(3818.0, -50.0), Vector2(106.0, 116.0)),
		"background_color": Color(0.13, 0.258, 0.236, 1.0),
		"main_route_color": Color(0.42, 0.88, 0.82, 0.52),
		"key_object_color": Color(0.78, 0.94, 0.56, 0.54),
		"hazard_or_facility_color": Color(0.9, 0.42, 0.24, 0.5)
	}
}

const STATE_PROFILES := {
	STATE_AVAILABLE: {
		"label": "可处理",
		"color": Color(0.52, 0.86, 0.62, 1.0),
		"marker_size": Vector2(38.0, 28.0),
		"monitoring": true
	},
	STATE_PROCESSED: {
		"label": "已处理",
		"color": Color(0.44, 0.54, 0.5, 1.0),
		"marker_size": Vector2(34.0, 22.0),
		"monitoring": false
	},
	STATE_MISSING_PREREQUISITE: {
		"label": "缺条件",
		"color": Color(0.94, 0.58, 0.24, 1.0),
		"marker_size": Vector2(42.0, 28.0),
		"monitoring": true
	},
	STATE_DANGER_ACTIVE: {
		"label": "危险仍在",
		"color": Color(0.88, 0.32, 0.2, 1.0),
		"marker_size": Vector2(44.0, 32.0),
		"monitoring": true
	},
	STATE_DEVICE_READY: {
		"label": "设备可用",
		"color": Color(0.32, 0.78, 0.78, 1.0),
		"marker_size": Vector2(44.0, 30.0),
		"monitoring": true
	},
	STATE_DEVICE_BUSY: {
		"label": "设备忙碌",
		"color": Color(0.9, 0.62, 0.22, 1.0),
		"marker_size": Vector2(48.0, 30.0),
		"monitoring": true
	},
	STATE_CORE_WRITE_BLOCKED: {
		"label": "写入不足",
		"color": Color(0.92, 0.42, 0.32, 1.0),
		"marker_size": Vector2(48.0, 36.0),
		"monitoring": true
	}
}


static func get_region_ids() -> Array:
	return REGION_IDS.duplicate()


static func get_region_profile(region_id: String) -> Dictionary:
	var profile: Dictionary = REGION_PROFILES.get(region_id, {})
	return profile.duplicate(true)


static func get_state_ids() -> Array:
	return REQUIRED_STATE_IDS.duplicate()


static func get_state_profile(state_id: String) -> Dictionary:
	var profile: Dictionary = STATE_PROFILES.get(state_id, {})
	return profile.duplicate(true)


static func get_required_region_keys() -> Array:
	return REQUIRED_REGION_KEYS.duplicate()


static func get_required_state_ids() -> Array:
	return REQUIRED_STATE_IDS.duplicate()


static func make_cue_name(region_id: String, role: String) -> String:
	var profile := get_region_profile(region_id)
	var cue_name := String(profile.get("cue_name", "Unknown"))
	var suffix := String(ROLE_CUE_SUFFIXES.get(role, "Visual"))
	return "%s%sCue" % [cue_name, suffix]
