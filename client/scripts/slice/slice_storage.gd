class_name SliceStorage
extends SliceBuildingInstance

## Passive L3 storage endpoint. L4 will expose logistics transfer; package 2
## only establishes the content gate needed by adjustment and demolition.

const CAPACITY := 20

var inventory := Inventory.new(CAPACITY)


func content_block_reason() -> String:
	return "" if inventory.is_empty() else "先清空储物箱"


func state_dict(allowed_keys: Array[String]) -> Dictionary:
	var result := {}
	if allowed_keys.has("inventory"):
		result["inventory"] = inventory.to_dict()
	return result
