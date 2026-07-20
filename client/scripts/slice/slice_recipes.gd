class_name SliceRecipes
extends RefCounted

## Crafting recipe table for the handheld panel (arc L1,
## docs/features/slice-handheld-crafting-panel-v1.md). Each recipe outputs
## either a backpack item (`kind = "item"`) or a carried building placed on the
## grid (`kind = "carry"`). Costs are item_id -> count. Kept as a plain const
## table so the panel and SliceWorld share one source of truth.

const ITEM_NAMES := {
	"crystal": "晶体",
	"part": "机械零件",
}

const RECIPES := [
	{
		"id": "part",
		"name": "机械零件",
		"kind": "item",
		"output": "part",
		"cost": {"crystal": 3},
	},
	{
		"id": "collector",
		"name": "采集器",
		"kind": "carry",
		"output": "collector",
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
