extends RefCounted
class_name DemoInitialArtIdentityProfile

const ROLE_DEVICE := "device"
const ROLE_RESOURCE := "resource"
const ROLE_HAZARD := "hazard"
const ROLE_OBJECTIVE := "objective"

const MATERIAL_ALLOY_CORE := "alloy_core"
const MATERIAL_REACTOR_HEAT := "reactor_heat"
const MATERIAL_STORAGE_SUPPLY := "storage_supply"
const MATERIAL_OUTFITTING_BLUE := "outfitting_blue"
const MATERIAL_POLLUTION_FILTER := "pollution_filter"
const MATERIAL_CRYSTAL := "crystal"
const MATERIAL_POLLUTION_SLUDGE := "pollution_sludge"
const MATERIAL_PRESSURE_WARNING := "pressure_warning"
const MATERIAL_STABILIZATION_CORE := "stabilization_core"

const REQUIRED_IDENTITY_KEYS := [
	"title",
	"role",
	"material",
	"anchor_path",
	"scene_path",
	"body_rect",
	"accent_rect",
	"body_color",
	"accent_color"
]

const IDENTITY_IDS := [
	"identity.outpost_core",
	"identity.basic_reactor",
	"identity.basic_storage",
	"identity.field_outfitting_station",
	"identity.pollution_filter",
	"identity.crystal_ore",
	"identity.pollution_residue",
	"identity.pollution_pressure",
	"identity.demo_stabilization_core"
]

