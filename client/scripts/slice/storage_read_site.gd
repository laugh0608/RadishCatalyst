class_name StorageReadSite
extends Area2D

## Retained compatibility surface for old scene prototypes. Current storage
## state is presented by the shared building action panel.


func get_prompt(_world: Node) -> String:
	return "储物箱：靠近后按 E 查看分类库存、模式与供电状态"


func try_interact(_world: Node) -> void:
	pass
