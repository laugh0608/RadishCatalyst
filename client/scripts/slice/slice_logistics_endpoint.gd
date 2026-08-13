class_name SliceLogisticsEndpoint
extends RefCounted

## Non-persistent runtime binding between one resolved logistics port and its
## authoritative device inventory or buffer. Geometry comes from the immutable
## port definition; transfer callbacks remain owned by the runtime device.

var owner: Object
var port_definition: SliceLogisticsPortDefinition
var endpoint_id: String
var instance_id: String
var device_name: String
var port_id: String
var role: String
var label: String
var port_cell: Vector2i
var connection_cell: Vector2i
var connection_distance: int
var outward_direction: Vector2i
var accepted_item_ids: Array[String]
var output_item_order: Array[String]
var source_phase: int
## Some fixed devices need the whole terminal belt to remain on the ordinary
## y-sort plane and use a device-owned patch for the visible insertion seam.
var terminal_belt_overlaps_device := true

var _accept_one: Callable
var _peek_output: Callable
var _take_output: Callable


func _init(
	endpoint_owner: Object = null,
	definition: SliceLogisticsPortDefinition = null,
	accept_one: Callable = Callable(),
	peek_output: Callable = Callable(),
	take_output: Callable = Callable()
) -> void:
	if endpoint_owner == null or definition == null:
		return
	var building := endpoint_owner as SliceBuildingInstance
	if building == null or building.definition == null:
		push_error("Building endpoint owner requires a definition.")
		return
	_bind(
		endpoint_owner,
		definition,
		building.instance_id,
		building.definition.display_name,
		definition.resolved_descriptor(
			building.origin_cell,
			building.definition.footprint,
			building.definition.normalized_rotation(
				building.building_rotation
			)
		),
		accept_one,
		peek_output,
		take_output
	)


static func bind_fixed(
	endpoint_owner: Object,
	definition: SliceLogisticsPortDefinition,
	stable_instance_id: String,
	display_name: String,
	origin_cell: Vector2i,
	footprint: Vector2i,
	rotation: int,
	accept_one: Callable = Callable(),
	peek_output: Callable = Callable(),
	take_output: Callable = Callable()
) -> SliceLogisticsEndpoint:
	var endpoint := SliceLogisticsEndpoint.new()
	endpoint._bind(
		endpoint_owner,
		definition,
		stable_instance_id,
		display_name,
		definition.resolved_descriptor(
			origin_cell, footprint, rotation
		),
		accept_one,
		peek_output,
		take_output
	)
	return endpoint


func _bind(
	endpoint_owner: Object,
	definition: SliceLogisticsPortDefinition,
	stable_instance_id: String,
	display_name: String,
	resolved: Dictionary,
	accept_one: Callable,
	peek_output: Callable,
	take_output: Callable
) -> void:
	owner = endpoint_owner
	port_definition = definition
	instance_id = stable_instance_id
	device_name = display_name
	port_id = definition.id
	endpoint_id = "%s:%s" % [instance_id, port_id]
	role = definition.role
	label = definition.label
	port_cell = Vector2i(resolved["port_cell"])
	connection_cell = Vector2i(resolved["connection_cell"])
	connection_distance = int(resolved["connection_distance"])
	outward_direction = Vector2i(resolved["outward_direction"])
	accepted_item_ids = definition.accepted_item_ids.duplicate()
	output_item_order = definition.output_item_order.duplicate()
	source_phase = definition.source_phase
	_accept_one = accept_one
	_peek_output = peek_output
	_take_output = take_output


func accepts_input() -> bool:
	return port_definition.accepts_input()


func provides_output() -> bool:
	return port_definition.provides_output()


func can_receive_from(conveyor_output: Vector2i) -> bool:
	return accepts_input() and conveyor_output == -outward_direction


func can_supply_to(conveyor_output: Vector2i) -> bool:
	return provides_output() and conveyor_output == outward_direction


func matches_conveyor_direction(conveyor_output: Vector2i) -> bool:
	return (
		can_receive_from(conveyor_output)
		or can_supply_to(conveyor_output)
	)


func try_accept_one(item_id: String) -> int:
	if (
		not accepts_input()
		or not _accept_one.is_valid()
		or (
			not accepted_item_ids.is_empty()
			and not accepted_item_ids.has(item_id)
		)
	):
		return 0
	return clampi(int(_accept_one.call(item_id)), 0, 1)


func peek_output_item() -> String:
	if not provides_output() or not _peek_output.is_valid():
		return ""
	var item_id := String(_peek_output.call())
	if (
		not item_id.is_empty()
		and not output_item_order.is_empty()
		and not output_item_order.has(item_id)
	):
		return ""
	return item_id


func take_output_item(item_id: String) -> bool:
	if (
		not provides_output()
		or not _take_output.is_valid()
		or item_id.is_empty()
	):
		return false
	return int(_take_output.call(item_id)) == 1


func preview_descriptor() -> Dictionary:
	return {
		"endpoint_id": endpoint_id,
		"instance_id": instance_id,
		"device_name": device_name,
		"port_id": port_id,
		"role": role,
		"kind": legacy_kind(),
		"label": label,
		"port_cell": port_cell,
		"connection_cell": connection_cell,
		"connection_distance": connection_distance,
		"outward_direction": outward_direction,
	}


func legacy_kind() -> String:
	if role == SliceLogisticsPortDefinition.ROLE_BIDIRECTIONAL:
		return "storage"
	return role
