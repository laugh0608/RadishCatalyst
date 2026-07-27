class_name SliceCriticalSample
extends Area2D

## Package-2 critical pickup. It bypasses ordinary inventory capacity and asks
## SliceCombatController to perform the authoritative dropped -> carried move.

var combat_controller: SliceCombatController


func get_prompt(_world: Node) -> String:
	return "按 E 拾取晶腺样本（任务物品）"


func get_interaction_priority() -> int:
	return 100


func try_interact(_world: Node) -> void:
	if combat_controller != null:
		combat_controller.collect_critical_sample(self)
