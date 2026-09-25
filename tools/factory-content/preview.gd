extends SceneTree

## Manual static review only: no Boot migration, user saves, or production simulation.
const Preview := preload("res://scripts/checks/factory_discovery_preview.gd")


func _init() -> void:
	call_deferred("_open")


func _open() -> void:
	root.title = "异星催化 · D1 场景与资产预览"
	root.content_scale_size = Vector2i(1440, 900)
	root.size = Vector2i(1440, 900)
	root.min_size = Vector2i(1100, 720)
	root.add_child(Preview.new())
