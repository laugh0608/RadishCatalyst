class_name SliceLogisticsGrid
extends RefCounted

## L4 world-authoritative belt simulation. Topology is derived from stable
## building cells; only conveyor cargo state is persisted.

const BELT_SPEED_CELLS_PER_SECOND := 1.0
const SIMULATION_STEP_SECONDS := 1.0 / 60.0
const BLOCKED_PROGRESS := 0.999999

var _conveyors: Array[SliceConveyor] = []
var _endpoints: Array[SliceLogisticsEndpoint] = []
var _source_endpoints: Array[SliceLogisticsEndpoint] = []
var _conveyor_by_cell := {}
var _sink_endpoints_by_port_cell := {}
var _sink_endpoints_by_connection_cell := {}
var _source_endpoints_by_connection_cell := {}
var _endpoints_by_instance_id := {}
var _simulation_accumulator := 0.0


func rebuild(
	instances: Array[SliceBuildingInstance],
	excluded_instance_id: String = "",
	external_endpoints: Array[SliceLogisticsEndpoint] = []
) -> void:
	_conveyors.clear()
	_endpoints.clear()
	_source_endpoints.clear()
	_conveyor_by_cell.clear()
	_sink_endpoints_by_port_cell.clear()
	_sink_endpoints_by_connection_cell.clear()
	_source_endpoints_by_connection_cell.clear()
	_endpoints_by_instance_id.clear()
	_simulation_accumulator = 0.0

	for instance in instances:
		if instance.instance_id == excluded_instance_id:
			continue
		if instance is SliceConveyor:
			var conveyor := instance as SliceConveyor
			_conveyors.append(conveyor)
			_conveyor_by_cell[_cell_key(conveyor.origin_cell)] = conveyor
			continue
		for endpoint in instance.logistics_endpoints():
			_register_endpoint(endpoint)
	for endpoint in external_endpoints:
		_register_endpoint(endpoint)
	_conveyors.sort_custom(_instance_before)
	_endpoints.sort_custom(_endpoint_before)
	_source_endpoints.sort_custom(_endpoint_before)
	_sort_endpoint_indexes()
	_refresh_conveyor_topologies()
	_refresh_endpoint_visuals(
		instances, excluded_instance_id, external_endpoints
	)


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

		var target_endpoint := _sink_endpoint_at_connection(
			conveyor.origin_cell, conveyor.output_direction()
		)
		if target_endpoint != null:
			var accepted := target_endpoint.try_accept_one(
				conveyor.cargo_item_id
			)
			if accepted == 1:
				conveyor.clear_cargo()
				_append_unique(
					changed_storage_ids, target_endpoint.instance_id
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

	for endpoint in _source_endpoints:
		var target_conveyor := conveyor_at(endpoint.connection_cell)
		if (
			target_conveyor == null
			or target_conveyor.has_cargo()
			or not endpoint.can_supply_to(
				target_conveyor.output_direction()
			)
		):
			continue
		var item_id := endpoint.peek_output_item()
		if item_id.is_empty():
			continue
		if not endpoint.take_output_item(item_id):
			continue
		target_conveyor.set_cargo(
			item_id, 0.0, -target_conveyor.output_direction()
		)
		_append_unique(changed_storage_ids, endpoint.instance_id)
		changed = true

	if not changed_storage_ids.is_empty():
		changed = true
	return _result(changed, changed_storage_ids)


func conveyor_at(cell: Vector2i) -> SliceConveyor:
	return _conveyor_by_cell.get(_cell_key(cell)) as SliceConveyor


func storage_at_port(cell: Vector2i) -> SliceStorage:
	for endpoint in _sink_endpoints_at_cell(cell):
		if endpoint.owner is SliceStorage:
			return endpoint.owner as SliceStorage
	return null


func source_storage_at_connection(cell: Vector2i) -> SliceStorage:
	for endpoint in _source_endpoints_at_cell(cell):
		if endpoint.owner is SliceStorage:
			return endpoint.owner as SliceStorage
	return null


func reactor_at_input_port(cell: Vector2i) -> SliceReactor:
	for endpoint in _sink_endpoints_at_cell(cell):
		if endpoint.owner is SliceReactor:
			return endpoint.owner as SliceReactor
	return null


func source_reactor_at_connection(cell: Vector2i) -> SliceReactor:
	for endpoint in _source_endpoints_at_cell(cell):
		if endpoint.owner is SliceReactor:
			return endpoint.owner as SliceReactor
	return null


func can_extract_reactor_output(reactor: SliceReactor) -> bool:
	if reactor == null:
		return false
	var endpoint := _endpoint_for_instance_port(
		reactor.instance_id, "output"
	)
	if endpoint == null:
		for candidate in reactor.logistics_endpoints():
			if candidate.port_id == "output":
				endpoint = candidate
				break
	if endpoint == null:
		return false
	var conveyor := conveyor_at(endpoint.connection_cell)
	return (
		conveyor != null
		and not conveyor.has_cargo()
		and endpoint.can_supply_to(conveyor.output_direction())
	)


func placement_preview_ports() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for endpoint in _endpoints:
		result.append(_preview_port(endpoint))
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
	var result: Array[Dictionary] = []
	if instance == null:
		return result
	var endpoints := _endpoints_for_instance(instance.instance_id)
	if endpoints.is_empty():
		endpoints = instance.logistics_endpoints()
	for endpoint in endpoints:
		result.append(_endpoint_status_snapshot(endpoint))
	return result


func _preview_port(
	endpoint: SliceLogisticsEndpoint
) -> Dictionary:
	var conveyor := conveyor_at(endpoint.connection_cell)
	return {
		"instance_id": endpoint.instance_id,
		"device_name": endpoint.device_name,
		"kind": endpoint.legacy_kind(),
		"label": endpoint.label,
		"port_cell": endpoint.port_cell,
		"connection_cell": endpoint.connection_cell,
		"outward_direction": endpoint.outward_direction,
		"connected": (
			conveyor != null
			and endpoint.matches_conveyor_direction(
				conveyor.output_direction()
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


func _endpoint_status_snapshot(
	endpoint: SliceLogisticsEndpoint
) -> Dictionary:
	if endpoint.instance_id == SliceCoreLogistics.INSTANCE_ID:
		return _core_port_status_snapshot(endpoint)
	if (
		endpoint.role
		== SliceLogisticsPortDefinition.ROLE_BIDIRECTIONAL
	):
		return _storage_status_snapshot(endpoint)
	if endpoint.owner is SliceStorage:
		return _fixed_storage_port_status_snapshot(endpoint)
	if endpoint.owner is SliceCollector:
		return _collector_port_status_snapshot(endpoint)
	return _reactor_port_status_snapshot(endpoint)


func _core_port_status_snapshot(
	endpoint: SliceLogisticsEndpoint
) -> Dictionary:
	var input_port := (
		endpoint.role == SliceLogisticsPortDefinition.ROLE_INPUT
	)
	return _fixed_port_status_snapshot(
		endpoint,
		(
			"可运输物品会存入核心仓库"
			if input_port
			else "核心仓库按稳定物品顺序输出"
		),
		"把传送带接到核心固定%s标记格" % (
			" IN " if input_port else " OUT "
		)
	)


func _fixed_storage_port_status_snapshot(
	endpoint: SliceLogisticsEndpoint
) -> Dictionary:
	var input_port := (
		endpoint.role == SliceLogisticsPortDefinition.ROLE_INPUT
	)
	return _fixed_port_status_snapshot(
		endpoint,
		(
			"传送带可在断电时继续向箱内送货"
			if input_port
			else "通电后只输出当前选中的供给物品"
		),
		"把传送带接到储物箱固定%s标记格" % (
			" IN " if input_port else " OUT "
		)
	)


func _collector_port_status_snapshot(
	endpoint: SliceLogisticsEndpoint
) -> Dictionary:
	return _fixed_port_status_snapshot(
		endpoint,
		"通电后会从采集缓冲输出晶体",
		"把传送带接到采集器右侧 OUT 标记格"
	)


func _fixed_port_status_snapshot(
	endpoint: SliceLogisticsEndpoint,
	connected_detail: String,
	unconnected_detail: String
) -> Dictionary:
	var input_port := (
		endpoint.role == SliceLogisticsPortDefinition.ROLE_INPUT
	)
	var kind := "input" if input_port else "output"
	var conveyor := conveyor_at(endpoint.connection_cell)
	if conveyor == null:
		return {
			"kind": kind,
			"label": endpoint.label,
			"state": "unconnected",
			"tone": "warning",
			"title": "%s 未连接" % endpoint.label,
			"detail": unconnected_detail,
			"text": "%s：未接传送带（请接端口标记格）" % endpoint.label,
		}
	var expected := (
		-endpoint.outward_direction
		if input_port
		else endpoint.outward_direction
	)
	if conveyor.output_direction() == expected:
		return {
			"kind": kind,
			"label": endpoint.label,
			"state": "connected",
			"tone": "ready",
			"title": "%s 已连接" % endpoint.label,
			"detail": connected_detail,
			"text": "%s：已接" % endpoint.label,
		}
	return {
		"kind": kind,
		"label": endpoint.label,
		"state": "wrong_direction",
		"tone": "fault",
		"title": "%s 方向错误" % endpoint.label,
		"detail": "按 R 旋转传送带，使箭头对准端口",
		"text": "%s：方向错误（按箭头旋转传送带）" % endpoint.label,
	}


func _storage_status_snapshot(
	endpoint: SliceLogisticsEndpoint
) -> Dictionary:
	var conveyor := conveyor_at(endpoint.connection_cell)
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
	if conveyor.output_direction() == endpoint.outward_direction:
		return {
			"kind": "storage",
			"label": "OUT",
			"state": "connected_output",
			"tone": "ready",
			"title": "OUT 已连接",
			"detail": "传送带会从箱内取货",
			"text": "物流口：已接 OUT（从箱内出货）",
		}
	if conveyor.output_direction() == -endpoint.outward_direction:
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
	endpoint: SliceLogisticsEndpoint
) -> Dictionary:
	var input_port := (
		endpoint.role == SliceLogisticsPortDefinition.ROLE_INPUT
	)
	var conveyor := conveyor_at(endpoint.connection_cell)
	var label := endpoint.label
	if conveyor == null:
		return {
			"kind": "input" if input_port else "output",
			"label": label,
			"state": "unconnected",
			"tone": "warning",
			"title": "%s 未连接" % label,
			"detail": "接入对应 %s 标记格" % label,
			"text": "%s：未接传送带（请接端口标记格）" % label,
		}
	var expected := (
		-endpoint.outward_direction
		if input_port
		else endpoint.outward_direction
	)
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
		var source_endpoint := _source_endpoint_at(
			conveyor.origin_cell, output
		)
		if source_endpoint != null:
			conveyor.set_topology_visual(
				SliceConveyor.TOPOLOGY_SOURCE_ENDPOINT,
				[-output],
				source_endpoint.terminal_belt_overlaps_device
			)
			_restore_cargo_entry_direction(conveyor)
			continue

		var sink_endpoint := _sink_endpoint_at_connection(
			conveyor.origin_cell, output
		)
		if sink_endpoint != null:
			conveyor.set_topology_visual(
				SliceConveyor.TOPOLOGY_SINK_ENDPOINT,
				[-output],
				sink_endpoint.terminal_belt_overlaps_device
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


func _refresh_endpoint_visuals(
	instances: Array[SliceBuildingInstance],
	excluded_instance_id: String,
	external_endpoints: Array[SliceLogisticsEndpoint]
) -> void:
	for instance in instances:
		var connected_port_ids: Array[String] = []
		if instance.instance_id != excluded_instance_id:
			for endpoint in _endpoints_for_instance(instance.instance_id):
				var conveyor := conveyor_at(endpoint.connection_cell)
				if (
					conveyor != null
					and endpoint.matches_conveyor_direction(
						conveyor.output_direction()
					)
				):
					connected_port_ids.append(endpoint.port_id)
		instance.set_connected_logistics_port_visuals(connected_port_ids)
	var external_visual_owners: Array[Object] = []
	for endpoint in external_endpoints:
		if (
			endpoint.owner != null
			and not external_visual_owners.has(endpoint.owner)
		):
			external_visual_owners.append(endpoint.owner)
	for owner in external_visual_owners:
		if owner == null or not owner.has_method(
			"set_connected_logistics_port_visuals"
		):
			continue
		var connected_port_ids: Array[String] = []
		for endpoint in _endpoints:
			if endpoint.owner != owner:
				continue
			var conveyor := conveyor_at(endpoint.connection_cell)
			if (
				conveyor != null
				and endpoint.matches_conveyor_direction(
					conveyor.output_direction()
				)
			):
				connected_port_ids.append(endpoint.port_id)
		owner.call(
			"set_connected_logistics_port_visuals",
			connected_port_ids
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


func _register_endpoint(endpoint: SliceLogisticsEndpoint) -> void:
	_endpoints.append(endpoint)
	var per_instance: Array = _endpoints_by_instance_id.get(
		endpoint.instance_id, []
	)
	per_instance.append(endpoint)
	_endpoints_by_instance_id[endpoint.instance_id] = per_instance
	if endpoint.accepts_input():
		_append_endpoint_index(
			_sink_endpoints_by_port_cell, endpoint.port_cell, endpoint
		)
		_append_endpoint_index(
			_sink_endpoints_by_connection_cell,
			endpoint.connection_cell,
			endpoint
		)
	if endpoint.provides_output():
		_source_endpoints.append(endpoint)
		_append_endpoint_index(
			_source_endpoints_by_connection_cell,
			endpoint.connection_cell,
			endpoint
		)


func _append_endpoint_index(
	index: Dictionary,
	cell: Vector2i,
	endpoint: SliceLogisticsEndpoint
) -> void:
	var key := _cell_key(cell)
	var values: Array = index.get(key, [])
	values.append(endpoint)
	index[key] = values


func _sort_endpoint_indexes() -> void:
	for index in [
		_sink_endpoints_by_port_cell,
		_sink_endpoints_by_connection_cell,
		_source_endpoints_by_connection_cell,
		_endpoints_by_instance_id,
	]:
		for key in index:
			var values: Array = index[key]
			values.sort_custom(_endpoint_before)


func _sink_endpoints_at_cell(
	cell: Vector2i
) -> Array[SliceLogisticsEndpoint]:
	return _typed_endpoints(
		_sink_endpoints_by_port_cell.get(_cell_key(cell), [])
	)


func _source_endpoints_at_cell(
	cell: Vector2i
) -> Array[SliceLogisticsEndpoint]:
	return _typed_endpoints(
		_source_endpoints_by_connection_cell.get(_cell_key(cell), [])
	)


func _sink_endpoints_at_connection_cell(
	cell: Vector2i
) -> Array[SliceLogisticsEndpoint]:
	return _typed_endpoints(
		_sink_endpoints_by_connection_cell.get(_cell_key(cell), [])
	)


func _endpoints_for_instance(
	instance_id: String
) -> Array[SliceLogisticsEndpoint]:
	return _typed_endpoints(_endpoints_by_instance_id.get(instance_id, []))


func _typed_endpoints(values: Array) -> Array[SliceLogisticsEndpoint]:
	var result: Array[SliceLogisticsEndpoint] = []
	for value in values:
		result.append(value as SliceLogisticsEndpoint)
	return result


func _sink_endpoint_at_connection(
	cell: Vector2i,
	conveyor_output: Vector2i
) -> SliceLogisticsEndpoint:
	for endpoint in _sink_endpoints_at_connection_cell(cell):
		if endpoint.can_receive_from(conveyor_output):
			return endpoint
	return null


func _source_endpoint_at(
	cell: Vector2i,
	conveyor_output: Vector2i
) -> SliceLogisticsEndpoint:
	for endpoint in _source_endpoints_at_cell(cell):
		if endpoint.can_supply_to(conveyor_output):
			return endpoint
	return null


func _endpoint_for_instance_port(
	instance_id: String,
	port_id: String
) -> SliceLogisticsEndpoint:
	for endpoint in _endpoints_for_instance(instance_id):
		if endpoint.port_id == port_id:
			return endpoint
	return null


func _endpoint_before(
	left: SliceLogisticsEndpoint,
	right: SliceLogisticsEndpoint
) -> bool:
	if left.source_phase != right.source_phase:
		return left.source_phase < right.source_phase
	if left.instance_id != right.instance_id:
		return left.instance_id < right.instance_id
	return left.port_id < right.port_id


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
