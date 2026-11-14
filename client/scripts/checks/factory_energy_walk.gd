extends RefCounted

## Read-only route planning. The Boot driver follows these points with real WASD.
static func route(model: RefCounted, target: Dictionary) -> Array[Vector2]:
	var start := Vector2i(roundi(model.actor.x * 2), roundi(model.actor.z * 2))
	var queue: Array[Vector2i] = [start]
	var previous := {start: start}
	var clear := {}
	var cursor := 0
	var goal := start
	var found := false
	var shape: Dictionary = model.CATALOG[target.type]
	while cursor < queue.size():
		var cell := queue[cursor]; cursor += 1
		var point := Vector2(cell) / 2.0
		var distance := Vector2(maxf(maxf(target.x - point.x, 0), point.x - target.x - shape.w), maxf(maxf(target.z - point.y, 0), point.y - target.z - shape.d)).length()
		if distance >= 0.5 and distance <= 1.3 and _clear(model, point):
			goal = cell; found = true; break
		for direction in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + direction
			if previous.has(next) or abs(next.x) > 62 or abs(next.y) > 62: continue
			if not clear.has(next): clear[next] = _clear(model, Vector2(next) / 2.0)
			if not clear[next] or not _clear(model, (Vector2(next) + Vector2(cell)) / 4.0): continue
			previous[next] = cell; queue.append(next)
	var result: Array[Vector2] = []
	if not found: return result
	var path: Array[Vector2i] = [goal]
	while path[-1] != start: path.append(previous[path[-1]])
	path.reverse()
	for i in path.size():
		if i == 0 or i == path.size() - 1 or path[i] - path[i - 1] != path[i + 1] - path[i]: result.append(Vector2(path[i]) / 2.0)
	return result


static func _clear(model: RefCounted, point: Vector2) -> bool:
	for offset in [Vector2.ZERO, Vector2(0.1, 0), Vector2(-0.1, 0), Vector2(0, 0.1), Vector2(0, -0.1)]:
		if model.blocked_for_actor(point.x + offset.x, point.y + offset.y): return false
	return true
