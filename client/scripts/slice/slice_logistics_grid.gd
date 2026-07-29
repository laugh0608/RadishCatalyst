class_name SliceLogisticsGrid
extends RefCounted

## L4 world-authoritative belt simulation. Topology is derived from stable
## building cells; only conveyor cargo state is persisted.

const BELT_SPEED_CELLS_PER_SECOND := 1.0
const SIMULATION_STEP_SECONDS := 1.0 / 60.0
const BLOCKED_PROGRESS := 0.999999
const TRANSPORT_ITEM_ORDER := ["crystal", "catalyst"]

var _conveyors: Array[SliceConveyor] = []
var _storages: Array[SliceStorage] = []
var _reactors: Array[SliceReactor] = []
var _conveyor_by_cell := {}
var _storage_by_port_cell := {}
var _source_storage_by_connection_cell := {}
var _reactor_by_input_port_cell := {}
var _source_reactor_by_output_connection_cell := {}
var _simulation_accumulator := 0.0


func rebuild(
	instances: Array[SliceBuildingInstance],
	excluded_instance_id: String = ""
) -> void:
	_conveyors.clear()
	_storages.clear()
	_reactors.clear()
	_conveyor_by_cell.clear()
	_storage_by_port_cell.clear()
	_source_storage_by_connection_cell.clear()
	_reactor_by_input_port_cell.clear()
	_source_reactor_by_output_connection_cell.clear()
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
		elif instance is SliceReactor:
			var reactor := instance as SliceReactor
			_reactors.append(reactor)
			var input_port_cell := (
				reactor.definition.machine_input_port_world_cell(
					reactor.origin_cell, reactor.building_rotation
				)
			)
			_reactor_by_input_port_cell[_cell_key(input_port_cell)] = reactor
			var output_connection_cell := (
				reactor.definition.machine_output_connection_world_cell(
					reactor.origin_cell, reactor.building_rotation
				)
			)
			_source_reactor_by_output_connection_cell[
				_cell_key(output_connection_cell)
			] = reactor
	_conveyors.sort_custom(_instance_before)
	_storages.sort_custom(_instance_before)
	_reactors.sort_custom(_instance_before)
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

	var contenders_by_target := {}
	for conveyor in _conveyors:
		if (
			not conveyor.has_cargo()
			or conveyor.cargo_progress < 1.0
		):
			continue
		var target_conveyor := conveyor_at(conveyor.output_cell())
		if target_conveyor != null:
			if not target_conveyor.has_cargo():
				if not contenders_by_target.has(
					target_conveyor.instance_id
				):
					contenders_by_target[
						target_conveyor.instance_id
					] = []
				contenders_by_target[
					target_conveyor.instance_id
				].append(conveyor)
			else:
				changed = _block_at_output(conveyor) or changed
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
				changed = _block_at_output(conveyor) or changed
			continue

		var target_reactor := reactor_at_input_port(conveyor.output_cell())
		if (
			target_reactor != null
			and _belt_points_into_reactor_input(
				conveyor, target_reactor
			)
		):
			var accepted := 0
			if conveyor.cargo_item_id == SliceReactor.INPUT_ITEM_ID:
				accepted = target_reactor.input_inventory.add(
					conveyor.cargo_item_id, 1
				)
			if accepted == 1:
				conveyor.clear_cargo()
				_append_unique(
					changed_storage_ids, target_reactor.instance_id
				)
				changed = true
			else:
				changed = _block_at_output(conveyor) or changed
			continue

		changed = _block_at_output(conveyor) or changed

	for target_conveyor in _conveyors:
		var raw_contenders: Array = contenders_by_target.get(
			target_conveyor.instance_id, []
		)
		if raw_contenders.is_empty():
			continue
		var winner := _choose_merge_winner(
			target_conveyor, raw_contenders
		)
		for contender in raw_contenders:
			var source := contender as SliceConveyor
			if source != winner:
				changed = _block_at_output(source) or changed
		if winner == null:
			continue
		var item_id := winner.cargo_item_id
		var entry_direction := (
			winner.origin_cell - target_conveyor.origin_cell
		)
		winner.clear_cargo()
		target_conveyor.set_cargo(
			item_id, 0.0, entry_direction
		)
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
		target_conveyor.set_cargo(
			item_id, 0.0, -target_conveyor.output_direction()
		)
		_append_unique(changed_storage_ids, storage.instance_id)
		changed = true

	for reactor in _reactors:
		var connection_cell := (
			reactor.definition.machine_output_connection_world_cell(
				reactor.origin_cell, reactor.building_rotation
			)
		)
		var target_conveyor := conveyor_at(connection_cell)
		if (
			target_conveyor == null
			or target_conveyor.has_cargo()
			or not _belt_points_away_from_reactor_output(
				target_conveyor, reactor
			)
			or reactor.output_inventory.count(
				SliceReactor.OUTPUT_ITEM_ID
			) <= 0
		):
			continue
		if (
			reactor.output_inventory.remove(
				SliceReactor.OUTPUT_ITEM_ID, 1
			)
			!= 1
		):
			continue
		target_conveyor.set_cargo(
			SliceReactor.OUTPUT_ITEM_ID,
			0.0,
			-target_conveyor.output_direction()
		)
		_append_unique(changed_storage_ids, reactor.instance_id)
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