const IDENTITY_PROFILES := {
	"identity.outpost_core": {
		"title": "前哨核心现场身份",
		"role": ROLE_DEVICE,
		"material": MATERIAL_ALLOY_CORE,
		"anchor_path": "Interactables/OutpostCore",
		"scene_path": "OpeningSceneLayer/BaseCoreObjectMarker",
		"body_rect": Rect2(Vector2(-334.0, -126.0), Vector2(86.0, 62.0)),
		"accent_rect": Rect2(Vector2(-334.0, -126.0), Vector2(86.0, 8.0)),
		"body_color": Color(0.26, 0.68, 0.72, 0.42),
		"accent_color": Color(0.82, 0.96, 0.92, 0.78)
	},
	"identity.basic_reactor": {
		"title": "基础反应器现场身份",
		"role": ROLE_DEVICE,
		"material": MATERIAL_REACTOR_HEAT,
		"anchor_path": "Interactables/BasicReactor",
		"scene_path": "OpeningSceneLayer/BaseReactorObjectMarker",
		"body_rect": Rect2(Vector2(-214.0, -114.0), Vector2(96.0, 96.0)),
		"accent_rect": Rect2(Vector2(-214.0, -114.0), Vector2(10.0, 96.0)),
		"body_color": Color(0.84, 0.56, 0.22, 0.38),
		"accent_color": Color(0.96, 0.8, 0.36, 0.82)
	},
	"identity.basic_storage": {
		"title": "基础储存箱现场身份",
		"role": ROLE_DEVICE,
		"material": MATERIAL_STORAGE_SUPPLY,
		"anchor_path": "Interactables/BasicStorageBuildSite",
		"scene_path": "OpeningSceneLayer/BaseStorageObjectMarker",
		"body_rect": Rect2(Vector2(-292.0, -24.0), Vector2(84.0, 76.0)),
		"accent_rect": Rect2(Vector2(-292.0, 42.0), Vector2(84.0, 8.0)),
		"body_color": Color(0.28, 0.68, 0.56, 0.38),
		"accent_color": Color(0.6, 0.94, 0.78, 0.76)
	},
	"identity.field_outfitting_station": {
		"title": "出发整备台现场身份",
		"role": ROLE_DEVICE,
		"material": MATERIAL_OUTFITTING_BLUE,
		"anchor_path": "Interactables/FieldOutfittingStation",
		"scene_path": "OpeningSceneLayer/BaseOutfittingObjectMarker",
		"body_rect": Rect2(Vector2(-124.0, -92.0), Vector2(86.0, 98.0)),
		"accent_rect": Rect2(Vector2(-48.0, -92.0), Vector2(10.0, 98.0)),
		"body_color": Color(0.36, 0.58, 0.86, 0.34),
		"accent_color": Color(0.66, 0.82, 1.0, 0.72)
	},
	"identity.pollution_filter": {
		"title": "污染过滤器现场身份",
		"role": ROLE_DEVICE,
		"material": MATERIAL_POLLUTION_FILTER,
		"anchor_path": "Interactables/PollutionFilter",
		"scene_path": "OpeningSceneLayer/PollutionFilterObjectMarker",
		"body_rect": Rect2(Vector2(266.0, -138.0), Vector2(66.0, 56.0)),
		"accent_rect": Rect2(Vector2(266.0, -138.0), Vector2(66.0, 8.0)),
		"body_color": Color(0.58, 0.72, 0.28, 0.42),
		"accent_color": Color(0.88, 0.9, 0.38, 0.78)
	},
	"identity.crystal_ore": {
		"title": "晶体矿物现场身份",
		"role": ROLE_RESOURCE,
		"material": MATERIAL_CRYSTAL,
		"anchor_path": "Interactables/CrystalCluster",
		"scene_path": "OpeningSceneLayer/CrystalMainVeinStartAnchor",
		"body_rect": Rect2(Vector2(0.0, -132.0), Vector2(238.0, 164.0)),
		"accent_rect": Rect2(Vector2(0.0, -132.0), Vector2(238.0, 8.0)),
		"body_color": Color(0.28, 0.72, 1.0, 0.32),
		"accent_color": Color(0.62, 0.9, 1.0, 0.76)
	},
	"identity.pollution_residue": {
		"title": "污染沉积物现场身份",
		"role": ROLE_RESOURCE,
		"material": MATERIAL_POLLUTION_SLUDGE,
		"anchor_path": "Interactables/PollutionResidue",
		"scene_path": "OpeningSceneLayer/PollutionResidueObjectPocket",
		"body_rect": Rect2(Vector2(238.0, 8.0), Vector2(150.0, 250.0)),
		"accent_rect": Rect2(Vector2(238.0, 250.0), Vector2(150.0, 8.0)),
		"body_color": Color(0.68, 0.7, 0.24, 0.34),
		"accent_color": Color(0.9, 0.78, 0.26, 0.72)
	},
	"identity.pollution_pressure": {
		"title": "污染压力现场身份",
		"role": ROLE_HAZARD,
		"material": MATERIAL_PRESSURE_WARNING,
		"anchor_path": "OpeningSceneLayer/PollutionGatePressureMarker",
		"scene_path": "OpeningSceneLayer/PollutionGatePressurePocket",
		"body_rect": Rect2(Vector2(340.0, 4.0), Vector2(44.0, 48.0)),
		"accent_rect": Rect2(Vector2(340.0, 4.0), Vector2(44.0, 8.0)),
		"body_color": Color(0.9, 0.34, 0.18, 0.44),
		"accent_color": Color(1.0, 0.64, 0.22, 0.82)
	},
	"identity.demo_stabilization_core": {
		"title": "核心稳定站现场身份",
		"role": ROLE_OBJECTIVE,
		"material": MATERIAL_STABILIZATION_CORE,
		"anchor_path": "Interactables/DemoStabilizationCore",
		"scene_path": "OpeningSceneLayer/CoreStabilizationCorePad",
		"body_rect": Rect2(Vector2(3912.0, -166.0), Vector2(196.0, 306.0)),
		"accent_rect": Rect2(Vector2(3912.0, -166.0), Vector2(196.0, 10.0)),
		"body_color": Color(0.34, 0.86, 0.74, 0.34),
		"accent_color": Color(0.88, 0.96, 0.48, 0.78)
	}
}


static func get_identity_ids() -> Array:
	return IDENTITY_IDS.duplicate()


static func get_identity_profile(identity_id: String) -> Dictionary:
	var profile: Dictionary = IDENTITY_PROFILES.get(identity_id, {})
	return profile.duplicate(true)


static func get_required_identity_keys() -> Array:
	return REQUIRED_IDENTITY_KEYS.duplicate()


static func get_role_ids() -> Array:
	return [ROLE_DEVICE, ROLE_RESOURCE, ROLE_HAZARD, ROLE_OBJECTIVE]


static func make_node_name(identity_id: String, suffix: String = "") -> String:
	var parts := identity_id.split(".")
	var base_name := "Unknown"
	if not parts.is_empty():
		base_name = String(parts[parts.size() - 1]).to_pascal_case()
	return "%s%s" % [base_name, suffix]
