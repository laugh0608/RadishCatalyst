class_name Inventory
extends RefCounted

## Generic item container: item_id (String) -> count (int), with an optional
## total-quantity capacity (0 = unlimited). Backs the slice's spatial resource
## model — the player backpack, the core central warehouse, machine buffers and
## storage tanks each hold one of these, replacing the old global int counters
## (docs/features/slice-item-inventory-model-v1.md).

const UNLIMITED := 1 << 30

var capacity: int  ## 0 = unlimited
var _contents: Dictionary = {}  ## String item_id -> int count


func _init(cap: int = 0) -> void:
	capacity = cap


func count(item: String) -> int:
	return int(_contents.get(item, 0))


func total() -> int:
	var sum := 0
	for n in _contents.values():
		sum += int(n)
	return sum


func free_space() -> int:
	if capacity <= 0:
		return UNLIMITED
	return maxi(0, capacity - total())


func is_full() -> bool:
	return capacity > 0 and total() >= capacity


func is_empty() -> bool:
	return total() == 0


## Stores up to n; returns the amount actually stored (less if capped).
func add(item: String, n: int) -> int:
	if n <= 0:
		return 0
	var stored := mini(n, free_space())
	if stored > 0:
		_contents[item] = count(item) + stored
	return stored


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


static func from_dict(data: Dictionary) -> Inventory:
	var inv := Inventory.new(int(data.get("capacity", 0)))
	var contents = data.get("contents", {})
	if contents is Dictionary:
		for key in contents:
			var n := int(contents[key])
			if n > 0:
				inv._contents[String(key)] = n
	return inv
