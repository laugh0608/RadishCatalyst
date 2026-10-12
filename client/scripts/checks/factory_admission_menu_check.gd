extends "res://scripts/checks/factory_routing_menu_check.gd"


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	assert(not evidence.is_empty())
	var store := Store.new(evidence.path_join("factory"))
	var created := store.create("V4 准入口升级菜单", Store.Codec.V2.Config.ROUTING_SUPPLY_ID, true)
	expect(created.ok, "isolated schema4 prepared")
	if not created.ok: finish(); return
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
	expect(not menu.continue_button.disabled and menu.upgrade_button.text == "升级物品准入口", "V4 offers independent continue and admission upgrade")
	menu.upgrade_button.pressed.emit()
	expect(menu.upgrade_dialog.visible and "8 个物品准入口" in menu.upgrade_dialog.dialog_text and "总配额" in menu.upgrade_dialog.dialog_text and "独立备份" in menu.upgrade_dialog.dialog_text, "confirmation explains supply quota and source backup")
	menu.upgrade_dialog.get_cancel_button().pressed.emit()
	await process_frame
	expect(FileAccess.get_sha256(store.path("autosave.json")) == original_hash and not DirAccess.dir_exists_absolute(store.path("session.lock")), "cancel does not acquire lock or publish")
	menu.continue_button.pressed.emit()
	expect(boot.factory_world != null and boot.factory_world.model.supply_id == Store.Codec.V2.Config.ROUTING_SUPPLY_ID and not boot.factory_world.model.kits.has("admission_gate"), "continue preserves original V4 world")
	if boot.factory_world == null: boot.free(); finish(); return
	boot.factory_world._action("return", null)
	await process_frame
	menu = boot.factory_menu
	menu.list.select(0)
	menu.list.item_selected.emit(0)
	original_hash = FileAccess.get_sha256(store.path("autosave.json"))
	menu.upgrade_button.pressed.emit()
	menu.upgrade_dialog.get_ok_button().pressed.emit()
	await process_frame
	expect(boot.factory_world != null and boot.factory_world.initialized, "confirmed upgrade reconstructs formal V5")
	if boot.factory_world != null:
		expect(boot.factory_world.model.kits.admission_gate == 8 and boot.factory_world.model.supply_id == Store.Codec.V2.Config.ADMISSION_SUPPLY_ID, "confirmed upgrade grants exactly eight new gates")
		var retained := false
		for name in DirAccess.get_files_at(store.path("backups")):
			if name.begins_with("pre-admission-v4-") and FileAccess.get_sha256(store.path("backups/" + name)) == original_hash: retained = true
		expect(retained, "original V4 retained byte-for-byte")
		boot.factory_world._action("return", null)
		await process_frame
	menu = boot.factory_menu
	menu.list.select(0)
	menu.list.item_selected.emit(0)
	expect(menu.upgrade_button.disabled and menu.worlds[0].schema == 5 and menu.worlds[0].id == id, "V5 cannot receive another upgrade grant")
	menu.world_type.select(1)
	menu.title_input.text = "新建 V5 菜单"
	menu.create_button.pressed.emit()
	expect(boot.factory_world != null and boot.factory_world.model.kits.admission_gate == 8 and boot.factory_world.model.entities.is_empty(), "new exploration world is ordinary zero-inventory V5")
	if boot.factory_world != null: boot.factory_world._action("return", null)
	boot.free()
	finish()
