class_name SliceItemCatalog
extends RefCounted

## The nine ordinary slice item IDs and their shared presentation order.
## Building-kit icon metadata is derived from SliceBuildingCatalog so item UI
## does not create a second source for the current building sprite and region.
## Quest-item presentation stays outside find(), all() and ORDERED_IDS: it is a
## view over independent quest state, never an Inventory or logistics item.

const CRYSTAL_ID := "crystal"
const CATALYST_ID := "catalyst"
const PART_ID := "part"
const CRYSTAL_ICON := "res://assets/sprites/slice/cargo_crystal.png"
const CATALYST_ICON := "res://assets/sprites/slice/cargo_catalyst.png"
const PART_ICON := "res://assets/icons/slice_mechanical_part.svg"
const CRITICAL_SAMPLE_PRESENTATION_ID := "quest.critical_sample"
const CRITICAL_SAMPLE_ICON := (
	"res://assets/sprites/slice/critical_sample_crystal_gland.png"
)
const UNKNOWN_SORT_ORDER := 1 << 29

const CATEGORY_ORDER: Array[String] = [
	SliceItemDefinition.CATEGORY_RAW_MATERIAL,
	SliceItemDefinition.CATEGORY_PROCESSED_ITEM,
	SliceItemDefinition.CATEGORY_BUILDING_KIT,
	SliceItemDefinition.CATEGORY_KEY_ITEM,
	SliceItemDefinition.CATEGORY_UNKNOWN,
]

const ORDERED_IDS: Array[String] = [
	CRYSTAL_ID,
	CATALYST_ID,
	PART_ID,
	SliceBuildingCatalog.FLOOR_ID,
	SliceBuildingCatalog.COLLECTOR_ID,
	SliceBuildingCatalog.REACTOR_ID,
	SliceBuildingCatalog.POWER_RELAY_ID,
	SliceBuildingCatalog.CONVEYOR_ID,
	SliceBuildingCatalog.STORAGE_ID,
]


static func find(item_id: String) -> SliceItemDefinition:
	match item_id:
		CRYSTAL_ID:
			return SliceItemDefinition.new(
				CRYSTAL_ID,
				"晶体",
				"晶体",
				SliceItemDefinition.CATEGORY_RAW_MATERIAL,
				0,
				CRYSTAL_ICON,
				true
			)
		CATALYST_ID:
			return SliceItemDefinition.new(
				CATALYST_ID,
				"催化剂",
				"催化剂",
				SliceItemDefinition.CATEGORY_PROCESSED_ITEM,
				10,
				CATALYST_ICON,
				true
			)
		PART_ID:
			return SliceItemDefinition.new(
				PART_ID,
				"机械零件",
				"机械零件",
				SliceItemDefinition.CATEGORY_PROCESSED_ITEM,
				20,
				PART_ICON,
				false
			)
		SliceBuildingCatalog.FLOOR_ID:
			return _building_kit(
				item_id, "工业地板套件", "地板", 30
			)
		SliceBuildingCatalog.COLLECTOR_ID:
			return _building_kit(
				item_id, "采集器套件", "采集器", 40
			)
		SliceBuildingCatalog.REACTOR_ID:
			return _building_kit(
				item_id, "反应器套件", "反应器", 50
			)
		SliceBuildingCatalog.POWER_RELAY_ID:
			return _building_kit(
				item_id, "中继套件", "中继", 60
			)
		SliceBuildingCatalog.CONVEYOR_ID:
			return _building_kit(
				item_id, "传送带套件", "传送带", 70
			)
		SliceBuildingCatalog.STORAGE_ID:
			return _building_kit(
				item_id, "储物箱套件", "储物箱", 80
			)
	return null


static func all() -> Array[SliceItemDefinition]:
	var result: Array[SliceItemDefinition] = []
	for item_id in ORDERED_IDS:
		result.append(find(item_id))
	return result


static func is_known_ordinary(item_id: String) -> bool:
	return ORDERED_IDS.has(item_id)


static func category_title(category: String) -> String:
	match category:
		SliceItemDefinition.CATEGORY_RAW_MATERIAL:
			return "原料"
		SliceItemDefinition.CATEGORY_PROCESSED_ITEM:
			return "加工品"
		SliceItemDefinition.CATEGORY_BUILDING_KIT:
			return "建筑套件"
		SliceItemDefinition.CATEGORY_KEY_ITEM:
			return "关键物品"
		SliceItemDefinition.CATEGORY_UNKNOWN:
			return "兼容物品"
	return category


static func critical_sample_read_model(carried: bool) -> Dictionary:
	if not carried:
		return {}
	return SliceItemDefinition.new(
		CRITICAL_SAMPLE_PRESENTATION_ID,
		"晶腺样本",
		"晶腺样本",
		SliceItemDefinition.CATEGORY_KEY_ITEM,
		0,
		CRITICAL_SAMPLE_ICON,
		false
	).to_read_model(1)


static func transportable_ids() -> Array[String]:
	var result: Array[String] = []
	for definition in all():
		if definition.transportable:
			result.append(definition.item_id)
	return result


static func is_transportable(item_id: String) -> bool:
	var definition := find(item_id)
	return definition != null and definition.transportable


static func sorted_ids(item_ids: Array[String]) -> Array[String]:
	var unique := {}
	for item_id in item_ids:
		unique[item_id] = true
	var result: Array[String] = []
	for item_id in unique:
		result.append(String(item_id))
	result.sort_custom(_item_id_before)
	return result


## Builds deterministic UI data without exposing Inventory's mutable storage.
## Unknown schema-7 keys remain visible after the nine known definitions.
static func read_model(
	contents: Dictionary,
	include_empty_known: bool = false
) -> Array[Dictionary]:
	var ids: Array[String] = []
	if include_empty_known:
		ids.append_array(ORDERED_IDS)
	for key in contents:
		if int(contents[key]) > 0:
			ids.append(String(key))

	var result: Array[Dictionary] = []
	for item_id in sorted_ids(ids):
		var definition := find(item_id)
		if definition == null:
			definition = SliceItemDefinition.new(
				item_id,
				item_id,
				item_id,
				SliceItemDefinition.CATEGORY_UNKNOWN,
				UNKNOWN_SORT_ORDER,
				"",
				false
			)
		result.append(definition.to_read_model(int(contents.get(item_id, 0))))
	return result


static func _building_kit(
	item_id: String,
	display_name: String,
	short_name: String,
	sort_order: int
) -> SliceItemDefinition:
	var building := SliceBuildingCatalog.find(item_id)
	var icon_path := ""
	var icon_region := Rect2()
	if building != null:
		icon_path = building.texture_path_for_rotation(0)
		icon_region = building.icon_region
	return SliceItemDefinition.new(
		item_id,
		display_name,
		short_name,
		SliceItemDefinition.CATEGORY_BUILDING_KIT,
		sort_order,
		icon_path,
		false,
		item_id,
		icon_region
	)


static func _item_id_before(left: String, right: String) -> bool:
	var left_definition := find(left)
	var right_definition := find(right)
	var left_order := (
		UNKNOWN_SORT_ORDER
		if left_definition == null
		else left_definition.sort_order
	)
	var right_order := (
		UNKNOWN_SORT_ORDER
		if right_definition == null
		else right_definition.sort_order
	)
	if left_order == right_order:
		return left < right
	return left_order < right_order
