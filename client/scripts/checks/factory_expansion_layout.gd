extends RefCounted

## Approved E1 paper layouts, exercised by both state and formal Boot checks.
const COMMON := [
	["I", "collector", -28, -12], ["Q", "collector", -20, -1],
	["F", "refinery", -18, -11], ["A", "assembler", -6, -11],
	["T", "storage", -1, -11], ["S1", "power_source", -26, -17],
	["S2", "power_source", -6, -6], ["N1", "power_junction", -21, -6],
	["N2", "power_junction", -12, -9], ["N3", "power_junction", -24, 1],
	["GI", "admission_gate", -26, -11], ["GQ", "admission_gate", -18, 0],
]
const A_EXTRA := [["U", "storage", -15, -1]]
const B_EXTRA := [["C", "crusher", -23, -12], ["R", "refinery", -12, -5],
	["K", "collector", -28, 10], ["U", "storage", -23, 10],
	["N4", "power_junction", -26, 6], ["GK", "admission_gate", -26, 11]]


static func rows(stage: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for row in COMMON + (A_EXTRA if stage == "A" else B_EXTRA):
		result.append({"name": row[0], "type": row[1], "x": row[2], "z": row[3], "dir": 0})
	for x in range(-16, -6): _belt(result, x, -11, 0)
	for x in [-3, -2]: _belt(result, x, -10, 0)
	if stage == "A":
		for x in range(-25, -18): _belt(result, x, -11, 0)
		for x in [-17, -16]: _belt(result, x, 0, 0)
	else:
		for x in [-25, -24, -21, -20, -19]: _belt(result, x, -11, 0)
		for x in [-16, -15]: _belt(result, x, -9, 0)
		for z in range(-9, -5): _belt(result, -14, z, 1)
		for x in [-14, -13]: _belt(result, x, -5, 0)
		for z in range(-5, -10, -1): _belt(result, -10, z, 3)
		for x in range(-10, -6): _belt(result, x, -10, 0)
		for x in [-17, -16, -15]: _belt(result, x, 0, 0)
		for z in [0, -1, -2]: _belt(result, -14, z, 3)
		for x in [-14, -13]: _belt(result, x, -3, 0)
		for x in [-25, -24]: _belt(result, x, 11, 0)
	return result


static func _belt(rows: Array[Dictionary], x: int, z: int, dir: int) -> void:
	rows.append({"name": "belt_%d_%d" % [x, z], "type": "belt", "x": x, "z": z, "dir": dir})


static func waypoints(name: String, stage: String) -> Array[Vector2]:
	var paths := {
		"F": [Vector2(-16.5, 4), Vector2(-16.5, -7)],
		"GI": [Vector2(-29.5, 4), Vector2(-29.5, -9), Vector2(-26, -9)],
		"GQ": [Vector2(-18, 4), Vector2(-18, 2)],
		"C": [Vector2(-16.5, 4), Vector2(-16.5, -7), Vector2(-23.5, -7), Vector2(-23.5, -10)],
		"R": [Vector2(-11, 4), Vector2(-11, -1)],
		"GK": [Vector2(-29.5, 4), Vector2(-29.5, 13), Vector2(-26, 13)],
		"A": [Vector2(1.5, 4), Vector2(1.5, -12), Vector2(-5, -12)],
		"T": [Vector2(1.5, 4), Vector2(1.5, -10)],
		"U": [Vector2(-14, 4), Vector2(-14, 2)] if stage == "A" else [Vector2(-20, 4), Vector2(-20, 13), Vector2(-22, 13)],
	}
	var result: Array[Vector2] = [Vector2(-3.5, 4)]
	result.append_array(paths[name])
	return result
