extends RefCounted

const Rules := preload("res://data/factory/discovery_rules.gd")
var revision := -1
var groups: Array[Dictionary] = []
var membership := {}
var rebuild_count := 0


static func is_node(e: Dictionary) -> bool:
	return e.get("type", "") in ["power_source", "power_junction"]


static func center(e: Dictionary) -> Vector2:
	var shape: Dictionary = Rules.CATALOG[e.type]
	return Vector2(e.x + shape.w * 0.5, e.z + shape.d * 0.5)


## Closed cell rectangles deliberately include edge/corner touches (supercover).
static func line_open(a: Vector2, b: Vector2, passages: Dictionary) -> bool:
	for x in range(floori(minf(a.x, b.x)) - 1, floori(maxf(a.x, b.x)) + 1):
		for z in range(floori(minf(a.y, b.y)) - 1, floori(maxf(a.y, b.y)) + 1):
			if Rules.open_cell(Vector2i(x, z), passages):
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
	if not is_node(b) and not Rules.POWER.has(b.type):
		return {"ok": false, "reason": "仓库与传送带为被动设施，无需接电"}
	var distance := center(a).distance_to(center(b))
	var limit := Rules.NODE_RANGE if is_node(b) else Rules.CONSUMER_RANGE
	if distance > limit + 1e-9:
		return {"ok": false, "reason": "距离 %.1f 格，超过 %.0f 格接线范围" % [distance, limit]}
	if not line_open(center(a), center(b), model.discovery.passages):
		return {"ok": false, "reason": "连接经过封闭矿区或矿壳"}
	return {"ok": true, "distance": distance}


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
		var group := {"nodes": [], "sources": [], "capacity_kw": 0.0, "request_kw": 0.0, "supplied_kw": 0.0}
		var pending := [id]
		membership[id] = groups.size()
		while not pending.is_empty():
			var current: int = pending.pop_back()
			group.nodes.append(current)
			var e: Dictionary = model.by_id(current)
			if e.type == "power_source" and e.enabled:
				group.sources.append(current)
				group.capacity_kw += Rules.SOURCE_KW
			for neighbor in neighbors[current]:
				if not membership.has(neighbor):
					membership[neighbor] = groups.size()
					pending.append(neighbor)
		group.nodes.sort()
		groups.append(group)
	revision = model.revision
	rebuild_count += 1


func allocate(model: RefCounted, dt: float) -> Dictionary:
	rebuild(model)
	var result := {"work": {}, "devices": {}, "sources": {}, "installed_kw": 0.0,
		"available_kw": 0.0, "request_kw": 0.0, "supplied_kw": 0.0, "deficit_kw": 0.0}
	for group in groups:
		group.request_kw = 0.0
		group.supplied_kw = 0.0
	for e in model.entities:
		if e.type == "power_source":
			result.installed_kw += Rules.SOURCE_KW
			result.sources[e.id] = 0.0
			if e.enabled:
				result.available_kw += Rules.SOURCE_KW
		if not Rules.POWER.has(e.type):
			continue
		var spec: Dictionary = model.work_spec(e)
		var work: float = minf(dt, maxf(0, spec.seconds - e.progress)) if spec.ready else 0.0
		var demand: float = spec.kw * work / dt
		var network: int = membership.get(e.power_node_id, -1)
		result.devices[e.id] = {"request_kw": demand, "supplied_kw": 0.0, "fraction": 0.0, "network": network, "work": work}
		result.request_kw += demand
		if network >= 0:
			groups[network].request_kw += demand
		else:
			result.deficit_kw += demand
	for group in groups:
		group.supplied_kw = minf(group.capacity_kw, group.request_kw)
		result.supplied_kw += group.supplied_kw
		result.deficit_kw += maxf(0, group.request_kw - group.capacity_kw)
		for id in group.sources:
			result.sources[id] = group.supplied_kw * Rules.SOURCE_KW / group.capacity_kw
	for id in result.devices:
		var device: Dictionary = result.devices[id]
		if device.network >= 0 and device.request_kw > 0:
			var group: Dictionary = groups[device.network]
			device.fraction = minf(1, group.capacity_kw / group.request_kw)
		device.supplied_kw = device.request_kw * device.fraction
		result.work[id] = device.work * device.fraction
	return result
