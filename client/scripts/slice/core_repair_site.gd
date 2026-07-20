class_name CoreRepairSite
extends Area2D

## Damaged outpost core: press E to repair it by spending crafted mechanical
## parts from the backpack (arc L1,
## docs/features/slice-handheld-crafting-panel-v1.md). Charging and power come
## with later arc layers.

const REPAIR_PART_COST := 3

var repaired_texture: Texture2D = preload("res://assets/sprites/slice/outpost_core_repaired.png")


func get_prompt(world: Node) -> String:
	if world.core_repaired:
		return "前哨核心已修复"
	var parts: int = world.pocket.count(SliceWorld.ITEM_PART)
	if parts >= REPAIR_PART_COST:
		return "按 E 修复前哨核心（消耗 %d 机械零件）" % REPAIR_PART_COST
	return "修复前哨核心需要 %d 机械零件（背包 %d，按 B 合成）" % [REPAIR_PART_COST, parts]


func try_interact(world: Node) -> void:
	if world.core_repaired:
		return
	if not world.spend_pocket_item(SliceWorld.ITEM_PART, REPAIR_PART_COST):
		return
	(get_parent() as Sprite2D).texture = repaired_texture
	world.mark_core_repaired()
