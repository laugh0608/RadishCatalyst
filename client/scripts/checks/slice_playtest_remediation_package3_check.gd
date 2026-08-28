extends SceneTree

const SliceWorldScene := preload("res://scenes/slice/SliceWorld.tscn")

var failures: Array[String] = []
var _assertion_count := 0
var _test_root := ""


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	_test_root = "user://slice-playtest-remediation-package3-%d" % Time.get_ticks_usec()
	_check_flat_read_model_and_transfer_contracts()
	await _check_shared_container_view()
	await _check_world_container_paths()
	if failures.is_empty():
		print(
			"Slice playtest remediation package 3 checks passed (%d assertions)."
			% _assertion_count
		)
		_cleanup()
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	_cleanup()
	quit(1)


func _check_flat_read_model_and_transfer_contracts() -> void:
	var pocket := Inventory.new(SliceInventoryProfiles.category_pocket())
	var core := Inventory.new(SliceInventoryProfiles.category_core_storage())
	pocket.add(SliceWorld.ITEM_CRYSTAL, 5)
	pocket.add(SliceWorld.ITEM_PART, 3)
	core.add(SliceWorld.ITEM_CATALYST, 2)
	var items := SliceInventoryReadModel.paired_inventory_items(pocket, core)
	_expect_equal(items.size(), 3, "paired model omits every empty known item")
	_expect_equal(
		_items_ids(items),
		[SliceWorld.ITEM_CRYSTAL, SliceWorld.ITEM_CATALYST, SliceWorld.ITEM_PART],
		"all view stays flat in catalog order"
	)
	_expect_equal(
		int(items[0]["left_count"]),
		5,
		"paired model reads the authoritative pocket count"
	)
	_expect_equal(
		int(items[1]["right_count"]),
		2,
		"paired model reads the authoritative target count"
	)

	core.restore_existing("future.item", 99998)
	pocket.restore_existing("future.item", 3)
	var total_before := pocket.count("future.item") + core.count("future.item")
	_expect_equal(
		pocket.transfer_up_to(core, "future.item", 3),
		1,
		"capacity-limited transfer moves only the accepted amount"
	)
	_expect_equal(
		pocket.count("future.item") + core.count("future.item"),
		total_before,
		"partial transfer conserves property"
	)

	var storage := Inventory.new(SliceInventoryProfiles.category_storage())
	for item_id in [
		SliceWorld.ITEM_CRYSTAL,
		SliceWorld.ITEM_PART,
		SliceWorld.ITEM_CATALYST,
		SliceWorld.ITEM_FLOOR_KIT,
	]:
		storage.add(item_id, 1)
	var storage_before := storage.contents_view()
	_expect_equal(
		storage.add(SliceWorld.ITEM_CONVEYOR_KIT, 1),
		0,
		"fifth storage category is rejected"
	)
	_expect_equal(
		storage.contents_view(),
		storage_before,
		"type-limit rejection changes no storage contents"
	)
	var reactor_input := Inventory.new(
		SliceInventoryProfiles.device_reactor_input()
	)
	_expect_equal(
		reactor_input.add(SliceWorld.ITEM_CATALYST, 1),
		0,
		"reactor input whitelist rejects catalyst"
	)


