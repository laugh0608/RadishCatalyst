extends RefCounted

const Model := preload("res://scripts/factory/engineering_model.gd")
const Config := preload("res://data/factory/engineering_rules.gd")
const MACHINES := [
	["collector", "collector", 0, 3], ["catalyst", "reactor", 5, 0], ["solvent", "reactor", 5, 6],
	["upper-store", "storage", 11, 5], ["lower-store", "storage", 11, 8],
	["source-a", "power_source", 0, 6], ["source-b", "power_source", 0, 9], ["node", "power_junction", 6, 4],
	["branch", "splitter", 8, 2], ["merge", "merger", 8, 9], ["distribute", "splitter", 9, 9],
]


static func origin(index: int) -> Vector2i:
	return Vector2i(-30 + 15 * (index % 4), -30 + 12 * (index / 4))


static func route(points: Array) -> Array[Vector2i]:
	var cells: Array[Vector2i] = [points[0]]
	for target in points.slice(1):
		var current: Vector2i = cells.back()
		assert(current.x == target.x or current.y == target.y)
		while current != target:
			current += Vector2i(signi(target.x - current.x), signi(target.y - current.y))
			cells.append(current)
	return cells


static func cell_entities(index: int) -> Array[Dictionary]:
	var at := origin(index)
	var rows: Array[Dictionary] = []
	for machine in MACHINES:
		rows.append({"name": machine[0], "type": machine[1], "x": at.x + machine[2], "z": at.y + machine[3], "dir": 0})
	var paths := [
		["raw", route([Vector2i(2, 4), Vector2i(2, 1), Vector2i(1, 1), Vector2i(1, 0), Vector2i(4, 0), Vector2i(4, 1), Vector2i(3, 1), Vector2i(3, 2), Vector2i(4, 2)]), 0],
		["feed", route([Vector2i(8, 3), Vector2i(8, 5), Vector2i(3, 5), Vector2i(3, 8), Vector2i(4, 8)]), 0],
		["bypass", route([Vector2i(9, 2), Vector2i(14, 2), Vector2i(14, 11), Vector2i(8, 11), Vector2i(8, 10)]), 3],
		["solvent", [Vector2i(8, 8)], 1],
		["upper", route([Vector2i(9, 8), Vector2i(9, 6), Vector2i(10, 6)]), 0],
		["lower", [Vector2i(10, 9)], 0],
	]
	for path in paths:
		var cells: Array = path[1]
		for i in cells.size():
			var last := i == cells.size() - 1
			var gate: bool = last and path[0] in ["raw", "feed", "bypass"]
			var dir: int = path[2] if last else Model.DIRS.find(cells[i + 1] - cells[i])
			rows.append({"name": ("g1" if path[0] == "raw" else "g2" if path[0] == "feed" else "g3") if gate else "%s-%d" % [path[0], i],
				"type": "admission_gate" if gate else "belt", "x": at.x + cells[i].x, "z": at.y + cells[i].y, "dir": dir})
	return rows


static func ids(model: RefCounted, index: int) -> Dictionary:
	var found := {}
	for row in cell_entities(index):
		var e: Dictionary = model.entity_at(Vector2i(row.x, row.z))
		if e.get("type") == row.type and e.x == row.x and e.z == row.z and e.dir == row.dir:
			found[row.name] = e.id
	return found


## Breadth-first service route over centers, then actual subdivided model movement.
## Movement preparation does not advance production time or assign actor coordinates.
static func walk(model: RefCounted, target: Vector2, near_device: Dictionary = {}) -> Dictionary:
	var start := Vector2i(floori(model.actor.x), floori(model.actor.z))
	var pending: Array[Vector2i] = [start]
	var visited := {start: start}
	var cursor := 0
	var destination := Vector2i(999, 999)
	while cursor < pending.size():
		var cell := pending[cursor]
		cursor += 1
		var point := Vector2(cell) + Vector2(0.5, 0.5)
		var reached := point.distance_to(target) < 0.1
		if not near_device.is_empty():
			var shape: Dictionary = Model.CATALOG[near_device.type]
			var nearest := Vector2(clampf(point.x, near_device.x, near_device.x + shape.w), clampf(point.y, near_device.z, near_device.z + shape.d))
			reached = point.distance_to(nearest) <= 1.5
		if reached:
			destination = cell
			break
		for dir in Model.DIRS:
			var next: Vector2i = cell + dir
			if not visited.has(next) and not model.blocked_for_actor(next.x + 0.5, next.y + 0.5):
				visited[next] = cell
				pending.append(next)
	if destination.x == 999:
		return {"ok": false, "reason": "No collision-free service route", "target": target, "device": near_device.get("id", 0)}
	var path: Array[Vector2i] = [destination]
	while path.back() != start: path.append(visited[path.back()])
	path.reverse()
	var steps := 0
	for cell in path:
		var point := Vector2(cell) + Vector2(0.5, 0.5)
		for attempt in 120:
			var delta := point - Vector2(model.actor.x, model.actor.z)
			if delta.length() < 0.001: break
			model.move_actor(model.actor, delta.x, delta.y, minf(0.02, delta.length() / 3.3))
			steps += 1
		if point.distance_to(Vector2(model.actor.x, model.actor.z)) >= 0.001:
			return {"ok": false, "reason": "Movement command blocked", "cell": cell}
	var valid: bool = near_device.is_empty() or model.near_entity(near_device)
	return {"ok": valid, "movement_steps": steps, "route_cells": path.size(), "destination": [model.actor.x, model.actor.z]}
