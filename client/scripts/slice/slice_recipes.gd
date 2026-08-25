class_name SliceRecipes
extends RefCounted

## Crafting recipe table for the handheld panel (arc L1,
## docs/features/slice-handheld-crafting-panel-v1.md). Each recipe outputs
## backpack property (`item`, `equipment`, `field_supply`) or ordinary building
## kit items (`building`). Costs are item_id -> count. Kept as a plain const
## table so the panel and SliceWorld share one source of truth.

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
		"name": "工业地板",
		"kind": "building",
		"output": "building.floor",
		"output_count": 8,
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
		"name": "传送带",
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
	{
		"id": "pulse_rifle",
		"name": "前哨脉冲步枪",
		"kind": "equipment",
		"output": SliceItemCatalog.PULSE_RIFLE_ID,
		"output_count": 1,
		"cost": {SliceItemCatalog.PART_ID: 4, SliceItemCatalog.CATALYST_ID: 1},
		"unlock": "core_charged",
		"unique_total_limit": 1,
	},
	{
		"id": "pulse_cell",
		"name": "晶体脉冲电池",
		"kind": "field_supply",
		"output": SliceItemCatalog.PULSE_CELL_ID,
		"output_count": 8,
		"cost": {SliceItemCatalog.PART_ID: 1, SliceItemCatalog.CATALYST_ID: 1},
		"unlock": "core_charged",
	},
]


static func find(recipe_id: String) -> Dictionary:
	for recipe in RECIPES:
		if recipe["id"] == recipe_id:
			return recipe
	return {}


static func is_unlocked(recipe: Dictionary, core_charged: bool) -> bool:
	return (
		String(recipe.get("unlock", "")).is_empty()
		or core_charged
	)


## Compact material text shared by graphical recipe cards and diagnostics.
static func cost_text(cost: Dictionary) -> String:
	var parts: Array[String] = []
	for item in cost:
		var definition := SliceItemCatalog.find(String(item))
		var item_name := String(item) if definition == null else definition.display_name
		parts.append(
			"%s ×%d" % [item_name, int(cost[item])]
		)
	return " · ".join(parts)


## Returns an empty string when authoritative inventory rules allow crafting,
## otherwise a player-facing blocker. SliceWorld and the panel both consume
## this result so button state cannot drift from actual crafting.
static func craft_block_reason(
	recipe: Dictionary,
	inventory: Inventory,
	core_inventory: Inventory = null,
	core_charged: bool = true
) -> String:
	if not is_unlocked(recipe, core_charged):
		return "核心首次充能后解锁"

	var output_id := String(recipe["output"])
	var unique_total_limit := int(recipe.get("unique_total_limit", 0))
	if unique_total_limit > 0:
		var existing_total := inventory.count(output_id)
		if core_inventory != null:
			existing_total += core_inventory.count(output_id)
		if existing_total >= unique_total_limit:
			return "已制造"

	var missing: Array[String] = []
	var cost: Dictionary = recipe["cost"]
	for item in cost:
		var needed := int(cost[item])
		var available := inventory.count(String(item))
		if available < needed:
			var definition := SliceItemCatalog.find(String(item))
			var item_name := (
				String(item) if definition == null else definition.display_name
			)
			missing.append(
				"%s ×%d"
				% [
					item_name,
					needed - available,
				]
			)
	if not missing.is_empty():
		return "缺少 %s" % " · ".join(missing)

	var output_count := int(recipe.get("output_count", 1))
	if not inventory.can_exchange(cost, {output_id: output_count}):
		var available_space := inventory.free_space_for_after(output_id, cost)
		if inventory.profile().is_per_item():
			var output_definition := SliceItemCatalog.find(output_id)
			var output_name := (
				output_id
				if output_definition == null
				else output_definition.display_name
			)
			return "%s还需 %d 容量" % [
				output_name,
				maxi(1, output_count - available_space),
			]
		return "背包还需 %d 格" % maxi(1, output_count - available_space)
	return ""
