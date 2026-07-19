class_name WorkbenchBuildSite
extends Area2D

## Workbench build interaction: crafting a collector consumes crystals and
## puts the player into the carry state; placement happens on crystal ground
## via SliceWorld. Cost and carry/placement rules live in SliceWorld
## (docs/features/slice-harvest-and-build-v1.md).


func get_prompt(world: Node) -> String:
	if world.carrying_collector:
		return "先放置携带中的采集器"
	var crystals: int = world.pocket.count(SliceWorld.ITEM_CRYSTAL)
	if crystals >= SliceWorld.COLLECTOR_COST:
		return "按 E 制造采集器（消耗 %d 晶体）" % SliceWorld.COLLECTOR_COST
	return "制造采集器需要 %d 晶体（背包 %d）" % [SliceWorld.COLLECTOR_COST, crystals]


func try_interact(world: Node) -> void:
	world.try_craft_collector()
