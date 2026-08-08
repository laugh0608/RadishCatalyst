class_name CollectorPickupSite
extends Area2D

## Interaction on a placed collector opens its operation panel. Buffer transfer
## remains an explicit panel action subject to backpack free space.


func get_prompt(world: Node) -> String:
	var collector := get_parent() as SliceCollector
	var power_text := collector.power_status_text()
	if not collector.powered:
		return "按 E 管理采集器（%s，缓冲 %d/%d）" % [
			power_text, collector.buffer, SliceCollector.BUFFER_CAP
		]
	if collector.buffer <= 0:
		return "按 E 管理采集器（通电，缓冲 0/%d）" % SliceCollector.BUFFER_CAP
	if world.pocket.free_space_for(SliceWorld.ITEM_CRYSTAL) <= 0:
		return "按 E 管理采集器（通电，背包已满，缓冲 %d/%d）" % [
			collector.buffer, SliceCollector.BUFFER_CAP
		]
	return "按 E 管理采集器（通电，待取 %d/%d）" % [
		collector.buffer, SliceCollector.BUFFER_CAP
	]


func try_interact(world: Node) -> void:
	var collector := get_parent() as SliceCollector
	world.open_building_actions(collector)


func get_interaction_priority() -> int:
	return 10
