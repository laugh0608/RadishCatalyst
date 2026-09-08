extends RefCounted

const RULESET_ID := "factory_foundation_v1"
const MAP_ID := "factory_yard_64_v1"
const NORMAL_SUPPLY := "factory_starter_v1"
const ENGINEERING_SUPPLY := "factory_load_100_v1"
const MIN_CELL := -32
const MAX_CELL := 32
const SUPPLIES := {
	NORMAL_SUPPLY: {"collector": 8, "reactor": 16, "storage": 8, "belt": 256},
	ENGINEERING_SUPPLY: {"collector": 25, "reactor": 50, "storage": 25, "belt": 1000},
}
const CATALOG := {
	"collector": {"name": "晶体采集器", "w": 2, "d": 2, "output": Vector2i(1, 1)},
	"reactor": {"name": "基础反应器", "w": 3, "d": 3, "input": Vector2i(0, 2), "output": Vector2i(2, 2)},
	"storage": {"name": "终端仓", "w": 2, "d": 2, "input": Vector2i(0, 1)},
	"belt": {"name": "传送带", "w": 1, "d": 1},
}


static func ore_sites() -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for x in [-32, -20, -8, 4, 16]:
		for z in [-25, -13, -1, 11, 23]:
			result.append(Vector2i(x, z))
	return result
