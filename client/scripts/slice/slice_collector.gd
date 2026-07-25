class_name SliceCollector
extends SliceBuildingInstance

## Placed crystal collector: produces crystals into its own output buffer on a
## timed tick driven by SliceWorld. The buffer pauses at BUFFER_CAP until the
## player walks over and withdraws it — spatial output that belts will automate
## at arc layer L4 (docs/features/slice-item-inventory-model-v1.md).

const BUFFER_CAP := 10

var buffer := 0


func has_space() -> bool:
	return buffer < BUFFER_CAP


func produce(n: int) -> void:
	buffer = mini(buffer + n, BUFFER_CAP)


func state_dict(allowed_keys: Array[String]) -> Dictionary:
	var result := {}
	if allowed_keys.has("buffer"):
		result["buffer"] = buffer
	return result


func content_block_reason() -> String:
	return "" if buffer <= 0 else "先取空采集器"