func reactor_at_input_port(cell: Vector2i) -> SliceReactor:
	return (
		_reactor_by_input_port_cell.get(_cell_key(cell))
		as SliceReactor
	)


func source_reactor_at_connection(cell: Vector2i) -> SliceReactor:
	return (
		_source_reactor_by_output_connection_cell.get(_cell_key(cell))
		as SliceReactor
	)


func can_extract_reactor_output(reactor: SliceReactor) -> bool:
	if reactor == null:
		return false
	var connection_cell := (
		reactor.definition.machine_output_connection_world_cell(
			reactor.origin_cell, reactor.building_rotation
		)
	)
	var conveyor := conveyor_at(connection_cell)
	return (
		conveyor != null
		and not conveyor.has_cargo()
		and _belt_points_away_from_reactor_output(conveyor, reactor)
	)


func placement_preview_ports() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for storage in _storages:
		var definition := storage.definition
		result.append(_preview_port(
			storage,
			"storage",
			"IO",
			definition.logistics_port_world_cell(
				storage.origin_cell, storage.building_rotation
			),
			definition.logistics_connection_world_cell(
				storage.origin_cell, storage.building_rotation
			),
			definition.logistics_direction_for_rotation(
				storage.building_rotation
			)
		))
	for reactor in _reactors:
		var definition := reactor.definition
		result.append(_preview_port(
			reactor,
			"input",
			"IN",
			definition.machine_input_port_world_cell(
				reactor.origin_cell, reactor.building_rotation
			),
			definition.machine_input_connection_world_cell(
				reactor.origin_cell, reactor.building_rotation
			),
			definition.machine_input_direction_for_rotation(
				reactor.building_rotation
			)
		))
		result.append(_preview_port(
			reactor,
			"output",
			"OUT",
			definition.machine_output_port_world_cell(
				reactor.origin_cell, reactor.building_rotation
			),
			definition.machine_output_connection_world_cell(
				reactor.origin_cell, reactor.building_rotation
			),
			definition.machine_output_direction_for_rotation(
				reactor.building_rotation
			)
		))
	return result


