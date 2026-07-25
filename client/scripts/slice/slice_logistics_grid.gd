class_name SliceLogisticsGrid
extends RefCounted

## L4 world-authoritative belt simulation. Topology is derived from stable
## building cells; only conveyor cargo state is persisted.

const BELT_SPEED_CELLS_PER_SECOND := 1.0
const SIMULATION_STEP_SECONDS := 1.0 / 60.0
const BLOCKED_PROGRESS := 0.999999
const TRANSPORT_ITEM_ORDER := ["crystal"]

var _conveyors: Array[SliceConveyor] = []
var _storages: Array[SliceStorage] = []
var _conveyor_by_cell := {}
var _storage_by_port_cell := {}
var _source_storage_by_connection_cell := {}
var _simulation_accumulator := 0.0


func rebuild(
	instances: Array[SliceBuildingInstance],
	excluded_instance_id: String = ""
) -> void:
	_conveyors.clear()
	_storages.clear()
	_conveyor_by_cell.clear()
	_storage_by_port_cell.clear()
	_source_storage_by_connection_cell.clear()
	_simulation_accumulator = 0.0

	for instance in instances:
		if instance.instance_id == excluded_instance_id:
			continue
		if instance is SliceConveyor:
			var conveyor := instance as SliceConveyor
			_conveyors.append(conveyor)
			_conveyor_by_cell[_cell_key(conveyor.origin_cell)] = conveyor
		elif instance is SliceStorage:
			var storage := instance as SliceStorage
			_storages.append(storage)
			var port_cell := storage.definition.logistics_port_world_cell(
				storage.origin_cell, storage.building_rotation
			)
			_storage_by_port_cell[_cell_key(port_cell)] = storage
			var connection_cell := (
				storage.definition.logistics_connection_world_cell(
					storage.origin_cell, storage.building_rotation
				)
			)
			_source_storage_by_connection_cell[
				_cell_key(connection_cell)
			] = storage
	_conveyors.sort_custom(_instance_before)
	_storages.sort_custom(_instance_before)
	_refresh_conveyor_topologies()


func tick(delta: float) -> Dictionary:
	if delta <= 0.0:
		return _result(false, [])
	_simulation_accumulator += delta
	var changed := false
	var changed_storage_ids: Array[String] = []
	while _simulation_accumulator + 0.0000001 >= SIMULATION_STEP_SECONDS:
		_simulation_accumulator -= SIMULATION_STEP_SECONDS
		var step_result := _tick_step(SIMULATION_STEP_SECONDS)
		changed = changed or bool(step_result.get("changed", false))
		for instance_id in step_result.get("storage_ids", []):
			_append_unique(changed_storage_ids, String(instance_id))
	return _result(changed, changed_storage_ids)


func _tick_step(delta: float) -> Dictionary:
	var changed := false
	var changed_storage_ids: Array[String] = []
	for conveyor in _conveyors:
		if not conveyor.has_cargo():
			continue
		var next_progress := minf(
			1.0,
			conveyor.cargo_progress
			+ BELT_SPEED_CELLS_PER_SECOND * delta
		)
		if next_progress > conveyor.cargo_progress:
			conveyor.set_cargo_progress(next_progress)
			changed = true

	var reserved_targets := {}
	for conveyor in _conveyors:
		if (
			not conveyor.has_cargo()
			or conveyor.cargo_progress < 1.0
		):
			continue
		var target_conveyor := conveyor_at(conveyor.output_cell())
		if target_conveyor != null:
			if (
				not target_conveyor.has_cargo()
				and not reserved_targets.has(target_conveyor.instance_id)
			):
				var item_id := conveyor.cargo_item_id
				conveyor.clear_cargo()
				target_conveyor.set_cargo(item_id, 0.0)
				reserved_targets[target_conveyor.instance_id] = true
				changed = true
			else:
				if conveyor.cargo_progress != BLOCKED_PROGRESS:
					conveyor.set_cargo_progress(BLOCKED_PROGRESS)
					changed = true
			continue

		var target_storage := storage_at_port(conveyor.output_cell())
		if target_storage != null and _belt_points_into_storage(
			conveyor, target_storage
		):
			var stored := target_storage.inventory.add(
				conveyor.cargo_item_id, 1
			)
			if stored == 1:
				conveyor.clear_cargo()
				_append_unique(
					changed_storage_ids, target_storage.instance_id
				)
				changed = true
			else:
				if conveyor.cargo_progress != BLOCKED_PROGRESS:
					conveyor.set_cargo_progress(BLOCKED_PROGRESS)
					changed = true
			continue

		if conveyor.cargo_progress != BLOCKED_PROGRESS:
			conveyor.set_cargo_progress(BLOCKED_PROGRESS)
			changed = true

	for storage in _storages:
		var connection_cell := (
			storage.definition.logistics_connection_world_cell(
				storage.origin_cell, storage.building_rotation
			)
		)
		var target_conveyor := conveyor_at(connection_cell)
		if (
			target_conveyor == null
			or target_conveyor.has_cargo()
			or not _belt_points_away_from_storage(
				target_conveyor, storage
			)
		):
			continue
		var item_id := _first_transport_item(storage)
		if item_id.is_empty():
			continue
		if storage.inventory.remove(item_id, 1) != 1:
			continue
		target_conveyor.set_cargo(item_id, 0.0)
		_append_unique(changed_storage_ids, storage.instance_id)
		changed = true

	if not changed_storage_ids.is_empty():
		changed = true
	return _result(changed, changed_storage_ids)


