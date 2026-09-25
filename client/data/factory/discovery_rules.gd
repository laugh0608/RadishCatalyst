extends RefCounted

const Foundation := preload("res://data/factory/rules.gd")
const RULESET_ID := "factory_discovery_v1"
const MAP_ID := "factory_discovery_yard_64_v1"
const SUPPLY_ID := "factory_discovery_starter_v1"
const SUPPLY := {"collector": 8, "reactor": 16, "storage": 8, "belt": 256, "power_source": 2, "power_junction": 12}
const CATALOG := {
	"collector": Foundation.CATALOG.collector,
	"reactor": Foundation.CATALOG.reactor,
	"storage": Foundation.CATALOG.storage,
	"belt": Foundation.CATALOG.belt,
	"power_source": {"name": "封装电源", "w": 3, "d": 3},
	"power_junction": {"name": "配电节点", "w": 1, "d": 1},
}
const ITEMS := ["crystal", "catalyst", "crust_sample", "crust_solvent", "rich_crystal"]
const SOURCE_KW := 120.0
const NODE_RANGE := 12.0
const CONSUMER_RANGE := 6.0
const POWER := {"collector": 20.0, "reactor": 40.0}
const CYCLE := {"collector": 1.0, "reactor": 10.0}

static func ore_sites() -> Array[Vector2i]:
	return [Vector2i(-20, -13), Vector2i(-20, -1), Vector2i(-20, 11), Vector2i(10, -1), Vector2i(26, -13), Vector2i(26, 11)]

static func open_cell(cell: Vector2i, passages: Dictionary) -> bool:
	if cell.x < -32 or cell.x >= 32 or cell.y < -32 or cell.y >= 32:
		return false
	if cell.x < 4:
		return true
	if not passages.outer:
		return false
	if cell.x < 8:
		return cell.y >= -2 and cell.y <= 1
	if cell.x < 20:
		return true
	if not passages.inner:
		return false
	if cell.x < 24:
		return cell.y >= -2 and cell.y <= 1
	return true
