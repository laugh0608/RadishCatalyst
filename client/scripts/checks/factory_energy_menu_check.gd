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
	if evidence.is_empty(): push_error("E2 menu requires isolated evidence root"); quit(1); return
	var boot := Boot.instantiate()
	boot.slice_save_catalog = SliceSaveCatalog.new(evidence.path_join("slice"))
	boot.factory_save_root = evidence.path_join("factory")
	root.add_child(boot)
	boot.startup_menu.factory_requested.emit()
	await process_frame
	var menu: Control = boot.factory_menu
	expect(menu.world_type.selected == 0 and menu.world_type.item_count == 4, "foundation remains default; E1 is explicit third choice")
	var records := []
	for option in 4:
		menu.world_type.select(option)
		menu.title_input.text = ["基础菜单回归", "V5 菜单回归", "E1 独立新世界", "E2 能源新世界"][option]
		menu.create_button.pressed.emit()
		var world: Control = boot.factory_world
		expect(world != null and world.initialized, "formal menu creation " + str(option))
		if world == null: break
		var doc: Dictionary = Store.Codec.snapshot(world.model, world.store.world_id, world.store.world_name, world.store.sequence)
		expect(doc.save_schema_version == [1, 5, 6, 7][option], "world uses selected schema " + str(option))
		if option == 2:
			expect(doc.ruleset_id == Store.Codec.V6.Expansion.RULESET_ID and doc.map_id == Store.Codec.V6.Expansion.MAP_ID and world.model.owned_count() == 165 and world.model.bag.is_empty(), "E1 exact identity and ordinary zero-material supply")
		elif option == 1:
			expect(world.model.admission_items.size() == 4 and not world.model.kits.has("refinery"), "V5 whitelist and supply unchanged")
		if option == 3:
			expect(world.model.energy_origin.is_empty() and world.model.kits.cell_generator == 0 and world.model.owned_count() == 165, "new E2 has no source identity or extra fuel/kits")
		if option == 2:
			world.ui.paused = true
			_seed_natural_partial(world.model)
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
	menu = boot.factory_menu
	var source_id: String = records[2].id
	var source_file: String = boot.factory_save_root.path_join(source_id).path_join("autosave.json")
	var original := FileAccess.get_file_as_bytes(source_file)
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(source_file))
	var index: int = menu.worlds.find_custom(func(entry): return entry.id == source_id)
	menu.list.select(index); menu.list.item_selected.emit(index)
	menu.upgrade_button.pressed.emit()
	expect(menu.upgrade_dialog.visible and "原 E1 保留" in menu.upgrade_dialog.dialog_text, "copy dialog explains independent world and retained original")
	menu.upgrade_dialog.canceled.emit(); menu.upgrade_dialog.hide()
	expect(boot.factory_world == null and menu.catalog.list_worlds().size() == 4 and FileAccess.get_file_as_bytes(source_file) == original, "cancel copy changes neither world nor source")
	menu.upgrade_button.pressed.emit(); menu.upgrade_dialog.hide(); menu.upgrade_dialog.confirmed.emit()
	var copied: Control = boot.factory_world
	expect(copied != null and copied.initialized, "formal explicit copy enters E2")
	if copied != null:
		copied.ui.paused = true
		var result: Dictionary = Store.Codec.snapshot(copied.model, copied.store.world_id, copied.store.world_name, copied.store.sequence)
		expect(result.save_schema_version == 7 and result.world_id != source_id and result.sequence == 1, "copy creates independent V7 identity")
		expect(FileAccess.get_file_as_bytes(source_file) == original, "copy never rewrites original E1 bytes")
		var projected: Dictionary = result.state.duplicate(true)
		projected.erase("energy_origin"); projected.kits.erase("cell_generator")
		projected.assembly_counts.erase("cell_generator"); projected.completed_by_recipe.erase("cell_assembly")
		for entity in projected.entities:
			if Store.Codec.V2.Config.POWER.has(entity.type): entity.erase("enabled")
		for record in [projected.statistics.totals, projected.statistics.current] + projected.statistics.buckets:
			for field in ["enabled_kj", "base_supplied_kj", "cell_supplied_kj", "discarded_kj", "cells_activated"]: record.erase(field)
		expect(preload("res://scripts/checks/factory_expansion_compare.gd").equivalent(projected, source.state), "copy preserves every existing E1 authoritative field including active batch and statistics")
		expect(copied.model.energy_origin.source_sha256 == FileAccess.get_sha256(source_file) and copied.model.energy_origin.source_sequence == source.sequence, "copy records exact selected source")
		var count: int = copied.model.completed_by_recipe.direct_refining
		copied._action("pause", null)
		var deadline := Time.get_ticks_msec() + 15000
		while copied.model.completed_by_recipe.direct_refining == count and Time.get_ticks_msec() < deadline:
			await process_frame
		expect(copied.model.completed_by_recipe.direct_refining == count + 1, "copied partial furnace completes through natural Boot clock without reinvesting")
		copied._action("return", null)
		await process_frame
		expect(menu.catalog.list_worlds().size() == 5 and FileAccess.get_file_as_bytes(source_file) == original, "saved E2 and unchanged E1 coexist")
	boot.free()
	var file := FileAccess.open(evidence.path_join("menu-result.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"assertions": checks, "failures": failures, "input": "formal Boot with menu/button/list signals; isolated foundation/V5/E1/E2 creation and continue; explicit E1 copy/cancel; source partial batch produced with fixed steps and actor repositioning as declared state fixture; copied partial batch continues under actual Boot clock; no full natural origin or screenshots claim"}, "\t"))
	file.close()
	print("E2 menu: %d assertions, %d failures" % [checks, failures.size()])
	quit(0 if failures.is_empty() else 1)


func _seed_natural_partial(model: RefCounted) -> void:
	# A nonempty, conserved source fixture; deliberately not natural Boot-clock evidence.
	var collector: Dictionary = model.place("collector", Vector2i(-28, -12)).entity
	var furnace: Dictionary = model.place("refinery", Vector2i(-24, -12)).entity
	model.place("power_source", Vector2i(-27, -16))
	for i in 45: model._step(0.05)
	model.actor.x = -28.6; model.actor.z = -11.5
	expect(model.transfer(collector.id, "iron_ore", false, true).ok, "copy source mines real iron")
	model.actor.x = -24.6; model.actor.z = -11.5
	expect(model.transfer(furnace.id, "iron_ore", true, true).ok, "copy source transfers real iron")
	for i in 20: model._step(0.05)
	expect(furnace.processing and furnace.progress > 0 and not furnace.invested.is_empty(), "copy source contains a real partial batch")
