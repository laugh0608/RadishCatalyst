extends SceneTree

const BootScene := preload("res://scenes/boot/Boot.tscn")
const SHOT_DIR := "/Users/luobo/Code/RadishCatalyst/assets/art-intake/2026-07-26-multi-world-package3-preview"

var failures: Array[String] = []
var assertion_count := 0
var damaged_world_id := ""
var normal_world_id := ""
var REVIEW_BASE := SliceCheckPaths.review_worlds("multi-world")
var ONE_ROOT := REVIEW_BASE.path_join("one")
var MAIN_ROOT := REVIEW_BASE.path_join("main")


func _init() -> void:
	call_deferred("_execute")


func _execute() -> void:
	await _run()
	if failures.is_empty():
		print(
			"Slice save review worlds checks passed (%d assertions)."
			% assertion_count
		)
		print("Preserved one-world review root: %s" % ONE_ROOT)
		print("Preserved 30-world review root: %s" % MAIN_ROOT)
		print("Preserved screenshots: %s" % SHOT_DIR)
		quit(0)
		return
	for failure in failures:
		push_error(failure)
	quit(1)


func _run() -> void:
	_remove_tree(REVIEW_BASE)
	DirAccess.make_dir_recursive_absolute(SHOT_DIR)
	var one_catalog := SliceSaveCatalog.new(ONE_ROOT)
	var one_id := _create_saved_world(
		one_catalog,
		"01 单世界基线",
		_state(1)
	)
	if one_id.is_empty():
		return
	await _check_one_world_state(one_catalog, one_id)

	var main_catalog := SliceSaveCatalog.new(MAIN_ROOT)
	var trash_id := _create_trash_sample(main_catalog)
	if trash_id.is_empty():
		return
	for index in range(1, SliceSaveCatalog.MAX_WORLDS + 1):
		var display_name := _review_world_name(index)
		var world_id := _create_saved_world(
			main_catalog,
			display_name,
			_state(index)
		)
		if world_id.is_empty():
			return
		if index == 1:
			normal_world_id = world_id
		if index == 29:
			damaged_world_id = world_id
	_expect_equal(
		main_catalog.list_worlds().size(),
		SliceSaveCatalog.MAX_WORLDS,
		"main review root preserves 30 active worlds"
	)
	_expect_equal(
		main_catalog.list_trash().size(),
		1,
		"main review root preserves one trash item"
	)
	_corrupt_world_metadata(main_catalog, damaged_world_id)
	await _check_full_review_state(main_catalog, trash_id)


func _check_one_world_state(
	catalog: SliceSaveCatalog,
	world_id: String
) -> void:
	var boot := BootScene.instantiate()
	boot.slice_save_catalog = catalog
	root.add_child(boot)
	await process_frame
	var menu := boot.get_node_or_null("StartupMenu") as StartupMenu
	_expect(menu != null, "one-world Boot opens StartupMenu")
	if menu == null:
		return
	menu.load_game_button.pressed.emit()
	await process_frame
	_expect(menu.world_panel.visible, "one-world load opens list")
	_expect_equal(menu.world_item_list.item_count, 1, "one-world list has one row")
	_expect_equal(
		String(
			menu.world_item_list.get_item_metadata(0).get("world_id", "")
		),
		world_id,
		"one-world row keeps stable ID"
	)
	_expect(menu.world_item_list.has_focus(), "one-world list owns keyboard focus")
	menu.world_item_list.select(0)
	menu.world_item_list.item_selected.emit(0)
	await _screenshot("01-one-world.png")
	menu.world_back_button.pressed.emit()
	_expect(not menu.world_panel.visible, "world-list back returns to startup menu")
	boot.free()
	await process_frame


