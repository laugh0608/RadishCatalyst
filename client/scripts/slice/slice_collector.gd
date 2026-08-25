class_name SliceCollector
extends SliceBuildingInstance

## Placed crystal collector: produces into one authoritative output buffer.
## Manual withdrawal and the fixed right logistics endpoint consume the same
## count, so belt backpressure cannot duplicate or discard production.

const BUFFER_CAP := 50
const OUTPUT_ITEM_ID := "crystal"

var buffer := 0
var production_progress := 0.0


func logistics_endpoints() -> Array[SliceLogisticsEndpoint]:
	var result: Array[SliceLogisticsEndpoint] = []
	if definition == null:
		return result
	var port := definition.logistics_port_definition("output")
	if port == null:
		return result
	result.append(SliceLogisticsEndpoint.new(
		self,
		port,
		Callable(),
		Callable(self, "_peek_logistics_output"),
		Callable(self, "_take_logistics_output")
	))
	return result


func has_space() -> bool:
	return buffer < BUFFER_CAP


func produce(n: int) -> void:
	buffer = mini(buffer + n, BUFFER_CAP)


func state_dict(allowed_keys: Array[String]) -> Dictionary:
	var result := {}
	if allowed_keys.has("buffer"):
		result["buffer"] = buffer
	if allowed_keys.has("production_progress"):
		result["production_progress"] = production_progress
	return result


func content_block_reason() -> String:
	return "" if buffer <= 0 else "先取空采集器"


func _peek_logistics_output() -> String:
	return OUTPUT_ITEM_ID if buffer > 0 else ""


func _take_logistics_output(item_id: String) -> int:
	if item_id != OUTPUT_ITEM_ID or buffer <= 0:
		return 0
	buffer -= 1
	return 1
