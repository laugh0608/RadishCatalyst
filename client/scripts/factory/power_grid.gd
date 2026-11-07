extends RefCounted

const Energy := preload("res://data/factory/energy_rules.gd")
const Rules := preload("res://data/factory/discovery_rules.gd")
const Buffer := Rules.Integrated.Storage
var fixed_burn := false
var storage_enabled := false
var revision := -1
var groups: Array[Dictionary] = []
var membership := {}
var rebuild_count := 0


static func is_node(e: Dictionary) -> bool:
	return e.get("type", "") in ["power_source", "power_junction", "cell_generator", "base_core"]


static func is_endpoint(type: String) -> bool:
	return Rules.POWER.has(type) or type == Buffer.TYPE


static func base_capacity(e: Dictionary) -> float:
	match e.type:
		"base_core": return Rules.Integrated.BASE_KW
		"power_source": return Rules.SOURCE_KW
	return 0.0


static func center(e: Dictionary) -> Vector2:
	var shape: Dictionary = Rules.CATALOG[e.type]
	return Vector2(e.x + shape.w * 0.5, e.z + shape.d * 0.5)


## Closed cell rectangles deliberately include edge/corner touches (supercover).
static func line_open(a: Vector2, b: Vector2, passages: Dictionary, map_id: String = Rules.MAP_ID) -> bool:
	for x in range(floori(minf(a.x, b.x)) - 1, floori(maxf(a.x, b.x)) + 1):
		for z in range(floori(minf(a.y, b.y)) - 1, floori(maxf(a.y, b.y)) + 1):
			if Rules.open_cell(Vector2i(x, z), passages, map_id):
				continue
			var low := 0.0
			var high := 1.0
			for axis in 2:
				var origin: float = a[axis]
				var delta: float = b[axis] - origin
				var edge := float(x if axis == 0 else z)
				if absf(delta) < 1e-12:
					if origin < edge or origin > edge + 1:
						high = -1
						break
				else:
					var t0 := (edge - origin) / delta
					var t1 := (edge + 1 - origin) / delta
					low = maxf(low, minf(t0, t1))
					high = minf(high, maxf(t0, t1))
			if low <= high + 1e-12:
				return false
	return true


static func connection(model: RefCounted, a_id: int, b_id: int) -> Dictionary:
	var a: Dictionary = model.by_id(a_id)
	var b: Dictionary = model.by_id(b_id)
	if a.is_empty() or b.is_empty() or a_id == b_id or not is_node(a):
		return {"ok": false, "reason": "先选择电源 / 配电节点，再选择另一节点或用电设备"}
	return reachability(a, b, model.discovery.passages, model.map_id)


## Placement previews share the exact geometry checks without creating a model entity.
static func reachability(a: Dictionary, b: Dictionary, passages: Dictionary, map_id: String = Rules.MAP_ID) -> Dictionary:
	if not is_node(b) and not is_endpoint(b.type):
		return {"ok": false, "reason": "仓库与传送带为被动设施，无需接电"}
	var distance := center(a).distance_to(center(b))
	var limit := Rules.NODE_RANGE if is_node(b) else Rules.CONSUMER_RANGE
	if distance > limit + 1e-9:
		return {"ok": false, "reason": "距离 %.1f 格，超过 %.0f 格接线范围" % [distance, limit]}
	if not line_open(center(a), center(b), passages, map_id):
		return {"ok": false, "reason": "连接经过封闭矿区或矿壳"}
	return {"ok": true, "distance": distance}


## Called only after a topology command, or once when loading an automatic world.
func reconnect_automatic(model: RefCounted) -> void:
	var nodes: Array = model.entities.filter(is_node)
	nodes.sort_custom(func(a, b): return a.id < b.id)
	model.power_links.clear()
	for i in nodes.size():
		for j in range(i + 1, nodes.size()):
			if reachability(nodes[i], nodes[j], model.discovery.passages, model.map_id).ok:
				model.power_links.append([nodes[i].id, nodes[j].id])
	revision = -1
	rebuild(model)
	for e in model.entities:
		if not is_endpoint(e.type):
			continue
		var best_id := 0
		var best_powered := false
		var best_distance := INF
		for node in nodes:
			if not reachability(node, e, model.discovery.passages, model.map_id).ok:
				continue
			var powered: bool = groups[membership[node.id]].nominal_kw > 0
			var distance := center(node).distance_squared_to(center(e))
			if best_id == 0 or (powered and not best_powered) or (powered == best_powered and distance < best_distance):
				best_id = node.id
				best_powered = powered
				best_distance = distance
		# Sorted node traversal makes exact distance ties deterministic by stable ID.
		e.power_node_id = best_id


