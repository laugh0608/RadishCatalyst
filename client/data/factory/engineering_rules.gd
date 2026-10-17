extends RefCounted

## Fixed, versioned check world. Never an override for ordinary-world budgets.
const RULESET_ID := "factory_engineering_admission_v1"
const MAP_ID := "factory_engineering_yard_64_v1"
const SUPPLY_ID := "factory_engineering_load_100_v1"
const SUPPLY := {"collector": 20, "reactor": 40, "storage": 40, "belt": 1000,
	"power_source": 40, "power_junction": 20, "splitter": 40, "merger": 20, "admission_gate": 60}
const MAX_POWER_LINKS := 1770
const INSTALLED_KW := 4800.0
const REQUEST_KW := 3600.0


static func ore_sites() -> Array[Vector2i]:
	var sites: Array[Vector2i] = []
	for row in 5:
		for column in 4:
			sites.append(Vector2i(-30 + 15 * column, -27 + 12 * row))
	return sites


static func mineral_at(cell: Vector2i) -> String:
	var index := ore_sites().find(cell)
	if index < 0:
		return ""
	return "crystal" if (index % 4 + index / 4) % 2 == 0 else "rich_crystal"


static func matches(value: Dictionary) -> bool:
	return value.get("world_kind") == "factory_3d" and value.get("save_schema_version") == 5 and value.get("ruleset_id") == RULESET_ID and value.get("map_id") == MAP_ID and value.get("supply_id") == SUPPLY_ID
