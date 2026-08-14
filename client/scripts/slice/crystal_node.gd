class_name CrystalNode
extends Area2D

## Harvestable crystal cluster: one interaction collects the full yield and
## removes the cluster (sprite root) from the map.

@export var yield_amount := 1


func get_prompt(world: Node) -> String:
	if world.pocket.free_space_for(SliceWorld.ITEM_CRYSTAL) < yield_amount:
		return "背包已满（需 %d 空位采集）" % yield_amount
	return "按 E 采集晶体（+%d）" % yield_amount


func try_interact(world: Node) -> void:
	var cluster := get_parent()
	if world.harvest_crystals(cluster.name, yield_amount):
		cluster.queue_free()
