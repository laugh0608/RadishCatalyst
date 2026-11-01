extends RefCounted

const Boot := preload("res://scenes/boot/Boot.tscn")
const Demo := preload("res://scripts/prototypes/factory_camera/demo.gd")


static func open(tree: SceneTree, isolated_root: String, screenshots: String) -> Dictionary:
	var boot := Boot.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(isolated_root.path_join("slice"))
	boot.factory_save_root = isolated_root.path_join("factory")
	tree.root.add_child(boot)
	await tree.process_frame
	if boot.startup_menu == null:
		push_error("Camera study: isolated Boot startup failed")
		return {}
	boot.startup_menu.hide()
	var demo := Demo.new()
	demo.output_root = isolated_root
	demo.screenshot_root = screenshots
	boot.add_child(demo)
	await tree.process_frame
	if not demo.view.prepared or not demo.view.resource_error.is_empty():
		push_error("Camera study: imported resources failed")
		return {}
	return {"boot": boot, "demo": demo}
