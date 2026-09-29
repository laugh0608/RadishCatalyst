extends SceneTree

const Demo := preload("res://scripts/prototypes/factory_refinement/demo.gd")
const Boot := preload("res://scenes/boot/Boot.tscn")
var demo: Control


func _init() -> void:
	call_deferred("_open")


func _open() -> void:
	root.title = "异星催化 · 圆润机械化工交互样板"
	root.mode = Window.MODE_WINDOWED
	root.content_scale_size = Vector2i(1440, 900)
	root.size = Vector2i(1440, 900)
	root.min_size = Vector2i(1152, 720)
	var repo := ProjectSettings.globalize_path("res://..").simplify_path()
	var isolated := repo.path_join("tools/runtime-intake/review-worlds/factory-refinement-v1")
	var boot := Boot.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(isolated.path_join("slice"))
	boot.factory_save_root = isolated.path_join("factory")
	root.add_child(boot)
	await process_frame
	if boot.startup_menu == null:
		push_error("Refinement demo: isolated Boot startup failed")
		quit(1)
		return
	boot.startup_menu.hide()
	demo = Demo.new()
	boot.add_child(demo)
	await process_frame
	print("REFINEMENT_DEMO_READY: isolated Boot; in-memory model; no world save")