func rebuild(model: RefCounted) -> void:
	if revision == model.revision:
		return
	groups.clear()
	membership.clear()
	var neighbors := {}
	for e in model.entities:
		if is_node(e):
			neighbors[e.id] = []
	for link in model.power_links:
		neighbors[link[0]].append(link[1])
		neighbors[link[1]].append(link[0])
	var ids: Array = neighbors.keys()
	ids.sort()
	for id in ids:
		if membership.has(id):
			continue
		var group := {"nodes": [], "sources": [], "generators": [], "base_capacity_kw": 0.0, "nominal_kw": 0.0, "capacity_kw": 0.0, "request_kw": 0.0, "supplied_kw": 0.0}
		var pending := [id]
		membership[id] = groups.size()
		while not pending.is_empty():
			var current: int = pending.pop_back()
			group.nodes.append(current)
			var e: Dictionary = model.by_id(current)
			var base := base_capacity(e)
			if base > 0 and e.get("enabled", true):
				group.sources.append(current)
				group.base_capacity_kw += base
				group.nominal_kw += base
			if e.type == Energy.GENERATOR and e.enabled:
				group.generators.append(current)
				group.nominal_kw += Energy.GENERATOR_KW
			for neighbor in neighbors[current]:
				if not membership.has(neighbor):
					membership[neighbor] = groups.size()
					pending.append(neighbor)
		group.nodes.sort()
		group.generators.sort()
		group.capacity_kw = group.base_capacity_kw
		groups.append(group)
	revision = model.revision
	rebuild_count += 1


func allocate(model: RefCounted, dt: float) -> Dictionary:
	rebuild(model)
	var result := {"work": {}, "devices": {}, "sources": {}, "generators": {}, "installed_kw": 0.0,
		"enabled_kw": 0.0, "available_kw": 0.0, "request_kw": 0.0, "supplied_kw": 0.0, "deficit_kw": 0.0,
		"base_supplied_kw": 0.0, "cell_supplied_kw": 0.0, "standby_supplied_kw": 0.0,
		"fuel_released_kw": 0.0, "spill_kw": 0.0}
	var capacities := {}
	var buffers_by_group := {}
	if storage_enabled:
		result.merge({"buffers": {}, "charge_j": 0, "discharge_j": 0, "storage_loss_j": 0})
	for group in groups:
		group.request_kw = 0.0
		group.supplied_kw = 0.0
		group.capacity_kw = group.base_capacity_kw
		for id in group.generators:
			var e: Dictionary = model.by_id(id)
			if fixed_burn:
				capacities[id] = Energy.GENERATOR_KW if e.burn_remaining_ticks > 0 or not e.fuel.is_empty() else 0.0
			else:
				capacities[id] = minf(Energy.GENERATOR_KW, (e.remaining_kj + Energy.CELL_KJ * e.fuel.get(Energy.CELL, 0)) / dt)
			group.capacity_kw += capacities[id]
		result.available_kw += group.capacity_kw
		result.enabled_kw += group.nominal_kw
	for e in model.entities:
		var base := base_capacity(e)
		if base > 0 or e.type == Energy.GENERATOR:
			result.installed_kw += Energy.GENERATOR_KW if e.type == Energy.GENERATOR else base
			result.sources[e.id] = 0.0
			if e.type == Energy.GENERATOR: result.generators[e.id] = 0.0
		if storage_enabled and e.type == Buffer.TYPE:
			var network: int = membership.get(e.power_node_id, -1)
			result.buffers[e.id] = {"network": network, "stored_delta_j": 0, "charge_j": 0, "discharge_j": 0}
			result.installed_kw += Buffer.DISCHARGE_KW
			if e.enabled:
				result.enabled_kw += Buffer.DISCHARGE_KW
				if network >= 0:
					if not buffers_by_group.has(network):
						buffers_by_group[network] = []
					buffers_by_group[network].append(e)
					var available := minf(Buffer.DISCHARGE_KW, e.stored_j / (dt * 1000.0))
					result.available_kw += available
					groups[network].capacity_kw += available
		if not Rules.POWER.has(e.type): continue
		var spec: Dictionary = model.work_spec(e)
		var work: float = minf(dt, maxf(0, spec.seconds - e.progress)) if spec.ready else 0.0
		var standby: float = spec.standby_kw * (dt - work) / dt
		var demand: float = spec.kw * work / dt + standby
		var network: int = membership.get(e.power_node_id, -1)
		result.devices[e.id] = {"request_kw": demand, "supplied_kw": 0.0, "fraction": 0.0, "network": network, "work": work,
			"running_kw": spec.kw, "standby_kw": spec.standby_kw, "standby_request_kw": standby, "standby_supplied_kw": 0.0}
		result.request_kw += demand
		if network >= 0:
			groups[network].request_kw += demand
		else:
			result.deficit_kw += demand
	for index in groups.size():
		var group := groups[index]
		var base: float = minf(group.base_capacity_kw, group.request_kw)
		var generation := {}
		if fixed_burn:
			for id in group.generators:
				generation[id] = capacities[id]
		else:
			generation = capped_equal_share(group.generators, capacities, maxf(0, group.request_kw - base))
		var released := 0.0
		for id in generation:
			result.sources[id] = generation[id]
			result.generators[id] = generation[id]
			released += generation[id]
		var cells := released
		var storage_kw := 0.0
		if fixed_burn:
			cells = minf(released, group.request_kw)
			base = minf(group.base_capacity_kw, maxf(0.0, group.request_kw - cells))
			result.fuel_released_kw += released
			var surplus := released - cells
			if buffers_by_group.has(index):
				var transfers := _storage_transfers(buffers_by_group[index], surplus, group.request_kw - base - cells, dt, result)
				surplus = maxf(0.0, surplus - transfers.charge_j / (dt * 1000.0))
				storage_kw = transfers.discharge_j / (dt * 1000.0)
			group["spill_kw"] = surplus
			result.spill_kw += surplus
		group.supplied_kw = base + cells + storage_kw
		result.base_supplied_kw += base
		result.cell_supplied_kw += cells
		result.supplied_kw += group.supplied_kw
		result.deficit_kw += maxf(0, group.request_kw - group.supplied_kw)
		for id in group.sources:
			result.sources[id] = base * base_capacity(model.by_id(id)) / group.base_capacity_kw
	for id in result.devices:
		var device: Dictionary = result.devices[id]
		if device.network >= 0 and device.request_kw > 0:
			var group: Dictionary = groups[device.network]
			device.fraction = minf(1, group.supplied_kw / group.request_kw)
		device.supplied_kw = device.request_kw * device.fraction
		device.standby_supplied_kw = device.standby_request_kw * device.fraction
		result.standby_supplied_kw += device.standby_supplied_kw
		result.work[id] = device.work * device.fraction
	return result


