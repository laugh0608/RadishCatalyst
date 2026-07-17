class_name CoreRepairSite
extends Area2D

## Damaged outpost core repair interaction: consumes crystals and swaps the
## parent sprite to the repaired state. The repair cost is the topic's fixed
## 10-crystal beat (docs/features/slice-minimal-core-loop-v1.md).

const REPAIR_COST := 10

var repaired_texture: Texture2D = preload("res://assets/sprites/slice/outpost_core_repaired.png")


func get_prompt(world: Node) -> String:
	if world.core_repaired:
		return ""
	if world.crystal_count >= REPAIR_COST:
		return "按 E 修复前哨核心（消耗 %d 晶体）" % REPAIR_COST
	return "修复前哨核心需要 %d 晶体（当前 %d）" % [REPAIR_COST, world.crystal_count]


func try_interact(world: Node) -> void:
	if world.core_repaired:
		return
	if not world.spend_crystals(REPAIR_COST):
		return
	(get_parent() as Sprite2D).texture = repaired_texture
	world.mark_core_repaired()
