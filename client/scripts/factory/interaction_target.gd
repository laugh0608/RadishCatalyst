extends RefCounted


## Query nearby occupied cells, then apply the same range/occlusion authority as commands.
static func candidates(model: RefCounted) -> Array[Dictionary]:
	var point := Vector2(model.actor.x, model.actor.z)
	var seen := {}
	var result: Array[Dictionary] = []
	for x in range(floori(point.x) - 2, floori(point.x) + 3):
		for z in range(floori(point.y) - 2, floori(point.y) + 3):
			var e: Dictionary = model.entity_at(Vector2i(x, z))
			if e.is_empty() or seen.has(e.id):
				continue
			seen[e.id] = true
			if not model.near_entity(e):
				continue
			var size: Dictionary = model.CATALOG[e.type]
			var nearest := Vector2(clampf(point.x, e.x + 0.001, e.x + size.w - 0.001), clampf(point.y, e.z + 0.001, e.z + size.d - 0.001))
			result.append({"kind": "device", "id": e.id, "ready": true, "distance": point.distance_squared_to(nearest)})
	if not model.discovery.sample_taken and model.near_sample():
		result.append({"kind": "sample", "id": 0, "ready": true, "distance": point.distance_squared_to(model.DiscoveryRules.SAMPLE)})
	result.sort_custom(func(a, b): return a.id < b.id if is_equal_approx(a.distance, b.distance) else a.distance < b.distance)
	return result


## A manually cycled target is retained only while it remains reachable.
static func resolve(model: RefCounted, preferred_id := -1) -> Dictionary:
	var nearby := candidates(model)
	if nearby.is_empty():
		return {"kind": "", "id": -1, "ready": false, "count": 0, "index": -1}
	var index := nearby.find_custom(func(target): return target.id == preferred_id)
	if index < 0:
		index = 0
	return nearby[index].merged({"count": nearby.size(), "index": index})
