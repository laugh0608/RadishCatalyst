class_name SliceInventoryProfile
extends RefCounted

## Runtime-only capacity policy. Profiles never enter save payloads; schema 7
## continues to serialize a legacy numeric capacity while schema 8+ derives
## its per-item rules from the owning container.

const MODE_LEGACY_TOTAL := "legacy_total"
const MODE_PER_ITEM := "per_item"
const UNLIMITED := 1 << 30

var profile_id: String:
	get:
		return _profile_id
var mode: String:
	get:
		return _mode
var total_capacity: int:
	get:
		return _total_capacity
var per_item_capacity: int:
	get:
		return _per_item_capacity
var type_limit: int:
	get:
		return _type_limit

var _profile_id := ""
var _mode := MODE_LEGACY_TOTAL
var _total_capacity := 0
var _per_item_capacity := 0
var _type_limit := 0
var _item_capacity_overrides: Dictionary = {}
var _allowed_item_ids: Dictionary = {}


func _init(
	definition_id: String,
	capacity_mode: String,
	legacy_total_capacity: int = 0,
	default_per_item_capacity: int = 0,
	maximum_type_count: int = 0,
	item_capacity_overrides: Dictionary = {},
	allowed_item_ids: Array[String] = []
) -> void:
	_profile_id = definition_id
	_mode = capacity_mode
	_total_capacity = (
		legacy_total_capacity if capacity_mode == MODE_LEGACY_TOTAL else 0
	)
	_per_item_capacity = maxi(0, default_per_item_capacity)
	_type_limit = maxi(0, maximum_type_count)
	for key in item_capacity_overrides:
		var item_limit := int(item_capacity_overrides[key])
		if item_limit > 0:
			_item_capacity_overrides[String(key)] = item_limit
	for item_id in allowed_item_ids:
		if not item_id.is_empty():
			_allowed_item_ids[item_id] = true


func is_legacy_total() -> bool:
	return mode == MODE_LEGACY_TOTAL


func is_per_item() -> bool:
	return mode == MODE_PER_ITEM


## Only this legacy projection is serialized by Inventory.to_dict().
func schema_seven_capacity() -> int:
	return total_capacity if is_legacy_total() else 0


func item_capacity(item_id: String) -> int:
	if is_legacy_total():
		return total_capacity
	if not accepts_item(item_id):
		return 0
	return int(_item_capacity_overrides.get(item_id, per_item_capacity))


func accepts_item(item_id: String) -> bool:
	return (
		not item_id.is_empty()
		and (_allowed_item_ids.is_empty() or _allowed_item_ids.has(item_id))
	)


func free_space_for(contents: Dictionary, item_id: String) -> int:
	if is_legacy_total():
		if total_capacity <= 0:
			return UNLIMITED
		return maxi(0, total_capacity - _total(contents))
	if not is_per_item() or not accepts_item(item_id):
		return 0

	var existing := maxi(0, int(contents.get(item_id, 0)))
	if existing <= 0 and type_limit > 0 and _type_count(contents) >= type_limit:
		return 0
	var limit := item_capacity(item_id)
	return UNLIMITED if limit <= 0 else maxi(0, limit - existing)


func accepts(contents: Dictionary) -> bool:
	if is_legacy_total():
		return total_capacity <= 0 or _total(contents) <= total_capacity
	if not is_per_item():
		return false
	if type_limit > 0 and _type_count(contents) > type_limit:
		return false
	for key in contents:
		var amount := int(contents[key])
		if amount <= 0:
			continue
		if not accepts_item(String(key)):
			return false
		var limit := item_capacity(String(key))
		if limit > 0 and amount > limit:
			return false
	return true


func is_full(contents: Dictionary) -> bool:
	if is_legacy_total():
		return total_capacity > 0 and _total(contents) >= total_capacity
	if not is_per_item() or type_limit <= 0:
		return false
	if _type_count(contents) < type_limit:
		return false
	for key in contents:
		if free_space_for(contents, String(key)) > 0:
			return false
	return true


func _total(contents: Dictionary) -> int:
	var result := 0
	for amount in contents.values():
		result += maxi(0, int(amount))
	return result


func _type_count(contents: Dictionary) -> int:
	var result := 0
	for amount in contents.values():
		if int(amount) > 0:
			result += 1
	return result
