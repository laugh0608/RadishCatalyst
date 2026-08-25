class_name SliceReactor
extends SliceBuildingInstance

## Powered fixed-recipe reactor. Input is consumed atomically when a batch
## starts; power loss pauses retained progress, and the one-slot output buffer
## prevents the next batch from starting until catalyst is withdrawn.

const INPUT_CAPACITY := 2
const OUTPUT_CAPACITY := 1
const PROCESS_DURATION := 10.0
const INPUT_ITEM_ID := "crystal"
const OUTPUT_ITEM_ID := "catalyst"
const PROCESSING_OVERLAY_TEXTURES := [
	preload("res://assets/sprites/slice/reactor_processing_pulse_a.png"),
	preload("res://assets/sprites/slice/reactor_processing_pulse_b.png"),
]
const PROCESSING_OVERLAY_TEXTURE_LOCAL_ANCHOR := Vector2(48, 28)

var input_inventory := Inventory.new(
	SliceInventoryProfiles.device_reactor_input()
)
var output_inventory := Inventory.new(
	SliceInventoryProfiles.device_reactor_output()
)
var processing := false
var production_progress := 0.0


func logistics_endpoints() -> Array[SliceLogisticsEndpoint]:
	var result: Array[SliceLogisticsEndpoint] = []
	if definition == null:
		return result
	for port in definition.logistics_ports:
		if port.role == SliceLogisticsPortDefinition.ROLE_INPUT:
			result.append(SliceLogisticsEndpoint.new(
				self,
				port,
				Callable(self, "_accept_logistics_input")
			))
		elif port.role == SliceLogisticsPortDefinition.ROLE_OUTPUT:
			result.append(SliceLogisticsEndpoint.new(
				self,
				port,
				Callable(),
				Callable(self, "_peek_logistics_output"),
				Callable(self, "_take_logistics_output")
			))
	return result


func _process(_delta: float) -> void:
	_refresh_processing_visual()


func can_start_batch() -> bool:
	return (
		powered
		and not processing
		and input_inventory.count(INPUT_ITEM_ID) >= INPUT_CAPACITY
		and output_inventory.is_empty()
	)


func tick(delta: float) -> Dictionary:
	var result := {
		"changed": false,
		"started": false,
		"completed": false,
		"progressed": false,
	}
	if delta <= 0.0 or not powered:
		return result

	if can_start_batch():
		var consumed := input_inventory.remove(INPUT_ITEM_ID, INPUT_CAPACITY)
		if consumed != INPUT_CAPACITY:
			push_error("Reactor input changed after start validation.")
			input_inventory.restore_existing(INPUT_ITEM_ID, consumed)
			return result
		processing = true
		production_progress = 0.0
		result["changed"] = true
		result["started"] = true

	if not processing:
		return result

	production_progress += delta
	result["changed"] = true
	result["progressed"] = true
	if (
		production_progress < PROCESS_DURATION
		and not is_equal_approx(production_progress, PROCESS_DURATION)
	):
		return result

	var stored := output_inventory.add(OUTPUT_ITEM_ID, 1)
	if stored != 1:
		push_error("Reactor output changed while a batch was processing.")
		production_progress = PROCESS_DURATION - 0.001
		return result
	processing = false
	production_progress = 0.0
	result["completed"] = true
	return result


func state_dict(allowed_keys: Array[String]) -> Dictionary:
	var result := {}
	if allowed_keys.has("input_inventory"):
		result["input_inventory"] = input_inventory.to_dict()
	if allowed_keys.has("output_inventory"):
		result["output_inventory"] = output_inventory.to_dict()
	if allowed_keys.has("processing"):
		result["processing"] = processing
	if allowed_keys.has("production_progress"):
		result["production_progress"] = production_progress
	return result


func content_block_reason() -> String:
	if processing:
		return "反应器正在生产"
	if not input_inventory.is_empty() or not output_inventory.is_empty():
		return "先取空反应器"
	return ""


func operation_status_text(output_can_extract: bool) -> String:
	if not powered:
		return "断电：加工暂停" if processing else "断电"
	if processing:
		return "加工中"
	if not output_inventory.is_empty():
		return "待出料" if output_can_extract else "出料堵塞"
	if input_inventory.count(INPUT_ITEM_ID) < INPUT_CAPACITY:
		return "缺晶体"
	return "就绪"


func _accept_logistics_input(item_id: String) -> int:
	if item_id != INPUT_ITEM_ID:
		return 0
	return input_inventory.add(item_id, 1)


func _peek_logistics_output() -> String:
	return (
		OUTPUT_ITEM_ID
		if output_inventory.count(OUTPUT_ITEM_ID) > 0
		else ""
	)


func _take_logistics_output(item_id: String) -> int:
	if item_id != OUTPUT_ITEM_ID:
		return 0
	return output_inventory.remove(item_id, 1)


func recover_contents_to(target: Inventory) -> Dictionary:
	var crystal_count := input_inventory.count(INPUT_ITEM_ID)
	if processing:
		crystal_count += INPUT_CAPACITY
	var catalyst_count := output_inventory.count(OUTPUT_ITEM_ID)
	var total := crystal_count + catalyst_count
	if total <= 0:
		return {
			"success": false,
			"message": "反应器内没有可回收物料",
		}
	var recovered_items := {}
	if crystal_count > 0:
		recovered_items[INPUT_ITEM_ID] = crystal_count
	if catalyst_count > 0:
		recovered_items[OUTPUT_ITEM_ID] = catalyst_count
	if not target.can_add_batch(recovered_items):
		return {
			"success": false,
			"message": "背包空间不足，未回收任何物料",
		}

	if not target.add_batch(recovered_items):
		push_error("Reactor recovery capacity changed after validation.")
		return {
			"success": false,
			"message": "背包空间变化，未回收任何物料",
		}
	input_inventory.remove(
		INPUT_ITEM_ID, input_inventory.count(INPUT_ITEM_ID)
	)
	output_inventory.remove(
		OUTPUT_ITEM_ID, output_inventory.count(OUTPUT_ITEM_ID)
	)
	processing = false
	production_progress = 0.0
	return {
		"success": true,
		"crystal": crystal_count,
		"catalyst": catalyst_count,
		"message": "已回收晶体 %d、催化剂 %d" % [
			crystal_count,
			catalyst_count,
		],
	}


func _refresh_processing_visual() -> void:
	if definition == null:
		return
	var body_sprite := get_node_or_null("Sprite") as Sprite2D
	if body_sprite == null or body_sprite.texture == null:
		return
	var sprite := get_node_or_null("ProcessingOverlay") as Sprite2D
	if sprite == null:
		sprite = Sprite2D.new()
		sprite.name = "ProcessingOverlay"
		sprite.z_index = 4
		add_child(sprite)
	var texture_origin := body_sprite.position + body_sprite.offset
	if body_sprite.centered:
		texture_origin -= Vector2(body_sprite.texture.get_size()) * 0.5
	sprite.position = (
		texture_origin + PROCESSING_OVERLAY_TEXTURE_LOCAL_ANCHOR
	)
	sprite.visible = processing
	if not processing:
		return
	var frame := int(floor(production_progress * 4.0)) % 2
	sprite.texture = PROCESSING_OVERLAY_TEXTURES[frame]
	sprite.modulate = Color.WHITE if powered else Color(0.55, 0.6, 0.62, 1.0)
