extends RefCounted

## B0 subset of the audited four-sided S0 layout. Only topology is prepared.
const STAGES := [
	[Vector2i(-26, -11), Vector2i(-26, 10), Vector2i(-8, 10), Vector2i(-8, 21)],
	[Vector2i(-10, 28), Vector2i(-10, 30), Vector2i(-27, 30), Vector2i(-27, 23), Vector2i(-26, 23)],
	[Vector2i(-23, 23), Vector2i(-23, 19), Vector2i(-10, 19), Vector2i(-10, 21)],
]
const LAST_DIRECTIONS := [1, 0, 1]
const JUNCTIONS := [Vector2i(-24, -10), Vector2i(-24, 0), Vector2i(-24, 8),
	Vector2i(-16, 16), Vector2i(-24, 21), Vector2i(-16, 22)]


static func build(model: RefCounted) -> Dictionary:
	var collector: Dictionary = model.place("collector", Vector2i(-28, -12))
	if not collector.ok: return collector
	var refinery: Dictionary = model.place("refinery", Vector2i(-25, 23))
	if not refinery.ok: return refinery
	for cell in JUNCTIONS:
		var junction: Dictionary = model.place("power_junction", cell)
		if not junction.ok: return junction
	var lengths := []
	for i in STAGES.size():
		var path: Array[Vector2i] = [STAGES[i][0]]
		for end in STAGES[i].slice(1):
			while path.back() != end:
				path.append(path.back() + (end - path.back()).sign())
		var result: Dictionary = model.place_path(path, LAST_DIRECTIONS[i])
		if not result.ok: return result
		lengths.append(path.size())
	return model.success({"collector": collector.entity, "refinery": refinery.entity, "lengths": lengths})