func _check_full_review_state(
	catalog: SliceSaveCatalog,
	trash_id: String
) -> void:
	var boot := BootScene.instantiate()
	boot.slice_save_catalog = catalog
	root.add_child(boot)
	await process_frame
	var menu := boot.get_node_or_null("StartupMenu") as StartupMenu
	_expect(menu != null, "30-world Boot opens StartupMenu")
	if menu == null:
		return
	menu.load_game_button.pressed.emit()
	await process_frame
	_expect_equal(menu.world_item_list.item_count, 30, "active list shows 30 rows")
	_expect_text_contains(
		menu.world_count_label.text,
		"30 / 30",
		"count label reports capacity"
	)
	_expect(menu.create_world_button.disabled, "create is disabled at capacity")
	_expect_text_contains(
		menu.world_status_label.text,
		"上限",
		"capacity state explains why create is disabled"
	)
	var normal_index := _find_world_index(menu, normal_world_id)
	_expect(normal_index >= 0, "normal review world remains listed")
	if normal_index >= 0:
		menu.world_item_list.select(normal_index)
		menu.world_item_list.item_selected.emit(normal_index)
		_expect(
			not menu.load_world_button.disabled,
			"normal world remains loadable beside damaged item"
		)
	await _screenshot("02-thirty-worlds.png")

	var damaged_index := _find_world_index(menu, damaged_world_id)
	_expect(damaged_index >= 0, "damaged metadata item remains listed")
	if damaged_index >= 0:
		menu.world_item_list.select(damaged_index)
		menu.world_item_list.item_selected.emit(damaged_index)
		menu.world_item_list.ensure_current_is_visible()
		_expect(
			menu.load_world_button.disabled,
			"damaged metadata item cannot be loaded"
		)
		_expect_text_contains(
			menu.world_details_label.text,
			"元数据损坏",
			"damaged selection states its problem"
		)
		_expect_text_contains(
			menu.world_details_label.text,
			"无法读取的世界",
			"damaged selection hides opaque internal ID"
		)
		_expect(
			menu.rename_world_button.disabled,
			"damaged metadata item cannot be renamed"
		)
		_expect(
			not menu.world_name_input.editable,
			"damaged metadata item disables the name field"
		)
		_expect_text_contains(
			menu.world_details_label.text,
			"无法从游戏内恢复",
			"damaged selection states the in-game recovery boundary"
		)
		menu.trash_world_button.pressed.emit()
		_expect(
			menu.trash_confirm_panel.visible,
			"damaged item still supports recoverable directory isolation"
		)
		_expect_text_contains(
			menu.trash_confirm_label.text,
			"无法从游戏内恢复",
			"damaged trash confirmation does not promise restoration"
		)
		await _press_action("ui_cancel")
		_expect_equal(
			catalog.list_worlds().size(),
			30,
			"cancel keeps damaged world in active directory"
		)
	await _screenshot("03-damaged-world.png")

	if normal_index >= 0:
		menu.world_item_list.select(normal_index)
		menu.world_item_list.item_selected.emit(normal_index)
		menu.trash_world_button.pressed.emit()
		_expect(
			menu.trash_confirm_panel.visible,
			"move-to-trash action opens confirmation"
		)
		await _press_action("ui_cancel")
		_expect(
			not menu.trash_confirm_panel.visible,
			"cancel closes trash confirmation"
		)
		_expect_equal(
			catalog.list_worlds().size(),
			30,
			"cancel keeps all active worlds"
		)

	menu.trash_worlds_button.pressed.emit()
	await process_frame
	_expect_equal(menu.world_item_list.item_count, 1, "trash list shows one row")
	menu.world_item_list.select(0)
	menu.world_item_list.item_selected.emit(0)
	var trash_summary = menu.world_item_list.get_item_metadata(0)
	_expect_equal(
		String(trash_summary.get("trash_id", "")),
		trash_id,
		"trash row keeps recoverable trash ID"
	)
	_expect(
		not menu.restore_world_button.disabled,
		"selected trash item can be restored"
	)
	await _screenshot("04-trash-world.png")
	await _press_action("ui_cancel")
	_expect(not menu.world_panel.visible, "Escape returns from world list")
	boot.free()


func _create_trash_sample(catalog: SliceSaveCatalog) -> String:
	var world_id := _create_saved_world(
		catalog,
		"回收恢复样本",
		_state(0)
	)
	if world_id.is_empty():
		return ""
	var trash_result := catalog.move_world_to_trash(world_id)
	_expect_success(trash_result, "move review sample to trash")
	return String(trash_result.get("data", {}).get("trash_id", ""))


