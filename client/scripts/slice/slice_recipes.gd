class_name SliceRecipes
extends RefCounted

## Crafting recipe table for the handheld panel (arc L1,
## docs/features/slice-handheld-crafting-panel-v1.md). Each recipe outputs
## either a backpack item (`kind = "item"`) or ordinary building kit items
## (`kind = "building"`). Costs are item_id -> count. Kept as a plain const
## table so the panel and SliceWorld share one source of truth.

const ITEM_NAMES := {
	"crystal": "晶体",
	"part": "机械零件",
	"building.floor": "工业地板套件",
	"building.collector": "采集器套件",
	"building.reactor": "反应器套件",
	"building.power_relay": "中继套件",
	"building.conveyor": "传送带套件",
	"building.storage": "储物箱套件",
}

const RECIPES := [
	{
		"id": "part",
		"name": "机械零件",
		"kind": "item",
		"output": "part",
		"output_count": 1,
		"cost": {"crystal": 3},
	},
	{
		"id": "floor",
		"name": "工业地板 ×4",
		"kind": "building",
		"output": "building.floor",
		"output_count": 4,
		"building_id": "building.floor",
		"cost": {"crystal": 1},
	},
	{
		"id": "collector",
		"name": "采集器",
		"kind": "building",
		"output": "building.collector",
		"output_count": 1,
		"building_id": "building.collector",
		"cost": {"part": 2},
	},
	{
		"id": "reactor",
		"name": "基础反应器",
		"kind": "building",
		"output": "building.reactor",
		"output_count": 1,
		"building_id": "building.reactor",
		"cost": {"part": 4},
	},
	{
		"id": "power_relay",
		"name": "电力中继",
		"kind": "building",
		"output": "building.power_relay",
		"output_count": 1,
		"building_id": "building.power_relay",
		"cost": {"part": 1},
	},
	{
		"id": "conveyor",
		"name": "传送带 ×4",
		"kind": "building",
		"output": "building.conveyor",
		"output_count": 4,
		"building_id": "building.conveyor",
		"cost": {"crystal": 1, "part": 1},
	},
	{
		"id": "storage",
		"name": "储物箱",
		"kind": "building",
		"output": "building.storage",
		"output_count": 1,
		"building_id": "building.storage",
		"cost": {"part": 2},
	},
]


static func find(recipe_id: String) -> Dictionary:
	for recipe in RECIPES:
		if recipe["id"] == recipe_id:
			return recipe
	return {}


## "晶体3 机械零件2" style cost text for the panel.
static func cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for item in cost:
		parts.append("%s%d" % [String(ITEM_NAMES.get(item, item)), int(cost[item])])
	return " ".join(parts)
