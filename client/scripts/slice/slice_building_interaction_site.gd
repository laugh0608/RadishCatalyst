class_name SliceBuildingInteractionSite
extends Area2D

## Shared interaction surface for placed L3 buildings. The operation panel owns
## adjustment / demolition input; this area only resolves the target instance.


func get_prompt(_world: Node) -> String:
	var instance := get_parent() as SliceBuildingInstance
	return "按 E 管理%s" % instance.definition.display_name


func try_interact(world: Node) -> void:
	world.open_building_actions(get_parent())


func get_interaction_priority() -> int:
	return (get_parent() as SliceBuildingInstance).interaction_priority()
