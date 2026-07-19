class_name CollectorPickupSite
extends Area2D

## Interaction on a placed collector: press E to move its output buffer into the
## player backpack, subject to backpack free space
## (docs/features/slice-item-inventory-model-v1.md).


func get_prompt(world: Node) -> String:
	var collector := get_parent() as SliceCollector
	if collector.buffer <= 0:
		return "采集器运转中（缓冲 0/%d）" % SliceCollector.BUFFER_CAP
	if world.pocket.free_space() <= 0:
		return "背包已满（缓冲 %d/%d）" % [collector.buffer, SliceCollector.BUFFER_CAP]
	return "按 E 取晶体（缓冲 %d/%d）" % [collector.buffer, SliceCollector.BUFFER_CAP]


func try_interact(world: Node) -> void:
	world.collect_from_collector(get_parent())
