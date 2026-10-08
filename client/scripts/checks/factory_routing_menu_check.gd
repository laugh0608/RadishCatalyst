extends SceneTree

const Boot := preload("res://scenes/boot/Boot.tscn")
const Store := preload("res://scripts/factory/save/store.gd")
var checks := 0
var failures: Array[String] = []
var evidence := ""


func _init() -> void:
	Engine.max_fps = 60
	call_deferred("run")


func expect(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		push_error(message)


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	assert(not evidence.is_empty())
	var store := Store.new(evidence.path_join("factory"))
	var created := store.create("旧规则菜单验证", Store.Codec.V2.Config.SUPPLY_ID, true)
	expect(created.ok, "isolated schema3 menu fixture prepared")
	if not created.ok:
		finish()
		return
	var id: String = store.world_id
	var original_hash := FileAccess.get_sha256(store.path("autosave.json"))
	store.release()
	var boot := Boot.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(evidence.path_join("slice"))
	boot.factory_save_root = store.root
	root.add_child(boot)
	boot.startup_menu.factory_requested.emit()
	await process_frame
	var menu: Control = boot.factory_menu
	menu.list.select(0)
	menu.list.item_selected.emit(0)
	expect(not menu.continue_button.disabled and not menu.upgrade_button.disabled, "old world offers independent continue and upgrade actions")
	menu.upgrade_button.pressed.emit()
	expect(menu.upgrade_dialog.visible and "50ms" in menu.upgrade_dialog.dialog_text and "独立备份" in menu.upgrade_dialog.dialog_text, "upgrade dialog explains timing and original backup")
	menu.upgrade_dialog.get_cancel_button().pressed.emit()
	await process_frame
	expect(not menu.upgrade_dialog.visible and FileAccess.get_sha256(store.path("autosave.json")) == original_hash and not DirAccess.dir_exists_absolute(store.path("session.lock")), "cancel leaves source and ownership unchanged")
	menu.continue_button.pressed.emit()
	expect(boot.factory_world != null and boot.factory_world.model.supply_id == Store.Codec.V2.Config.SUPPLY_ID and not boot.factory_world.model.kits.has("splitter"), "continue keeps schema3 model and original supply")
	if boot.factory_world == null:
		boot.free()
		finish()
		return
	boot.factory_world._action("return", null)
	await process_frame
	menu = boot.factory_menu
	menu.list.select(0)
	menu.list.item_selected.emit(0)
	original_hash = FileAccess.get_sha256(store.path("autosave.json"))
	menu.upgrade_button.pressed.emit()
	menu.upgrade_dialog.get_ok_button().pressed.emit()
	await process_frame
	expect(boot.factory_world != null and boot.factory_world.initialized, "confirmed menu upgrade reconstructs formal world")
	if boot.factory_world != null:
		expect(boot.factory_world.model.kits.get("splitter", 0) == 8 and boot.factory_world.model.kits.get("merger", 0) == 8, "confirmed upgrade grants exact attachment budget")
		var backup_found := false
		for name in DirAccess.get_files_at(store.path("backups")):
			if name.begins_with("pre-routing-v3-") and FileAccess.get_sha256(store.path("backups/" + name)) == original_hash:
				backup_found = true
		expect(backup_found, "menu upgrade keeps byte-identical original outside normal backup slots")
		boot.factory_world._action("return", null)
		await process_frame
	menu = boot.factory_menu
	menu.list.select(0)
	menu.list.item_selected.emit(0)
	expect(menu.upgrade_button.disabled and not menu.continue_button.disabled and menu.worlds[0].id == id and menu.worlds[0].schema == 4, "upgraded world retains identity and cannot receive a second grant")
	boot.free()
	finish()


func finish() -> void:
	var file := FileAccess.open(evidence.path_join("menu-result.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"assertions": checks, "failures": failures, "input": "formal Boot with button/list signals; isolated legacy fixture; no screenshots"}, "\t"))
	file.close()
	print("Routing menu checks: %d assertions, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
