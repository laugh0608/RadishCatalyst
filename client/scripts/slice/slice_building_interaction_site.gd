class_name SliceBuildingInteractionSite
extends Area2D

## Shared interaction surface for placed L3 buildings. The operation panel owns
## adjustment / demolition input; this area only resolves the target instance.


func get_prompt(world: Node) -> String:
	var instance := get_parent() as SliceBuildingInstance
	if instance.building_id == SliceBuildingCatalog.REACTOR_ID:
		var reactor := instance as SliceReactor
		return "按 E 管理基础反应器（%s，晶体 %d/2，催化剂 %d/1）" % [
			world.reactor_status_text(reactor),
			reactor.input_inventory.count(SliceReactor.INPUT_ITEM_ID),
			reactor.output_inventory.count(SliceReactor.OUTPUT_ITEM_ID),
		]
	if (
		instance.definition.power_role
		== SliceBuildingDefinition.POWER_RELAY
	):
		return "按 E 管理%s（%s）" % [
			instance.definition.display_name,
			instance.power_status_text(),
		]
	if instance is SliceStorage:
		var storage := instance as SliceStorage
		return "按 E 管理储物箱（%s｜%s｜%d/%d 类）" % [
			storage.mode_display_name(),
			"通电" if storage.powered else "断电",
			storage.type_count(),
			SliceStorage.TYPE_LIMIT,
		]
	if instance is SliceConveyor:
		var conveyor := instance as SliceConveyor
		var cargo_label := "空"
		if conveyor.cargo_item_id == SliceWorld.ITEM_CRYSTAL:
			cargo_label = "晶体运输中"
		elif conveyor.cargo_item_id == SliceWorld.ITEM_CATALYST:
			cargo_label = "催化剂运输中"
		return "按 E 管理传送带（%s）" % cargo_label
	return "按 E 管理%s" % instance.definition.display_name


func try_interact(world: Node) -> void:
	world.open_building_actions(get_parent())


func get_interaction_priority() -> int:
	return (get_parent() as SliceBuildingInstance).interaction_priority()