func _create_saved_world(
	catalog: SliceSaveCatalog,
	display_name: String,
	state: Dictionary
) -> String:
	var create_result := catalog.create_world(display_name)
	_expect_success(create_result, "create %s" % display_name)
	if not bool(create_result.get("success", false)):
		return ""
	var world_id := String(create_result.get("data", {}).get("world_id", ""))
	var service := catalog.service_for_world(world_id)
	_expect(service != null, "%s receives a save service" % display_name)
	if service == null:
		return ""
	_expect_success(service.save_state(state), "save %s main" % display_name)
	_expect_success(service.save_state(state), "save %s backup" % display_name)
	return world_id


func _review_world_name(index: int) -> String:
	match index:
		1:
			return "01 正常载入基线"
		2:
			return "02 L5 完整产线"
		8:
			return "08 北部晶体带反应器物流超长名称截断复核"
		29:
			return "29 元数据损坏样本"
		30:
			return "30 容量上限末项"
		_:
			return "%02d 前哨复核世界" % index


func _state(marker: int) -> Dictionary:
	var building_count := marker % 5
	var buildings: Array[Dictionary] = []
	for index in range(building_count):
		buildings.append({
			"instance_id": "building-%06d" % (index + 1),
			"building_id": SliceBuildingCatalog.FLOOR_ID,
			"origin_cell": [4 + index, 4],
			"rotation": 0,
			"state": {},
		})
	return {
		"pocket": {
			"capacity": SliceWorld.POCKET_CAPACITY,
			"contents": {},
		},
		"core_storage": {
			"capacity": SliceWorld.CORE_STORAGE_CAPACITY,
			"contents": {
				SliceWorld.ITEM_CATALYST: marker % 4,
			},
		},
		"core_repaired": marker % 2 == 0,
		"core_energy": marker,
		"harvested_clusters": [],
		"buildings": buildings,
		"next_building_serial": building_count + 1,
		"player_x": 480.0,
		"player_y": 270.0,
		"first_journey_flags": {
			"terminal_opened": true,
			"part_recipe_inspected": true,
		},
		"explored_map_bits": SliceExplorationState.default_bits_for_position(
			Vector2(480, 270)
		),
	}


func _corrupt_world_metadata(
	catalog: SliceSaveCatalog,
	world_id: String
) -> void:
	var path := catalog.worlds_directory().path_join(
		world_id
	).path_join("metadata.json")
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		failures.append("cannot corrupt metadata fixture %s" % path)
		return
	file.store_string("{damaged-review-fixture")
	file.close()


func _find_world_index(menu: StartupMenu, world_id: String) -> int:
	for index in range(menu.world_item_list.item_count):
		var metadata = menu.world_item_list.get_item_metadata(index)
		if (
			metadata is Dictionary
			and String(metadata.get("world_id", "")) == world_id
		):
			return index
	return -1


func _press_action(action: StringName) -> void:
	var pressed := InputEventAction.new()
	pressed.action = action
	pressed.pressed = true
	Input.parse_input_event(pressed)
	await process_frame
	var released := InputEventAction.new()
	released.action = action
	released.pressed = false
	Input.parse_input_event(released)
	await process_frame


func _screenshot(file_name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png(SHOT_DIR.path_join(file_name))
	_expect(error == OK, "screenshot %s writes" % file_name)


func _remove_tree(path: String) -> void:
	var absolute_path := ProjectSettings.globalize_path(path)
	var dir := DirAccess.open(absolute_path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		var child := absolute_path.path_join(entry)
		if dir.current_is_dir():
			_remove_tree(child)
		else:
			DirAccess.remove_absolute(child)
		entry = dir.get_next()
	dir.list_dir_end()
	DirAccess.remove_absolute(absolute_path)


func _expect_success(result: Dictionary, context: String) -> void:
	_expect(
		bool(result.get("success", false)),
		"%s: %s" % [context, String(result.get("message", ""))]
	)


func _expect_equal(actual, expected, context: String) -> void:
	_expect(
		actual == expected,
		"%s: expected %s, got %s" % [context, str(expected), str(actual)]
	)


func _expect_text_contains(text: String, expected: String, context: String) -> void:
	_expect(
		text.contains(expected),
		"%s: expected '%s' in '%s'" % [context, expected, text]
	)


func _expect(condition: bool, context: String) -> void:
	assertion_count += 1
	if not condition:
		failures.append(context)