func conveyor_placement_preview(
	origin_cell: Vector2i,
	rotation: int
) -> Dictionary:
	var output := _conveyor_direction(rotation)
	var nearby: Dictionary = {}
	var nearby_distance := 3
	var exact_ports: Array[Dictionary] = []
	for port in placement_preview_ports():
		var connection_cell := Vector2i(port["connection_cell"])
		if connection_cell == origin_cell:
			exact_ports.append(port)
			continue
		var offset := connection_cell - origin_cell
		var distance := absi(offset.x) + absi(offset.y)
		if distance <= 2 and distance < nearby_distance:
			nearby = port
			nearby_distance = distance
	if not exact_ports.is_empty():
		var source_labels: Array[String] = []
		var sink_labels: Array[String] = []
		for port in exact_ports:
			var kind := String(port["kind"])
			var outward := Vector2i(port["outward_direction"])
			var matched := _port_accepts_direction(
				kind, outward, output
			)
			if not matched:
				return {
					"status": "wrong_direction",
					"message": _placement_message(
						port, output, false
					),
					"instance_id": String(port["instance_id"]),
					"kind": kind,
					"connection_cell": origin_cell,
				}
			var endpoint_label := _placement_endpoint_label(port, output)
			if (
				kind == "output"
				or (kind == "storage" and output == outward)
			):
				source_labels.append(endpoint_label)
			else:
				sink_labels.append(endpoint_label)
		var endpoint_labels: Array[String] = source_labels + sink_labels
		return {
			"status": "connected",
			"message": (
				_placement_message(exact_ports[0], output, true)
				if exact_ports.size() == 1
				else "已连 %s" % " → ".join(endpoint_labels)
			),
			"instance_id": String(exact_ports[0]["instance_id"]),
			"kind": String(exact_ports[0]["kind"]),
			"connection_cell": origin_cell,
		}
	if nearby.is_empty():
		return {
			"status": "none",
			"message": "",
		}
	return {
		"status": "nearby",
		"message": "附近有 %s %s，请放到端口标记格" % [
			String(nearby["device_name"]),
			String(nearby["label"]),
		],
		"instance_id": String(nearby["instance_id"]),
		"kind": String(nearby["kind"]),
		"connection_cell": Vector2i(nearby["connection_cell"]),
	}


func building_status_lines(
	instance: SliceBuildingInstance
) -> Array[String]:
	var result: Array[String] = []
	for port in building_status_snapshot(instance):
		result.append(String(port["text"]))
	return result


func building_status_snapshot(
	instance: SliceBuildingInstance
) -> Array[Dictionary]:
	if instance is SliceStorage:
		return [_storage_status_snapshot(instance as SliceStorage)]
	if instance is SliceReactor:
		var reactor := instance as SliceReactor
		return [
			_reactor_port_status_snapshot(reactor, true),
			_reactor_port_status_snapshot(reactor, false),
		]
	return []


func _preview_port(
	instance: SliceBuildingInstance,
	kind: String,
	label: String,
	port_cell: Vector2i,
	connection_cell: Vector2i,
	outward: Vector2i
) -> Dictionary:
	var conveyor := conveyor_at(connection_cell)
	return {
		"instance_id": instance.instance_id,
		"device_name": instance.definition.display_name,
		"kind": kind,
		"label": label,
		"port_cell": port_cell,
		"connection_cell": connection_cell,
		"outward_direction": outward,
		"connected": (
			conveyor != null
			and _port_accepts_direction(
				kind, outward, conveyor.output_direction()
			)
		),
	}


func _placement_message(
	port: Dictionary,
	output: Vector2i,
	matched: bool
) -> String:
	var device_name := String(port["device_name"])
	var kind := String(port["kind"])
	var label := String(port["label"])
	var outward := Vector2i(port["outward_direction"])
	if not matched:
		return "%s %s 方向错误，按 R 对准箭头" % [device_name, label]
	if kind == "storage":
		return (
			"已对准 %s OUT：从箱内出货"
			% device_name
			if output == outward
			else "已对准 %s IN：向箱内入库" % device_name
		)
	return "已对准 %s %s" % [device_name, label]


func _placement_endpoint_label(
	port: Dictionary,
	output: Vector2i
) -> String:
	var kind := String(port["kind"])
	if kind == "storage":
		var outward := Vector2i(port["outward_direction"])
		return "%s %s" % [
			String(port["device_name"]),
			"OUT" if output == outward else "IN",
		]
	return "%s %s" % [
		String(port["device_name"]),
		String(port["label"]),
	]


