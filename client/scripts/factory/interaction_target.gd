extends RefCounted

const Rules := preload("res://data/factory/discovery_rules.gd")
const Frontier := Rules.Integrated.Frontier
const OUTER_PASSAGE := "outer_passage"
const FRONTIER_PASSAGE := "frontier_passage"
const FRONTIER_PASSAGE_POINT := Vector2(Frontier.MOUTH.position.x + 0.5 * Frontier.MOUTH.size.x, Frontier.MOUTH.position.y)
const PASSAGES := {
	OUTER_PASSAGE: {"id": -2, "point": Vector2(Rules.PASSAGES.outer.x, 0), "label": "外矿道开路"},
	FRONTIER_PASSAGE: {"id": -3, "point": FRONTIER_PASSAGE_POINT, "label": "炭矿支路开路"},
}


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
	var passage_kind := _nearby_passage(model)
	if not passage_kind.is_empty():
		var passage: Dictionary = PASSAGES[passage_kind]
		result.append({"kind": passage_kind, "id": passage.id, "ready": true,
			"distance": point.distance_squared_to(passage.point)})
	result.sort_custom(func(a, b): return a.id < b.id if is_equal_approx(a.distance, b.distance) else a.distance < b.distance)
	return result


static func _nearby_passage(model: RefCounted) -> String:
	if model.map_id != Frontier.MAP_ID or not model.researched.has(Frontier.RESEARCH):
		return ""
	if not model.discovery.passages.outer:
		return OUTER_PASSAGE if model.near_passage("outer") else ""
	if not model.discovery.passages[Frontier.PASSAGE] and model.bag.get(Frontier.CAPSULE, 0) >= Frontier.OPEN_COST \
			and model.near_passage(Frontier.PASSAGE):
		return FRONTIER_PASSAGE
	return ""


## A manually cycled target is retained only while it remains reachable.
static func resolve(model: RefCounted, preferred_id := -1) -> Dictionary:
	var nearby := candidates(model)
	if nearby.is_empty():
		return {"kind": "", "id": -1, "ready": false, "count": 0, "index": -1}
	var index := nearby.find_custom(func(target): return target.id == preferred_id)
	if index < 0:
		index = 0
	return nearby[index].merged({"count": nearby.size(), "index": index})