static func _storage_transfers(devices: Array, surplus_kw: float, gap_kw: float, dt: float, result: Dictionary) -> Dictionary:
	var available := floori(maxf(0.0, surplus_kw) * dt * 1000.0 + 1e-7)
	var gap := floori(maxf(0.0, gap_kw) * dt * 1000.0 + 1e-7)
	var input_limit := roundi(Buffer.CHARGE_KW * dt * 1000.0)
	var output_limit := roundi(Buffer.DISCHARGE_KW * dt * 1000.0)
	var totals := {"charge_j": 0, "discharge_j": 0}
	devices.sort_custom(func(a, b): return a.id < b.id)
	for e in devices:
		var room: int = Buffer.CAPACITY_J - e.stored_j
		var packets := mini(mini(input_limit, available) / Buffer.CHARGE_INPUT_J, room / Buffer.CHARGE_STORED_J)
		var charge := packets * Buffer.CHARGE_INPUT_J
		var retained := packets * Buffer.CHARGE_STORED_J
		var discharge := mini(mini(output_limit, gap), e.stored_j)
		assert(charge == 0 or discharge == 0)
		available -= charge
		gap -= discharge
		result.buffers[e.id].merge({"charge_j": charge, "discharge_j": discharge, "stored_delta_j": retained - discharge}, true)
		totals.charge_j += charge
		totals.discharge_j += discharge
		result.storage_loss_j += charge - retained
	result.charge_j += totals.charge_j
	result.discharge_j += totals.discharge_j
	return totals


## Water filling: small sources cap first, then redistribute the remaining gap.
static func capped_equal_share(ids: Array, capacities: Dictionary, gap: float) -> Dictionary:
	var pending := ids.duplicate()
	var result := {}
	while not pending.is_empty():
		var share: float = gap / pending.size()
		var limited: Array = pending.filter(func(id): return capacities[id] <= share)
		if limited.is_empty():
			for id in pending: result[id] = share
			break
		for id in limited:
			result[id] = capacities[id]
			gap = maxf(0, gap - capacities[id])
			pending.erase(id)
	return result