func _storage_status_snapshot(storage: SliceStorage) -> Dictionary:
	var definition := storage.definition
	var connection_cell := definition.logistics_connection_world_cell(
		storage.origin_cell, storage.building_rotation
	)
	var conveyor := conveyor_at(connection_cell)
	if conveyor == null:
		return {
			"kind": "storage",
			"label": "IO",
			"state": "unconnected",
			"tone": "warning",
			"title": "物流口未连接",
			"detail": "把传送带接到舱口外的 IO 标记格",
			"text": "物流口：未接传送带（请接舱口外的 IO 标记格）",
		}
	var outward := definition.logistics_direction_for_rotation(
		storage.building_rotation
	)
	if conveyor.output_direction() == outward:
		return {
			"kind": "storage",
			"label": "OUT",
			"state": "connected_output",
			"tone": "ready",
			"title": "OUT 已连接",
			"detail": "传送带会从箱内取货",
			"text": "物流口：已接 OUT（从箱内出货）",
		}
	if conveyor.output_direction() == -outward:
		return {
			"kind": "storage",
			"label": "IN",
			"state": "connected_input",
			"tone": "ready",
			"title": "IN 已连接",
			"detail": "传送带会向箱内送货",
			"text": "物流口：已接 IN（向箱内入库）",
		}
	return {
		"kind": "storage",
		"label": "IO",
		"state": "wrong_direction",
		"tone": "fault",
		"title": "物流方向错误",
		"detail": "按 R 旋转传送带，使箭头沿舱口方向",
		"text": "物流口：方向错误（传送带需沿舱口箭头）",
	}


func _reactor_port_status_snapshot(
	reactor: SliceReactor,
	input_port: bool
) -> Dictionary:
	var definition := reactor.definition
	var connection_cell := (
		definition.machine_input_connection_world_cell(
			reactor.origin_cell, reactor.building_rotation
		)
		if input_port
		else definition.machine_output_connection_world_cell(
			reactor.origin_cell, reactor.building_rotation
		)
	)
	var outward := (
		definition.machine_input_direction_for_rotation(
			reactor.building_rotation
		)
		if input_port
		else definition.machine_output_direction_for_rotation(
			reactor.building_rotation
		)
	)
	var conveyor := conveyor_at(connection_cell)
	var label := "IN" if input_port else "OUT"
	if conveyor == null:
		return {
			"kind": "input" if input_port else "output",
			"label": label,
			"state": "unconnected",
			"tone": "warning",
			"title": "%s 未连接" % label,
			"detail": "把传送带接到对应的端口标记格",
			"text": "%s：未接传送带（请接端口标记格）" % label,
		}
	var expected := -outward if input_port else outward
	if conveyor.output_direction() == expected:
		return {
			"kind": "input" if input_port else "output",
			"label": label,
			"state": "connected",
			"tone": "ready",
			"title": "%s 已连接" % label,
			"detail": (
				"晶体可送入反应器"
				if input_port
				else "催化剂可从反应器送出"
			),
			"text": "%s：已接" % label,
		}
	return {
		"kind": "input" if input_port else "output",
		"label": label,
		"state": "wrong_direction",
		"tone": "fault",
		"title": "%s 方向错误" % label,
		"detail": "按 R 旋转传送带，使箭头对准端口",
		"text": "%s：方向错误（按箭头旋转传送带）" % label,
	}


func _conveyor_direction(rotation: int) -> Vector2i:
	return SliceConveyor.DIRECTION_ORDER[posmod(rotation, 4)]