func conveyor_at(cell: Vector2i) -> SliceConveyor:
	return _conveyor_by_cell.get(_cell_key(cell)) as SliceConveyor


func storage_at_port(cell: Vector2i) -> SliceStorage:
	return _storage_by_port_cell.get(_cell_key(cell)) as SliceStorage


func source_storage_at_connection(cell: Vector2i) -> SliceStorage:
	return (
		_source_storage_by_connection_cell.get(_cell_key(cell))
		as SliceStorage
	)


func _refresh_conveyor_topologies() -> void:
	for conveyor in _conveyors:
		var output := conveyor.output_direction()
		var source_storage := source_storage_at_connection(
			conveyor.origin_cell
		)
		if (
			source_storage != null
			and _belt_points_away_from_storage(
				conveyor, source_storage
			)
		):
			conveyor.set_topology_visual(
				SliceConveyor.TOPOLOGY_SOURCE_ENDPOINT, -output
			)
			continue

		var sink_storage := storage_at_port(conveyor.output_cell())
		if (
			sink_storage != null
			and _belt_points_into_storage(conveyor, sink_storage)
		):
			conveyor.set_topology_visual(
				SliceConveyor.TOPOLOGY_SINK_ENDPOINT, -output
			)
			continue

		var input_directions := _input_directions(conveyor)
		if (
			input_directions.size() == 1
			and (
				input_directions[0].x * output.x
				+ input_directions[0].y * output.y
				== 0
			)
		):
			conveyor.set_topology_visual(
				SliceConveyor.TOPOLOGY_TURN, input_directions[0]
			)
		else:
			conveyor.set_topology_visual(
				SliceConveyor.TOPOLOGY_STRAIGHT, -output
			)


func _input_directions(conveyor: SliceConveyor) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for direction in [
		Vector2i.UP,
		Vector2i.RIGHT,
		Vector2i.DOWN,
		Vector2i.LEFT,
	]:
		if direction == conveyor.output_direction():
			continue
		var upstream := conveyor_at(conveyor.origin_cell + direction)
		if upstream != null and upstream.output_cell() == conveyor.origin_cell:
			result.append(direction)
	return result


func _belt_points_into_storage(
	conveyor: SliceConveyor,
	storage: SliceStorage
) -> bool:
	var outward := storage.definition.logistics_direction_for_rotation(
		storage.building_rotation
	)
	return conveyor.output_direction() == -outward


func _belt_points_away_from_storage(
	conveyor: SliceConveyor,
	storage: SliceStorage
) -> bool:
	var outward := storage.definition.logistics_direction_for_rotation(
		storage.building_rotation
	)
	return conveyor.output_direction() == outward


func _first_transport_item(storage: SliceStorage) -> String:
	for item_id in TRANSPORT_ITEM_ORDER:
		if storage.inventory.count(item_id) > 0:
			return item_id
	return ""


func _instance_before(
	left: SliceBuildingInstance,
	right: SliceBuildingInstance
) -> bool:
	return left.instance_id < right.instance_id


func _append_unique(values: Array[String], value: String) -> void:
	if not values.has(value):
		values.append(value)


func _cell_key(cell: Vector2i) -> String:
	return "%d:%d" % [cell.x, cell.y]


func _result(changed: bool, storage_ids: Array[String]) -> Dictionary:
	return {
		"changed": changed,
		"storage_ids": storage_ids,
	}
