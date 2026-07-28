class_name SlicePowerGrid
extends RefCounted

## Derived binary reachability graph for L3. Only powered relay ids and relay
## positions are retained; saves contain building topology, never graph edges or
## powered booleans.

const RELAY_LINK_RANGE_CELLS := 6.0
const DEVICE_SUPPLY_RANGE_CELLS := 4.0
const CORE_NODE_ID := "__core__"

var _tile_size := 32.0
var _core_online := false
var _core_position := Vector2.ZERO
var _relay_positions: Dictionary = {}
var _powered_relay_ids: Dictionary = {}
var _relay_parent_ids: Dictionary = {}
var _powered_connections: Array[Dictionary] = []


func rebuild(
	core_online: bool,
	core_position: Vector2,
	tile_size: float,
	buildings: Array[SliceBuildingInstance],
	excluded_instance_id: String = ""
) -> void:
	_tile_size = tile_size
	_core_online = core_online
	_core_position = core_position
	_relay_positions.clear()
	_powered_relay_ids.clear()
	_relay_parent_ids.clear()
	_powered_connections.clear()
	for instance in buildings:
		if instance.instance_id == excluded_instance_id:
			continue
		if (
			instance.definition != null
			and instance.definition.power_role
			== SliceBuildingDefinition.POWER_RELAY
		):
			_relay_positions[instance.instance_id] = (
				instance.definition.block_center(
					instance.origin_cell,
					_tile_size,
					instance.building_rotation
				)
			)
	if not _core_online:
		return

	var pending_ids: Array[String] = []
	for instance_id in _relay_positions:
		pending_ids.append(String(instance_id))
	pending_ids.sort()
	while not pending_ids.is_empty():
		var connected_ids: Array[String] = []
		for instance_id in pending_ids:
			var position: Vector2 = _relay_positions[instance_id]
			var parent_id := _connection_parent_for(position)
			if parent_id.is_empty():
				continue
			_powered_relay_ids[instance_id] = true
			_relay_parent_ids[instance_id] = parent_id
			connected_ids.append(instance_id)
		if connected_ids.is_empty():
			break
		for instance_id in connected_ids:
			pending_ids.erase(instance_id)
	_rebuild_powered_connections()


func can_connect_relay_at(world_position: Vector2) -> bool:
	if not _core_online:
		return false
	return (
		_is_within_cells(
			world_position, _core_position, RELAY_LINK_RANGE_CELLS
		)
		or _within_any_powered_relay(world_position, RELAY_LINK_RANGE_CELLS)
	)


func is_relay_powered(instance_id: String) -> bool:
	return _powered_relay_ids.has(instance_id)


func is_consumer_powered(instance: SliceBuildingInstance) -> bool:
	if not _core_online or instance.definition == null:
		return false
	var port_position := instance.definition.power_port_world_position(
		instance.origin_cell, _tile_size, instance.building_rotation
	)
	if _is_within_cells(
		port_position, _core_position, RELAY_LINK_RANGE_CELLS
	):
		return true
	return _within_any_powered_relay(
		port_position, DEVICE_SUPPLY_RANGE_CELLS
	)


func powered_relay_count() -> int:
	return _powered_relay_ids.size()


func powered_connections() -> Array[Dictionary]:
	return _powered_connections.duplicate(true)


func placement_preview_nodes() -> Array[Dictionary]:
	var nodes: Array[Dictionary] = []
	if not _core_online:
		return nodes
	nodes.append({
		"id": CORE_NODE_ID,
		"position": _core_position,
		"device_range_cells": RELAY_LINK_RANGE_CELLS,
	})
	var relay_ids: Array[String] = []
	for instance_id in _powered_relay_ids:
		relay_ids.append(String(instance_id))
	relay_ids.sort()
	for instance_id in relay_ids:
		nodes.append({
			"id": instance_id,
			"position": _relay_positions[instance_id] as Vector2,
			"device_range_cells": DEVICE_SUPPLY_RANGE_CELLS,
		})
	return nodes


func _connection_parent_for(world_position: Vector2) -> String:
	if _is_within_cells(
		world_position, _core_position, RELAY_LINK_RANGE_CELLS
	):
		return CORE_NODE_ID
	var best_id := ""
	var best_distance := INF
	var powered_ids: Array[String] = []
	for instance_id in _powered_relay_ids:
		powered_ids.append(String(instance_id))
	powered_ids.sort()
	for instance_id in powered_ids:
		var relay_position: Vector2 = _relay_positions[instance_id]
		var distance := world_position.distance_to(relay_position)
		if distance > RELAY_LINK_RANGE_CELLS * _tile_size + 0.001:
			continue
		if distance < best_distance:
			best_id = instance_id
			best_distance = distance
	return best_id


func _rebuild_powered_connections() -> void:
	var child_ids: Array[String] = []
	for instance_id in _relay_parent_ids:
		child_ids.append(String(instance_id))
	child_ids.sort()
	for child_id in child_ids:
		var parent_id := String(_relay_parent_ids[child_id])
		var parent_position := (
			_core_position
			if parent_id == CORE_NODE_ID
			else _relay_positions[parent_id] as Vector2
		)
		_powered_connections.append({
			"parent_id": parent_id,
			"child_id": child_id,
			"from_position": parent_position,
			"to_position": _relay_positions[child_id] as Vector2,
		})


func _within_any_powered_relay(
	world_position: Vector2,
	range_cells: float
) -> bool:
	for instance_id in _powered_relay_ids:
		var relay_position: Vector2 = _relay_positions[instance_id]
		if _is_within_cells(world_position, relay_position, range_cells):
			return true
	return false


func _is_within_cells(
	a: Vector2,
	b: Vector2,
	range_cells: float
) -> bool:
	return a.distance_to(b) <= range_cells * _tile_size + 0.001