func _port_accepts_direction(
	kind: String,
	outward: Vector2i,
	output: Vector2i
) -> bool:
	if kind == "storage":
		return output == outward or output == -outward
	if kind == "input":
		return output == -outward
	return output == outward


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
				SliceConveyor.TOPOLOGY_SOURCE_ENDPOINT, [-output]
			)
			_restore_cargo_entry_direction(conveyor)
			continue

		var source_reactor := source_reactor_at_connection(
			conveyor.origin_cell
		)
		if (
			source_reactor != null
			and _belt_points_away_from_reactor_output(
				conveyor, source_reactor
			)
		):
			conveyor.set_topology_visual(
				SliceConveyor.TOPOLOGY_SOURCE_ENDPOINT, [-output]
			)
			_restore_cargo_entry_direction(conveyor)
			continue

		var sink_storage := storage_at_port(conveyor.output_cell())
		if (
			sink_storage != null
			and _belt_points_into_storage(conveyor, sink_storage)
		):
			conveyor.set_topology_visual(
				SliceConveyor.TOPOLOGY_SINK_ENDPOINT, [-output]
			)
			_restore_cargo_entry_direction(conveyor)
			continue

		var sink_reactor := reactor_at_input_port(conveyor.output_cell())
		if (
			sink_reactor != null
			and _belt_points_into_reactor_input(
				conveyor, sink_reactor
			)
		):
			conveyor.set_topology_visual(
				SliceConveyor.TOPOLOGY_SINK_ENDPOINT, [-output]
			)
			_restore_cargo_entry_direction(conveyor)
			continue

		var input_directions := _input_directions(conveyor)
		if input_directions.size() >= 2:
			conveyor.set_topology_visual(
				SliceConveyor.TOPOLOGY_MERGE, input_directions
			)
		elif (
			input_directions.size() == 1
			and (
				input_directions[0].x * output.x
				+ input_directions[0].y * output.y
				== 0
			)
		):
			conveyor.set_topology_visual(
				SliceConveyor.TOPOLOGY_TURN, input_directions
			)
		else:
			conveyor.set_topology_visual(
				SliceConveyor.TOPOLOGY_STRAIGHT, [-output]
			)
		_restore_cargo_entry_direction(conveyor)


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


func _input_conveyors(conveyor: SliceConveyor) -> Array[SliceConveyor]:
	var result: Array[SliceConveyor] = []
	for direction in _input_directions(conveyor):
		var upstream := conveyor_at(conveyor.origin_cell + direction)
		if upstream != null:
			result.append(upstream)
	result.sort_custom(_instance_before)
	return result


func _choose_merge_winner(
	target: SliceConveyor,
	raw_contenders: Array
) -> SliceConveyor:
	var contenders: Array[SliceConveyor] = []
	for value in raw_contenders:
		contenders.append(value as SliceConveyor)
	contenders.sort_custom(_instance_before)
	var upstreams := _input_conveyors(target)
	if upstreams.is_empty():
		return contenders[0] if not contenders.is_empty() else null

	var start := posmod(target.merge_cursor, upstreams.size())
	for offset in range(upstreams.size()):
		var index := (start + offset) % upstreams.size()
		var candidate := upstreams[index]
		if contenders.has(candidate):
			target.merge_cursor = (index + 1) % upstreams.size()
			return candidate
	return contenders[0] if not contenders.is_empty() else null


func _restore_cargo_entry_direction(conveyor: SliceConveyor) -> void:
	if not conveyor.has_cargo():
		return
	var upstreams := _input_conveyors(conveyor)
	if (
		conveyor.topology_kind() == SliceConveyor.TOPOLOGY_MERGE
		and upstreams.size() >= 2
	):
		var last_index := posmod(
			conveyor.merge_cursor - 1, upstreams.size()
		)
		conveyor.set_cargo_entry_direction(
			upstreams[last_index].origin_cell - conveyor.origin_cell
		)
		return
	conveyor.set_cargo_entry_direction(conveyor.entry_direction())


func _block_at_output(conveyor: SliceConveyor) -> bool:
	if conveyor.cargo_progress == BLOCKED_PROGRESS:
		return false
	conveyor.set_cargo_progress(BLOCKED_PROGRESS)
	return true


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


func _belt_points_into_reactor_input(
	conveyor: SliceConveyor,
	reactor: SliceReactor
) -> bool:
	var outward := (
		reactor.definition.machine_input_direction_for_rotation(
			reactor.building_rotation
		)
	)
	return conveyor.output_direction() == -outward


func _belt_points_away_from_reactor_output(
	conveyor: SliceConveyor,
	reactor: SliceReactor
) -> bool:
	var outward := (
		reactor.definition.machine_output_direction_for_rotation(
			reactor.building_rotation
		)
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
