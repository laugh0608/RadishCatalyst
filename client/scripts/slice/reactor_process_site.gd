class_name ReactorProcessSite
extends Area2D

## Retained compatibility surface for old scene prototypes. The current slice
## reactor is operated through its building panel and fixed logistics ports.


func get_prompt(_world: Node) -> String:
	return "反应器固定左侧 IN、右侧 OUT；靠近设备按 E 查看状态"


func try_interact(_world: Node) -> void:
	pass