func _check_shared_container_view() -> void:
	var view := SlicePairedContainerView.new()
	root.add_child(view)
	await process_frame
	var rows := SliceInventoryReadModel.paired_content_items(
		{SliceWorld.ITEM_CRYSTAL: 5, SliceWorld.ITEM_PART: 3},
		{SliceWorld.ITEM_CATALYST: 2},
		{SliceWorld.ITEM_CRYSTAL: 200, SliceWorld.ITEM_PART: 200},
		{SliceWorld.ITEM_CATALYST: 200}
	)
	view.set_snapshot({
		"left_source": "pocket",
		"right_source": "target",
		"left_title": "随身背包",
		"right_title": "目标容器",
		"items": rows,
	})
	_expect_equal(view.item_row_count(), 3, "shared view receives only held rows")
	_expect_equal(
		view.visible_item_ids("pocket"),
		[SliceWorld.ITEM_CRYSTAL, SliceWorld.ITEM_PART],
		"left side renders only items actually held on the left"
	)
	_expect_equal(
		view.visible_item_ids("target"),
		[SliceWorld.ITEM_CATALYST],
		"right side renders only items actually held on the right"
	)
	view.set_filter(SliceItemDefinition.CATEGORY_RAW_MATERIAL)
	_expect_equal(
		view.visible_item_ids("pocket"),
		[SliceWorld.ITEM_CRYSTAL],
		"category filter changes only the visible subset"
	)
	_expect_equal(view.item_row_count(), 3, "filter keeps the underlying flat model")
	view.set_filter(SlicePairedContainerView.FILTER_ALL)
	_expect(
		view.select_item(SliceWorld.ITEM_PART, "pocket", true),
		"click selection accepts a held stack"
	)
	_expect_equal(view.selected_amount(), 2, "control selection rounds an odd half up")
	view.halve_selection()
	_expect_equal(view.selected_amount(), 1, "each control press halves again")
	var requests: Array[Dictionary] = []
	view.transfer_requested.connect(func(item_id: String, source: String, requested: int):
		requests.append({"item_id": item_id, "source": source, "requested": requested})
	)
	_expect(view.request_selected_transfer(), "Enter-equivalent action emits a transfer")
	_expect_equal(
		requests,
		[{"item_id": SliceWorld.ITEM_PART, "source": "pocket", "requested": 1}],
		"click and keyboard action share the selected request"
	)
	view.cancel_interaction()
	_expect_equal(view.selected_amount(), 0, "cancel clears the session selection")
	_expect(
		view.result_text().contains("未移动"),
		"cancel explains that property did not move"
	)
	view.free()


