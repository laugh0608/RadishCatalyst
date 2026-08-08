class_name SliceLogisticsPortDefinition
extends RefCounted

## Immutable, non-persistent logistics geometry and item policy. Runtime owners
## bind inventories or buffers separately; saves continue to contain only
## building topology and device-owned state.

const ROLE_INPUT := "input"
const ROLE_OUTPUT := "output"
const ROLE_BIDIRECTIONAL := "bidirectional"

const ORIENTATION_FOLLOWS := "follows_orientation"
const ORIENTATION_FIXED_LOCAL := "fixed_local"

var id: String
var role: String
var label: String
var local_cell: Vector2i
var outward_direction: Vector2i
var orientation_policy: String
var accepted_item_ids: Array[String]
var output_item_order: Array[String]
var source_phase: int
var connection_distance: int


func _init(
	port_id: String,
	flow_role: String,
	display_label: String,
	cell: Vector2i,
	outward: Vector2i,
	port_orientation_policy: String,
	accepted_items: Array[String] = [],
	ordered_output_items: Array[String] = [],
	output_source_phase: int = 0,
	belt_connection_distance: int = 1
) -> void:
	id = port_id
	role = flow_role
	label = display_label
	local_cell = cell
	outward_direction = outward
	orientation_policy = port_orientation_policy
	accepted_item_ids = accepted_items.duplicate()
	output_item_order = ordered_output_items.duplicate()
	source_phase = output_source_phase
	connection_distance = maxi(1, belt_connection_distance)


func resolved_local_cell(
	base_footprint: Vector2i,
	rotation: int
) -> Vector2i:
	if not is_cell_defined():
		return local_cell
	if orientation_policy == ORIENTATION_FIXED_LOCAL:
		return local_cell
	var point := local_cell
	var size := base_footprint
	for _step in range(posmod(rotation, 4)):
		point = Vector2i(size.y - 1 - point.y, point.x)
		size = Vector2i(size.y, size.x)
	return point


func resolved_outward_direction(rotation: int) -> Vector2i:
	if orientation_policy == ORIENTATION_FIXED_LOCAL:
		return outward_direction
	var result := outward_direction
	for _step in range(posmod(rotation, 4)):
		result = Vector2i(-result.y, result.x)
	return result


func resolved_descriptor(
	origin_cell: Vector2i,
	base_footprint: Vector2i,
	rotation: int
) -> Dictionary:
	var port_cell := origin_cell + resolved_local_cell(
		base_footprint, rotation
	)
	var outward := resolved_outward_direction(rotation)
	return {
		"id": id,
		"role": role,
		"label": label,
		"port_cell": port_cell,
		"connection_cell": port_cell + outward * connection_distance,
		"connection_distance": connection_distance,
		"outward_direction": outward,
		"accepted_item_ids": accepted_item_ids.duplicate(),
		"output_item_order": output_item_order.duplicate(),
		"source_phase": source_phase,
	}


func accepts_input() -> bool:
	return role == ROLE_INPUT or role == ROLE_BIDIRECTIONAL


func provides_output() -> bool:
	return role == ROLE_OUTPUT or role == ROLE_BIDIRECTIONAL


func is_cell_defined() -> bool:
	return local_cell.x >= 0 and local_cell.y >= 0
