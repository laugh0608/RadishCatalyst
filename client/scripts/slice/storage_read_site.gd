class_name StorageReadSite
extends Area2D

## Storage tank read-out: catalyst refined by the reactor is stored here up to
## the capacity cap. This interaction is read-only (no side effect); it surfaces
## the stored amount when the player stands near the tank
## (docs/features/slice-recipe-processing-v1.md).


func get_prompt(world: Node) -> String:
	return "储存罐：催化剂 %d/%d" % [world.catalyst_count, SliceWorld.CATALYST_CAP]


func try_interact(_world: Node) -> void:
	pass
