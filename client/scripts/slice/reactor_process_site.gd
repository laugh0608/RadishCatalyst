class_name ReactorProcessSite
extends Area2D

## Reactor processing interaction. Activation is recorded here; actual crystal →
## catalyst processing is being re-wired to spatial input / output buffers in L0
## package 2, so the tick is inert for now and the prompt says so
## (docs/features/slice-item-inventory-model-v1.md).


func get_prompt(world: Node) -> String:
	if not world.reactor_active:
		return "按 E 激活反应器（进出料 L0 包 2 接入）"
	return "反应器已激活（进出料 L0 包 2 接入）"


func try_interact(world: Node) -> void:
	world.activate_reactor()
