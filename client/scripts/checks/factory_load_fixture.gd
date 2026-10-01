extends RefCounted

const Model := preload("res://scripts/factory/model.gd")


static func route(points: Array) -> Array[Vector2i]:
	var result: Array[Vector2i] = [points[0]]
	for target in points.slice(1):
		var cursor: Vector2i = result.back()
		assert(cursor.x == target.x or cursor.y == target.y)
		while cursor != target:
			cursor += Vector2i(signi(target.x - cursor.x), signi(target.y - cursor.y))
			result.append(cursor)
	return result


static func build() -> Dictionary:
	var model := Model.new(Model.Rules.ENGINEERING_SUPPLY)
	var input := route([Vector2i(2, 1), Vector2i(3, 1), Vector2i(3, -3), Vector2i(5, -3), Vector2i(5, 2)])
	var output := route([Vector2i(9, 2), Vector2i(9, 1), Vector2i(11, 1), Vector2i(11, 8),
		Vector2i(4, 8), Vector2i(4, 4), Vector2i(7, 4), Vector2i(7, 5), Vector2i(8, 5)])
	assert(input.size() + output.size() == 40)
	for ore in Model.Rules.ore_sites():
		for spec in [["collector", Vector2i.ZERO], ["reactor", Vector2i(6, 0)],
			["reactor", Vector2i(0, 4)], ["storage", Vector2i(9, 4)]]:
			var placed := model.place(spec[0], ore + spec[1])
			if not placed.ok:
				return placed
		for segment in [input, output]:
			var directions := Model.path_directions(segment, 0)
			directions[-1] = 0 # Both terminal belts enter east-facing machine inputs.
			for i in segment.size():
				var placed := model.place("belt", ore + segment[i], directions[i])
				if not placed.ok:
					return placed
	return {"ok": true, "model": model,
		"description": "25 ore-fed lines; each 1 collector + 1 working reactor + 1 deliberately unfed spare reactor + 1 storage + 40 belts. No splitters or hidden supply."}
