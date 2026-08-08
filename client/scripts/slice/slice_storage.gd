class_name SliceStorage
extends SliceBuildingInstance

## Passive L3 storage endpoint. L4 will expose logistics transfer; package 2
## only establishes the content gate needed by adjustment and demolition.

const CAPACITY := 20

var inventory := Inventory.new(SliceInventoryProfiles.legacy_storage())


func logistics_endpoints() -> Array[SliceLogisticsEndpoint]:
	var result: Array[SliceLogisticsEndpoint] = []
	if definition == null:
		return result
	for port in definition.logistics_ports:
		result.append(SliceLogisticsEndpoint.new(
			self,
			port,
			Callable(self, "_accept_logistics_item"),
			Callable(self, "_peek_logistics_output").bind(
				port.output_item_order
			),
			Callable(self, "_take_logistics_output")
		))
	return result


func content_block_reason() -> String:
	return "" if inventory.is_empty() else "先清空储物箱"


func state_dict(allowed_keys: Array[String]) -> Dictionary:
	var result := {}
	if allowed_keys.has("inventory"):
		result["inventory"] = inventory.to_dict()
	return result


func _accept_logistics_item(item_id: String) -> int:
	return inventory.add(item_id, 1)


func _peek_logistics_output(ordered_items: Array[String]) -> String:
	for item_id in ordered_items:
		if inventory.count(item_id) > 0:
			return item_id
	return ""


func _take_logistics_output(item_id: String) -> int:
	return inventory.remove(item_id, 1)
