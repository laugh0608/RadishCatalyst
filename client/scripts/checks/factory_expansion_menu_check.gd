extends SceneTree

const Boot := preload("res://scenes/boot/Boot.tscn")
const Store := preload("res://scripts/factory/save/store.gd")
var evidence := ""
var checks := 0
var failures: Array[String] = []


func _init() -> void:
	Engine.max_fps = 60
	call_deferred("run")


func expect(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label); push_error(label)


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--evidence="): evidence = arg.trim_prefix("--evidence=")
	if evidence.is_empty(): push_error("E1 menu requires isolated evidence root"); quit(1); return
	var boot := Boot.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(evidence.path_join("slice"))
	boot.factory_save_root = evidence.path_join("factory")
	root.add_child(boot)
	boot.startup_menu.factory_requested.emit()
	await process_frame
	var menu: Control = boot.factory_menu
	expect(menu.world_type.selected == 0 and menu.world_type.item_count == 4, "foundation remains default; E1 is explicit third choice")
	var records := []
	for option in 3:
		menu.world_type.select(option)
		menu.title_input.text = ["基础菜单回归", "V5 菜单回归", "E1 独立新世界"][option]
		menu.create_button.pressed.emit()
		var world: Control = boot.factory_world
		expect(world != null and world.initialized, "formal menu creation " + str(option))
		if world == null: break
		var doc: Dictionary = Store.Codec.snapshot(world.model, world.store.world_id, world.store.world_name, world.store.sequence)
		expect(doc.save_schema_version == [1, 5, 6][option], "world uses selected schema " + str(option))
		if option == 2:
			expect(doc.ruleset_id == Store.Codec.V6.Expansion.RULESET_ID and doc.map_id == Store.Codec.V6.Expansion.MAP_ID and world.model.owned_count() == 165 and world.model.bag.is_empty(), "E1 exact identity and ordinary zero-material supply")
		elif option == 1:
			expect(world.model.admission_items.size() == 4 and not world.model.kits.has("refinery"), "V5 whitelist and supply unchanged")
		var id: String = world.store.world_id
		world._action("return", null)
		await process_frame
		expect(boot.factory_world == null, "save return releases " + str(option))
		records.append({"id": id, "schema": doc.save_schema_version, "hash": FileAccess.get_sha256(boot.factory_save_root.path_join(id).path_join("autosave.json"))})
		for previous in records:
			expect(FileAccess.get_sha256(boot.factory_save_root.path_join(previous.id).path_join("autosave.json")) == previous.hash, "new world does not overwrite previous world " + previous.id)
	for record in records:
		menu = boot.factory_menu
		var index: int = menu.worlds.find_custom(func(entry): return entry.id == record.id)
		expect(index >= 0, "saved world listed by stable identity")
		if index < 0: continue
		menu.list.select(index)
		menu.list.item_selected.emit(index)
		expect(menu.worlds[index].schema == record.schema and (not menu.upgrade_button.disabled if record.schema == 6 else menu.upgrade_button.disabled), "1/5/6 continue original rules; E1 offers explicit separate copy")
		if record.schema == 6: expect("生产扩建 E1" in menu.worlds[index].name, "list explicitly labels E1")
		menu.continue_button.pressed.emit()
		var world: Control = boot.factory_world
		expect(world != null and world.initialized and Store.Codec.snapshot(world.model, world.store.world_id, world.store.world_name, world.store.sequence).save_schema_version == record.schema, "formal continue retains schema " + str(record.schema))
		if world != null: world._action("return", null)
		await process_frame
	boot.free()
	var file := FileAccess.open(evidence.path_join("menu-result.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"assertions": checks, "failures": failures, "input": "formal Boot with menu/button/list signals; isolated foundation/V5/E1 creation and continue; no natural-production or screenshots claim"}, "\t"))
	file.close()
	print("E1 menu: %d assertions, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)
