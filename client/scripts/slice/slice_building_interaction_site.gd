class_name SliceBuildingInteractionSite
extends Area2D

## Shared interaction surface for placed L3 buildings. The operation panel owns
## adjustment / demolition input; this area only resolves the target instance.


func get_prompt(_world: Node) -> String:
	var instance := get_parent() as SliceBuildingInstance
	if instance.building_id == SliceBuildingCatalog.REACTOR_ID:
		if instance.powered:
			return "按 E 管理基础反应器（通电，待接进出料 L5）"
		return "按 E 管理基础反应器（断电：未接入核心电网）"
	if (
		instance.definition.power_role
		== SliceBuildingDefinition.POWER_RELAY
	):
		return "按 E 管理%s（%s）" % [
			instance.definition.display_name,
			instance.power_status_text(),
		]
	return "按 E 管理%s" % instance.definition.display_name


func try_interact(world: Node) -> void:
	world.open_building_actions(get_parent())


func get_interaction_priority() -> int:
	return (get_parent() as SliceBuildingInstance).interaction_priority()