func _check_world_container_paths() -> void:
	var service := SliceSaveService.new(_test_root.path_join("world"))
	var world := SliceWorldScene.instantiate() as SliceWorld
	world.save_service = service
	root.add_child(world)
	await process_frame
	await physics_frame
	_clear_inventory(world.pocket)
	_clear_inventory(world.core_storage)
	world.core_repaired = true
	world.pocket.add(SliceWorld.ITEM_CRYSTAL, 5)
	world.pocket.add(SliceWorld.ITEM_PART, 3)
	world.core_storage.add(SliceWorld.ITEM_CATALYST, 2)
	world.inventory_changed.emit()
	world.core_storage_changed.emit()

	world._core_storage_panel.open()
	_expect_equal(
		world._core_storage_panel.item_row_count(),
		3,
		"core warehouse defaults to the three actually held item types"
	)
	_expect_equal(
		world._core_storage_panel.pocket_slot(SliceWorld.ITEM_PULSE_RIFLE),
		null,
		"absent unlocked equipment does not occupy a core row"
	)
	var total_parts := (
		world.pocket.count(SliceWorld.ITEM_PART)
		+ world.core_storage.count(SliceWorld.ITEM_PART)
	)
	_expect_equal(
		world._core_storage_panel.transfer_drag(
			SliceWorld.ITEM_PART, SliceCoreStoragePanel.SOURCE_POCKET, true
		),
		2,
		"core drag reuses rounded half transfer"
	)
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_PART)
		+ world.core_storage.count(SliceWorld.ITEM_PART),
		total_parts,
		"core drag conserves the selected item"
	)
	world._core_storage_panel.close()

	var storage := world._spawn_building(
		SliceBuildingCatalog.find(SliceBuildingCatalog.STORAGE_ID),
		"package3-storage",
		Vector2i(70, 10),
		0,
		{}
	) as SliceStorage
	world.open_building_actions(storage)
	var storage_view := world._building_action_panel.container_view()
	_expect(storage_view.visible, "storage opens the shared paired-container view")
	_expect(
		storage_view.select_item(SliceWorld.ITEM_CRYSTAL, "pocket", true),
		"storage view selects a pocket stack"
	)
	_expect(storage_view.request_selected_transfer(), "storage click action requests transfer")
	_expect_equal(storage.inventory.count(SliceWorld.ITEM_CRYSTAL), 3, "odd half moves into storage")
	_expect_equal(world.pocket.count(SliceWorld.ITEM_CRYSTAL), 2, "odd half leaves the remainder")
	for item_id in [
		SliceWorld.ITEM_PART,
		SliceWorld.ITEM_CATALYST,
		SliceWorld.ITEM_FLOOR_KIT,
	]:
		storage.inventory.add(item_id, 1)
	world.pocket.add(SliceWorld.ITEM_CONVEYOR_KIT, 1)
	world.inventory_changed.emit()
	world.building_storage_changed.emit(storage.instance_id)
	var conveyor_before := world.pocket.count(SliceWorld.ITEM_CONVEYOR_KIT)
	_expect(
		storage_view.select_item(SliceWorld.ITEM_CONVEYOR_KIT, "pocket"),
		"full storage still shows the held source item"
	)
	_expect_equal(
		storage_view.request_selected_transfer(),
		false,
		"four-type limit disables the fifth-category transfer"
	)
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_CONVEYOR_KIT),
		conveyor_before,
		"rejected storage transfer keeps the source unchanged"
	)

	var collector := world._spawn_building(
		SliceBuildingCatalog.find(SliceBuildingCatalog.COLLECTOR_ID),
		"package3-collector",
		Vector2i(76, 10),
		0,
		{"buffer": 4}
	) as SliceCollector
	var crystal_before := world.pocket.count(SliceWorld.ITEM_CRYSTAL)
	world.open_building_actions(collector)
	var collector_view := world._building_action_panel.container_view()
	_expect(
		collector_view.select_item(SliceWorld.ITEM_CRYSTAL, "collector", true),
		"collector buffer is a source row in the shared view"
	)
	_expect_equal(
		collector_view.selected_amount(),
		4,
		"collector keeps its existing whole-buffer extraction contract"
	)
	_expect(collector_view.request_selected_transfer(), "collector drag requests extraction")
	_expect_equal(collector.buffer, 0, "collector extraction empties the available buffer")
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_CRYSTAL),
		crystal_before + 4,
		"collector extraction conserves every moved crystal"
	)

	var reactor := world._spawn_building(
		SliceBuildingCatalog.find(SliceBuildingCatalog.REACTOR_ID),
		"package3-reactor",
		Vector2i(82, 10),
		0,
		{
			"input_inventory": {"contents": {SliceWorld.ITEM_CRYSTAL: 2}},
			"output_inventory": {"contents": {SliceWorld.ITEM_CATALYST: 1}},
		}
	) as SliceReactor
	var reactor_crystal_before := world.pocket.count(SliceWorld.ITEM_CRYSTAL)
	var reactor_catalyst_before := world.pocket.count(SliceWorld.ITEM_CATALYST)
	world.open_building_actions(reactor)
	var reactor_view := world._building_action_panel.container_view()
	_expect(
		reactor_view.select_item(SliceWorld.ITEM_CRYSTAL, "reactor"),
		"reactor input appears as a recoverable device row"
	)
	_expect(reactor_view.request_selected_transfer(), "reactor row requests atomic recovery")
	_expect(
		reactor.input_inventory.is_empty() and reactor.output_inventory.is_empty(),
		"reactor recovery clears input and output together"
	)
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_CRYSTAL),
		reactor_crystal_before + 2,
		"reactor recovery conserves input crystals"
	)
	_expect_equal(
		world.pocket.count(SliceWorld.ITEM_CATALYST),
		reactor_catalyst_before + 1,
		"reactor recovery conserves output catalyst"
	)
	_expect_equal(
		SliceSaveService.SAVE_SCHEMA_VERSION,
		10,
		"container interaction does not change schema ten"
	)
	world.free()


func _items_ids(items: Array[Dictionary]) -> Array[String]:
	var result: Array[String] = []
	for item in items:
		result.append(String(item["item_id"]))
	return result


func _clear_inventory(inventory: Inventory) -> void:
	for item_id in inventory.item_ids():
		inventory.remove(item_id, inventory.count(item_id))


func _cleanup() -> void:
	_remove_tree(ProjectSettings.globalize_path(_test_root))


func _remove_tree(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		var child := path.path_join(entry)
		if dir.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(child)
		entry = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(path)


func _expect(condition: bool, label: String) -> void:
	_assertion_count += 1
	if not condition:
		failures.append(label)


func _expect_equal(actual, expected, label: String) -> void:
	_assertion_count += 1
	if actual != expected:
		failures.append("%s: expected %s, got %s" % [label, expected, actual])
