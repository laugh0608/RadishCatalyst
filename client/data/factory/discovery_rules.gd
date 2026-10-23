extends RefCounted

const Energy := preload("res://data/factory/energy_rules.gd")
const Expansion := preload("res://data/factory/expansion_rules.gd")
const Engineering := preload("res://data/factory/engineering_rules.gd")
const Foundation := preload("res://data/factory/rules.gd")
const RULESET_ID := "factory_discovery_v1"
const AUTO_RULESET_ID := "factory_discovery_auto_power_v1"
const MAP_ID := "factory_discovery_yard_64_v1"
const SUPPLY_ID := "factory_discovery_starter_v1"
const ROUTING_RULESET_ID := "factory_discovery_routing_v1"
const ROUTING_SUPPLY_ID := "factory_discovery_routing_starter_v1"
const ADMISSION_RULESET_ID := "factory_discovery_admission_v1"
const ADMISSION_SUPPLY_ID := "factory_discovery_admission_starter_v1"
const SUPPLY := {"collector": 8, "reactor": 16, "storage": 8, "belt": 256, "power_source": 2, "power_junction": 12}
const CATALOG := {
	"cell_generator": {"name": "电芯发电机", "w": 2, "d": 2, "input": Vector2i(0, 1)},
	"crusher": {"name": "粉碎机", "w": 2, "d": 2},
	"refinery": {"name": "精炼炉", "w": 2, "d": 3},
	"assembler": {"name": "组装机", "w": 3, "d": 2},
	"collector": Foundation.CATALOG.collector,
	"reactor": Foundation.CATALOG.reactor,
	"storage": Foundation.CATALOG.storage,
	"belt": Foundation.CATALOG.belt,
	"power_source": {"name": "封装电源", "w": 3, "d": 3},
	"power_junction": {"name": "配电节点", "w": 1, "d": 1},
	"splitter": {"name": "分流器", "w": 1, "d": 1},
	"merger": {"name": "汇合器", "w": 1, "d": 1},
	"admission_gate": {"name": "物品准入口", "w": 1, "d": 1},
}
const ROUTING_CATALOG := {"splitter": CATALOG.splitter, "merger": CATALOG.merger}

static func routing_supply() -> Dictionary:
	return SUPPLY.merged({"splitter": 8, "merger": 8})

static func admission_supply() -> Dictionary:
	return routing_supply().merged({"admission_gate": 8})

static func routing_world(supply: String) -> bool:
	return supply == ROUTING_SUPPLY_ID or admission_world(supply)

static func admission_world(supply: String) -> bool:
	return supply in [ADMISSION_SUPPLY_ID, Engineering.SUPPLY_ID, Expansion.SUPPLY_ID, Energy.SUPPLY_ID]

const ITEMS := ["crystal", "catalyst", "crust_sample", "crust_solvent", "rich_crystal"]
const NAMES := {"crystal": "晶体", "catalyst": "催化剂", "crust_sample": "矿壳样本", "crust_solvent": "解壳剂", "rich_crystal": "富集晶体"}
const WEIGHTS := {"crystal": 1, "catalyst": 2, "crust_sample": 0, "crust_solvent": 4, "rich_crystal": 6}
const RECIPES := {
	"basic_catalyst": {"name": "基础催化剂", "input": {"crystal": 2}, "output": {"catalyst": 1}, "seconds": 10.0, "kw": 40.0},
	"solvent_trial": {"name": "矿壳试制", "input": {"crust_sample": 1, "catalyst": 2}, "output": {"crust_solvent": 1}, "seconds": 10.0, "kw": 40.0},
	"crust_solvent": {"name": "解壳剂", "input": {"catalyst": 2}, "output": {"crust_solvent": 1}, "seconds": 8.0, "kw": 60.0},
	"rich_catalyst": {"name": "富集催化剂", "input": {"rich_crystal": 1}, "output": {"catalyst": 3}, "seconds": 12.0, "kw": 80.0},
}
const SAMPLE := Vector2(2.5, 2.5)
const PASSAGES := {"outer": {"x": 4, "cost": 4}, "inner": {"x": 20, "cost": 8}}
const SOURCE_KW := 120.0
const NODE_RANGE := 12.0
const CONSUMER_RANGE := 6.0
const POWER := {"crusher": 20.0, "refinery": 60.0, "assembler": 40.0, "collector": 20.0, "reactor": 40.0}
const CYCLE := {"collector": 1.0, "reactor": 10.0}

static func ore_sites(map_id: String = MAP_ID) -> Array[Vector2i]:
	if map_id == Engineering.MAP_ID:
		return Engineering.ore_sites()
	if map_id == Expansion.MAP_ID:
		var sites: Array[Vector2i] = ore_sites()
		sites.append_array([Vector2i(-28, -12), Vector2i(-28, 10)])
		return sites
	if map_id != MAP_ID:
		return []
	return [Vector2i(-20, -13), Vector2i(-20, -1), Vector2i(-20, 11), Vector2i(10, -1), Vector2i(26, -13), Vector2i(26, 11)]

static func mineral_at(cell: Vector2i, map_id: String = MAP_ID) -> String:
	if map_id == Engineering.MAP_ID:
		return Engineering.mineral_at(cell)
	if map_id == Expansion.MAP_ID:
		if cell == Vector2i(-28, -12): return "iron_ore"
		if cell == Vector2i(-28, 10): return "carbon_ore"
		return mineral_at(cell)
	if map_id != MAP_ID or cell not in ore_sites():
		return ""
	return "crystal" if cell.x < 4 else "rich_crystal"

static func open_cell(cell: Vector2i, passages: Dictionary, map_id: String = MAP_ID) -> bool:
	if map_id not in [MAP_ID, Engineering.MAP_ID, Expansion.MAP_ID]:
		return false
	if cell.x < -32 or cell.x >= 32 or cell.y < -32 or cell.y >= 32:
		return false
	if map_id == Engineering.MAP_ID:
		return true
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
