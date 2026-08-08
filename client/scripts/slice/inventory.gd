class_name Inventory
extends RefCounted

## Generic item container: item_id (String) -> count (int). A runtime-only
## SliceInventoryProfile owns capacity policy; Inventory.new(capacity) remains
## the exact schema-7 total-capacity compatibility constructor.

const UNLIMITED := 1 << 30

var capacity: int:
	get:
		return _profile.schema_seven_capacity()

var _profile: SliceInventoryProfile
var _contents: Dictionary = {}  ## String item_id -> int count


func _init(profile_or_capacity: Variant = 0) -> void:
	if profile_or_capacity is SliceInventoryProfile:
		_profile = profile_or_capacity as SliceInventoryProfile
	else:
		_profile = SliceInventoryProfiles.legacy_total(int(profile_or_capacity))


func profile() -> SliceInventoryProfile:
	return _profile


func count(item: String) -> int:
	return int(_contents.get(item, 0))


func total() -> int:
	var sum := 0
	for n in _contents.values():
		sum += int(n)
	return sum


func contents_view() -> Dictionary:
	return _contents.duplicate()


func item_ids() -> Array[String]:
	var result: Array[String] = []
	for item_id in _contents:
		if int(_contents[item_id]) > 0:
			result.append(String(item_id))
	result.sort()
	return result


## Legacy aggregate-space compatibility. Per-item callers must name the item;
## returning zero here makes accidental post-schema-8 use fail closed.
func free_space() -> int:
	if not _profile.is_legacy_total():
		push_error("Per-item inventory requires free_space_for(item_id).")
		return 0
	return _profile.free_space_for(_contents, "")


func free_space_for(item: String) -> int:
	if not _profile.accepts(_contents):
		return 0
	return _profile.free_space_for(_contents, item)


## Named capacity after an exact removal preview. Crafting uses this to explain
## the same remove-before-add transaction that exchange() later commits.
func free_space_for_after(item: String, removals: Dictionary) -> int:
	var result := _removal_result(removals)
	if not bool(result.get("success", false)):
		return 0
	return _profile.free_space_for(result["contents"], item)


func is_full() -> bool:
	return _profile.is_full(_contents)


func is_empty() -> bool:
	return total() == 0


## Stores up to n; returns the amount actually stored (less if capped).
func add(item: String, n: int) -> int:
	if n <= 0:
		return 0
	var stored := mini(n, free_space_for(item))
	if stored > 0:
		_contents[item] = count(item) + stored
	return stored


func can_add_batch(items: Dictionary) -> bool:
	return can_exchange({}, items)


func add_batch(items: Dictionary) -> bool:
	return exchange({}, items)


## Tests a same-container atomic transaction. Removals happen logically before
## additions, so crafting can reuse the capacity released by its ingredients.
func can_exchange(removals: Dictionary, additions: Dictionary) -> bool:
	return bool(_exchange_result(removals, additions).get("success", false))


func exchange(removals: Dictionary, additions: Dictionary) -> bool:
	var result := _exchange_result(removals, additions)
	if not bool(result.get("success", false)):
		return false
	_contents = result["contents"]
	return true


func can_transfer_to(target: Inventory, items: Dictionary) -> bool:
	if target == null or not _batch_is_valid(items):
		return false
	if target == self:
		return bool(_exchange_result(items, items).get("success", false))
	return (
		bool(_removal_result(items).get("success", false))
		and target.can_add_batch(items)
	)


## Moves the entire requested batch or changes neither inventory.
func transfer_to(target: Inventory, items: Dictionary) -> bool:
	if not can_transfer_to(target, items):
		return false
	if target == self:
		return true
	var source_result := _removal_result(items)
	var target_result := target._exchange_result({}, items)
	_contents = source_result["contents"]
	target._contents = target_result["contents"]
	return true


static func transfer(
	source: Inventory,
	target: Inventory,
	items: Dictionary
) -> bool:
	return source != null and source.transfer_to(target, items)


## Moves as much of one item as the target can currently accept. This is the
## explicit best-effort counterpart to transfer_to()'s all-or-nothing batch.
func transfer_up_to(target: Inventory, item: String, amount: int) -> int:
	if (
		target == null
		or target == self
		or item.is_empty()
		or amount <= 0
	):
		return 0
	var moved := mini(
		amount,
		mini(count(item), target.free_space_for(item))
	)
	if moved <= 0:
		return 0
	var stored := target.add(item, moved)
	if stored != moved:
		if stored > 0:
			target.remove(item, stored)
		push_error("Inventory target changed during best-effort transfer.")
		return 0
	var removed := remove(item, moved)
	if removed != moved:
		target.remove(item, moved)
		if removed > 0:
			restore_existing(item, removed)
		push_error("Inventory source changed during best-effort transfer.")
		return 0
	return moved


## Trusted migration path for items that already existed outside Inventory in
## an older schema (for example schema-3 carrying_collector). It may leave the
## inventory temporarily over capacity, but never discards existing player
## property; normal add() remains capacity-bound until space is freed.
func restore_existing(item: String, n: int) -> void:
	if n > 0:
		_contents[item] = count(item) + n


## Removes up to n; returns the amount actually removed.
func remove(item: String, n: int) -> int:
	if n <= 0:
		return 0
	var taken := mini(n, count(item))
	if taken <= 0:
		return 0
	var left := count(item) - taken
	if left > 0:
		_contents[item] = left
	else:
		_contents.erase(item)
	return taken


func to_dict() -> Dictionary:
	return {"capacity": capacity, "contents": _contents.duplicate()}


static func from_dict(
	data: Dictionary,
	explicit_profile: SliceInventoryProfile = null
) -> Inventory:
	var inv := Inventory.new(
		explicit_profile
		if explicit_profile != null
		else int(data.get("capacity", 0))
	)
	var contents = data.get("contents", {})
	if contents is Dictionary:
		for key in contents:
			var n := int(contents[key])
			if n > 0:
				inv._contents[String(key)] = n
	return inv


func _exchange_result(
	removals: Dictionary,
	additions: Dictionary
) -> Dictionary:
	if not _batch_is_valid(removals) or not _batch_is_valid(additions):
		return {"success": false}
	var next_contents := _contents.duplicate()
	for item_id in removals:
		var key := String(item_id)
		var remaining := int(next_contents.get(key, 0)) - int(removals[item_id])
		if remaining < 0:
			return {"success": false}
		if remaining == 0:
			next_contents.erase(key)
		else:
			next_contents[key] = remaining
	for item_id in additions:
		var key := String(item_id)
		next_contents[key] = (
			int(next_contents.get(key, 0)) + int(additions[item_id])
		)
	if not _profile.accepts(next_contents):
		return {"success": false}
	return {"success": true, "contents": next_contents}


func _removal_result(removals: Dictionary) -> Dictionary:
	if not _batch_is_valid(removals):
		return {"success": false}
	var next_contents := _contents.duplicate()
	for item_id in removals:
		var key := String(item_id)
		var remaining := int(next_contents.get(key, 0)) - int(removals[item_id])
		if remaining < 0:
			return {"success": false}
		if remaining == 0:
			next_contents.erase(key)
		else:
			next_contents[key] = remaining
	return {"success": true, "contents": next_contents}


func _batch_is_valid(items: Dictionary) -> bool:
	for item_id in items:
		if String(item_id).is_empty():
			return false
		var amount = items[item_id]
		if not (amount is int) or int(amount) <= 0:
			return false
	return true
