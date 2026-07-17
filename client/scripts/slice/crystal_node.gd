class_name CrystalNode
extends Area2D

## Harvestable crystal cluster: one interaction collects the full yield and
## removes the cluster (sprite root) from the map.

@export var yield_amount := 1


func get_prompt(_world: Node) -> String:
	return "按 E 采集晶体（+%d）" % yield_amount


func try_interact(world: Node) -> void:
	world.add_crystals(yield_amount)
	get_parent().queue_free()
