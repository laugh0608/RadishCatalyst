extends RefCounted

# C 专用固定布局；只共享静态坐标，不构造世界或修改运行状态。
static func _entity(name: String, type: String, x: int, z: int, dir: int = 0) -> Dictionary:
	return {"name": name, "type": type, "x": x, "z": z, "dir": dir}


static func _belt(x: int, z: int, dir: int = 0) -> Dictionary:
	return _entity("belt_%d_%d" % [x, z], "belt", x, z, dir)


static func initial_entities() -> Array[Dictionary]:
	var result: Array[Dictionary] = [
		_entity("collector", "collector", -20, -1),
		_entity("basic", "reactor", -13, -2),
		_entity("solvent", "reactor", -6, -2),
		_entity("solvent_store", "storage", -2, -1),
		_entity("source_a", "power_source", -19, -6),
		_entity("node_a", "power_junction", -14, 3),
		_entity("node_b", "power_junction", -5, 3),
		_entity("g1", "admission_gate", -18, 0),
		_entity("g3", "admission_gate", -10, 0),
		_entity("g4", "admission_gate", -3, 0),
	]
	for x in range(-17, -13): result.append(_belt(x, 0))
	for x in range(-9, -6): result.append(_belt(x, 0))
	return result


static func combination_entities() -> Array[Dictionary]:
	var result: Array[Dictionary] = [
		_entity("collector", "collector", -20, -1),
		_entity("rich_collector", "collector", 10, -1),
		_entity("basic", "reactor", -13, -2),
		_entity("rich", "reactor", -13, 6),
		_entity("solvent", "reactor", -6, -2),
		_entity("solvent_store", "storage", -2, -1),
		_entity("catalyst_store", "storage", -7, 2),
		_entity("source_a", "power_source", -19, -6),
		_entity("source_b", "power_source", 9, -6),
		_entity("node_a", "power_junction", -14, 3),
		_entity("node_b", "power_junction", -5, 3),
		_entity("node_c", "power_junction", 2, -1),
		_entity("node_d", "power_junction", 8, -1),
		_entity("m1", "merger", -18, 0),
		_entity("s1", "splitter", -17, 0),
		_entity("g1", "admission_gate", -16, 0),
		_entity("g2", "admission_gate", -17, 1, 1),
		_entity("m2", "merger", -9, 0),
		_entity("s2", "splitter", -8, 0),
		_entity("g3", "admission_gate", -7, 0),
		_entity("g4", "admission_gate", -3, 0),
	]
	for x in [-15, -14, -10]: result.append(_belt(x, 0))
	for z in range(2, 8): result.append(_belt(-17, z, 1))
	for x in range(-17, -13): result.append(_belt(x, 8))
	result.append(_belt(-10, 8))
	for z in range(8, 0, -1): result.append(_belt(-9, z, 3))
	result.append(_belt(-8, 1, 1))
	result.append(_belt(-8, 2, 1))
	result.append(_belt(-8, 3))
	result.append(_belt(12, 0, 1))
	for x in range(12, 1, -1): result.append(_belt(x, 1, 2))
	for z in range(1, -3, -1): result.append(_belt(1, z, 3))
	for x in range(1, -18, -1): result.append(_belt(x, -3, 2))
	result.append(_belt(-18, -3, 1))
	result.append(_belt(-18, -2, 1))
	result.append(_belt(-18, -1, 1))
	return result


static func routes() -> Dictionary[String, Array]:
	return {
		"hub": [Vector2(-3.5, 5.7), Vector2(-3.5, 5), Vector2(-18, 5)],
		"g1": [Vector2(-18, 5), Vector2(-15.5, 5), Vector2(-15.5, 1.8)],
		"g2": [Vector2(-18, 5), Vector2(-18, 2.6), Vector2(-17.6, 2.6)],
		"m1": [Vector2(-18, 5), Vector2(-18, 1.8)],
		"s1": [Vector2(-18, 5), Vector2(-21, 5), Vector2(-21, -2), Vector2(-17.5, -2), Vector2(-17.5, -1)],
		"basic": [Vector2(-18, 5), Vector2(-11.5, 5), Vector2(-11.5, 2)],
		"rich": [Vector2(-18, 5), Vector2(-11.5, 5), Vector2(-11.5, 4.8)],
		"g3": [Vector2(-3.5, 5), Vector2(-9, 5), Vector2(-9, 1.6), Vector2(-7.5, 1.6)],
		"m2": [Vector2(-3.5, 5), Vector2(-9, 5), Vector2(-9, 1.6)],
		"s2": [Vector2(-3.5, 5), Vector2(-9, 5), Vector2(-9, 1.6), Vector2(-7.5, 1.6)],
		"solvent": [Vector2(-3.5, 5), Vector2(-3.5, 1.6), Vector2(-5, 1.6)],
		"g4": [Vector2(-3.5, 5), Vector2(-3.5, 1.6)],
		"solvent_store": [Vector2(-3.5, 5), Vector2(-1, 5), Vector2(-1, 2)],
		"catalyst_store": [Vector2(-3.5, 5), Vector2(-6, 5), Vector2(-6, 4.6)],
		"outer": [Vector2(-3.5, 5), Vector2(2, 5), Vector2(2, 0.5), Vector2(8.8, 0.5)],
		"inner_approach": [Vector2(8.8, 0.5), Vector2(8.8, 2.5), Vector2(18.5, 2.5), Vector2(18.5, 0.5), Vector2(19, 0.5)],
		"inner_cross": [Vector2(19, 0.5), Vector2(24.5, 0.5)],
	}
