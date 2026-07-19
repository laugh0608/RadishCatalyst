class_name CoreRepairSite
extends Area2D

## Outpost core interaction with two staged goals. Before repair it consumes
## crystals and swaps the parent sprite to the repaired state (the topic's
## fixed 10-crystal beat, docs/features/slice-minimal-core-loop-v1.md). After
## repair it becomes the charging goal: pressing E injects stored catalyst to
## advance core energy toward full (docs/features/slice-recipe-processing-v1.md).

const REPAIR_COST := 10

var repaired_texture: Texture2D = preload("res://assets/sprites/slice/outpost_core_repaired.png")


func get_prompt(world: Node) -> String:
	if not world.core_repaired:
		var crystals: int = world.pocket.count(SliceWorld.ITEM_CRYSTAL)
		if crystals >= REPAIR_COST:
			return "按 E 修复前哨核心（消耗 %d 晶体）" % REPAIR_COST
		return "修复前哨核心需要 %d 晶体（背包 %d）" % [REPAIR_COST, crystals]
	if world.is_core_charged():
		return "前哨核心已充能"
	if world.catalyst_count <= 0:
		return "为核心充能需要催化剂（去反应器加工）"
	return "按 E 注入催化剂充能（%d/%d）" % [world.core_energy, SliceWorld.CORE_CHARGE_TARGET]


func try_interact(world: Node) -> void:
	if not world.core_repaired:
		if not world.spend_pocket_crystals(REPAIR_COST):
			return
		(get_parent() as Sprite2D).texture = repaired_texture
		world.mark_core_repaired()
		return
	world.charge_core()
