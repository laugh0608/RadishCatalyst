class_name SliceItemDefinition
extends RefCounted

## Runtime-only presentation and logistics metadata for one stable slice item.
## Item definitions are deliberately absent from save payloads: schema 7 keeps
## persisting the stable item ID and amount only.

const CATEGORY_RAW_MATERIAL := "raw_material"
const CATEGORY_PROCESSED_ITEM := "processed_item"
const CATEGORY_BUILDING_KIT := "building_kit"
const CATEGORY_KEY_ITEM := "key_item"
const CATEGORY_UNKNOWN := "unknown"

var item_id: String:
	get:
		return _item_id
var display_name: String:
	get:
		return _display_name
var short_name: String:
	get:
		return _short_name
var category: String:
	get:
		return _category
var sort_order: int:
	get:
		return _sort_order
var icon_path: String:
	get:
		return _icon_path
var icon_region: Rect2:
	get:
		return _icon_region
var transportable: bool:
	get:
		return _transportable
var building_id: String:
	get:
		return _building_id

var _item_id := ""
var _display_name := ""
var _short_name := ""
var _category := CATEGORY_UNKNOWN
var _sort_order := 0
var _icon_path := ""
var _icon_region := Rect2()
var _transportable := false
var _building_id := ""


func _init(
	definition_id: String,
	definition_display_name: String,
	definition_short_name: String,
	definition_category: String,
	definition_sort_order: int,
	definition_icon_path: String,
	is_transportable: bool,
	definition_building_id: String = "",
	definition_icon_region: Rect2 = Rect2()
) -> void:
	_item_id = definition_id
	_display_name = definition_display_name
	_short_name = definition_short_name
	_category = definition_category
	_sort_order = definition_sort_order
	_icon_path = definition_icon_path
	_icon_region = definition_icon_region
	_transportable = is_transportable
	_building_id = definition_building_id


func to_read_model(amount: int) -> Dictionary:
	return {
		"item_id": item_id,
		"display_name": display_name,
		"short_name": short_name,
		"category": category,
		"sort_order": sort_order,
		"icon_path": icon_path,
		"icon_region": icon_region,
		"transportable": transportable,
		"count": maxi(0, amount),
	}
