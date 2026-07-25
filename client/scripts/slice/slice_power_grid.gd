class_name SlicePowerGrid
extends RefCounted

## Derived binary reachability graph for L3. Only powered relay ids and relay
## positions are retained; saves contain building topology, never graph edges or
## powered booleans.

const RELAY_LINK_RANGE_CELLS := 6.0
const DEVICE_SUPPLY_RANGE_CELLS := 4.0

var _tile_size := 32.0
var _core_online := false
var _core_position := Vector2.ZERO
var _relay_positions: Dictionary = {}
var _powered_relay_ids: Dictionary = {}


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
	for instance in buildings:
		if instance.instance_id == excluded_instance_id:
			continue
		if (
			instance.definition != null
			and instance.definition.power_role
			== SliceBuildingDefinition.POWER_RELAY
		):
			_relay_positions[instance.instance_id] = instance.position
	if not _core_online:
		return

	var changed := true
	while changed:
		changed = false
		for instance_id in _relay_positions:
			if _powered_relay_ids.has(instance_id):
				continue
			var position: Vector2 = _relay_positions[instance_id]
			if _is_within_cells(
				position, _core_position, RELAY_LINK_RANGE_CELLS
			) or _within_any_powered_relay(position, RELAY_LINK_RANGE_CELLS):
				_powered_relay_ids[instance_id] = true
				changed = true


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
