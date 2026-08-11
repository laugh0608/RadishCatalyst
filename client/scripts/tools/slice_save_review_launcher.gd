extends SceneTree

const BootScene := preload("res://scenes/boot/Boot.tscn")
func _init() -> void:
	call_deferred("_launch")


func _launch() -> void:
	var review_root := _argument_value(
		"--review-root=", SliceCheckPaths.review_worlds("current")
	)
	var catalog := SliceSaveCatalog.new(review_root)
	if catalog.list_worlds().is_empty() and catalog.list_trash().is_empty():
		push_error("复核目录没有可显示的世界：%s" % review_root)
		quit(1)
		return
	var boot := BootScene.instantiate()
	boot.slice_save_catalog = catalog
	root.add_child(boot)
	await process_frame
	var menu := boot.get_node_or_null("StartupMenu") as StartupMenu
	if menu == null:
		push_error("人工复核启动器未能打开 StartupMenu。")
		quit(1)
		return
	menu.load_game_button.pressed.emit()


func _argument_value(prefix: String, fallback: String) -> String:
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with(prefix):
			var value := argument.trim_prefix(prefix).strip_edges()
			if not value.is_empty():
				return value
	return fallback
